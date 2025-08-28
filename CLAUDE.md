# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwiftViewer is a macOS photo viewer application built with Swift 6 and SwiftUI, targeting macOS 14.0+. The app provides comprehensive image viewing capabilities with slideshow functionality, folder browsing, and performance-optimized image caching.

## Build and Development Commands

### Building the Project

```bash
# Build for Debug
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -configuration Debug build

# Build for Release
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -configuration Release build

# Clean build folder
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer clean
```

### Running Tests

```bash
# Run all tests
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -sdk macosx test

# Run specific test target
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -sdk macosx -only-testing:SwiftViewerTests test
```

### SwiftLint (when configured)

```bash
# Run SwiftLint
swiftlint

# Auto-fix violations
swiftlint --fix
```

## Architecture

### MVVM Pattern

- **Views**: SwiftUI views in `SwiftViewer/Views/`
- **ViewModels**: Observable objects managing view state and business logic
- **Models**: Data structures representing domain objects
- **Repositories**: Data access layer with protocol-based abstraction
- **Services**: Reusable business logic components

### Dependency Injection

- Protocol-based dependency injection for testability
- Dependencies injected through initializers
- Mock implementations for testing

### Key Components (To Be Implemented)

- **ImageLoader**: Asynchronous image loading with NSImage/CGImage support
- **ImageCache**: LRU cache with configurable memory limits
- **FileManager Extension**: Directory browsing and file filtering
- **SettingsManager**: UserDefaults wrapper for app preferences
- **SlideShowController**: Timer-based image rotation logic

## Test-Driven Development (TDD) Workflow

1. **Write failing test first** in appropriate test file
2. **Implement minimal code** to make test pass
3. **Refactor** while keeping tests green
4. **Commit** with both test and implementation

### Test Organization

- Unit tests: `SwiftViewerTests/`
- UI tests: `SwiftViewerUITests/`
- Test naming: `test_methodName_expectedBehavior_whenCondition()`

## Git Workflow (GitHub Flow)

### Creating Features

```bash
# Create feature branch
git checkout -b feature/feature-name

# After implementation
git add .
git commit -m "feat: implement feature description"
git push -u origin feature/feature-name
```

### Pull Request Process

1. Create PR with detailed description
2. Ensure all tests pass
3. Code coverage must be 75%+
4. Request review before merge

## Cipher MCP Integration

Use Cipher MCP to record:

- Architecture decisions
- Implementation plans
- Test results
- Performance metrics
- Bug fixes and resolutions

Session ID: `swiftviewer_project`

## Key Requirements

### Supported Image Formats

- JPEG (.jpg, .jpeg)
- HEIC (.heic)
- GIF (.gif) with animation support
- Future: RAW formats via plugin system

### Performance Targets

- Support 10,000+ images in a folder
- Cache response time: <10ms for cached images
- Memory usage: User-configurable limits
- Preload: 10-1000 images (configurable)

### UI/UX Features

- Fullscreen mode (F key toggle)
- Slideshow with configurable intervals (1-300 seconds)
- Keyboard navigation (arrow keys)
- Sort options (name, date, size, random)
- Progress bar with clickable navigation
- Blur effect for non-image areas

### Entitlements Required

- `com.apple.security.app-sandbox`
- `com.apple.security.files.user-selected.read-only`
- `com.apple.security.files.bookmarks.app-scope`

## Development Guidelines

### File Organization

- One responsibility per file
- Protocol definitions in separate files
- Extensions grouped logically
- Test files mirror source structure

### Code Style

- Follow Swift API Design Guidelines
- Use async/await for asynchronous operations
- Prefer value types where appropriate
- Document public APIs

### Error Handling

- Use custom error types
- Handle corrupted images gracefully
- Request permissions for protected folders
- Log errors appropriately (no print statements)

## Debugging

### Enable Debug Logging

Set UserDefaults key `debugLoggingEnabled` to true

### Common Issues

- **Sandbox violations**: Check entitlements
- **Memory issues**: Review cache configuration
- **Performance**: Profile with Instruments

## Claude Code Behavioral Rules

### CRITICAL: Implementation Prevention Rules

#### Mandatory Plan Mode Usage

**ALWAYS use Plan Mode for these instruction types:**

- "方法を提示" / "提案" / "手順を教え"
- "どうすれば" / "アプローチを" / "戦略を"
- Any request for proposals, methods, or approaches

**Plan Mode Process:**

1. Analyze the request thoroughly
2. Present detailed plan with ExitPlanMode tool
3. Wait for explicit user approval
4. ONLY THEN proceed with implementation

#### Absolute Prohibitions

