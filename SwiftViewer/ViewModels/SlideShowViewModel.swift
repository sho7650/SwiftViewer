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
    private let logger = Logger.shared
    
    private var _isRunning: Bool = false
    
    // Convert to stored property for @Observable reactivity
    internal var isRepeatEnabled: Bool = false {
        didSet {
            // Persist through the injected settings manager (honours mocks in tests).
            settingsManager.repeatEnabled = isRepeatEnabled
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

        let result = slideShowService.startTimer(interval: actualInterval, action: makeTimerAction())

        // Only update state if service actually started
        switch result {
        case .success:
            _isRunning = true
        case .failure(let error):
            logger.error("Failed to start slideshow: \(error.localizedDescription)")
            _isRunning = false
        }
    }

    func restartSlideShowIfRunning() {
        guard _isRunning else { return }

        let currentInterval = slideShowService.currentInterval ?? defaultInterval
        slideShowService.stopTimer()
        let result = slideShowService.startTimer(interval: currentInterval, action: makeTimerAction())

        if case .failure(let error) = result {
            logger.error("Failed to restart slideshow: \(error.localizedDescription)")
            _isRunning = false
        }
    }

    func updateIntervalIfRunning() {
        guard _isRunning else { return }

        let newInterval = defaultInterval
        slideShowService.stopTimer()
        let result = slideShowService.startTimer(interval: newInterval, action: makeTimerAction())

        if case .failure(let error) = result {
            logger.error("Failed to update slideshow interval: \(error.localizedDescription)")
            _isRunning = false
        }
    }

    // MARK: - Private Methods

    /// Creates the timer action closure for slideshow navigation.
    /// Handles repeat mode and stopping at the last image.
    private func makeTimerAction() -> @MainActor () -> Void {
        return { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                let isAtLastImage = self.imageNavigator.currentIndex == self.imageNavigator.imageFiles.count - 1
                let isRepeatEnabled = self.settingsManager.repeatEnabled

                if isAtLastImage && !isRepeatEnabled {
                    self.stopSlideShow()
                } else {
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
        NotificationCenter.default.removeObserver(self)
    }
}