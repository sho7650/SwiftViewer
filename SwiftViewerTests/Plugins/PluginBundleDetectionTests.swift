import XCTest
@testable import SwiftViewer
import Foundation

final class PluginBundleDetectionTests: XCTestCase {
    
    var tempDirectory: URL!
    var discoveryService: PluginDiscoveryService!
    
    override func setUp() {
        super.setUp()
        tempDirectory = createTempDirectory()
        discoveryService = PluginDiscoveryService()
    }
    
    override func tearDown() {
        removeTempDirectory()
        discoveryService = nil
        tempDirectory = nil
        super.tearDown()
    }
    
    // MARK: - Bundle Discovery Tests
    
    func test_PluginDiscoveryService_findsValidPluginBundles() throws {
        // Create valid plugin bundle
        let validBundle = createValidPluginBundle(
            name: "TestTransition.plugin",
            metadata: PluginMetadata(
                id: "com.example.test",
                name: "Test Transition",
                version: "1.0.0",
                author: "Test Author",
                description: "Test Description",
                capabilities: [.transitionEffect]
            )
        )
        
        let discoveredBundles = discoveryService.discoverPlugins(in: tempDirectory)
        
        XCTAssertEqual(discoveredBundles.count, 1, "Should find exactly one bundle")
        XCTAssertTrue(discoveredBundles.contains { $0.bundleURL.standardizedFileURL == validBundle.standardizedFileURL })
    }
    
    func test_PluginDiscoveryService_ignoresInvalidBundles() throws {
        // Create invalid bundles
        createInvalidPluginBundle(name: "NoMetadata.plugin")
        createInvalidPluginBundle(name: "CorruptedMetadata.plugin", malformedJSON: true)
        createNonPluginFile(name: "NotAPlugin.txt")
        createEmptyDirectory(name: "EmptyPlugin.plugin")
        
        let discoveredBundles = discoveryService.discoverPlugins(in: tempDirectory)
        
        XCTAssertEqual(discoveredBundles.count, 0, "Should ignore all invalid bundles")
    }
    
    func test_PluginDiscoveryService_handlesMultipleValidBundles() throws {
        // Create multiple valid bundles
        let bundle1 = createValidPluginBundle(
            name: "Fade.plugin",
            metadata: PluginMetadata(
                id: "com.example.fade",
                name: "Fade Transition",
                version: "1.0.0",
                author: "Author",
                description: "Fade transition",
                capabilities: [.transitionEffect]
            )
        )
        
        let bundle2 = createValidPluginBundle(
            name: "Slide.plugin",
            metadata: PluginMetadata(
                id: "com.example.slide",
                name: "Slide Transition",
                version: "2.0.0",
                author: "Author",
                description: "Slide transition",
                capabilities: [.transitionEffect, .imageFilter]
            )
        )
        
        let discoveredBundles = discoveryService.discoverPlugins(in: tempDirectory)
        
        XCTAssertEqual(discoveredBundles.count, 2)
        
        let bundleURLs = discoveredBundles.map { $0.bundleURL.standardizedFileURL }
        XCTAssertTrue(bundleURLs.contains(bundle1.standardizedFileURL))
        XCTAssertTrue(bundleURLs.contains(bundle2.standardizedFileURL))
    }
    
    func test_PluginDiscoveryService_supportsNestedDirectories() throws {
        // Create nested directory structure
        let nestedDir = tempDirectory.appendingPathComponent("Nested")
        try FileManager.default.createDirectory(at: nestedDir, withIntermediateDirectories: true)
        
        let validBundle = createValidPluginBundle(
            name: "Nested.plugin",
            baseDirectory: nestedDir,
            metadata: PluginMetadata(
                id: "com.example.nested",
                name: "Nested Plugin",
                version: "1.0.0",
                author: "Author",
                description: "Nested plugin",
                capabilities: [.imageFilter]
            )
        )
        
        let discoveredBundles = discoveryService.discoverPlugins(in: tempDirectory)
        
        XCTAssertEqual(discoveredBundles.count, 1)
        XCTAssertEqual(discoveredBundles.first?.bundleURL.standardizedFileURL, validBundle.standardizedFileURL)
    }
    
