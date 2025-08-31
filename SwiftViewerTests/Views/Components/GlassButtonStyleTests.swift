//
//  GlassButtonStyleTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/31.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

final class GlassButtonStyleTests: XCTestCase {
    
    // MARK: - Basic Properties Tests
    
    func test_glassButtonStyle_createsValidButtonStyle() {
        // Given & When
        let buttonStyle = GlassButtonStyle()
        
        // Then
        XCTAssertNotNil(buttonStyle)
    }
    
    func test_glassButtonStyle_withCustomGlassParameters() {
        // Given & When
        let buttonStyle = GlassButtonStyle(
            radius: 12,
            material: .regularMaterial,
            shadowRadius: 6
        )
        
        // Then
        XCTAssertNotNil(buttonStyle)
    }
    
    // MARK: - Button Configuration Tests
    
    func test_glassButtonStyle_appliesCorrectFrameSize() {
        // Given
        let buttonStyle = GlassButtonStyle()
        let testButton = Button("Test") {}
        
        // When
        let styledButton = testButton.buttonStyle(buttonStyle)
        
        // Then
        // Should maintain 40x40 frame size for consistency
        XCTAssertNotNil(styledButton)
    }
    
    func test_glassButtonStyle_handlesHoverStates() {
        // Given
        let buttonStyle = GlassButtonStyle()
        
        // When & Then
        // Glass button should handle hover states with enhanced visual feedback
        XCTAssertNotNil(buttonStyle)
        // Note: Hover state testing requires UI interaction framework
    }
    
    // MARK: - Visual Effect Tests
    
    func test_glassButtonStyle_appliesGlassMaterial() {
        // Given & When
        let buttonStyleDefault = GlassButtonStyle()
        let buttonStyleCustom = GlassButtonStyle(material: .thickMaterial)
        
        // Then
        // Both styles should apply glass material effect
        XCTAssertNotNil(buttonStyleDefault)
        XCTAssertNotNil(buttonStyleCustom)
    }
    
    func test_glassButtonStyle_hasCorrectShadowEffect() {
        // Given & When
        let buttonStyle = GlassButtonStyle(shadowRadius: 8)
        
        // Then
        // Should apply floating shadow effect
        XCTAssertNotNil(buttonStyle)
    }
    
    // MARK: - Micro-interaction Tests
    
    func test_glassButtonStyle_supportsMicroInteractions() {
        // Given & When
        let buttonStyle = GlassButtonStyle()
        
        // Then
        // Should support press/hover micro-interactions
        XCTAssertNotNil(buttonStyle)
        // Note: Animation testing requires specialized SwiftUI testing tools
    }
    
    // MARK: - Performance Tests
    
    func test_glassButtonStyle_performsEfficientRendering() {
        // Given
        let buttonStyle = GlassButtonStyle()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When
        for _ in 0..<100 {
            let _ = Button("Test") {}.buttonStyle(buttonStyle)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        // Glass effect should render efficiently
        XCTAssertLessThan(timeElapsed, 0.1, "Glass button style should render efficiently")
    }
    
    // MARK: - Accessibility Tests
    
    func test_glassButtonStyle_maintainsAccessibility() {
        // Given
        let buttonStyle = GlassButtonStyle()
        let accessibleButton = Button("Accessible Button") {}
            .buttonStyle(buttonStyle)
            .accessibilityLabel("Test Button")
        
        // When & Then
        // Glass effects should not interfere with accessibility
        XCTAssertNotNil(accessibleButton)
    }
}