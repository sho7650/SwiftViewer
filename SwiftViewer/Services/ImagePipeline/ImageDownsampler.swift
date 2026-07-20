//
//  ImageDownsampler.swift
//  SwiftViewer
//
//  Pure ImageIO downsampling — decodes a bounded thumbnail off the main thread.
//

import Foundation
import ImageIO
import CoreGraphics

enum ImageDownsampler {
    /// Decodes `url` into a downsampled `CGImage` whose longest edge is at most `maxPixelSize`.
    /// Decoding happens eagerly here so the returned bitmap never decodes on the main thread at draw time.
    static func downsample(url: URL, maxPixelSize: CGFloat) throws -> CGImage {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ImagePipelineError.fileNotFound
        }

        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            throw ImagePipelineError.invalidImage
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true, // respect EXIF orientation
            kCGImageSourceShouldCacheImmediately: true,        // decode now, off-main
            kCGImageSourceThumbnailMaxPixelSize: max(1, maxPixelSize)
        ]

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
            throw ImagePipelineError.invalidImage
        }
        return thumbnail
    }
}
