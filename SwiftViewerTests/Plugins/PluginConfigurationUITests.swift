//
//  PluginConfigurationUITests.swift
//  SwiftViewerTests
//
//  Created by Claude Code on 2025-08-28.
//

import XCTest
import SwiftUI
import Combine
@testable import SwiftViewer

@MainActor
final class PluginConfigurationUITests: XCTestCase {
    
    // MARK: - PluginConfigurationView Protocol Tests
    
    func test_pluginConfigurationView_protocol_requirements() {
        // Test that the protocol has the required properties and methods
        let mockConfigView = MockPluginConfigurationView()
        
        XCTAssertNotNil(mockConfigView.pluginId)
        XCTAssertFalse(mockConfigView.pluginId.isEmpty)
        XCTAssertNotNil(mockConfigView.configuration)
    }
    
    func test_pluginConfigurationView_updateConfiguration() {
        let mockConfigView = MockPluginConfigurationView()
        let initialConfig = mockConfigView.configuration
        
        mockConfigView.updateConfiguration(["testKey": "testValue"])
        
        XCTAssertNotEqual(mockConfigView.configuration, initialConfig)
        XCTAssertEqual(mockConfigView.configuration["testKey"], "testValue")
    }
    
    // MARK: - PluginConfigurationSection Tests
    
    func test_pluginConfigurationSection_initialization() {
        let section = PluginConfigurationSection(
            title: "Test Section",
            description: "Test description",
            items: []
        )
        
        XCTAssertEqual(section.title, "Test Section")
        XCTAssertEqual(section.description, "Test description")
        XCTAssertTrue(section.items.isEmpty)
    }
    
    func test_pluginConfigurationSection_withItems() {
        let textItem = PluginConfigurationItem.textField(
            key: "text",
            label: "Text Field",
            defaultValue: "default",
            placeholder: "Enter text"
        )
        
        let section = PluginConfigurationSection(
            title: "Test Section",
            description: "Section with items",
            items: [textItem]
        )
        
        XCTAssertEqual(section.items.count, 1)
        
        if case .textField(let key, let label, let defaultValue, let placeholder) = section.items.first {
            XCTAssertEqual(key, "text")
            XCTAssertEqual(label, "Text Field")
            XCTAssertEqual(defaultValue, "default")
            XCTAssertEqual(placeholder, "Enter text")
        } else {
            XCTFail("Expected textField configuration item")
        }
    }
    
    // MARK: - PluginConfigurationItem Tests
    
    func test_pluginConfigurationItem_textField() {
        let item = PluginConfigurationItem.textField(
            key: "testKey",
            label: "Test Label",
            defaultValue: "default",
            placeholder: "placeholder"
        )
        
        if case .textField(let key, let label, let defaultValue, let placeholder) = item {
            XCTAssertEqual(key, "testKey")
            XCTAssertEqual(label, "Test Label")
            XCTAssertEqual(defaultValue, "default")
            XCTAssertEqual(placeholder, "placeholder")
        } else {
            XCTFail("Expected textField item")
        }
    }
    
    func test_pluginConfigurationItem_slider() {
        let item = PluginConfigurationItem.slider(
            key: "sliderKey",
            label: "Slider Label",
            defaultValue: 0.5,
            range: 0.0...1.0,
            step: 0.1
        )
        
        if case .slider(let key, let label, let defaultValue, let range, let step) = item {
            XCTAssertEqual(key, "sliderKey")
            XCTAssertEqual(label, "Slider Label")
            XCTAssertEqual(defaultValue, 0.5, accuracy: 0.001)
            XCTAssertEqual(range, 0.0...1.0)
            XCTAssertEqual(step, 0.1, accuracy: 0.001)
        } else {
            XCTFail("Expected slider item")
        }
    }
    
    func test_pluginConfigurationItem_toggle() {
        let item = PluginConfigurationItem.toggle(
            key: "toggleKey",
            label: "Toggle Label",
            defaultValue: true
        )
        
        if case .toggle(let key, let label, let defaultValue) = item {
            XCTAssertEqual(key, "toggleKey")
            XCTAssertEqual(label, "Toggle Label")
            XCTAssertTrue(defaultValue)
        } else {
            XCTFail("Expected toggle item")
        }
    }
    
