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

        // Use minimum valid interval (1.0 second)
        let result = sut.startTimer(interval: 1.0) {
            callCount += 1
            if callCount == 2 {
                expectation.fulfill()
            }
        }

        XCTAssertTrue(result.isSuccess, "Timer should start successfully with valid interval")
        wait(for: [expectation], timeout: 2.5)
        XCTAssertGreaterThanOrEqual(callCount, 2)
    }

    func test_startTimer_respectsSpecifiedInterval() {
        let expectation = XCTestExpectation(description: "Timer respects interval")
        var firstCall: Date?

        // Use minimum valid interval (1.0 second)
        let result = sut.startTimer(interval: 1.0) {
            if firstCall == nil {
                firstCall = Date()
            } else {
                let elapsed = Date().timeIntervalSince(firstCall!)
                // Allow tolerance for 1.0 second interval
                XCTAssertGreaterThan(elapsed, 0.8)
                XCTAssertLessThan(elapsed, 1.3)
                expectation.fulfill()
            }
        }

        XCTAssertTrue(result.isSuccess)
        wait(for: [expectation], timeout: 2.5)
    }

    func test_startTimer_replacesExistingTimer() {
        let expectation = XCTestExpectation(description: "Old timer replaced")
        var firstTimerCalled = false
        var secondTimerCalled = false

        // Start first timer with long interval (should be replaced before firing)
        let result1 = sut.startTimer(interval: 5.0) {
            firstTimerCalled = true
        }

        // Verify first timer is running
        XCTAssertTrue(result1.isSuccess)
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.currentInterval, 5.0)

        // Immediately start second timer with shorter interval to replace the first
        let result2 = sut.startTimer(interval: 1.0) {
            secondTimerCalled = true
            expectation.fulfill()
        }

        // Verify second timer replaced the first
        XCTAssertTrue(result2.isSuccess)
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.currentInterval, 1.0)

        wait(for: [expectation], timeout: 1.5)

        // First timer should not have fired (was replaced)
        // Second timer should have fired at least once
        XCTAssertFalse(firstTimerCalled, "First timer should not have fired - it was replaced")
        XCTAssertTrue(secondTimerCalled, "Second timer should have fired")
    }

    // MARK: - Timer Stop Tests

    func test_stopTimer_stopsRunningTimer() {
        let expectation = XCTestExpectation(description: "Timer fires at least once")
        var callCount = 0

        let result = sut.startTimer(interval: 1.0) {
            callCount += 1
            expectation.fulfill()
        }

        XCTAssertTrue(result.isSuccess)

        // Wait for timer to fire at least once
        wait(for: [expectation], timeout: 1.5)

        sut.stopTimer()
        let callCountAfterStop = callCount

        // Wait a bit more and ensure no more calls
        Thread.sleep(forTimeInterval: 1.5)

        XCTAssertEqual(callCount, callCountAfterStop)
    }

    func test_stopTimer_canBeCalledWhenNotRunning() {
        XCTAssertNoThrow(sut.stopTimer())

        let result = sut.startTimer(interval: 1.0) { }
        XCTAssertTrue(result.isSuccess)
        sut.stopTimer()

        XCTAssertNoThrow(sut.stopTimer()) // Should not throw
    }

    // MARK: - State Tests

    func test_isRunning_returnsCorrectState() {
        XCTAssertFalse(sut.isRunning)

        let result = sut.startTimer(interval: 1.0) { }
        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(sut.isRunning)

        sut.stopTimer()
        XCTAssertFalse(sut.isRunning)
    }

    func test_currentInterval_returnsCorrectValue() {
        XCTAssertNil(sut.currentInterval)

        let result = sut.startTimer(interval: 2.5) { }
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(sut.currentInterval, 2.5)

        sut.stopTimer()
        XCTAssertNil(sut.currentInterval)
    }

    // MARK: - Error Handling Tests

    func test_startTimer_handlesZeroInterval() {
        let expectation = XCTestExpectation(description: "Zero interval handled")
        expectation.isInverted = true // Should NOT be called

        let result = sut.startTimer(interval: 0) {
            expectation.fulfill()
        }

        XCTAssertFalse(result.isSuccess, "Zero interval should fail validation")
        wait(for: [expectation], timeout: 0.1)
        XCTAssertFalse(sut.isRunning)
    }

    func test_startTimer_handlesNegativeInterval() {
        let expectation = XCTestExpectation(description: "Negative interval handled")
        expectation.isInverted = true // Should NOT be called

        let result = sut.startTimer(interval: -1.0) {
            expectation.fulfill()
        }

        XCTAssertFalse(result.isSuccess, "Negative interval should fail validation")
        wait(for: [expectation], timeout: 0.1)
        XCTAssertFalse(sut.isRunning)
    }

    func test_startTimer_handlesTooSmallInterval() {
        let result = sut.startTimer(interval: 0.5) { }

        XCTAssertFalse(result.isSuccess, "Interval below 1.0 should fail validation")
        XCTAssertFalse(sut.isRunning)

        if case .failure(let error) = result {
            XCTAssertEqual(error, .invalidInterval(0.5))
        }
    }

    func test_startTimer_handlesTooLargeInterval() {
        let result = sut.startTimer(interval: 2000.0) { }

        XCTAssertFalse(result.isSuccess, "Interval above 1800 should fail validation")
        XCTAssertFalse(sut.isRunning)

        if case .failure(let error) = result {
            XCTAssertEqual(error, .invalidInterval(2000.0))
        }
    }

    func test_startTimer_acceptsValidIntervalRange() {
        // Test minimum valid interval
        let result1 = sut.startTimer(interval: 1.0) { }
        XCTAssertTrue(result1.isSuccess, "1.0 second interval should be valid")
        sut.stopTimer()

        // Test maximum valid interval
        let result2 = sut.startTimer(interval: 1800.0) { }
        XCTAssertTrue(result2.isSuccess, "1800 second interval should be valid")
        sut.stopTimer()

        // Test middle value
        let result3 = sut.startTimer(interval: 60.0) { }
        XCTAssertTrue(result3.isSuccess, "60 second interval should be valid")
    }

    // MARK: - Memory Management Tests

    func test_deinit_stopsTimer() {
        var callCount = 0
        var service: SlideShowService? = SlideShowService()

        let result = service?.startTimer(interval: 1.0) {
            callCount += 1
        }

        // Verify timer started successfully
        XCTAssertTrue(result?.isSuccess == true)
        XCTAssertTrue(service?.isRunning == true)

        // Release service
        service = nil

        // Wait for a potential timer fire and verify timer stopped
        Thread.sleep(forTimeInterval: 1.5)
        let finalCallCount = callCount
        Thread.sleep(forTimeInterval: 1.5)

        // Should not have increased after deallocation
        XCTAssertEqual(callCount, finalCallCount)
    }

    // MARK: - Thread Safety Tests

    func test_startTimer_isThreadSafe() {
        let expectation = XCTestExpectation(description: "Thread safe timer start")
        expectation.expectedFulfillmentCount = 1 // Only one timer should be active

        // Use MainActor.run to properly handle @MainActor isolation
        Task { @MainActor in
            let result = self.sut.startTimer(interval: 1.0) {
                expectation.fulfill()
            }
            XCTAssertTrue(result.isSuccess)
        }

        // The second task will replace the first timer
        Task { @MainActor in
            // Small delay to ensure first timer was set
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            let result = self.sut.startTimer(interval: 1.0) {
                expectation.fulfill()
            }
            XCTAssertTrue(result.isSuccess)
        }

        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - Result Extension for Tests

private extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
