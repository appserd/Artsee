import SwiftUI

struct MockupDetailView: View {
    @EnvironmentObject private var store: PersistenceStore
    @Environment(\.dismiss) private var dismiss
    let mockup: SavedMockup

    @State private var showPartnerVote = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let image = store.snapshotImage(for: mockup) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(mockup.name).font(.title2.bold())
                    Text(mockup.isGalleryBoard ? "\(mockup.pieces.count)-piece gallery wall · \(mockup.layoutPreset.displayName)" : "Single piece")
                        .foregroundStyle(.secondary)
                    if !mockup.nailSpots.isEmpty {
                        Text("\(mockup.nailSpots.count) nail spot\(mockup.nailSpots.count == 1 ? "" : "s") marked")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    HangArtworkView(pieces: artworkPieces, existingMockup: mockup, layoutPreset: mockup.layoutPreset)
                } label: {
                    Label("Reopen in AR", systemImage: "arkit")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    showPartnerVote = true
                } label: {
                    Label("Partner vote", systemImage: "hand.thumbsup")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationTitle(mockup.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPartnerVote) {
            PartnerVoteView(mockup: mockup)
        }
        .confirmationDialog("Delete this wall?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.deleteMockup(mockup)
                dismiss()
            }
        }
    }

    private var artworkPieces: [ArtworkPiece] {
        mockup.pieces.compactMap { store.artwork(id: $0.artworkId) }
    }
}

#Preview {
    NavigationStack {
        MockupDetailView(mockup: SavedMockup(name: "Living room", pieces: []))
            .environmentObject(PersistenceStore())
    }
}
