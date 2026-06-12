import Testing
import Foundation
@testable import BigClipboard

@Suite("JSONLogger Tests")
struct JSONLoggerTests {
    private var logFileURL: URL {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportDir = paths[0].appendingPathComponent("com.danielvm.bigclipboard", isDirectory: true)
        return appSupportDir.appendingPathComponent("app.log")
    }

    private func parseLastMatchingLogLine(query: String) throws -> [String: Any] {
        let fileManager = FileManager.default
        let url = logFileURL
        #expect(fileManager.fileExists(atPath: url.path))
        let logData = try Data(contentsOf: url)
        let logString = try #require(String(data: logData, encoding: .utf8))
        let lines = logString.split(separator: "\n")
        let matchingLine = try #require(lines.first { $0.contains(query) })
        let jsonData = try #require(matchingLine.data(using: .utf8))
        return try #require(JSONSerialization.jsonObject(with: jsonData) as? [String: Any])
    }

    @Test func testJSONLoggerOutputsValidJSON() async throws {
        let url = logFileURL
        try? FileManager.default.removeItem(at: url)

        let uniqueMessage = "Test log message \(UUID().uuidString)"
        JSONLogger.shared.info(uniqueMessage, metadata: ["testKey": "testVal"])

        let jsonObject = try parseLastMatchingLogLine(query: uniqueMessage)
        #expect(jsonObject["level"] as? String == "info")
        #expect(jsonObject["message"] as? String == uniqueMessage)
        #expect(jsonObject["testKey"] as? String == "testVal")
        #expect(jsonObject["timestamp"] != nil)
    }

    @Test func testJSONLoggerErrorsWithMetadata() async throws {
        let url = logFileURL
        try? FileManager.default.removeItem(at: url)

        let uniqueMessage = "Test error message"
        let error = NSError(
            domain: "test.domain",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Sample error details"]
        )
        JSONLogger.shared.error(uniqueMessage, error: error, metadata: ["extra": "metadata"])

        let jsonObject = try parseLastMatchingLogLine(query: uniqueMessage)
        #expect(jsonObject["level"] as? String == "error")
        #expect(jsonObject["message"] as? String == uniqueMessage)
        #expect(jsonObject["error"] as? String == "Sample error details")
        #expect(jsonObject["extra"] as? String == "metadata")
        #expect(jsonObject["timestamp"] != nil)
    }
}