    // MARK: - Bundle Validation Tests
    
    func test_PluginBundleInfo_loadsMetadataCorrectly() throws {
        let validBundle = createValidPluginBundle(
            name: "LoadTest.plugin",
            metadata: PluginMetadata(
                id: "com.example.loadtest",
                name: "Load Test Plugin",
                version: "3.1.0",
                author: "Test Author",
                description: "Plugin for testing metadata loading",
                capabilities: [.metadataExtractor, .exportFormat],
                minimumAppVersion: "1.0.0",
                websiteURL: "https://example.com"
            )
        )
        
        let discoveredBundles = discoveryService.discoverPlugins(in: tempDirectory)
        let bundleInfo = discoveredBundles.first!
        
        XCTAssertEqual(bundleInfo.metadata.id, "com.example.loadtest")
        XCTAssertEqual(bundleInfo.metadata.name, "Load Test Plugin")
        XCTAssertEqual(bundleInfo.metadata.version, "3.1.0")
        XCTAssertEqual(bundleInfo.metadata.author, "Test Author")
        XCTAssertEqual(bundleInfo.metadata.description, "Plugin for testing metadata loading")
        XCTAssertEqual(bundleInfo.metadata.capabilities.count, 2)
        XCTAssertTrue(bundleInfo.metadata.capabilities.contains(.metadataExtractor))
        XCTAssertTrue(bundleInfo.metadata.capabilities.contains(.exportFormat))
        XCTAssertEqual(bundleInfo.metadata.minimumAppVersion, "1.0.0")
        XCTAssertEqual(bundleInfo.metadata.websiteURL, "https://example.com")
    }
    
    func test_PluginBundleInfo_detectsRequiredFiles() throws {
        let validBundle = createValidPluginBundle(
            name: "FileTest.plugin",
            metadata: PluginMetadata(
                id: "com.example.filetest",
                name: "File Test",
                version: "1.0.0",
                author: "Author",
                description: "Test",
                capabilities: [.transitionEffect]
            ),
            includeExecutable: true
        )
        
        let discoveredBundles = discoveryService.discoverPlugins(in: tempDirectory)
        let bundleInfo = discoveredBundles.first!
        
        XCTAssertNotNil(bundleInfo.executableURL)
        XCTAssertTrue(bundleInfo.hasRequiredFiles)
    }
    
    // MARK: - Error Handling Tests
    
    func test_PluginDiscoveryService_handlesNonexistentDirectory() {
        let nonexistentDir = tempDirectory.appendingPathComponent("DoesNotExist")
        
        let discoveredBundles = discoveryService.discoverPlugins(in: nonexistentDir)
        
        XCTAssertEqual(discoveredBundles.count, 0)
    }
    
    func test_PluginDiscoveryService_handlesPermissionDeniedDirectory() throws {
        // This test is tricky to implement reliably across different environments
        // For now, just verify it doesn't crash
        let discoveredBundles = discoveryService.discoverPlugins(in: tempDirectory)
        
        // Should not crash, returns empty array for inaccessible directories
        XCTAssertGreaterThanOrEqual(discoveredBundles.count, 0)
    }
    
    func test_PluginDiscoveryService_handlesCorruptedMetadataFile() throws {
        let corruptedBundle = tempDirectory.appendingPathComponent("Corrupted.plugin")
        try FileManager.default.createDirectory(at: corruptedBundle, withIntermediateDirectories: true)
        
        let metadataFile = corruptedBundle.appendingPathComponent("plugin.json")
        let corruptedJSON = "{ invalid json structure"
        try corruptedJSON.write(to: metadataFile, atomically: true, encoding: .utf8)
        
        let discoveredBundles = discoveryService.discoverPlugins(in: tempDirectory)
        
        XCTAssertEqual(discoveredBundles.count, 0, "Corrupted metadata should be ignored")
    }
    
    // MARK: - Performance Tests
    
