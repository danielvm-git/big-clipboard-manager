import Testing
import AppKit
import Foundation
@testable import BigClipboard

@Suite("ClipboardMonitor Tests")
@MainActor
struct ClipboardMonitorTests {
    
    @Test func testClipboardPollingAndDuplicates() async throws {
        let monitor = ClipboardMonitor()
        monitor.maxRememberedClips = 5
        
        let pboard = NSPasteboard.general
        pboard.clearContents()
        
        // Write item 1
        pboard.declareTypes([.string], owner: nil)
        pboard.setString("test-1", forType: .string)
        
        // Manually trigger check
        monitor.checkPasteboard()
        
        #expect(monitor.clips.count == 1)
        #expect(monitor.clips.first?.text == "test-1")
        
        // Try duplicate copy
        pboard.declareTypes([.string], owner: nil)
        pboard.setString("test-1", forType: .string)
        monitor.checkPasteboard()
        
        #expect(monitor.clips.count == 1) // Should remain 1
        
        // Write item 2
        pboard.declareTypes([.string], owner: nil)
        pboard.setString("test-2", forType: .string)
        monitor.checkPasteboard()
        
        #expect(monitor.clips.count == 2)
        #expect(monitor.clips.first?.text == "test-2")
    }
    
    @Test func testClippingLimits() async throws {
        let monitor = ClipboardMonitor()
        monitor.maxRememberedClips = 3
        
        let pboard = NSPasteboard.general
        
        for index in 1...5 {
            pboard.clearContents()
            pboard.declareTypes([.string], owner: nil)
            pboard.setString("item-\(index)", forType: .string)
            monitor.checkPasteboard()
        }
        
        #expect(monitor.clips.count == 3)
        #expect(monitor.clips.first?.text == "item-5")
    }
    
    @Test func testAutoStripFormatting() async throws {
        let monitor = ClipboardMonitor()
        monitor.isAutoStripEnabled = true
        
        let pboard = NSPasteboard.general
        pboard.clearContents()
        
        pboard.declareTypes([.string, .rtf], owner: nil)
        pboard.setString("styled-text", forType: .string)
        pboard.setData("{\\rtf1 styled-text}".data(using: .utf8)!, forType: .rtf)
        
        monitor.checkPasteboard()
        
        #expect(monitor.clips.count == 1)
        #expect(monitor.clips.first?.text == "styled-text")
        
        let types = pboard.types ?? []
        #expect(types.contains(.string))
        #expect(!types.contains(.rtf))
    }
    
    @Test func testAutoStripDisabledPreservesFormatting() async throws {
        let monitor = ClipboardMonitor()
        monitor.isAutoStripEnabled = false
        
        let pboard = NSPasteboard.general
        pboard.clearContents()
        
        pboard.declareTypes([.string, .rtf], owner: nil)
        pboard.setString("styled-text-2", forType: .string)
        pboard.setData("{\\rtf1 styled-text-2}".data(using: .utf8)!, forType: .rtf)
        
        monitor.checkPasteboard()
        
        #expect(monitor.clips.count == 1)
        #expect(monitor.clips.first?.text == "styled-text-2")
        
        let types = pboard.types ?? []
        #expect(types.contains(.string))
        #expect(types.contains(.rtf))
    }
}

@Suite("StorageManager Tests")
@MainActor
struct StorageManagerTests {
    
    @Test func testStorageLoadAndSave() async throws {
        let storage = StorageManager()
        
        let fileManager = FileManager.default
        let appSupportPaths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let fileURL = appSupportPaths[0].appendingPathComponent("com.danielvm.bigclipboard/history.json")
        try? fileManager.removeItem(at: fileURL)
        
        // Initial load should be empty
        let initialClips = storage.loadHistory()
        #expect(initialClips.isEmpty)
        
        // Save clips
        let clips = [
            Clip(text: "clip-a"),
            Clip(text: "clip-b")
        ]
        storage.saveHistoryAsync(clips)
        
        // Wait for throttled write (500ms sleep + buffer)
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Load again
        let loaded = storage.loadHistory()
        #expect(loaded.count == 2)
        #expect(loaded[0].text == "clip-a")
        #expect(loaded[1].text == "clip-b")
    }
    
    @Test func testStorageThrottling() async throws {
        let storage = StorageManager()
        
        let fileManager = FileManager.default
        let appSupportPaths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let fileURL = appSupportPaths[0].appendingPathComponent("com.danielvm.bigclipboard/history.json")
        try? fileManager.removeItem(at: fileURL)
        
        // Rapid updates: only the final one should write
        storage.saveHistoryAsync([Clip(text: "first")])
        try await Task.sleep(nanoseconds: 100_000_000)
        storage.saveHistoryAsync([Clip(text: "second")])
        try await Task.sleep(nanoseconds: 100_000_000)
        storage.saveHistoryAsync([Clip(text: "third")])
        
        // Wait for final throttle timer to expire
        try await Task.sleep(nanoseconds: 600_000_000)
        
        let loaded = storage.loadHistory()
        #expect(loaded.count == 1)
        #expect(loaded.first?.text == "third")
    }
    
    @Test func testStorageCorruptedLoad() async throws {
        let storage = StorageManager()
        
        let fileManager = FileManager.default
        let appSupportPaths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dirURL = appSupportPaths[0].appendingPathComponent("com.danielvm.bigclipboard")
        let fileURL = dirURL.appendingPathComponent("history.json")
        let corruptedURL = dirURL.appendingPathComponent("history.corrupted.json")
        
        try? fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
        try? fileManager.removeItem(at: fileURL)
        try? fileManager.removeItem(at: corruptedURL)
        
        // Write invalid data
        let invalidData = "corrupted-json-data".data(using: .utf8)!
        try invalidData.write(to: fileURL)
        
        // Load should fallback to empty and move to corrupted
        let loaded = storage.loadHistory()
        #expect(loaded.isEmpty)
        #expect(fileManager.fileExists(atPath: corruptedURL.path))
        #expect(!fileManager.fileExists(atPath: fileURL.path))
    }
    
