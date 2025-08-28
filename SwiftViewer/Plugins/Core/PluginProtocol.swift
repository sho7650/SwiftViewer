import Foundation

/// Defines the capabilities a plugin can provide
public enum PluginCapability: String, CaseIterable, Codable {
    /// Plugin provides transition effects between images
    case transitionEffect = "transition_effect"
    
    /// Plugin provides image filtering/processing
    case imageFilter = "image_filter"
    
    /// Plugin extracts metadata from images
    case metadataExtractor = "metadata_extractor"
    
    /// Plugin provides export format conversion
    case exportFormat = "export_format"
}

/// Metadata describing a plugin
public struct PluginMetadata: Codable, Equatable {
    /// Unique identifier for the plugin (reverse DNS format recommended)
    public let id: String
    
    /// Human-readable name of the plugin
    public let name: String
    
    /// Semantic version string (e.g., "1.0.0")
    public let version: String
    
    /// Plugin author or organization
    public let author: String
    
    /// Brief description of what the plugin does
    public let description: String
    
    /// Capabilities this plugin provides
    public let capabilities: Set<PluginCapability>
    
    /// Optional minimum SwiftViewer version required
    public var minimumAppVersion: String?
    
    /// Optional plugin website or documentation URL
    public var websiteURL: String?
    
    /// Optional plugin icon resource name
    public var iconName: String?
    
    public init(
        id: String,
        name: String,
        version: String,
        author: String,
        description: String,
        capabilities: Set<PluginCapability>,
        minimumAppVersion: String? = nil,
        websiteURL: String? = nil,
        iconName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.description = description
        self.capabilities = capabilities
        self.minimumAppVersion = minimumAppVersion
        self.websiteURL = websiteURL
        self.iconName = iconName
    }
}

/// Core protocol that all plugins must conform to
public protocol PluginProtocol: AnyObject {
    /// Plugin metadata containing identification and capability information
    var metadata: PluginMetadata { get }
    
    /// Indicates whether the plugin is currently active
    var isActive: Bool { get }
    
    /// Initialize the plugin and prepare it for use
    /// - Throws: Any initialization errors
    func initialize() async throws
    
    /// Clean up resources and prepare for plugin deactivation
    func cleanup() async
    
    /// Optional: Validate that the plugin can run in the current environment
    /// Default implementation returns true
    func validate() async -> Bool
}

// MARK: - Default Implementations

public extension PluginProtocol {
    /// Default validation always returns true
    func validate() async -> Bool {
        true
    }
}