//
//  ImageLoaderService.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation
import AppKit
import ImageIO

/// Result type for enhanced image loading with metadata
struct ImageLoadResult {
    let image: NSImage
    let animatedImage: AnimatedImage?
    let isAnimated: Bool
}

protocol ImageLoaderServiceProtocol {
    func loadImage(from url: URL) async throws -> NSImage
    func isGIFFile(url: URL) -> Bool
    func loadAnimatedImage(from url: URL) async throws -> AnimatedImage
    func loadImageWithMetadata(from url: URL) async throws -> ImageLoadResult
}

final class ImageLoaderService: ImageLoaderServiceProtocol {
    private let logger = Logger.shared
    
    func loadImage(from url: URL) async throws -> NSImage {
        return try await Task {
            // Check if it's a GIF file and handle appropriately
            if isGIFFile(url: url) {
                // For GIF files, return the first frame as NSImage
                let animatedImage = try await loadAnimatedImage(from: url)
                guard let firstFrame = animatedImage.frame(at: 0) else {
                    logger.error("Failed to extract first frame from GIF at \(url.path)")
                    throw ImageLoaderError.invalidImage
                }
                return firstFrame
            } else {
                // Handle regular image files
                guard let image = NSImage(contentsOf: url) else {
                    logger.error("Failed to load image from \(url.path)")
                    throw ImageLoaderError.invalidImage
                }
                return image
            }
        }.value
    }
    
    func isGIFFile(url: URL) -> Bool {
        return url.pathExtension.lowercased() == "gif"
    }
    
    func loadAnimatedImage(from url: URL) async throws -> AnimatedImage {
        return try await Task {
            // Verify it's a GIF file
            guard isGIFFile(url: url) else {
                logger.error("Attempted to load animated image from non-GIF file: \(url.path)")
                throw ImageLoaderError.notAnimatedGIF
            }
            
            // Check if file exists
            guard FileManager.default.fileExists(atPath: url.path) else {
                logger.error("GIF file not found at path: \(url.path)")
                throw ImageLoaderError.fileNotFound
            }
            
            // Create CGImageSource from file
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                logger.error("Failed to create image source from GIF file: \(url.path)")
                throw ImageLoaderError.corruptedGIF
            }
            
            // Use AnimatedImage factory method
            guard let animatedImage = AnimatedImage.from(imageSource: imageSource) else {
                logger.error("Failed to parse GIF data from file: \(url.path)")
                throw ImageLoaderError.corruptedGIF
            }
            
            logger.debug("Successfully loaded animated GIF with \(animatedImage.frameCount) frames from \(url.path)")
            return animatedImage
        }.value
    }
    
    func loadImageWithMetadata(from url: URL) async throws -> ImageLoadResult {
        return try await Task {
            let image = try await loadImage(from: url)
            
            if isGIFFile(url: url) {
                do {
                    let animatedImage = try await loadAnimatedImage(from: url)
                    return ImageLoadResult(
                        image: image,
                        animatedImage: animatedImage,
                        isAnimated: true
                    )
                } catch {
                    // If animated loading fails, treat as static image
                    logger.warning("Failed to load GIF animation, treating as static image: \(error.localizedDescription)")
                    return ImageLoadResult(
                        image: image,
                        animatedImage: nil,
                        isAnimated: false
                    )
                }
            } else {
                return ImageLoadResult(
                    image: image,
                    animatedImage: nil,
                    isAnimated: false
                )
            }
        }.value
    }
}

enum ImageLoaderError: Error, Equatable {
    case invalidImage
    case fileNotFound
    case notAnimatedGIF
    case corruptedGIF
    case unsupportedFormat
}

final class MockImageLoaderService: ImageLoaderServiceProtocol {
    var mockImage: NSImage?
    var shouldThrowError = false
    var mockAnimatedImage: AnimatedImage?
    var shouldReturnAnimatedGIF = false
    
    func loadImage(from url: URL) async throws -> NSImage {
        if shouldThrowError {
            throw ImageLoaderError.invalidImage
        }
        
        if let mockImage = mockImage {
            return mockImage
        }
        
        // Create a guaranteed valid test image
        let testImage = NSImage(size: NSSize(width: 100, height: 100))
        testImage.lockFocus()
        NSColor.gray.set()
        NSRect(origin: .zero, size: NSSize(width: 100, height: 100)).fill()
        testImage.unlockFocus()
        return testImage
    }
    
    func isGIFFile(url: URL) -> Bool {
        return url.pathExtension.lowercased() == "gif"
    }
    
    func loadAnimatedImage(from url: URL) async throws -> AnimatedImage {
        if shouldThrowError {
            throw ImageLoaderError.corruptedGIF
        }
        
        if let mockAnimated = mockAnimatedImage {
            return mockAnimated
        }
        
        // Create mock animated image for testing
        let testFrame = NSImage(size: NSSize(width: 100, height: 100))
        return AnimatedImage(
            frames: [testFrame, testFrame],
            frameDurations: [0.1, 0.1],
            loopCount: 0,
            totalDuration: 0.2
        )
    }
    
    func loadImageWithMetadata(from url: URL) async throws -> ImageLoadResult {
        let image = try await loadImage(from: url)
        let animatedImage = shouldReturnAnimatedGIF ? try await loadAnimatedImage(from: url) : nil
        
        return ImageLoadResult(
            image: image,
            animatedImage: animatedImage,
            isAnimated: animatedImage != nil
        )
    }
}