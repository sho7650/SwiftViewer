//
//  PluginConfigurationUI.swift
//  SwiftViewer
//
//  Created by Claude Code on 2025-08-28.
//

import SwiftUI
import Foundation
import Combine

// MARK: - Plugin Configuration View Protocol

/// Protocol for plugin-specific configuration views
@MainActor
protocol PluginConfigurationViewProtocol: View {
    /// Unique identifier for the plugin this configuration belongs to
    var pluginId: String { get }
    
    /// Current configuration values
    var configuration: [String: String] { get set }
    
    /// Update the configuration with new values
    /// - Parameter newConfiguration: The updated configuration dictionary
    func updateConfiguration(_ newConfiguration: [String: String])
}

// MARK: - Configuration Data Structures

/// Represents a section in the plugin configuration UI
struct PluginConfigurationSection {
    let title: String
    let description: String
    let items: [PluginConfigurationItem]
    
    init(title: String, description: String, items: [PluginConfigurationItem] = []) {
        self.title = title
        self.description = description
        self.items = items
    }
}

/// Represents different types of configuration items
enum PluginConfigurationItem {
    case textField(key: String, label: String, defaultValue: String, placeholder: String)
    case slider(key: String, label: String, defaultValue: Double, range: ClosedRange<Double>, step: Double)
    case toggle(key: String, label: String, defaultValue: Bool)
    case picker(key: String, label: String, options: [String], defaultIndex: Int)
    case stepper(key: String, label: String, defaultValue: Int, range: ClosedRange<Int>, step: Int)
    case colorPicker(key: String, label: String, defaultValue: Color)
    
    var key: String {
        switch self {
        case .textField(let key, _, _, _),
             .slider(let key, _, _, _, _),
             .toggle(let key, _, _),
             .picker(let key, _, _, _),
             .stepper(let key, _, _, _, _),
             .colorPicker(let key, _, _):
            return key
        }
    }
    
    var label: String {
        switch self {
        case .textField(_, let label, _, _),
             .slider(_, let label, _, _, _),
             .toggle(_, let label, _),
             .picker(_, let label, _, _),
             .stepper(_, let label, _, _, _),
             .colorPicker(_, let label, _):
            return label
        }
    }
}

// MARK: - Configuration Manager

