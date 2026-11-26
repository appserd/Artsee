import SwiftUI

/// The AR hanging screen. Works for a single piece or a whole gallery
/// board — `pieces.count > 1` just means more entities on the same wall.
struct HangArtworkView: View {
    @EnvironmentObject private var store: PersistenceStore
    @AppStorage("furnitureAdvisorEnabled") private var furnitureAdvisorEnabled = true
    let pieces: [ArtworkPiece]
    var existingMockup: SavedMockup?
    var layoutPreset: BoardLayoutPreset = .freeform

    @State private var contents: [ARPieceContent] = []
    @State private var scaleFactors: [UUID: Double] = [:]
    @State private var nailSpots: [NailSpot] = []
    @State private var wallIsReady = false
    @State private var wallIsApproximate = false
    @State private var showNailInput = false
    @State private var furnitureWidthMeters: Double?
    @State private var showFurnitureInput = false
    @State private var mockupName: String
    @State private var lastSnapshot: UIImage?
    @State private var savedMockup: SavedMockup?
    @State private var showPartnerVote = false
    @State private var liveResizeDimensions: Dimensions?

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
                nailSpots: $nailSpots,
                wallIsReady: $wallIsReady,
                wallIsApproximate: $wallIsApproximate,
                onPlacementChanged: { update in
                    if let index = contents.firstIndex(where: { $0.id == update.pieceId }) {
                        contents[index].offsetXMeters = update.offsetXMeters
                        contents[index].offsetYMeters = update.offsetYMeters
                        scaleFactors[update.pieceId] = update.scaleFactor
                    }
                },
                onPinchChanging: { pieceId, scale in
                    if let content = contents.first(where: { $0.id == pieceId }) {
                        liveResizeDimensions = Dimensions(
                            widthMeters: content.dimensions.widthMeters * scale,
                            heightMeters: content.dimensions.heightMeters * scale
                        )
                    }
                },
                onPinchEnded: {
                    liveResizeDimensions = nil
                },
                requestSnapshot: snapshotRequest
            )
            .ignoresSafeArea()

            if !wallIsReady {
                centerReticle
            }

            if let liveResizeDimensions {
                resizeReadout(liveResizeDimensions)
            }

            VStack {
                if !wallIsReady {
                    hintBanner
                } else if wallIsApproximate {
                    approximateWallBanner
                }
                Spacer()
                HStack(alignment: .bottom) {
                    if furnitureAdvisorEnabled {
                        AdvisorBannerView(advice: furnitureAdvice)
                    }
                    Spacer()
                    if !nailSpots.isEmpty {
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
        .sheet(isPresented: $showNailInput) {
            NailPlacementInputView { result in
                applyNailPlacement(result)
            }
        }
        .sheet(isPresented: $showPartnerVote) {
            if let savedMockup {
                PartnerVoteView(mockup: savedMockup)
            }
        }
    }

    /// A plain crosshair at screen center — "tap here, on your wall" is
    /// a much clearer instruction than the spot anywhere, and gives the
    /// user a concrete target instead of guessing.
    private var centerReticle: some View {
        Image(systemName: "plus")
            .font(.system(size: 28, weight: .light))
            .foregroundStyle(.white)
            .shadow(radius: 3)
    }

    private func resizeReadout(_ dims: Dimensions) -> some View {
        Text(dims.formatted(in: .inches))
            .font(.headline.monospacedDigit())
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.75), in: Capsule())
            .foregroundStyle(.white)
    }

    private var hintBanner: some View {
        Text("Slowly move your phone side to side, pointing at the wall where you want to hang this. Once it stops moving, tap the + at the center of the screen on your wall.")
            .font(.footnote)
            .multilineTextAlignment(.center)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
            .padding(.top, 8)
    }

    private var approximateWallBanner: some View {
        Text("This wall had too little detail for AR to measure precisely, so the distance is approximate — true-size accuracy may be slightly off.")
            .font(.footnote)
            .multilineTextAlignment(.center)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(.orange.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.top, 8)
    }

    private var controlBar: some View {
        HStack(spacing: 8) {
            if furnitureAdvisorEnabled {
                Button {
                    showFurnitureInput = true
                } label: {
                    Label(furnitureWidthMeters == nil ? "Furniture" : "Furniture ✓", systemImage: "sofa")
                        .lineLimit(1)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Button {
                showNailInput = true
            } label: {
                Label(nailSpots.isEmpty ? "Nail" : "Nail ✓", systemImage: "pin")
                    .lineLimit(1)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(contents.isEmpty)

            Spacer(minLength: 4)

            Button {
                captureAndSave()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
                    .lineLimit(1)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(!wallIsReady)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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

    // MARK: - Nail spot

    /// Computes the nail spot(s) directly from the first piece's
    /// already-known true-size position and dimensions — not tapped,
    /// since a tap has no way to know where the hardware on the back
    /// of the frame actually sits relative to the top of it.
    private func applyNailPlacement(_ result: NailPlacementResult) {
        guard let content = contents.first else { return }
        let scale = scaleFactors[content.id] ?? 1
        nailSpots = NailSpotCalculator.compute(
            pieceId: content.id,
            pieceCenterXMeters: content.offsetXMeters,
            pieceCenterYMeters: content.offsetYMeters,
            pieceDisplayedHeightMeters: content.dimensions.heightMeters * scale,
            result: result
        )
    }

    // MARK: - Advisor

    private var totalDisplayedWidthMeters: Double {
        contents.reduce(0) { total, content in
            let scale = scaleFactors[content.id] ?? 1
            return total + content.dimensions.widthMeters * scale
        }
    }

    private var furnitureAdvice: SizeAdvisor.FurnitureAdvice? {
        guard let furnitureWidthMeters, totalDisplayedWidthMeters > 0 else { return nil }
        return SizeAdvisor.furnitureFitAdvice(artworkWidthMeters: totalDisplayedWidthMeters, furnitureWidthMeters: furnitureWidthMeters)
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
