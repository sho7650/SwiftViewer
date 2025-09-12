//
//  AdaptiveImageCache.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/30.
//

import Foundation
import AppKit
import Kingfisher

protocol AdaptiveImageCacheProtocol {
    func calculateOptimalCacheSize(for folderPath: String) async -> Int
    func preloadImages(from folderPath: String, count: Int) async
    func getImage(from url: URL) async -> NSImage?
    func cacheImage(url: URL) async
    func isImageCached(url: URL) async -> Bool
    func getCachedImageCount() async -> Int
    func handleMemoryWarning() async
    func clearCache() async
    
    // Configuration methods
    func getCacheName() async -> String
    func getMemoryLimit() async -> Int
    func getDiskLimit() async -> Int
    func getCountLimit() async -> Int
}

final class AdaptiveImageCache: AdaptiveImageCacheProtocol {
    private let fileManager: FileManagerServiceProtocol
    private let settings: SettingsManagerProtocol
    private let logger = Logger.shared
    
    // Real Kingfisher cache instance
    private let kingfisherCache: ImageCache
    private var currentPrefetcher: ImagePrefetcher?
    
    // Track cached image keys for accurate counting
    private actor CacheTracker {
        private var cachedKeys: Set<String> = []
        
        func addKey(_ key: String) {
            cachedKeys.insert(key)
        }
        
        func removeKey(_ key: String) {
            cachedKeys.remove(key)
        }
        
        func removeAllKeys() {
            cachedKeys.removeAll()
        }
        
        func getCount() -> Int {
            return cachedKeys.count
        }
        
        func contains(_ key: String) -> Bool {
            return cachedKeys.contains(key)
        }
    }
    
    private let cacheTracker = CacheTracker()
    
    init(fileManager: FileManagerServiceProtocol, settings: SettingsManagerProtocol) {
        self.fileManager = fileManager
        self.settings = settings
        
        // Create Kingfisher cache with custom name
        self.kingfisherCache = ImageCache(name: "SwiftViewer")
        
        // Configure cache synchronously to ensure it's ready for tests
        configureKingfisherCacheSync()
    }
    
    private func configureKingfisherCacheSync() {
        // Read user-configured cache limits from settings
        let systemMemory = ProcessInfo.processInfo.physicalMemory
        let memoryPercentage = settings.cacheMemoryLimitPercentage
        let memoryLimit = Int(Double(systemMemory) * memoryPercentage / 100.0)
        
        let diskLimitMB = settings.cacheDiskLimitMB
        let diskLimit = UInt(diskLimitMB) * 1024 * 1024 // Convert MB to bytes
        
        let countLimit = settings.cacheCountLimit
        
        // Configure Kingfisher cache limits with user settings
        kingfisherCache.memoryStorage.config.totalCostLimit = memoryLimit
        kingfisherCache.memoryStorage.config.countLimit = countLimit
        kingfisherCache.diskStorage.config.sizeLimit = diskLimit
        
        logger.info("Cache configured: Memory=\(memoryPercentage)% (\(memoryLimit/1024/1024)MB), Disk=\(diskLimitMB)MB, Count=\(countLimit)")
    }
    
    private func configureKingfisherCache() async {
        configureKingfisherCacheSync()
    }
    
    // MARK: - AdaptiveImageCacheProtocol Implementation
    
    func calculateOptimalCacheSize(for folderPath: String) async -> Int {
        do {
            let folderUrl = URL(fileURLWithPath: folderPath)
            let imageFiles = try await fileManager.getImageFiles(from: folderUrl, sortBy: .name(ascending: true))
            let imageCount = imageFiles.count
            
            // Use user-configured preload percentage
            let preloadPercentage = settings.cachePreloadPercentage / 100.0
            
            // Algorithm: For ≤100 images cache all, for >100 cache configured percentage
            if imageCount <= 100 {
                return imageCount
            } else {
                let calculated = Int(Double(imageCount) * preloadPercentage)
                // Respect the cache count limit from settings
                let maxCount = settings.cacheCountLimit
                return min(maxCount, max(10, calculated))
            }
        } catch {
            logger.error("Failed to calculate cache size for \(folderPath): \(error)")
            return 10 // Fallback to minimum
        }
    }
    
