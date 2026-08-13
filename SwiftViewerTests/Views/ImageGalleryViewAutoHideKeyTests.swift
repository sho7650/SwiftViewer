//
//  ImageGalleryViewAutoHideKeyTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2026/08/13.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

/// Arrow-key navigation must leave the auto-hidden player alone: once it has faded
/// out, browsing with the keyboard must not bring it back, and while it is still
/// visible the arrows must not extend its timer either. Every other key counts as
/// user activity and wakes the controls as before.
@MainActor
final class ImageGalleryViewAutoHideKeyTests: XCTestCase {

    // MARK: - Navigation Keys

    func test_leftAndRightArrows_doNotAffectAutoHideControls() {
        XCTAssertFalse(ImageGalleryView.affectsAutoHideControls(.leftArrow))
        XCTAssertFalse(ImageGalleryView.affectsAutoHideControls(.rightArrow))
    }

    func test_upAndDownArrows_doNotAffectAutoHideControls() {
        // Up/down perform the same navigation as left/right, so they behave alike.
        XCTAssertFalse(ImageGalleryView.affectsAutoHideControls(.upArrow))
        XCTAssertFalse(ImageGalleryView.affectsAutoHideControls(.downArrow))
    }

    // MARK: - Non-Navigation Keys

    func test_space_affectsAutoHideControls() {
        // Space toggles the slideshow, so the player should reappear to show the change.
        XCTAssertTrue(ImageGalleryView.affectsAutoHideControls(.space))
    }

    func test_unhandledKeys_affectAutoHideControls() {
        // Any other key still counts as user activity.
        XCTAssertTrue(ImageGalleryView.affectsAutoHideControls(KeyEquivalent("f")))
        XCTAssertTrue(ImageGalleryView.affectsAutoHideControls(.return))
        XCTAssertTrue(ImageGalleryView.affectsAutoHideControls(.escape))
        XCTAssertTrue(ImageGalleryView.affectsAutoHideControls(.tab))
    }

    func test_pagingKeys_affectAutoHideControls() {
        // Only the four arrows are exempt; nothing else is silently swept in.
        XCTAssertTrue(ImageGalleryView.affectsAutoHideControls(.pageUp))
        XCTAssertTrue(ImageGalleryView.affectsAutoHideControls(.pageDown))
        XCTAssertTrue(ImageGalleryView.affectsAutoHideControls(.home))
        XCTAssertTrue(ImageGalleryView.affectsAutoHideControls(.end))
    }
}
