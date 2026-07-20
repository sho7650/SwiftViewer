//
//  ScaleFadeTransition.swift
//  SwiftViewer
//
//  A single parameterized scale + opacity transition covering the built-in effects.
//

import SwiftUI

/// A transition built from an asymmetric scale-and-fade. Every built-in effect
/// (cross dissolve, zoom in/out, blur replace) is a configuration of this one type.
///
/// The animation timing is applied centrally by `TransitionManager`, so this type
/// returns a bare transition and ignores `duration`.
struct ScaleFadeTransition: ImageTransitionProtocol {
    let name: String
    let displayName: String
    let insertionScale: CGFloat
    let removalScale: CGFloat

    func createTransition(duration: TimeInterval) -> AnyTransition {
        // Equal unit scales reduce to a pure cross-dissolve.
        if insertionScale == 1.0 && removalScale == 1.0 {
            return .opacity
        }
        return .asymmetric(
            insertion: .scale(scale: insertionScale).combined(with: .opacity),
            removal: .scale(scale: removalScale).combined(with: .opacity)
        )
    }
}
