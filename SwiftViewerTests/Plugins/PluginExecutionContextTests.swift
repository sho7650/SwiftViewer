import XCTest
import Foundation
@testable import SwiftViewer

/// Tests for Plugin Execution Context functionality
/// Unit 13: Plugin Execution Context (3-4 hours)
/// Test: Context isolation and resource management
@MainActor
final class PluginExecutionContextTests: XCTestCase {
    
    fileprivate var sut: PluginExecutionContext!
    fileprivate var mockPlugin: MockPlugin!
    
    override func setUp() async throws {
        try await super.setUp()
        mockPlugin = MockPlugin()
        sut = PluginExecutionContext(
            memoryLimitMB: 50,
            cpuTimeLimit: 5.0,
            diskIOLimitMB: 10
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockPlugin = nil
        try await super.tearDown()
    }
    
    // MARK: - Context Creation Tests
    
    func testContextCreation_WithValidLimits_ShouldCreateContext() {
        // Given valid resource limits
        let memoryLimit: UInt64 = 100
        let cpuLimit: TimeInterval = 10.0
        let diskLimit: UInt64 = 20
        
        // When creating context
        let context = PluginExecutionContext(
            memoryLimitMB: memoryLimit,
            cpuTimeLimit: cpuLimit,
            diskIOLimitMB: diskLimit
        )
        
        // Then context should be created with correct limits
        XCTAssertEqual(context.memoryLimitMB, memoryLimit)
        XCTAssertEqual(context.cpuTimeLimit, cpuLimit)
        XCTAssertEqual(context.diskIOLimitMB, diskLimit)
        XCTAssertEqual(context.status, .idle)
    }
    
    func testContextCreation_WithZeroLimits_ShouldUseDefaults() {
        // Given zero limits
        let context = PluginExecutionContext(
            memoryLimitMB: 0,
            cpuTimeLimit: 0,
            diskIOLimitMB: 0
        )
        
        // Then should use default limits
        XCTAssertEqual(context.memoryLimitMB, PluginExecutionContext.defaultMemoryLimitMB)
        XCTAssertEqual(context.cpuTimeLimit, PluginExecutionContext.defaultCPUTimeLimit)
        XCTAssertEqual(context.diskIOLimitMB, PluginExecutionContext.defaultDiskIOLimitMB)
    }
    
    // MARK: - Context Isolation Tests
    
    func testExecuteInContext_WithValidPlugin_ShouldIsolateExecution() async throws {
        // Given a mock plugin
        mockPlugin.executeBlock = {
            // Simulate some work
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            return "test result"
        }
        
        // When executing plugin in context
        let result = try await sut.execute(plugin: mockPlugin) { plugin in
            guard let mockPlugin = plugin as? MockPlugin else {
                throw PluginError.executionFailed(reason: "Wrong plugin type")
            }
            return try await mockPlugin.performWork()
        }
        
        // Then execution should complete successfully
        XCTAssertEqual(result, "test result")
        XCTAssertEqual(sut.status, .idle)
    }
    
    // MARK: - Resource Monitoring Tests
    
    func testExecuteInContext_TracksResourceUsage_ShouldRecordMetrics() async throws {
        // Given a plugin that uses some resources
        mockPlugin.executeBlock = {
            // Simulate some work
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            return "completed"
        }
        
        // When executing plugin
        _ = try await sut.execute(plugin: mockPlugin) { plugin in
            guard let mockPlugin = plugin as? MockPlugin else {
                throw PluginError.executionFailed(reason: "Wrong plugin type")
            }
            return try await mockPlugin.performWork()
        }
        
        // Then resource usage should be tracked
        let metrics = sut.getResourceMetrics()
        XCTAssertGreaterThanOrEqual(metrics.peakMemoryUsageMB, 0)
        XCTAssertGreaterThan(metrics.executionTimeSeconds, 0)
        XCTAssertLessThan(metrics.executionTimeSeconds, 1.0)
    }
    
    // MARK: - Error Recovery Tests
    
    func testExecuteInContext_PluginThrowsError_ShouldCleanupAndPropagate() async {
        // Given a plugin that throws an error
        mockPlugin.executeBlock = {
            throw PluginError.initializationFailed(reason: "test error")
        }
        
        // When executing plugin
        do {
            _ = try await sut.execute(plugin: mockPlugin) { plugin in
                guard let mockPlugin = plugin as? MockPlugin else {
                    throw PluginError.executionFailed(reason: "Wrong plugin type")
                }
                return try await mockPlugin.performWork()
            }
            XCTFail("Expected plugin error")
        } catch let error as PluginError {
            // Then should propagate error and cleanup context
            XCTAssertTrue(error.localizedDescription.contains("test error"))
            // Context should be in error state, not idle
            switch sut.status {
            case .error:
                break // This is expected
            default:
                XCTFail("Expected error status, got \(sut.status)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Memory Limit Tests
    
    func testMemoryLimit_CanBeSet_AndRetrieved() {
        // Given a context with specific memory limit
        let context = PluginExecutionContext(
            memoryLimitMB: 100,
            cpuTimeLimit: 10.0,
            diskIOLimitMB: 20
        )
        
        // Then memory limit should be accessible
        XCTAssertEqual(context.memoryLimitMB, 100)
    }
    
    // MARK: - Context Reset Tests
    
    func testContextReset_ShouldReturnToIdleState() {
        // Given a context that might be in any state
        sut.simulateMemoryPressure(50)
        
        // When resetting context
        sut.reset()
        
        // Then should be idle
        XCTAssertEqual(sut.status, .idle)
    }
}

// MARK: - Mock Plugin for Testing

fileprivate class MockPlugin: PluginProtocol {
    let metadata: PluginMetadata
    var isActive: Bool = false
    var executeBlock: (() async throws -> String)?
    
    init(id: String = "test.plugin") {
        self.metadata = PluginMetadata(
            id: id,
            name: "Test Plugin",
            version: "1.0.0",
            author: "Test Author",
            description: "Test plugin for execution context tests",
            capabilities: [.transitionEffect]
        )
    }
    
    func initialize() async throws {
        isActive = true
    }
    
    func cleanup() async {
        isActive = false
    }
    
    func performWork() async throws -> String {
        guard let block = executeBlock else {
            return "default result"
        }
        return try await block()
    }
}

// MARK: - Extensions for Testing

extension ContextStatus: Equatable {
    public static func == (lhs: ContextStatus, rhs: ContextStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.executing(let id1), .executing(let id2)):
            return id1 == id2
        case (.resourceLimited, .resourceLimited):
            return true
        case (.error(let e1), .error(let e2)):
            return e1.localizedDescription == e2.localizedDescription
        default:
            return false
        }
    }
}