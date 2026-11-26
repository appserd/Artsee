import Foundation

/// Pure geometry — computes where the nail(s) need to go directly from
/// a piece's already-known true-size position, with no AR/UIKit
/// dependency, so this can be unit-tested without a simulator or
/// device at all.
enum NailSpotCalculator {
    static func compute(
        pieceId: UUID,
        pieceCenterXMeters: Double,
        pieceCenterYMeters: Double,
        pieceDisplayedHeightMeters: Double,
        result: NailPlacementResult
    ) -> [NailSpot] {
        let topY = pieceCenterYMeters + pieceDisplayedHeightMeters / 2
        let nailY = topY - result.dropMeters

        switch result.kind {
        case .singlePoint:
            return [NailSpot(pieceId: pieceId, offsetXMeters: pieceCenterXMeters, offsetYMeters: nailY)]
        case .twoPoint:
            let halfSpacing = (result.spacingMeters ?? 0) / 2
            return [
                NailSpot(pieceId: pieceId, offsetXMeters: pieceCenterXMeters - halfSpacing, offsetYMeters: nailY),
                NailSpot(pieceId: pieceId, offsetXMeters: pieceCenterXMeters + halfSpacing, offsetYMeters: nailY),
            ]
        }
    }
}
