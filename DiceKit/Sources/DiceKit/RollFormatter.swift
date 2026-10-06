import Foundation

/// User-facing (Chinese) text for rolls.
public enum RollFormatter {
    public static let pendingCaption = "发送后揭晓"
    /// Subcaption of the fallback bubble that people without the app see.
    public static let installToRevealCaption = "安装「骰子」App 查看结果"
    public static let needsUpdateText = "无法读取这次投骰，请更新 App"
    public static let corruptText = "数据无效"

    /// e.g. "1d20+5 · 优势 · DC 15"
    public static func formula(_ spec: RollSpec) -> String {
        var text = "\(spec.count)d\(spec.sides)"
        if spec.modifier > 0 { text += "+\(spec.modifier)" }
        if spec.modifier < 0 { text += "\(spec.modifier)" }
        switch spec.mode {
        case .normal: break
        case .advantage: text += " · 优势"
        case .disadvantage: text += " · 劣势"
        }
        if let dc = spec.dc { text += " · DC \(dc)" }
        return text
    }

    public static func summary(_ spec: RollSpec) -> String {
        "🎲 " + formula(spec)
    }

    /// e.g. "[17, ~~8~~] + 5 = 22"; dropped dice are struck through for `AttributedString(markdown:)`.
    public static func detailMarkdown(_ spec: RollSpec, _ result: RollResult) -> String {
        let dice = result.dice.enumerated().map { index, value in
            result.keptIndices.contains(index) ? "\(value)" : "~~\(value)~~"
        }
        var text = "[" + dice.joined(separator: ", ") + "]"
        if spec.modifier > 0 { text += " + \(spec.modifier)" }
        if spec.modifier < 0 { text += " - \(-spec.modifier)" }
        return text + " = \(result.total)"
    }

    public static func outcome(_ result: RollResult) -> String? {
        switch result.critical {
        case .success: return "大成功"
        case .failure: return "大失败"
        case .none: break
        }
        switch result.dcOutcome {
        case .success: return "成功"
        case .failure: return "失败"
        case nil: return nil
        }
    }

    /// "HH:mm" in 24-hour time regardless of the device's 12/24-hour setting.
    public static func clockTime(_ date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }
}
