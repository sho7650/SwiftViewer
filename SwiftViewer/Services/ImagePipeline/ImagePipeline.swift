//
//  ImagePipeline.swift
//  SwiftViewer
//
//  Actor-isolated image cache + preloader over ImageIO downsampling.
//

import Foundation
import CoreGraphics

/// Boxes a `CGImage` so it can be stored in `NSCache`, which requires class values.
private final class CGImageBox {
    let image: CGImage
    let cost: Int

    init(_ image: CGImage) {
        self.image = image
        self.cost = image.width * image.height * 4 // bytes for RGBA
    }
}

actor ImagePipeline: ImagePipelineProtocol {
    private let cache = NSCache<NSURL, CGImageBox>()
    private var inFlight: [URL: Task<CGImage, Error>] = [:]

    private let maxConcurrentDecodes = 4

    /// - Parameters:
    ///   - memoryLimitPercentage: share of physical memory the cache may use (1–50).
    ///   - countLimit: maximum number of cached images.
    init(memoryLimitPercentage: Double, countLimit: Int) {
        let fraction = max(1.0, min(50.0, memoryLimitPercentage)) / 100.0
        cache.totalCostLimit = Int(Double(ProcessInfo.processInfo.physicalMemory) * fraction)
        cache.countLimit = max(1, countLimit)
    }

    func image(for url: URL, maxPixelSize: CGFloat) async throws -> DecodedImage {
        if let cached = cache.object(forKey: url as NSURL) {
            return DecodedImage(cgImage: cached.image)
        }

        let task: Task<CGImage, Error>
        if let existing = inFlight[url] {
            task = existing
        } else {
            task = Task.detached(priority: .userInitiated) {
                try ImageDownsampler.downsample(url: url, maxPixelSize: maxPixelSize)
            }
            inFlight[url] = task
        }

        defer { inFlight[url] = nil }
        let cgImage = try await task.value
        cache.setObject(CGImageBox(cgImage), forKey: url as NSURL)
        return DecodedImage(cgImage: cgImage)
    }

    func preload(_ urls: [URL], maxPixelSize: CGFloat) async {
        let pending = urls.filter { cache.object(forKey: $0 as NSURL) == nil }
        guard !pending.isEmpty else { return }

        for chunk in pending.chunked(into: maxConcurrentDecodes) {
            if Task.isCancelled { return }
            await withTaskGroup(of: Void.self) { group in
                for url in chunk {
                    group.addTask { [weak self] in
                        _ = try? await self?.image(for: url, maxPixelSize: maxPixelSize)
                    }
                }
            }
        }
    }

    func reset() {
        for task in inFlight.values {
            task.cancel()
        }
        inFlight.removeAll()
        cache.removeAllObjects()
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
