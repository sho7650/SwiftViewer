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
        return try await Task {
            guard let image = NSImage(contentsOf: url) else {
                logger.error("Failed to load image from \(url.path)")
                throw ImageLoaderError.invalidImage
            }
            return image
        }.value
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
        return mockImage ?? NSImage()
    }
}