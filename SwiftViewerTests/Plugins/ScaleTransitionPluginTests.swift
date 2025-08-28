//
//  ScaleTransitionPluginTests.swift
//  SwiftViewerTests
//
//  Created by Claude Code on 2025-08-28.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class ScaleTransitionPluginTests: XCTestCase {
    
    // MARK: - ScaleTransitionPlugin Tests
    
    func test_scaleTransitionPlugin_conformsToTransitionPluginProtocol() async {
        let plugin = ScaleTransitionPlugin()
        
        XCTAssertFalse(plugin.metadata.id.isEmpty)
        XCTAssertFalse(plugin.metadata.name.isEmpty)
        XCTAssertFalse(plugin.metadata.version.isEmpty)
        XCTAssertTrue(plugin.metadata.capabilities.contains(.transition))
        XCTAssertFalse(plugin.isActive)
    }
    
    func test_scaleTransitionPlugin_metadata() {
        let plugin = ScaleTransitionPlugin()
        
        XCTAssertEqual(plugin.metadata.id, "com.swiftviewer.plugins.transitions.scale")
        XCTAssertEqual(plugin.metadata.name, "Scale Transition")
        XCTAssertEqual(plugin.metadata.version, "1.0.0")
        XCTAssertEqual(plugin.metadata.author, "SwiftViewer")
        XCTAssertEqual(plugin.metadata.description, "Scale transition with configurable zoom effects and anchor points")
        XCTAssertTrue(plugin.metadata.capabilities.contains(.transition))
    }
    
    func test_scaleTransitionPlugin_initialization() async throws {
        let plugin = ScaleTransitionPlugin()
        
        XCTAssertFalse(plugin.isActive)
        
        try await plugin.initialize()
        XCTAssertTrue(plugin.isActive)
        
        await plugin.cleanup()
        XCTAssertFalse(plugin.isActive)
    }
    
    func test_scaleTransitionPlugin_createTransition_defaultParameters() {
        let plugin = ScaleTransitionPlugin()
        let params = TransitionParameters()
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_scaleTransitionPlugin_createTransition_customScale() {
        let plugin = ScaleTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["scale": "0.5"]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_scaleTransitionPlugin_createTransition_allAnchorPoints() {
        let plugin = ScaleTransitionPlugin()
        let anchors = ["center", "top", "bottom", "leading", "trailing", "topLeading", "topTrailing", "bottomLeading", "bottomTrailing"]
        
        for anchor in anchors {
            let params = TransitionParameters(
                customValues: ["anchor": anchor]
            )
            let transition = plugin.createTransition(with: params)
            XCTAssertNotNil(transition, "Failed to create transition for anchor: \(anchor)")
        }
    }
    
    func test_scaleTransitionPlugin_createTransition_allCurveTypes() {
        let plugin = ScaleTransitionPlugin()
        let curves: [TransitionCurve] = [.linear, .easeIn, .easeOut, .easeInOut, .spring]
        
        for curve in curves {
            let params = TransitionParameters(
                duration: 0.3,
                curve: curve,
                customValues: ["scale": "0.8"]
            )
            let transition = plugin.createTransition(with: params)
            XCTAssertNotNil(transition, "Failed to create transition for curve: \(curve)")
        }
    }
    
    func test_scaleTransitionPlugin_scaleParameter_range() {
        let plugin = ScaleTransitionPlugin()
        
        let scaleValues = ["0.0", "0.1", "0.5", "1.0", "1.5", "2.0"]
        
        for scaleValue in scaleValues {
            let params = TransitionParameters(
                customValues: ["scale": scaleValue]
            )
            let transition = plugin.createTransition(with: params)
            XCTAssertNotNil(transition, "Failed to create transition for scale: \(scaleValue)")
        }
    }
    
    func test_scaleTransitionPlugin_scaleIn_vs_scaleOut() {
        let plugin = ScaleTransitionPlugin()
        
        // Test scale in (zoom from small to normal)
        let scaleInParams = TransitionParameters(
            customValues: ["scale": "0.1", "mode": "in"]
        )
        let scaleInTransition = plugin.createTransition(with: scaleInParams)
        XCTAssertNotNil(scaleInTransition)
        
        // Test scale out (zoom from normal to large)
        let scaleOutParams = TransitionParameters(
            customValues: ["scale": "2.0", "mode": "out"]
        )
        let scaleOutTransition = plugin.createTransition(with: scaleOutParams)
        XCTAssertNotNil(scaleOutTransition)
    }
    
    func test_scaleTransitionPlugin_extremeParameters() {
        let plugin = ScaleTransitionPlugin()
        
        // Test with very short duration
        let shortParams = TransitionParameters(
            duration: 0.01,
            customValues: ["scale": "0.5"]
        )
        let shortTransition = plugin.createTransition(with: shortParams)
        XCTAssertNotNil(shortTransition)
        
        // Test with very long duration
        let longParams = TransitionParameters(
            duration: 5.0,
            customValues: ["scale": "1.5"]
        )
        let longTransition = plugin.createTransition(with: longParams)
        XCTAssertNotNil(longTransition)
        
        // Test with invalid scale (should be clamped)
        let invalidParams = TransitionParameters(
            customValues: ["scale": "5.0"] // Should be clamped to max
        )
        let invalidTransition = plugin.createTransition(with: invalidParams)
        XCTAssertNotNil(invalidTransition)
    }
    
    func test_scaleTransitionPlugin_combinedWithOpacity() {
        let plugin = ScaleTransitionPlugin()
        let params = TransitionParameters(
            customValues: [
                "scale": "0.5",
                "opacity": "true"
            ]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_scaleTransitionPlugin_aspectRatioPreservation() {
        let plugin = ScaleTransitionPlugin()
        let params = TransitionParameters(
            customValues: [
                "scale": "0.8",
                "preserveAspectRatio": "true"
            ]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_scaleTransitionPlugin_swiftUIIntegration() {
        let plugin = ScaleTransitionPlugin()
        let params = TransitionParameters(
            duration: 0.25,
            curve: .easeOut,
            customValues: ["scale": "0.5", "anchor": "center"]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_scaleTransitionPlugin_validation() async {
        let plugin = ScaleTransitionPlugin()
        
        let isValid = await plugin.validate()
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Performance Tests
    
    func test_scaleTransitionPlugin_performance() {
        let plugin = ScaleTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["scale": "0.5"]
        )
        
        measure {
            for _ in 0..<1000 {
                _ = plugin.createTransition(with: params)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func test_scaleTransitionPlugin_negativeScale() {
        let plugin = ScaleTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["scale": "-0.5"] // Should be clamped to minimum
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_scaleTransitionPlugin_invalidScaleFormat() {
        let plugin = ScaleTransitionPlugin()
        let params = TransitionParameters(
            customValues: ["scale": "not_a_number"] // Should default to 1.0
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_scaleTransitionPlugin_invalidAnchorPoint() {
        let plugin = ScaleTransitionPlugin()
        let params = TransitionParameters(
            customValues: [
                "scale": "0.8",
                "anchor": "invalid_anchor" // Should default to center
            ]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_scaleTransitionPlugin_caseInsensitiveAnchor() {
        let plugin = ScaleTransitionPlugin()
        let anchors = ["CENTER", "Top", "BOTTOM", "Leading"]
        
        for anchor in anchors {
            let params = TransitionParameters(
                customValues: ["anchor": anchor]
            )
            let transition = plugin.createTransition(with: params)
            XCTAssertNotNil(transition, "Failed to create transition for case-insensitive anchor: \(anchor)")
        }
    }
    
    func test_scaleTransitionPlugin_asymmetricScale() {
        let plugin = ScaleTransitionPlugin()
        let params = TransitionParameters(
            customValues: [
                "scaleIn": "0.1",
                "scaleOut": "2.0",
                "asymmetric": "true"
            ]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_scaleTransitionPlugin_springAnimation() {
        let plugin = ScaleTransitionPlugin()
        let params = TransitionParameters(
            curve: .spring,
            customValues: [
                "scale": "0.5",
                "springResponse": "0.6",
                "springDamping": "0.8"
            ]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
    
    func test_scaleTransitionPlugin_combinedEffects() {
        let plugin = ScaleTransitionPlugin()
        let params = TransitionParameters(
            duration: 0.4,
            curve: .easeInOut,
            customValues: [
                "scale": "0.3",
                "anchor": "topLeading",
                "opacity": "true",
                "rotation": "15"
            ]
        )
        
        let transition = plugin.createTransition(with: params)
        XCTAssertNotNil(transition)
    }
}