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
    @State private var isShowingFolderPicker = false
    @State private var isFullscreen = false
    
    @Environment(MenuState.self) private var menuState
    
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
        .focusedValue(\.openFolderAction) {
            isShowingFolderPicker = true
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
        .fileImporter(
            isPresented: $isShowingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    handleFolderSelection(url)
                }
            case .failure(let error):
                print("Error selecting folder: \(error)")
            }
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
    
    private func handleFolderSelection(_ url: URL) {
        selectedFolderURL = url
        
        Task { @MainActor in
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
        menuState.updateSortType(sortType)
    }
    
    private func handleDisplayModeChange(_ displayMode: DisplayMode) {
        // Placeholder for Phase 6.1 implementation
        menuState.updateDisplayMode(displayMode)
        print("Display mode changed to: \(displayMode.rawValue)")
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
