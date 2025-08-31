//
//  CrossDissolveTransition.swift
//  SwiftViewer
//
//  Created by SwiftViewer Development Team.
//

import SwiftUI

/// A transition that performs a cross-dissolve (fade) effect between images
/// 
/// This transition uses SwiftUI's opacity transition to create a smooth
/// fade-in/fade-out effect during image changes.
struct CrossDissolveTransition: ImageTransitionProtocol {
    
    let name = "crossDissolve"
    let displayName = "Cross Dissolve"
    
    func createTransition(duration: TimeInterval) -> AnyTransition {
        return .opacity
    }
}