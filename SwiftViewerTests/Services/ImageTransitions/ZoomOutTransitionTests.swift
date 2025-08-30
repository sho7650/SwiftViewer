//
//  ZoomOutTransitionTests.swift
//  SwiftViewerTests
//
//  Created by SwiftViewer Development Team.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

final class ZoomOutTransitionTests: XCTestCase {
    
    var sut: ZoomOutTransition!
    
    override func setUp() {
        super.setUp()
        sut = ZoomOutTransition()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Protocol Conformance Tests
    
    func test_zoomOutTransition_conformsToProtocol() {
        XCTAssertTrue(sut is ImageTransitionProtocol)
    }
    
    func test_zoomOutTransition_hasCorrectName() {
        XCTAssertEqual(sut.name, "zoomOut")
    }
    
    func test_zoomOutTransition_hasCorrectDisplayName() {
        XCTAssertEqual(sut.displayName, "Zoom Out")
    }
    
    // MARK: - Transition Creation Tests
    
    func test_zoomOutTransition_createTransition_returnsValidTransition() {
        let duration: TimeInterval = 0.3
        
        let transition = sut.createTransition(duration: duration)
        
        XCTAssertNotNil(transition)
    }
    
    func test_zoomOutTransition_createTransition_handlesDifferentDurations() {
        let durations: [TimeInterval] = [0.1, 0.2, 0.5, 1.0, 2.0]
        
        for duration in durations {
            let transition = sut.createTransition(duration: duration)
            XCTAssertNotNil(transition, "Should create transition for duration: \(duration)")
        }
    }
    
    func test_zoomOutTransition_createTransition_handlesZeroDuration() {
        let transition = sut.createTransition(duration: 0.0)
        XCTAssertNotNil(transition)
    }
    
    func test_zoomOutTransition_createTransition_handlesNegativeDuration() {
        let transition = sut.createTransition(duration: -0.5)
        XCTAssertNotNil(transition)
    }
    
    // MARK: - Consistency Tests
    
    func test_zoomOutTransition_properties_areConsistent() {
        let name1 = sut.name
        let name2 = sut.name
        let displayName1 = sut.displayName
        let displayName2 = sut.displayName
        
        XCTAssertEqual(name1, name2)
        XCTAssertEqual(displayName1, displayName2)
    }
    
    func test_zoomOutTransition_createTransition_isConsistent() {
        let duration: TimeInterval = 0.5
        
        let transition1 = sut.createTransition(duration: duration)
        let transition2 = sut.createTransition(duration: duration)
        
        // Both transitions should be created successfully
        XCTAssertNotNil(transition1)
        XCTAssertNotNil(transition2)
    }
}