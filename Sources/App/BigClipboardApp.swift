import SwiftUI

@main
struct BigClipboardApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra("BigClipboard", systemImage: "paperclip") {
            DropdownMenu(appState: appState)
        }
    }
}
