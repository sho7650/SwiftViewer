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
    var adaptiveImageCache: AdaptiveImageCacheProtocol { get }
    @MainActor var slideShowService: SlideShowServiceProtocol { get }
    // TODO: Plugin system not yet implemented
    // @MainActor var pluginSettingsManager: PluginSettingsManager { get }
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
    
    lazy var adaptiveImageCache: AdaptiveImageCacheProtocol = {
        AdaptiveImageCache(fileManager: fileManagerService, settings: settingsManager)
    }()
    
    @MainActor lazy var slideShowService: SlideShowServiceProtocol = {
        SlideShowService()
    }()
    
    // TODO: Plugin system not yet implemented
    // @MainActor lazy var pluginSettingsManager: PluginSettingsManager = {
    //     PluginSettingsManager(settingsManager: settingsManager)
    // }()
}

final class MockDependencyContainer: DependencyContainerProtocol {
    var fileManagerService: FileManagerServiceProtocol
    var imageLoaderService: ImageLoaderServiceProtocol
    var settingsManager: SettingsManagerProtocol
    var adaptiveImageCache: AdaptiveImageCacheProtocol
    
    @MainActor lazy var slideShowService: SlideShowServiceProtocol = {
        MockSlideShowService()
    }()
    
    // TODO: Plugin system not yet implemented
    // @MainActor lazy var pluginSettingsManager: PluginSettingsManager = {
    //     PluginSettingsManager(settingsManager: settingsManager)
    // }()
    
    init(
        fileManagerService: FileManagerServiceProtocol = MockFileManagerService(),
        imageLoaderService: ImageLoaderServiceProtocol = MockImageLoaderService(),
        settingsManager: SettingsManagerProtocol = MockSettingsManager()
    ) {
        self.fileManagerService = fileManagerService
        self.imageLoaderService = imageLoaderService
        self.settingsManager = settingsManager
        self.adaptiveImageCache = AdaptiveImageCache(fileManager: fileManagerService, settings: settingsManager)
    }
}