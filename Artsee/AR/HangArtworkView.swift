import SwiftUI

/// The AR hanging screen. Works for a single piece or a whole gallery
/// board — `pieces.count > 1` just means more entities on the same wall.
struct HangArtworkView: View {
    @EnvironmentObject private var store: PersistenceStore
    let pieces: [ArtworkPiece]
    var existingMockup: SavedMockup?
    var layoutPreset: BoardLayoutPreset = .freeform

    @State private var contents: [ARPieceContent] = []
    @State private var scaleFactors: [UUID: Double] = [:]
    @State private var nailSpots: [NailSpot] = []
    @State private var wallIsReady = false
    @State private var isNailMode = false
    @State private var furnitureWidthMeters: Double?
    @State private var showFurnitureInput = false
    @State private var mockupName: String
    @State private var lastSnapshot: UIImage?
    @State private var savedMockup: SavedMockup?
    @State private var showPartnerVote = false

    @StateObject private var snapshotRequest = ARWallContainerView.SnapshotRequest()

    init(pieces: [ArtworkPiece], existingMockup: SavedMockup? = nil, layoutPreset: BoardLayoutPreset = .freeform) {
        self.pieces = pieces
        self.existingMockup = existingMockup
        self.layoutPreset = layoutPreset
        _mockupName = State(initialValue: existingMockup?.name ?? (pieces.count > 1 ? "Gallery wall" : pieces.first?.title ?? "Wall mockup"))
    }

    var body: some View {
        ZStack {
            ARWallContainerView(
                pieces: $contents,
                isNailMode: $isNailMode,
                wallIsReady: $wallIsReady,
                onPlacementChanged: { update in
                    if let index = contents.firstIndex(where: { $0.id == update.pieceId }) {
                        contents[index].offsetXMeters = update.offsetXMeters
                        contents[index].offsetYMeters = update.offsetYMeters
                        scaleFactors[update.pieceId] = update.scaleFactor
                    }
                },
                onNailPlaced: { pieceId, x, y in
                    if let idx = nailSpots.firstIndex(where: { $0.pieceId == pieceId }) {
                        nailSpots[idx] = NailSpot(id: nailSpots[idx].id, pieceId: pieceId, offsetXMeters: x, offsetYMeters: y)
                    } else {
                        nailSpots.append(NailSpot(pieceId: pieceId, offsetXMeters: x, offsetYMeters: y))
                    }
                },
                requestSnapshot: snapshotRequest
            )
            .ignoresSafeArea()

            VStack {
                if !wallIsReady {
                    hintBanner
                }
                Spacer()
                HStack(alignment: .bottom) {
                    AdvisorBannerView(messages: advisorMessages, verdict: advisorVerdict)
                    Spacer()
                    if isNailMode {
                        LevelIndicatorView()
                    }
                }
                .padding()

                controlBar
            }
        }
        .onAppear(perform: setUpInitialContents)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                TextField("Name", text: $mockupName)
                    .multilineTextAlignment(.center)
            }
        }
        .sheet(isPresented: $showFurnitureInput) {
            FurnitureInputView { meters in
                furnitureWidthMeters = meters
            }
        }
        .sheet(isPresented: $showPartnerVote) {
            if let savedMockup {
                PartnerVoteView(mockup: savedMockup)
            }
        }
    }

    private var hintBanner: some View {
        Text("Point at your wall, wait for it to highlight, then tap to place your art.")
            .font(.footnote)
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding(.top, 8)
    }

    private var controlBar: some View {
        HStack(spacing: 16) {
            Button {
                showFurnitureInput = true
            } label: {
                Label(furnitureWidthMeters == nil ? "Set furniture" : "Furniture ✓", systemImage: "sofa")
            }

            Toggle(isOn: $isNailMode) {
                Label("Nail spot", systemImage: "pin")
            }
            .toggleStyle(.button)

            Spacer()

            Button {
                captureAndSave()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!wallIsReady)
        }
        .padding()
        .background(.thinMaterial)
    }

    private func setUpInitialContents() {
        guard contents.isEmpty else { return }

        if let existingMockup {
            contents = existingMockup.pieces.compactMap { placed in
                guard let artwork = store.artwork(id: placed.artworkId), let image = store.image(for: artwork) else { return nil }
                return ARPieceContent(
                    id: placed.id,
                    image: image,
                    dimensions: artwork.dimensions,
                    offsetXMeters: placed.offsetXMeters,
                    offsetYMeters: placed.offsetYMeters
                )
            }
            nailSpots = existingMockup.nailSpots
            furnitureWidthMeters = existingMockup.furnitureWidthMeters
            return
        }

        let positions = BoardLayoutEngine.layout(preset: layoutPreset, pieces: pieces.map(\.dimensions))
        contents = zip(pieces, positions).map { piece, offset in
            ARPieceContent(
                id: UUID(),
                image: store.image(for: piece) ?? UIImage(),
                dimensions: piece.dimensions,
                offsetXMeters: offset.x,
                offsetYMeters: offset.y
            )
        }
    }

    // MARK: - Advisor

    private var totalDisplayedWidthMeters: Double {
        contents.reduce(0) { total, content in
            let scale = scaleFactors[content.id] ?? 1
            return total + content.dimensions.widthMeters * scale
        }
    }

    private var advisorMessages: [String] {
        guard let furnitureWidthMeters, totalDisplayedWidthMeters > 0 else { return [] }
        let advice = SizeAdvisor.furnitureFitAdvice(artworkWidthMeters: totalDisplayedWidthMeters, furnitureWidthMeters: furnitureWidthMeters)
        return [advice.message]
    }

    private var advisorVerdict: SizeAdvisor.Verdict? {
        guard let furnitureWidthMeters, totalDisplayedWidthMeters > 0 else { return nil }
        return SizeAdvisor.furnitureFitAdvice(artworkWidthMeters: totalDisplayedWidthMeters, furnitureWidthMeters: furnitureWidthMeters).verdict
    }

    // MARK: - Saving

    private func captureAndSave() {
        snapshotRequest.capture { image in
            lastSnapshot = image
            save(with: image)
        }
    }

    private func save(with snapshot: UIImage?) {
        let placedPieces: [PlacedPiece] = zip(pieces, contents).map { artwork, content in
            let scale = scaleFactors[content.id] ?? 1
            return PlacedPiece(
                id: content.id,
                artworkId: artwork.id,
                offsetXMeters: content.offsetXMeters,
                offsetYMeters: content.offsetYMeters,
                displayedDimensions: Dimensions(
                    widthMeters: content.dimensions.widthMeters * scale,
                    heightMeters: content.dimensions.heightMeters * scale
                )
            )
        }

        var mockup = existingMockup ?? SavedMockup(name: mockupName, pieces: placedPieces, layoutPreset: layoutPreset)
        mockup.name = mockupName
        mockup.pieces = placedPieces
        mockup.nailSpots = nailSpots
        mockup.furnitureWidthMeters = furnitureWidthMeters

        let saved = store.saveMockup(mockup, snapshot: snapshot)
        savedMockup = saved
        showPartnerVote = true
    }
}
