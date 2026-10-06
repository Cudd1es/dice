import Messages
import DiceKit

enum InvalidReason: Error, Equatable {
    case needsUpdate, corrupt
}

/// What the extension shows, derived purely from presentation style and the selected message.
enum Screen: Equatable {
    case panel
    case pendingBubble(RollSpec)
    case revealedBubble(RollSpec, RollResult)
    case detail(RollSpec, RollResult)
    case invalid(InvalidReason)

    static func resolve(style: MSMessagesAppPresentationStyle, messageURL: URL?, isPending: Bool) -> Screen {
        switch style {
        case .transcript:
            guard let messageURL else { return .invalid(.corrupt) }
            switch decode(messageURL) {
            case .failure(let reason): return .invalid(reason)
            case .success(let roll): return isPending ? .pendingBubble(roll.spec) : .revealedBubble(roll.spec, roll.result)
            }
        default:
            // A pending (draft) message must never reveal its result, so it falls back to the panel.
            guard let messageURL, !isPending else { return .panel }
            switch decode(messageURL) {
            case .failure(let reason): return .invalid(reason)
            case .success(let roll): return .detail(roll.spec, roll.result)
            }
        }
    }

    private struct Roll {
        let spec: RollSpec
        let result: RollResult
    }

    private static func decode(_ url: URL) -> Result<Roll, InvalidReason> {
        do {
            let decoded = try MessageCodec.decode(url)
            return .success(Roll(spec: decoded.spec, result: decoded.result))
        } catch CodecError.unsupportedVersion(let version) where version > MessageCodec.currentVersion {
            return .failure(.needsUpdate)
        } catch {
            return .failure(.corrupt)
        }
    }
}
