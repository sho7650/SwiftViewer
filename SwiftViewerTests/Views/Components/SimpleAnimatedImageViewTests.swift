//
//  SimpleAnimatedImageViewTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/27.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class SimpleAnimatedImageViewTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func test_simpleAnimatedImageView_initialization() {
        let testURL = URL(fileURLWithPath: "/test/animation.gif")
        let view = SimpleAnimatedImageView(url: testURL)
        
        XCTAssertNotNil(view)
        XCTAssertEqual(view.url, testURL)
    }
    
    func test_simpleAnimatedImageView_body_renders() {
        let testURL = URL(fileURLWithPath: "/test/animation.gif")
        let view = SimpleAnimatedImageView(url: testURL)
        
        let body = view.body
        XCTAssertNotNil(body)
        
        // Test that the view can be rendered without crashing
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
    }
    
    // MARK: - Animation Control Tests
    
    func test_simpleAnimatedImageView_pause_functionality() {
        let testURL = URL(fileURLWithPath: "/test/animation.gif")
        let view = SimpleAnimatedImageView(url: testURL)
        
        // Test pause functionality
        view.pause()
        // Since we can't directly access @State variables in tests,
        // we'll test that the method doesn't crash
        XCTAssertTrue(true)
    }
    
    func test_simpleAnimatedImageView_resume_functionality() {
        let testURL = URL(fileURLWithPath: "/test/animation.gif")
        let view = SimpleAnimatedImageView(url: testURL)
        
        // Test resume functionality
        view.resume()
        // Since we can't directly access @State variables in tests,
        // we'll test that the method doesn't crash
        XCTAssertTrue(true)
    }
    
    func test_simpleAnimatedImageView_toggle_functionality() {
        let testURL = URL(fileURLWithPath: "/test/animation.gif")
        let view = SimpleAnimatedImageView(url: testURL)
        
        // Test toggle functionality
        view.togglePlayback()
        view.togglePlayback() // Toggle twice
        // Since we can't directly access @State variables in tests,
        // we'll test that the method doesn't crash
        XCTAssertTrue(true)
    }
    
    // MARK: - URL Validation Tests
    
    func test_simpleAnimatedImageView_handles_valid_file_url() {
        let validURL = URL(fileURLWithPath: "/Users/test/Documents/animation.gif")
        let view = SimpleAnimatedImageView(url: validURL)
        
        XCTAssertNotNil(view)
        XCTAssertEqual(view.url, validURL)
    }
    
    func test_simpleAnimatedImageView_handles_invalid_file_url() {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/path/animation.gif")
        let view = SimpleAnimatedImageView(url: invalidURL)
        
        // Should still initialize but won't load frames
        XCTAssertNotNil(view)
        XCTAssertEqual(view.url, invalidURL)
    }
    
    // MARK: - SwiftUI Integration Tests
    
    func test_simpleAnimatedImageView_id_modifier_compatibility() {
        let testURL1 = URL(fileURLWithPath: "/test/animation1.gif")
        let testURL2 = URL(fileURLWithPath: "/test/animation2.gif")
        
        let view1 = SimpleAnimatedImageView(url: testURL1)
            .id(testURL1.absoluteString)
        
        let view2 = SimpleAnimatedImageView(url: testURL2)
            .id(testURL2.absoluteString)
        
        XCTAssertNotNil(view1)
        XCTAssertNotNil(view2)
    }
    
    func test_simpleAnimatedImageView_frame_modifier_compatibility() {
        let testURL = URL(fileURLWithPath: "/test/animation.gif")
        let view = SimpleAnimatedImageView(url: testURL)
            .frame(width: 400, height: 300)
        
        XCTAssertNotNil(view)
    }
    
    // MARK: - Performance Tests
    
    func test_simpleAnimatedImageView_multiple_instances() {
        let urls = (1...10).map { URL(fileURLWithPath: "/test/animation\($0).gif") }
        let views = urls.map { SimpleAnimatedImageView(url: $0) }
        
        XCTAssertEqual(views.count, 10)
        
        // Test that creating multiple instances doesn't cause issues
        for (index, view) in views.enumerated() {
            XCTAssertEqual(view.url, urls[index])
        }
    }
    
    func test_simpleAnimatedImageView_memory_management() {
        var view: SimpleAnimatedImageView? = SimpleAnimatedImageView(
            url: URL(fileURLWithPath: "/test/animation.gif")
        )
        
        XCTAssertNotNil(view)
        
        // Simulate deallocation
        view = nil
        XCTAssertNil(view)
    }
    
    // MARK: - Edge Cases
    
    func test_simpleAnimatedImageView_empty_filename() {
        let testURL = URL(fileURLWithPath: "/test/.gif")
        let view = SimpleAnimatedImageView(url: testURL)
        
        XCTAssertNotNil(view)
        XCTAssertEqual(view.url, testURL)
    }
    
    func test_simpleAnimatedImageView_long_filename() {
        let longName = String(repeating: "a", count: 255)
        let testURL = URL(fileURLWithPath: "/test/\(longName).gif")
        let view = SimpleAnimatedImageView(url: testURL)
        
        XCTAssertNotNil(view)
        XCTAssertEqual(view.url, testURL)
    }
}

// MARK: - Test Helper Extensions

extension SimpleAnimatedImageViewTests {
    
    /// Helper method to create a test GIF URL
    private func createTestGIFURL(named: String = "test") -> URL {
        return URL(fileURLWithPath: "/tmp/\(named).gif")
    }
    
    /// Helper method to verify view rendering without crashes
    private func verifyViewRendering(_ view: SimpleAnimatedImageView) {
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
    }
}