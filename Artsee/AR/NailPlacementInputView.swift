import SwiftUI

enum HangerKind: String, CaseIterable, Identifiable {
    case singlePoint
    case twoPoint

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .singlePoint: return "Single point (wire or hook)"
        case .twoPoint: return "Two points (D-rings)"
        }
    }
}

struct NailPlacementResult {
    var kind: HangerKind
    var dropMeters: Double
    var spacingMeters: Double?
}

/// Asks what the hanging hardware on the back of the piece actually
/// looks like, so the nail spot can be computed directly from where
/// the art is already placed — not tapped blindly on the wall, which
/// has no way to know where the hardware sits relative to the frame.
/// One point self-levels by gravity, so leveling only matters for two.
struct NailPlacementInputView: View {
    var onConfirm: (NailPlacementResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var kind: HangerKind = .singlePoint
    @State private var unit: LengthUnit = .inches
    @State private var dropText: String = ""
    @State private var spacingText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Hanging hardware", selection: $kind) {
                        ForEach(HangerKind.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if kind == .singlePoint {
                        Text("A single wire or hook self-levels — no checking needed, just drop the nail where marked.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Two points only hang level if both nails are at the same height — use the level while you place each one.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Measure on the back of the frame") {
                    Picker("Units", selection: $unit) {
                        ForEach(LengthUnit.allCases) { Text($0.abbreviation).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(kind == .singlePoint ? "Top edge → wire/hook" : "Top edge → each D-ring")
                        Spacer()
                        TextField("0", text: $dropText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text(unit.abbreviation)
                    }

                    if kind == .twoPoint {
                        HStack {
                            Text("Distance between the two D-rings")
                            Spacer()
                            TextField("0", text: $spacingText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text(unit.abbreviation)
                        }
                    }
                }
            }
            .navigationTitle("Nail Spot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Mark it") {
                        guard let drop = Double(dropText), drop >= 0 else { return }
                        let spacing: Double?
                        if kind == .twoPoint {
                            guard let s = Double(spacingText), s > 0 else { return }
                            spacing = s * unit.metersPerUnit
                        } else {
                            spacing = nil
                        }
                        onConfirm(NailPlacementResult(kind: kind, dropMeters: drop * unit.metersPerUnit, spacingMeters: spacing))
                        dismiss()
                    }
                    .disabled(dropText.isEmpty || (kind == .twoPoint && spacingText.isEmpty))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NailPlacementInputView { _ in }
}
