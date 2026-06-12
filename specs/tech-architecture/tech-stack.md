# Technical Stack & Architecture

## Core Technologies
- **Language:** Swift 6.0
- **UI Framework:** SwiftUI (MenuBarExtra + standard Settings scene)
- **Deployment Target:** macOS 14.0+ (utilizes modern SwiftUI APIs)
- **Concurrency:** Swift Concurrency (actors, @MainActor)
- **Storage:** JSON serialization using `Codable` saved locally in `Application Support/com.danielvm.bigclipboard/history.json` and `UserDefaults` for user settings.

## System Integrations
- **Clipboard Monitoring:** Custom polling mechanism that checks `NSPasteboard.general.changeCount` every 500ms.
- **Plain Text Stripping:** Reads clipboard text contents, wipes existing formatting representations, and writes back only `NSPasteboard.PasteboardType.string` data.
- **Launch at Startup:** Implemented via standard macOS `SMAppService.mainApp` API.
- **Ignored Apps Filtration:** Uses `NSWorkspace.shared.frontmostApplication` to retrieve the bundle identifier of the application originating the clipboard operation.

## File Organization
- `Sources/App/`: Application life cycle (`BigClipboardApp.swift`) and main coordinator state (`AppState.swift`).
- `Sources/Core/`: Clipboard polling logic, formatting stripper, database/file manager, ignored apps configuration, launch manager.
- `Sources/UI/`: Menu bar dropdown representation, preference tabs (General, Ignored Apps, Clips Management, About).
- `Tests/BigClipboardTests/`: Unit tests leveraging the Swift Testing framework.
