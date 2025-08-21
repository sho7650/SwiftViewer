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
        slideShowService.isRunning
    }
    
    var currentInterval: TimeInterval? {
        slideShowService.currentInterval
    }
    
    func startSlideShow(interval: TimeInterval? = nil) {
        let actualInterval = interval ?? defaultInterval
        guard actualInterval > 0 else { return }
        
        slideShowService.startTimer(interval: actualInterval) { [weak self] in
            guard let self = self else { return }
            // Note: For testing, we need synchronous execution
            Task { @MainActor in
                await self.imageNavigator.navigateToNext()
            }
        }
    }
    
    func stopSlideShow() {
        slideShowService.stopTimer()
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