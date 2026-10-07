import Foundation

/// Player settings shared by the app and the Messages extension through an App Group, so a house rule set in the
/// app's Settings page also applies to rolls sent from Messages.
struct SettingsStore {
    static let appGroup = "group.dev.ansel.dice"

    /// The App Group's defaults. Without the App Group entitlement (an unsigned build, a signing problem) iOS still
    /// returns a store, just a private one, so settings keep working without being shared; `.standard` is only a
    /// last resort if no store is returned at all.
    static var shared: UserDefaults { UserDefaults(suiteName: appGroup) ?? .standard }

    private static let criticalsKey = "criticalsEnabled"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = SettingsStore.shared) {
        self.defaults = defaults
    }

    /// Whether a natural 20 / 1 on a single d20 is a critical success / failure. On unless turned off.
    var criticalsEnabled: Bool {
        get { defaults.object(forKey: Self.criticalsKey) as? Bool ?? true }
        nonmutating set { defaults.set(newValue, forKey: Self.criticalsKey) }
    }
}
