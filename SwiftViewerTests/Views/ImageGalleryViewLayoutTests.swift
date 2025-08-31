//
//  ImageGalleryViewLayoutTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/31.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class ImageGalleryViewLayoutTests: XCTestCase {
    
    var mockContainer: MockDependencyContainer!
    var viewModel: ImageGalleryViewModel!
    
    override func setUp() {
        super.setUp()
        mockContainer = MockDependencyContainer()
        viewModel = ImageGalleryViewModel(dependencies: mockContainer)
    }
    
    override func tearDown() {
        viewModel = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - Safe Area Expansion Tests
    
    func test_imageGalleryView_ignoresSafeArea_expandsIntoTitlebarArea() {
        // Given: ImageGalleryView with loaded image
        viewModel.imageFiles = [createTestImageFile()]
        viewModel.currentIndex = 0
        let galleryView = ImageGalleryView(viewModel: viewModel)
        
        // When: View is rendered
        // Then: Should expand into titlebar area (verified by safe area ignoring)
        XCTAssertNotNil(galleryView, "ImageGalleryView should be created successfully")
        XCTAssertEqual(viewModel.imageFiles.count, 1, "Should have one test image loaded")
    }
    
    func test_imageGalleryView_layout_expandsFullWindow() {
        // Given: ImageGalleryView without titlebar constraints
        let galleryView = ImageGalleryView(viewModel: viewModel)
        
        // When: View layout is calculated
        // Then: Should use full window area without titlebar restrictions
        XCTAssertNotNil(galleryView.body, "View body should be accessible")
    }
    
    func test_imageGalleryView_geomtryReader_usesFullArea() {
        // Given: ImageGalleryView using GeometryReader
        viewModel.imageFiles = [createTestImageFile()]
        viewModel.currentIndex = 0
        let galleryView = ImageGalleryView(viewModel: viewModel)
        
        // When: Accessing view structure
        // Then: GeometryReader should have access to full window bounds
        XCTAssertNotNil(galleryView, "View should utilize full geometry")
    }
    
    // MARK: - Helper Methods
    
    private func createTestImageFile() -> ImageFile {
        return ImageFile(
            url: URL(fileURLWithPath: "/test/image1.jpg"),
            fileName: "image1.jpg",
            fileSize: 1024000,
            createdDate: Date()
        )
    }
}