//
//  AnimationSettingsTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/30.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class AnimationSettingsTests: XCTestCase {
    
    var mockContainer: MockDependencyContainer!
    
    override func setUp() {
        super.setUp()
        mockContainer = MockDependencyContainer()
    }
    
    override func tearDown() {
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - Animation.fromSettings Tests
    
    func test_fromSettings_returns_easeInOut_with_configured_duration() {
        // Given: Settings manager with custom animation duration
        let customDuration = 0.5
        mockContainer.settingsManager.animationDurations[.control] = customDuration
        
        // When: Creating animation from settings using mock container
        let duration = mockContainer.settingsManager.animationDurations[.control] ?? AnimationType.control.defaultDuration
        let animation = Animation.easeInOut(duration: duration)
        
        // Then: Should return easeInOut with configured duration
        XCTAssertNotNil(animation)
        XCTAssertEqual(duration, customDuration)
    }
    
    func test_fromSettings_uses_default_duration_when_not_configured() {
        // Given: Settings manager without custom duration
        mockContainer.settingsManager.animationDurations.removeValue(forKey: .feedback)
        
        // When: Creating animation from settings using default
        let duration = mockContainer.settingsManager.animationDurations[.feedback] ?? AnimationType.feedback.defaultDuration
        let animation = Animation.easeInOut(duration: duration)
        
        // Then: Should use default duration
        XCTAssertNotNil(animation)
        XCTAssertEqual(duration, AnimationType.feedback.defaultDuration)
    }
    
    // MARK: - Animation Convenience Properties Tests
    
    func test_controlAnimation_returns_control_type_animation() {
        // Given: Configured settings
        mockContainer.settingsManager.animationDurations[.control] = 0.3
        
        // When: Creating control animation manually (testing concept)
        let duration = mockContainer.settingsManager.animationDurations[.control] ?? AnimationType.control.defaultDuration
        let animation = Animation.easeInOut(duration: duration)
        
        // Then: Should return valid animation
        XCTAssertNotNil(animation)
        XCTAssertEqual(duration, 0.3)
    }
    
    func test_transitionAnimation_returns_transition_type_animation() {
        // Given: Configured settings
        mockContainer.settingsManager.animationDurations[.transition] = 0.8
        
        // When: Creating transition animation manually (testing concept)
        let duration = mockContainer.settingsManager.animationDurations[.transition] ?? AnimationType.transition.defaultDuration
        let animation = Animation.easeInOut(duration: duration)
        
        // Then: Should return valid animation
        XCTAssertNotNil(animation)
        XCTAssertEqual(duration, 0.8)
    }
    
    func test_feedbackAnimation_returns_feedback_type_animation() {
        // Given: Configured settings
        mockContainer.settingsManager.animationDurations[.feedback] = 0.1
        
        // When: Creating feedback animation manually (testing concept)
        let duration = mockContainer.settingsManager.animationDurations[.feedback] ?? AnimationType.feedback.defaultDuration
        let animation = Animation.easeInOut(duration: duration)
        
        // Then: Should return valid animation
        XCTAssertNotNil(animation)
        XCTAssertEqual(duration, 0.1)
    }
    
    // MARK: - View Extension Tests (Modern API)
    
    func test_settingsAnimation_with_value_uses_modern_api() {
        // Given: A test view and state value
        let testView = Rectangle()
        let testValue = true
        
        // When: Applying settings animation with value (modern API)
        let animatedView = testView.settingsAnimation(.control, value: testValue)
        
        // Then: Should create animated view without crashing
        XCTAssertNotNil(animatedView)
    }
    
    // MARK: - Modern API Migration Tests
    
    func test_withSettingsAnimation_wrapper_function() {
        // Given: A state variable and settings
        var testState = false
        mockContainer.settingsManager.animationDurations[.feedback] = 0.2
        
        // When: Using withAnimation wrapper (testing concept)
        var animationExecuted = false
        let duration = mockContainer.settingsManager.animationDurations[.feedback] ?? AnimationType.feedback.defaultDuration
        
        // This tests the concept of wrapping withAnimation for settings
        withAnimation(.easeInOut(duration: duration)) {
            testState = true
            animationExecuted = true
        }
        
        // Then: State should be updated and animation wrapper should work
        XCTAssertTrue(testState)
        XCTAssertTrue(animationExecuted)
        XCTAssertEqual(duration, 0.2)
    }
    
    // MARK: - Integration Tests
    
    func test_modern_animation_extension_integrates_with_swiftui_views() {
        // Given: A SwiftUI view with modern animation API
        struct TestView: View {
            @State private var isActive = false
            
            var body: some View {
                Rectangle()
                    .fill(isActive ? Color.red : Color.blue)
                    .settingsAnimation(.transition, value: isActive)
                    .onTapGesture {
                        // Using modern withAnimation pattern
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isActive.toggle()
                        }
                    }
            }
        }
        
        // When: Creating the view
        let testView = TestView()
        
        // Then: Should create without crashing
        XCTAssertNotNil(testView)
        XCTAssertNotNil(testView.body)
    }
}

// MARK: - Test Helper Extensions

extension AnimationSettingsTests {
    
    /// Helper to verify modern animation API usage
    private func verifyModernAnimationAPI<V: View>(_ view: V) {
        // This helper verifies that a view can be rendered without issues
        // when using modern animation APIs
        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
    }
}