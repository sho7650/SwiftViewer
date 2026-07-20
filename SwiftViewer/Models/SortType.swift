//
//  SortType.swift
//  SwiftViewer
//
//  How a folder's images are ordered for display.
//

import Foundation

enum SortType: Equatable {
    case name(ascending: Bool)
    case date(ascending: Bool)
    case size(ascending: Bool)
    case random
}

extension Array where Element == ImageFile {
    /// Returns the images ordered by the given sort type.
    func sorted(by sortType: SortType) -> [ImageFile] {
        switch sortType {
        case .name(let ascending):
            return sorted { ascending ? $0.fileName < $1.fileName : $0.fileName > $1.fileName }
        case .date(let ascending):
            return sorted { ascending ? $0.createdDate < $1.createdDate : $0.createdDate > $1.createdDate }
        case .size(let ascending):
            return sorted { ascending ? $0.fileSize < $1.fileSize : $0.fileSize > $1.fileSize }
        case .random:
            return shuffled()
        }
    }
}
