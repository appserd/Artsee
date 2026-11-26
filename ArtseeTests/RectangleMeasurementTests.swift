import XCTest
@testable import Artsee

final class RectangleMeasurementTests: XCTestCase {
    /// Builds a normalized, axis-aligned quad (Vision's bottom-left
    /// origin convention) of the given width/height, for a square
    /// (imageAspect = 1) test photo so normalizedSize() reduces to
    /// plain width/height.
    private func quad(width: CGFloat, height: CGFloat) -> DetectedQuad {
        DetectedQuad(
            topLeft: CGPoint(x: 0, y: height),
            topRight: CGPoint(x: width, y: height),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: width, y: 0),
            confidence: 1
        )
    }

    func testMeasureArtworkAgainstCreditCard() {
        // A credit card occupying 20%x10% of a square photo, with
        // artwork occupying 60%x50% — hand-computed expected result
        // below (meters-per-normalized-unit ≈ 0.4841875).
        let referenceQuad = quad(width: 0.2, height: 0.1)
        let artworkQuad = quad(width: 0.6, height: 0.5)

        let result = RectangleMeasurement.measureArtwork(
            artworkQuad: artworkQuad,
            referenceQuad: referenceQuad,
            referenceDimensions: ReferenceObjectKind.creditCard.dimensions,
            imageAspect: 1.0
        )

        XCTAssertEqual(result.widthMeters, 0.2905, accuracy: 0.001)
        XCTAssertEqual(result.heightMeters, 0.2421, accuracy: 0.001)
    }

    func testLargerReferenceQuadYieldsSmallerArtwork() {
        // Sanity check on the scaling direction: if the reference
        // object appears bigger in the photo (closer to camera /
        // actually physically bigger in frame), the same artwork quad
        // should resolve to a *smaller* real-world size.
        let smallReference = quad(width: 0.1, height: 0.05)
        let largeReference = quad(width: 0.2, height: 0.1)
        let artworkQuad = quad(width: 0.6, height: 0.5)

        let resultSmallRef = RectangleMeasurement.measureArtwork(
            artworkQuad: artworkQuad, referenceQuad: smallReference,
            referenceDimensions: ReferenceObjectKind.creditCard.dimensions, imageAspect: 1.0
        )
        let resultLargeRef = RectangleMeasurement.measureArtwork(
            artworkQuad: artworkQuad, referenceQuad: largeReference,
            referenceDimensions: ReferenceObjectKind.creditCard.dimensions, imageAspect: 1.0
        )

        XCTAssertGreaterThan(resultSmallRef.widthMeters, resultLargeRef.widthMeters)
    }

    func testPortraitAspectDoesNotSilentlySwapWidthAndHeight() {
        // Regression test for a real bug: detectQuads once sorted
        // candidates using the raw, unrotated cgImage dimensions
        // instead of the orientation-corrected size, which swapped
        // width/height for any portrait photo. This exercises the
        // same measureArtwork math with a non-square imageAspect to
        // guard against that class of bug reappearing.
        let referenceQuad = quad(width: 0.2, height: 0.1)
        let artworkQuad = quad(width: 0.4, height: 0.6)
        let portraitAspect: CGFloat = 0.75 // narrower than tall, like a phone photo

        let result = RectangleMeasurement.measureArtwork(
            artworkQuad: artworkQuad,
            referenceQuad: referenceQuad,
            referenceDimensions: ReferenceObjectKind.creditCard.dimensions,
            imageAspect: portraitAspect
        )

        // A portrait-oriented artwork quad (taller than wide in
        // normalized coordinates) must still resolve taller than wide
        // in real-world meters.
        XCTAssertGreaterThan(result.heightMeters, result.widthMeters)
    }
}
