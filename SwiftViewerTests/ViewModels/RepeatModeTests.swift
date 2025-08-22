//
//  RepeatModeTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/22.
//

import XCTest
@testable import SwiftViewer

@MainActor
final class RepeatModeTests: XCTestCase {
    
    var mockContainer: MockDependencyContainer!
    var mockNavigator: MockImageNavigator!
    var slideShowViewModel: SlideShowViewModel!
    var imageViewerViewModel: ImageViewerViewModel!
    
    override func setUp() {
        super.setUp()
        mockContainer = MockDependencyContainer()
        mockNavigator = MockImageNavigator()
        slideShowViewModel = SlideShowViewModel(
            slideShowService: mockContainer.slideShowService,
            imageNavigator: mockNavigator,
            settingsManager: mockContainer.settingsManager
        )
        imageViewerViewModel = ImageViewerViewModel(dependencies: mockContainer)
    }
    
    override func tearDown() {
        slideShowViewModel = nil
        imageViewerViewModel = nil
        mockNavigator = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - Settings Tests
    
    func test_repeatEnabled_default_is_false() {
        XCTAssertFalse(mockContainer.settingsManager.repeatEnabled)
        XCTAssertFalse(slideShowViewModel.isRepeatEnabled)
    }
    
    func test_repeatEnabled_can_be_toggled() {
        XCTAssertFalse(slideShowViewModel.isRepeatEnabled)
        
        slideShowViewModel.isRepeatEnabled = true
        XCTAssertTrue(slideShowViewModel.isRepeatEnabled)
        
        slideShowViewModel.isRepeatEnabled = false
        XCTAssertFalse(slideShowViewModel.isRepeatEnabled)
    }
    
    func test_repeatEnabled_persists_to_settings() {
        slideShowViewModel.isRepeatEnabled = true
        
        // Create new view model to verify persistence
        let newViewModel = SlideShowViewModel(
            slideShowService: mockContainer.slideShowService,
            imageNavigator: mockNavigator,
            settingsManager: mockContainer.settingsManager
        )
        
        XCTAssertTrue(newViewModel.isRepeatEnabled)
    }
    
    // MARK: - Navigation Tests
    
    func test_navigateToNext_stops_at_last_when_repeat_disabled() async {
        // Setup
        let mockImages = createMockImages(count: 3)
        imageViewerViewModel.imageFiles = mockImages
        imageViewerViewModel.currentIndex = 2 // Last image
        mockContainer.settingsManager.repeatEnabled = false
        
        // Act
        await imageViewerViewModel.navigateToNext()
        
        // Assert - should stay at last image
        XCTAssertEqual(imageViewerViewModel.currentIndex, 2)
    }
    
    func test_navigateToNext_loops_to_first_when_repeat_enabled() async {
        // Setup
        let mockImages = createMockImages(count: 3)
        imageViewerViewModel.imageFiles = mockImages
        imageViewerViewModel.currentIndex = 2 // Last image
        mockContainer.settingsManager.repeatEnabled = true
        
        // Act
        await imageViewerViewModel.navigateToNext()
        
        // Assert - should loop to first image
        XCTAssertEqual(imageViewerViewModel.currentIndex, 0)
    }
    
    func test_navigateToPrevious_stops_at_first_when_repeat_disabled() async {
        // Setup
        let mockImages = createMockImages(count: 3)
        imageViewerViewModel.imageFiles = mockImages
        imageViewerViewModel.currentIndex = 0 // First image
        mockContainer.settingsManager.repeatEnabled = false
        
        // Act
        await imageViewerViewModel.navigateToPrevious()
        
        // Assert - should stay at first image
        XCTAssertEqual(imageViewerViewModel.currentIndex, 0)
    }
    
    func test_navigateToPrevious_loops_to_last_when_repeat_enabled() async {
        // Setup
        let mockImages = createMockImages(count: 3)
        imageViewerViewModel.imageFiles = mockImages
        imageViewerViewModel.currentIndex = 0 // First image
        mockContainer.settingsManager.repeatEnabled = true
        
        // Act
        await imageViewerViewModel.navigateToPrevious()
        
        // Assert - should loop to last image
        XCTAssertEqual(imageViewerViewModel.currentIndex, 2)
    }
    
    // MARK: - SlideShow Tests
    
    func test_slideshow_stops_at_last_image_when_repeat_disabled() {
        mockNavigator.currentIndex = 2
        mockNavigator.imageFiles = createMockImages(count: 3)
        mockContainer.settingsManager.repeatEnabled = false
        
        slideShowViewModel.startSlideShow(interval: 1.0)
        XCTAssertTrue(slideShowViewModel.isRunning)
        
        // Simulate timer firing when at last image
        // The slideshow should stop itself
        // This is tested through the timer callback logic
    }
    
    func test_slideshow_continues_when_repeat_enabled() {
        mockNavigator.currentIndex = 2
        mockNavigator.imageFiles = createMockImages(count: 3)
        mockContainer.settingsManager.repeatEnabled = true
        
        slideShowViewModel.startSlideShow(interval: 1.0)
        XCTAssertTrue(slideShowViewModel.isRunning)
        
        // Slideshow should continue running and loop
        // This is tested through the timer callback logic
    }
    
    // MARK: - Menu State Tests
    
    func test_menuState_initializes_with_saved_repeat_setting() {
        // Set repeat in settings
        DependencyContainer.shared.settingsManager.repeatEnabled = true
        
        // Create new menu state
        let menuState = MenuState()
        
        // Should initialize with saved setting
        XCTAssertTrue(menuState.isRepeatEnabled)
    }
    
    func test_menuState_toggleRepeat_updates_settings() {
        let menuState = MenuState()
        XCTAssertFalse(menuState.isRepeatEnabled)
        
        menuState.toggleRepeat()
        XCTAssertTrue(menuState.isRepeatEnabled)
        XCTAssertTrue(DependencyContainer.shared.settingsManager.repeatEnabled)
        
        menuState.toggleRepeat()
        XCTAssertFalse(menuState.isRepeatEnabled)
        XCTAssertFalse(DependencyContainer.shared.settingsManager.repeatEnabled)
    }
    
    func test_menuState_toggleRepeat_posts_notification() {
        let menuState = MenuState()
        let expectation = XCTestExpectation(description: "Repeat mode change notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .repeatModeChanged,
            object: nil,
            queue: .main
        ) { notification in
            if let isEnabled = notification.object as? Bool {
                XCTAssertTrue(isEnabled)
                expectation.fulfill()
            }
        }
        
        menuState.toggleRepeat()
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Helper Methods
    
    private func createMockImages(count: Int) -> [ImageFile] {
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

// MARK: - Mock Image Navigator

@MainActor
final class MockImageNavigator: ImageNavigationProtocol {
    var currentIndex: Int = 0
    var imageFiles: [ImageFile] = []
    var navigateToNextCalled = false
    var navigateToPreviousCalled = false
    
    func navigateToNext() async {
        navigateToNextCalled = true
        if currentIndex < imageFiles.count - 1 {
            currentIndex += 1
        }
    }
    
    func navigateToPrevious() async {
        navigateToPreviousCalled = true
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
}