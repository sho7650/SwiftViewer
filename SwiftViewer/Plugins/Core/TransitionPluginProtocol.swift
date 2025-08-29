//
//  TransitionPluginProtocol.swift
//  SwiftViewer
//
//  Created by Claude Code on 2025-08-28.
//

import SwiftUI
import Foundation

/// Protocol defining transition effects for plugin system
/// Extends PluginProtocol to provide transition-specific functionality
@MainActor
public protocol TransitionPluginProtocol: PluginProtocol {
    /// Creates a SwiftUI transition with the given parameters
    /// - Parameter parameters: Configuration for the transition animation
    /// - Returns: A SwiftUI AnyTransition that can be applied to views
    func createTransition(with parameters: TransitionParameters) -> AnyTransition
}

/// Configuration parameters for transition animations
public struct TransitionParameters: Equatable, Sendable {
    /// Duration of the transition in seconds
    let duration: TimeInterval
    
    /// Animation curve for the transition
    let curve: TransitionCurve
    
    /// Custom values for plugin-specific configuration
    let customValues: [String: String]?
    
    public init(
        duration: TimeInterval = 0.25,
        curve: TransitionCurve = .easeInOut,
        customValues: [String: String]? = nil
    ) {
        self.duration = max(0.0, duration) // Ensure non-negative duration
        self.curve = curve
        self.customValues = customValues
    }
    
    public static func == (lhs: TransitionParameters, rhs: TransitionParameters) -> Bool {
        lhs.duration == rhs.duration &&
        lhs.curve == rhs.curve &&
        lhs.customValues == rhs.customValues
    }
}

/// Animation curves supported by transition plugins
public enum TransitionCurve: String, CaseIterable, Sendable {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case spring
    
    /// Converts the curve to a SwiftUI Animation
    /// - Parameter duration: Duration for the animation
    /// - Returns: SwiftUI Animation with the specified curve and duration
    public func swiftUIAnimation(duration: TimeInterval) -> Animation {
        switch self {
        case .linear:
            return .linear(duration: duration)
        case .easeIn:
            return .easeIn(duration: duration)
        case .easeOut:
            return .easeOut(duration: duration)
        case .easeInOut:
            return .easeInOut(duration: duration)
        case .spring:
            return .spring(duration: duration)
        }
    }
}

// MARK: - Default Implementations

extension TransitionPluginProtocol {
    /// Default transition creation with animation applied
    func createTransition(with parameters: TransitionParameters) -> AnyTransition {
        let baseTransition = createBaseTransition(with: parameters)
        let animation = parameters.curve.swiftUIAnimation(duration: parameters.duration)
        return baseTransition.animation(animation)
    }
    
    /// Override this method in conforming types to provide the base transition
    /// Default implementation returns opacity transition
    func createBaseTransition(with parameters: TransitionParameters) -> AnyTransition {
        return AnyTransition.opacity
    }
}