import XCTest
@testable import Artsee

final class NailSpotCalculatorTests: XCTestCase {
    func testSinglePointIsCenteredBelowTopEdgeByDrop() {
        let pieceId = UUID()
        let spots = NailSpotCalculator.compute(
            pieceId: pieceId,
            pieceCenterXMeters: 1.0,
            pieceCenterYMeters: 2.0,
            pieceDisplayedHeightMeters: 0.5, // top edge at y = 2.25
            result: NailPlacementResult(kind: .singlePoint, dropMeters: 0.05, spacingMeters: nil)
        )

        XCTAssertEqual(spots.count, 1)
        XCTAssertEqual(spots[0].offsetXMeters, 1.0, accuracy: 0.0001)
        XCTAssertEqual(spots[0].offsetYMeters, 2.20, accuracy: 0.0001) // 2.25 - 0.05
        XCTAssertEqual(spots[0].pieceId, pieceId)
    }

    func testTwoPointSpotsAreSymmetricAndSameHeight() {
        let spots = NailSpotCalculator.compute(
            pieceId: UUID(),
            pieceCenterXMeters: 0.0,
            pieceCenterYMeters: 1.0,
            pieceDisplayedHeightMeters: 0.6, // top edge at y = 1.3
            result: NailPlacementResult(kind: .twoPoint, dropMeters: 0.1, spacingMeters: 0.4)
        )

        XCTAssertEqual(spots.count, 2)
        // Symmetric around the piece's horizontal center.
        XCTAssertEqual(spots[0].offsetXMeters, -0.2, accuracy: 0.0001)
        XCTAssertEqual(spots[1].offsetXMeters, 0.2, accuracy: 0.0001)
        // A two-point hanger only hangs level if both nails are at the
        // exact same height — this is the whole reason leveling matters
        // for two points and not one.
        XCTAssertEqual(spots[0].offsetYMeters, spots[1].offsetYMeters, accuracy: 0.0001)
        XCTAssertEqual(spots[0].offsetYMeters, 1.2, accuracy: 0.0001) // 1.3 - 0.1
    }

    func testZeroDropPutsSpotExactlyOnTopEdge() {
        let spots = NailSpotCalculator.compute(
            pieceId: UUID(),
            pieceCenterXMeters: 0,
            pieceCenterYMeters: 0,
            pieceDisplayedHeightMeters: 1.0,
            result: NailPlacementResult(kind: .singlePoint, dropMeters: 0, spacingMeters: nil)
        )
        XCTAssertEqual(spots[0].offsetYMeters, 0.5, accuracy: 0.0001)
    }
}
