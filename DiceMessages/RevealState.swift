import Foundation

/// Decides when the extension shows a sent message's result instead of the panel.
///
/// A message can stay selected long after the user looked at it, so only a fresh tap reveals.
struct RevealState {
    private(set) var revealing = false
    /// The message whose result the user closed with 再投一次, so expanding the panel won't reopen it.
    private var closedURL: URL?
    /// Set when the extension expands so the keyboard can show; that expansion is not a tap on a message.
    private var ignoreNextExpand = false

    mutating func activate() {
        self = RevealState()
    }

    /// The user tapped a message while the extension was already open.
    mutating func didSelect(isPending: Bool) {
        revealing = !isPending
        closedURL = nil
    }

    /// Tapping a sent message while the extension is closed activates it compact with nothing
    /// selected, then expands with the message selected; didSelect is not called on that path.
    mutating func didExpand(selected url: URL?, isPending: Bool) {
        if ignoreNextExpand {
            ignoreNextExpand = false
            return
        }
        if !revealing, let url, !isPending, url != closedURL {
            revealing = true
        }
    }

    /// Messages shows no keyboard in the compact drawer, so typing expands the extension first.
    mutating func expandForInput() {
        ignoreNextExpand = true
    }

    mutating func closeResult(selected url: URL?) {
        closedURL = url
        revealing = false
    }
}
