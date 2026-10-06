/// One group of extra dice added to or subtracted from the main roll, e.g. +1d4 (Bless) or −2d6.
/// Bonus dice never take part in advantage or criticals; only the main dice do.
public struct BonusDice: Codable, Equatable, Hashable, Sendable {
    public enum Sign: String, Codable, Sendable {
        case plus, minus
    }

    public static let countRange = 1...10
    public static let allowedSides = [4, 6, 8, 10, 12, 20, 100]

    public var sign: Sign
    public var count: Int
    public var sides: Int

    public init(sign: Sign = .plus, count: Int = 1, sides: Int) {
        self.sign = sign
        self.count = count
        self.sides = sides
    }

    var isValid: Bool {
        Self.countRange.contains(count) && Self.allowedSides.contains(sides)
    }
}
