import SwiftUI

@main
struct BigClipboardApp: App {
    var body: some Scene {
        MenuBarExtra("BigClipboard", systemImage: "paperclip") {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
