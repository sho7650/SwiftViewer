import XCTest
import Foundation
import CoreGraphics
import ImageIO
@testable import SwiftViewer

/// Tests for Image Processing Plugin Support functionality
/// Unit 14: Image Processing Plugin Support (2-3 hours)
/// Test: Image data handling for plugins
@MainActor
final class ImageProcessingPluginSupportTests: XCTestCase {
    
    fileprivate var sut: ImageProcessingPluginSupport!
    fileprivate var mockImageProcessingPlugin: MockImageProcessingPlugin!
    
    override func setUp() async throws {
        try await super.setUp()
        mockImageProcessingPlugin = MockImageProcessingPlugin()
        sut = ImageProcessingPluginSupport()
    }
    
    override func tearDown() async throws {
        sut = nil
        mockImageProcessingPlugin = nil
        try await super.tearDown()
    }
    
    // MARK: - Image Format Support Tests
    
    func testProcessImage_WithJPEGFormat_ShouldHandleCorrectly() async throws {
        // Given JPEG image data
        let jpegData = createMockImageData(format: .jpeg)
        
        // When processing image
        let result = try await sut.processImage(
            data: jpegData,
            format: .jpeg,
            with: mockImageProcessingPlugin
        )
        
        // Then should handle JPEG correctly
        XCTAssertNotNil(result.processedData)
        XCTAssertEqual(result.originalFormat, .jpeg)
        XCTAssertGreaterThan(result.processingTime, 0)
        XCTAssertTrue(mockImageProcessingPlugin.processImageCalled)
    }
    
    func testProcessImage_WithHEICFormat_ShouldHandleCorrectly() async throws {
        // Given HEIC image data
        let heicData = createMockImageData(format: .heic)
        
        // When processing image
        let result = try await sut.processImage(
            data: heicData,
            format: .heic,
            with: mockImageProcessingPlugin
        )
        
        // Then should handle HEIC correctly
        XCTAssertNotNil(result.processedData)
        XCTAssertEqual(result.originalFormat, .heic)
        XCTAssertGreaterThan(result.processingTime, 0)
    }
    
    func testProcessImage_WithGIFFormat_ShouldHandleAnimation() async throws {
        // Given GIF image data with animation
        let gifData = createMockImageData(format: .gif, animated: true)
        
        // When processing animated GIF
        let result = try await sut.processImage(
            data: gifData,
            format: .gif,
            with: mockImageProcessingPlugin
        )
        
        // Then should preserve animation metadata
        XCTAssertNotNil(result.processedData)
        XCTAssertEqual(result.originalFormat, .gif)
        XCTAssertTrue(result.hasAnimation)
        XCTAssertGreaterThan(result.frameCount, 1)
    }
    
