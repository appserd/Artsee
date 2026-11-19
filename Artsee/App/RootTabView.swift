import SwiftUI

struct RootTabView: View {
    @State private var selection: Tab = .library

    enum Tab {
        case library
        case addArtwork
        case board
    }

    var body: some View {
        TabView(selection: $selection) {
            SavedWallsView()
                .tabItem { Label("My Walls", systemImage: "photo.on.rectangle.angled") }
                .tag(Tab.library)

            AddArtworkFlowView()
                .tabItem { Label("Add Art", systemImage: "plus.square.on.square") }
                .tag(Tab.addArtwork)

            GalleryBoardBuilderView()
                .tabItem { Label("Gallery Wall", systemImage: "square.grid.3x2") }
                .tag(Tab.board)
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(PersistenceStore())
}
