import Messages
import SwiftUI
import UIKit
import DiceKit

struct RootView: View {
    /// nil until the transcript bubble knows which message it shows.
    let screen: Screen?
    let model: PanelModel
    let onRoll: () -> Void
    let onRollAgain: () -> Void

    var body: some View {
        switch screen {
        case nil:
            Color.clear
        case .panel?:
            RollPanelView(model: model, onRoll: onRoll)
        case .detail(let spec, let result)?:
            ResultCard(spec: spec, result: result, onRollAgain: onRollAgain)
        case let screen?:
            // No ScrollView: the transcript bubble is sized from this view's fitting height.
            BubbleView(screen: screen)
        }
    }
}

final class MessagesViewController: MSMessagesAppViewController {
    private let model = PanelModel(store: SpecStore())
    private lazy var host = UIHostingController(rootView: makeRoot(nil))
    private var reveal = RevealState()

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        reveal.activate()
        refresh()
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        if presentationStyle == .expanded, let message = activeConversation?.selectedMessage {
            reveal.didExpand(selected: message.url, isPending: message.isPending)
        }
        refresh()
    }

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        super.didSelect(message, conversation: conversation)
        reveal.didSelect(isPending: message.isPending)
        refresh()
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        refresh()
    }

    /// Height used before the bubble knows its message; fits the draft and a typical result.
    private static let fallbackBubbleHeight: CGFloat = 110

    override func contentSizeThatFits(_ size: CGSize) -> CGSize {
        refresh()
        guard activeConversation != nil else {
            return CGSize(width: size.width, height: Self.fallbackBubbleHeight)
        }
        return host.sizeThatFits(in: CGSize(width: size.width, height: .greatestFiniteMagnitude))
    }

    private func refresh() {
        // A transcript bubble learns its message in willBecomeActive; until then there is nothing to draw,
        // and resolving now would flash the corrupt-data text.
        if presentationStyle == .transcript && activeConversation == nil { return }
        let message = activeConversation?.selectedMessage
        let screen = Screen.resolve(style: presentationStyle, messageURL: message?.url,
                                    isPending: message?.isPending ?? false, revealing: reveal.revealing)
        host.rootView = makeRoot(screen)
    }

    private func makeRoot(_ screen: Screen?) -> RootView {
        RootView(screen: screen, model: model,
                 onRoll: { [weak self] in self?.roll() },
                 onRollAgain: { [weak self] in self?.showPanel() })
    }

    private func showPanel() {
        reveal.closeResult(selected: activeConversation?.selectedMessage?.url)
        refresh()
    }

    /// The result is fixed here and goes straight into the draft; nothing on screen shows it.
    private func roll() {
        guard let conversation = activeConversation else { return }
        model.errorMessage = nil
        conversation.insert(model.makeRoll()) { [weak self] error in
            DispatchQueue.main.async {
                if error != nil {
                    self?.model.errorMessage = "插入失败，请重试"
                } else {
                    self?.dismiss()
                }
            }
        }
    }
}
