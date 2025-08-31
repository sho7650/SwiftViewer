//
//  TransitionTypeTests.swift
//  SwiftViewerTests
//
//  Created by SwiftViewer Development Team.
//

import XCTest
@testable import SwiftViewer

final class TransitionTypeTests: XCTestCase {
    
    // MARK: - Enum Cases Tests
    
    func test_transitionType_hasExpectedCases() {
        let allCases = TransitionType.allCases
        
        XCTAssertEqual(allCases.count, 6)
        XCTAssertTrue(allCases.contains(.crossDissolve))
        XCTAssertTrue(allCases.contains(.zoomOut))
        XCTAssertTrue(allCases.contains(.zoomIn))
        XCTAssertTrue(allCases.contains(.none))
        XCTAssertTrue(allCases.contains(.blurReplace))
        XCTAssertTrue(allCases.contains(.blurReplaceUpUp))
    }
    
    func test_transitionType_rawValues_areCorrect() {
        XCTAssertEqual(TransitionType.crossDissolve.rawValue, "crossDissolve")
        XCTAssertEqual(TransitionType.zoomOut.rawValue, "zoomOut")
        XCTAssertEqual(TransitionType.zoomIn.rawValue, "zoomIn")
        XCTAssertEqual(TransitionType.none.rawValue, "none")
        XCTAssertEqual(TransitionType.blurReplace.rawValue, "blurReplace")
        XCTAssertEqual(TransitionType.blurReplaceUpUp.rawValue, "blurReplaceUpUp")
    }
    
    // MARK: - Display Name Tests
    
    func test_transitionType_displayNames_areCorrect() {
        XCTAssertEqual(TransitionType.crossDissolve.displayName, "Cross Dissolve")
        XCTAssertEqual(TransitionType.zoomOut.displayName, "Zoom Out")
        XCTAssertEqual(TransitionType.zoomIn.displayName, "Zoom In")
        XCTAssertEqual(TransitionType.none.displayName, "None")
        XCTAssertEqual(TransitionType.blurReplace.displayName, "Blur Replace")
        XCTAssertEqual(TransitionType.blurReplaceUpUp.displayName, "Blur Replace (Expand)")
    }
    
    // MARK: - Codable Tests
    
    func test_transitionType_codable_encodesCorrectly() throws {
        let transitions = TransitionType.allCases
        let encoder = JSONEncoder()
        
        for transition in transitions {
            let data = try encoder.encode(transition)
            let jsonString = String(data: data, encoding: .utf8)
            XCTAssertNotNil(jsonString)
            XCTAssertTrue(jsonString?.contains(transition.rawValue) == true)
        }
    }
    
    func test_transitionType_codable_decodesCorrectly() throws {
        let testCases = [
            ("\"crossDissolve\"", TransitionType.crossDissolve),
            ("\"zoomOut\"", TransitionType.zoomOut),
            ("\"zoomIn\"", TransitionType.zoomIn)
        ]
        
        let decoder = JSONDecoder()
        
        for (jsonString, expectedType) in testCases {
            let data = jsonString.data(using: .utf8)!
            let decodedType = try decoder.decode(TransitionType.self, from: data)
            XCTAssertEqual(decodedType, expectedType)
        }
    }
    
    func test_transitionType_codable_handlesInvalidRawValue() throws {
        let invalidData = "\"invalidTransition\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(TransitionType.self, from: invalidData))
    }
    
    // MARK: - Case Iteration Tests
    
    func test_transitionType_allCases_isComplete() {
        // Ensure we haven't missed any cases when adding new transitions
        let expectedCount = 6
        XCTAssertEqual(TransitionType.allCases.count, expectedCount, 
                      "Update this test when adding new transition types")
    }
    
    func test_transitionType_allCases_hasUniqueRawValues() {
        let rawValues = TransitionType.allCases.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)
        
        XCTAssertEqual(rawValues.count, uniqueRawValues.count, 
                      "All transition types should have unique raw values")
    }
    
    func test_transitionType_allCases_hasUniqueDisplayNames() {
        let displayNames = TransitionType.allCases.map { $0.displayName }
        let uniqueDisplayNames = Set(displayNames)
        
        XCTAssertEqual(displayNames.count, uniqueDisplayNames.count,
                      "All transition types should have unique display names")
    }
}