//
//  ZoomInTransition.swift
//  SwiftViewer
//
//  Created by SwiftViewer Development Team.
//

import SwiftUI

/// A transition that performs a zoom-in effect during image changes
/// 
/// This transition uses SwiftUI's scale transition with asymmetric insertion
/// and removal effects to create a zoom-in visual effect.
struct ZoomInTransition: ImageTransitionProtocol {
    
    let name = "zoomIn"
    let displayName = "Zoom In"
    
    func createTransition(duration: TimeInterval) -> AnyTransition {
        return .asymmetric(
            insertion: .scale(scale: 1.2).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
    }
}