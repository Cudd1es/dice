import Foundation

/// Decides when the extension shows a sent message's result instead of the panel.
///
/// A message can stay selected long after the user looked at it, so only a fresh tap reveals.
struct RevealState {
    private(set) var revealing = false
    /// The message whose result the user closed with 再投一次, so expanding the panel won't reopen it.
    private var closedURL: URL?

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
        if !revealing, let url, !isPending, url != closedURL {
            revealing = true
        }
    }

    mutating func closeResult(selected url: URL?) {
        closedURL = url
        revealing = false
    }
}
