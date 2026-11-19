import SwiftUI

/// No accounts, no backend — sharing the mockup is just the system share
/// sheet with the snapshot + a yes/no prompt. Since the partner likely
/// doesn't have Artsee installed, their answer comes back the normal way
/// (a text, a thumbs-up) and the user logs it here with one tap.
struct PartnerVoteView: View {
    @EnvironmentObject private var store: PersistenceStore
    @Environment(\.dismiss) private var dismiss
    let mockup: SavedMockup

    @State private var voteStatus: PartnerVoteStatus

    init(mockup: SavedMockup) {
        self.mockup = mockup
        _voteStatus = State(initialValue: mockup.partnerVoteStatus)
    }

    private var snapshot: UIImage? {
        store.snapshotImage(for: mockup)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let snapshot {
                    Image(uiImage: snapshot)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(radius: 4)
                }

                Text("Saved! Want a second opinion?")
                    .font(.headline)

                if let snapshot {
                    ShareLink(
                        item: Image(uiImage: snapshot),
                        preview: SharePreview("What do you think — yes or no?", image: Image(uiImage: snapshot))
                    ) {
                        Label("Send to partner", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .simultaneousGesture(TapGesture().onEnded { markSent() })
                }

                Text("When they reply, log their answer:")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    voteButton(status: .yes, label: "Yes", icon: "hand.thumbsup.fill", color: .green)
                    voteButton(status: .no, label: "No", icon: "hand.thumbsdown.fill", color: .red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Partner Vote")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func voteButton(status: PartnerVoteStatus, label: String, icon: String, color: Color) -> some View {
        Button {
            voteStatus = status
            persist()
        } label: {
            VStack {
                Image(systemName: icon)
                    .font(.title)
                Text(label)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(voteStatus == status ? color.opacity(0.2) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(voteStatus == status ? color : .primary)
    }

    private func markSent() {
        if voteStatus == .notSent {
            voteStatus = .sent
            persist()
        }
    }

    private func persist() {
        var updated = mockup
        updated.partnerVoteStatus = voteStatus
        store.saveMockup(updated)
    }
}

#Preview {
    PartnerVoteView(mockup: SavedMockup(name: "Living room", pieces: []))
        .environmentObject(PersistenceStore())
}
