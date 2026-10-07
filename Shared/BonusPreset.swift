import Foundation
import DiceKit

/// A one-tap bonus from the 2024 rules (System Reference Document 5.2.1). Adding one is the same as picking its dice
/// by hand, so presets merge with other bonus dice of the same kind.
struct BonusPreset: Identifiable {
    let id: String
    let name: LocalizedStringResource
    let sign: BonusDice.Sign
    let count: Int
    let sides: Int

    init(_ id: String, _ name: LocalizedStringResource, _ sign: BonusDice.Sign = .plus, count: Int = 1, sides: Int) {
        self.id = id
        self.name = name
        self.sign = sign
        self.count = count
        self.sides = sides
    }

    /// e.g. "+1d4", "−1d4" (with a real minus sign, as on the bonus tags).
    var diceText: String {
        (sign == .plus ? "+" : "−") + "\(count)d\(sides)"
    }

    /// Added to a d20 test.
    static let checks = [
        BonusPreset("bless", "Bless", sides: 4),          // attack rolls and saving throws
        BonusPreset("guidance", "Guidance", sides: 4),    // ability checks with the chosen skill
        BonusPreset("bane", "Bane", .minus, sides: 4),    // the target's attack rolls and saving throws
    ]

    /// The die grows with Bard level: d6, then d8 at 5, d10 at 10, d12 at 15.
    static let bardicInspiration = [6, 8, 10, 12].map {
        BonusPreset("bardic-d\($0)", "Bardic Inspiration", sides: $0)
    }

    /// Extra damage on a hit.
    static let damage = [
        BonusPreset("hunters-mark", "Hunter's Mark", sides: 6),
        BonusPreset("hex", "Hex", sides: 6),
        BonusPreset("divine-favor", "Divine Favor", sides: 4),
        BonusPreset("divine-smite", "Divine Smite", count: 2, sides: 8),  // level 1 slot; +1d8 per slot level above
    ]
}
