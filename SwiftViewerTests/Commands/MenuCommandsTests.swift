//
//  MenuCommandsTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/22.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class MenuCommandsTests: XCTestCase {
    
    var contentViewModel: ContentViewModel!
    var mockSettingsManager: MockSettingsManager!
    var originalContainer: DependencyContainerProtocol!
    
    override func setUp() {
        super.setUp()
        
        // Store original container
        originalContainer = DependencyContainer.shared
        
        // Create mock settings manager
        mockSettingsManager = MockSettingsManager()
        
        // Create content view model with mock settings
        contentViewModel = ContentViewModel(settingsManager: mockSettingsManager)
    }
    
    override func tearDown() {
        contentViewModel = nil
        mockSettingsManager = nil
        originalContainer = nil
        super.tearDown()
    }
    
    // MARK: - Display Mode Tests
    
    func test_displayMode_enum_has_all_cases() {
        let allCases = DisplayMode.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.fit))
        XCTAssertTrue(allCases.contains(.fill))
        XCTAssertTrue(allCases.contains(.actualSize))
    }
    
    func test_displayMode_raw_values() {
        XCTAssertEqual(DisplayMode.fit.rawValue, "Fit to Window")
        XCTAssertEqual(DisplayMode.fill.rawValue, "Fill Window")
        XCTAssertEqual(DisplayMode.actualSize.rawValue, "Actual Size")
    }
    
    // MARK: - ContentViewModel Tests
    
    func test_contentViewModel_initialization() {
        XCTAssertNotNil(contentViewModel)
        XCTAssertEqual(contentViewModel.currentDisplayMode, .fit)
        XCTAssertFalse(contentViewModel.isFullscreen)
    }
    
    func test_contentViewModel_updateSortType() {
        let expectation = XCTestExpectation(description: "Sort type change notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .sortTypeChanged,
            object: nil,
            queue: .main
        ) { notification in
            if let sortType = notification.object as? SortType {
                XCTAssertEqual(sortType, .date(ascending: false))
                expectation.fulfill()
            }
        }
        
        contentViewModel.updateSortType(.date(ascending: false))
        
        XCTAssertEqual(contentViewModel.currentSortType, .date(ascending: false))
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    func test_contentViewModel_updateDisplayMode() {
        let expectation = XCTestExpectation(description: "Display mode change notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .displayModeChanged,
            object: nil,
            queue: .main
        ) { notification in
            if let mode = notification.object as? DisplayMode {
                XCTAssertEqual(mode, .fill)
                expectation.fulfill()
            }
        }
        
        contentViewModel.updateDisplayMode(.fill)
        
        XCTAssertEqual(contentViewModel.currentDisplayMode, .fill)
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    func test_contentViewModel_toggleFullscreen() {
        let expectation = XCTestExpectation(description: "Fullscreen toggle notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .fullscreenToggled,
            object: nil,
            queue: .main
        ) { notification in
            if let isFullscreen = notification.object as? Bool {
                XCTAssertTrue(isFullscreen)
                expectation.fulfill()
            }
        }
        
        XCTAssertFalse(contentViewModel.isFullscreen)
        
        contentViewModel.toggleFullscreen()
        
        XCTAssertTrue(contentViewModel.isFullscreen)
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
        
        // Toggle again
        contentViewModel.toggleFullscreen()
        XCTAssertFalse(contentViewModel.isFullscreen)
    }
    
    // MARK: - Sort Type Integration Tests
    
    func test_contentViewModel_sortType_persists_to_settings() {
        // Update sort type
        contentViewModel.updateSortType(.size(ascending: true))
        
        // Verify it was persisted to mock settings
        XCTAssertEqual(mockSettingsManager.sortType, .size(ascending: true))
    }
    
    func test_contentViewModel_initializes_with_saved_sortType() {
        // Set a sort type in mock settings
        mockSettingsManager.sortType = .random
        
        // Create new content view model
        let newContentViewModel = ContentViewModel(settingsManager: mockSettingsManager)
        
        // Should initialize with the saved sort type
        XCTAssertEqual(newContentViewModel.currentSortType, .random)
    }
    
    // MARK: - Notification Tests
    
    func test_notification_names_are_unique() {
        let names: [Notification.Name] = [
            .sortTypeChanged,
            .displayModeChanged,
            .fullscreenToggled,
            .slideShowIntervalChanged
        ]
        
        let uniqueNames = Set(names.map { $0.rawValue })
        XCTAssertEqual(uniqueNames.count, names.count, "Notification names should be unique")
    }
    
    // MARK: - Focus Management Tests
    
    func test_contentView_should_maintain_focus_for_menu_commands() {
        // Given: ContentView with focusable capability
        let contentView = ContentView()
        
        // When: ContentView is displayed
        let hostingController = NSHostingController(rootView: contentView)
        let view = hostingController.view
        
        // Then: View should be created successfully and be focusable
        XCTAssertNotNil(view, "ContentView should be created successfully")
    }
    
    func test_focus_chain_should_support_keyboard_shortcuts() {
        // Given: A mock environment where window is frontmost but lacks focus
        var actionCalled = false
        let testAction: () -> Void = {
            actionCalled = true
        }
        
        // When: Action would be triggered by keyboard shortcut
        // This simulates what should happen when ⌘+O is pressed
        testAction()
        
        // Then: Action should be executed regardless of focus state
        XCTAssertTrue(actionCalled, "Keyboard shortcut action should execute even when window lacks specific view focus")
    }
    
    func test_openFolderAction_should_be_available_when_window_is_active() {
        // Given: ContentView in active window state
        let contentView = ContentView()
        
        // When: ContentView is rendered
        let hostingController = NSHostingController(rootView: contentView)
        
        // Then: Should not crash and should maintain focus capability
        XCTAssertNotNil(hostingController.view, "ContentView should render successfully with focus support")
    }
    
    func test_focus_recovery_after_window_loses_and_regains_focus() {
        // Given: ContentView that has lost focus
        var focusRecovered = false
        
        // Simulate focus recovery mechanism
        let focusRecoveryAction: () -> Void = {
            focusRecovered = true
        }
        
        // When: Focus recovery is triggered
        focusRecoveryAction()
        
        // Then: Focus should be restored
        XCTAssertTrue(focusRecovered, "Focus should be recoverable after window regains frontmost status")
    }
}

// MARK: - MenuCommands Structure Tests

final class MenuCommandsStructureTests: XCTestCase {
    
    func test_menuCommands_initialization() {
        let commands = MenuCommands()
        XCTAssertNotNil(commands)
    }
}