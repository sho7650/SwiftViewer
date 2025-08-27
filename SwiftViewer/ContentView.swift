//
//  ContentView.swift
//  SwiftViewer
//
//  Created by sho kisaragi on 2025/08/21.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @State private var selectedFolderURL: URL?
    @State private var imageGalleryViewModel: ImageGalleryViewModel
    @State private var isImageViewerActive = false
    @State private var isFullscreen = false
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
        .focusedValue(\.windowMoveResizeAction) {
            // Handle window move & resize
        }
        .focusedValue(\.windowFullScreenTileAction) {
            // Handle full screen tile
        }
        // MARK: - State Providers
        .focusedValue(\.currentSortType, contentViewModel.currentSortType)
        .focusedValue(\.currentWindowPosition, contentViewModel.currentWindowPosition)
        .focusedValue(\.currentDisplayMode, contentViewModel.currentDisplayMode)
        .onAppear {
            // Ensure ContentView has focus for keyboard shortcuts
            DispatchQueue.main.async {
                isContentViewFocused = true
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
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                handleFolderSelection(url)
            }
        }
    }
    
    private func handleFolderSelection(_ url: URL) {
        selectedFolderURL = url
        
        Task { @MainActor in
            // Load folder contents
            await imageGalleryViewModel.loadFolder(url)
            
            // Only show image viewer if we successfully loaded images
            if imageGalleryViewModel.hasImages && imageGalleryViewModel.errorMessage == nil {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isImageViewerActive = true
                }
            }
        }
    }
    
    
    private func handleSortChange(_ sortType: SortType) {
        contentViewModel.updateSortType(sortType)
    }
    
    private func handleDisplayModeChange(_ displayMode: DisplayMode) {
        // Placeholder for Phase 6.1 implementation
        contentViewModel.updateDisplayMode(displayMode)
        Logger.shared.info("Display mode changed to: \(displayMode.rawValue)")
    }
    
    private func toggleFullscreen() {
        // Placeholder for Phase 4.2 implementation
        contentViewModel.toggleFullscreen()
        
        if let window = NSApp.keyWindow {
            window.toggleFullScreen(nil)
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
