import XCTest
@testable import DiceKit

final class RollFormatterTests: XCTestCase {
    func test_formula() {
        XCTAssertEqual(RollFormatter.formula(RollSpec(mode: .advantage, modifier: 5, dc: 15)), "1d20+5 · 优势 · DC 15")
        XCTAssertEqual(RollFormatter.formula(RollSpec(count: 2, sides: 6)), "2d6")
        XCTAssertEqual(RollFormatter.formula(RollSpec(sides: 8, modifier: -2)), "1d8-2")
        XCTAssertEqual(RollFormatter.formula(RollSpec(mode: .disadvantage)), "1d20 · 劣势")
    }

    func test_summary() {
        XCTAssertEqual(RollFormatter.summary(RollSpec(mode: .advantage, modifier: 5, dc: 15)), "🎲 1d20+5 · 优势 · DC 15")
    }

    func test_detail() {
        let advantage = RollSpec(mode: .advantage, modifier: 5)
        let advantageResult = RollResult(dice: [17, 8], keptIndices: [0], total: 22, critical: .none, dcOutcome: nil)
        XCTAssertEqual(RollFormatter.detailMarkdown(advantage, advantageResult), "[17, ~~8~~] + 5 = 22")

        let twoD6 = RollSpec(count: 2, sides: 6, modifier: -2)
        XCTAssertEqual(RollFormatter.detailMarkdown(twoD6, DiceEngine.evaluate(twoD6, dice: [3, 4])), "[3, 4] - 2 = 5")

        let oneD6 = RollSpec(sides: 6)
        XCTAssertEqual(RollFormatter.detailMarkdown(oneD6, DiceEngine.evaluate(oneD6, dice: [6])), "[6] = 6")
    }

    func test_detail_twentyDice() {
        let spec = RollSpec(count: 20, sides: 100)
        let result = DiceEngine.evaluate(spec, dice: Array(81...100))
        let detail = RollFormatter.detailMarkdown(spec, result)
        XCTAssertEqual(detail.split(separator: ",").count, 20)
        XCTAssertTrue(detail.hasSuffix(" = \(result.total)"))
    }

    func test_outcome() {
        func result(_ critical: Critical, _ dc: DCOutcome?) -> RollResult {
            RollResult(dice: [10], keptIndices: [0], total: 10, critical: critical, dcOutcome: dc)
        }
        XCTAssertEqual(RollFormatter.outcome(result(.success, nil)), "大成功")
        XCTAssertEqual(RollFormatter.outcome(result(.failure, nil)), "大失败")
        XCTAssertEqual(RollFormatter.outcome(result(.none, .success)), "成功")
        XCTAssertEqual(RollFormatter.outcome(result(.none, .failure)), "失败")
        XCTAssertNil(RollFormatter.outcome(result(.none, nil)))
        XCTAssertEqual(RollFormatter.outcome(result(.success, .success)), "大成功")
    }
}
