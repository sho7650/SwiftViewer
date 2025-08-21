//
//  LoggerTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
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
    
    func test_logger_logsDebugMessage_whenDebugLoggingEnabled() {
        UserDefaults.standard.set(true, forKey: "debugLoggingEnabled")
        
        let logger = Logger()
        let testMessage = "Test debug message"
        
        XCTAssertNoThrow(logger.debug(testMessage))
    }
    
    func test_logger_doesNotLogDebugMessage_whenDebugLoggingDisabled() {
        UserDefaults.standard.set(false, forKey: "debugLoggingEnabled")
        
        let logger = Logger()
        let testMessage = "Test debug message"
        
        XCTAssertNoThrow(logger.debug(testMessage))
    }
    
    func test_logger_logsInfoMessage() {
        let logger = Logger()
        let testMessage = "Test info message"
        
        XCTAssertNoThrow(logger.info(testMessage))
    }
    
    func test_logger_logsWarningMessage() {
        let logger = Logger()
        let testMessage = "Test warning message"
        
        XCTAssertNoThrow(logger.warning(testMessage))
    }
    
    func test_logger_logsErrorMessage() {
        let logger = Logger()
        let testMessage = "Test error message"
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        
        XCTAssertNoThrow(logger.error(testMessage, error: testError))
    }
    
    func test_logger_formatsMessageWithFile_andFunction_andLine() {
        let logger = Logger()
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
    
    func test_logLevel_hasCorrectPriority() {
        XCTAssertLessThan(LogLevel.debug.rawValue, LogLevel.info.rawValue)
        XCTAssertLessThan(LogLevel.info.rawValue, LogLevel.warning.rawValue)
        XCTAssertLessThan(LogLevel.warning.rawValue, LogLevel.error.rawValue)
    }
}