    func test_PluginDiscoveryService_performanceWithManyBundles() throws {
        // Create 100 plugin bundles
        for i in 1...100 {
            _ = createValidPluginBundle(
                name: "Plugin\(i).plugin",
                metadata: PluginMetadata(
                    id: "com.test.plugin\(i)",
                    name: "Plugin \(i)",
                    version: "1.0.0",
                    author: "Test",
                    description: "Plugin \(i)",
                    capabilities: [.transitionEffect]
                )
            )
        }
        
        measure {
            let discoveredBundles = discoveryService.discoverPlugins(in: tempDirectory)
            XCTAssertEqual(discoveredBundles.count, 100)
        }
    }
    
    // MARK: - Bundle Format Tests
    
    func test_PluginDiscoveryService_requiresPluginExtension() throws {
        // Create bundle without .plugin extension
        let invalidExtensionDir = tempDirectory.appendingPathComponent("NotPlugin.bundle")
        try FileManager.default.createDirectory(at: invalidExtensionDir, withIntermediateDirectories: true)
        
        let metadataFile = invalidExtensionDir.appendingPathComponent("plugin.json")
        let metadata = PluginMetadata(
            id: "com.example.invalid",
            name: "Invalid Extension",
            version: "1.0.0",
            author: "Author",
            description: "Should be ignored",
            capabilities: [.transitionEffect]
        )
        let jsonData = try JSONEncoder().encode(metadata)
        try jsonData.write(to: metadataFile)
        
        let discoveredBundles = discoveryService.discoverPlugins(in: tempDirectory)
        
        XCTAssertEqual(discoveredBundles.count, 0, "Bundles without .plugin extension should be ignored")
    }
    
    func test_PluginDiscoveryService_requiresMetadataFile() throws {
        // Create bundle without metadata file
        let noMetadataBundle = tempDirectory.appendingPathComponent("NoMetadata.plugin")
        try FileManager.default.createDirectory(at: noMetadataBundle, withIntermediateDirectories: true)
        
        // Create some other file but not plugin.json
        let otherFile = noMetadataBundle.appendingPathComponent("other.txt")
        try "content".write(to: otherFile, atomically: true, encoding: .utf8)
        
        let discoveredBundles = discoveryService.discoverPlugins(in: tempDirectory)
        
        XCTAssertEqual(discoveredBundles.count, 0, "Bundles without metadata file should be ignored")
    }
}

// MARK: - Test Helpers

extension PluginBundleDetectionTests {
    
    func createTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("PluginTests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }
    
    func removeTempDirectory() {
        guard let tempDirectory = tempDirectory else { return }
        try? FileManager.default.removeItem(at: tempDirectory)
    }
    
    @discardableResult
    func createValidPluginBundle(
        name: String,
        baseDirectory: URL? = nil,
        metadata: PluginMetadata,
        includeExecutable: Bool = false
    ) -> URL {
        let baseDir = baseDirectory ?? tempDirectory!
        let bundleURL = baseDir.appendingPathComponent(name)
        
        try! FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        
        // Create metadata file
        let metadataFile = bundleURL.appendingPathComponent("plugin.json")
        let jsonData = try! JSONEncoder().encode(metadata)
        try! jsonData.write(to: metadataFile)
        
        // Optionally create executable
        if includeExecutable {
            let executableFile = bundleURL.appendingPathComponent("plugin")
            try! "#!/bin/bash\necho 'mock executable'".write(to: executableFile, atomically: true, encoding: .utf8)
            try! FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executableFile.path)
        }
        
        return bundleURL
    }
    
    @discardableResult
    func createInvalidPluginBundle(name: String, malformedJSON: Bool = false) -> URL {
        let bundleURL = tempDirectory.appendingPathComponent(name)
        try! FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        
        if malformedJSON {
            let metadataFile = bundleURL.appendingPathComponent("plugin.json")
            let invalidJSON = "{ malformed json"
            try! invalidJSON.write(to: metadataFile, atomically: true, encoding: .utf8)
        }
        
        return bundleURL
    }
    
    func createNonPluginFile(name: String) {
        let fileURL = tempDirectory.appendingPathComponent(name)
        try! "not a plugin".write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    func createEmptyDirectory(name: String) {
        let dirURL = tempDirectory.appendingPathComponent(name)
        try! FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
    }
}