import XCTest
@testable import DiceKit

final class BonusDiceTests: XCTestCase {
    func test_addBonus_appendsNewGroup() {
        var spec = RollSpec()
        spec.addBonus(sign: .plus, sides: 4)
        XCTAssertEqual(spec.extras, [BonusDice(sides: 4)])
    }

    func test_addBonus_mergesSameKind() {
        var spec = RollSpec()
        spec.addBonus(sign: .plus, sides: 4)
        spec.addBonus(sign: .plus, sides: 4)
        XCTAssertEqual(spec.extras, [BonusDice(count: 2, sides: 4)])
        spec.addBonus(sign: .minus, sides: 4)
        XCTAssertEqual(spec.extras, [BonusDice(count: 2, sides: 4), BonusDice(sign: .minus, sides: 4)])
    }

    func test_addBonus_countCapsAt10() {
        var spec = RollSpec()
        for _ in 0..<11 { spec.addBonus(sign: .plus, sides: 6) }
        XCTAssertEqual(spec.extras, [BonusDice(count: 10, sides: 6)])
    }

    func test_addBonus_maxFourGroups() {
        var spec = RollSpec()
        for sides in [4, 6, 8, 10, 12] { spec.addBonus(sign: .plus, sides: sides) }
        XCTAssertEqual(spec.extras.map(\.sides), [4, 6, 8, 10])
        XCTAssertFalse(spec.canAddBonus(sign: .plus, sides: 12))
        XCTAssertTrue(spec.canAddBonus(sign: .plus, sides: 6))
    }

    func test_totalDiceCount() {
        let spec = RollSpec(mode: .advantage, extras: [BonusDice(count: 2, sides: 6)])
        XCTAssertEqual(spec.totalDiceCount, 4)
    }

    // Presets such as Divine Smite add more than one die at once.
    func test_addBonus_count() {
        var spec = RollSpec()
        spec.addBonus(sign: .plus, sides: 8, count: 2)
        XCTAssertEqual(spec.extras, [BonusDice(count: 2, sides: 8)])
        spec.addBonus(sign: .plus, sides: 8, count: 2)
        XCTAssertEqual(spec.extras, [BonusDice(count: 4, sides: 8)])
    }

    // A merge that would pass 10 dice is refused whole, not clamped.
    func test_addBonus_countRefusedPastTen() {
        var spec = RollSpec(extras: [BonusDice(count: 9, sides: 8)])
        XCTAssertFalse(spec.canAddBonus(sign: .plus, sides: 8, count: 2))
        spec.addBonus(sign: .plus, sides: 8, count: 2)
        XCTAssertEqual(spec.extras, [BonusDice(count: 9, sides: 8)])
        XCTAssertTrue(spec.canAddBonus(sign: .plus, sides: 8, count: 1))
    }
}
