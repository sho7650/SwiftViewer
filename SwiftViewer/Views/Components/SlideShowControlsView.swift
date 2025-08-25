//
//  SlideShowControlsView.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import SwiftUI

struct SlideShowControlsView: View {
    let isSlideShowRunning: Bool
    let currentIndex: Int
    let totalCount: Int
    let isRepeatEnabled: Bool
    let isLeftKeyPressed: Bool
    let isSpaceKeyPressed: Bool
    let isRightKeyPressed: Bool
    let onPrevious: () -> Void
    let onToggleSlideShow: () -> Void
    let onNext: () -> Void
    let onToggleRepeat: () -> Void
    let onProgressTapped: ((Int) -> Void)?
    
    init(
        isSlideShowRunning: Bool,
        currentIndex: Int,
        totalCount: Int,
        isRepeatEnabled: Bool = false,
        isLeftKeyPressed: Bool = false,
        isSpaceKeyPressed: Bool = false,
        isRightKeyPressed: Bool = false,
        onPrevious: @escaping () -> Void,
        onToggleSlideShow: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onToggleRepeat: @escaping () -> Void,
        onProgressTapped: ((Int) -> Void)? = nil
    ) {
        self.isSlideShowRunning = isSlideShowRunning
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.isRepeatEnabled = isRepeatEnabled
        self.isLeftKeyPressed = isLeftKeyPressed
        self.isSpaceKeyPressed = isSpaceKeyPressed
        self.isRightKeyPressed = isRightKeyPressed
        self.onPrevious = onPrevious
        self.onToggleSlideShow = onToggleSlideShow
        self.onNext = onNext
        self.onToggleRepeat = onToggleRepeat
        self.onProgressTapped = onProgressTapped
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            CustomProgressBar(
                currentIndex: currentIndex,
                totalCount: totalCount,
                onProgressTapped: onProgressTapped
            )
            .frame(width: 200)
            
            // Control buttons
            HStack(spacing: 16) {
                // Previous button
                Button {
                    onPrevious()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(ControlButtonStyle(isKeyPressed: isLeftKeyPressed))
                .disabled(currentIndex == 0 && !isRepeatEnabled)
                
                // Play/Pause button
                Button {
                    onToggleSlideShow()
                } label: {
                    Image(systemName: isSlideShowRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(ControlButtonStyle(isActive: isSlideShowRunning, isKeyPressed: isSpaceKeyPressed))
                
                // Next button
                Button {
                    onNext()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(ControlButtonStyle(isKeyPressed: isRightKeyPressed))
                .disabled(currentIndex >= totalCount - 1 && !isRepeatEnabled)
                
                Divider()
                    .frame(height: 20)
                    .background(Color.white.opacity(0.3))
                
                // Repeat button
                Button {
                    onToggleRepeat()
                } label: {
                    Image(systemName: isRepeatEnabled ? "repeat.circle.fill" : "repeat")
                        .foregroundColor(isRepeatEnabled ? .blue : .white)
                }
                .buttonStyle(ControlButtonStyle(isActive: isRepeatEnabled))
                .help("Toggle Repeat (⌘R)")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    VStack(spacing: 40) {
        // Running slideshow with repeat
        SlideShowControlsView(
            isSlideShowRunning: true,
            currentIndex: 6,
            totalCount: 50,
            isRepeatEnabled: true,
            onPrevious: { Logger.shared.debug("Preview: Previous button tapped") },
            onToggleSlideShow: { Logger.shared.debug("Preview: Toggle slideshow") },
            onNext: { Logger.shared.debug("Preview: Next button tapped") },
            onToggleRepeat: { Logger.shared.debug("Preview: Toggle repeat") }
        )
        
        // Paused slideshow without repeat
        SlideShowControlsView(
            isSlideShowRunning: false,
            currentIndex: 24,
            totalCount: 25,
            isRepeatEnabled: false,
            onPrevious: { Logger.shared.debug("Preview: Previous button tapped") },
            onToggleSlideShow: { Logger.shared.debug("Preview: Toggle slideshow") },
            onNext: { Logger.shared.debug("Preview: Next button tapped") },
            onToggleRepeat: { Logger.shared.debug("Preview: Toggle repeat") }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}