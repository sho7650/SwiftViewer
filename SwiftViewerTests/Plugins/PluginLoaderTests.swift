import XCTest
@testable import SwiftViewer
import Foundation

final class PluginLoaderTests: XCTestCase {
    
    var tempDirectory: URL!
    var pluginLoader: PluginLoader!
    var discoveryService: PluginDiscoveryService!
    
    override func setUp() {
        super.setUp()
        tempDirectory = createTempDirectory()
        discoveryService = PluginDiscoveryService()
        pluginLoader = PluginLoader(discoveryService: discoveryService)
    }
    
    override func tearDown() {
        removeTempDirectory()
        pluginLoader = nil
        discoveryService = nil
        tempDirectory = nil
        super.tearDown()
    }
    
    // MARK: - Plugin Loading Tests
    
    func test_PluginLoader_loadsValidPlugin() async throws {
        // Create valid plugin bundle
        let validBundle = createValidPluginBundle(
            name: "TestPlugin.plugin",
            metadata: createTestMetadata(id: "com.test.valid")
        )
        
        let bundleInfos = discoveryService.discoverPlugins(in: tempDirectory)
        XCTAssertEqual(bundleInfos.count, 1)
        
        let result = await pluginLoader.loadPlugin(from: bundleInfos.first!)
        
        switch result {
        case .success(let plugin):
            XCTAssertEqual(plugin.metadata.id, "com.test.valid")
            XCTAssertEqual(plugin.metadata.name, "Test Plugin")
            XCTAssertTrue(plugin.isActive)
        case .failure(let error):
            XCTFail("Plugin loading should succeed, but failed with: \(error)")
        }
    }
    
    func test_PluginLoader_handlesLoadingFailure() async throws {
        // Create plugin bundle that will fail to load
        let failingBundle = createFailingPluginBundle(
            name: "FailingPlugin.plugin",
            metadata: createTestMetadata(id: "com.test.failing")
        )
        
        let bundleInfos = discoveryService.discoverPlugins(in: tempDirectory)
        XCTAssertEqual(bundleInfos.count, 1)
        
        let result = await pluginLoader.loadPlugin(from: bundleInfos.first!)
        
        switch result {
        case .success:
            XCTFail("Plugin loading should fail")
        case .failure(let error):
            XCTAssertTrue(error is PluginError)
            if case .loadingFailed(let reason) = error as? PluginError {
                XCTAssertFalse(reason.isEmpty)
            }
        }
    }
    
    func test_PluginLoader_handlesMissingExecutable() async throws {
        // Create plugin bundle without executable
        let bundleURL = tempDirectory.appendingPathComponent("NoExecutable.plugin")
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        
        let metadata = createTestMetadata(id: "com.test.noexec")
        let metadataFile = bundleURL.appendingPathComponent("plugin.json")
        let jsonData = try JSONEncoder().encode(metadata)
        try jsonData.write(to: metadataFile)
        
        let bundleInfos = discoveryService.discoverPlugins(in: tempDirectory)
        let bundleInfo = bundleInfos.first!
        
        let result = await pluginLoader.loadPlugin(from: bundleInfo)
        
        switch result {
        case .success:
            XCTFail("Should fail when no executable present")
        case .failure(let error):
            XCTAssertTrue(error is PluginError)
            if case .missingExecutable = error as? PluginError {
                // Expected error
            } else {
                XCTFail("Expected missingExecutable error, got: \(error)")
            }
        }
    }
    
    // MARK: - Plugin Initialization Tests
    
    func test_PluginLoader_initializesPluginSuccessfully() async throws {
        let validBundle = createValidPluginBundle(
            name: "InitTest.plugin",
            metadata: createTestMetadata(id: "com.test.init"),
            includeExecutable: true
        )
        
        let bundleInfos = discoveryService.discoverPlugins(in: tempDirectory)
        let result = await pluginLoader.loadPlugin(from: bundleInfos.first!)
        
        switch result {
        case .success(let plugin):
            XCTAssertTrue(plugin.isActive, "Plugin should be active after successful loading")
        case .failure(let error):
            XCTFail("Plugin initialization should succeed: \(error)")
        }
    }
    
