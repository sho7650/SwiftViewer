//
//  DependencyContainer.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import Foundation

protocol DependencyContainerProtocol {
    var fileManagerService: FileManagerServiceProtocol { get }
    var imagePipeline: ImagePipelineProtocol { get }
    var settingsManager: SettingsManagerProtocol { get }
    @MainActor var slideShowService: SlideShowServiceProtocol { get }
}

/// The production composition root. Marked `@unchecked Sendable` because it is
/// initialised once and its stored services are only read afterward; the
/// `@MainActor` service is created lazily on the main actor.
final class DependencyContainer: DependencyContainerProtocol, @unchecked Sendable {
    static let shared = DependencyContainer()

    let fileManagerService: FileManagerServiceProtocol
    let settingsManager: SettingsManagerProtocol
    let imagePipeline: ImagePipelineProtocol

    private init() {
        let settings = SettingsManager()
        self.fileManagerService = FileManagerService()
        self.settingsManager = settings
        self.imagePipeline = ImagePipeline(
            memoryLimitPercentage: settings.cacheMemoryLimitPercentage,
            countLimit: settings.cacheCountLimit
        )
    }

    @MainActor lazy var slideShowService: SlideShowServiceProtocol = {
        SlideShowService()
    }()
}

final class MockDependencyContainer: DependencyContainerProtocol {
    var fileManagerService: FileManagerServiceProtocol
    var imagePipeline: ImagePipelineProtocol
    var settingsManager: SettingsManagerProtocol

    @MainActor lazy var slideShowService: SlideShowServiceProtocol = {
        MockSlideShowService()
    }()

    init(
        fileManagerService: FileManagerServiceProtocol = MockFileManagerService(),
        imagePipeline: ImagePipelineProtocol = MockImagePipeline(),
        settingsManager: SettingsManagerProtocol = MockSettingsManager()
    ) {
        self.fileManagerService = fileManagerService
        self.imagePipeline = imagePipeline
        self.settingsManager = settingsManager
    }
}