//
//  SlideShowService.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation

@MainActor
protocol SlideShowServiceProtocol {
    var isRunning: Bool { get }
    var currentInterval: TimeInterval? { get }
    
    func startTimer(interval: TimeInterval, action: @escaping () -> Void)
    func stopTimer()
}

@MainActor
final class SlideShowService: SlideShowServiceProtocol {
    
    // MARK: - Properties
    
    private var timer: Timer?
    private var _currentInterval: TimeInterval?
    private let logger = Logger.shared
    
    var isRunning: Bool {
        timer?.isValid == true
    }
    
    var currentInterval: TimeInterval? {
        _currentInterval
    }
    
    // MARK: - Initialization
    
    init() {
        logger.debug("SlideShowService initialized")
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
        logger.debug("SlideShowService deinitialized")
    }
    
    // MARK: - Public Methods
    
    func startTimer(interval: TimeInterval, action: @escaping () -> Void) {
        // Validate interval
        guard interval > 0 else {
            logger.warning("Invalid timer interval: \(interval). Timer not started.")
            return
        }
        
        logger.info("Starting slideshow timer with interval: \(interval)s")
        
        // Stop existing timer if running
        stopTimer()
        
        // Store interval
        _currentInterval = interval
        
        // Create and schedule new timer
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.logger.debug("SlideShow timer fired")
                action()
            }
        }
        
        // Ensure timer runs in current run loop mode
        timer?.tolerance = interval * 0.1 // 10% tolerance for better performance
        
        logger.debug("SlideShow timer started successfully")
    }
    
    func stopTimer() {
        guard let timer = timer, timer.isValid else {
            logger.debug("No active timer to stop")
            return
        }
        
        logger.info("Stopping slideshow timer")
        
        timer.invalidate()
        self.timer = nil
        _currentInterval = nil
        
        logger.debug("SlideShow timer stopped")
    }
}

// MARK: - Mock Implementation

@MainActor
final class MockSlideShowService: SlideShowServiceProtocol {
    var isRunning: Bool = false
    var currentInterval: TimeInterval?
    
    private var mockAction: (() -> Void)?
    private var shouldFailStart: Bool = false
    
    func startTimer(interval: TimeInterval, action: @escaping () -> Void) {
        guard !shouldFailStart else { return }
        
        isRunning = true
        currentInterval = interval
        mockAction = action
    }
    
    func stopTimer() {
        isRunning = false
        currentInterval = nil
        mockAction = nil
    }
    
    // Test helpers
    func simulateTimerFire() {
        mockAction?()
    }
    
    func setShouldFailStart(_ shouldFail: Bool) {
        shouldFailStart = shouldFail
    }
}