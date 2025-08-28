import Foundation

/// Thread-safe plugin registry for managing plugin lifecycle
public actor PluginRegistry {
    
    // MARK: - Private Storage
    
    private var plugins: [String: any PluginProtocol] = [:]
    private var pluginStates: [String: PluginState] = [:]
    
    // MARK: - Plugin State
    
    private struct PluginState {
        var isEnabled: Bool
        var registrationDate: Date
        var lastAccessDate: Date
        
        init() {
            self.isEnabled = true
            self.registrationDate = Date()
            self.lastAccessDate = Date()
        }
        
        mutating func updateAccess() {
            self.lastAccessDate = Date()
        }
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Plugin Registration
    
    /// Registers a plugin with the registry
    /// - Parameter plugin: The plugin to register
    /// - Returns: Result indicating success or failure
    public func registerPlugin(_ plugin: any PluginProtocol) -> Result<Void, Error> {
        let pluginId = plugin.metadata.id
        
        // Check if plugin is already registered
        guard plugins[pluginId] == nil else {
            return .failure(PluginError.pluginAlreadyRegistered(id: pluginId))
        }
        
        // Verify plugin is properly initialized
        guard plugin.isActive else {
            return .failure(PluginError.initializationFailed(reason: "Plugin is not active"))
        }
        
        // Register the plugin
        plugins[pluginId] = plugin
        pluginStates[pluginId] = PluginState()
        
        return .success(())
    }
    
    /// Deregisters a plugin from the registry
    /// - Parameter pluginId: ID of the plugin to deregister
    /// - Returns: Result indicating success or failure
    public func deregisterPlugin(withId pluginId: String) -> Result<Void, Error> {
        guard let plugin = plugins[pluginId] else {
            return .failure(PluginError.pluginNotFound(id: pluginId))
        }
        
        // Clean up the plugin
        Task {
            await plugin.cleanup()
        }
        
        // Remove from registry
        plugins.removeValue(forKey: pluginId)
        pluginStates.removeValue(forKey: pluginId)
        
        return .success(())
    }
    
    /// Deregisters all plugins from the registry
    public func deregisterAllPlugins() {
        // Clean up all plugins
        for plugin in plugins.values {
            Task {
                await plugin.cleanup()
            }
        }
        
        // Clear all storage
        plugins.removeAll()
        pluginStates.removeAll()
    }
    
    // MARK: - Plugin Lookup
    
    /// Retrieves a plugin by its ID
    /// - Parameter pluginId: The plugin ID to search for
    /// - Returns: The plugin if found, nil otherwise
    public func getPlugin(withId pluginId: String) -> (any PluginProtocol)? {
        updateAccessDate(for: pluginId)
        return plugins[pluginId]
    }
    
    /// Retrieves all plugins with a specific capability
    /// - Parameter capability: The capability to search for
    /// - Returns: Array of plugins that have the specified capability
    public func getPlugins(withCapability capability: PluginCapability) -> [any PluginProtocol] {
        let matchingPlugins = plugins.values.filter { plugin in
            plugin.metadata.capabilities.contains(capability)
        }
        
        // Update access dates for all matching plugins
        for plugin in matchingPlugins {
            updateAccessDate(for: plugin.metadata.id)
        }
        
        return matchingPlugins
    }
    
    /// Retrieves all registered plugins
    /// - Returns: Array of all registered plugins
    public func getAllPlugins() -> [any PluginProtocol] {
        let allPlugins = Array(plugins.values)
        
        // Update access dates for all plugins
        for plugin in allPlugins {
            updateAccessDate(for: plugin.metadata.id)
        }
        
        return allPlugins
    }
    
    /// Retrieves all active (running) plugins
    /// - Returns: Array of plugins that are currently active
    public func getActivePlugins() -> [any PluginProtocol] {
        let activePlugins = plugins.values.filter { $0.isActive }
        
        // Update access dates for active plugins
        for plugin in activePlugins {
            updateAccessDate(for: plugin.metadata.id)
        }
        
        return activePlugins
    }
    
    /// Retrieves all enabled plugins (may be active or inactive)
    /// - Returns: Array of plugins that are enabled
    public func getEnabledPlugins() -> [any PluginProtocol] {
        let enabledPlugins = plugins.compactMap { (pluginId, plugin) in
            pluginStates[pluginId]?.isEnabled == true ? plugin : nil
        }
        
        // Update access dates for enabled plugins
        for plugin in enabledPlugins {
            updateAccessDate(for: plugin.metadata.id)
        }
        
        return enabledPlugins
    }
    
    // MARK: - Plugin State Management
    
    /// Checks if a plugin is enabled
    /// - Parameter pluginId: The plugin ID to check
    /// - Returns: true if the plugin is enabled, false otherwise
    public func isPluginEnabled(withId pluginId: String) -> Bool {
        return pluginStates[pluginId]?.isEnabled ?? false
    }
    
    /// Enables or disables a plugin
    /// - Parameters:
    ///   - pluginId: The plugin ID to modify
    ///   - enabled: Whether the plugin should be enabled
    /// - Returns: Result indicating success or failure
    public func setPluginEnabled(withId pluginId: String, enabled: Bool) -> Result<Void, Error> {
        guard plugins[pluginId] != nil else {
            return .failure(PluginError.pluginNotFound(id: pluginId))
        }
        
        guard var state = pluginStates[pluginId] else {
            return .failure(PluginError.pluginNotFound(id: pluginId))
        }
        
        state.isEnabled = enabled
        state.updateAccess()
        pluginStates[pluginId] = state
        
        return .success(())
    }
    
    // MARK: - Registry Statistics
    
    /// Gets the total number of registered plugins
    /// - Returns: Count of registered plugins
    public func getPluginCount() -> Int {
        return plugins.count
    }
    
    /// Gets the number of active plugins
    /// - Returns: Count of active plugins
    public func getActivePluginCount() -> Int {
        return plugins.values.filter { $0.isActive }.count
    }
    
    /// Gets the number of enabled plugins
    /// - Returns: Count of enabled plugins
    public func getEnabledPluginCount() -> Int {
        return pluginStates.values.filter { $0.isEnabled }.count
    }
    
    /// Gets plugins grouped by capability
    /// - Returns: Dictionary mapping capabilities to plugin arrays
    public func getPluginsByCapability() -> [PluginCapability: [any PluginProtocol]] {
        var result: [PluginCapability: [any PluginProtocol]] = [:]
        
        for plugin in plugins.values {
            for capability in plugin.metadata.capabilities {
                if result[capability] == nil {
                    result[capability] = []
                }
                result[capability]?.append(plugin)
            }
        }
        
        return result
    }
    
    // MARK: - Plugin Validation
    
    /// Validates all registered plugins
    /// - Returns: Array of plugin IDs that failed validation
    public func validateAllPlugins() async -> [String] {
        var failedPlugins: [String] = []
        
        for (pluginId, plugin) in plugins {
            let isValid = await plugin.validate()
            if !isValid {
                failedPlugins.append(pluginId)
            }
        }
        
        return failedPlugins
    }
    
    /// Validates a specific plugin
    /// - Parameter pluginId: The plugin ID to validate
    /// - Returns: true if the plugin is valid, false otherwise
    public func validatePlugin(withId pluginId: String) async -> Bool {
        guard let plugin = plugins[pluginId] else {
            return false
        }
        
        updateAccessDate(for: pluginId)
        return await plugin.validate()
    }
    
    // MARK: - Plugin Dependencies
    
    /// Checks if all plugin dependencies are satisfied
    /// - Parameter pluginId: The plugin ID to check
    /// - Returns: Array of missing dependency IDs (empty if all satisfied)
    public func getMissingDependencies(for pluginId: String) -> [String] {
        // For now, return empty array as dependency system is not implemented
        // In a full implementation, this would check plugin dependencies
        return []
    }
    
    /// Gets plugins that depend on the specified plugin
    /// - Parameter pluginId: The plugin ID to check
    /// - Returns: Array of dependent plugins
    public func getDependentPlugins(for pluginId: String) -> [any PluginProtocol] {
        // For now, return empty array as dependency system is not implemented
        // In a full implementation, this would check reverse dependencies
        return []
    }
    
    // MARK: - Private Helper Methods
    
    private func updateAccessDate(for pluginId: String) {
        pluginStates[pluginId]?.updateAccess()
    }
    
    // MARK: - Registry Cleanup
    
    /// Removes inactive plugins that haven't been accessed recently
    /// - Parameter inactiveThreshold: Time threshold for considering plugins inactive
    public func cleanupInactivePlugins(olderThan inactiveThreshold: TimeInterval = 3600) { // 1 hour default
        let cutoffDate = Date().addingTimeInterval(-inactiveThreshold)
        
        let inactivePluginIds = pluginStates.compactMap { (pluginId, state) in
            if state.lastAccessDate < cutoffDate && plugins[pluginId]?.isActive == false {
                return pluginId
            }
            return nil
        }
        
        for pluginId in inactivePluginIds {
            _ = deregisterPlugin(withId: pluginId)
        }
    }
    
    /// Gets registry statistics
    /// - Returns: Dictionary containing registry statistics
    public func getRegistryStatistics() -> [String: Any] {
        let activeCount = getActivePluginCount()
        let enabledCount = getEnabledPluginCount()
        let totalCount = getPluginCount()
        let capabilityGroups = getPluginsByCapability()
        
        return [
            "totalPlugins": totalCount,
            "activePlugins": activeCount,
            "enabledPlugins": enabledCount,
            "inactivePlugins": totalCount - activeCount,
            "disabledPlugins": totalCount - enabledCount,
            "capabilityGroups": capabilityGroups.mapValues { $0.count },
            "oldestRegistration": pluginStates.values.map { $0.registrationDate }.min() ?? Date(),
            "newestRegistration": pluginStates.values.map { $0.registrationDate }.max() ?? Date()
        ]
    }
}