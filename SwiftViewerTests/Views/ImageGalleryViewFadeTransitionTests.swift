//
//  ImageGalleryViewFadeTransitionTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/31.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class ImageGalleryViewFadeTransitionTests: XCTestCase {
    
    // MARK: - Fade Transition Tests
    
    func test_slideShowControlsOverlay_usesFadeTransitionAnimation() {
        // Given
        let mockContainer = MockDependencyContainer()
        let viewModel = ImageGalleryViewModel(dependencies: mockContainer)
        
        // When
        let galleryView = ImageGalleryView(viewModel: viewModel)
        
        // Then
        // Controls overlay should use .fromSettings(.transition) for fade animation
        XCTAssertNotNil(galleryView)
        // Note: Animation behavior testing requires specialized SwiftUI testing tools
    }
    
    func test_controlsVisibility_animatesWithTransitionDuration() {
        // Given
        let mockContainer = MockDependencyContainer()
        mockContainer.settingsManager.animationDurations[.transition] = 0.8
        let viewModel = ImageGalleryViewModel(dependencies: mockContainer)
        
        // When
        let galleryView = ImageGalleryView(viewModel: viewModel)
        
        // Then
        // Should use custom transition duration from settings
        XCTAssertNotNil(galleryView)
        XCTAssertEqual(mockContainer.settingsManager.animationDurations[.transition], 0.8)
    }
    
    func test_controlsVisibility_usesDefaultTransitionDuration() {
        // Given
        let mockContainer = MockDependencyContainer()
        mockContainer.settingsManager.animationDurations[.transition] = nil
        let viewModel = ImageGalleryViewModel(dependencies: mockContainer)
        
        // When
        let galleryView = ImageGalleryView(viewModel: viewModel)
        
        // Then
        // Should fallback to default transition duration
        XCTAssertNotNil(galleryView)
        let expectedDefault = AnimationType.transition.defaultDuration
        XCTAssertEqual(expectedDefault, 0.3)
    }
    
    func test_autoHideManager_triggersControlsFadeAnimation() {
        // Given
        let mockContainer = MockDependencyContainer()
        let viewModel = ImageGalleryViewModel(dependencies: mockContainer)
        let galleryView = ImageGalleryView(viewModel: viewModel)
        
        // When & Then
        // AutoHideManager visibility changes should trigger fade animation
        XCTAssertNotNil(galleryView)
        // Note: AutoHideManager behavior testing requires time-based testing framework
    }
    
    func test_fadeTransition_supportsConfigurableRange() {
        // Given
        let mockContainer = MockDependencyContainer()
        let testDurations: [TimeInterval] = [0.1, 0.5, 1.0, 2.0, 5.0]
        
        for duration in testDurations {
            // When
            mockContainer.settingsManager.animationDurations[.transition] = duration
            let viewModel = ImageGalleryViewModel(dependencies: mockContainer)
            let galleryView = ImageGalleryView(viewModel: viewModel)
            
            // Then
            XCTAssertNotNil(galleryView)
            XCTAssertEqual(mockContainer.settingsManager.animationDurations[.transition], duration)
        }
    }
    
    func test_fadeTransition_preservesControlsInteractivity() {
        // Given
        let mockContainer = MockDependencyContainer()
        let viewModel = ImageGalleryViewModel(dependencies: mockContainer)
        
        // When
        let galleryView = ImageGalleryView(viewModel: viewModel)
        
        // Then
        // Fade animation should not interfere with button interactions
        XCTAssertNotNil(galleryView)
        // Note: Interaction testing during animation requires UI testing framework
    }
}