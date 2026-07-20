//
//  ImagePipelineProtocol.swift
//  SwiftViewer
//
//  Downsampling image pipeline with an in-memory cache and neighbour preloading.
//

import Foundation
import CoreGraphics

/// An immutable decoded image, safe to pass across concurrency domains.
///
/// `CGImage` is not declared `Sendable` by the SDK, but the decoded bitmap this
/// wraps is never mutated after creation, so the wrapper can be treated as sendable.
struct DecodedImage: @unchecked Sendable, Equatable {
    let cgImage: CGImage

    var pixelWidth: Int { cgImage.width }
    var pixelHeight: Int { cgImage.height }
}

enum ImagePipelineError: Error, Equatable {
    case fileNotFound
    case invalidImage
}

protocol ImagePipelineProtocol: Sendable {
    /// Returns a downsampled image for `url`, serving from cache when available.
    /// `maxPixelSize` bounds the longest edge of the returned bitmap.
    func image(for url: URL, maxPixelSize: CGFloat) async throws -> DecodedImage

    /// Ensures `urls` are decoded and cached with bounded concurrency.
    /// Honours cancellation of the calling task.
    func preload(_ urls: [URL], maxPixelSize: CGFloat) async

    /// Clears the cache and cancels in-flight decodes (e.g. on folder change).
    func reset() async
}

/// Test double mirroring the ergonomics of the production pipeline.
final class MockImagePipeline: ImagePipelineProtocol, @unchecked Sendable {
    var shouldThrowError = false
    var errorToThrow: Error = ImagePipelineError.invalidImage
    /// When set, `image(for:)` returns this bitmap; otherwise a small placeholder is returned.
    var mockImage: CGImage?
    private(set) var preloadedURLs: [URL] = []
    private(set) var didReset = false

    func image(for url: URL, maxPixelSize: CGFloat) async throws -> DecodedImage {
        if shouldThrowError { throw errorToThrow }
        return DecodedImage(cgImage: mockImage ?? Self.placeholder)
    }

    func preload(_ urls: [URL], maxPixelSize: CGFloat) async {
        preloadedURLs = urls
    }

    func reset() async {
        didReset = true
    }

    /// A minimal valid 2×2 opaque bitmap for tests that only need a non-nil image.
    static let placeholder: CGImage = {
        let context = CGContext(
            data: nil,
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        return context.makeImage()!
    }()
}
