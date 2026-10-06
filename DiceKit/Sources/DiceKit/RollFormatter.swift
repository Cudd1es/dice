import Foundation

/// User-facing text for rolls, in English or Simplified Chinese.
public enum RollFormatter {
    public static func pendingCaption(_ language: RollLanguage = .current) -> String {
        language == .english ? "Revealed when sent" : "发送后揭晓"
    }

    /// Subcaption of the fallback bubble that people without the app see.
    public static func installToRevealCaption(_ language: RollLanguage = .current) -> String {
        language == .english ? "Install DND Dice to see the result" : "安装 DND Dice 查看结果"
    }

    public static func needsUpdateText(_ language: RollLanguage = .current) -> String {
        language == .english ? "Can't read this roll. Please update the app." : "无法读取这次投骰，请更新 App"
    }

    public static func corruptText(_ language: RollLanguage = .current) -> String {
        language == .english ? "Invalid roll data" : "数据无效"
    }

    /// e.g. "1d20+5 · Advantage · DC 15" / "1d20+5 · 优势 · DC 15"
    public static func formula(_ spec: RollSpec, _ language: RollLanguage = .current) -> String {
        var text = "\(spec.count)d\(spec.sides)"
        if spec.modifier > 0 { text += "+\(spec.modifier)" }
        if spec.modifier < 0 { text += "\(spec.modifier)" }
        switch spec.mode {
        case .normal: break
        case .advantage: text += language == .english ? " · Advantage" : " · 优势"
        case .disadvantage: text += language == .english ? " · Disadvantage" : " · 劣势"
        }
        if let dc = spec.dc { text += " · DC \(dc)" }
        return text
    }

    public static func summary(_ spec: RollSpec, _ language: RollLanguage = .current) -> String {
        "🎲 " + formula(spec, language)
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

    public static func outcome(_ result: RollResult, _ language: RollLanguage = .current) -> String? {
        let english = language == .english
        switch result.critical {
        case .success: return english ? "Critical Success" : "大成功"
        case .failure: return english ? "Critical Failure" : "大失败"
        case .none: break
        }
        switch result.dcOutcome {
        case .success: return english ? "Success" : "成功"
        case .failure: return english ? "Failure" : "失败"
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
