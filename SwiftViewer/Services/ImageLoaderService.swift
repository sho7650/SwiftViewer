//
//  ImageLoaderService.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation
import AppKit

protocol ImageLoaderServiceProtocol {
    func loadImage(from url: URL) async throws -> NSImage
}

final class ImageLoaderService: ImageLoaderServiceProtocol {
    private let logger = Logger.shared
    
    func loadImage(from url: URL) async throws -> NSImage {
        guard FileManager.default.fileExists(atPath: url.path) else {
            logger.error("Image file not found: \(Logger.sanitizePath(url))")
            throw ImageLoaderError.fileNotFound
        }
        guard let image = NSImage(contentsOf: url) else {
            logger.error("Failed to load image from \(Logger.sanitizePath(url))")
            throw ImageLoaderError.invalidImage
        }
        return image
    }
}

enum ImageLoaderError: Error {
    case invalidImage
    case fileNotFound
}

final class MockImageLoaderService: ImageLoaderServiceProtocol {
    var mockImage: NSImage?
    var shouldThrowError = false
    
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
}