//
//  ScaleFadeTransitionTests.swift
//  SwiftViewerTests
//

import XCTest
import SwiftUI
@testable import SwiftViewer

final class ScaleFadeTransitionTests: XCTestCase {

    func test_storesConfiguredIdentity() {
        let transition = ScaleFadeTransition(
            name: "zoomIn", displayName: "Zoom In", insertionScale: 1.2, removalScale: 0.8
        )

        XCTAssertEqual(transition.name, "zoomIn")
        XCTAssertEqual(transition.displayName, "Zoom In")
        XCTAssertEqual(transition.insertionScale, 1.2)
        XCTAssertEqual(transition.removalScale, 0.8)
    }

    func test_createTransition_returnsBareTransition_forAllScales() {
        // Duration is applied centrally by TransitionManager; the strategy just builds the shape.
        let configs: [(CGFloat, CGFloat)] = [(1.0, 1.0), (1.2, 0.8), (0.8, 1.2), (1.1, 1.1)]
        for (insertion, removal) in configs {
            let transition = ScaleFadeTransition(
                name: "t", displayName: "T", insertionScale: insertion, removalScale: removal
            )
            _ = transition.createTransition(duration: 0.3) // must not trap for any configuration
        }
    }
}
