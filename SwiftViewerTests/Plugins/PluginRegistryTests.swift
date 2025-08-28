import XCTest
@testable import SwiftViewer
import Foundation

final class PluginRegistryTests: XCTestCase {
    
    var registry: PluginRegistry!
    var mockPlugins: [MockPlugin]!
    
    override func setUp() {
        super.setUp()
        registry = PluginRegistry()
        mockPlugins = []
    }
    
    override func tearDown() {
        // Cleanup all registered plugins
        if let registry = registry {
            Task {
                await registry.deregisterAllPlugins()
            }
        }
        registry = nil
        mockPlugins = nil
        super.tearDown()
    }
    
    // MARK: - Plugin Registration Tests
    
    func test_PluginRegistry_registersPluginSuccessfully() async throws {
        let plugin = createMockPlugin(id: "com.test.register", capabilities: [.transitionEffect])
        
        let result = await registry.registerPlugin(plugin)
        
        switch result {
        case .success:
            let registeredPlugins = await registry.getAllPlugins()
            XCTAssertEqual(registeredPlugins.count, 1)
            XCTAssertEqual(registeredPlugins.first?.metadata.id, "com.test.register")
        case .failure(let error):
            XCTFail("Plugin registration should succeed: \(error)")
        }
    }
    
    func test_PluginRegistry_preventsDoubleRegistration() async throws {
        let plugin1 = createMockPlugin(id: "com.test.double", capabilities: [.transitionEffect])
        let plugin2 = createMockPlugin(id: "com.test.double", capabilities: [.imageFilter])
        
        let result1 = await registry.registerPlugin(plugin1)
        let result2 = await registry.registerPlugin(plugin2)
        
        switch result1 {
        case .success:
            // First registration should succeed
            break
        case .failure(let error):
            XCTFail("First plugin registration should succeed: \(error)")
        }
        
        switch result2 {
        case .success:
            XCTFail("Second plugin registration with same ID should fail")
        case .failure(let error):
            XCTAssertTrue(error is PluginError)
            if case .pluginAlreadyRegistered = error as? PluginError {
                // Expected error
            } else {
                XCTFail("Expected pluginAlreadyRegistered error, got: \(error)")
            }
        }
        
        let registeredPlugins = await registry.getAllPlugins()
        XCTAssertEqual(registeredPlugins.count, 1)
    }
    
