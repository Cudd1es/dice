public enum Critical: String, Codable, Sendable {
    case none, success, failure
}

public enum DCOutcome: String, Codable, Sendable {
    case success, failure
}

/// What was rolled, and what it adds up to.
public struct RollResult: Codable, Equatable, Sendable {
    /// Every die rolled, in roll order.
    public let dice: [Int]
    /// Indices into `dice` that count toward `total`.
    public let keptIndices: [Int]
    public let total: Int
    public let critical: Critical
    public let dcOutcome: DCOutcome?
}
