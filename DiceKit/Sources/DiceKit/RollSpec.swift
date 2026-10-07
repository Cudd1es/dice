public enum RollMode: String, Codable, CaseIterable, Sendable {
    case normal, advantage, disadvantage
}

public enum RollSpecError: Error, Equatable {
    case invalidSides(Int)
    case invalidCount(Int)
    case invalidModifier(Int)
    case invalidDC(Int)
    case modeRequiresSingleD20
    /// Too many groups, a bad count or size, or the same kind listed twice.
    case invalidExtras
}

/// What to roll: the main dice (count and size, advantage mode), bonus dice, a flat modifier and an optional DC.
public struct RollSpec: Codable, Equatable, Sendable {
    public static let allowedSides = [4, 6, 8, 10, 12, 20, 100]
    public static let countRange = 1...20
    public static let modifierRange = -20...20
    public static let dcRange = 1...999
    public static let maxExtras = 4

    public var count: Int
    public var sides: Int
    public var mode: RollMode
    public var modifier: Int
    public var dc: Int?
    /// Extra dice groups after the main dice, in the order they were added.
    public var extras: [BonusDice]
    /// House rule: whether a natural 20 / 1 on a single main d20 is a critical success / failure that decides the DC.
    /// Off, only the total is compared with the DC.
    public var criticalsEnabled: Bool

    public init(count: Int = 1, sides: Int = 20, mode: RollMode = .normal, modifier: Int = 0, dc: Int? = nil,
                extras: [BonusDice] = [], criticalsEnabled: Bool = true) {
        self.count = count
        self.sides = sides
        self.mode = mode
        self.modifier = modifier
        self.dc = dc
        self.extras = extras
        self.criticalsEnabled = criticalsEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case count, sides, mode, modifier, dc, extras, criticalsEnabled
    }

    /// Formulas saved by 0.3.x have no `extras` key; those before 0.6.0 have no `criticalsEnabled` key.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try container.decode(Int.self, forKey: .count)
        sides = try container.decode(Int.self, forKey: .sides)
        mode = try container.decode(RollMode.self, forKey: .mode)
        modifier = try container.decode(Int.self, forKey: .modifier)
        dc = try container.decodeIfPresent(Int.self, forKey: .dc)
        extras = try container.decodeIfPresent([BonusDice].self, forKey: .extras) ?? []
        criticalsEnabled = try container.decodeIfPresent(Bool.self, forKey: .criticalsEnabled) ?? true
    }

    public var isSingleD20: Bool { count == 1 && sides == 20 }

    /// Advantage and disadvantage roll two d20s; otherwise one die per `count`.
    public var diceToRoll: Int { mode == .normal ? count : 2 }

    /// Main dice plus every bonus die.
    public var totalDiceCount: Int { diceToRoll + extras.reduce(0) { $0 + $1.count } }

    /// True when `count` dice can merge into an existing group or open a new one without passing the limits.
    public func canAddBonus(sign: BonusDice.Sign, sides: Int, count: Int = 1) -> Bool {
        guard BonusDice.allowedSides.contains(sides), BonusDice.countRange.contains(count) else { return false }
        if let group = extras.first(where: { $0.sign == sign && $0.sides == sides }) {
            return group.count + count <= BonusDice.countRange.upperBound
        }
        return extras.count < Self.maxExtras
    }

    /// Adds `count` dice of this kind, merging into an existing group. Past the limits it does nothing rather
    /// than adding part of them.
    public mutating func addBonus(sign: BonusDice.Sign, sides: Int, count: Int = 1) {
        guard canAddBonus(sign: sign, sides: sides, count: count) else { return }
        if let index = extras.firstIndex(where: { $0.sign == sign && $0.sides == sides }) {
            extras[index].count += count
        } else {
            extras.append(BonusDice(sign: sign, count: count, sides: sides))
        }
    }

    public func validate() throws {
        guard Self.allowedSides.contains(sides) else { throw RollSpecError.invalidSides(sides) }
        guard Self.countRange.contains(count) else { throw RollSpecError.invalidCount(count) }
        guard Self.modifierRange.contains(modifier) else { throw RollSpecError.invalidModifier(modifier) }
        if let dc, !Self.dcRange.contains(dc) { throw RollSpecError.invalidDC(dc) }
        if mode != .normal && !isSingleD20 { throw RollSpecError.modeRequiresSingleD20 }
        let kinds = Set(extras.map { "\($0.sign)\($0.sides)" })
        guard extras.count <= Self.maxExtras, extras.allSatisfy(\.isValid), kinds.count == extras.count else {
            throw RollSpecError.invalidExtras
        }
    }

    /// Drops advantage/disadvantage when the spec is no longer a single d20.
    public func normalized() -> RollSpec {
        var copy = self
        if !isSingleD20 { copy.mode = .normal }
        return copy
    }
}
