//
//  ImageFile.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation

struct ImageFile: Equatable, Identifiable {
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
        let validFormats = ["jpg", "jpeg", "heic", "gif"]
        return validFormats.contains(fileExtension)
    }
    
    var isAnimated: Bool {
        return fileExtension == "gif"
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    init(url: URL, fileName: String, fileSize: Int64, createdDate: Date) {
        self.url = url
        self.fileName = fileName
        self.fileSize = fileSize
        self.createdDate = createdDate
    }
}