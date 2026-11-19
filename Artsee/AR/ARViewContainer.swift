import SwiftUI
import RealityKit
import ARKit
import Combine

/// One piece of art as rendered content: what to show and how big to
/// show it. The container turns these into real, true-size RealityKit
/// entities once a wall is found.
struct ARPieceContent: Identifiable {
    let id: UUID // matches PlacedPiece.id
    let image: UIImage
    var dimensions: Dimensions
    var offsetXMeters: Double
    var offsetYMeters: Double
}

/// Fed back out to SwiftUI whenever something the advisor or persistence
/// layer cares about changes.
struct ARPlacementUpdate {
    var pieceId: UUID
    var offsetXMeters: Double
    var offsetYMeters: Double
    /// Uniform scale applied on top of the piece's true-size mesh — the
    /// caller owns the base `Dimensions` and multiplies by this to get
    /// the displayed size after a pinch-resize. 1.0 means unchanged.
    var scaleFactor: Double
}

struct ARWallContainerView: UIViewRepresentable {
    @Binding var pieces: [ARPieceContent]
    @Binding var isNailMode: Bool
    @Binding var wallIsReady: Bool

    var onPlacementChanged: (ARPlacementUpdate) -> Void
    var onNailPlaced: (UUID, Double, Double) -> Void
    var requestSnapshot: SnapshotRequest

    final class SnapshotRequest: ObservableObject {
        var handler: (@escaping (UIImage?) -> Void) -> Void = { $0(nil) }
        func capture(completion: @escaping (UIImage?) -> Void) {
            handler(completion)
        }
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.vertical]
        arView.session.run(config)
        arView.session.delegate = context.coordinator

