import Foundation
import CoreGraphics
import ImageIO
import os

/// Supported image formats for plugin processing
public enum ImageFormat: String, CaseIterable, Codable {
    case jpeg = "jpeg"
    case heic = "heic"
    case gif = "gif"
    case raw = "raw" // Future support
    
    public var utType: String {
        switch self {
        case .jpeg:
            return "public.jpeg"
        case .heic:
            return "public.heic"
        case .gif:
            return "public.gif"
        case .raw:
            return "public.camera-raw-image"
        }
    }
    
    public var fileExtensions: [String] {
        switch self {
        case .jpeg:
            return ["jpg", "jpeg"]
        case .heic:
            return ["heic", "heif"]
        case .gif:
            return ["gif"]
        case .raw:
            return ["raw", "cr2", "nef", "arw"]
        }
    }
}

/// Errors specific to image processing operations
public enum ImageProcessingError: Error, LocalizedError {
    case unsupportedFormat(ImageFormat)
    case invalidImageData
    case pluginProcessingFailed(reason: String)
    case memoryLimitExceeded(limit: UInt64)
    case formatValidationFailed
    case processingTimeout
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "Unsupported image format: \(format.rawValue)"
        case .invalidImageData:
            return "Invalid or corrupted image data"
        case .pluginProcessingFailed(let reason):
            return "Plugin processing failed: \(reason)"
        case .memoryLimitExceeded(let limit):
            return "Memory limit exceeded: \(limit) bytes"
        case .formatValidationFailed:
            return "Image format validation failed"
        case .processingTimeout:
            return "Image processing operation timed out"
        }
    }
}

/// Result of image processing operation
public struct ProcessedImageResult {
    public let originalData: Data
    public let processedData: Data
    public let originalFormat: ImageFormat
    public let processingTime: TimeInterval
    public let memoryUsed: UInt64
    public let hasAnimation: Bool
    public let frameCount: Int
    public let memoryOptimized: Bool
    
    public init(
        originalData: Data,
        processedData: Data,
        originalFormat: ImageFormat,
        processingTime: TimeInterval,
        memoryUsed: UInt64,
        hasAnimation: Bool = false,
        frameCount: Int = 1,
        memoryOptimized: Bool = true
    ) {
        self.originalData = originalData
        self.processedData = processedData
        self.originalFormat = originalFormat
        self.processingTime = processingTime
        self.memoryUsed = memoryUsed
        self.hasAnimation = hasAnimation
        self.frameCount = frameCount
        self.memoryOptimized = memoryOptimized
    }
}

/// Protocol for image processing plugins
public protocol ImageProcessingPluginProtocol: PluginProtocol {
    /// Process image data with the plugin's algorithm
    /// - Parameters:
    ///   - imageData: Raw image data
    ///   - format: Image format
    /// - Returns: Processed image result
    /// - Throws: ImageProcessingError if processing fails
    func processImage(_ imageData: Data, format: ImageFormat) async throws -> ProcessedImageResult
}

/// Manages image processing operations for plugins with format support and memory efficiency
@MainActor
public final class ImageProcessingPluginSupport {
    
    // MARK: - Properties
    
    private let logger: Logger
    private let memoryLimit: UInt64 = 500 * 1024 * 1024 // 500MB default limit for testing
    private let processingTimeout: TimeInterval = 30.0 // 30 seconds
    
    // Currently supported formats (RAW support will be added later)
    private let supportedFormats: Set<ImageFormat> = [.jpeg, .heic, .gif]
    
    // MARK: - Initialization
    
    public init() {
        self.logger = Logger()
        logger.info("ImageProcessingPluginSupport initialized")
    }
    
    // MARK: - Public Methods
    
