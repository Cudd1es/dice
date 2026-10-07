import XCTest
@testable import DiceKit

final class RollSpecTests: XCTestCase {
    private func assertThrows(_ spec: RollSpec, _ expected: RollSpecError, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try spec.validate(), file: file, line: line) { error in
            XCTAssertEqual(error as? RollSpecError, expected, file: file, line: line)
        }
    }

    func test_validate_acceptsDefault() {
        XCTAssertNoThrow(try RollSpec().validate())
    }

    func test_validate_rejectsBadSides() {
        assertThrows(RollSpec(sides: 7), .invalidSides(7))
    }

    func test_validate_rejectsCountBounds() {
        assertThrows(RollSpec(count: 0), .invalidCount(0))
        assertThrows(RollSpec(count: 21), .invalidCount(21))
    }

    func test_validate_rejectsModifierBounds() {
        assertThrows(RollSpec(modifier: -21), .invalidModifier(-21))
        assertThrows(RollSpec(modifier: 21), .invalidModifier(21))
    }

    func test_validate_rejectsDCBounds() {
        assertThrows(RollSpec(dc: 0), .invalidDC(0))
        assertThrows(RollSpec(dc: 1000), .invalidDC(1000))
        // Percentile and many-dice rolls need DCs well above the d20 range.
        XCTAssertNoThrow(try RollSpec(sides: 100, dc: 999).validate())
        XCTAssertNoThrow(try RollSpec(dc: nil).validate())
    }

    func test_validate_rejectsAdvantageOnNonD20() {
        assertThrows(RollSpec(count: 2, sides: 20, mode: .advantage), .modeRequiresSingleD20)
    }

    func test_normalized_resetsModeWhenNotSingleD20() {
        XCTAssertEqual(RollSpec(sides: 6, mode: .advantage).normalized().mode, .normal)
        XCTAssertEqual(RollSpec(mode: .advantage).normalized().mode, .advantage)
    }

    func test_diceToRoll() {
        XCTAssertEqual(RollSpec(count: 3, sides: 6).diceToRoll, 3)
        XCTAssertEqual(RollSpec(mode: .disadvantage).diceToRoll, 2)
    }

    func test_validate_rejectsBadExtras() {
        let d4 = BonusDice(sides: 4)
        assertThrows(RollSpec(extras: [4, 6, 8, 10, 12].map { BonusDice(sides: $0) }), .invalidExtras)
        assertThrows(RollSpec(extras: [BonusDice(count: 0, sides: 6)]), .invalidExtras)
        assertThrows(RollSpec(extras: [BonusDice(count: 11, sides: 6)]), .invalidExtras)
        assertThrows(RollSpec(extras: [BonusDice(sides: 7)]), .invalidExtras)
        assertThrows(RollSpec(extras: [d4, d4]), .invalidExtras)
        XCTAssertNoThrow(try RollSpec(extras: [d4, BonusDice(sign: .minus, count: 2, sides: 6)]).validate())
    }

    func test_validate_allowsAdvantageWithExtras() {
        XCTAssertNoThrow(try RollSpec(mode: .advantage, extras: [BonusDice(sides: 4)]).validate())
    }

    func test_normalized_keepsExtras() {
        let spec = RollSpec(sides: 6, mode: .advantage, extras: [BonusDice(sides: 4)]).normalized()
        XCTAssertEqual(spec.mode, .normal)
        XCTAssertEqual(spec.extras, [BonusDice(sides: 4)])
    }

    // A formula saved by 0.3.x has no "extras" key.
    func test_decode_legacyJSONWithoutExtras() throws {
        let json = #"{"count":1,"sides":20,"mode":"advantage","modifier":5,"dc":15}"#
        let spec = try JSONDecoder().decode(RollSpec.self, from: Data(json.utf8))
        XCTAssertEqual(spec, RollSpec(mode: .advantage, modifier: 5, dc: 15))
        XCTAssertEqual(spec.extras, [])
    }

    func test_codable_roundTripsExtras() throws {
        let spec = RollSpec(modifier: 2, dc: 12, extras: [BonusDice(sides: 4), BonusDice(sign: .minus, count: 2, sides: 6)])
        let decoded = try JSONDecoder().decode(RollSpec.self, from: JSONEncoder().encode(spec))
        XCTAssertEqual(decoded, spec)
    }

    // Formulas saved before 0.6.0 have no criticalsEnabled key.
    func test_decode_legacyJSONCriticalsEnabled() throws {
        let json = #"{"count":1,"sides":20,"mode":"normal","modifier":0}"#
        XCTAssertTrue(try JSONDecoder().decode(RollSpec.self, from: Data(json.utf8)).criticalsEnabled)
        let off = RollSpec(dc: 12, criticalsEnabled: false)
        XCTAssertEqual(try JSONDecoder().decode(RollSpec.self, from: JSONEncoder().encode(off)), off)
    }
}
