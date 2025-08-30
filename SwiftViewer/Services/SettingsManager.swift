//
//  SettingsManager.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation

protocol SettingsManagerProtocol {
    // Existing properties
    var slideShowInterval: TimeInterval { get set }
    var repeatEnabled: Bool { get set }
    var sortType: SortType { get set }
    var debugLoggingEnabled: Bool { get set }
    
    // Phase 1 new properties
    var autoHideDelay: TimeInterval { get set }
    var animationDurations: [AnimationType: TimeInterval] { get set }
    var blurRadius: Double { get set }
    var blurOpacity: Double { get set }
    var loggingLevel: LogLevel { get set }
    var windowPosition: WindowPosition { get set }
    var slideShowPresetIntervals: [TimeInterval] { get }
}

final class SettingsManager: SettingsManagerProtocol {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    var slideShowInterval: TimeInterval {
        get {
            let interval = userDefaults.double(forKey: "slideShowInterval")
            return interval > 0 ? interval : 10.0
        }
        set {
            let validatedValue = validateSlideShowInterval(newValue)
            userDefaults.set(validatedValue, forKey: "slideShowInterval")
        }
    }
    
    private func validateSlideShowInterval(_ interval: TimeInterval) -> TimeInterval {
        // Allow intervals from 1 to 1800 seconds (30 minutes)
        return max(1.0, min(1800.0, interval))
    }
    
    var repeatEnabled: Bool {
        get {
            userDefaults.bool(forKey: "repeatEnabled")
        }
        set {
            userDefaults.set(newValue, forKey: "repeatEnabled")
        }
    }
    
    var sortType: SortType {
        get {
            let sortTypeRaw = userDefaults.string(forKey: "sortType") ?? "name_ascending"
            return parseSortType(from: sortTypeRaw)
        }
        set {
            userDefaults.set(sortTypeString(from: newValue), forKey: "sortType")
        }
    }
    
    var debugLoggingEnabled: Bool {
        get {
            userDefaults.bool(forKey: "debugLoggingEnabled")
        }
        set {
            userDefaults.set(newValue, forKey: "debugLoggingEnabled")
        }
    }
    
    private func parseSortType(from string: String) -> SortType {
        switch string {
        case "name_ascending":
            return .name(ascending: true)
        case "name_descending":
            return .name(ascending: false)
        case "date_ascending":
            return .date(ascending: true)
        case "date_descending":
            return .date(ascending: false)
        case "size_ascending":
            return .size(ascending: true)
        case "size_descending":
            return .size(ascending: false)
        case "random":
            return .random
        default:
            return .name(ascending: true)
        }
    }
    
    private func sortTypeString(from sortType: SortType) -> String {
        switch sortType {
        case .name(let ascending):
            return ascending ? "name_ascending" : "name_descending"
        case .date(let ascending):
            return ascending ? "date_ascending" : "date_descending"
        case .size(let ascending):
            return ascending ? "size_ascending" : "size_descending"
        case .random:
            return "random"
        }
    }
    
    // MARK: - Phase 1 New Properties
    
    var autoHideDelay: TimeInterval {
        get {
            let delay = userDefaults.double(forKey: "autoHideDelay")
            return delay > 0 ? delay : 3.0 // Default 3 seconds
        }
        set {
            let validatedValue = max(1.0, min(60.0, newValue))
            userDefaults.set(validatedValue, forKey: "autoHideDelay")
        }
    }
    
    var animationDurations: [AnimationType: TimeInterval] {
        get {
            if let data = userDefaults.data(forKey: "animationDurations"),
               let durations = try? JSONDecoder().decode([AnimationType: TimeInterval].self, from: data) {
                return durations
            }
            // Default durations
            return [
                .control: 0.3,
                .transition: 0.2,
                .feedback: 0.1
            ]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: "animationDurations")
            }
        }
    }
    
    var blurRadius: Double {
        get {
            let radius = userDefaults.double(forKey: "blurRadius")
            if radius == 0 && !userDefaults.bool(forKey: "blurRadiusSet") {
                return 20.0 // Default 20
            }
            return max(0.0, min(50.0, radius)) // Always clamp
        }
        set {
            let validatedValue = max(0.0, min(50.0, newValue))
            userDefaults.set(validatedValue, forKey: "blurRadius")
            userDefaults.set(true, forKey: "blurRadiusSet")
        }
    }
    
    var blurOpacity: Double {
        get {
            let opacity = userDefaults.double(forKey: "blurOpacity")
            if opacity == 0 && !userDefaults.bool(forKey: "blurOpacitySet") {
                return 0.8 // Default 0.8
            }
            return opacity
        }
        set {
            let validatedValue = max(0.0, min(1.0, newValue))
            userDefaults.set(validatedValue, forKey: "blurOpacity")
            userDefaults.set(true, forKey: "blurOpacitySet")
        }
    }
    
    var loggingLevel: LogLevel {
        get {
            if let levelString = userDefaults.string(forKey: "loggingLevel"),
               let level = LogLevel(rawValue: Int(levelString) ?? 1) {
                return level
            }
            return .info // Default
        }
        set {
            userDefaults.set(String(newValue.rawValue), forKey: "loggingLevel")
        }
    }
    
    var windowPosition: WindowPosition {
        get {
            if let positionString = userDefaults.string(forKey: "windowPosition"),
               let position = WindowPosition(rawValue: positionString) {
                return position
            }
            return .normal // Default
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: "windowPosition")
        }
    }
    
    var slideShowPresetIntervals: [TimeInterval] {
        // Read-only property
        return [1, 2, 3, 5, 10, 20, 30, 60, 120, 300, 600, 1200, 1800]
    }
}

final class MockSettingsManager: SettingsManagerProtocol {
    var slideShowInterval: TimeInterval = 10.0
    var repeatEnabled: Bool = false
    var sortType: SortType = .name(ascending: true)
    var debugLoggingEnabled: Bool = false
    
    // Phase 1 new properties
    var autoHideDelay: TimeInterval = 3.0
    var animationDurations: [AnimationType: TimeInterval] = [
        .control: 0.3,
        .transition: 0.2,
        .feedback: 0.1
    ]
    var blurRadius: Double = 20.0
    var blurOpacity: Double = 0.8
    var loggingLevel: LogLevel = .info
    var windowPosition: WindowPosition = .normal
    var slideShowPresetIntervals: [TimeInterval] = [1, 2, 3, 5, 10, 20, 30, 60, 120, 300, 600, 1200, 1800]
    
    // AdaptiveImageCache properties
    var customCacheMemoryLimit: Int?
    var preloadImageCount: Int?
}