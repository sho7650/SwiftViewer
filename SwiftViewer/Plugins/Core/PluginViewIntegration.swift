import SwiftUI
import Foundation
import os

/// Errors specific to plugin view operations
public enum PluginViewError: Error, LocalizedError, Equatable {
    case pluginNotFound(String)
    case viewInitializationFailed(reason: String)
    case viewActivationFailed(reason: String)
    case unsupportedViewType
    case invalidViewState
    case containerNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .pluginNotFound(let pluginId):
            return "Plugin view not found: \(pluginId)"
        case .viewInitializationFailed(let reason):
            return "Plugin view initialization failed: \(reason)"
        case .viewActivationFailed(let reason):
            return "Plugin view activation failed: \(reason)"
        case .unsupportedViewType:
            return "Unsupported plugin view type"
        case .invalidViewState:
            return "Invalid plugin view state"
        case .containerNotAvailable:
            return "Plugin view container is not available"
        }
    }
    
    public static func == (lhs: PluginViewError, rhs: PluginViewError) -> Bool {
        switch (lhs, rhs) {
        case (.pluginNotFound(let id1), .pluginNotFound(let id2)):
            return id1 == id2
        case (.viewInitializationFailed(let reason1), .viewInitializationFailed(let reason2)):
            return reason1 == reason2
        case (.viewActivationFailed(let reason1), .viewActivationFailed(let reason2)):
            return reason1 == reason2
        case (.unsupportedViewType, .unsupportedViewType),
             (.invalidViewState, .invalidViewState),
             (.containerNotAvailable, .containerNotAvailable):
            return true
        default:
            return false
        }
    }
}

/// Positions where plugin views can be displayed
public enum PluginViewPosition: String, CaseIterable, Codable {
    case sidebar = "sidebar"
    case overlay = "overlay"
    case toolbar = "toolbar"
    case statusBar = "status_bar"
    case contextMenu = "context_menu"
    case inspector = "inspector"
}

/// Information about a plugin view for positioning and management
public struct PluginViewInfo {
    public let pluginId: String
    public let position: PluginViewPosition
    public let priorityOrder: Int
    public let isActive: Bool
    public let view: AnyView?
    
    public init(
        pluginId: String,
        position: PluginViewPosition,
        priorityOrder: Int = 0,
        isActive: Bool = false,
        view: AnyView? = nil
    ) {
        self.pluginId = pluginId
        self.position = position
        self.priorityOrder = priorityOrder
        self.isActive = isActive
        self.view = view
    }
}

/// Protocol for plugins that provide SwiftUI views
public protocol PluginViewProtocol: PluginProtocol {
    /// Create the SwiftUI view for this plugin
    /// - Returns: The plugin's SwiftUI view wrapped in AnyView
    /// - Throws: PluginViewError if view creation fails
    func createView() throws -> AnyView
    
    /// Get the preferred position for this plugin's view
    /// - Returns: The preferred view position
    func getViewPosition() -> PluginViewPosition
    
    /// Get the current view state for persistence
    /// - Returns: Dictionary containing the current view state
    func getViewState() -> [String: Any]
    
    /// Restore view state from saved data
    /// - Parameter state: Previously saved view state
    func restoreViewState(_ state: [String: Any])
}

/// Environment values for plugin views
public struct PluginEnvironmentValues {
    public let pluginContainer: PluginViewContainer?
    public let pluginEventSystem: PluginEventSystem?
    
    public init(
        pluginContainer: PluginViewContainer? = nil,
        pluginEventSystem: PluginEventSystem? = nil
    ) {
        self.pluginContainer = pluginContainer
        self.pluginEventSystem = pluginEventSystem
    }
}

