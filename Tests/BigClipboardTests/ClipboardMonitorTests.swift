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
        
        for i in 1...5 {
            pboard.clearContents()
            pboard.declareTypes([.string], owner: nil)
            pboard.setString("item-\(i)", forType: .string)
            monitor.checkPasteboard()
        }
        
        #expect(monitor.clips.count == 3)
        #expect(monitor.clips.first?.text == "item-5")
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
}
