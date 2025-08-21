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
                await self.imageNavigator.navigateToNext()
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
                    await self.imageNavigator.navigateToNext()
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
                    await self.imageNavigator.navigateToNext()
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