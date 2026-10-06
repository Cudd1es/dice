import Messages
import SwiftUI
import UIKit
import DiceKit

struct RootView: View {
    let screen: Screen
    let model: PanelModel
    let onRoll: () -> Void

    var body: some View {
        switch screen {
        case .panel:
            RollPanelView(model: model, onRoll: onRoll)
        default:
            ScrollView { BubbleView(screen: screen) }
        }
    }
}

final class MessagesViewController: MSMessagesAppViewController {
    private let model = PanelModel(store: SpecStore())
    private lazy var host = UIHostingController(rootView: makeRoot(.panel))

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
        refresh()
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        refresh()
    }

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        super.didSelect(message, conversation: conversation)
        refresh()
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        refresh()
    }

    override func contentSizeThatFits(_ size: CGSize) -> CGSize {
        host.sizeThatFits(in: CGSize(width: size.width, height: .greatestFiniteMagnitude))
    }

    private func refresh() {
        let message = activeConversation?.selectedMessage
        let screen = Screen.resolve(style: presentationStyle, messageURL: message?.url, isPending: message?.isPending ?? false)
        host.rootView = makeRoot(screen)
    }

    private func makeRoot(_ screen: Screen) -> RootView {
        RootView(screen: screen, model: model) { [weak self] in self?.roll() }
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
