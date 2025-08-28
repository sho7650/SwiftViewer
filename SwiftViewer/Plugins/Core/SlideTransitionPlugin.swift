//
//  SlideTransitionPlugin.swift
//  SwiftViewer
//
//  Created by Claude Code on 2025-08-28.
//

import SwiftUI
import Foundation

/// Built-in slide transition plugin that provides directional slide animations
@MainActor
final class SlideTransitionPlugin: TransitionPluginProtocol {
    
    // MARK: - PluginProtocol Implementation
    
    let metadata = PluginMetadata(
        id: "com.swiftviewer.plugins.transitions.slide",
        name: "Slide Transition",
        version: "1.0.0",
        author: "SwiftViewer",
        description: "Directional slide transition with configurable direction",
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
        let baseTransition = createSlideTransition(with: parameters)
        let animation = parameters.curve.swiftUIAnimation(duration: parameters.duration)
        return baseTransition.animation(animation)
    }
    
    // MARK: - Private Implementation
    
    private func createSlideTransition(with parameters: TransitionParameters) -> AnyTransition {
        let direction = extractDirection(from: parameters)
        let distance = extractDistance(from: parameters)
        let isAsymmetric = extractAsymmetric(from: parameters)
        
        let transition = createDirectionalTransition(direction: direction, distance: distance)
        
        if isAsymmetric {
            // Create asymmetric transition with different insertion/removal behavior
            return createAsymmetricTransition(direction: direction, distance: distance)
        } else {
            return transition
        }
    }
    
    private func createDirectionalTransition(direction: SlideDirection, distance: Double) -> AnyTransition {
        switch direction {
        case .left:
            return AnyTransition.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .right:
            return AnyTransition.asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        case .up:
            return AnyTransition.asymmetric(
                insertion: .move(edge: .bottom),
                removal: .move(edge: .top)
            )
        case .down:
            return AnyTransition.asymmetric(
                insertion: .move(edge: .top),
                removal: .move(edge: .bottom)
            )
        }
    }
    
    private func createAsymmetricTransition(direction: SlideDirection, distance: Double) -> AnyTransition {
        // For asymmetric transitions, use different effects for insertion and removal
        let insertionTransition: AnyTransition
        let removalTransition: AnyTransition
        
        switch direction {
        case .left:
            insertionTransition = AnyTransition.move(edge: .trailing).combined(with: .opacity)
            removalTransition = AnyTransition.move(edge: .leading)
        case .right:
            insertionTransition = AnyTransition.move(edge: .leading).combined(with: .opacity)
            removalTransition = AnyTransition.move(edge: .trailing)
        case .up:
            insertionTransition = AnyTransition.move(edge: .bottom).combined(with: .opacity)
            removalTransition = AnyTransition.move(edge: .top)
        case .down:
            insertionTransition = AnyTransition.move(edge: .top).combined(with: .opacity)
            removalTransition = AnyTransition.move(edge: .bottom)
        }
        
        return AnyTransition.asymmetric(
            insertion: insertionTransition,
            removal: removalTransition
        )
    }
    
    private func extractDirection(from parameters: TransitionParameters) -> SlideDirection {
        guard let customValues = parameters.customValues,
              let directionString = customValues["direction"] else {
            return .right // Default direction
        }
        
        return SlideDirection.from(string: directionString)
    }
    
    private func extractDistance(from parameters: TransitionParameters) -> Double {
        guard let customValues = parameters.customValues,
              let distanceString = customValues["distance"],
              let distance = Double(distanceString) else {
            return 1.0 // Default distance
        }
        
        // Clamp distance between 0.0 and 1.0
        return max(0.0, min(1.0, distance))
    }
    
    private func extractAsymmetric(from parameters: TransitionParameters) -> Bool {
        guard let customValues = parameters.customValues,
              let asymmetricString = customValues["asymmetric"] else {
            return false // Default to symmetric
        }
        
        return asymmetricString.lowercased() == "true"
    }
}

// MARK: - Slide Direction Enum

private enum SlideDirection: String, CaseIterable {
    case left
    case right
    case up
    case down
    
    static func from(string: String) -> SlideDirection {
        let lowercased = string.lowercased()
        return SlideDirection(rawValue: lowercased) ?? .right
    }
}

// MARK: - Built-in Plugin Registration

extension SlideTransitionPlugin {
    /// Static instance for built-in plugin registration
    static let shared = SlideTransitionPlugin()
}