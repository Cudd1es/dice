import XCTest
import Messages
import DiceKit

final class MessageFactoryTests: XCTestCase {
    private let spec = RollSpec(mode: .advantage, modifier: 5, dc: 15)
    private var result: RollResult { DiceEngine.evaluate(spec, dice: [20, 3]) }
    private var message: MSMessage { MessageFactory.makeMessage(spec: spec, result: result, session: nil) }

    func test_message_urlDecodesBack() throws {
        let decoded = try MessageCodec.decode(XCTUnwrap(message.url))
        XCTAssertEqual(decoded.spec, spec)
        XCTAssertEqual(decoded.result, result)
    }

    func test_message_summaryHasNoResult() {
        XCTAssertEqual(message.summaryText, RollFormatter.summary(spec))
    }

    func test_message_alternateLayoutHasNoResult() throws {
        let template = try XCTUnwrap(message.layout as? MSMessageTemplateLayout)
        XCTAssertEqual(template.caption, RollFormatter.formula(spec))
        XCTAssertEqual(template.subcaption, RollFormatter.tapToRevealCaption)
    }

    // Spike decision B (docs/superpowers/spikes/2026-10-05-live-layout.md).
    func test_message_layoutMatchesSpikeDecision() {
        XCTAssertTrue(message.layout is MSMessageTemplateLayout)
        XCTAssertFalse(message.layout is MSMessageLiveLayout)
    }
}
