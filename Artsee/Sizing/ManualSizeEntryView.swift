import SwiftUI

/// Sizing method #1: type it in, or pick a common frame size.
struct ManualSizeEntryView: View {
    var onConfirm: (Dimensions, SizingMethod) -> Void

    @State private var unit: LengthUnit = .inches
    @State private var widthText: String = ""
    @State private var heightText: String = ""
    @State private var selectedCommonSize: CommonSize?

    private var typedDimensions: Dimensions? {
        guard let w = Double(widthText), let h = Double(heightText), w > 0, h > 0 else { return nil }
        return Dimensions(width: w, height: h, unit: unit)
    }

    var body: some View {
        Form {
            Section("Common sizes") {
                ForEach(CommonSize.allCases) { size in
                    Button {
                        selectedCommonSize = size
                        widthText = ""
                        heightText = ""
                    } label: {
                        HStack {
                            Text(size.rawValue)
                            Spacer()
                            if selectedCommonSize == size {
                                Image(systemName: "checkmark").foregroundStyle(.tint)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }

            Section("Or type exact dimensions") {
                Picker("Units", selection: $unit) {
                    ForEach(LengthUnit.allCases) { Text($0.abbreviation).tag($0) }
                }
                .pickerStyle(.segmented)

                HStack {
                    TextField("Width", text: $widthText)
                        .keyboardType(.decimalPad)
                        .onChange(of: widthText) { _, _ in selectedCommonSize = nil }
                    Text(unit.abbreviation)
                    Divider()
                    TextField("Height", text: $heightText)
                        .keyboardType(.decimalPad)
                        .onChange(of: heightText) { _, _ in selectedCommonSize = nil }
                    Text(unit.abbreviation)
                }
            }

            Section {
                Button("Use this size") {
                    if let size = selectedCommonSize {
                        onConfirm(size.dimensions, .commonSize(size.rawValue))
                    } else if let dims = typedDimensions {
                        onConfirm(dims, .manualEntry)
                    }
                }
                .disabled(selectedCommonSize == nil && typedDimensions == nil)
            }
        }
        .navigationTitle("Size")
    }
}

#Preview {
    NavigationStack {
        ManualSizeEntryView { _, _ in }
    }
}
