//
//  SettingsPopoverController.swift
//  Ikonic MenuBar
//

import Cocoa
import UniformTypeIdentifiers

class SettingsPopoverController: NSViewController {

    // MARK: - UI Elements

    lazy var imageScrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.borderType = .noBorder
        scroll.autohidesScrollers = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    lazy var imageStackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 10
        stack.alignment = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    lazy var addButton: NSButton = {
        let button = NSButton(title: "Add Image", target: self, action: #selector(addImage))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var removeButton: NSButton = {
        let button = NSButton(title: "Remove Image", target: self, action: #selector(removeSelectedImage))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var applyOverlayCheckbox: NSButton = {
        let button = NSButton(checkboxWithTitle: "Apply White Mask", target: self, action: #selector(toggleOverlay(_:)))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.state = UserDefaults.standard.bool(forKey: AppConfig.Keys.overlayEnabled) ? .on : .off
        return button
    }()

    // Overlay strength slider (kept) — padded row
    lazy var overlaySlider: NSSlider = {
        let slider = NSSlider(value: Double(UserDefaults.standard.float(forKey: AppConfig.Keys.overlayStrength)),
                              minValue: 0.0, maxValue: 1.0,
                              target: self,
                              action: #selector(overlaySliderChanged(_:)))
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    // New: Menu bar height controls using − / + buttons
    private let minHeight: Double = 12.0
    private let maxHeight: Double = 32.0
    private let step: Double = 1.0

    lazy var heightTitleLabel: NSTextField = {
        let lbl = NSTextField(labelWithString: "Menu Bar Height")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    lazy var heightValueLabel: NSTextField = {
        let stored = UserDefaults.standard.object(forKey: AppConfig.Keys.imageHeight) as? NSNumber
        let current = Int(stored?.doubleValue ?? 18.0)
        let lbl = NSTextField(labelWithString: "\(current) pt")
        lbl.alignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    lazy var decrementButton: NSButton = {
        let b = NSButton(title: "−", target: self, action: #selector(decrementHeight))
        b.bezelStyle = .texturedRounded
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    lazy var incrementButton: NSButton = {
        let b = NSButton(title: "+", target: self, action: #selector(incrementHeight))
        b.bezelStyle = .texturedRounded
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    lazy var loginItemsCheckbox: NSButton = {
        let button = NSButton(checkboxWithTitle: "Add to Login Items", target: self, action: #selector(toggleLoginItems(_:)))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.state = UserDefaults.standard.bool(forKey: AppConfig.Keys.launchAtLogin) ? .on : .off
        return button
    }()

    lazy var quitButton: NSButton = {
        let button = NSButton(title: "Quit", target: self, action: #selector(quitApp))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - State
    private var selectedImageFilename: String?

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        self.preferredContentSize = NSSize(width: 280, height: 460)

        // Main vertical stack with window padding so controls don't touch edges
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.spacing = 10
        mainStack.edgeInsets = NSEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Scrollable vertical image list
        mainStack.addArrangedSubview(imageScrollView)
        imageScrollView.documentView = imageStackView
        imageScrollView.heightAnchor.constraint(equalToConstant: 250).isActive = true

        // Make the stack view fill width and scroll vertically:
        // Pin top/leading/trailing + equal width; bottom is >= for overflow to enable scrolling [3][7].
        let clipView = imageScrollView.contentView
        NSLayoutConstraint.activate([
            imageStackView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            imageStackView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            imageStackView.topAnchor.constraint(equalTo: clipView.topAnchor),
            imageStackView.widthAnchor.constraint(equalTo: clipView.widthAnchor)
        ])
        let bottomGE = imageStackView.bottomAnchor.constraint(greaterThanOrEqualTo: clipView.bottomAnchor)
        bottomGE.priority = .defaultLow
        bottomGE.isActive = true

        // Buttons row
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 10
        buttonStack.addArrangedSubview(addButton)
        buttonStack.addArrangedSubview(removeButton)
        mainStack.addArrangedSubview(buttonStack)

        // Overlay checkbox
        mainStack.addArrangedSubview(applyOverlayCheckbox)

        // Overlay slider in padded row so it doesn't touch edges
        mainStack.addArrangedSubview(paddedRow(overlaySlider))

        // Height row: [label] [−] [value] [+]
        let heightRow = NSStackView()
        heightRow.orientation = .horizontal
        heightRow.alignment = .centerY
        heightRow.spacing = 8
        heightRow.addArrangedSubview(heightTitleLabel)
        heightRow.addArrangedSubview(decrementButton)
        heightRow.addArrangedSubview(heightValueLabel)
        heightRow.addArrangedSubview(incrementButton)

        heightTitleLabel.setContentHuggingPriority(.required, for: .horizontal)
        heightValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        decrementButton.setContentHuggingPriority(.required, for: .horizontal)
        incrementButton.setContentHuggingPriority(.required, for: .horizontal)

        mainStack.addArrangedSubview(paddedRow(heightRow))

        // Login items + Quit
        mainStack.addArrangedSubview(loginItemsCheckbox)
        mainStack.addArrangedSubview(quitButton)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSavedImages()
    }

    // MARK: - Helpers

    // Wrap a view in a container with left/right padding; keeps controls off the window edges
    private func paddedRow(_ inner: NSView, left: CGFloat = 8, right: CGFloat = 8) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        inner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: left),
            inner.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -right),
            inner.topAnchor.constraint(equalTo: container.topAnchor),
            inner.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func currentHeight() -> Double {
        let stored = UserDefaults.standard.object(forKey: AppConfig.Keys.imageHeight) as? NSNumber
        return stored?.doubleValue ?? 18.0
    }

    private func setHeight(_ value: Double) {
        let clamped = min(max(value, minHeight), maxHeight)
        UserDefaults.standard.set(clamped, forKey: AppConfig.Keys.imageHeight)
        heightValueLabel.stringValue = "\(Int(round(clamped))) pt"
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }

    // MARK: - Image Handling

    @objc func addImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif, .tiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.saveImage(url)
        }
    }

    func saveImage(_ url: URL) {
        let appFolder = AppConfig.appSupportFolder()
        let destinationURL = appFolder.appendingPathComponent(url.lastPathComponent)

        try? FileManager.default.copyItem(at: url, to: destinationURL)

        UserDefaults.standard.set(url.lastPathComponent, forKey: AppConfig.Keys.selectedImageName)
        var allImages = UserDefaults.standard.stringArray(forKey: AppConfig.Keys.allSavedImages) ?? []
        if !allImages.contains(url.lastPathComponent) {
            allImages.append(url.lastPathComponent)
            UserDefaults.standard.set(allImages, forKey: AppConfig.Keys.allSavedImages)
        }

        DispatchQueue.main.async {
            if let nsImage = NSImage(contentsOf: destinationURL) {
                self.addPreviewImage(nsImage, filename: url.lastPathComponent)
            }
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }

    @objc func removeSelectedImage() {
        guard let filename = selectedImageFilename else { return }
        var allImages = UserDefaults.standard.stringArray(forKey: AppConfig.Keys.allSavedImages) ?? []
        allImages.removeAll { $0 == filename }
        UserDefaults.standard.set(allImages, forKey: AppConfig.Keys.allSavedImages)

        let appFolder = AppConfig.appSupportFolder()
        let fileURL = appFolder.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)

        // Remove container view
        for subview in imageStackView.arrangedSubviews {
            if subview.toolTip == filename {
                imageStackView.removeArrangedSubview(subview)
                subview.removeFromSuperview()
                break
            }
        }

        if let first = allImages.first {
            UserDefaults.standard.set(first, forKey: AppConfig.Keys.selectedImageName)
        } else {
            UserDefaults.standard.removeObject(forKey: AppConfig.Keys.selectedImageName)
        }

        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }

    func addPreviewImage(_ image: NSImage, filename: String) {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor
        container.toolTip = filename

        let imageView = NSImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        container.addSubview(imageView)

        imageStackView.addArrangedSubview(container)

        // Use current setting for preview scale
        let menubarHeight: CGFloat = CGFloat(currentHeight())
        let menubarMaxWidth: CGFloat = menubarHeight * 3
        let previewHeight = menubarHeight * 2
        let previewMaxWidth = menubarMaxWidth * 2

        let aspect = image.size.width / image.size.height
        let widthByAspect = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: aspect)
        let maxWidth = imageView.widthAnchor.constraint(lessThanOrEqualToConstant: previewMaxWidth)

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: previewHeight),
            widthByAspect, maxWidth,
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let click = NSClickGestureRecognizer(target: self, action: #selector(imageClicked(_:)))
        container.addGestureRecognizer(click)
    }

    @objc func imageClicked(_ sender: NSClickGestureRecognizer) {
        guard let container = sender.view, let filename = container.toolTip else { return }
        selectedImageFilename = filename
        UserDefaults.standard.set(filename, forKey: AppConfig.Keys.selectedImageName)
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }

    func loadSavedImages() {
        let appFolder = AppConfig.appSupportFolder()
        if let files = try? FileManager.default.contentsOfDirectory(at: appFolder, includingPropertiesForKeys: nil) {
            for file in files {
                if let image = NSImage(contentsOf: file) {
                    DispatchQueue.main.async {
                        self.addPreviewImage(image, filename: file.lastPathComponent)
                    }
                }
            }
        }

        selectedImageFilename = UserDefaults.standard.string(forKey: AppConfig.Keys.selectedImageName)
    }

    // MARK: - Overlay Controls

    @objc func toggleOverlay(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: AppConfig.Keys.overlayEnabled)
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }

    @objc func overlaySliderChanged(_ sender: NSSlider) {
        UserDefaults.standard.set(sender.floatValue, forKey: AppConfig.Keys.overlayStrength)
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }

    // MARK: - Height Controls (− / +)

    @objc func decrementHeight() {
        setHeight(currentHeight() - step) // target–action pattern updates and persists the value [6].
    }

    @objc func incrementHeight() {
        setHeight(currentHeight() + step) // target–action pattern updates and persists the value [6].
    }

    // MARK: - Login Items

    @objc func toggleLoginItems(_ sender: NSButton) {
        let enabled = sender.state == .on
        UserDefaults.standard.set(enabled, forKey: AppConfig.Keys.launchAtLogin)
    }

    // MARK: - Quit

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
