//
//  ImageTransitionProtocol.swift
//  SwiftViewer
//
//  Created by SwiftViewer Development Team.
//

import SwiftUI

/// Protocol defining the interface for image transition strategies
/// 
/// This protocol follows the Strategy design pattern, allowing different
/// transition effects to be implemented as separate types and switched
/// dynamically at runtime.
protocol ImageTransitionProtocol {
    
    /// Unique identifier for the transition type
    var name: String { get }
    
    /// User-friendly display name for UI presentation
    var displayName: String { get }
    
    /// Creates a SwiftUI transition with the specified duration
    /// - Parameter duration: The duration of the transition animation
    /// - Returns: An AnyTransition that can be applied to SwiftUI views
    func createTransition(duration: TimeInterval) -> AnyTransition
}