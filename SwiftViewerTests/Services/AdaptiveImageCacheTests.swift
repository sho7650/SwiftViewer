//
//  AdaptiveImageCacheTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/30.
//

import XCTest
import Kingfisher
@testable import SwiftViewer

@available(macOS 14.0, *)
final class AdaptiveImageCacheTests: XCTestCase {
    var sut: AdaptiveImageCache!
    var mockFileManager: MockFileManagerService!
    var mockSettingsManager: MockSettingsManager!
    
    override func setUp() async throws {
        try await super.setUp()
        mockFileManager = MockFileManagerService()
        mockSettingsManager = MockSettingsManager()
        sut = AdaptiveImageCache(fileManager: mockFileManager, settings: mockSettingsManager)
        
        // Clear cache before each test to ensure clean state
        await sut.clearCache()
    }
    
    override func tearDown() {
        sut = nil
        mockFileManager = nil
        mockSettingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Level 1: Basic Initialization Tests
    
    func test_init_withKingfisherDependency() {
        XCTAssertNotNil(sut, "Should initialize with Kingfisher dependency")
    }
    
    func test_kingfisher_cache_hasCustomName() async throws {
        let cacheName = await sut.getCacheName()
        XCTAssertEqual(cacheName, "SwiftViewer", "Should use custom cache name")
    }
    
    func test_memoryLimit_configuration() async throws {
        let memoryLimit = await sut.getMemoryLimit()
        let systemMemory = ProcessInfo.processInfo.physicalMemory
        let expected = Int(systemMemory * 15 / 100)
        
        XCTAssertEqual(memoryLimit, expected, "Should use 15% of system memory")
    }
    
    func test_diskLimit_configuration() async throws {
        let diskLimit = await sut.getDiskLimit()
        XCTAssertEqual(diskLimit, 500 * 1024 * 1024, "Should use 500MB disk limit")
    }
    
    func test_countLimit_configuration() async throws {
        let countLimit = await sut.getCountLimit()
        XCTAssertEqual(countLimit, 100, "Should limit to 100 images")
    }
    
    // MARK: - Level 2: Cache Operations Tests
    
    func test_cache_storeAndRetrieve_basicImage() async throws {
        // Given: Test image URL
        let testUrl = URL(fileURLWithPath: "/test/image1.jpg")
        
        // When: Store and retrieve image
        await sut.cacheImage(url: testUrl)
        let retrievedImage = await sut.getImage(from: testUrl)
        
        // Then: Should retrieve cached image
        XCTAssertNotNil(retrievedImage, "Should retrieve cached image")
    }
    
    func test_cache_responseTime_under10ms() async throws {
        // Given: Cached image
        let testUrl = URL(fileURLWithPath: "/test/image1.jpg")
        await sut.cacheImage(url: testUrl)
        
        // When: Retrieve cached image with timing
        let startTime = CFAbsoluteTimeGetCurrent()
        let image = await sut.getImage(from: testUrl)
        let responseTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        // Then: Should respond under 10ms
        XCTAssertNotNil(image, "Should return cached image")
        XCTAssertLessThan(responseTime, 10.0, "Cache response should be under 10ms")
    }
    
    func test_isImageCached_returnsCorrectStatus() async throws {
        // Given: Cached and uncached URLs
        let cachedUrl = URL(fileURLWithPath: "/test/cached.jpg")
        let uncachedUrl = URL(fileURLWithPath: "/test/uncached.jpg")
        await sut.cacheImage(url: cachedUrl)
        
        // When: Check cache status
        let isCached = await sut.isImageCached(url: cachedUrl)
        let isNotCached = await sut.isImageCached(url: uncachedUrl)
        
        // Then: Should return correct status
        XCTAssertTrue(isCached, "Should return true for cached image")
        XCTAssertFalse(isNotCached, "Should return false for uncached image")
    }
    
    func test_getCachedImageCount_returnsCorrectCount() async throws {
        // Given: Clear cache first to ensure clean state
        await sut.clearCache()
        
        // Multiple cached images
        let urls = [
            URL(fileURLWithPath: "/test/image1.jpg"),
            URL(fileURLWithPath: "/test/image2.jpg"),
            URL(fileURLWithPath: "/test/image3.jpg")
        ]
        
        // Cache images one by one and verify each is cached
        for url in urls {
            await sut.cacheImage(url: url)
            let isCached = await sut.isImageCached(url: url)
            XCTAssertTrue(isCached, "Image \(url.lastPathComponent) should be cached")
        }
        
        // When: Get cached count
        let count = await sut.getCachedImageCount()
        
        // Then: Should return correct count
        XCTAssertEqual(count, 3, "Should return correct cached image count")
    }
}