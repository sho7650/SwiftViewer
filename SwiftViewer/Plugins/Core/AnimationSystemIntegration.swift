import Foundation
import SwiftUI
import AppKit
import os

/// Errors specific to animation system operations
public enum AnimationSystemError: Error, LocalizedError, Equatable {
    case pluginNotFound(String)
    case transitionFailed(reason: String)
    case invalidConfiguration(reason: String)
    case timingError(reason: String)
    case concurrencyError(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .pluginNotFound(let pluginId):
            return "Transition plugin not found: \(pluginId)"
        case .transitionFailed(let reason):
            return "Transition failed: \(reason)"
        case .invalidConfiguration(let reason):
            return "Invalid animation configuration: \(reason)"
        case .timingError(let reason):
            return "Animation timing error: \(reason)"
        case .concurrencyError(let reason):
            return "Animation concurrency error: \(reason)"
        }
    }
    
    public static func == (lhs: AnimationSystemError, rhs: AnimationSystemError) -> Bool {
        switch (lhs, rhs) {
        case (.pluginNotFound(let id1), .pluginNotFound(let id2)):
            return id1 == id2
        case (.transitionFailed(let reason1), .transitionFailed(let reason2)):
            return reason1 == reason2
        case (.invalidConfiguration(let reason1), .invalidConfiguration(let reason2)):
            return reason1 == reason2
        case (.timingError(let reason1), .timingError(let reason2)):
            return reason1 == reason2
        case (.concurrencyError(let reason1), .concurrencyError(let reason2)):
            return reason1 == reason2
        default:
            return false
        }
    }
}

/// Extension to TransitionPluginProtocol for animation system integration
extension TransitionPluginProtocol {
    /// Apply transition between two images using the plugin's transition
    /// - Parameters:
    ///   - fromImage: Source image
    ///   - toImage: Destination image
    ///   - duration: Transition duration in seconds
    ///   - configuration: Optional configuration parameters
    /// - Returns: SwiftUI view containing the transition animation
    /// - Throws: AnimationSystemError if transition fails
    func applyTransition(
        fromImage: NSImage,
        toImage: NSImage,
        duration: TimeInterval,
        configuration: [String: Any]? = nil
    ) async throws -> AnyView {
        // Create transition parameters from configuration
        let curve = TransitionCurve(rawValue: configuration?["curve"] as? String ?? "easeInOut") ?? .easeInOut
        let customValues = configuration?.compactMapValues { "\($0)" }
        
        let parameters = TransitionParameters(
            duration: duration,
            curve: curve,
            customValues: customValues
        )
        
        // Create the transition
        let transition = createTransition(with: parameters)
        
        // Create a view that applies the transition between images
        let transitionView = TransitionAnimationView(
            fromImage: fromImage,
            toImage: toImage,
            transition: transition,
            duration: duration
        )
        
        return AnyView(transitionView)
    }
}

/// SwiftUI view that animates between two images using a transition
struct TransitionAnimationView: View {
    let fromImage: NSImage
    let toImage: NSImage
    let transition: AnyTransition
    let duration: TimeInterval
    
    @State private var showToImage = false
    
    var body: some View {
        ZStack {
            if !showToImage {
                Image(nsImage: fromImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .transition(transition)
            } else {
                Image(nsImage: toImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .transition(transition)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: duration)) {
                showToImage = true
            }
        }
    }
}

/// Manages integration of plugin animations with the slideshow system
@MainActor
public final class AnimationSystemIntegration {
    
    // MARK: - Properties
    
    private let logger: Logger
    private var registeredPlugins: [String: TransitionPluginProtocol] = [:]
    private var activeTransitions: [String: Task<AnyView, any Error>] = [:]
    private weak var slideShowController: SlideShowControllerProtocol?
    
    // MARK: - Initialization
    
    public init(slideShowController: SlideShowControllerProtocol? = nil) {
        self.logger = Logger()
        self.slideShowController = slideShowController
        logger.info("AnimationSystemIntegration initialized")
    }
    
    // MARK: - Plugin Registration
    
    /// Register a transition plugin
    /// - Parameter plugin: The transition plugin to register
    public func registerTransitionPlugin(_ plugin: TransitionPluginProtocol) {
        let pluginId = plugin.metadata.id
        logger.debug("Registering transition plugin: \(pluginId)")
        
        registeredPlugins[pluginId] = plugin
        
        logger.info("Transition plugin registered: \(pluginId)")
    }
    
    /// Unregister a transition plugin
    /// - Parameter pluginId: ID of the plugin to unregister
    public func unregisterTransitionPlugin(pluginId: String) {
        logger.debug("Unregistering transition plugin: \(pluginId)")
        
        // Cancel any active transitions for this plugin
        if let activeTask = activeTransitions[pluginId] {
            activeTask.cancel()
            activeTransitions.removeValue(forKey: pluginId)
        }
        
        registeredPlugins.removeValue(forKey: pluginId)
        
        logger.info("Transition plugin unregistered: \(pluginId)")
    }
    
    /// Get a registered transition plugin
    /// - Parameter pluginId: ID of the plugin
    /// - Returns: The transition plugin if registered, nil otherwise
    public func getTransitionPlugin(for pluginId: String) -> TransitionPluginProtocol? {
        return registeredPlugins[pluginId]
    }
    
    /// Check if a plugin is registered
    /// - Parameter pluginId: ID of the plugin to check
    /// - Returns: True if registered, false otherwise
    public func hasRegisteredPlugin(_ pluginId: String) -> Bool {
        return registeredPlugins[pluginId] != nil
    }
    
    /// Get the count of registered plugins
    public var registeredPluginCount: Int {
        return registeredPlugins.count
    }
    
    // MARK: - Animation Integration
    
