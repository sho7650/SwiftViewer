//
//  AnimatedGIFView.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/27.
//

import SwiftUI

/// Context7-compliant SwiftUI view for displaying animated GIFs
/// Uses CustomAnimation pattern for optimal performance and integration
struct AnimatedGIFView: View {
    
    // MARK: - Properties
    
    @ObservedObject private var controller: GIFAnimationController
    @State private var currentFrameImage: NSImage?
    @State private var animationPhase: AnimationPhase = .inactive
    
    // MARK: - Animation Phases
    
    enum AnimationPhase: CaseIterable {
        case inactive
        case playing
        case paused
        case stopped
    }
    
    // MARK: - Initialization
    
    init(controller: GIFAnimationController) {
        self.controller = controller
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let frameImage = currentFrameImage {
                Image(nsImage: frameImage)
                    .resizable()
                    .animation(.easeInOut(duration: 0.1), value: currentFrameImage)
            } else {
                // Fallback to first frame if no current frame
                if let firstFrame = controller.animatedImage.frame(at: 0) {
                    Image(nsImage: firstFrame)
                        .resizable()
                } else {
                    Rectangle()
                        .fill(Color.clear)
                }
            }
        }
        .onAppear {
            startObservingFrameChanges()
            updateCurrentFrame()
        }
        .onDisappear {
            controller.stop()
        }
        .onChange(of: controller.currentFrameIndex) { _, _ in
            updateCurrentFrame()
        }
        .onChange(of: controller.isPlaying) { _, isPlaying in
            animationPhase = isPlaying ? .playing : .stopped
        }
        // Context7 pattern: Use phaseAnimator for state-driven animations
        .phaseAnimator(AnimationPhase.allCases) { content, phase in
            content
                .opacity(phase == .inactive ? 0.8 : 1.0)
                .scaleEffect(phase == .playing ? 1.0 : 0.98)
        } animation: { phase in
            switch phase {
            case .inactive:
                .easeIn(duration: 0.2)
            case .playing:
                .easeOut(duration: 0.3)
            case .paused:
                .easeInOut(duration: 0.2)
            case .stopped:
                .easeInOut(duration: 0.25)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startObservingFrameChanges() {
        // Start animation if not already playing
        if !controller.isPlaying {
            controller.play()
            animationPhase = .playing
        }
    }
    
    private func updateCurrentFrame() {
        currentFrameImage = controller.currentImage
    }
}

// MARK: - Context7 Animation Extensions

extension AnimatedGIFView {
    
    /// Context7-compliant keyframe animation for smooth GIF transitions
    /// This provides additional animation polish when transitioning between states
    @ViewBuilder
    private func keyframeTransition<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        content()
            .keyframeAnimator(
                initialValue: AnimationValues(),
                trigger: controller.currentFrameIndex
            ) { content, value in
                content
                    .opacity(value.opacity)
                    .scaleEffect(value.scale)
                    .blur(radius: value.blur)
            } keyframes: { _ in
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.95, duration: 0.05)
                    LinearKeyframe(1.0, duration: 0.05)
                }
                KeyframeTrack(\.scale) {
                    LinearKeyframe(0.999, duration: 0.05)
                    LinearKeyframe(1.0, duration: 0.05)
                }
                KeyframeTrack(\.blur) {
                    LinearKeyframe(0.1, duration: 0.05)
                    LinearKeyframe(0.0, duration: 0.05)
                }
            }
    }
    
    /// Animation values for keyframe transitions
    private struct AnimationValues {
        var opacity: Double = 1.0
        var scale: Double = 1.0
        var blur: Double = 0.0
    }
}

// MARK: - Preview

#if DEBUG
struct AnimatedGIFView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock controller for preview
        let testFrame = NSImage(size: NSSize(width: 200, height: 200))
        let testAnimatedImage = AnimatedImage(
            frames: [testFrame, testFrame],
            frameDurations: [0.5, 0.5],
            loopCount: 0,
            totalDuration: 1.0
        )
        
        if let mockController = try? GIFAnimationController(animatedImage: testAnimatedImage) {
            AnimatedGIFView(controller: mockController)
                .frame(width: 300, height: 200)
                .background(Color.black)
        } else {
            Rectangle()
                .fill(Color.red)
                .frame(width: 300, height: 200)
        }
    }
}
#endif