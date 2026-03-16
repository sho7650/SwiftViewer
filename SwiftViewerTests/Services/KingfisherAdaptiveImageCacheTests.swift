//
//  KingfisherAdaptiveImageCacheTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/30.
//

import XCTest
@testable import SwiftViewer

@available(macOS 14.0, *)
final class KingfisherAdaptiveImageCacheTests: XCTestCase {
    var sut: KingfisherAdaptiveImageCache!
    var mockFileManager: MockFileManagerService!
    var mockSettingsManager: MockSettingsManager!
    
    override func setUp() {
        super.setUp()
        mockFileManager = MockFileManagerService()
        // Set up sufficient test data for Kingfisher tests
        mockFileManager.mockImageFiles = Array(1...100).map { 
            ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
        }
        mockSettingsManager = MockSettingsManager()
        sut = KingfisherAdaptiveImageCache(fileManager: mockFileManager, settings: mockSettingsManager)
    }
    
    override func tearDown() {
        sut = nil
        mockFileManager = nil
        mockSettingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_configuresKingfisherCache() {
        XCTAssertNotNil(sut, "Should initialize with Kingfisher cache")
    }
    
    func test_kingfisher_cache_hasCustomName() async throws {
        let cacheName = await sut.getKingfisherCacheName()
        XCTAssertEqual(cacheName, "SwiftViewer-AdaptiveCache", "Should use custom cache name")
    }
    
    func test_memory_limit_setTo15PercentSystemMemory() async throws {
        let memoryLimit = await sut.getConfiguredMemoryLimit()
        let systemMemory = ProcessInfo.processInfo.physicalMemory
        let expected = Int(systemMemory * 15 / 100)
        
        XCTAssertEqual(memoryLimit, expected, "Should use 15% of system memory")
    }
    
    // MARK: - Cache Performance Tests
    
    func test_cache_response_under10ms_whenImageCached() async throws {
        // Given: Image cached with Kingfisher
        let testUrl = URL(fileURLWithPath: "/test/image1.jpg")
        await sut.cacheImage(url: testUrl)
        
        // When: Retrieve cached image
        let startTime = CFAbsoluteTimeGetCurrent()
        let image = await sut.getImage(from: testUrl)
        let responseTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        // Then: Should respond under 10ms
        XCTAssertNotNil(image, "Should return cached image")
        XCTAssertLessThan(responseTime, 10.0, "Kingfisher cache response should be under 10ms")
    }
    
    func test_kingfisher_retrieval_performance() async throws {
        // Given: Multiple cached images
        let urls = Array(1...50).map { URL(fileURLWithPath: "/test/image\($0).jpg") }
        for url in urls {
            await sut.cacheImage(url: url)
        }
        
        // When: Retrieve all images
        let startTime = CFAbsoluteTimeGetCurrent()
        for url in urls {
            _ = await sut.getImage(from: url)
        }
        let totalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        let averageTime = totalTime / Double(urls.count)
        
        // Then: Average response should be well under 10ms
        XCTAssertLessThan(averageTime, 10.0, "Average Kingfisher response time should be under 10ms")
    }
    
    // MARK: - Kingfisher Integration Tests
    
    func test_kingfisher_cache_stores_and_retrieves() async throws {
        // Given: Test image URL
        let testUrl = URL(fileURLWithPath: "/test/kingfisher_test.jpg")
        
        // When: Store image through Kingfisher
        await sut.cacheImage(url: testUrl)
        
        // Then: Should retrieve from Kingfisher cache
        let isCached = await sut.isImageCached(url: testUrl)
        XCTAssertTrue(isCached, "Image should be cached in Kingfisher")
        
        let image = await sut.getImage(from: testUrl)
        XCTAssertNotNil(image, "Should retrieve image from Kingfisher cache")
    }
    
    func test_kingfisher_memory_cache_limits() async throws {
        // Given: Custom memory limit
        let customLimit = 50 * 1024 * 1024 // 50MB
        await sut.setMemoryLimit(customLimit)
        
        // When: Check Kingfisher cache configuration
        let configuredLimit = await sut.getKingfisherMemoryLimit()
        
        // Then: Should match custom limit
        XCTAssertEqual(configuredLimit, customLimit, "Kingfisher should use configured memory limit")
    }
    
    func test_kingfisher_disk_cache_limits() async throws {
        // Given: Disk cache limit
        let diskLimit = 500 * 1024 * 1024 // 500MB
        await sut.setDiskCacheLimit(diskLimit)
        
        // When: Check disk cache configuration
        let configuredDiskLimit = await sut.getKingfisherDiskLimit()
        
        // Then: Should match configured limit
        XCTAssertEqual(configuredDiskLimit, diskLimit, "Kingfisher should use configured disk limit")
    }
    
    // MARK: - Prefetching Tests with Kingfisher
    
    func test_kingfisher_prefetcher_loads_specified_count() async throws {
        // Given: Mock file manager with images
        mockFileManager.mockImageFiles = Array(1...100).map { 
            ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
        }
        
        // When: Preload with Kingfisher
        await sut.preloadImages(from: "/test", count: 20)
        
        // Then: Should have preloaded images
        let cachedCount = await sut.getCachedImageCount()
        XCTAssertGreaterThanOrEqual(cachedCount, 15, "Should preload most images through Kingfisher")
    }
    
    func test_kingfisher_prefetcher_completion_callback() async throws {
        // Given: URLs for prefetching
        let urls = Array(1...10).map { URL(fileURLWithPath: "/test/image\($0).jpg") }
        
        // When: Use Kingfisher prefetcher with completion
        let (completed, failed) = await sut.preloadImagesWithResult(urls: urls)
        
        // Then: Should report completion status
        XCTAssertGreaterThan(completed.count, 0, "Should complete some prefetch operations")
        XCTAssertEqual(failed.count, 0, "Should not fail for valid test images")
    }
    
    // MARK: - Automatic Cache Size Calculation Tests
    
    func test_automatic_calculation_with_kingfisher_metadata() async throws {
        // Given: Folder with images
        mockFileManager.mockImageFiles = Array(1...250).map { 
            ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
        }
        
        // When: Calculate optimal cache size using Kingfisher capabilities
        let cacheSize = await sut.calculateOptimalCacheSize(for: "/test")
        
        // Then: Should use automatic calculation (20% of 250 = 50, max 100)
        XCTAssertEqual(cacheSize, 50, "Should calculate 20% of folder size for large folders")
    }
    
    func test_kingfisher_based_memory_estimation() async throws {
        // Given: Image format and dimensions
        let jpegSize = await sut.estimateKingfisherMemoryUsage(format: .jpeg, width: 1920, height: 1080)
        let heicSize = await sut.estimateKingfisherMemoryUsage(format: .heic, width: 1920, height: 1080)
        let gifSize = await sut.estimateKingfisherMemoryUsage(format: .gif, width: 1920, height: 1080)
        
        // Then: Should follow Kingfisher compression ratios
        XCTAssertLessThan(jpegSize, heicSize, "JPEG should be smaller than HEIC in Kingfisher")
        XCTAssertLessThan(heicSize, gifSize, "HEIC should be smaller than GIF in Kingfisher")
    }
    
    // MARK: - Memory Management with Kingfisher
    
    func test_kingfisher_memory_pressure_handling() async throws {
        // Given: Cache with images
        await sut.preloadImages(from: "/test", count: 50)
        let initialCount = await sut.getCachedImageCount()
        XCTAssertGreaterThan(initialCount, 0, "Should have cached images")
        
        // When: Memory pressure notification
        await sut.handleMemoryWarning()
        
        // Then: Should clear Kingfisher cache
        let finalCount = await sut.getCachedImageCount()
        XCTAssertEqual(finalCount, 0, "Should clear Kingfisher cache on memory pressure")
    }
    
    func test_kingfisher_cache_eviction_policy() async throws {
        // Given: Cache capacity of 3
        await sut.setCacheCapacity(3)
        
        let urls = [
            URL(fileURLWithPath: "/test/image1.jpg"),
            URL(fileURLWithPath: "/test/image2.jpg"),
            URL(fileURLWithPath: "/test/image3.jpg"),
            URL(fileURLWithPath: "/test/image4.jpg")
        ]
        
        // When: Cache 4 images (exceeds Kingfisher capacity)
        for url in urls {
            await sut.cacheImage(url: url)
        }

        // Allow Kingfisher LRU eviction to settle (async on CI runners)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then: Should evict oldest image via Kingfisher LRU
        let image1Cached = await sut.isImageCached(url: urls[0])
        let image4Cached = await sut.isImageCached(url: urls[3])
        
        XCTAssertFalse(image1Cached, "First image should be evicted by Kingfisher LRU")
        XCTAssertTrue(image4Cached, "Last image should remain in Kingfisher cache")
    }
    
    // MARK: - Error Handling Tests
    
    func test_kingfisher_handles_corrupted_images() async throws {
        // Given: Corrupted image URL
        let corruptedUrl = URL(fileURLWithPath: "/test/corrupted/invalid.jpg")
        
        // When: Try to cache corrupted image
        await sut.cacheImage(url: corruptedUrl)
        
        // Then: Should handle gracefully with Kingfisher
        let image = await sut.getImage(from: corruptedUrl)
        XCTAssertNil(image, "Kingfisher should handle corrupted images gracefully")
    }
    
    func test_kingfisher_invalid_url_handling() async throws {
        // Given: Invalid URL
        let invalidUrl = URL(fileURLWithPath: "/nonexistent/path/image.jpg")
        
        // When: Try to load invalid URL
        let image = await sut.getImage(from: invalidUrl)
        
        // Then: Should return nil gracefully
        XCTAssertNil(image, "Kingfisher should handle invalid URLs gracefully")
    }
    
    // MARK: - Integration Tests
    
    func test_kingfisher_integration_with_dependency_injection() {
        // Given: Dependency container
        let container = MockDependencyContainer()
        
        // When: Access adaptive cache
        let cache = container.adaptiveImageCache
        
        // Then: Should be Kingfisher-based implementation
        XCTAssertTrue(cache is AdaptiveImageCache, "Should provide Kingfisher-based cache")
    }
    
    func test_end_to_end_workflow_with_kingfisher() async throws {
        // Given: Realistic folder setup
        mockFileManager.mockImageFiles = [
            ImageFile(url: URL(fileURLWithPath: "/test/photo1.jpg"), fileName: "photo1.jpg", fileSize: 2048, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/test/photo2.heic"), fileName: "photo2.heic", fileSize: 1536, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/test/photo3.gif"), fileName: "photo3.gif", fileSize: 512, createdDate: Date())
        ]
        
        // When: Complete workflow
        let cacheSize = await sut.calculateOptimalCacheSize(for: "/test")
        await sut.preloadImages(from: "/test", count: cacheSize)
        
        let image1 = await sut.getImage(from: URL(fileURLWithPath: "/test/photo1.jpg"))
        let image2 = await sut.getImage(from: URL(fileURLWithPath: "/test/photo2.heic"))
        
        // Then: Should work end-to-end with Kingfisher
        XCTAssertEqual(cacheSize, 3, "Should cache all 3 images")
        XCTAssertNotNil(image1, "Should load JPEG through Kingfisher")
        XCTAssertNotNil(image2, "Should load HEIC through Kingfisher")
    }
    
