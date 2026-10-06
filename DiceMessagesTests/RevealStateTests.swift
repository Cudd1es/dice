import XCTest

final class RevealStateTests: XCTestCase {
    private let url = URL(string: "https://dice.invalid/roll?v=1")!
    private let other = URL(string: "https://dice.invalid/roll?v=1&x")!

    // Seen on the simulator: tapping a sent message with the extension closed activates it compact
    // with nothing selected, then expands with the message selected and never calls didSelect.
    func test_tapWhileClosed_reveals() {
        var state = RevealState()
        state.activate()
        XCTAssertFalse(state.revealing)
        state.didExpand(selected: url, isPending: false)
        XCTAssertTrue(state.revealing)
    }

    func test_tapWhileOpen_reveals() {
        var state = RevealState()
        state.activate()
        state.didSelect(isPending: false)
        XCTAssertTrue(state.revealing)
        state.didExpand(selected: url, isPending: false)
        XCTAssertTrue(state.revealing)
    }

    func test_draggingPanelUpWithoutSelection_staysOnPanel() {
        var state = RevealState()
        state.activate()
        state.didExpand(selected: nil, isPending: false)
        XCTAssertFalse(state.revealing)
    }

    func test_pendingMessage_neverReveals() {
        var state = RevealState()
        state.activate()
        state.didSelect(isPending: true)
        XCTAssertFalse(state.revealing)
        state.didExpand(selected: url, isPending: true)
        XCTAssertFalse(state.revealing)
    }

    func test_closedResult_doesNotReopenWhenPanelExpands() {
        var state = RevealState()
        state.activate()
        state.didExpand(selected: url, isPending: false)
        state.closeResult(selected: url)
        XCTAssertFalse(state.revealing)
        state.didExpand(selected: url, isPending: false)
        XCTAssertFalse(state.revealing)
    }

    func test_closedResult_otherMessageStillReveals() {
        var state = RevealState()
        state.activate()
        state.closeResult(selected: url)
        state.didExpand(selected: other, isPending: false)
        XCTAssertTrue(state.revealing)
    }

    func test_reactivating_clearsEverything() {
        var state = RevealState()
        state.didSelect(isPending: false)
        state.closeResult(selected: url)
        state.activate()
        XCTAssertFalse(state.revealing)
        state.didExpand(selected: url, isPending: false)
        XCTAssertTrue(state.revealing, "a fresh tap on the same message reveals again")
    }

    // Tapping the purpose or DC field in the compact drawer expands the extension for the keyboard. A sent
    // message left selected from earlier must not take over the panel on that expansion.
    func test_expandForInput_doesNotReveal() {
        var state = RevealState()
        state.activate()
        state.expandForInput()
        state.didExpand(selected: url, isPending: false)
        XCTAssertFalse(state.revealing)
        // Only that one expansion is ignored.
        state.didExpand(selected: url, isPending: false)
        XCTAssertTrue(state.revealing)
    }
}
