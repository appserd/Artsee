import Foundation

/// Where one piece sits relative to the wall anchor's origin, in meters,
/// plus the size it's actually being shown at (may differ from the
/// artwork's true size if the user pinch-resized it).
struct PlacedPiece: Identifiable, Codable, Equatable {
    let id: UUID
    var artworkId: UUID
    var offsetXMeters: Double
    var offsetYMeters: Double
    var displayedDimensions: Dimensions

    init(
        id: UUID = UUID(),
        artworkId: UUID,
        offsetXMeters: Double = 0,
        offsetYMeters: Double = 0,
        displayedDimensions: Dimensions
    ) {
        self.id = id
        self.artworkId = artworkId
        self.offsetXMeters = offsetXMeters
        self.offsetYMeters = offsetYMeters
        self.displayedDimensions = displayedDimensions
    }
}

/// Exact spot on the wall to drive a nail, relative to the same wall
/// anchor origin as the pieces above.
struct NailSpot: Identifiable, Codable, Equatable {
    let id: UUID
    var pieceId: UUID
    var offsetXMeters: Double
    var offsetYMeters: Double
    var heightFromFloorMeters: Double?

    init(
        id: UUID = UUID(),
        pieceId: UUID,
        offsetXMeters: Double,
        offsetYMeters: Double,
        heightFromFloorMeters: Double? = nil
    ) {
        self.id = id
        self.pieceId = pieceId
        self.offsetXMeters = offsetXMeters
        self.offsetYMeters = offsetYMeters
        self.heightFromFloorMeters = heightFromFloorMeters
    }
}

enum PartnerVoteStatus: String, Codable {
    case notSent
    case sent
    case yes
    case no
}

enum BoardLayoutPreset: String, Codable, CaseIterable, Identifiable {
    case freeform
    case row
    case grid
    case salon

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .freeform: return "Freeform"
        case .row: return "Row"
        case .grid: return "Grid"
        case .salon: return "Salon"
        }
    }
}

/// One saved wall mockup: a single piece, or a gallery board of several,
/// everything needed to reopen it in AR and pick up where the user left off.
struct SavedMockup: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    /// File name of the snapshot photo taken in AR, if any.
    var snapshotFileName: String?
    var pieces: [PlacedPiece]
    var layoutPreset: BoardLayoutPreset
    var nailSpots: [NailSpot]
    var furnitureWidthMeters: Double?
    var partnerVoteStatus: PartnerVoteStatus
    var dateCreated: Date
    var dateUpdated: Date

    init(
        id: UUID = UUID(),
        name: String,
        snapshotFileName: String? = nil,
        pieces: [PlacedPiece],
        layoutPreset: BoardLayoutPreset = .freeform,
        nailSpots: [NailSpot] = [],
        furnitureWidthMeters: Double? = nil,
        partnerVoteStatus: PartnerVoteStatus = .notSent,
        dateCreated: Date = Date(),
        dateUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.snapshotFileName = snapshotFileName
        self.pieces = pieces
        self.layoutPreset = layoutPreset
        self.nailSpots = nailSpots
        self.furnitureWidthMeters = furnitureWidthMeters
        self.partnerVoteStatus = partnerVoteStatus
        self.dateCreated = dateCreated
        self.dateUpdated = dateUpdated
    }

    var isGalleryBoard: Bool { pieces.count > 1 }
}
