import Messages
import DiceKit

enum MessageFactory {
    /// Builds the outgoing message. Only the URL carries the result; every visible field shows the formula only.
    ///
    /// The bubble is a Live Layout drawn by this extension: the formula while it is a draft, the result once sent
    /// (verified on a device; the simulator cannot do this, see docs/superpowers/spikes/2026-10-05-live-layout.md).
    /// People without the app see the template fallback, which asks them to install it.
    static func makeMessage(spec: RollSpec, result: RollResult, purpose: String?, session: MSSession?) -> MSMessage {
        let message = session.map(MSMessage.init(session:)) ?? MSMessage()
        message.url = MessageCodec.url(for: spec, result: result, purpose: purpose)
        message.summaryText = RollFormatter.summary(spec, purpose: purpose)

        let fallback = MSMessageTemplateLayout()
        if let purpose {
            fallback.caption = purpose
            fallback.subcaption = RollFormatter.formula(spec) + " · " + RollFormatter.installToRevealCaption()
        } else {
            fallback.caption = RollFormatter.formula(spec)
            fallback.subcaption = RollFormatter.installToRevealCaption()
        }
        message.layout = MSMessageLiveLayout(alternateLayout: fallback)
        return message
    }
}
