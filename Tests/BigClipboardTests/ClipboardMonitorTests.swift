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
