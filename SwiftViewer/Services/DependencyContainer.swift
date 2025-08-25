//
//  DependencyContainer.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation

protocol DependencyContainerProtocol {
    var fileManagerService: FileManagerServiceProtocol { get }
    var imageLoaderService: ImageLoaderServiceProtocol { get }
    var settingsManager: SettingsManagerProtocol { get }
    @MainActor var slideShowService: SlideShowServiceProtocol { get }
}

final class DependencyContainer: DependencyContainerProtocol {
    static let shared = DependencyContainer()
    
    private init() {}
    
    lazy var fileManagerService: FileManagerServiceProtocol = {
        FileManagerService()
    }()
    
    lazy var imageLoaderService: ImageLoaderServiceProtocol = {
        ImageLoaderService()
    }()
    
    lazy var settingsManager: SettingsManagerProtocol = {
        SettingsManager()
    }()
    
    
    @MainActor lazy var slideShowService: SlideShowServiceProtocol = {
        SlideShowService()
    }()
}

final class MockDependencyContainer: DependencyContainerProtocol {
    var fileManagerService: FileManagerServiceProtocol
    var imageLoaderService: ImageLoaderServiceProtocol
    var settingsManager: SettingsManagerProtocol
    
    @MainActor lazy var slideShowService: SlideShowServiceProtocol = {
        MockSlideShowService()
    }()
    
    init(
        fileManagerService: FileManagerServiceProtocol = MockFileManagerService(),
        imageLoaderService: ImageLoaderServiceProtocol = MockImageLoaderService(),
        settingsManager: SettingsManagerProtocol = MockSettingsManager()
    ) {
        self.fileManagerService = fileManagerService
        self.imageLoaderService = imageLoaderService
        self.settingsManager = settingsManager
    }
}