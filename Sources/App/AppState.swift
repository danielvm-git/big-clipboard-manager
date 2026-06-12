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
    
    public var isAutoStripEnabled: Bool {
        didSet {
            monitor.isAutoStripEnabled = isAutoStripEnabled
            UserDefaults.standard.set(isAutoStripEnabled, forKey: "isAutoStripEnabled")
        }
    }
    
    public var isLaunchAtStartupEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isLaunchAtStartupEnabled, forKey: "isLaunchAtStartupEnabled")
            do {
                try StartupManager.shared.setEnabled(isLaunchAtStartupEnabled)
            } catch {
                print("AppState: Failed to set launch at startup state: \(error)")
            }
        }
    }
    
    public var maxRememberedClips: Int {
        didSet {
            monitor.maxRememberedClips = maxRememberedClips
            UserDefaults.standard.set(maxRememberedClips, forKey: "maxRememberedClips")
        }
    }
    
    public var maxDisplayClips: Int {
        didSet {
            UserDefaults.standard.set(maxDisplayClips, forKey: "maxDisplayClips")
        }
    }
    
    public let monitor: ClipboardMonitor
    private let storage: StorageManager
    private let paster = ClipboardPaster()
    
    public init() {
        let recording = UserDefaults.standard.object(forKey: "isRecordingEnabled") as? Bool ?? true
        let autoStrip = UserDefaults.standard.bool(forKey: "isAutoStripEnabled")
        let launchAtStartup = UserDefaults.standard.bool(forKey: "isLaunchAtStartupEnabled")
        var limit = UserDefaults.standard.integer(forKey: "maxRememberedClips")
        if limit <= 0 || limit > 9999 {
            limit = 80
        }
        
        var displayLimit = UserDefaults.standard.integer(forKey: "maxDisplayClips")
        if displayLimit <= 0 || displayLimit > 100 {
            displayLimit = 20
        }
        
        self.isRecordingEnabled = recording
        self.isAutoStripEnabled = autoStrip
        self.isLaunchAtStartupEnabled = launchAtStartup
        self.maxRememberedClips = limit
        self.maxDisplayClips = displayLimit
        
        // Sync launch at startup setting with system registration
        do {
            try StartupManager.shared.setEnabled(launchAtStartup)
        } catch {
            print("AppState: Failed to sync initial launch at startup registration: \(error)")
        }
        
        let storageManager = StorageManager()
        self.storage = storageManager
        
        let initialClips = storageManager.loadHistory()
        self.monitor = ClipboardMonitor(initialClips: initialClips)
        self.monitor.isRecordingEnabled = recording
        self.monitor.isAutoStripEnabled = autoStrip
        self.monitor.maxRememberedClips = limit
        self.clips = self.monitor.clips
        
        self.monitor.onHistoryChanged = { [weak self] newClips in
            self?.clips = newClips
            self?.storage.saveHistoryAsync(newClips)
        }
        
        self.monitor.startPolling()
    }
    
    public func selectAndPasteClip(_ clip: Clip) {
        paster.copyAndPaste(text: clip.text)
    }
    
    public func deleteClip(_ clip: Clip) {
        monitor.deleteClip(id: clip.id)
    }
    
    public func clearHistory() {
        monitor.clearHistory()
    }
}
