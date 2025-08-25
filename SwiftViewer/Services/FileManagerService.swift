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
    private let bookmarkManagerService: BookmarkManagerServiceProtocol
    private let logger = Logger.shared
    
    init(
        fileManager: FileManager = .default,
        bookmarkManagerService: BookmarkManagerServiceProtocol = BookmarkManagerService()
    ) {
        self.fileManager = fileManager
        self.bookmarkManagerService = bookmarkManagerService
    }
    
    func getImageFiles(from url: URL, sortBy: SortType = .name(ascending: true)) async throws -> [ImageFile] {
        return try await Task {
            do {
                // Try to restore access using bookmark if available, otherwise use original URL
                let accessibleURL = try bookmarkManagerService.restoreAccessIfNeeded(for: url)
                
                // Use security-scoped resource access if URL was resolved from bookmark
                if accessibleURL != url {
                    return try bookmarkManagerService.withSecurityScopedResource(accessibleURL) { securedURL in
                        try getImageFilesWithDirectAccess(from: securedURL, sortBy: sortBy)
                    }
                } else {
                    // First-time access or no bookmark - use direct access
                    return try getImageFilesWithDirectAccess(from: url, sortBy: sortBy)
                }
                
            } catch let error as BookmarkManagerError {
                logger.error("Bookmark error for \(url.path): \(error.localizedDescription)")
                // Fallback to direct access for bookmark errors
                return try getImageFilesWithDirectAccess(from: url, sortBy: sortBy)
            } catch {
                logger.error("Failed to get image files from \(url.path)", error: error)
                throw FileManagerServiceError.readError(error)
            }
        }.value
    }
    
    private func getImageFilesWithDirectAccess(from url: URL, sortBy: SortType) throws -> [ImageFile] {
        // For external volumes, try with a brief delay to allow permission establishment
        let contents: [URL]
        if url.path.starts(with: "/Volumes/") {
            contents = try getDirectoryContentsWithRetry(url: url)
        } else {
            contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
                options: [.skipsHiddenFiles]
            )
        }
        
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
    }
    
    private func getDirectoryContentsWithRetry(url: URL) throws -> [URL] {
        // For external volumes, brief delay to allow permission establishment
        // Based on best practices research: avoid complex retry loops for timing issues
        Thread.sleep(forTimeInterval: 0.05) // 50ms delay
        
        return try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )
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
    private let mockBookmarkService = MockBookmarkManagerService()
    
    func getImageFiles(from url: URL, sortBy: SortType) async throws -> [ImageFile] {
        lastUsedSortType = sortBy
        if shouldThrowError {
            throw errorToThrow
        }
        return mockImageFiles
    }
}