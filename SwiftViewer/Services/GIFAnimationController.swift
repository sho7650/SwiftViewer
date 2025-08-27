import Foundation
import SwiftUI
import ImageIO
import Combine

/// A comprehensive GIF animation controller that implements SwiftUI's CustomAnimation protocol
/// for seamless integration with Context7 animation patterns
final class GIFAnimationController: ObservableObject, CustomAnimation {
    
    // MARK: - Published Properties
    
    @Published var currentFrameIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var playbackSpeed: Double = 1.0
    
    // MARK: - Private Properties
    
    let animatedImage: AnimatedImage
    private var animationTimer: Timer?
    private var startTime: CFTimeInterval = 0
    private var lastFrameTime: CFTimeInterval = 0
    private var frameCache: FrameCache
    private let logger = Logger.shared
    
    // Animation state for CustomAnimation protocol
    private var animationStartTime: TimeInterval = 0
    private var hasFinished: Bool = false
    
    // MARK: - Initialization
    
    init(animatedImage: AnimatedImage) throws {
        guard !animatedImage.frames.isEmpty else {
            throw GIFAnimationError.emptyFrames
        }
        
        guard animatedImage.frames.count == animatedImage.frameDurations.count else {
            throw GIFAnimationError.mismatchedFramesAndDurations
        }
        
        self.animatedImage = animatedImage
        self.frameCache = FrameCache(capacity: min(100, animatedImage.frameCount * 2))
        
        // Pre-cache first few frames
        preCacheFrames(startingAt: 0, count: min(5, animatedImage.frameCount))
    }
    
    // MARK: - Animation Control Methods
    
    func play() {
        guard !animatedImage.frames.isEmpty else { return }
        
        isPlaying = true
        startAnimationTimer()
        logger.debug("GIF animation started")
    }
    
    func pause() {
        isPlaying = false
        stopAnimationTimer()
        logger.debug("GIF animation paused")
    }
    
    func stop() {
        isPlaying = false
        currentFrameIndex = 0
        stopAnimationTimer()
        logger.debug("GIF animation stopped")
    }
    
    // MARK: - Frame Navigation
    
    func nextFrame() {
        currentFrameIndex = (currentFrameIndex + 1) % animatedImage.frameCount
        preCacheFrames(startingAt: currentFrameIndex, count: 3)
    }
    
    func previousFrame() {
        currentFrameIndex = currentFrameIndex == 0 ? animatedImage.frameCount - 1 : currentFrameIndex - 1
        preCacheFrames(startingAt: currentFrameIndex, count: 3)
    }
    
    // MARK: - Current Image Access
    
    var currentImage: NSImage? {
        guard currentFrameIndex >= 0 && currentFrameIndex < animatedImage.frameCount else {
            return nil
        }
        
        // Check cache first
        if let cachedImage = frameCache.get(key: currentFrameIndex) {
            return cachedImage
        }
        
        // Get from animated image and cache it
        if let image = animatedImage.frame(at: currentFrameIndex) {
            frameCache.set(key: currentFrameIndex, value: image)
            return image
        }
        
        return nil
    }
    
    // MARK: - Playback Speed Control
    
    func setPlaybackSpeed(_ speed: Double) {
        playbackSpeed = max(0.1, min(5.0, speed)) // Clamp to valid range
        logger.debug("GIF playback speed set to: \(playbackSpeed)")
    }
    
    // MARK: - Memory Management
    
    func clearFrameCache() {
        frameCache.removeAll()
        logger.debug("GIF frame cache cleared")
    }
    
    // MARK: - Private Methods
    
