import XCTest
@testable import DiceKit

final class RollFormatterTests: XCTestCase {
    private let zh = RollLanguage.simplifiedChinese
    private let en = RollLanguage.english

    func test_language_fromLocalization() {
        XCTAssertEqual(RollLanguage(localization: "zh-Hans"), zh)
        XCTAssertEqual(RollLanguage(localization: "zh-Hans-CN"), zh)
        XCTAssertEqual(RollLanguage(localization: "zh_Hans"), zh)
        XCTAssertEqual(RollLanguage(localization: "zh"), zh)
        XCTAssertEqual(RollLanguage(localization: "zh-CN"), zh)
        // Only Simplified Chinese is translated; everything else, Traditional included, is English.
        XCTAssertEqual(RollLanguage(localization: "zh-Hant"), en)
        XCTAssertEqual(RollLanguage(localization: "zh-TW"), en)
        XCTAssertEqual(RollLanguage(localization: "en"), en)
        XCTAssertEqual(RollLanguage(localization: "fr"), en)
        XCTAssertEqual(RollLanguage(localization: ""), en)
    }

    func test_formula() {
        XCTAssertEqual(RollFormatter.formula(RollSpec(mode: .advantage, modifier: 5, dc: 15), zh), "1d20+5 · 优势 · DC 15")
        XCTAssertEqual(RollFormatter.formula(RollSpec(count: 2, sides: 6), zh), "2d6")
        XCTAssertEqual(RollFormatter.formula(RollSpec(sides: 8, modifier: -2), zh), "1d8-2")
        XCTAssertEqual(RollFormatter.formula(RollSpec(mode: .disadvantage), zh), "1d20 · 劣势")
    }

    func test_formula_english() {
        XCTAssertEqual(RollFormatter.formula(RollSpec(mode: .advantage, modifier: 5, dc: 15), en), "1d20+5 · Advantage · DC 15")
        XCTAssertEqual(RollFormatter.formula(RollSpec(mode: .disadvantage), en), "1d20 · Disadvantage")
        XCTAssertEqual(RollFormatter.formula(RollSpec(count: 2, sides: 6), en), "2d6")
    }

    func test_captions() {
        XCTAssertEqual(RollFormatter.pendingCaption(zh), "发送后揭晓")
        XCTAssertEqual(RollFormatter.installToRevealCaption(zh), "安装 DND Dice 查看结果")
        XCTAssertEqual(RollFormatter.needsUpdateText(zh), "无法读取这次投骰，请更新 App")
        XCTAssertEqual(RollFormatter.corruptText(zh), "数据无效")
    }

    func test_captions_english() {
        XCTAssertEqual(RollFormatter.pendingCaption(en), "Revealed when sent")
        XCTAssertEqual(RollFormatter.installToRevealCaption(en), "Install DND Dice to see the result")
        XCTAssertEqual(RollFormatter.needsUpdateText(en), "Can't read this roll. Please update the app.")
        XCTAssertEqual(RollFormatter.corruptText(en), "Invalid roll data")
    }

    // History rows always use 24-hour HH:mm, even when the phone is set to 12-hour time.
    func test_clockTime_is24Hour() {
        let utc = TimeZone(identifier: "UTC")!
        XCTAssertEqual(RollFormatter.clockTime(Date(timeIntervalSince1970: 14 * 3600 + 30 * 60), timeZone: utc), "14:30")
        XCTAssertEqual(RollFormatter.clockTime(Date(timeIntervalSince1970: 5 * 60), timeZone: utc), "00:05")
    }

    func test_summary() {
        XCTAssertEqual(RollFormatter.summary(RollSpec(mode: .advantage, modifier: 5, dc: 15), zh), "🎲 1d20+5 · 优势 · DC 15")
        XCTAssertEqual(RollFormatter.summary(RollSpec(mode: .advantage, modifier: 5, dc: 15), en), "🎲 1d20+5 · Advantage · DC 15")
    }

    func test_detail() {
        let advantage = RollSpec(mode: .advantage, modifier: 5)
        let advantageResult = RollResult(dice: [17, 8], keptIndices: [0], total: 22, critical: .none, dcOutcome: nil)
        XCTAssertEqual(RollFormatter.detailMarkdown(advantage, advantageResult), "[17, ~~8~~] + 5 = 22")

        let twoD6 = RollSpec(count: 2, sides: 6, modifier: -2)
        XCTAssertEqual(RollFormatter.detailMarkdown(twoD6, DiceEngine.evaluate(twoD6, dice: [3, 4])), "[3, 4] - 2 = 5")

        let oneD6 = RollSpec(sides: 6)
        XCTAssertEqual(RollFormatter.detailMarkdown(oneD6, DiceEngine.evaluate(oneD6, dice: [6])), "[6] = 6")
    }

    func test_detail_twentyDice() {
        let spec = RollSpec(count: 20, sides: 100)
        let result = DiceEngine.evaluate(spec, dice: Array(81...100))
        let detail = RollFormatter.detailMarkdown(spec, result)
        XCTAssertEqual(detail.split(separator: ",").count, 20)
        XCTAssertTrue(detail.hasSuffix(" = \(result.total)"))
    }

    func test_outcome() {
        func result(_ critical: Critical, _ dc: DCOutcome?) -> RollResult {
            RollResult(dice: [10], keptIndices: [0], total: 10, critical: critical, dcOutcome: dc)
        }
        XCTAssertEqual(RollFormatter.outcome(result(.success, nil), zh), "大成功")
        XCTAssertEqual(RollFormatter.outcome(result(.failure, nil), zh), "大失败")
        XCTAssertEqual(RollFormatter.outcome(result(.none, .success), zh), "成功")
        XCTAssertEqual(RollFormatter.outcome(result(.none, .failure), zh), "失败")
        XCTAssertNil(RollFormatter.outcome(result(.none, nil), zh))
        XCTAssertEqual(RollFormatter.outcome(result(.success, .success), zh), "大成功")

        XCTAssertEqual(RollFormatter.outcome(result(.success, nil), en), "Critical Success")
        XCTAssertEqual(RollFormatter.outcome(result(.failure, nil), en), "Critical Failure")
        XCTAssertEqual(RollFormatter.outcome(result(.none, .success), en), "Success")
        XCTAssertEqual(RollFormatter.outcome(result(.none, .failure), en), "Failure")
        XCTAssertNil(RollFormatter.outcome(result(.none, nil), en))
    }
}