/// Manages plugin view lifecycle and integration with SwiftUI
@MainActor
public final class PluginViewContainerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var registeredPlugins: [String: PluginViewProtocol] = [:]
    @Published public var activePlugins: Set<String> = []
    @Published public var viewStates: [String: [String: Any]] = [:]
    
    // MARK: - Private Properties
    
    private let logger: Logger
    private var pluginViews: [String: AnyView] = [:]
    private var viewPositions: [String: PluginViewPosition] = [:]
    private var priorityCounter: Int = 0
    
    // MARK: - Initialization
    
    public init() {
        self.logger = Logger()
        logger.info("PluginViewContainerViewModel initialized")
    }
    
    // MARK: - Plugin Registration
    
    /// Register a plugin that provides views
    /// - Parameter plugin: The plugin to register
    public func registerPluginView(plugin: PluginViewProtocol) {
        let pluginId = plugin.metadata.id
        logger.debug("Registering plugin view: \(pluginId)")
        
        registeredPlugins[pluginId] = plugin
        viewPositions[pluginId] = plugin.getViewPosition()
        
        // Create view immediately upon registration for testing purposes
        do {
            let view = try plugin.createView()
            pluginViews[pluginId] = view
        } catch {
            logger.error("Failed to create view for plugin \(pluginId): \(error.localizedDescription)")
        }
        
        // Restore saved state if available
        if let savedState = viewStates[pluginId] {
            plugin.restoreViewState(savedState)
        }
        
        logger.info("Plugin view registered: \(pluginId)")
    }
    
    /// Unregister a plugin view
    /// - Parameter pluginId: ID of the plugin to unregister
    public func unregisterPluginView(pluginId: String) {
        logger.debug("Unregistering plugin view: \(pluginId)")
        
        // Save current state before unregistering
        if let plugin = registeredPlugins[pluginId] {
            viewStates[pluginId] = plugin.getViewState()
        }
        
        registeredPlugins.removeValue(forKey: pluginId)
        pluginViews.removeValue(forKey: pluginId)
        viewPositions.removeValue(forKey: pluginId)
        activePlugins.remove(pluginId)
        
        logger.info("Plugin view unregistered: \(pluginId)")
    }
    
    // MARK: - Plugin Lifecycle
    
    /// Activate a plugin view
    /// - Parameter pluginId: ID of the plugin to activate
    /// - Throws: PluginViewError if activation fails
    public func activatePluginView(pluginId: String) async throws {
        logger.debug("Activating plugin view: \(pluginId)")
        
        guard let plugin = registeredPlugins[pluginId] else {
            throw PluginViewError.pluginNotFound(pluginId)
        }
        
        do {
            // Initialize plugin if not already active
            if !plugin.isActive {
                try await plugin.initialize()
            }
            
            // Create the view
            let view = try plugin.createView()
            pluginViews[pluginId] = view
            activePlugins.insert(pluginId)
            
            logger.info("Plugin view activated: \(pluginId)")
            
        } catch let error as PluginViewError {
            throw error
        } catch {
            throw PluginViewError.viewActivationFailed(reason: error.localizedDescription)
        }
    }
    
    /// Deactivate a plugin view
    /// - Parameter pluginId: ID of the plugin to deactivate
    public func deactivatePluginView(pluginId: String) async {
        logger.debug("Deactivating plugin view: \(pluginId)")
        
        guard let plugin = registeredPlugins[pluginId] else {
            logger.warning("Attempted to deactivate unregistered plugin: \(pluginId)")
            return
        }
        
        // Save current state
        viewStates[pluginId] = plugin.getViewState()
        
        // Remove from active set and clear view
        activePlugins.remove(pluginId)
        pluginViews.removeValue(forKey: pluginId)
        
        // Always cleanup plugin to ensure proper state
        await plugin.cleanup()
        
        logger.info("Plugin view deactivated: \(pluginId)")
    }
    
    // MARK: - View Access
    
    /// Get the view for a specific plugin
    /// - Parameter pluginId: ID of the plugin
    /// - Returns: The plugin's view if active, nil otherwise
    public func getPluginView(for pluginId: String) -> AnyView? {
        return pluginViews[pluginId]
    }
    
    /// Get all injectable views
    /// - Parameter activeOnly: Whether to return only active views
    /// - Returns: Array of plugin view information
    public func getInjectableViews(activeOnly: Bool = false) -> [PluginViewInfo] {
        let pluginsToProcess = activeOnly ? 
            registeredPlugins.filter { activePlugins.contains($0.key) } :
            registeredPlugins
        
        return pluginsToProcess.compactMap { (pluginId, plugin) in
            let position = viewPositions[pluginId] ?? .sidebar
            let priorityOrder = getPriorityOrder(for: pluginId, position: position)
            let isActive = activePlugins.contains(pluginId)
            let view = pluginViews[pluginId]
            
            return PluginViewInfo(
                pluginId: pluginId,
                position: position,
                priorityOrder: priorityOrder,
                isActive: isActive,
                view: view
            )
        }.sorted { $0.priorityOrder < $1.priorityOrder }
    }
    
    /// Get view information for a specific plugin
    /// - Parameter pluginId: ID of the plugin
    /// - Returns: Plugin view information if registered
    public func getPluginViewInfo(for pluginId: String) -> PluginViewInfo? {
        guard registeredPlugins[pluginId] != nil else { return nil }
        
        let position = viewPositions[pluginId] ?? .sidebar
        let priorityOrder = getPriorityOrder(for: pluginId, position: position)
        let isActive = activePlugins.contains(pluginId)
        let view = pluginViews[pluginId]
        
        return PluginViewInfo(
            pluginId: pluginId,
            position: position,
            priorityOrder: priorityOrder,
            isActive: isActive,
            view: view
        )
    }
    
    // MARK: - Position Management
    
    /// Resolve view positions to handle conflicts
    /// - Returns: Array of resolved plugin view information
    public func resolveViewPositions() -> [PluginViewInfo] {
        let allViews = getInjectableViews()
        var resolvedViews: [PluginViewInfo] = []
        var positionCounters: [PluginViewPosition: Int] = [:]
        
        // Group by position and assign priority orders
        let groupedByPosition = Dictionary(grouping: allViews) { $0.position }
        
        for (position, views) in groupedByPosition {
            var counter = positionCounters[position] ?? 0
            
            for view in views.sorted(by: { $0.pluginId < $1.pluginId }) {
                let resolvedView = PluginViewInfo(
                    pluginId: view.pluginId,
                    position: position,
                    priorityOrder: counter,
                    isActive: view.isActive,
                    view: view.view
                )
                resolvedViews.append(resolvedView)
                counter += 1
            }
            
            positionCounters[position] = counter
        }
        
        return resolvedViews.sorted { $0.priorityOrder < $1.priorityOrder }
    }
    
    // MARK: - State Management
    
    /// Get the current view state for a plugin
    /// - Parameter pluginId: ID of the plugin
    /// - Returns: Current view state dictionary
    public func getPluginViewState(for pluginId: String) -> [String: Any]? {
        if let plugin = registeredPlugins[pluginId] {
            return plugin.getViewState()
        }
        return viewStates[pluginId]
    }
    
    /// Set the view state for a plugin
    /// - Parameters:
    ///   - pluginId: ID of the plugin
    ///   - state: State dictionary to set
    public func setPluginViewState(for pluginId: String, state: [String: Any]) {
        viewStates[pluginId] = state
        registeredPlugins[pluginId]?.restoreViewState(state)
    }
    
    // MARK: - Query Methods
    
    /// Check if a plugin is registered
    /// - Parameter pluginId: ID of the plugin to check
    /// - Returns: True if registered, false otherwise
    public func hasRegisteredPlugin(_ pluginId: String) -> Bool {
        return registeredPlugins[pluginId] != nil
    }
    
    /// Check if a plugin view is active
    /// - Parameter pluginId: ID of the plugin to check
    /// - Returns: True if active, false otherwise
    public func isPluginViewActive(_ pluginId: String) -> Bool {
        return activePlugins.contains(pluginId)
    }
    
    /// Get the count of registered plugins
    public var registeredPluginCount: Int {
        return registeredPlugins.count
    }
    
    // MARK: - SwiftUI Environment
    
    /// Create environment values for plugin views
    /// - Returns: Plugin environment values
    public func createEnvironmentValues() -> PluginEnvironmentValues {
        let container = PluginViewContainer(viewModel: self)
        let eventSystem = PluginEventSystem()
        
        return PluginEnvironmentValues(
            pluginContainer: container,
            pluginEventSystem: eventSystem
        )
    }
    
    // MARK: - Private Methods
    
    private func getPriorityOrder(for pluginId: String, position: PluginViewPosition) -> Int {
        // Simple priority assignment based on registration order
        // In a real implementation, this could be more sophisticated
        let samePositionPlugins = viewPositions.filter { $0.value == position }
        return samePositionPlugins.keys.sorted().firstIndex(of: pluginId) ?? 0
    }
}

