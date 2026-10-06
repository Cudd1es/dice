import XCTest
import DiceKit

final class SpecStoreTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: UUID().uuidString)
    }

    func test_specStore_roundTrip() {
        let store = SpecStore(defaults: defaults)
        let spec = RollSpec(mode: .advantage, modifier: 5, dc: 15)
        store.save(spec)
        XCTAssertEqual(SpecStore(defaults: defaults).load(), spec)
    }

    func test_specStore_fallsBackToDefault() {
        defaults.set(Data("garbage".utf8), forKey: "lastRollSpec")
        XCTAssertEqual(SpecStore(defaults: defaults).load(), RollSpec())
        XCTAssertEqual(SpecStore(defaults: UserDefaults(suiteName: UUID().uuidString)!).load(), RollSpec())
    }

    func test_specStore_fallsBackWhenStoredSpecInvalid() throws {
        let invalid = RollSpec(count: 99, sides: 7)
        defaults.set(try JSONEncoder().encode(invalid), forKey: "lastRollSpec")
        XCTAssertEqual(SpecStore(defaults: defaults).load(), RollSpec())
    }

    func test_specStore_persistsSpecOnly() throws {
        SpecStore(defaults: defaults).save(RollSpec(mode: .advantage, modifier: 5, dc: 15))
        let data = try XCTUnwrap(defaults.data(forKey: "lastRollSpec"))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertTrue(Set(object.keys).isSubset(of: ["count", "sides", "mode", "modifier", "dc", "extras"]), "\(object.keys)")
    }
}
