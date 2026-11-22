import SwiftUI
import PhotosUI

/// The full "get art in, then size it" flow:
/// 1. Scan with camera, or import from Photos.
/// 2. Size by manual entry, common size, or reference object.
/// 3. Save to the library and (optionally) jump straight into AR.
struct AddArtworkFlowView: View {
    @EnvironmentObject private var store: PersistenceStore
    /// Safe no-op when there's nothing to dismiss (e.g. on its own tab);
    /// lets this view offer "Done" when opened as a sheet from elsewhere
    /// (Gallery Wall, My Walls' "+" tile).
    @Environment(\.dismiss) private var dismiss

    private enum Stage {
        case chooseSource
        case sizing(UIImage)
        case savedGoToHang(ArtworkPiece)
    }

    @State private var stage: Stage = .chooseSource
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var title: String = "Untitled piece"
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Add Art")
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                stage = .sizing(image)
            }
        }
        // Full-screen cover, not a tab's regular content — otherwise the
        // app's own tab bar stays docked at the bottom and squeezes the
        // camera UI, hiding its own controls (VisionKit's document
        // scanner needs the whole screen to itself).
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView(
                onScanned: { image in
                    showScanner = false
                    stage = .sizing(image)
                },
                onCancel: { showScanner = false }
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch stage {
        case .chooseSource:
            chooseSourceView

        case .sizing(let image):
            sizingView(for: image)

        case .savedGoToHang(let piece):
            savedView(piece: piece)
        }
    }

    private var chooseSourceView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "photo.artframe")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Get your art into Artsee")
                .font(.title2.bold())

            Button {
                showScanner = true
            } label: {
                Label("Scan a real piece", systemImage: "camera.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                Label("Import from Photos", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }

    private enum SizingTab: String, CaseIterable, Identifiable {
        case manual
        case reference
        var id: String { rawValue }
        var label: String {
            switch self {
            case .manual: return "Manual / common size"
            case .reference: return "Reference object"
            }
        }
    }

    @State private var sizingTab: SizingTab = .manual

    private func sizingView(for image: UIImage) -> some View {
        // A plain VStack + Picker here, not a nested TabView — this
        // screen is itself one tab of the app's own TabView, and a
        // second tab bar stacked above the first squeezed everything
        // above it and clipped buttons with no way to scroll past them.
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 140)
                .padding(.top, 8)

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.top, 8)

            Picker("Sizing method", selection: $sizingTab) {
                ForEach(SizingTab.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                switch sizingTab {
                case .manual:
                    NavigationStack {
                        ManualSizeEntryView { dims, method in
                            save(image: image, dimensions: dims, method: method)
                        }
                    }
                case .reference:
                    NavigationStack {
                        ReferenceSizingView { dims, method in
                            save(image: image, dimensions: dims, method: method)
                        }
                    }
                }
            }
        }
    }

    private func save(image: UIImage, dimensions: Dimensions, method: SizingMethod) {
        let piece = store.addArtwork(image: image, title: title, dimensions: dimensions, sizingMethod: method)
        stage = .savedGoToHang(piece)
    }

    private func savedView(piece: ArtworkPiece) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("\(piece.title) added")
                .font(.title3.bold())
            Text(piece.dimensions.formatted(in: .inches))
                .foregroundStyle(.secondary)

            NavigationLink {
                HangArtworkView(pieces: [piece])
            } label: {
                Label("Hang it in AR", systemImage: "arkit")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Add another piece") {
                title = "Untitled piece"
                stage = .chooseSource
            }

            Button("Done") { dismiss() }
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AddArtworkFlowView()
        .environmentObject(PersistenceStore())
}
