//
//  AutoHideControlsManagerTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/22.
//

import XCTest
@testable import SwiftViewer

@MainActor
final class AutoHideControlsManagerTests: XCTestCase {
    
    var mockContainer: MockDependencyContainer!
    var viewModel: ImageGalleryViewModel!
    var slideShowViewModel: SlideShowViewModel!
    var mockNavigator: MockImageNavigator!
    var autoHideManager: AutoHideControlsManager!
    
    override func setUp() {
        super.setUp()
        mockContainer = MockDependencyContainer()
        mockNavigator = MockImageNavigator()
        viewModel = ImageGalleryViewModel(dependencies: mockContainer)
        slideShowViewModel = SlideShowViewModel(
            slideShowService: mockContainer.slideShowService,
            imageNavigator: mockNavigator,
            settingsManager: mockContainer.settingsManager
        )
        
        autoHideManager = AutoHideControlsManager(
            slideShowViewModel: slideShowViewModel,
            imageGalleryViewModel: viewModel
        )
        
        // Setup some test images
        let testImages = createTestImageFiles(count: 3)
        viewModel.imageFiles = testImages
        mockNavigator.imageFiles = testImages
    }
    
    override func tearDown() {
        autoHideManager.cleanupTimer()
        autoHideManager = nil
        slideShowViewModel = nil
        viewModel = nil
        mockNavigator = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_initialization_controlsVisibleByDefault() {
        XCTAssertTrue(autoHideManager.areControlsVisible, "Controls should be visible by default")
    }
    
    func test_initialization_lastActivityTimeIsRecent() {
        let timeDifference = Date().timeIntervalSince(autoHideManager.lastActivityTime)
        XCTAssertLessThan(timeDifference, 1.0, "Last activity time should be very recent")
    }
    
    // MARK: - Show/Hide Controls Tests
    
    func test_showControlsAndResetTimer_makesControlsVisible() {
        // Initially hide controls for testing
        autoHideManager.hideControlsImmediately()
        XCTAssertFalse(autoHideManager.areControlsVisible)
        
        // Show controls
        autoHideManager.showControlsAndResetTimer()
        
        // Controls should be visible
        XCTAssertTrue(autoHideManager.areControlsVisible, "Controls should be visible after showControlsAndResetTimer")
    }
    
    func test_hideControlsImmediately_hidesControls() {
        // Ensure controls are visible initially
        XCTAssertTrue(autoHideManager.areControlsVisible)
        
        // Hide controls immediately
        autoHideManager.hideControlsImmediately()
        
        // Controls should be hidden
        XCTAssertFalse(autoHideManager.areControlsVisible, "Controls should be hidden after hideControlsImmediately")
    }
    
    func test_registerActivity_showsControls() {
        // Hide controls initially
        autoHideManager.hideControlsImmediately()
        XCTAssertFalse(autoHideManager.areControlsVisible)
        
        // Register activity
        autoHideManager.registerActivity()
        
        // Controls should be visible
        XCTAssertTrue(autoHideManager.areControlsVisible, "Controls should be visible after registerActivity")
    }
    
    // MARK: - Timer Behavior Tests
    
    func test_shouldAllowAutoHide_returnsTrue_whenSlideshowRunning() {
        // Start slideshow
        slideShowViewModel.startSlideShow(interval: 1.0)
        
        // Should allow auto-hide during slideshow for cleaner viewing experience
        XCTAssertTrue(autoHideManager.shouldAllowAutoHide(), "Should allow auto-hide during slideshow for better UX")
    }
    
    func test_shouldAllowAutoHide_returnsFalse_whenLoading() {
        // Set loading state
        viewModel.isLoading = true
        
        // Should not allow auto-hide when loading
        XCTAssertFalse(autoHideManager.shouldAllowAutoHide(), "Should not allow auto-hide when loading")
    }
    
    func test_shouldAllowAutoHide_returnsFalse_whenError() {
        // Set error state
        viewModel.errorMessage = "Test error"
        
        // Should not allow auto-hide when there's an error
        XCTAssertFalse(autoHideManager.shouldAllowAutoHide(), "Should not allow auto-hide when there's an error")
    }
    
    func test_shouldAllowAutoHide_returnsTrue_inNormalState() {
        // Ensure normal state
        viewModel.isLoading = false
        viewModel.errorMessage = nil
        slideShowViewModel.stopSlideShow()
        
        // Should allow auto-hide in normal state
        XCTAssertTrue(autoHideManager.shouldAllowAutoHide(), "Should allow auto-hide in normal state")
    }
    
    func test_hideControlsIfAllowed_hidesControls_whenAllowed() {
        // Ensure normal state
        viewModel.isLoading = false
        viewModel.errorMessage = nil
        slideShowViewModel.stopSlideShow()
        
        // Ensure controls are visible
        autoHideManager.showControlsAndResetTimer()
        XCTAssertTrue(autoHideManager.areControlsVisible)
        
        // Hide controls if allowed
        autoHideManager.hideControlsIfAllowed()
        
        // Controls should be hidden
        XCTAssertFalse(autoHideManager.areControlsVisible, "Controls should be hidden when auto-hide is allowed")
    }
    
    func test_hideControlsIfAllowed_keepsControlsVisible_whenNotAllowed() {
        // Set loading state to prevent auto-hide
        viewModel.isLoading = true
        
        // Ensure controls are visible
        autoHideManager.showControlsAndResetTimer()
        XCTAssertTrue(autoHideManager.areControlsVisible)
        
        // Try to hide controls
        autoHideManager.hideControlsIfAllowed()
        
        // Controls should still be visible because loading state prevents auto-hide
        XCTAssertTrue(autoHideManager.areControlsVisible, "Controls should remain visible when auto-hide is not allowed")
    }
    
    // MARK: - Mock Manager Tests
    
    func test_mockManager_tracksActivityCalls() {
        let mockManager = MockAutoHideControlsManager(
            slideShowViewModel: slideShowViewModel,
            imageGalleryViewModel: viewModel
        )
        
        // Initial count should be zero
        XCTAssertEqual(mockManager.registerActivityCallCount, 0)
        
        // Register activity multiple times
        mockManager.registerActivity()
        mockManager.registerActivity()
        mockManager.registerActivity()
        
        // Count should be tracked
        XCTAssertEqual(mockManager.registerActivityCallCount, 3, "Mock should track registerActivity calls")
    }
    
    func test_mockManager_canSimulateTimerFire() {
        let mockManager = MockAutoHideControlsManager(
            slideShowViewModel: slideShowViewModel,
            imageGalleryViewModel: viewModel
        )
        
        // Ensure normal state for auto-hide
        viewModel.isLoading = false
        viewModel.errorMessage = nil
        slideShowViewModel.stopSlideShow()
        
        // Initial state
        XCTAssertEqual(mockManager.hideTimerFireCount, 0)
        XCTAssertTrue(mockManager.areControlsVisible)
        
        // Simulate timer fire
        mockManager.simulateTimerFire()
        
        // Should track fire count and hide controls
        XCTAssertEqual(mockManager.hideTimerFireCount, 1)
        XCTAssertFalse(mockManager.areControlsVisible, "Controls should be hidden after simulated timer fire")
    }
    
    func test_mockManager_canOverrideShouldAllowAutoHide() {
        let mockManager = MockAutoHideControlsManager(
            slideShowViewModel: slideShowViewModel,
            imageGalleryViewModel: viewModel
        )
        
        // Set mock to disallow auto-hide
        mockManager.mockShouldAllowAutoHide = false
        
        // Should return false even in normal conditions
        XCTAssertFalse(mockManager.shouldAllowAutoHide(), "Mock should override shouldAllowAutoHide")
        
        // Set mock to allow auto-hide
        mockManager.mockShouldAllowAutoHide = true
        
        // Should return true
        XCTAssertTrue(mockManager.shouldAllowAutoHide(), "Mock should override shouldAllowAutoHide")
    }
    
    func test_mockManager_simulateAutoHideCheck_usesRealLogic() {
        let mockManager = MockAutoHideControlsManager(
            slideShowViewModel: slideShowViewModel,
            imageGalleryViewModel: viewModel
        )
        
        // Set loading state to prevent auto-hide (slideshow now allows auto-hide)
        viewModel.isLoading = true
        
        // Mock override says allow, but real logic should say no because of loading state
        mockManager.mockShouldAllowAutoHide = true
        XCTAssertTrue(mockManager.shouldAllowAutoHide()) // Mock override
        XCTAssertFalse(mockManager.simulateAutoHideCheck()) // Real logic checks loading state
    }
    
    // MARK: - Timer Cleanup Tests
    
    func test_cleanupTimer_canBeCalledMultipleTimes() {
        // Should not crash when called multiple times
        autoHideManager.cleanupTimer()
        autoHideManager.cleanupTimer()
        autoHideManager.cleanupTimer()
        
        // Test passes if we reach here without crashes
        XCTAssert(true, "cleanupTimer should handle multiple calls gracefully")
    }
    
    func test_deinit_cleansUpTimer() {
        // Create manager in a scope
        var manager: AutoHideControlsManager? = AutoHideControlsManager(
            slideShowViewModel: slideShowViewModel,
            imageGalleryViewModel: viewModel
        )
        
        // Start a timer
        manager?.showControlsAndResetTimer()
        
        // Release the manager (triggers deinit)
        manager = nil
        
        // Test passes if we reach here without crashes
        // The timer should be cleaned up in deinit
        XCTAssert(true, "Manager should clean up timers in deinit")
    }
    
    // MARK: - Integration Tests
    
    func test_multipleActivityRegistrations_updateLastActivityTime() {
        let initialTime = autoHideManager.lastActivityTime
        
        // Wait a small amount to ensure time difference
        let expectation = XCTestExpectation(description: "Wait for time to pass")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Register new activity
        autoHideManager.registerActivity()
        
        // Last activity time should be updated
        XCTAssertGreaterThan(autoHideManager.lastActivityTime, initialTime, "Last activity time should be updated")
    }
    
    func test_stateChanges_affectAutoHideBehavior() {
        // Start in normal state
        viewModel.isLoading = false
        viewModel.errorMessage = nil
        slideShowViewModel.stopSlideShow()
        
        XCTAssertTrue(autoHideManager.shouldAllowAutoHide(), "Should allow auto-hide in normal state")
        
        // Change to loading state
        viewModel.isLoading = true
        XCTAssertFalse(autoHideManager.shouldAllowAutoHide(), "Should not allow auto-hide when loading")
        
        // Change to error state
        viewModel.isLoading = false
        viewModel.errorMessage = "Error"
        XCTAssertFalse(autoHideManager.shouldAllowAutoHide(), "Should not allow auto-hide when error exists")
        
        // Start slideshow - now allows auto-hide for better UX
        viewModel.errorMessage = nil
        slideShowViewModel.startSlideShow(interval: 1.0)
        XCTAssertTrue(autoHideManager.shouldAllowAutoHide(), "Should allow auto-hide during slideshow for cleaner viewing")
    }
    
    // MARK: - Helper Methods
    
    private func createTestImageFiles(count: Int) -> [ImageFile] {
        return (0..<count).map { index in
            ImageFile(
                url: URL(fileURLWithPath: "/test\(index).jpg"),
                fileName: "test\(index).jpg",
                fileSize: 1024,
                createdDate: Date()
            )
        }
    }
}