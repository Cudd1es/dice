import XCTest

final class SettingsStoreTests: XCTestCase {
    private func freshDefaults() -> UserDefaults { UserDefaults(suiteName: UUID().uuidString)! }

    func test_defaultsToEnabled() {
        XCTAssertTrue(SettingsStore(defaults: freshDefaults()).criticalsEnabled)
    }

    func test_persists() {
        let defaults = freshDefaults()
        SettingsStore(defaults: defaults).criticalsEnabled = false
        XCTAssertFalse(SettingsStore(defaults: defaults).criticalsEnabled)
    }
}
