import XCTest
@testable import SwiftViewer

final class PluginMetadataTests: XCTestCase {
    
    // MARK: - JSON Serialization Tests
    
    func test_PluginMetadata_encodeToJSON() throws {
        let metadata = PluginMetadata(
            id: "com.example.fade",
            name: "Fade Transition",
            version: "1.2.3",
            author: "Example Corp",
            description: "Smooth fade transition effect",
            capabilities: [.transitionEffect],
            minimumAppVersion: "1.0.0",
            websiteURL: "https://example.com",
            iconName: "fade-icon"
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(metadata)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"id\" : \"com.example.fade\""))
        XCTAssertTrue(jsonString!.contains("\"name\" : \"Fade Transition\""))
        XCTAssertTrue(jsonString!.contains("\"version\" : \"1.2.3\""))
        XCTAssertTrue(jsonString!.contains("\"transition_effect\""))
    }
    
    func test_PluginMetadata_decodeFromJSON() throws {
        let jsonString = """
        {
            "id": "com.example.slide",
            "name": "Slide Transition",
            "version": "2.0.1",
            "author": "Test Author",
            "description": "Slide transition with multiple directions",
            "capabilities": ["transition_effect", "image_filter"],
            "minimumAppVersion": "1.5.0",
            "websiteURL": "https://example.org",
            "iconName": "slide-icon"
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let metadata = try decoder.decode(PluginMetadata.self, from: jsonData)
        
        XCTAssertEqual(metadata.id, "com.example.slide")
        XCTAssertEqual(metadata.name, "Slide Transition")
        XCTAssertEqual(metadata.version, "2.0.1")
        XCTAssertEqual(metadata.author, "Test Author")
        XCTAssertEqual(metadata.description, "Slide transition with multiple directions")
        XCTAssertEqual(metadata.capabilities.count, 2)
        XCTAssertTrue(metadata.capabilities.contains(.transitionEffect))
        XCTAssertTrue(metadata.capabilities.contains(.imageFilter))
        XCTAssertEqual(metadata.minimumAppVersion, "1.5.0")
        XCTAssertEqual(metadata.websiteURL, "https://example.org")
        XCTAssertEqual(metadata.iconName, "slide-icon")
    }
    
    func test_PluginMetadata_roundTripSerialization() throws {
        let original = PluginMetadata(
            id: "com.test.roundtrip",
            name: "Round Trip Test",
            version: "3.0.0",
            author: "Tester",
            description: "Testing round trip serialization",
            capabilities: [.metadataExtractor, .exportFormat],
            minimumAppVersion: "2.0.0",
            websiteURL: nil,
            iconName: nil
        )
        
        // Encode
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(original)
        
        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PluginMetadata.self, from: jsonData)
        
        // Verify equality
        XCTAssertEqual(original, decoded)
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.capabilities, decoded.capabilities)
        XCTAssertEqual(original.minimumAppVersion, decoded.minimumAppVersion)
        XCTAssertNil(decoded.websiteURL)
        XCTAssertNil(decoded.iconName)
    }
    
    // MARK: - Validation Tests
    
    func test_PluginMetadata_validationForMalformedJSON() {
        let malformedJSONs = [
            // Missing required field
            """
            {
                "name": "Missing ID",
                "version": "1.0.0",
                "author": "Test",
                "description": "Test",
                "capabilities": []
            }
            """,
            // Invalid capability
            """
            {
                "id": "test",
                "name": "Test",
                "version": "1.0.0",
                "author": "Test",
                "description": "Test",
                "capabilities": ["invalid_capability"]
            }
            """,
            // Wrong type for capabilities
            """
            {
                "id": "test",
                "name": "Test",
                "version": "1.0.0",
                "author": "Test",
                "description": "Test",
                "capabilities": "should_be_array"
            }
            """
        ]
        
        let decoder = JSONDecoder()
        
        for malformed in malformedJSONs {
            let jsonData = malformed.data(using: .utf8)!
            
            XCTAssertThrowsError(try decoder.decode(PluginMetadata.self, from: jsonData)) { error in
                // Verify that decoding error occurred
                XCTAssertTrue(error is DecodingError)
            }
        }
    }
    
    func test_PluginMetadata_emptyCapabilities() throws {
        let jsonString = """
        {
            "id": "com.example.empty",
            "name": "Empty Capabilities",
            "version": "1.0.0",
            "author": "Test",
            "description": "Plugin with no capabilities",
            "capabilities": []
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let metadata = try decoder.decode(PluginMetadata.self, from: jsonData)
        
        XCTAssertTrue(metadata.capabilities.isEmpty)
        XCTAssertEqual(metadata.id, "com.example.empty")
    }
    
    func test_PluginMetadata_duplicateCapabilitiesHandled() throws {
        // JSON with duplicate capabilities should result in unique set
        let jsonString = """
        {
            "id": "com.example.duplicates",
            "name": "Duplicate Test",
            "version": "1.0.0",
            "author": "Test",
            "description": "Test",
            "capabilities": ["transition_effect", "transition_effect", "image_filter"]
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let metadata = try decoder.decode(PluginMetadata.self, from: jsonData)
        
        // Set should eliminate duplicates
        XCTAssertEqual(metadata.capabilities.count, 2)
        XCTAssertTrue(metadata.capabilities.contains(.transitionEffect))
        XCTAssertTrue(metadata.capabilities.contains(.imageFilter))
    }
    
    // MARK: - Version Validation Tests
    
    func test_PluginMetadata_versionFormats() throws {
        let validVersions = [
            "1.0.0",
            "2.1.3",
            "10.20.30",
            "0.0.1",
            "1.0.0-beta",
            "2.0.0-rc1",
            "3.0.0+build123"
        ]
        
        for version in validVersions {
            let metadata = PluginMetadata(
                id: "test",
                name: "Test",
                version: version,
                author: "Test",
                description: "Test",
                capabilities: []
            )
            
            XCTAssertEqual(metadata.version, version)
        }
    }
    
    // MARK: - Edge Cases
    
    func test_PluginMetadata_unicodeHandling() throws {
        let metadata = PluginMetadata(
            id: "com.example.unicode",
            name: "🎨 Unicode Plugin 日本語",
            version: "1.0.0",
            author: "作者",
            description: "Plugin with émojis and 中文 characters",
            capabilities: [.imageFilter]
        )
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(metadata)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PluginMetadata.self, from: jsonData)
        
        XCTAssertEqual(metadata.name, decoded.name)
        XCTAssertEqual(metadata.author, decoded.author)
        XCTAssertEqual(metadata.description, decoded.description)
    }
    
    func test_PluginMetadata_largeCapabilitySet() throws {
        // Test with all available capabilities
        let allCapabilities = Set(PluginCapability.allCases)
        
        let metadata = PluginMetadata(
            id: "com.example.all",
            name: "All Capabilities",
            version: "1.0.0",
            author: "Test",
            description: "Plugin with all capabilities",
            capabilities: allCapabilities
        )
        
        XCTAssertEqual(metadata.capabilities.count, PluginCapability.allCases.count)
        
        // Test serialization
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(metadata)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PluginMetadata.self, from: jsonData)
        
        XCTAssertEqual(decoded.capabilities, allCapabilities)
    }
}