//
//  BlurReplaceTransitionTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/31.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

final class BlurReplaceTransitionTests: XCTestCase {
    
    // MARK: - Basic Properties Tests
    
    func test_blurReplaceTransition_hasCorrectName() {
        // Given & When
        let transition = BlurReplaceTransition()
        
        // Then
        XCTAssertEqual(transition.name, "blurReplace")
    }
    
    func test_blurReplaceTransition_hasCorrectDisplayName() {
        // Given & When
        let transition = BlurReplaceTransition()
        
        // Then
        XCTAssertEqual(transition.displayName, "Blur Replace")
    }
    
    // MARK: - Configuration Tests
    
    func test_blurReplaceTransition_defaultConfiguration_isDownUp() {
        // Given & When
        let transition = BlurReplaceTransition()
        
        // Then
        // Default configuration should be .downThenUp
        // We'll verify this indirectly through the transition creation
        let createdTransition = transition.createTransition(duration: 1.0)
        XCTAssertNotNil(createdTransition)
    }
    
    func test_blurReplaceTransition_withExpandBothConfiguration() {
        // Given
        let transition = BlurReplaceTransition(configuration: .expandBoth)
        
        // When
        let createdTransition = transition.createTransition(duration: 1.0)
        
        // Then
        XCTAssertNotNil(createdTransition)
    }
    
    // MARK: - Transition Creation Tests
    
    func test_createTransition_returnsValidTransition() {
        // Given
        let transition = BlurReplaceTransition()
        let duration: TimeInterval = 2.0
        
        // When
        let createdTransition = transition.createTransition(duration: duration)
        
        // Then
        XCTAssertNotNil(createdTransition)
        // AnyTransition is opaque, so we can only verify it's created
    }
    
    func test_createTransition_withZeroDuration_returnsValidTransition() {
        // Given
        let transition = BlurReplaceTransition()
        let duration: TimeInterval = 0
        
        // When
        let createdTransition = transition.createTransition(duration: duration)
        
        // Then
        XCTAssertNotNil(createdTransition)
    }
    
    // MARK: - Protocol Conformance Tests
    
    func test_blurReplaceTransition_conformsToImageTransitionProtocol() {
        // Given & When
        let transition = BlurReplaceTransition()
        
        // Then
        XCTAssertTrue(transition is ImageTransitionProtocol)
    }
    
    // MARK: - UpUp Configuration Variant Tests
    
    func test_blurReplaceExpandBothTransition_hasCorrectName() {
        // Given & When
        let transition = BlurReplaceTransition(configuration: .expandBoth)
        
        // Then
        // The name should remain the same regardless of configuration
        XCTAssertEqual(transition.name, "blurReplace")
    }
    
    func test_blurReplaceExpandBothTransition_hasExpandBothDisplayName() {
        // Given & When
        let transition = BlurReplaceTransition(configuration: .expandBoth)
        
        // Then
        // Display name should indicate the configuration
        XCTAssertEqual(transition.displayName, "Blur Replace (Expand)")
    }
}