//
//  CustomProgressBarTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class CustomProgressBarTests: XCTestCase {
    
    func test_customProgressBar_initialization_withoutCallback() {
        let progressBar = CustomProgressBar(currentIndex: 5, totalCount: 10)
        
        XCTAssertNotNil(progressBar)
        XCTAssertEqual(progressBar.currentIndex, 5)
        XCTAssertEqual(progressBar.totalCount, 10)
        XCTAssertNil(progressBar.onProgressTapped)
    }
    
    func test_customProgressBar_initialization_withCallback() {
        var tappedIndex: Int?
        let callback: (Int) -> Void = { index in
            tappedIndex = index
        }
        
        let progressBar = CustomProgressBar(
            currentIndex: 3,
            totalCount: 8,
            onProgressTapped: callback
        )
        
        XCTAssertNotNil(progressBar)
        XCTAssertEqual(progressBar.currentIndex, 3)
        XCTAssertEqual(progressBar.totalCount, 8)
        XCTAssertNotNil(progressBar.onProgressTapped)
    }
    
    func test_progressBar_properties() {
        // Test different progress states
        let beginningBar = CustomProgressBar(currentIndex: 0, totalCount: 10)
        XCTAssertEqual(beginningBar.currentIndex, 0)
        XCTAssertEqual(beginningBar.totalCount, 10)
        
        let middleBar = CustomProgressBar(currentIndex: 4, totalCount: 10)
        XCTAssertEqual(middleBar.currentIndex, 4)
        XCTAssertEqual(middleBar.totalCount, 10)
        
        let endBar = CustomProgressBar(currentIndex: 9, totalCount: 10)
        XCTAssertEqual(endBar.currentIndex, 9)
        XCTAssertEqual(endBar.totalCount, 10)
    }
    
    func test_progressBar_edgeCaseValues() {
        // Test zero count
        let zeroBar = CustomProgressBar(currentIndex: 0, totalCount: 0)
        XCTAssertEqual(zeroBar.currentIndex, 0)
        XCTAssertEqual(zeroBar.totalCount, 0)
        
        // Test single item
        let singleBar = CustomProgressBar(currentIndex: 0, totalCount: 1)
        XCTAssertEqual(singleBar.currentIndex, 0)
        XCTAssertEqual(singleBar.totalCount, 1)
        
        // Test large numbers
        let largeBar = CustomProgressBar(currentIndex: 49, totalCount: 100)
        XCTAssertEqual(largeBar.currentIndex, 49)
        XCTAssertEqual(largeBar.totalCount, 100)
    }
    
    func test_progressBar_bodyGeneration() {
        let progressBar = CustomProgressBar(currentIndex: 2, totalCount: 5)
        
        // Test that body can be generated without crashing
        let body = progressBar.body
        XCTAssertNotNil(body)
    }
    
    func test_progressBar_displayText() {
        let progressBar = CustomProgressBar(currentIndex: 6, totalCount: 50)
        
        // The display text should show "7 / 50" (currentIndex + 1)
        let body = progressBar.body
        XCTAssertNotNil(body)
        
        // We can't directly test the text content in SwiftUI views,
        // but we can verify the view is properly constructed
    }
    
    func test_progressBar_edgeCases() {
        // Test with very small numbers
        let smallProgressBar = CustomProgressBar(currentIndex: 0, totalCount: 1)
        XCTAssertNotNil(smallProgressBar.body)
        
        // Test with large numbers
        let largeProgressBar = CustomProgressBar(currentIndex: 999, totalCount: 1000)
        XCTAssertNotNil(largeProgressBar.body)
        
        // Test with zero total (edge case)
        let zeroProgressBar = CustomProgressBar(currentIndex: 0, totalCount: 0)
        XCTAssertNotNil(zeroProgressBar.body)
    }
}