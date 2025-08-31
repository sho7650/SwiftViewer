//
//  TransitionType.swift
//  SwiftViewer
//
//  Created by SwiftViewer Development Team.
//

import Foundation

/// Represents the different types of image transitions available in the application
enum TransitionType: String, CaseIterable, Codable, Equatable {
    case crossDissolve = "crossDissolve"
    case zoomOut = "zoomOut"
    case zoomIn = "zoomIn"
    case none = "none"
    case blurReplace = "blurReplace"
    case blurReplaceUpUp = "blurReplaceUpUp"
    
    /// User-friendly display name for the transition type
    var displayName: String {
        switch self {
        case .crossDissolve:
            return "Cross Dissolve"
        case .zoomOut:
            return "Zoom Out"
        case .zoomIn:
            return "Zoom In"
        case .none:
            return "None"
        case .blurReplace:
            return "Blur Replace"
        case .blurReplaceUpUp:
            return "Blur Replace (Expand)"
        }
    }
}