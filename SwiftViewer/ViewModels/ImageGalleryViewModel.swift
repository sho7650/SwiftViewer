//
//  ImageGalleryViewModel.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation
import AppKit
import SwiftUI
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
    
    // MARK: - Dependencies

    private let fileManagerService: FileManagerServiceProtocol
    private let imagePipeline: ImagePipelineProtocol
    private let settingsManager: SettingsManagerProtocol
    private let logger = Logger.shared

    // Tracks the in-flight display load so rapid navigation can cancel stale work.
    private var displayLoadTask: Task<Void, Never>?
    private var preloadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(dependencies: DependencyContainerProtocol) {
        self.fileManagerService = dependencies.fileManagerService
        self.imagePipeline = dependencies.imagePipeline
        self.settingsManager = dependencies.settingsManager
    }

    /// The longest edge, in pixels, worth decoding for the current display.
    private var displayMaxPixelSize: CGFloat {
        guard let screen = NSScreen.main else { return 2048 }
        let longEdge = max(screen.frame.width, screen.frame.height)
        return longEdge * screen.backingScaleFactor
    }
    
    // MARK: - Public Methods
    
    func loadFolder(_ url: URL) async {
        logger.info("Loading folder: \(Logger.sanitizePath(url))")
        clearError()
        isLoading = true
        await imagePipeline.reset()

        do {
            let sortType = settingsManager.sortType
            let loadedFiles = try await fileManagerService.getImageFiles(from: url, sortBy: sortType)

            imageFiles = loadedFiles
            currentIndex = 0

            if !imageFiles.isEmpty {
                await loadImageAtCurrentIndex()
                schedulePreload()
            } else {
                currentImage = nil
                currentImageFile = nil
                logger.warning("No image files found in folder: \(Logger.sanitizePath(url))")
            }

        } catch {
            logger.error("Failed to load folder: \(Logger.sanitizePath(url))", error: error)
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
        
        currentIndex = index
        await loadImageAtCurrentIndex()
        schedulePreload()
    }
    
    func refreshWithCurrentSort() async {
        guard !imageFiles.isEmpty else { return }

        logger.info("Refreshing with current sort type")

        // Re-order the already-loaded files in memory; no directory re-scan.
        let currentImageFile = self.currentImageFile
        imageFiles = imageFiles.sorted(by: settingsManager.sortType)

        if let currentFile = currentImageFile,
           let newIndex = imageFiles.firstIndex(where: { $0.url == currentFile.url }) {
            currentIndex = newIndex
        } else {
            currentIndex = 0
        }

        await loadImageAtCurrentIndex()
        schedulePreload()
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
        let requestedIndex = currentIndex
        clearError()

        displayLoadTask?.cancel()
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performLoad(of: imageFile, requestedIndex: requestedIndex)
        }
        displayLoadTask = task
        await task.value
    }

    private func performLoad(of imageFile: ImageFile, requestedIndex: Int) async {
        do {
            logger.debug("Loading image: \(imageFile.fileName)")
            let decoded = try await imagePipeline.image(for: imageFile.url, maxPixelSize: displayMaxPixelSize)

            // Ignore results for a navigation that has since moved on or been cancelled.
            guard !Task.isCancelled, currentIndex == requestedIndex else { return }

            let image = NSImage(cgImage: decoded.cgImage, size: .zero)
            withAnimation(.fromSettings(.transition)) {
                self.currentImageFile = imageFile
                self.currentImage = image
            }
        } catch is CancellationError {
            return
        } catch {
            guard currentIndex == requestedIndex else { return }
            logger.error("Failed to load image: \(imageFile.fileName)", error: error)
            handleError(error)
            self.currentImage = nil
        }
    }

    /// Preloads a forward-biased window of neighbours around the current index.
    private func schedulePreload() {
        guard !imageFiles.isEmpty else { return }
        let window = settingsManager.cachePreloadWindow
        let backward = min(2, window)
        let forward = window - backward

        var urls: [URL] = []
        for offset in 1...max(1, forward) where currentIndex + offset < imageFiles.count {
            urls.append(imageFiles[currentIndex + offset].url)
        }
        for offset in 1...max(1, backward) where currentIndex - offset >= 0 {
            urls.append(imageFiles[currentIndex - offset].url)
        }

        let maxPixelSize = displayMaxPixelSize
        preloadTask?.cancel()
        preloadTask = Task { [weak self] in
            await self?.imagePipeline.preload(urls, maxPixelSize: maxPixelSize)
        }
    }

    private func handleError(_ error: Error) {
        switch error {
        case FileManagerServiceError.directoryNotFound:
            errorMessage = "Folder not found."
        case FileManagerServiceError.accessDenied:
            errorMessage = "SwiftViewer doesn't have permission to read this folder."
        case FileManagerServiceError.symbolicLinkNotAllowed:
            errorMessage = "Symbolic links are not supported."
        case FileManagerServiceError.readError:
            errorMessage = "The folder could not be read."
        case ImagePipelineError.fileNotFound, ImagePipelineError.invalidImage:
            errorMessage = "This image could not be displayed."
        default:
            errorMessage = "An unexpected error occurred."
        }
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