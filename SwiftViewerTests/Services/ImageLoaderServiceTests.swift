//
//  ImageLoaderServiceTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/03/13.
//

import XCTest
@testable import SwiftViewer

final class ImageLoaderServiceTests: XCTestCase {

    var sut: ImageLoaderService!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        sut = ImageLoaderService()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageLoaderServiceTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper

    private func createTestPNG(at url: URL) throws {
        let size = NSSize(width: 10, height: 10)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.set()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            XCTFail("Failed to create test PNG data")
            return
        }
        try pngData.write(to: url)
    }

    private func assertLoadImageThrows(
        _ expectedError: ImageLoaderError,
        from url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await sut.loadImage(from: url)
            XCTFail("Expected \(expectedError) error", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? ImageLoaderError, expectedError, file: file, line: line)
        }
    }

    // MARK: - Tests

    func test_loadImage_validPNG_returnsNSImage() async throws {
        let imageURL = tempDirectory.appendingPathComponent("test.png")
        try createTestPNG(at: imageURL)

        let image = try await sut.loadImage(from: imageURL)

        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func test_loadImage_fileNotFound_throwsFileNotFoundError() async {
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent.jpg")

        await assertLoadImageThrows(.fileNotFound, from: nonExistentURL)
    }

    func test_loadImage_invalidData_throwsInvalidImageError() async throws {
        let invalidURL = tempDirectory.appendingPathComponent("invalid.jpg")
        try Data("not an image".utf8).write(to: invalidURL)

        await assertLoadImageThrows(.invalidImage, from: invalidURL)
    }

    func test_loadImage_emptyFile_throwsInvalidImageError() async throws {
        let emptyURL = tempDirectory.appendingPathComponent("empty.png")
        try Data().write(to: emptyURL)

        await assertLoadImageThrows(.invalidImage, from: emptyURL)
    }
}