/// SwiftUI container view for plugin views
public struct PluginViewContainer: View {
    @ObservedObject private var viewModel: PluginViewContainerViewModel
    
    public init(viewModel: PluginViewContainerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        EmptyView() // This will be extended with actual UI layout
    }
}

// MARK: - SwiftUI Environment Extensions

private struct PluginContainerKey: EnvironmentKey {
    static let defaultValue: PluginViewContainer? = nil
}

private struct PluginEventSystemKey: EnvironmentKey {
    static let defaultValue: PluginEventSystem? = nil
}

extension EnvironmentValues {
    public var pluginContainer: PluginViewContainer? {
        get { self[PluginContainerKey.self] }
        set { self[PluginContainerKey.self] = newValue }
    }
    
    public var pluginEventSystem: PluginEventSystem? {
        get { self[PluginEventSystemKey.self] }
        set { self[PluginEventSystemKey.self] = newValue }
    }
}

// MARK: - View Modifiers

public extension View {
    /// Inject plugin container into the environment
    /// - Parameter container: Plugin view container to inject
    /// - Returns: View with plugin container in environment
    func pluginContainer(_ container: PluginViewContainer) -> some View {
        self.environment(\.pluginContainer, container)
    }
    
    /// Inject plugin event system into the environment
    /// - Parameter eventSystem: Plugin event system to inject
    /// - Returns: View with plugin event system in environment
    func pluginEventSystem(_ eventSystem: PluginEventSystem) -> some View {
        self.environment(\.pluginEventSystem, eventSystem)
    }
}