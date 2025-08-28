//
//  TransitionPluginTests.swift
//  SwiftViewerTests
//
//  Created by Claude Code on 2025-08-28.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class TransitionPluginTests: XCTestCase {
    
    // MARK: - TransitionPluginProtocol Tests
    
    func test_transitionPluginProtocol_conformsToPluginProtocol() async {
        // Test that TransitionPluginProtocol inherits from PluginProtocol
        let mockPlugin = MockTransitionPlugin()
        
        // Should be able to access PluginProtocol properties
        XCTAssertFalse(mockPlugin.metadata.id.isEmpty)
        XCTAssertFalse(mockPlugin.metadata.name.isEmpty)
        XCTAssertFalse(mockPlugin.metadata.version.isEmpty)
        XCTAssertFalse(mockPlugin.isActive) // Initially inactive
    }
    
    func test_transitionPluginProtocol_hasRequiredMethods() {
        let mockPlugin = MockTransitionPlugin()
        
        // Test that transition method exists and returns a transition
        let transition = mockPlugin.createTransition(with: TransitionParameters())
        XCTAssertNotNil(transition)
    }
    
    // MARK: - TransitionParameters Tests
    
    func test_transitionParameters_initialization() {
        let params = TransitionParameters()
        
        // Test default values
        XCTAssertEqual(params.duration, 0.25)
        XCTAssertEqual(params.curve, .easeInOut)
        XCTAssertNil(params.customValues)
    }
    
    func test_transitionParameters_customInitialization() {
        let customValues = ["scale": "2.0", "opacity": "0.5"]
        let params = TransitionParameters(
            duration: 1.0,
            curve: .spring,
            customValues: customValues
        )
        
        XCTAssertEqual(params.duration, 1.0)
        XCTAssertEqual(params.curve, TransitionCurve.spring)
        XCTAssertEqual(params.customValues?["scale"], "2.0")
        XCTAssertEqual(params.customValues?["opacity"], "0.5")
    }
    
    func test_transitionParameters_equatable() {
        let params1: TransitionParameters = TransitionParameters(duration: 0.5, curve: .linear)
        let params2: TransitionParameters = TransitionParameters(duration: 0.5, curve: .linear)
        let params3: TransitionParameters = TransitionParameters(duration: 1.0, curve: .linear)
        
        XCTAssertEqual(params1, params2)
        XCTAssertNotEqual(params1, params3)
    }
    
    // MARK: - TransitionCurve Tests
    
    func test_transitionCurve_allCases() {
        let expectedCases: [TransitionCurve] = [
            .linear, .easeIn, .easeOut, .easeInOut, .spring
        ]
        
        XCTAssertEqual(Set(TransitionCurve.allCases), Set(expectedCases))
    }
    
    func test_transitionCurve_swiftUIAnimationMapping() {
        // Test that each curve can be converted to SwiftUI Animation
        let curves: [TransitionCurve] = [.linear, .easeIn, .easeOut, .easeInOut, .spring]
        
        for curve in curves {
            let animation: Animation = curve.swiftUIAnimation(duration: 0.5)
            XCTAssertNotNil(animation)
        }
    }
    
    // MARK: - Mock Transition Plugin Integration Tests
    
    func test_mockTransitionPlugin_swiftUIIntegration() {
        let mockPlugin = MockTransitionPlugin()
        let params = TransitionParameters(duration: 0.3, curve: .easeOut)
        
        // Test that the transition can be applied to a SwiftUI view
        let transition = mockPlugin.createTransition(with: params)
        
        // We can't directly test SwiftUI view modifiers in unit tests,
        // but we can verify the transition object is created properly
        XCTAssertNotNil(transition)
    }
    
    func test_mockTransitionPlugin_parameterValidation() {
        let mockPlugin = MockTransitionPlugin()
        
        // Test with invalid duration (negative)
        let invalidParams = TransitionParameters(duration: -1.0, curve: .linear)
        let transition = mockPlugin.createTransition(with: invalidParams)
        
        // Mock plugin should handle invalid parameters gracefully
        XCTAssertNotNil(transition)
    }
    
    // MARK: - Performance Tests
    
    func test_transitionCreation_performance() {
        let mockPlugin = MockTransitionPlugin()
        let params = TransitionParameters()
        
        measure {
            for _ in 0..<1000 {
                _ = mockPlugin.createTransition(with: params)
            }
        }
    }
}

// MARK: - Mock Classes for Testing

@MainActor
private class MockTransitionPlugin: TransitionPluginProtocol {
    let metadata = PluginMetadata(
        id: "com.test.mock-transition",
        name: "Mock Transition",
        version: "1.0.0",
        author: "Test Author",
        description: "A mock transition plugin for testing",
        capabilities: [.transition]
    )
    
    var isActive: Bool = false
    
    func initialize() async throws {
        // Mock initialization - always succeeds
        isActive = true
    }
    
    func cleanup() async {
        // Mock cleanup - no action needed
        isActive = false
    }
    
    func createTransition(with parameters: TransitionParameters) -> AnyTransition {
        // Return a simple opacity transition for testing
        return AnyTransition.opacity
    }
}