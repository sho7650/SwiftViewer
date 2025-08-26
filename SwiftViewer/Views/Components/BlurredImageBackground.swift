//
//  BlurredImageBackground.swift
//  SwiftViewer
//
//  Created by SwiftViewer on 2025-08-26.
//

import SwiftUI

/// A SwiftUI view that displays a blurred version of an image as a background
/// Used to fill non-image areas in the image gallery with a blurred representation
struct BlurredImageBackground: View {
    
    // MARK: - Properties
    
    /// The image to blur and display as background, nil shows transparent background
    let image: NSImage?
    
    /// Blur radius - higher values create more diffuse blur effect
    let blurRadius: CGFloat
    
    /// Background opacity - controls how prominent the blur effect is
    let backgroundOpacity: Double
    
    // MARK: - Initialization
    
    init(
        image: NSImage?,
        blurRadius: CGFloat = 20.0,
        backgroundOpacity: Double = 0.3
    ) {
        self.image = image
        self.blurRadius = blurRadius
        self.backgroundOpacity = backgroundOpacity
    }
    
    // MARK: - Body
    
    var body: some View {
        if let image = image {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: blurRadius)
                .opacity(backgroundOpacity)
                .clipped()
                .drawingGroup() // Optimize rendering performance for blur effects
                .allowsHitTesting(false) // Background shouldn't intercept touch events
        } else {
            Color.clear
        }
    }
}

// MARK: - Preview

#Preview("With Image") {
    let testImage = NSImage(size: NSSize(width: 300, height: 200))
    testImage.lockFocus()
    
    // Create a colorful gradient for preview
    let gradient = NSGradient(colors: [.blue, .purple, .red])
    gradient?.draw(in: NSRect(origin: .zero, size: NSSize(width: 300, height: 200)), angle: 45)
    
    testImage.unlockFocus()
    
    return BlurredImageBackground(image: testImage)
        .frame(width: 400, height: 300)
        .background(Color.black)
}

#Preview("Without Image") {
    BlurredImageBackground(image: nil)
        .frame(width: 400, height: 300)
        .background(Color.black)
}