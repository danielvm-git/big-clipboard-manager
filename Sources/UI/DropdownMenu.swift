import SwiftUI

@MainActor
public struct DropdownMenu: View {
    let appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        Button(appState.isAutoStripEnabled ? "✓ Auto-Strip Formatting" : "Auto-Strip Formatting") {
            appState.isAutoStripEnabled.toggle()
        }
        
        Divider()
        
        let displayed = Array(appState.clips.prefix(appState.maxDisplayClips))
        if displayed.isEmpty {
            Button("No Clips Stored") {}
                .disabled(true)
        } else {
            ForEach(Array(displayed.enumerated()), id: \.element.id) { index, clip in
                if index < 10 {
                    Button {
                        appState.selectAndPasteClip(clip)
                    } label: {
                        Text(formatClipText(clip.text))
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: .command)
                } else {
                    Button {
                        appState.selectAndPasteClip(clip)
                    } label: {
                        Text(formatClipText(clip.text))
                    }
                }
            }
        }
        
        Divider()
        
        Button("Delete All History") {
            appState.clearHistory()
        }
        
        Button("Preferences...") {
            // Open Preferences Window (standard SwiftUI Settings window)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",", modifiers: .command)
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
    
    private func formatClipText(_ text: String) -> String {
        // Clean linebreaks for menu display and truncate
        let singleLine = text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if singleLine.count > 40 {
            return String(singleLine.prefix(40)) + "..."
        }
        return singleLine
    }
}
