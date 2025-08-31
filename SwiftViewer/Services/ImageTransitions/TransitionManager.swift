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
    
    /// Initialize with auto-discovered transitions
    init() {
        self.transitionRegistry = [
            .crossDissolve: CrossDissolveTransition(),
            .zoomOut: ZoomOutTransition(),
            .zoomIn: ZoomInTransition()
        ]
    }
    
    /// Get all available transition types
    var availableTransitions: [TransitionType] {
        return Array(transitionRegistry.keys).sorted { $0.rawValue < $1.rawValue }
    }
    
    /// Create a SwiftUI transition for the specified type and duration
    /// - Parameters:
    ///   - type: The transition type to create
    ///   - duration: The duration of the transition animation
    /// - Returns: An AnyTransition that can be applied to SwiftUI views
    func createTransition(for type: TransitionType, duration: TimeInterval) -> AnyTransition {
        guard let transitionStrategy = transitionRegistry[type] else {
            // Fallback to default transition if type not found
            return transitionRegistry[Self.defaultTransitionType]?.createTransition(duration: duration) ?? .opacity
        }
        
        return transitionStrategy.createTransition(duration: duration)
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
        return transitionRegistry[type] != nil
    }
}