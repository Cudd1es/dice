import CoreGraphics

/// Splits one row between bonus tags (leading) and the formula (trailing), so a bonus does not add a row to the
/// panel: the compact Messages drawer has no room for one.
enum RowSplit {
    /// Both get their ideal widths when they fit. Otherwise the tags keep their width up to half the row (they
    /// scroll beyond it) or more when the formula needs less, and the formula gets the rest (it shrinks, then
    /// truncates).
    static func widths(available: CGFloat, leading: CGFloat, trailing: CGFloat,
                       spacing: CGFloat) -> (leading: CGFloat, trailing: CGFloat) {
        let room = max(available - spacing, 0)
        if leading + trailing <= room { return (leading, trailing) }
        let tags = min(leading, max(room / 2, room - trailing))
        return (tags, min(trailing, room - tags))
    }
}
