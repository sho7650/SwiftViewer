//
//  ImageGalleryViewModel.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation
import AppKit
import Observation

@Observable
@MainActor
final class ImageGalleryViewModel {
    
    // MARK: - Observable Properties
    
    var currentImage: NSImage?
    var currentImageFile: ImageFile?
    var imageFiles: [ImageFile] = []
    var currentIndex: Int = 0
    var isLoading: Bool = false
    var errorMessage: String?
    
    // MARK: - GIF Animation Properties
    
    var currentAnimatedImage: AnimatedImage?
    var gifAnimationController: GIFAnimationController?
    
    // MARK: - Dependencies
    
    private let fileManagerService: FileManagerServiceProtocol
    private let imageLoaderService: ImageLoaderServiceProtocol
    private let settingsManager: SettingsManagerProtocol
    private let logger = Logger.shared
    
    // MARK: - Initialization
    
    init(dependencies: DependencyContainerProtocol) {
        self.fileManagerService = dependencies.fileManagerService
        self.imageLoaderService = dependencies.imageLoaderService
        self.settingsManager = dependencies.settingsManager
    }
    
    // MARK: - Public Methods
    
    func loadFolder(_ url: URL) async {
        logger.info("Loading folder: \(url.path)")
        clearError()
        isLoading = true
        
        do {
            let sortType = settingsManager.sortType
            let loadedFiles = try await fileManagerService.getImageFiles(from: url, sortBy: sortType)
            
            imageFiles = loadedFiles
            currentIndex = 0
            
            if !imageFiles.isEmpty {
                await loadImageAtCurrentIndex()
            } else {
                currentImage = nil
                currentImageFile = nil
                cleanupGIFAnimation()
                logger.warning("No image files found in folder: \(url.path)")
            }
            
        } catch {
            logger.error("Failed to load folder: \(url.path)", error: error)
            handleError(error)
        }
        
        isLoading = false
    }
    
    func navigateToNext() async {
        guard !imageFiles.isEmpty else { return }
        
        let isRepeatEnabled = settingsManager.repeatEnabled
        let isAtLastImage = currentIndex == imageFiles.count - 1
        
        if isAtLastImage && !isRepeatEnabled {
            // Don't navigate if we're at the last image and repeat is disabled
            return
        }
        
        let nextIndex = (currentIndex + 1) % imageFiles.count
        await navigateToIndex(nextIndex)
    }
    
    func navigateToPrevious() async {
        guard !imageFiles.isEmpty else { return }
        
        let isRepeatEnabled = settingsManager.repeatEnabled
        let isAtFirstImage = currentIndex == 0
        
        if isAtFirstImage && !isRepeatEnabled {
            // Don't navigate if we're at the first image and repeat is disabled
            return
        }
        
        let previousIndex = currentIndex == 0 ? imageFiles.count - 1 : currentIndex - 1
        await navigateToIndex(previousIndex)
    }
    
    func navigateToIndex(_ index: Int) async {
        guard !imageFiles.isEmpty,
              index >= 0,
              index < imageFiles.count else {
            logger.warning("Invalid navigation index: \(index), available images: \(imageFiles.count)")
            return
        }
        
        // Stop current GIF animation before navigating
        stopGIFAnimation()
        
        currentIndex = index
        await loadImageAtCurrentIndex()
        
        // Auto-start GIF animation if current image is animated
        if isCurrentImageAnimated {
            startGIFAnimation()
        }
    }
    
    func refreshWithCurrentSort() async {
        guard !imageFiles.isEmpty else { return }
        
        logger.info("Refreshing with current sort type")
        
        // Store current image file to maintain position if possible
        let currentImageFile = self.currentImageFile
        
        do {
            let sortType = settingsManager.sortType
            let currentFolderURL = imageFiles.first?.url.deletingLastPathComponent()
            
            guard let folderURL = currentFolderURL else { return }
            
            let sortedFiles = try await fileManagerService.getImageFiles(from: folderURL, sortBy: sortType)
            imageFiles = sortedFiles
            
            // Try to find the current image in the new sorted list
            if let currentFile = currentImageFile,
               let newIndex = imageFiles.firstIndex(where: { $0.url == currentFile.url }) {
                currentIndex = newIndex
            } else {
                currentIndex = 0
            }
            
            await loadImageAtCurrentIndex()
            
        } catch {
            logger.error("Failed to refresh with current sort", error: error)
            handleError(error)
        }
    }
    
    // MARK: - GIF Animation Methods
    
    func startGIFAnimation() {
        guard let controller = gifAnimationController else {
            logger.debug("No GIF animation controller available")
            return
        }
        
        controller.play()
        logger.debug("Started GIF animation")
    }
    
    func stopGIFAnimation() {
        gifAnimationController?.stop()
        logger.debug("Stopped GIF animation")
    }
    
    func setGIFPlaybackSpeed(_ speed: Double) {
        gifAnimationController?.setPlaybackSpeed(speed)
        logger.debug("Set GIF playback speed to: \(speed)")
    }
    
    func getCurrentGIFFrame() -> NSImage? {
        return gifAnimationController?.currentImage
    }
    
    // MARK: - Private Methods
    
    private func loadImageAtCurrentIndex() async {
        guard !imageFiles.isEmpty,
              currentIndex >= 0,
              currentIndex < imageFiles.count else { 
            logger.warning("Cannot load image: invalid index \(currentIndex) for \(imageFiles.count) images")
            return 
        }
        
        let imageFile = imageFiles[currentIndex]
        currentImageFile = imageFile
        clearError()
        
        do {
            logger.debug("Loading image: \(imageFile.fileName)")
            
            // Use enhanced image loading with metadata for potential GIF support
            let result = try await imageLoaderService.loadImageWithMetadata(from: imageFile.url)
            
            // Set the static image
            currentImage = result.image
            
            // Handle animated GIF if present
            if result.isAnimated, let animatedImage = result.animatedImage {
                currentAnimatedImage = animatedImage
                setupGIFAnimationController(with: animatedImage)
                logger.debug("Loaded animated GIF: \(imageFile.fileName) with \(animatedImage.frameCount) frames")
            } else {
                // Clean up any existing animation for non-GIF images
                cleanupGIFAnimation()
                logger.debug("Loaded static image: \(imageFile.fileName)")
            }
            
        } catch {
            logger.error("Failed to load image: \(imageFile.fileName)", error: error)
            handleError(error)
            currentImage = nil
            cleanupGIFAnimation()
        }
    }
    
    private func setupGIFAnimationController(with animatedImage: AnimatedImage) {
        do {
            gifAnimationController = try GIFAnimationController(animatedImage: animatedImage)
            logger.debug("Created GIF animation controller with \(animatedImage.frameCount) frames")
        } catch {
            logger.error("Failed to create GIF animation controller", error: error)
            gifAnimationController = nil
            currentAnimatedImage = nil
        }
    }
    
    private func cleanupGIFAnimation() {
        stopGIFAnimation()
        gifAnimationController = nil
        currentAnimatedImage = nil
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
    
    private func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    
    var hasImages: Bool {
        !imageFiles.isEmpty
    }
    
    var currentImageIndex: String {
        guard hasImages else { return "0 / 0" }
        return "\(currentIndex + 1) / \(imageFiles.count)"
    }
    
    var canNavigateNext: Bool {
        hasImages && currentIndex < imageFiles.count - 1
    }
    
    var canNavigatePrevious: Bool {
        hasImages && currentIndex > 0
    }
    
    // MARK: - GIF Animation Computed Properties
    
    var isCurrentImageAnimated: Bool {
        return currentAnimatedImage != nil && gifAnimationController != nil
    }
}