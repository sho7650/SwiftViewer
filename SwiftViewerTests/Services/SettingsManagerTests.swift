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
        let testValues: [TimeInterval] = [0.5, 1.0, 5.0, 10.0, 30.0, 60.0]
        
        for value in testValues {
            sut.slideShowInterval = value
            XCTAssertEqual(sut.slideShowInterval, value, "Should accept valid interval \(value)")
        }
    }
    
    func test_slideShowInterval_validatesMinimumValue() {
        sut.slideShowInterval = 0.1
        
        XCTAssertEqual(sut.slideShowInterval, 0.5, "Should clamp to minimum 0.5 seconds")
    }
    
    func test_slideShowInterval_validatesMaximumValue() {
        sut.slideShowInterval = 120.0
        
        XCTAssertEqual(sut.slideShowInterval, 60.0, "Should clamp to maximum 60 seconds")
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
}