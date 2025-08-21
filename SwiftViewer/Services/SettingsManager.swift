//
//  SettingsManager.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation

protocol SettingsManagerProtocol {
    var slideShowInterval: TimeInterval { get set }
    var repeatEnabled: Bool { get set }
    var sortType: SortType { get set }
    var debugLoggingEnabled: Bool { get set }
}

final class SettingsManager: SettingsManagerProtocol {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    var slideShowInterval: TimeInterval {
        get {
            let interval = userDefaults.double(forKey: "slideShowInterval")
            return interval > 0 ? interval : 3.0
        }
        set {
            userDefaults.set(newValue, forKey: "slideShowInterval")
        }
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
}

final class MockSettingsManager: SettingsManagerProtocol {
    var slideShowInterval: TimeInterval = 3.0
    var repeatEnabled: Bool = false
    var sortType: SortType = .name(ascending: true)
    var debugLoggingEnabled: Bool = false
}