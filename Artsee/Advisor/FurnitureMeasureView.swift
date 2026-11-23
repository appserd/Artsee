import SwiftUI
import RealityKit
import ARKit

/// Measures furniture width with the camera instead of asking the user
/// to go find a tape measure — tap the floor at each end of the
/// furniture and this reports the real-world distance between the two
/// taps, the same raycasting this app already relies on elsewhere.
struct FurnitureMeasureView: View {
    var onMeasured: (Double) -> Void
    var onCancel: () -> Void

    @State private var hasFirstPoint = false
    @State private var resultMeters: Double?
    @State private var resetToken = UUID()

    var body: some View {
        ZStack {
            FurnitureMeasureARView(
                hasFirstPoint: $hasFirstPoint,
                resultMeters: $resultMeters,
                resetToken: resetToken
            )
            .ignoresSafeArea()

            VStack {
                Text(instructionText)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding()

                Spacer()

                if let resultMeters {
                    resultCard(meters: resultMeters)
                        .padding()
                }

                Button("Cancel") { onCancel() }
                    .buttonStyle(.bordered)
                    .padding(.bottom, 12)
            }
        }
    }

    private var instructionText: String {
        if resultMeters != nil { return "Got it!" }
        return hasFirstPoint
            ? "Now tap the floor at the other end of the furniture"
            : "Tap the floor at one end of the furniture, where it meets the wall area"
    }

    private func resultCard(meters: Double) -> some View {
        let dims = Dimensions(widthMeters: meters, heightMeters: 0)
        return VStack(spacing: 12) {
            Text("Measured width").font(.headline)
            Text(dims.formatted(in: .inches)).font(.title2.bold())
            Text(dims.formatted(in: .centimeters)).foregroundStyle(.secondary)
            HStack {
                Button("Retry") {
                    hasFirstPoint = false
                    resultMeters = nil
                    resetToken = UUID()
                }
                .buttonStyle(.bordered)

                Button("Use this") {
                    onMeasured(meters)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct FurnitureMeasureARView: UIViewRepresentable {
    @Binding var hasFirstPoint: Bool
    @Binding var resultMeters: Double?
    var resetToken: UUID

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        let coaching = ARCoachingOverlayView()
        coaching.session = arView.session
        coaching.goal = .horizontalPlane
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coaching.frame = arView.bounds
        arView.addSubview(coaching)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if context.coordinator.lastResetToken != resetToken {
            context.coordinator.lastResetToken = resetToken
            context.coordinator.reset()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    final class Coordinator: NSObject {
        private let parent: FurnitureMeasureARView
        weak var arView: ARView?
        var lastResetToken: UUID

        private var firstWorldPoint: SIMD3<Float>?
        private var markerAnchors: [AnchorEntity] = []

        init(_ parent: FurnitureMeasureARView) {
            self.parent = parent
            self.lastResetToken = parent.resetToken
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView else { return }
            let point = gesture.location(in: arView)
            guard let result = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .horizontal).first else { return }
            let worldPos = SIMD3<Float>(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
            placeMarker(at: worldPos)

            if let firstWorldPoint {
                let distance = simd_distance(firstWorldPoint, worldPos)
                parent.resultMeters = Double(distance)
            } else {
                firstWorldPoint = worldPos
                parent.hasFirstPoint = true
            }
        }

        func reset() {
            for anchor in markerAnchors {
                anchor.removeFromParent()
            }
            markerAnchors = []
            firstWorldPoint = nil
        }

        private func placeMarker(at position: SIMD3<Float>) {
            guard let arView else { return }
            let sphere = MeshResource.generateSphere(radius: 0.015)
            let marker = ModelEntity(mesh: sphere, materials: [SimpleMaterial(color: .systemBlue, isMetallic: false)])
            let anchor = AnchorEntity(world: position)
            anchor.addChild(marker)
            arView.scene.addAnchor(anchor)
            markerAnchors.append(anchor)
        }
    }
}

#Preview {
    FurnitureMeasureView(onMeasured: { _ in }, onCancel: {})
}
