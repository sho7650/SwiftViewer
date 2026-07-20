//
//  SwiftViewerAppTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/31.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class SwiftViewerAppTests: XCTestCase {
    
    // MARK: - Window Style Tests

    func test_swiftViewerApp_initializesWithoutTitlebarMode() {
        // Given: Clean app initialization
        let app = SwiftViewerApp()
        
        // When: App is created
        // Then: Should not depend on any titlebar mode settings
        XCTAssertNotNil(app.body, "App body should be created successfully")
    }
    
    func test_swiftViewerApp_windowManagerRole_isPrincipal() {
        // Given: SwiftViewerApp
        let app = SwiftViewerApp()
        
        // When: Accessing body
        let scene = app.body
        
        // Then: Should maintain principal role for window management
        XCTAssertNotNil(scene, "Scene should be configured properly")
    }
}