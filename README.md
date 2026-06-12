# BigClipboard

[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue.svg)](https://developer.apple.com/macos/)
[![Language](https://img.shields.io/badge/Language-Swift%206.0-orange.svg)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](#)
[![Build](https://img.shields.io/badge/Build-Passing-green.svg)](#)

> A lightweight, local-first macOS menu bar utility that aggregates clipboard history and offers instant, toggleable plain-text stripping to streamline modern text editing and copying workflows.

---

## Overview

BigClipboard is a native macOS application built with Swift 6.0 and SwiftUI that runs silently in the menu bar. It monitors the system pasteboard for copies, manages an in-memory history, persists history to a local JSON file, and provides a toggle to automatically strip text formatting (RTF, HTML, custom fonts) from newly copied items transparently.

## Motivation

Rich-text clipboard contents often carry unwanted fonts, colors, and hyperlinks that disrupt document formats upon pasting. Manually converting text to plain text is tedious. BigClipboard solves this by intercepting clipboard events to transparently strip styling (under 5ms) while preserving a robust, searchable history of your clips.

## Screenshots

*(Placeholder: Include a mockup of the status bar dropdown menu and the premium SwiftUI settings pane)*
![BigClipboard App Dropdown Menu](https://github.com/danielvm-git/big-clipboard-manager/raw/main/Assets/dropdown_preview.png)

## Tech Stack & Architecture

- **Language:** Swift 6.0
- **UI Framework:** SwiftUI (MenuBarExtra + standard Settings scene)
- **Deployment Target:** macOS 14.0+
- **Concurrency:** Swift Concurrency (actors, `@MainActor`)
- **Storage:** JSON serialization via `Codable` locally stored in `Application Support/com.danielvm.bigclipboard/history.json`, and `UserDefaults` for user settings.

## Features

- **Clipboard History Tracking:** High-performance background polling of `NSPasteboard.general` with duplicate prevention and history pruning.
- **Plain Text Auto-Strip Mode:** When enabled, automatically strips formatting (RTF, HTML, etc.) from copied text on the fly.
- **Ignored Applications Filter:** Exclude specific applications (e.g., password managers, IDEs) from being tracked.
- **Clips Management:** Dedicated UI to search, preview, and delete saved clips with confirmations.
- **Native & Lightweight:** 100% native Cocoa frameworks with zero third-party dependencies and minimal memory footprint.

## Code Example

Here is how BigClipboard reads the pasteboard, checks the originating app, and performs the auto-strip operation cleanly:

```swift
// Blacklist check using the originating bundle identifier
if let bundleId = activeBundleId, ignoredAppBundleIds.contains(bundleId) {
    JSONLogger.shared.info("ClipboardMonitor: Ignored copy from \(bundleId)")
    return
}

// Check if there are rich formatting representations on the pasteboard
let richTypes: [NSPasteboard.PasteboardType] = [.rtf, .rtfd, .html, .multipleTextSelection]
let hasRichFormat = pasteboard.types?.contains { richTypes.contains($0) } ?? false

if isAutoStripEnabled && hasRichFormat {
    // Write only plain text string back to system clipboard
    pasteboard.clearContents()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString(text, forType: .string)
    // Synchronize changeCount to avoid self-trigger loop on the next poll
    lastChangeCount = pasteboard.changeCount
}
```

## Prerequisites

- **Xcode 15.0+** (Swift 6.0 compatible)
- **macOS 14.0+**
- **xcodegen** (Project generation tool)

## Installation & Build

To set up the development environment and build the application locally:

```bash
# 1. Clone the repository
git clone https://github.com/danielvm-git/big-clipboard-manager.git
cd big-clipboard-manager

# 2. Run the environment setup (runs xcodegen to generate Xcode project)
./scripts/setup.sh

# 3. Build the application
xcodebuild -project BigClipboard.xcodeproj -scheme BigClipboard build

# 4. Launch the application
open build/Debug/BigClipboard.app
```

## Running Tests

We write headless unit tests using the modern Swift Testing framework. Run the tests using:

```bash
xcodebuild test -project BigClipboard.xcodeproj -scheme BigClipboard -only-testing BigClipboardTests
```

## Code Style

This project strictly adheres to the code guidelines detailed in [CONVENTIONS.md](file:///Users/danielvm/Developer/big-clipboard-manager/CONVENTIONS.md):
- Keep files under 300 lines.
- Keep functions under 20 lines.
- Native Cocoa frameworks only (no external Swift Packages).
- Thread-safe `@MainActor` clipboard interactions.

## Observability

Monitor application logs and run-time state:

| Diagnostic | Command |
|---|---|
| **View logs** | `tail -f ~/Library/Application\ Support/com.danielvm.bigclipboard/app.log` |
| **Health check** | `pgrep BigClipboard && echo "App is running" || echo "App is not running"` |

## Contributing

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/my-new-feature`).
3. Commit your changes using Conventional Commits (`git commit -m 'feat: add new feature'`).
4. Push to the branch (`git push origin feature/my-new-feature`).
5. Open a Pull Request.

## License

This project is licensed under the MIT License.

## Credits

Built with [bigpowers](https://github.com/danielvm-git/bigpowers).
