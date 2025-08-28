//
//  WindowControllerTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/28.
//

import XCTest
import AppKit
@testable import SwiftViewer

final class WindowControllerTests: XCTestCase {
    
    var sut: WindowController!
    var mockWindow: MockNSWindow!
    
    override func setUp() {
        super.setUp()
        mockWindow = MockNSWindow()
        sut = WindowController()
    }
    
    override func tearDown() {
        sut = nil
        mockWindow = nil
        super.tearDown()
    }
    
    // MARK: - Window Level Tests
    
    func test_setWindowLevel_alwaysOnTop_shouldSetFloatingLevel() {
        // Given: Controller with mock window
        sut.setWindow(mockWindow)
        
        // When: Set always on top
        sut.setWindowLevel(.alwaysOnTop)
        
        // Then: Window level is floating
        XCTAssertEqual(mockWindow.level, .floating)
    }
    
    func test_setWindowLevel_alwaysOnBottom_shouldSetBackgroundLevel() {
        // Given: Controller with mock window
        sut.setWindow(mockWindow)
        
        // When: Set always on bottom
        sut.setWindowLevel(.alwaysOnBottom)
        
        // Then: Window level is background/desktop
        XCTAssertEqual(mockWindow.level, .init(Int(CGWindowLevelForKey(.desktopWindow))))
    }
    
    func test_setWindowLevel_normal_shouldSetNormalLevel() {
        // Given: Controller with mock window
        sut.setWindow(mockWindow)
        
        // When: Set normal position
        sut.setWindowLevel(.normal)
        
        // Then: Window level is normal
        XCTAssertEqual(mockWindow.level, .normal)
    }
    
    func test_setWindowLevel_withNoWindow_shouldNotCrash() {
        // Given: Controller with no window
        XCTAssertNoThrow {
            // When: Try to set window level
            self.sut.setWindowLevel(.alwaysOnTop)
        }
        // Then: Should not crash (no window to set)
    }
    
    func test_setWindow_shouldStoreWindowReference() {
        // Given: Controller and window
        
        // When: Set window
        sut.setWindow(mockWindow)
        
        // Then: Window is stored (tested via subsequent level setting)
        sut.setWindowLevel(.alwaysOnTop)
        XCTAssertEqual(mockWindow.level, .floating)
    }
    
    // MARK: - Shared Instance Tests
    
    func test_sharedInstance_shouldReturnSameInstance() {
        // Given/When: Get shared instances
        let instance1 = WindowController.shared
        let instance2 = WindowController.shared
        
        // Then: Should be same instance
        XCTAssertTrue(instance1 === instance2)
    }
}

// MARK: - Mock NSWindow

final class MockNSWindow: NSWindow {
    private var _level: NSWindow.Level = .normal
    
    override var level: NSWindow.Level {
        get { _level }
        set { _level = newValue }
    }
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
    }
}