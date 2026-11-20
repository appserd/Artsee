import SwiftUI

/// Lets the user directly drag four corner handles onto an object in a
/// photo — used for both the artwork and the reference object in turn.
/// Vision's auto-detection is unreliable on a real wall photo (it tends
/// to pick up whatever has the strongest edges in the whole frame, not
/// necessarily the object we care about), so this is the source of
/// truth: an optional detected quad only seeds the starting position.
struct CornerDragQuadEditor: View {
    let image: UIImage
    let prompt: String
    var seedQuad: DetectedQuad?
    var onConfirm: (DetectedQuad) -> Void

    /// Screen-space corner positions, in reading order: topLeft,
    /// topRight, bottomRight, bottomLeft.
    @State private var corners: [CGPoint] = []
    @State private var fittedRect: CGRect = .zero
    @State private var draggingIndex: Int?

    var body: some View {
        VStack(spacing: 12) {
            Text(prompt)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            GeometryReader { proxy in
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width, height: proxy.size.height)

                    if corners.count == 4 {
                        quadOutline
                        ForEach(0..<4, id: \.self) { index in
                            handle(at: index)
                        }
                    }
                }
                .onAppear {
                    fittedRect = Self.aspectFitRect(imageSize: image.size, in: proxy.size)
                    corners = Self.initialCorners(seedQuad: seedQuad, fittedRect: fittedRect)
                }
            }

            Button("Use this outline") {
                onConfirm(currentQuad())
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
    }

    private var quadOutline: some View {
        Path { path in
            guard corners.count == 4 else { return }
            path.move(to: corners[0])
            path.addLine(to: corners[1])
            path.addLine(to: corners[2])
            path.addLine(to: corners[3])
            path.closeSubpath()
        }
        .stroke(Color.yellow, lineWidth: 3)
    }

    private func handle(at index: Int) -> some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 28, height: 28)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .position(corners[index])
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        draggingIndex = index
                        var point = value.location
                        point.x = min(max(point.x, fittedRect.minX), fittedRect.maxX)
                        point.y = min(max(point.y, fittedRect.minY), fittedRect.maxY)
                        corners[index] = point
                    }
                    .onEnded { _ in draggingIndex = nil }
            )
    }

    /// Converts the current screen-space corners into Vision-style
    /// normalized coordinates (0...1, origin bottom-left) relative to
    /// the photo itself — ignoring any aspect-fit letterboxing.
    private func currentQuad() -> DetectedQuad {
        func normalized(_ p: CGPoint) -> CGPoint {
            guard fittedRect.width > 0, fittedRect.height > 0 else { return .zero }
            let x = (p.x - fittedRect.minX) / fittedRect.width
            let y = 1 - (p.y - fittedRect.minY) / fittedRect.height
            return CGPoint(x: min(max(x, 0), 1), y: min(max(y, 0), 1))
        }
        return DetectedQuad(
            topLeft: normalized(corners[0]),
            topRight: normalized(corners[1]),
            bottomLeft: normalized(corners[3]),
            bottomRight: normalized(corners[2]),
            confidence: 1
        )
    }

    private static func aspectFitRect(imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        var fitSize = containerSize
        if imageAspect > containerAspect {
            fitSize.height = containerSize.width / imageAspect
        } else {
            fitSize.width = containerSize.height * imageAspect
        }
        let origin = CGPoint(x: (containerSize.width - fitSize.width) / 2, y: (containerSize.height - fitSize.height) / 2)
        return CGRect(origin: origin, size: fitSize)
    }

    /// Seeds from a detected quad when we have one (saves some dragging),
    /// otherwise falls back to a generic inset rectangle the user drags
    /// into place from scratch. Either way, nothing here is ever "final"
    /// until the user confirms it.
    private static func initialCorners(seedQuad: DetectedQuad?, fittedRect: CGRect) -> [CGPoint] {
        func screenPoint(_ normalized: CGPoint) -> CGPoint {
            CGPoint(
                x: fittedRect.minX + normalized.x * fittedRect.width,
                y: fittedRect.minY + (1 - normalized.y) * fittedRect.height
            )
        }
        if let seedQuad {
            return [
                screenPoint(seedQuad.topLeft),
                screenPoint(seedQuad.topRight),
                screenPoint(seedQuad.bottomRight),
                screenPoint(seedQuad.bottomLeft),
            ]
        }
        let inset = 0.18
        return [
            CGPoint(x: fittedRect.minX + fittedRect.width * inset, y: fittedRect.minY + fittedRect.height * inset),
            CGPoint(x: fittedRect.maxX - fittedRect.width * inset, y: fittedRect.minY + fittedRect.height * inset),
            CGPoint(x: fittedRect.maxX - fittedRect.width * inset, y: fittedRect.maxY - fittedRect.height * inset),
            CGPoint(x: fittedRect.minX + fittedRect.width * inset, y: fittedRect.maxY - fittedRect.height * inset),
        ]
    }
}
