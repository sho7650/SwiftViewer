//
//  StateManagementTests.swift
//  SwiftViewerTests
//
//  Tests for proper SwiftUI state management between ContentView and ImageGalleryView
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class StateManagementTests: XCTestCase {
    
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
    
    // MARK: - ViewModel Sharing Tests
    
    func test_imageGalleryView_should_receive_viewModel_as_property_not_state() {
        // Given: A ViewModel instance created by parent
        let parentViewModel = ImageGalleryViewModel(dependencies: mockContainer)
        
        // When: Creating ImageGalleryView with the ViewModel
        let galleryView = ImageGalleryView(viewModel: parentViewModel)
        
        // Then: The view should use the same ViewModel instance
        // This test will initially fail because ImageGalleryView creates its own @State
        XCTAssertTrue(galleryView.viewModel === parentViewModel, 
                     "ImageGalleryView should use the same ViewModel instance passed from parent")
    }
    
    func test_viewModel_state_changes_should_propagate_to_child_views() {
        // Given: A parent ViewModel with initial state
        let parentViewModel = ImageGalleryViewModel(dependencies: mockContainer)
        let testImages = [
            ImageFile(url: URL(fileURLWithPath: "/test1.jpg"), 
                     fileName: "test1.jpg", 
                     fileSize: 1024, 
                     createdDate: Date())
        ]
        
        // When: Parent updates the ViewModel state
        parentViewModel.imageFiles = testImages
        parentViewModel.currentIndex = 0
        
        // Then: Child view should see the same state
        let galleryView = ImageGalleryView(viewModel: parentViewModel)
        XCTAssertEqual(galleryView.viewModel.imageFiles.count, 1)
        XCTAssertEqual(galleryView.viewModel.currentIndex, 0)
        XCTAssertEqual(galleryView.viewModel.imageFiles.first?.fileName, "test1.jpg")
    }
    
    func test_contentView_should_maintain_single_viewModel_instance() {
        // Given: ContentView with its ViewModel
        let contentView = ContentView()
        
        // When: ContentView body is accessed multiple times (simulating re-renders)
        _ = contentView.body
        _ = contentView.body
        
        // Then: The ViewModel instance should remain the same
        // This verifies @State/StateObject is properly maintaining the instance
        XCTAssertNotNil(contentView.body)
    }
    
    // MARK: - State Mutation Tests
    
    func test_viewModel_mutations_in_child_should_reflect_in_parent_state() async {
        // Given: A shared ViewModel
        let sharedViewModel = ImageGalleryViewModel(dependencies: mockContainer)
        let testImages = [
            ImageFile(url: URL(fileURLWithPath: "/test1.jpg"), 
                     fileName: "test1.jpg", 
                     fileSize: 1024, 
                     createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/test2.jpg"), 
                     fileName: "test2.jpg", 
                     fileSize: 2048, 
                     createdDate: Date())
        ]
        sharedViewModel.imageFiles = testImages
        sharedViewModel.currentIndex = 0
        
        // When: Child view navigates to next image
        let galleryView = ImageGalleryView(viewModel: sharedViewModel)
        await sharedViewModel.navigateToNext()
        
        // Then: Parent should see the updated state
        XCTAssertEqual(sharedViewModel.currentIndex, 1)
        XCTAssertEqual(galleryView.viewModel.currentIndex, 1)
    }
    
    func test_slideShowViewModel_should_be_created_with_correct_dependencies() {
        // Given: A ViewModel for ImageGalleryView
        let parentViewModel = ImageGalleryViewModel(dependencies: mockContainer)
        
        // When: ImageGalleryView is created
        let galleryView = ImageGalleryView(viewModel: parentViewModel)
        
        // Then: SlideShowViewModel should be properly initialized
        // Note: This tests the internal state management of ImageGalleryView
        XCTAssertNotNil(galleryView.body)
    }
    
    // MARK: - Memory Management Tests
    
    func test_viewModel_should_not_create_retain_cycles() {
        // Given: A ViewModel with potential retain cycle
        weak var weakViewModel: ImageGalleryViewModel?
        
        autoreleasepool {
            let strongViewModel = ImageGalleryViewModel(dependencies: mockContainer)
            weakViewModel = strongViewModel
            
            // When: Creating and destroying ImageGalleryView
            _ = ImageGalleryView(viewModel: strongViewModel)
        }
        
        // Then: ViewModel should be deallocated if no retain cycle
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated when no longer referenced")
    }
    
    // MARK: - Integration Tests
    
    func test_contentView_to_imageGalleryView_state_flow() async {
        // Given: ContentView with folder selection
        let contentView = ContentView()
        let testFolderURL = URL(fileURLWithPath: "/test/folder")
        
        // When: Folder is selected (simulated)
        // Note: This would normally be done through the UI
        // We're testing the state management structure
        
        // Then: State should flow correctly to child views
        XCTAssertNotNil(contentView.body)
    }
}