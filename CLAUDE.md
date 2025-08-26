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
