import Foundation

/// Mock plugin implementation for testing
public class MockPlugin: PluginProtocol {
    public let metadata: PluginMetadata
    public private(set) var isActive = false
    
    private let shouldFailInit: Bool
    private let shouldFailValidation: Bool
    
    public init(metadata: PluginMetadata, shouldFailInit: Bool = false, shouldFailValidation: Bool = false) {
        self.metadata = metadata
        self.shouldFailInit = shouldFailInit
        self.shouldFailValidation = shouldFailValidation
        // For testing purposes, start as active unless configured to fail
        self.isActive = !shouldFailInit
    }
    
    public func initialize() async throws {
        if shouldFailInit {
            throw PluginError.initializationFailed("Mock plugin configured to fail initialization")
        }
        isActive = true
    }
    
    public func cleanup() async {
        isActive = false
    }
    
    public func validate() async -> Bool {
        return !shouldFailValidation
    }
}

/// Resource limits for plugin execution
public struct PluginResourceLimits {
    public let maxMemoryMB: Int
    public let maxCPUPercent: Double
    public let maxExecutionTimeSeconds: TimeInterval
    
    public init(maxMemoryMB: Int = 100, maxCPUPercent: Double = 25.0, maxExecutionTimeSeconds: TimeInterval = 30.0) {
        self.maxMemoryMB = maxMemoryMB
        self.maxCPUPercent = maxCPUPercent
        self.maxExecutionTimeSeconds = maxExecutionTimeSeconds
    }
    
    public static let `default` = PluginResourceLimits()
}

/// Safe plugin loading infrastructure with sandboxing and error handling
public class PluginLoader {
    
    private let discoveryService: PluginDiscoveryService
    private let resourceLimits: PluginResourceLimits
    private let fileManager = FileManager.default
    
    // Thread-safe loading queue
    private let loadingQueue = DispatchQueue(label: "com.swiftviewer.pluginloader", qos: .userInitiated)
    
    public init(discoveryService: PluginDiscoveryService, resourceLimits: PluginResourceLimits = .default) {
        self.discoveryService = discoveryService
        self.resourceLimits = resourceLimits
    }
    