    /// Apply a transition using a specific plugin
    /// - Parameters:
    ///   - pluginId: ID of the transition plugin to use
    ///   - fromImage: Source image
    ///   - toImage: Destination image
    ///   - duration: Transition duration in seconds
    ///   - configuration: Optional configuration parameters
    /// - Returns: SwiftUI view containing the transition animation
    /// - Throws: AnimationSystemError if transition fails
    public func applyTransition(
        pluginId: String,
        fromImage: NSImage,
        toImage: NSImage,
        duration: TimeInterval,
        configuration: [String: Any]? = nil
    ) async throws -> AnyView {
        logger.debug("Applying transition with plugin: \(pluginId)")
        
        guard let plugin = registeredPlugins[pluginId] else {
            throw AnimationSystemError.pluginNotFound(pluginId)
        }
        
        // Cancel any existing transition for this plugin
        if let existingTask = activeTransitions[pluginId] {
            existingTask.cancel()
        }
        
        // Create and track the transition task
        let transitionTask = Task<AnyView, any Error> {
            do {
                let result = try await plugin.applyTransition(
                    fromImage: fromImage,
                    toImage: toImage,
                    duration: duration,
                    configuration: configuration
                )
                
                // Remove from active transitions when completed
                await MainActor.run {
                    activeTransitions.removeValue(forKey: pluginId)
                }
                
                return result
                
            } catch {
                // Remove from active transitions on error
                await MainActor.run {
                    activeTransitions.removeValue(forKey: pluginId)
                }
                throw AnimationSystemError.transitionFailed(reason: error.localizedDescription)
            }
        }
        
        activeTransitions[pluginId] = transitionTask
        
        let result = try await transitionTask.value
        logger.info("Transition applied successfully with plugin: \(pluginId)")
        return result
    }
    
    // MARK: - Slideshow Integration
    
    /// Integrate the animation system with the slideshow controller
    public func integrateWithSlideshow() {
        logger.debug("Integrating animation system with slideshow")
        
        guard let controller = slideShowController else {
            logger.warning("No slideshow controller available for integration")
            return
        }
        
        // Set up transition handler for slideshow
        controller.setTransitionHandler { [weak self] fromImage, toImage, duration in
            guard let self = self else {
                throw AnimationSystemError.concurrencyError(reason: "Animation system deallocated")
            }
            
            // Use the default transition plugin or first available
            let pluginId = self.getDefaultTransitionPluginId()
            guard let selectedPluginId = pluginId else {
                throw AnimationSystemError.pluginNotFound("No transition plugins available")
            }
            
            return try await self.applyTransition(
                pluginId: selectedPluginId,
                fromImage: fromImage,
                toImage: toImage,
                duration: duration
            )
        }
        
        logger.info("Animation system integrated with slideshow")
    }
    
    // MARK: - Animation Management
    
    /// Cancel all active transitions
    public func cancelAllTransitions() {
        logger.debug("Cancelling all active transitions")
        
        for (pluginId, task) in activeTransitions {
            task.cancel()
            logger.debug("Cancelled transition for plugin: \(pluginId)")
        }
        
        activeTransitions.removeAll()
        logger.info("All transitions cancelled")
    }
    
    /// Get the count of active transitions
    public var activeTransitionCount: Int {
        return activeTransitions.count
    }
    
    /// Check if a specific plugin has an active transition
    /// - Parameter pluginId: ID of the plugin
    /// - Returns: True if the plugin has an active transition
    public func hasActiveTransition(for pluginId: String) -> Bool {
        return activeTransitions[pluginId] != nil
    }
    
    // MARK: - Private Methods
    
    private func getDefaultTransitionPluginId() -> String? {
        // Return the first available plugin, or a preferred default
        return registeredPlugins.keys.first
    }
}

// MARK: - SlideShow Controller Protocol

/// Protocol for slideshow controllers that can integrate with animation system
public protocol SlideShowControllerProtocol: AnyObject {
    /// Set the transition handler for slideshow transitions
    /// - Parameter handler: Handler function that creates transition views
    func setTransitionHandler(_ handler: @escaping (NSImage, NSImage, TimeInterval) async throws -> AnyView)
}

// MARK: - Extensions

extension AnimationSystemIntegration {
    /// Get all registered plugin IDs
    /// - Returns: Array of registered plugin IDs
    public func getRegisteredPluginIds() -> [String] {
        return Array(registeredPlugins.keys).sorted()
    }
    
    /// Get all plugins supporting a specific capability
    /// - Parameter capability: The capability to filter by
    /// - Returns: Array of plugins that support the capability
    public func getPlugins(supporting capability: PluginCapability) -> [TransitionPluginProtocol] {
        return registeredPlugins.values.filter { plugin in
            plugin.metadata.capabilities.contains(capability)
        }
    }
    
    /// Validate plugin configuration
    /// - Parameters:
    ///   - pluginId: ID of the plugin
    ///   - configuration: Configuration to validate
    /// - Returns: True if configuration is valid
    /// - Throws: AnimationSystemError if configuration is invalid
    public func validateConfiguration(for pluginId: String, configuration: [String: Any]) throws -> Bool {
        guard registeredPlugins[pluginId] != nil else {
            throw AnimationSystemError.pluginNotFound(pluginId)
        }
        
        // Basic validation - can be extended with plugin-specific validation
        if let duration = configuration["duration"] as? TimeInterval, duration <= 0 {
            throw AnimationSystemError.invalidConfiguration(reason: "Duration must be positive")
        }
        
        if let repeatCount = configuration["repeatCount"] as? Int, repeatCount < 0 {
            throw AnimationSystemError.invalidConfiguration(reason: "Repeat count cannot be negative")
        }
        
        return true
    }
}