import Messages
import DiceKit

enum InvalidReason: Error, Equatable {
    case needsUpdate, corrupt
}

/// What the extension shows, derived purely from presentation style and the selected message.
enum Screen: Equatable {
    case panel
    case pendingBubble(RollSpec, purpose: String?)
    case revealedBubble(RollSpec, RollResult, purpose: String?)
    case detail(RollSpec, RollResult, purpose: String?)
    case invalid(InvalidReason)

    /// - Parameter revealing: the user just tapped a sent message. A message that merely stays selected
    ///   from earlier must not replace the panel, so only this flag shows a result outside the transcript.
    static func resolve(style: MSMessagesAppPresentationStyle, messageURL: URL?, isPending: Bool, revealing: Bool = false) -> Screen {
        if style == .transcript {
            guard let messageURL else { return .invalid(.corrupt) }
            switch decode(messageURL) {
            case .failure(let reason): return .invalid(reason)
            case .success(let roll):
                return isPending ? .pendingBubble(roll.spec, purpose: roll.purpose)
                    : .revealedBubble(roll.spec, roll.result, purpose: roll.purpose)
            }
        }
        // A pending (draft) message must never reveal its result.
        guard revealing, let messageURL, !isPending else { return .panel }
        switch decode(messageURL) {
        case .failure(let reason): return .invalid(reason)
        case .success(let roll): return .detail(roll.spec, roll.result, purpose: roll.purpose)
        }
    }

    private struct Roll {
        let spec: RollSpec
        let result: RollResult
        let purpose: String?
    }

    private static func decode(_ url: URL) -> Result<Roll, InvalidReason> {
        do {
            let decoded = try MessageCodec.decode(url)
            return .success(Roll(spec: decoded.spec, result: decoded.result, purpose: decoded.purpose))
        } catch CodecError.unsupportedVersion(let version) where version > MessageCodec.currentVersion {
            return .failure(.needsUpdate)
        } catch {
            return .failure(.corrupt)
        }
    }
}
