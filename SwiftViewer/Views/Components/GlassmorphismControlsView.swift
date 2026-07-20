//
//  GlassmorphismControlsView.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/31.
//

import SwiftUI

struct GlassmorphismControlsView: View {
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
    let onProgressTapped: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar with glassmorphism styling
            GlassProgressBar(
                currentIndex: currentIndex,
                totalCount: totalCount,
                onTapped: onProgressTapped
            )
            
            // Control buttons with glass effects
            GlassEffectContainer(spacing: 20) {
                HStack(spacing: 20) {
                    // Previous button
                    Button(action: onPrevious) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .scaleEffect(isLeftKeyPressed ? 0.95 : 1.0)
                    .disabled(currentIndex <= 0)

                    // Play/Pause button
                    Button(action: onToggleSlideShow) {
                        Image(systemName: isSlideShowRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .scaleEffect(isSpaceKeyPressed ? 0.95 : 1.0)

                    // Next button
                    Button(action: onNext) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .scaleEffect(isRightKeyPressed ? 0.95 : 1.0)
                    .disabled(currentIndex >= totalCount - 1)

                    // Repeat button
                    Button(action: onToggleRepeat) {
                        Image(systemName: "repeat")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isRepeatEnabled ? .accentColor : .white)
                    }
                    .buttonStyle(GlassButtonStyle())
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .animation(.fromSettings(.feedback), value: isLeftKeyPressed)
        .animation(.fromSettings(.feedback), value: isSpaceKeyPressed)
        .animation(.fromSettings(.feedback), value: isRightKeyPressed)
    }
}

struct GlassProgressBar: View {
    let currentIndex: Int
    let totalCount: Int
    let onTapped: (Int) -> Void
    
    var progress: Double {
        // A single-image folder (totalCount == 1) has a zero divisor; clamp to avoid NaN.
        guard totalCount > 1 else { return 0.0 }
        return Double(currentIndex) / Double(totalCount - 1)
    }

    /// The target index for a tap at the given horizontal fraction (0...1) of the bar.
    func targetIndex(forFraction fraction: Double) -> Int {
        guard totalCount > 1 else { return 0 }
        let index = Int(fraction * Double(totalCount - 1))
        return max(0, min(index, totalCount - 1))
    }

    var body: some View {
        VStack(spacing: 6) {
            // Progress visualization
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(.clear)
                        .frame(height: 4)
                        .glassEffect(in: .capsule)

                    // Progress fill (thin bar — a plain gradient reads better than glass here)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.8), .cyan.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let fraction = geometry.size.width > 0 ? location.x / geometry.size.width : 0
                    onTapped(targetIndex(forFraction: fraction))
                }
            }
            .frame(height: 4)

            // Index indicator
            Text("\(currentIndex + 1) / \(totalCount)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .glassEffect(.regular, in: .capsule)
        }
    }
}

struct GlassButtonStyle: ButtonStyle {
    let radius: CGFloat
    let material: Material
    let shadowRadius: CGFloat
    
    init(
        radius: CGFloat = 12,
        material: Material = .ultraThinMaterial,
        shadowRadius: CGFloat = 6
    ) {
        self.radius = radius
        self.material = material
        self.shadowRadius = shadowRadius
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 40, height: 40)
            .glassEffect(.regular.interactive(), in: .circle)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.fromSettings(.feedback), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Running Slideshow") {
    VStack(spacing: 40) {
        // Running slideshow with repeat enabled
        GlassmorphismControlsView(
            isSlideShowRunning: true,
            currentIndex: 3,
            totalCount: 10,
            isRepeatEnabled: true,
            isLeftKeyPressed: false,
            isSpaceKeyPressed: false,
            isRightKeyPressed: false,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { },
            onProgressTapped: { _ in }
        )

        // Paused slideshow with key press feedback
        GlassmorphismControlsView(
            isSlideShowRunning: false,
            currentIndex: 0,
            totalCount: 5,
            isRepeatEnabled: false,
            isLeftKeyPressed: true,
            isSpaceKeyPressed: false,
            isRightKeyPressed: false,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { },
            onProgressTapped: { _ in }
        )
    }
    .padding()
    .background(Color.black.opacity(0.8))
}

#Preview("Different States") {
    VStack(spacing: 40) {
        // Space key pressed state
        GlassmorphismControlsView(
            isSlideShowRunning: true,
            currentIndex: 4,
            totalCount: 8,
            isRepeatEnabled: true,
            isLeftKeyPressed: false,
            isSpaceKeyPressed: true,
            isRightKeyPressed: false,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { },
            onProgressTapped: { _ in }
        )
        
        // Right key pressed state
        GlassmorphismControlsView(
            isSlideShowRunning: false,
            currentIndex: 7,
            totalCount: 8,
            isRepeatEnabled: false,
            isLeftKeyPressed: false,
            isSpaceKeyPressed: false,
            isRightKeyPressed: true,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { },
            onProgressTapped: { _ in }
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
