//
//  FileManagerService.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation

enum FileManagerServiceError: Error {
    case directoryNotFound
    case accessDenied
    case readError(Error)
    case symbolicLinkNotAllowed
}

protocol FileManagerServiceProtocol: Sendable {
    func getImageFiles(from url: URL, sortBy: SortType) async throws -> [ImageFile]
}

extension FileManagerServiceProtocol {
    func getImageFiles(from url: URL) async throws -> [ImageFile] {
        try await getImageFiles(from: url, sortBy: .name(ascending: true))
    }
}

final class FileManagerService: FileManagerServiceProtocol, @unchecked Sendable {
    private let fileManager: FileManager
    private let logger = Logger.shared
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func getImageFiles(from url: URL, sortBy: SortType = .name(ascending: true)) async throws -> [ImageFile] {
        do {
            // Reject a symlinked source directory outright rather than silently following it.
            if url.resolvingSymlinksInPath().standardizedFileURL.path != url.standardizedFileURL.path {
                logger.warning("Rejecting symbolic-link directory: \(Logger.sanitizePath(url))")
                throw FileManagerServiceError.symbolicLinkNotAllowed
            }

            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .creationDateKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
            )

            let imageFiles = contents.compactMap { makeImageFile(from: $0) }
            return imageFiles.sorted(by: sortBy)
        } catch let error as FileManagerServiceError {
            throw error
        } catch let error as NSError {
            if error.code == NSFileReadNoSuchFileError || error.code == NSFileNoSuchFileError {
                throw FileManagerServiceError.directoryNotFound
            } else if error.code == NSFileReadNoPermissionError {
                throw FileManagerServiceError.accessDenied
            } else {
                throw FileManagerServiceError.readError(error)
            }
        }
    }

    /// Builds an `ImageFile` from a directory entry, or `nil` if it should be excluded.
    /// A single `attributesOfItem` read supplies both the symlink flag and the metadata.
    /// Any failure to read the entry fails closed (the entry is excluded).
    private func makeImageFile(from fileURL: URL) -> ImageFile? {
        guard ImageFile.supportedExtensions.contains(fileURL.pathExtension.lowercased()) else {
            return nil
        }

        let attributes: [FileAttributeKey: Any]
        do {
            attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        } catch {
            logger.debug("Excluding unreadable entry: \(fileURL.lastPathComponent)")
            return nil
        }

        if attributes[.type] as? FileAttributeType == .typeSymbolicLink {
            logger.debug("Skipping symbolic link: \(fileURL.lastPathComponent)")
            return nil
        }

        let fileSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        let createdDate = (attributes[.creationDate] as? Date) ?? Date()
        return ImageFile(
            url: fileURL,
            fileName: fileURL.lastPathComponent,
            fileSize: fileSize,
            createdDate: createdDate
        )
    }
}

final class MockFileManagerService: FileManagerServiceProtocol, @unchecked Sendable {
    var mockImageFiles: [ImageFile] = []
    var shouldThrowError = false
    var errorToThrow: Error = FileManagerServiceError.directoryNotFound
    var lastUsedSortType: SortType?
    
    func getImageFiles(from url: URL, sortBy: SortType) async throws -> [ImageFile] {
        lastUsedSortType = sortBy
        if shouldThrowError {
            throw errorToThrow
        }
        
        // For specific memory pressure test only
        if url.path.contains("/test") && url.path.contains("memory-pressure") && mockImageFiles.count < 100 {
            mockImageFiles = Array(1...100).map { 
                ImageFile(url: URL(fileURLWithPath: "/test/image\($0).jpg"), fileName: "image\($0).jpg", fileSize: 1024, createdDate: Date())
            }
        }
        
        return mockImageFiles
    }
}