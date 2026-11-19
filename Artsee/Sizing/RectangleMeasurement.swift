import UIKit
import Vision

/// A quadrilateral Vision found in a photo, in normalized image
/// coordinates (0...1, origin bottom-left — Vision's convention).
struct DetectedQuad: Identifiable {
    let id = UUID()
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
    let confidence: Float

    /// Average of the two side lengths, in normalized units, for each axis.
    func normalizedSize(imageAspect: CGFloat) -> (width: CGFloat, height: CGFloat) {
        // Vision's points are normalized to a square 0...1 space; scale by
        // the image's real aspect ratio to get proportionally-correct
        // width/height before converting to physical units.
        func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            let dx = (a.x - b.x) * imageAspect
            let dy = (a.y - b.y)
            return sqrt(dx * dx + dy * dy)
        }
        let topWidth = distance(topLeft, topRight)
        let bottomWidth = distance(bottomLeft, bottomRight)
        let leftHeight = distance(topLeft, bottomLeft)
        let rightHeight = distance(topRight, bottomRight)
        return ((topWidth + bottomWidth) / 2, (leftHeight + rightHeight) / 2)
    }
}

enum RectangleMeasurement {
    /// Finds candidate rectangles (artwork edge, reference-object edge) in
    /// a single photo. Returns the largest few by area so the caller can
    /// let the user pick which is which.
    static func detectQuads(in image: UIImage, maxResults: Int = 5) async -> [DetectedQuad] {
        guard let cgImage = image.cgImage else { return [] }

        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 12
        request.minimumConfidence = 0.5
        request.minimumAspectRatio = 0.1
        request.quadratureTolerance = 30

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation(from: image.imageOrientation))

        return await Task.detached(priority: .userInitiated) {
            do {
                try handler.perform([request])
            } catch {
                return []
            }
            guard let observations = request.results else { return [] }

            let quads = observations.map {
                DetectedQuad(
                    topLeft: $0.topLeft,
                    topRight: $0.topRight,
                    bottomLeft: $0.bottomLeft,
                    bottomRight: $0.bottomRight,
                    confidence: $0.confidence
                )
            }

            let imageAspect = CGFloat(cgImage.width) / CGFloat(cgImage.height)
            return quads
                .sorted { a, b in
                    let areaA = a.normalizedSize(imageAspect: imageAspect)
                    let areaB = b.normalizedSize(imageAspect: imageAspect)
                    return (areaA.width * areaA.height) > (areaB.width * areaB.height)
                }
                .prefix(maxResults)
                .map { $0 }
        }.value
    }

    /// Given a quad known to be the reference object (with real-world
    /// `referenceDimensions`) and a quad for the artwork, compute the
    /// artwork's real-world dimensions.
    static func measureArtwork(
        artworkQuad: DetectedQuad,
        referenceQuad: DetectedQuad,
        referenceDimensions: Dimensions,
        imageAspect: CGFloat
    ) -> Dimensions {
        let refSize = referenceQuad.normalizedSize(imageAspect: imageAspect)
        let artSize = artworkQuad.normalizedSize(imageAspect: imageAspect)

        // Reference object's long/short edge may map to either normalized
        // axis depending on how it was laid down — match by ratio rather
        // than assuming width = width.
        let refIsLandscape = refSize.width >= refSize.height
        let knownLong = max(referenceDimensions.widthMeters, referenceDimensions.heightMeters)
        let knownShort = min(referenceDimensions.widthMeters, referenceDimensions.heightMeters)

        let metersPerNormalizedUnitLong = knownLong / (refIsLandscape ? refSize.width : refSize.height)
        let metersPerNormalizedUnitShort = knownShort / (refIsLandscape ? refSize.height : refSize.width)
        let metersPerNormalizedUnit = (metersPerNormalizedUnitLong + metersPerNormalizedUnitShort) / 2

        return Dimensions(
            widthMeters: artSize.width * metersPerNormalizedUnit,
            heightMeters: artSize.height * metersPerNormalizedUnit
        )
    }

    private static func cgOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
