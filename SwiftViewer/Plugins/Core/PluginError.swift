import Foundation

/// Comprehensive error types for plugin operations
public enum PluginError: Error, LocalizedError {
    /// Bundle-related errors
    case bundleNotFound(String)
    case invalidBundle(String)
    case missingMetadata
    case corruptedMetadata(String)
    
    /// Loading errors
    case missingExecutable
    case loadingFailed(String)
    case incompatibleVersion(required: String, found: String)
    case unsupportedCapability(String)
    
    /// Runtime errors
    case initializationFailed(String)
    case executionFailed(String)
    case resourceLimitExceeded(String)
    case securityViolation(String)
    
    /// Registry errors
    case pluginAlreadyRegistered(String)
    case pluginNotFound(String)
    case dependencyMissing(String)
    
    /// Validation errors
    case signatureValidationFailed
    case integrityCheckFailed
    case sandboxViolation(String)
    
    /// System errors
    case systemError(Error)
    case permissionDenied(String)
    case networkError(String)
    
    // MARK: - LocalizedError Implementation
    
    public var errorDescription: String? {
        switch self {
        // Bundle errors
        case .bundleNotFound(let path):
            return "Plugin bundle not found at path: \(path)"
        case .invalidBundle(let reason):
            return "Invalid plugin bundle: \(reason)"
        case .missingMetadata:
            return "Plugin metadata file (plugin.json) is missing"
        case .corruptedMetadata(let reason):
            return "Plugin metadata is corrupted: \(reason)"
            
        // Loading errors
        case .missingExecutable:
            return "Plugin executable file is missing"
        case .loadingFailed(let reason):
            return "Failed to load plugin: \(reason)"
        case .incompatibleVersion(let required, let found):
            return "Plugin version incompatible. Required: \(required), Found: \(found)"
        case .unsupportedCapability(let capability):
            return "Unsupported plugin capability: \(capability)"
            
        // Runtime errors
        case .initializationFailed(let reason):
            return "Plugin initialization failed: \(reason)"
        case .executionFailed(let reason):
            return "Plugin execution failed: \(reason)"
        case .resourceLimitExceeded(let resource):
            return "Plugin exceeded resource limit: \(resource)"
        case .securityViolation(let violation):
            return "Security violation detected: \(violation)"
            
        // Registry errors
        case .pluginAlreadyRegistered(let id):
            return "Plugin already registered: \(id)"
        case .pluginNotFound(let id):
            return "Plugin not found: \(id)"
        case .dependencyMissing(let dependency):
            return "Required dependency missing: \(dependency)"
            
        // Validation errors
        case .signatureValidationFailed:
            return "Plugin signature validation failed"
        case .integrityCheckFailed:
            return "Plugin integrity check failed"
        case .sandboxViolation(let violation):
            return "Plugin sandbox violation: \(violation)"
            
        // System errors
        case .systemError(let error):
            return "System error: \(error.localizedDescription)"
        case .permissionDenied(let operation):
            return "Permission denied for operation: \(operation)"
        case .networkError(let reason):
            return "Network error: \(reason)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .bundleNotFound, .invalidBundle, .missingMetadata, .corruptedMetadata:
            return "The plugin bundle is invalid or cannot be accessed"
        case .missingExecutable, .loadingFailed, .incompatibleVersion, .unsupportedCapability:
            return "The plugin cannot be loaded due to compatibility issues"
        case .initializationFailed, .executionFailed, .resourceLimitExceeded, .securityViolation:
            return "The plugin failed to run properly"
        case .pluginAlreadyRegistered, .pluginNotFound, .dependencyMissing:
            return "Plugin registry operation failed"
        case .signatureValidationFailed, .integrityCheckFailed, .sandboxViolation:
            return "Plugin security validation failed"
        case .systemError, .permissionDenied, .networkError:
            return "System-level error occurred"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .bundleNotFound:
            return "Verify the plugin bundle exists and is accessible"
        case .invalidBundle, .missingMetadata, .corruptedMetadata:
            return "Check if the plugin bundle is properly formatted"
        case .missingExecutable:
            return "Ensure the plugin bundle contains a valid executable"
        case .loadingFailed:
            return "Check plugin compatibility with current application version"
        case .incompatibleVersion:
            return "Update the plugin to a compatible version"
        case .unsupportedCapability:
            return "Use a plugin with supported capabilities"
        case .initializationFailed, .executionFailed:
            return "Check plugin configuration and try reloading"
        case .resourceLimitExceeded:
            return "Restart the application or increase resource limits"
        case .securityViolation, .sandboxViolation:
            return "Use a trusted plugin from a verified source"
        case .pluginAlreadyRegistered:
            return "Unregister the existing plugin before registering again"
        case .pluginNotFound:
            return "Ensure the plugin is installed and registered"
        case .dependencyMissing:
            return "Install the required dependencies"
        case .signatureValidationFailed, .integrityCheckFailed:
            return "Download the plugin from the official source"
        case .permissionDenied:
            return "Check application permissions and security settings"
        case .systemError, .networkError:
            return "Check system resources and network connectivity"
        }
    }
    
    // MARK: - Error Classification
    
    /// Whether this error is recoverable
    public var isRecoverable: Bool {
        switch self {
        case .bundleNotFound, .invalidBundle, .missingMetadata, .corruptedMetadata,
             .missingExecutable, .incompatibleVersion, .signatureValidationFailed,
             .integrityCheckFailed:
            return false
        case .loadingFailed, .initializationFailed, .executionFailed,
             .resourceLimitExceeded, .pluginNotFound, .dependencyMissing,
             .permissionDenied, .networkError:
            return true
        case .unsupportedCapability, .securityViolation, .pluginAlreadyRegistered,
             .sandboxViolation:
            return false
        case .systemError:
            return true // Depends on underlying error, but assume recoverable
        }
    }
    
    /// Error severity level
    public enum Severity {
        case low, medium, high, critical
    }
    
    public var severity: Severity {
        switch self {
        case .bundleNotFound, .pluginNotFound:
            return .low
        case .invalidBundle, .missingMetadata, .corruptedMetadata, .missingExecutable,
             .loadingFailed, .incompatibleVersion, .unsupportedCapability,
             .initializationFailed, .executionFailed, .pluginAlreadyRegistered,
             .dependencyMissing, .permissionDenied, .networkError:
            return .medium
        case .resourceLimitExceeded, .systemError:
            return .high
        case .securityViolation, .signatureValidationFailed, .integrityCheckFailed,
             .sandboxViolation:
            return .critical
        }
    }
}