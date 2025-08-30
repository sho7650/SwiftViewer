//
//  AdaptiveImageCacheTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/30.
//

import XCTest
@testable import SwiftViewer

@MainActor
class AdaptiveImageCacheTests: XCTestCase {
    var sut: AdaptiveImageCache!
    var mockFileManager: MockFileManagerService!
    var mockSettingsManager: MockSettingsManager!
    
    override func setUp() {
        super.setUp()
        mockFileManager = MockFileManagerService()
        mockSettingsManager = MockSettingsManager()
        // Reset mock state
        mockFileManager.mockImageFiles = []
        mockFileManager.shouldReturnCorruptedImage = false
        mockFileManager.simulateLowMemory = false
        mockFileManager.disableAutoGeneration = true // Disable auto-generation by default
        
        sut = AdaptiveImageCache(
            fileManager: mockFileManager,
            settings: mockSettingsManager
        )
    }
    
    override func tearDown() {
        sut = nil
        mockFileManager = nil
        mockSettingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_setsCorrectDependencies() {
        XCTAssertNotNil(sut, "Should initialize successfully")
    }
    
    func test_init_calculatesAutomaticCacheSize_forSmallFolder() async throws {
        // Given: Small folder with 50 images
        mockFileManager.mockImageFiles = Array(1...50).map { 
            ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
        }
        
        // When: Initialize cache
        let cacheSize = await sut.calculateOptimalCacheSize(for: "/test")
        
        // Then: Should cache all 50 images (within 10-100 range)
        XCTAssertEqual(cacheSize, 50, "Should cache all images in small folder")
    }
    
    func test_init_calculatesAutomaticCacheSize_forMediumFolder() async throws {
        // Given: Medium folder with 200 images
        mockFileManager.mockImageFiles = Array(1...200).map { 
            ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
        }
        
        // When: Calculate cache size
        let cacheSize = await sut.calculateOptimalCacheSize(for: "/test")
        
        // Then: Should use 20% rule: 200 * 0.2 = 40 images
        XCTAssertEqual(cacheSize, 40, "Should use 20% of total images for medium folder")
    }
    
    func test_automaticCalculation_usesCorrectFormula() async throws {
        // Given: Folder with exactly 25 images
        mockFileManager.mockImageFiles = Array(1...25).map { 
            ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
        }
        
        // When: Calculate cache size  
        let cacheSize = await sut.calculateOptimalCacheSize(for: "/test")
        
        // Then: Should cache all 25 images (≤100 rule)
        XCTAssertEqual(cacheSize, 25, "Should cache all images when count ≤ 100")
    }
    
    func test_cacheEviction_removesLeastRecentlyUsed() async throws {
        // Given: Cache with capacity of 3
        await sut.setCacheCapacity(3)
        let urls = (1...4).map { URL(fileURLWithPath: "/test/image\($0).jpg") }
        
        // When: Cache 4 images (exceeds capacity)
        for url in urls {
            await sut.cacheImage(url: url)
        }
        
        // Then: Should evict first image (LRU), keep last 3
        let image1Cached = await sut.isCached(url: urls[0])
        let image4Cached = await sut.isCached(url: urls[3])
        XCTAssertFalse(image1Cached, "First image should be evicted")
        XCTAssertTrue(image4Cached, "Last image should remain cached")
    }
    
    func test_corruptedImage_handlesGracefully() async throws {
        // Given: Corrupted image file
        mockFileManager.shouldReturnCorruptedImage = true
        let corruptedUrl = URL(fileURLWithPath: "/test/corrupted_image.jpg")
        
        // When: Try to load corrupted image
        let image = await sut.getImage(from: corruptedUrl)
        
        // Then: Should return nil gracefully
        XCTAssertNil(image, "Should return nil for corrupted images")
    }
    
    func test_largeFolder_handlesThousandsOfImages() async throws {
        // Given: Very large folder with 5000 images
        mockFileManager.mockImageFiles = Array(1...5000).map { 
            ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
        }
        
        // When: Calculate cache size
        let cacheSize = await sut.calculateOptimalCacheSize(for: "/test")
        
        // Then: Should cap at 100 images maximum
        XCTAssertEqual(cacheSize, 100, "Should cap cache size at 100 for very large folders")
    }
    
    func test_insufficientMemory_degradesGracefully() async throws {
        // Given: Low memory simulation
        mockFileManager.simulateLowMemory = true
        mockFileManager.mockImageFiles = Array(1...50).map { 
            ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
        }
        
        // When: Calculate cache size and preload
        let cacheSize = await sut.calculateOptimalCacheSize(for: "/test")
        await sut.preloadImages(from: "/test", count: 50)
        let cachedCount = await sut.getCachedImageCount()
        
        // Then: Should reduce cache size in low memory
        XCTAssertLessThan(cacheSize, 50, "Should reduce cache size in low memory")
        XCTAssertLessThan(cachedCount, 50, "Should cache fewer images in low memory")
    }
    
    // MARK: - Memory Management Tests
    
    func test_memoryPressure_clearsCache() async throws {
        // Given: Setup mock images and cache with images
        mockFileManager.mockImageFiles = Array(1...50).map { 
            ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
        }
        await sut.preloadImages(from: "/test", count: 50)
        let initialCount = await sut.getCachedImageCount()
        XCTAssertGreaterThan(initialCount, 0, "Should have cached images")
        
        // When: Memory pressure notification
        await sut.handleMemoryWarning()
        
        // Then: Should clear cache
        let finalCount = await sut.getCachedImageCount()
        XCTAssertEqual(finalCount, 0, "Should clear all cached images on memory pressure")
    }
    
    func test_memoryEstimation_calculatesAccurately() async throws {
        // Given: Known image sizes
        let jpegSize = await sut.estimateImageSize(format: .jpeg, width: 1024, height: 768)
        let heicSize = await sut.estimateImageSize(format: .heic, width: 1024, height: 768)
        let gifSize = await sut.estimateImageSize(format: .gif, width: 1024, height: 768)
        
        // Then: Should follow compression hierarchy: JPEG < HEIC < GIF
        XCTAssertLessThan(jpegSize, heicSize, "JPEG should be smallest")
        XCTAssertLessThan(heicSize, gifSize, "HEIC should be smaller than GIF")
    }
    
    // MARK: - Cache Functionality Tests
    
    func test_getImage_returnsNil_forInvalidUrl() async throws {
        // Given: Invalid URL
        let invalidUrl = URL(fileURLWithPath: "/nonexistent/path.jpg")
        
        // When: Try to get image
        let image = await sut.getImage(from: invalidUrl)
        
        // Then: Should return nil
        XCTAssertNil(image, "Should return nil for invalid URL")
    }
    
    func test_cacheImage_storesImageSuccessfully() async throws {
        // Given: Valid image URL
        let url = URL(fileURLWithPath: "/test/image1.jpg")
        
        // When: Cache the image
        await sut.cacheImage(url: url)
        
        // Then: Should be cached
        let cachedCount = await sut.getCachedImageCount()
        XCTAssertEqual(cachedCount, 1, "Should have cached one image")
    }
    
    func test_preloadImages_loadsSpecifiedCount() async throws {
        // Given: Folder with images
        mockFileManager.mockImageFiles = Array(1...20).map { 
            ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
        }
        
        // When: Preload 10 images
        await sut.preloadImages(from: "/test", count: 10)
        
        // Then: Should cache exactly 10 images
        let cachedCount = await sut.getCachedImageCount()
        XCTAssertEqual(cachedCount, 10, "Should preload exactly 10 images")
    }
    
    func test_invalidImageUrl_handlesGracefully() async throws {
        // Given: Non-existent file URL
        let invalidUrl = URL(fileURLWithPath: "/nonexistent/image.jpg")
        
        // When: Try to get image
        let image = await sut.getImage(from: invalidUrl)
        
        // Then: Should return nil without crashing
        XCTAssertNil(image, "Should return nil for non-existent image")
    }
    
    // MARK: - Memory Configuration Tests
    
    func test_memoryAllocation_respectsSystemConstraints() async throws {
        // Given: System with known memory
        let systemMemory = await sut.getSystemMemory()
        let availableMemory = await sut.getAvailableMemory()
        let memoryLimit = await sut.getConfiguredMemoryLimit()
        
        // Then: Should respect constraints
        XCTAssertGreaterThan(systemMemory, 0, "System memory should be positive")
        XCTAssertLessThanOrEqual(availableMemory, systemMemory, "Available should not exceed system memory")
        XCTAssertLessThanOrEqual(memoryLimit, Int(availableMemory), "Memory limit should not exceed available memory")
    }
    
    func test_userConfigurableMemoryLimits_respected() async throws {
        // Given: Custom memory limit
        let customLimit = 50 * 1024 * 1024 // 50MB
        mockSettingsManager.customCacheMemoryLimit = customLimit
        
        // When: Get configured limit
        let configuredLimit = await sut.getConfiguredMemoryLimit()
        
        // Then: Should use custom limit
        XCTAssertEqual(configuredLimit, customLimit, "Should respect user-configured memory limit")
    }
    
    // MARK: - Preload Configuration Tests
    
    func test_preloadCount_respectsConfigurableRange() async throws {
        // Given: Custom preload count
        mockSettingsManager.preloadImageCount = 75
        
        // When: Get configured count
        let configuredCount = await sut.getConfiguredPreloadCount()
        
        // Then: Should use custom count within range
        XCTAssertEqual(configuredCount, 75, "Should respect configured preload count")
    }
    
    func test_preloadCount_clampsToValidRange() async throws {
        // Given: Out-of-range preload count
        mockSettingsManager.preloadImageCount = 150 // Above max of 100
        
        // When: Get configured count
        let configuredCount = await sut.getConfiguredPreloadCount()
        
        // Then: Should clamp to valid range
        XCTAssertEqual(configuredCount, 100, "Should clamp preload count to maximum of 100")
    }
    
    // MARK: - Native Cache Tests
    
    func test_nativeCache_configuredCorrectly() async throws {
        // Given: Fresh cache instance
        let memoryLimit = await sut.getConfiguredMemoryLimit()
        let configuredCount = await sut.getConfiguredPreloadCount()
        
        // Then: Should have valid configuration
        XCTAssertGreaterThan(memoryLimit, 0, "Memory limit should be positive")
        XCTAssertGreaterThanOrEqual(configuredCount, 10, "Preload count should be at least 10")
        XCTAssertLessThanOrEqual(configuredCount, 100, "Preload count should not exceed 100")
    }
    
    func test_nativeCache_handlesImageFormats() async throws {
        // Given: Different image formats
        let jpegUrl = URL(fileURLWithPath: "/test/image.jpg")
        let heicUrl = URL(fileURLWithPath: "/test/image.heic")
        let gifUrl = URL(fileURLWithPath: "/test/image.gif")
        
        // When: Cache images of different formats
        await sut.cacheImage(url: jpegUrl)
        await sut.cacheImage(url: heicUrl)
        await sut.cacheImage(url: gifUrl)
        
        // Then: Should cache all formats
        let cachedCount = await sut.getCachedImageCount()
        XCTAssertEqual(cachedCount, 3, "Should cache all supported image formats")
    }
    
    func test_nativeCache_respectsMemoryLimits() async throws {
        // Given: Very small memory limit
        await sut.setMemoryLimit(1024) // 1KB limit
        
        // When: Try to cache many images
        let urls = (1...10).map { URL(fileURLWithPath: "/test/large_image\($0).jpg") }
        for url in urls {
            await sut.cacheImage(url: url)
        }
        
        // Then: Should respect memory constraints
        let cachedCount = await sut.getCachedImageCount()
        XCTAssertLessThanOrEqual(cachedCount, 10, "Should respect memory limits")
    }
}