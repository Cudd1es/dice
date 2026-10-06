import Foundation

public enum CodecError: Error, Equatable {
    case missingField(String)
    case unsupportedVersion(Int)
    /// Name of the field whose value failed to parse.
    case malformed(String)
    case invalidSpec(RollSpecError)
    case invalidDice
}

/// Encodes a roll into the message URL and back.
///
/// The total is not stored: decoding recomputes it with `DiceEngine.evaluate`,
/// so a URL whose total disagrees with its dice cannot exist.
public enum MessageCodec {
    public static let currentVersion = 1

    /// Messages drops custom-scheme URLs, so the payload rides on an https URL.
    /// `.invalid` is a reserved TLD and never resolves.
    private static let base = "https://dice.invalid/roll"

    private static let modeCodes: [RollMode: String] = [.normal: "n", .advantage: "a", .disadvantage: "d"]

    /// The purpose rides in an optional `p` field. Version 1 decoders ignore unknown fields, so 0.2.1 still
    /// shows the result; without a purpose the URL is unchanged.
    public static func url(for spec: RollSpec, result: RollResult, purpose: String? = nil) -> URL {
        var components = URLComponents(string: base)!
        var items = [
            URLQueryItem(name: "v", value: String(currentVersion)),
            URLQueryItem(name: "n", value: String(spec.count)),
            URLQueryItem(name: "s", value: String(spec.sides)),
            URLQueryItem(name: "m", value: modeCodes[spec.mode]),
            URLQueryItem(name: "k", value: String(spec.modifier)),
        ]
        if let dc = spec.dc {
            items.append(URLQueryItem(name: "dc", value: String(dc)))
        }
        items.append(URLQueryItem(name: "d", value: result.dice.map(String.init).joined(separator: ",")))
        if let purpose = purpose.flatMap(RollPurpose.normalize) {
            items.append(URLQueryItem(name: "p", value: purpose))
        }
        components.queryItems = items
        return components.url!
    }

    /// A missing, blank or oversized purpose never fails decoding; it is normalized like typed input.
    public static func decode(_ url: URL) throws -> (spec: RollSpec, result: RollResult, purpose: String?) {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }
        func required(_ name: String) throws -> String {
            guard let raw = value(name) else { throw CodecError.missingField(name) }
            return raw
        }
        func int(_ name: String) throws -> Int {
            guard let number = Int(try required(name)) else { throw CodecError.malformed(name) }
            return number
        }

        let version = try int("v")
        guard version == currentVersion else { throw CodecError.unsupportedVersion(version) }

        let count = try int("n")
        let sides = try int("s")
        let modeCode = try required("m")
        guard let mode = modeCodes.first(where: { $0.value == modeCode })?.key else {
            throw CodecError.malformed("m")
        }
        let modifier = try int("k")
        let dc: Int? = try value("dc").map { _ in try int("dc") }
        let dice = try required("d").split(separator: ",", omittingEmptySubsequences: false).map { part -> Int in
            guard let die = Int(part) else { throw CodecError.malformed("d") }
            return die
        }

        let spec = RollSpec(count: count, sides: sides, mode: mode, modifier: modifier, dc: dc)
        do {
            try spec.validate()
        } catch let error as RollSpecError {
            throw CodecError.invalidSpec(error)
        }
        guard dice.count == spec.diceToRoll, dice.allSatisfy({ (1...sides).contains($0) }) else {
            throw CodecError.invalidDice
        }
        return (spec, DiceEngine.evaluate(spec, dice: dice), value("p").flatMap(RollPurpose.normalize))
    }
}
