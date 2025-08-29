import XCTest
import SwiftUI
@testable import SwiftViewer

/// Tests for Plugin Performance Monitoring functionality
/// Unit 18: Performance Monitoring (1-2 hours)
/// Test: Plugin performance impact measurement
@MainActor
final class PluginPerformanceMonitoringTests: XCTestCase {
    
    fileprivate var sut: PluginPerformanceMonitor!
    fileprivate var mockPlugin: MockPerformancePlugin!
    
    override func setUp() async throws {
        try await super.setUp()
        mockPlugin = MockPerformancePlugin()
        sut = PluginPerformanceMonitor()
    }
    
    override func tearDown() async throws {
        sut = nil
        mockPlugin = nil
        try await super.tearDown()
    }
    
    // MARK: - Performance Metrics Collection Tests
    
    func testStartMetricsCollection_WithValidPlugin_ShouldStartTracking() {
        // Given valid plugin
        let pluginId = mockPlugin.metadata.id
        
        // When starting metrics collection
        sut.startMetricsCollection(for: pluginId)
        
        // Then should start tracking
        XCTAssertTrue(sut.isTrackingPlugin(pluginId))
        XCTAssertNotNil(sut.getMetrics(for: pluginId))
    }
    
    func testStopMetricsCollection_ShouldStopTracking() {
        // Given plugin being tracked
        let pluginId = mockPlugin.metadata.id
        sut.startMetricsCollection(for: pluginId)
        
        // When stopping metrics collection
        sut.stopMetricsCollection(for: pluginId)
        
        // Then should stop tracking
        XCTAssertFalse(sut.isTrackingPlugin(pluginId))
    }
    
    func testRecordExecutionTime_ShouldTrackPerformance() async throws {
        // Given plugin being tracked
        let pluginId = mockPlugin.metadata.id
        sut.startMetricsCollection(for: pluginId)
        
        // When recording execution time
        let executionTime = try await sut.measureExecutionTime(for: pluginId) {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return "test result"
        }
        
        // Then should record execution time
        XCTAssertGreaterThan(executionTime, 0.008) // Should be at least 8ms
        XCTAssertLessThan(executionTime, 0.050) // Should be less than 50ms
        
        let metrics = sut.getMetrics(for: pluginId)
        XCTAssertNotNil(metrics)
        XCTAssertEqual(metrics?.executionCount, 1)
        XCTAssertGreaterThan(metrics?.averageExecutionTime ?? 0, 0)
    }
    
    func testRecordMemoryUsage_ShouldTrackMemoryImpact() {
        // Given plugin being tracked
        let pluginId = mockPlugin.metadata.id
        sut.startMetricsCollection(for: pluginId)
        
        // When recording memory usage
        let initialMemory: UInt64 = 1024 * 1024 // 1MB
        let peakMemory: UInt64 = 2 * 1024 * 1024 // 2MB
        
        sut.recordMemoryUsage(for: pluginId, initial: initialMemory, peak: peakMemory)
        
        // Then should track memory impact
        let metrics = sut.getMetrics(for: pluginId)
        XCTAssertEqual(metrics?.peakMemoryUsage, peakMemory)
        XCTAssertEqual(metrics?.averageMemoryUsage, (initialMemory + peakMemory) / 2)
    }
    
    // MARK: - Performance Analysis Tests
    
