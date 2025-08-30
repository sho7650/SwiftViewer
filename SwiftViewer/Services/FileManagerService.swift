//
//  FileManagerService.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation

enum SortType: Equatable {
    case name(ascending: Bool)
    case date(ascending: Bool)
    case size(ascending: Bool)
    case random
}

enum FileManagerServiceError: Error {
    case directoryNotFound
    case accessDenied
    case readError(Error)
}

protocol FileManagerServiceProtocol {
    func getImageFiles(from url: URL, sortBy: SortType) async throws -> [ImageFile]
}

extension FileManagerServiceProtocol {
    func getImageFiles(from url: URL) async throws -> [ImageFile] {
        try await getImageFiles(from: url, sortBy: .name(ascending: true))
    }
}

final class FileManagerService: FileManagerServiceProtocol {
    private let fileManager: FileManager
    private let logger = Logger.shared
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func getImageFiles(from url: URL, sortBy: SortType = .name(ascending: true)) async throws -> [ImageFile] {
        return try await Task {
            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
                    options: [.skipsHiddenFiles]
                )
                
                let imageFiles = try contents.compactMap { fileURL -> ImageFile? in
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    
                    let fileName = fileURL.lastPathComponent
                    let fileSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
                    let createdDate = (attributes[.creationDate] as? Date) ?? Date()
                    
                    let imageFile = ImageFile(
                        url: fileURL,
                        fileName: fileName,
                        fileSize: fileSize,
                        createdDate: createdDate
                    )
                    
                    return imageFile.isValidImageFormat ? imageFile : nil
                }
                
                return sortImageFiles(imageFiles, by: sortBy)
            } catch let error as NSError {
                if error.code == NSFileReadNoSuchFileError || error.code == NSFileNoSuchFileError {
                    throw FileManagerServiceError.directoryNotFound
                } else if error.code == NSFileReadNoPermissionError {
                    throw FileManagerServiceError.accessDenied
                } else {
                    throw FileManagerServiceError.readError(error)
                }
            }
        }.value
    }
    
    
    private func sortImageFiles(_ files: [ImageFile], by sortType: SortType) -> [ImageFile] {
        switch sortType {
        case .name(let ascending):
            return files.sorted { 
                ascending ? $0.fileName < $1.fileName : $0.fileName > $1.fileName
            }
        case .date(let ascending):
            return files.sorted {
                ascending ? $0.createdDate < $1.createdDate : $0.createdDate > $1.createdDate
            }
        case .size(let ascending):
            return files.sorted {
                ascending ? $0.fileSize < $1.fileSize : $0.fileSize > $1.fileSize
            }
        case .random:
            return files.shuffled()
        }
    }
}

final class MockFileManagerService: FileManagerServiceProtocol {
    var mockImageFiles: [ImageFile] = []
    var shouldThrowError = false
    var errorToThrow: Error = FileManagerServiceError.directoryNotFound
    var lastUsedSortType: SortType?
    
    // Test helper properties
    var shouldReturnCorruptedImage = false
    var simulateLowMemory = false
    var disableAutoGeneration = false // New property to control auto-generation
    
    func getImageFiles(from url: URL, sortBy: SortType) async throws -> [ImageFile] {
        lastUsedSortType = sortBy
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Only auto-generate if not disabled and no mock files are set
        if !disableAutoGeneration && url.path.contains("/test") && mockImageFiles.isEmpty {
            mockImageFiles = Array(1...100).map { 
                ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
            }
        }
        
        return mockImageFiles
    }
}