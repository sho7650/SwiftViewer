# SwiftViewer

[![Swift CI](https://github.com/sho7650/SwiftViewer/actions/workflows/swift.yml/badge.svg)](https://github.com/sho7650/SwiftViewer/actions/workflows/swift.yml)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2026.0%2B-blue.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A modern, high-performance photo viewer for macOS built with Swift 6 and SwiftUI. SwiftViewer provides a clean, intuitive interface for browsing large image collections, with a slideshow, configurable transitions, and a Liquid Glass control bar that stays out of your way.

## ✨ Features

### 🖼️ Image Viewing
- **Formats**: JPEG (`.jpg`, `.jpeg`), HEIC (`.heic`), and animated GIF (`.gif`)
- **Built for large folders**: designed to handle 10,000+ images in a single directory
- **Actor-isolated image pipeline**: ImageIO downsampling behind an `NSCache`, with neighbouring images preloaded in the background
- **Configurable cache**: memory ceiling as a share of system RAM, image count limit, and preload window
- **Blurred backdrop**: non-image areas are filled with a blurred copy of the current photo (radius and opacity adjustable)

### 🎬 Slideshow
- **13 preset intervals**: 1s, 2s, 3s, 5s, 10s, 20s, 30s, 1m, 2m, 5m, 10m, 20m, 30m
- **Six transitions**: Cross Dissolve, Zoom In, Zoom Out, Blur Replace, Blur Replace (Expand), None
- **Adjustable transition duration**: 0.1–5.0 seconds
- **Repeat mode**: loop continuously or stop at the last image
- **Keyboard control**: Space to play/pause, arrow keys to navigate

### 🎛️ User Interface
- **Liquid Glass controls**: native `.glass` / `.glassProminent` styling, with Play/Pause raised as the primary action
- **Auto-hide controls**: the player fades out after a configurable delay (1–60 s, default 3 s) and returns on activity. Arrow-key navigation is deliberately exempt, so keyboard browsing stays distraction-free
- **Progress bar**: click to jump, or drag to scrub — navigation commits once on release, so scrubbing a huge folder never floods the image pipeline
- **Fullscreen**: ⌘F
- **Window layering**: keep the window always on top or always on bottom

### 📁 Organization
- **Sort options**:
  - Name (A–Z / Z–A)
  - Date created (oldest / newest first)
  - File size (smallest / largest first)
  - Random shuffle
- **Real-time sorting**: instant re-ordering without reloading the folder

### ⚙️ Settings & Customization
- **Persistent preferences**: stored in `UserDefaults` and applied live
- **Display modes**: Fit to Window, Fill Window, Actual Size
- **Slideshow interval**, **transition type and duration**, **auto-hide delay**
- **Backdrop blur**: radius and opacity
- **Cache tuning**: memory limit (1–50 % of system RAM, default 15 %), count limit (default 100), preload window (default 10)
- **Logging level**: Debug / Info / Warning / Error

## 🚀 Getting Started

### Requirements
- macOS 26.0 (Tahoe) or later
- Xcode 26+ (for development)

### Installation

#### Option 1: Download Release (Coming Soon)
Download the latest release from the [Releases](https://github.com/sho7650/SwiftViewer/releases) page.

#### Option 2: Build from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/sho7650/SwiftViewer.git
   cd SwiftViewer
   ```

2. Open in Xcode:
   ```bash
   open SwiftViewer.xcodeproj
   ```

3. Build and run:
   - Select the SwiftViewer scheme
   - Press ⌘R to build and run

## 📖 Usage

### Basic Navigation
- **Open a folder**: File ▸ Open Folder… (⌘O)
- **Navigate images**:
  - ← → (or ↑ ↓) for previous/next
  - Click the progress bar to jump to a specific image
  - Drag the progress bar to scrub through the folder

### Slideshow Controls
- **Start/Stop**: Space, or the Play/Pause button in the control bar
- **Settings**: Preferences (⌘,)
- **Repeat mode**: View ▸ Toggle Repeat Slideshow (⌘R), or the repeat button in the control bar

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| ← / ↑ | Previous image |
| → / ↓ | Next image |
| Space | Toggle slideshow |
| ⌘O | Open folder |
| ⌘, | Open preferences |
| ⌘F | Toggle fullscreen |
| ⌘R | Toggle repeat mode |
| ⌘1 / ⌘2 / ⌘3 | Fit to Window / Fill Window / Actual Size |
| ⌥⌘1 / ⇧⌥⌘1 | Sort by name, A–Z / Z–A |
| ⌥⌘2 / ⇧⌥⌘2 | Sort by date, oldest / newest first |
| ⌥⌘3 / ⇧⌥⌘3 | Sort by size, smallest / largest first |
| ⌥⌘R | Random shuffle |
| ⌃⌘T | Always on Top |
| ⌃⌘B | Always on Bottom |

> Arrow keys navigate without waking the auto-hidden control bar. Any other input — Space, other keys, mouse movement, or clicking the controls — brings it back.

### Display Modes
- **Fit to Window**: scale to fit while maintaining aspect ratio
- **Fill Window**: scale to fill the entire window
- **Actual Size**: display at original resolution

## 🏗️ Architecture

SwiftViewer follows an MVVM architecture with protocol-based dependency injection.

### Core Components

- **ViewModels**
  - `ImageGalleryViewModel` — folder contents, current index, navigation
  - `SlideShowViewModel` — slideshow state and timing
  - `AutoHideControlsManager` — control-bar visibility and the hide timer
  - `ContentViewModel` — folder selection and top-level app state

- **Services**
  - `FileManagerService` — directory scanning and image filtering
  - `ImagePipeline` — `actor` wrapping ImageIO downsampling, an `NSCache`, and background preloading (`ImageDownsampler`, `ImagePipelineProtocol`)
  - `SettingsManager` — `UserDefaults`-backed preferences
  - `SlideShowService` — timer management
  - `TransitionManager` / `ScaleFadeTransition` — pluggable image transitions
  - `WindowController` — fullscreen and window layering
  - `DependencyContainer` — composition root, with a mock container for tests and previews

- **Views**
  - `ImageGalleryView` — main image display and key handling
  - `GlassmorphismControlsView` — Liquid Glass player bar and progress scrubber
  - `BlurredImageBackground` — blurred backdrop
  - `SimpleAnimatedImageView` — animated GIF playback
  - `FolderSelectionView`, `SettingsView`

### Key Design Patterns
- **Protocol-oriented programming** for testability
- **Dependency injection** through initializers
- **`@Observable` state** for reactive UI updates
- **Command pattern** for menu and keyboard actions (`MenuCommands`)
- **Swift 6 strict concurrency**: actors for shared mutable state, `@MainActor` for UI

## 🧪 Testing

```bash
# Run all tests
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -sdk macosx test

# Run only the unit test target
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -sdk macosx -only-testing:SwiftViewerTests test

# Run with the coverage test plan
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -testPlan TestCoveragePlan test
```

Current suite: **427 unit tests** and **4 UI tests**.

### Test Structure
- **Unit tests** (`SwiftViewerTests/`) — logic and business rules, mirroring the source tree
- **UI tests** (`SwiftViewerUITests/`) — launch and interaction
- **Performance tests** — rendering and load behaviour with large collections

## 🔧 Development

### Prerequisites
- macOS 26.0+
- Xcode 26+
- Swift 6.0

### Building
```bash
# Debug build
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -configuration Debug build

# Release build
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -configuration Release build
```

### Linting
```bash
swiftlint          # rules in .swiftlint.yml
swiftlint --fix    # auto-fix
```

### Code Style
- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- Prefer value types and `let`; use actors for shared mutable state
- Maintain MVVM separation and inject dependencies through protocols
- Write tests first — the project targets 75 %+ coverage

### Contributing
1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Make your changes with tests
4. Ensure the build and full test suite pass — a pre-commit hook runs `scripts/verify_prerequisites.sh` (build + tests) and blocks the commit on failure
5. Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`)
6. Push and open a Pull Request

See [docs/RELEASING.md](docs/RELEASING.md) for the release process.

## 📱 System Requirements

### Minimum
- macOS 26.0 (Tahoe)
- 4 GB RAM
- 100 MB disk space

### Recommended
- 8 GB+ RAM for large image collections
- SSD for optimal performance

### Supported Formats

| Format | Extension | Status |
|--------|-----------|--------|
| JPEG | `.jpg`, `.jpeg` | Supported |
| HEIC | `.heic` | Supported |
| GIF | `.gif` | Supported, including animation |
| PNG | `.png` | Not yet supported |
| RAW | Various | Planned via plugin system |

## 🔐 Privacy & Security

- **App Sandbox**: enabled (`com.apple.security.app-sandbox`)
- **File access**: read-only, and only for folders you explicitly choose (`com.apple.security.files.user-selected.read-only`)
- **No network access**: SwiftViewer operates entirely offline
- **No persistent folder access**: security-scoped bookmarks are not used yet, so a folder must be re-selected after relaunch

## 🐛 Troubleshooting

### Common Issues
1. **Images not loading** — confirm the folder contains supported formats and is readable
2. **High memory use** — lower the cache memory limit or preload window in Preferences
3. **Slideshow stops at the last image** — enable repeat mode (⌘R)
4. **Controls disappear while browsing** — expected: arrow keys do not wake the control bar. Move the mouse or press any other key to bring it back

### Debug Logging
```bash
defaults write oshiire.SwiftViewer debugLoggingEnabled -bool YES
```
The logging level (Debug / Info / Warning / Error) can also be set in Preferences.

### Xcode Previews fail with `missing required module 'SwiftShims'`
A stale explicit-module cache. Quit Xcode and clear it:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
```

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Developed using [Claude Code](https://claude.ai/code) assistance
- Inspired by the need for a fast, clean macOS photo viewer

## 📞 Support

- 🐛 [Report bugs](https://github.com/sho7650/SwiftViewer/issues)
- 💡 [Request features](https://github.com/sho7650/SwiftViewer/issues)
- ❓ [Ask questions](https://github.com/sho7650/SwiftViewer/discussions)

---

<div align="center">
  <p>Made with ❤️ for macOS</p>
  <p>SwiftViewer • Fast • Clean • Reliable</p>
</div>
