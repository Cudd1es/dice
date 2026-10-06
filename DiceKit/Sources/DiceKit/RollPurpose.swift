import Foundation

/// The optional line a player writes before rolling, e.g. "Perception check". It is not part of `RollSpec`:
/// the formula is remembered between rolls, the purpose is cleared after each one.
public enum RollPurpose {
    /// Counted in Characters, so an emoji counts as one.
    public static let maxLength = 40

    /// One line, trimmed and cut to `maxLength`; nil when nothing is left.
    public static func normalize(_ raw: String) -> String? {
        let oneLine = String(raw.map { $0.isNewline ? " " : $0 })
        let trimmed = oneLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let cut = String(trimmed.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        return cut.isEmpty ? nil : cut
    }
}
