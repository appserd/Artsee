# Progress

## Where we are
Full v1 Swift/SwiftUI scaffold written (23 Swift files) covering every item in the spec: scan/import, manual + reference-object sizing, AR wall hanging (RealityKit, true-size placement, drag/pinch), size advisor, gallery board layouts, partner vote, nail+level, on-device persistence. Not yet compiled — written from a cloud container with no Xcode/macOS access.

`CLAUDE.md` and `.gitignore` are in place (house rules + standard iOS/secrets ignores). Not yet pushed to GitHub — `github.com/appserd/Artsee` doesn't exist yet and this cloud session can't create new GitHub repos (infra restriction, not a permission setting).

## Next steps
1. Create the `appserd/Artsee` GitHub repo (private), then push this local commit.
2. On a Mac: `brew install xcodegen && cd Artsee && xcodegen generate && open Artsee.xcodeproj`, set signing team, build on a real iPhone.
3. Work through the "known rough edges" list in README.md — a few RealityKit API calls that need Xcode's compiler to confirm.
4. Run the 7 proof tests in README.md on a real device.
5. Per house rules: this project's actual home should probably be `~/Desktop/APPSERD APPS/Artsee/code/` on your Mac, matching your other apps — currently it only exists in this cloud session at `/home/user/Artsee`.
