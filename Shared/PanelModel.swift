import Combine
import DiceKit

/// Panel state, shared by the app and the iMessage extension. Holds the formula and the purpose being typed;
/// each roll is handed straight to the caller, which shows it (app) or seals it into a message (extension).
@MainActor
final class PanelModel: ObservableObject {
    @Published private(set) var spec: RollSpec
    @Published var errorMessage: String?
    /// Raw text of the purpose field; never saved. Rolling normalizes it, which also cuts it to the limit.
    @Published var purpose = ""
    /// Text of the DC field while it is being typed; nil when not editing. Kept here, not in the view, so rolling
    /// can commit it first: the view's focus-loss commit runs only after the Roll action returns.
    @Published var dcDraft: String?

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
        if dc == nil { dcDraft = nil }
        update { $0.dc = dc.map { Self.clamp($0, to: RollSpec.dcRange) } }
    }

    /// Starts empty; the view shows the current DC as the placeholder.
    func beginEditingDC() {
        dcDraft = ""
    }

    /// Applies the typed DC, if any, and ends editing.
    func commitDCDraft() {
        guard let draft = dcDraft else { return }
        dcDraft = nil
        setDC(text: draft)
    }

    /// Typed DC: a number is clamped into range; empty or non-numeric text keeps the current DC.
    func setDC(text: String) {
        guard let dc = Int(text.trimmingCharacters(in: .whitespaces)) else { return }
        setDC(dc)
    }

    /// Rolls the current formula and remembers it for next time. The purpose goes with this roll only.
    func roll<G: RandomNumberGenerator>(using rng: inout G) -> (spec: RollSpec, result: RollResult, purpose: String?) {
        commitDCDraft()
        let result = DiceEngine.roll(spec, using: &rng)
        store.save(spec)
        let rolledPurpose = RollPurpose.normalize(purpose)
        purpose = ""
        return (spec, result, rolledPurpose)
    }

    func roll() -> (spec: RollSpec, result: RollResult, purpose: String?) {
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
