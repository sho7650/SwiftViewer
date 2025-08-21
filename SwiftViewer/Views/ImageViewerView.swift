//
//  ImageViewerView.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import SwiftUI
import AppKit

struct ImageViewerView: View {
    @State private var viewModel: ImageViewerViewModel
    
    init(viewModel: ImageViewerViewModel) {
        self.viewModel = viewModel
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
            }
        }
        .onKeyPress { keyPress in
            handleKeyPress(keyPress.key)
            return .handled
        }
        .focusable()
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
                        .opacity(viewModel.canNavigatePrevious ? 1.0 : 0.5)
                    Text("→ Next")
                        .opacity(viewModel.canNavigateNext ? 1.0 : 0.5)
                    Text("Esc Folder Selection")
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
    
    // MARK: - Input Handling
    
    private func handleKeyPress(_ key: KeyEquivalent) -> Void {
        Task { @MainActor in
            switch key {
            case .leftArrow:
                await viewModel.navigateToPrevious()
                
            case .rightArrow:
                await viewModel.navigateToNext()
                
            case .upArrow:
                await viewModel.navigateToPrevious()
                
            case .downArrow:
                await viewModel.navigateToNext()
                
            case .escape:
                // This will be handled by parent view for navigation back to folder selection
                break
                
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
    
    return ImageViewerView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}