//
//  WindowController.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/28.
//

import AppKit
import Foundation

final class WindowController {
    static let shared = WindowController()
    
    private var window: NSWindow?
    
    init() {}
    
    func setWindow(_ window: NSWindow) {
        self.window = window
    }
    
    func setWindowLevel(_ position: WindowPosition) {
        guard let window = window else {
            // Fallback: try to find the main window
            if let mainWindow = NSApp.windows.first {
                self.window = mainWindow
                setLevel(for: mainWindow, position: position)
            }
            return
        }
        
        setLevel(for: window, position: position)
    }
    
    private func setLevel(for window: NSWindow, position: WindowPosition) {
        switch position {
        case .normal:
            window.level = .normal
        case .alwaysOnTop:
            window.level = .floating
        case .alwaysOnBottom:
            window.level = .init(Int(CGWindowLevelForKey(.desktopWindow)))
        }
    }
}