import XCTest
@testable import SwiftViewer

final class PluginErrorHandlingTests: XCTestCase {
    
    // MARK: - Error Type Classification Tests
    
    func test_PluginError_bundleErrorCases() {
        let errors: [PluginError] = [
            .bundleNotFound(path: "/test/path"),
            .invalidBundleStructure(reason: "Missing plugin.json"),
            .metadataParsingFailed(underlying: MockError.testError)
        ]
        
        for error in errors {
            XCTAssertTrue(error.isBundleError, "Should be classified as bundle error: \(error)")
        }
    }
    
    func test_PluginError_loadingErrorCases() {
        let errors: [PluginError] = [
            .loadingFailed(reason: "Executable not found"),
            .initializationFailed(reason: "Plugin setup failed"),
            .dependencyNotFound(name: "RequiredLibrary"),
            .incompatibleVersion(required: "1.0.0", found: "2.0.0")
        ]
        
        for error in errors {
            XCTAssertTrue(error.isLoadingError, "Should be classified as loading error: \(error)")
        }
    }
    
    func test_PluginError_runtimeErrorCases() {
        let errors: [PluginError] = [
            .executionFailed(reason: "Runtime exception"),
            .resourceLimitExceeded(resource: "Memory", limit: "100MB"),
            .timeoutExceeded(operation: "Initialize", timeout: 5.0),
            .unexpectedBehavior(description: "Plugin crashed")
        ]
        
        for error in errors {
            XCTAssertTrue(error.isRuntimeError, "Should be classified as runtime error: \(error)")
        }
    }
    
    func test_PluginError_registryErrorCases() {
        let errors: [PluginError] = [
            .pluginAlreadyRegistered(id: "com.test.plugin"),
            .pluginNotFound(id: "com.test.missing"),
            .registryCorrupted(reason: "Database inconsistency")
        ]
        
        for error in errors {
            XCTAssertTrue(error.isRegistryError, "Should be classified as registry error: \(error)")
        }
    }
    
    func test_PluginError_validationErrorCases() {
        let errors: [PluginError] = [
            .invalidMetadata(field: "capabilities", reason: "Empty array"),
            .missingExecutable(bundlePath: "/test/plugin.bundle"),
            .signatureVerificationFailed(reason: "Invalid signature"),
            .securityViolation(description: "Unauthorized file access")
        ]
        
        for error in errors {
            XCTAssertTrue(error.isValidationError, "Should be classified as validation error: \(error)")
        }
    }
    
    func test_PluginError_systemErrorCases() {
        let errors: [PluginError] = [
            .fileSystemError(underlying: MockError.testError),
            .permissionDenied(operation: "File read"),
            .networkError(underlying: MockError.testError),
            .unknownError(underlying: MockError.testError)
        ]
        
        for error in errors {
            XCTAssertTrue(error.isSystemError, "Should be classified as system error: \(error)")
        }
    }
    
    // MARK: - Error Severity Tests
    
    func test_PluginError_severityClassification() {
        let lowSeverityErrors: [PluginError] = [
            .pluginNotFound(id: "test"),
            .incompatibleVersion(required: "1.0", found: "1.1"),
            .timeoutExceeded(operation: "test", timeout: 1.0)
        ]
        
        let mediumSeverityErrors: [PluginError] = [
            .loadingFailed(reason: "test"),
            .executionFailed(reason: "test"),
            .resourceLimitExceeded(resource: "memory", limit: "100MB")
        ]
        
        let highSeverityErrors: [PluginError] = [
            .securityViolation(description: "test"),
            .registryCorrupted(reason: "test"),
            .unexpectedBehavior(description: "crash")
        ]
        
        for error in lowSeverityErrors {
            XCTAssertEqual(error.severity, .low, "Should be low severity: \(error)")
        }
        
        for error in mediumSeverityErrors {
            XCTAssertEqual(error.severity, .medium, "Should be medium severity: \(error)")
        }
        
        for error in highSeverityErrors {
            XCTAssertEqual(error.severity, .high, "Should be high severity: \(error)")
        }
    }
    
    // MARK: - Recovery Suggestions Tests
    
    func test_PluginError_recoverySuggestions() {
        let bundleNotFound = PluginError.bundleNotFound(path: "/test/path")
        let suggestions = bundleNotFound.recoverySuggestion
        XCTAssertTrue(suggestions?.contains("Check that the plugin file exists") == true)
        
        let loadingFailed = PluginError.loadingFailed(reason: "Missing dependency")
        let loadingSuggestion = loadingFailed.recoverySuggestion
        XCTAssertTrue(loadingSuggestion?.contains("Try reinstalling the plugin") == true)
        
        let securityViolation = PluginError.securityViolation(description: "File access")
        let securitySuggestion = securityViolation.recoverySuggestion
        XCTAssertTrue(securitySuggestion?.contains("Review plugin permissions") == true)
    }
    
    // MARK: - Localized Error Messages Tests
    
    func test_PluginError_localizedDescriptions() {
        let errors: [PluginError] = [
            .bundleNotFound(path: "/test/path"),
            .loadingFailed(reason: "test reason"),
            .pluginAlreadyRegistered(id: "com.test.plugin"),
            .securityViolation(description: "unauthorized access"),
            .resourceLimitExceeded(resource: "memory", limit: "100MB")
        ]
        
        for error in errors {
            let description = error.localizedDescription
            XCTAssertFalse(description.isEmpty, "Localized description should not be empty")
            XCTAssertFalse(description.contains("PluginError"), "Should not contain raw enum name")
        }
    }
    
