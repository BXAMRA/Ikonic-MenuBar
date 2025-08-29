//
//  AppDelegate.swift
//  Ikonic MenuBar
//
//  Created by BXAMRA on 2025-08-29.
//

import Cocoa
import ServiceManagement
import UniformTypeIdentifiers

extension Notification.Name {
    static let settingsDidChange = Notification.Name("SettingsDidChange")
}

/// Central place for keys and paths used across the app.
enum AppConfig {
    enum Keys {
        static let selectedImageName = "SelectedImageName"
        static let allSavedImages   = "AllSavedImages"
        static let overlayEnabled   = "OverlayEnabled"
        static let overlayStrength  = "OverlayStrength"
        static let launchAtLogin    = "LaunchAtLogin"
        static let imageHeight      = "ImageHeight"
    }

    static let appSupportFolderName = "Ikonic MenuBar"

    static func appSupportFolder() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent(appSupportFolderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: appFolder.path) {
            try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }
        return appFolder
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Default Icon")
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
            button.action = #selector(statusItemClicked(_:))
        }

        restoreSettings()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .settingsDidChange,
            object: nil
        )
    }

    @objc func settingsDidChange() {
        restoreSettings()
    }

    @objc func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }

        switch event.type {
        case .rightMouseUp:
            openSettingsWindow()
        case .leftMouseUp:
            break
        default:
            break
        }
    }

    func openSettingsWindow() {
        let controller = SettingsPopoverController()
        if settingsWindow == nil {
            settingsWindow = NSWindow(
                contentRect: NSRect(origin: .zero, size: controller.preferredContentSize),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.center()
            settingsWindow?.title = "Settings"
            settingsWindow?.contentViewController = controller
        }

        // Update window size each time based on preferredContentSize
        if let controllerSize = settingsWindow?.contentViewController?.preferredContentSize {
            settingsWindow?.setContentSize(controllerSize)
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Restore State
    func restoreSettings() {
        let defaults = UserDefaults.standard
        let appFolder = AppConfig.appSupportFolder()

        if let savedName = defaults.string(forKey: AppConfig.Keys.selectedImageName) {
            let localPath = appFolder.appendingPathComponent(savedName)
            if FileManager.default.fileExists(atPath: localPath.path),
               let savedImage = NSImage(contentsOf: localPath) {
                statusItem.button?.image = processImage(savedImage)
                return
            }
        }

        let allNames = defaults.stringArray(forKey: AppConfig.Keys.allSavedImages) ?? []
        if let firstName = allNames.first {
            let localPath = appFolder.appendingPathComponent(firstName)
            if FileManager.default.fileExists(atPath: localPath.path),
               let savedImage = NSImage(contentsOf: localPath) {
                statusItem.button?.image = processImage(savedImage)
                defaults.set(firstName, forKey: AppConfig.Keys.selectedImageName)
                return
            }
        }

        loadDefaultImage()
    }

    func loadDefaultImage() {
        if let defaultImage = NSImage(named: "BXAMRA") {
            statusItem.button?.image = processImage(defaultImage)
        } else {
            statusItem.button?.image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Default Icon")
        }
    }

    // MARK: - Image Processor
    func processImage(_ image: NSImage) -> NSImage {
        let defaults = UserDefaults.standard
        let storedHeight = defaults.object(forKey: AppConfig.Keys.imageHeight) as? NSNumber
        let targetHeight = CGFloat(storedHeight?.doubleValue ?? 18.0)
        let maxWidth: CGFloat = targetHeight * 5.0

        let originalSize = image.size
        let aspectRatio = max(originalSize.width, 1) / max(originalSize.height, 1)

        var scaledWidth = targetHeight * aspectRatio
        var scaledHeight = targetHeight

        if scaledWidth > maxWidth {
            scaledWidth = maxWidth
            scaledHeight = maxWidth / aspectRatio
        }

        let imageSize = NSSize(width: scaledWidth, height: scaledHeight)
        let canvasSize = NSSize(width: scaledWidth, height: targetHeight)

        let finalImage = NSImage(size: canvasSize)
        finalImage.lockFocus()

        let originY = (canvasSize.height - imageSize.height) / 2
        let drawRect = NSRect(x: 0, y: originY, width: imageSize.width, height: imageSize.height)

        image.draw(in: drawRect)

        if UserDefaults.standard.bool(forKey: AppConfig.Keys.overlayEnabled) {
            let strength = CGFloat(UserDefaults.standard.float(forKey: AppConfig.Keys.overlayStrength))
            if let context = NSGraphicsContext.current {
                context.compositingOperation = .sourceAtop
                NSColor(white: 1.0, alpha: strength).setFill()
                NSBezierPath(rect: drawRect).fill()
            }
        }

        finalImage.unlockFocus()
        finalImage.isTemplate = false
        return finalImage
    }
}
