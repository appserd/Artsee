import SwiftUI

/// Lets the user tell the advisor how wide the furniture under the art
/// is, so it can apply the two-thirds rule. Deliberately simple for v1 —
/// typed width, not another AR measurement step.
struct FurnitureInputView: View {
    @Environment(\.dismiss) private var dismiss
    var onConfirm: (Double?) -> Void

    @State private var unit: LengthUnit = .inches
    @State private var widthText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("What's under this piece? Enter the width of the sofa, console, or headboard so the advisor can check the fit.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section {
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
    }
}

#Preview {
    FurnitureInputView { _ in }
}
