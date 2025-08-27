import Foundation
import SwiftUI

/// A model representing an animated GIF with frame data and animation metadata
/// Conforms to VectorArithmetic for use with SwiftUI animations
struct AnimatedImage: VectorArithmetic, Equatable, Hashable {
    
    // MARK: - Properties
    
    /// Individual frames of the animation
    let frames: [NSImage]
    
    /// Duration for each frame in seconds
    let frameDurations: [TimeInterval]
    
    /// Number of times to loop the animation (0 = infinite)
    let loopCount: Int
    
    /// Total duration of one complete animation cycle
    let totalDuration: TimeInterval
    
    // MARK: - Initialization
    
    init(frames: [NSImage], frameDurations: [TimeInterval], loopCount: Int, totalDuration: TimeInterval) {
        self.frames = frames
        self.frameDurations = frameDurations
        self.loopCount = loopCount
        self.totalDuration = totalDuration
    }
    
    // MARK: - Computed Properties
    
    /// Number of frames in the animation
    var frameCount: Int {
        return frames.count
    }
    
    /// Whether this animation loops infinitely
    var isInfiniteLoop: Bool {
        return loopCount == 0
    }
    
    /// Average duration per frame
    var averageFrameDuration: TimeInterval {
        guard !frameDurations.isEmpty else { return 0.0 }
        return frameDurations.reduce(0.0, +) / Double(frameDurations.count)
    }
    
    // MARK: - Frame Access Methods
    
    /// Get frame at specified index
    /// - Parameter index: Frame index
    /// - Returns: NSImage if index is valid, nil otherwise
    func frame(at index: Int) -> NSImage? {
        guard index >= 0 && index < frames.count else { return nil }
        return frames[index]
    }
    
    /// Get duration at specified index
    /// - Parameter index: Frame index
    /// - Returns: Duration if index is valid, nil otherwise
    func duration(at index: Int) -> TimeInterval? {
        guard index >= 0 && index < frameDurations.count else { return nil }
        return frameDurations[index]
    }
    
    // MARK: - VectorArithmetic Conformance
    
    static var zero: AnimatedImage {
        return AnimatedImage(
            frames: [],
            frameDurations: [],
            loopCount: 0,
            totalDuration: 0.0
        )
    }
    
    var magnitudeSquared: Double {
        // Calculate magnitude based on total duration and frame count
        return totalDuration * totalDuration + Double(frameCount * frameCount)
    }
    
    static func + (lhs: AnimatedImage, rhs: AnimatedImage) -> AnimatedImage {
        // Combine two animations by concatenating frames
        let combinedFrames = lhs.frames + rhs.frames
        let combinedDurations = lhs.frameDurations + rhs.frameDurations
        let combinedLoopCount = lhs.loopCount + rhs.loopCount
        let combinedTotalDuration = lhs.totalDuration + rhs.totalDuration
        
        return AnimatedImage(
            frames: combinedFrames,
            frameDurations: combinedDurations,
            loopCount: combinedLoopCount,
            totalDuration: combinedTotalDuration
        )
    }
    
    static func - (lhs: AnimatedImage, rhs: AnimatedImage) -> AnimatedImage {
        // Subtract by removing frames from the end
        let framesToRemove = min(rhs.frameCount, lhs.frameCount)
        let remainingFrames = Array(lhs.frames.dropLast(framesToRemove))
        let remainingDurations = Array(lhs.frameDurations.dropLast(framesToRemove))
        
        let remainingLoopCount = max(0, lhs.loopCount - rhs.loopCount)
        let remainingDuration = max(0.0, lhs.totalDuration - rhs.totalDuration)
        
        return AnimatedImage(
            frames: remainingFrames,
            frameDurations: remainingDurations,
            loopCount: remainingLoopCount,
            totalDuration: remainingDuration
        )
    }
    
    static func * (lhs: AnimatedImage, rhs: Double) -> AnimatedImage {
        // Scale animation by affecting durations and loop count
        let scaledDurations = lhs.frameDurations.map { $0 * rhs }
        let scaledLoopCount = Int(Double(lhs.loopCount) * rhs)
        let scaledTotalDuration = lhs.totalDuration * rhs
        
        return AnimatedImage(
            frames: lhs.frames, // Frames don't scale
            frameDurations: scaledDurations,
            loopCount: scaledLoopCount,
            totalDuration: scaledTotalDuration
        )
    }
    
    mutating func scale(by rhs: Double) {
        self = self * rhs
    }
    
    // MARK: - Equatable & Hashable Conformance
    
    static func == (lhs: AnimatedImage, rhs: AnimatedImage) -> Bool {
        return lhs.frameCount == rhs.frameCount &&
               lhs.frameDurations == rhs.frameDurations &&
               lhs.loopCount == rhs.loopCount &&
               lhs.totalDuration == rhs.totalDuration
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(frameCount)
        hasher.combine(frameDurations)
        hasher.combine(loopCount)
        hasher.combine(totalDuration)
    }
}

// MARK: - Animation Support

extension AnimatedImage {
    
    /// Create an AnimatedImage from ImageIO CGImageSource
    /// - Parameter imageSource: CGImageSource from GIF data
    /// - Returns: AnimatedImage if successful, nil otherwise
    static func from(imageSource: CGImageSource) -> AnimatedImage? {
        let frameCount = CGImageSourceGetCount(imageSource)
        guard frameCount > 0 else { return nil }
        
        var frames: [NSImage] = []
        var frameDurations: [TimeInterval] = []
        var totalDuration: TimeInterval = 0.0
        
        for index in 0..<frameCount {
            // Extract frame image
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
                continue
            }
            
            let nsImage = NSImage(cgImage: cgImage, size: .zero)
            frames.append(nsImage)
            
            // Extract frame duration
            let frameDuration = getFrameDuration(from: imageSource, at: index)
            frameDurations.append(frameDuration)
            totalDuration += frameDuration
        }
        
        // Extract loop count from GIF properties
        let loopCount = getLoopCount(from: imageSource)
        
        guard !frames.isEmpty else { return nil }
        
        return AnimatedImage(
            frames: frames,
            frameDurations: frameDurations,
            loopCount: loopCount,
            totalDuration: totalDuration
        )
    }
    
    private static func getFrameDuration(from imageSource: CGImageSource, at index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as? [String: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
            return 0.1 // Default duration
        }
        
        // Check for unclampedDelay first, then delayTime
        if let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
            let duration = unclampedDelay.doubleValue
            return duration > 0 ? duration : 0.1
        }
        
        if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
            let duration = delayTime.doubleValue
            return duration > 0 ? duration : 0.1
        }
        
        return 0.1 // Default duration
    }
    
    private static func getLoopCount(from imageSource: CGImageSource) -> Int {
        guard let properties = CGImageSourceCopyProperties(imageSource, nil) as? [String: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
              let loopCount = gifProperties[kCGImagePropertyGIFLoopCount as String] as? NSNumber else {
            return 0 // Default to infinite loop
        }
        
        return loopCount.intValue
    }
}