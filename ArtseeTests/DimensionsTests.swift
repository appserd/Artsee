import XCTest
@testable import Artsee

final class DimensionsTests: XCTestCase {
    func testInchesToMetersRoundTrip() {
        let dims = Dimensions(width: 16, height: 20, unit: .inches)
        XCTAssertEqual(dims.width(in: .inches), 16, accuracy: 0.0001)
        XCTAssertEqual(dims.height(in: .inches), 20, accuracy: 0.0001)
        XCTAssertEqual(dims.widthMeters, 16 * 0.0254, accuracy: 0.0001)
    }

    func testCentimeterConversion() {
        let dims = Dimensions(width: 40, height: 50, unit: .centimeters)
        XCTAssertEqual(dims.width(in: .centimeters), 40, accuracy: 0.0001)
        XCTAssertEqual(dims.width(in: .inches), 40 / 2.54, accuracy: 0.001)
    }

    func testFormattedIncludesUnitAbbreviation() {
        let dims = Dimensions(width: 16, height: 20, unit: .inches)
        XCTAssertTrue(dims.formatted(in: .inches).contains("in"))
        XCTAssertTrue(dims.formatted(in: .centimeters).contains("cm"))
    }

    func testReferenceObjectDimensionsAreStandard() {
        // These are the whole point of the reference-object sizing
        // feature — if these are ever wrong, every measurement using
        // them is silently wrong too.
        let card = ReferenceObjectKind.creditCard.dimensions
        XCTAssertEqual(card.width(in: .inches), 3.375, accuracy: 0.001)
        XCTAssertEqual(card.height(in: .inches), 2.125, accuracy: 0.001)

        let bill = ReferenceObjectKind.dollarBill.dimensions
        XCTAssertEqual(bill.width(in: .inches), 6.14, accuracy: 0.001)
        XCTAssertEqual(bill.height(in: .inches), 2.61, accuracy: 0.001)
    }

    func testCommonSizesIncludeSquares() {
        // Regression test — v1 only offered portrait ratios until a
        // square scanned piece on device had nothing to pick from.
        let squareSizes = CommonSize.allCases.filter { $0.dimensions.widthMeters == $0.dimensions.heightMeters }
        XCTAssertFalse(squareSizes.isEmpty, "Expected at least one square common size")
    }
}
