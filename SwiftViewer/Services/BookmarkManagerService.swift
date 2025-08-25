//
//  BookmarkManagerService.swift
//  SwiftViewer
//
//  Created by Claude Code on Folder Permission Error Resolution
//

import Foundation

// MARK: - BookmarkManagerError

enum BookmarkManagerError: LocalizedError {
    case bookmarkCreationFailed(URL, Error)
    case bookmarkResolutionFailed(Error)
    case bookmarkStale
    case invalidBookmarkData
    case permissionDenied(URL)
    case externalVolumeUnavailable(URL)
    
    var errorDescription: String? {
        switch self {
        case .bookmarkCreationFailed(let url, let error):
            return "Failed to create bookmark for '\(url.path)': \(error.localizedDescription)"
        case .bookmarkResolutionFailed(let error):
            return "Failed to resolve bookmark: \(error.localizedDescription)"
        case .bookmarkStale:
            return "Bookmark has become stale and needs to be refreshed"
        case .invalidBookmarkData:
            return "Invalid bookmark data format"
        case .permissionDenied(let url):
            return "Permission denied to access '\(url.path)'"
        case .externalVolumeUnavailable(let url):
            return "External volume containing '\(url.path)' is not available"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .bookmarkCreationFailed, .permissionDenied:
            return "Please select the folder again to grant access permissions."
        case .bookmarkResolutionFailed, .bookmarkStale:
            return "The folder access has expired. Please select the folder again."
        case .invalidBookmarkData:
            return "The stored folder information is corrupted. Please select the folder again."
        case .externalVolumeUnavailable:
            return "Please ensure the external drive or network volume is connected and accessible."
        }
    }
}

// MARK: - BookmarkManagerServiceProtocol

protocol BookmarkManagerServiceProtocol {
    func createBookmark(for url: URL) throws -> Data
    func validateBookmark(_ bookmarkData: Data) -> Bool
    func restoreAccess(from bookmarkData: Data) throws -> URL
    func removeBookmark(for url: URL)
    func getAllBookmarks() -> [String: Data]
    func hasBookmark(for url: URL) -> Bool
    func refreshBookmark(for url: URL) throws
    func withSecurityScopedResource<T>(_ url: URL, closure: (URL) throws -> T) throws -> T
}

extension BookmarkManagerServiceProtocol {
    func createAndStoreBookmark(for url: URL) throws {
        let bookmarkData = try createBookmark(for: url)
        // Store bookmark automatically using the URL path as key
        UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey(for: url))
    }
    
    func restoreAccessIfNeeded(for url: URL) throws -> URL {
        let key = bookmarkKey(for: url)
        guard let bookmarkData = UserDefaults.standard.data(forKey: key) else {
            // No bookmark exists, return original URL (first-time access)
            return url
        }
        
        if validateBookmark(bookmarkData) {
            return try restoreAccess(from: bookmarkData)
        } else {
            // Bookmark is stale, remove it
            removeBookmark(for: url)
            throw BookmarkManagerError.bookmarkStale
        }
    }
    
    private func bookmarkKey(for url: URL) -> String {
        return "bookmark_\(url.path.hash)"
    }
}

// MARK: - BookmarkManagerService

