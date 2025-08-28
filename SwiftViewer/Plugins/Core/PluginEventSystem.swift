import Foundation
import os

/// Types of plugin events that can be published and subscribed to
public enum PluginEventType: String, CaseIterable, Codable {
    // Plugin lifecycle events
    case pluginLoaded = "plugin.loaded"
    case pluginUnloaded = "plugin.unloaded"
    case pluginActivated = "plugin.activated"
    case pluginDeactivated = "plugin.deactivated"
    case pluginError = "plugin.error"
    
    // Image viewing events
    case imageChanged = "image.changed"
    case imageLoaded = "image.loaded"
    case imageLoadError = "image.load.error"
    
    // Slideshow events
    case slideShowStarted = "slideshow.started"
    case slideShowStopped = "slideshow.stopped"
    case slideShowPaused = "slideshow.paused"
    case slideShowResumed = "slideshow.resumed"
    
    // Generic plugin event
    case pluginEvent = "plugin.event"
}

/// Represents an event in the plugin system
public struct PluginEvent {
    /// Type of the event
    public let type: PluginEventType
    
    /// Source identifier (plugin ID or system component)
    public let source: String
    
    /// Event-specific data payload
    public let data: [String: Any]
    
    /// Timestamp when the event was created
    public let timestamp: Date
    
    /// Unique identifier for this event
    public let id: String
    
    public init(
        type: PluginEventType,
        source: String,
        data: [String: Any] = [:],
        timestamp: Date = Date()
    ) {
        self.type = type
        self.source = source
        self.data = data
        self.timestamp = timestamp
        self.id = UUID().uuidString
    }
}

/// Protocol for objects that can receive plugin events
public protocol PluginEventListener: AnyObject {
    /// Called when an event is received
    /// - Parameter event: The received event
    func onEvent(_ event: PluginEvent) async throws
}

/// Manages plugin event distribution and communication
@MainActor
public final class PluginEventSystem {
    
    // MARK: - Properties
    
    private let logger: Logger
    private var eventSubscriptions: [PluginEventType: [WeakEventListener]] = [:]
    private let eventQueue: DispatchQueue
    
    // MARK: - Initialization
    
    public init() {
        self.logger = Logger()
        self.eventQueue = DispatchQueue(label: "com.swiftviewer.plugin-events", qos: .userInitiated)
        logger.info("PluginEventSystem initialized")
    }
    
    // MARK: - Subscription Management
    
    /// Subscribe to a specific event type
    /// - Parameters:
    ///   - eventType: Type of event to subscribe to
    ///   - listener: Object that will receive events
    public func subscribe(to eventType: PluginEventType, listener: PluginEventListener) {
        logger.debug("Subscribing listener to event type: \(eventType.rawValue)")
        
        if eventSubscriptions[eventType] == nil {
            eventSubscriptions[eventType] = []
        }
        
        let weakListener = WeakEventListener(listener)
        eventSubscriptions[eventType]?.append(weakListener)
        
        // Clean up deallocated listeners
        cleanupDeadListeners(for: eventType)
    }
    
    /// Unsubscribe from a specific event type
    /// - Parameters:
    ///   - eventType: Type of event to unsubscribe from
    ///   - listener: Object to remove from subscriptions
    public func unsubscribe(from eventType: PluginEventType, listener: PluginEventListener) {
        logger.debug("Unsubscribing listener from event type: \(eventType.rawValue)")
        
        guard var listeners = eventSubscriptions[eventType] else { return }
        
        listeners.removeAll { weakListener in
            weakListener.listener === listener
        }
        
        eventSubscriptions[eventType] = listeners.isEmpty ? nil : listeners
    }
    
    /// Remove all subscriptions for a listener
    /// - Parameter listener: Listener to remove from all subscriptions
    public func unsubscribeFromAll(listener: PluginEventListener) {
        logger.debug("Unsubscribing listener from all events")
        
        for eventType in eventSubscriptions.keys {
            unsubscribe(from: eventType, listener: listener)
        }
    }
    
    // MARK: - Event Publishing
    
