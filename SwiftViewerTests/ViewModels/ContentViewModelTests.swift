//
//  ContentViewModelTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/03/13.
//

import XCTest
@testable import SwiftViewer

@MainActor
final class ContentViewModelTests: XCTestCase {

    var sut: ContentViewModel!
    var mockSettings: MockSettingsManager!

    override func setUp() {
        super.setUp()
        mockSettings = MockSettingsManager()
        sut = ContentViewModel(settingsManager: mockSettings)
    }

    override func tearDown() {
        sut = nil
        mockSettings = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func assertPostsNotification(_ name: Notification.Name, when action: () -> Void) {
        let expectation = expectation(forNotification: name, object: nil)
        action()
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Initialization

    func test_init_loadsSortTypeFromSettings() {
        mockSettings.sortType = .date(ascending: false)
        let vm = ContentViewModel(settingsManager: mockSettings)

        XCTAssertEqual(vm.currentSortType, .date(ascending: false))
    }

    func test_init_loadsRepeatFromSettings() {
        mockSettings.repeatEnabled = true
        let vm = ContentViewModel(settingsManager: mockSettings)

        XCTAssertTrue(vm.isRepeatEnabled)
    }

    func test_init_loadsWindowPositionFromSettings() {
        mockSettings.windowPosition = .alwaysOnTop
        let vm = ContentViewModel(settingsManager: mockSettings)

        XCTAssertEqual(vm.currentWindowPosition, .alwaysOnTop)
    }

    // MARK: - Sort Management

    func test_updateSortType_updatesProperty() {
        sut.updateSortType(.size(ascending: true))

        XCTAssertEqual(sut.currentSortType, .size(ascending: true))
    }

    func test_updateSortType_persistsToSettings() {
        sut.updateSortType(.date(ascending: false))

        XCTAssertEqual(mockSettings.sortType, .date(ascending: false))
    }

    func test_updateSortType_postsNotification() {
        assertPostsNotification(.sortTypeChanged) {
            sut.updateSortType(.random)
        }
    }

    // MARK: - Display Mode Management

    func test_updateDisplayMode_updatesProperty() {
        sut.updateDisplayMode(.fill)

        XCTAssertEqual(sut.currentDisplayMode, .fill)
    }

    func test_updateDisplayMode_postsNotification() {
        assertPostsNotification(.displayModeChanged) {
            sut.updateDisplayMode(.fill)
        }
    }

    // MARK: - Fullscreen Management

    func test_toggleFullscreen_togglesState() {
        XCTAssertFalse(sut.isFullscreen)

        sut.toggleFullscreen()
        XCTAssertTrue(sut.isFullscreen)

        sut.toggleFullscreen()
        XCTAssertFalse(sut.isFullscreen)
    }

    func test_toggleFullscreen_postsNotification() {
        assertPostsNotification(.fullscreenToggled) {
            sut.toggleFullscreen()
        }
    }

    // MARK: - Repeat Management

    func test_toggleRepeat_togglesState() {
        XCTAssertFalse(sut.isRepeatEnabled)

        sut.toggleRepeat()
        XCTAssertTrue(sut.isRepeatEnabled)

        sut.toggleRepeat()
        XCTAssertFalse(sut.isRepeatEnabled)
    }

    func test_toggleRepeat_persistsToSettings() {
        sut.toggleRepeat()

        XCTAssertTrue(mockSettings.repeatEnabled)
    }

    func test_toggleRepeat_postsNotification() {
        assertPostsNotification(.repeatModeChanged) {
            sut.toggleRepeat()
        }
    }

    // MARK: - Window Position Management

    func test_updateWindowPosition_updatesProperty() {
        sut.updateWindowPosition(.alwaysOnTop)

        XCTAssertEqual(sut.currentWindowPosition, .alwaysOnTop)
    }

    func test_updateWindowPosition_persistsToSettings() {
        sut.updateWindowPosition(.alwaysOnBottom)

        XCTAssertEqual(mockSettings.windowPosition, .alwaysOnBottom)
    }

    func test_updateWindowPosition_postsNotification() {
        assertPostsNotification(.windowPositionChanged) {
            sut.updateWindowPosition(.alwaysOnTop)
        }
    }
}
