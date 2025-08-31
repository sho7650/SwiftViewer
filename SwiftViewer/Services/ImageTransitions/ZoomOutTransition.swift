//
//  ZoomOutTransition.swift
//  SwiftViewer
//
//  Created by SwiftViewer Development Team.
//

import SwiftUI

/// A transition that performs a zoom-out effect during image changes
/// 
/// This transition uses SwiftUI's scale transition with asymmetric insertion
/// and removal effects to create a zoom-out visual effect.
struct ZoomOutTransition: ImageTransitionProtocol {
    
    let name = "zoomOut"
    let displayName = "Zoom Out"
    
    func createTransition(duration: TimeInterval) -> AnyTransition {
        return .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.2).combined(with: .opacity)
        )
    }
}