    func test_pluginConfigurationItem_picker() {
        let options = ["Option 1", "Option 2", "Option 3"]
        let item = PluginConfigurationItem.picker(
            key: "pickerKey",
            label: "Picker Label",
            options: options,
            defaultIndex: 1
        )
        
        if case .picker(let key, let label, let itemOptions, let defaultIndex) = item {
            XCTAssertEqual(key, "pickerKey")
            XCTAssertEqual(label, "Picker Label")
            XCTAssertEqual(itemOptions, options)
            XCTAssertEqual(defaultIndex, 1)
        } else {
            XCTFail("Expected picker item")
        }
    }
    
    // MARK: - PluginConfigurationManager Tests
    
    func test_pluginConfigurationManager_registration() {
        let manager = PluginConfigurationManager()
        let mockConfigView = MockPluginConfigurationView()
        
        manager.registerConfiguration(for: "testPlugin", view: mockConfigView)
        
        let retrievedView = manager.getConfiguration(for: "testPlugin")
        XCTAssertNotNil(retrievedView)
        XCTAssertEqual(retrievedView?.pluginId, "testPlugin")
    }
    
    func test_pluginConfigurationManager_unregistration() {
        let manager = PluginConfigurationManager()
        let mockConfigView = MockPluginConfigurationView()
        
        manager.registerConfiguration(for: "testPlugin", view: mockConfigView)
        XCTAssertNotNil(manager.getConfiguration(for: "testPlugin"))
        
        manager.unregisterConfiguration(for: "testPlugin")
        XCTAssertNil(manager.getConfiguration(for: "testPlugin"))
    }
    
    func test_pluginConfigurationManager_getAllConfigurations() {
        let manager = PluginConfigurationManager()
        let mockConfigView1 = MockPluginConfigurationView(pluginId: "plugin1")
        let mockConfigView2 = MockPluginConfigurationView(pluginId: "plugin2")
        
        manager.registerConfiguration(for: "plugin1", view: mockConfigView1)
        manager.registerConfiguration(for: "plugin2", view: mockConfigView2)
        
        let allConfigs = manager.getAllConfigurations()
        XCTAssertEqual(allConfigs.count, 2)
        XCTAssertTrue(allConfigs.keys.contains("plugin1"))
        XCTAssertTrue(allConfigs.keys.contains("plugin2"))
    }
    
    // MARK: - Configuration Persistence Tests
    
    func test_pluginConfigurationManager_saveConfiguration() {
        let manager = PluginConfigurationManager()
        let configuration = ["key1": "value1", "key2": "value2"]
        
        manager.saveConfiguration(for: "testPlugin", configuration: configuration)
        
        let savedConfig = manager.loadConfiguration(for: "testPlugin")
        XCTAssertEqual(savedConfig, configuration)
    }
    
    func test_pluginConfigurationManager_loadNonExistentConfiguration() {
        let manager = PluginConfigurationManager()
        
        let config = manager.loadConfiguration(for: "nonExistentPlugin")
        XCTAssertTrue(config.isEmpty)
    }
    
    func test_pluginConfigurationManager_updateConfiguration() {
        let manager = PluginConfigurationManager()
        let initialConfig = ["key1": "value1"]
        let updatedConfig = ["key1": "updatedValue1", "key2": "value2"]
        
        manager.saveConfiguration(for: "testPlugin", configuration: initialConfig)
        manager.saveConfiguration(for: "testPlugin", configuration: updatedConfig)
        
        let finalConfig = manager.loadConfiguration(for: "testPlugin")
        XCTAssertEqual(finalConfig, updatedConfig)
        XCTAssertNotEqual(finalConfig, initialConfig)
    }
    
    // MARK: - Configuration Validation Tests
    
    func test_pluginConfigurationManager_validateConfiguration() {
        let manager = PluginConfigurationManager()
        
        let validConfig = ["duration": "0.5", "scale": "1.0"]
        XCTAssertTrue(manager.validateConfiguration(validConfig))
        
        let invalidConfig = ["duration": "invalid", "scale": "also_invalid"]
        XCTAssertFalse(manager.validateConfiguration(invalidConfig))
    }
    
