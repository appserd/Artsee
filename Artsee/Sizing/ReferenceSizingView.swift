import SwiftUI

/// Sizing method #2: lay a credit card or dollar bill flat next to the
/// art, in the same plane, fully in frame. We detect both rectangles in
/// one photo and scale the artwork from the reference's known size.
struct ReferenceSizingView: View {
    var onConfirm: (Dimensions, SizingMethod) -> Void

    private enum Stage {
        case chooseReference
        case detecting
        case pickArtworkQuad
        case pickReferenceQuad
        case confirmResult(Dimensions)
        case failed
    }

    @State private var stage: Stage = .chooseReference
    @State private var referenceKind: ReferenceObjectKind = .creditCard
    @State private var capturedImage: UIImage?
    @State private var quads: [DetectedQuad] = []
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
                        stage = .detecting
                        Task { await runDetection(on: image) }
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
            ProgressView("Finding edges…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .pickArtworkQuad:
            quadPicker(
                prompt: "Tap the artwork",
                onPick: { quad in
                    artworkQuad = quad
                    stage = .pickReferenceQuad
                }
            )

        case .pickReferenceQuad:
            quadPicker(
                prompt: "Now tap the \(referenceKind.displayName.lowercased())",
                onPick: { quad in
                    guard let image = capturedImage, let artworkQuad else { return }
                    let aspect = image.size.width / image.size.height
                    let dims = RectangleMeasurement.measureArtwork(
                        artworkQuad: artworkQuad,
                        referenceQuad: quad,
                        referenceDimensions: referenceKind.dimensions,
                        imageAspect: aspect
                    )
                    stage = .confirmResult(dims)
                }
            )

        case .confirmResult(let dims):
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Measured size")
                        .font(.headline)
                    Text(dims.formatted(in: .inches))
                        .font(.title2.bold())
                    Text(dims.formatted(in: .centimeters))
                        .foregroundStyle(.secondary)
                    Button("Use this size") {
                        onConfirm(dims, .referenceObject(referenceKind))
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Retake photo") {
                        capturedImage = nil
                        quads = []
                        artworkQuad = nil
                        showCamera = true
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }

        case .failed:
            ScrollView {
                VStack(spacing: 16) {
                    Text("Couldn't find two clear rectangles in that photo.")
                        .multilineTextAlignment(.center)
                    Text("Make sure both the art and the reference object are flat, fully in frame, and well lit.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try again") { showCamera = true }
                        .buttonStyle(.borderedProminent)
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

    private func quadPicker(prompt: String, onPick: @escaping (DetectedQuad) -> Void) -> some View {
        VStack(spacing: 12) {
            Text(prompt).font(.headline)
            if let capturedImage {
                GeometryReader { proxy in
                    ZStack {
                        Image(uiImage: capturedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: proxy.size.width, height: proxy.size.height)

                        ForEach(quads) { quad in
                            QuadOverlay(quad: quad, containerSize: proxy.size)
                                .onTapGesture { onPick(quad) }
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func runDetection(on image: UIImage) async {
        let found = await RectangleMeasurement.detectQuads(in: image)
        quads = found
        stage = found.count >= 2 ? .pickArtworkQuad : .failed
    }
}

/// Draws one detected quad as a tappable outline over the photo.
private struct QuadOverlay: View {
    let quad: DetectedQuad
    let containerSize: CGSize

    var body: some View {
        Path { path in
            func point(_ p: CGPoint) -> CGPoint {
                // Vision's origin is bottom-left; SwiftUI's is top-left.
                CGPoint(x: p.x * containerSize.width, y: (1 - p.y) * containerSize.height)
            }
            path.move(to: point(quad.topLeft))
            path.addLine(to: point(quad.topRight))
            path.addLine(to: point(quad.bottomRight))
            path.addLine(to: point(quad.bottomLeft))
            path.closeSubpath()
        }
        .stroke(Color.yellow, lineWidth: 3)
        .contentShape(
            Path { path in
                func point(_ p: CGPoint) -> CGPoint {
                    CGPoint(x: p.x * containerSize.width, y: (1 - p.y) * containerSize.height)
                }
                path.move(to: point(quad.topLeft))
                path.addLine(to: point(quad.topRight))
                path.addLine(to: point(quad.bottomRight))
                path.addLine(to: point(quad.bottomLeft))
                path.closeSubpath()
            }
        )
    }
}

#Preview {
    NavigationStack {
        ReferenceSizingView { _, _ in }
    }
}
