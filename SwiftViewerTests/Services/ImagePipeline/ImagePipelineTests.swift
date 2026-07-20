//
//  ImagePipelineTests.swift
//  SwiftViewerTests
//

import XCTest
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics
@testable import SwiftViewer

final class ImagePipelineTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImagePipelineTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
        tempDir = nil
    }

    // MARK: - Helpers

    /// Writes a solid-colour JPEG of the given pixel dimensions and returns its URL.
    @discardableResult
    private func writeJPEG(width: Int, height: Int, name: String) throws -> URL {
        let url = tempDir.appendingPathComponent(name)
        let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let cgImage = context.makeImage()!

        let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.jpeg.identifier as CFString, 1, nil
        )!
        CGImageDestinationAddImage(dest, cgImage, nil)
        XCTAssertTrue(CGImageDestinationFinalize(dest))
        return url
    }

    private func makePipeline() -> ImagePipeline {
        ImagePipeline(memoryLimitPercentage: 15, countLimit: 100)
    }

    // MARK: - Downsampling

    func test_image_downsamplesToMaxPixelSize() async throws {
        let url = try writeJPEG(width: 4000, height: 2000, name: "large.jpg")
        let pipeline = makePipeline()

        let decoded = try await pipeline.image(for: url, maxPixelSize: 512)

        XCTAssertLessThanOrEqual(decoded.pixelWidth, 512)
        XCTAssertLessThanOrEqual(decoded.pixelHeight, 512)
        // Aspect ratio preserved: the long edge should be the one bounded to 512.
        XCTAssertEqual(decoded.pixelWidth, 512)
    }

    // MARK: - Caching

    func test_image_servesFromCache_afterFileDeleted() async throws {
        let url = try writeJPEG(width: 800, height: 600, name: "cached.jpg")
        let pipeline = makePipeline()

        _ = try await pipeline.image(for: url, maxPixelSize: 256)
        // Deleting the file proves the second read comes from cache, not disk.
        try FileManager.default.removeItem(at: url)

        let decoded = try await pipeline.image(for: url, maxPixelSize: 256)
        XCTAssertGreaterThan(decoded.pixelWidth, 0)
    }

    func test_reset_clearsCache() async throws {
        let url = try writeJPEG(width: 800, height: 600, name: "reset.jpg")
        let pipeline = makePipeline()

        _ = try await pipeline.image(for: url, maxPixelSize: 256)
        await pipeline.reset()
        try FileManager.default.removeItem(at: url)

        // After reset the cache is empty, so a missing file must now throw.
        do {
            _ = try await pipeline.image(for: url, maxPixelSize: 256)
            XCTFail("Expected fileNotFound after reset with the file removed")
        } catch let error as ImagePipelineError {
            XCTAssertEqual(error, .fileNotFound)
        }
    }

    // MARK: - Errors

    func test_image_throwsFileNotFound_forMissingFile() async {
        let url = tempDir.appendingPathComponent("missing.jpg")
        let pipeline = makePipeline()

        do {
            _ = try await pipeline.image(for: url, maxPixelSize: 256)
            XCTFail("Expected fileNotFound")
        } catch let error as ImagePipelineError {
            XCTAssertEqual(error, .fileNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_image_throwsInvalidImage_forCorruptFile() async throws {
        let url = tempDir.appendingPathComponent("corrupt.jpg")
        try Data("not an image".utf8).write(to: url)
        let pipeline = makePipeline()

        do {
            _ = try await pipeline.image(for: url, maxPixelSize: 256)
            XCTFail("Expected invalidImage")
        } catch let error as ImagePipelineError {
            XCTAssertEqual(error, .invalidImage)
        }
    }

    // MARK: - Preloading

    func test_preload_populatesNeighbours() async throws {
        let urls = try (0..<3).map { try writeJPEG(width: 400, height: 300, name: "p\($0).jpg") }
        let pipeline = makePipeline()

        await pipeline.preload(urls, maxPixelSize: 256)

        // Deleting the files proves the subsequent reads are served from the warm cache.
        for url in urls { try FileManager.default.removeItem(at: url) }
        for url in urls {
            let decoded = try await pipeline.image(for: url, maxPixelSize: 256)
            XCTAssertGreaterThan(decoded.pixelWidth, 0)
        }
    }
}
