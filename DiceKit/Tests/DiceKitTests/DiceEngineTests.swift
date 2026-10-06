import XCTest
@testable import DiceKit

final class DiceEngineTests: XCTestCase {
    func test_roll_isDeterministicWithSeed() {
        let spec = RollSpec(count: 4, sides: 6)
        var a = SplitMix64(seed: 42)
        var b = SplitMix64(seed: 42)
        XCTAssertEqual(DiceEngine.roll(spec, using: &a), DiceEngine.roll(spec, using: &b))
    }

    func test_roll_rangeAndUniformity() {
        let trials = 100_000
        for sides in RollSpec.allowedSides {
            var rng = SplitMix64(seed: 1)
            var counts = [Int](repeating: 0, count: sides + 1)
            for _ in 0..<trials {
                let value = DiceEngine.roll(RollSpec(sides: sides), using: &rng).dice[0]
                XCTAssertTrue((1...sides).contains(value), "d\(sides) rolled \(value)")
                counts[value] += 1
            }
            let expected = Double(trials) / Double(sides)
            for face in 1...sides {
                XCTAssertEqual(Double(counts[face]), expected, accuracy: expected * 0.1, "d\(sides) face \(face)")
            }
        }
    }

    func test_evaluate_normalSum() {
        let result = DiceEngine.evaluate(RollSpec(count: 2, sides: 6, modifier: 3), dice: [2, 5])
        XCTAssertEqual(result.keptIndices, [0, 1])
        XCTAssertEqual(result.total, 10)
        XCTAssertEqual(result.critical, .none)
    }

    func test_evaluate_advantageKeepsHigher() {
        let result = DiceEngine.evaluate(RollSpec(mode: .advantage, modifier: 5), dice: [8, 17])
        XCTAssertEqual(result.keptIndices, [1])
        XCTAssertEqual(result.total, 22)
    }

    func test_evaluate_disadvantageKeepsLower() {
        let result = DiceEngine.evaluate(RollSpec(mode: .disadvantage, modifier: 5), dice: [8, 17])
        XCTAssertEqual(result.keptIndices, [0])
        XCTAssertEqual(result.total, 13)
    }

    func test_evaluate_tieKeepsFirst() {
        XCTAssertEqual(DiceEngine.evaluate(RollSpec(mode: .advantage), dice: [9, 9]).keptIndices, [0])
        XCTAssertEqual(DiceEngine.evaluate(RollSpec(mode: .disadvantage), dice: [9, 9]).keptIndices, [0])
    }

    func test_evaluate_criticalOnlyForSingleD20() {
        XCTAssertEqual(DiceEngine.evaluate(RollSpec(), dice: [20]).critical, .success)
        XCTAssertEqual(DiceEngine.evaluate(RollSpec(), dice: [1]).critical, .failure)
        XCTAssertEqual(DiceEngine.evaluate(RollSpec(mode: .advantage), dice: [1, 20]).critical, .success)
        XCTAssertEqual(DiceEngine.evaluate(RollSpec(mode: .disadvantage), dice: [1, 20]).critical, .failure)
        XCTAssertEqual(DiceEngine.evaluate(RollSpec(count: 3, sides: 20), dice: [20, 20, 20]).critical, .none)
    }

    func test_evaluate_dcBoundaryAndNaturals() {
        XCTAssertEqual(DiceEngine.evaluate(RollSpec(dc: 10), dice: [10]).dcOutcome, .success)
        XCTAssertEqual(DiceEngine.evaluate(RollSpec(dc: 10), dice: [9]).dcOutcome, .failure)
        XCTAssertEqual(DiceEngine.evaluate(RollSpec(dc: 25), dice: [20]).dcOutcome, .success)
        XCTAssertEqual(DiceEngine.evaluate(RollSpec(modifier: 10, dc: 5), dice: [1]).dcOutcome, .failure)
        XCTAssertEqual(DiceEngine.evaluate(RollSpec(count: 2, sides: 6, dc: 7), dice: [3, 4]).dcOutcome, .success)
        XCTAssertNil(DiceEngine.evaluate(RollSpec(), dice: [12]).dcOutcome)
    }
}
