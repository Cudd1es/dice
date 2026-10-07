import XCTest
import Messages
import DiceKit

@MainActor
final class PanelModelTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: SpecStore { SpecStore(defaults: defaults) }

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: UUID().uuidString)
    }

    func test_panel_loadsLastSpec() {
        let spec = RollSpec(count: 3, sides: 8, modifier: -1)
        store.save(spec)
        XCTAssertEqual(PanelModel(store: store).spec, spec)
    }

    func test_panel_clampsCount() {
        store.save(RollSpec(count: 20, sides: 6))
        let model = PanelModel(store: store)
        model.changeCount(by: 1)
        XCTAssertEqual(model.spec.count, 20)
        model.changeCount(by: -19)
        model.changeCount(by: -1)
        XCTAssertEqual(model.spec.count, 1)
    }

    func test_panel_clampsModifier() {
        let model = PanelModel(store: store)
        model.changeModifier(by: 25)
        XCTAssertEqual(model.spec.modifier, 20)
        model.changeModifier(by: -50)
        XCTAssertEqual(model.spec.modifier, -20)
    }

    func test_panel_clampsDC() {
        let model = PanelModel(store: store)
        model.setDC(1500)
        XCTAssertEqual(model.spec.dc, 999)
        model.setDC(0)
        XCTAssertEqual(model.spec.dc, 1)
        model.setDC(nil)
        XCTAssertNil(model.spec.dc)
    }

    func test_panel_changingSidesResetsMode() {
        let model = PanelModel(store: store)
        model.setMode(.advantage)
        XCTAssertEqual(model.spec.mode, .advantage)
        model.selectSides(6)
        XCTAssertEqual(model.spec.mode, .normal)
        XCTAssertFalse(model.isModeEnabled)
    }

    func test_panel_changingCountResetsMode() {
        let model = PanelModel(store: store)
        model.setMode(.disadvantage)
        model.changeCount(by: 1)
        XCTAssertEqual(model.spec.mode, .normal)
    }

    func test_panel_modeIgnoredWhenDisabled() {
        let model = PanelModel(store: store)
        model.selectSides(8)
        model.setMode(.advantage)
        XCTAssertEqual(model.spec.mode, .normal)
    }

    func test_panel_rollSavesSpec() {
        let model = PanelModel(store: store)
        model.selectSides(12)
        model.changeModifier(by: 2)
        _ = model.roll()
        XCTAssertEqual(store.load(), model.spec)
    }

    func test_panel_rollIsReproducibleWithSeed() {
        let model = PanelModel(store: store)
        model.setMode(.advantage)
        model.setDC(15)
        var first = SplitMix64(seed: 7)
        var second = SplitMix64(seed: 7)
        let a = model.roll(using: &first)
        let b = model.roll(using: &second)
        XCTAssertEqual(a.spec, b.spec)
        XCTAssertEqual(a.result, b.result)
        XCTAssertEqual(a.spec, model.spec)
    }

    func test_panel_rollReturnsPurposeAndClears() {
        let model = PanelModel(store: store)
        model.purpose = "  攻击哥布林 "
        XCTAssertEqual(model.roll().purpose, "攻击哥布林")
        XCTAssertEqual(model.purpose, "")
    }

    func test_panel_blankPurposeIsNil() {
        let model = PanelModel(store: store)
        model.purpose = "  "
        XCTAssertNil(model.roll().purpose)
    }

    // The field cuts at 40 as you type (RollPanelView); a longer value still never leaves the panel.
    func test_panel_longPurposeRollsAs40() {
        let model = PanelModel(store: store)
        model.purpose = String(repeating: "a", count: 50)
        XCTAssertEqual(model.roll().purpose, String(repeating: "a", count: 40))
    }

    func test_panel_purposeNotSaved() {
        let model = PanelModel(store: store)
        model.purpose = "察觉检定"
        _ = model.roll()
        XCTAssertEqual(PanelModel(store: store).purpose, "")
    }

    func test_panel_setDCText() {
        let model = PanelModel(store: store)
        model.setDC(15)
        model.setDC(text: "120")
        XCTAssertEqual(model.spec.dc, 120)
        model.setDC(text: "5000")
        XCTAssertEqual(model.spec.dc, 999)
        model.setDC(text: "007")
        XCTAssertEqual(model.spec.dc, 7)
        model.setDC(text: "-5")
        XCTAssertEqual(model.spec.dc, 1)
        model.setDC(text: "")
        XCTAssertEqual(model.spec.dc, 1)
        model.setDC(text: "abc")
        XCTAssertEqual(model.spec.dc, 1)
    }

    // Tapping Roll with the number pad still up must roll the DC that was typed, not the old one.
    func test_panel_rollCommitsTypedDC() {
        let model = PanelModel(store: store)
        model.setDC(15)
        model.beginEditingDC()
        model.dcDraft = "18"
        XCTAssertEqual(model.roll().spec.dc, 18)
        XCTAssertNil(model.dcDraft)
        XCTAssertEqual(store.load().dc, 18)
    }

    // Switching DC off mid-edit drops the draft, so the later focus-loss commit cannot turn it back on.
    func test_panel_turningDCOffDropsDraft() {
        let model = PanelModel(store: store)
        model.setDC(15)
        model.beginEditingDC()
        model.dcDraft = "2"
        model.setDC(nil)
        model.commitDCDraft()
        XCTAssertNil(model.spec.dc)
        XCTAssertNil(model.dcDraft)
    }

    func test_panel_emptyDCDraftKeepsDC() {
        let model = PanelModel(store: store)
        model.setDC(15)
        model.beginEditingDC()
        model.commitDCDraft()
        XCTAssertEqual(model.spec.dc, 15)
        XCTAssertNil(model.dcDraft)
    }

    func test_panel_addBonusClosesPicker() {
        let model = PanelModel(store: store)
        model.isPickingBonus = true
        model.addBonus(sign: .plus, sides: 4)
        XCTAssertEqual(model.spec.extras, [BonusDice(sides: 4)])
        XCTAssertFalse(model.isPickingBonus)
    }

    func test_panel_incrementDecrementRemove() {
        let model = PanelModel(store: store)
        model.addBonus(sign: .plus, sides: 6)
        model.incrementBonus(at: 0)
        XCTAssertEqual(model.spec.extras, [BonusDice(count: 2, sides: 6)])
        model.decrementBonus(at: 0)
        model.decrementBonus(at: 0)
        XCTAssertEqual(model.spec.extras, [])
        model.addBonus(sign: .plus, sides: 4)
        model.addBonus(sign: .plus, sides: 8)
        model.removeBonus(at: 0)
        XCTAssertEqual(model.spec.extras, [BonusDice(sides: 8)])
    }

    func test_panel_incrementCapsAt10() {
        let model = PanelModel(store: store)
        model.addBonus(sign: .plus, sides: 6)
        for _ in 0..<12 { model.incrementBonus(at: 0) }
        XCTAssertEqual(model.spec.extras, [BonusDice(count: 10, sides: 6)])
    }

    // A tag's menu can outlive its group; a stale index must do nothing.
    func test_panel_bonusIndexOutOfRangeIgnored() {
        let model = PanelModel(store: store)
        model.incrementBonus(at: 0)
        model.decrementBonus(at: 3)
        model.removeBonus(at: -1)
        XCTAssertEqual(model.spec.extras, [])
    }

    // Bonus dice belong to one roll, like the purpose: rolling uses them, then the panel starts without any.
    func test_panel_rollClearsBonus() {
        let model = PanelModel(store: store)
        model.addBonus(sign: .minus, sides: 4)
        let rolled = model.roll()
        XCTAssertEqual(rolled.spec.extras, [BonusDice(sign: .minus, sides: 4)])
        XCTAssertEqual(rolled.result.bonusRolls.count, 1)
        XCTAssertEqual(model.spec.extras, [])
        XCTAssertEqual(store.load().extras, [])
    }

    // 0.4.0 and 0.5.0 saved bonus dice with the formula; they no longer carry over.
    func test_panel_loadDropsSavedBonus() {
        store.save(RollSpec(modifier: 3, extras: [BonusDice(sides: 4)]))
        let model = PanelModel(store: store)
        XCTAssertEqual(model.spec, RollSpec(modifier: 3))
    }

    func test_panel_rollIncludesBonus() {
        let model = PanelModel(store: store)
        model.addBonus(sign: .plus, sides: 4)
        model.addBonus(sign: .minus, sides: 6)
        XCTAssertEqual(model.roll().result.bonusRolls.map(\.count), [1, 1])
    }

    // Leaving the Messages drawer with the picker open must not bring the picker back next time.
    func test_panel_didActivateClosesPicker() {
        let model = PanelModel(store: store)
        model.isPickingBonus = true
        model.didActivate()
        XCTAssertFalse(model.isPickingBonus)
    }

    private func settings(criticals: Bool) -> SettingsStore {
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        settings.criticalsEnabled = criticals
        return settings
    }

    func test_panel_rollUsesSettings() {
        let model = PanelModel(store: store, settings: settings(criticals: false))
        XCTAssertFalse(model.roll().spec.criticalsEnabled)
    }

    func test_panel_refreshSettingsUpdatesFormula() {
        let settings = settings(criticals: true)
        let model = PanelModel(store: store, settings: settings)
        settings.criticalsEnabled = false
        model.refreshSettings()
        XCTAssertEqual(RollFormatter.formula(model.spec), RollFormatter.formula(RollSpec(criticalsEnabled: false)))
    }

    // The setting can change in the app while the Messages extension is already open.
    func test_panel_didActivateRefreshesSettings() {
        let settings = settings(criticals: true)
        let model = PanelModel(store: store, settings: settings)
        settings.criticalsEnabled = false
        model.didActivate()
        XCTAssertFalse(model.spec.criticalsEnabled)
    }

    func test_panel_settingOverridesStoredFlag() {
        store.save(RollSpec(criticalsEnabled: false))
        XCTAssertTrue(PanelModel(store: store, settings: settings(criticals: true)).spec.criticalsEnabled)
    }
}
