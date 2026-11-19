import SwiftUI

/// Small floating card shown over the AR view with the advisor's verdict.
struct AdvisorBannerView: View {
    let messages: [String]
    let verdict: SizeAdvisor.Verdict?

    var body: some View {
        if !messages.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(tint)
                    Text("Size advisor")
                        .font(.footnote.bold())
                }
                ForEach(messages, id: \.self) { message in
                    Text(message)
                        .font(.footnote)
                }
            }
            .padding(12)
            .frame(maxWidth: 320, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var icon: String {
        switch verdict {
        case .goodFit: return "checkmark.seal.fill"
        case .tooSmall, .tooLarge: return "exclamationmark.triangle.fill"
        case .none: return "ruler"
        }
    }

    private var tint: Color {
        switch verdict {
        case .goodFit: return .green
        case .tooSmall, .tooLarge: return .orange
        case .none: return .blue
        }
    }
}

#Preview {
    AdvisorBannerView(
        messages: ["Too small for what's below it — only about 40% of its width. Try one size up."],
        verdict: .tooSmall
    )
    .padding()
}
