import SwiftUI

@main
struct ArtseeApp: App {
    @StateObject private var store = PersistenceStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
        }
    }
}
