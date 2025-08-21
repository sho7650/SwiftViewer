//
//  FileManagerServiceTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
@testable import SwiftViewer

final class FileManagerServiceTests: XCTestCase {
    
    var sut: FileManagerService!
    var mockFileManager: MockFoundationFileManager!
    
    override func setUp() {
        super.setUp()
        mockFileManager = MockFoundationFileManager()
        sut = FileManagerService(fileManager: mockFileManager)
    }
    
    override func tearDown() {
        sut = nil
        mockFileManager = nil
        super.tearDown()
    }
    
    func test_getImageFiles_returnsOnlyValidImageFormats() async throws {
        let testURL = URL(fileURLWithPath: "/test/folder")
        
        mockFileManager.mockContents = [
            URL(fileURLWithPath: "/test/folder/image1.jpg"),
            URL(fileURLWithPath: "/test/folder/image2.jpeg"),
            URL(fileURLWithPath: "/test/folder/image3.heic"),
            URL(fileURLWithPath: "/test/folder/image4.gif"),
            URL(fileURLWithPath: "/test/folder/document.pdf"),
            URL(fileURLWithPath: "/test/folder/text.txt")
        ]
        
        mockFileManager.mockAttributes = [
            .size: NSNumber(value: 1024),
            .creationDate: Date()
        ]
        
        let imageFiles = try await sut.getImageFiles(from: testURL)
        
        XCTAssertEqual(imageFiles.count, 4)
        XCTAssertTrue(imageFiles.allSatisfy { $0.isValidImageFormat })
    }
    
    func test_getImageFiles_throwsError_whenDirectoryDoesNotExist() async {
        let testURL = URL(fileURLWithPath: "/nonexistent/folder")
        mockFileManager.shouldThrowError = true
        
        do {
            _ = try await sut.getImageFiles(from: testURL)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is FileManagerServiceError)
        }
    }
    
    func test_getImageFiles_returnsEmptyArray_whenNoImagesInFolder() async throws {
        let testURL = URL(fileURLWithPath: "/test/folder")
        
        mockFileManager.mockContents = [
            URL(fileURLWithPath: "/test/folder/document.pdf"),
            URL(fileURLWithPath: "/test/folder/text.txt")
        ]
        
        let imageFiles = try await sut.getImageFiles(from: testURL)
        
        XCTAssertTrue(imageFiles.isEmpty)
    }
    
    func test_getImageFiles_sortsFilesByName_ascending() async throws {
        let testURL = URL(fileURLWithPath: "/test/folder")
        
        mockFileManager.mockContents = [
            URL(fileURLWithPath: "/test/folder/c.jpg"),
            URL(fileURLWithPath: "/test/folder/a.jpg"),
            URL(fileURLWithPath: "/test/folder/b.jpg")
        ]
        
        mockFileManager.mockAttributes = [
            .size: NSNumber(value: 1024),
            .creationDate: Date()
        ]
        
        let imageFiles = try await sut.getImageFiles(
            from: testURL,
            sortBy: .name(ascending: true)
        )
        
        XCTAssertEqual(imageFiles[0].fileName, "a.jpg")
        XCTAssertEqual(imageFiles[1].fileName, "b.jpg")
        XCTAssertEqual(imageFiles[2].fileName, "c.jpg")
    }
    
    func test_getImageFiles_sortsFilesBySize_descending() async throws {
        let testURL = URL(fileURLWithPath: "/test/folder")
        
        mockFileManager.mockContents = [
            URL(fileURLWithPath: "/test/folder/small.jpg"),
            URL(fileURLWithPath: "/test/folder/large.jpg"),
            URL(fileURLWithPath: "/test/folder/medium.jpg")
        ]
        
        mockFileManager.mockAttributesForPaths = [
            "/test/folder/small.jpg": [
                .size: NSNumber(value: 100),
                .creationDate: Date()
            ],
            "/test/folder/large.jpg": [
                .size: NSNumber(value: 1000),
                .creationDate: Date()
            ],
            "/test/folder/medium.jpg": [
                .size: NSNumber(value: 500),
                .creationDate: Date()
            ]
        ]
        
        let imageFiles = try await sut.getImageFiles(
            from: testURL,
            sortBy: .size(ascending: false)
        )
        
        XCTAssertEqual(imageFiles[0].fileName, "large.jpg")
        XCTAssertEqual(imageFiles[1].fileName, "medium.jpg")
        XCTAssertEqual(imageFiles[2].fileName, "small.jpg")
    }
}

class MockFoundationFileManager: FileManager {
    var mockContents: [URL] = []
    var mockAttributes: [FileAttributeKey: Any] = [:]
    var mockAttributesForPaths: [String: [FileAttributeKey: Any]] = [:]
    var shouldThrowError = false
    
    override func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions = []) throws -> [URL] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        return mockContents
    }
    
    override func attributesOfItem(atPath path: String) throws -> [FileAttributeKey : Any] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        
        if let attributes = mockAttributesForPaths[path] {
            return attributes
        }
        
        return mockAttributes
    }
}