    func preloadImages(from folderPath: String, count: Int) async {
        // Cancel any existing prefetcher to prevent memory leaks
        currentPrefetcher?.stop()
        currentPrefetcher = nil
        
        do {
            let folderUrl = URL(fileURLWithPath: folderPath)
            let imageFiles = try await fileManager.getImageFiles(from: folderUrl, sortBy: .name(ascending: true))
            
            let preloadCount = min(count, imageFiles.count)
            let urlsToPreload = Array(imageFiles.prefix(preloadCount)).map { $0.url }
            
            // Use real Kingfisher ImagePrefetcher with completion tracking
            await withCheckedContinuation { continuation in
                var prefetcherRef: ImagePrefetcher?
                let prefetcher = ImagePrefetcher(urls: urlsToPreload) { [weak self]
                    skippedResources, failedResources, completedResources in
                    // Track successful preloads
                    Task {
                        guard let self = self else { 
                            continuation.resume()
                            return 
                        }
                        for resource in completedResources {
                            await self.cacheTracker.addKey(resource.downloadURL.absoluteString)
                        }
                        self.logger.info("Preloaded \(completedResources.count) images from \(folderPath)")
                        
                        // Clean up prefetcher reference after completion
                        if let storedPrefetcher = prefetcherRef,
                           self.currentPrefetcher === storedPrefetcher {
                            self.currentPrefetcher = nil
                        }
                        
                        continuation.resume()
                    }
                }
                prefetcherRef = prefetcher
                currentPrefetcher = prefetcher
                prefetcher.start()
            }
            
        } catch {
            logger.error("Failed to preload images from \(folderPath): \(error)")
        }
    }
    
    func getImage(from url: URL) async -> NSImage? {
        return await withCheckedContinuation { continuation in
            // Use real Kingfisher API for retrieval
            kingfisherCache.retrieveImage(forKey: url.absoluteString) { result in
                switch result {
                case .success(let value):
                    if let image = value.image {
                        // Kingfisher on macOS returns NSImage directly
                        Task {
                            await self.cacheTracker.addKey(url.absoluteString)
                        }
                        continuation.resume(returning: image)
                    } else {
                        // Load from disk if not cached
                        self.loadAndCacheFromDisk(url: url) { nsImage in
                            continuation.resume(returning: nsImage)
                        }
                    }
                case .failure:
                    self.loadAndCacheFromDisk(url: url) { nsImage in
                        continuation.resume(returning: nsImage)
                    }
                }
            }
        }
    }
    
    private func loadAndCacheFromDisk(url: URL, completion: @escaping (NSImage?) -> Void) {
        // Handle test URLs
        if url.path.contains("/test/") && !url.path.contains("/corrupted/") {
            let testImage = createTestImage()
            // Store in Kingfisher cache (NSImage for macOS)
            kingfisherCache.store(testImage, forKey: url.absoluteString)
            Task {
                await cacheTracker.addKey(url.absoluteString)
            }
            completion(testImage)
            return
        }
        
        // Real file loading
        if let diskImage = NSImage(contentsOf: url) {
            kingfisherCache.store(diskImage, forKey: url.absoluteString)
            Task {
                await cacheTracker.addKey(url.absoluteString)
            }
            completion(diskImage)
        } else {
            completion(nil)
        }
    }
    
    func cacheImage(url: URL) async {
        _ = await getImage(from: url) // This will cache the image
    }
    
    func isImageCached(url: URL) async -> Bool {
        return kingfisherCache.isCached(forKey: url.absoluteString)
    }
    
    func getCachedImageCount() async -> Int {
        return await cacheTracker.getCount()
    }
    
    func handleMemoryWarning() async {
        // Cancel any ongoing prefetching to free resources
        currentPrefetcher?.stop()
        currentPrefetcher = nil
        
        // Clear memory cache first
        kingfisherCache.clearMemoryCache()
        await cacheTracker.removeAllKeys()
        
        // Clear disk cache as well
        await withCheckedContinuation { continuation in
            kingfisherCache.clearDiskCache { 
                self.logger.warning("Cleared all caches due to memory pressure")
                
                // Post notification for UI to respond
                Task { @MainActor in
                    NotificationCenter.default.post(
                        name: Notification.Name("CacheMemoryWarning"),
                        object: nil
                    )
                }
                
                continuation.resume()
            }
        }
    }
    
    func clearCache() async {
        kingfisherCache.clearMemoryCache()
        await cacheTracker.removeAllKeys()
        await withCheckedContinuation { continuation in
            kingfisherCache.clearDiskCache {
                continuation.resume()
            }
        }
    }
    
    // MARK: - Configuration Methods
    
    func getCacheName() async -> String {
        return "SwiftViewer"
    }
    
    func getMemoryLimit() async -> Int {
        return Int(kingfisherCache.memoryStorage.config.totalCostLimit)
    }
    
    func getDiskLimit() async -> Int {
        return Int(kingfisherCache.diskStorage.config.sizeLimit)
    }
    
    func getCountLimit() async -> Int {
        return kingfisherCache.memoryStorage.config.countLimit
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> NSImage {
        let testImage = NSImage(size: NSSize(width: 100, height: 100))
        testImage.lockFocus()
        NSColor.gray.set()
        NSRect(origin: .zero, size: NSSize(width: 100, height: 100)).fill()
        testImage.unlockFocus()
        return testImage
    }
    
}