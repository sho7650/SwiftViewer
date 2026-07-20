//
//  SwiftViewerApp.swift
//  SwiftViewer
//
//  Created by sho kisaragi on 2025/08/21.
//

import SwiftUI

@main
struct SwiftViewerApp: App {
    @State private var isShowingSettings = false

    init() {
        // Wire the animation-duration provider to the shared settings once at launch.
        AnimationDurationProvider.configure(with: DependencyContainer.shared.settingsManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .windowFullScreenBehavior(.enabled)
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView()
                }
                .onAppear {
                    // Establish window reference and initialize window position
                    DispatchQueue.main.async {
                        if let window = NSApp.keyWindow ?? NSApp.windows.first {
                            WindowController.shared.setWindow(window)
                            let savedPosition = DependencyContainer.shared.settingsManager.windowPosition
                            WindowController.shared.setWindowLevel(savedPosition)
                            Logger.shared.info("[SwiftViewerApp] Window initialized with position: \(savedPosition)")
                        } else {
                            Logger.shared.warning("[SwiftViewerApp] No window available on startup")
                        }
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowManagerRole(.principal)
        .commands {
            MenuCommands()
            
            CommandGroup(replacing: .appSettings) {
                Button("Preferences...") {
                    isShowingSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
