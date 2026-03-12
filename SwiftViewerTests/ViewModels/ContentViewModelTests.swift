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
        let expectation = expectation(forNotification: .sortTypeChanged, object: nil)

        sut.updateSortType(.random)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Display Mode Management

    func test_updateDisplayMode_updatesProperty() {
        sut.updateDisplayMode(.fill)

        XCTAssertEqual(sut.currentDisplayMode, .fill)
    }

    func test_updateDisplayMode_postsNotification() {
        let expectation = expectation(forNotification: .displayModeChanged, object: nil)

        sut.updateDisplayMode(.fill)

        wait(for: [expectation], timeout: 1.0)
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
        let expectation = expectation(forNotification: .fullscreenToggled, object: nil)

        sut.toggleFullscreen()

        wait(for: [expectation], timeout: 1.0)
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
        let expectation = expectation(forNotification: .repeatModeChanged, object: nil)

        sut.toggleRepeat()

        wait(for: [expectation], timeout: 1.0)
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
        let expectation = expectation(forNotification: .windowPositionChanged, object: nil)

        sut.updateWindowPosition(.alwaysOnTop)

        wait(for: [expectation], timeout: 1.0)
    }
}