**NEVER do these without explicit user instruction:**

- Automatic implementation after presenting methods
- File modifications during planning phase
- "While I'm at it" optimizations
- Adding features not specifically requested

#### Two-Phase Confirmation Required

```
Phase 1: Planning (Plan Mode MANDATORY)
- Problem analysis
- Solution proposal
- Implementation steps
- ExitPlanMode call → User approval required

Phase 2: Implementation (ONLY after approval)
- Execute approved plan exactly
- No deviations from approved scope
- No additional "improvements"
```

#### Emergency Stop Triggers

**Immediately cease all activity when detecting:**

- "勝手に" / "無断で" / "指示していない"
- "やめろ" / "停止" / "待て" / "まて"

#### Instruction Classification

```
Proposal-type (→ Plan Mode REQUIRED):
- "方法を提示" → Planning phase
- "手順を説明" → Planning phase
- "アプローチを提案" → Planning phase

Implementation-type (→ Direct execution OK):
- "修正しろ" → Direct implementation
- "実装しろ" → Direct implementation
- "コミットしろ" → Direct implementation
```

#### Verification Checklist

Before ANY file modification, verify:

- ✓ User gave explicit implementation instruction?
- ✓ Plan was approved via ExitPlanMode?
- ✓ Change is within approved scope?
- ✓ No unauthorized additions being made?

**If ANY answer is NO → STOP immediately**

## SwiftViewer Feature Extension Plan 2025

### Implementation Strategy (4-Phase Approach)

SwiftViewer will be enhanced through a systematic 4-phase implementation plan focusing on settings-driven configurability, plugin extensibility, and SwiftUI best practices compliance.

#### Phase 1: Settings Foundation (Weeks 1-2)

**Objective:** Expand settings system to support all planned features

**Key Deliverables:**

- Extend `SettingsManagerProtocol` with 7 new configuration properties
- Update `SettingsView` UI for dynamic real-time configuration changes
- Implement menu checkmarks for visual selection feedback
- Ensure settings persistence and live application

**New Settings:**

- `autoHideDelay: TimeInterval` (1.0-60.0 seconds)
- `animationDurations: [AnimationType: TimeInterval]`
- `blurRadius: Double` and `blurOpacity: Double`
- `loggingLevel: LogLevel`
- `slideShowCustomIntervals: [TimeInterval]`
- `windowPositioning: WindowPosition`

#### Phase 2: Core UI Features (Weeks 3-4)

**Objective:** Implement primary user experience improvements

**Key Features:**

- Configurable auto-hide controls (1-60 second delay)
- Controller blur/opacity visual effects system
- Debug mode conditional UI element visibility
- Basic window positioning (Always on Top/Bottom)

#### Phase 3: Advanced Features (Weeks 5-6)

**Objective:** Fine-grained control and customization capabilities

**Implementation Focus:**

- Unified animation duration management system (13 `.easeInOut` locations)
- Slideshow interval selection: [1,2,3,5,10,20,30,60,120,300,600,1200,1800] seconds
- Window menu extensions: "Move & Resize", "Full Screen Tile"
- Image display standardization (Fit mode only, remove resize options)

#### Phase 4: Plugin Architecture (Weeks 7-8+)

**Objective:** Future extensibility through plugin system

**Architectural Components:**

- Transition effects framework with plugin interface
- Safe plugin loading mechanism
- Built-in transition implementations
- Plugin API specification for third-party extensions

### Technical Standards

- **Platform:** Swift 6, SwiftUI, macOS 14.0+
- **Architecture:** MVVM + Dependency Injection (maintained)
- **Testing:** TDD with 75%+ coverage requirement
- **Performance:** Support 10,000+ images capability
- **Compliance:** Full Context7 SwiftUI best practices adherence

### Quality Gates

Each phase requires:

- Functional verification of all deliverables
- Regression testing of existing functionality
- Performance benchmark validation
- Architecture compliance review

This systematic approach ensures SwiftViewer evolves into a highly customizable, extensible macOS application while maintaining code quality and architectural integrity.

---

