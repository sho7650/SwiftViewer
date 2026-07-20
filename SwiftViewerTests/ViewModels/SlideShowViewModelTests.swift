//
//  SlideShowViewModelTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
import Observation
@testable import SwiftViewer

@MainActor
final class SlideShowViewModelTests: XCTestCase {
    
    var sut: SlideShowViewModel!
    var mockSlideShowService: MockSlideShowService!
    var mockImageGalleryViewModel: MockImageGalleryViewModel!
    var mockSettingsManager: MockSettingsManager!
    
    override func setUp() {
        super.setUp()
        mockSlideShowService = MockSlideShowService()
        mockImageGalleryViewModel = MockImageGalleryViewModel()
        mockSettingsManager = MockSettingsManager()
        sut = SlideShowViewModel(
            slideShowService: mockSlideShowService,
            imageNavigator: mockImageGalleryViewModel,
            settingsManager: mockSettingsManager
        )
    }
    
    override func tearDown() {
        sut.stopSlideShow()
        sut = nil
        mockSlideShowService = nil
        mockImageGalleryViewModel = nil
        mockSettingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func test_initialState_isCorrect() {
        XCTAssertFalse(sut.isRunning)
        XCTAssertNil(sut.currentInterval)
        XCTAssertEqual(sut.defaultInterval, 10.0)
    }
    
    // MARK: - Repeat Mode Reactivity Tests
    
    func test_isRepeatEnabled_whenSettingsChange_shouldUpdateImmediately() {
        // Given: Initial repeat is disabled
        mockSettingsManager.repeatEnabled = false
        XCTAssertFalse(sut.isRepeatEnabled)
        
        // When: Settings change via notification
        mockSettingsManager.repeatEnabled = true
        NotificationCenter.default.post(name: .repeatModeChanged, object: true)
        
        // Then: ViewModel reflects change immediately
        XCTAssertTrue(sut.isRepeatEnabled)
    }
    
    func test_isRepeatEnabled_whenToggled_shouldUpdateSettingsManager() {
        // Given: Initial repeat is disabled
        mockSettingsManager.repeatEnabled = false
        XCTAssertFalse(sut.isRepeatEnabled)

        // When: Toggle repeat mode
        sut.toggleRepeatMode()

        // Then: The injected settings manager is updated (proper dependency injection).
        XCTAssertTrue(mockSettingsManager.repeatEnabled)
        XCTAssertTrue(sut.isRepeatEnabled)
    }
    
    func test_isRepeatEnabled_whenNotificationReceived_shouldReflectCorrectValue() {
        // Given: Initial state
        mockSettingsManager.repeatEnabled = false
        
        // When: Multiple notifications with different values
        NotificationCenter.default.post(name: .repeatModeChanged, object: true)
        XCTAssertTrue(sut.isRepeatEnabled)
        
        NotificationCenter.default.post(name: .repeatModeChanged, object: false)
        XCTAssertFalse(sut.isRepeatEnabled)
        
        NotificationCenter.default.post(name: .repeatModeChanged, object: true)
        XCTAssertTrue(sut.isRepeatEnabled)
    }
    
    // MARK: - Start Slideshow Tests
    
    func test_startSlideShow_withDefaultInterval_startsService() {
        sut.startSlideShow()
        
        XCTAssertTrue(mockSlideShowService.isRunning)
        XCTAssertEqual(mockSlideShowService.currentInterval, 10.0)
        XCTAssertTrue(sut.isRunning)
    }
    
    func test_startSlideShow_withCustomInterval_startsService() {
        let customInterval: TimeInterval = 5.0
        
        sut.startSlideShow(interval: customInterval)
        
        XCTAssertTrue(mockSlideShowService.isRunning)
        XCTAssertEqual(mockSlideShowService.currentInterval, customInterval)
        XCTAssertEqual(sut.currentInterval, customInterval)
    }
    
    func test_startSlideShow_callsNextImageOnTimer() {
        let expectation = XCTestExpectation(description: "Navigation method called")
        
        sut.startSlideShow(interval: 0.1)
        
        mockSlideShowService.simulateTimerFire()
        
        // Wait a brief moment for async Task to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            XCTAssertEqual(self.mockImageGalleryViewModel.navigateToNextCallCount, 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_startSlideShow_handlesMultipleTimerFires() {
        let expectation = XCTestExpectation(description: "Multiple navigation calls")
        
        sut.startSlideShow(interval: 0.1)
        
        mockSlideShowService.simulateTimerFire()
        mockSlideShowService.simulateTimerFire()
        mockSlideShowService.simulateTimerFire()
        
        // Wait a brief moment for async Tasks to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            XCTAssertEqual(self.mockImageGalleryViewModel.navigateToNextCallCount, 3)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_startSlideShow_whenServiceFailsToStart_doesNotUpdateState() {
        mockSlideShowService.setShouldFailStart(true)
        
        sut.startSlideShow()
        
        // Since service failed to start, isRunning should remain false
        XCTAssertFalse(sut.isRunning)
        XCTAssertNil(sut.currentInterval)
    }
    
    // MARK: - Stop Slideshow Tests
    
    func test_stopSlideShow_stopsRunningSlideshow() {
        sut.startSlideShow()
        XCTAssertTrue(sut.isRunning)
        
        sut.stopSlideShow()
        
        XCTAssertFalse(mockSlideShowService.isRunning)
        XCTAssertFalse(sut.isRunning)
        XCTAssertNil(sut.currentInterval)
    }
    
    func test_stopSlideShow_canBeCalledWhenNotRunning() {
        XCTAssertNoThrow(sut.stopSlideShow())
        XCTAssertFalse(sut.isRunning)
    }
    
    func test_stopSlideShow_preventsTimerCallbacks() {
        sut.startSlideShow(interval: 0.1)
        sut.stopSlideShow()
        
        mockSlideShowService.simulateTimerFire()
        
        XCTAssertEqual(mockImageGalleryViewModel.navigateToNextCallCount, 0)
    }
    
    // MARK: - Toggle Slideshow Tests
    
    func test_toggleSlideShow_startsWhenStopped() {
        XCTAssertFalse(sut.isRunning)
        
        sut.toggleSlideShow()
        
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.currentInterval, 10.0)
    }
    
