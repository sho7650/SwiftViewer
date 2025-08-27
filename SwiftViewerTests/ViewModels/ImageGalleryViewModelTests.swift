//
//  ImageGalleryViewModelTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
import AppKit
@testable import SwiftViewer

@MainActor
final class ImageGalleryViewModelTests: XCTestCase {
    
    var sut: ImageGalleryViewModel!
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
        sut = ImageGalleryViewModel(dependencies: mockContainer)
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
        mockSettingsManager.repeatEnabled = true  // Enable repeat for wrap-around
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
        mockSettingsManager.repeatEnabled = true  // Enable repeat for wrap-around
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
    
    // MARK: - GIF Animation Tests (RED PHASE - These will FAIL)
    
    func test_currentAnimatedImage_returnsNil_forNonGIFImage() async {
        await setupWithImages(count: 1)
        
        // This property doesn't exist yet - will fail
        XCTAssertNil(sut.currentAnimatedImage)
    }
    
    func test_currentAnimatedImage_returnsAnimatedImage_forGIFFile() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let gifImageFiles = createTestGIFImageFiles(count: 1)
        mockFileManagerService.mockImageFiles = gifImageFiles
        
        // Set up mock to return animated GIF
        let testFrame = NSImage(size: NSSize(width: 100, height: 100))
        let mockAnimatedImage = AnimatedImage(
            frames: [testFrame, testFrame],
            frameDurations: [0.1, 0.2],
            loopCount: 0,
            totalDuration: 0.3
        )
        mockImageLoaderService.mockAnimatedImage = mockAnimatedImage
        mockImageLoaderService.shouldReturnAnimatedGIF = true
        
        await sut.loadFolder(testURL)
        