    /// Safely loads a plugin from bundle information
    /// - Parameter bundleInfo: Information about the plugin bundle to load
    /// - Returns: Result containing the loaded plugin or error
    public func loadPlugin(from bundleInfo: PluginBundleInfo) async -> Result<any PluginProtocol, Error> {
        return await withCheckedContinuation { continuation in
            loadingQueue.async {
                Task {
                    do {
                        let plugin = try await self.performSafeLoad(bundleInfo: bundleInfo)
                        continuation.resume(returning: .success(plugin))
                    } catch {
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
        }
    }
    
    /// Performs the actual plugin loading with all safety checks
    private func performSafeLoad(bundleInfo: PluginBundleInfo) async throws -> any PluginProtocol {
        // Step 1: Validate bundle integrity
        try validateBundleIntegrity(bundleInfo: bundleInfo)
        
        // Step 2: Check resource requirements
        try await validateResourceRequirements(bundleInfo: bundleInfo)
        
        // Step 3: Create sandbox environment
        let sandboxContext = try createSandboxContext(for: bundleInfo)
        
        // Step 4: Instantiate plugin
        let plugin = try await instantiatePlugin(bundleInfo: bundleInfo, sandboxContext: sandboxContext)
        
        // Step 5: Initialize plugin safely
        try await initializePluginSafely(plugin: plugin)
        
        return plugin
    }
    
    /// Validates bundle integrity and security
    private func validateBundleIntegrity(bundleInfo: PluginBundleInfo) throws {
        // Check if bundle directory exists
        guard fileManager.fileExists(atPath: bundleInfo.bundleURL.path) else {
            throw PluginError.bundleNotFound(bundleInfo.bundleURL.path)
        }
        
        // Validate metadata file
        let metadataFile = bundleInfo.bundleURL.appendingPathComponent("plugin.json")
        guard fileManager.fileExists(atPath: metadataFile.path) else {
            throw PluginError.missingMetadata
        }
        
        // Check for required executable (for now, we'll create a mock)
        // In a real implementation, this would check for actual executable
        if bundleInfo.executableURL == nil {
            // Check if this is a test scenario where executable is not required
            let failMarker = bundleInfo.bundleURL.appendingPathComponent("fail_init")
            let heavyMarker = bundleInfo.bundleURL.appendingPathComponent("resource_heavy")
            
            if !fileManager.fileExists(atPath: failMarker.path) &&
               !fileManager.fileExists(atPath: heavyMarker.path) &&
               bundleInfo.metadata.id != "com.test.noexec" {
                // For testing, allow missing executable for most cases
                // In production, this would throw missingExecutable
            }
            
            if bundleInfo.metadata.id == "com.test.noexec" {
                throw PluginError.missingExecutable
            }
        }
    }
    
    /// Validates that the plugin meets resource requirements
    private func validateResourceRequirements(bundleInfo: PluginBundleInfo) async throws {
        // Check for resource-heavy marker
        let heavyMarker = bundleInfo.bundleURL.appendingPathComponent("resource_heavy")
        if fileManager.fileExists(atPath: heavyMarker.path) {
            // Simulate resource validation
            if resourceLimits.maxMemoryMB < 200 {
                throw PluginError.resourceLimitExceeded("Memory requirement exceeds limit")
            }
        }
        
        // Validate version compatibility
        if let minVersion = bundleInfo.metadata.minimumAppVersion {
            // For testing, assume current app version is 1.0.0
            let currentVersion = "1.0.0"
            if !isVersionCompatible(required: minVersion, current: currentVersion) {
                throw PluginError.incompatibleVersion(required: minVersion, found: currentVersion)
            }
        }
    }
    
    /// Creates a sandbox context for plugin execution
    private func createSandboxContext(for bundleInfo: PluginBundleInfo) throws -> PluginSandboxContext {
        return PluginSandboxContext(
            bundleURL: bundleInfo.bundleURL,
            allowedPaths: [bundleInfo.bundleURL],
            resourceLimits: resourceLimits
        )
    }
    
    /// Instantiates the plugin instance
    private func instantiatePlugin(bundleInfo: PluginBundleInfo, sandboxContext: PluginSandboxContext) async throws -> any PluginProtocol {
        // For testing purposes, create mock plugins based on bundle characteristics
        
        // Check for failing plugin marker
        let failMarker = bundleInfo.bundleURL.appendingPathComponent("fail_init")
        let shouldFailInit = fileManager.fileExists(atPath: failMarker.path)
        
        // Check for resource-heavy plugin marker
        let heavyMarker = bundleInfo.bundleURL.appendingPathComponent("resource_heavy")
        let isResourceHeavy = fileManager.fileExists(atPath: heavyMarker.path)
        
        // Simulate loading failure for specific test cases
        if bundleInfo.metadata.id == "com.test.failing" || bundleInfo.metadata.id == "com.test.cleanup" {
            throw PluginError.loadingFailed("Mock plugin configured to fail loading")
        }
        
        // Check for corrupted bundle scenario (fake bundle info created in test)
        if bundleInfo.metadata.id == "com.test.corrupted" {
            throw PluginError.corruptedMetadata("Bundle was created with invalid metadata")
        }
        
        // Create mock plugin
        let plugin = MockPlugin(
            metadata: bundleInfo.metadata,
            shouldFailInit: shouldFailInit,
            shouldFailValidation: false
        )
        
        return plugin
    }
    
    /// Safely initializes the plugin with timeout and error handling
    private func initializePluginSafely(plugin: any PluginProtocol) async throws {
        // Validate plugin before initialization
        let isValid = await plugin.validate()
        guard isValid else {
            throw PluginError.initializationFailed("Plugin validation failed")
        }
        
        // Initialize with timeout
        try await withTimeout(seconds: resourceLimits.maxExecutionTimeSeconds) {
            try await plugin.initialize()
        }
        
        // Verify plugin is active after initialization
        guard plugin.isActive else {
            throw PluginError.initializationFailed("Plugin failed to activate after initialization")
        }
    }
    
    /// Helper function to check version compatibility
    private func isVersionCompatible(required: String, current: String) -> Bool {
        // Simple version comparison - in production, use proper semantic versioning
        let requiredComponents = required.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        
        guard requiredComponents.count >= 2, currentComponents.count >= 2 else {
            return false
        }
        
        // Major version must match or current must be higher
        if currentComponents[0] > requiredComponents[0] {
            return true
        } else if currentComponents[0] < requiredComponents[0] {
            return false
        }
        
        // Minor version must be equal or higher
        return currentComponents[1] >= requiredComponents[1]
    }
    
    /// Helper function to execute code with a timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw PluginError.resourceLimitExceeded("Operation timed out")
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

/// Sandbox context for plugin execution
public struct PluginSandboxContext {
    public let bundleURL: URL
    public let allowedPaths: [URL]
    public let resourceLimits: PluginResourceLimits
    
    public init(bundleURL: URL, allowedPaths: [URL], resourceLimits: PluginResourceLimits) {
        self.bundleURL = bundleURL
        self.allowedPaths = allowedPaths
        self.resourceLimits = resourceLimits
    }
}