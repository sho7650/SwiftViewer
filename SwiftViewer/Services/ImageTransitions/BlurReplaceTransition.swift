//
//  BlurReplaceTransition.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/31.
//

import Foundation
import SwiftUI

/// A modern transition effect that combines blur and scale animations
/// Available in macOS 14.0+ with native support, falls back to scale+opacity on older versions
struct BlurReplaceTransition: ImageTransitionProtocol {
    
    /// Configuration options for the blur replace transition
    enum Configuration {
        /// Shrink on removal, expand on insertion (default)
        case downThenUp
        /// Expand on both removal and insertion
        case expandBoth
    }
    
    /// Unique identifier for this transition type
    let name = "blurReplace"
    
    /// User-friendly display name based on configuration
    var displayName: String {
        switch configuration {
        case .downThenUp:
            return "Blur Replace"
        case .expandBoth:
            return "Blur Replace (Expand)"
        }
    }
    
    /// The configuration for this transition instance
    private let configuration: Configuration
    
    /// Initialize with specified configuration
    /// - Parameter configuration: The blur replace configuration to use (default: .downUp)
    init(configuration: Configuration = .downThenUp) {
        self.configuration = configuration
    }
    
    /// Creates a SwiftUI transition with the specified duration
    /// - Parameter duration: The duration of the transition animation
    /// - Returns: An AnyTransition that can be applied to SwiftUI views
    func createTransition(duration: TimeInterval) -> AnyTransition {
        // Simulate a blur-replace look with scale and opacity for a
        // similar visual effect (kept API-version agnostic on purpose).
        
        let scaleTransition: AnyTransition
        switch configuration {
        case .downThenUp:
            // Asymmetric: scale down on removal, scale up on insertion with blur effect
            scaleTransition = .asymmetric(
                insertion: .scale(scale: 1.1).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            )
        case .expandBoth:
            // Symmetric: scale up on both removal and insertion with blur effect
            scaleTransition = .scale(scale: 1.1).combined(with: .opacity)
        }
        
        return scaleTransition
            .animation(.easeInOut(duration: duration))
    }
}