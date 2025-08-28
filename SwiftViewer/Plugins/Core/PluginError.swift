import Foundation

/// Comprehensive error types for plugin operations
public enum PluginError: Error, LocalizedError {
    // MARK: - Bundle Errors
    case bundleNotFound(path: String)
    case invalidBundleStructure(reason: String)
    case metadataParsingFailed(underlying: Error)
    
    // MARK: - Loading Errors
    case loadingFailed(reason: String)
    case initializationFailed(reason: String)
    case dependencyNotFound(name: String)
    case incompatibleVersion(required: String, found: String)
    case missingExecutable(bundlePath: String)
    
    // MARK: - Runtime Errors
    case executionFailed(reason: String)
    case resourceLimitExceeded(resource: String, limit: String)
    case timeoutExceeded(operation: String, timeout: TimeInterval)
    case unexpectedBehavior(description: String)
    
    // MARK: - Registry Errors
    case pluginAlreadyRegistered(id: String)
    case pluginNotFound(id: String)
    case registryCorrupted(reason: String)
    
    // MARK: - Validation Errors
    case invalidMetadata(field: String, reason: String)
    case signatureVerificationFailed(reason: String)
    case securityViolation(description: String)
    
    // MARK: - System Errors
    case fileSystemError(underlying: Error)
    case permissionDenied(operation: String)
    case networkError(underlying: Error)
    case unknownError(underlying: Error)
    
    // MARK: - LocalizedError Implementation
    
    public var errorDescription: String? {
        switch self {
        // Bundle errors
        case .bundleNotFound(let path):
            return "Plugin bundle not found at path: \(path)"
        case .invalidBundleStructure(let reason):
            return "Invalid plugin bundle structure: \(reason)"
        case .metadataParsingFailed(let underlying):
            return "Failed to parse plugin metadata: \(underlying.localizedDescription)"
            
        // Loading errors
        case .loadingFailed(let reason):
            return "Failed to load plugin: \(reason)"
        case .initializationFailed(let reason):
            return "Plugin initialization failed: \(reason)"
        case .dependencyNotFound(let name):
            return "Required dependency not found: \(name)"
        case .incompatibleVersion(let required, let found):
            return "Plugin version incompatible. Required: \(required), Found: \(found)"
        case .missingExecutable(let bundlePath):
            return "Plugin executable missing in bundle: \(bundlePath)"
            
        // Runtime errors
        case .executionFailed(let reason):
            return "Plugin execution failed: \(reason)"
        case .resourceLimitExceeded(let resource, let limit):
            return "Plugin exceeded \(resource) limit of \(limit)"
        case .timeoutExceeded(let operation, let timeout):
            return "Plugin \(operation) operation timed out after \(timeout) seconds"
        case .unexpectedBehavior(let description):
            return "Plugin exhibited unexpected behavior: \(description)"
            
        // Registry errors
        case .pluginAlreadyRegistered(let id):
            return "Plugin already registered: \(id)"
        case .pluginNotFound(let id):
            return "Plugin not found: \(id)"
        case .registryCorrupted(let reason):
            return "Plugin registry corrupted: \(reason)"
            
        // Validation errors
        case .invalidMetadata(let field, let reason):
            return "Invalid metadata field '\(field)': \(reason)"
        case .signatureVerificationFailed(let reason):
            return "Plugin signature verification failed: \(reason)"
        case .securityViolation(let description):
            return "Security violation detected: \(description)"
            
        // System errors
        case .fileSystemError(let underlying):
            return "File system error: \(underlying.localizedDescription)"
        case .permissionDenied(let operation):
            return "Permission denied for operation: \(operation)"
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .unknownError(let underlying):
            return "Unknown error occurred: \(underlying.localizedDescription)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .bundleNotFound, .metadataParsingFailed:
            return "The plugin bundle structure is invalid or cannot be accessed"
        case .invalidBundleStructure:
            return "The plugin bundle structure is invalid or corrupted"
        case .loadingFailed, .dependencyNotFound, .incompatibleVersion, .missingExecutable:
            return "The plugin cannot be loaded due to compatibility or dependency issues"
        case .initializationFailed:
            return "The plugin initialization failed due to configuration or setup issues"
        case .executionFailed, .resourceLimitExceeded, .timeoutExceeded, .unexpectedBehavior:
            return "The plugin failed during runtime execution"
        case .pluginAlreadyRegistered, .pluginNotFound, .registryCorrupted:
            return "Plugin registry operation failed"
        case .invalidMetadata, .signatureVerificationFailed, .securityViolation:
            return "Plugin security or validation check failed"
        case .fileSystemError, .permissionDenied, .networkError, .unknownError:
            return "System-level error occurred"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .bundleNotFound:
            return "Check that the plugin file exists and is accessible"
        case .invalidBundleStructure, .metadataParsingFailed:
            return "Verify the plugin bundle is properly formatted and contains valid metadata"
        case .loadingFailed, .initializationFailed:
            return "Try reinstalling the plugin or check compatibility"
        case .dependencyNotFound:
            return "Install the required dependencies and try again"
        case .incompatibleVersion:
            return "Update the plugin to a compatible version"
        case .missingExecutable:
            return "Ensure the plugin bundle contains a valid executable file"
        case .executionFailed:
            return "Check plugin configuration and restart the application"
        case .resourceLimitExceeded:
            return "Increase resource limits or restart the application"
        case .timeoutExceeded:
            return "Check system performance and try increasing timeout limits"
        case .unexpectedBehavior:
            return "Report this issue to the plugin developer"
        case .pluginAlreadyRegistered:
            return "Unregister the existing plugin before registering again"
        case .pluginNotFound:
            return "Ensure the plugin is installed and properly registered"
        case .registryCorrupted:
            return "Restart the application to reset the plugin registry"
        case .invalidMetadata:
            return "Check the plugin metadata file for correct formatting"
        case .signatureVerificationFailed:
            return "Download the plugin from the official source"
        case .securityViolation:
            return "Review plugin permissions and use trusted plugins only"
        case .fileSystemError, .permissionDenied:
            return "Check file permissions and application security settings"
        case .networkError:
            return "Check network connectivity and try again"
        case .unknownError:
            return "Restart the application and contact support if the issue persists"
        }
    }
    
