import XCTest
import SwiftUI
@testable import SwiftViewer

/// Tests for SwiftUI Plugin View Integration functionality  
/// Unit 16: SwiftUI View Integration (3-4 hours)
/// Test: Plugin views in main UI hierarchy
@MainActor
final class PluginViewIntegrationTests: XCTestCase {
    
    fileprivate var sut: PluginViewContainer!
    fileprivate var mockViewPlugin: MockViewPlugin!
    fileprivate var viewModel: PluginViewContainerViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        mockViewPlugin = MockViewPlugin()
        viewModel = PluginViewContainerViewModel()
        sut = PluginViewContainer(viewModel: viewModel)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockViewPlugin = nil
        viewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - Plugin View Registration Tests
    
    func testRegisterPluginView_WithValidPlugin_ShouldRegisterSuccessfully() {
        // Given valid view plugin
        let pluginId = mockViewPlugin.metadata.id
        
        // When registering plugin view
        viewModel.registerPluginView(plugin: mockViewPlugin)
        
        // Then plugin should be registered
        XCTAssertTrue(viewModel.hasRegisteredPlugin(pluginId))
        XCTAssertEqual(viewModel.registeredPluginCount, 1)
        XCTAssertNotNil(viewModel.getPluginView(for: pluginId))
    }
    
    func testRegisterPluginView_WithMultiplePlugins_ShouldRegisterAll() {
        // Given multiple view plugins
        let plugin1 = MockViewPlugin(id: "test.plugin.1")
        let plugin2 = MockViewPlugin(id: "test.plugin.2")
        let plugin3 = MockViewPlugin(id: "test.plugin.3")
        
        // When registering multiple plugins
        viewModel.registerPluginView(plugin: plugin1)
        viewModel.registerPluginView(plugin: plugin2)
        viewModel.registerPluginView(plugin: plugin3)
        
        // Then all should be registered
        XCTAssertTrue(viewModel.hasRegisteredPlugin(plugin1.metadata.id))
        XCTAssertTrue(viewModel.hasRegisteredPlugin(plugin2.metadata.id))
        XCTAssertTrue(viewModel.hasRegisteredPlugin(plugin3.metadata.id))
        XCTAssertEqual(viewModel.registeredPluginCount, 3)
    }
    
    func testUnregisterPluginView_ShouldRemovePlugin() {
        // Given registered plugin
        let pluginId = mockViewPlugin.metadata.id
        viewModel.registerPluginView(plugin: mockViewPlugin)
        
        // When unregistering plugin
        viewModel.unregisterPluginView(pluginId: pluginId)
        
        // Then plugin should be removed
        XCTAssertFalse(viewModel.hasRegisteredPlugin(pluginId))
        XCTAssertEqual(viewModel.registeredPluginCount, 0)
        XCTAssertNil(viewModel.getPluginView(for: pluginId))
    }
    
    // MARK: - View Lifecycle Tests
    
    func testPluginViewLifecycle_ShouldManageStateCorrectly() async throws {
        // Given registered plugin
        viewModel.registerPluginView(plugin: mockViewPlugin)
        let pluginId = mockViewPlugin.metadata.id
        
        // When activating plugin view
        try await viewModel.activatePluginView(pluginId: pluginId)
        
        // Then plugin should be active
        XCTAssertTrue(viewModel.isPluginViewActive(pluginId))
        XCTAssertTrue(mockViewPlugin.isViewActive)
        
        // When deactivating plugin view
        await viewModel.deactivatePluginView(pluginId: pluginId)
        
        // Then plugin should be inactive
        XCTAssertFalse(viewModel.isPluginViewActive(pluginId))
        XCTAssertFalse(mockViewPlugin.isViewActive)
    }
    
