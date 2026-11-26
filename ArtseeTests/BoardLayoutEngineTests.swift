import XCTest
@testable import Artsee

final class BoardLayoutEngineTests: XCTestCase {
    func testRowLayoutIsSymmetricAroundCenter() {
        let pieces = [
            Dimensions(widthMeters: 1, heightMeters: 1),
            Dimensions(widthMeters: 1, heightMeters: 1),
        ]
        let positions = BoardLayoutEngine.layout(preset: .row, pieces: pieces)
        XCTAssertEqual(positions.count, 2)
        // Equal-size pieces in a row should mirror around x = 0.
        XCTAssertEqual(positions[0].x, -positions[1].x, accuracy: 0.0001)
        XCTAssertEqual(positions[0].y, 0, accuracy: 0.0001)
        XCTAssertEqual(positions[1].y, 0, accuracy: 0.0001)
    }

    func testRowLayoutGapIsActuallyEven() {
        // The whole point of a locked gallery-board layout: gaps
        // between adjacent pieces must be identical, not eyeballed.
        let pieces = [
            Dimensions(widthMeters: 0.4, heightMeters: 0.5),
            Dimensions(widthMeters: 0.6, heightMeters: 0.5),
            Dimensions(widthMeters: 0.3, heightMeters: 0.5),
        ]
        let positions = BoardLayoutEngine.layout(preset: .row, pieces: pieces)
        XCTAssertEqual(positions.count, 3)

        let gap1 = (positions[1].x - pieces[1].widthMeters / 2) - (positions[0].x + pieces[0].widthMeters / 2)
        let gap2 = (positions[2].x - pieces[2].widthMeters / 2) - (positions[1].x + pieces[1].widthMeters / 2)
        XCTAssertEqual(gap1, gap2, accuracy: 0.0001)
        XCTAssertEqual(gap1, BoardLayoutEngine.defaultGapMeters, accuracy: 0.0001)
    }

    func testGridLayoutProducesOnePositionPerPiece() {
        let pieces = (0..<5).map { _ in Dimensions(widthMeters: 0.5, heightMeters: 0.5) }
        let positions = BoardLayoutEngine.layout(preset: .grid, pieces: pieces)
        XCTAssertEqual(positions.count, pieces.count)
    }

    func testSalonLayoutStillProducesOnePositionPerPieceWithFiniteValues() {
        let pieces = (0..<4).map { _ in Dimensions(widthMeters: 0.4, heightMeters: 0.6) }
        let positions = BoardLayoutEngine.layout(preset: .salon, pieces: pieces)
        XCTAssertEqual(positions.count, pieces.count)
        for position in positions {
            XCTAssertTrue(position.x.isFinite)
            XCTAssertTrue(position.y.isFinite)
        }
    }

    func testEmptyPiecesProducesNoPositions() {
        XCTAssertTrue(BoardLayoutEngine.layout(preset: .row, pieces: []).isEmpty)
    }
}