    // MARK: - Error Classification
    
    /// Error severity level
    public enum Severity {
        case low, medium, high
    }
    
    public var severity: Severity {
        switch self {
        case .bundleNotFound, .pluginNotFound, .incompatibleVersion, .timeoutExceeded:
            return .low
        case .loadingFailed, .initializationFailed, .dependencyNotFound, .executionFailed,
             .resourceLimitExceeded, .pluginAlreadyRegistered, .missingExecutable,
             .invalidBundleStructure, .metadataParsingFailed, .invalidMetadata,
             .permissionDenied, .fileSystemError, .networkError, .unknownError:
            return .medium
        case .securityViolation, .signatureVerificationFailed, .registryCorrupted,
             .unexpectedBehavior:
            return .high
        }
    }
    
    /// Whether this error can be retried
    public var isRetryable: Bool {
        switch self {
        case .timeoutExceeded, .resourceLimitExceeded, .networkError:
            return true
        case .securityViolation, .invalidMetadata, .signatureVerificationFailed:
            return false
        case .loadingFailed, .initializationFailed, .executionFailed, .fileSystemError,
             .permissionDenied, .unknownError:
            return true
        case .bundleNotFound, .invalidBundleStructure, .metadataParsingFailed,
             .dependencyNotFound, .incompatibleVersion, .missingExecutable,
             .unexpectedBehavior, .pluginAlreadyRegistered, .pluginNotFound,
             .registryCorrupted:
            return false
        }
    }
    