    /// Process image data using the specified plugin
    /// - Parameters:
    ///   - data: Image data to process
    ///   - format: Expected image format
    ///   - plugin: Plugin to use for processing
    /// - Returns: Processing result with metadata
    /// - Throws: ImageProcessingError if processing fails
    public func processImage(
        data: Data,
        format: ImageFormat,
        with plugin: ImageProcessingPluginProtocol
    ) async throws -> ProcessedImageResult {
        logger.info("Starting image processing with plugin: \(plugin.metadata.id), format: \(format.rawValue)")
        
        // Validate format support
        guard supportedFormats.contains(format) else {
            throw ImageProcessingError.unsupportedFormat(format)
        }
        
        // Validate image data
        guard !data.isEmpty else {
            throw ImageProcessingError.invalidImageData
        }
        
        // Check memory constraints
        let currentMemory = getCurrentMemoryUsage()
        guard currentMemory + UInt64(data.count) < memoryLimit else {
            throw ImageProcessingError.memoryLimitExceeded(limit: memoryLimit)
        }
        
        let startTime = Date()
        
        do {
            // Execute processing with timeout
            let result = try await withThrowingTaskGroup(of: ProcessedImageResult.self) { group in
                // Add processing task
                group.addTask {
                    try await plugin.processImage(data, format: format)
                }
                
                // Add timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(self.processingTimeout * 1_000_000_000))
                    throw ImageProcessingError.processingTimeout
                }
                
                // Wait for first completion
                guard let result = try await group.next() else {
                    throw ImageProcessingError.pluginProcessingFailed(reason: "No result returned")
                }
                
                // Cancel remaining tasks
                group.cancelAll()
                return result
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            logger.info("Image processing completed in \(processingTime)s")
            
            // Create result with updated timing
            return ProcessedImageResult(
                originalData: result.originalData,
                processedData: result.processedData,
                originalFormat: result.originalFormat,
                processingTime: processingTime,
                memoryUsed: result.memoryUsed,
                hasAnimation: result.hasAnimation,
                frameCount: result.frameCount,
                memoryOptimized: result.memoryOptimized
            )
            
        } catch let error as ImageProcessingError {
            logger.error("Image processing failed: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("Unexpected error during image processing: \(error.localizedDescription)")
            throw ImageProcessingError.pluginProcessingFailed(reason: error.localizedDescription)
        }
    }
    
    /// Get list of supported image formats
    /// - Returns: Set of supported formats
    public func getSupportedFormats() -> Set<ImageFormat> {
        return supportedFormats
    }
    
    /// Validate that image data matches expected format
    /// - Parameters:
    ///   - data: Image data to validate
    ///   - expectedFormat: Expected format
    /// - Returns: True if format matches, false otherwise
    /// - Throws: ImageProcessingError if validation fails
    public func validateImageFormat(data: Data, expectedFormat: ImageFormat) async throws -> Bool {
        guard !data.isEmpty else {
            throw ImageProcessingError.invalidImageData
        }
        
        let detectedFormat = await detectImageFormat(from: data)
        let isValid = detectedFormat == expectedFormat
        
        logger.debug("Format validation: expected=\(expectedFormat.rawValue), detected=\(detectedFormat?.rawValue ?? "unknown"), valid=\(isValid)")
        
        return isValid
    }
    
    // MARK: - Private Methods
    
    /// Detect image format from data header
    private func detectImageFormat(from data: Data) async -> ImageFormat? {
        guard data.count >= 8 else { return nil }
        
        let header = data.prefix(8)
        
        // Check JPEG signature (FF D8)
        if header.starts(with: Data([0xFF, 0xD8])) {
            return .jpeg
        }
        
        // Check GIF signature (GIF89a or GIF87a)
        if header.starts(with: Data("GIF89a".utf8)) || header.starts(with: Data("GIF87a".utf8)) {
            return .gif
        }
        
        // Check HEIC signature (more complex, check for 'ftyp' box with 'heic')
        if data.count >= 12 {
            let ftypSignature = data.subdata(in: 4..<8)
            let brandSignature = data.subdata(in: 8..<12)
            
            if ftypSignature == Data("ftyp".utf8) && brandSignature == Data("heic".utf8) {
                return .heic
            }
        }
        
        return nil
    }
    
    /// Get current memory usage for monitoring
    private func getCurrentMemoryUsage() -> UInt64 {
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
        
        return UInt64(info.resident_size)
    }
}

// MARK: - Extensions

extension ImageFormat {
    /// Check if format supports animation
    public var supportsAnimation: Bool {
        switch self {
        case .gif:
            return true
        case .jpeg, .heic, .raw:
            return false
        }
    }
    
    /// Check if format supports transparency
    public var supportsTransparency: Bool {
        switch self {
        case .gif:
            return true
        case .jpeg:
            return false
        case .heic:
            return true // HEIC can support transparency
        case .raw:
            return true // RAW formats typically support transparency
        }
    }
}