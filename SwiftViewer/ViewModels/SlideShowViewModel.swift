//
//  SlideShowViewModel.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation

@MainActor
protocol ImageGalleryNavigationProtocol {
    func navigateToNext() async
    func navigateToPrevious() async
    var currentIndex: Int { get }
    var imageFiles: [ImageFile] { get }
}

extension ImageGalleryViewModel: ImageGalleryNavigationProtocol {}

@MainActor
@Observable
final class SlideShowViewModel {
    
    private let slideShowService: SlideShowServiceProtocol
    private let imageNavigator: ImageGalleryNavigationProtocol
    private var settingsManager: SettingsManagerProtocol
    
    private var _isRunning: Bool = false
    
    // Convert to stored property for @Observable reactivity
    internal var isRepeatEnabled: Bool = false {
        didSet {
            // Update settings manager when property changes - use shared instance for consistency
            DependencyContainer.shared.settingsManager.repeatEnabled = isRepeatEnabled
        }
    }
    
    var defaultInterval: TimeInterval {
        settingsManager.slideShowInterval
    }
    
    init(slideShowService: SlideShowServiceProtocol, 
         imageNavigator: ImageGalleryNavigationProtocol,
         settingsManager: SettingsManagerProtocol) {
        self.slideShowService = slideShowService
        self.imageNavigator = imageNavigator
        self.settingsManager = settingsManager
        
        // Initialize repeat enabled from settings
        self.isRepeatEnabled = settingsManager.repeatEnabled
        
        // Listen for repeat mode changes from Settings panel
        NotificationCenter.default.addObserver(
            forName: .repeatModeChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let newValue = notification.object as? Bool {
                MainActor.assumeIsolated {
                    self?.isRepeatEnabled = newValue
                }
            }
        }
    }
    
    
    func toggleRepeatMode() {
        isRepeatEnabled.toggle()
    }
    
    var isRunning: Bool {
        _isRunning
    }
    
    var currentInterval: TimeInterval? {
        slideShowService.currentInterval
    }
    
    func startSlideShow(interval: TimeInterval? = nil) {
        let actualInterval = interval ?? defaultInterval
        guard actualInterval > 0 else { return }
        
        slideShowService.startTimer(interval: actualInterval) { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                // Check if we should stop at the last image
                let isAtLastImage = self.imageNavigator.currentIndex == self.imageNavigator.imageFiles.count - 1
                let isRepeatEnabled = self.settingsManager.repeatEnabled
                
                if isAtLastImage && !isRepeatEnabled {
                    // Stop slideshow when reaching the last image without repeat
                    self.stopSlideShow()
                } else {
                    await self.imageNavigator.navigateToNext()
                }
            }
        }
        
        // Only update state if service actually started
        if slideShowService.isRunning {
            _isRunning = true
        }
    }
    
    func restartSlideShowIfRunning() {
        if _isRunning {
            let currentInterval = slideShowService.currentInterval ?? defaultInterval
            slideShowService.stopTimer()
            slideShowService.startTimer(interval: currentInterval) { [weak self] in
                guard let self = self else { return }
                Task { @MainActor in
                    // Check if we should stop at the last image
                    let isAtLastImage = self.imageNavigator.currentIndex == self.imageNavigator.imageFiles.count - 1
                    let isRepeatEnabled = self.settingsManager.repeatEnabled
                    
                    if isAtLastImage && !isRepeatEnabled {
                        // Stop slideshow when reaching the last image without repeat
                        self.stopSlideShow()
                    } else {
                        await self.imageNavigator.navigateToNext()
                    }
                }
            }
        }
    }
    
    func updateIntervalIfRunning() {
        if _isRunning {
            let newInterval = defaultInterval
            slideShowService.stopTimer()
            slideShowService.startTimer(interval: newInterval) { [weak self] in
                guard let self = self else { return }
                Task { @MainActor in
                    // Check if we should stop at the last image
                    let isAtLastImage = self.imageNavigator.currentIndex == self.imageNavigator.imageFiles.count - 1
                    let isRepeatEnabled = self.settingsManager.repeatEnabled
                    
                    if isAtLastImage && !isRepeatEnabled {
                        // Stop slideshow when reaching the last image without repeat
                        self.stopSlideShow()
                    } else {
                        await self.imageNavigator.navigateToNext()
                    }
                }
            }
        }
    }
    
    func stopSlideShow() {
        slideShowService.stopTimer()
        _isRunning = false
    }
    
    func toggleSlideShow(interval: TimeInterval? = nil) {
        if isRunning {
            stopSlideShow()
        } else {
            startSlideShow(interval: interval)
        }
    }
    
    deinit {
        // Note: Cannot call async methods in deinit
        // Timer cleanup will be handled by SlideShowService's own deinit
        NotificationCenter.default.removeObserver(self)
    }
}