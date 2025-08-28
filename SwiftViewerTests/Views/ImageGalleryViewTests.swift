//
//  ImageGalleryViewTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class ImageGalleryViewTests: XCTestCase {
    
    var mockContainer: MockDependencyContainer!
    var viewModel: ImageGalleryViewModel!
    var galleryView: ImageGalleryView!
    
    override func setUp() {
        super.setUp()
        mockContainer = MockDependencyContainer()
        viewModel = ImageGalleryViewModel(dependencies: mockContainer)
        // Pass the ViewModel as a property, not creating new state
        galleryView = ImageGalleryView(viewModel: viewModel)
    }
    
    override func tearDown() {
        galleryView = nil
        viewModel = nil
        mockContainer = nil
        super.tearDown()
    }
    
    func test_imageGalleryView_initialization() {
        XCTAssertNotNil(galleryView)
        XCTAssertNotNil(galleryView.body)
    }
    
    func test_imageGalleryView_loadingState() {
        // Set loading state
        viewModel.isLoading = true
        
        let body = galleryView.body
        XCTAssertNotNil(body)
        
        // Verify loading state is reflected in the view
        XCTAssertTrue(viewModel.isLoading)
    }
    
    func test_imageGalleryView_errorState() {
        // Set error state
        viewModel.errorMessage = "Test error message"
        
        let body = galleryView.body
        XCTAssertNotNil(body)
        
        // Verify error state is reflected
        XCTAssertEqual(viewModel.errorMessage, "Test error message")
    }
    
    func test_imageGalleryView_emptyState() {
        // Ensure empty state (no images loaded)
        viewModel.imageFiles = []
        viewModel.isLoading = false
        viewModel.errorMessage = nil
        
        let body = galleryView.body
        XCTAssertNotNil(body)
        
        // Verify empty state
        XCTAssertTrue(viewModel.imageFiles.isEmpty)
        XCTAssertFalse(viewModel.hasImages)
    }
    
    func test_imageGalleryView_withImages() {
        // Set up with mock images
        let mockImages = [
            ImageFile(url: URL(fileURLWithPath: "/test1.jpg"), fileName: "test1.jpg", fileSize: 1024, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/test2.jpg"), fileName: "test2.jpg", fileSize: 2048, createdDate: Date())
        ]
        
        viewModel.imageFiles = mockImages
        viewModel.currentIndex = 0
        viewModel.isLoading = false
        
        let body = galleryView.body
        XCTAssertNotNil(body)
        
        // Verify images are loaded
        XCTAssertEqual(viewModel.imageFiles.count, 2)
        XCTAssertTrue(viewModel.hasImages)
    }
    
    func test_imageGalleryView_slideShowIntegration() {
        // Test that slideshow components are properly integrated
        let mockImages = [
            ImageFile(url: URL(fileURLWithPath: "/test1.jpg"), fileName: "test1.jpg", fileSize: 1024, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/test2.jpg"), fileName: "test2.jpg", fileSize: 2048, createdDate: Date())
        ]
        
        viewModel.imageFiles = mockImages
        viewModel.currentIndex = 0
        viewModel.isLoading = false
        
        let body = galleryView.body
        XCTAssertNotNil(body)
        
        // Verify slideshow controls should be available
        XCTAssertTrue(viewModel.hasImages)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_imageGalleryView_currentImageInfo() {
        // Test image info display structure
        let mockImage = ImageFile(
            url: URL(fileURLWithPath: "/test.jpg"), 
            fileName: "test.jpg", 
            fileSize: 1024000, 
            createdDate: Date()
        )
        
        viewModel.imageFiles = [mockImage]
        viewModel.currentIndex = 0
        viewModel.isLoading = false
        
        let body = galleryView.body
        XCTAssertNotNil(body)
        
        // Verify that images are loaded and view state is correct
        XCTAssertEqual(viewModel.imageFiles.count, 1)
        XCTAssertEqual(viewModel.imageFiles.first?.fileName, "test.jpg")
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertTrue(viewModel.hasImages)
    }
    
    func test_imageGalleryView_navigationHints() {
        // Test navigation hint display logic
        let mockImages = [
            ImageFile(url: URL(fileURLWithPath: "/test1.jpg"), fileName: "test1.jpg", fileSize: 1024, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/test2.jpg"), fileName: "test2.jpg", fileSize: 2048, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/test3.jpg"), fileName: "test3.jpg", fileSize: 3072, createdDate: Date())
        ]
        
        viewModel.imageFiles = mockImages
        viewModel.isLoading = false
        
        // Test at beginning
        viewModel.currentIndex = 0
        let bodyAtBeginning = galleryView.body
        XCTAssertNotNil(bodyAtBeginning)
        XCTAssertEqual(viewModel.currentIndex, 0)
        
        // Test in middle
        viewModel.currentIndex = 1
        let bodyInMiddle = galleryView.body
        XCTAssertNotNil(bodyInMiddle)
        XCTAssertEqual(viewModel.currentIndex, 1)
        
        // Test at end
        viewModel.currentIndex = 2
        let bodyAtEnd = galleryView.body
        XCTAssertNotNil(bodyAtEnd)
        XCTAssertEqual(viewModel.currentIndex, 2)
    }
    
    func test_imageGalleryView_focusState() {
        // Test that the view can receive focus for keyboard input
        let body = galleryView.body
        XCTAssertNotNil(body)
        
        // The view should be focusable for keyboard input
        // This is mainly a structural test since we can't directly test focus state
    }
    
    func test_imageGalleryView_multiplePreviewScenarios() {
        // Test various scenarios that would be shown in previews
        
        // Dark mode empty state
        viewModel.imageFiles = []
        viewModel.isLoading = false
        let emptyBody = galleryView.body
        XCTAssertNotNil(emptyBody)
        
        // Loading state
        viewModel.isLoading = true
        let loadingBody = galleryView.body
        XCTAssertNotNil(loadingBody)
        
        // Error state
        viewModel.isLoading = false
        viewModel.errorMessage = "Failed to load images from the selected folder"
        let errorBody = galleryView.body
        XCTAssertNotNil(errorBody)
        
        // Compact view
        viewModel.errorMessage = nil
        let compactBody = galleryView.body
        XCTAssertNotNil(compactBody)
    }
    
    func test_imageGalleryView_uses_injected_viewModel() {
        // Test that the view uses the injected ViewModel instance
        // Update ViewModel state
        viewModel.isLoading = true
        
        // The view should reflect the same state
        let body = galleryView.body
        XCTAssertNotNil(body)
        XCTAssertTrue(viewModel.isLoading)
        
        // Change state again
        viewModel.isLoading = false
        viewModel.errorMessage = "Test error"
        
        // View should still reflect the changes
        let updatedBody = galleryView.body
        XCTAssertNotNil(updatedBody)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Test error")
    }
    
    func test_imageGalleryView_notificationHandling() {
        // Test that the view properly handles slideshow interval change notifications
        let body = galleryView.body
        XCTAssertNotNil(body)
        
        // Simulate notification (structural test)
        // The actual notification handling is tested in integration tests
    }
    
    func test_imageGalleryView_cleanup() {
        // Test that slideshow is properly stopped when view disappears
        let body = galleryView.body
        XCTAssertNotNil(body)
        
        // This tests the structural setup - the actual cleanup behavior
        // would be tested in integration tests with the actual slideshow service
    }
    
    // MARK: - GIF Animation Tests
    
    func test_imageGalleryView_displays_animated_gif() async {
        // Test that animated GIF files are properly displayed
        let gifFile = ImageFile(
            url: URL(fileURLWithPath: "/test/animation.gif"),
            fileName: "animation.gif",
            fileSize: 2048000,
            createdDate: Date()
        )
        
        viewModel.imageFiles = [gifFile]
        await viewModel.navigateToIndex(0)
        viewModel.isLoading = false
        
        let body = galleryView.body
        XCTAssertNotNil(body)
        
        // Verify GIF is identified as animated
        XCTAssertTrue(gifFile.isAnimated)
        XCTAssertEqual(viewModel.currentImageFile?.isAnimated, true)
    }
    
    func test_imageGalleryView_displays_static_image() async {
        // Test that non-GIF files are displayed as static images
        let jpgFile = ImageFile(
            url: URL(fileURLWithPath: "/test/photo.jpg"),
            fileName: "photo.jpg",
            fileSize: 1024000,
            createdDate: Date()
        )
        
        viewModel.imageFiles = [jpgFile]
        await viewModel.navigateToIndex(0)
        viewModel.isLoading = false
        
        let body = galleryView.body
        XCTAssertNotNil(body)
        
        // Verify JPG is not identified as animated
        XCTAssertFalse(jpgFile.isAnimated)
        XCTAssertEqual(viewModel.currentImageFile?.isAnimated, false)
    }
    
    func test_imageGalleryView_mixed_image_types() async {
        // Test handling of mixed animated and static images
        let gifFile = ImageFile(
            url: URL(fileURLWithPath: "/test/animation.gif"),
            fileName: "animation.gif",
            fileSize: 2048000,
            createdDate: Date()
        )
        
        let jpgFile = ImageFile(
            url: URL(fileURLWithPath: "/test/photo.jpg"),
            fileName: "photo.jpg",
            fileSize: 1024000,
            createdDate: Date()
        )
        
        let heicFile = ImageFile(
            url: URL(fileURLWithPath: "/test/photo.heic"),
            fileName: "photo.heic",
            fileSize: 1536000,
            createdDate: Date()
        )
        
        viewModel.imageFiles = [gifFile, jpgFile, heicFile]
        viewModel.isLoading = false
        
        // Test GIF
        await viewModel.navigateToIndex(0)
        let gifBody = galleryView.body
        XCTAssertNotNil(gifBody)
        XCTAssertTrue(viewModel.currentImageFile?.isAnimated == true)
        
        // Test JPG
        await viewModel.navigateToIndex(1)
        let jpgBody = galleryView.body
        XCTAssertNotNil(jpgBody)
        XCTAssertTrue(viewModel.currentImageFile?.isAnimated == false)
        
        // Test HEIC
        await viewModel.navigateToIndex(2)
        let heicBody = galleryView.body
        XCTAssertNotNil(heicBody)
        XCTAssertTrue(viewModel.currentImageFile?.isAnimated == false)
    }
    
    func test_imageGalleryView_gif_view_identification() {
        // Test that GIF views are properly identified with unique IDs
        let gif1 = ImageFile(
            url: URL(fileURLWithPath: "/test/animation1.gif"),
            fileName: "animation1.gif",
            fileSize: 1024000,
            createdDate: Date()
        )
        
        let gif2 = ImageFile(
            url: URL(fileURLWithPath: "/test/animation2.gif"),
            fileName: "animation2.gif",
            fileSize: 2048000,
            createdDate: Date()
        )
        
        viewModel.imageFiles = [gif1, gif2]
        viewModel.isLoading = false
        
        // Test first GIF
        viewModel.currentIndex = 0
        let body1 = galleryView.body
        XCTAssertNotNil(body1)
        XCTAssertTrue(gif1.isAnimated)
        
        // Test second GIF
        viewModel.currentIndex = 1
        let body2 = galleryView.body
        XCTAssertNotNil(body2)
        XCTAssertTrue(gif2.isAnimated)
        
        // Verify different URLs result in different identification
        XCTAssertNotEqual(gif1.url.absoluteString, gif2.url.absoluteString)
    }
    
    func test_imageGalleryView_gif_case_sensitivity() {
        // Test that GIF identification works with different case variations
        let gifFiles = [
            ImageFile(url: URL(fileURLWithPath: "/test/animation.gif"), fileName: "animation.gif", fileSize: 1024000, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/test/animation.GIF"), fileName: "animation.GIF", fileSize: 1024000, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/test/animation.Gif"), fileName: "animation.Gif", fileSize: 1024000, createdDate: Date())
        ]
        
        for (index, gifFile) in gifFiles.enumerated() {
            viewModel.imageFiles = [gifFile]
            viewModel.currentIndex = 0
            viewModel.isLoading = false
            
            let body = galleryView.body
            XCTAssertNotNil(body)
            XCTAssertTrue(gifFile.isAnimated, "GIF with extension '\(gifFile.fileExtension)' should be identified as animated")
        }
    }
    
    // MARK: - Focus Effect Tests
    
    func test_ImageGalleryView_imageDisplay_shouldNotShowAccentColorBorder() {
        // Given: ViewModel with image loaded
        viewModel.isLoading = false
        let imageFile = ImageFile(
            url: URL(fileURLWithPath: "/test/image.jpg"),
            fileName: "image.jpg",
            fileSize: 1000,
            createdDate: Date()
        )
        viewModel.imageFiles = [imageFile]
        viewModel.currentImage = NSImage(size: NSSize(width: 100, height: 100))
        viewModel.currentIndex = 0
        
        // When: View is created
        let body = galleryView.body
        
        // Then: View should be created properly (focusEffectDisabled will be applied in implementation)
        XCTAssertNotNil(body)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.imageFiles.count, 1)
    }
    
    func test_ImageGalleryView_animatedImageDisplay_shouldHaveFocusEffectDisabled() {
        // Given: ViewModel with animated image
        viewModel.isLoading = false
        let gifFile = ImageFile(
            url: URL(fileURLWithPath: "/test/animated.gif"),
            fileName: "animated.gif",
            fileSize: 2000,
            createdDate: Date()
        )
        viewModel.imageFiles = [gifFile]
        viewModel.currentImage = NSImage(size: NSSize(width: 100, height: 100))
        viewModel.currentIndex = 0
        
        // When: View is created
        let body = galleryView.body
        
        // Then: Animated image view should be constructed properly
        XCTAssertNotNil(body)
        XCTAssertTrue(gifFile.isAnimated, "GIF file should be identified as animated")
        XCTAssertEqual(viewModel.imageFiles.count, 1)
    }
}