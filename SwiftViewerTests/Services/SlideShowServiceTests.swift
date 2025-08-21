//
//  SlideShowServiceTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
@testable import SwiftViewer

@MainActor
final class SlideShowServiceTests: XCTestCase {
    
    var sut: SlideShowService!
    
    override func setUp() {
        super.setUp()
        sut = SlideShowService()
    }
    
    override func tearDown() {
        sut.stopTimer()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Timer Start Tests
    
    func test_startTimer_callsActionAtSpecifiedInterval() {
        let expectation = XCTestExpectation(description: "Timer action called")
        var callCount = 0
        
        sut.startTimer(interval: 0.1) {
            callCount += 1
            if callCount == 2 {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.5)
        XCTAssertGreaterThanOrEqual(callCount, 2)
    }
    
    func test_startTimer_respectsSpecifiedInterval() {
        let expectation = XCTestExpectation(description: "Timer respects interval")
        let startTime = Date()
        var firstCall: Date?
        
        sut.startTimer(interval: 0.2) {
            if firstCall == nil {
                firstCall = Date()
            } else {
                let elapsed = Date().timeIntervalSince(firstCall!)
                XCTAssertGreaterThan(elapsed, 0.15) // Allow some tolerance
                XCTAssertLessThan(elapsed, 0.25)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_startTimer_replacesExistingTimer() {
        let expectation = XCTestExpectation(description: "Old timer replaced")
        var firstTimerCalled = false
        var secondTimerCalled = false
        
        // Start first timer with long interval (should be replaced before firing)
        sut.startTimer(interval: 1.0) {
            firstTimerCalled = true
        }
        
        // Verify first timer is running
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.currentInterval, 1.0)
        
        // Immediately start second timer with short interval to replace the first
        sut.startTimer(interval: 0.1) {
            secondTimerCalled = true
            expectation.fulfill()
        }
        
        // Verify second timer replaced the first
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.currentInterval, 0.1)
        
        wait(for: [expectation], timeout: 0.5)
        
        // First timer should not have fired (was replaced)
        // Second timer should have fired at least once
        XCTAssertFalse(firstTimerCalled, "First timer should not have fired - it was replaced")
        XCTAssertTrue(secondTimerCalled, "Second timer should have fired")
    }
    
    // MARK: - Timer Stop Tests
    
    func test_stopTimer_stopsRunningTimer() {
        var callCount = 0
        
        sut.startTimer(interval: 0.1) {
            callCount += 1
        }
        
        // Let it run briefly
        Thread.sleep(forTimeInterval: 0.15)
        
        sut.stopTimer()
        let callCountAfterStop = callCount
        
        // Wait a bit more and ensure no more calls
        Thread.sleep(forTimeInterval: 0.2)
        
        XCTAssertEqual(callCount, callCountAfterStop)
    }
    
    func test_stopTimer_canBeCalledWhenNotRunning() {
        XCTAssertNoThrow(sut.stopTimer())
        
        sut.startTimer(interval: 0.1) { }
        sut.stopTimer()
        
        XCTAssertNoThrow(sut.stopTimer()) // Should not throw
    }
    
    // MARK: - State Tests
    
    func test_isRunning_returnsCorrectState() {
        XCTAssertFalse(sut.isRunning)
        
        sut.startTimer(interval: 0.1) { }
        XCTAssertTrue(sut.isRunning)
        
        sut.stopTimer()
        XCTAssertFalse(sut.isRunning)
    }
    
    func test_currentInterval_returnsCorrectValue() {
        XCTAssertNil(sut.currentInterval)
        
        sut.startTimer(interval: 2.5) { }
        XCTAssertEqual(sut.currentInterval, 2.5)
        
        sut.stopTimer()
        XCTAssertNil(sut.currentInterval)
    }
    
    // MARK: - Error Handling Tests
    
    func test_startTimer_handlesZeroInterval() {
        let expectation = XCTestExpectation(description: "Zero interval handled")
        expectation.isInverted = true // Should NOT be called
        
        sut.startTimer(interval: 0) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertFalse(sut.isRunning)
    }
    
    func test_startTimer_handlesNegativeInterval() {
        let expectation = XCTestExpectation(description: "Negative interval handled")
        expectation.isInverted = true // Should NOT be called
        
        sut.startTimer(interval: -1.0) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertFalse(sut.isRunning)
    }
    
    // MARK: - Memory Management Tests
    
    func test_deinit_stopsTimer() {
        var callCount = 0
        var service: SlideShowService? = SlideShowService()
        
        service?.startTimer(interval: 0.1) {
            callCount += 1
        }
        
        // Verify timer is running
        XCTAssertTrue(service?.isRunning == true)
        
        // Release service
        service = nil
        
        // Wait and verify timer stopped
        Thread.sleep(forTimeInterval: 0.2)
        let finalCallCount = callCount
        Thread.sleep(forTimeInterval: 0.2)
        
        // Should not have increased after deallocation
        XCTAssertEqual(callCount, finalCallCount)
    }
    
    // MARK: - Thread Safety Tests
    
    func test_startTimer_isThreadSafe() {
        let expectation = XCTestExpectation(description: "Thread safe timer start")
        expectation.expectedFulfillmentCount = 2
        
        // Use MainActor.run to properly handle @MainActor isolation
        Task { @MainActor in
            self.sut.startTimer(interval: 0.1) {
                expectation.fulfill()
            }
        }
        
        Task { @MainActor in
            self.sut.startTimer(interval: 0.1) {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}