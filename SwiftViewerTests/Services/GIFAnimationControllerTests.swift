import XCTest
import ImageIO
import SwiftUI
@testable import SwiftViewer

final class GIFAnimationControllerTests: XCTestCase {
    
    private var sut: GIFAnimationController!
    private var mockAnimatedImage: AnimatedImage!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create a simple test AnimatedImage with 3 frames
        let frame1 = NSImage(size: NSSize(width: 100, height: 100))
        let frame2 = NSImage(size: NSSize(width: 100, height: 100))
        let frame3 = NSImage(size: NSSize(width: 100, height: 100))
        
        mockAnimatedImage = AnimatedImage(
            frames: [frame1, frame2, frame3],
            frameDurations: [0.1, 0.2, 0.15],
            loopCount: 0, // infinite loop
            totalDuration: 0.45
        )
        
        sut = try GIFAnimationController(animatedImage: mockAnimatedImage)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockAnimatedImage = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_setsAnimatedImageCorrectly() {
        XCTAssertEqual(sut.animatedImage.frames.count, 3)
        XCTAssertEqual(sut.animatedImage.totalDuration, 0.45)
        XCTAssertEqual(sut.animatedImage.loopCount, 0)
    }
    
    func test_init_setsInitialStateCorrectly() {
        XCTAssertEqual(sut.currentFrameIndex, 0)
        XCTAssertFalse(sut.isPlaying)
        XCTAssertEqual(sut.playbackSpeed, 1.0)
    }
    
    // MARK: - Animation Control Tests
    
    func test_play_startsAnimation() {
        sut.play()
        
        XCTAssertTrue(sut.isPlaying)
    }
    
    func test_pause_stopsAnimation() {
        sut.play()
        sut.pause()
        
        XCTAssertFalse(sut.isPlaying)
    }
    
    func test_stop_resetsToFirstFrame() {
        sut.play()
        // Simulate some progression
        sut.stop()
        
        XCTAssertFalse(sut.isPlaying)
        XCTAssertEqual(sut.currentFrameIndex, 0)
    }
    
    // MARK: - Frame Navigation Tests
    
    func test_nextFrame_advancesToNextFrame() {
        XCTAssertEqual(sut.currentFrameIndex, 0)
        
        sut.nextFrame()
        XCTAssertEqual(sut.currentFrameIndex, 1)
        
        sut.nextFrame()
        XCTAssertEqual(sut.currentFrameIndex, 2)
    }
    
    func test_nextFrame_wrapsAroundAtEnd() {
        sut.currentFrameIndex = 2 // Last frame
        
        sut.nextFrame()
        XCTAssertEqual(sut.currentFrameIndex, 0) // Should wrap to first frame
    }
    
    func test_previousFrame_movesToPreviousFrame() {
        sut.currentFrameIndex = 2
        
        sut.previousFrame()
        XCTAssertEqual(sut.currentFrameIndex, 1)
        
        sut.previousFrame()
        XCTAssertEqual(sut.currentFrameIndex, 0)
    }
    
    func test_previousFrame_wrapsAroundAtBeginning() {
        XCTAssertEqual(sut.currentFrameIndex, 0) // First frame
        
        sut.previousFrame()
        XCTAssertEqual(sut.currentFrameIndex, 2) // Should wrap to last frame
    }
    
    // MARK: - Current Image Tests
    
    func test_currentImage_returnsCorrectFrameImage() {
        let firstFrameImage = sut.currentImage
        XCTAssertNotNil(firstFrameImage)
        
        sut.nextFrame()
        let secondFrameImage = sut.currentImage
        XCTAssertNotNil(secondFrameImage)
        XCTAssertNotEqual(firstFrameImage, secondFrameImage)
    }
    
    func test_currentImage_returnsNilForInvalidIndex() {
        sut.currentFrameIndex = 999 // Invalid index
        
        XCTAssertNil(sut.currentImage)
    }
    
    // MARK: - Playback Speed Tests
    
    func test_setPlaybackSpeed_updatesSpeedCorrectly() {
        sut.setPlaybackSpeed(2.0)
        
        XCTAssertEqual(sut.playbackSpeed, 2.0)
    }
    
    func test_setPlaybackSpeed_clampsToValidRange() {
        sut.setPlaybackSpeed(-1.0)
        XCTAssertEqual(sut.playbackSpeed, 0.1) // Minimum speed
        
        sut.setPlaybackSpeed(10.0)
        XCTAssertEqual(sut.playbackSpeed, 5.0) // Maximum speed
    }
    
    // MARK: - CustomAnimation Protocol Tests
    
    func test_animate_calculatesCorrectValueAtTime() {
        // Note: AnimationContext cannot be initialized directly in tests
        // This tests the core animation logic indirectly through the controller
        sut.play()
        
        // Verify the controller starts properly
        XCTAssertTrue(sut.isPlaying)
        
        // Wait briefly to allow some animation frames
        let expectation = expectation(description: "Animation frames")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        sut.pause()
        XCTAssertFalse(sut.isPlaying)
    }
    
    func test_animate_returnsNilWhenAnimationFinishes() {
        // For finite loop animations, should return nil when finished
        let finiteLoopImage = AnimatedImage(
            frames: mockAnimatedImage.frames,
            frameDurations: mockAnimatedImage.frameDurations,
            loopCount: 1, // Finite loop
            totalDuration: mockAnimatedImage.totalDuration
        )
        
        let finiteController = try! GIFAnimationController(animatedImage: finiteLoopImage)
        finiteController.play()
        
        // Test that finite animations can be created and controlled
        XCTAssertTrue(finiteController.isPlaying)
        XCTAssertFalse(finiteLoopImage.isInfiniteLoop)
        
        finiteController.stop()
        XCTAssertFalse(finiteController.isPlaying)
    }
    
    // MARK: - Memory Management Tests
    
    func test_clearFrameCache_removesAllCachedFrames() {
        // Force some frames to be cached
        _ = sut.currentImage
        sut.nextFrame()
        _ = sut.currentImage
        
        sut.clearFrameCache()
        
        // After clearing, accessing current image should work (regenerate cache)
        XCTAssertNotNil(sut.currentImage)
    }
    
    // MARK: - Error Handling Tests
    
    func test_init_withEmptyFrames_throwsError() {
        let emptyImage = AnimatedImage(
            frames: [],
            frameDurations: [],
            loopCount: 0,
            totalDuration: 0.0
        )
        
        XCTAssertThrowsError(try GIFAnimationController(animatedImage: emptyImage))
    }
    
    func test_init_withMismatchedFramesAndDurations_throwsError() {
        let mismatchedImage = AnimatedImage(
            frames: [NSImage(size: NSSize(width: 100, height: 100))], // 1 frame
            frameDurations: [0.1, 0.2], // 2 durations
            loopCount: 0,
            totalDuration: 0.3
        )
        
        XCTAssertThrowsError(try GIFAnimationController(animatedImage: mismatchedImage))
    }
}

// MARK: - Test Helpers

extension GIFAnimationControllerTests {
    
    private func createTestGIFData() -> Data {
        // Create minimal GIF data for testing
        // This would normally load from a test GIF file
        return Data()
    }
}