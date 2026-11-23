import SwiftUI

/// Lets the user tell the advisor how wide the furniture under the art
/// is, so it can apply the two-thirds rule. Measuring with the camera
/// is the primary path — typing a number is the fallback for furniture
/// not visible from where the art is being placed.
struct FurnitureInputView: View {
    @Environment(\.dismiss) private var dismiss
    var onConfirm: (Double?) -> Void

    @State private var unit: LengthUnit = .inches
    @State private var widthText: String = ""
    @State private var showMeasure = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("What's under this piece? Measure the sofa, console, or headboard's width so the advisor can check the fit.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        showMeasure = true
                    } label: {
                        Label("Measure with camera", systemImage: "camera.viewfinder")
                    }
                }

                Section("Or type it in") {
                    Picker("Units", selection: $unit) {
                        ForEach(LengthUnit.allCases) { Text($0.abbreviation).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        TextField("Furniture width", text: $widthText)
                            .keyboardType(.decimalPad)
                        Text(unit.abbreviation)
                    }
                }
            }
            .navigationTitle("Size Advisor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onConfirm(nil)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let w = Double(widthText), w > 0 {
                            onConfirm(w * unit.metersPerUnit)
                        } else {
                            onConfirm(nil)
                        }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showMeasure) {
            FurnitureMeasureView(
                onMeasured: { meters in
                    widthText = String(format: "%.1f", meters / unit.metersPerUnit)
                    showMeasure = false
                },
                onCancel: { showMeasure = false }
            )
        }
    }
}

#Preview {
    FurnitureInputView { _ in }
}
