//
//  SettingsView.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import SwiftUI

extension Notification.Name {
    static let slideShowIntervalChanged = Notification.Name("slideShowIntervalChanged")
}

struct SettingsView: View {
    @State private var settingsManager: SettingsManagerProtocol
    @State private var slideShowInterval: Double
    @Environment(\.dismiss) private var dismiss
    
    init(settingsManager: SettingsManagerProtocol = DependencyContainer.shared.settingsManager) {
        self.settingsManager = settingsManager
        self._slideShowInterval = State(initialValue: settingsManager.slideShowInterval)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom, 8)
            
            Divider()
            
            // Slideshow Settings Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Slideshow")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Interval:")
                            .frame(width: 80, alignment: .leading)
                        
                        Slider(value: $slideShowInterval, in: 0.5...60.0, step: 0.5) {
                            Text("Slideshow Interval")
                        }
                        .frame(maxWidth: 200)
                        
                        Text(intervalDisplayText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                    
                    Text("Time between images during slideshow (0.5 - 60 seconds)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 80)
                }
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            // Save button and info
            HStack {
                Text("Changes are saved automatically")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(24)
        .frame(width: 500, height: 300)
        .onChange(of: slideShowInterval) { _, newValue in
            settingsManager.slideShowInterval = newValue
            // Notify any active slideshow to update its interval
            NotificationCenter.default.post(name: .slideShowIntervalChanged, object: nil)
        }
        .onAppear {
            slideShowInterval = settingsManager.slideShowInterval
        }
    }
    
    private var intervalDisplayText: String {
        if slideShowInterval < 1.0 {
            return String(format: "%.1fs", slideShowInterval)
        } else if slideShowInterval.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0fs", slideShowInterval)
        } else {
            return String(format: "%.1fs", slideShowInterval)
        }
    }
}

#Preview {
    SettingsView(settingsManager: MockSettingsManager())
}