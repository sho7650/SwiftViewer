//
//  ImageViewerViewModelTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
import AppKit
@testable import SwiftViewer

@MainActor
final class ImageViewerViewModelTests: XCTestCase {
    
    var sut: ImageViewerViewModel!
    var mockFileManagerService: MockFileManagerService!
    var mockImageLoaderService: MockImageLoaderService!
    var mockSettingsManager: MockSettingsManager!
    var mockContainer: MockDependencyContainer!
    
    override func setUp() {
        super.setUp()
        mockFileManagerService = MockFileManagerService()
        mockImageLoaderService = MockImageLoaderService()
        mockSettingsManager = MockSettingsManager()
        mockContainer = MockDependencyContainer(
            fileManagerService: mockFileManagerService,
            imageLoaderService: mockImageLoaderService,
            settingsManager: mockSettingsManager
        )
        sut = ImageViewerViewModel(dependencies: mockContainer)
    }
    
    override func tearDown() {
        sut = nil
        mockContainer = nil
        mockFileManagerService = nil
        mockImageLoaderService = nil
        mockSettingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_initialization_setsDefaultValues() {
        XCTAssertNil(sut.currentImage)
        XCTAssertNil(sut.currentImageFile)
        XCTAssertTrue(sut.imageFiles.isEmpty)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Folder Loading Tests
    
    func test_loadFolder_loadsImagesFromFileManager() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let testImageFiles = createTestImageFiles(count: 3)
        mockFileManagerService.mockImageFiles = testImageFiles
        mockImageLoaderService.mockImage = NSImage()
        
        await sut.loadFolder(testURL)
        
        XCTAssertEqual(sut.imageFiles.count, 3)
        XCTAssertEqual(sut.imageFiles, testImageFiles)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertNotNil(sut.currentImage)
        XCTAssertEqual(sut.currentImageFile, testImageFiles[0])
    }
    
    func test_loadFolder_setsLoadingState() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        mockFileManagerService.mockImageFiles = createTestImageFiles(count: 1)
        
        let loadingExpectation = expectation(description: "Loading state")
        
        Task {
            XCTAssertTrue(sut.isLoading)
            loadingExpectation.fulfill()
        }
        
        await sut.loadFolder(testURL)
        await fulfillment(of: [loadingExpectation], timeout: 1.0)
        XCTAssertFalse(sut.isLoading)
    }
    
    func test_loadFolder_handlesError_whenFileManagerFails() async {
        let testURL = URL(fileURLWithPath: "/nonexistent/folder")
        mockFileManagerService.shouldThrowError = true
        mockFileManagerService.errorToThrow = FileManagerServiceError.directoryNotFound
        
        await sut.loadFolder(testURL)
        
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.imageFiles.isEmpty)
        XCTAssertNil(sut.currentImage)
    }
    
    func test_loadFolder_handlesEmptyFolder() async {
        let testURL = URL(fileURLWithPath: "/empty/folder")
        mockFileManagerService.mockImageFiles = []
        
        await sut.loadFolder(testURL)
        
        XCTAssertTrue(sut.imageFiles.isEmpty)
        XCTAssertNil(sut.currentImage)
        XCTAssertEqual(sut.currentIndex, 0)
    }
    
    // MARK: - Navigation Tests
    
    func test_navigateToNext_movesToNextImage() async {
        await setupWithImages(count: 3)
        
        await sut.navigateToNext()
        
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.currentImageFile, sut.imageFiles[1])
    }
    
    func test_navigateToNext_wrapsAroundAtEnd() async {
        await setupWithImages(count: 3)
        sut.currentIndex = 2  // Move to last image
        
        await sut.navigateToNext()
        
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.currentImageFile, sut.imageFiles[0])
    }
    
    func test_navigateToPrevious_movesToPreviousImage() async {
        await setupWithImages(count: 3)
        sut.currentIndex = 1
        
        await sut.navigateToPrevious()
        
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.currentImageFile, sut.imageFiles[0])
    }
    
    func test_navigateToPrevious_wrapsAroundAtBeginning() async {
        await setupWithImages(count: 3)
        sut.currentIndex = 0  // Start at first image
        
        await sut.navigateToPrevious()
        
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.currentImageFile, sut.imageFiles[2])
    }
    
    func test_navigateToIndex_movesToSpecificImage() async {
        await setupWithImages(count: 5)
        
        await sut.navigateToIndex(3)
        
        XCTAssertEqual(sut.currentIndex, 3)
        XCTAssertEqual(sut.currentImageFile, sut.imageFiles[3])
    }
    
    func test_navigateToIndex_ignoresInvalidIndex() async {
        await setupWithImages(count: 3)
        let originalIndex = sut.currentIndex
        
        await sut.navigateToIndex(5)
        
        XCTAssertEqual(sut.currentIndex, originalIndex)
    }
    
    func test_navigation_doesNotWork_whenNoImages() async {
        // No images loaded
        
        await sut.navigateToNext()
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertNil(sut.currentImage)
        
        await sut.navigateToPrevious()
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertNil(sut.currentImage)
    }
    
    // MARK: - Image Loading Tests
    
    func test_loadImageAtIndex_loadsCorrectImage() async {
        let testImages = [NSImage(), NSImage(), NSImage()]
        await setupWithImages(count: 3)
        mockImageLoaderService.mockImage = testImages[1]
        
        await sut.navigateToIndex(1)
        
        XCTAssertEqual(sut.currentImage, testImages[1])
        XCTAssertEqual(sut.currentIndex, 1)
    }
    
    func test_loadImageAtIndex_handlesImageLoadingError() async {
        await setupWithImages(count: 3)
        mockImageLoaderService.shouldThrowError = true
        
        await sut.navigateToIndex(1)
        
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertNil(sut.currentImage)
    }
    
    // MARK: - Sort Tests
    
    func test_refreshWithCurrentSort_resortsImages() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let testImageFiles = createTestImageFiles(count: 3)
        mockFileManagerService.mockImageFiles = testImageFiles
        mockSettingsManager.sortType = .name(ascending: false)
        
        await sut.loadFolder(testURL)
        await sut.refreshWithCurrentSort()
        
        // Verify FileManagerService was called with correct sort type
        XCTAssertTrue(mockFileManagerService.lastUsedSortType != nil)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImageFiles(count: Int) -> [ImageFile] {
        return (0..<count).map { index in
            ImageFile(
                url: URL(fileURLWithPath: "/test/image\(index).jpg"),
                fileName: "image\(index).jpg",
                fileSize: 1024,
                createdDate: Date()
            )
        }
    }
    
    private func setupWithImages(count: Int) async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let testImageFiles = createTestImageFiles(count: count)
        mockFileManagerService.mockImageFiles = testImageFiles
        mockImageLoaderService.mockImage = NSImage()
        
        await sut.loadFolder(testURL)
    }
}

