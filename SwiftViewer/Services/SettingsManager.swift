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
    
    // Image transition support
    var transitionType: TransitionType { get set }
    
    // Cache configuration properties
    var cacheMemoryLimitPercentage: Double { get set } // 1-50% of system memory
    var cacheDiskLimitMB: Int { get set } // Disk cache limit in MB
    var cacheCountLimit: Int { get set } // Max number of cached images
    var cachePreloadPercentage: Double { get set } // 10-100% of images to preload
}

enum SettingsKeys {
    static let debugLoggingEnabled = "debugLoggingEnabled"
    static let loggingLevel = "loggingLevel"
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
            userDefaults.bool(forKey: SettingsKeys.debugLoggingEnabled)
        }
        set {
            userDefaults.set(newValue, forKey: SettingsKeys.debugLoggingEnabled)
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
            guard let data = userDefaults.data(forKey: "animationDurations") else {
                return defaultAnimationDurations
            }
            do {
                return try JSONDecoder().decode([AnimationType: TimeInterval].self, from: data)
            } catch {
                Logger.shared.warning("Failed to decode animationDurations: \(error.localizedDescription)")
                return defaultAnimationDurations
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                userDefaults.set(data, forKey: "animationDurations")
            } catch {
                Logger.shared.warning("Failed to encode animationDurations: \(error.localizedDescription)")
            }
        }
    }

    private var defaultAnimationDurations: [AnimationType: TimeInterval] {
        [.control: 0.3, .transition: 0.2, .feedback: 0.1]
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
            if let levelString = userDefaults.string(forKey: SettingsKeys.loggingLevel),
               let level = LogLevel(rawValue: Int(levelString) ?? 1) {
                return level
            }
            return .info // Default
        }
        set {
            userDefaults.set(String(newValue.rawValue), forKey: SettingsKeys.loggingLevel)
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
    
    var transitionType: TransitionType {
        get {
            if let transitionString = userDefaults.string(forKey: "transitionType"),
               let type = TransitionType(rawValue: transitionString) {
                return type
            }
            return .crossDissolve // Default
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: "transitionType")
        }
    }
    
    // MARK: - Cache Configuration Properties
    
    var cacheMemoryLimitPercentage: Double {
        get {
            let percentage = userDefaults.double(forKey: "cacheMemoryLimitPercentage")
            if percentage == 0 && !userDefaults.bool(forKey: "cacheMemoryLimitPercentageSet") {
                return 15.0 // Default 15% of system memory
            }
            return max(1.0, min(50.0, percentage))
        }
        set {
            let validatedValue = max(1.0, min(50.0, newValue))
            userDefaults.set(validatedValue, forKey: "cacheMemoryLimitPercentage")
            userDefaults.set(true, forKey: "cacheMemoryLimitPercentageSet")
        }
    }
    
    var cacheDiskLimitMB: Int {
        get {
            let limit = userDefaults.integer(forKey: "cacheDiskLimitMB")
            return limit > 0 ? limit : 500 // Default 500MB
        }
        set {
            let validatedValue = max(100, min(10000, newValue)) // 100MB to 10GB
            userDefaults.set(validatedValue, forKey: "cacheDiskLimitMB")
        }
    }
    
    var cacheCountLimit: Int {
        get {
            let limit = userDefaults.integer(forKey: "cacheCountLimit")
            return limit > 0 ? limit : 100 // Default 100 images
        }
        set {
            let validatedValue = max(10, min(1000, newValue)) // 10 to 1000 images
            userDefaults.set(validatedValue, forKey: "cacheCountLimit")
        }
    }
    
    var cachePreloadPercentage: Double {
        get {
            let percentage = userDefaults.double(forKey: "cachePreloadPercentage")
            if percentage == 0 && !userDefaults.bool(forKey: "cachePreloadPercentageSet") {
                return 20.0 // Default 20% preload
            }
            return max(10.0, min(100.0, percentage))
        }
        set {
            let validatedValue = max(10.0, min(100.0, newValue))
            userDefaults.set(validatedValue, forKey: "cachePreloadPercentage")
            userDefaults.set(true, forKey: "cachePreloadPercentageSet")
        }
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
    
    // Image transition support
    var transitionType: TransitionType = .crossDissolve
    
    // Cache configuration properties
    var cacheMemoryLimitPercentage: Double = 15.0
    var cacheDiskLimitMB: Int = 500
    var cacheCountLimit: Int = 100
    var cachePreloadPercentage: Double = 20.0
    
    // Legacy testing properties (deprecated)
    var customCacheMemoryLimit: Int? = nil
    var preloadImageCount: Int? = nil
}