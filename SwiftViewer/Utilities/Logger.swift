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