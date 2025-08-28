import Foundation
import os

/// Errors specific to plugin execution context operations
public enum PluginExecutionError: Error, LocalizedError {
    case memoryLimitExceeded(limit: UInt64)
    case cpuTimeLimitExceeded(limit: TimeInterval)
    case diskIOLimitExceeded(limit: UInt64)
    case contextNotAvailable
    case resourceMonitoringFailed
    
    public var errorDescription: String? {
        switch self {
        case .memoryLimitExceeded(let limit):
            return "Plugin exceeded memory limit of \(limit) MB"
        case .cpuTimeLimitExceeded(let limit):
            return "Plugin exceeded CPU time limit of \(limit) seconds"
        case .diskIOLimitExceeded(let limit):
            return "Plugin exceeded disk I/O limit of \(limit) MB"
        case .contextNotAvailable:
            return "Plugin execution context is not available"
        case .resourceMonitoringFailed:
            return "Failed to monitor plugin resource usage"
        }
    }
}

/// Tracks resource usage metrics for plugin execution
public struct ResourceMetrics {
    public let peakMemoryUsageMB: UInt64
    public let executionTimeSeconds: TimeInterval
    public let diskIOUsageMB: UInt64
    public let startTime: Date
    public let endTime: Date?
    
    public init(
        peakMemoryUsageMB: UInt64 = 0,
        executionTimeSeconds: TimeInterval = 0,
        diskIOUsageMB: UInt64 = 0,
        startTime: Date = Date(),
        endTime: Date? = nil
    ) {
        self.peakMemoryUsageMB = peakMemoryUsageMB
        self.executionTimeSeconds = executionTimeSeconds
        self.diskIOUsageMB = diskIOUsageMB
        self.startTime = startTime
        self.endTime = endTime
    }
}

/// Represents the current status of the execution context
public enum ContextStatus {
    case idle
    case executing(pluginId: String)
    case resourceLimited
    case error(Error)
}

/// Manages isolated execution environment for plugins with resource limits and monitoring
@MainActor
public final class PluginExecutionContext {
    
    // MARK: - Public Properties
    
    public let memoryLimitMB: UInt64
    public let cpuTimeLimit: TimeInterval
    public let diskIOLimitMB: UInt64
    
    public private(set) var status: ContextStatus = .idle
    
    // MARK: - Default Limits
    
    public static let defaultMemoryLimitMB: UInt64 = 256
    public static let defaultCPUTimeLimit: TimeInterval = 30.0
    public static let defaultDiskIOLimitMB: UInt64 = 100
    
    // MARK: - Private Properties
    
    private let logger: Logger
    private var resourceMetrics: ResourceMetrics
    private let resourceMonitorQueue = DispatchQueue(label: "com.swiftviewer.plugins.resource-monitor", qos: .utility)
    private var resourceMonitorTimer: Timer?
    private var executionStartTime: Date?
    private var currentMemoryUsage: UInt64 = 0
    
    // MARK: - Initialization
    
    public init(
        memoryLimitMB: UInt64,
        cpuTimeLimit: TimeInterval,
        diskIOLimitMB: UInt64
    ) {
        // Use defaults if zero values provided
        self.memoryLimitMB = memoryLimitMB > 0 ? memoryLimitMB : Self.defaultMemoryLimitMB
        self.cpuTimeLimit = cpuTimeLimit > 0 ? cpuTimeLimit : Self.defaultCPUTimeLimit
        self.diskIOLimitMB = diskIOLimitMB > 0 ? diskIOLimitMB : Self.defaultDiskIOLimitMB
        
        self.resourceMetrics = ResourceMetrics()
        self.logger = Logger()
        
        logger.info("PluginExecutionContext initialized with limits: memory=\(self.memoryLimitMB)MB, cpu=\(self.cpuTimeLimit)s, diskIO=\(self.diskIOLimitMB)MB")
    }
    
    // MARK: - Public Methods
    
