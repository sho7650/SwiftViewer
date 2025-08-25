//
//  FolderSelectionView.swift
//  SwiftViewer
//
//  Created by Claude on 2025/08/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct FolderSelectionView: View {
    let onFolderSelected: (URL) -> Void
    
    @State private var isDragOver = false
    @State private var isShowingFilePicker = false
    
    var body: some View {
        VStack(spacing: 40) {
            // App icon/branding area
            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                Text("SwiftViewer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select a folder to view images")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Main action area
            VStack(spacing: 24) {
                // Folder selection button
                Button(action: {
                    openFolderPicker()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.title2)
                        Text("Choose Folder")
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .scaleEffect(isDragOver ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isDragOver)
                
                // Drag and drop area
                VStack(spacing: 12) {
                    Text("or")
                        .foregroundColor(.secondary)
                    
                    dropZone
                }
            }
            
            // Help text
            VStack(spacing: 8) {
                Text("Supported formats: JPG, JPEG, HEIC, GIF")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Label("Arrow keys to navigate", systemImage: "arrow.left.arrow.right")
                    Label("F for fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var dropZone: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(
                isDragOver ? Color.accentColor : Color.secondary.opacity(0.5),
                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDragOver ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc")
                        .font(.title)
                        .foregroundColor(isDragOver ? .accentColor : .secondary)
                    
                    Text("Drop folder here")
                        .font(.headline)
                        .foregroundColor(isDragOver ? .accentColor : .secondary)
                }
            )
            .frame(height: 120)
            .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                handleDrop(providers: providers)
            }
    }
    
    // MARK: - Actions
    
    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                onFolderSelected(url)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            DispatchQueue.main.async {
                if let url = url, url.hasDirectoryPath {
                    onFolderSelected(url)
                }
            }
        }
        
        return true
    }
}

// MARK: - Preview

#Preview {
    FolderSelectionView { url in
        Logger.shared.debug("Folder selected: \(url.path)")
    }
    .frame(width: 600, height: 500)
}