    func testAnalyzePerformance_WithGoodPerformance_ShouldReturnGoodStatus() {
        // Given plugin with good performance metrics
        let pluginId = mockPlugin.metadata.id
        sut.startMetricsCollection(for: pluginId)
        
        // Record good performance
        sut.recordMemoryUsage(for: pluginId, initial: 512 * 1024, peak: 1024 * 1024) // 1MB peak
        sut.recordExecutionTime(for: pluginId, duration: 0.005) // 5ms
        
        // When analyzing performance
        let analysis = sut.analyzePerformance(for: pluginId)
        
        // Then should return good status
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis?.performanceStatus, .good)
        XCTAssertTrue(analysis?.warnings.isEmpty ?? false)
    }
    
    func testAnalyzePerformance_WithSlowPlugin_ShouldReturnWarning() {
        // Given plugin with slow performance
        let pluginId = mockPlugin.metadata.id
        sut.startMetricsCollection(for: pluginId)
        
        // Record slow performance
        sut.recordExecutionTime(for: pluginId, duration: 0.075) // 75ms - slow but not critical
        sut.recordMemoryUsage(for: pluginId, initial: 1024 * 1024, peak: 2 * 1024 * 1024)
        
        // When analyzing performance
        let analysis = sut.analyzePerformance(for: pluginId)
        
        // Then should return warning
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis?.performanceStatus, .warning)
        XCTAssertFalse(analysis?.warnings.isEmpty ?? true)
        XCTAssertTrue(analysis?.warnings.contains { $0.contains("execution time") } ?? false)
    }
    
    func testAnalyzePerformance_WithHighMemoryUsage_ShouldReturnCritical() {
        // Given plugin with high memory usage
        let pluginId = mockPlugin.metadata.id
        sut.startMetricsCollection(for: pluginId)
        
        // Record high memory usage
        let highMemory: UInt64 = 100 * 1024 * 1024 // 100MB - high
        sut.recordMemoryUsage(for: pluginId, initial: 10 * 1024 * 1024, peak: highMemory)
        sut.recordExecutionTime(for: pluginId, duration: 0.010)
        
        // When analyzing performance
        let analysis = sut.analyzePerformance(for: pluginId)
        
        // Then should return critical
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis?.performanceStatus, .critical)
        XCTAssertFalse(analysis?.warnings.isEmpty ?? true)
        XCTAssertTrue(analysis?.warnings.contains { $0.contains("memory") } ?? false)
    }
    
    // MARK: - Resource Monitoring Tests
    
    func testMonitorResourceUsage_ShouldTrackCPUAndMemory() async throws {
        // Given plugin being monitored
        let pluginId = mockPlugin.metadata.id
        sut.startMetricsCollection(for: pluginId)
        
        // When monitoring resource usage during operation
        let result: String = try await sut.monitorResourceUsage(for: pluginId) {
            // Simulate some work
            var data: [Int] = []
            for i in 0..<1000 {
                data.append(i * i)
            }
            return "work completed"
        }
        
        // Then should track resource usage
        XCTAssertEqual(result, "work completed")
        let metrics = sut.getMetrics(for: pluginId)
        XCTAssertNotNil(metrics)
        XCTAssertGreaterThan(metrics?.executionCount ?? 0, 0)
    }
    
    // MARK: - Performance Limits Tests
    
    func testCheckPerformanceLimits_WithinLimits_ShouldReturnTrue() {
        // Given plugin with performance within limits
        let pluginId = mockPlugin.metadata.id
        sut.startMetricsCollection(for: pluginId)
        
        // Record performance within limits
        sut.recordExecutionTime(for: pluginId, duration: 0.020) // 20ms - good
        sut.recordMemoryUsage(for: pluginId, initial: 1024 * 1024, peak: 2 * 1024 * 1024) // 2MB - good
        
        // When checking performance limits
        let withinLimits = sut.checkPerformanceLimits(for: pluginId)
        
        // Then should return true
        XCTAssertTrue(withinLimits)
    }
    
    func testCheckPerformanceLimits_ExceedsLimits_ShouldReturnFalse() {
        // Given plugin exceeding performance limits
        let pluginId = mockPlugin.metadata.id
        sut.startMetricsCollection(for: pluginId)
        
        // Record performance exceeding limits
        sut.recordExecutionTime(for: pluginId, duration: 1.0) // 1000ms - too slow
        sut.recordMemoryUsage(for: pluginId, initial: 50 * 1024 * 1024, peak: 200 * 1024 * 1024) // 200MB - too high
        
        // When checking performance limits
        let withinLimits = sut.checkPerformanceLimits(for: pluginId)
        
        // Then should return false
        XCTAssertFalse(withinLimits)
    }
    
    // MARK: - Performance Reports Tests
    
    func testGeneratePerformanceReport_ShouldProvideDetailedReport() {
        // Given multiple plugins with different performance
        let plugin1Id = "plugin.fast"
        let plugin2Id = "plugin.slow"
        
        sut.startMetricsCollection(for: plugin1Id)
        sut.startMetricsCollection(for: plugin2Id)
        
        // Record different performance metrics
        sut.recordExecutionTime(for: plugin1Id, duration: 0.005) // Fast
        sut.recordMemoryUsage(for: plugin1Id, initial: 512 * 1024, peak: 1024 * 1024)
        
        sut.recordExecutionTime(for: plugin2Id, duration: 0.075) // Slow but not critical
        sut.recordMemoryUsage(for: plugin2Id, initial: 10 * 1024 * 1024, peak: 50 * 1024 * 1024)
        
        // When generating performance report
        let report = sut.generatePerformanceReport()
        
        // Then should provide detailed report
        XCTAssertNotNil(report)
        XCTAssertEqual(report.totalPluginsMonitored, 2)
        XCTAssertEqual(report.pluginReports.count, 2)
        
        // Check fast plugin report
        let fastPluginReport = report.pluginReports.first { $0.pluginId == plugin1Id }
        XCTAssertNotNil(fastPluginReport)
        XCTAssertEqual(fastPluginReport?.performanceStatus, .good)
        
        // Check slow plugin report
        let slowPluginReport = report.pluginReports.first { $0.pluginId == plugin2Id }
        XCTAssertNotNil(slowPluginReport)
        XCTAssertEqual(slowPluginReport?.performanceStatus, .warning)
    }
    
    // MARK: - Error Handling Tests
    
    func testMeasureExecutionTime_WithError_ShouldPropagateError() async {
        // Given plugin being tracked
        let pluginId = mockPlugin.metadata.id
        sut.startMetricsCollection(for: pluginId)
        
        // When measuring execution time of failing operation
        do {
            _ = try await sut.measureExecutionTime(for: pluginId) {
                throw PluginPerformanceError.operationFailed
            }
            XCTFail("Expected error to be thrown")
        } catch PluginPerformanceError.operationFailed {
            // Then should propagate error and still record metrics
            let metrics = sut.getMetrics(for: pluginId)
            XCTAssertNotNil(metrics)
            // Error execution should not be counted in normal metrics
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Cleanup Tests
    
    func testClearMetrics_ShouldResetAllData() {
        // Given multiple plugins being tracked
        let plugin1Id = "plugin.1"
        let plugin2Id = "plugin.2"
        
        sut.startMetricsCollection(for: plugin1Id)
        sut.startMetricsCollection(for: plugin2Id)
        sut.recordExecutionTime(for: plugin1Id, duration: 0.010)
        sut.recordExecutionTime(for: plugin2Id, duration: 0.020)
        
        // When clearing metrics
        sut.clearAllMetrics()
        
        // Then should reset all data
        XCTAssertFalse(sut.isTrackingPlugin(plugin1Id))
        XCTAssertFalse(sut.isTrackingPlugin(plugin2Id))
        XCTAssertNil(sut.getMetrics(for: plugin1Id))
        XCTAssertNil(sut.getMetrics(for: plugin2Id))
    }
}

// MARK: - Mock Performance Plugin

fileprivate class MockPerformancePlugin: PluginProtocol {
    let metadata: PluginMetadata
    var isActive: Bool = false
    
    init(id: String = "test.performance.plugin") {
        self.metadata = PluginMetadata(
            id: id,
            name: "Test Performance Plugin",
            version: "1.0.0",
            author: "Test Author",
            description: "Test plugin for performance monitoring tests",
            capabilities: [.transitionEffect]
        )
    }
    
    func initialize() async throws {
        isActive = true
    }
    
    func cleanup() async {
        isActive = false
    }
}

// MARK: - Performance Error

fileprivate enum PluginPerformanceError: Error {
    case operationFailed
}