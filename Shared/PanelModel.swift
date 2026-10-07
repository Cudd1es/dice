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
    /// The bonus dice picker replaces the panel in place while this is true.
    @Published var isPickingBonus = false

    private let store: SpecStore

    init(store: SpecStore) {
        self.store = store
        // Bonus dice never carry over; 0.4.0 and 0.5.0 saved them with the formula.
        var saved = store.load()
        saved.extras = []
        spec = saved
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

    /// The Messages extension calls this each time it becomes active: a picker left open last time starts closed.
    func didActivate() {
        isPickingBonus = false
    }

    func canAddBonus(sign: BonusDice.Sign, sides: Int) -> Bool {
        spec.canAddBonus(sign: sign, sides: sides)
    }

    /// Adds one bonus die (merging into its group) and closes the picker.
    func addBonus(sign: BonusDice.Sign, sides: Int) {
        update { $0.addBonus(sign: sign, sides: sides) }
        isPickingBonus = false
    }

    func canAddPreset(_ preset: BonusPreset) -> Bool {
        spec.canAddBonus(sign: preset.sign, sides: preset.sides, count: preset.count)
    }

    /// Adds a preset's dice (merging like any bonus) and closes the picker.
    func addPreset(_ preset: BonusPreset) {
        update { $0.addBonus(sign: preset.sign, sides: preset.sides, count: preset.count) }
        isPickingBonus = false
    }

    func incrementBonus(at index: Int) {
        guard spec.extras.indices.contains(index) else { return }
        update { $0.extras[index].count = min($0.extras[index].count + 1, BonusDice.countRange.upperBound) }
    }

    /// Removing the last die of a group removes the group.
    func decrementBonus(at index: Int) {
        guard spec.extras.indices.contains(index) else { return }
        if spec.extras[index].count <= 1 {
            removeBonus(at: index)
        } else {
            update { $0.extras[index].count -= 1 }
        }
    }

    // Menus can outlive their group, so every index is checked.
    func removeBonus(at index: Int) {
        guard spec.extras.indices.contains(index) else { return }
        update { $0.extras.remove(at: index) }
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

    /// Rolls the current formula and remembers it for next time. The purpose and bonus dice go with this roll only.
    func roll<G: RandomNumberGenerator>(using rng: inout G) -> (spec: RollSpec, result: RollResult, purpose: String?) {
        commitDCDraft()
        let rolled = spec
        let result = DiceEngine.roll(rolled, using: &rng)
        // Bonus dice and the purpose belong to this roll only; the rest of the formula is kept for next time.
        update { $0.extras = [] }
        store.save(spec)
        let rolledPurpose = RollPurpose.normalize(purpose)
        purpose = ""
        return (rolled, result, rolledPurpose)
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
