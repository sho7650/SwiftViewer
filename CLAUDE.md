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