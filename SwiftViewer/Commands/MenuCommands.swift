//
//  MenuCommands.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/22.
//

import SwiftUI

// MARK: - Focused Values

struct FolderSelectionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct SortSelectionKey: FocusedValueKey {
    typealias Value = (SortType) -> Void
}

struct DisplayModeSelectionKey: FocusedValueKey {
    typealias Value = (DisplayMode) -> Void
}

struct FullscreenToggleKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var openFolderAction: (() -> Void)? {
        get { self[FolderSelectionKey.self] }
        set { self[FolderSelectionKey.self] = newValue }
    }
    
    var sortSelectionAction: ((SortType) -> Void)? {
        get { self[SortSelectionKey.self] }
        set { self[SortSelectionKey.self] = newValue }
    }
    
    var displayModeAction: ((DisplayMode) -> Void)? {
        get { self[DisplayModeSelectionKey.self] }
        set { self[DisplayModeSelectionKey.self] = newValue }
    }
    
    var toggleFullscreenAction: (() -> Void)? {
        get { self[FullscreenToggleKey.self] }
        set { self[FullscreenToggleKey.self] = newValue }
    }
}

// MARK: - Display Mode

enum DisplayMode: String, CaseIterable {
    case fit = "Fit to Window"
    case fill = "Fill Window"
    case actualSize = "Actual Size"
}

// MARK: - Menu Commands

struct MenuCommands: Commands {
    @FocusedValue(\.openFolderAction) var openFolderAction
    @FocusedValue(\.sortSelectionAction) var sortSelectionAction
    @FocusedValue(\.displayModeAction) var displayModeAction
    @FocusedValue(\.toggleFullscreenAction) var toggleFullscreenAction
    
    var body: some Commands {
        // MARK: - File Menu
        CommandGroup(replacing: .newItem) {
            Button("Open Folder...") {
                openFolderAction?()
            }
            .keyboardShortcut("o", modifiers: .command)
            
            Menu("Recent Folders") {
                Text("No Recent Folders")
                    .foregroundColor(.secondary)
            }
            .disabled(true) // Will be enabled in Phase 7
            
            Divider()
        }
        
        // MARK: - View Menu
        CommandGroup(after: .toolbar) {
            Button("Toggle Fullscreen") {
                toggleFullscreenAction?()
            }
            .keyboardShortcut("f", modifiers: .command)
            
            Divider()
            
            Menu("Display Mode") {
                Button("Fit to Window") {
                    displayModeAction?(.fit)
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Fill Window") {
                    displayModeAction?(.fill)
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Actual Size") {
                    displayModeAction?(.actualSize)
                }
                .keyboardShortcut("3", modifiers: .command)
            }
            
            Divider()
        }
        
        // MARK: - Sort Menu
        CommandMenu("Sort") {
            Section("By Name") {
                Button("Ascending") {
                    sortSelectionAction?(.name(ascending: true))
                }
                .keyboardShortcut("1", modifiers: [.command, .option])
                
                Button("Descending") {
                    sortSelectionAction?(.name(ascending: false))
                }
                .keyboardShortcut("1", modifiers: [.command, .option, .shift])
            }
            
            Divider()
            
            Section("By Date") {
                Button("Ascending") {
                    sortSelectionAction?(.date(ascending: true))
                }
                .keyboardShortcut("2", modifiers: [.command, .option])
                
                Button("Descending") {
                    sortSelectionAction?(.date(ascending: false))
                }
                .keyboardShortcut("2", modifiers: [.command, .option, .shift])
            }
            
            Divider()
            
            Section("By Size") {
                Button("Ascending") {
                    sortSelectionAction?(.size(ascending: true))
                }
                .keyboardShortcut("3", modifiers: [.command, .option])
                
                Button("Descending") {
                    sortSelectionAction?(.size(ascending: false))
                }
                .keyboardShortcut("3", modifiers: [.command, .option, .shift])
            }
            
            Divider()
            
            Button("Random") {
                sortSelectionAction?(.random)
            }
            .keyboardShortcut("r", modifiers: [.command, .option])
        }
    }
}

// MARK: - App State for Menu

@Observable
@MainActor
final class MenuState {
    var currentSortType: SortType = .name(ascending: true)
    var currentDisplayMode: DisplayMode = .fit
    var isFullscreen: Bool = false
    var hasRecentFolders: Bool = false
    
    init() {
        let settingsManager = DependencyContainer.shared.settingsManager
        self.currentSortType = settingsManager.sortType
    }
    
    func updateSortType(_ sortType: SortType) {
        currentSortType = sortType
        DependencyContainer.shared.settingsManager.sortType = sortType
        NotificationCenter.default.post(name: .sortTypeChanged, object: sortType)
    }
    
    func updateDisplayMode(_ displayMode: DisplayMode) {
        currentDisplayMode = displayMode
        NotificationCenter.default.post(name: .displayModeChanged, object: displayMode)
    }
    
    func toggleFullscreen() {
        isFullscreen.toggle()
        NotificationCenter.default.post(name: .fullscreenToggled, object: isFullscreen)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let sortTypeChanged = Notification.Name("sortTypeChanged")
    static let displayModeChanged = Notification.Name("displayModeChanged")
    static let fullscreenToggled = Notification.Name("fullscreenToggled")
}