import Foundation

/// Recent rolls made in the app, newest first. Kept in memory only.
public struct RollHistory: Equatable, Sendable {
    public struct Entry: Equatable, Identifiable, Sendable {
        public let id: UUID
        public let spec: RollSpec
        public let result: RollResult
        public let date: Date
    }

    public static let capacity = 10

    public private(set) var entries: [Entry] = []

    public init() {}

    public mutating func add(spec: RollSpec, result: RollResult, date: Date = Date()) {
        entries.insert(Entry(id: UUID(), spec: spec, result: result, date: date), at: 0)
        if entries.count > Self.capacity {
            entries.removeLast()
        }
    }
}
