//
//  DependencyContainerTests.swift
//  SwiftViewerTests
//
//  Created by Claude on 2025/03/13.
//

import XCTest
@testable import SwiftViewer

final class DependencyContainerTests: XCTestCase {

    // MARK: - Singleton Tests

    func test_shared_returnsSameInstance() {
        let instance1 = DependencyContainer.shared
        let instance2 = DependencyContainer.shared

        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Service Type Tests

    func test_fileManagerService_returnsCorrectType() {
        let service = DependencyContainer.shared.fileManagerService

        XCTAssertTrue(service is FileManagerService)
    }

    func test_imageLoaderService_returnsCorrectType() {
        let service = DependencyContainer.shared.imageLoaderService

        XCTAssertTrue(service is ImageLoaderService)
    }

    func test_settingsManager_returnsCorrectType() {
        let service = DependencyContainer.shared.settingsManager

        XCTAssertTrue(service is SettingsManager)
    }

    // MARK: - Mock Container Tests

    func test_mockContainer_usesDefaultMocks() {
        let mock = MockDependencyContainer()

        XCTAssertTrue(mock.fileManagerService is MockFileManagerService)
        XCTAssertTrue(mock.imageLoaderService is MockImageLoaderService)
        XCTAssertTrue(mock.settingsManager is MockSettingsManager)
    }

    func test_mockContainer_acceptsCustomServices() {
        let customSettings = MockSettingsManager()
        customSettings.slideShowInterval = 42.0

        let mock = MockDependencyContainer(settingsManager: customSettings)

        XCTAssertEqual(mock.settingsManager.slideShowInterval, 42.0)
    }

    func test_mockContainer_adaptiveImageCache_isInitialized() {
        let mock = MockDependencyContainer()

        XCTAssertNotNil(mock.adaptiveImageCache)
    }
}