    func test_toggleSlideShow_stopsWhenRunning() {
        sut.startSlideShow()
        XCTAssertTrue(sut.isRunning)
        
        sut.toggleSlideShow()
        
        XCTAssertFalse(sut.isRunning)
    }
    
    func test_toggleSlideShow_withCustomInterval_usesInterval() {
        let customInterval: TimeInterval = 2.0
        
        sut.toggleSlideShow(interval: customInterval)
        
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.currentInterval, customInterval)
    }
    
    // MARK: - State Synchronization Tests
    
    func test_isRunning_reflectsViewModelState() {
        XCTAssertFalse(sut.isRunning)
        
        sut.startSlideShow()
        XCTAssertTrue(sut.isRunning)
        
        sut.stopSlideShow()
        XCTAssertFalse(sut.isRunning)
    }
    
    func test_currentInterval_reflectsServiceState() {
        XCTAssertNil(sut.currentInterval)
        
        mockSlideShowService.currentInterval = 5.0
        XCTAssertEqual(sut.currentInterval, 5.0)
        
        mockSlideShowService.currentInterval = nil
        XCTAssertNil(sut.currentInterval)
    }
    
    // MARK: - Error Handling Tests
    
    func test_startSlideShow_withInvalidInterval_doesNotStart() {
        sut.startSlideShow(interval: 0)
        XCTAssertFalse(sut.isRunning)
        
        sut.startSlideShow(interval: -1)
        XCTAssertFalse(sut.isRunning)
    }
    
    // MARK: - Settings Integration Tests
    
    func test_defaultInterval_readsFromSettingsManager() {
        mockSettingsManager.slideShowInterval = 15.0
        
        XCTAssertEqual(sut.defaultInterval, 15.0, "Should read default interval from settings")
    }
    
    func test_startSlideShow_usesSettingsManagerInterval_whenNoIntervalProvided() {
        mockSettingsManager.slideShowInterval = 7.5
        
        sut.startSlideShow()
        
        XCTAssertTrue(mockSlideShowService.isRunning)
        XCTAssertEqual(mockSlideShowService.currentInterval, 7.5)
    }
    
    func test_startSlideShow_usesProvidedInterval_overridingSettings() {
        mockSettingsManager.slideShowInterval = 15.0
        
        sut.startSlideShow(interval: 5.0)
        
        XCTAssertTrue(mockSlideShowService.isRunning)
        XCTAssertEqual(mockSlideShowService.currentInterval, 5.0)
    }
    
    func test_toggleSlideShow_usesSettingsManagerInterval_whenNoIntervalProvided() {
        mockSettingsManager.slideShowInterval = 12.5
        
        sut.toggleSlideShow()
        
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.currentInterval, 12.5)
    }
    
    // MARK: - New Features Tests (Phase 3)
    
    func test_restartSlideShowIfRunning_restartsWhenRunning() {
        // Start slideshow first
        sut.startSlideShow(interval: 2.0)
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.currentInterval, 2.0)
        
        // Restart should maintain the running state
        sut.restartSlideShowIfRunning()
        
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.currentInterval, 2.0)
        // Service should have been stopped and restarted
        XCTAssertTrue(mockSlideShowService.isRunning)
    }
    
    func test_restartSlideShowIfRunning_doesNothingWhenStopped() {
        // Ensure slideshow is not running
        XCTAssertFalse(sut.isRunning)
        
        sut.restartSlideShowIfRunning()
        
        // Should remain stopped
        XCTAssertFalse(sut.isRunning)
        XCTAssertFalse(mockSlideShowService.isRunning)
    }
    
    func test_updateIntervalIfRunning_updatesWhenRunning() {
        // Start slideshow with initial interval
        sut.startSlideShow(interval: 3.0)
        XCTAssertEqual(sut.currentInterval, 3.0)
        
        // Change settings interval
        mockSettingsManager.slideShowInterval = 5.0
        
        // Update interval if running
        sut.updateIntervalIfRunning()
        
        // Should use new interval from settings
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.currentInterval, 5.0)
        XCTAssertEqual(mockSlideShowService.currentInterval, 5.0)
    }
    
    func test_updateIntervalIfRunning_doesNothingWhenStopped() {
        // Ensure slideshow is not running
        XCTAssertFalse(sut.isRunning)
        
        // Change settings interval
        mockSettingsManager.slideShowInterval = 8.0
        
        sut.updateIntervalIfRunning()
        
        // Should remain stopped and not use new interval
        XCTAssertFalse(sut.isRunning)
        XCTAssertNil(sut.currentInterval)
    }
    
    func test_isRunning_propertyReflectsInternalState() {
        // Test that isRunning property reflects internal _isRunning state
        XCTAssertFalse(sut.isRunning)
        
        sut.startSlideShow()
        XCTAssertTrue(sut.isRunning)
        
        sut.stopSlideShow()
        XCTAssertFalse(sut.isRunning)
        
        // Test toggle
        sut.toggleSlideShow()
        XCTAssertTrue(sut.isRunning)
        
        sut.toggleSlideShow()
        XCTAssertFalse(sut.isRunning)
    }
    
    func test_slideShowViewModel_handlesSettingsChanges() {
        // Start with initial interval
        mockSettingsManager.slideShowInterval = 2.0
        sut.startSlideShow()
        XCTAssertEqual(sut.currentInterval, 2.0)
        
        // Simulate settings change
        mockSettingsManager.slideShowInterval = 4.0
        sut.updateIntervalIfRunning()
        
        XCTAssertEqual(sut.currentInterval, 4.0)
        XCTAssertTrue(sut.isRunning)
    }
    
    func test_slideShowViewModel_notificationCenterIntegration() {
        // This test verifies the structure for notification handling
        // In real implementation, this would be handled by the view
        
        sut.startSlideShow(interval: 1.0)
        XCTAssertEqual(sut.currentInterval, 1.0)
        
        // Simulate interval change via settings
        mockSettingsManager.slideShowInterval = 3.0
        sut.updateIntervalIfRunning()
        
        XCTAssertEqual(sut.currentInterval, 3.0)
    }
    
    func test_slideShowViewModel_keyboardNavigationIntegration() {
        // Test that slideshow restarts properly after keyboard navigation
        sut.startSlideShow(interval: 2.0)
        XCTAssertTrue(sut.isRunning)
        
        // Simulate keyboard navigation (which should restart slideshow)
        sut.restartSlideShowIfRunning()
        
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.currentInterval, 2.0)
    }
    
    func test_slideShowViewModel_progressBarNavigationIntegration() {
        // Test that slideshow restarts properly after progress bar tap
        sut.startSlideShow(interval: 1.5)
        XCTAssertTrue(sut.isRunning)
        
        // Simulate progress bar tap navigation
        sut.restartSlideShowIfRunning()
        
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.currentInterval, 1.5)
    }
}

// MARK: - Mock ImageGalleryViewModel

@Observable
@MainActor
final class MockImageGalleryViewModel: ImageGalleryNavigationProtocol {
    var navigateToNextCallCount = 0
    var navigateToPreviousCallCount = 0
    
    var currentIndex: Int = 0
    var imageFiles: [ImageFile] = []
    
    func navigateToNext() async {
        navigateToNextCallCount += 1
    }
    
    func navigateToPrevious() async {
        navigateToPreviousCallCount += 1
    }
    
    // Synchronous version for testing
    func navigateToNextSync() {
        navigateToNextCallCount += 1
    }
}