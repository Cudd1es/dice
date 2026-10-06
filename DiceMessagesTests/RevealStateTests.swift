import XCTest

final class RevealStateTests: XCTestCase {
    private let url = URL(string: "https://dice.invalid/roll?v=1")!
    private let other = URL(string: "https://dice.invalid/roll?v=1&x")!

    // Seen on the simulator: tapping a sent message with the extension closed activates it compact
    // with nothing selected, then expands with the message selected and never calls didSelect.
    func test_tapWhileClosed_revealsAndCollapsesOnce() {
        var state = RevealState()
        state.activate()
        XCTAssertFalse(state.revealing)
        XCTAssertTrue(state.didExpand(selected: url, isPending: false))
        XCTAssertTrue(state.revealing)
        XCTAssertFalse(state.didExpand(selected: url, isPending: false), "collapse only once")
        XCTAssertTrue(state.revealing)
    }

    func test_tapWhileOpen_revealsThenCollapsesOnExpand() {
        var state = RevealState()
        state.activate()
        state.didSelect(isPending: false)
        XCTAssertTrue(state.revealing)
        XCTAssertTrue(state.didExpand(selected: url, isPending: false))
    }

    func test_draggingPanelUpWithoutSelection_staysOnPanel() {
        var state = RevealState()
        state.activate()
        XCTAssertFalse(state.didExpand(selected: nil, isPending: false))
        XCTAssertFalse(state.revealing)
    }

    func test_pendingMessage_neverReveals() {
        var state = RevealState()
        state.activate()
        state.didSelect(isPending: true)
        XCTAssertFalse(state.revealing)
        XCTAssertFalse(state.didExpand(selected: url, isPending: true))
        XCTAssertFalse(state.revealing)
    }

    func test_closedResult_doesNotReopenWhenPanelExpands() {
        var state = RevealState()
        state.activate()
        _ = state.didExpand(selected: url, isPending: false)
        state.closeResult(selected: url)
        XCTAssertFalse(state.revealing)
        XCTAssertFalse(state.didExpand(selected: url, isPending: false))
        XCTAssertFalse(state.revealing)
    }

    func test_closedResult_otherMessageStillReveals() {
        var state = RevealState()
        state.activate()
        state.closeResult(selected: url)
        XCTAssertTrue(state.didExpand(selected: other, isPending: false))
        XCTAssertTrue(state.revealing)
    }

    func test_reactivating_clearsEverything() {
        var state = RevealState()
        state.didSelect(isPending: false)
        state.closeResult(selected: url)
        state.activate()
        XCTAssertFalse(state.revealing)
        XCTAssertTrue(state.didExpand(selected: url, isPending: false), "a fresh tap on the same message reveals again")
    }
}
