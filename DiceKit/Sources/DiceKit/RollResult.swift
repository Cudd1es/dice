public enum Critical: String, Codable, Sendable {
    case none, success, failure
}

public enum DCOutcome: String, Codable, Sendable {
    case success, failure
}

/// What was rolled, and what it adds up to.
public struct RollResult: Codable, Equatable, Sendable {
    /// Every main die rolled, in roll order.
    public let dice: [Int]
    /// Indices into `dice` that count toward `total`.
    public let keptIndices: [Int]
    /// Each bonus group's dice, aligned with `RollSpec.extras`; all of them count.
    public let bonusRolls: [[Int]]
    public let total: Int
    public let critical: Critical
    public let dcOutcome: DCOutcome?

    init(dice: [Int], keptIndices: [Int], bonusRolls: [[Int]] = [], total: Int, critical: Critical, dcOutcome: DCOutcome?) {
        self.dice = dice
        self.keptIndices = keptIndices
        self.bonusRolls = bonusRolls
        self.total = total
        self.critical = critical
        self.dcOutcome = dcOutcome
    }
}
