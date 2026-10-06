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
}
