import XCTest

final class RevealHandoffTests: XCTestCase {
    private let url = URL(string: "https://dice.invalid/roll?v=1&n=1&s=20&m=0&d=7")!
    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func freshHandoff() -> RevealHandoff { RevealHandoff(defaults: UserDefaults(suiteName: UUID().uuidString)!) }

    func test_takeReturnsTheStoredURLOnce() {
        let handoff = freshHandoff()
        handoff.store(url, at: now)
        XCTAssertEqual(handoff.take(now: now.addingTimeInterval(1)), url)
        XCTAssertNil(handoff.take(now: now.addingTimeInterval(2)))
    }

    func test_staleURLIsDropped() {
        let handoff = freshHandoff()
        handoff.store(url, at: now)
        XCTAssertNil(handoff.take(now: now.addingTimeInterval(RevealHandoff.maxAge + 1)))
        XCTAssertNil(handoff.take(now: now))
    }

    func test_nothingStored() {
        XCTAssertNil(freshHandoff().take(now: now))
    }
}
