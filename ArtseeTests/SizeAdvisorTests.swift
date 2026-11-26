import XCTest
@testable import Artsee

final class SizeAdvisorTests: XCTestCase {
    func testTooSmallBelowRange() {
        // A small print over a wide sofa should trigger "too small" —
        // this is one of the spec's explicit proof tests.
        let advice = SizeAdvisor.furnitureFitAdvice(artworkWidthMeters: 0.4, furnitureWidthMeters: 2.0) // 20%
        XCTAssertEqual(advice.verdict, .tooSmall)
    }

    func testGoodFitWithinRange() {
        // ~2/3 of the furniture width is the textbook "right" size.
        let advice = SizeAdvisor.furnitureFitAdvice(artworkWidthMeters: 1.32, furnitureWidthMeters: 2.0) // 66%
        XCTAssertEqual(advice.verdict, .goodFit)
    }

    func testTooLargeAboveRange() {
        let advice = SizeAdvisor.furnitureFitAdvice(artworkWidthMeters: 1.9, furnitureWidthMeters: 2.0) // 95%
        XCTAssertEqual(advice.verdict, .tooLarge)
    }

    func testRangeBoundariesAreInclusiveAsDocumented() {
        let lower = SizeAdvisor.acceptableRatioRange.lowerBound
        let atLower = SizeAdvisor.furnitureFitAdvice(artworkWidthMeters: lower, furnitureWidthMeters: 1.0)
        XCTAssertEqual(atLower.verdict, .goodFit)
    }

    func testEyeLevelAdviceIsNilWithinTolerance() {
        let advice = SizeAdvisor.eyeLevelAdvice(centerHeightMeters: SizeAdvisor.idealEyeLevelCenterMeters)
        XCTAssertNil(advice)
    }

    func testEyeLevelAdviceFiresWhenFarOff() {
        let tooLow = SizeAdvisor.idealEyeLevelCenterMeters - 0.5 // way below eye level
        XCTAssertNotNil(SizeAdvisor.eyeLevelAdvice(centerHeightMeters: tooLow))

        let tooHigh = SizeAdvisor.idealEyeLevelCenterMeters + 0.5
        XCTAssertNotNil(SizeAdvisor.eyeLevelAdvice(centerHeightMeters: tooHigh))
    }
}
