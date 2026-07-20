//
//  ImageFile.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation

struct ImageFile: Equatable, Identifiable {
    /// The single source of truth for supported image extensions (lowercased, no dot).
    static let supportedExtensions: Set<String> = ["jpg", "jpeg", "heic", "gif"]

    // Configured once and only read from thereafter (string(fromByteCount:) does not mutate it).
    nonisolated(unsafe) private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    let url: URL
    let fileName: String
    let fileSize: Int64
    let createdDate: Date

    var id: String {
        url.absoluteString
    }

    var fileExtension: String {
        url.pathExtension.lowercased()
    }

    var isValidImageFormat: Bool {
        Self.supportedExtensions.contains(fileExtension)
    }

    var isAnimated: Bool {
        return fileExtension == "gif"
    }

    var formattedFileSize: String {
        Self.byteCountFormatter.string(fromByteCount: fileSize)
    }
    
    init(url: URL, fileName: String, fileSize: Int64, createdDate: Date) {
        self.url = url
        self.fileName = fileName
        self.fileSize = fileSize
        self.createdDate = createdDate
    }
}