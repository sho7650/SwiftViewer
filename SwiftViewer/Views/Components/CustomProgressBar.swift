//
//  CustomProgressBar.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import SwiftUI

struct CustomProgressBar: View {
    let currentIndex: Int
    let totalCount: Int
    let onProgressTapped: ((Int) -> Void)?
    
    init(currentIndex: Int, totalCount: Int, onProgressTapped: ((Int) -> Void)? = nil) {
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.onProgressTapped = onProgressTapped
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Image count label
            Text("\(currentIndex + 1) / \(totalCount)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: progressWidth(geometry.size.width), height: 8)
                        .animation(.fromSettings(.ui), value: currentIndex)
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    if let onProgressTapped = onProgressTapped {
                        let tappedIndex = Int((location.x / geometry.size.width) * Double(totalCount))
                        let clampedIndex = max(0, min(totalCount - 1, tappedIndex))
                        onProgressTapped(clampedIndex)
                    }
                }
            }
            .frame(height: 8)
        }
    }
    
    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard totalCount > 0 else { return 0 }
        let progress = Double(currentIndex + 1) / Double(totalCount)
        return totalWidth * progress
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomProgressBar(currentIndex: 6, totalCount: 50)
        CustomProgressBar(currentIndex: 0, totalCount: 10)
        CustomProgressBar(currentIndex: 24, totalCount: 25)
    }
    .frame(width: 200)
    .padding()
    .background(Color.black)
}