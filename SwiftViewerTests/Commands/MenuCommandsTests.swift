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
    
    var menuState: MenuState!
    var mockSettingsManager: MockSettingsManager!
    var originalContainer: DependencyContainerProtocol!
    
    override func setUp() {
        super.setUp()
        
        // Store original container
        originalContainer = DependencyContainer.shared
        
        // Create mock settings manager
        mockSettingsManager = MockSettingsManager()
        
        // Create mock container with our mock settings
        let mockContainer = MockDependencyContainer(settingsManager: mockSettingsManager)
        
        // Create menu state with default settings
        menuState = MenuState()
    }
    
    override func tearDown() {
        menuState = nil
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
    
    // MARK: - MenuState Tests
    
    func test_menuState_initialization() {
        XCTAssertNotNil(menuState)
        XCTAssertEqual(menuState.currentDisplayMode, .fit)
        XCTAssertFalse(menuState.isFullscreen)
        XCTAssertFalse(menuState.hasRecentFolders)
    }
    
    func test_menuState_updateSortType() {
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
        
        menuState.updateSortType(.date(ascending: false))
        
        XCTAssertEqual(menuState.currentSortType, .date(ascending: false))
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    func test_menuState_updateDisplayMode() {
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
        
        menuState.updateDisplayMode(.fill)
        
        XCTAssertEqual(menuState.currentDisplayMode, .fill)
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    func test_menuState_toggleFullscreen() {
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
        
        XCTAssertFalse(menuState.isFullscreen)
        
        menuState.toggleFullscreen()
        
        XCTAssertTrue(menuState.isFullscreen)
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
        
        // Toggle again
        menuState.toggleFullscreen()
        XCTAssertFalse(menuState.isFullscreen)
    }
    
    // MARK: - Sort Type Integration Tests
    
    func test_menuState_sortType_persists_to_settings() {
        // Create a new menu state that will use the real DependencyContainer
        let menuState = MenuState()
        
        // Update sort type
        menuState.updateSortType(.size(ascending: true))
        
        // Verify it was persisted
        let settingsManager = DependencyContainer.shared.settingsManager
        XCTAssertEqual(settingsManager.sortType, .size(ascending: true))
    }
    
    func test_menuState_initializes_with_saved_sortType() {
        // Set a sort type in settings
        let settingsManager = DependencyContainer.shared.settingsManager
        settingsManager.sortType = .random
        
        // Create new menu state
        let newMenuState = MenuState()
        
        // Should initialize with the saved sort type
        XCTAssertEqual(newMenuState.currentSortType, .random)
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
    
    // MARK: - FocusedValue Keys Tests
    
    func test_focused_value_keys_exist() {
        var focusedValues = FocusedValues()
        
        // Test setting and getting actions
        let openFolderAction = { print("Open folder") }
        focusedValues.openFolderAction = openFolderAction
        XCTAssertNotNil(focusedValues.openFolderAction)
        
        let sortAction: (SortType) -> Void = { _ in print("Sort changed") }
        focusedValues.sortSelectionAction = sortAction
        XCTAssertNotNil(focusedValues.sortSelectionAction)
        
        let displayModeAction: (DisplayMode) -> Void = { _ in print("Display mode changed") }
        focusedValues.displayModeAction = displayModeAction
        XCTAssertNotNil(focusedValues.displayModeAction)
        
        let fullscreenAction = { print("Toggle fullscreen") }
        focusedValues.toggleFullscreenAction = fullscreenAction
        XCTAssertNotNil(focusedValues.toggleFullscreenAction)
    }
}

// MARK: - MenuCommands Structure Tests

final class MenuCommandsStructureTests: XCTestCase {
    
    func test_menuCommands_initialization() {
        let commands = MenuCommands()
        XCTAssertNotNil(commands)
    }
    
    func test_menuCommands_has_body() {
        let commands = MenuCommands()
        // The body property exists and can be accessed
        _ = commands.body
        // If we get here without crashing, the test passes
        XCTAssertTrue(true)
    }
}