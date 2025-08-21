//
//  ControlButtonStyle.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import SwiftUI

struct ControlButtonStyle: ButtonStyle {
    let isActive: Bool
    let isKeyPressed: Bool
    
    init(isActive: Bool = false, isKeyPressed: Bool = false) {
        self.isActive = isActive
        self.isKeyPressed = isKeyPressed
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(foregroundColor(configuration.isPressed))
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor(configuration.isPressed))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func foregroundColor(_ isPressed: Bool) -> Color {
        if isPressed || isKeyPressed {
            return .white.opacity(0.8)
        } else if isActive {
            return .blue
        } else {
            return .white
        }
    }
    
    private func backgroundColor(_ isPressed: Bool) -> Color {
        if isPressed || isKeyPressed {
            return .black.opacity(0.8)
        } else {
            return .black.opacity(0.6)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Button("▶") {
            // Preview action
        }
        .buttonStyle(ControlButtonStyle())
        
        Button("⏸") {
            // Preview action
        }
        .buttonStyle(ControlButtonStyle(isActive: true))
        
        Button("◀︎") {
            // Preview action
        }
        .buttonStyle(ControlButtonStyle())
    }
    .padding()
    .background(Color.black)
}