import Foundation

/// Equal-spacing math for gallery walls. The hard part of a multi-piece
/// wall is getting the gaps even — this computes true-size layouts so
/// the user doesn't have to eyeball it.
enum BoardLayoutEngine {
    static let defaultGapMeters = 0.05 // ~2 in between pieces

    static func layout(preset: BoardLayoutPreset, pieces: [Dimensions]) -> [(x: Double, y: Double)] {
        guard !pieces.isEmpty else { return [] }
        switch preset {
        case .freeform, .row:
            return rowLayout(pieces: pieces)
        case .grid:
            return gridLayout(pieces: pieces)
        case .salon:
            return salonLayout(pieces: pieces)
        }
    }

    private static func rowLayout(pieces: [Dimensions]) -> [(x: Double, y: Double)] {
        let totalWidth = pieces.reduce(0) { $0 + $1.widthMeters } + defaultGapMeters * Double(max(0, pieces.count - 1))
        var cursor = -totalWidth / 2
        var positions: [(x: Double, y: Double)] = []
        for dims in pieces {
            let center = cursor + dims.widthMeters / 2
            positions.append((x: center, y: 0))
            cursor += dims.widthMeters + defaultGapMeters
        }
        return positions
    }

    private static func gridLayout(pieces: [Dimensions]) -> [(x: Double, y: Double)] {
        let columns = max(1, Int(ceil(sqrt(Double(pieces.count)))))
        let rows = Int(ceil(Double(pieces.count) / Double(columns)))

        var colWidths = [Double](repeating: 0, count: columns)
        var rowHeights = [Double](repeating: 0, count: rows)
        for (i, dims) in pieces.enumerated() {
            let col = i % columns
            let row = i / columns
            colWidths[col] = max(colWidths[col], dims.widthMeters)
            rowHeights[row] = max(rowHeights[row], dims.heightMeters)
        }

        let totalWidth = colWidths.reduce(0, +) + defaultGapMeters * Double(max(0, columns - 1))
        let totalHeight = rowHeights.reduce(0, +) + defaultGapMeters * Double(max(0, rows - 1))

        var colCenterX = [Double](repeating: 0, count: columns)
        var cursor = -totalWidth / 2
        for c in 0..<columns {
            colCenterX[c] = cursor + colWidths[c] / 2
            cursor += colWidths[c] + defaultGapMeters
        }

        var rowCenterY = [Double](repeating: 0, count: rows)
        cursor = totalHeight / 2
        for r in 0..<rows {
            rowCenterY[r] = cursor - rowHeights[r] / 2
            cursor -= rowHeights[r] + defaultGapMeters
        }

        return pieces.indices.map { i in
            (x: colCenterX[i % columns], y: rowCenterY[i / columns])
        }
    }

    /// Salon-style: starts from the even grid, then applies a small,
    /// deterministic stagger so it reads as "curated" rather than rigid —
    /// still evenly spaced on average, just not a strict row/grid.
    private static func salonLayout(pieces: [Dimensions]) -> [(x: Double, y: Double)] {
        gridLayout(pieces: pieces).enumerated().map { i, position in
            let jitterX = (i % 2 == 0 ? 1.0 : -1.0) * 0.03
            let jitterY = Double((i % 3) - 1) * 0.02
            return (x: position.x + jitterX, y: position.y + jitterY)
        }
    }
}
