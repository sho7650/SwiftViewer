//
//  PluginSettingsManager.swift
//  SwiftViewer
//
//  Created by Claude Code on 2025-08-28.
//

import Foundation
import Combine
import SwiftUI

/// Protocol for plugins that can be configured
protocol ConfigurablePluginProtocol {
    /// Unique identifier for the plugin
    var pluginId: String { get }
    
    /// Current configuration values
    var configuration: [String: String] { get set }
    
    /// Update the configuration with new values
    /// - Parameter newConfiguration: The updated configuration dictionary
    func updateConfiguration(_ newConfiguration: [String: String])
    
    /// Get the configuration view for this plugin
    /// - Returns: Configuration view conforming to PluginConfigurationViewProtocol
    func getConfigurationView() -> any PluginConfigurationViewProtocol
}

/// Manages integration between plugin configurations and main app settings
@MainActor
final class PluginSettingsManager: ObservableObject {
    
    // MARK: - Properties
    
    private let settingsManager: SettingsManagerProtocol
    private var registeredPlugins: [String: any ConfigurablePluginProtocol] = [:]
    private let settingsSubject = PassthroughSubject<(String, [String: String]), Never>()
    
    /// Publisher for plugin settings updates
    var settingsUpdates: AnyPublisher<(String, [String: String]), Never> {
        settingsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(settingsManager: SettingsManagerProtocol = DependencyContainer.shared.settingsManager) {
        self.settingsManager = settingsManager
    }
    
    // MARK: - Plugin Registration
    
    /// Register a configurable plugin
    /// - Parameter plugin: Plugin to register for settings management
    func registerPlugin(_ plugin: any ConfigurablePluginProtocol) {
        registeredPlugins[plugin.pluginId] = plugin
        
        // Load existing settings for this plugin
        let existingSettings = loadPluginSettings(for: plugin.pluginId)
        if !existingSettings.isEmpty {
            registeredPlugins[plugin.pluginId]?.updateConfiguration(existingSettings)
        }
    }
    
    /// Unregister a plugin
    /// - Parameter pluginId: ID of plugin to unregister
    func unregisterPlugin(with pluginId: String) {
        registeredPlugins.removeValue(forKey: pluginId)
    }
    
    /// Get plugin settings view for a registered plugin
    /// - Parameter pluginId: Plugin identifier
    /// - Returns: Plugin settings view if registered, nil otherwise
    func getPluginSettings(for pluginId: String) -> (any PluginConfigurationViewProtocol)? {
        guard let plugin = registeredPlugins[pluginId] else { return nil }
        var configView = plugin.getConfigurationView()
        configView.updateConfiguration(plugin.configuration)
        return configView
    }
    
    /// Get all registered plugin settings
    /// - Returns: Dictionary mapping plugin IDs to their configuration views
    func getAllPluginSettings() -> [String: any PluginConfigurationViewProtocol] {
        var allSettings: [String: any PluginConfigurationViewProtocol] = [:]
        
        for (pluginId, plugin) in registeredPlugins {
            var configView = plugin.getConfigurationView()
            configView.updateConfiguration(plugin.configuration)
            allSettings[pluginId] = configView
        }
        
        return allSettings
    }
    
    // MARK: - Settings Persistence
    
    /// Save plugin settings using the main settings manager
    /// - Parameters:
    ///   - pluginId: Plugin identifier
    ///   - settings: Settings dictionary to save
    func savePluginSettings(for pluginId: String, settings: [String: String]) {
        let sanitizedSettings = sanitizeSettings(settings)
        
        // Save to UserDefaults via settings manager pattern
        let settingsKey = "PluginSettings_\(pluginId)"
        UserDefaults.standard.set(sanitizedSettings, forKey: settingsKey)
        
        // Update registered plugin if available
        registeredPlugins[pluginId]?.updateConfiguration(sanitizedSettings)
        
        // Notify subscribers
        settingsSubject.send((pluginId, sanitizedSettings))
    }
    
    /// Load plugin settings
    /// - Parameter pluginId: Plugin identifier
    /// - Returns: Settings dictionary, empty if not found
    func loadPluginSettings(for pluginId: String) -> [String: String] {
        let settingsKey = "PluginSettings_\(pluginId)"
        
        if let settings = UserDefaults.standard.object(forKey: settingsKey) as? [String: String] {
            return settings
        }
        
        return [:]
    }
    
    // MARK: - Settings Validation
    
    /// Validate plugin settings
    /// - Parameter settings: Settings to validate
    /// - Returns: True if settings are valid
    func validateSettings(_ settings: [String: String]) -> Bool {
        for (key, value) in settings {
            // Check for empty keys
            if key.isEmpty {
                return false
            }
            
            // Validate numeric values for common keys
            if key.contains("duration") || key.contains("scale") || key.contains("intensity") {
                if Double(value) == nil {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Sanitize plugin settings
    /// - Parameter settings: Settings to sanitize
    /// - Returns: Sanitized settings dictionary
    func sanitizeSettings(_ settings: [String: String]) -> [String: String] {
        var sanitized: [String: String] = [:]
        
        for (key, value) in settings {
            // Skip empty keys
            guard !key.isEmpty else { continue }
            
            // Sanitize values to prevent XSS and other issues
            let sanitizedValue = value
                .replacingOccurrences(of: "<script>", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "</script>", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "javascript:", with: "", options: .caseInsensitive)
            
            sanitized[key] = sanitizedValue
        }
        
        return sanitized
    }
}

/// SwiftUI view section for plugin settings integration
struct PluginSettingsSection: View {
    
    @ObservedObject private var pluginSettingsManager: PluginSettingsManager
    
    init(pluginSettingsManager: PluginSettingsManager) {
        self.pluginSettingsManager = pluginSettingsManager
    }
    
    var body: some View {
        let allPluginSettings = pluginSettingsManager.getAllPluginSettings()
        
        if !allPluginSettings.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("PLUGINS")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ForEach(Array(allPluginSettings.keys.sorted()), id: \.self) { pluginId in
                    if let configView = allPluginSettings[pluginId] {
                        PluginSettingsItemView(
                            pluginId: pluginId,
                            configView: configView,
                            onSettingsUpdate: { settings in
                                pluginSettingsManager.savePluginSettings(for: pluginId, settings: settings)
                            }
                        )
                        
                        if pluginId != allPluginSettings.keys.sorted().last {
                            Divider()
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }
    
    /// Get all plugin settings for testing
    /// - Returns: Dictionary of all plugin settings
    @MainActor
    func getAllPluginSettings() -> [String: any PluginConfigurationViewProtocol] {
        return pluginSettingsManager.getAllPluginSettings()
    }
}

/// Individual plugin settings item view
private struct PluginSettingsItemView: View {
    let pluginId: String
    let configView: any PluginConfigurationViewProtocol
    let onSettingsUpdate: ([String: String]) -> Void
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Plugin header with expand/collapse
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(pluginId)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("Plugin Settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Expanded configuration view
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    AnyView(configView)
                        .padding(.leading, 20)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
    }
}