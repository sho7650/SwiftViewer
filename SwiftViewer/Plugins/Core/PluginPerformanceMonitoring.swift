import Foundation
import os

/// Performance status levels for plugin monitoring
public enum PluginPerformanceStatus {
    case good
    case warning
    case critical
}

/// Performance metrics for a plugin
public struct PluginPerformanceMetrics {
    public let pluginId: String
    public var executionCount: Int = 0
    public var totalExecutionTime: TimeInterval = 0
    public var averageExecutionTime: TimeInterval {
        executionCount > 0 ? totalExecutionTime / TimeInterval(executionCount) : 0
    }
    public var peakMemoryUsage: UInt64 = 0
    public var totalMemoryUsage: UInt64 = 0
    public var memoryReadings: Int = 0
    public var averageMemoryUsage: UInt64 {
        memoryReadings > 0 ? totalMemoryUsage / UInt64(memoryReadings) : 0
    }
    public var lastExecutionTime: Date?
    public var startTime: Date = Date()
    
    public init(pluginId: String) {
        self.pluginId = pluginId
    }
}

/// Performance analysis result for a plugin
public struct PluginPerformanceAnalysis {
    public let pluginId: String
    public let performanceStatus: PluginPerformanceStatus
    public let warnings: [String]
    public let recommendations: [String]
    public let metrics: PluginPerformanceMetrics
    
    public init(
        pluginId: String,
        performanceStatus: PluginPerformanceStatus,
        warnings: [String],
        recommendations: [String],
        metrics: PluginPerformanceMetrics
    ) {
        self.pluginId = pluginId
        self.performanceStatus = performanceStatus
        self.warnings = warnings
        self.recommendations = recommendations
        self.metrics = metrics
    }
}

/// Individual plugin report within performance report
public struct PluginPerformanceReport {
    public let pluginId: String
    public let performanceStatus: PluginPerformanceStatus
    public let metrics: PluginPerformanceMetrics
    public let analysis: PluginPerformanceAnalysis
    
    public init(
        pluginId: String,
        performanceStatus: PluginPerformanceStatus,
        metrics: PluginPerformanceMetrics,
        analysis: PluginPerformanceAnalysis
    ) {
        self.pluginId = pluginId
        self.performanceStatus = performanceStatus
        self.metrics = metrics
        self.analysis = analysis
    }
}

/// Overall performance report for all monitored plugins
public struct OverallPerformanceReport {
    public let totalPluginsMonitored: Int
    public let pluginReports: [PluginPerformanceReport]
    public let generatedAt: Date
    public let summary: String
    
    public init(
        totalPluginsMonitored: Int,
        pluginReports: [PluginPerformanceReport],
        generatedAt: Date = Date(),
        summary: String = ""
    ) {
        self.totalPluginsMonitored = totalPluginsMonitored
        self.pluginReports = pluginReports
        self.generatedAt = generatedAt
        self.summary = summary
    }
}

/// Monitors plugin performance and provides analysis
@MainActor
public final class PluginPerformanceMonitor {
    
    // MARK: - Properties
    
    private let logger: Logger
    private var metricsMap: [String: PluginPerformanceMetrics] = [:]
    private var trackingPlugins: Set<String> = []
    
    // Performance thresholds
    private let maxExecutionTime: TimeInterval = 0.100 // 100ms
    private let warningExecutionTime: TimeInterval = 0.050 // 50ms
    private let maxMemoryUsage: UInt64 = 50 * 1024 * 1024 // 50MB
    private let warningMemoryUsage: UInt64 = 20 * 1024 * 1024 // 20MB
    
    // MARK: - Initialization
    
    public init() {
        self.logger = Logger()
        logger.info("PluginPerformanceMonitor initialized")
    }
    
    // MARK: - Metrics Collection
    
    /// Start collecting performance metrics for a plugin
    /// - Parameter pluginId: ID of the plugin to monitor
    public func startMetricsCollection(for pluginId: String) {
        logger.debug("Starting metrics collection for plugin: \(pluginId)")
        
        trackingPlugins.insert(pluginId)
        if metricsMap[pluginId] == nil {
            metricsMap[pluginId] = PluginPerformanceMetrics(pluginId: pluginId)
        }
        
        logger.info("Started metrics collection for plugin: \(pluginId)")
    }
    
