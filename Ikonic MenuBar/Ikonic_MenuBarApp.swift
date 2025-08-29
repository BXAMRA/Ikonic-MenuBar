//
//  Ikonic_MenuBarApp.swift
//  Ikonic MenuBar
//
//  Created by Jass Bhamra on 2025-08-29.
//

import SwiftUI

@main
struct Ikonic_MenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { EmptyView() }
    }
}
