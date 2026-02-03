//
//  ContentView.swift
//  SwiftViewer
//
//  Created by sho kisaragi on 2025/08/21.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var selectedFolderURL: URL?
    @State private var imageGalleryViewModel: ImageGalleryViewModel
    @State private var isImageViewerActive = false
    @State private var isFullscreen = false
    @State private var currentLoadingTaskID: UUID?
    @FocusState private var isContentViewFocused: Bool
    
    @StateObject private var contentViewModel = ContentViewModel()
    
    init() {
        let dependencies = DependencyContainer.shared
        self._imageGalleryViewModel = State(initialValue: ImageGalleryViewModel(dependencies: dependencies))
    }
    
    var body: some View {
        ZStack {
            if isImageViewerActive, selectedFolderURL != nil {
                imageGalleryView
            } else {
                folderSelectionView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable()
        .focused($isContentViewFocused)
        .focusedValue(\.openFolderAction) {
            openFolderPicker()
        }
        .focusedValue(\.sortSelectionAction) { sortType in
            contentViewModel.updateSortType(sortType)
            handleSortChange(sortType)
        }
        .focusedValue(\.displayModeAction) { displayMode in
            handleDisplayModeChange(displayMode)
        }
        .focusedValue(\.toggleFullscreenAction) {
            toggleFullscreen()
        }
        .focusedValue(\.toggleRepeatAction) {
            toggleRepeat()
        }
        .focusedValue(\.windowPositionAction) { position in
            contentViewModel.updateWindowPosition(position)
        }
        // MARK: - State Providers
        .focusedValue(\.currentSortType, contentViewModel.currentSortType)
        .focusedValue(\.currentWindowPosition, contentViewModel.currentWindowPosition)
        .focusedValue(\.currentDisplayMode, contentViewModel.currentDisplayMode)
        // Ensure focus is properly set
        .onAppear {
            // Set focus after a short delay to ensure window is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let window = NSApp.keyWindow {
                    window.makeKeyAndOrderFront(nil)
                    isContentViewFocused = true
                    Logger.shared.debug("[ContentView] Focus set on appear")
                }
            }
        }
        .onTapGesture {
            // Restore focus when user interacts with the view
            isContentViewFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .sortTypeChanged)) { notification in
            if let sortType = notification.object as? SortType {
                Task { @MainActor in
                    await imageGalleryViewModel.refreshWithCurrentSort()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var folderSelectionView: some View {
        FolderSelectionView { url in
            handleFolderSelection(url)
        }
        .transition(.opacity)
    }
    
    private var imageGalleryView: some View {
        ImageGalleryView(viewModel: imageGalleryViewModel)
            .transition(.opacity)
    }
    
    // MARK: - Actions
    
    private func openFolderPicker() {
        // Debug log for ⌘O trigger
        Logger.shared.debug("[ContentView] ⌘O triggered - keyWindow: \(NSApp.keyWindow != nil), isActive: \(NSApp.isActive)")
        
        // Ensure window is key before opening panel
        if NSApp.keyWindow == nil {
            Logger.shared.warning("[ContentView] No key window, attempting to make window key")
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        
        // Inherit window level from main window for proper layering
        if let mainWindow = NSApp.keyWindow {
            panel.level = mainWindow.level
            Logger.shared.debug("[ContentView] Panel inheriting level: \(mainWindow.level.rawValue)")
        } else {
            Logger.shared.warning("[ContentView] No key window for panel level inheritance")
        }
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Logger.shared.info("[ContentView] Folder selected: \(url.path)")
                self.handleFolderSelection(url)
            }
        }
    }
    
    private func handleFolderSelection(_ url: URL) {
        selectedFolderURL = url
        
        // Create a unique task ID to prevent race conditions
        let taskID = UUID()
        currentLoadingTaskID = taskID
        
        Task { @MainActor in
            // Load folder contents
            await imageGalleryViewModel.loadFolder(url)
            
            // Check if this is still the current loading task (prevent race condition)
            guard currentLoadingTaskID == taskID else {
                Logger.shared.debug("[ContentView] Skipping UI update - newer folder load initiated")
                return
            }
            
            // Only show image viewer if we successfully loaded images
            if imageGalleryViewModel.hasImages && imageGalleryViewModel.errorMessage == nil {
                withAnimation(.fromSettings(.control)) {
                    isImageViewerActive = true
                }
            } else if let error = imageGalleryViewModel.errorMessage {
                // Show error alert to user
                Logger.shared.error("[ContentView] Failed to load folder: \(error)")
                showErrorAlert(message: error)
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Failed to Load Images"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    
    private func handleSortChange(_ sortType: SortType) {
        contentViewModel.updateSortType(sortType)
    }
    
    private func handleDisplayModeChange(_ displayMode: DisplayMode) {
        contentViewModel.updateDisplayMode(displayMode)
        Logger.shared.info("Display mode changed to: \(displayMode.rawValue)")
        
        // Notify the gallery view to update its display mode
        NotificationCenter.default.post(
            name: Notification.Name("DisplayModeChanged"),
            object: displayMode
        )
    }
    
    private func toggleFullscreen() {
        contentViewModel.toggleFullscreen()
        
        // Debug log before fullscreen
        WindowController.shared.debugState()
        
        // Prepare window level for fullscreen if needed
        if WindowController.shared.prepareForFullscreen() {
            if let window = NSApp.keyWindow {
                // Check current fullscreen state (PhotoSlideshow pattern)
                let isCurrentlyFullscreen = window.styleMask.contains(.fullScreen)
                Logger.shared.info("[ContentView] Current fullscreen state: \(isCurrentlyFullscreen), toggling...")
                
                window.toggleFullScreen(nil)
                
                // Restore window level after fullscreen transition
                if isCurrentlyFullscreen {
                    // Exiting fullscreen - restore immediately
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        WindowController.shared.restoreAfterFullscreen()
                    }
                } else {
                    // Entering fullscreen - restore after longer delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        WindowController.shared.restoreAfterFullscreen()
                    }
                }
            } else {
                Logger.shared.error("[ContentView] No key window for fullscreen")
            }
        }
    }
    
    private func toggleRepeat() {
        contentViewModel.toggleRepeat()
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}