    /// Stop collecting performance metrics for a plugin
    /// - Parameter pluginId: ID of the plugin to stop monitoring
    public func stopMetricsCollection(for pluginId: String) {
        logger.debug("Stopping metrics collection for plugin: \(pluginId)")
        
        trackingPlugins.remove(pluginId)
        
        logger.info("Stopped metrics collection for plugin: \(pluginId)")
    }
    
    /// Check if a plugin is currently being tracked
    /// - Parameter pluginId: ID of the plugin to check
    /// - Returns: True if plugin is being tracked
    public func isTrackingPlugin(_ pluginId: String) -> Bool {
        return trackingPlugins.contains(pluginId)
    }
    
    /// Get current metrics for a plugin
    /// - Parameter pluginId: ID of the plugin
    /// - Returns: Current performance metrics, nil if not tracked
    public func getMetrics(for pluginId: String) -> PluginPerformanceMetrics? {
        return metricsMap[pluginId]
    }
    
    // MARK: - Performance Measurement
    
    /// Measure execution time of an operation for a plugin
    /// - Parameters:
    ///   - pluginId: ID of the plugin
    ///   - operation: Operation to measure
    /// - Returns: Result of the operation and execution time
    /// - Throws: Any error thrown by the operation
    public func measureExecutionTime<T>(
        for pluginId: String,
        operation: () async throws -> T
    ) async throws -> TimeInterval {
        let startTime = Date()
        
        do {
            _ = try await operation()
        } catch {
            // Don't record failed operations in normal metrics
            throw error
        }
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        recordExecutionTime(for: pluginId, duration: executionTime)
        
        return executionTime
    }
    
    /// Record execution time for a plugin
    /// - Parameters:
    ///   - pluginId: ID of the plugin
    ///   - duration: Execution duration in seconds
    public func recordExecutionTime(for pluginId: String, duration: TimeInterval) {
        guard var metrics = metricsMap[pluginId] else { return }
        
        metrics.executionCount += 1
        metrics.totalExecutionTime += duration
        metrics.lastExecutionTime = Date()
        
        metricsMap[pluginId] = metrics
        
        logger.debug("Recorded execution time for plugin \(pluginId): \(duration)s")
    }
    
    /// Record memory usage for a plugin
    /// - Parameters:
    ///   - pluginId: ID of the plugin
    ///   - initial: Initial memory usage in bytes
    ///   - peak: Peak memory usage in bytes
    public func recordMemoryUsage(for pluginId: String, initial: UInt64, peak: UInt64) {
        guard var metrics = metricsMap[pluginId] else { return }
        
        metrics.peakMemoryUsage = max(metrics.peakMemoryUsage, peak)
        metrics.totalMemoryUsage += (initial + peak) / 2 // Average of initial and peak
        metrics.memoryReadings += 1
        
        metricsMap[pluginId] = metrics
        
        logger.debug("Recorded memory usage for plugin \(pluginId): peak \(peak) bytes")
    }
    
    /// Monitor resource usage during operation execution
    /// - Parameters:
    ///   - pluginId: ID of the plugin
    ///   - operation: Operation to monitor
    /// - Returns: Result of the operation
    /// - Throws: Any error thrown by the operation
    public func monitorResourceUsage<T>(
        for pluginId: String,
        operation: () async throws -> T
    ) async throws -> T {
        let initialMemory = getCurrentMemoryUsage()
        let startTime = Date()
        
        let result = try await operation()
        
        let endTime = Date()
        let peakMemory = getCurrentMemoryUsage()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        recordExecutionTime(for: pluginId, duration: executionTime)
        recordMemoryUsage(for: pluginId, initial: initialMemory, peak: peakMemory)
        
        return result
    }
    
    // MARK: - Performance Analysis
    
