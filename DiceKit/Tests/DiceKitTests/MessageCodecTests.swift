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
        assertDecodeThrows("v=2&n=1&s=20&m=n&k=0&d=7", .unsupportedVersion(2))
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
}