    func testPluginViewLifecycle_WithError_ShouldHandleGracefully() async {
        // Given plugin that throws initialization error
        mockViewPlugin.shouldThrowViewError = true
        viewModel.registerPluginView(plugin: mockViewPlugin)
        let pluginId = mockViewPlugin.metadata.id
        
        // When activating plugin view that throws error
        do {
            try await viewModel.activatePluginView(pluginId: pluginId)
            XCTFail("Expected plugin view error")
        } catch let error as PluginViewError {
            // Then should handle error gracefully
            XCTAssertTrue(error.localizedDescription.contains("initialization"))
            XCTAssertFalse(viewModel.isPluginViewActive(pluginId))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - View Injection Tests
    
    func testViewInjection_ShouldProvidePluginViews() {
        // Given registered plugins
        let plugin1 = MockViewPlugin(id: "test.plugin.1")
        let plugin2 = MockViewPlugin(id: "test.plugin.2")
        viewModel.registerPluginView(plugin: plugin1)
        viewModel.registerPluginView(plugin: plugin2)
        
        // When getting injectable views
        let injectableViews = viewModel.getInjectableViews()
        
        // Then should provide plugin views
        XCTAssertEqual(injectableViews.count, 2)
        XCTAssertTrue(injectableViews.contains { $0.pluginId == plugin1.metadata.id })
        XCTAssertTrue(injectableViews.contains { $0.pluginId == plugin2.metadata.id })
    }
    
    func testViewInjection_WithActiveFiltering_ShouldReturnActiveOnly() async throws {
        // Given registered plugins with different states
        let plugin1 = MockViewPlugin(id: "test.plugin.1")
        let plugin2 = MockViewPlugin(id: "test.plugin.2")
        viewModel.registerPluginView(plugin: plugin1)
        viewModel.registerPluginView(plugin: plugin2)
        
        // Activate only plugin1
        try await viewModel.activatePluginView(pluginId: plugin1.metadata.id)
        
        // When getting active injectable views
        let activeViews = viewModel.getInjectableViews(activeOnly: true)
        
        // Then should return only active plugin
        XCTAssertEqual(activeViews.count, 1)
        XCTAssertEqual(activeViews.first?.pluginId, plugin1.metadata.id)
    }
    
    // MARK: - View Positioning Tests
    
    func testViewPositioning_ShouldSupportDifferentPositions() {
        // Given plugin with position preferences
        mockViewPlugin.preferredPosition = .overlay
        viewModel.registerPluginView(plugin: mockViewPlugin)
        
        // When getting plugin view info
        let viewInfo = viewModel.getPluginViewInfo(for: mockViewPlugin.metadata.id)
        
        // Then should respect position preference
        XCTAssertNotNil(viewInfo)
        XCTAssertEqual(viewInfo?.position, .overlay)
    }
    
    func testViewPositioning_WithConflicts_ShouldResolveIntelligently() {
        // Given multiple plugins with same position
        let plugin1 = MockViewPlugin(id: "test.plugin.1", position: .sidebar)
        let plugin2 = MockViewPlugin(id: "test.plugin.2", position: .sidebar)
        let plugin3 = MockViewPlugin(id: "test.plugin.3", position: .sidebar)
        
        viewModel.registerPluginView(plugin: plugin1)
        viewModel.registerPluginView(plugin: plugin2)
        viewModel.registerPluginView(plugin: plugin3)
        
        // When resolving positions
        let resolvedPositions = viewModel.resolveViewPositions()
        
        // Then should resolve conflicts intelligently
        let sidebarPlugins = resolvedPositions.filter { $0.position == .sidebar }
        XCTAssertEqual(sidebarPlugins.count, 3)
        
        // Should assign priority order
        let priorityOrders = sidebarPlugins.map { $0.priorityOrder }
        XCTAssertEqual(Set(priorityOrders).count, 3) // All different priorities
    }
    
    // MARK: - State Management Tests
    
    func testStateManagement_ShouldPersistViewStates() async throws {
        // Given plugin with custom state
        mockViewPlugin.customViewState = ["key1": "value1", "key2": 42]
        viewModel.registerPluginView(plugin: mockViewPlugin)
        let pluginId = mockViewPlugin.metadata.id
        
        try await viewModel.activatePluginView(pluginId: pluginId)
        
        // When saving view state
        let savedState = viewModel.getPluginViewState(for: pluginId)
        
        // Then should persist state correctly
        XCTAssertNotNil(savedState)
        XCTAssertEqual(savedState?["key1"] as? String, "value1")
        XCTAssertEqual(savedState?["key2"] as? Int, 42)
    }
    
    func testStateManagement_WithStateRestoration_ShouldRestoreCorrectly() async throws {
        // Given saved plugin state
        let pluginId = mockViewPlugin.metadata.id
        let savedState: [String: Any] = ["restoredKey": "restoredValue", "number": 123]
        
        viewModel.registerPluginView(plugin: mockViewPlugin)
        viewModel.setPluginViewState(for: pluginId, state: savedState)
        
        // When activating plugin with restored state
        try await viewModel.activatePluginView(pluginId: pluginId)
        
        // Then should restore state
        let currentState = viewModel.getPluginViewState(for: pluginId)
        XCTAssertEqual(currentState?["restoredKey"] as? String, "restoredValue")
        XCTAssertEqual(currentState?["number"] as? Int, 123)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling_WithInvalidPluginId_ShouldHandleGracefully() async {
        // Given invalid plugin ID
        let invalidPluginId = "non.existent.plugin"
        
        // When trying to activate invalid plugin
        do {
            try await viewModel.activatePluginView(pluginId: invalidPluginId)
            XCTFail("Expected plugin not found error")
        } catch let error as PluginViewError {
            // Then should throw appropriate error
            XCTAssertEqual(error, .pluginNotFound(invalidPluginId))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - SwiftUI Environment Tests
    
    func testSwiftUIEnvironment_ShouldProvidePluginContext() {
        // Given plugin view container
        mockViewPlugin.requiresEnvironment = true
        viewModel.registerPluginView(plugin: mockViewPlugin)
        
        // When creating SwiftUI environment
        let environmentValues = viewModel.createEnvironmentValues()
        
        // Then should provide plugin context
        XCTAssertNotNil(environmentValues.pluginContainer)
        XCTAssertNotNil(environmentValues.pluginEventSystem)
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_WithManyPlugins_ShouldPerformWell() {
        measure {
            // Given many plugins
            let pluginCount = 100
            let plugins = (0..<pluginCount).map { i in
                MockViewPlugin(id: "test.plugin.\(i)")
            }
            
            // When registering many plugins
            for plugin in plugins {
                viewModel.registerPluginView(plugin: plugin)
            }
            
            // When getting injectable views
            let injectableViews = viewModel.getInjectableViews()
            
            // Then should perform well
            XCTAssertEqual(injectableViews.count, pluginCount)
        }
    }
    
    func testMemoryManagement_ShouldNotLeakPluginViews() {
        // Given registered plugins
        var plugin1: MockViewPlugin? = MockViewPlugin(id: "test.plugin.1")
        var plugin2: MockViewPlugin? = MockViewPlugin(id: "test.plugin.2")
        
        weak var weakPlugin1 = plugin1
        weak var weakPlugin2 = plugin2
        
        viewModel.registerPluginView(plugin: plugin1!)
        viewModel.registerPluginView(plugin: plugin2!)
        
        // When releasing plugin references
        plugin1 = nil
        plugin2 = nil
        
        // When unregistering plugins
        viewModel.unregisterPluginView(pluginId: "test.plugin.1")
        viewModel.unregisterPluginView(pluginId: "test.plugin.2")
        
        // Then plugins should be deallocated
        XCTAssertNil(weakPlugin1)
        XCTAssertNil(weakPlugin2)
    }
}

// MARK: - Mock View Plugin

fileprivate class MockViewPlugin: PluginViewProtocol {
    let metadata: PluginMetadata
    var isActive: Bool = false
    var isViewActive: Bool = false
    var shouldThrowViewError: Bool = false
    var preferredPosition: PluginViewPosition = .sidebar
    var requiresEnvironment: Bool = false
    var customViewState: [String: Any] = [:]
    
    init(id: String = "test.view.plugin", position: PluginViewPosition = .sidebar) {
        self.metadata = PluginMetadata(
            id: id,
            name: "Test View Plugin",
            version: "1.0.0",
            author: "Test Author",
            description: "Test plugin for view integration tests",
            capabilities: [.transitionEffect]
        )
        self.preferredPosition = position
    }
    
    func initialize() async throws {
        isActive = true
    }
    
    func cleanup() async {
        isActive = false
        isViewActive = false
    }
    
    func createView() throws -> AnyView {
        if shouldThrowViewError {
            throw PluginViewError.viewInitializationFailed(reason: "Mock view initialization error")
        }
        
        // Set view as active immediately for testing purposes
        isViewActive = true
        
        let view = Text("Plugin View: \(metadata.name)")
            .onAppear {
                self.isViewActive = true
            }
            .onDisappear {
                self.isViewActive = false
            }
        
        return AnyView(view)
    }
    
    func getViewPosition() -> PluginViewPosition {
        return preferredPosition
    }
    
    func getViewState() -> [String: Any] {
        return customViewState
    }
    
    func restoreViewState(_ state: [String: Any]) {
        customViewState = state
    }
    
    /// Explicitly deactivate the view for testing
    func deactivateView() {
        isViewActive = false
    }
}