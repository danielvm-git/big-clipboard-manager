import AppKit
import Foundation

@MainActor
public final class ClipboardMonitor: Sendable {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    
    public var onHistoryChanged: (@MainActor ([Clip]) -> Void)?
    public private(set) var clips: [Clip] = []
    
    public var maxRememberedClips: Int = 80 {
        didSet {
            trimHistory()
        }
    }
    public var isRecordingEnabled: Bool = true
    public var isAutoStripEnabled: Bool = false
    public var ignoredAppBundleIds: [String] = []
    
    /// Optional closure to mock frontmost application bundle ID in unit tests.
    public var testFrontmostBundleIdProvider: (@MainActor () -> String?)?
    
    public init(initialClips: [Clip] = []) {
        self.clips = initialClips
        self.lastChangeCount = pasteboard.changeCount
    }
    
    public func startPolling() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPasteboard()
            }
        }
    }
    
    public func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    public func checkPasteboard() {
        guard isRecordingEnabled else { return }
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        // Read plain string
        guard let text = pasteboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Blacklist check
        let activeBundleId: String?
        if let provider = testFrontmostBundleIdProvider {
            activeBundleId = provider()
        } else {
            activeBundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        }
        
        if let bundleId = activeBundleId {
            if ignoredAppBundleIds.contains(bundleId) {
                JSONLogger.shared.info("ClipboardMonitor: Ignored copy from \(bundleId)", metadata: [
                    "bundleId": bundleId,
                    "textLength": String(text.count)
                ])
                return
            }
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
        
        // Duplicate check (consecutive duplicate)
        if let first = clips.first, first.text == text {
            return
        }
        
        // Create and add new clip
        let clip = Clip(text: text)
        clips.insert(clip, at: 0)
        
        // Trim
        if clips.count > maxRememberedClips {
            clips = Array(clips.prefix(maxRememberedClips))
        }
        
        onHistoryChanged?(clips)
    }
    
    public func clearHistory() {
        clips.removeAll()
        onHistoryChanged?(clips)
    }
    
    public func deleteClip(id: UUID) {
        clips.removeAll { $0.id == id }
        onHistoryChanged?(clips)
    }
    
    public func setHistory(_ newClips: [Clip]) {
        clips = newClips
        // Trim in case loaded history exceeds current limit
        if clips.count > maxRememberedClips {
            clips = Array(clips.prefix(maxRememberedClips))
        }
        onHistoryChanged?(clips)
    }
    
    private func trimHistory() {
        if clips.count > maxRememberedClips {
            clips = Array(clips.prefix(maxRememberedClips))
            onHistoryChanged?(clips)
        }
    }
}
