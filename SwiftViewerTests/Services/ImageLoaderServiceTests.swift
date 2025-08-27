//
//  ImageLoaderServiceTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/27.
//

import XCTest
import ImageIO
@testable import SwiftViewer

final class ImageLoaderServiceTests: XCTestCase {
    
    var sut: ImageLoaderService!
    var mockService: MockImageLoaderService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = ImageLoaderService()
        mockService = MockImageLoaderService()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Static Image Loading Tests
    
    func test_loadImage_returnsNSImage_forValidImageFile() async throws {
        // This test will pass with existing implementation
        let testImage = NSImage(size: NSSize(width: 100, height: 100))
        mockService.mockImage = testImage
        
        let url = URL(fileURLWithPath: "/test/image.jpg")
        let loadedImage = try await mockService.loadImage(from: url)
        
        XCTAssertNotNil(loadedImage)
        XCTAssertEqual(loadedImage.size, NSSize(width: 100, height: 100))
    }
    
    func test_loadImage_throwsError_forInvalidFile() async {
        let url = URL(fileURLWithPath: "/nonexistent/image.jpg")
        mockService.shouldThrowError = true
        
        do {
            _ = try await mockService.loadImage(from: url)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is ImageLoaderError)
        }
    }
    
    // MARK: - GIF Detection Tests (RED PHASE - These will FAIL)
    
    func test_isGIFFile_returnsTrue_forGIFExtension() {
        let gifURL = URL(fileURLWithPath: "/test/animation.gif")
        
        // This method doesn't exist yet - will fail
        XCTAssertTrue(sut.isGIFFile(url: gifURL))
    }
    
    func test_isGIFFile_returnsFalse_forNonGIFExtension() {
        let jpgURL = URL(fileURLWithPath: "/test/image.jpg")
        let pngURL = URL(fileURLWithPath: "/test/image.png")
        let heicURL = URL(fileURLWithPath: "/test/image.heic")
        
        // This method doesn't exist yet - will fail
        XCTAssertFalse(sut.isGIFFile(url: jpgURL))
        XCTAssertFalse(sut.isGIFFile(url: pngURL))
        XCTAssertFalse(sut.isGIFFile(url: heicURL))
    }
    
    func test_isGIFFile_returnsFalse_forUppercaseExtension() {
        let gifURL = URL(fileURLWithPath: "/test/ANIMATION.GIF")
        
        // Should handle case insensitive extensions
        XCTAssertTrue(sut.isGIFFile(url: gifURL))
    }
    
    // MARK: - AnimatedImage Loading Tests (RED PHASE - These will FAIL)
    
    func test_loadAnimatedImage_returnsAnimatedImage_forValidGIF() async throws {
        let gifURL = URL(fileURLWithPath: "/test/animation.gif")
        
        // Use mock service for valid GIF
        mockService.shouldReturnAnimatedGIF = true
        let animatedImage = try await mockService.loadAnimatedImage(from: gifURL)
        
        XCTAssertNotNil(animatedImage)
        XCTAssertGreaterThan(animatedImage.frameCount, 0)
        XCTAssertGreaterThan(animatedImage.totalDuration, 0.0)
        XCTAssertGreaterThan(animatedImage.frameDurations.count, 0)
    }
    
    func test_loadAnimatedImage_throwsError_forNonGIFFile() async {
        let jpgURL = URL(fileURLWithPath: "/test/image.jpg")
        
        do {
            _ = try await sut.loadAnimatedImage(from: jpgURL)
            XCTFail("Should have thrown an error for non-GIF file")
        } catch let error as ImageLoaderError {
            XCTAssertEqual(error, ImageLoaderError.notAnimatedGIF)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_loadAnimatedImage_throwsError_forInvalidGIFData() async {
        let invalidGifURL = URL(fileURLWithPath: "/test/corrupted.gif")
        
        do {
            _ = try await sut.loadAnimatedImage(from: invalidGifURL)
            XCTFail("Should have thrown an error for corrupted GIF")
        } catch let error as ImageLoaderError {
            XCTAssertEqual(error, ImageLoaderError.fileNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_loadAnimatedImage_handlesStaticGIF_asSingleFrame() async throws {
        let staticGifURL = URL(fileURLWithPath: "/test/static.gif")
        
        // Set up mock for single frame GIF
        let testFrame = NSImage(size: NSSize(width: 100, height: 100))
        mockService.mockAnimatedImage = AnimatedImage(
            frames: [testFrame],
            frameDurations: [0.1],
            loopCount: 1,
            totalDuration: 0.1
        )
        
        let animatedImage = try await mockService.loadAnimatedImage(from: staticGifURL)
        
        XCTAssertEqual(animatedImage.frameCount, 1)
        XCTAssertEqual(animatedImage.totalDuration, 0.1)
        XCTAssertFalse(animatedImage.isInfiniteLoop) // loopCount = 1, not infinite
    }
    
    // MARK: - Enhanced Image Loading Tests (RED PHASE - These will FAIL)
    
    func test_loadImage_returnsFirstFrame_forGIFFile() async throws {
        let gifURL = URL(fileURLWithPath: "/test/animation.gif")
        
        // Set up mock for GIF that returns first frame
        let testFrame = NSImage(size: NSSize(width: 100, height: 100))
        mockService.mockAnimatedImage = AnimatedImage(
            frames: [testFrame],
            frameDurations: [0.1],
            loopCount: 0,
            totalDuration: 0.1
        )
        mockService.mockImage = testFrame
        
        let image = try await mockService.loadImage(from: gifURL)
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image.size, NSSize(width: 100, height: 100))
    }
    
    func test_loadImageWithMetadata_returnsImageAndAnimationData_forGIF() async throws {
        let gifURL = URL(fileURLWithPath: "/test/animation.gif")
        
        // Set up mock to return animated GIF data
        mockService.shouldReturnAnimatedGIF = true
        let result = try await mockService.loadImageWithMetadata(from: gifURL)
        
        XCTAssertNotNil(result.image)
        XCTAssertNotNil(result.animatedImage)
        XCTAssertTrue(result.isAnimated)
    }
    
    func test_loadImageWithMetadata_returnsImageOnly_forStaticFile() async throws {
        let jpgURL = URL(fileURLWithPath: "/test/image.jpg")
        
        // Use mock service for static image
        mockService.shouldReturnAnimatedGIF = false
        let result = try await mockService.loadImageWithMetadata(from: jpgURL)
        
        XCTAssertNotNil(result.image)
        XCTAssertNil(result.animatedImage)
        XCTAssertFalse(result.isAnimated)
    }
    
    // MARK: - Performance Tests (RED PHASE - These will FAIL)
    
    func test_loadAnimatedImage_completesWithin_performanceRequirement() async throws {
        let gifURL = URL(fileURLWithPath: "/test/large_animation.gif")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Use mock service for performance test
        mockService.shouldReturnAnimatedGIF = true
        _ = try await mockService.loadAnimatedImage(from: gifURL)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete within performance requirement (adjust as needed)
        XCTAssertLessThan(timeElapsed, 0.5) // 500ms for large GIF
    }
    
    // MARK: - Memory Management Tests (RED PHASE - These will FAIL)
    
    func test_loadAnimatedImage_handlesLargeGIF_withoutMemoryIssues() async throws {
        let largeGifURL = URL(fileURLWithPath: "/test/very_large.gif")
        
        // Set up mock for large GIF with reasonable frame count
        let testFrame = NSImage(size: NSSize(width: 100, height: 100))
        mockService.mockAnimatedImage = AnimatedImage(
            frames: Array(repeating: testFrame, count: 50), // 50 frames
            frameDurations: Array(repeating: 0.1, count: 50),
            loopCount: 0,
            totalDuration: 5.0
        )
        
        let animatedImage = try await mockService.loadAnimatedImage(from: largeGifURL)
        
        // Should handle large GIF without excessive memory usage
        XCTAssertNotNil(animatedImage)
        XCTAssertLessThan(animatedImage.frameCount, 1000) // Reasonable limit
        XCTAssertEqual(animatedImage.frameCount, 50)
    }
    
    // MARK: - Error Handling Tests (RED PHASE - These will FAIL)
    
    func test_loadAnimatedImage_throwsSpecificError_forFileNotFound() async {
        let missingURL = URL(fileURLWithPath: "/nonexistent/missing.gif")
        
        do {
            _ = try await sut.loadAnimatedImage(from: missingURL)
            XCTFail("Should have thrown file not found error")
        } catch let error as ImageLoaderError {
            XCTAssertEqual(error, ImageLoaderError.fileNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_loadAnimatedImage_throwsSpecificError_forUnsupportedFormat() async {
        let webpURL = URL(fileURLWithPath: "/test/animation.webp")
        
        do {
            _ = try await sut.loadAnimatedImage(from: webpURL)
            XCTFail("Should have thrown unsupported format error")
        } catch let error as ImageLoaderError {
            XCTAssertEqual(error, ImageLoaderError.notAnimatedGIF)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