    @Test func testStartupManagerToggling() async throws {
        let state = AppState()
        state.isLaunchAtStartupEnabled = true
        #expect(UserDefaults.standard.bool(forKey: "isLaunchAtStartupEnabled") == true)
        
        state.isLaunchAtStartupEnabled = false
        #expect(UserDefaults.standard.bool(forKey: "isLaunchAtStartupEnabled") == false)
    }
}

@Suite("AppState Settings Tests")
@MainActor
struct AppStateSettingsTests {
    @Test func testSettingsDefaultsAndUpdates() async throws {
        // Clear existing keys to test defaults
        UserDefaults.standard.removeObject(forKey: "maxRememberedClips")
        UserDefaults.standard.removeObject(forKey: "maxDisplayClips")
        
        let state = AppState()
        #expect(state.maxRememberedClips == 80)
        #expect(state.maxDisplayClips == 20)
        
        // Update limits
        state.maxRememberedClips = 150
        state.maxDisplayClips = 50
        
        #expect(UserDefaults.standard.integer(forKey: "maxRememberedClips") == 150)
        #expect(UserDefaults.standard.integer(forKey: "maxDisplayClips") == 50)
    }
    
    @Test func testClipsTrimmingOnLimitChange() async throws {
        let state = AppState()
        state.maxRememberedClips = 10
        
        // Add 10 clips manually to the monitor
        let monitor = state.monitor
        monitor.clearHistory()
        
        let pboard = NSPasteboard.general
        for index in 1...10 {
            pboard.clearContents()
            pboard.declareTypes([.string], owner: nil)
            pboard.setString("clip-\(index)", forType: .string)
            monitor.checkPasteboard()
        }
        
        #expect(monitor.clips.count == 10)
        
        // Decrease limits to 5, it should automatically trim
        state.maxRememberedClips = 5
        #expect(monitor.clips.count == 5)
        #expect(monitor.clips.first?.text == "clip-10")
    }
    
    @Test func testIgnoredApplicationsBlacklist() async throws {
        let state = AppState()
        let monitor = state.monitor
        monitor.clearHistory()
        
        // Add an ignored app bundle ID
        state.ignoredAppBundleIds = ["com.agilebits.onepassword-osx"]
        
        // Mock frontmost application to be 1Password
        monitor.testFrontmostBundleIdProvider = {
            "com.agilebits.onepassword-osx"
        }
        
        let pboard = NSPasteboard.general
        pboard.clearContents()
        pboard.declareTypes([.string], owner: nil)
        pboard.setString("secret-password", forType: .string)
        
        // Trigger check
        monitor.checkPasteboard()
        
        // It should be ignored!
        #expect(monitor.clips.isEmpty)
        
        // Now mock frontmost application to be Safari (not ignored)
        monitor.testFrontmostBundleIdProvider = {
            "com.apple.Safari"
        }
        
        pboard.clearContents()
        pboard.declareTypes([.string], owner: nil)
        pboard.setString("public Safari text", forType: .string)
        monitor.checkPasteboard()
        
        // It should be recorded!
        #expect(monitor.clips.count == 1)
        #expect(monitor.clips.first?.text == "public Safari text")
        
        // Now mock frontmost app to return nil (fallback)
        monitor.testFrontmostBundleIdProvider = {
            nil
        }
        
        pboard.clearContents()
        pboard.declareTypes([.string], owner: nil)
        pboard.setString("anonymous text", forType: .string)
        monitor.checkPasteboard()
        
        // It should be recorded!
        #expect(monitor.clips.count == 2)
        #expect(monitor.clips.first?.text == "anonymous text")
    }
    
    @Test func testClipsSearchAndFiltering() async throws {
        let state = AppState()
        let monitor = state.monitor
        monitor.clearHistory()
        
        let pboard = NSPasteboard.general
        let items = ["XcodeGen build", "git status", "xcodebuild test"]
        
        for item in items {
            pboard.clearContents()
            pboard.declareTypes([.string], owner: nil)
            pboard.setString(item, forType: .string)
            monitor.checkPasteboard()
        }
        
        #expect(state.clips.count == 3)
        
        // Let's filter case-insensitive for "xcode"
        let filtered = state.clips.filter { $0.text.localizedCaseInsensitiveContains("xcode") }
        #expect(filtered.count == 2)
        #expect(filtered.contains { $0.text == "XcodeGen build" })
        #expect(filtered.contains { $0.text == "xcodebuild test" })
        #expect(!filtered.contains { $0.text == "git status" })
    }
    
    @Test func testClipsDeletionAndConfirmationPreferences() async throws {
        UserDefaults.standard.removeObject(forKey: "confirmBeforeDeleting")
        
        let state = AppState()
        #expect(state.confirmBeforeDeleting == true) // default
        
        state.confirmBeforeDeleting = false
        #expect(UserDefaults.standard.bool(forKey: "confirmBeforeDeleting") == false)
        
        // Add a clip
        state.monitor.clearHistory()
        let pboard = NSPasteboard.general
        pboard.clearContents()
        pboard.declareTypes([.string], owner: nil)
        pboard.setString("test-delete-item", forType: .string)
        state.monitor.checkPasteboard()
        
        #expect(state.clips.count == 1)
        let clip = try #require(state.clips.first)
        
        // Delete it
        state.deleteClip(clip)
        #expect(state.clips.isEmpty)
    }
}