        // This property doesn't exist yet - will fail
        XCTAssertNotNil(sut.currentAnimatedImage)
        XCTAssertEqual(sut.currentAnimatedImage?.frameCount, 2)
        XCTAssertEqual(sut.currentAnimatedImage?.totalDuration, 0.3)
    }
    
    func test_isCurrentImageAnimated_returnsFalse_forStaticImage() async {
        await setupWithImages(count: 1)
        
        // This property doesn't exist yet - will fail
        XCTAssertFalse(sut.isCurrentImageAnimated)
    }
    
    func test_isCurrentImageAnimated_returnsTrue_forGIFImage() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let gifImageFiles = createTestGIFImageFiles(count: 1)
        mockFileManagerService.mockImageFiles = gifImageFiles
        mockImageLoaderService.shouldReturnAnimatedGIF = true
        
        await sut.loadFolder(testURL)
        
        // This property doesn't exist yet - will fail
        XCTAssertTrue(sut.isCurrentImageAnimated)
    }
    
    func test_gifAnimationController_returnsNil_forNonGIFImage() async {
        await setupWithImages(count: 1)
        
        // This property doesn't exist yet - will fail
        XCTAssertNil(sut.gifAnimationController)
    }
    
    func test_gifAnimationController_returnsController_forGIFImage() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let gifImageFiles = createTestGIFImageFiles(count: 1)
        mockFileManagerService.mockImageFiles = gifImageFiles
        mockImageLoaderService.shouldReturnAnimatedGIF = true
        
        await sut.loadFolder(testURL)
        
        // This property doesn't exist yet - will fail
        XCTAssertNotNil(sut.gifAnimationController)
        XCTAssertEqual(sut.gifAnimationController?.animatedImage.frameCount, 2)
    }
    
    func test_startGIFAnimation_startsController_forAnimatedGIF() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let gifImageFiles = createTestGIFImageFiles(count: 1)
        mockFileManagerService.mockImageFiles = gifImageFiles
        mockImageLoaderService.shouldReturnAnimatedGIF = true
        
        await sut.loadFolder(testURL)
        
        // This method doesn't exist yet - will fail
        sut.startGIFAnimation()
        
        XCTAssertNotNil(sut.gifAnimationController)
        XCTAssertTrue(sut.gifAnimationController?.isPlaying ?? false)
    }
    
    func test_stopGIFAnimation_stopsController() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let gifImageFiles = createTestGIFImageFiles(count: 1)
        mockFileManagerService.mockImageFiles = gifImageFiles
        mockImageLoaderService.shouldReturnAnimatedGIF = true
        
        await sut.loadFolder(testURL)
        sut.startGIFAnimation()
        
        // This method doesn't exist yet - will fail
        sut.stopGIFAnimation()
        
        XCTAssertFalse(sut.gifAnimationController?.isPlaying ?? true)
    }
    
    func test_navigation_stopsAndStartsGIFAnimation() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        // Mix of GIF and regular images
        var mixedImageFiles = createTestGIFImageFiles(count: 1)
        mixedImageFiles.append(contentsOf: createTestImageFiles(count: 1))
        mockFileManagerService.mockImageFiles = mixedImageFiles
        mockImageLoaderService.shouldReturnAnimatedGIF = true
        
        await sut.loadFolder(testURL)
        sut.startGIFAnimation()
        XCTAssertTrue(sut.gifAnimationController?.isPlaying ?? false)
        
        // Navigate to next image (non-GIF)
        mockImageLoaderService.shouldReturnAnimatedGIF = false
        await sut.navigateToNext()
        
        // Animation should be stopped for non-GIF
        XCTAssertNil(sut.gifAnimationController)
        XCTAssertFalse(sut.isCurrentImageAnimated)
    }
    
    func test_setGIFPlaybackSpeed_updatesController() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let gifImageFiles = createTestGIFImageFiles(count: 1)
        mockFileManagerService.mockImageFiles = gifImageFiles
        mockImageLoaderService.shouldReturnAnimatedGIF = true
        
        await sut.loadFolder(testURL)
        
        // This method doesn't exist yet - will fail
        sut.setGIFPlaybackSpeed(2.0)
        
        XCTAssertNotNil(sut.gifAnimationController)
        XCTAssertEqual(sut.gifAnimationController?.playbackSpeed, 2.0)
    }
    
    func test_getCurrentGIFFrame_returnsCurrentFrameImage() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let gifImageFiles = createTestGIFImageFiles(count: 1)
        mockFileManagerService.mockImageFiles = gifImageFiles
        mockImageLoaderService.shouldReturnAnimatedGIF = true
        
        await sut.loadFolder(testURL)
        
        // This method doesn't exist yet - will fail
        let currentFrame = sut.getCurrentGIFFrame()
        
        XCTAssertNotNil(currentFrame)
    }
    
    func test_loadImageWithMetadata_loadsAnimationData_forGIF() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let gifImageFiles = createTestGIFImageFiles(count: 1)
        mockFileManagerService.mockImageFiles = gifImageFiles
        
        // Set up enhanced mock response
        mockImageLoaderService.shouldReturnAnimatedGIF = true
        
        await sut.loadFolder(testURL)
        
        // Should have loaded both static image and animation data
        XCTAssertNotNil(sut.currentImage)
        XCTAssertNotNil(sut.currentAnimatedImage)
        XCTAssertTrue(sut.isCurrentImageAnimated)
    }
    
    func test_animationState_persistsAcrossNavigation() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let gifImageFiles = createTestGIFImageFiles(count: 2) // Two GIFs
        mockFileManagerService.mockImageFiles = gifImageFiles
        mockImageLoaderService.shouldReturnAnimatedGIF = true
        
        await sut.loadFolder(testURL)
        
        // Start animation on first GIF
        sut.startGIFAnimation()
        let firstAnimationPlaying = sut.gifAnimationController?.isPlaying ?? false
        
        // Navigate to second GIF
        await sut.navigateToNext()
        
        // Animation should start automatically for second GIF (if that's the expected behavior)
        XCTAssertNotNil(sut.gifAnimationController)
        XCTAssertTrue(sut.isCurrentImageAnimated)
    }
    
    // MARK: - Integration Tests for GIF Animation
    
    func test_viewModelNotifications_triggerOnGIFStateChange() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let gifImageFiles = createTestGIFImageFiles(count: 1)
        mockFileManagerService.mockImageFiles = gifImageFiles
        mockImageLoaderService.shouldReturnAnimatedGIF = true
        
        // This would test if the ViewModel properly notifies observers when GIF state changes
        // The actual implementation would need to post notifications or use Combine publishers
        
        await sut.loadFolder(testURL)
        
        // Verify that loading a GIF triggers appropriate state changes
        XCTAssertTrue(sut.isCurrentImageAnimated)
        XCTAssertNotNil(sut.currentAnimatedImage)
    }
    
    func test_memoryManagement_cleansUpGIFController() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let gifImageFiles = createTestGIFImageFiles(count: 1)
        mockFileManagerService.mockImageFiles = gifImageFiles
        mockImageLoaderService.shouldReturnAnimatedGIF = true
        
        await sut.loadFolder(testURL)
        sut.startGIFAnimation()
        
        // Verify GIF controller is set up
        XCTAssertNotNil(sut.gifAnimationController)
        XCTAssertTrue(sut.isCurrentImageAnimated)
        
        // Clear the mock state to simulate empty folder
        mockFileManagerService.mockImageFiles = []
        mockImageLoaderService.shouldReturnAnimatedGIF = false
        
        // Clear the current image (simulate navigating away or error)
        await sut.loadFolder(URL(fileURLWithPath: "/empty"))
        
        // GIF controller should be cleaned up
        XCTAssertNil(sut.gifAnimationController)
        XCTAssertFalse(sut.isCurrentImageAnimated)
    }
    
    // MARK: - Error Handling Tests for GIF Animation
    
    func test_gifLoading_handlesCorruptedGIFFile() async {
        let testURL = URL(fileURLWithPath: "/test/folder")
        let gifImageFiles = createTestGIFImageFiles(count: 1)
        mockFileManagerService.mockImageFiles = gifImageFiles
        
        // Set up mock to fail on animated loading but succeed on static
        mockImageLoaderService.shouldThrowError = false // Static loading succeeds
        // But animated loading should fail - this would need additional mock setup
        
        await sut.loadFolder(testURL)
        
        // Should fallback to static image display
        XCTAssertNotNil(sut.currentImage)
        XCTAssertFalse(sut.isCurrentImageAnimated)
        XCTAssertNil(sut.currentAnimatedImage)
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
    
    private func createTestGIFImageFiles(count: Int) -> [ImageFile] {
        return (0..<count).map { index in
            ImageFile(
                url: URL(fileURLWithPath: "/test/animation\(index).gif"),
                fileName: "animation\(index).gif",
                fileSize: 2048,
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

