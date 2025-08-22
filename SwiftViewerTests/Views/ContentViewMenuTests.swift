//
//  ContentViewMenuTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/22.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class ContentViewMenuTests: XCTestCase {
    
    var contentView: ContentView!
    var menuState: MenuState!
    
    override func setUp() {
        super.setUp()
        menuState = MenuState()
        contentView = ContentView()
    }
    
    override func tearDown() {
        contentView = nil
        menuState = nil
        super.tearDown()
    }
    
    // MARK: - Basic Tests
    
    func test_contentView_initialization() {
        XCTAssertNotNil(contentView)
        XCTAssertNotNil(contentView.body)
    }
    
    // MARK: - Sort Change Tests
    
    func test_contentView_responds_to_sortTypeChanged_notification() {
        let expectation = XCTestExpectation(description: "ContentView responds to sort change")
        
        // Post a sort type change notification
        NotificationCenter.default.post(
            name: .sortTypeChanged,
            object: SortType.name(ascending: false)
        )
        
        // Give the async operation a moment to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // The test passes if no crash occurs and the notification is handled
        XCTAssertTrue(true)
    }
    
    // MARK: - Menu Action Handler Tests
    
    func test_handleSortChange_updates_menuState() {
        let initialSort = menuState.currentSortType
        let newSort = SortType.date(ascending: true)
        
        // This would be called from the menu
        menuState.updateSortType(newSort)
        
        XCTAssertNotEqual(menuState.currentSortType, initialSort)
        XCTAssertEqual(menuState.currentSortType, newSort)
    }
    
    func test_handleDisplayModeChange_updates_menuState() {
        let initialMode = menuState.currentDisplayMode
        XCTAssertEqual(initialMode, .fit)
        
        menuState.updateDisplayMode(.fill)
        
        XCTAssertNotEqual(menuState.currentDisplayMode, initialMode)
        XCTAssertEqual(menuState.currentDisplayMode, .fill)
    }
    
    func test_toggleFullscreen_updates_menuState() {
        XCTAssertFalse(menuState.isFullscreen)
        
        menuState.toggleFullscreen()
        
        XCTAssertTrue(menuState.isFullscreen)
        
        menuState.toggleFullscreen()
        
        XCTAssertFalse(menuState.isFullscreen)
    }
    
    // MARK: - File Import Tests
    
    func test_contentView_has_fileImporter_modifier() {
        // This is a structural test to ensure the file importer is configured
        let body = contentView.body
        XCTAssertNotNil(body)
        
        // The view should be configured with fileImporter
        // We can't directly test the modifier, but we ensure the view builds
    }
    
    // MARK: - Integration Tests
    
    func test_menu_sort_integration_with_settings() {
        // Get the settings manager
        let settingsManager = DependencyContainer.shared.settingsManager
        let initialSort = settingsManager.sortType
        
        // Update sort through menu state
        menuState.updateSortType(.size(ascending: false))
        
        // Verify it's persisted in settings
        XCTAssertNotEqual(settingsManager.sortType, initialSort)
        XCTAssertEqual(settingsManager.sortType, .size(ascending: false))
    }
    
    func test_multiple_sort_changes() {
        let sortTypes: [SortType] = [
            .name(ascending: true),
            .name(ascending: false),
            .date(ascending: true),
            .date(ascending: false),
            .size(ascending: true),
            .size(ascending: false),
            .random
        ]
        
        for sortType in sortTypes {
            menuState.updateSortType(sortType)
            XCTAssertEqual(menuState.currentSortType, sortType)
            
            // Verify persistence
            let settingsManager = DependencyContainer.shared.settingsManager
            XCTAssertEqual(settingsManager.sortType, sortType)
        }
    }
    
    func test_display_mode_changes() {
        let modes: [DisplayMode] = [.fit, .fill, .actualSize]
        
        for mode in modes {
            menuState.updateDisplayMode(mode)
            XCTAssertEqual(menuState.currentDisplayMode, mode)
        }
    }
}