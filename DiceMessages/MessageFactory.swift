import Messages
import DiceKit

enum MessageFactory {
    /// Builds the outgoing message. Only the URL carries the result; every visible field shows the formula only.
    ///
    /// Uses a template layout (variant B): the Live Layout spike showed transcript extensions
    /// cannot read their own message, see docs/superpowers/spikes/2026-10-05-live-layout.md.
    static func makeMessage(spec: RollSpec, result: RollResult, session: MSSession?) -> MSMessage {
        let message = session.map(MSMessage.init(session:)) ?? MSMessage()
        message.url = MessageCodec.url(for: spec, result: result)
        message.summaryText = RollFormatter.summary(spec)

        let template = MSMessageTemplateLayout()
        template.caption = RollFormatter.formula(spec)
        template.subcaption = RollFormatter.tapToRevealCaption
        message.layout = template
        return message
    }
}
