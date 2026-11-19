import Foundation

/// Pure rules engine behind the "size advisor" — the thing that tells the
/// user whether their art is actually the right size, instead of just
/// placing it and leaving them to guess.
enum SizeAdvisor {
    /// Classic interior-design rule of thumb: art over furniture should
    /// be roughly two-thirds that furniture's width.
    static let idealWidthRatio = 0.66
    static let acceptableRatioRange: ClosedRange<Double> = 0.55...0.78

    /// Center of the artwork should land near average standing eye level.
    static let idealEyeLevelCenterMeters = 1.448 // 57 in

    /// Tolerance before we bother nagging about eye-level height.
    static let eyeLevelToleranceInches = 2.0

    enum Verdict {
        case tooSmall
        case tooLarge
        case goodFit
    }

    struct FurnitureAdvice {
        let verdict: Verdict
        let ratioPercent: Int
        let message: String
    }

    static func furnitureFitAdvice(artworkWidthMeters: Double, furnitureWidthMeters: Double) -> FurnitureAdvice {
        let ratio = furnitureWidthMeters > 0 ? artworkWidthMeters / furnitureWidthMeters : 0
        let percent = Int((ratio * 100).rounded())

        if ratio < acceptableRatioRange.lowerBound {
            return FurnitureAdvice(
                verdict: .tooSmall,
                ratioPercent: percent,
                message: "Too small for what's below it — only about \(percent)% of its width. Art looks best at roughly two-thirds the width of the furniture under it. Try one size up, or add pieces to make a gallery wall."
            )
        } else if ratio > acceptableRatioRange.upperBound {
            return FurnitureAdvice(
                verdict: .tooLarge,
                ratioPercent: percent,
                message: "This runs wide for what's below it — about \(percent)% of its width. Consider a size down."
            )
        } else {
            return FurnitureAdvice(
                verdict: .goodFit,
                ratioPercent: percent,
                message: "Good fit — about \(percent)% of the furniture's width, right in the classic two-thirds range."
            )
        }
    }

    /// Returns nil when the current height is close enough to eye level
    /// that there's nothing worth saying.
    static func eyeLevelAdvice(centerHeightMeters: Double) -> String? {
        let diffMeters = centerHeightMeters - idealEyeLevelCenterMeters
        let diffInches = diffMeters / LengthUnit.inches.metersPerUnit
        guard abs(diffInches) >= eyeLevelToleranceInches else { return nil }

        let rounded = Int(abs(diffInches).rounded())
        if diffMeters > 0 {
            return "Hang it about \(rounded) in lower — center it near 57 in from the floor, average eye level."
        } else {
            return "Hang it about \(rounded) in higher — center it near 57 in from the floor, average eye level."
        }
    }
}
