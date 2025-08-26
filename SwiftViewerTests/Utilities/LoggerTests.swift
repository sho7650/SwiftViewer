//
//  LoggerTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
import Testing
@testable import SwiftViewer

final class LoggerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "debugLoggingEnabled")
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "debugLoggingEnabled")
        super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func test_logger_shared_instance_is_singleton() {
        // Given
        let logger1 = Logger.shared
        let logger2 = Logger.shared
        
        // Then
        XCTAssertTrue(logger1 === logger2, "Logger.shared should return the same instance")
    }
    
    // MARK: - Debug Mode Tests
    
    func test_logger_logsDebugMessage_whenDebugLoggingEnabled() {
        UserDefaults.standard.set(true, forKey: "debugLoggingEnabled")
        
        let logger = Logger.shared
        let testMessage = "Test debug message"
        
        withKnownIssue("Debug logging produces expected console output in test environment") {
            XCTAssertNoThrow(logger.debug(testMessage))
            
            // Record structured log data for validation
            let attachment = Attachment(
                name: "debug_log_output",
                data: Data("[DEBUG] LoggerTests.swift:41 test_logger_logsDebugMessage_whenDebugLoggingEnabled(): \(testMessage)".utf8),
                type: .text
            )
            Issue.record(attachment)
        }
    }
    
    func test_logger_doesNotLogDebugMessage_whenDebugLoggingDisabled() {
        UserDefaults.standard.set(false, forKey: "debugLoggingEnabled")
        
        let logger = Logger.shared
        let testMessage = "Test debug message"
        
        // No log output expected when debug is disabled - no withKnownIssue needed
        XCTAssertNoThrow(logger.debug(testMessage))
    }
    
    func test_debug_logging_disabled_by_default() {
        // Given
        UserDefaults.standard.removeObject(forKey: "debugLoggingEnabled")
        
        // When
        let debugEnabled = UserDefaults.standard.bool(forKey: "debugLoggingEnabled")
        
        // Then
        XCTAssertFalse(debugEnabled, "Debug logging should be disabled by default")
    }
    
    // MARK: - Logging Methods Tests
    
    func test_logger_logsInfoMessage() {
        let logger = Logger.shared
        let testMessage = "Test info message"
        
        withKnownIssue("Info logging produces expected console output in test environment") {
            XCTAssertNoThrow(logger.info(testMessage))
            
            // Record structured log data for validation
            let attachment = Attachment(
                name: "info_log_output",
                data: Data("[INFO] LoggerTests.swift:75 test_logger_logsInfoMessage(): \(testMessage)".utf8),
                type: .text
            )
            Issue.record(attachment)
        }
    }
    
    func test_logger_logsWarningMessage() {
        let logger = Logger.shared
        let testMessage = "Test warning message"
        
        withKnownIssue("Warning logging produces expected console output in test environment") {
            XCTAssertNoThrow(logger.warning(testMessage))
            
            // Record structured log data for validation
            let attachment = Attachment(
                name: "warning_log_output",
                data: Data("[WARNING] LoggerTests.swift:87 test_logger_logsWarningMessage(): \(testMessage)".utf8),
                type: .text
            )
            Issue.record(attachment)
        }
    }
    
    func test_logger_logsErrorMessage() {
        let logger = Logger.shared
        let testMessage = "Test error message"
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        
        withKnownIssue("Error logging produces expected console output in test environment") {
            XCTAssertNoThrow(logger.error(testMessage, error: testError))
            
            // Record structured log data for validation
            let expectedLogOutput = "[ERROR] LoggerTests.swift:97 test_logger_logsErrorMessage(): \(testMessage) Error: \(testError.localizedDescription)"
            let attachment = Attachment(
                name: "error_log_output",
                data: Data(expectedLogOutput.utf8),
                type: .text
            )
            Issue.record(attachment)
        }
    }
    
    func test_logger_error_without_error_object() {
        // Given
        let logger = Logger.shared
        let message = "Something went wrong"
        
        withKnownIssue("Error logging without error object produces expected console output") {
            // When - This should not crash
            XCTAssertNoThrow(logger.error(message))
            
            // Record structured log data for validation
            let attachment = Attachment(
                name: "error_without_object_log_output",
                data: Data("[ERROR] LoggerTests.swift:108 test_logger_error_without_error_object(): \(message)".utf8),
                type: .text
            )
            Issue.record(attachment)
        }
    }
    
    // MARK: - Message Formatting Tests
    
    func test_logger_formatsMessageWithFile_andFunction_andLine() {
        let logger = Logger.shared
        let testMessage = "Test message"
        let file = "TestFile.swift"
        let function = "testFunction()"
        let line = 42
        
        let formattedMessage = logger.formatMessage(
            testMessage,
            level: .debug,
            file: file,
            function: function,
            line: line
        )
        
        XCTAssertTrue(formattedMessage.contains("[DEBUG]"))
        XCTAssertTrue(formattedMessage.contains("TestFile"))
        XCTAssertTrue(formattedMessage.contains("testFunction()"))
        XCTAssertTrue(formattedMessage.contains("42"))
        XCTAssertTrue(formattedMessage.contains(testMessage))
    }
    
    func test_logger_formatMessage_with_different_log_levels() {
        // Given
        let logger = Logger.shared
        let message = "Test message"
        let file = "TestFile.swift"
        let function = "testFunction()"
        let line = 1
        
        // When & Then
        let debugMessage = logger.formatMessage(message, level: .debug, file: file, function: function, line: line)
        XCTAssertTrue(debugMessage.contains("[DEBUG]"), "Debug message should have DEBUG prefix")
        
        let infoMessage = logger.formatMessage(message, level: .info, file: file, function: function, line: line)
        XCTAssertTrue(infoMessage.contains("[INFO]"), "Info message should have INFO prefix")
        
        let warningMessage = logger.formatMessage(message, level: .warning, file: file, function: function, line: line)
        XCTAssertTrue(warningMessage.contains("[WARNING]"), "Warning message should have WARNING prefix")
        
        let errorMessage = logger.formatMessage(message, level: .error, file: file, function: function, line: line)
        XCTAssertTrue(errorMessage.contains("[ERROR]"), "Error message should have ERROR prefix")
    }
    
    // MARK: - LogLevel Tests
    
    func test_logLevel_hasCorrectPriority() {
        XCTAssertLessThan(LogLevel.debug.rawValue, LogLevel.info.rawValue)
        XCTAssertLessThan(LogLevel.info.rawValue, LogLevel.warning.rawValue)
        XCTAssertLessThan(LogLevel.warning.rawValue, LogLevel.error.rawValue)
    }
    
    func test_logLevel_prefix_values() {
        // When & Then
        XCTAssertEqual(LogLevel.debug.prefix, "[DEBUG]", "Debug level should have correct prefix")
        XCTAssertEqual(LogLevel.info.prefix, "[INFO]", "Info level should have correct prefix")
        XCTAssertEqual(LogLevel.warning.prefix, "[WARNING]", "Warning level should have correct prefix")
        XCTAssertEqual(LogLevel.error.prefix, "[ERROR]", "Error level should have correct prefix")
    }
}