    /// Execute a plugin operation within the controlled context
    /// - Parameters:
    ///   - plugin: The plugin to execute
    ///   - operation: The operation to perform
    /// - Returns: The result of the operation
    /// - Throws: PluginExecutionError if resource limits are exceeded or execution fails
    public func execute<T>(
        plugin: PluginProtocol,
        operation: @escaping (PluginProtocol) async throws -> T
    ) async throws -> T {
        let pluginId = plugin.metadata.id
        
        // Check if context is available
        guard case .idle = status else {
            throw PluginExecutionError.contextNotAvailable
        }
        
        // Set executing status
        status = .executing(pluginId: pluginId)
        executionStartTime = Date()
        
        logger.info("Starting execution of plugin: \(pluginId)")
        
        do {
            // Start resource monitoring
            try await startResourceMonitoring(for: pluginId)
            
            // Execute the operation with timeout
            let result = try await withThrowingTaskGroup(of: T.self) { group in
                // Add the main operation task
                group.addTask {
                    try await operation(plugin)
                }
                
                // Add timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(self.cpuTimeLimit * 1_000_000_000))
                    throw PluginExecutionError.cpuTimeLimitExceeded(limit: self.cpuTimeLimit)
                }
                
                // Wait for the first task to complete
                guard let result = try await group.next() else {
                    throw PluginExecutionError.resourceMonitoringFailed
                }
                
                // Cancel the other task
                group.cancelAll()
                return result
            }
            
            // Stop resource monitoring and finalize metrics
            await stopResourceMonitoring()
            
            logger.info("Plugin execution completed successfully: \(pluginId)")
            status = .idle
            return result
            
        } catch let error as PluginExecutionError {
            await handleExecutionError(error, pluginId: pluginId)
            throw error
        } catch {
            let wrappedError = PluginError.executionFailed(reason: error.localizedDescription)
            await handleExecutionError(wrappedError, pluginId: pluginId)
            throw wrappedError
        }
    }
    
    /// Get current resource usage metrics
    public func getResourceMetrics() -> ResourceMetrics {
        let currentTime = Date()
        let executionTime = executionStartTime?.timeIntervalSince(currentTime) ?? resourceMetrics.executionTimeSeconds
        
        return ResourceMetrics(
            peakMemoryUsageMB: max(resourceMetrics.peakMemoryUsageMB, currentMemoryUsage),
            executionTimeSeconds: abs(executionTime),
            diskIOUsageMB: resourceMetrics.diskIOUsageMB,
            startTime: resourceMetrics.startTime,
            endTime: currentTime
        )
    }
    
    /// Reset the execution context to idle state
    public func reset() {
        status = .idle
        executionStartTime = nil
        currentMemoryUsage = 0
        resourceMetrics = ResourceMetrics()
        resourceMonitorTimer?.invalidate()
        resourceMonitorTimer = nil
        
        logger.info("PluginExecutionContext reset to idle state")
    }
    
    // MARK: - Private Methods
    
    private func startResourceMonitoring(for pluginId: String) async throws {
        logger.debug("Starting resource monitoring for plugin: \(pluginId)")
        
        // Create a timer to periodically check resource usage
        resourceMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                await self.checkResourceUsage()
            }
        }
    }
    
    private func stopResourceMonitoring() async {
        logger.debug("Stopping resource monitoring")
        
        resourceMonitorTimer?.invalidate()
        resourceMonitorTimer = nil
        
        // Final resource check
        await updateResourceMetrics()
    }
    
    private func checkResourceUsage() async {
        await updateResourceMetrics()
        
        // Check memory limit
        if currentMemoryUsage > memoryLimitMB {
            let error = PluginExecutionError.memoryLimitExceeded(limit: memoryLimitMB)
            await handleExecutionError(error, pluginId: getCurrentPluginId())
            return
        }
        
        // CPU time limit is handled by the timeout mechanism in execute()
        
        // Disk I/O limit would be checked here if we were tracking actual file operations
        // For now, we simulate this check
        if resourceMetrics.diskIOUsageMB > diskIOLimitMB {
            let error = PluginExecutionError.diskIOLimitExceeded(limit: diskIOLimitMB)
            await handleExecutionError(error, pluginId: getCurrentPluginId())
            return
        }
    }
    
    private func updateResourceMetrics() async {
        // Get current memory usage (simplified simulation)
        let currentMemory = getCurrentMemoryUsage()
        currentMemoryUsage = max(currentMemoryUsage, currentMemory)
        
        // Update peak memory usage
        resourceMetrics = ResourceMetrics(
            peakMemoryUsageMB: max(resourceMetrics.peakMemoryUsageMB, currentMemory),
            executionTimeSeconds: executionStartTime?.timeIntervalSinceNow ?? 0,
            diskIOUsageMB: resourceMetrics.diskIOUsageMB,
            startTime: resourceMetrics.startTime,
            endTime: nil
        )
    }
    
    private func getCurrentMemoryUsage() -> UInt64 {
        // Simplified memory usage calculation
        // In a real implementation, this would query actual memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return 0
        }
        
        return UInt64(info.resident_size) / (1024 * 1024) // Convert to MB
    }
    
    private func getCurrentPluginId() -> String {
        switch status {
        case .executing(let pluginId):
            return pluginId
        default:
            return "unknown"
        }
    }
    
    private func handleExecutionError(_ error: Error, pluginId: String) async {
        logger.error("Plugin execution error for \(pluginId): \(error.localizedDescription)")
        
        // Stop resource monitoring
        await stopResourceMonitoring()
        
        // Update status
        status = .error(error)
        
        // Clean up resources
        currentMemoryUsage = 0
        executionStartTime = nil
    }
}

// MARK: - Extensions for Testing

extension PluginExecutionContext {
    /// Test helper to simulate memory pressure
    internal func simulateMemoryPressure(_ memoryMB: UInt64) {
        currentMemoryUsage = memoryMB
    }
    
    /// Test helper to get current status
    internal var currentStatus: ContextStatus {
        return status
    }
}