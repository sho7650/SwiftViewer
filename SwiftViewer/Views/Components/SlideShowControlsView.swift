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
    let onPrevious: () -> Void
    let onToggleSlideShow: () -> Void
    let onNext: () -> Void
    let onProgressTapped: ((Int) -> Void)?
    
    init(
        isSlideShowRunning: Bool,
        currentIndex: Int,
        totalCount: Int,
        onPrevious: @escaping () -> Void,
        onToggleSlideShow: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onProgressTapped: ((Int) -> Void)? = nil
    ) {
        self.isSlideShowRunning = isSlideShowRunning
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.onPrevious = onPrevious
        self.onToggleSlideShow = onToggleSlideShow
        self.onNext = onNext
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
                .buttonStyle(ControlButtonStyle())
                .disabled(currentIndex == 0)
                
                // Play/Pause button
                Button {
                    onToggleSlideShow()
                } label: {
                    Image(systemName: isSlideShowRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(ControlButtonStyle(isActive: isSlideShowRunning))
                
                // Next button
                Button {
                    onNext()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(ControlButtonStyle())
                .disabled(currentIndex >= totalCount - 1)
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
        // Running slideshow
        SlideShowControlsView(
            isSlideShowRunning: true,
            currentIndex: 6,
            totalCount: 50,
            onPrevious: { print("Previous") },
            onToggleSlideShow: { print("Toggle") },
            onNext: { print("Next") }
        )
        
        // Paused slideshow
        SlideShowControlsView(
            isSlideShowRunning: false,
            currentIndex: 24,
            totalCount: 25,
            onPrevious: { print("Previous") },
            onToggleSlideShow: { print("Toggle") },
            onNext: { print("Next") }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}