SwiftViewer Plugin Architecture: Testable Minimal Units Implementation Plan │
│ │
│ Strategic Approach: Atomic Development Units │
│ │
│ Based on Context7 SwiftUI best practices and Swift Package Manager plugin architecture patterns, I've broken down │
│ the plugin system into 22 individually testable atomic units, each deliverable in 2-4 hours with immediate │
│ validation. │
│ │
│ Phase 1: Foundation Infrastructure (Units 1-6) │
│ │
│ Estimated Time: 12-16 hours │
│ │
│ Unit 1: Plugin Protocol Foundation (2-3 hours) │
│ │
│ Test: Protocol conformance validation │
│ - Create PluginProtocol with required methods │
│ - Define PluginCapability enum (transition effects, filters, etc.) │
│ - Implement basic protocol validation tests │
│ Success Criteria: Protocol compiles, tests pass, interface documented │
│ │
│ Unit 2: Plugin Metadata Structure (2 hours) │
│ │
│ Test: Metadata parsing and validation │
│ - Create PluginMetadata struct with name, version, capabilities │
│ - Implement JSON serialization/deserialization │
│ - Test metadata validation edge cases │
│ Success Criteria: Metadata loads correctly, validation catches malformed data │
│ │
│ Unit 3: Plugin Bundle Detection (3 hours) │
│ │
│ Test: Bundle discovery in file system │
│ - Implement PluginDiscoveryService to scan plugin directories │
│ - Support .plugin bundle format based on SPM patterns │
│ - Test with mock plugin bundles │
│ Success Criteria: Service finds valid plugins, ignores invalid ones │
│ │
│ Unit 4: Safe Plugin Loading Infrastructure (3-4 hours) │
│ │
│ Test: Secure plugin instantiation │
│ - Create PluginLoader with sandboxing support │
│ - Implement dynamic loading with error handling │
│ - Test loading failure scenarios │
│ Success Criteria: Plugins load safely, failures don't crash app │
│ │
│ Unit 5: Plugin Registry Service (2-3 hours) │
│ │
│ Test: Plugin lifecycle management │
│ - Implement plugin registration/deregistration │
│ - Create plugin lookup by capability │
│ - Test concurrent access scenarios │
│ Success Criteria: Registry manages plugins correctly, thread-safe │
│ │
│ Unit 6: Error Handling Foundation (1-2 hours) │
│ │
│ Test: Comprehensive error scenarios │
│ - Define PluginError enum with all failure cases │
│ - Implement error propagation patterns │
│ - Test error message localization │
│ Success Criteria: All errors handled gracefully with user-friendly messages │
│ │
│ Phase 2: Core Plugin Interfaces (Units 7-12) │
│ │
│ Estimated Time: 12-16 hours │
│ │
│ Unit 7: Transition Effect Plugin Interface (2-3 hours) │
│ │
│ Test: Transition animation contracts │
│ - Define TransitionPluginProtocol with SwiftUI integration │
│ - Create animation parameter structures │
│ - Test interface with mock transition │
│ Success Criteria: Interface supports SwiftUI transitions, parameters validated │
│ │
│ Unit 8: Built-in Transition: Fade (2 hours) │
│ │
│ Test: Smooth fade transition implementation │
│ - Implement fade transition as reference plugin │
│ - Test with various durations and curves │
│ - Validate SwiftUI integration │
│ Success Criteria: Fade works smoothly, configurable parameters │
│ │
│ Unit 9: Built-in Transition: Slide (2-3 hours) │
│ │
│ Test: Directional slide animations │
│ - Implement slide transitions (left, right, up, down) │
│ - Test direction handling and edge cases │
│ - Performance validation with large images │
│ Success Criteria: All slide directions work, no performance degradation │
│ │
│ Unit 10: Built-in Transition: Scale (2 hours) │
│ │
│ Test: Scale transition with proper anchoring │
│ - Implement scale transition with zoom effects │
│ - Test anchor point handling │
│ - Validate aspect ratio preservation │
│ Success Criteria: Scale transitions maintain image quality, configurable anchor │
│ │
│ Unit 11: Plugin Configuration UI Framework (3-4 hours) │
│ │
│ Test: SwiftUI configuration interfaces │
│ - Create PluginConfigurationView protocol │
│ - Implement settings binding patterns │
│ - Test configuration persistence │
│ Success Criteria: Plugins can expose settings UI, changes persist │
│ │
│ Unit 12: Settings Integration Bridge (2-3 hours) │
│ │
│ Test: Plugin settings in main settings │
│ - Integrate plugin configs into main SettingsView │
│ - Test live updates and validation │
│ - Ensure settings isolation between plugins │
│ Success Criteria: Plugin settings appear in app, isolated and validated │
│ │
│ Phase 3: Runtime Integration (Units 13-18) │
│ │
│ Estimated Time: 12-16 hours │
│ │
│ Unit 13: Plugin Execution Context (3-4 hours) │
│ │
│ Test: Context isolation and resource management │
│ - Create execution context with resource limits │
│ - Implement context switching for plugins │
│ - Test memory and CPU constraints │
│ Success Criteria: Plugins execute in controlled environment, resource-limited │
│ │
│ Unit 14: Image Processing Plugin Support (2-3 hours) │
│ │
│ Test: Image data handling for plugins │
│ - Create image processing pipeline interfaces │
│ - Test with various image formats (JPEG, HEIC, GIF) │
│ - Validate memory efficiency │
│ Success Criteria: Plugins can process all supported formats efficiently │
│ │
│ Unit 15: Plugin Event System (2-3 hours) │
│ │
│ Test: Plugin lifecycle and image events │
│ - Implement event bus for plugin communication │
│ - Define standard events (imageChanged, slideShowStarted, etc.) │
│ - Test event propagation and handling │
│ Success Criteria: Plugins receive relevant events, no performance impact │
│ │
│ Unit 16: SwiftUI View Integration (3-4 hours) │
│ │
│ Test: Plugin views in main UI hierarchy │
│ - Create plugin view container system │
│ - Implement SwiftUI view injection patterns │
│ - Test view lifecycle and state management │
│ Success Criteria: Plugin views integrate seamlessly, proper lifecycle │
│ │
│ Unit 17: Animation System Integration (2-3 hours) │
│ │
│ Test: Plugin animations in slideshow │
│ - Integrate plugin transitions with slideshow controller │
│ - Test timing and synchronization │
│ - Validate smooth handoff between transitions │
│ Success Criteria: Plugin transitions work in slideshow, timing accurate │
│ │
│ Unit 18: Performance Monitoring (1-2 hours) │
│ │
│ Test: Plugin performance impact measurement │
│ - Implement performance metrics collection │
│ - Test with slow/resource-heavy plugins │
│ - Create performance warning system │
│ Success Criteria: Performance impact measurable, warnings triggered appropriately │
│ │
│ Phase 4: Security & Validation (Units 19-22) │
│ │
│ Estimated Time: 8-10 hours │
│ │
│ Unit 19: Plugin Validation System (3-4 hours) │
│ │
│ Test: Code signature and integrity validation │
│ - Implement plugin signing validation (future-ready) │
│ - Create basic integrity checks │
│ - Test with modified/corrupted plugins │
│ Success Criteria: Only valid plugins load, corruption detected │
│ │
│ Unit 20: Sandboxing Implementation (2-3 hours) │
│ │
│ Test: Plugin security boundaries │
│ - Implement file system access restrictions │
│ - Test network access blocking │
│ - Validate resource usage limits │
│ Success Criteria: Plugins cannot access restricted resources │
│ │
│ Unit 21: Plugin Manager UI (2-3 hours) │
│ │
│ Test: User plugin management interface │
│ - Create plugin list view with enable/disable │
│ - Implement plugin installation workflow │
│ - Test plugin removal and cleanup │
│ Success Criteria: Users can manage plugins easily, safe installation/removal │
│ │
│ Unit 22: Migration & Compatibility (1-2 hours) │
│ │
│ Test: Plugin version compatibility │
│ - Implement plugin version checking │
│ - Create migration system for plugin updates │
│ - Test backward compatibility scenarios │
│ Success Criteria: Version conflicts handled gracefully, smooth updates │
│ │
│ Design Pattern Optimizations (Context7-Based) │
│ │
│ 1. Observable Pattern: Use @Observable for plugin state management │
│ │
│ 2. Dependency Injection: Extend DependencyContainer for plugin services │
│ │
│ 3. Protocol Composition: Combine multiple plugin capabilities cleanly │
│ │
│ 4. SwiftUI Environment: Plugin settings via environment values │
│ │
│ 5. Actor Isolation: @MainActor for UI-related plugin operations │
│ │
│ TDD Workflow Per Unit │
│ │
│ 1. Write Tests First: Create test cases defining unit behavior │
│ 2. Red Phase: Confirm tests fail with minimal implementation │
│ 3. Green Phase: Implement minimal code to pass tests │
│ 4. Refactor: Improve implementation while maintaining tests │
│ 5. Integration: Verify unit works with existing system │
│ 6. Git Workflow: Feature branch → tests pass → commit → PR │
│ │
│ Success Metrics │
│ │
│ - Unit Size: Each unit completable in single session (2-4 hours) │
│ - Test Coverage: Minimum 90% coverage per unit │
│ - Integration: Each unit integrates without breaking existing functionality │
│ - Performance: No unit adds >10ms to app launch or >5ms to image transitions │
│ - Memory: Plugin system uses <50MB additional memory │
│ │
│ Total Effort: 44-58 hours across 22 testable units │
│ │
│ This approach transforms the large plugin architecture into digestible, testable increments that can be developed,│
│ tested, and validated independently while following SwiftUI best practices and maintaining system stability.
