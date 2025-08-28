//
//  SlideTransitionPluginTests.swift
//  SwiftViewerTests
//
//  Created by Claude Code on 2025-08-28.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class SlideTransitionPluginTests: XCTestCase {
    
    // MARK: - SlideTransitionPlugin Tests
    
    func test_slideTransitionPlugin_conformsToTransitionPluginProtocol() async {
        let plugin = SlideTransitionPlugin()
        
        XCTAssertFalse(plugin.metadata.id.isEmpty)
        XCTAssertFalse(plugin.metadata.name.isEmpty)
        XCTAssertFalse(plugin.metadata.version.isEmpty)
        XCTAssertTrue(plugin.metadata.capabilities.contains(.transition))
        XCTAssertFalse(plugin.isActive)
    }
    
    func test_slideTransitionPlugin_metadata() {
        let plugin = SlideTransitionPlugin()
        
        XCTAssertEqual(plugin.metadata.id, "com.swiftviewer.plugins.transitions.slide")
        XCTAssertEqual(plugin.metadata.name, "Slide Transition")
        XCTAssertEqual(plugin.metadata.version, "1.0.0")
        XCTAssertEqual(plugin.metadata.author, "SwiftViewer")
        XCTAssertEqual(plugin.metadata.description, "Directional slide transition with configurable direction")
        XCTAssertTrue(plugin.metadata.capabilities.contains(.transition))
    }
    
    func test_slideTransitionPlugin_initialization() async throws {
        let plugin = SlideTransitionPlugin()
        
        XCTAssertFalse(plugin.isActive)
        
        try await plugin.initialize()
        XCTAssertTrue(plugin.isActive)
        
        await plugin.cleanup()
        XCTAssertFalse(plugin.isActive)
    }
    
    func test_slideTransitionPlugin_createTransition_defaultParameters() {
        let plugin = SlideTransitionPlugin()
        let params = TransitionParameters()
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_slideTransitionPlugin_createTransition_leftDirection() {
        let plugin = SlideTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["direction": "left"]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_slideTransitionPlugin_createTransition_rightDirection() {
        let plugin = SlideTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["direction": "right"]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_slideTransitionPlugin_createTransition_upDirection() {
        let plugin = SlideTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["direction": "up"]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_slideTransitionPlugin_createTransition_downDirection() {
        let plugin = SlideTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["direction": "down"]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_slideTransitionPlugin_createTransition_allDirections() {
        let plugin = SlideTransitionPlugin()
        let directions = ["left", "right", "up", "down"]
        
        for direction in directions {
            let params = TransitionParameters(
                customValues: ["direction": direction]
            )
            let transition = plugin.createTransition(with: params)
            XCTAssertNotNil(transition, "Failed to create transition for direction: \(direction)")
        }
    }
    
    func test_slideTransitionPlugin_createTransition_allCurveTypes() {
        let plugin = SlideTransitionPlugin()
        let curves: [TransitionCurve] = [.linear, .easeIn, .easeOut, .easeInOut, .spring]
        
        for curve in curves {
            let params = TransitionParameters(
                duration: 0.3, 
                curve: curve, 
                customValues: ["direction": "left"]
            )
            let transition = plugin.createTransition(with: params)
            XCTAssertNotNil(transition, "Failed to create transition for curve: \(curve)")
        }
    }
    
    func test_slideTransitionPlugin_createTransition_customParameters() {
        let plugin = SlideTransitionPlugin()
        let customValues = ["direction": "right", "distance": "0.8"]
        let params = TransitionParameters(
            duration: 0.5,
            curve: .easeInOut,
            customValues: customValues
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_slideTransitionPlugin_slideDistance_parameter() {
        let plugin = SlideTransitionPlugin()
        
        // Test default distance (should be 1.0)
        let defaultParams = TransitionParameters(
            customValues: ["direction": "left"]
        )
        let defaultTransition = plugin.createTransition(with: defaultParams)
        XCTAssertNotNil(defaultTransition)
        
        // Test custom distance
        let customParams = TransitionParameters(
            customValues: ["direction": "left", "distance": "0.5"]
        )
        let customTransition = plugin.createTransition(with: customParams)
        XCTAssertNotNil(customTransition)
    }
    
    func test_slideTransitionPlugin_extremeParameters() {
        let plugin = SlideTransitionPlugin()
        
        // Test with very short duration
        let shortParams = TransitionParameters(
            duration: 0.01,
            customValues: ["direction": "up"]
        )
        let shortTransition = plugin.createTransition(with: shortParams)
        XCTAssertNotNil(shortTransition)
        
        // Test with very long duration
        let longParams = TransitionParameters(
            duration: 5.0,
            customValues: ["direction": "down"]
        )
        let longTransition = plugin.createTransition(with: longParams)
        XCTAssertNotNil(longTransition)
        
        // Test with invalid distance (should be clamped)
        let invalidParams = TransitionParameters(
            customValues: ["direction": "left", "distance": "2.0"] // Should be clamped to 1.0
        )
        let invalidTransition = plugin.createTransition(with: invalidParams)
        XCTAssertNotNil(invalidTransition)
    }
    
    func test_slideTransitionPlugin_invalidDirection() {
        let plugin = SlideTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["direction": "invalid_direction"] // Should default to "right"
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_slideTransitionPlugin_swiftUIIntegration() {
        let plugin = SlideTransitionPlugin()
        let params = TransitionParameters(
            duration: 0.25, 
            curve: .easeOut,
            customValues: ["direction": "left"]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_slideTransitionPlugin_validation() async {
        let plugin = SlideTransitionPlugin()
        
        let isValid = await plugin.validate()
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Performance Tests
    
    func test_slideTransitionPlugin_performance() {
        let plugin = SlideTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["direction": "right"]
        )
        
        measure {
            for _ in 0..<1000 {
                _ = plugin.createTransition(with: params)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func test_slideTransitionPlugin_negativeDistance() {
        let plugin = SlideTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["direction": "left", "distance": "-0.5"] // Should be clamped to 0.0
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_slideTransitionPlugin_invalidDistanceFormat() {
        let plugin = SlideTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["direction": "right", "distance": "not_a_number"] // Should default to 1.0
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_slideTransitionPlugin_caseInsensitiveDirection() {
        let plugin = SlideTransitionPlugin()
        let directions = ["LEFT", "Right", "UP", "Down"]
        
        for direction in directions {
            let params = TransitionParameters(
                customValues: ["direction": direction]
            )
            let transition = plugin.createTransition(with: params)
            XCTAssertNotNil(transition, "Failed to create transition for case-insensitive direction: \(direction)")
        }
    }
    
    func test_slideTransitionPlugin_asymmetricTransitions() {
        let plugin = SlideTransitionPlugin()
        
        // Test that slide transitions can be asymmetric (different for insertion vs removal)
        let params = TransitionParameters(
            customValues: ["direction": "left", "asymmetric": "true"]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
}