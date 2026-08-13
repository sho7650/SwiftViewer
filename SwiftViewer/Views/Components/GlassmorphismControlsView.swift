//
//  GlassmorphismControlsView.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/31.
//

import SwiftUI

/// Shared dimensions for the slideshow control bar and its progress scrubber.
private enum Metrics {
    static let stackSpacing: CGFloat = 12
    static let controlSpacing: CGFloat = 20
    static let horizontalPadding: CGFloat = 24
    static let verticalPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 16

    static let buttonSize: CGFloat = 40
    static let iconSize: CGFloat = 18
    static let repeatIconSize: CGFloat = 16
    static let keyPressScale: CGFloat = 0.95
    static let disabledOpacity: Double = 0.35

    static let barSpacing: CGFloat = 6
    static let barHeight: CGFloat = 4
    /// The bar is drawn thin but grabbed through a taller transparent strip.
    static let barHitHeight: CGFloat = 24
    static let counterHorizontalPadding: CGFloat = 8
    static let counterVerticalPadding: CGFloat = 2
}

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
    
    /// Shared by `.disabled` and the dimming opacity so the two never disagree.
    private var isPreviousDisabled: Bool { currentIndex <= 0 }
    private var isNextDisabled: Bool { currentIndex >= totalCount - 1 }

    var body: some View {
        VStack(spacing: Metrics.stackSpacing) {
            // Progress bar with glassmorphism styling
            GlassProgressBar(
                currentIndex: currentIndex,
                totalCount: totalCount,
                onTapped: onProgressTapped
            )

            // Control buttons with glass effects
            GlassEffectContainer(spacing: Metrics.controlSpacing) {
                HStack(spacing: Metrics.controlSpacing) {
                    // Previous button
                    Button(action: onPrevious) {
                        controlIcon("chevron.left")
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .disabled(isPreviousDisabled)
                    .opacity(isPreviousDisabled ? Metrics.disabledOpacity : 1.0)
                    .scaleEffect(isLeftKeyPressed ? Metrics.keyPressScale : 1.0)

                    // Play/Pause button — the primary action, so it reads a step louder
                    Button(action: onToggleSlideShow) {
                        controlIcon(isSlideShowRunning ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                    .scaleEffect(isSpaceKeyPressed ? Metrics.keyPressScale : 1.0)

                    // Next button
                    Button(action: onNext) {
                        controlIcon("chevron.right")
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .disabled(isNextDisabled)
                    .opacity(isNextDisabled ? Metrics.disabledOpacity : 1.0)
                    .scaleEffect(isRightKeyPressed ? Metrics.keyPressScale : 1.0)

                    // Repeat button
                    Button(action: onToggleRepeat) {
                        controlIcon("repeat", size: Metrics.repeatIconSize)
                            .foregroundStyle(isRepeatEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                }
            }
        }
        .padding(.horizontal, Metrics.horizontalPadding)
        .padding(.vertical, Metrics.verticalPadding)
        .glassEffect(.regular, in: .rect(cornerRadius: Metrics.cornerRadius))
        .animation(.fromSettings(.feedback), value: isLeftKeyPressed)
        .animation(.fromSettings(.feedback), value: isSpaceKeyPressed)
        .animation(.fromSettings(.feedback), value: isRightKeyPressed)
    }

    /// Gives every control the same tap target, so `.glass` and `.glassProminent` size alike.
    private func controlIcon(_ systemName: String, size: CGFloat = Metrics.iconSize) -> some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .medium))
            .frame(width: Metrics.buttonSize, height: Metrics.buttonSize)
    }
}

struct GlassProgressBar: View {
    let currentIndex: Int
    let totalCount: Int
    let onTapped: (Int) -> Void

    /// Index under the thumb mid-drag. `nil` whenever the bar is not being scrubbed.
    @State private var scrubIndex: Int?

    var progress: Double {
        displayProgress(scrubbing: nil)
    }

    /// The target index for a tap at the given horizontal fraction (0...1) of the bar.
    func targetIndex(forFraction fraction: Double) -> Int {
        guard totalCount > 1 else { return 0 }
        let index = Int(fraction * Double(totalCount - 1))
        return max(0, min(index, totalCount - 1))
    }

    /// Converts a gesture location into a 0...1 fraction of the bar's width.
    func fraction(forX x: CGFloat, width: CGFloat) -> Double {
        // GeometryReader reports a zero width on the first layout pass.
        guard width > 0 else { return 0.0 }
        return Double(x / width)
    }

    /// The index the bar should render: the thumb position while scrubbing, otherwise the live index.
    func displayIndex(scrubbing scrubIndex: Int?) -> Int {
        scrubIndex ?? currentIndex
    }

    /// Progress for `displayIndex`, so the fill tracks the thumb before navigation commits.
    func displayProgress(scrubbing scrubIndex: Int?) -> Double {
        // A single-image folder (totalCount == 1) has a zero divisor; clamp to avoid NaN.
        guard totalCount > 1 else { return 0.0 }
        return Double(displayIndex(scrubbing: scrubIndex)) / Double(totalCount - 1)
    }

    var body: some View {
        VStack(spacing: Metrics.barSpacing) {
            // Progress visualization
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(.clear)
                        .frame(height: Metrics.barHeight)
                        .glassEffect(in: .capsule)

                    // Progress fill (thin bar — a solid tint reads better than glass here)
                    Capsule()
                        .fill(.tint)
                        .frame(
                            width: geometry.size.width * displayProgress(scrubbing: scrubIndex),
                            height: Metrics.barHeight
                        )
                }
                // Fill the taller strip so the thin bar stays centred but easy to grab.
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                // minimumDistance 0 makes this handle plain clicks as well as drags,
                // so there is no separate tap gesture to double-fire.
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Preview only — navigating here would thrash the image
                            // pipeline on a 10,000-image folder.
                            scrubIndex = targetIndex(
                                forFraction: fraction(forX: value.location.x, width: geometry.size.width)
                            )
                        }
                        .onEnded { value in
                            let index = targetIndex(
                                forFraction: fraction(forX: value.location.x, width: geometry.size.width)
                            )
                            scrubIndex = nil
                            onTapped(index)
                        }
                )
            }
            .frame(height: Metrics.barHitHeight)

            // Index indicator
            Text("\(displayIndex(scrubbing: scrubIndex) + 1) / \(totalCount)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.primary)
                .padding(.horizontal, Metrics.counterHorizontalPadding)
                .padding(.vertical, Metrics.counterVerticalPadding)
                .glassEffect(.regular, in: .capsule)
        }
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
