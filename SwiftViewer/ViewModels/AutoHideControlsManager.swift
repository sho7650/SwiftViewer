//
//  AutoHideControlsManager.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/22.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class AutoHideControlsManager {
    
    // MARK: - Observable Properties
    
    private(set) var areControlsVisible: Bool = true
    private(set) var lastActivityTime: Date = Date()
    
    // MARK: - Private Properties
    
    private var hideTimer: Timer?
    private let autoHideDelay: TimeInterval = 3.0
    
    // Dependencies for state checking
    private weak var slideShowViewModel: SlideShowViewModel?
    private weak var imageGalleryViewModel: ImageGalleryViewModel?
    
    // MARK: - Initialization
    
    init(slideShowViewModel: SlideShowViewModel?, imageGalleryViewModel: ImageGalleryViewModel?) {
        self.slideShowViewModel = slideShowViewModel
        self.imageGalleryViewModel = imageGalleryViewModel
    }
    
    deinit {
        // Note: Timer cleanup will be handled automatically when the object is deallocated
        // Swift 6 strict concurrency doesn't allow accessing actor-isolated properties in deinit
    }
    
    // MARK: - Public Methods
    
    func showControlsAndResetTimer() {
        withAnimation(.fromSettings(.control)) {
            areControlsVisible = true
        }
        resetHideTimer()
    }
    
    func hideControlsImmediately() {
        withAnimation(.fromSettings(.control)) {
            areControlsVisible = false
        }
        cleanupTimer()
    }
    
    open func registerActivity() {
        showControlsAndResetTimer()
    }
    
    func cleanupTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    // MARK: - Private Methods
    
    private func resetHideTimer() {
        // Cancel existing timer
        cleanupTimer()
        
        // Update activity time
        lastActivityTime = Date()
        
        // Don't auto-hide if conditions don't allow it
        guard shouldAllowAutoHide() else {
            return
        }
        
        // Start new timer
        hideTimer = Timer.scheduledTimer(withTimeInterval: autoHideDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.hideControlsIfAllowed()
            }
        }
    }
    
    internal func hideControlsIfAllowed() {
        guard shouldAllowAutoHide() else {
            return
        }
        
        withAnimation(.fromSettings(.control)) {
            areControlsVisible = false
        }
        cleanupTimer()
    }
    
    open func shouldAllowAutoHide() -> Bool {
        // Allow auto-hide during slideshow - controls will reappear on any user interaction
        // This provides a cleaner viewing experience while keeping controls accessible
        
        // Don't auto-hide if we're in loading state
        if let galleryVM = imageGalleryViewModel, galleryVM.isLoading {
            return false
        }
        
        // Don't auto-hide if there's an error
        if let galleryVM = imageGalleryViewModel, galleryVM.errorMessage != nil {
            return false
        }
        
        return true
    }
}

// MARK: - Mock Implementation

@MainActor
@Observable
final class MockAutoHideControlsManager: AutoHideControlsManager {
    
    var mockShouldAllowAutoHide: Bool = true
    var hideTimerFireCount: Int = 0
    var registerActivityCallCount: Int = 0
    
    override init(slideShowViewModel: SlideShowViewModel?, imageGalleryViewModel: ImageGalleryViewModel?) {
        super.init(slideShowViewModel: slideShowViewModel, imageGalleryViewModel: imageGalleryViewModel)
    }
    
    override func registerActivity() {
        registerActivityCallCount += 1
        super.registerActivity()
    }
    
    func simulateTimerFire() {
        hideTimerFireCount += 1
        hideControlsIfAllowed()
    }
    
    override func shouldAllowAutoHide() -> Bool {
        return mockShouldAllowAutoHide
    }
    
    func simulateAutoHideCheck() -> Bool {
        return super.shouldAllowAutoHide()
    }
}