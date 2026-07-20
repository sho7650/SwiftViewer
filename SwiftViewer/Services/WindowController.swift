//
//  WindowController.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/28.
//

import AppKit
import Foundation

@MainActor
final class WindowController {
    static let shared = WindowController()

    private var window: NSWindow?
    private var savedLevel: NSWindow.Level?
    private let logger = Logger.shared

    init() {}
    
    func setWindow(_ window: NSWindow) {
        self.window = window
        logger.debug("[WindowController] Window reference set: \(window)")
        debugState()
    }
    
    func setWindowLevel(_ position: WindowPosition) {
        guard let window = window else {
            logger.warning("[WindowController] No window reference, attempting fallback")
            // Fallback: try to find the main window
            if let mainWindow = NSApp.windows.first {
                self.window = mainWindow
                logger.info("[WindowController] Using fallback window: \(mainWindow)")
                setLevel(for: mainWindow, position: position)
            } else {
                logger.error("[WindowController] No windows available")
            }
            return
        }
        
        logger.info("[WindowController] Setting window level to: \(position)")
        setLevel(for: window, position: position)
    }
    
    private func setLevel(for window: NSWindow, position: WindowPosition) {
        let previousLevel = window.level
        switch position {
        case .normal:
            window.level = .normal
        case .alwaysOnTop:
            window.level = .floating
        case .alwaysOnBottom:
            window.level = .init(Int(CGWindowLevelForKey(.desktopWindow)))
        }
        logger.debug("[WindowController] Level changed from \(previousLevel.rawValue) to \(window.level.rawValue)")
    }
    
    // MARK: - Fullscreen Support
    
    func prepareForFullscreen() -> Bool {
        guard let window = window else {
            logger.error("[WindowController] No window reference for fullscreen")
            return false
        }
        
        // Ensure window supports fullscreen (PhotoSlideshow pattern)
        if !window.collectionBehavior.contains(.fullScreenPrimary) {
            window.collectionBehavior.insert(.fullScreenPrimary)
            logger.debug("[WindowController] Added fullScreenPrimary to collection behavior")
        }
        if window.collectionBehavior.contains(.fullScreenNone) {
            window.collectionBehavior.remove(.fullScreenNone)
            logger.debug("[WindowController] Removed fullScreenNone from collection behavior")
        }
        
        // Fullscreen requires .normal level
        if window.level != .normal {
            savedLevel = window.level
            window.level = .normal
            logger.info("[WindowController] Window level temporarily set to normal for fullscreen (was: \(savedLevel?.rawValue ?? -1))")
        }
        return true
    }
    
    func restoreAfterFullscreen() {
        if let saved = savedLevel, let window = window {
            window.level = saved
            savedLevel = nil
            logger.info("[WindowController] Window level restored to: \(saved.rawValue)")
        }
    }
    
    // MARK: - Debug
    
    func debugState() {
        logger.debug("[WindowController] === Window State ===")
        logger.debug("[WindowController] Window reference: \(window != nil)")
        logger.debug("[WindowController] Window level: \(window?.level.rawValue ?? -1)")
        logger.debug("[WindowController] Is key window: \(window?.isKeyWindow ?? false)")
        logger.debug("[WindowController] Is main window: \(window?.isMainWindow ?? false)")
        logger.debug("[WindowController] NSApp.keyWindow: \(NSApp.keyWindow != nil)")
        logger.debug("[WindowController] NSApp.isActive: \(NSApp.isActive)")
        logger.debug("[WindowController] Windows count: \(NSApp.windows.count)")
    }
}