    // MARK: - Error Category Classification
    
    public var isBundleError: Bool {
        switch self {
        case .bundleNotFound, .invalidBundleStructure, .metadataParsingFailed:
            return true
        default:
            return false
        }
    }
    
    public var isLoadingError: Bool {
        switch self {
        case .loadingFailed, .initializationFailed, .dependencyNotFound, .incompatibleVersion:
            return true
        default:
            return false
        }
    }
    
    public var isRuntimeError: Bool {
        switch self {
        case .executionFailed, .resourceLimitExceeded, .timeoutExceeded, .unexpectedBehavior:
            return true
        default:
            return false
        }
    }
    
    public var isRegistryError: Bool {
        switch self {
        case .pluginAlreadyRegistered, .pluginNotFound, .registryCorrupted:
            return true
        default:
            return false
        }
    }
    
    public var isValidationError: Bool {
        switch self {
        case .invalidMetadata, .missingExecutable, .signatureVerificationFailed, .securityViolation:
            return true
        default:
            return false
        }
    }
    
    public var isSystemError: Bool {
        switch self {
        case .fileSystemError, .permissionDenied, .networkError, .unknownError:
            return true
        default:
            return false
        }
    }
    
    // MARK: - User-Friendly Messages
    
    public var userFriendlyMessage: String {
        switch self {
        case .bundleNotFound:
            return "The plugin could not be found. Please check that the plugin is properly installed."
        case .invalidBundleStructure:
            return "The plugin appears to be corrupted. Please reinstall the plugin."
        case .metadataParsingFailed:
            return "The plugin information could not be read. Please try reinstalling the plugin."
        case .loadingFailed:
            return "The plugin could not be loaded. Please check compatibility with your application version."
        case .initializationFailed:
            return "The plugin failed to start properly. Please try restarting the application."
        case .dependencyNotFound:
            return "The plugin requires additional components that are not installed."
        case .incompatibleVersion:
            return "This plugin version is not compatible with your application. Please update the plugin."
        case .missingExecutable:
            return "The plugin is incomplete and cannot run. Please reinstall the plugin."
        case .executionFailed:
            return "The plugin encountered an error while running. Please try again."
        case .resourceLimitExceeded:
            return "The plugin is using too many system resources. Please restart the application."
        case .timeoutExceeded:
            return "The plugin operation took too long to complete. Please try again."
        case .unexpectedBehavior:
            return "The plugin behaved unexpectedly. Please report this issue."
        case .pluginAlreadyRegistered:
            return "This plugin is already installed."
        case .pluginNotFound:
            return "The requested plugin is not installed."
        case .registryCorrupted:
            return "Plugin database is corrupted. Please restart the application."
        case .invalidMetadata:
            return "The plugin information is invalid. Please reinstall the plugin."
        case .signatureVerificationFailed:
            return "The plugin could not be verified as safe. Please download from official sources."
        case .securityViolation:
            return "The plugin attempted unauthorized actions and was blocked."
        case .fileSystemError:
            return "A file system error occurred. Please check disk space and permissions."
        case .permissionDenied:
            return "Permission denied. Please check application security settings."
        case .networkError:
            return "A network error occurred. Please check your internet connection."
        case .unknownError:
            return "An unexpected error occurred. Please try again or contact support."
        }
    }
    
    // MARK: - Analytics Data
    
    public var analyticsData: [String: Any] {
        return [
            "errorType": String(describing: self).components(separatedBy: "(").first ?? "unknown",
            "severity": String(describing: severity),
            "category": errorCategory,
            "isRetryable": isRetryable
        ]
    }
    
    private var errorCategory: String {
        if isBundleError { return "bundle" }
        if isLoadingError { return "loading" }
        if isRuntimeError { return "runtime" }
        if isRegistryError { return "registry" }
        if isValidationError { return "validation" }
        if isSystemError { return "system" }
        return "unknown"
    }
}