import SwiftUI
import Combine

/// Everything on-device: no account, no network, no backend. Artwork
/// images and AR snapshots are written as JPEGs in the app's Documents
/// directory; the catalog data (pieces, mockups) is a pair of JSON files
/// next to them. Good enough for a free, offline-first v1.
@MainActor
final class PersistenceStore: ObservableObject {
    @Published private(set) var artworkPieces: [ArtworkPiece] = []
    @Published private(set) var mockups: [SavedMockup] = []

    private let fileManager = FileManager.default

    private lazy var documentsURL: URL = {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    private lazy var artworkImagesURL: URL = {
        let url = documentsURL.appendingPathComponent("ArtworkImages", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    private lazy var snapshotsURL: URL = {
        let url = documentsURL.appendingPathComponent("Snapshots", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    private var piecesIndexURL: URL { documentsURL.appendingPathComponent("artwork_pieces.json") }
    private var mockupsIndexURL: URL { documentsURL.appendingPathComponent("mockups.json") }

    init() {
        load()
    }

    // MARK: - Loading / saving the index files

    private func load() {
        artworkPieces = decode([ArtworkPiece].self, from: piecesIndexURL) ?? []
        mockups = decode([SavedMockup].self, from: mockupsIndexURL) ?? []
    }

    private func decode<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }

    private func persistPieces() {
        encode(artworkPieces, to: piecesIndexURL)
    }

    private func persistMockups() {
        encode(mockups, to: mockupsIndexURL)
    }

    private func encode<T: Encodable>(_ value: T, to url: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        if let data = try? encoder.encode(value) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: - Artwork pieces

    @discardableResult
    func addArtwork(image: UIImage, title: String, dimensions: Dimensions, sizingMethod: SizingMethod) -> ArtworkPiece {
        let fileName = "\(UUID().uuidString).jpg"
        writeJPEG(image, to: artworkImagesURL.appendingPathComponent(fileName))

        let piece = ArtworkPiece(
            title: title,
            imageFileName: fileName,
            dimensions: dimensions,
            sizingMethod: sizingMethod
        )
        artworkPieces.append(piece)
        persistPieces()
        return piece
    }

    func image(for piece: ArtworkPiece) -> UIImage? {
        UIImage(contentsOfFile: artworkImagesURL.appendingPathComponent(piece.imageFileName).path)
    }

    func artwork(id: UUID) -> ArtworkPiece? {
        artworkPieces.first { $0.id == id }
    }

    func deleteArtwork(_ piece: ArtworkPiece) {
        try? fileManager.removeItem(at: artworkImagesURL.appendingPathComponent(piece.imageFileName))
        artworkPieces.removeAll { $0.id == piece.id }
        persistPieces()
    }

    // MARK: - Mockups

    @discardableResult
    func saveMockup(_ mockup: SavedMockup, snapshot: UIImage? = nil) -> SavedMockup {
        var mockup = mockup
        if let snapshot {
            let fileName = mockup.snapshotFileName ?? "\(UUID().uuidString).jpg"
            writeJPEG(snapshot, to: snapshotsURL.appendingPathComponent(fileName))
            mockup.snapshotFileName = fileName
        }
        mockup.dateUpdated = Date()

        if let index = mockups.firstIndex(where: { $0.id == mockup.id }) {
            mockups[index] = mockup
        } else {
            mockups.append(mockup)
        }
        persistMockups()
        return mockup
    }

    func snapshotImage(for mockup: SavedMockup) -> UIImage? {
        guard let fileName = mockup.snapshotFileName else { return nil }
        return UIImage(contentsOfFile: snapshotsURL.appendingPathComponent(fileName).path)
    }

    func deleteMockup(_ mockup: SavedMockup) {
        if let fileName = mockup.snapshotFileName {
            try? fileManager.removeItem(at: snapshotsURL.appendingPathComponent(fileName))
        }
        mockups.removeAll { $0.id == mockup.id }
        persistMockups()
    }

    // MARK: - Helpers

    private func writeJPEG(_ image: UIImage, to url: URL, quality: CGFloat = 0.9) {
        if let data = image.jpegData(compressionQuality: quality) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
