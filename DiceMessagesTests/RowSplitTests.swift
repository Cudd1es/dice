import XCTest

final class RowSplitTests: XCTestCase {
    func test_bothFit_eachGetsItsIdealWidth() {
        let split = RowSplit.widths(available: 370, leading: 60, trailing: 120, spacing: 8)
        XCTAssertEqual(split.leading, 60)
        XCTAssertEqual(split.trailing, 120)
    }

    func test_longFormula_tagsKeepTheirWidthAndFormulaTakesTheRest() {
        let split = RowSplit.widths(available: 370, leading: 60, trailing: 400, spacing: 8)
        XCTAssertEqual(split.leading, 60)
        XCTAssertEqual(split.trailing, 302)
    }

    func test_manyTags_getAtMostHalfWhenTheFormulaNeedsTheRest() {
        let split = RowSplit.widths(available: 370, leading: 300, trailing: 250, spacing: 8)
        XCTAssertEqual(split.leading, 181)
        XCTAssertEqual(split.trailing, 181)
    }

    func test_manyTagsShortFormula_tagsTakeWhatTheFormulaLeaves() {
        let split = RowSplit.widths(available: 370, leading: 300, trailing: 80, spacing: 8)
        XCTAssertEqual(split.leading, 282)
        XCTAssertEqual(split.trailing, 80)
    }
}
