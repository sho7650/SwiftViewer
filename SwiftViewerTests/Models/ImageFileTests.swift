//
//  ImageFileTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/08/21.
//

import XCTest
@testable import SwiftViewer

final class ImageFileTests: XCTestCase {
    
    func test_imageFile_initialization() {
        let url = URL(fileURLWithPath: "/path/to/image.jpg")
        let fileName = "image.jpg"
        let fileSize: Int64 = 1024
        let createdDate = Date()
        
        let imageFile = ImageFile(
            url: url,
            fileName: fileName,
            fileSize: fileSize,
            createdDate: createdDate
        )
        
        XCTAssertEqual(imageFile.url, url)
        XCTAssertEqual(imageFile.fileName, fileName)
        XCTAssertEqual(imageFile.fileSize, fileSize)
        XCTAssertEqual(imageFile.createdDate, createdDate)
    }
    
    func test_imageFile_equatable() {
        let url1 = URL(fileURLWithPath: "/path/to/image1.jpg")
        let url2 = URL(fileURLWithPath: "/path/to/image2.jpg")
        let date = Date()
        
        let imageFile1 = ImageFile(
            url: url1,
            fileName: "image1.jpg",
            fileSize: 1024,
            createdDate: date
        )
        
        let imageFile2 = ImageFile(
            url: url1,
            fileName: "image1.jpg",
            fileSize: 1024,
            createdDate: date
        )
        
        let imageFile3 = ImageFile(
            url: url2,
            fileName: "image2.jpg",
            fileSize: 2048,
            createdDate: date
        )
        
        XCTAssertEqual(imageFile1, imageFile2)
        XCTAssertNotEqual(imageFile1, imageFile3)
    }
    
    func test_imageFile_identifiable() {
        let url = URL(fileURLWithPath: "/path/to/image.jpg")
        let imageFile = ImageFile(
            url: url,
            fileName: "image.jpg",
            fileSize: 1024,
            createdDate: Date()
        )
        
        XCTAssertEqual(imageFile.id, url.absoluteString)
    }
    
    func test_imageFile_fileExtension() {
        let imageFile1 = ImageFile(
            url: URL(fileURLWithPath: "/path/to/image.jpg"),
            fileName: "image.jpg",
            fileSize: 1024,
            createdDate: Date()
        )
        
        let imageFile2 = ImageFile(
            url: URL(fileURLWithPath: "/path/to/image.HEIC"),
            fileName: "image.HEIC",
            fileSize: 1024,
            createdDate: Date()
        )
        
        XCTAssertEqual(imageFile1.fileExtension, "jpg")
        XCTAssertEqual(imageFile2.fileExtension, "heic")
    }
    
    func test_imageFile_isValidImageFormat() {
        let validFormats = ["jpg", "jpeg", "heic", "gif"]
        let invalidFormats = ["png", "pdf", "txt", ""]
        
        for format in validFormats {
            let imageFile = ImageFile(
                url: URL(fileURLWithPath: "/path/to/image.\(format)"),
                fileName: "image.\(format)",
                fileSize: 1024,
                createdDate: Date()
            )
            XCTAssertTrue(imageFile.isValidImageFormat, "Format \(format) should be valid")
        }
        
        for format in invalidFormats {
            let imageFile = ImageFile(
                url: URL(fileURLWithPath: "/path/to/file.\(format)"),
                fileName: "file.\(format)",
                fileSize: 1024,
                createdDate: Date()
            )
            XCTAssertFalse(imageFile.isValidImageFormat, "Format \(format) should be invalid")
        }
    }
    
    func test_imageFile_formattedFileSize() {
        let imageFile1 = ImageFile(
            url: URL(fileURLWithPath: "/path/to/image.jpg"),
            fileName: "image.jpg",
            fileSize: 512,
            createdDate: Date()
        )
        
        let imageFile2 = ImageFile(
            url: URL(fileURLWithPath: "/path/to/image.jpg"),
            fileName: "image.jpg",
            fileSize: 1024 * 1024,
            createdDate: Date()
        )
        
        let imageFile3 = ImageFile(
            url: URL(fileURLWithPath: "/path/to/image.jpg"),
            fileName: "image.jpg",
            fileSize: 1024 * 1024 * 1024,
            createdDate: Date()
        )
        
        XCTAssertEqual(imageFile1.formattedFileSize, "512 bytes")
        XCTAssertEqual(imageFile2.formattedFileSize, "1 MB")
        XCTAssertEqual(imageFile3.formattedFileSize, "1.07 GB")
    }
    
    // MARK: - Animation Tests
    
    func test_imageFile_isAnimated_gif() {
        let gifImageFile = ImageFile(
            url: URL(fileURLWithPath: "/path/to/animation.gif"),
            fileName: "animation.gif",
            fileSize: 1024,
            createdDate: Date()
        )
        
        XCTAssertTrue(gifImageFile.isAnimated, "GIF files should be identified as animated")
    }
    
    func test_imageFile_isAnimated_nonGif() {
        let nonAnimatedFormats = ["jpg", "jpeg", "heic", "png"]
        
        for format in nonAnimatedFormats {
            let imageFile = ImageFile(
                url: URL(fileURLWithPath: "/path/to/image.\(format)"),
                fileName: "image.\(format)",
                fileSize: 1024,
                createdDate: Date()
            )
            XCTAssertFalse(imageFile.isAnimated, "Format \(format) should not be identified as animated")
        }
    }
    
    func test_imageFile_isAnimated_caseInsensitive() {
        let gifVariations = ["gif", "GIF", "Gif", "gIf"]
        
        for format in gifVariations {
            let imageFile = ImageFile(
                url: URL(fileURLWithPath: "/path/to/animation.\(format)"),
                fileName: "animation.\(format)",
                fileSize: 1024,
                createdDate: Date()
            )
            XCTAssertTrue(imageFile.isAnimated, "Format \(format) should be identified as animated (case insensitive)")
        }
    }
}