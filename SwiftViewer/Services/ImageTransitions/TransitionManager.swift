//
//  TransitionManager.swift
//  SwiftViewer
//
//  Created by SwiftViewer Development Team.
//

import SwiftUI

/// Manages image transition strategies and provides access to available transitions
/// 
/// This manager uses a registry pattern to map transition types to their concrete
/// implementations, enabling easy addition of new transitions without modifying
/// existing code.
class TransitionManager: ObservableObject {
    
    /// Registry mapping transition types to their implementations
    private let transitionRegistry: [TransitionType: any ImageTransitionProtocol]
    
    /// Default transition type
    public static let defaultTransitionType: TransitionType = .crossDissolve
    
    /// Initialize with the built-in transition strategies.
    init() {
        self.transitionRegistry = [
            .crossDissolve: ScaleFadeTransition(name: "crossDissolve", displayName: "Cross Dissolve", insertionScale: 1.0, removalScale: 1.0),
            .zoomOut: ScaleFadeTransition(name: "zoomOut", displayName: "Zoom Out", insertionScale: 0.8, removalScale: 1.2),
            .zoomIn: ScaleFadeTransition(name: "zoomIn", displayName: "Zoom In", insertionScale: 1.2, removalScale: 0.8),
            .blurReplace: ScaleFadeTransition(name: "blurReplace", displayName: "Blur Replace", insertionScale: 1.1, removalScale: 0.9),
            .blurReplaceUpUp: ScaleFadeTransition(name: "blurReplaceUpUp", displayName: "Blur Replace (Expand)", insertionScale: 1.1, removalScale: 1.1)
        ]
    }
    
    /// Get all available transition types
    var availableTransitions: [TransitionType] {
        // Include none transition which is handled specially
        var transitions = Array(transitionRegistry.keys)
        transitions.append(.none)
        return transitions.sorted { $0.rawValue < $1.rawValue }
    }
    
    /// Create a SwiftUI transition for the specified type and duration
    /// - Parameters:
    ///   - type: The transition type to create
    ///   - duration: The duration of the transition animation
    /// - Returns: An AnyTransition that can be applied to SwiftUI views
    func createTransition(for type: TransitionType, duration: TimeInterval) -> AnyTransition {
        // Handle none transition type - no animation effect
        if type == .none {
            return .identity
        }

        let strategy = transitionRegistry[type] ?? transitionRegistry[Self.defaultTransitionType]
        let transition = strategy?.createTransition(duration: duration) ?? .opacity
        // Apply the configured timing centrally so every strategy honours `duration`.
        return transition.animation(.easeInOut(duration: duration))
    }
    
    /// Get the display name for a transition type
    /// - Parameter type: The transition type
    /// - Returns: User-friendly display name
    func getDisplayName(for type: TransitionType) -> String {
        return transitionRegistry[type]?.displayName ?? type.displayName
    }
    
    /// Check if a transition type is available
    /// - Parameter type: The transition type to check
    /// - Returns: True if the transition is available
    func isTransitionAvailable(_ type: TransitionType) -> Bool {
        // None transition is always available (handled specially)
        if type == .none {
            return true
        }
        return transitionRegistry[type] != nil
    }
}