    private func startAnimationTimer() {
        guard animationTimer == nil else { return }
        
        startTime = CACurrentMediaTime()
        lastFrameTime = startTime
        
        // Use a high frequency timer for smooth animation
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func stopAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateAnimation() {
        guard isPlaying else { return }
        
        let currentTime = CACurrentMediaTime()
        let elapsed = (currentTime - lastFrameTime) * playbackSpeed
        
        guard let frameDuration = animatedImage.duration(at: currentFrameIndex) else { return }
        
        if elapsed >= frameDuration {
            nextFrame()
            lastFrameTime = currentTime
            
            // Check for animation completion (non-infinite loops)
            if !animatedImage.isInfiniteLoop {
                let cycleTime = currentTime - startTime
                let totalCycles = cycleTime / (animatedImage.totalDuration / playbackSpeed)
                
                if totalCycles >= Double(animatedImage.loopCount) {
                    stop()
                    hasFinished = true
                }
            }
        }
    }
    
    private func preCacheFrames(startingAt index: Int, count: Int) {
        let framesToCache = min(count, animatedImage.frameCount)
        
        for i in 0..<framesToCache {
            let frameIndex = (index + i) % animatedImage.frameCount
            
            // Only cache if not already cached
            if frameCache.get(key: frameIndex) == nil,
               let frame = animatedImage.frame(at: frameIndex) {
                frameCache.set(key: frameIndex, value: frame)
            }
        }
    }
    
    // MARK: - CustomAnimation Protocol Implementation
    
    func animate<V>(
        value: V,
        time: TimeInterval,
        context: inout AnimationContext<V>
    ) -> V? where V : VectorArithmetic {
        
        // Initialize animation start time on first call
        if animationStartTime == 0 {
            animationStartTime = time
        }
        
        let elapsed = time - animationStartTime
        
        // Handle finite loop animations
        if !animatedImage.isInfiniteLoop && hasFinished {
            return nil // Signal animation completion
        }
        
        // Calculate current frame based on elapsed time
        let scaledTime = elapsed * playbackSpeed
        let cycleTime = scaledTime.truncatingRemainder(dividingBy: animatedImage.totalDuration)
        
        var accumulatedTime: TimeInterval = 0
        var targetFrameIndex = 0
        
        for (index, duration) in animatedImage.frameDurations.enumerated() {
            if cycleTime >= accumulatedTime && cycleTime < accumulatedTime + duration {
                targetFrameIndex = index
                break
            }
            accumulatedTime += duration
        }
        
        // Update current frame index if needed
        if targetFrameIndex != currentFrameIndex {
            DispatchQueue.main.async { [weak self] in
                self?.currentFrameIndex = targetFrameIndex
            }
        }
        
        // For finite loops, check completion
        if !animatedImage.isInfiniteLoop {
            let completedCycles = scaledTime / animatedImage.totalDuration
            if completedCycles >= Double(animatedImage.loopCount) {
                hasFinished = true
                return nil
            }
        }
        
        // Return interpolated value (for VectorArithmetic conformance)
        let progress = cycleTime / animatedImage.totalDuration
        return value.scaled(by: progress)
    }
    
    func velocity<V>(
        value: V,
        time: TimeInterval,
        context: AnimationContext<V>
    ) -> V? where V : VectorArithmetic {
        // Return velocity based on current frame duration
        guard let currentDuration = animatedImage.duration(at: currentFrameIndex) else {
            return nil
        }
        
        let velocity = 1.0 / (currentDuration / playbackSpeed)
        return value.scaled(by: velocity)
    }
    
    func shouldMerge<V>(
        previous: Animation,
        value: V,
        time: TimeInterval,
        context: inout AnimationContext<V>
    ) -> Bool where V : VectorArithmetic {
        // GIF animations generally should not merge with other animations
        return false
    }
}

// MARK: - Equatable & Hashable for CustomAnimation

extension GIFAnimationController: Equatable {
    static func == (lhs: GIFAnimationController, rhs: GIFAnimationController) -> Bool {
        return lhs.animatedImage == rhs.animatedImage &&
               lhs.playbackSpeed == rhs.playbackSpeed
    }
}

extension GIFAnimationController: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(animatedImage)
        hasher.combine(playbackSpeed)
    }
}

// MARK: - GIF Animation Errors

enum GIFAnimationError: LocalizedError {
    case emptyFrames
    case mismatchedFramesAndDurations
    case invalidFrameIndex
    case animationNotPlaying
    
    var errorDescription: String? {
        switch self {
        case .emptyFrames:
            return "GIF animation cannot be created with empty frames"
        case .mismatchedFramesAndDurations:
            return "Frame count and duration count must match"
        case .invalidFrameIndex:
            return "Invalid frame index for GIF animation"
        case .animationNotPlaying:
            return "Animation is not currently playing"
        }
    }
}

// MARK: - Simple Frame Cache Implementation

private final class FrameCache {
    private var cache: [Int: NSImage] = [:]
    private var accessOrder: [Int] = []
    private let capacity: Int
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func get(key: Int) -> NSImage? {
        guard let image = cache[key] else { return nil }
        
        // Update access order
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(key)
        
        return image
    }
    
    func set(key: Int, value: NSImage) {
        // Remove existing if present
        if cache[key] != nil {
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
            }
        } else if cache.count >= capacity {
            // Remove least recently used
            if let lruKey = accessOrder.first {
                cache.removeValue(forKey: lruKey)
                accessOrder.removeFirst()
            }
        }
        
        cache[key] = value
        accessOrder.append(key)
    }
    
    func removeAll() {
        cache.removeAll()
        accessOrder.removeAll()
    }
}

// MARK: - SwiftUI Animation Extension

extension Animation {
    /// Create a GIF animation from AnimatedImage
    /// - Parameter controller: GIFAnimationController instance
    /// - Returns: Animation configured for GIF playback
    static func gif(_ controller: GIFAnimationController) -> Animation {
        return Animation(controller)
    }
}