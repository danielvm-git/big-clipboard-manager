import Foundation

public struct Clip: Identifiable, Codable, Equatable {
    public let id: UUID
    public let text: String
    public let timestamp: Date
    
    public init(id: UUID = UUID(), text: String, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
    }
}
