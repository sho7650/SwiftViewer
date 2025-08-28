//
//  FadeTransitionPlugin.swift
//  SwiftViewer
//
//  Created by Claude Code on 2025-08-28.
//

import SwiftUI
import Foundation

/// Built-in fade transition plugin that provides smooth opacity-based transitions
@MainActor
final class FadeTransitionPlugin: TransitionPluginProtocol {
    
    // MARK: - PluginProtocol Implementation
    
    let metadata = PluginMetadata(
        id: "com.swiftviewer.plugins.transitions.fade",
        name: "Fade Transition",
        version: "1.0.0",
        author: "SwiftViewer",
        description: "Smooth fade in/out transition effect",
        capabilities: [.transition]
    )
    
    var isActive: Bool = false
    
    func initialize() async throws {
        isActive = true
    }
    
    func cleanup() async {
        isActive = false
    }
    
    // MARK: - TransitionPluginProtocol Implementation
    
    func createTransition(with parameters: TransitionParameters) -> AnyTransition {
        let baseTransition = createFadeTransition(with: parameters)
        let animation = parameters.curve.swiftUIAnimation(duration: parameters.duration)
        return baseTransition.animation(animation)
    }
    
    // MARK: - Private Implementation
    
    private func createFadeTransition(with parameters: TransitionParameters) -> AnyTransition {
        let intensity = extractIntensity(from: parameters)
        
        // Create opacity transition with configurable intensity
        let opacityTransition = AnyTransition.opacity
        
        if intensity < 1.0 {
            // For partial fade, combine opacity with scale for more visible effect
            let scaleAmount = 1.0 - (1.0 - intensity) * 0.1 // Subtle scale change
            let scaleTransition = AnyTransition.scale(scale: scaleAmount)
            return AnyTransition.asymmetric(
                insertion: opacityTransition.combined(with: scaleTransition),
                removal: opacityTransition.combined(with: scaleTransition)
            )
        } else {
            // Full fade uses pure opacity transition
            return opacityTransition
        }
    }
    
    private func extractIntensity(from parameters: TransitionParameters) -> Double {
        guard let customValues = parameters.customValues,
              let intensityString = customValues["intensity"],
              let intensity = Double(intensityString) else {
            return 1.0 // Default intensity
        }
        
        // Clamp intensity between 0.0 and 1.0
        return max(0.0, min(1.0, intensity))
    }
}

// MARK: - Built-in Plugin Registration

extension FadeTransitionPlugin {
    /// Static instance for built-in plugin registration
    static let shared = FadeTransitionPlugin()
}