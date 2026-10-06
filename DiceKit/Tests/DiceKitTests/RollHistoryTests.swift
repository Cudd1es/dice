import XCTest
@testable import DiceKit

final class RollHistoryTests: XCTestCase {
    private func result(_ spec: RollSpec, _ dice: [Int]) -> RollResult {
        DiceEngine.evaluate(spec, dice: dice)
    }

    func test_init_isEmpty() {
        XCTAssertTrue(RollHistory().entries.isEmpty)
    }

    func test_add_newestFirst() {
        var history = RollHistory()
        let d6 = RollSpec(sides: 6), d8 = RollSpec(sides: 8)
        history.add(spec: d6, result: result(d6, [2]))
        history.add(spec: d8, result: result(d8, [5]))
        XCTAssertEqual(history.entries.map(\.spec.sides), [8, 6])
    }

    func test_add_dropsOldestBeyondCapacity() {
        var history = RollHistory()
        for i in 0...10 {
            let spec = RollSpec(modifier: i)
            history.add(spec: spec, result: result(spec, [10]))
        }
        XCTAssertEqual(RollHistory.capacity, 10)
        XCTAssertEqual(history.entries.count, 10)
        XCTAssertEqual(history.entries.first?.spec.modifier, 10)
        XCTAssertEqual(history.entries.last?.spec.modifier, 1)
    }

    func test_add_keepsPurpose() {
        var history = RollHistory()
        let spec = RollSpec()
        history.add(spec: spec, result: result(spec, [12]), purpose: "攻击")
        history.add(spec: spec, result: result(spec, [3]))
        XCTAssertNil(history.entries[0].purpose)
        XCTAssertEqual(history.entries[1].purpose, "攻击")
    }

    func test_add_keepsSpecResultAndDate() {
        var history = RollHistory()
        let spec = RollSpec(mode: .advantage, modifier: 5, dc: 15)
        let rolled = result(spec, [17, 8])
        let date = Date(timeIntervalSince1970: 1000)
        history.add(spec: spec, result: rolled, date: date)
        XCTAssertEqual(history.entries[0].spec, spec)
        XCTAssertEqual(history.entries[0].result, rolled)
        XCTAssertEqual(history.entries[0].date, date)
    }

    func test_add_identicalRollsGetDistinctIDs() {
        var history = RollHistory()
        let spec = RollSpec()
        history.add(spec: spec, result: result(spec, [12]))
        history.add(spec: spec, result: result(spec, [12]))
        XCTAssertEqual(history.entries.count, 2)
        XCTAssertNotEqual(history.entries[0].id, history.entries[1].id)
    }
}
