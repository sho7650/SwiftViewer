//
//  DisplayMode.swift
//  SwiftViewer
//
//  How the current image is fitted within the window.
//

import Foundation

enum DisplayMode: String, CaseIterable {
    case fit = "Fit to Window"
    case fill = "Fill Window"
    case actualSize = "Actual Size"
}
