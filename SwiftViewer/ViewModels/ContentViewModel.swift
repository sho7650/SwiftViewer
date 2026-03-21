//
//  ContentViewModel.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/26.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class ContentViewModel {

    // MARK: - Observable Properties

    var currentSortType: SortType = .name(ascending: true)
    var currentDisplayMode: DisplayMode = .fit
    var currentWindowPosition: WindowPosition = .normal
    var isFullscreen: Bool = false
    var isRepeatEnabled: Bool = false
    
    // MARK: - Dependencies
    
    private var settingsManager: SettingsManagerProtocol
    
    // MARK: - Initialization
    
    init(settingsManager: SettingsManagerProtocol = DependencyContainer.shared.settingsManager) {
        self.settingsManager = settingsManager
        
        // Initialize from settings
        self.currentSortType = settingsManager.sortType
        self.isRepeatEnabled = settingsManager.repeatEnabled
        self.currentWindowPosition = settingsManager.windowPosition
    }
    
    // MARK: - Sort Management
    
    func updateSortType(_ sortType: SortType) {
        currentSortType = sortType
        settingsManager.sortType = sortType
        NotificationCenter.default.post(name: .sortTypeChanged, object: sortType)
    }
    
    // MARK: - Display Mode Management
    
    func updateDisplayMode(_ displayMode: DisplayMode) {
        currentDisplayMode = displayMode
        NotificationCenter.default.post(name: .displayModeChanged, object: displayMode)
    }
    
    // MARK: - Fullscreen Management
    
    func toggleFullscreen() {
        isFullscreen.toggle()
        NotificationCenter.default.post(name: .fullscreenToggled, object: isFullscreen)
    }
    
    // MARK: - Repeat Management
    
    func toggleRepeat() {
        isRepeatEnabled.toggle()
        settingsManager.repeatEnabled = isRepeatEnabled
        NotificationCenter.default.post(name: .repeatModeChanged, object: isRepeatEnabled)
    }
    
    // MARK: - Window Position Management
    
    func updateWindowPosition(_ position: WindowPosition) {
        currentWindowPosition = position
        settingsManager.windowPosition = position
        
        // Apply window level change immediately
        WindowController.shared.setWindowLevel(position)
        
        NotificationCenter.default.post(name: .windowPositionChanged, object: position)
    }
}