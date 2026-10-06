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
        model.setDC(99)
        XCTAssertEqual(model.spec.dc, 40)
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

    func test_panel_makeRollSavesSpec() {
        let model = PanelModel(store: store)
        model.selectSides(12)
        model.changeModifier(by: 2)
        _ = model.makeRoll()
        XCTAssertEqual(store.load(), model.spec)
    }

    func test_panel_makeRollMessageDecodes() throws {
        let model = PanelModel(store: store)
        model.setMode(.advantage)
        model.setDC(15)
        let message = model.makeRoll()
        let decoded = try MessageCodec.decode(XCTUnwrap(message.url))
        XCTAssertEqual(decoded.spec, model.spec)
    }
}