        let coaching = ARCoachingOverlayView()
        coaching.session = arView.session
        coaching.goal = .verticalPlane
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coaching.frame = arView.bounds
        arView.addSubview(coaching)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinch)

        requestSnapshot.handler = { completion in
            arView.snapshot(saveToHDR: false) { image in
                completion(image)
            }
        }

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        context.coordinator.isNailMode = isNailMode
        context.coordinator.syncPieces(pieces)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    final class Coordinator: NSObject, ARSessionDelegate {
        private let parent: ARWallContainerView
        weak var arView: ARView?

        var wallAnchor: AnchorEntity?
        private var pieceEntities: [UUID: ModelEntity] = [:]
        private var knownPieceIds: Set<UUID> = []
        private var activeDragEntity: ModelEntity?
        private var activePinchEntity: ModelEntity?
        private var pinchStartScale: Float = 1

        var isNailMode = false

        init(_ parent: ARWallContainerView) {
            self.parent = parent
        }

        // MARK: - Wall + piece sync

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView else { return }
            let point = gesture.location(in: arView)

            if wallAnchor == nil {
                guard let result = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .vertical).first else { return }
                placeWall(at: result)
                return
            }

            if isNailMode {
                guard let wallAnchor,
                      let result = arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .vertical).first else { return }
                let worldPos = SIMD3<Float>(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
                let localPos = wallAnchor.convert(position: worldPos, from: nil)
                placeNailMarker(at: localPos)
                if let entity = arView.entity(at: point) as? ModelEntity, let pieceId = pieceEntities.first(where: { $0.value === entity })?.key {
                    parent.onNailPlaced(pieceId, Double(localPos.x), Double(localPos.y))
                } else if let nearest = pieceEntities.min(by: { lhs, rhs in
                    distance2D(lhs.value.position, localPos) < distance2D(rhs.value.position, localPos)
                }) {
                    parent.onNailPlaced(nearest.key, Double(localPos.x), Double(localPos.y))
                }
            }
        }

        private func distance2D(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
            let dx = a.x - b.x
            let dy = a.y - b.y
            return sqrt(dx * dx + dy * dy)
        }

        private func placeWall(at result: ARRaycastResult) {
            guard let arView else { return }
            let hitTransform = result.worldTransform
            let position = SIMD3<Float>(hitTransform.columns.3.x, hitTransform.columns.3.y, hitTransform.columns.3.z)

            // ARKit's convention puts the surface normal along the
            // transform's Y column for both horizontal and vertical hits.
            // Rebuild our own basis so local X/Y on the anchor map to
            // "along the wall, left-right / up-down" regardless of that.
            let normal = simd_normalize(SIMD3<Float>(hitTransform.columns.1.x, hitTransform.columns.1.y, hitTransform.columns.1.z))
            let worldUp = SIMD3<Float>(0, 1, 0)
            var up = worldUp - normal * simd_dot(worldUp, normal)
            if simd_length(up) < 0.001 {
                up = SIMD3<Float>(0, 0, 1)
            }
            up = simd_normalize(up)
            let right = simd_normalize(simd_cross(up, normal))

            var transform = matrix_identity_float4x4
            transform.columns.0 = SIMD4<Float>(right, 0)
            transform.columns.1 = SIMD4<Float>(up, 0)
            transform.columns.2 = SIMD4<Float>(normal, 0)
            transform.columns.3 = SIMD4<Float>(position, 1)

            let anchor = AnchorEntity(world: transform)
            arView.scene.addAnchor(anchor)
            wallAnchor = anchor
            parent.wallIsReady = true
        }

        func syncPieces(_ pieces: [ARPieceContent]) {
            guard let wallAnchor else { return }

            for content in pieces where !knownPieceIds.contains(content.id) {
                knownPieceIds.insert(content.id)
                addPiece(content, to: wallAnchor)
            }

            for content in pieces {
                guard let entity = pieceEntities[content.id], activeDragEntity !== entity, activePinchEntity !== entity else { continue }
                entity.position = SIMD3<Float>(Float(content.offsetXMeters), Float(content.offsetYMeters), 0.002)
            }

            let currentIds = Set(pieces.map(\.id))
            for staleId in knownPieceIds.subtracting(currentIds) {
                pieceEntities[staleId]?.removeFromParent()
                pieceEntities[staleId] = nil
                knownPieceIds.remove(staleId)
            }
        }

        private func addPiece(_ content: ARPieceContent, to anchor: AnchorEntity) {
            let mesh = MeshResource.generatePlane(width: Float(content.dimensions.widthMeters), height: Float(content.dimensions.heightMeters))
            let placeholder = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: .white, isMetallic: false)])
            placeholder.position = SIMD3<Float>(Float(content.offsetXMeters), Float(content.offsetYMeters), 0.002)
            placeholder.generateCollisionShapes(recursive: true)
            placeholder.name = content.id.uuidString
            anchor.addChild(placeholder)
            pieceEntities[content.id] = placeholder

            guard let cgImage = content.image.cgImage else { return }
            Task.detached(priority: .userInitiated) { [weak self] in
                guard let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .color)) else { return }
                await MainActor.run {
                    guard let self, let entity = self.pieceEntities[content.id] else { return }
                    var material = UnlitMaterial()
                    material.color = .init(texture: .init(texture))
                    entity.model?.materials = [material]
                }
            }
        }

        // MARK: - Drag to move / pinch to resize

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView, let wallAnchor else { return }
            let point = gesture.location(in: arView)

            switch gesture.state {
            case .began:
                guard let entity = arView.entity(at: point) as? ModelEntity, pieceEntities.values.contains(where: { $0 === entity }) else { return }
                activeDragEntity = entity

            case .changed:
                guard let entity = activeDragEntity else { return }
                guard let result = arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .vertical).first else { return }
                let worldPos = SIMD3<Float>(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
                let localPos = wallAnchor.convert(position: worldPos, from: nil)
                entity.position = SIMD3<Float>(localPos.x, localPos.y, 0.002)

            case .ended, .cancelled, .failed:
                if let entity = activeDragEntity, let pieceId = pieceEntities.first(where: { $0.value === entity })?.key {
                    reportPlacement(pieceId: pieceId, entity: entity)
                }
                activeDragEntity = nil

            default:
                break
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let arView else { return }
            let point = gesture.location(in: arView)

            switch gesture.state {
            case .began:
                guard let entity = arView.entity(at: point) as? ModelEntity, pieceEntities.values.contains(where: { $0 === entity }) else { return }
                activePinchEntity = entity
                pinchStartScale = entity.scale.x

            case .changed:
                guard let entity = activePinchEntity else { return }
                let newScale = max(0.2, min(4.0, pinchStartScale * Float(gesture.scale)))
                entity.scale = SIMD3<Float>(repeating: newScale)

            case .ended, .cancelled, .failed:
                if let entity = activePinchEntity, let pieceId = pieceEntities.first(where: { $0.value === entity })?.key {
                    reportPlacement(pieceId: pieceId, entity: entity)
                }
                activePinchEntity = nil

            default:
                break
            }
        }

        /// Reports the entity's new position plus its current uniform
        /// scale factor (not an absolute size) — the caller owns each
        /// piece's true-size `Dimensions` and multiplies by this factor
        /// to get the displayed size after a pinch-resize.
        private func reportPlacement(pieceId: UUID, entity: ModelEntity) {
            parent.onPlacementChanged(
                ARPlacementUpdate(
                    pieceId: pieceId,
                    offsetXMeters: Double(entity.position.x),
                    offsetYMeters: Double(entity.position.y),
                    scaleFactor: Double(entity.scale.x)
                )
            )
        }

        // MARK: - Nail marker

        private var nailEntity: ModelEntity?

        private func placeNailMarker(at localPosition: SIMD3<Float>) {
            guard let wallAnchor else { return }
            nailEntity?.removeFromParent()
            let sphere = MeshResource.generateSphere(radius: 0.006)
            let marker = ModelEntity(mesh: sphere, materials: [SimpleMaterial(color: .systemRed, isMetallic: false)])
            marker.position = SIMD3<Float>(localPosition.x, localPosition.y, 0.004)
            wallAnchor.addChild(marker)
            nailEntity = marker
        }

        // MARK: - ARSessionDelegate

        nonisolated func session(_ session: ARSession, didFailWithError error: Error) {}
    }
}
