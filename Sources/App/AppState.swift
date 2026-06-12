import SwiftUI
import Combine

@Observable
@MainActor
public final class AppState {
    public var clips: [Clip] = []
    
    public var isRecordingEnabled: Bool {
        didSet {
            monitor.isRecordingEnabled = isRecordingEnabled
            UserDefaults.standard.set(isRecordingEnabled, forKey: "isRecordingEnabled")
        }
    }
    
    public var maxRememberedClips: Int {
        didSet {
            monitor.maxRememberedClips = maxRememberedClips
            UserDefaults.standard.set(maxRememberedClips, forKey: "maxRememberedClips")
        }
    }
    
    public let monitor: ClipboardMonitor
    
    public init() {
        let recording = UserDefaults.standard.object(forKey: "isRecordingEnabled") as? Bool ?? true
        var limit = UserDefaults.standard.integer(forKey: "maxRememberedClips")
        if limit <= 0 {
            limit = 80
        }
        
        self.isRecordingEnabled = recording
        self.maxRememberedClips = limit
        
        let initialClips: [Clip] = []
        self.monitor = ClipboardMonitor(initialClips: initialClips)
        self.monitor.isRecordingEnabled = recording
        self.monitor.maxRememberedClips = limit
        self.clips = self.monitor.clips
        
        self.monitor.onHistoryChanged = { [weak self] newClips in
            self?.clips = newClips
        }
        
        self.monitor.startPolling()
    }
}
