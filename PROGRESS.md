# Progress

## Where we are
Full v1 Swift/SwiftUI app, building successfully on a real iPhone (iPhone 16e, Mac mini's `appserd inc` developer team). Pushed to `github.com/appserd/Artsee`, `main` branch.

Live-tested so far by Oren: scanning a real piece (VisionKit) works well. Sizing by manual/common size works. Reference-object sizing was rewritten from tap-to-pick-a-detected-rectangle to drag-four-corners-yourself after the auto-detect approach proved unreliable on a real wall photo — not yet re-tested live since the rewrite.

## Fixed this session (in order)
1. Escaping-closure build error in `SnapshotRequest` (first-ever build attempt).
2. Camera screens (document scanner, reference-object camera) were rendering behind the app's own tab bar instead of full-screen — fixed with `.fullScreenCover`.
3. Nested tab bars in the sizing screen (its own Manual/Reference tabs stacked above the app's tab bar) clipped buttons with no way to scroll — replaced with a plain segmented `Picker`.
4. Common sizes only offered portrait ratios, no squares — added 10×10 through 24×24.
5. Reference-object measurement picked the wrong rectangle (a detail inside the artwork instead of its outer edge) — added a sanity-check warning, then fully replaced the tap-to-pick-a-detected-quad flow with drag-four-corners-yourself (`CornerDragQuadEditor.swift`), since Vision's detector isn't reliable enough on a real wall photo to trust blindly.
6. Signing team (`appserd inc`, ID `3EWU788PWA`) wasn't persisted in `project.yml`, so regenerating the Xcode project via `xcodegen generate` silently reset it — now stored in `project.yml` itself.
7. Added a placeholder app icon (framed painting + AR scan-corner brackets).
8. **Dead-end navigation**: after adding art, "My Walls" stayed empty (it only ever showed saved AR mockups) and Gallery Wall had no way to add more art without leaving the tab. My Walls now shows a "Your Artwork" row above "Saved Walls", both tabs got a "+ Add Art" tile, and the add-art sheet got a "Done" button.
9. Removed `arkit` from `UIRequiredDeviceCapabilities` (was blocking simulator testing entirely — this flag makes iOS refuse to properly run the app on any hardware without real ARKit support, Simulator included; not the actual cause of a blank-screen scare that turned out to be an unrelated `simctl screenshot` tool bug, but a worthwhile fix on its own).

## Not yet live-tested at all
- AR hanging (wall detection, true-size placement, drag/pinch, snapshot/save)
- Gallery board (multi-piece layouts, equal spacing)
- Size advisor
- Partner vote (ShareLink + manual yes/no)
- Nail spot + level
- The rewritten drag-to-outline reference sizing (post-rewrite)
- "My Walls" / Gallery Wall navigation fixes from this session

## Next steps
1. Plug the iPhone back in, rebuild (`xcodebuild ... -allowProvisioningUpdates build`), install via `devicectl`, and keep working through the proof-test checklist in README.md.
2. Try the rewritten reference-object sizing (drag corners onto the artwork, then the credit card).
3. Try AR hanging end to end: point at a wall, place a piece, drag/pinch, save, confirm it shows up under "My Walls".
4. Try the Gallery Wall flow with 3+ pieces and a locked layout (row/grid/salon) — check gaps are actually even.
