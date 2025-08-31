//
//  GlassmorphismControlsView.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/31.
//

import SwiftUI
import SwiftGlass

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
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .glass(
            radius: 16,
            color: .white,
            material: .ultraThinMaterial,
            gradientOpacity: 0.7,
            shadowColor: .black,
            shadowOpacity: 0.4,
            shadowRadius: 8,
            shadowY: 4
        )
        .animation(.fromSettings(.feedback), value: isLeftKeyPressed)
        .animation(.fromSettings(.feedback), value: isSpaceKeyPressed)
        .animation(.fromSettings(.feedback), value: isRightKeyPressed)
    }
}

struct GlassProgressBar: View {
    let currentIndex: Int
    let totalCount: Int
    let onTapped: (Int) -> Void
    
    private var progress: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(currentIndex) / Double(totalCount - 1)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Progress visualization
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 4)
                        .glass(
                            radius: 2,
                            color: .white,
                            material: .thickMaterial,
                            gradientOpacity: 0.2,
                            shadowOpacity: 0.1
                        )
                    
                    // Progress fill
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.8), .cyan.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .glass(
                            radius: 2,
                            color: .blue,
                            material: .regularMaterial,
                            gradientOpacity: 0.6,
                            shadowColor: .blue,
                            shadowOpacity: 0.4,
                            shadowRadius: 4
                        )
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let tappedProgress = location.x / geometry.size.width
                    let targetIndex = Int(tappedProgress * Double(totalCount - 1))
                    let clampedIndex = max(0, min(targetIndex, totalCount - 1))
                    onTapped(clampedIndex)
                }
            }
            .frame(height: 4)
            
            // Index indicator
            Text("\(currentIndex + 1) / \(totalCount)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .glass(
                    radius: 8,
                    color: .white,
                    material: .ultraThinMaterial,
                    gradientOpacity: 0.3,
                    shadowOpacity: 0.2
                )
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
            .glass(
                radius: radius,
                color: .white,
                material: material,
                gradientOpacity: configuration.isPressed ? 0.6 : 0.3,
                shadowColor: .black,
                shadowOpacity: configuration.isPressed ? 0.1 : 0.2,
                shadowRadius: shadowRadius,
                shadowY: configuration.isPressed ? 2 : 4
            )
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
            onPrevious: { print("Preview: Previous tapped") },
            onToggleSlideShow: { print("Preview: Toggle slideshow") },
            onNext: { print("Preview: Next tapped") },
            onToggleRepeat: { print("Preview: Toggle repeat") },
            onProgressTapped: { index in print("Preview: Progress tapped at \(index)") }
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
            onPrevious: { print("Preview: Previous tapped") },
            onToggleSlideShow: { print("Preview: Toggle slideshow") },
            onNext: { print("Preview: Next tapped") },
            onToggleRepeat: { print("Preview: Toggle repeat") },
            onProgressTapped: { index in print("Preview: Progress tapped at \(index)") }
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
