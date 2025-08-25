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
    
    @Environment(MenuState.self) private var menuState
    
    private let bookmarkManagerService: BookmarkManagerServiceProtocol
    
    init() {
        let dependencies = DependencyContainer.shared
        self._imageGalleryViewModel = State(initialValue: ImageGalleryViewModel(dependencies: dependencies))
        self.bookmarkManagerService = dependencies.bookmarkManagerService
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
        .focusedValue(\.openFolderAction) {
            openFolderPicker()
        }
        .focusedValue(\.sortSelectionAction) { sortType in
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
            // Create persistent bookmark for future access
            await createBookmarkForFolder(url)
            
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
    
    private func createBookmarkForFolder(_ url: URL) async {
        // For external volumes, try creating bookmark after a brief delay
        // This allows the system permission to be fully established
        if url.path.starts(with: "/Volumes/") {
            // Small delay for external volume permission establishment
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        }
        
        do {
            try bookmarkManagerService.createAndStoreBookmark(for: url)
            Logger.shared.info("Successfully created bookmark for folder: \(url.path)")
        } catch let error as BookmarkManagerError {
            Logger.shared.warning("Could not create bookmark for folder: \(url.path). App will use temporary permissions.")
            Logger.shared.debug("Bookmark creation failed: \(error.localizedDescription)")
            // Don't prevent folder loading - temporary permissions from NSOpenPanel should still work
        } catch {
            Logger.shared.error("Unexpected error creating bookmark: \(url.path)", error: error)
        }
    }
    
    private func handleSortChange(_ sortType: SortType) {
        menuState.updateSortType(sortType)
    }
    
    private func handleDisplayModeChange(_ displayMode: DisplayMode) {
        // Placeholder for Phase 6.1 implementation
        menuState.updateDisplayMode(displayMode)
        Logger.shared.info("Display mode changed to: \(displayMode.rawValue)")
    }
    
    private func toggleFullscreen() {
        // Placeholder for Phase 4.2 implementation
        menuState.toggleFullscreen()
        
        if let window = NSApp.keyWindow {
            window.toggleFullScreen(nil)
        }
    }
    
    private func toggleRepeat() {
        menuState.toggleRepeat()
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}
