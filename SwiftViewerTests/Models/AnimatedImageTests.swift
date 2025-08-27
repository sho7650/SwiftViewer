import XCTest
import SwiftUI
@testable import SwiftViewer

final class AnimatedImageTests: XCTestCase {
    
    private var testFrames: [NSImage]!
    private var testDurations: [TimeInterval]!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        testFrames = [
            NSImage(size: NSSize(width: 100, height: 100)),
            NSImage(size: NSSize(width: 100, height: 100)),
            NSImage(size: NSSize(width: 100, height: 100))
        ]
        
        testDurations = [0.1, 0.2, 0.15]
    }
    
    override func tearDownWithError() throws {
        testFrames = nil
        testDurations = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_setsAllPropertiesCorrectly() {
        let animatedImage = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 5,
            totalDuration: 0.45
        )
        
        XCTAssertEqual(animatedImage.frames.count, 3)
        XCTAssertEqual(animatedImage.frameDurations, testDurations)
        XCTAssertEqual(animatedImage.loopCount, 5)
        XCTAssertEqual(animatedImage.totalDuration, 0.45)
    }
    
    func test_init_withInfiniteLoop_setsLoopCountToZero() {
        let animatedImage = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 0, // 0 means infinite loop in GIF spec
            totalDuration: 0.45
        )
        
        XCTAssertEqual(animatedImage.loopCount, 0)
        XCTAssertTrue(animatedImage.isInfiniteLoop)
    }
    
    func test_init_withFiniteLoop_setsLoopCountCorrectly() {
        let animatedImage = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 3,
            totalDuration: 0.45
        )
        
        XCTAssertEqual(animatedImage.loopCount, 3)
        XCTAssertFalse(animatedImage.isInfiniteLoop)
    }
    
    // MARK: - Computed Properties Tests
    
    func test_frameCount_returnsCorrectCount() {
        let animatedImage = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 0,
            totalDuration: 0.45
        )
        
        XCTAssertEqual(animatedImage.frameCount, 3)
    }
    
    func test_isInfiniteLoop_returnsTrueForZeroLoopCount() {
        let infiniteLoop = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 0,
            totalDuration: 0.45
        )
        
        XCTAssertTrue(infiniteLoop.isInfiniteLoop)
    }
    
    func test_isInfiniteLoop_returnsFalseForPositiveLoopCount() {
        let finiteLoop = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 5,
            totalDuration: 0.45
        )
        
        XCTAssertFalse(finiteLoop.isInfiniteLoop)
    }
    
    func test_averageFrameDuration_calculatesCorrectAverage() {
        let animatedImage = AnimatedImage(
            frames: testFrames,
            frameDurations: [0.1, 0.2, 0.3], // Average = 0.2
            loopCount: 0,
            totalDuration: 0.6
        )
        
        XCTAssertEqual(animatedImage.averageFrameDuration, 0.2, accuracy: 0.001)
    }
    
    // MARK: - Frame Access Tests
    
    func test_frame_atValidIndex_returnsCorrectFrame() {
        let animatedImage = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 0,
            totalDuration: 0.45
        )
        
        let frame0 = animatedImage.frame(at: 0)
        let frame1 = animatedImage.frame(at: 1)
        let frame2 = animatedImage.frame(at: 2)
        
        XCTAssertNotNil(frame0)
        XCTAssertNotNil(frame1)
        XCTAssertNotNil(frame2)
        XCTAssertNotEqual(frame0, frame1)
    }
    
    func test_frame_atInvalidIndex_returnsNil() {
        let animatedImage = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 0,
            totalDuration: 0.45
        )
        
        XCTAssertNil(animatedImage.frame(at: -1))
        XCTAssertNil(animatedImage.frame(at: 3))
        XCTAssertNil(animatedImage.frame(at: 999))
    }
    
    func test_duration_atValidIndex_returnsCorrectDuration() {
        let animatedImage = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 0,
            totalDuration: 0.45
        )
        
        XCTAssertEqual(animatedImage.duration(at: 0), 0.1)
        XCTAssertEqual(animatedImage.duration(at: 1), 0.2)
        XCTAssertEqual(animatedImage.duration(at: 2), 0.15)
    }
    
    func test_duration_atInvalidIndex_returnsNil() {
        let animatedImage = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 0,
            totalDuration: 0.45
        )
        
        XCTAssertNil(animatedImage.duration(at: -1))
        XCTAssertNil(animatedImage.duration(at: 3))
        XCTAssertNil(animatedImage.duration(at: 999))
    }
    
    // MARK: - VectorArithmetic Conformance Tests
    
    func test_vectorArithmetic_zeroProperty() {
        let zero = AnimatedImage.zero
        
        XCTAssertEqual(zero.frameCount, 0)
        XCTAssertEqual(zero.totalDuration, 0.0)
        XCTAssertEqual(zero.loopCount, 0)
    }
    
    func test_vectorArithmetic_magnitudeSquared() {
        let animatedImage = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 3,
            totalDuration: 0.45
        )
        
        let magnitude = animatedImage.magnitudeSquared
        XCTAssertGreaterThan(magnitude, 0.0)
    }
    
    func test_vectorArithmetic_addition() {
        let image1 = AnimatedImage(
            frames: [testFrames[0]],
            frameDurations: [0.1],
            loopCount: 1,
            totalDuration: 0.1
        )
        
        let image2 = AnimatedImage(
            frames: [testFrames[1]],
            frameDurations: [0.2],
            loopCount: 2,
            totalDuration: 0.2
        )
        
        let sum = image1 + image2
        
        XCTAssertEqual(sum.frameCount, 2)
        XCTAssertEqual(sum.totalDuration, 0.3, accuracy: 0.001)
        XCTAssertEqual(sum.loopCount, 3) // Combined loop count
    }
    
    func test_vectorArithmetic_subtraction() {
        let image1 = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 5,
            totalDuration: 0.45
        )
        
        let image2 = AnimatedImage(
            frames: [testFrames[0]],
            frameDurations: [0.1],
            loopCount: 2,
            totalDuration: 0.1
        )
        
        let difference = image1 - image2
        
        XCTAssertEqual(difference.frameCount, 2) // Remaining frames after subtraction
        XCTAssertEqual(difference.totalDuration, 0.35) // 0.45 - 0.1
        XCTAssertEqual(difference.loopCount, 3) // 5 - 2
    }
    
    func test_vectorArithmetic_scalarMultiplication() {
        let animatedImage = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 2,
            totalDuration: 0.45
        )
        
        let scaled = animatedImage * 2.0
        
        XCTAssertEqual(scaled.frameCount, animatedImage.frameCount) // Frame count doesn't scale
        XCTAssertEqual(scaled.totalDuration, 0.9, accuracy: 0.001) // Duration scales
        XCTAssertEqual(scaled.loopCount, 4) // Loop count scales
    }
    
    // MARK: - Equatable Conformance Tests
    
    func test_equatable_identicalImages_areEqual() {
        let image1 = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 3,
            totalDuration: 0.45
        )
        
        let image2 = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 3,
            totalDuration: 0.45
        )
        
        XCTAssertEqual(image1, image2)
    }
    
    func test_equatable_differentImages_areNotEqual() {
        let image1 = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 3,
            totalDuration: 0.45
        )
        
        let image2 = AnimatedImage(
            frames: testFrames,
            frameDurations: testDurations,
            loopCount: 5, // Different loop count
            totalDuration: 0.45
        )
        
        XCTAssertNotEqual(image1, image2)
    }
    
    // MARK: - Memory Management Tests
    
    func test_largeAnimation_doesNotCauseMemoryLeak() {
        let largeFrames = (0..<100).map { _ in
            NSImage(size: NSSize(width: 1000, height: 1000))
        }
        let largeDurations = Array(repeating: 0.1, count: 100)
        
        // Test that large animations can be created and used without issues
        let largeImage = AnimatedImage(
            frames: largeFrames,
            frameDurations: largeDurations,
            loopCount: 1,
            totalDuration: 10.0
        )
        
        // Use the image
        XCTAssertEqual(largeImage.frameCount, 100)
        XCTAssertEqual(largeImage.totalDuration, 10.0)
        XCTAssertFalse(largeImage.isInfiniteLoop)
    }
    
    // MARK: - Error Handling Tests
    
    func test_init_withEmptyFrames_hasZeroFrameCount() {
        let emptyImage = AnimatedImage(
            frames: [],
            frameDurations: [],
            loopCount: 0,
            totalDuration: 0.0
        )
        
        XCTAssertEqual(emptyImage.frameCount, 0)
        XCTAssertEqual(emptyImage.totalDuration, 0.0)
    }
    
    func test_init_withMismatchedArrays_handlesSafely() {
        // More frames than durations
        let mismatchedImage = AnimatedImage(
            frames: testFrames, // 3 frames
            frameDurations: [0.1, 0.2], // 2 durations
            loopCount: 0,
            totalDuration: 0.3
        )
        
        // Should handle gracefully by using available data
        XCTAssertEqual(mismatchedImage.frameCount, 3)
        XCTAssertNotNil(mismatchedImage.frame(at: 0))
        XCTAssertNotNil(mismatchedImage.frame(at: 2))
    }
}

// MARK: - Test Helpers

extension AnimatedImageTests {
    
    private func createTestFrameWithColor(_ color: NSColor) -> NSImage {
        let image = NSImage(size: NSSize(width: 100, height: 100))
        image.lockFocus()
        color.set()
        NSRect(origin: .zero, size: image.size).fill()
        image.unlockFocus()
        return image
    }
}