/// Manages plugin configurations with persistence and live updates
@MainActor
final class PluginConfigurationManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published private var configurations: [String: any PluginConfigurationViewProtocol] = [:]
    @Published private var savedConfigurations: [String: [String: String]] = [:]
    
    private let configurationSubject = PassthroughSubject<(String, [String: String]), Never>()
    
    /// Publisher for configuration updates
    var configurationUpdates: AnyPublisher<(String, [String: String]), Never> {
        configurationSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Configuration Registration
    
    /// Register a configuration view for a plugin
    /// - Parameters:
    ///   - pluginId: Unique identifier for the plugin
    ///   - view: The configuration view instance
    func registerConfiguration(for pluginId: String, view: any PluginConfigurationViewProtocol) {
        configurations[pluginId] = view
        
        // Load saved configuration if available
        let savedConfig = loadConfiguration(for: pluginId)
        if !savedConfig.isEmpty {
            configurations[pluginId]?.updateConfiguration(savedConfig)
        }
    }
    
    /// Unregister a configuration view
    /// - Parameter pluginId: Plugin identifier to unregister
    func unregisterConfiguration(for pluginId: String) {
        configurations.removeValue(forKey: pluginId)
    }
    
    /// Get configuration view for a plugin
    /// - Parameter pluginId: Plugin identifier
    /// - Returns: Configuration view if registered, nil otherwise
    func getConfiguration(for pluginId: String) -> (any PluginConfigurationViewProtocol)? {
        return configurations[pluginId]
    }
    
    /// Get all registered configurations
    /// - Returns: Dictionary mapping plugin IDs to their configuration views
    func getAllConfigurations() -> [String: any PluginConfigurationViewProtocol] {
        return configurations
    }
    
    // MARK: - Configuration Persistence
    
    /// Save configuration for a plugin
    /// - Parameters:
    ///   - pluginId: Plugin identifier
    ///   - configuration: Configuration dictionary to save
    func saveConfiguration(for pluginId: String, configuration: [String: String]) {
        let sanitizedConfig = sanitizeConfiguration(configuration)
        
        savedConfigurations[pluginId] = sanitizedConfig
        
        // Update the registered view if available
        configurations[pluginId]?.updateConfiguration(sanitizedConfig)
        
        // Persist to UserDefaults
        UserDefaults.standard.set(sanitizedConfig, forKey: "PluginConfig_\(pluginId)")
        
        // Notify subscribers
        configurationSubject.send((pluginId, sanitizedConfig))
    }
    
    /// Load configuration for a plugin
    /// - Parameter pluginId: Plugin identifier
    /// - Returns: Configuration dictionary, empty if not found
    func loadConfiguration(for pluginId: String) -> [String: String] {
        // Check in-memory cache first
        if let cached = savedConfigurations[pluginId] {
            return cached
        }
        
        // Load from UserDefaults
        if let saved = UserDefaults.standard.object(forKey: "PluginConfig_\(pluginId)") as? [String: String] {
            savedConfigurations[pluginId] = saved
            return saved
        }
        
        return [:]
    }
    
    // MARK: - Configuration Validation
    
    /// Validate configuration values
    /// - Parameter configuration: Configuration to validate
    /// - Returns: True if configuration is valid
    func validateConfiguration(_ configuration: [String: String]) -> Bool {
        for (key, value) in configuration {
            // Check for empty keys
            if key.isEmpty {
                return false
            }
            
            // Validate numeric values
            if key.contains("duration") || key.contains("scale") || key.contains("intensity") {
                if Double(value) == nil {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Sanitize configuration values
    /// - Parameter configuration: Configuration to sanitize
    /// - Returns: Sanitized configuration
    func sanitizeConfiguration(_ configuration: [String: String]) -> [String: String] {
        var sanitized: [String: String] = [:]
        
        for (key, value) in configuration {
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

// MARK: - Configuration Builder

/// Builder pattern for creating plugin configuration sections
final class PluginConfigurationBuilder {
    
    private var sections: [PluginConfigurationSection] = []
    private var currentSection: PluginConfigurationSection?
    private var currentItems: [PluginConfigurationItem] = []
    
    /// Add a new configuration section
    /// - Parameters:
    ///   - title: Section title
    ///   - description: Section description
    /// - Returns: Builder instance for chaining
    func addSection(title: String, description: String) -> PluginConfigurationBuilder {
        // Finalize previous section if exists
        if let section = currentSection {
            let finalizedSection = PluginConfigurationSection(
                title: section.title,
                description: section.description,
                items: currentItems
            )
            sections.append(finalizedSection)
        }
        
        // Start new section
        currentSection = PluginConfigurationSection(title: title, description: description)
        currentItems = []
        
        return self
    }
    
    /// Add configuration item to current section
    /// - Parameter item: Configuration item to add
    /// - Returns: Builder instance for chaining
    func addItem(_ item: PluginConfigurationItem) -> PluginConfigurationBuilder {
        currentItems.append(item)
        return self
    }
    
    /// Build the final configuration sections
    /// - Returns: Array of configuration sections
    func build() -> [PluginConfigurationSection] {
        // Finalize current section
        if let section = currentSection {
            let finalizedSection = PluginConfigurationSection(
                title: section.title,
                description: section.description,
                items: currentItems
            )
            sections.append(finalizedSection)
        }
        
        let result = sections
        
        // Reset builder state
        sections = []
        currentSection = nil
        currentItems = []
        
        return result
    }
}

// MARK: - Default Configuration Views

/// Generic configuration view that can be used by plugins
@MainActor
struct GenericPluginConfigurationView: PluginConfigurationViewProtocol {
    
    let pluginId: String
    @State var configuration: [String: String] = [:]
    
    private let sections: [PluginConfigurationSection]
    private let onConfigurationUpdate: (([String: String]) -> Void)?
    
    init(pluginId: String, sections: [PluginConfigurationSection], onUpdate: (([String: String]) -> Void)? = nil) {
        self.pluginId = pluginId
        self.sections = sections
        self.onConfigurationUpdate = onUpdate
    }
    
    func updateConfiguration(_ newConfiguration: [String: String]) {
        configuration = newConfiguration
        onConfigurationUpdate?(newConfiguration)
    }
    
    var body: some View {
        Form {
            ForEach(sections, id: \.title) { section in
                Section {
                    ForEach(section.items, id: \.key) { item in
                        configurationItemView(for: item)
                    }
                } header: {
                    VStack(alignment: .leading) {
                        Text(section.title)
                            .font(.headline)
                        if !section.description.isEmpty {
                            Text(section.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Plugin Configuration")
    }
    
    @ViewBuilder
    private func configurationItemView(for item: PluginConfigurationItem) -> some View {
        switch item {
        case .textField(let key, let label, let defaultValue, let placeholder):
            VStack(alignment: .leading) {
                Text(label)
                TextField(placeholder, text: Binding(
                    get: { configuration[key] ?? defaultValue },
                    set: { newValue in
                        configuration[key] = newValue
                        onConfigurationUpdate?(configuration)
                    }
                ))
            }
            
        case .slider(let key, let label, let defaultValue, let range, _):
            VStack(alignment: .leading) {
                Text(label)
                Slider(
                    value: Binding(
                        get: { Double(configuration[key] ?? "") ?? defaultValue },
                        set: { newValue in
                            configuration[key] = String(newValue)
                            onConfigurationUpdate?(configuration)
                        }
                    ),
                    in: range
                )
            }
            
        case .toggle(let key, let label, let defaultValue):
            Toggle(label, isOn: Binding(
                get: { Bool(configuration[key] ?? "") ?? defaultValue },
                set: { newValue in
                    configuration[key] = String(newValue)
                    onConfigurationUpdate?(configuration)
                }
            ))
            
        case .picker(let key, let label, let options, let defaultIndex):
            VStack(alignment: .leading) {
                Text(label)
                Picker(label, selection: Binding(
                    get: { Int(configuration[key] ?? "") ?? defaultIndex },
                    set: { newValue in
                        configuration[key] = String(newValue)
                        onConfigurationUpdate?(configuration)
                    }
                )) {
                    ForEach(options.indices, id: \.self) { index in
                        Text(options[index]).tag(index)
                    }
                }
                .pickerStyle(.menu)
            }
            
        case .stepper(let key, let label, let defaultValue, let range, _):
            Stepper(
                value: Binding(
                    get: { Int(configuration[key] ?? "") ?? defaultValue },
                    set: { newValue in
                        configuration[key] = String(newValue)
                        onConfigurationUpdate?(configuration)
                    }
                ),
                in: range
            ) {
                Text(label)
            }
            
        case .colorPicker(let key, let label, let defaultValue):
            ColorPicker(label, selection: Binding(
                get: { 
                    // Simple color parsing - in real implementation would be more robust
                    return Color(configuration[key] ?? "") ?? defaultValue
                },
                set: { newValue in
                    configuration[key] = newValue.description
                    onConfigurationUpdate?(configuration)
                }
            ))
        }
    }
}

// MARK: - Color Extension for String Conversion

private extension Color {
    init?(_ string: String) {
        // Simplified color parsing - would need proper implementation
        return nil
    }
}