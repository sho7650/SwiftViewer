//
//  ImageGalleryView.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import SwiftUI
import AppKit

struct ImageGalleryView: View {
    let viewModel: ImageGalleryViewModel
    @State private var slideShowViewModel: SlideShowViewModel
    @State private var autoHideManager: AutoHideControlsManager
    @FocusState private var isFocused: Bool
    
    // Keyboard press states for visual feedback
    @State private var isLeftKeyPressed = false
    @State private var isRightKeyPressed = false
    @State private var isSpaceKeyPressed = false
    
    /// Check if debug overlay is enabled from UserDefaults
    private var isDebugModeEnabled: Bool {
        UserDefaults.standard.bool(forKey: "debugLoggingEnabled")
    }
    
    init(viewModel: ImageGalleryViewModel) {
        self.viewModel = viewModel
        let dependencies = DependencyContainer.shared
        let slideShowVM = SlideShowViewModel(
            slideShowService: dependencies.slideShowService,
            imageNavigator: viewModel,
            settingsManager: dependencies.settingsManager
        )
        self._slideShowViewModel = State(initialValue: slideShowVM)
        self._autoHideManager = State(initialValue: AutoHideControlsManager(
            slideShowViewModel: slideShowVM,
            imageGalleryViewModel: viewModel
        ))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
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
                        .opacity(autoHideManager.areControlsVisible ? 1.0 : 0.0)
                        .allowsHitTesting(autoHideManager.areControlsVisible)
                }
            }
            .background {
                // Background - Blurred image or solid black (isolated from main content layout)
                if let currentImage = viewModel.currentImage {
                    BlurredImageBackground(image: currentImage)
                } else {
                    Color.black
                }
            }
        }
        .focusable()
        .focused($isFocused)
        .onContinuousHover { phase in
            switch phase {
            case .active:
                autoHideManager.registerActivity()
            case .ended:
                // Don't hide immediately when mouse leaves, let timer handle it
                break
            }
        }
        .onAppear {
            isFocused = true
            // Start with controls visible and reset timer
            autoHideManager.showControlsAndResetTimer()
        }
        .onKeyPress { keyPress in
            handleKeyPress(keyPress.key)
            return .handled
        }
        .onDisappear {
            slideShowViewModel.stopSlideShow()
            autoHideManager.cleanupTimer()
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
        Group {
            if let currentImageFile = viewModel.currentImageFile, currentImageFile.isAnimated {
                SimpleAnimatedImageView(url: currentImageFile.url)
                    .id(currentImageFile.url.absoluteString)
            } else {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
            }
        }
    }
    
    private var imageInfoOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                // File info - only shown in debug mode
                if isDebugModeEnabled {
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
            }
            
            Spacer()
            
            // Navigation hints - only shown in debug mode
            if isDebugModeEnabled {
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
                    isRepeatEnabled: slideShowViewModel.isRepeatEnabled,
                    isLeftKeyPressed: isLeftKeyPressed,
                    isSpaceKeyPressed: isSpaceKeyPressed,
                    isRightKeyPressed: isRightKeyPressed,
                    onPrevious: {
                        Task { @MainActor in
                            await performUserAction {
                                await viewModel.navigateToPrevious()
                                slideShowViewModel.restartSlideShowIfRunning()
                            }
                        }
                    },
                    onToggleSlideShow: {
                        performUserAction {
                            slideShowViewModel.toggleSlideShow()
                        }
                    },
                    onNext: {
                        Task { @MainActor in
                            await performUserAction {
                                await viewModel.navigateToNext()
                                slideShowViewModel.restartSlideShowIfRunning()
                            }
                        }
                    },
                    onToggleRepeat: {
                        performUserAction {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                slideShowViewModel.toggleRepeatMode()
                            }
                            NotificationCenter.default.post(name: .repeatModeChanged, object: slideShowViewModel.isRepeatEnabled)
                        }
                    },
                    onProgressTapped: { index in
                        Task { @MainActor in
                            await performUserAction {
                                await viewModel.navigateToIndex(index)
                                slideShowViewModel.restartSlideShowIfRunning()
                            }
                        }
                    }
                )
                
                Spacer()
            }
        }
        .padding()
    }
    
    
    // MARK: - User Action Handling
    
    /// Executes a user action while automatically registering activity for auto-hide controls
    /// - Parameter action: The synchronous action to perform
    private func performUserAction(_ action: @escaping () -> Void) {
        autoHideManager.registerActivity()
        action()
    }
    
    /// Executes an async user action while automatically registering activity for auto-hide controls
    /// - Parameter action: The async action to perform
    /// - Returns: The result of the action
    private func performUserAction<T>(_ action: @escaping () async throws -> T) async rethrows -> T {
        autoHideManager.registerActivity()
        return try await action()
    }
    
    // MARK: - Input Handling
    
    private func handleKeyPress(_ key: KeyEquivalent) -> Void {
        // Show controls and reset timer on any keyboard activity
        autoHideManager.registerActivity()
        
        Task { @MainActor in
            switch key {
            case .leftArrow, .upArrow:
                // Show visual feedback
                withAnimation(.easeInOut(duration: 0.1)) {
                    isLeftKeyPressed = true
                }
                
                await viewModel.navigateToPrevious()
                slideShowViewModel.restartSlideShowIfRunning()
                
                // Reset visual feedback
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isLeftKeyPressed = false
                    }
                }
                
            case .rightArrow, .downArrow:
                // Show visual feedback
                withAnimation(.easeInOut(duration: 0.1)) {
                    isRightKeyPressed = true
                }
                
                await viewModel.navigateToNext()
                slideShowViewModel.restartSlideShowIfRunning()
                
                // Reset visual feedback
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isRightKeyPressed = false
                    }
                }
                
            case .space:
                // Show visual feedback
                withAnimation(.easeInOut(duration: 0.1)) {
                    isSpaceKeyPressed = true
                }
                
                slideShowViewModel.toggleSlideShow()
                
                // Reset visual feedback
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isSpaceKeyPressed = false
                    }
                }
                
            default:
                break
            }
        }
    }
}

