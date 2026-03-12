//
//  AutoHideControlsManagerTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/03/13.
//

import XCTest
@testable import SwiftViewer

@MainActor
final class AutoHideControlsManagerStandaloneTests: XCTestCase {

    var sut: AutoHideControlsManager!

    override func setUp() {
        super.setUp()
        sut = AutoHideControlsManager(slideShowViewModel: nil, imageGalleryViewModel: nil)
    }

    override func tearDown() {
        sut.cleanupTimer()
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialState_controlsAreVisible() {
        XCTAssertTrue(sut.areControlsVisible)
    }

    // MARK: - Show/Hide

    func test_hideControlsImmediately_hidesControls() {
        sut.hideControlsImmediately()

        XCTAssertFalse(sut.areControlsVisible)
    }

    func test_showControlsAndResetTimer_showsControls() {
        sut.hideControlsImmediately()
        XCTAssertFalse(sut.areControlsVisible)

        sut.showControlsAndResetTimer()

        XCTAssertTrue(sut.areControlsVisible)
    }

    // MARK: - Activity Registration

    func test_registerActivity_showsControls() {
        sut.hideControlsImmediately()

        sut.registerActivity()

        XCTAssertTrue(sut.areControlsVisible)
    }

    func test_registerActivity_updatesLastActivityTime() {
        let timeBefore = sut.lastActivityTime

        // Small delay to ensure different timestamp
        Thread.sleep(forTimeInterval: 0.01)
        sut.registerActivity()

        XCTAssertGreaterThan(sut.lastActivityTime, timeBefore)
    }

    // MARK: - Auto-Hide Conditions

    func test_shouldAllowAutoHide_noViewModels_returnsTrue() {
        let manager = AutoHideControlsManager(slideShowViewModel: nil, imageGalleryViewModel: nil)

        XCTAssertTrue(manager.shouldAllowAutoHide())
    }

    func test_shouldAllowAutoHide_galleryLoading_returnsFalse() {
        let mockDeps = MockDependencyContainer()
        let galleryVM = ImageGalleryViewModel(dependencies: mockDeps)
        galleryVM.isLoading = true

        let manager = AutoHideControlsManager(slideShowViewModel: nil, imageGalleryViewModel: galleryVM)

        XCTAssertFalse(manager.shouldAllowAutoHide())
    }

    func test_shouldAllowAutoHide_galleryHasError_returnsFalse() {
        let mockDeps = MockDependencyContainer()
        let galleryVM = ImageGalleryViewModel(dependencies: mockDeps)
        galleryVM.errorMessage = "Test error"

        let manager = AutoHideControlsManager(slideShowViewModel: nil, imageGalleryViewModel: galleryVM)

        XCTAssertFalse(manager.shouldAllowAutoHide())
    }

    // MARK: - Mock

    func test_mockAutoHide_tracksRegisterActivityCalls() {
        let mock = MockAutoHideControlsManager(slideShowViewModel: nil, imageGalleryViewModel: nil)

        mock.registerActivity()
        mock.registerActivity()
        mock.registerActivity()

        XCTAssertEqual(mock.registerActivityCallCount, 3)
    }

    func test_mockAutoHide_simulateTimerFire_hidesWhenAllowed() {
        let mock = MockAutoHideControlsManager(slideShowViewModel: nil, imageGalleryViewModel: nil)
        mock.mockShouldAllowAutoHide = true

        mock.simulateTimerFire()

        XCTAssertFalse(mock.areControlsVisible)
        XCTAssertEqual(mock.hideTimerFireCount, 1)
    }

    func test_mockAutoHide_simulateTimerFire_doesNotHideWhenDisallowed() {
        let mock = MockAutoHideControlsManager(slideShowViewModel: nil, imageGalleryViewModel: nil)
        mock.mockShouldAllowAutoHide = false

        mock.simulateTimerFire()

        XCTAssertTrue(mock.areControlsVisible)
    }

    // MARK: - Cleanup

    func test_cleanupTimer_canBeCalledSafely() {
        sut.cleanupTimer()
        sut.cleanupTimer() // Double cleanup should not crash

        XCTAssertTrue(true) // No crash = pass
    }
}
