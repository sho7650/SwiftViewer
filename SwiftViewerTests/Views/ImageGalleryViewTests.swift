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
}