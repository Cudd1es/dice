import Foundation

/// Decides when the extension shows a sent message's result instead of the panel.
///
/// A message can stay selected long after the user looked at it, so only a fresh tap reveals.
/// Messages always opens a tapped message expanded; the result card is sized for compact, so the
/// first expansion after a tap asks to collapse.
struct RevealState {
    private(set) var revealing = false
    private var collapsePending = false
    /// The message whose result the user closed with 再投一次, so expanding the panel won't reopen it.
    private var closedURL: URL?

    mutating func activate() {
        self = RevealState()
    }

    /// The user tapped a message while the extension was already open.
    mutating func didSelect(isPending: Bool) {
        revealing = !isPending
        collapsePending = revealing
        closedURL = nil
    }

    /// Returns whether to request the compact style now.
    ///
    /// Tapping a sent message while the extension is closed activates it compact with nothing
    /// selected, then expands with the message selected; didSelect is not called on that path.
    mutating func didExpand(selected url: URL?, isPending: Bool) -> Bool {
        if !revealing, let url, !isPending, url != closedURL {
            revealing = true
            collapsePending = true
        }
        defer { collapsePending = false }
        return collapsePending
    }

    mutating func closeResult(selected url: URL?) {
        closedURL = url
        revealing = false
        collapsePending = false
    }
}
