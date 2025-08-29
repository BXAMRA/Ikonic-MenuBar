//
//  AppDelegate.swift
//  Ikonic MenuBar
//
//  Created by Jass Bhamra on 2025-08-29.
//

import Cocoa
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    let imagePathKey = "SelectedImagePath"

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        addAppToLoginItems()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Default Icon")
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
        }

        // Enable right-click tracking
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { event in
            if let button = self.statusItem.button, button.window?.contentView?.hitTest(event.locationInWindow) != nil {
                self.statusBarButtonClicked(button)
                return nil // swallow the event
            }
            return event
        }
        
        // Try to load last selected image
        if let savedPath = UserDefaults.standard.string(forKey: imagePathKey),
           FileManager.default.fileExists(atPath: savedPath),
           let savedImage = NSImage(contentsOfFile: savedPath) {
            let processed = processImage(savedImage)
            statusItem.button?.image = processed
        } else {
            // Load default image if no saved image
            loadDefaultImage()
        }
    }

    @objc func statusBarButtonClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            if event.modifierFlags.contains(.command) {
                openFilePicker()
            }
        }
        // Left click: do nothing
    }

    func openFilePicker() {
        let dialog = NSOpenPanel()
        dialog.allowedContentTypes = [.png]
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false

        if dialog.runModal() == .OK, let url = dialog.url {
            if let image = NSImage(contentsOf: url) {
                let processed = processImage(image)
                statusItem.button?.image = processed
                
                UserDefaults.standard.set(url.path, forKey: imagePathKey)
            }
        }
    }
    
    func loadDefaultImage() {
        if let defaultImage = NSImage(named: "IkonicBanner") {
            let processed = processImage(defaultImage)
            statusItem.button?.image = processed
        } else {
            // Fallback to system symbol if custom image not found
            statusItem.button?.image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Default Icon")
        }
    }

    func processImage(_ image: NSImage) -> NSImage {
        let targetHeight: CGFloat = 18.0
        let maxWidth: CGFloat = targetHeight * 3.0

        let originalSize = image.size
        let aspectRatio = originalSize.width / originalSize.height

        // First: calculate image scale so height fits
        var scaledWidth = targetHeight * aspectRatio
        var scaledHeight = targetHeight

        if scaledWidth > maxWidth {
            // If width is too big, scale down further
            scaledWidth = maxWidth
            scaledHeight = maxWidth / aspectRatio
        }

        let imageSize = NSSize(width: scaledWidth, height: scaledHeight)
        let canvasSize = NSSize(width: scaledWidth, height: targetHeight)

        let finalImage = NSImage(size: canvasSize)
        finalImage.lockFocus()

        // Step 1: draw image centered vertically (no stretch)
        let originY = (canvasSize.height - imageSize.height) / 2
        let drawRect = NSRect(x: 0, y: originY, width: imageSize.width, height: imageSize.height)

        image.draw(
            in: drawRect,
            from: NSRect(origin: .zero, size: originalSize),
            operation: .sourceOver,
            fraction: 1.0
        )

        // Step 2: apply white overlay ONLY on non-transparent pixels
        if let context = NSGraphicsContext.current {
            context.compositingOperation = .sourceAtop
            NSColor(white: 1.0, alpha: 1.0).setFill()
            NSBezierPath(rect: drawRect).fill()
        }

        finalImage.unlockFocus()
        finalImage.isTemplate = false

        return finalImage
    }
    
    func addAppToLoginItems() {
        guard let appPath = Bundle.main.bundlePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            print("Invalid app path")
            return
        }

        let appleScript = """
        tell application "System Events"
            if login item "\(Bundle.main.bundleURL.lastPathComponent)" exists then
                return
            end if
            make login item at end with properties {path:"\(Bundle.main.bundlePath)", hidden:false}
        end tell
        """

        var error: NSDictionary?
        if let script = NSAppleScript(source: appleScript) {
            script.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
            } else {
                print("Added to login items")
            }
        }
    }
}
