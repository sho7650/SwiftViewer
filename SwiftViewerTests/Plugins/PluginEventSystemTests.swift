import XCTest
import Foundation
@testable import SwiftViewer

/// Tests for Plugin Event System functionality
/// Unit 15: Plugin Event System (2-3 hours)
/// Test: Plugin lifecycle and image events
@MainActor
final class PluginEventSystemTests: XCTestCase {
    
    fileprivate var sut: PluginEventSystem!
    fileprivate var mockEventListener: MockEventListener!
    fileprivate var mockPlugin: MockEventPlugin!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = PluginEventSystem()
        mockEventListener = MockEventListener()
        mockPlugin = MockEventPlugin()
    }
    
    override func tearDown() async throws {
        sut = nil
        mockEventListener = nil
        mockPlugin = nil
        try await super.tearDown()
    }
    
    // MARK: - Event Subscription Tests
    
    func testSubscribeToEvent_WithValidListener_ShouldRegisterSuccessfully() {
        // Given valid event type and listener
        let eventType: PluginEventType = .imageChanged
        
        // When subscribing to event
        sut.subscribe(to: eventType, listener: mockEventListener)
        
        // Then subscription should be registered
        XCTAssertTrue(sut.hasSubscriber(for: eventType))
        XCTAssertEqual(sut.getSubscriberCount(for: eventType), 1)
    }
    
    func testSubscribeToMultipleEvents_ShouldRegisterAll() {
        // Given multiple event types
        let eventTypes: [PluginEventType] = [.imageChanged, .slideShowStarted, .pluginLoaded]
        
        // When subscribing to multiple events
        for eventType in eventTypes {
            sut.subscribe(to: eventType, listener: mockEventListener)
        }
        
        // Then all subscriptions should be registered
        for eventType in eventTypes {
            XCTAssertTrue(sut.hasSubscriber(for: eventType))
            XCTAssertEqual(sut.getSubscriberCount(for: eventType), 1)
        }
    }
    
    func testUnsubscribeFromEvent_ShouldRemoveListener() {
        // Given subscribed listener
        let eventType: PluginEventType = .imageChanged
        sut.subscribe(to: eventType, listener: mockEventListener)
        
        // When unsubscribing
        sut.unsubscribe(from: eventType, listener: mockEventListener)
        
        // Then subscription should be removed
        XCTAssertFalse(sut.hasSubscriber(for: eventType))
        XCTAssertEqual(sut.getSubscriberCount(for: eventType), 0)
    }
    
    // MARK: - Event Publishing Tests
    
    func testPublishEvent_WithSubscribedListener_ShouldDeliverEvent() async {
        // Given subscribed listener
        let eventType: PluginEventType = .imageChanged
        sut.subscribe(to: eventType, listener: mockEventListener)
        
        // When publishing event
        let event = PluginEvent(
            type: eventType,
            source: "test.plugin",
            data: ["imagePath": "/test/image.jpg"],
            timestamp: Date()
        )
        
        await sut.publish(event)
        
        // Then listener should receive event
        XCTAssertTrue(mockEventListener.receivedEvent)
        XCTAssertEqual(mockEventListener.lastReceivedEvent?.type, eventType)
        XCTAssertEqual(mockEventListener.lastReceivedEvent?.source, "test.plugin")
        XCTAssertEqual(mockEventListener.eventReceiveCount, 1)
    }
    
    func testPublishEvent_WithMultipleListeners_ShouldDeliverToAll() async {
        // Given multiple listeners
        let eventType: PluginEventType = .slideShowStarted
        let listener1 = MockEventListener()
        let listener2 = MockEventListener()
        
        sut.subscribe(to: eventType, listener: listener1)
        sut.subscribe(to: eventType, listener: listener2)
        
        // When publishing event
        let event = PluginEvent(
            type: eventType,
            source: "slideshow.controller",
            data: ["interval": 5.0],
            timestamp: Date()
        )
        
        await sut.publish(event)
        
        // Then both listeners should receive event
        XCTAssertTrue(listener1.receivedEvent)
        XCTAssertTrue(listener2.receivedEvent)
        XCTAssertEqual(listener1.eventReceiveCount, 1)
        XCTAssertEqual(listener2.eventReceiveCount, 1)
    }
    
    func testPublishEvent_WithNoSubscribers_ShouldNotCrash() async {
        // Given no subscribers
        let event = PluginEvent(
            type: .pluginError,
            source: "test.plugin",
            data: ["error": "test error"],
            timestamp: Date()
        )
        
        // When publishing event with no subscribers
        await sut.publish(event)
        
        // Then should not crash and complete successfully
        XCTAssertEqual(sut.getSubscriberCount(for: .pluginError), 0)
    }
    
    // MARK: - Plugin Lifecycle Events Tests
    
    func testPluginLifecycleEvents_ShouldTriggerCorrectEvents() async {
        // Given lifecycle event subscribers
        var receivedEvents: [PluginEventType] = []
        let lifecycleListener = MockEventListener()
        lifecycleListener.onEventReceived = { event in
            receivedEvents.append(event.type)
        }
        
        sut.subscribe(to: .pluginLoaded, listener: lifecycleListener)
        sut.subscribe(to: .pluginActivated, listener: lifecycleListener)
        sut.subscribe(to: .pluginDeactivated, listener: lifecycleListener)
        sut.subscribe(to: .pluginUnloaded, listener: lifecycleListener)
        
        // When plugin goes through lifecycle
        await sut.notifyPluginLoaded(mockPlugin)
        await sut.notifyPluginActivated(mockPlugin)
        await sut.notifyPluginDeactivated(mockPlugin)
        await sut.notifyPluginUnloaded(mockPlugin)
        
        // Then all lifecycle events should be triggered
        let expectedEvents: [PluginEventType] = [.pluginLoaded, .pluginActivated, .pluginDeactivated, .pluginUnloaded]
        XCTAssertEqual(receivedEvents, expectedEvents)
        XCTAssertEqual(lifecycleListener.eventReceiveCount, 4)
    }
    
    // MARK: - Image Events Tests
    
    func testImageEvents_ShouldTriggerWithCorrectData() async {
        // Given image event subscriber
        sut.subscribe(to: .imageChanged, listener: mockEventListener)
        
        // When image changes
        let imagePath = "/Users/test/image.jpg"
        await sut.notifyImageChanged(imagePath: imagePath, index: 5, totalCount: 100)
        
        // Then should receive image event with correct data
        XCTAssertTrue(mockEventListener.receivedEvent)
        XCTAssertEqual(mockEventListener.lastReceivedEvent?.type, .imageChanged)
        
        guard let data = mockEventListener.lastReceivedEvent?.data else {
            XCTFail("Event data should not be nil")
            return
        }
        
        XCTAssertEqual(data["imagePath"] as? String, imagePath)
        XCTAssertEqual(data["index"] as? Int, 5)
        XCTAssertEqual(data["totalCount"] as? Int, 100)
    }
    
    func testSlideShowEvents_ShouldTriggerCorrectly() async {
        // Given slideshow event subscribers
        var receivedEventTypes: [PluginEventType] = []
        let slideshowListener = MockEventListener()
        slideshowListener.onEventReceived = { event in
            receivedEventTypes.append(event.type)
        }
        
        sut.subscribe(to: .slideShowStarted, listener: slideshowListener)
        sut.subscribe(to: .slideShowPaused, listener: slideshowListener)
        sut.subscribe(to: .slideShowResumed, listener: slideshowListener)
        sut.subscribe(to: .slideShowStopped, listener: slideshowListener)
        
        // When slideshow state changes
        await sut.notifySlideShowStarted(interval: 3.0)
        await sut.notifySlideShowPaused()
        await sut.notifySlideShowResumed()
        await sut.notifySlideShowStopped()
        
        // Then all slideshow events should be received
        let expectedEvents: [PluginEventType] = [.slideShowStarted, .slideShowPaused, .slideShowResumed, .slideShowStopped]
        XCTAssertEqual(receivedEventTypes, expectedEvents)
    }
    
    // MARK: - Event Filtering Tests
    
    func testEventFiltering_WithEventFilter_ShouldOnlyDeliverMatchingEvents() async {
        // Given filtered listener
        let filteringListener = MockEventListener()
        filteringListener.eventFilter = { event in
            // Only accept events with "important" tag
            return (event.data["priority"] as? String) == "important"
        }
        
        sut.subscribe(to: .pluginEvent, listener: filteringListener)
        
        // When publishing filtered and unfiltered events
        let importantEvent = PluginEvent(
            type: .pluginEvent,
            source: "test.plugin",
            data: ["priority": "important", "message": "Critical update"],
            timestamp: Date()
        )
        
        let normalEvent = PluginEvent(
            type: .pluginEvent,
            source: "test.plugin",
            data: ["priority": "normal", "message": "Regular update"],
            timestamp: Date()
        )
        
        await sut.publish(importantEvent)
        await sut.publish(normalEvent)
        
        // Then only important event should be received
        XCTAssertEqual(filteringListener.eventReceiveCount, 1)
        XCTAssertEqual(filteringListener.lastReceivedEvent?.data["message"] as? String, "Critical update")
    }
    
    // MARK: - Performance Tests
    
    func testEventPublishing_WithManyListeners_ShouldPerformWell() async {
        // Given many listeners
        let eventType: PluginEventType = .imageChanged
        let listenerCount = 100
        var listeners: [MockEventListener] = []
        
        for _ in 0..<listenerCount {
            let listener = MockEventListener()
            listeners.append(listener)
            sut.subscribe(to: eventType, listener: listener)
        }
        
        // Measure event publishing performance
        let event = PluginEvent(
            type: eventType,
            source: "performance.test",
            data: [:],
            timestamp: Date()
        )
        
        let startTime = Date()
        await sut.publish(event)
        let publishingTime = Date().timeIntervalSince(startTime)
        
        // Then should complete within reasonable time
        XCTAssertLessThan(publishingTime, 0.1) // Less than 100ms
        
        // Verify all listeners received event
        for listener in listeners {
            XCTAssertTrue(listener.receivedEvent)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testEventListener_ThatThrowsError_ShouldNotAffectOthers() async {
        // Given listeners where one throws error
        let goodListener1 = MockEventListener()
        let errorListener = MockEventListener()
        let goodListener2 = MockEventListener()
        
        errorListener.shouldThrowError = true
        
        let eventType: PluginEventType = .pluginError
        sut.subscribe(to: eventType, listener: goodListener1)
        sut.subscribe(to: eventType, listener: errorListener)
        sut.subscribe(to: eventType, listener: goodListener2)
        
        // When publishing event
        let event = PluginEvent(
            type: eventType,
            source: "test.plugin",
            data: ["error": "test error"],
            timestamp: Date()
        )
        
        await sut.publish(event)
        
        // Then good listeners should still receive event
        XCTAssertTrue(goodListener1.receivedEvent)
        XCTAssertTrue(goodListener2.receivedEvent)
        // Error listener should also be called (error is caught by event system)
        XCTAssertTrue(errorListener.receivedEvent)
    }
    
    // MARK: - Memory Management Tests
    
    func testWeakReferences_ShouldNotRetainListeners() {
        // Given weak listener reference
        var listener: MockEventListener? = MockEventListener()
        weak var weakListener = listener
        
        sut.subscribe(to: .imageChanged, listener: listener!)
        XCTAssertNotNil(weakListener)
        XCTAssertEqual(sut.getSubscriberCount(for: .imageChanged), 1)
        
        // When releasing strong reference
        listener = nil
        
        // Then after cleanup, weak reference should be nil and count should be 0
        XCTAssertNil(weakListener)
        // Trigger cleanup by checking subscriber count (which calls cleanup internally)
        XCTAssertEqual(sut.getSubscriberCount(for: .imageChanged), 0) // Should be 0 after cleanup
    }
}

// MARK: - Mock Event Listener

fileprivate class MockEventListener: PluginEventListener {
    var receivedEvent: Bool = false
    var eventReceiveCount: Int = 0
    var lastReceivedEvent: PluginEvent?
    var shouldThrowError: Bool = false
    var onEventReceived: ((PluginEvent) -> Void)?
    var eventFilter: ((PluginEvent) -> Bool)?
    
    func onEvent(_ event: PluginEvent) async throws {
        // Check filter first, before marking as received
        if let filter = eventFilter {
            guard filter(event) else { return }
        }
        
        // Mark as received only if filter passes
        receivedEvent = true
        eventReceiveCount += 1
        lastReceivedEvent = event
        onEventReceived?(event)
        
        if shouldThrowError {
            throw PluginError.executionFailed(reason: "Mock listener error")
        }
    }
}

// MARK: - Mock Event Plugin

fileprivate class MockEventPlugin: PluginProtocol {
    let metadata: PluginMetadata
    var isActive: Bool = false
    
    init(id: String = "test.event.plugin") {
        self.metadata = PluginMetadata(
            id: id,
            name: "Test Event Plugin",
            version: "1.0.0",
            author: "Test Author",
            description: "Test plugin for event system tests",
            capabilities: [.transitionEffect]
        )
    }
    
    func initialize() async throws {
        isActive = true
    }
    
    func cleanup() async {
        isActive = false
    }
}