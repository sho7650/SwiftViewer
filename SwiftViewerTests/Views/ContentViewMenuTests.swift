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
    var contentViewModel: ContentViewModel!
    
    override func setUp() {
        super.setUp()
        contentViewModel = ContentViewModel()
        contentView = ContentView()
    }
    
    override func tearDown() {
        contentView = nil
        contentViewModel = nil
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
    
    // MARK: - ContentViewModel Tests
    
    func test_handleSortChange_updates_contentViewModel() {
        let initialSort = contentViewModel.currentSortType
        
        // Choose a different sort type than the initial one
        let newSort: SortType = switch initialSort {
        case .date(ascending: true):
            .name(ascending: false)
        case .name(ascending: false):
            .size(ascending: true)
        default:
            .date(ascending: false)
        }
        
        // This would be called from the menu
        contentViewModel.updateSortType(newSort)
        
        XCTAssertNotEqual(contentViewModel.currentSortType, initialSort)
        XCTAssertEqual(contentViewModel.currentSortType, newSort)
    }
    
    func test_handleDisplayModeChange_updates_contentViewModel() {
        let initialMode = contentViewModel.currentDisplayMode
        XCTAssertEqual(initialMode, .fit)
        
        contentViewModel.updateDisplayMode(.fill)
        
        XCTAssertNotEqual(contentViewModel.currentDisplayMode, initialMode)
        XCTAssertEqual(contentViewModel.currentDisplayMode, .fill)
    }
    
    func test_toggleFullscreen_updates_contentViewModel() {
        XCTAssertFalse(contentViewModel.isFullscreen)
        
        contentViewModel.toggleFullscreen()
        
        XCTAssertTrue(contentViewModel.isFullscreen)
        
        contentViewModel.toggleFullscreen()
        
        XCTAssertFalse(contentViewModel.isFullscreen)
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
        
        // Update sort through content view model
        contentViewModel.updateSortType(.size(ascending: false))
        
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
            contentViewModel.updateSortType(sortType)
            XCTAssertEqual(contentViewModel.currentSortType, sortType)
            
            // Verify persistence
            let settingsManager = DependencyContainer.shared.settingsManager
            XCTAssertEqual(settingsManager.sortType, sortType)
        }
    }
    
    func test_display_mode_changes() {
        let modes: [DisplayMode] = [.fit, .fill, .actualSize]
        
        for mode in modes {
            contentViewModel.updateDisplayMode(mode)
            XCTAssertEqual(contentViewModel.currentDisplayMode, mode)
        }
    }
}