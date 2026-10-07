import XCTest
import DiceKit

/// Presets follow the 2024 rules (SRD 5.2.1). Each one is a plain bonus: what it adds must match the rule.
@MainActor
final class BonusPresetTests: XCTestCase {
    private func dice(_ presets: [BonusPreset]) -> [String] {
        presets.map { "\($0.id) \($0.sign == .plus ? "+" : "-")\($0.count)d\($0.sides)" }
    }

    func test_checkPresets() {
        XCTAssertEqual(dice(BonusPreset.checks), ["bless +1d4", "guidance +1d4", "bane -1d4"])
    }

    func test_bardicInspirationDice() {
        XCTAssertEqual(dice(BonusPreset.bardicInspiration),
                       ["bardic-d6 +1d6", "bardic-d8 +1d8", "bardic-d10 +1d10", "bardic-d12 +1d12"])
    }

    func test_damagePresets() {
        XCTAssertEqual(dice(BonusPreset.damage),
                       ["hunters-mark +1d6", "hex +1d6", "divine-favor +1d4", "divine-smite +2d8"])
    }

    func test_idsAreUnique() {
        let all = BonusPreset.checks + BonusPreset.bardicInspiration + BonusPreset.damage
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)
    }

    func test_diceText() {
        XCTAssertEqual(BonusPreset.checks.map(\.diceText), ["+1d4", "+1d4", "−1d4"])
    }

    // Presets merge like any bonus: Bless and Guidance together are +2d4.
    func test_panel_addPresetMergesAndClosesPicker() {
        let model = PanelModel(store: SpecStore(defaults: UserDefaults(suiteName: UUID().uuidString)!),
                               settings: SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!))
        model.isPickingBonus = true
        model.addPreset(BonusPreset.checks[0])
        XCTAssertFalse(model.isPickingBonus)
        model.addPreset(BonusPreset.checks[1])
        model.addPreset(BonusPreset.damage[3])
        XCTAssertEqual(model.spec.extras, [BonusDice(count: 2, sides: 4), BonusDice(count: 2, sides: 8)])
        XCTAssertTrue(model.canAddPreset(BonusPreset.checks[2]))
    }
}
