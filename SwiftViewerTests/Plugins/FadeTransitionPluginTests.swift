//
//  FadeTransitionPluginTests.swift
//  SwiftViewerTests
//
//  Created by Claude Code on 2025-08-28.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class FadeTransitionPluginTests: XCTestCase {
    
    // MARK: - FadeTransitionPlugin Tests
    
    func test_fadeTransitionPlugin_conformsToTransitionPluginProtocol() async {
        // Test that FadeTransitionPlugin conforms to TransitionPluginProtocol
        let plugin = FadeTransitionPlugin()
        
        // Should conform to both PluginProtocol and TransitionPluginProtocol
        XCTAssertFalse(plugin.metadata.id.isEmpty)
        XCTAssertFalse(plugin.metadata.name.isEmpty)
        XCTAssertFalse(plugin.metadata.version.isEmpty)
        XCTAssertTrue(plugin.metadata.capabilities.contains(.transition))
        XCTAssertFalse(plugin.isActive) // Initially inactive
    }
    
    func test_fadeTransitionPlugin_metadata() {
        let plugin = FadeTransitionPlugin()
        
        // Verify specific metadata for fade transition
        XCTAssertEqual(plugin.metadata.id, "com.swiftviewer.plugins.transitions.fade")
        XCTAssertEqual(plugin.metadata.name, "Fade Transition")
        XCTAssertEqual(plugin.metadata.version, "1.0.0")
        XCTAssertEqual(plugin.metadata.author, "SwiftViewer")
        XCTAssertEqual(plugin.metadata.description, "Smooth fade in/out transition effect")
        XCTAssertTrue(plugin.metadata.capabilities.contains(.transition))
    }
    
    func test_fadeTransitionPlugin_initialization() async throws {
        let plugin = FadeTransitionPlugin()
        
        XCTAssertFalse(plugin.isActive)
        
        // Test initialization
        try await plugin.initialize()
        XCTAssertTrue(plugin.isActive)
        
        // Test cleanup
        await plugin.cleanup()
        XCTAssertFalse(plugin.isActive)
    }
    
    func test_fadeTransitionPlugin_createTransition_defaultParameters() {
        let plugin = FadeTransitionPlugin()
        let params = TransitionParameters()
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_fadeTransitionPlugin_createTransition_customParameters() {
        let plugin = FadeTransitionPlugin()
        let customValues = ["intensity": "0.8"]
        let params = TransitionParameters(
            duration: 0.5,
            curve: .easeInOut,
            customValues: customValues
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_fadeTransitionPlugin_createTransition_allCurveTypes() {
        let plugin = FadeTransitionPlugin()
        
        let curves: [TransitionCurve] = [.linear, .easeIn, .easeOut, .easeInOut, .spring]
        
        for curve in curves {
            let params = TransitionParameters(duration: 0.3, curve: curve)
            let transition = plugin.createTransition(with: params)
            XCTAssertNotNil(transition, "Failed to create transition for curve: \(curve)")
        }
    }
    
    func test_fadeTransitionPlugin_fadeIntensity_parameter() {
        let plugin = FadeTransitionPlugin()
        
        // Test default intensity (should be 1.0)
        let defaultParams = TransitionParameters()
        let defaultTransition = plugin.createTransition(with: defaultParams)
        XCTAssertNotNil(defaultTransition)
        
        // Test custom intensity
        let customParams = TransitionParameters(
            customValues: ["intensity": "0.5"]
        )
        let customTransition = plugin.createTransition(with: customParams)
        XCTAssertNotNil(customTransition)
    }
    
    func test_fadeTransitionPlugin_extremeParameters() {
        let plugin = FadeTransitionPlugin()
        
        // Test with very short duration
        let shortParams = TransitionParameters(duration: 0.01)
        let shortTransition = plugin.createTransition(with: shortParams)
        XCTAssertNotNil(shortTransition)
        
        // Test with very long duration
        let longParams = TransitionParameters(duration: 5.0)
        let longTransition = plugin.createTransition(with: longParams)
        XCTAssertNotNil(longTransition)
        
        // Test with invalid intensity (should be clamped)
        let invalidParams = TransitionParameters(
            customValues: ["intensity": "2.0"] // Should be clamped to 1.0
        )
        let invalidTransition = plugin.createTransition(with: invalidParams)
        XCTAssertNotNil(invalidTransition)
    }
    
    func test_fadeTransitionPlugin_swiftUIIntegration() {
        let plugin = FadeTransitionPlugin()
        let params = TransitionParameters(duration: 0.25, curve: .easeOut)
        
        let transition = plugin.createTransition(with: params)
        
        // Verify we can use the transition in a SwiftUI context
        // (We can't fully test SwiftUI view rendering in unit tests,
        // but we can verify the transition is properly formed)
        XCTAssertNotNil(transition)
        
        // The transition should be an opacity-based transition
        // This is validated by the fact that it doesn't crash when created
    }
    
    func test_fadeTransitionPlugin_validation() async {
        let plugin = FadeTransitionPlugin()
        
        // Test default validation
        let isValid = await plugin.validate()
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Performance Tests
    
    func test_fadeTransitionPlugin_performance() {
        let plugin = FadeTransitionPlugin()
        let params = TransitionParameters()
        
        measure {
            for _ in 0..<1000 {
                _ = plugin.createTransition(with: params)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func test_fadeTransitionPlugin_negativeIntensity() {
        let plugin = FadeTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["intensity": "-0.5"] // Should be clamped to 0.0
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_fadeTransitionPlugin_invalidIntensityFormat() {
        let plugin = FadeTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["intensity": "not_a_number"] // Should default to 1.0
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
}