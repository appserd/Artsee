import SwiftUI

/// The "My Walls" tab: every saved mockup and gallery board, so the user
/// can come back to them without rescanning or resizing anything.
struct SavedWallsView: View {
    @EnvironmentObject private var store: PersistenceStore

    var body: some View {
        NavigationStack {
            Group {
                if store.mockups.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
            .navigationTitle("My Walls")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No saved walls yet")
                .font(.headline)
            Text("Add a piece of art, size it, and hang it in AR — it'll show up here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 12)], spacing: 12) {
                ForEach(store.mockups.sorted(by: { $0.dateUpdated > $1.dateUpdated })) { mockup in
                    NavigationLink {
                        MockupDetailView(mockup: mockup)
                    } label: {
                        MockupCard(mockup: mockup)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

private struct MockupCard: View {
    @EnvironmentObject private var store: PersistenceStore
    let mockup: SavedMockup

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                if let image = store.snapshotImage(for: mockup) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 140)
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }
                voteBadge
                    .padding(6)
            }
            Text(mockup.name)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            Text(mockup.isGalleryBoard ? "\(mockup.pieces.count) pieces" : "1 piece")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var voteBadge: some View {
        switch mockup.partnerVoteStatus {
        case .yes:
            Image(systemName: "hand.thumbsup.fill").foregroundStyle(.white).padding(6).background(.green, in: Circle())
        case .no:
            Image(systemName: "hand.thumbsdown.fill").foregroundStyle(.white).padding(6).background(.red, in: Circle())
        case .sent:
            Image(systemName: "paperplane.fill").foregroundStyle(.white).padding(6).background(.blue, in: Circle())
        case .notSent:
            EmptyView()
        }
    }
}

#Preview {
    SavedWallsView()
        .environmentObject(PersistenceStore())
}
