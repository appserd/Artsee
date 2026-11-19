import SwiftUI
import PhotosUI

/// The full "get art in, then size it" flow:
/// 1. Scan with camera, or import from Photos.
/// 2. Size by manual entry, common size, or reference object.
/// 3. Save to the library and (optionally) jump straight into AR.
struct AddArtworkFlowView: View {
    @EnvironmentObject private var store: PersistenceStore

    private enum Stage {
        case chooseSource
        case scanning
        case sizing(UIImage)
        case savedGoToHang(ArtworkPiece)
    }

    @State private var stage: Stage = .chooseSource
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var title: String = "Untitled piece"

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
    }

    @ViewBuilder
    private var content: some View {
        switch stage {
        case .chooseSource:
            chooseSourceView

        case .scanning:
            DocumentScannerView(
                onScanned: { image in stage = .sizing(image) },
                onCancel: { stage = .chooseSource }
            )
            .ignoresSafeArea()

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
                stage = .scanning
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

    private func sizingView(for image: UIImage) -> some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 220)
                .padding(.top)

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
                .padding()

            TabView {
                NavigationStack {
                    ManualSizeEntryView { dims, method in
                        save(image: image, dimensions: dims, method: method)
                    }
                }
                .tabItem { Label("Manual / common size", systemImage: "ruler") }

                NavigationStack {
                    ReferenceSizingView { dims, method in
                        save(image: image, dimensions: dims, method: method)
                    }
                }
                .tabItem { Label("Reference object", systemImage: "creditcard") }
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
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AddArtworkFlowView()
        .environmentObject(PersistenceStore())
}
