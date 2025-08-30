//
//  TransitionManagerTests.swift
//  SwiftViewerTests
//
//  Created by SwiftViewer Development Team.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

final class TransitionManagerTests: XCTestCase {
    
    var sut: TransitionManager!
    
    override func setUp() {
        super.setUp()
        sut = TransitionManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_transitionManager_initialization_succeeds() {
        XCTAssertNotNil(sut)
    }
    
    func test_transitionManager_defaultTransitionType_isCrossDissolve() {
        XCTAssertEqual(TransitionManager.defaultTransitionType, .crossDissolve)
    }
    
    // MARK: - Available Transitions Tests
    
    func test_transitionManager_availableTransitions_containsAllExpectedTypes() {
        let availableTransitions = sut.availableTransitions
        
        XCTAssertTrue(availableTransitions.contains(.crossDissolve))
        XCTAssertTrue(availableTransitions.contains(.zoomOut))
        XCTAssertTrue(availableTransitions.contains(.zoomIn))
    }
    
    func test_transitionManager_availableTransitions_countMatchesTransitionTypes() {
        let expectedCount = TransitionType.allCases.count
        let actualCount = sut.availableTransitions.count
        
        XCTAssertEqual(actualCount, expectedCount)
    }
    
    func test_transitionManager_availableTransitions_isSorted() {
        let availableTransitions = sut.availableTransitions
        let sortedTransitions = availableTransitions.sorted { $0.rawValue < $1.rawValue }
        
        XCTAssertEqual(availableTransitions, sortedTransitions)
    }
    
    // MARK: - Transition Creation Tests
    
    func test_transitionManager_createTransition_crossDissolve_returnsValidTransition() {
        let transition = sut.createTransition(for: .crossDissolve, duration: 0.3)
        XCTAssertNotNil(transition)
    }
    
    func test_transitionManager_createTransition_zoomOut_returnsValidTransition() {
        let transition = sut.createTransition(for: .zoomOut, duration: 0.3)
        XCTAssertNotNil(transition)
    }
    
    func test_transitionManager_createTransition_zoomIn_returnsValidTransition() {
        let transition = sut.createTransition(for: .zoomIn, duration: 0.3)
        XCTAssertNotNil(transition)
    }
    
    func test_transitionManager_createTransition_handlesDifferentDurations() {
        let durations: [TimeInterval] = [0.1, 0.3, 0.5, 1.0, 2.0]
        
        for duration in durations {
            for transitionType in TransitionType.allCases {
                let transition = sut.createTransition(for: transitionType, duration: duration)
                XCTAssertNotNil(transition, "Should create transition for type: \(transitionType), duration: \(duration)")
            }
        }
    }
    
    func test_transitionManager_createTransition_handlesZeroDuration() {
        for transitionType in TransitionType.allCases {
            let transition = sut.createTransition(for: transitionType, duration: 0.0)
            XCTAssertNotNil(transition, "Should handle zero duration for type: \(transitionType)")
        }
    }
    
    func test_transitionManager_createTransition_handlesNegativeDuration() {
        for transitionType in TransitionType.allCases {
            let transition = sut.createTransition(for: transitionType, duration: -0.5)
            XCTAssertNotNil(transition, "Should handle negative duration for type: \(transitionType)")
        }
    }
    
    // MARK: - Display Name Tests
    
    func test_transitionManager_getDisplayName_crossDissolve_returnsCorrectName() {
        let displayName = sut.getDisplayName(for: .crossDissolve)
        XCTAssertEqual(displayName, "Cross Dissolve")
    }
    
    func test_transitionManager_getDisplayName_zoomOut_returnsCorrectName() {
        let displayName = sut.getDisplayName(for: .zoomOut)
        XCTAssertEqual(displayName, "Zoom Out")
    }
    
    func test_transitionManager_getDisplayName_zoomIn_returnsCorrectName() {
        let displayName = sut.getDisplayName(for: .zoomIn)
        XCTAssertEqual(displayName, "Zoom In")
    }
    
    func test_transitionManager_getDisplayName_allTypes_returnNonEmptyStrings() {
        for transitionType in TransitionType.allCases {
            let displayName = sut.getDisplayName(for: transitionType)
            XCTAssertFalse(displayName.isEmpty, "Display name should not be empty for type: \(transitionType)")
        }
    }
    
    // MARK: - Availability Tests
    
    func test_transitionManager_isTransitionAvailable_allTypesAreAvailable() {
        for transitionType in TransitionType.allCases {
            let isAvailable = sut.isTransitionAvailable(transitionType)
            XCTAssertTrue(isAvailable, "Transition should be available for type: \(transitionType)")
        }
    }
    
    // MARK: - Consistency Tests
    
    func test_transitionManager_createTransition_isConsistent() {
        let duration: TimeInterval = 0.5
        
        for transitionType in TransitionType.allCases {
            let transition1 = sut.createTransition(for: transitionType, duration: duration)
            let transition2 = sut.createTransition(for: transitionType, duration: duration)
            
            XCTAssertNotNil(transition1)
            XCTAssertNotNil(transition2)
        }
    }
}