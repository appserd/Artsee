import SwiftUI

/// The "My Walls" tab: every piece of art added, plus every saved AR
/// mockup, so there's always somewhere to see what you have and do
/// something with it — not just a dead end after sizing a piece.
struct SavedWallsView: View {
    @EnvironmentObject private var store: PersistenceStore
    @State private var showAddArt = false

    var body: some View {
        NavigationStack {
            Group {
                if store.artworkPieces.isEmpty && store.mockups.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("My Walls")
        }
        .sheet(isPresented: $showAddArt) {
            AddArtworkFlowView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Nothing here yet")
                .font(.headline)
            Text("Add a piece of art and size it — it'll show up here right away, ready to hang in AR.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showAddArt = true
            } label: {
                Label("Add Art", systemImage: "plus.square.on.square")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !store.artworkPieces.isEmpty {
                    sectionHeader("Your Artwork")
                    artworkRow
                }
                if !store.mockups.isEmpty {
                    sectionHeader("Saved Walls")
                    mockupsGrid
                }
            }
            .padding(.vertical)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
            .padding(.horizontal)
    }

    private var artworkRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(store.artworkPieces.sorted(by: { $0.dateAdded > $1.dateAdded })) { piece in
                    NavigationLink {
                        HangArtworkView(pieces: [piece])
                    } label: {
                        ArtworkThumbnail(piece: piece)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showAddArt = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.title2)
                        Text("Add Art")
                            .font(.caption)
                    }
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.secondary)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal)
        }
    }

    private var mockupsGrid: some View {
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
        .padding(.horizontal)
    }
}

private struct ArtworkThumbnail: View {
    @EnvironmentObject private var store: PersistenceStore
    let piece: ArtworkPiece

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let image = store.image(for: piece) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 120, height: 120)
            }
            Text(piece.title)
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)
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
