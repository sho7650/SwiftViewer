//
//  SettingsManagerTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
@testable import SwiftViewer

final class SettingsManagerTests: XCTestCase {
    
    var sut: SettingsManager!
    var mockUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        mockUserDefaults = UserDefaults(suiteName: "com.swiftviewer.tests")!
        mockUserDefaults.removePersistentDomain(forName: "com.swiftviewer.tests")
        sut = SettingsManager(userDefaults: mockUserDefaults)
    }
    
    override func tearDown() {
        mockUserDefaults.removePersistentDomain(forName: "com.swiftviewer.tests")
        sut = nil
        mockUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - SlideShow Interval Tests
    
    func test_slideShowInterval_returnsDefaultValue_whenNotSet() {
        let interval = sut.slideShowInterval
        
        XCTAssertEqual(interval, 10.0, "Should return default interval of 10.0 seconds")
    }
    
    func test_slideShowInterval_returnsStoredValue_whenSet() {
        sut.slideShowInterval = 5.0
        
        let interval = sut.slideShowInterval
        
        XCTAssertEqual(interval, 5.0, "Should return stored interval value")
    }
    
    func test_slideShowInterval_persistsValue_acrossSessions() {
        sut.slideShowInterval = 7.5
        
        // Create new instance with same UserDefaults
        let newSettings = SettingsManager(userDefaults: mockUserDefaults)
        
        XCTAssertEqual(newSettings.slideShowInterval, 7.5, "Should persist value across sessions")
    }
    
    func test_slideShowInterval_handlesZeroValue() {
        mockUserDefaults.set(0.0, forKey: "slideShowInterval")
        
        let interval = sut.slideShowInterval
        
        XCTAssertEqual(interval, 10.0, "Should return default when stored value is 0.0")
    }
    
    func test_slideShowInterval_handlesNegativeValue() {
        mockUserDefaults.set(-1.0, forKey: "slideShowInterval")
        
        let interval = sut.slideShowInterval
        
        XCTAssertEqual(interval, 10.0, "Should return default when stored value is negative")
    }
    
    func test_slideShowInterval_acceptsValidRange() {
        let testValues: [TimeInterval] = [1.0, 5.0, 10.0, 30.0, 60.0, 300.0, 1200.0, 1800.0]
        
        for value in testValues {
            sut.slideShowInterval = value
            XCTAssertEqual(sut.slideShowInterval, value, "Should accept valid interval \(value)")
        }
    }
    
    func test_slideShowInterval_validatesMinimumValue() {
        sut.slideShowInterval = 0.5
        
        XCTAssertEqual(sut.slideShowInterval, 1.0, "Should clamp to minimum 1.0 seconds")
    }
    
    func test_slideShowInterval_validatesMaximumValue() {
        sut.slideShowInterval = 2000.0
        
        XCTAssertEqual(sut.slideShowInterval, 1800.0, "Should clamp to maximum 1800 seconds")
    }
    
    // MARK: - Other Settings Independence Tests
    
    func test_slideShowInterval_isIndependentFromOtherSettings() {
        // Set other settings
        sut.repeatEnabled = true
        sut.sortType = .date(ascending: false)
        sut.debugLoggingEnabled = true
        
        // Change slideShowInterval
        sut.slideShowInterval = 15.0
        
        // Verify other settings unchanged
        XCTAssertTrue(sut.repeatEnabled, "repeatEnabled should remain unchanged")
        XCTAssertEqual(sut.sortType, .date(ascending: false), "sortType should remain unchanged")
        XCTAssertTrue(sut.debugLoggingEnabled, "debugLoggingEnabled should remain unchanged")
        
        // Verify slideShowInterval changed
        XCTAssertEqual(sut.slideShowInterval, 15.0, "slideShowInterval should be updated")
    }
    
    // MARK: - UserDefaults Integration Tests
    
    func test_slideShowInterval_usesCorrectUserDefaultsKey() {
        sut.slideShowInterval = 8.5
        
        let storedValue = mockUserDefaults.double(forKey: "slideShowInterval")
        
        XCTAssertEqual(storedValue, 8.5, "Should store value with correct key")
    }
    
    func test_slideShowInterval_handlesUserDefaultsDirectModification() {
        mockUserDefaults.set(12.5, forKey: "slideShowInterval")
        
        let interval = sut.slideShowInterval
        
        XCTAssertEqual(interval, 12.5, "Should read directly modified UserDefaults value")
    }
    
    // MARK: - Phase 1 New Properties Tests
    
    func test_autoHideDelay_returnsDefaultValue() {
        XCTAssertEqual(sut.autoHideDelay, 3.0, "Should return default 3.0 seconds")
    }
    
    func test_autoHideDelay_persistsValue() {
        sut.autoHideDelay = 5.0
        
        let newSettings = SettingsManager(userDefaults: mockUserDefaults)
        XCTAssertEqual(newSettings.autoHideDelay, 5.0)
    }
    
    func test_autoHideDelay_validatesRange() {
        sut.autoHideDelay = 0.5
        XCTAssertEqual(sut.autoHideDelay, 1.0, "Should clamp to minimum")
        
        sut.autoHideDelay = 100.0
        XCTAssertEqual(sut.autoHideDelay, 60.0, "Should clamp to maximum")
    }
    
    func test_animationDurations_returnsDefaultValues() {
        let durations = sut.animationDurations
        XCTAssertEqual(durations[.control], 0.3)
        XCTAssertEqual(durations[.transition], 0.2)
        XCTAssertEqual(durations[.feedback], 0.1)
    }
    
    func test_animationDurations_persistsValues() {
        let custom: [AnimationType: TimeInterval] = [
            .control: 0.5,
            .transition: 0.4,
            .feedback: 0.2
        ]
        sut.animationDurations = custom
        
        let newSettings = SettingsManager(userDefaults: mockUserDefaults)
        XCTAssertEqual(newSettings.animationDurations[.control], 0.5)
        XCTAssertEqual(newSettings.animationDurations[.transition], 0.4)
        XCTAssertEqual(newSettings.animationDurations[.feedback], 0.2)
    }
    
    func test_blurRadius_returnsDefaultValue() {
        XCTAssertEqual(sut.blurRadius, 20.0)
    }
    
    func test_blurRadius_validatesRange() {
        sut.blurRadius = -10.0
        XCTAssertEqual(sut.blurRadius, 0.0, "Should clamp to minimum")
        
        sut.blurRadius = 100.0
        XCTAssertEqual(sut.blurRadius, 50.0, "Should clamp to maximum")
    }
    
    func test_blurOpacity_returnsDefaultValue() {
        XCTAssertEqual(sut.blurOpacity, 0.8)
    }
    
    func test_blurOpacity_validatesRange() {
        sut.blurOpacity = -0.5
        XCTAssertEqual(sut.blurOpacity, 0.0, "Should clamp to minimum")
        
        sut.blurOpacity = 1.5
        XCTAssertEqual(sut.blurOpacity, 1.0, "Should clamp to maximum")
    }
    
    func test_blurOpacity_handlesZeroCorrectly() {
        sut.blurOpacity = 0.0
        XCTAssertEqual(sut.blurOpacity, 0.0, "Should allow setting to 0.0")
        
        // Create new instance should still get 0.0
        let newSettings = SettingsManager(userDefaults: mockUserDefaults)
        XCTAssertEqual(newSettings.blurOpacity, 0.0, "Should persist 0.0 value")
    }
    
    func test_loggingLevel_returnsDefaultValue() {
        XCTAssertEqual(sut.loggingLevel, .info)
    }
    
    func test_loggingLevel_persistsValue() {
        sut.loggingLevel = .debug
        
        let newSettings = SettingsManager(userDefaults: mockUserDefaults)
        XCTAssertEqual(newSettings.loggingLevel, .debug)
    }
    
    func test_windowPosition_returnsDefaultValue() {
        XCTAssertEqual(sut.windowPosition, .normal)
    }
    
    func test_windowPosition_persistsValue() {
        sut.windowPosition = .alwaysOnTop
        
        let newSettings = SettingsManager(userDefaults: mockUserDefaults)
        XCTAssertEqual(newSettings.windowPosition, .alwaysOnTop)
    }
    
    func test_slideShowPresetIntervals_returnsCorrectValues() {
        let expected: [TimeInterval] = [1, 2, 3, 5, 10, 20, 30, 60, 120, 300, 600, 1200, 1800]
        XCTAssertEqual(sut.slideShowPresetIntervals, expected)
    }
    
    // MARK: - Transition Type Tests
    
    func test_transitionType_returnsDefaultValue_whenNotSet() {
        let transitionType = sut.transitionType
        
        XCTAssertEqual(transitionType, .crossDissolve, "Should return default transition type of crossDissolve")
    }
    
    func test_transitionType_returnsStoredValue_whenSet() {
        sut.transitionType = .zoomOut
        
        let transitionType = sut.transitionType
        
        XCTAssertEqual(transitionType, .zoomOut, "Should return stored transition type value")
    }
    
    func test_transitionType_persistsValue_acrossSessions() {
        sut.transitionType = .zoomIn
        
        // Create new instance with same UserDefaults
        let newSettings = SettingsManager(userDefaults: mockUserDefaults)
        
        XCTAssertEqual(newSettings.transitionType, .zoomIn, "Should persist transition type across sessions")
    }
    
    func test_transitionType_handlesAllTransitionTypes() {
        let allTypes = TransitionType.allCases
        
        for type in allTypes {
            sut.transitionType = type
            XCTAssertEqual(sut.transitionType, type, "Should handle transition type: \(type)")
        }
    }
    
    func test_transitionType_fallsBackToDefault_withInvalidRawValue() {
        // Manually set invalid raw value
        mockUserDefaults.set("invalidTransitionType", forKey: "transitionType")
        
        let transitionType = sut.transitionType
        
        XCTAssertEqual(transitionType, .crossDissolve, "Should fall back to default when invalid raw value is stored")
    }
    
    // MARK: - Mock Settings Manager Tests
    
    func test_mockSettingsManager_hasCorrectDefaultInterval() {
        let mockSettings = MockSettingsManager()
        
        XCTAssertEqual(mockSettings.slideShowInterval, 10.0, "Mock should have correct default interval")
    }
    
    func test_mockSettingsManager_allowsIntervalModification() {
        let mockSettings = MockSettingsManager()
        
        mockSettings.slideShowInterval = 20.0
        
        XCTAssertEqual(mockSettings.slideShowInterval, 20.0, "Mock should allow interval modification")
    }
    
    func test_mockSettingsManager_hasCorrectDefaultNewProperties() {
        let mockSettings = MockSettingsManager()
        
        XCTAssertEqual(mockSettings.autoHideDelay, 3.0)
        XCTAssertEqual(mockSettings.animationDurations[.control], 0.3)
        XCTAssertEqual(mockSettings.blurRadius, 20.0)
        XCTAssertEqual(mockSettings.blurOpacity, 0.8)
        XCTAssertEqual(mockSettings.loggingLevel, .info)
        XCTAssertEqual(mockSettings.windowPosition, .normal)
        XCTAssertEqual(mockSettings.slideShowPresetIntervals.count, 13)
        XCTAssertEqual(mockSettings.transitionType, .crossDissolve)
    }
}