    func test_PluginRegistry_registersMultiplePlugins() async throws {
        let plugin1 = createMockPlugin(id: "com.test.multi1", capabilities: [.transitionEffect])
        let plugin2 = createMockPlugin(id: "com.test.multi2", capabilities: [.imageFilter])
        let plugin3 = createMockPlugin(id: "com.test.multi3", capabilities: [.metadataExtractor])
        
        let results = await withTaskGroup(of: Result<Void, Error>.self) { group in
            group.addTask { await self.registry.registerPlugin(plugin1) }
            group.addTask { await self.registry.registerPlugin(plugin2) }
            group.addTask { await self.registry.registerPlugin(plugin3) }
            
            var results: [Result<Void, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // All registrations should succeed
        for result in results {
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Plugin registration should succeed: \(error)")
            }
        }
        
        let registeredPlugins = await registry.getAllPlugins()
        XCTAssertEqual(registeredPlugins.count, 3)
    }
    
    // MARK: - Plugin Deregistration Tests
    
    func test_PluginRegistry_deregistersPluginSuccessfully() async throws {
        let plugin = createMockPlugin(id: "com.test.dereg", capabilities: [.transitionEffect])
        
        _ = await registry.registerPlugin(plugin)
        let result = await registry.deregisterPlugin(withId: "com.test.dereg")
        
        switch result {
        case .success:
            let registeredPlugins = await registry.getAllPlugins()
            XCTAssertEqual(registeredPlugins.count, 0)
        case .failure(let error):
            XCTFail("Plugin deregistration should succeed: \(error)")
        }
    }
    
    func test_PluginRegistry_handlesDeregistrationOfNonexistentPlugin() async throws {
        let result = await registry.deregisterPlugin(withId: "com.test.nonexistent")
        
        switch result {
        case .success:
            XCTFail("Deregistration of nonexistent plugin should fail")
        case .failure(let error):
            XCTAssertTrue(error is PluginError)
            if case .pluginNotFound = error as? PluginError {
                // Expected error
            } else {
                XCTFail("Expected pluginNotFound error, got: \(error)")
            }
        }
    }
    
    func test_PluginRegistry_deregistersAllPlugins() async throws {
        let plugins = [
            createMockPlugin(id: "com.test.all1", capabilities: [.transitionEffect]),
            createMockPlugin(id: "com.test.all2", capabilities: [.imageFilter]),
            createMockPlugin(id: "com.test.all3", capabilities: [.exportFormat])
        ]
        
        // Register all plugins
        for plugin in plugins {
            _ = await registry.registerPlugin(plugin)
        }
        
        let beforeCount = await registry.getAllPlugins().count
        XCTAssertEqual(beforeCount, 3)
        
        await registry.deregisterAllPlugins()
        
        let afterCount = await registry.getAllPlugins().count
        XCTAssertEqual(afterCount, 0)
    }
    
    // MARK: - Plugin Lookup Tests
    
    func test_PluginRegistry_findsPluginById() async throws {
        let plugin = createMockPlugin(id: "com.test.lookup", capabilities: [.transitionEffect])
        _ = await registry.registerPlugin(plugin)
        
        let foundPlugin = await registry.getPlugin(withId: "com.test.lookup")
        XCTAssertNotNil(foundPlugin)
        XCTAssertEqual(foundPlugin?.metadata.id, "com.test.lookup")
        
        let notFoundPlugin = await registry.getPlugin(withId: "com.test.notfound")
        XCTAssertNil(notFoundPlugin)
    }
    
    func test_PluginRegistry_findsPluginsByCapability() async throws {
        let transitionPlugin1 = createMockPlugin(id: "com.test.transition1", capabilities: [.transitionEffect])
        let transitionPlugin2 = createMockPlugin(id: "com.test.transition2", capabilities: [.transitionEffect])
        let filterPlugin = createMockPlugin(id: "com.test.filter", capabilities: [.imageFilter])
        let multiPlugin = createMockPlugin(id: "com.test.multi", capabilities: [.transitionEffect, .imageFilter])
        
        _ = await registry.registerPlugin(transitionPlugin1)
        _ = await registry.registerPlugin(transitionPlugin2)
        _ = await registry.registerPlugin(filterPlugin)
        _ = await registry.registerPlugin(multiPlugin)
        
        let transitionPlugins = await registry.getPlugins(withCapability: .transitionEffect)
        XCTAssertEqual(transitionPlugins.count, 3) // transition1, transition2, multi
        
        let filterPlugins = await registry.getPlugins(withCapability: .imageFilter)
        XCTAssertEqual(filterPlugins.count, 2) // filter, multi
        
        let exportPlugins = await registry.getPlugins(withCapability: .exportFormat)
        XCTAssertEqual(exportPlugins.count, 0)
    }
    
    func test_PluginRegistry_getAllPlugins() async throws {
        let plugins = [
            createMockPlugin(id: "com.test.getall1", capabilities: [.transitionEffect]),
            createMockPlugin(id: "com.test.getall2", capabilities: [.imageFilter]),
            createMockPlugin(id: "com.test.getall3", capabilities: [.metadataExtractor])
        ]
        
        for plugin in plugins {
            _ = await registry.registerPlugin(plugin)
        }
        
        let allPlugins = await registry.getAllPlugins()
        XCTAssertEqual(allPlugins.count, 3)
        
        let pluginIds = Set(allPlugins.map { $0.metadata.id })
        let expectedIds = Set(["com.test.getall1", "com.test.getall2", "com.test.getall3"])
        XCTAssertEqual(pluginIds, expectedIds)
    }
    
    // MARK: - Plugin State Management Tests
    
    func test_PluginRegistry_tracksPluginActiveState() async throws {
        let plugin = createMockPlugin(id: "com.test.state", capabilities: [.transitionEffect])
        _ = await registry.registerPlugin(plugin)
        
        // Plugin should be active after registration (initialized by default)
        let activePlugins = await registry.getActivePlugins()
        XCTAssertEqual(activePlugins.count, 1)
        
        // Deactivate plugin
        await plugin.cleanup()
        
        // Registry should reflect the state change
        let activePluginsAfter = await registry.getActivePlugins()
        XCTAssertEqual(activePluginsAfter.count, 0)
    }
    
    func test_PluginRegistry_enablesAndDisablesPlugins() async throws {
        let plugin = createMockPlugin(id: "com.test.toggle", capabilities: [.transitionEffect])
        _ = await registry.registerPlugin(plugin)
        
        // Plugin should start enabled
        let isEnabled = await registry.isPluginEnabled(withId: "com.test.toggle")
        XCTAssertTrue(isEnabled)
        
        // Disable plugin
        let disableResult = await registry.setPluginEnabled(withId: "com.test.toggle", enabled: false)
        switch disableResult {
        case .success:
            let isDisabled = await registry.isPluginEnabled(withId: "com.test.toggle")
            XCTAssertFalse(isDisabled)
        case .failure(let error):
            XCTFail("Plugin disable should succeed: \(error)")
        }
        
        // Re-enable plugin
        let enableResult = await registry.setPluginEnabled(withId: "com.test.toggle", enabled: true)
        switch enableResult {
        case .success:
            let isReEnabled = await registry.isPluginEnabled(withId: "com.test.toggle")
            XCTAssertTrue(isReEnabled)
        case .failure(let error):
            XCTFail("Plugin enable should succeed: \(error)")
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func test_PluginRegistry_handlesConcurrentRegistration() async throws {
        // Test concurrent registration of different plugins
        let plugins = (1...20).map { i in
            createMockPlugin(id: "com.test.concurrent\(i)", capabilities: [.transitionEffect])
        }
        
        let results = await withTaskGroup(of: Result<Void, Error>.self) { group in
            for plugin in plugins {
                group.addTask {
                    await self.registry.registerPlugin(plugin)
                }
            }
            
            var results: [Result<Void, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // All registrations should succeed
        let successCount = results.compactMap { result in
            if case .success = result { return true } else { return false }
        }.count
        
        XCTAssertEqual(successCount, 20)
        
        let finalCount = await registry.getAllPlugins().count
        XCTAssertEqual(finalCount, 20)
    }
    
    func test_PluginRegistry_handlesConcurrentDeregistration() async throws {
        // Register plugins first
        let plugins = (1...10).map { i in
            createMockPlugin(id: "com.test.concurrentdereg\(i)", capabilities: [.transitionEffect])
        }
        
        for plugin in plugins {
            _ = await registry.registerPlugin(plugin)
        }
        
        // Concurrently deregister all plugins
        let results = await withTaskGroup(of: Result<Void, Error>.self) { group in
            for i in 1...10 {
                group.addTask {
                    await self.registry.deregisterPlugin(withId: "com.test.concurrentdereg\(i)")
                }
            }
            
            var results: [Result<Void, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // All deregistrations should succeed
        let successCount = results.compactMap { result in
            if case .success = result { return true } else { return false }
        }.count
        
        XCTAssertEqual(successCount, 10)
        
        let finalCount = await registry.getAllPlugins().count
        XCTAssertEqual(finalCount, 0)
    }
    
    func test_PluginRegistry_handlesConcurrentLookups() async throws {
        // Register some plugins
        let plugins = (1...5).map { i in
            createMockPlugin(id: "com.test.lookup\(i)", capabilities: [.transitionEffect])
        }
        
        for plugin in plugins {
            _ = await registry.registerPlugin(plugin)
        }
        
        // Perform concurrent lookups
        let lookupResults = await withTaskGroup(of: (any PluginProtocol)?.self) { group in
            for i in 1...5 {
                group.addTask {
                    await self.registry.getPlugin(withId: "com.test.lookup\(i)")
                }
                group.addTask {
                    let plugins = await self.registry.getPlugins(withCapability: .transitionEffect)
                    return plugins.first
                }
            }
            
            var results: [(any PluginProtocol)?] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // All lookups should find plugins
        let foundCount = lookupResults.compactMap { $0 }.count
        XCTAssertEqual(foundCount, 10) // 5 by ID + 5 by capability
    }
    
    // MARK: - Plugin Lifecycle Integration Tests
    
    func test_PluginRegistry_handlesPluginCleanupOnDeregistration() async throws {
        let plugin = createMockPlugin(id: "com.test.cleanup", capabilities: [.transitionEffect])
        _ = await registry.registerPlugin(plugin)
        
        // Verify plugin is active
        XCTAssertTrue(plugin.isActive)
        
        // Deregister should trigger cleanup
        _ = await registry.deregisterPlugin(withId: "com.test.cleanup")
        
        // Wait a brief moment for async cleanup to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Plugin should be cleaned up
        XCTAssertFalse(plugin.isActive)
    }
    
    func test_PluginRegistry_handlesPluginInitializationFailure() async throws {
        let plugin = createMockPlugin(id: "com.test.initfail", capabilities: [.transitionEffect], shouldFailInit: true)
        
        let result = await registry.registerPlugin(plugin)
        
        switch result {
        case .success:
            XCTFail("Registration of plugin with init failure should fail")
        case .failure(let error):
            XCTAssertTrue(error is PluginError)
        }
        
        let registeredPlugins = await registry.getAllPlugins()
        XCTAssertEqual(registeredPlugins.count, 0)
    }
    
    // MARK: - Performance Tests
    
    func test_PluginRegistry_performsLookupEfficiently() async throws {
        // Register 50 plugins
        for i in 1...50 {
            let plugin = createMockPlugin(id: "com.test.perf\(i)", capabilities: [.transitionEffect])
            _ = await registry.registerPlugin(plugin)
        }
        
        measure {
            let semaphore = DispatchSemaphore(value: 0)
            
            Task {
                // Perform 50 lookups
                for i in 1...50 {
                    _ = await registry.getPlugin(withId: "com.test.perf\(i)")
                }
                semaphore.signal()
            }
            
            semaphore.wait()
        }
        
        await registry.deregisterAllPlugins()
    }
}

// MARK: - Test Helpers

extension PluginRegistryTests {
    
    func createMockPlugin(
        id: String,
        capabilities: Set<PluginCapability>,
        shouldFailInit: Bool = false,
        shouldFailValidation: Bool = false
    ) -> MockPlugin {
        let metadata = PluginMetadata(
            id: id,
            name: "Mock Plugin",
            version: "1.0.0",
            author: "Test Author",
            description: "Test Plugin",
            capabilities: capabilities
        )
        
        let plugin = MockPlugin(
            metadata: metadata,
            shouldFailInit: shouldFailInit,
            shouldFailValidation: shouldFailValidation
        )
        
        // Initialize plugin by default for successful registration
        if !shouldFailInit {
            // For testing purposes, we'll use a synchronous approach
            // In practice, plugins would be initialized when loaded
        }
        
        mockPlugins.append(plugin)
        return plugin
    }
}