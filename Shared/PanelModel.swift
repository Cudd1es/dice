import Combine
import DiceKit

/// Panel state, shared by the app and the iMessage extension. Holds only the formula; each roll is handed
/// straight to the caller, which shows it (app) or seals it into a message (extension).
@MainActor
final class PanelModel: ObservableObject {
    @Published private(set) var spec: RollSpec
    @Published var errorMessage: String?

    private let store: SpecStore

    init(store: SpecStore) {
        self.store = store
        spec = store.load()
    }

    var isModeEnabled: Bool { spec.isSingleD20 }

    func selectSides(_ sides: Int) {
        update { $0.sides = sides }
    }

    func changeCount(by delta: Int) {
        update { $0.count = Self.clamp($0.count + delta, to: RollSpec.countRange) }
    }

    func changeModifier(by delta: Int) {
        update { $0.modifier = Self.clamp($0.modifier + delta, to: RollSpec.modifierRange) }
    }

    func setMode(_ mode: RollMode) {
        guard isModeEnabled else { return }
        update { $0.mode = mode }
    }

    func setDC(_ dc: Int?) {
        update { $0.dc = dc.map { Self.clamp($0, to: RollSpec.dcRange) } }
    }

    /// Rolls the current formula and remembers it for next time.
    func roll<G: RandomNumberGenerator>(using rng: inout G) -> (spec: RollSpec, result: RollResult) {
        let result = DiceEngine.roll(spec, using: &rng)
        store.save(spec)
        return (spec, result)
    }

    func roll() -> (spec: RollSpec, result: RollResult) {
        var rng = SystemRandomNumberGenerator()
        return roll(using: &rng)
    }

    private func update(_ change: (inout RollSpec) -> Void) {
        var next = spec
        change(&next)
        spec = next.normalized()
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
