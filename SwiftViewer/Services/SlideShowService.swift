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
    
    func startTimer(interval: TimeInterval, action: @escaping @MainActor () -> Void) -> Result<Void, SlideShowError>
    func stopTimer()
}

enum SlideShowError: LocalizedError, Equatable {
    case invalidInterval(TimeInterval)

    var errorDescription: String? {
        switch self {
        case .invalidInterval(let interval):
            return "Invalid slideshow interval: \(interval) seconds. Please use a value between 1 and 1800 seconds."
        }
    }
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
    
    isolated deinit {
        timer?.invalidate()
        timer = nil
        logger.debug("SlideShowService deinitialized")
    }
    
    // MARK: - Public Methods
    
    func startTimer(interval: TimeInterval, action: @escaping @MainActor () -> Void) -> Result<Void, SlideShowError> {
        // Validate interval (1 second to 30 minutes)
        guard interval >= 1.0 && interval <= 1800.0 else {
            logger.error("Invalid timer interval: \(interval). Must be between 1 and 1800 seconds.")
            return .failure(.invalidInterval(interval))
        }
        
        logger.info("Starting slideshow timer with interval: \(interval)s")
        
        // Stop existing timer if running
        stopTimer()
        
        // Store interval
        _currentInterval = interval
        
        // Create and schedule new timer. scheduledTimer fires on the main run loop,
        // so the callback is already on the main actor.
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.logger.debug("SlideShow timer fired")
                action()
            }
        }
        
        // Ensure timer runs in current run loop mode
        timer?.tolerance = interval * 0.1 // 10% tolerance for better performance
        
        logger.debug("SlideShow timer started successfully")
        return .success(())
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

    private var mockAction: (@MainActor () -> Void)?
    private var shouldFailStart: Bool = false
    /// For testing: allow intervals below 1.0 second
    var allowShortIntervals: Bool = true

    func startTimer(interval: TimeInterval, action: @escaping @MainActor () -> Void) -> Result<Void, SlideShowError> {
        guard !shouldFailStart else {
            return .failure(.invalidInterval(interval))
        }

        // For testing: optionally skip the 1.0 minimum interval check
        let minInterval: TimeInterval = allowShortIntervals ? 0.01 : 1.0
        guard interval >= minInterval && interval <= 1800.0 else {
            return .failure(.invalidInterval(interval))
        }

        isRunning = true
        currentInterval = interval
        mockAction = action
        return .success(())
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