    func test_PluginError_failureReasons() {
        let bundleError = PluginError.invalidBundleStructure(reason: "Missing metadata")
        XCTAssertNotNil(bundleError.failureReason)
        XCTAssertTrue(bundleError.failureReason?.lowercased().contains("bundle") == true)
        
        let loadingError = PluginError.initializationFailed(reason: "Setup failed")
        XCTAssertNotNil(loadingError.failureReason)
        XCTAssertTrue(loadingError.failureReason?.lowercased().contains("initialization") == true)
    }
    
    // MARK: - Error Propagation Tests
    
    func test_PluginError_underlyingErrorPropagation() {
        let underlyingError = MockError.testError
        let wrappedError = PluginError.fileSystemError(underlying: underlyingError)
        
        XCTAssertTrue(wrappedError.localizedDescription.lowercased().contains("file system"))
        
        // Test that underlying error information is preserved
        if case .fileSystemError(let underlying) = wrappedError {
            XCTAssertEqual(underlying as? MockError, underlyingError)
        } else {
            XCTFail("Error should maintain underlying error information")
        }
    }
    
    func test_PluginError_chainedErrorHandling() {
        let originalError = MockError.testError
        let metadataError = PluginError.metadataParsingFailed(underlying: originalError)
        let loadingError = PluginError.loadingFailed(reason: "Failed due to: \(metadataError.localizedDescription)")
        
        let description = loadingError.localizedDescription
        XCTAssertTrue(description.lowercased().contains("load"), "Expected 'load' in: \(description)")
        XCTAssertTrue(description.lowercased().contains("metadata"), "Expected 'metadata' in: \(description)")
    }
    
    // MARK: - Error Context Tests
    
    func test_PluginError_contextualInformation() {
        let pathError = PluginError.bundleNotFound(path: "/specific/test/path")
        XCTAssertTrue(pathError.localizedDescription.contains("/specific/test/path"))
        
        let versionError = PluginError.incompatibleVersion(required: "2.1.0", found: "1.5.0")
        let description = versionError.localizedDescription
        XCTAssertTrue(description.contains("2.1.0"))
        XCTAssertTrue(description.contains("1.5.0"))
        
        let resourceError = PluginError.resourceLimitExceeded(resource: "CPU", limit: "50%")
        let resourceDescription = resourceError.localizedDescription
        XCTAssertTrue(resourceDescription.contains("CPU"))
        XCTAssertTrue(resourceDescription.contains("50%"))
    }
    
    // MARK: - Error Logging Integration Tests
    
    func test_PluginError_loggingCompatibility() {
        let errors: [PluginError] = [
            .bundleNotFound(path: "/test"),
            .loadingFailed(reason: "test"),
            .securityViolation(description: "test")
        ]
        
        for error in errors {
            // Verify error can be converted to string for logging
            let logString = String(describing: error)
            XCTAssertFalse(logString.isEmpty)
            
            // Verify error has severity for log level determination
            let severity = error.severity
            XCTAssertTrue([.low, .medium, .high].contains(severity))
        }
    }
    
    // MARK: - Error Handling Strategy Tests
    
    func test_PluginError_handlingStrategies() {
        // Test retryable errors
        let retryableErrors: [PluginError] = [
            .timeoutExceeded(operation: "load", timeout: 5.0),
            .resourceLimitExceeded(resource: "memory", limit: "100MB"),
            .networkError(underlying: MockError.testError)
        ]
        
        for error in retryableErrors {
            XCTAssertTrue(error.isRetryable, "Should be retryable: \(error)")
        }
        
        // Test non-retryable errors
        let nonRetryableErrors: [PluginError] = [
            .securityViolation(description: "unauthorized"),
            .invalidMetadata(field: "version", reason: "malformed"),
            .signatureVerificationFailed(reason: "invalid signature")
        ]
        
        for error in nonRetryableErrors {
            XCTAssertFalse(error.isRetryable, "Should not be retryable: \(error)")
        }
    }
    
    // MARK: - Error User Presentation Tests
    
    func test_PluginError_userFriendlyMessages() {
        let userFacingErrors: [PluginError] = [
            .bundleNotFound(path: "/Users/test/plugin.bundle"),
            .incompatibleVersion(required: "2.0.0", found: "1.0.0"),
            .resourceLimitExceeded(resource: "memory", limit: "500MB")
        ]
        
        for error in userFacingErrors {
            let message = error.userFriendlyMessage
            XCTAssertFalse(message.isEmpty, "Should have user-friendly message")
            XCTAssertFalse(message.contains("PluginError"), "Should not contain technical enum names")
            XCTAssertFalse(message.contains("nil"), "Should not contain nil references")
        }
    }
    
    // MARK: - Error Analytics Integration Tests
    
    func test_PluginError_analyticsData() {
        let errors: [PluginError] = [
            .bundleNotFound(path: "/test"),
            .loadingFailed(reason: "dependency missing"),
            .securityViolation(description: "file access")
        ]
        
        for error in errors {
            let analyticsData = error.analyticsData
            
            XCTAssertNotNil(analyticsData["errorType"], "Should have error type")
            XCTAssertNotNil(analyticsData["severity"], "Should have severity")
            XCTAssertNotNil(analyticsData["category"], "Should have category")
            XCTAssertNotNil(analyticsData["isRetryable"], "Should have retry flag")
        }
    }
}

// MARK: - Mock Error Type

private enum MockError: Error, Equatable {
    case testError
    
    var localizedDescription: String {
        return "Mock test error"
    }
}