    func test_pluginConfigurationManager_sanitizeConfiguration() {
        let manager = PluginConfigurationManager()
        
        let unsafeConfig = [
            "normalKey": "normalValue",
            "": "emptyKey", // Should be removed
            "validKey": "", // Should be kept (empty values allowed)
            "scriptTag": "<script>alert('xss')</script>" // Should be sanitized
        ]
        
        let sanitized = manager.sanitizeConfiguration(unsafeConfig)
        
        XCTAssertTrue(sanitized.keys.contains("normalKey"))
        XCTAssertTrue(sanitized.keys.contains("validKey"))
        XCTAssertFalse(sanitized.keys.contains(""))
        XCTAssertFalse(sanitized["scriptTag"]?.contains("<script>") ?? false)
    }
    
    // MARK: - Configuration UI Generation Tests
    
    func test_pluginConfigurationBuilder_generateSections() {
        let builder = PluginConfigurationBuilder()
        
        let textItem = PluginConfigurationItem.textField(
            key: "text",
            label: "Text Input",
            defaultValue: "",
            placeholder: "Enter text"
        )
        
        let sliderItem = PluginConfigurationItem.slider(
            key: "intensity",
            label: "Intensity",
            defaultValue: 0.5,
            range: 0.0...1.0,
            step: 0.1
        )
        
        let sections = builder
            .addSection(title: "Basic Settings", description: "Basic configuration")
            .addItem(textItem)
            .addItem(sliderItem)
            .build()
        
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.title, "Basic Settings")
        XCTAssertEqual(sections.first?.items.count, 2)
    }
    
    func test_pluginConfigurationBuilder_multipleSections() {
        let builder = PluginConfigurationBuilder()
        
        let sections = builder
            .addSection(title: "Section 1", description: "First section")
            .addItem(.toggle(key: "enabled", label: "Enabled", defaultValue: true))
            .addSection(title: "Section 2", description: "Second section")
            .addItem(.slider(key: "speed", label: "Speed", defaultValue: 1.0, range: 0.1...2.0, step: 0.1))
            .build()
        
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].title, "Section 1")
        XCTAssertEqual(sections[1].title, "Section 2")
        XCTAssertEqual(sections[0].items.count, 1)
        XCTAssertEqual(sections[1].items.count, 1)
    }
    
    // MARK: - Live Update Tests
    
    func test_pluginConfigurationManager_liveUpdates() {
        let manager = PluginConfigurationManager()
        var receivedUpdates: [(String, [String: String])] = []
        
        let cancellable = manager.configurationUpdates.sink { pluginId, configuration in
            receivedUpdates.append((pluginId, configuration))
        }
        
        manager.saveConfiguration(for: "testPlugin", configuration: ["key": "value"])
        
        XCTAssertEqual(receivedUpdates.count, 1)
        XCTAssertEqual(receivedUpdates.first?.0, "testPlugin")
        XCTAssertEqual(receivedUpdates.first?.1["key"], "value")
        
        _ = cancellable // Keep reference to avoid warning
    }
    
    // MARK: - Error Handling Tests
    
    func test_pluginConfigurationManager_errorHandling() {
        let manager = PluginConfigurationManager()
        
        // Test duplicate registration
        let mockConfigView = MockPluginConfigurationView()
        manager.registerConfiguration(for: "testPlugin", view: mockConfigView)
        
        // Should not crash on duplicate registration
        XCTAssertNoThrow {
            manager.registerConfiguration(for: "testPlugin", view: mockConfigView)
        }
        
        // Test unregistering non-existent plugin
        XCTAssertNoThrow {
            manager.unregisterConfiguration(for: "nonExistentPlugin")
        }
    }
    
    // MARK: - Performance Tests
    
    func test_pluginConfigurationManager_performance() {
        let manager = PluginConfigurationManager()
        
        measure {
            for i in 0..<1000 {
                manager.saveConfiguration(for: "plugin\(i)", configuration: ["key": "value\(i)"])
            }
        }
    }
}

// MARK: - Mock Classes

@MainActor
private final class MockPluginConfigurationView: ObservableObject, PluginConfigurationViewProtocol {
    let pluginId: String
    var configuration: [String: String] = [:]
    
    init(pluginId: String = "testPlugin") {
        self.pluginId = pluginId
    }
    
    func updateConfiguration(_ newConfiguration: [String: String]) {
        self.configuration = newConfiguration
    }
    
    var body: some View {
        Text("Mock Configuration View")
    }
}