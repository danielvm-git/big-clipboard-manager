import Cocoa
import CoreGraphics

@MainActor
public final class ClipboardPaster: Sendable {
    public init() {}
    
    public func copyAndPaste(text: String) {
        // Copy back to general pasteboard
        let pboard = NSPasteboard.general
        pboard.clearContents()
        pboard.declareTypes([.string], owner: nil)
        pboard.setString(text, forType: .string)
        
        // Asynchronously post the cmd+v keystrokes to let Launch Services settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let source = CGEventSource(stateID: .combinedSessionState)
            
            // Virtual keycode for 'v' is 9
            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true) else { return }
            keyDown.flags = .maskCommand
            
            guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { return }
            keyUp.flags = .maskCommand
            
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