    /// Publish an event to all subscribers
    /// - Parameter event: Event to publish
    public func publish(_ event: PluginEvent) async {
        logger.debug("Publishing event: \(event.type.rawValue) from \(event.source)")
        
        guard let listeners = eventSubscriptions[event.type] else {
            logger.debug("No subscribers for event type: \(event.type.rawValue)")
            return
        }
        
        // Clean up deallocated listeners before publishing
        cleanupDeadListeners(for: event.type)
        
        // Get current valid listeners
        guard let validListeners = eventSubscriptions[event.type] else { return }
        
        // Deliver event to all subscribers
        await withTaskGroup(of: Void.self) { group in
            for weakListener in validListeners {
                guard let listener = weakListener.listener else { continue }
                
                group.addTask {
                    do {
                        try await listener.onEvent(event)
                    } catch {
                        self.logger.error("Event listener error: \(error.localizedDescription)")
                        // Don't let one listener's error stop others
                    }
                }
            }
        }
        
        logger.debug("Event published to \(validListeners.count) listeners")
    }
    
    // MARK: - Convenience Publishing Methods
    
    /// Notify that a plugin has been loaded
    /// - Parameter plugin: The loaded plugin
    public func notifyPluginLoaded(_ plugin: PluginProtocol) async {
        let event = PluginEvent(
            type: .pluginLoaded,
            source: plugin.metadata.id,
            data: [
                "pluginName": plugin.metadata.name,
                "pluginVersion": plugin.metadata.version
            ]
        )
        await publish(event)
    }
    
    /// Notify that a plugin has been unloaded
    /// - Parameter plugin: The unloaded plugin
    public func notifyPluginUnloaded(_ plugin: PluginProtocol) async {
        let event = PluginEvent(
            type: .pluginUnloaded,
            source: plugin.metadata.id,
            data: [
                "pluginName": plugin.metadata.name,
                "pluginVersion": plugin.metadata.version
            ]
        )
        await publish(event)
    }
    
    /// Notify that a plugin has been activated
    /// - Parameter plugin: The activated plugin
    public func notifyPluginActivated(_ plugin: PluginProtocol) async {
        let event = PluginEvent(
            type: .pluginActivated,
            source: plugin.metadata.id,
            data: [
                "pluginName": plugin.metadata.name,
                "isActive": plugin.isActive
            ]
        )
        await publish(event)
    }
    
    /// Notify that a plugin has been deactivated
    /// - Parameter plugin: The deactivated plugin
    public func notifyPluginDeactivated(_ plugin: PluginProtocol) async {
        let event = PluginEvent(
            type: .pluginDeactivated,
            source: plugin.metadata.id,
            data: [
                "pluginName": plugin.metadata.name,
                "isActive": plugin.isActive
            ]
        )
        await publish(event)
    }
    
    /// Notify that the current image has changed
    /// - Parameters:
    ///   - imagePath: Path to the new current image
    ///   - index: Index of the image in the current collection
    ///   - totalCount: Total number of images in the collection
    public func notifyImageChanged(imagePath: String, index: Int, totalCount: Int) async {
        let event = PluginEvent(
            type: .imageChanged,
            source: "image.viewer",
            data: [
                "imagePath": imagePath,
                "index": index,
                "totalCount": totalCount
            ]
        )
        await publish(event)
    }
    
    /// Notify that an image has been loaded
    /// - Parameters:
    ///   - imagePath: Path to the loaded image
    ///   - loadTime: Time taken to load the image
    public func notifyImageLoaded(imagePath: String, loadTime: TimeInterval) async {
        let event = PluginEvent(
            type: .imageLoaded,
            source: "image.loader",
            data: [
                "imagePath": imagePath,
                "loadTime": loadTime
            ]
        )
        await publish(event)
    }
    
    /// Notify that slideshow has started
    /// - Parameter interval: Slideshow interval in seconds
    public func notifySlideShowStarted(interval: TimeInterval) async {
        let event = PluginEvent(
            type: .slideShowStarted,
            source: "slideshow.controller",
            data: [
                "interval": interval
            ]
        )
        await publish(event)
    }
    
    /// Notify that slideshow has been paused
    public func notifySlideShowPaused() async {
        let event = PluginEvent(
            type: .slideShowPaused,
            source: "slideshow.controller",
            data: [:]
        )
        await publish(event)
    }
    
    /// Notify that slideshow has been resumed
    public func notifySlideShowResumed() async {
        let event = PluginEvent(
            type: .slideShowResumed,
            source: "slideshow.controller",
            data: [:]
        )
        await publish(event)
    }
    
