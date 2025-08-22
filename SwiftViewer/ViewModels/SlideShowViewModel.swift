//
//  SlideShowViewModel.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation

@MainActor
protocol ImageNavigationProtocol {
    func navigateToNext() async
    func navigateToPrevious() async
    var currentIndex: Int { get }
    var imageFiles: [ImageFile] { get }
}

extension ImageViewerViewModel: ImageNavigationProtocol {}

@MainActor
@Observable
final class SlideShowViewModel {
    
    private let slideShowService: SlideShowServiceProtocol
    private let imageNavigator: ImageNavigationProtocol
    private let settingsManager: SettingsManagerProtocol
    
    private var _isRunning: Bool = false
    
    var defaultInterval: TimeInterval {
        settingsManager.slideShowInterval
    }
    
    var isRepeatEnabled: Bool {
        get { settingsManager.repeatEnabled }
        set { 
            // SettingsManager handles persistence directly
            DependencyContainer.shared.settingsManager.repeatEnabled = newValue
        }
    }
    
    init(slideShowService: SlideShowServiceProtocol, 
         imageNavigator: ImageNavigationProtocol,
         settingsManager: SettingsManagerProtocol) {
        self.slideShowService = slideShowService
        self.imageNavigator = imageNavigator
        self.settingsManager = settingsManager
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
    }
}