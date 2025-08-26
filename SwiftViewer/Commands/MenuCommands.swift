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

struct RepeatToggleKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct WindowPositionSelectionKey: FocusedValueKey {
    typealias Value = (WindowPosition) -> Void
}

struct WindowMoveResizeKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct WindowFullScreenTileKey: FocusedValueKey {
    typealias Value = () -> Void
}

// MARK: - State Focused Values

struct CurrentSortTypeKey: FocusedValueKey {
    typealias Value = SortType
}

struct CurrentWindowPositionKey: FocusedValueKey {
    typealias Value = WindowPosition
}

struct CurrentDisplayModeKey: FocusedValueKey {
    typealias Value = DisplayMode
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
    
    var toggleRepeatAction: (() -> Void)? {
        get { self[RepeatToggleKey.self] }
        set { self[RepeatToggleKey.self] = newValue }
    }
    
    var windowPositionAction: ((WindowPosition) -> Void)? {
        get { self[WindowPositionSelectionKey.self] }
        set { self[WindowPositionSelectionKey.self] = newValue }
    }
    
    var windowMoveResizeAction: (() -> Void)? {
        get { self[WindowMoveResizeKey.self] }
        set { self[WindowMoveResizeKey.self] = newValue }
    }
    
    var windowFullScreenTileAction: (() -> Void)? {
        get { self[WindowFullScreenTileKey.self] }
        set { self[WindowFullScreenTileKey.self] = newValue }
    }
    
    // MARK: - State Accessors
    
    var currentSortType: SortType? {
        get { self[CurrentSortTypeKey.self] }
        set { self[CurrentSortTypeKey.self] = newValue }
    }
    
    var currentWindowPosition: WindowPosition? {
        get { self[CurrentWindowPositionKey.self] }
        set { self[CurrentWindowPositionKey.self] = newValue }
    }
    
    var currentDisplayMode: DisplayMode? {
        get { self[CurrentDisplayModeKey.self] }
        set { self[CurrentDisplayModeKey.self] = newValue }
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
    @FocusedValue(\.toggleRepeatAction) var toggleRepeatAction
    @FocusedValue(\.windowPositionAction) var windowPositionAction
    @FocusedValue(\.windowMoveResizeAction) var windowMoveResizeAction
    @FocusedValue(\.windowFullScreenTileAction) var windowFullScreenTileAction
    
    // MARK: - State FocusedValues
    @FocusedValue(\.currentSortType) var currentSortType
    @FocusedValue(\.currentWindowPosition) var currentWindowPosition
    @FocusedValue(\.currentDisplayMode) var currentDisplayMode
    
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
            
            Button("Toggle Repeat Slideshow") {
                toggleRepeatAction?()
            }
            .keyboardShortcut("r", modifiers: .command)
            
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
        
        // MARK: - Window Menu
        CommandGroup(after: .windowArrangement) {
            Section("Position") {
                Button(currentWindowPosition == .alwaysOnTop ? "✓ Always on Top" : "Always on Top") {
                    windowPositionAction?(.alwaysOnTop)
                }
                .keyboardShortcut("t", modifiers: [.command, .control])
                
                Button(currentWindowPosition == .alwaysOnBottom ? "✓ Always on Bottom" : "Always on Bottom") {
                    windowPositionAction?(.alwaysOnBottom)
                }
                .keyboardShortcut("b", modifiers: [.command, .control])
                
                Button(currentWindowPosition == .normal ? "✓ Normal Position" : "Normal Position") {
                    windowPositionAction?(.normal)
                }
            }
            
            Divider()
            
            Button("Move & Resize") {
                windowMoveResizeAction?()
            }
            .keyboardShortcut("m", modifiers: [.command, .control])
            
            Button("Full Screen Tile") {
                windowFullScreenTileAction?()
            }
            .keyboardShortcut("g", modifiers: [.command, .control])
        }
        
        // MARK: - Sort Menu
        CommandMenu("Sort") {
            Section("By Name") {
                Button(currentSortType == .name(ascending: true) ? "✓ Name (A-Z)" : "Name (A-Z)") {
                    sortSelectionAction?(.name(ascending: true))
                }
                .keyboardShortcut("1", modifiers: [.command, .option])
                
                Button(currentSortType == .name(ascending: false) ? "✓ Name (Z-A)" : "Name (Z-A)") {
                    sortSelectionAction?(.name(ascending: false))
                }
                .keyboardShortcut("1", modifiers: [.command, .option, .shift])
            }
            
            Divider()
            
            Section("By Date") {
                Button(currentSortType == .date(ascending: true) ? "✓ Date (Oldest First)" : "Date (Oldest First)") {
                    sortSelectionAction?(.date(ascending: true))
                }
                .keyboardShortcut("2", modifiers: [.command, .option])
                
                Button(currentSortType == .date(ascending: false) ? "✓ Date (Newest First)" : "Date (Newest First)") {
                    sortSelectionAction?(.date(ascending: false))
                }
                .keyboardShortcut("2", modifiers: [.command, .option, .shift])
            }
            
            Divider()
            
            Section("By Size") {
                Button(currentSortType == .size(ascending: true) ? "✓ Size (Smallest First)" : "Size (Smallest First)") {
                    sortSelectionAction?(.size(ascending: true))
                }
                .keyboardShortcut("3", modifiers: [.command, .option])
                
                Button(currentSortType == .size(ascending: false) ? "✓ Size (Largest First)" : "Size (Largest First)") {
                    sortSelectionAction?(.size(ascending: false))
                }
                .keyboardShortcut("3", modifiers: [.command, .option, .shift])
            }
            
            Divider()
            
            Button(currentSortType == .random ? "✓ Random" : "Random") {
                sortSelectionAction?(.random)
            }
            .keyboardShortcut("r", modifiers: [.command, .option])
        }
    }
}


// MARK: - Notification Names

extension Notification.Name {
    static let sortTypeChanged = Notification.Name("sortTypeChanged")
    static let displayModeChanged = Notification.Name("displayModeChanged")
    static let fullscreenToggled = Notification.Name("fullscreenToggled")
    static let repeatModeChanged = Notification.Name("repeatModeChanged")
    static let windowPositionChanged = Notification.Name("windowPositionChanged")
}