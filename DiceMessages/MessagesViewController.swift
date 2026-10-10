import Messages
import SwiftUI
import UIKit
import os
import DiceKit

private let log = Logger(subsystem: "dev.ansel.dice.imessage", category: "reveal")

struct RootView: View {
    /// nil until the transcript bubble knows which message it shows.
    let screen: Screen?
    let model: PanelModel
    let onRoll: () -> Void
    let onRollAgain: () -> Void
    let onKeyboardFocus: () -> Void
    let onOpenResult: () -> Void

    var body: some View {
        content
            // Same cap as the app (RollerView): beyond it the panel and the result card no longer fit the screen.
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case nil:
            // Fixed height: Color.clear alone is greedy and made the bubble very tall.
            Color.clear.frame(height: 1)
        case .panel?:
            RollPanelView(model: model, onRoll: onRoll, onKeyboardFocus: onKeyboardFocus)
        case .detail(let spec, let result, let purpose)?:
            ResultCard(spec: spec, result: result, purpose: purpose, onRollAgain: onRollAgain, showsFullPurpose: true)
        case let screen?:
            // No ScrollView: the transcript bubble is sized from this view's fitting height.
            BubbleView(screen: screen, onOpen: onOpenResult)
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
        if presentationStyle != .transcript { takeHandoff() }
        model.didActivate()
        // activeConversation is still nil inside this callback when Messages recreates a bubble that was
        // scrolled off screen (seen on device), so use the conversation it hands us.
        refresh(conversation)
    }

    override func didBecomeActive(with conversation: MSConversation) {
        super.didBecomeActive(with: conversation)
        refresh(conversation)
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        // Messages hides the keyboard in compact but the field could stay focused; end editing so the next tap
        // on a field is a new focus and expands again.
        if presentationStyle == .compact { view.endEditing(true) }
        if presentationStyle == .expanded { takeHandoff() }
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

    private func refresh(_ conversation: MSConversation? = nil) {
        let conversation = conversation ?? activeConversation
        // A transcript bubble learns its message in willBecomeActive; until then there is nothing to draw,
        // and resolving now would flash the corrupt-data text.
        if presentationStyle == .transcript && conversation == nil { return }
        let message = conversation?.selectedMessage
        // Opened from a tapped bubble: show that message even if Messages selected none (or another).
        let opened = presentationStyle == .transcript ? nil : reveal.openedURL
        let screen = Screen.resolve(style: presentationStyle, messageURL: opened ?? message?.url,
                                    isPending: opened == nil && (message?.isPending ?? false),
                                    revealing: reveal.revealing)
        host.rootView = makeRoot(screen)
    }

    private func makeRoot(_ screen: Screen?) -> RootView {
        RootView(screen: screen, model: model,
                 onRoll: { [weak self] in self?.roll() },
                 onRollAgain: { [weak self] in self?.showPanel() },
                 onKeyboardFocus: { [weak self] in self?.expandForKeyboard() },
                 onOpenResult: { [weak self] in self?.openResultFromBubble() })
    }

    /// Messages does not open the extension when a sent Live Layout bubble is tapped, so the bubble asks for an
    /// expanded instance itself and hands it the message (RevealHandoff), where the full result and purpose show.
    private func openResultFromBubble() {
        guard presentationStyle == .transcript,
              let message = activeConversation?.selectedMessage, !message.isPending, let url = message.url
        else {
            log.info("bubble tap ignored: style \(self.presentationStyle.rawValue), no sent message")
            return
        }
        RevealHandoff().store(url)
        log.info("bubble tap: requesting expanded")
        requestPresentationStyle(.expanded)
    }

    private func takeHandoff() {
        guard let url = RevealHandoff().take() else { return }
        log.info("opened from a bubble tap (style \(self.presentationStyle.rawValue))")
        reveal.didOpen(from: url)
    }

    private func expandForKeyboard() {
        guard presentationStyle == .compact else { return }
        reveal.expandForInput()
        requestPresentationStyle(.expanded)
    }

    private func showPanel() {
        reveal.closeResult(selected: activeConversation?.selectedMessage?.url)
        refresh()
    }

    /// The result is fixed here and goes straight into the draft; nothing on screen shows it.
    private func roll() {
        guard let conversation = activeConversation else { return }
        model.errorMessage = nil
        let (spec, result, purpose) = model.roll()
        let message = MessageFactory.makeMessage(spec: spec, result: result, purpose: purpose, session: nil)
        conversation.insert(message) { [weak self] error in
            DispatchQueue.main.async {
                if error != nil {
                    self?.model.errorMessage = String(localized: "Couldn't insert the roll. Try again.")
                } else {
                    self?.dismiss()
                }
            }
        }
    }
}
