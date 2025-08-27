//
//  SettingsTypesTests.swift
//  SwiftViewerTests
//
//  Created on 2025/08/26.
//

import XCTest
@testable import SwiftViewer

final class SettingsTypesTests: XCTestCase {
    
    // MARK: - AnimationType Tests
    
    func test_AnimationType_allCases_returnsAllTypes() {
        let allCases = AnimationType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.control))
        XCTAssertTrue(allCases.contains(.transition))
        XCTAssertTrue(allCases.contains(.feedback))
    }
    
    func test_AnimationType_displayName_returnsCorrectNames() {
        XCTAssertEqual(AnimationType.control.displayName, "Controls")
        XCTAssertEqual(AnimationType.transition.displayName, "Transitions")
        XCTAssertEqual(AnimationType.feedback.displayName, "Feedback")
    }
    
    func test_AnimationType_defaultDuration_returnsCorrectValues() {
        XCTAssertEqual(AnimationType.control.defaultDuration, 0.3)
        XCTAssertEqual(AnimationType.transition.defaultDuration, 0.2)
        XCTAssertEqual(AnimationType.feedback.defaultDuration, 0.1)
    }
    
    func test_AnimationType_codable_encodesAndDecodes() throws {
        let original = AnimationType.control
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AnimationType.self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
    
    func test_AnimationType_rawValue_returnsCorrectStrings() {
        XCTAssertEqual(AnimationType.control.rawValue, "control")
        XCTAssertEqual(AnimationType.transition.rawValue, "transition")
        XCTAssertEqual(AnimationType.feedback.rawValue, "feedback")
    }
    
    // MARK: - WindowPosition Tests
    
    func test_WindowPosition_allCases_returnsAllPositions() {
        let allCases: [WindowPosition] = [.normal, .alwaysOnTop, .alwaysOnBottom]
        XCTAssertEqual(allCases.count, 3)
    }
    
    func test_WindowPosition_displayName_returnsCorrectNames() {
        XCTAssertEqual(WindowPosition.normal.displayName, "Normal")
        XCTAssertEqual(WindowPosition.alwaysOnTop.displayName, "Always on Top")
        XCTAssertEqual(WindowPosition.alwaysOnBottom.displayName, "Always on Bottom")
    }
    
    func test_WindowPosition_codable_encodesAndDecodes() throws {
        let original = WindowPosition.alwaysOnTop
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(WindowPosition.self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
    
    func test_WindowPosition_rawValue_returnsCorrectStrings() {
        XCTAssertEqual(WindowPosition.normal.rawValue, "normal")
        XCTAssertEqual(WindowPosition.alwaysOnTop.rawValue, "alwaysOnTop")
        XCTAssertEqual(WindowPosition.alwaysOnBottom.rawValue, "alwaysOnBottom")
    }
    
    func test_WindowPosition_equatable_comparesCorrectly() {
        let position1 = WindowPosition.normal
        let position2 = WindowPosition.normal
        let position3 = WindowPosition.alwaysOnTop
        
        XCTAssertEqual(position1, position2)
        XCTAssertNotEqual(position1, position3)
    }
    
    // MARK: - Dictionary Encoding Tests
    
    func test_AnimationDurations_dictionary_encodesAndDecodes() throws {
        let original: [AnimationType: TimeInterval] = [
            .control: 0.5,
            .transition: 0.3,
            .feedback: 0.15
        ]
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode([AnimationType: TimeInterval].self, from: data)
        
        XCTAssertEqual(decoded[.control], 0.5)
        XCTAssertEqual(decoded[.transition], 0.3)
        XCTAssertEqual(decoded[.feedback], 0.15)
    }
}

// MARK: - SlideshowIntervalHelper Tests

class SlideshowIntervalHelperTests: XCTestCase {
    
    func test_intervals_containsExpectedValues() {
        let expected: [TimeInterval] = [1, 2, 3, 5, 10, 20, 30, 60, 120, 300, 600, 1200, 1800]
        XCTAssertEqual(SlideshowIntervalHelper.intervals, expected)
    }
    
    func test_indexForInterval_returnsCorrectIndex() {
        XCTAssertEqual(SlideshowIntervalHelper.indexForInterval(1), 0)
        XCTAssertEqual(SlideshowIntervalHelper.indexForInterval(60), 7)
        XCTAssertEqual(SlideshowIntervalHelper.indexForInterval(120), 8)
        XCTAssertEqual(SlideshowIntervalHelper.indexForInterval(300), 9)
        XCTAssertEqual(SlideshowIntervalHelper.indexForInterval(1800), 12)
    }
    
    func test_indexForInterval_findsClosestForInvalidValues() {
        // Test values between valid intervals
        XCTAssertEqual(SlideshowIntervalHelper.indexForInterval(4), 2) // Closer to 3
        XCTAssertEqual(SlideshowIntervalHelper.indexForInterval(90), 7) // Closer to 60
        XCTAssertEqual(SlideshowIntervalHelper.indexForInterval(200), 8) // Closer to 120
        XCTAssertEqual(SlideshowIntervalHelper.indexForInterval(0.5), 0) // Closest to 1
        XCTAssertEqual(SlideshowIntervalHelper.indexForInterval(2000), 12) // Closest to 1800
    }
    
    func test_intervalForIndex_returnsCorrectValue() {
        XCTAssertEqual(SlideshowIntervalHelper.intervalForIndex(0), 1)
        XCTAssertEqual(SlideshowIntervalHelper.intervalForIndex(7), 60)
        XCTAssertEqual(SlideshowIntervalHelper.intervalForIndex(8), 120)
        XCTAssertEqual(SlideshowIntervalHelper.intervalForIndex(9), 300)
        XCTAssertEqual(SlideshowIntervalHelper.intervalForIndex(12), 1800)
    }
    
    func test_intervalForIndex_clampsOutOfRangeValues() {
        XCTAssertEqual(SlideshowIntervalHelper.intervalForIndex(-1), 1) // Clamps to 0
        XCTAssertEqual(SlideshowIntervalHelper.intervalForIndex(100), 1800) // Clamps to max
    }
    
    func test_formatInterval_formatsCorrectly() {
        XCTAssertEqual(SlideshowIntervalHelper.formatInterval(1), "1s")
        XCTAssertEqual(SlideshowIntervalHelper.formatInterval(30), "30s")
        XCTAssertEqual(SlideshowIntervalHelper.formatInterval(60), "1m")
        XCTAssertEqual(SlideshowIntervalHelper.formatInterval(120), "2m")
        XCTAssertEqual(SlideshowIntervalHelper.formatInterval(300), "5m")
        XCTAssertEqual(SlideshowIntervalHelper.formatInterval(600), "10m")
        XCTAssertEqual(SlideshowIntervalHelper.formatInterval(1200), "20m")
        XCTAssertEqual(SlideshowIntervalHelper.formatInterval(1800), "30m")
    }
    
    func test_intervalConversion_isReversible() {
        for interval in SlideshowIntervalHelper.intervals {
            let index = SlideshowIntervalHelper.indexForInterval(interval)
            let convertedBack = SlideshowIntervalHelper.intervalForIndex(index)
            XCTAssertEqual(interval, convertedBack, "Conversion should be reversible for \(interval)")
        }
    }
}