// MARK: - Preview

#Preview("Dark Mode - Empty State") {
    let mockContainer = MockDependencyContainer()
    let viewModel = ImageGalleryViewModel(dependencies: mockContainer)
    
    return ImageGalleryView(viewModel: viewModel)
        .preferredColorScheme(.dark)
        .frame(width: 800, height: 600)
}

#Preview("Light Mode - With Images") {
    let mockContainer = MockDependencyContainer()
    let viewModel = ImageGalleryViewModel(dependencies: mockContainer)
    
    // Simulate loaded images
    Task { @MainActor in
        viewModel.imageFiles = [
            ImageFile(url: URL(fileURLWithPath: "/image1.jpg"), fileName: "image1.jpg", fileSize: 1024000, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/image2.jpg"), fileName: "image2.jpg", fileSize: 2048000, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/image3.jpg"), fileName: "image3.jpg", fileSize: 3072000, createdDate: Date())
        ]
        viewModel.currentIndex = 1
    }
    
    return ImageGalleryView(viewModel: viewModel)
        .preferredColorScheme(.light)
        .frame(width: 800, height: 600)
}

#Preview("Slideshow Running") {
    let mockContainer = MockDependencyContainer()
    let viewModel = ImageGalleryViewModel(dependencies: mockContainer)
    
    // Simulate loaded images and running slideshow
    Task { @MainActor in
        viewModel.imageFiles = [
            ImageFile(url: URL(fileURLWithPath: "/photo1.jpg"), fileName: "photo1.jpg", fileSize: 5242880, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/photo2.jpg"), fileName: "photo2.jpg", fileSize: 4194304, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/photo3.jpg"), fileName: "photo3.jpg", fileSize: 6291456, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/photo4.jpg"), fileName: "photo4.jpg", fileSize: 3145728, createdDate: Date()),
            ImageFile(url: URL(fileURLWithPath: "/photo5.jpg"), fileName: "photo5.jpg", fileSize: 7340032, createdDate: Date())
        ]
        viewModel.currentIndex = 2
    }
    
    return ImageGalleryView(viewModel: viewModel)
        .preferredColorScheme(.dark)
        .frame(width: 1024, height: 768)
}

#Preview("Compact View") {
    let mockContainer = MockDependencyContainer()
    let viewModel = ImageGalleryViewModel(dependencies: mockContainer)
    
    return ImageGalleryView(viewModel: viewModel)
        .preferredColorScheme(.dark)
        .frame(width: 400, height: 300)
}

#Preview("Loading State") {
    let mockContainer = MockDependencyContainer()
    let viewModel = ImageGalleryViewModel(dependencies: mockContainer)
    
    // Simulate loading state
    Task { @MainActor in
        viewModel.isLoading = true
    }
    
    return ImageGalleryView(viewModel: viewModel)
        .preferredColorScheme(.dark)
        .frame(width: 600, height: 400)
}

#Preview("Error State") {
    let mockContainer = MockDependencyContainer()
    let viewModel = ImageGalleryViewModel(dependencies: mockContainer)
    
    // Simulate error state
    Task { @MainActor in
        viewModel.errorMessage = "Failed to load images from the selected folder"
    }
    
    return ImageGalleryView(viewModel: viewModel)
        .preferredColorScheme(.dark)
        .frame(width: 600, height: 400)
}