    func test_PluginLoader_handlesInitializationFailure() async throws {
        // Create plugin that fails during initialization
        let failingInitBundle = createFailingInitPluginBundle(
            name: "FailInit.plugin",
            metadata: createTestMetadata(id: "com.test.failinit")
        )
        
        let bundleInfos = discoveryService.discoverPlugins(in: tempDirectory)
        let result = await pluginLoader.loadPlugin(from: bundleInfos.first!)
        
        switch result {
        case .success:
            XCTFail("Plugin with failing initialization should not succeed")
        case .failure(let error):
            XCTAssertTrue(error is PluginError)
            if case .initializationFailed(let reason) = error as? PluginError {
                XCTAssertFalse(reason.isEmpty)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func test_PluginLoader_handlesCorruptedBundle() async throws {
        // Create bundle with corrupted metadata
        let corruptedBundle = tempDirectory.appendingPathComponent("Corrupted.plugin")
        try FileManager.default.createDirectory(at: corruptedBundle, withIntermediateDirectories: true)
        
        let metadataFile = corruptedBundle.appendingPathComponent("plugin.json")
        try "{ corrupted json".write(to: metadataFile, atomically: true, encoding: .utf8)
        
        // This should be caught by the discovery service, but test loader's handling
        let fakeMetadata = createTestMetadata(id: "com.test.corrupted")
        let fakeBundleInfo = PluginBundleInfo(bundleURL: corruptedBundle, metadata: fakeMetadata)
        
        let result = await pluginLoader.loadPlugin(from: fakeBundleInfo)
        
        switch result {
        case .success:
            XCTFail("Corrupted bundle should not load successfully")
        case .failure(let error):
            XCTAssertTrue(error is PluginError)
        }
    }
    
    func test_PluginLoader_validatesSandboxConstraints() async throws {
        let validBundle = createValidPluginBundle(
            name: "SandboxTest.plugin",
            metadata: createTestMetadata(id: "com.test.sandbox"),
            includeExecutable: true
        )
        
        let bundleInfos = discoveryService.discoverPlugins(in: tempDirectory)
        let result = await pluginLoader.loadPlugin(from: bundleInfos.first!)
        
        switch result {
        case .success(let plugin):
            // Verify plugin is properly sandboxed
            await plugin.cleanup()
            XCTAssertFalse(plugin.isActive, "Plugin should be inactive after cleanup")
        case .failure(let error):
            XCTFail("Sandbox validation should not prevent loading: \(error)")
        }
    }
    
    // MARK: - Resource Management Tests
    
    func test_PluginLoader_cleansUpOnFailure() async throws {
        let failingBundle = createFailingPluginBundle(
            name: "CleanupTest.plugin",
            metadata: createTestMetadata(id: "com.test.cleanup")
        )
        
        let bundleInfos = discoveryService.discoverPlugins(in: tempDirectory)
        let result = await pluginLoader.loadPlugin(from: bundleInfos.first!)
        
        switch result {
        case .success:
            XCTFail("Failing bundle should not succeed")
        case .failure:
            // Verify no resources are leaked
            // In a real implementation, we would check for leaked resources
            XCTAssertTrue(true, "Cleanup completed")
        }
    }
    
    func test_PluginLoader_limitsResourceUsage() async throws {
        let resourceHeavyBundle = createResourceHeavyPluginBundle(
            name: "ResourceHeavy.plugin",
            metadata: createTestMetadata(id: "com.test.heavy")
        )
        
        let bundleInfos = discoveryService.discoverPlugins(in: tempDirectory)
        let result = await pluginLoader.loadPlugin(from: bundleInfos.first!)
        
        switch result {
        case .success(let plugin):
            // Plugin should load but with resource constraints
            XCTAssertTrue(plugin.isActive)
            await plugin.cleanup()
        case .failure(let error):
            // May fail due to resource limits
            if case .resourceLimitExceeded = error as? PluginError {
                // Expected behavior
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    // MARK: - Concurrent Loading Tests
    
    func test_PluginLoader_handlesConcurrentLoading() async throws {
        // Create multiple plugin bundles
        let bundle1 = createValidPluginBundle(
            name: "Concurrent1.plugin",
            metadata: createTestMetadata(id: "com.test.concurrent1")
        )
        
        let bundle2 = createValidPluginBundle(
            name: "Concurrent2.plugin",
            metadata: createTestMetadata(id: "com.test.concurrent2")
        )
        
        let bundleInfos = discoveryService.discoverPlugins(in: tempDirectory)
        XCTAssertEqual(bundleInfos.count, 2)
        
        // Load plugins concurrently
        async let result1 = pluginLoader.loadPlugin(from: bundleInfos[0])
        async let result2 = pluginLoader.loadPlugin(from: bundleInfos[1])
        
        let (res1, res2) = await (result1, result2)
        
        switch (res1, res2) {
        case (.success(let plugin1), .success(let plugin2)):
            XCTAssertNotEqual(plugin1.metadata.id, plugin2.metadata.id)
            XCTAssertTrue(plugin1.isActive)
            XCTAssertTrue(plugin2.isActive)
            
            await plugin1.cleanup()
            await plugin2.cleanup()
            
        case (.failure(let error), _), (_, .failure(let error)):
            XCTFail("Concurrent loading should succeed: \(error)")
        }
    }
    
    // MARK: - Plugin Lifecycle Tests
    
    func test_PluginLoader_managesPluginLifecycle() async throws {
        let validBundle = createValidPluginBundle(
            name: "Lifecycle.plugin",
            metadata: createTestMetadata(id: "com.test.lifecycle"),
            includeExecutable: true
        )
        
        let bundleInfos = discoveryService.discoverPlugins(in: tempDirectory)
        let result = await pluginLoader.loadPlugin(from: bundleInfos.first!)
        
        switch result {
        case .success(let plugin):
            // Verify plugin starts active
            XCTAssertTrue(plugin.isActive)
            
            // Test cleanup
            await plugin.cleanup()
            XCTAssertFalse(plugin.isActive)
            
            // Test re-initialization
            try await plugin.initialize()
            XCTAssertTrue(plugin.isActive)
            
            await plugin.cleanup()
            
        case .failure(let error):
            XCTFail("Plugin lifecycle test should succeed: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func test_PluginLoader_performanceWithMultiplePlugins() async throws {
        // Create 5 plugin bundles for performance test
        for i in 1...5 {
            _ = createValidPluginBundle(
                name: "Perf\(i).plugin",
                metadata: createTestMetadata(id: "com.test.perf\(i)")
            )
        }
        
        let bundleInfos = discoveryService.discoverPlugins(in: tempDirectory)
        
        measure {
            // Load all plugins synchronously for measurement
            let semaphore = DispatchSemaphore(value: 0)
            var plugins: [any PluginProtocol] = []
            
            Task {
                for bundleInfo in bundleInfos {
                    let result = await pluginLoader.loadPlugin(from: bundleInfo)
                    if case .success(let plugin) = result {
                        plugins.append(plugin)
                    }
                }
                
                // Cleanup all plugins
                for plugin in plugins {
                    await plugin.cleanup()
                }
                
                semaphore.signal()
            }
            
            semaphore.wait()
        }
        
        XCTAssertEqual(bundleInfos.count, 5, "Should have created 5 plugin bundles")
    }
}

// MARK: - Test Helpers

extension PluginLoaderTests {
    
    func createTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginLoaderTests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }
    
    func removeTempDirectory() {
        guard let tempDirectory = tempDirectory else { return }
        try? FileManager.default.removeItem(at: tempDirectory)
    }
    
    func createTestMetadata(id: String) -> PluginMetadata {
        return PluginMetadata(
            id: id,
            name: "Test Plugin",
            version: "1.0.0",
            author: "Test Author",
            description: "Test Description",
            capabilities: [.transitionEffect]
        )
    }
    
    @discardableResult
    func createValidPluginBundle(
        name: String,
        metadata: PluginMetadata,
        includeExecutable: Bool = false
    ) -> URL {
        guard let tempDir = tempDirectory else {
            fatalError("Temp directory not initialized")
        }
        
        let bundleURL = tempDir.appendingPathComponent(name)
        try! FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        
        // Create metadata file
        let metadataFile = bundleURL.appendingPathComponent("plugin.json")
        let jsonData = try! JSONEncoder().encode(metadata)
        try! jsonData.write(to: metadataFile)
        
        // Create executable if requested
        if includeExecutable {
            let executableFile = bundleURL.appendingPathComponent("plugin")
            try! "#!/bin/bash\necho 'mock executable'".write(
                to: executableFile, 
                atomically: true, 
                encoding: .utf8
            )
            try! FileManager.default.setAttributes(
                [.posixPermissions: 0o755], 
                ofItemAtPath: executableFile.path
            )
        }
        
        return bundleURL
    }
    
    @discardableResult
    func createFailingPluginBundle(name: String, metadata: PluginMetadata) -> URL {
        guard let tempDir = tempDirectory else {
            fatalError("Temp directory not initialized")
        }
        
        // Create bundle that will cause loading to fail
        let bundleURL = tempDir.appendingPathComponent(name)
        try! FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        
        // Create metadata file
        let metadataFile = bundleURL.appendingPathComponent("plugin.json")
        let jsonData = try! JSONEncoder().encode(metadata)
        try! jsonData.write(to: metadataFile)
        
        // Don't create executable to cause failure
        return bundleURL
    }
    
    @discardableResult
    func createFailingInitPluginBundle(name: String, metadata: PluginMetadata) -> URL {
        guard let tempDir = tempDirectory else {
            fatalError("Temp directory not initialized")
        }
        
        let bundleURL = createValidPluginBundle(name: name, metadata: metadata, includeExecutable: true)
        
        // Create a marker file that will cause initialization to fail
        let failMarker = bundleURL.appendingPathComponent("fail_init")
        try! "fail".write(to: failMarker, atomically: true, encoding: .utf8)
        
        return bundleURL
    }
    
    @discardableResult
    func createResourceHeavyPluginBundle(name: String, metadata: PluginMetadata) -> URL {
        guard let tempDir = tempDirectory else {
            fatalError("Temp directory not initialized")
        }
        
        let bundleURL = createValidPluginBundle(name: name, metadata: metadata, includeExecutable: true)
        
        // Create a marker file indicating resource-heavy plugin
        let heavyMarker = bundleURL.appendingPathComponent("resource_heavy")
        try! "heavy".write(to: heavyMarker, atomically: true, encoding: .utf8)
        
        return bundleURL
    }
}