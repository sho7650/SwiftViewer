//
//  Animation+Settings.swift
//  SwiftViewer
//
//  Created on 2025/08/26.
//

import SwiftUI

extension Animation {
    /// Returns an animation with duration from settings
    /// - Parameter type: The type of animation to retrieve duration for
    /// - Returns: An easeInOut animation with the configured duration
    static func fromSettings(_ type: AnimationType) -> Animation {
        let settingsManager = DependencyContainer.shared.settingsManager
        let duration = settingsManager.animationDurations[type] ?? type.defaultDuration
        return .easeInOut(duration: duration)
    }
    
    /// Convenience method for control animations (show/hide controls)
    static var controlAnimation: Animation {
        return fromSettings(.control)
    }
    
    /// Convenience method for transition animations (image transitions)
    static var transitionAnimation: Animation {
        return fromSettings(.transition)
    }
    
    /// Convenience method for feedback animations (user interaction feedback)
    static var feedbackAnimation: Animation {
        return fromSettings(.feedback)
    }
}

extension View {
    /// Apply settings-based animation to view changes
    /// - Parameter type: The type of animation to use
    /// - Returns: View with the configured animation
    func settingsAnimation(_ type: AnimationType) -> some View {
        self.animation(.fromSettings(type))
    }
    
    /// Apply settings-based animation with a value binding
    /// - Parameters:
    ///   - type: The type of animation to use
    ///   - value: The value to watch for changes
    /// - Returns: View with the configured animation
    func settingsAnimation<V: Equatable>(_ type: AnimationType, value: V) -> some View {
        self.animation(.fromSettings(type), value: value)
    }
}