import Foundation

@MainActor
public final class StorageManager: Sendable {
    private let fileManager = FileManager.default
    private let folderName = "com.danielvm.bigclipboard"
    private let fileName = "history.json"
    
    // We keep track of the active write task using a MainActor property
    private var writeTask: Task<Void, Never>? = nil
    
    public init() {}
    
    private var applicationSupportDirectoryURL: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportDir = paths[0].appendingPathComponent(folderName, isDirectory: true)
        return appSupportDir
    }
    
    private var historyFileURL: URL {
        return applicationSupportDirectoryURL.appendingPathComponent(fileName)
    }
    
    public func loadHistory() -> [Clip] {
        let fileURL = historyFileURL
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let clips = try decoder.decode([Clip].self, from: data)
            return clips
        } catch {
            let corruptedURL = fileURL.deletingLastPathComponent().appendingPathComponent("history.corrupted.json")
            // Try to backup the corrupted file, removing existing corrupted backup if present
            try? fileManager.removeItem(at: corruptedURL)
            try? fileManager.moveItem(at: fileURL, to: corruptedURL)
            print("StorageManager error: Corrupted history file found. Backup created. Fallback to empty list.")
            return []
        }
    }
    
    public func saveHistoryAsync(_ clips: [Clip]) {
        // Cancel the previous write task to debounce/coalesce writes
        writeTask?.cancel()
        
        let url = historyFileURL
        let directoryURL = applicationSupportDirectoryURL
        
        writeTask = Task {
            do {
                // Wait for 500ms to coalesce rapid copy/paste events
                try await Task.sleep(nanoseconds: 500_000_000)
                
                guard !Task.isCancelled else { return }
                
                // Encode using JSONEncoder
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(clips)
                
                guard !Task.isCancelled else { return }
                
                // Create directory if missing
                if !fileManager.fileExists(atPath: directoryURL.path) {
                    try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                }
                
                // Write atomically
                try data.write(to: url, options: .atomic)
            } catch is CancellationError {
                // Swallowed: task was cancelled
            } catch {
                print("StorageManager write failure: \(error)")
            }
        }
    }
}
