import Messages
import SwiftUI
import UIKit
import DiceKit

struct RootView: View {
    let screen: Screen

    var body: some View {
        switch screen {
        case .panel:
            Text("panel")
        default:
            ScrollView { BubbleView(screen: screen) }
        }
    }
}

final class MessagesViewController: MSMessagesAppViewController {
    private lazy var host = UIHostingController(rootView: RootView(screen: .panel))

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
        host.rootView = RootView(screen: screen)
    }
}
