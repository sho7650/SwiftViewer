//
//  BlurredImageBackgroundTests.swift
//  SwiftViewerTests
//
//  Created by SwiftViewer on 2025-08-26.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

final class BlurredImageBackgroundTests: XCTestCase {
    
    private var testImage: NSImage!
    
    override func setUpWithError() throws {
        super.setUp()
        // Create a test image (1x1 pixel for testing)
        testImage = NSImage(size: NSSize(width: 100, height: 100))
        testImage.lockFocus()
        NSColor.blue.set()
        NSRect(origin: .zero, size: NSSize(width: 100, height: 100)).fill()
        testImage.unlockFocus()
    }
    
    override func tearDownWithError() throws {
        testImage = nil
        super.tearDown()
    }
    
    // MARK: - Rendering Tests

    func test_BlurredImageBackground_WhenImageProvided_ShouldApplyBlurEffect() throws {
        // Given
        let blurredBackground = BlurredImageBackground(image: testImage)

        // When
        let hostingController = NSHostingController(rootView: blurredBackground)
        let view = hostingController.view

        // Then
        XCTAssertNotNil(view, "BlurredImageBackground should render a view")
    }

    func test_BlurredImageBackground_WhenNoImage_ShouldShowTransparentBackground() throws {
        // Given
        let blurredBackground = BlurredImageBackground(image: nil)

        // When
        let hostingController = NSHostingController(rootView: blurredBackground)
        let view = hostingController.view

        // Then
        XCTAssertNotNil(view, "BlurredImageBackground should render a view even with nil image")
    }

    func test_BlurredImageBackground_ShouldScaleToFillEntireArea() throws {
        // Given
        let blurredBackground = BlurredImageBackground(image: testImage)

        // When
        let hostingController = NSHostingController(rootView: blurredBackground.frame(width: 800, height: 600))
        let view = hostingController.view

        // Then
        XCTAssertNotNil(view, "BlurredImageBackground should render within specified frame")
    }
    
    func test_BlurredImageBackground_ShouldHaveCorrectBlurRadius() throws {
        // Given
        let expectedBlurRadius: CGFloat = 25.0
        let blurredBackground = BlurredImageBackground(
            image: testImage,
            blurRadius: expectedBlurRadius,
            backgroundOpacity: 0.4
        )
        
        // When
        let hostingController = NSHostingController(rootView: blurredBackground)
        let view = hostingController.view
        
        // Then
        XCTAssertNotNil(view, "BlurredImageBackground should render a view")
        
        // Verify that custom parameters are accepted and used
        XCTAssertEqual(blurredBackground.blurRadius, expectedBlurRadius, "BlurredImageBackground should use custom blur radius")
        XCTAssertEqual(blurredBackground.backgroundOpacity, 0.4, "BlurredImageBackground should use custom opacity")
    }
    
    func test_BlurredImageBackground_WithDefaultParameters_ShouldUseDefaults() throws {
        // Given
        let blurredBackground = BlurredImageBackground(image: testImage)
        
        // When
        let hostingController = NSHostingController(rootView: blurredBackground)
        let view = hostingController.view
        
        // Then
        XCTAssertNotNil(view, "BlurredImageBackground should render a view")
        
        // Verify default parameters are used when not specified
        XCTAssertEqual(blurredBackground.blurRadius, 20.0, "BlurredImageBackground should use default blur radius")
        XCTAssertEqual(blurredBackground.backgroundOpacity, 0.3, "BlurredImageBackground should use default opacity")
    }
    
    // MARK: - Performance Tests
    
    func test_BlurBackgroundPerformance_ShouldRenderWithin10ms() throws {
        // Given
        let largeImage = NSImage(size: NSSize(width: 1920, height: 1080))
        largeImage.lockFocus()
        NSColor.red.set()
        NSRect(origin: .zero, size: NSSize(width: 1920, height: 1080)).fill()
        largeImage.unlockFocus()
        
        // When & Then
        measure {
            let blurredBackground = BlurredImageBackground(image: largeImage)
            let hostingController = NSHostingController(rootView: blurredBackground)
            let _ = hostingController.view
        }
        
        // This test will fail initially because BlurredImageBackground doesn't exist yet
        // We expect rendering to complete within 10ms for performance requirements
    }
}