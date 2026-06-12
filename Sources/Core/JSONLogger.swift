import Foundation

/// A thread-safe, structured JSON logger that writes to stdout and a local log file.
public final class JSONLogger: @unchecked Sendable {
    public static let shared = JSONLogger()

    private let lock = NSLock()
    private let fileManager = FileManager.default
    private let folderName = "com.danielvm.bigclipboard"
    private let fileName = "app.log"
    private let dateFormatter: ISO8601DateFormatter

    private var logFileURL: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportDir = paths[0].appendingPathComponent(folderName, isDirectory: true)
        return appSupportDir.appendingPathComponent(fileName)
    }

    private init() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.dateFormatter = formatter

        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportDir = paths[0].appendingPathComponent(folderName, isDirectory: true)
        if !fileManager.fileExists(atPath: appSupportDir.path) {
            try? fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func formatLog(level: String, message: String, metadata: [String: String]?) -> String? {
        let timestamp = dateFormatter.string(from: Date())

        var dict: [String: Any] = [
            "level": level,
            "timestamp": timestamp,
            "message": message
        ]

        if let metadata = metadata {
            metadata.forEach { dict[$0.key] = $0.value }
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }

    private func appendToFile(jsonString: String) {
        let url = logFileURL
        let data = Data("\(jsonString)\n".utf8)

        if fileManager.fileExists(atPath: url.path) {
            if let fileHandle = try? FileHandle(forWritingTo: url) {
                defer { try? fileHandle.close() }
                _ = try? fileHandle.seekToEnd()
                try? fileHandle.write(contentsOf: data)
            }
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func log(level: String, message: String, metadata: [String: String]? = nil) {
        lock.lock()
        defer { lock.unlock() }

        guard let jsonString = formatLog(level: level, message: message, metadata: metadata) else {
            return
        }

        print(jsonString)
        appendToFile(jsonString: jsonString)
    }

    public func info(_ message: String, metadata: [String: String]? = nil) {
        log(level: "info", message: message, metadata: metadata)
    }

    public func warn(_ message: String, metadata: [String: String]? = nil) {
        log(level: "warning", message: message, metadata: metadata)
    }

    public func error(_ message: String, error: (any Error)? = nil, metadata: [String: String]? = nil) {
        var mergedMetadata = metadata ?? [:]
        if let error = error {
            mergedMetadata["error"] = error.localizedDescription
        }
        log(level: "error", message: message, metadata: mergedMetadata)
    }

    public func debug(_ message: String, metadata: [String: String]? = nil) {
        log(level: "debug", message: message, metadata: metadata)
    }
}
