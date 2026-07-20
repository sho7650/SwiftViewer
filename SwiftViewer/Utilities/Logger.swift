//
//  Logger.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation
import os.log

enum LogLevel: Int {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    var prefix: String {
        switch self {
        case .debug: return "[DEBUG]"
        case .info: return "[INFO]"
        case .warning: return "[WARNING]"
        case .error: return "[ERROR]"
        }
    }
}

/// Immutable and thread-safe: stored state is created once, and logging goes through
/// `os_log` and `UserDefaults`, which are themselves thread-safe.
final class Logger: @unchecked Sendable {
    static let shared = Logger()

    private let subsystem = Bundle.main.bundleIdentifier ?? "oshiire.SwiftViewer"
    private let osLog: OSLog

    init() {
        self.osLog = OSLog(subsystem: subsystem, category: "SwiftViewer")
    }

    private var isDebugLoggingEnabled: Bool {
        UserDefaults.standard.bool(forKey: SettingsKeys.debugLoggingEnabled)
    }

    // MARK: - Path Sanitization

    /// Sanitizes file paths in log messages to prevent exposing sensitive directory structure.
    /// Only shows the last two path components (parent directory + filename).
    static func sanitizePath(_ path: String) -> String {
        let components = (path as NSString).pathComponents
        if components.count <= 2 {
            return path
        }
        // Return only the last two components (parent/filename)
        return components.suffix(2).joined(separator: "/")
    }

    /// Sanitizes a URL for safe logging
    static func sanitizePath(_ url: URL) -> String {
        sanitizePath(url.path)
    }
    
    /// Get the current logging level from UserDefaults, defaulting to .info
    private var currentLoggingLevel: LogLevel {
        if let levelString = UserDefaults.standard.string(forKey: SettingsKeys.loggingLevel),
           let rawValue = Int(levelString),
           let level = LogLevel(rawValue: rawValue) {
            return level
        }
        return .info // Default to info level
    }
    
    /// Check if a message should be logged based on current logging level
    private func shouldLog(level: LogLevel) -> Bool {
        // Special case for debug: requires both debugLoggingEnabled AND appropriate level
        if level == .debug {
            return isDebugLoggingEnabled && level.rawValue >= currentLoggingLevel.rawValue
        }
        
        // For other levels, check against current logging level
        return level.rawValue >= currentLoggingLevel.rawValue
    }
    
    func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard shouldLog(level: .debug) else { return }
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard shouldLog(level: .info) else { return }
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard shouldLog(level: .warning) else { return }
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard shouldLog(level: .error) else { return }
        var fullMessage = message
        if let error = error {
            fullMessage += " Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .error, file: file, function: function, line: line)
    }
    
    private func log(
        _ message: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatMessage(
            message,
            level: level,
            file: file,
            function: function,
            line: line
        )
        
        #if DEBUG
        print(formattedMessage)
        #endif
        
        let osLogType: OSLogType
        switch level {
        case .debug:
            osLogType = .debug
        case .info:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        }
        
        os_log("%{public}@", log: osLog, type: osLogType, formattedMessage)
    }
    
    func formatMessage(
        _ message: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) -> String {
        let fileName = (file as NSString).lastPathComponent
        return "\(level.prefix) [\(fileName):\(line)] \(function): \(message)"
    }
}

// MARK: - Logger Extensions for Future Structured Logging

extension Logger {
    
    /// Structured logging support for future metadata enhancement
    /// Following Swift-Log best practices from apple/swift-log
    func info(
        _ message: String,
        metadata: [String: String],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // For now, format metadata as key=value pairs in the message
        // Future: Integrate with Swift-Log's Logger.Metadata for structured output
        let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        let enrichedMessage = metadata.isEmpty ? message : "\(message) [\(metadataString)]"
        info(enrichedMessage, file: file, function: function, line: line)
    }
    
    func debug(
        _ message: String,
        metadata: [String: String],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        let enrichedMessage = metadata.isEmpty ? message : "\(message) [\(metadataString)]"
        debug(enrichedMessage, file: file, function: function, line: line)
    }
    
    func error(
        _ message: String,
        error: Error?,
        metadata: [String: String],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        let baseMessage = metadata.isEmpty ? message : "\(message) [\(metadataString)]"
        self.error(baseMessage, error: error, file: file, function: function, line: line)
    }
    
}

