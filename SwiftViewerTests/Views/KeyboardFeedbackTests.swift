//
//  KeyboardFeedbackTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class KeyboardFeedbackTests: XCTestCase {
    
    var mockContainer: MockDependencyContainer!
    var viewModel: ImageGalleryViewModel!
    
    override func setUp() {
        super.setUp()
        mockContainer = MockDependencyContainer()
        viewModel = ImageGalleryViewModel(dependencies: mockContainer)
        
        // Set up mock images for testing
        let mockImages = [
            ImageFile(url: URL(fileURLWithPath: "/test1.jpg"), fileName: "test1.jpg", fileSize: 1024, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/test2.jpg"), fileName: "test2.jpg", fileSize: 2048, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/test3.jpg"), fileName: "test3.jpg", fileSize: 3072, createdDate: Date())
        ]
        viewModel.imageFiles = mockImages
        viewModel.currentIndex = 1 // Start in middle
        viewModel.isLoading = false
    }
    
    override func tearDown() {
        viewModel = nil
        mockContainer = nil
        super.tearDown()
    }
    
    func test_controlButtonStyle_keyboardFeedback_leftKey() {
        // Test that left key press affects button state
        let normalStyle = ControlButtonStyle(isKeyPressed: false)
        let pressedStyle = ControlButtonStyle(isKeyPressed: true)
        
        // The styles should have different key press states
        XCTAssertFalse(normalStyle.isKeyPressed)
        XCTAssertTrue(pressedStyle.isKeyPressed)
    }
    
    func test_controlButtonStyle_keyboardFeedback_spaceKey() {
        // Test space key feedback for play/pause button
        let inactiveStyle = ControlButtonStyle(isActive: false, isKeyPressed: false)
        let activeStyle = ControlButtonStyle(isActive: true, isKeyPressed: false)
        let activeWithKeyStyle = ControlButtonStyle(isActive: true, isKeyPressed: true)
        
        // Verify state combinations
        XCTAssertFalse(inactiveStyle.isActive)
        XCTAssertFalse(inactiveStyle.isKeyPressed)
        
        XCTAssertTrue(activeStyle.isActive)
        XCTAssertFalse(activeStyle.isKeyPressed)
        
        XCTAssertTrue(activeWithKeyStyle.isActive)
        XCTAssertTrue(activeWithKeyStyle.isKeyPressed)
    }
    
    func test_controlButtonStyle_keyboardFeedback_rightKey() {
        // Test right key press affects button state
        let normalStyle = ControlButtonStyle(isKeyPressed: false)
        let pressedStyle = ControlButtonStyle(isKeyPressed: true)
        
        XCTAssertFalse(normalStyle.isKeyPressed)
        XCTAssertTrue(pressedStyle.isKeyPressed)
    }
    
    func test_keyboardFeedback_animationTiming() {
        // Test that keyboard feedback states can be properly set and reset
        // This is a structural test since we can't test actual animation timing
        
        let style = ControlButtonStyle(isKeyPressed: false)
        XCTAssertFalse(style.isKeyPressed)
        
        let pressedStyle = ControlButtonStyle(isKeyPressed: true)
        XCTAssertTrue(pressedStyle.isKeyPressed)
        
        // In actual implementation, isKeyPressed would be set to true briefly
        // then reset to false after animation duration (0.1 seconds)
        let resetStyle = ControlButtonStyle(isKeyPressed: false)
        XCTAssertFalse(resetStyle.isKeyPressed)
    }
}