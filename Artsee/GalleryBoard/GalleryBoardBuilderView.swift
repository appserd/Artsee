import SwiftUI

/// Pick 3–5 pieces from the library, choose how they're arranged, then
/// hang the whole board in AR at once.
struct GalleryBoardBuilderView: View {
    @EnvironmentObject private var store: PersistenceStore

    @State private var selectedIds: Set<UUID> = []
    @State private var preset: BoardLayoutPreset = .grid
    @State private var showAddArt = false

    private var selectedPieces: [ArtworkPiece] {
        store.artworkPieces.filter { selectedIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.artworkPieces.isEmpty {
                    emptyState
                } else {
                    pickerGrid
                    layoutPicker
                    hangButton
                }
            }
            .navigationTitle("Gallery Wall")
        }
        .sheet(isPresented: $showAddArt) {
            AddArtworkFlowView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.3x2")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Add a few pieces first")
                .font(.headline)
            Text("Gallery walls work best with 3–5 pieces.")
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

    private var pickerGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 12)], spacing: 12) {
                Button {
                    showAddArt = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.title2)
                        Text("Add Art")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .foregroundStyle(.secondary)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                }

                ForEach(store.artworkPieces) { piece in
                    Button {
                        toggle(piece)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            if let image = store.image(for: piece) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            if selectedIds.contains(piece.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white, .tint)
                                    .padding(6)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedIds.contains(piece.id) ? Color.accentColor : .clear, lineWidth: 3)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private var layoutPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Layout").font(.subheadline.bold()).padding(.horizontal)
            Picker("Layout", selection: $preset) {
                ForEach(BoardLayoutPreset.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Text(preset == .freeform ? "You'll drag each piece freely in AR." : "Locked to equal spacing — one tap, even gaps.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var hangButton: some View {
        NavigationLink {
            HangArtworkView(pieces: selectedPieces, layoutPreset: preset)
        } label: {
            Label("Hang board in AR (\(selectedIds.count) pieces)", systemImage: "arkit")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(selectedIds.count < 2)
        .padding()
    }

    private func toggle(_ piece: ArtworkPiece) {
        if selectedIds.contains(piece.id) {
            selectedIds.remove(piece.id)
        } else if selectedIds.count < 5 {
            selectedIds.insert(piece.id)
        }
    }
}

#Preview {
    GalleryBoardBuilderView()
        .environmentObject(PersistenceStore())
}
