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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView()
                }
        }
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
