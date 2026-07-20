//
//  LogCapture.swift
//  SwiftViewerTests
//
//  Created by SwiftViewer on 2025-08-26.
//

import Foundation
import XCTest
@testable import SwiftViewer

/// Utility for capturing and validating log output in tests
struct LogCapture {
    private var capturedLogs: [LogEntry] = []
    private var isCapturing = false
    
    struct LogEntry {
        let level: LogLevel
        let message: String
        let timestamp: Date
        let category: String
    }
    
    /// Start capturing log output
    mutating func startCapture() {
        isCapturing = true
        capturedLogs.removeAll()
    }
    
    /// Stop capturing and return captured logs
    mutating func stopCapture() -> [LogEntry] {
        isCapturing = false
        return capturedLogs
    }
    
    /// Record a log entry (called by Logger extensions)
    mutating func recordLog(level: LogLevel, message: String, category: String) {
        guard isCapturing else { return }
        capturedLogs.append(LogEntry(
            level: level,
            message: message,
            timestamp: Date(),
            category: category
        ))
    }
    
    /// Validate that specific log patterns were captured
    func validateLogPattern(_ pattern: String, level: LogLevel? = nil) -> Bool {
        return capturedLogs.contains { entry in
            let levelMatches = level == nil || entry.level == level
            let messageMatches = entry.message.contains(pattern)
            return levelMatches && messageMatches
        }
    }
    
    /// Get formatted log output for debugging
    func getFormattedLogs(name: String = "captured_logs") -> String {
        return capturedLogs.map { entry in
            "[\(entry.timestamp)] [\(entry.level)] [\(entry.category)] \(entry.message)"
        }.joined(separator: "\n")
    }
    
    /// Filter logs by level
    func logs(atLevel level: LogLevel) -> [LogEntry] {
        return capturedLogs.filter { $0.level == level }
    }
    
    /// Filter logs by category
    func logs(inCategory category: String) -> [LogEntry] {
        return capturedLogs.filter { $0.category == category }
    }
}

/// Global log capture instance for test coordination
nonisolated(unsafe) var testLogCapture = LogCapture()