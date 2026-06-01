# SwiftViewer

[![Swift CI](https://github.com/sho7650/SwiftViewer/actions/workflows/swift.yml/badge.svg)](https://github.com/sho7650/SwiftViewer/actions/workflows/swift.yml)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A modern, high-performance photo viewer application for macOS built with Swift 6 and SwiftUI. SwiftViewer provides a clean, intuitive interface for browsing and viewing large collections of images with advanced slideshow functionality.

## ✨ Features

### 🖼️ Image Viewing
- **Multi-format Support**: JPG, JPEG, HEIC, GIF (with animation support)
- **High Performance**: Optimized for folders containing 10,000+ images
- **Smart Caching**: Sub-10ms response time for cached images with configurable memory limits
- **Folder-based Navigation**: Easy browsing of entire image directories

### 🎬 Slideshow
- **Configurable Intervals**: 1-300 seconds with precise timing
- **Smooth Transitions**: Fluid image transitions with auto-hide controls
- **Repeat Mode**: Continuous playback or stop at last image
- **Keyboard Control**: Space bar to play/pause, arrow keys for navigation

### 🎛️ User Interface
- **Auto-hide Controls**: Smart control visibility based on user activity
- **Progress Bar Navigation**: Click-to-jump functionality with visual progress
- **Fullscreen Support**: Immersive viewing experience (F key toggle)
- **Responsive Design**: Optimized for various screen sizes and orientations

### 📁 Organization
- **Multiple Sort Options**:
  - Name (ascending/descending)
  - Date created (ascending/descending)
  - File size (ascending/descending)
  - Random shuffle
- **Real-time Sorting**: Instant re-organization without reload

### ⚙️ Settings & Customization
- **Persistent Settings**: Preferences saved automatically
- **Slideshow Timing**: Customizable interval settings
- **Display Modes**: Fit to window, fill window, or actual size
- **Keyboard Shortcuts**: Full keyboard navigation support

## 🚀 Getting Started

### Requirements
- macOS 15.0 or later
- Xcode 16+ (for development)

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
   - Press ⌘+R to build and run

## 📖 Usage

### Basic Navigation
- **Open Folder**: Use File menu or drag & drop a folder onto the app
- **Navigate Images**: 
  - ← → arrow keys for previous/next
  - Click on progress bar to jump to specific image
  - Mouse wheel for quick scrolling

### Slideshow Controls
- **Start/Stop**: Space bar or click the play/pause button
- **Settings**: Configure timing via Preferences (⌘+,)
- **Repeat Mode**: Toggle continuous playback via menu or ⌘+R

### Keyboard Shortcuts
| Key | Action |
|-----|--------|
| ← | Previous image |
| → | Next image |
| Space | Toggle slideshow |
| F | Toggle fullscreen |
| ⌘+R | Toggle repeat mode |
| ⌘+, | Open preferences |
| ⌘+O | Open folder |

### Display Modes
- **Fit to Window**: Scale image to fit window while maintaining aspect ratio
- **Fill Window**: Scale image to fill entire window
- **Actual Size**: Display image at original resolution

## 🏗️ Architecture

SwiftViewer follows a clean MVVM architecture with dependency injection:

### Core Components
- **ViewModels**: Business logic and state management
  - `ImageGalleryViewModel`: Main gallery functionality
  - `SlideShowViewModel`: Slideshow control and timing
  - `AutoHideControlsManager`: Smart UI control visibility
  
- **Services**: Backend functionality
  - `FileManagerService`: File system operations
  - `ImageLoaderService`: Optimized image loading
  - `SettingsManager`: Persistent user preferences
  - `SlideShowService`: Timer management

- **Views**: SwiftUI interface components
  - `ImageGalleryView`: Main image display
  - `GlassmorphismControlsView`: Playback controls
  - `SettingsView`: Preferences interface

### Key Design Patterns
- **Protocol-oriented Programming**: Maximum testability and flexibility
- **Dependency Injection**: Clean separation of concerns
- **Observer Pattern**: Reactive UI updates
- **Command Pattern**: Menu and keyboard actions

## 🧪 Testing

SwiftViewer includes comprehensive test coverage:

```bash
# Run all tests
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer test

# Run with coverage
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -testPlan TestCoveragePlan test
```

### Test Structure
- **Unit Tests**: Logic and business rule validation
- **UI Tests**: User interface and interaction testing
- **Integration Tests**: Component interaction verification
- **Performance Tests**: Load testing with large image collections

## 🔧 Development

### Prerequisites
- Xcode 16+
- macOS 15.0+
- Swift 6.0

### Building
```bash
# Debug build
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -configuration Debug build

# Release build
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -configuration Release build
```

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Maintain MVVM separation
- Write comprehensive unit tests

### Contributing
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with tests
4. Ensure all tests pass
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📱 System Requirements

### Minimum Requirements
- macOS 15.0 (Sequoia)
- 4GB RAM
- 100MB disk space

### Recommended
- macOS 15.0+ (Sequoia)
- 8GB+ RAM for large image collections
- SSD for optimal performance

### Supported Formats
| Format | Extension | Notes |
|--------|-----------|-------|
| JPEG | .jpg, .jpeg | Full support |
| HEIC | .heic | Apple's high-efficiency format |
| GIF | .gif | Including animations |
| PNG | .png | Coming soon |
| RAW | Various | Planned via plugin system |

## 🔐 Privacy & Security

- **App Sandbox**: Full sandboxing for system security
- **File Access**: Read-only access to user-selected folders
- **No Network**: Completely offline operation
- **Bookmarks**: Secure persistent access to chosen directories

## 🐛 Troubleshooting

### Common Issues
1. **Images not loading**: Ensure folder has proper read permissions
2. **Slow performance**: Check available memory and consider reducing cache size
3. **Slideshow stopping**: Verify repeat mode settings in preferences

### Debug Mode
Enable debug logging via:
```bash
defaults write com.yourcompany.SwiftViewer debugLoggingEnabled -bool YES
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

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