    func testProcessImage_WithUnsupportedFormat_ShouldThrowError() async {
        // Given unsupported format
        let invalidData = Data("invalid".utf8)
        
        // When processing unsupported format
        do {
            _ = try await sut.processImage(
                data: invalidData,
                format: .raw, // Unsupported format
                with: mockImageProcessingPlugin
            )
            XCTFail("Expected error for unsupported format")
        } catch let error as ImageProcessingError {
            // Then should throw unsupported format error
            switch error {
            case .unsupportedFormat:
                break // This is expected
            default:
                XCTFail("Expected unsupported format error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Memory Efficiency Tests
    
    func testProcessImage_WithLargeImage_ShouldManageMemoryEfficiently() async throws {
        // Given large image data (simulated 2MB - more reasonable for testing)
        let largeImageData = createMockImageData(format: .jpeg, size: 2 * 1024 * 1024)
        
        // Track initial memory
        let initialMemory = getCurrentMemoryUsage()
        
        // When processing large image
        let result = try await sut.processImage(
            data: largeImageData,
            format: .jpeg,
            with: mockImageProcessingPlugin
        )
        
        // Then memory usage should be controlled
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = abs(Int64(finalMemory) - Int64(initialMemory))
        
        XCTAssertNotNil(result.processedData)
        XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024) // Less than 100MB increase
        XCTAssertTrue(result.memoryOptimized)
    }
    
    func testProcessImage_WithMultipleFormats_ShouldHandleSequentially() async throws {
        // Given multiple image formats
        let jpegData = createMockImageData(format: .jpeg)
        let heicData = createMockImageData(format: .heic)
        let gifData = createMockImageData(format: .gif)
        
        // When processing multiple formats
        let jpegResult = try await sut.processImage(data: jpegData, format: .jpeg, with: mockImageProcessingPlugin)
        let heicResult = try await sut.processImage(data: heicData, format: .heic, with: mockImageProcessingPlugin)
        let gifResult = try await sut.processImage(data: gifData, format: .gif, with: mockImageProcessingPlugin)
        
        // Then all should be processed correctly
        XCTAssertEqual(jpegResult.originalFormat, .jpeg)
        XCTAssertEqual(heicResult.originalFormat, .heic)
        XCTAssertEqual(gifResult.originalFormat, .gif)
        XCTAssertEqual(mockImageProcessingPlugin.processImageCallCount, 3)
    }
    
    // MARK: - Plugin Integration Tests
    
    func testProcessImage_WithPluginThatThrowsError_ShouldPropagateError() async {
        // Given plugin that throws error
        mockImageProcessingPlugin.shouldThrowError = true
        let imageData = createMockImageData(format: .jpeg)
        
        // When processing with failing plugin
        do {
            _ = try await sut.processImage(
                data: imageData,
                format: .jpeg,
                with: mockImageProcessingPlugin
            )
            XCTFail("Expected plugin error")
        } catch let error as ImageProcessingError {
            // Then should propagate plugin error
            switch error {
            case .pluginProcessingFailed:
                break // This is expected
            default:
                XCTFail("Expected plugin processing failed error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testGetSupportedFormats_ShouldReturnAllSupportedFormats() {
        // When getting supported formats
        let formats = sut.getSupportedFormats()
        
        // Then should include all major formats
        XCTAssertTrue(formats.contains(.jpeg))
        XCTAssertTrue(formats.contains(.heic))
        XCTAssertTrue(formats.contains(.gif))
        XCTAssertFalse(formats.contains(.raw)) // Not supported yet
    }
    
    func testValidateImageFormat_WithValidFormats_ShouldReturnTrue() async throws {
        // Given valid format data
        let jpegData = createMockImageData(format: .jpeg)
        
        // When validating format
        let isValid = try await sut.validateImageFormat(data: jpegData, expectedFormat: .jpeg)
        
        // Then should validate correctly
        XCTAssertTrue(isValid)
    }
    
    func testValidateImageFormat_WithMismatchedFormat_ShouldReturnFalse() async throws {
        // Given JPEG data claimed as HEIC
        let jpegData = createMockImageData(format: .jpeg)
        
        // When validating with wrong format
        let isValid = try await sut.validateImageFormat(data: jpegData, expectedFormat: .heic)
        
        // Then should detect mismatch
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Performance Tests
    
    func testProcessImage_PerformanceWithStandardImage_ShouldMeetTimingRequirements() async throws {
        // Given standard size image
        let imageData = createMockImageData(format: .jpeg, size: 2 * 1024 * 1024) // 2MB
        
        // Measure processing time
        let startTime = Date()
        let result = try await sut.processImage(
            data: imageData,
            format: .jpeg,
            with: mockImageProcessingPlugin
        )
        let processingTime = Date().timeIntervalSince(startTime)
        
        // Then should process within acceptable time
        XCTAssertNotNil(result.processedData)
        XCTAssertLessThan(processingTime, 1.0) // Should complete within 1 second
        XCTAssertEqual(result.processingTime, processingTime, accuracy: 0.1)
    }
    
    // MARK: - Helper Methods
    
    private func createMockImageData(format: ImageFormat, size: Int = 1024, animated: Bool = false) -> Data {
        switch format {
        case .jpeg:
            return createJPEGData(size: size)
        case .heic:
            return createHEICData(size: size)
        case .gif:
            return createGIFData(size: size, animated: animated)
        case .raw:
            return Data(repeating: 0, count: size)
        }
    }
    
    private func createJPEGData(size: Int) -> Data {
        // Create minimal valid JPEG header + data
        var data = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header
        data.append(Data(repeating: 0x00, count: max(0, size - 4)))
        data.append(Data([0xFF, 0xD9])) // JPEG end
        return data
    }
    
    private func createHEICData(size: Int) -> Data {
        // Create minimal HEIC-like data
        var data = Data("ftypheic".utf8) // HEIC signature
        data.append(Data(repeating: 0x00, count: max(0, size - 8)))
        return data
    }
    
    private func createGIFData(size: Int, animated: Bool) -> Data {
        // Create minimal GIF header
        var data = Data("GIF89a".utf8) // GIF signature
        if animated {
            data.append(Data([0x21, 0xFF])) // Application extension for animation
        }
        data.append(Data(repeating: 0x00, count: max(0, size - data.count)))
        return data
    }
    
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

// MARK: - Mock Image Processing Plugin

fileprivate class MockImageProcessingPlugin: ImageProcessingPluginProtocol {
    let metadata: PluginMetadata
    var isActive: Bool = false
    var processImageCalled: Bool = false
    var processImageCallCount: Int = 0
    var shouldThrowError: Bool = false
    
    init(id: String = "test.image.processor") {
        self.metadata = PluginMetadata(
            id: id,
            name: "Test Image Processor",
            version: "1.0.0",
            author: "Test Author",
            description: "Test image processing plugin",
            capabilities: [.imageFilter]
        )
    }
    
    func initialize() async throws {
        isActive = true
    }
    
    func cleanup() async {
        isActive = false
    }
    
    func processImage(_ imageData: Data, format: ImageFormat) async throws -> ProcessedImageResult {
        processImageCalled = true
        processImageCallCount += 1
        
        if shouldThrowError {
            throw ImageProcessingError.pluginProcessingFailed(reason: "Mock plugin error")
        }
        
        // Simulate processing by returning modified data
        let processedData = imageData + Data("_processed".utf8)
        
        return ProcessedImageResult(
            originalData: imageData,
            processedData: processedData,
            originalFormat: format,
            processingTime: 0.01,
            memoryUsed: UInt64(imageData.count),
            hasAnimation: format == .gif,
            frameCount: format == .gif ? 2 : 1,
            memoryOptimized: true
        )
    }
}

// MARK: - Extensions for Testing

extension ImageFormat: Equatable {
    public static func == (lhs: ImageFormat, rhs: ImageFormat) -> Bool {
        switch (lhs, rhs) {
        case (.jpeg, .jpeg), (.heic, .heic), (.gif, .gif), (.raw, .raw):
            return true
        default:
            return false
        }
    }
}