//
//  ImageViewerViewModel.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation
import AppKit
import Observation

@Observable
@MainActor
final class ImageViewerViewModel {
    
    // MARK: - Observable Properties
    
    var currentImage: NSImage?
    var currentImageFile: ImageFile?
    var imageFiles: [ImageFile] = []
    var currentIndex: Int = 0
    var isLoading: Bool = false
    var errorMessage: String?
    
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
        
        let nextIndex = (currentIndex + 1) % imageFiles.count
        await navigateToIndex(nextIndex)
    }
    
    func navigateToPrevious() async {
        guard !imageFiles.isEmpty else { return }
        
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
        
        currentIndex = index
        await loadImageAtCurrentIndex()
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
    
    // MARK: - Private Methods
    
    private func loadImageAtCurrentIndex() async {
        guard currentIndex < imageFiles.count else { return }
        
        let imageFile = imageFiles[currentIndex]
        currentImageFile = imageFile
        clearError()
        
        do {
            logger.debug("Loading image: \(imageFile.fileName)")
            currentImage = try await imageLoaderService.loadImage(from: imageFile.url)
            
        } catch {
            logger.error("Failed to load image: \(imageFile.fileName)", error: error)
            handleError(error)
            currentImage = nil
        }
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
}