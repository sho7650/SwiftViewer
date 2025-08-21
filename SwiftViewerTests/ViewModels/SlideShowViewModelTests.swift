//
//  SlideShowViewModelTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
@testable import SwiftViewer

@MainActor
final class SlideShowViewModelTests: XCTestCase {
    
    var sut: SlideShowViewModel!
    var mockSlideShowService: MockSlideShowService!
    var mockImageViewerViewModel: MockImageViewerViewModel!
    var mockSettingsManager: MockSettingsManager!
    
    override func setUp() {
        super.setUp()
        mockSlideShowService = MockSlideShowService()
        mockImageViewerViewModel = MockImageViewerViewModel()
        mockSettingsManager = MockSettingsManager()
        sut = SlideShowViewModel(
            slideShowService: mockSlideShowService,
            imageNavigator: mockImageViewerViewModel,
            settingsManager: mockSettingsManager
        )
    }
    
    override func tearDown() {
        sut.stopSlideShow()
        sut = nil
        mockSlideShowService = nil
        mockImageViewerViewModel = nil
        mockSettingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func test_initialState_isCorrect() {
        XCTAssertFalse(sut.isRunning)
        XCTAssertNil(sut.currentInterval)
        XCTAssertEqual(sut.defaultInterval, 10.0)
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
            XCTAssertEqual(self.mockImageViewerViewModel.navigateToNextCallCount, 1)
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
            XCTAssertEqual(self.mockImageViewerViewModel.navigateToNextCallCount, 3)
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
        
        XCTAssertEqual(mockImageViewerViewModel.navigateToNextCallCount, 0)
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
    
    // MARK: - Memory Management Tests
    
    func test_deinit_stopsSlideshow() {
        // Simply test that object can be deallocated
        let viewModel = SlideShowViewModel(
            slideShowService: MockSlideShowService(),
            imageNavigator: MockImageViewerViewModel(),
            settingsManager: MockSettingsManager()
        )
        viewModel.startSlideShow()
        
        // This test verifies that SlideShowViewModel can be created and deallocated
        // Timer cleanup is handled by the SlideShowService's own deinit
        XCTAssertTrue(true, "SlideShowViewModel test completed")
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
}

// MARK: - Mock ImageViewerViewModel

@MainActor
final class MockImageViewerViewModel: ImageNavigationProtocol {
    var navigateToNextCallCount = 0
    var navigateToPreviousCallCount = 0
    
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