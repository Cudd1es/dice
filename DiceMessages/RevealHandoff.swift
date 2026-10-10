import Foundation

/// Passes a tapped bubble's message to the expanded extension that opens for it.
///
/// Messages does not open the extension when a sent Live Layout bubble is tapped (see the live-layout spike), so the
/// bubble asks for an expanded instance itself (`requestPresentationStyle`). That is a new instance, possibly without
/// the message selected, so the bubble leaves the URL here first. Stored in the App Group: the two instances may run
/// in different processes. Short-lived, so a handoff that was never picked up cannot open a result later.
struct RevealHandoff {
    static let maxAge: TimeInterval = 10

    private static let urlKey = "revealHandoffURL"
    private static let dateKey = "revealHandoffDate"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = SettingsStore.shared) {
        self.defaults = defaults
    }

    func store(_ url: URL, at date: Date = Date()) {
        defaults.set(url.absoluteString, forKey: Self.urlKey)
        defaults.set(date.timeIntervalSince1970, forKey: Self.dateKey)
    }

    /// The URL stored in the last `maxAge` seconds, at most once.
    func take(now: Date = Date()) -> URL? {
        defer {
            defaults.removeObject(forKey: Self.urlKey)
            defaults.removeObject(forKey: Self.dateKey)
        }
        guard let string = defaults.string(forKey: Self.urlKey),
              let stored = defaults.object(forKey: Self.dateKey) as? TimeInterval,
              now.timeIntervalSince1970 - stored <= Self.maxAge
        else { return nil }
        return URL(string: string)
    }
}