    /// Analyze performance of a plugin
    /// - Parameter pluginId: ID of the plugin to analyze
    /// - Returns: Performance analysis result
    public func analyzePerformance(for pluginId: String) -> PluginPerformanceAnalysis? {
        guard let metrics = metricsMap[pluginId] else { return nil }
        
        var warnings: [String] = []
        var recommendations: [String] = []
        var status: PluginPerformanceStatus = .good
        
        // Analyze execution time
        if metrics.averageExecutionTime > maxExecutionTime {
            status = .critical
            warnings.append("Average execution time (\(String(format: "%.3f", metrics.averageExecutionTime))s) exceeds maximum threshold (\(String(format: "%.3f", maxExecutionTime))s)")
            recommendations.append("Optimize plugin code to reduce execution time")
        } else if metrics.averageExecutionTime > warningExecutionTime {
            if status == .good {
                status = .warning
            }
            warnings.append("Average execution time (\(String(format: "%.3f", metrics.averageExecutionTime))s) exceeds warning threshold (\(String(format: "%.3f", warningExecutionTime))s)")
            recommendations.append("Consider optimizing plugin performance")
        }
        
        // Analyze memory usage
        if metrics.peakMemoryUsage > maxMemoryUsage {
            status = .critical
            warnings.append("Peak memory usage (\(formatBytes(metrics.peakMemoryUsage))) exceeds maximum threshold (\(formatBytes(maxMemoryUsage)))")
            recommendations.append("Reduce memory usage or implement memory optimization")
        } else if metrics.averageMemoryUsage > warningMemoryUsage {
            if status == .good {
                status = .warning
            }
            warnings.append("Average memory usage (\(formatBytes(metrics.averageMemoryUsage))) exceeds warning threshold (\(formatBytes(warningMemoryUsage)))")
            recommendations.append("Monitor memory usage and consider optimization")
        }
        
        return PluginPerformanceAnalysis(
            pluginId: pluginId,
            performanceStatus: status,
            warnings: warnings,
            recommendations: recommendations,
            metrics: metrics
        )
    }
    
    /// Check if plugin performance is within acceptable limits
    /// - Parameter pluginId: ID of the plugin to check
    /// - Returns: True if within limits, false otherwise
    public func checkPerformanceLimits(for pluginId: String) -> Bool {
        guard let analysis = analyzePerformance(for: pluginId) else { return false }
        return analysis.performanceStatus != .critical
    }
    
    // MARK: - Reporting
    
    /// Generate comprehensive performance report for all monitored plugins
    /// - Returns: Overall performance report
    public func generatePerformanceReport() -> OverallPerformanceReport {
        var pluginReports: [PluginPerformanceReport] = []
        
        for (pluginId, metrics) in metricsMap {
            guard let analysis = analyzePerformance(for: pluginId) else { continue }
            
            let report = PluginPerformanceReport(
                pluginId: pluginId,
                performanceStatus: analysis.performanceStatus,
                metrics: metrics,
                analysis: analysis
            )
            pluginReports.append(report)
        }
        
        // Generate summary
        let goodCount = pluginReports.filter { $0.performanceStatus == .good }.count
        let warningCount = pluginReports.filter { $0.performanceStatus == .warning }.count
        let criticalCount = pluginReports.filter { $0.performanceStatus == .critical }.count
        
        let summary = "Performance Summary: \(goodCount) good, \(warningCount) warning, \(criticalCount) critical"
        
        return OverallPerformanceReport(
            totalPluginsMonitored: metricsMap.count,
            pluginReports: pluginReports,
            summary: summary
        )
    }
    
    // MARK: - Cleanup
    
    /// Clear all performance metrics and stop all tracking
    public func clearAllMetrics() {
        logger.debug("Clearing all performance metrics")
        
        trackingPlugins.removeAll()
        metricsMap.removeAll()
        
        logger.info("All performance metrics cleared")
    }
    
    // MARK: - Private Methods
    
    private func getCurrentMemoryUsage() -> UInt64 {
        // Simplified memory usage calculation
        // In a real implementation, this would get actual memory usage
        return UInt64(MemoryLayout<Int>.size * 1024) // Placeholder value
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Extensions

extension PluginPerformanceStatus: Comparable {
    public static func < (lhs: PluginPerformanceStatus, rhs: PluginPerformanceStatus) -> Bool {
        switch (lhs, rhs) {
        case (.good, .warning), (.good, .critical), (.warning, .critical):
            return true
        default:
            return false
        }
    }
}

// Helper function for max comparison
private func max(_ lhs: PluginPerformanceStatus, _ rhs: PluginPerformanceStatus) -> PluginPerformanceStatus {
    return lhs < rhs ? rhs : lhs
}