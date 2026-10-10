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
        XCTAssertEqual(RollFormatter.installToRevealCaption(zh), "安装「掷定」查看结果")
        XCTAssertEqual(RollFormatter.needsUpdateText(zh), "无法读取这次投骰，请更新 App")
        XCTAssertEqual(RollFormatter.corruptText(zh), "数据无效")
    }

    func test_captions_english() {
        XCTAssertEqual(RollFormatter.pendingCaption(en), "Revealed when sent")
        XCTAssertEqual(RollFormatter.installToRevealCaption(en), "Install Dicide to see the result")
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

    func test_summary_withPurpose() {
        let spec = RollSpec(mode: .advantage, modifier: 5)
        XCTAssertEqual(RollFormatter.summary(spec, purpose: "察觉检定", zh), "🎲 察觉检定 · 1d20+5 · 优势")
        XCTAssertEqual(RollFormatter.summary(spec, purpose: "Perception", en), "🎲 Perception · 1d20+5 · Advantage")
        XCTAssertEqual(RollFormatter.summary(spec, purpose: nil, en), "🎲 1d20+5 · Advantage")
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

    func test_formula_withBonus() {
        let bless = RollSpec(mode: .advantage, modifier: 5, dc: 15, extras: [BonusDice(sides: 4)])
        XCTAssertEqual(RollFormatter.formula(bless, zh), "1d20+1d4+5 · 优势 · DC 15")
        XCTAssertEqual(RollFormatter.formula(bless, en), "1d20+1d4+5 · Advantage · DC 15")
        XCTAssertEqual(RollFormatter.formula(RollSpec(sides: 8, modifier: 3, extras: [BonusDice(count: 2, sides: 6)]), en), "1d8+2d6+3")
        XCTAssertEqual(RollFormatter.formula(RollSpec(extras: [BonusDice(sign: .minus, sides: 4)]), en), "1d20-1d4")
    }

    func test_detail_withBonus() {
        let bless = RollSpec(mode: .advantage, modifier: 5, extras: [BonusDice(sides: 4)])
        XCTAssertEqual(RollFormatter.detailMarkdown(bless, DiceEngine.evaluate(bless, dice: [17, 8], bonusRolls: [[3]])),
                       "[17, ~~8~~] + [3] + 5 = 25")
        let bane = RollSpec(extras: [BonusDice(sign: .minus, count: 2, sides: 6)])
        XCTAssertEqual(RollFormatter.detailMarkdown(bane, DiceEngine.evaluate(bane, dice: [10], bonusRolls: [[2, 5]])),
                       "[10] - [2, 5] = 3")
    }

    func test_formula_noCrits() {
        let spec = RollSpec(mode: .advantage, modifier: 5, dc: 15, criticalsEnabled: false)
        XCTAssertEqual(RollFormatter.formula(spec, zh), "1d20+5 · 优势 · DC 15 · 不判定大成功")
        XCTAssertEqual(RollFormatter.formula(spec, en), "1d20+5 · Advantage · DC 15 · No crits")
    }

    // Without a single d20 there is nothing to switch off, so nothing is shown.
    func test_formula_noCritsOnlyForSingleD20() {
        XCTAssertEqual(RollFormatter.formula(RollSpec(count: 2, criticalsEnabled: false), en), "2d20")
        XCTAssertEqual(RollFormatter.formula(RollSpec(sides: 6, criticalsEnabled: false), en), "1d6")
    }

    // MARK: - Spoken text for VoiceOver

    func test_spokenFormula_replacesDotsWithCommas() {
        let spec = RollSpec(mode: .advantage, modifier: 5, dc: 15)
        XCTAssertEqual(RollFormatter.spokenFormula(spec, en), "1d20+5, Advantage, DC 15")
        XCTAssertEqual(RollFormatter.spokenFormula(spec, zh), "1d20+5，优势，DC 15")
    }

    func test_spokenResult_advantageNamesTheKeptDie() {
        let spec = RollSpec(mode: .advantage, modifier: 5, dc: 15)
        let result = DiceEngine.evaluate(spec, dice: [17, 8])
        XCTAssertEqual(RollFormatter.spokenResult(spec, result, purpose: "Perception", en),
                       "Perception. 1d20+5, Advantage, DC 15. Rolled 17, 8; kept 17. Total 22. Success")
        XCTAssertEqual(RollFormatter.spokenResult(spec, result, purpose: "察觉检定", zh),
                       "察觉检定。1d20+5，优势，DC 15。掷出 17、8，取 17。总计 22。成功")
    }

    func test_spokenResult_plainRollWithoutPurposeOrOutcome() {
        let spec = RollSpec(count: 2, sides: 6, modifier: 3)
        let result = DiceEngine.evaluate(spec, dice: [2, 5])
        XCTAssertEqual(RollFormatter.spokenResult(spec, result, en), "2d6+3. Rolled 2, 5. Total 10")
        XCTAssertEqual(RollFormatter.spokenResult(spec, result, zh), "2d6+3。掷出 2、5。总计 10")
    }

    func test_spokenResult_bonusGroupsWithSigns() {
        let spec = RollSpec(extras: [BonusDice(sides: 4), BonusDice(sign: .minus, count: 2, sides: 6)])
        let result = DiceEngine.evaluate(spec, dice: [12], bonusRolls: [[3], [2, 5]])
        XCTAssertEqual(RollFormatter.spokenResult(spec, result, en),
                       "1d20+1d4-2d6. Rolled 12. Plus 1d4: 3. Minus 2d6: 2, 5. Total 8")
        XCTAssertEqual(RollFormatter.spokenResult(spec, result, zh),
                       "1d20+1d4-2d6。掷出 12。加 1d4：3。减 2d6：2、5。总计 8")
    }

    func test_spokenResult_criticalAndNoCrits() {
        let crit = RollSpec(dc: 30)
        XCTAssertEqual(RollFormatter.spokenResult(crit, DiceEngine.evaluate(crit, dice: [20]), en),
                       "1d20, DC 30. Rolled 20. Total 20. Critical Success")
        let off = RollSpec(dc: 30, criticalsEnabled: false)
        XCTAssertEqual(RollFormatter.spokenResult(off, DiceEngine.evaluate(off, dice: [20]), zh),
                       "1d20，DC 30，不判定大成功。掷出 20。总计 20。失败")
    }
}
