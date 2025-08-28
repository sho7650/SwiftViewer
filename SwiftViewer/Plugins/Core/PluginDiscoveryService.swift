import Foundation

/// Information about a discovered plugin bundle
public struct PluginBundleInfo: Equatable {
    /// URL to the plugin bundle directory
    public let bundleURL: URL
    
    /// Plugin metadata loaded from plugin.json
    public let metadata: PluginMetadata
    
    /// URL to the main executable file (if present)
    public let executableURL: URL?
    
    /// Whether the bundle contains all required files
    public var hasRequiredFiles: Bool {
        // At minimum, must have metadata file
        let metadataFile = bundleURL.appendingPathComponent("plugin.json")
        return FileManager.default.fileExists(atPath: metadataFile.path)
    }
    
    public init(bundleURL: URL, metadata: PluginMetadata, executableURL: URL? = nil) {
        self.bundleURL = bundleURL
        self.metadata = metadata
        self.executableURL = executableURL
    }
    
    public static func == (lhs: PluginBundleInfo, rhs: PluginBundleInfo) -> Bool {
        lhs.bundleURL == rhs.bundleURL &&
        lhs.metadata == rhs.metadata &&
        lhs.executableURL == rhs.executableURL
    }
}

/// Service for discovering plugin bundles in the file system
public class PluginDiscoveryService {
    
    private let fileManager = FileManager.default
    private let jsonDecoder: JSONDecoder
    
    public init() {
        self.jsonDecoder = JSONDecoder()
    }
    
    /// Discovers all valid plugin bundles in the specified directory
    /// - Parameter directory: Directory to scan for plugin bundles
    /// - Returns: Array of discovered plugin bundle information
    public func discoverPlugins(in directory: URL) -> [PluginBundleInfo] {
        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }
        
        var discoveredBundles: [PluginBundleInfo] = []
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            // Process each item in the directory
            for url in contents {
                if let bundleInfo = processPotentialBundle(at: url) {
                    discoveredBundles.append(bundleInfo)
                }
            }
            
            // Recursively scan subdirectories
            for url in contents {
                if isDirectory(url) && !isPluginBundle(url) {
                    let nestedBundles = discoverPlugins(in: url)
                    discoveredBundles.append(contentsOf: nestedBundles)
                }
            }
            
        } catch {
            // Directory is not accessible or another error occurred
            // Return empty array without crashing
            return []
        }
        
        return discoveredBundles
    }
    
    /// Processes a potential plugin bundle and returns bundle info if valid
    /// - Parameter url: URL to potential plugin bundle
    /// - Returns: PluginBundleInfo if valid, nil otherwise
    private func processPotentialBundle(at url: URL) -> PluginBundleInfo? {
        // Must be a directory with .plugin extension
        guard isDirectory(url) && isPluginBundle(url) else {
            return nil
        }
        
        // Must have plugin.json metadata file
        let metadataFile = url.appendingPathComponent("plugin.json")
        guard fileManager.fileExists(atPath: metadataFile.path) else {
            return nil
        }
        
        // Load and validate metadata
        guard let metadata = loadMetadata(from: metadataFile) else {
            return nil
        }
        
        // Check for executable file
        let executableFile = url.appendingPathComponent("plugin")
        let executableURL = fileManager.fileExists(atPath: executableFile.path) ? executableFile : nil
        
        return PluginBundleInfo(
            bundleURL: url,
            metadata: metadata,
            executableURL: executableURL
        )
    }
    
    /// Loads plugin metadata from a JSON file
    /// - Parameter metadataFile: URL to the plugin.json file
    /// - Returns: PluginMetadata if successfully loaded, nil otherwise
    private func loadMetadata(from metadataFile: URL) -> PluginMetadata? {
        do {
            let data = try Data(contentsOf: metadataFile)
            let metadata = try jsonDecoder.decode(PluginMetadata.self, from: data)
            return metadata
        } catch {
            // Invalid JSON or decoding error
            return nil
        }
    }
    
    /// Checks if the URL points to a directory
    /// - Parameter url: URL to check
    /// - Returns: true if URL is a directory, false otherwise
    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    /// Checks if the URL represents a plugin bundle (has .plugin extension)
    /// - Parameter url: URL to check
    /// - Returns: true if URL has .plugin extension, false otherwise
    private func isPluginBundle(_ url: URL) -> Bool {
        return url.pathExtension.lowercased() == "plugin"
    }
}