//
//  SettingsTypes.swift
//  SwiftViewer
//
//  Created on 2025/08/26.
//

import Foundation

// MARK: - AnimationType

/// Types of animations used throughout the app
enum AnimationType: String, CaseIterable, Codable, Equatable {
    case control = "control"         // Control show/hide animations
    case transition = "transition"   // Image transition animations
    case feedback = "feedback"       // User interaction feedback animations
    
    var displayName: String {
        switch self {
        case .control:
            return "Controls"
        case .transition:
            return "Transitions"
        case .feedback:
            return "Feedback"
        }
    }
    
    var defaultDuration: TimeInterval {
        switch self {
        case .control:
            return 0.3
        case .transition:
            return 0.2
        case .feedback:
            return 0.1
        }
    }
}

// MARK: - WindowPosition

/// Window positioning options
enum WindowPosition: String, Codable, Equatable {
    case normal = "normal"
    case alwaysOnTop = "alwaysOnTop"
    case alwaysOnBottom = "alwaysOnBottom"
    
    var displayName: String {
        switch self {
        case .normal:
            return "Normal"
        case .alwaysOnTop:
            return "Always on Top"
        case .alwaysOnBottom:
            return "Always on Bottom"
        }
    }
}

// MARK: - SlideshowIntervalHelper

/// Helper for managing discrete slideshow interval values
struct SlideshowIntervalHelper {
    /// Discrete interval values in seconds
    static let intervals: [TimeInterval] = [1, 2, 3, 5, 10, 20, 30, 60, 120, 300, 600, 1200, 1800]
    
    /// Convert interval value to slider index
    static func indexForInterval(_ interval: TimeInterval) -> Int {
        // Find closest interval or exact match
        if let exactIndex = intervals.firstIndex(of: interval) {
            return exactIndex
        }
        
        // Find closest value
        var closestIndex = 0
        var smallestDifference = abs(intervals[0] - interval)
        
        for (index, value) in intervals.enumerated() {
            let difference = abs(value - interval)
            if difference < smallestDifference {
                smallestDifference = difference
                closestIndex = index
            }
        }
        
        return closestIndex
    }
    
    /// Convert slider index to interval value
    static func intervalForIndex(_ index: Int) -> TimeInterval {
        let clampedIndex = max(0, min(intervals.count - 1, index))
        return intervals[clampedIndex]
    }
    
    /// Format interval for display
    static func formatInterval(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)
        
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m"
        } else {
            let hours = seconds / 3600
            let remainingMinutes = (seconds % 3600) / 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}