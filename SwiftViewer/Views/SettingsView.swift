//
//  SettingsView.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import SwiftUI

extension Notification.Name {
    static let slideShowIntervalChanged = Notification.Name("slideShowIntervalChanged")
    static let autoHideDelayChanged = Notification.Name("autoHideDelayChanged")
    static let animationDurationsChanged = Notification.Name("animationDurationsChanged")
    static let blurSettingsChanged = Notification.Name("blurSettingsChanged")
}

struct SettingsView: View {
    @State private var settingsManager: SettingsManagerProtocol
    @State private var slideShowInterval: Double
    @State private var slideShowIntervalIndex: Double
    @State private var autoHideDelay: Double
    @State private var animationDurations: [AnimationType: TimeInterval]
    @State private var blurRadius: Double
    @State private var blurOpacity: Double
    @State private var loggingLevel: LogLevel
    @State private var debugLoggingEnabled: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    init(settingsManager: SettingsManagerProtocol = DependencyContainer.shared.settingsManager) {
        self.settingsManager = settingsManager
        let interval = settingsManager.slideShowInterval
        self._slideShowInterval = State(initialValue: interval)
        self._slideShowIntervalIndex = State(initialValue: Double(SlideshowIntervalHelper.indexForInterval(interval)))
        self._autoHideDelay = State(initialValue: settingsManager.autoHideDelay)
        self._animationDurations = State(initialValue: settingsManager.animationDurations)
        self._blurRadius = State(initialValue: settingsManager.blurRadius)
        self._blurOpacity = State(initialValue: settingsManager.blurOpacity)
        self._loggingLevel = State(initialValue: settingsManager.loggingLevel)
        self._debugLoggingEnabled = State(initialValue: settingsManager.debugLoggingEnabled)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    slideshowSection
                    Divider()
                    
                    visualEffectsSection
                    Divider()
                    
                    controlsSection
                    Divider()
                    
                    debugSection
                }
                .padding(.vertical, 20)
            }
            
            // Footer
            footerSection
        }
        .padding(24)
        .frame(width: 600, height: 500)
        .onAppear {
            loadSettings()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
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
        .padding(.bottom, 16)
    }
    
    // MARK: - Slideshow Section
    
    private var slideshowSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SLIDESHOW")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Slider(value: $slideShowIntervalIndex, in: 0.0...Double(SlideshowIntervalHelper.intervals.count - 1), step: 1.0) {
                        Text("Slideshow Interval")
                    }
                    .frame(maxWidth: 500)
                    .onChange(of: slideShowIntervalIndex) { _, newIndex in
                        let snappedIndex = Int(round(newIndex))
                        let actualInterval = SlideshowIntervalHelper.intervalForIndex(snappedIndex)
                        slideShowInterval = actualInterval
                        settingsManager.slideShowInterval = actualInterval
                        NotificationCenter.default.post(name: .slideShowIntervalChanged, object: nil)
                    }
                    
                    Text(SlideshowIntervalHelper.formatInterval(slideShowInterval))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
                
                Text("Time between images during slideshow (1 - 1800 seconds)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 100)
                
                Toggle("Repeat slideshow", isOn: Binding(
                    get: { settingsManager.repeatEnabled },
                    set: { newValue in
                        settingsManager.repeatEnabled = newValue
                        // Notify SlideShowViewModel of the change
                        NotificationCenter.default.post(name: .repeatModeChanged, object: newValue)
                    }
                ))
            }
        }
    }
    
    // MARK: - Visual Effects Section
    
    private var visualEffectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("VISUAL EFFECTS")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                // Background Blur
                VStack(alignment: .leading, spacing: 8) {
                    Text("Background Blur")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Slider(value: $blurRadius, in: 0.0...50.0, step: 1.0) {
                            Text("Blur Radius")
                        }
                        .frame(maxWidth: 500)
                        .onChange(of: blurRadius) { _, newValue in
                            settingsManager.blurRadius = newValue
                            NotificationCenter.default.post(name: .blurSettingsChanged, object: nil)
                        }
                        
                        Text(String(format: "%.0f", blurRadius))
                            .font(.system(.caption, design: .monospaced))
                            .frame(width: 30, alignment: .trailing)
                    }
                    
                    HStack {
                        Slider(value: $blurOpacity, in: 0.0...1.0, step: 0.1) {
                            Text("Blur Opacity")
                        }
                        .frame(maxWidth: 500)
                        .onChange(of: blurOpacity) { _, newValue in
                            settingsManager.blurOpacity = newValue
                            NotificationCenter.default.post(name: .blurSettingsChanged, object: nil)
                        }
                        
                        Text(String(format: "%.1f", blurOpacity))
                            .font(.system(.caption, design: .monospaced))
                            .frame(width: 30, alignment: .trailing)
                    }
                }
                
                // Animation Speeds
                VStack(alignment: .leading, spacing: 8) {
                    Text("Animation Speed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(AnimationType.allCases, id: \.self) { type in
                        HStack {
                            Slider(
                                value: bindingForAnimationType(type),
                                in: 0.1...1.0,
                                step: 0.1
                            ) {
                                Text("\(type.displayName) Duration")
                            }
                            .frame(maxWidth: 500)
                            
                            Text(String(format: "%.1fs", animationDurations[type] ?? type.defaultDuration))
                                .font(.system(.caption, design: .monospaced))
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CONTROLS")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Slider(value: $autoHideDelay, in: 1.0...60.0, step: 1.0) {
                        Text("Auto-hide Delay")
                    }
                    .frame(maxWidth: 500)
                    .onChange(of: autoHideDelay) { _, newValue in
                        settingsManager.autoHideDelay = newValue
                        NotificationCenter.default.post(name: .autoHideDelayChanged, object: nil)
                    }
                    
                    Text(String(format: "%.1fs", autoHideDelay))
                        .font(.system(.caption, design: .monospaced))
                        .frame(width: 50, alignment: .trailing)
                }
                
                Text("Time before controls automatically hide (1.0 - 60.0 seconds)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 120)
            }
        }
    }
    
    // MARK: - Debug Section
    
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DEBUG")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Logging Level:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Logging Level", selection: $loggingLevel) {
                        Text("Debug").tag(LogLevel.debug)
                        Text("Info").tag(LogLevel.info)
                        Text("Warning").tag(LogLevel.warning)
                        Text("Error").tag(LogLevel.error)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 300)
                    .onChange(of: loggingLevel) { _, newValue in
                        settingsManager.loggingLevel = newValue
                    }
                }
                
                Toggle("Enable debug overlay", isOn: $debugLoggingEnabled)
                    .onChange(of: debugLoggingEnabled) { _, newValue in
                        settingsManager.debugLoggingEnabled = newValue
                    }
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        HStack {
            Text("Changes are saved automatically")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.top, 16)
    }
    
    // MARK: - Helper Methods
    
    private func loadSettings() {
        let interval = settingsManager.slideShowInterval
        slideShowInterval = interval
        slideShowIntervalIndex = Double(SlideshowIntervalHelper.indexForInterval(interval))
        autoHideDelay = settingsManager.autoHideDelay
        animationDurations = settingsManager.animationDurations
        blurRadius = settingsManager.blurRadius
        blurOpacity = settingsManager.blurOpacity
        loggingLevel = settingsManager.loggingLevel
        debugLoggingEnabled = settingsManager.debugLoggingEnabled
    }
    
    private func bindingForAnimationType(_ type: AnimationType) -> Binding<Double> {
        Binding(
            get: { animationDurations[type] ?? type.defaultDuration },
            set: { newValue in
                animationDurations[type] = newValue
                settingsManager.animationDurations = animationDurations
                NotificationCenter.default.post(name: .animationDurationsChanged, object: nil)
            }
        )
    }
}

// MARK: - Slideshow Presets View

struct SlideShowPresetsView: View {
    @Binding var selectedInterval: Double
    let intervals: [TimeInterval]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(intervals, id: \.self) { interval in
                    Button(SlideshowIntervalHelper.formatInterval(interval)) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedInterval = interval
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(selectedInterval == interval ? .white : .primary)
                    .background(selectedInterval == interval ? Color.accentColor : Color.clear)
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

#Preview {
    SettingsView(settingsManager: MockSettingsManager())
}
