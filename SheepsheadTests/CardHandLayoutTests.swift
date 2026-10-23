import XCTest
@testable import Sheepshead

/// Hands wrap into even rows, so no card is ever left alone on a second row.
final class CardHandLayoutTests: XCTestCase {
    func testShortHandsStayOnOneRow() {
        XCTAssertEqual(CardHandView.rowSizes(count: 5), [5])
        XCTAssertEqual(CardHandView.rowSizes(count: 6), [6])
        XCTAssertEqual(CardHandView.rowSizes(count: 7), [7])
    }

    func testPickerHandSplitsFourAndFour() {
        XCTAssertEqual(CardHandView.rowSizes(count: 8), [4, 4])
    }

    func testRowsNeverDifferByMoreThanOne() {
        for count in 1...20 {
            let rows = CardHandView.rowSizes(count: count)
            XCTAssertEqual(rows.reduce(0, +), count)
            XCTAssertLessThanOrEqual(rows.max()! - rows.min()!, 1)
            XCTAssertTrue(rows.allSatisfy { $0 <= CardHandView.maxColumns })
            XCTAssertEqual(rows, rows.sorted(by: >), "longer rows come first")
        }
    }

    func testEmptyHandHasNoRows() {
        XCTAssertEqual(CardHandView.rowSizes(count: 0), [])
    }
}
