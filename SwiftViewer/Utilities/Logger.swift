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

final class Logger {
    static let shared = Logger()
    
    private let subsystem = Bundle.main.bundleIdentifier ?? "oshiire.SwiftViewer"
    private let osLog: OSLog
    
    init() {
        self.osLog = OSLog(subsystem: subsystem, category: "SwiftViewer")
    }
    
    private var isDebugLoggingEnabled: Bool {
        UserDefaults.standard.bool(forKey: "debugLoggingEnabled")
    }
    
    func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isDebugLoggingEnabled else { return }
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
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
    
    /// Context-aware logger for specific view components
    /// Following Swift-Log value semantics pattern
    static func viewLogger(for viewName: String) -> Logger {
        // Future: Create logger instance with embedded context metadata
        // For now, return shared instance (maintains current behavior)
        return Logger.shared
    }
}

// MARK: - Test Environment Support

extension Logger {
    /// Detects if currently running in test environment
    var isTestEnvironment: Bool {
        return NSClassFromString("XCTestCase") != nil || 
               ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
               ProcessInfo.processInfo.arguments.contains("-XCTestObserver")
    }
    
    /// Test category for log capture
    typealias LogLevel = LogLevel
    
    /// Captures logs for test validation when in test environment
    func logForTesting(
        _ message: String,
        level: LogLevel,
        category: String = "SwiftViewer",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Always perform normal logging
        log(message, level: level, file: file, function: function, line: line)
        
        // Additionally capture for tests if in test environment
        #if DEBUG
        if isTestEnvironment {
            // Import test module types only in test environment
            // This will be used by LogCapture utility
            if var capture = testLogCaptureIfAvailable() {
                capture.recordLog(level: level, message: message, category: category)
            }
        }
        #endif
    }
    
    /// Safe access to test log capture (returns nil if not in test environment)
    private func testLogCaptureIfAvailable() -> Any? {
        // This will be accessed via runtime checks in test environment
        // Prevents import dependency on test modules in production code
        return nil
    }
}