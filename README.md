# 🖼️ Ikonic MenuBar

A minimalist macOS menubar app that displays any PNG image (like a logo or tag) as your menubar icon.

---

## ✨ Features

- Custom PNG image shown as the menubar icon
- **Command + Right Click** to open image picker
- Auto-resizes image with white visibility mask
- Remembers last selected image between launches
- Optional: Auto-launch on system login

---

## 📷 Screenshot

![Ikonic MenuBar Screenshot](./screenshot.png)

---

## 🚀 Usage

1. Launch the app.
2. **Command + Right Click** the menubar icon.
3. Choose a `.png` image.
4. The image will appear in your menubar — scaled and masked for clarity.
5. Image is saved and shown automatically on next launch.

---

## ⚙️ Auto Launch on Login

The app uses AppleScript to add itself to **Login Items** when launched.

You can remove it via:

```
System Settings → Users & Groups → Login Items
```

---

## 🛠️ Technical Overview

- Built with **Swift** and **AppKit**
- Uses `NSStatusBar` and `NSStatusItem` for menubar integration
- `NSOpenPanel` for file selection
- `UserDefaults` for persistence
- Custom `NSImage` rendering with white overlay/masking
- Image constraints: height-fixed, width max 3× height

---

## 🧪 Build & Run

### Prerequisites

- macOS
- Xcode

### Steps

1. Clone the repo:

```bash
 git clone https://github.com/yourusername/ikonic-menubar.git
```

2. Open the project:
   open "Ikonic MenuBar.xcodeproj"
3. Build and run using the My Mac scheme.

---

## 📦 Locate the .app File

### After building:

- In Xcode, go to Products > Ikonic MenuBar.app
- Right-click → Show in Finder

### Or locate manually:

```
~/Library/Developer/Xcode/DerivedData/Ikonic_Menubar-.../Build/Products/Debug/Ikonic MenuBar.app
```

---

## 📝 License

MIT License — feel free to use, modify, or contribute.

---

## 🙌 Credits

Made with ❤️ using Swift and AppKit
by BXAMRA