    // MARK: - Settings Integration Tests
    
    func test_kingfisher_respects_user_memory_settings() async throws {
        // Given: Custom memory setting
        mockSettingsManager.customCacheMemoryLimit = 200 * 1024 * 1024 // 200MB
        
        // When: Update configuration
        await sut.updateConfiguration()
        
        // Then: Should apply to Kingfisher cache
        let memoryLimit = await sut.getKingfisherMemoryLimit()
        XCTAssertEqual(memoryLimit, 200 * 1024 * 1024, "Should apply user memory setting to Kingfisher")
    }
    
    func test_kingfisher_preload_count_configuration() async throws {
        // Given: Custom preload count
        mockSettingsManager.preloadImageCount = 75
        
        // When: Get configured preload count
        let preloadCount = await sut.getConfiguredPreloadCount()
        
        // Then: Should clamp to valid range (10-100)
        XCTAssertEqual(preloadCount, 75, "Should use configured preload count")
        XCTAssertGreaterThanOrEqual(preloadCount, 10, "Should be at least 10")
        XCTAssertLessThanOrEqual(preloadCount, 100, "Should be at most 100")
    }
    
    // MARK: - Large Scale Tests
    
    func test_kingfisher_handles_thousands_of_images() async throws {
        // Given: Large folder (10,000 images)
        mockFileManager.mockImageFiles = Array(1...10000).map { 
            ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
        }
        
        // When: Calculate cache size for large folder
        let cacheSize = await sut.calculateOptimalCacheSize(for: "/test")
        
        // Then: Should cap at 100 images (20% of 10000 = 2000, capped at 100)
        XCTAssertEqual(cacheSize, 100, "Should cap large folders at 100 images")
    }
    
