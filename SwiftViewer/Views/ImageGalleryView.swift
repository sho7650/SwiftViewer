//
//  ImageGalleryView.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import SwiftUI
import AppKit

struct ImageGalleryView: View {
    @State private var viewModel: ImageViewerViewModel
    @State private var slideShowViewModel: SlideShowViewModel
    @FocusState private var isFocused: Bool
    
    init(viewModel: ImageViewerViewModel) {
        self.viewModel = viewModel
        let dependencies = DependencyContainer.shared
        self.slideShowViewModel = SlideShowViewModel(
            slideShowService: dependencies.slideShowService,
            imageNavigator: viewModel,
            settingsManager: dependencies.settingsManager
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Main content
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else if let currentImage = viewModel.currentImage {
                    imageDisplayView(currentImage)
                } else {
                    emptyStateView
                }
                
                // Image info overlay (if image is loaded)
                if viewModel.hasImages && !viewModel.isLoading {
                    imageInfoOverlay
                }
                
                // Slideshow controls overlay
                if viewModel.hasImages && !viewModel.isLoading {
                    slideShowControlsOverlay
                }
            }
        }
        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
        }
        .onKeyPress { keyPress in
            handleKeyPress(keyPress.key)
            return .handled
        }
        .onDisappear {
            slideShowViewModel.stopSlideShow()
        }
        .onReceive(NotificationCenter.default.publisher(for: .slideShowIntervalChanged)) { _ in
            slideShowViewModel.updateIntervalIfRunning()
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .foregroundColor(.white)
                .font(.headline)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Image Selected")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Use ← → keys to navigate when images are loaded")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func imageDisplayView(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipped()
    }
    
    private var imageInfoOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let currentImageFile = viewModel.currentImageFile {
                        Text(currentImageFile.fileName)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("\(currentImageFile.formattedFileSize)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(viewModel.currentImageIndex)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.6))
                )
            }
            
            Spacer()
            
            // Navigation hints
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("← Previous")
                        .opacity(viewModel.currentIndex > 0 ? 1.0 : 0.5)
                    Text("→ Next")
                        .opacity(viewModel.currentIndex < viewModel.imageFiles.count - 1 ? 1.0 : 0.5)
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.6))
                )
                
                Spacer()
            }
        }
        .padding()
    }
    
    private var slideShowControlsOverlay: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                SlideShowControlsView(
                    isSlideShowRunning: slideShowViewModel.isRunning,
                    currentIndex: viewModel.currentIndex,
                    totalCount: viewModel.imageFiles.count,
                    onPrevious: {
                        Task { @MainActor in
                            await viewModel.navigateToPrevious()
                            slideShowViewModel.restartSlideShowIfRunning()
                        }
                    },
                    onToggleSlideShow: {
                        slideShowViewModel.toggleSlideShow()
                    },
                    onNext: {
                        Task { @MainActor in
                            await viewModel.navigateToNext()
                            slideShowViewModel.restartSlideShowIfRunning()
                        }
                    },
                    onProgressTapped: { index in
                        Task { @MainActor in
                            await viewModel.navigateToIndex(index)
                            slideShowViewModel.restartSlideShowIfRunning()
                        }
                    }
                )
                
                Spacer()
            }
        }
        .padding()
    }
    
    // MARK: - Input Handling
    
    private func handleKeyPress(_ key: KeyEquivalent) -> Void {
        Task { @MainActor in
            switch key {
            case .leftArrow:
                await viewModel.navigateToPrevious()
                slideShowViewModel.restartSlideShowIfRunning()
                
            case .rightArrow:
                await viewModel.navigateToNext()
                slideShowViewModel.restartSlideShowIfRunning()
                
            case .upArrow:
                await viewModel.navigateToPrevious()
                slideShowViewModel.restartSlideShowIfRunning()
                
            case .downArrow:
                await viewModel.navigateToNext()
                slideShowViewModel.restartSlideShowIfRunning()
                
            case .space:
                slideShowViewModel.toggleSlideShow()
                
            default:
                break
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let mockContainer = MockDependencyContainer()
    let viewModel = ImageViewerViewModel(dependencies: mockContainer)
    
    return ImageGalleryView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}