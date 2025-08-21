//
//  ContentView.swift
//  SwiftViewer
//
//  Created by sho kisaragi on 2025/08/21.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedFolderURL: URL?
    @State private var imageViewerViewModel: ImageViewerViewModel
    @State private var isImageViewerActive = false
    
    init() {
        let dependencies = DependencyContainer.shared
        self._imageViewerViewModel = State(initialValue: ImageViewerViewModel(dependencies: dependencies))
    }
    
    var body: some View {
        ZStack {
            if isImageViewerActive, selectedFolderURL != nil {
                imageViewerView
            } else {
                folderSelectionView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onKeyPress { keyPress in
            handleGlobalKeyPress(keyPress.key)
            return .handled
        }
        .focusable()
    }
    
    // MARK: - Subviews
    
    private var folderSelectionView: some View {
        FolderSelectionView { url in
            handleFolderSelection(url)
        }
        .transition(.opacity)
    }
    
    private var imageViewerView: some View {
        ImageViewerView(viewModel: imageViewerViewModel)
            .transition(.opacity)
    }
    
    // MARK: - Actions
    
    private func handleFolderSelection(_ url: URL) {
        selectedFolderURL = url
        
        Task { @MainActor in
            await imageViewerViewModel.loadFolder(url)
            
            // Only show image viewer if we successfully loaded images
            if imageViewerViewModel.hasImages && imageViewerViewModel.errorMessage == nil {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isImageViewerActive = true
                }
            }
        }
    }
    
    private func returnToFolderSelection() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isImageViewerActive = false
        }
        selectedFolderURL = nil
    }
    
    private func handleGlobalKeyPress(_ key: KeyEquivalent) {
        switch key {
        case .escape:
            if isImageViewerActive {
                returnToFolderSelection()
            }
        case "f", "F":
            // TODO: Toggle fullscreen in future phase
            break
        default:
            break
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}
