import XCTest
@testable import DiceKit

final class RollPurposeTests: XCTestCase {
    func test_trimsWhitespace() {
        XCTAssertEqual(RollPurpose.normalize("  察觉检定 "), "察觉检定")
    }

    // "\r\n" is a single Character, so it becomes a single space.
    func test_newlinesBecomeSpaces() {
        XCTAssertEqual(RollPurpose.normalize("攻击\n哥布林\r\n两次"), "攻击 哥布林 两次")
    }

    func test_blankIsNil() {
        XCTAssertNil(RollPurpose.normalize(""))
        XCTAssertNil(RollPurpose.normalize("   \n "))
    }

    func test_keeps40() {
        let forty = String(repeating: "a", count: 40)
        XCTAssertEqual(RollPurpose.normalize(forty), forty)
    }

    func test_truncatesTo40() {
        XCTAssertEqual(RollPurpose.normalize(String(repeating: "a", count: 41)), String(repeating: "a", count: 40))
        // Cut at 40 leaves a trailing space, which is trimmed too.
        XCTAssertEqual(RollPurpose.normalize(String(repeating: "a", count: 39) + " b"), String(repeating: "a", count: 39))
    }

    func test_emojiCountsAsOne() {
        let family = "👨‍👩‍👧"
        let normalized = RollPurpose.normalize(String(repeating: family, count: 41))
        XCTAssertEqual(normalized?.count, 40)
        XCTAssertTrue(normalized?.allSatisfy { String($0) == family } ?? false)
    }
}
