import XCTest
@testable import SwiftViewer

final class PluginProtocolTests: XCTestCase {
    
    // MARK: - Mock Plugin for Testing
    
    private class MockPlugin: PluginProtocol {
        let metadata: PluginMetadata
        var isActive = false
        var initializeCalled = false
        var cleanupCalled = false
        
        init(metadata: PluginMetadata) {
            self.metadata = metadata
        }
        
        func initialize() async throws {
            initializeCalled = true
            isActive = true
        }
        
        func cleanup() async {
            cleanupCalled = true
            isActive = false
        }
    }
    
    // MARK: - Plugin Capability Tests
    
    func test_PluginCapability_hasCorrectCases() {
        // Verify all required capability types exist
        let capabilities: [PluginCapability] = [
            .transitionEffect,
            .imageFilter,
            .metadataExtractor,
            .exportFormat
        ]
        
        // Each capability should have a unique raw value
        let uniqueValues = Set(capabilities.map { $0.rawValue })
        XCTAssertEqual(uniqueValues.count, capabilities.count, "Each capability should have a unique identifier")
    }
    
    func test_PluginCapability_supportsMultipleCapabilities() {
        // A plugin should be able to declare multiple capabilities
        let metadata = PluginMetadata(
            id: "test.plugin",
            name: "Test Plugin",
            version: "1.0.0",
            author: "Test Author",
            description: "Test Description",
            capabilities: [.transitionEffect, .imageFilter]
        )
        
        XCTAssertEqual(metadata.capabilities.count, 2)
        XCTAssertTrue(metadata.capabilities.contains(.transitionEffect))
        XCTAssertTrue(metadata.capabilities.contains(.imageFilter))
    }
    
    // MARK: - Plugin Protocol Tests
    
    func test_PluginProtocol_hasRequiredProperties() {
        let metadata = PluginMetadata(
            id: "test.plugin",
            name: "Test Plugin",
            version: "1.0.0",
            author: "Test Author",
            description: "Test Description",
            capabilities: [.transitionEffect]
        )
        
        let plugin = MockPlugin(metadata: metadata)
        
        // Verify required properties exist
        XCTAssertEqual(plugin.metadata.id, "test.plugin")
        XCTAssertEqual(plugin.metadata.name, "Test Plugin")
        XCTAssertEqual(plugin.metadata.version, "1.0.0")
        XCTAssertFalse(plugin.isActive)
    }
    
    func test_PluginProtocol_initializeMethod() async throws {
        let metadata = PluginMetadata(
            id: "test.plugin",
            name: "Test Plugin",
            version: "1.0.0",
            author: "Test Author",
            description: "Test Description",
            capabilities: [.transitionEffect]
        )
        
        let plugin = MockPlugin(metadata: metadata)
        
        // Plugin should not be active initially
        XCTAssertFalse(plugin.isActive)
        XCTAssertFalse(plugin.initializeCalled)
        
        // Initialize the plugin
        try await plugin.initialize()
        
        // Plugin should be active after initialization
        XCTAssertTrue(plugin.isActive)
        XCTAssertTrue(plugin.initializeCalled)
    }
    
    func test_PluginProtocol_cleanupMethod() async throws {
        let metadata = PluginMetadata(
            id: "test.plugin",
            name: "Test Plugin",
            version: "1.0.0",
            author: "Test Author",
            description: "Test Description",
            capabilities: [.transitionEffect]
        )
        
        let plugin = MockPlugin(metadata: metadata)
        
        // Initialize then cleanup
        try await plugin.initialize()
        XCTAssertTrue(plugin.isActive)
        
        await plugin.cleanup()
        
        // Plugin should not be active after cleanup
        XCTAssertFalse(plugin.isActive)
        XCTAssertTrue(plugin.cleanupCalled)
    }
    
    // MARK: - Plugin Metadata Tests
    
    func test_PluginMetadata_initialization() {
        let metadata = PluginMetadata(
            id: "com.example.plugin",
            name: "Example Plugin",
            version: "2.1.0",
            author: "John Doe",
            description: "An example plugin for testing",
            capabilities: [.transitionEffect, .imageFilter]
        )
        
        XCTAssertEqual(metadata.id, "com.example.plugin")
        XCTAssertEqual(metadata.name, "Example Plugin")
        XCTAssertEqual(metadata.version, "2.1.0")
        XCTAssertEqual(metadata.author, "John Doe")
        XCTAssertEqual(metadata.description, "An example plugin for testing")
        XCTAssertEqual(metadata.capabilities.count, 2)
    }
    
    func test_PluginMetadata_requiredFields() {
        // Test that metadata can handle minimal required fields
        let metadata = PluginMetadata(
            id: "minimal.plugin",
            name: "Minimal",
            version: "1.0.0",
            author: "Author",
            description: "Description",
            capabilities: []
        )
        
        XCTAssertNotNil(metadata)
        XCTAssertTrue(metadata.capabilities.isEmpty)
    }
    
    // MARK: - Protocol Conformance Tests
    
    func test_PluginProtocol_conformanceValidation() async throws {
        // This test ensures that any type conforming to PluginProtocol
        // must implement all required methods and properties
        
        let plugin: any PluginProtocol = MockPlugin(
            metadata: PluginMetadata(
                id: "conformance.test",
                name: "Conformance Test",
                version: "1.0.0",
                author: "Test",
                description: "Test",
                capabilities: [.transitionEffect]
            )
        )
        
        // Test that we can access all required protocol members
        _ = plugin.metadata
        _ = plugin.isActive
        try await plugin.initialize()
        await plugin.cleanup()
        
        // If this compiles and runs, protocol conformance is validated
        XCTAssertTrue(true, "Protocol conformance validated")
    }
}