import Foundation

/// How an artwork's real-world size was determined.
enum SizingMethod: Codable, Equatable {
    case manualEntry
    case commonSize(String)
    case referenceObject(ReferenceObjectKind)
}

/// A single piece of art the user has added to their library.
struct ArtworkPiece: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    /// File name of the (already straightened/cropped) image, relative to
    /// the artwork images directory managed by PersistenceStore.
    var imageFileName: String
    var dimensions: Dimensions
    var sizingMethod: SizingMethod
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        title: String,
        imageFileName: String,
        dimensions: Dimensions,
        sizingMethod: SizingMethod,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.imageFileName = imageFileName
        self.dimensions = dimensions
        self.sizingMethod = sizingMethod
        self.dateAdded = dateAdded
    }
}
