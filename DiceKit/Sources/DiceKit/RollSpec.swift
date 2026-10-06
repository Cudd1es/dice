public enum RollMode: String, Codable, CaseIterable, Sendable {
    case normal, advantage, disadvantage
}

public enum RollSpecError: Error, Equatable {
    case invalidSides(Int)
    case invalidCount(Int)
    case invalidModifier(Int)
    case invalidDC(Int)
    case modeRequiresSingleD20
}

/// What to roll: dice count and size, advantage mode, flat modifier and optional DC.
public struct RollSpec: Codable, Equatable, Sendable {
    public static let allowedSides = [4, 6, 8, 10, 12, 20, 100]
    public static let countRange = 1...20
    public static let modifierRange = -20...20
    public static let dcRange = 1...999

    public var count: Int
    public var sides: Int
    public var mode: RollMode
    public var modifier: Int
    public var dc: Int?

    public init(count: Int = 1, sides: Int = 20, mode: RollMode = .normal, modifier: Int = 0, dc: Int? = nil) {
        self.count = count
        self.sides = sides
        self.mode = mode
        self.modifier = modifier
        self.dc = dc
    }

    public var isSingleD20: Bool { count == 1 && sides == 20 }

    /// Advantage and disadvantage roll two d20s; otherwise one die per `count`.
    public var diceToRoll: Int { mode == .normal ? count : 2 }

    public func validate() throws {
        guard Self.allowedSides.contains(sides) else { throw RollSpecError.invalidSides(sides) }
        guard Self.countRange.contains(count) else { throw RollSpecError.invalidCount(count) }
        guard Self.modifierRange.contains(modifier) else { throw RollSpecError.invalidModifier(modifier) }
        if let dc, !Self.dcRange.contains(dc) { throw RollSpecError.invalidDC(dc) }
        if mode != .normal && !isSingleD20 { throw RollSpecError.modeRequiresSingleD20 }
    }

    /// Drops advantage/disadvantage when the spec is no longer a single d20.
    public func normalized() -> RollSpec {
        var copy = self
        if !isSingleD20 { copy.mode = .normal }
        return copy
    }
}
