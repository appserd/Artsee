# Artsee

See a piece of art on your own wall, at its true size, before buying or hanging it — then actually hang it. iOS-only, SwiftUI + ARKit/RealityKit, no account, no backend, everything on-device.

This project was written without access to Xcode or an iOS device (built from a Linux container), so it has **not been compiled or run yet**. It's structured to open cleanly in Xcode on a Mac — see below for the first-build checklist.

## Opening the project

The `.xcodeproj` isn't checked in — it's generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen), which keeps the project file from rotting out of sync with the folder structure.

```bash
brew install xcodegen
cd Artsee
xcodegen generate
open Artsee.xcodeproj
```

In Xcode:
1. Select the `Artsee` target → **Signing & Capabilities** → set your team (Development Team is blank in `project.yml` on purpose).
2. Build & run on a **real iPhone** — ARKit wall detection, the camera, and the document scanner all need real hardware; the Simulator can't do plane detection.
3. Bundle ID is `com.appserd.artsee`. Change it in `project.yml` (`PRODUCT_BUNDLE_IDENTIFIER`) if needed, then re-run `xcodegen generate`.

## What's implemented

| Area | Files |
|---|---|
| Capture (scan / import) | `Artsee/Capture/` — `DocumentScannerView` (VisionKit edge detection), `CameraCaptureView`, `AddArtworkFlowView` |
| Sizing | `Artsee/Sizing/` — manual entry + common sizes, and reference-object measurement via `Vision`'s rectangle detector (`RectangleMeasurement.swift`) |
| AR hanging | `Artsee/AR/` — `ARViewContainer` (RealityKit, vertical plane detection, true-size placement, drag/pinch), `HangArtworkView`, `LevelIndicatorView` |
| Size advisor | `Artsee/Advisor/` — two-thirds-of-furniture-width rule, 57in eye-level rule |
| Gallery wall board | `Artsee/GalleryBoard/` — multi-piece picker + `BoardLayoutEngine` (row / grid / salon, equal spacing) |
| Partner vote | `Artsee/PartnerVote/` — `ShareLink` out, manual yes/no logging back (no backend, no account on either side) |
| Nail + level | Folded into the AR screen: nail-mode tap marks a spot on the wall anchor; `LevelIndicatorView` is a CoreMotion bubble level for driving the nail in straight |
| Persistence | `Artsee/Persistence/PersistenceStore.swift` — JSON + JPEGs in the app's Documents directory, no network |

## Known rough edges to check on first build

Things that are very likely correct in principle but need a real device + Xcode's type-checker to confirm, since nothing here has compiled yet:

- **RealityKit APIs**: `TextureResource.generate(from:options:)`, `MeshResource.generatePlane`, `UnlitMaterial.color(texture:)` — signatures can drift slightly between SDK versions; fix to match whatever Xcode's autocomplete expects.
- **Wall-anchor basis vectors** in `ARViewContainer.placeWall`: built manually from the raycast normal so "drag" maps to left/right and up/down on the wall regardless of ARKit's raw transform convention. Worth double-checking signs feel right on device (drag right → art moves right).
- **`arView.entity(at:)`** hit-testing for pan/pinch — confirm it only picks up our artwork entities, not coaching-overlay internals.

## Proof tests (run on a real iPhone)

1. **Scan**: Add Art → Scan a real piece → confirm edges are detected and the result is a flat, unwarped rectangle (`DocumentScannerView`).
2. **Credit-card sizing**: Add Art → Reference object → credit card → place a 16×20 print on a wall → verify against a tape measure (`ReferenceSizingView` → `RectangleMeasurement`).
3. **Manual sizing**: same check via `ManualSizeEntryView`.
4. **Gallery board**: pick 4 pieces → Grid or Salon layout → confirm gaps are visibly equal on the wall (`BoardLayoutEngine`).
5. **Advisor**: a small print over a wide "furniture width" entry should show "too small"; a correctly sized one shouldn't nag (`SizeAdvisor`).
6. **Nail spot**: toggle Nail mode, tap the wall, confirm the marker lines up with where the piece actually hangs.
7. **Offline**: airplane mode on, confirm every flow above still works (importing from a website is the one exception called out in the spec, and isn't built in v1 anyway).

## Not in v1 (by design)

No accounts, no sign-in, no backend, no store/catalog, no payments, no Android, no auto-sizing from a scan alone.
