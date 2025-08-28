//
//  PluginSettingsIntegrationTests.swift
//  SwiftViewerTests
//
//  Created by Claude Code on 2025-08-28.
//

import XCTest
import SwiftUI
import Combine
@testable import SwiftViewer

@MainActor
final class PluginSettingsIntegrationTests: XCTestCase {
    
    // MARK: - Plugin Settings Manager Integration Tests
    
    func test_pluginSettingsManager_initialization() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        
        XCTAssertNotNil(pluginSettingsManager)
        XCTAssertTrue(pluginSettingsManager.getAllPluginSettings().isEmpty)
    }
    
    func test_pluginSettingsManager_registerPlugin() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        let mockPlugin = MockConfigurablePlugin()
        
        pluginSettingsManager.registerPlugin(mockPlugin)
        
        let allPluginSettings = pluginSettingsManager.getAllPluginSettings()
        XCTAssertEqual(allPluginSettings.count, 1)
        XCTAssertTrue(allPluginSettings.keys.contains("testPlugin"))
    }
    
    func test_pluginSettingsManager_unregisterPlugin() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        let mockPlugin = MockConfigurablePlugin()
        
        pluginSettingsManager.registerPlugin(mockPlugin)
        XCTAssertEqual(pluginSettingsManager.getAllPluginSettings().count, 1)
        
        pluginSettingsManager.unregisterPlugin(with: "testPlugin")
        XCTAssertTrue(pluginSettingsManager.getAllPluginSettings().isEmpty)
    }
    
    func test_pluginSettingsManager_getPluginSettings() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        let mockPlugin = MockConfigurablePlugin()
        
        pluginSettingsManager.registerPlugin(mockPlugin)
        
        let pluginSettings = pluginSettingsManager.getPluginSettings(for: "testPlugin")
        XCTAssertNotNil(pluginSettings)
        XCTAssertEqual(pluginSettings?.pluginId, "testPlugin")
    }
    
    // MARK: - Settings Persistence Tests
    
    func test_pluginSettingsManager_savesPluginSettingsToManager() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        let configuration = ["key1": "value1", "key2": "value2"]
        
        pluginSettingsManager.savePluginSettings(for: "testPlugin", settings: configuration)
        
        let savedSettings = pluginSettingsManager.loadPluginSettings(for: "testPlugin")
        XCTAssertEqual(savedSettings, configuration)
    }
    
    func test_pluginSettingsManager_loadPluginSettingsFromManager() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        let configuration = ["key1": "value1", "key2": "value2"]
        
        // Manually set in the underlying storage for testing
        pluginSettingsManager.savePluginSettings(for: "testPlugin", settings: configuration)
        
        let loadedSettings = pluginSettingsManager.loadPluginSettings(for: "testPlugin")
        XCTAssertEqual(loadedSettings, configuration)
    }
    
    func test_pluginSettingsManager_isolatesPluginSettings() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        
        let plugin1Settings = ["setting1": "value1"]
        let plugin2Settings = ["setting2": "value2"]
        
        pluginSettingsManager.savePluginSettings(for: "plugin1", settings: plugin1Settings)
        pluginSettingsManager.savePluginSettings(for: "plugin2", settings: plugin2Settings)
        
        let loaded1 = pluginSettingsManager.loadPluginSettings(for: "plugin1")
        let loaded2 = pluginSettingsManager.loadPluginSettings(for: "plugin2")
        
        XCTAssertEqual(loaded1, plugin1Settings)
        XCTAssertEqual(loaded2, plugin2Settings)
        XCTAssertNotEqual(loaded1, loaded2)
    }
    
    // MARK: - Settings View Integration Tests
    
    func test_pluginSettingsSection_integration() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        let mockPlugin = MockConfigurablePlugin()
        
        pluginSettingsManager.registerPlugin(mockPlugin)
        
        let pluginSettingsSection = PluginSettingsSection(pluginSettingsManager: pluginSettingsManager)
        XCTAssertNotNil(pluginSettingsSection)
    }
    
    func test_pluginSettingsSection_showsRegisteredPlugins() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        let mockPlugin1 = MockConfigurablePlugin(pluginId: "plugin1")
        let mockPlugin2 = MockConfigurablePlugin(pluginId: "plugin2")
        
        pluginSettingsManager.registerPlugin(mockPlugin1)
        pluginSettingsManager.registerPlugin(mockPlugin2)
        
        let pluginSettingsSection = PluginSettingsSection(pluginSettingsManager: pluginSettingsManager)
        let allPluginSettings = pluginSettingsSection.getAllPluginSettings()
        
        XCTAssertEqual(allPluginSettings.count, 2)
        XCTAssertTrue(allPluginSettings.keys.contains("plugin1"))
        XCTAssertTrue(allPluginSettings.keys.contains("plugin2"))
    }
    
    func test_pluginSettingsSection_handlesNoPlugins() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        
        let pluginSettingsSection = PluginSettingsSection(pluginSettingsManager: pluginSettingsManager)
        let allPluginSettings = pluginSettingsSection.getAllPluginSettings()
        
        XCTAssertTrue(allPluginSettings.isEmpty)
    }
    
    // MARK: - Live Updates Tests
    
    func test_pluginSettingsManager_providesLiveUpdates() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        var receivedUpdates: [(String, [String: String])] = []
        
        let cancellable = pluginSettingsManager.settingsUpdates.sink { pluginId, settings in
            receivedUpdates.append((pluginId, settings))
        }
        
        let configuration = ["key": "value"]
        pluginSettingsManager.savePluginSettings(for: "testPlugin", settings: configuration)
        
        XCTAssertEqual(receivedUpdates.count, 1)
        XCTAssertEqual(receivedUpdates.first?.0, "testPlugin")
        XCTAssertEqual(receivedUpdates.first?.1, configuration)
        
        _ = cancellable // Keep reference to avoid warning
    }
    
    func test_pluginSettingsManager_updatesRegisteredPlugins() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        let mockPlugin = MockConfigurablePlugin()
        
        pluginSettingsManager.registerPlugin(mockPlugin)
        
        let newConfiguration = ["key": "newValue"]
        pluginSettingsManager.savePluginSettings(for: "testPlugin", settings: newConfiguration)
        
        let updatedSettings = pluginSettingsManager.getPluginSettings(for: "testPlugin")
        XCTAssertEqual(updatedSettings?.configuration, newConfiguration)
    }
    
    // MARK: - Validation Tests
    
    func test_pluginSettingsManager_validatesSettings() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        
        let validSettings = ["duration": "0.5", "scale": "1.0"]
        let invalidSettings = ["duration": "invalid", "": "emptyKey"]
        
        XCTAssertTrue(pluginSettingsManager.validateSettings(validSettings))
        XCTAssertFalse(pluginSettingsManager.validateSettings(invalidSettings))
    }
    
    func test_pluginSettingsManager_sanitizesSettings() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        
        let unsafeSettings = [
            "normalKey": "normalValue",
            "": "emptyKey", // Should be removed
            "scriptTag": "<script>alert('xss')</script>" // Should be sanitized
        ]
        
        let sanitized = pluginSettingsManager.sanitizeSettings(unsafeSettings)
        
        XCTAssertTrue(sanitized.keys.contains("normalKey"))
        XCTAssertFalse(sanitized.keys.contains(""))
        XCTAssertFalse(sanitized["scriptTag"]?.contains("<script>") ?? false)
    }
    
    // MARK: - Error Handling Tests
    
    func test_pluginSettingsManager_handlesInvalidPluginId() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        
        let settings = pluginSettingsManager.loadPluginSettings(for: "nonexistentPlugin")
        XCTAssertTrue(settings.isEmpty)
        
        let pluginSettings = pluginSettingsManager.getPluginSettings(for: "nonexistentPlugin")
        XCTAssertNil(pluginSettings)
    }
    
    func test_pluginSettingsManager_handlesEmptySettings() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        
        pluginSettingsManager.savePluginSettings(for: "testPlugin", settings: [:])
        let loadedSettings = pluginSettingsManager.loadPluginSettings(for: "testPlugin")
        
        XCTAssertTrue(loadedSettings.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func test_pluginSettingsManager_performance() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        
        measure {
            for i in 0..<100 {
                pluginSettingsManager.savePluginSettings(for: "plugin\(i)", settings: ["key": "value\(i)"])
            }
        }
    }
    
    func test_pluginSettingsManager_bulkOperationPerformance() {
        let settingsManager = MockSettingsManager()
        let pluginSettingsManager = PluginSettingsManager(settingsManager: settingsManager)
        
        // Register multiple plugins
        for i in 0..<50 {
            let mockPlugin = MockConfigurablePlugin(pluginId: "plugin\(i)")
            pluginSettingsManager.registerPlugin(mockPlugin)
        }
        
        measure {
            let allSettings = pluginSettingsManager.getAllPluginSettings()
            XCTAssertEqual(allSettings.count, 50)
        }
    }
}

// MARK: - Mock Classes

@MainActor
private final class MockConfigurablePlugin: ConfigurablePluginProtocol {
    let pluginId: String
    var configuration: [String: String] = [:]
    
    init(pluginId: String = "testPlugin") {
        self.pluginId = pluginId
    }
    
    func updateConfiguration(_ newConfiguration: [String: String]) {
        configuration = newConfiguration
    }
    
    func getConfigurationView() -> any PluginConfigurationViewProtocol {
        return MockPluginConfigurationView(pluginId: pluginId)
    }
}

@MainActor
private final class MockPluginConfigurationView: ObservableObject, PluginConfigurationViewProtocol {
    let pluginId: String
    var configuration: [String: String] = [:]
    
    init(pluginId: String) {
        self.pluginId = pluginId
    }
    
    func updateConfiguration(_ newConfiguration: [String: String]) {
        configuration = newConfiguration
    }
    
    var body: some View {
        Text("Mock Plugin Configuration View")
    }
}