final class BookmarkManagerService: BookmarkManagerServiceProtocol {
    private let userDefaults: UserDefaults
    private let logger = Logger.shared
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func createBookmark(for url: URL) throws -> Data {
        logger.info("Creating security-scoped bookmark for: \(url.path)")
        
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            logger.debug("Successfully created bookmark for: \(url.path)")
            return bookmarkData
            
        } catch {
            logger.error("Failed to create bookmark for: \(url.path)", error: error)
            throw BookmarkManagerError.bookmarkCreationFailed(url, error)
        }
    }
    
    func validateBookmark(_ bookmarkData: Data) -> Bool {
        do {
            var isStale = false
            let _ = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return !isStale
        } catch {
            logger.debug("Bookmark validation failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func restoreAccess(from bookmarkData: Data) throws -> URL {
        logger.debug("Restoring access from security-scoped bookmark")
        
        var isStale = false
        do {
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                logger.warning("Bookmark is stale for: \(resolvedURL.path)")
                throw BookmarkManagerError.bookmarkStale
            }
            
            // Check if external volume is available
            if resolvedURL.path.starts(with: "/Volumes/") {
                let volumePath = String(resolvedURL.path.prefix(while: { $0 != "/" || resolvedURL.path.firstIndex(of: "/")! < resolvedURL.path.index(resolvedURL.path.startIndex, offsetBy: 8) }))
                if !FileManager.default.fileExists(atPath: volumePath) {
                    logger.error("External volume unavailable: \(volumePath)")
                    throw BookmarkManagerError.externalVolumeUnavailable(resolvedURL)
                }
            }
            
            logger.info("Successfully restored access to: \(resolvedURL.path)")
            return resolvedURL
            
        } catch let error as BookmarkManagerError {
            throw error
        } catch {
            logger.error("Failed to resolve bookmark", error: error)
            throw BookmarkManagerError.bookmarkResolutionFailed(error)
        }
    }
    
    func removeBookmark(for url: URL) {
        let key = bookmarkKey(for: url)
        userDefaults.removeObject(forKey: key)
        logger.info("Removed bookmark for: \(url.path)")
    }
    
    func getAllBookmarks() -> [String: Data] {
        let keys = userDefaults.dictionaryRepresentation().keys
        let bookmarkKeys = keys.filter { $0.hasPrefix("bookmark_") }
        
        var bookmarks: [String: Data] = [:]
        for key in bookmarkKeys {
            if let data = userDefaults.data(forKey: key) {
                bookmarks[key] = data
            }
        }
        
        return bookmarks
    }
    
    func hasBookmark(for url: URL) -> Bool {
        let key = bookmarkKey(for: url)
        return userDefaults.data(forKey: key) != nil
    }
    
    func refreshBookmark(for url: URL) throws {
        logger.info("Refreshing bookmark for: \(url.path)")
        
        // Remove old bookmark
        removeBookmark(for: url)
        
        // Create new bookmark
        let bookmarkData = try createBookmark(for: url)
        let key = bookmarkKey(for: url)
        userDefaults.set(bookmarkData, forKey: key)
        
        logger.info("Successfully refreshed bookmark for: \(url.path)")
    }
    
    // MARK: - Private Methods
    
    private func bookmarkKey(for url: URL) -> String {
        return "bookmark_\(url.path.hash)"
    }
}

// MARK: - SecurityScopedResourceManager

extension BookmarkManagerService {
    /// Executes a closure with security-scoped resource access
    /// - Parameters:
    ///   - url: The URL to access (must be from restoreAccess)
    ///   - closure: The work to perform with access
    /// - Returns: The result of the closure
    /// - Throws: Any errors from the closure or permission errors
    func withSecurityScopedResource<T>(_ url: URL, closure: (URL) throws -> T) throws -> T {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard didStartAccessing else {
            logger.error("Failed to start accessing security-scoped resource: \(url.path)")
            throw BookmarkManagerError.permissionDenied(url)
        }
        
        logger.debug("Started security-scoped access for: \(url.path)")
        return try closure(url)
    }
}

// MARK: - MockBookmarkManagerService

final class MockBookmarkManagerService: BookmarkManagerServiceProtocol {
    private var bookmarks: [String: Data] = [:]
    private var shouldFailValidation = false
    private var shouldFailCreation = false
    
    func setFailValidation(_ shouldFail: Bool) {
        shouldFailValidation = shouldFail
    }
    
    func setFailCreation(_ shouldFail: Bool) {
        shouldFailCreation = shouldFail
    }
    
    func createBookmark(for url: URL) throws -> Data {
        if shouldFailCreation {
            throw BookmarkManagerError.bookmarkCreationFailed(url, NSError(domain: "MockError", code: 1, userInfo: nil))
        }
        
        let mockData = "mock_bookmark_\(url.path)".data(using: .utf8)!
        bookmarks[bookmarkKey(for: url)] = mockData
        return mockData
    }
    
    func validateBookmark(_ bookmarkData: Data) -> Bool {
        return !shouldFailValidation && String(data: bookmarkData, encoding: .utf8)?.hasPrefix("mock_bookmark_") == true
    }
    
    func restoreAccess(from bookmarkData: Data) throws -> URL {
        guard let urlString = String(data: bookmarkData, encoding: .utf8),
              let path = urlString.components(separatedBy: "mock_bookmark_").last else {
            throw BookmarkManagerError.invalidBookmarkData
        }
        return URL(fileURLWithPath: path)
    }
    
    func removeBookmark(for url: URL) {
        bookmarks.removeValue(forKey: bookmarkKey(for: url))
    }
    
    func getAllBookmarks() -> [String: Data] {
        return bookmarks
    }
    
    func hasBookmark(for url: URL) -> Bool {
        return bookmarks[bookmarkKey(for: url)] != nil
    }
    
    func refreshBookmark(for url: URL) throws {
        try createBookmark(for: url)
    }
    
    func withSecurityScopedResource<T>(_ url: URL, closure: (URL) throws -> T) throws -> T {
        // Mock implementation - just execute closure directly
        return try closure(url)
    }
    
    private func bookmarkKey(for url: URL) -> String {
        return "bookmark_\(url.path.hash)"
    }
}