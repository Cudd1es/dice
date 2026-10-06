import Foundation
import DiceKit

/// Remembers the last formula the user rolled. Never stores a result.
struct SpecStore {
    private static let key = "lastRollSpec"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> RollSpec {
        guard let data = defaults.data(forKey: Self.key),
              let spec = try? JSONDecoder().decode(RollSpec.self, from: data),
              (try? spec.validate()) != nil
        else { return RollSpec() }
        return spec
    }

    func save(_ spec: RollSpec) {
        guard let data = try? JSONEncoder().encode(spec) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
