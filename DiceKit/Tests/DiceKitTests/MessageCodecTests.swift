import XCTest
@testable import DiceKit

final class MessageCodecTests: XCTestCase {
    private func url(_ query: String) -> URL {
        URL(string: "https://dice.invalid/roll?\(query)")!
    }

    private func assertDecodeThrows(_ query: String, _ expected: CodecError, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try MessageCodec.decode(url(query)), file: file, line: line) { error in
            XCTAssertEqual(error as? CodecError, expected, file: file, line: line)
        }
    }

    func test_roundTrip() throws {
        let cases: [(RollSpec, [Int])] = [
            (RollSpec(mode: .advantage, modifier: 5, dc: 15), [8, 17]),
            (RollSpec(count: 2, sides: 6, modifier: -2), [3, 4]),
            (RollSpec(count: 20, sides: 100), Array(1...20).map { $0 * 5 }),
        ]
        for (spec, dice) in cases {
            let result = DiceEngine.evaluate(spec, dice: dice)
            let decoded = try MessageCodec.decode(MessageCodec.url(for: spec, result: result))
            XCTAssertEqual(decoded.spec, spec)
            XCTAssertEqual(decoded.result, result)
        }
    }

    func test_dc999RoundTrips() throws {
        let spec = RollSpec(sides: 100, dc: 999)
        let decoded = try MessageCodec.decode(MessageCodec.url(for: spec, result: DiceEngine.evaluate(spec, dice: [42])))
        XCTAssertEqual(decoded.spec.dc, 999)
    }

    private let legacy = "https://dice.invalid/roll?v=1&n=1&s=20&m=a&k=5&dc=15&d=17,8"
    private let advantage = RollSpec(mode: .advantage, modifier: 5, dc: 15)

    func test_purposeRoundTrips() throws {
        let result = DiceEngine.evaluate(advantage, dice: [17, 8])
        let decoded = try MessageCodec.decode(MessageCodec.url(for: advantage, result: result, purpose: "察觉检定：门后有没有人"))
        XCTAssertEqual(decoded.purpose, "察觉检定：门后有没有人")
        XCTAssertEqual(decoded.spec, advantage)
        XCTAssertEqual(decoded.result, result)
    }

    func test_purpose_specialCharactersRoundTrip() throws {
        let purpose = "100% & a=b + c #1 🎲"
        let result = DiceEngine.evaluate(advantage, dice: [17, 8])
        let decoded = try MessageCodec.decode(MessageCodec.url(for: advantage, result: result, purpose: purpose))
        XCTAssertEqual(decoded.purpose, purpose)
    }

    // Without a purpose the URL is exactly what 0.2.1 produced.
    func test_noPurposeURLUnchanged() {
        let result = DiceEngine.evaluate(advantage, dice: [17, 8])
        XCTAssertEqual(MessageCodec.url(for: advantage, result: result).absoluteString, legacy)
        XCTAssertEqual(MessageCodec.url(for: advantage, result: result, purpose: "  ").absoluteString, legacy)
    }

    func test_decode_legacyURLHasNoPurpose() throws {
        XCTAssertNil(try MessageCodec.decode(URL(string: legacy)!).purpose)
    }

    func test_decode_normalizesPurpose() throws {
        let long = try MessageCodec.decode(URL(string: legacy + "&p=" + String(repeating: "a", count: 50))!)
        XCTAssertEqual(long.purpose, String(repeating: "a", count: 40))
        XCTAssertNil(try MessageCodec.decode(URL(string: legacy + "&p=%20%20")!).purpose)
    }

    func test_url_containsVersion() {
        let spec = RollSpec()
        let url = MessageCodec.url(for: spec, result: DiceEngine.evaluate(spec, dice: [7]))
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(items.first { $0.name == "v" }?.value, "1")
    }

    // Spike (docs/superpowers/spikes/2026-10-05-live-layout.md): Messages drops custom-scheme URLs.
    func test_url_usesHTTPS() {
        let spec = RollSpec()
        let url = MessageCodec.url(for: spec, result: DiceEngine.evaluate(spec, dice: [7]))
        XCTAssertEqual(url.scheme, "https")
    }

    func test_decode_missingVersion() {
        assertDecodeThrows("n=1&s=20&m=n&k=0&d=7", .missingField("v"))
    }

    func test_decode_futureVersion() {
        assertDecodeThrows("v=4&n=1&s=20&m=n&k=0&d=7", .unsupportedVersion(4))
    }

    func test_decode_missingField() {
        assertDecodeThrows("v=1&s=20&m=n&k=0&d=7", .missingField("n"))
    }

    func test_decode_malformedNumber() {
        assertDecodeThrows("v=1&n=abc&s=20&m=n&k=0&d=7", .malformed("n"))
    }

    func test_decode_malformedModeAndDice() {
        assertDecodeThrows("v=1&n=1&s=20&m=x&k=0&d=7", .malformed("m"))
        assertDecodeThrows("v=1&n=1&s=20&m=n&k=0&d=7,x", .malformed("d"))
    }

    func test_decode_outOfRangeSpec() {
        assertDecodeThrows("v=1&n=1&s=7&m=n&k=0&d=7", .invalidSpec(.invalidSides(7)))
    }

    func test_decode_wrongDiceCount() {
        assertDecodeThrows("v=1&n=1&s=20&m=a&k=0&d=12", .invalidDice)
    }

    func test_decode_dieOutOfRange() {
        assertDecodeThrows("v=1&n=1&s=6&m=n&k=0&d=7", .invalidDice)
    }

    private let bonusSpec = RollSpec(modifier: 5, extras: [BonusDice(sides: 4), BonusDice(sign: .minus, count: 2, sides: 6)])

    func test_bonusURLUsesV2() {
        let result = DiceEngine.evaluate(bonusSpec, dice: [12], bonusRolls: [[3], [2, 5]])
        XCTAssertEqual(MessageCodec.url(for: bonusSpec, result: result).absoluteString,
                       "https://dice.invalid/roll?v=2&n=1&s=20&m=n&k=5&x=1d4,-2d6&d=12,3,2,5")
    }

    func test_bonusRoundTrips() throws {
        let plain = DiceEngine.evaluate(bonusSpec, dice: [12], bonusRolls: [[3], [2, 5]])
        let decoded = try MessageCodec.decode(MessageCodec.url(for: bonusSpec, result: plain))
        XCTAssertEqual(decoded.spec, bonusSpec)
        XCTAssertEqual(decoded.result, plain)

        let bless = RollSpec(mode: .advantage, modifier: 3, dc: 15, extras: [BonusDice(sides: 4)])
        let rolled = DiceEngine.evaluate(bless, dice: [8, 17], bonusRolls: [[2]])
        let withPurpose = try MessageCodec.decode(MessageCodec.url(for: bless, result: rolled, purpose: "攻击哥布林"))
        XCTAssertEqual(withPurpose.spec, bless)
        XCTAssertEqual(withPurpose.result, rolled)
        XCTAssertEqual(withPurpose.purpose, "攻击哥布林")
    }

    func test_decode_invalidExtrasRejected() {
        let head = "v=2&n=1&s=20&m=n&k=0"
        assertDecodeThrows(head + "&x=1d4,1d6,1d8,1d10,1d12&d=1,1,1,1,1,1", .invalidSpec(.invalidExtras))
        assertDecodeThrows(head + "&x=1d4,1d4&d=1,1,1", .invalidSpec(.invalidExtras))
        assertDecodeThrows(head + "&x=1d&d=1,1", .malformed("x"))
        assertDecodeThrows(head + "&x=0d6&d=1", .invalidSpec(.invalidExtras))
        assertDecodeThrows(head + "&x=1d7&d=1,1", .invalidSpec(.invalidExtras))
    }

    func test_decode_bonusDiceCountMismatch() {
        assertDecodeThrows("v=2&n=1&s=20&m=n&k=0&x=2d6&d=1,1", .invalidDice)
        assertDecodeThrows("v=2&n=1&s=20&m=n&k=0&x=1d4&d=1,5", .invalidDice)
    }

    // Version 1 never had bonus dice, so a stray x is ignored as before.
    func test_decode_v1IgnoresX() throws {
        let decoded = try MessageCodec.decode(url("v=1&n=1&s=20&m=n&k=0&x=1d4&d=7"))
        XCTAssertEqual(decoded.spec.extras, [])
        XCTAssertEqual(decoded.result.total, 7)
    }

    private let noCrits = RollSpec(modifier: 5, dc: 15, criticalsEnabled: false)

    func test_criticalsOffUsesV3() {
        let result = DiceEngine.evaluate(noCrits, dice: [20])
        XCTAssertEqual(MessageCodec.url(for: noCrits, result: result).absoluteString,
                       "https://dice.invalid/roll?v=3&n=1&s=20&m=n&k=5&dc=15&c=0&d=20")
    }

    func test_criticalsOffRoundTrips() throws {
        let plain = DiceEngine.evaluate(noCrits, dice: [20])
        let decoded = try MessageCodec.decode(MessageCodec.url(for: noCrits, result: plain))
        XCTAssertEqual(decoded.spec, noCrits)
        XCTAssertEqual(decoded.result, plain)
        XCTAssertEqual(decoded.result.critical, .none)

        let blessed = RollSpec(modifier: 5, dc: 15, extras: [BonusDice(sides: 4)], criticalsEnabled: false)
        let rolled = DiceEngine.evaluate(blessed, dice: [20], bonusRolls: [[3]])
        let withPurpose = try MessageCodec.decode(MessageCodec.url(for: blessed, result: rolled, purpose: "攻击"))
        XCTAssertEqual(withPurpose.spec, blessed)
        XCTAssertEqual(withPurpose.result, rolled)
        XCTAssertEqual(withPurpose.purpose, "攻击")
    }

    // Without a single main d20 the setting changes nothing, so the URL stays at version 1.
    func test_criticalsOffNonD20StaysV1() throws {
        let spec = RollSpec(sides: 6, criticalsEnabled: false)
        let url = MessageCodec.url(for: spec, result: DiceEngine.evaluate(spec, dice: [4]))
        XCTAssertEqual(url.absoluteString, "https://dice.invalid/roll?v=1&n=1&s=6&m=n&k=0&d=4")
        XCTAssertTrue(try MessageCodec.decode(url).spec.criticalsEnabled)
    }

    func test_decode_badCriticalsField() {
        assertDecodeThrows("v=3&n=1&s=20&m=n&k=0&c=x&d=7", .malformed("c"))
    }

    func test_decode_v3WithoutCIsEnabled() throws {
        let decoded = try MessageCodec.decode(url("v=3&n=1&s=20&m=n&k=0&d=20"))
        XCTAssertTrue(decoded.spec.criticalsEnabled)
        XCTAssertEqual(decoded.result.critical, .success)
    }

    // Versions 1 and 2 never had c; older apps ignore it, so this one does too.
    func test_decode_v2IgnoresC() throws {
        let decoded = try MessageCodec.decode(url("v=2&n=1&s=20&m=n&k=0&x=1d4&c=0&d=20,3"))
        XCTAssertTrue(decoded.spec.criticalsEnabled)
        XCTAssertEqual(decoded.result.critical, .success)
    }
}
