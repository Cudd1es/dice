import Foundation

/// The languages the roll text is written in.
public enum RollLanguage: Sendable, Equatable {
    case english
    case simplifiedChinese

    /// Maps a localization identifier ("zh-Hans", "en", ...) to a language. Only Simplified Chinese is
    /// translated, so Traditional Chinese and every other language fall back to English.
    public init(localization: String) {
        let id = localization.replacingOccurrences(of: "_", with: "-").lowercased()
        let simplified = id == "zh" || id.hasPrefix("zh-hans") || id == "zh-cn" || id == "zh-sg"
        self = simplified ? .simplifiedChinese : .english
    }

    /// The language the app is showing, as iOS resolved it from the app's localizations.
    public static var current: RollLanguage {
        RollLanguage(localization: Bundle.main.preferredLocalizations.first ?? "en")
    }
}