    /// Notify that slideshow has stopped
    public func notifySlideShowStopped() async {
        let event = PluginEvent(
            type: .slideShowStopped,
            source: "slideshow.controller",
            data: [:]
        )
        await publish(event)
    }
    
    /// Notify of a plugin error
    /// - Parameters:
    ///   - plugin: Plugin that encountered the error
    ///   - error: The error that occurred
    public func notifyPluginError(_ plugin: PluginProtocol, error: Error) async {
        let event = PluginEvent(
            type: .pluginError,
            source: plugin.metadata.id,
            data: [
                "pluginName": plugin.metadata.name,
                "error": error.localizedDescription,
                "errorType": String(describing: type(of: error))
            ]
        )
        await publish(event)
    }
    
    // MARK: - Subscription Queries
    
    /// Check if there are any subscribers for a specific event type
    /// - Parameter eventType: Event type to check
    /// - Returns: True if there are subscribers, false otherwise
    public func hasSubscriber(for eventType: PluginEventType) -> Bool {
        guard let listeners = eventSubscriptions[eventType] else { return false }
        return !listeners.isEmpty && listeners.contains { $0.listener != nil }
    }
    
    /// Get the number of subscribers for a specific event type
    /// - Parameter eventType: Event type to check
    /// - Returns: Number of active subscribers
    public func getSubscriberCount(for eventType: PluginEventType) -> Int {
        guard let listeners = eventSubscriptions[eventType] else { return 0 }
        return listeners.compactMap { $0.listener }.count
    }
    
    /// Get all event types that have active subscribers
    /// - Returns: Set of event types with subscribers
    public func getActiveEventTypes() -> Set<PluginEventType> {
        let activeTypes = eventSubscriptions.compactMapValues { listeners in
            listeners.contains { $0.listener != nil } ? true : nil
        }
        return Set(activeTypes.keys)
    }
    
    // MARK: - Private Methods
    
    /// Clean up deallocated listeners for a specific event type
    /// - Parameter eventType: Event type to clean up
    private func cleanupDeadListeners(for eventType: PluginEventType) {
        guard var listeners = eventSubscriptions[eventType] else { return }
        
        let originalCount = listeners.count
        listeners.removeAll { $0.listener == nil }
        
        if listeners.isEmpty {
            eventSubscriptions[eventType] = nil
        } else {
            eventSubscriptions[eventType] = listeners
        }
        
        let cleanedCount = originalCount - listeners.count
        if cleanedCount > 0 {
            logger.debug("Cleaned up \(cleanedCount) dead listeners for \(eventType.rawValue)")
        }
    }
    
    /// Clean up all deallocated listeners
    private func cleanupAllDeadListeners() {
        for eventType in eventSubscriptions.keys {
            cleanupDeadListeners(for: eventType)
        }
    }
}

// MARK: - Supporting Types

/// Weak reference wrapper for event listeners to prevent retain cycles
private class WeakEventListener {
    weak var listener: PluginEventListener?
    
    init(_ listener: PluginEventListener) {
        self.listener = listener
    }
}

// MARK: - Extensions

extension PluginEvent {
    /// Get a typed value from the event data
    /// - Parameter key: Key to look up
    /// - Returns: Value cast to the specified type, or nil if not found or wrong type
    public func getValue<T>(_ key: String, as type: T.Type) -> T? {
        return data[key] as? T
    }
    
    /// Check if the event contains a specific key
    /// - Parameter key: Key to check
    /// - Returns: True if the key exists
    public func hasKey(_ key: String) -> Bool {
        return data[key] != nil
    }
}

extension PluginEventType {
    /// Check if this is a plugin lifecycle event
    public var isLifecycleEvent: Bool {
        switch self {
        case .pluginLoaded, .pluginUnloaded, .pluginActivated, .pluginDeactivated:
            return true
        default:
            return false
        }
    }
    
    /// Check if this is an image-related event
    public var isImageEvent: Bool {
        switch self {
        case .imageChanged, .imageLoaded, .imageLoadError:
            return true
        default:
            return false
        }
    }
    
    /// Check if this is a slideshow-related event
    public var isSlideshowEvent: Bool {
        switch self {
        case .slideShowStarted, .slideShowStopped, .slideShowPaused, .slideShowResumed:
            return true
        default:
            return false
        }
    }
}