//
//  SlideShowControlsViewTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
import SwiftUI
@testable import SwiftViewer

@MainActor
final class SlideShowControlsViewTests: XCTestCase {
    
    func test_slideShowControlsView_initialization_minimal() {
        var previousCalled = false
        var toggleCalled = false
        var nextCalled = false
        var repeatCalled = false
        
        let controlsView = SlideShowControlsView(
            isSlideShowRunning: false,
            currentIndex: 0,
            totalCount: 10,
            onPrevious: { previousCalled = true },
            onToggleSlideShow: { toggleCalled = true },
            onNext: { nextCalled = true },
            onToggleRepeat: { repeatCalled = true }
        )
        
        XCTAssertNotNil(controlsView)
        XCTAssertEqual(controlsView.isSlideShowRunning, false)
        XCTAssertEqual(controlsView.currentIndex, 0)
        XCTAssertEqual(controlsView.totalCount, 10)
        XCTAssertFalse(controlsView.isLeftKeyPressed)
        XCTAssertFalse(controlsView.isSpaceKeyPressed)
        XCTAssertFalse(controlsView.isRightKeyPressed)
        XCTAssertNil(controlsView.onProgressTapped)
    }
    
    func test_slideShowControlsView_initialization_full() {
        var previousCalled = false
        var toggleCalled = false
        var nextCalled = false
        var progressTappedIndex: Int?
        
        let controlsView = SlideShowControlsView(
            isSlideShowRunning: true,
            currentIndex: 5,
            totalCount: 20,
            isLeftKeyPressed: true,
            isSpaceKeyPressed: false,
            isRightKeyPressed: true,
            onPrevious: { previousCalled = true },
            onToggleSlideShow: { toggleCalled = true },
            onNext: { nextCalled = true },
            onToggleRepeat: { },
            onProgressTapped: { index in progressTappedIndex = index }
        )
        
        XCTAssertNotNil(controlsView)
        XCTAssertEqual(controlsView.isSlideShowRunning, true)
        XCTAssertEqual(controlsView.currentIndex, 5)
        XCTAssertEqual(controlsView.totalCount, 20)
        XCTAssertTrue(controlsView.isLeftKeyPressed)
        XCTAssertFalse(controlsView.isSpaceKeyPressed)
        XCTAssertTrue(controlsView.isRightKeyPressed)
        XCTAssertNotNil(controlsView.onProgressTapped)
    }
    
    func test_slideShowControlsView_bodyGeneration() {
        let controlsView = SlideShowControlsView(
            isSlideShowRunning: false,
            currentIndex: 3,
            totalCount: 8,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { }
        )
        
        let body = controlsView.body
        XCTAssertNotNil(body)
    }
    
    func test_slideShowControlsView_runningState() {
        let runningView = SlideShowControlsView(
            isSlideShowRunning: true,
            currentIndex: 0,
            totalCount: 5,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { }
        )
        
        XCTAssertTrue(runningView.isSlideShowRunning)
        XCTAssertNotNil(runningView.body)
    }
    
    func test_slideShowControlsView_pausedState() {
        let pausedView = SlideShowControlsView(
            isSlideShowRunning: false,
            currentIndex: 2,
            totalCount: 5,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { }
        )
        
        XCTAssertFalse(pausedView.isSlideShowRunning)
        XCTAssertNotNil(pausedView.body)
    }
    
    func test_slideShowControlsView_keyboardFeedback_leftPressed() {
        let view = SlideShowControlsView(
            isSlideShowRunning: false,
            currentIndex: 1,
            totalCount: 5,
            isLeftKeyPressed: true,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { }
        )
        
        XCTAssertTrue(view.isLeftKeyPressed)
        XCTAssertFalse(view.isSpaceKeyPressed)
        XCTAssertFalse(view.isRightKeyPressed)
    }
    
    func test_slideShowControlsView_keyboardFeedback_spacePressed() {
        let view = SlideShowControlsView(
            isSlideShowRunning: false,
            currentIndex: 1,
            totalCount: 5,
            isSpaceKeyPressed: true,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { }
        )
        
        XCTAssertFalse(view.isLeftKeyPressed)
        XCTAssertTrue(view.isSpaceKeyPressed)
        XCTAssertFalse(view.isRightKeyPressed)
    }
    
    func test_slideShowControlsView_keyboardFeedback_rightPressed() {
        let view = SlideShowControlsView(
            isSlideShowRunning: false,
            currentIndex: 1,
            totalCount: 5,
            isRightKeyPressed: true,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { }
        )
        
        XCTAssertFalse(view.isLeftKeyPressed)
        XCTAssertFalse(view.isSpaceKeyPressed)
        XCTAssertTrue(view.isRightKeyPressed)
    }
    
    func test_slideShowControlsView_keyboardFeedback_allPressed() {
        let view = SlideShowControlsView(
            isSlideShowRunning: true,
            currentIndex: 2,
            totalCount: 5,
            isLeftKeyPressed: true,
            isSpaceKeyPressed: true,
            isRightKeyPressed: true,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { }
        )
        
        XCTAssertTrue(view.isLeftKeyPressed)
        XCTAssertTrue(view.isSpaceKeyPressed)
        XCTAssertTrue(view.isRightKeyPressed)
    }
    
    func test_slideShowControlsView_edgeCases() {
        // Test at beginning (index 0)
        let beginningView = SlideShowControlsView(
            isSlideShowRunning: false,
            currentIndex: 0,
            totalCount: 5,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { }
        )
        XCTAssertNotNil(beginningView.body)
        
        // Test at end (last index)
        let endView = SlideShowControlsView(
            isSlideShowRunning: false,
            currentIndex: 4,
            totalCount: 5,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { }
        )
        XCTAssertNotNil(endView.body)
        
        // Test with single item
        let singleView = SlideShowControlsView(
            isSlideShowRunning: false,
            currentIndex: 0,
            totalCount: 1,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { }
        )
        XCTAssertNotNil(singleView.body)
    }
    
    func test_slideShowControlsView_progressCallback() {
        var tappedIndex: Int?
        
        let view = SlideShowControlsView(
            isSlideShowRunning: false,
            currentIndex: 2,
            totalCount: 10,
            onPrevious: { },
            onToggleSlideShow: { },
            onNext: { },
            onToggleRepeat: { },
            onProgressTapped: { index in tappedIndex = index }
        )
        
        XCTAssertNotNil(view.onProgressTapped)
        
        // Simulate progress tap
        view.onProgressTapped?(7)
        XCTAssertEqual(tappedIndex, 7)
    }
}