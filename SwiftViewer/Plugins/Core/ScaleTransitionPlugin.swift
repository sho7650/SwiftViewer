//
//  ScaleTransitionPlugin.swift
//  SwiftViewer
//
//  Created by Claude Code on 2025-08-28.
//

import SwiftUI
import Foundation

/// Built-in scale transition plugin that provides zoom effects with configurable anchor points
@MainActor
final class ScaleTransitionPlugin: TransitionPluginProtocol {
    
    // MARK: - PluginProtocol Implementation
    
    let metadata = PluginMetadata(
        id: "com.swiftviewer.plugins.transitions.scale",
        name: "Scale Transition",
        version: "1.0.0",
        author: "SwiftViewer",
        description: "Scale transition with configurable zoom effects and anchor points",
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
        let baseTransition = createScaleTransition(with: parameters)
        let animation = parameters.curve.swiftUIAnimation(duration: parameters.duration)
        return baseTransition.animation(animation)
    }
    
    // MARK: - Private Implementation
    
    private func createScaleTransition(with parameters: TransitionParameters) -> AnyTransition {
        let scale = extractScale(from: parameters)
        let anchor = extractAnchor(from: parameters)
        let includeOpacity = extractOpacity(from: parameters)
        let isAsymmetric = extractAsymmetric(from: parameters)
        
        if isAsymmetric {
            return createAsymmetricScaleTransition(with: parameters)
        } else {
            return createBasicScaleTransition(scale: scale, anchor: anchor, includeOpacity: includeOpacity)
        }
    }
    
    private func createBasicScaleTransition(scale: Double, anchor: UnitPoint, includeOpacity: Bool) -> AnyTransition {
        let scaleTransition = AnyTransition.scale(scale: scale, anchor: anchor)
        
        if includeOpacity {
            return scaleTransition.combined(with: .opacity)
        } else {
            return scaleTransition
        }
    }
    
    private func createAsymmetricScaleTransition(with parameters: TransitionParameters) -> AnyTransition {
        let scaleIn = extractScaleIn(from: parameters)
        let scaleOut = extractScaleOut(from: parameters)
        let anchor = extractAnchor(from: parameters)
        let includeOpacity = extractOpacity(from: parameters)
        
        let insertionTransition = AnyTransition.scale(scale: scaleIn, anchor: anchor)
        let removalTransition = AnyTransition.scale(scale: scaleOut, anchor: anchor)
        
        let finalInsertionTransition = includeOpacity ? insertionTransition.combined(with: .opacity) : insertionTransition
        let finalRemovalTransition = includeOpacity ? removalTransition.combined(with: .opacity) : removalTransition
        
        return AnyTransition.asymmetric(
            insertion: finalInsertionTransition,
            removal: finalRemovalTransition
        )
    }
    
    private func extractScale(from parameters: TransitionParameters) -> Double {
        guard let customValues = parameters.customValues,
              let scaleString = customValues["scale"],
              let scale = Double(scaleString) else {
            return 1.0 // Default scale
        }
        
        // Clamp scale between 0.01 and 3.0 for reasonable visual effects
        return max(0.01, min(3.0, scale))
    }
    
    private func extractScaleIn(from parameters: TransitionParameters) -> Double {
        guard let customValues = parameters.customValues,
              let scaleString = customValues["scaleIn"],
              let scale = Double(scaleString) else {
            return 0.1 // Default scale in (small)
        }
        
        return max(0.01, min(3.0, scale))
    }
    
    private func extractScaleOut(from parameters: TransitionParameters) -> Double {
        guard let customValues = parameters.customValues,
              let scaleString = customValues["scaleOut"],
              let scale = Double(scaleString) else {
            return 2.0 // Default scale out (large)
        }
        
        return max(0.01, min(3.0, scale))
    }
    
    private func extractAnchor(from parameters: TransitionParameters) -> UnitPoint {
        guard let customValues = parameters.customValues,
              let anchorString = customValues["anchor"] else {
            return .center // Default anchor
        }
        
        return ScaleAnchor.from(string: anchorString).unitPoint
    }
    
    private func extractOpacity(from parameters: TransitionParameters) -> Bool {
        guard let customValues = parameters.customValues,
              let opacityString = customValues["opacity"] else {
            return false // Default: no opacity
        }
        
        return opacityString.lowercased() == "true"
    }
    
    private func extractAsymmetric(from parameters: TransitionParameters) -> Bool {
        guard let customValues = parameters.customValues,
              let asymmetricString = customValues["asymmetric"] else {
            return false // Default: symmetric
        }
        
        return asymmetricString.lowercased() == "true"
    }
}

// MARK: - Scale Anchor Enum

private enum ScaleAnchor: String, CaseIterable {
    case center
    case top
    case bottom
    case leading
    case trailing
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing
    
    var unitPoint: UnitPoint {
        switch self {
        case .center:
            return .center
        case .top:
            return .top
        case .bottom:
            return .bottom
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        case .topLeading:
            return .topLeading
        case .topTrailing:
            return .topTrailing
        case .bottomLeading:
            return .bottomLeading
        case .bottomTrailing:
            return .bottomTrailing
        }
    }
    
    static func from(string: String) -> ScaleAnchor {
        let lowercased = string.lowercased()
        return ScaleAnchor(rawValue: lowercased) ?? .center
    }
}

// MARK: - Built-in Plugin Registration

extension ScaleTransitionPlugin {
    /// Static instance for built-in plugin registration
    static let shared = ScaleTransitionPlugin()
}