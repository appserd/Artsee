import SwiftUI

/// Sizing method #2: lay a credit card or dollar bill flat next to the
/// art, in the same plane, fully in frame. The user outlines each one
/// by dragging four corner handles — Vision's auto-detection only seeds
/// a starting guess where it's confident, since trusting it to pick the
/// right rectangle out of a whole room is not reliable enough on its
/// own (confirmed live: it happily grabbed a shape drawn inside the
/// artwork instead of the artwork's own edge).
struct ReferenceSizingView: View {
    var onConfirm: (Dimensions, SizingMethod) -> Void

    private enum Stage {
        case chooseReference
        case detecting
        case outlineArtwork
        case outlineReference
        case confirmResult(Dimensions)
    }

    @State private var stage: Stage = .chooseReference
    @State private var referenceKind: ReferenceObjectKind = .creditCard
    @State private var capturedImage: UIImage?
    @State private var detectedQuads: [DetectedQuad] = []
    @State private var artworkQuad: DetectedQuad?
    @State private var showCamera = false

    var body: some View {
        content
            .navigationTitle("Measure with reference")
            // Full-screen cover, not a tab's regular content — the
            // camera needs the whole screen, not whatever's left after
            // the app's own tab bar and nav bar take their share.
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView(
                    onCaptured: { image in
                        showCamera = false
                        capturedImage = image
                        detectedQuads = []
                        artworkQuad = nil
                        stage = .detecting
                        Task {
                            detectedQuads = await RectangleMeasurement.detectQuads(in: image)
                            stage = .outlineArtwork
                        }
                    },
                    onCancel: { showCamera = false }
                )
                .ignoresSafeArea()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch stage {
        case .chooseReference:
            chooseReferenceView

        case .detecting:
            ProgressView("Looking for a starting outline…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .outlineArtwork:
            if let capturedImage {
                CornerDragQuadEditor(
                    image: capturedImage,
                    prompt: "Drag the four dots onto the corners of the artwork",
                    seedQuad: detectedQuads.first
                ) { quad in
                    artworkQuad = quad
                    stage = .outlineReference
                }
            }

        case .outlineReference:
            if let capturedImage {
                CornerDragQuadEditor(
                    image: capturedImage,
                    prompt: "Now drag the four dots onto the corners of the \(referenceKind.displayName.lowercased())",
                    seedQuad: detectedQuads.count > 1 ? detectedQuads[1] : nil
                ) { quad in
                    guard let artworkQuad else { return }
                    let aspect = capturedImage.size.width / capturedImage.size.height
                    let dims = RectangleMeasurement.measureArtwork(
                        artworkQuad: artworkQuad,
                        referenceQuad: quad,
                        referenceDimensions: referenceKind.dimensions,
                        imageAspect: aspect
                    )
                    stage = .confirmResult(dims)
                }
            }

        case .confirmResult(let dims):
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: isImplausiblySmall(dims) ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(isImplausiblySmall(dims) ? .orange : .green)
                    Text("Measured size")
                        .font(.headline)
                    Text(dims.formatted(in: .inches))
                        .font(.title2.bold())
                    Text(dims.formatted(in: .centimeters))
                        .foregroundStyle(.secondary)

                    if isImplausiblySmall(dims) {
                        Text("That's small for most artwork — double-check the outlines before saving.")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button("Use this size") {
                        onConfirm(dims, .referenceObject(referenceKind))
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Redo outlines (same photo)") {
                        artworkQuad = nil
                        stage = .outlineArtwork
                    }
                    Button("Retake photo") {
                        capturedImage = nil
                        detectedQuads = []
                        artworkQuad = nil
                        showCamera = true
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var chooseReferenceView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pick your reference object")
                    .font(.headline)
                ForEach(ReferenceObjectKind.allCases) { kind in
                    Button {
                        referenceKind = kind
                        showCamera = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(kind.displayName).font(.body.bold())
                                if kind == .creditCard {
                                    Text("Recommended")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(.tint, in: Capsule())
                                        .foregroundStyle(.white)
                                }
                            }
                            Text(kind.hint).font(.footnote).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(kind == .creditCard ? Color.accentColor : .clear, lineWidth: 2)
                        )
                    }
                    .foregroundStyle(.primary)
                }
                Text("Lay the art and the reference object flat, side by side, both fully visible in one photo.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    /// A rough sanity check — real artwork measured with this method is
    /// essentially never smaller than this on both edges. Catches a
    /// mis-drawn outline before it gets silently saved.
    private func isImplausiblySmall(_ dims: Dimensions) -> Bool {
        let minMeters = 3.0 * LengthUnit.inches.metersPerUnit
        return dims.widthMeters < minMeters && dims.heightMeters < minMeters
    }
}

#Preview {
    NavigationStack {
        ReferenceSizingView { _, _ in }
    }
}
