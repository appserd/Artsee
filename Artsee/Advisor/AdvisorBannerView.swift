import SwiftUI

/// Small floating card shown over the AR view with the advisor's
/// verdict — a colored percentage badge (green = good fit, red = not
/// quite) rather than a paragraph, so it reads at a glance.
struct AdvisorBannerView: View {
    let advice: SizeAdvisor.FurnitureAdvice?

    var body: some View {
        if let advice {
            HStack(spacing: 10) {
                Text("\(advice.ratioPercent)%")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(tint(for: advice.verdict), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Size advisor")
                        .font(.footnote.bold())
                    Text(shortLabel(for: advice.verdict))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: 280, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func tint(for verdict: SizeAdvisor.Verdict) -> Color {
        switch verdict {
        case .goodFit: return .green
        case .tooSmall, .tooLarge: return .red
        }
    }

    private func shortLabel(for verdict: SizeAdvisor.Verdict) -> String {
        switch verdict {
        case .goodFit: return "Good fit for what's below it"
        case .tooSmall: return "Too small — try a size up"
        case .tooLarge: return "Runs wide — consider a size down"
        }
    }
}

#Preview {
    AdvisorBannerView(advice: SizeAdvisor.furnitureFitAdvice(artworkWidthMeters: 0.8, furnitureWidthMeters: 2.0))
        .padding()
}
