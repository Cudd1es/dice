import XCTest
import Messages
import DiceKit

final class ScreenTests: XCTestCase {
    private let spec = RollSpec(mode: .advantage, modifier: 5, dc: 15)
    private var result: RollResult { DiceEngine.evaluate(spec, dice: [8, 17]) }
    private var url: URL { MessageCodec.url(for: spec, result: result) }

    func test_resolve_transcriptPending() {
        XCTAssertEqual(Screen.resolve(style: .transcript, messageURL: url, isPending: true), .pendingBubble(spec))
    }

    func test_resolve_transcriptSent() {
        XCTAssertEqual(Screen.resolve(style: .transcript, messageURL: url, isPending: false), .revealedBubble(spec, result))
    }

    func test_resolve_transcriptFutureVersionNeedsUpdate() {
        let future = URL(string: "https://dice.invalid/roll?v=2&n=1&s=20&m=n&k=0&d=7")!
        XCTAssertEqual(Screen.resolve(style: .transcript, messageURL: future, isPending: false), .invalid(.needsUpdate))
    }

    func test_resolve_transcriptGarbageIsCorrupt() {
        let garbage = URL(string: "https://dice.invalid/roll?v=1&n=1&s=6&m=n&k=0&d=9")!
        XCTAssertEqual(Screen.resolve(style: .transcript, messageURL: garbage, isPending: false), .invalid(.corrupt))
        XCTAssertEqual(Screen.resolve(style: .transcript, messageURL: nil, isPending: false), .invalid(.corrupt))
    }

    func test_resolve_compactNoMessageShowsPanel() {
        XCTAssertEqual(Screen.resolve(style: .compact, messageURL: nil, isPending: false), .panel)
    }

    func test_resolve_expandedPendingShowsPanel() {
        XCTAssertEqual(Screen.resolve(style: .expanded, messageURL: url, isPending: true), .panel)
    }

    func test_resolve_expandedSentShowsDetail() {
        XCTAssertEqual(Screen.resolve(style: .expanded, messageURL: url, isPending: false), .detail(spec, result))
    }

    func test_resolve_expandedSentGarbageIsInvalid() {
        let garbage = URL(string: "https://dice.invalid/roll?v=9")!
        XCTAssertEqual(Screen.resolve(style: .expanded, messageURL: garbage, isPending: false), .invalid(.needsUpdate))
    }
}
