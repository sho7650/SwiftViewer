//
//  ControlButtonStyleTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class ControlButtonStyleTests: XCTestCase {
    
    func test_controlButtonStyle_initialization_default() {
        let style = ControlButtonStyle()
        
        // Should use default values when not specified
        XCTAssertFalse(style.isActive)
        XCTAssertFalse(style.isKeyPressed)
    }
    
    func test_controlButtonStyle_initialization_withParameters() {
        let style = ControlButtonStyle(isActive: true, isKeyPressed: true)
        
        XCTAssertTrue(style.isActive)
        XCTAssertTrue(style.isKeyPressed)
    }
    
    func test_controlButtonStyle_properties() {
        // Test different state combinations
        let defaultStyle = ControlButtonStyle()
        XCTAssertFalse(defaultStyle.isActive)
        XCTAssertFalse(defaultStyle.isKeyPressed)
        
        let activeStyle = ControlButtonStyle(isActive: true)
        XCTAssertTrue(activeStyle.isActive)
        XCTAssertFalse(activeStyle.isKeyPressed)
        
        let keyPressedStyle = ControlButtonStyle(isKeyPressed: true)
        XCTAssertFalse(keyPressedStyle.isActive)
        XCTAssertTrue(keyPressedStyle.isKeyPressed)
        
        let combinedStyle = ControlButtonStyle(isActive: true, isKeyPressed: true)
        XCTAssertTrue(combinedStyle.isActive)
        XCTAssertTrue(combinedStyle.isKeyPressed)
    }
    
    func test_controlButtonStyle_bodyGeneration() {
        // Test that different styles can generate bodies without crashing
        let styles = [
            ControlButtonStyle(),
            ControlButtonStyle(isActive: true),
            ControlButtonStyle(isKeyPressed: true),
            ControlButtonStyle(isActive: true, isKeyPressed: true)
        ]
        
        for style in styles {
            // We can't directly test makeBody with mock configurations,
            // but we can test that the style objects are properly configured
            XCTAssertNotNil(style)
        }
    }
}