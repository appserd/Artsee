import SwiftUI

struct SettingsView: View {
    @AppStorage("furnitureAdvisorEnabled") private var furnitureAdvisorEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Size advisor", isOn: $furnitureAdvisorEnabled)
                    Text("Shows whether your art is a good size for the furniture under it — about two-thirds the furniture's width is the classic rule of thumb. Turn this off to hide the Furniture button in AR entirely.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
