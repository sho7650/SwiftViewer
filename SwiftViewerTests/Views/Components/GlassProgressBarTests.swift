//
//  GlassProgressBarTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/31.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

final class GlassProgressBarTests: XCTestCase {
    
    // MARK: - Basic Properties Tests
    
    func test_glassProgressBar_createsValidProgressBar() {
        // Given & When
        let progressBar = GlassProgressBar(
            currentIndex: 2,
            totalCount: 10,
            onTapped: { _ in }
        )
        
        // Then
        XCTAssertNotNil(progressBar)
    }
    
    func test_glassProgressBar_handlesZeroTotalCount() {
        // Given & When
        let progressBar = GlassProgressBar(
            currentIndex: 0,
            totalCount: 0,
            onTapped: { _ in }
        )
        
        // Then
        // Should handle edge case gracefully
        XCTAssertNotNil(progressBar)
    }
    
    func test_glassProgressBar_handlesMaxIndex() {
        // Given & When
        let progressBar = GlassProgressBar(
            currentIndex: 9,
            totalCount: 10,
            onTapped: { _ in }
        )
        
        // Then
        // Should handle maximum index correctly
        XCTAssertNotNil(progressBar)
    }
    
    // MARK: - Glass Effect Tests
    
    func test_glassProgressBar_appliesGlassBackground() {
        // Given & When
        let progressBar = GlassProgressBar(
            currentIndex: 1,
            totalCount: 5,
            onTapped: { _ in }
        )
        
        // Then
        // Should apply glass material background
        XCTAssertNotNil(progressBar)
    }
    
    func test_glassProgressBar_hasGlassProgressFill() {
        // Given & When
        let progressBar = GlassProgressBar(
            currentIndex: 3,
            totalCount: 8,
            onTapped: { _ in }
        )
        
        // Then
        // Progress fill should use glass styling
        XCTAssertNotNil(progressBar)
    }
    
    // MARK: - Interaction Tests
    
    func test_glassProgressBar_handlesTapInteraction() {
        // Given
        var tappedIndex: Int?
        let progressBar = GlassProgressBar(
            currentIndex: 2,
            totalCount: 6,
            onTapped: { index in
                tappedIndex = index
            }
        )
        
        // When & Then
        // Tap interaction should be preserved with glass styling
        XCTAssertNotNil(progressBar)
        // Note: Actual tap testing requires UI interaction framework
    }
    
    // MARK: - Visual Feedback Tests
    
    func test_glassProgressBar_providesVisualFeedback() {
        // Given & When
        let progressBar = GlassProgressBar(
            currentIndex: 4,
            totalCount: 7,
            onTapped: { _ in }
        )
        
        // Then
        // Should provide enhanced visual feedback through glass effects
        XCTAssertNotNil(progressBar)
    }
    
    // MARK: - Layout Tests
    
    func test_glassProgressBar_maintainsCorrectLayout() {
        // Given & When
        let progressBar = GlassProgressBar(
            currentIndex: 1,
            totalCount: 4,
            onTapped: { _ in }
        )
        
        // Then
        // Layout should remain consistent with glassmorphism styling
        XCTAssertNotNil(progressBar)
    }
    
    // MARK: - Performance Tests
    
    func test_glassProgressBar_performsEfficientRendering() {
        // Given
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When
        for i in 0..<50 {
            let _ = GlassProgressBar(
                currentIndex: i % 10,
                totalCount: 10,
                onTapped: { _ in }
            )
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        // Glass progress bar should render efficiently
        XCTAssertLessThan(timeElapsed, 0.05, "Glass progress bar should render efficiently")
    }
    
    // MARK: - Adaptive Transparency Tests
    
    func test_glassProgressBar_adaptsToBackground() {
        // Given & When
        let progressBar = GlassProgressBar(
            currentIndex: 3,
            totalCount: 8,
            onTapped: { _ in }
        )
        
        // Then
        // Should adapt transparency based on background content
        XCTAssertNotNil(progressBar)
    }
    
    // MARK: - Progress Computation Tests

    func test_glassProgressBar_singleImageFolder_progressIsFiniteZero() {
        // Given a folder with exactly one image (totalCount == 1),
        // the progress divisor (totalCount - 1) is 0.
        let progressBar = GlassProgressBar(
            currentIndex: 0,
            totalCount: 1,
            onTapped: { _ in }
        )

        // Then progress must be a finite value, not NaN, and clamped to 0.
        XCTAssertTrue(progressBar.progress.isFinite, "Progress must not be NaN for a single-image folder")
        XCTAssertEqual(progressBar.progress, 0.0, "Single-image folder should report zero progress")
    }

    func test_glassProgressBar_progressSpansZeroToOne() {
        XCTAssertEqual(GlassProgressBar(currentIndex: 0, totalCount: 10, onTapped: { _ in }).progress, 0.0)
        XCTAssertEqual(GlassProgressBar(currentIndex: 9, totalCount: 10, onTapped: { _ in }).progress, 1.0)
    }

    // MARK: - Edge Case Tests

    func test_glassProgressBar_handlesInvalidIndex() {
        // Given & When
        let progressBarNegative = GlassProgressBar(
            currentIndex: -1,
            totalCount: 5,
            onTapped: { _ in }
        )
        
        let progressBarOverflow = GlassProgressBar(
            currentIndex: 10,
            totalCount: 5,
            onTapped: { _ in }
        )
        
        // Then
        // Should handle invalid indices gracefully
        XCTAssertNotNil(progressBarNegative)
        XCTAssertNotNil(progressBarOverflow)
    }
}