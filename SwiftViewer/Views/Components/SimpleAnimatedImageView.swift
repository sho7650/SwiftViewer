import SwiftUI
import Foundation
import ImageIO

// MARK: - Animation Frame Structure
private struct AnimationFrame {
    let image: NSImage
    let duration: TimeInterval
}

// MARK: - Simple Animated Image View
struct SimpleAnimatedImageView: View {
    let url: URL
    @State private var frames: [AnimationFrame] = []
    @State private var currentFrameIndex: Int = 0
    @State private var timer: Timer?
    @State private var isPlaying: Bool = true
    
    var body: some View {
        Group {
            if !frames.isEmpty {
                Image(nsImage: frames[currentFrameIndex].image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .animation(.none, value: currentFrameIndex) // Disable SwiftUI animations
            } else {
                // Fallback for non-animated images
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
            }
        }
        .onAppear {
            loadGIFFrames()
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    // MARK: - GIF Frame Loading
    private func loadGIFFrames() {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return
        }
        
        let frameCount = CGImageSourceGetCount(imageSource)
        guard frameCount > 1 else {
            // Not an animated GIF, let AsyncImage handle it
            return
        }
        
        var loadedFrames: [AnimationFrame] = []
        
        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else {
                continue
            }
            
            let nsImage = NSImage(cgImage: cgImage, size: .zero)
            let duration = getFrameDuration(from: imageSource, at: i)
            
            loadedFrames.append(AnimationFrame(image: nsImage, duration: duration))
        }
        
        self.frames = loadedFrames
    }
    
    // MARK: - Frame Duration Calculation (SwiftPhotos Pattern)
    private func getFrameDuration(from imageSource: CGImageSource, at index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as? [String: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
            return 0.1 // Default 100ms
        }
        
        // Try unclampedDelayTime first, fall back to delayTime
        if let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double,
           unclampedDelay > 0 {
            return unclampedDelay
        }
        
        if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double,
           delayTime > 0 {
            return delayTime
        }
        
        // Default to 100ms if no delay time is specified
        return 0.1
    }
    
    // MARK: - Timer Management (Frame-Specific Timing)
    private func startAnimation() {
        guard !frames.isEmpty, isPlaying else { return }
        
        scheduleNextFrame()
    }
    
    private func scheduleNextFrame() {
        guard !frames.isEmpty, isPlaying else { return }
        
        let currentFrame = frames[currentFrameIndex]
        
        timer = Timer.scheduledTimer(withTimeInterval: currentFrame.duration, repeats: false) { _ in
            advanceToNextFrame()
        }
    }
    
    private func advanceToNextFrame() {
        guard !frames.isEmpty else { return }
        
        currentFrameIndex = (currentFrameIndex + 1) % frames.count
        
        if isPlaying {
            scheduleNextFrame()
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Playback Controls
    func pause() {
        isPlaying = false
        stopAnimation()
    }
    
    func resume() {
        isPlaying = true
        startAnimation()
    }
    
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }
}

// MARK: - Preview
#Preview {
    SimpleAnimatedImageView(url: URL(fileURLWithPath: "/path/to/sample.gif"))
        .frame(width: 400, height: 300)
}