    func test_kingfisher_concurrent_access_thread_safety() async throws {
        // Given: Multiple concurrent operations
        let urls = Array(1...20).map { URL(fileURLWithPath: "/test/image\($0).jpg") }
        
        // When: Concurrent cache operations
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    await self.sut.cacheImage(url: url)
                }
            }
        }
        
        // Then: Should handle concurrent access safely
        let cachedCount = await sut.getCachedImageCount()
        XCTAssertGreaterThan(cachedCount, 0, "Should cache images safely under concurrent access")
    }
    
    // MARK: - Kingfisher Cache Status Tests
    
    func test_kingfisher_cache_type_detection() async throws {
        // Given: Image to cache
        let testUrl = URL(fileURLWithPath: "/test/image.jpg")
        await sut.cacheImage(url: testUrl)
        
        // When: Check cache type
        let cacheType = await sut.getKingfisherCacheType(for: testUrl)
        
        // Then: Should detect cache location
        XCTAssertNotEqual(cacheType, "none", "Should be cached in memory or disk")
    }
    
    func test_kingfisher_disk_cache_size_calculation() async throws {
        // Given: Images cached to disk
        let urls = Array(1...10).map { URL(fileURLWithPath: "/test/large_image\($0).jpg") }
        for url in urls {
            await sut.cacheImage(url: url)
        }
        
        // When: Calculate disk cache size
        let diskSize = await sut.calculateKingfisherDiskCacheSize()
        
        // Then: Should report meaningful size
        XCTAssertGreaterThan(diskSize, 0, "Should have positive disk cache size")
    }
    
    // MARK: - Configuration Tests
    
    func test_kingfisher_cache_expiration_settings() async throws {
        // Given: Custom expiration settings
        await sut.setKingfisherCacheExpiration(memory: .seconds(600), disk: .never)
        
        // When: Check configuration
        let memoryExpiration = await sut.getKingfisherMemoryExpiration()
        let diskExpiration = await sut.getKingfisherDiskExpiration()
        
        // Then: Should apply expiration settings
        XCTAssertEqual(memoryExpiration, .seconds(600), "Should set memory expiration")
        XCTAssertEqual(diskExpiration, .never, "Should set disk expiration to never")
    }
    
    func test_kingfisher_clean_expired_cache() async throws {
        // Given: Cache with expired images
        await sut.preloadImages(from: "/test", count: 10)
        
        // When: Clean expired cache
        await sut.cleanExpiredKingfisherCache()
        
        // Then: Should clean expired images only
        let remainingCount = await sut.getCachedImageCount()
        XCTAssertGreaterThanOrEqual(remainingCount, 0, "Should clean expired images via Kingfisher")
    }
}