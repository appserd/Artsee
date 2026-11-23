import SwiftUI
import CoreMotion

/// A classic bubble-level readout, driven by CoreMotion rather than
/// ARKit — hold the phone flat against the top edge of the frame and
/// this tells you when it's level, closing the loop after the nail spot
/// is marked.
///
/// Deliberately uses the raw gravity vector rather than
/// `attitude.roll`: roll is only an intuitive "tilted left/right"
/// measurement when the device is held flat like a tablet. Held
/// vertically against a wall — the actual use case here — roll means
/// something else entirely and swings wildly (confirmed live: -77.6°
/// while just holding the phone up normally). The gravity vector is
/// expressed in the device's own frame regardless of how it's held, so
/// this works correctly held any way the phone naturally sits against
/// a wall.
@MainActor
final class LevelMonitor: ObservableObject {
    @Published var rollDegrees: Double = 0
    @Published var isLevel: Bool = false

    private let motionManager = CMMotionManager()
    private let tolerance = 1.0

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let gravity = motion.gravity
            let degrees = atan2(gravity.x, -gravity.y) * 180 / .pi
            self.rollDegrees = degrees
            self.isLevel = abs(degrees) <= self.tolerance
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct LevelIndicatorView: View {
    @StateObject private var monitor = LevelMonitor()

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.6))
                    .frame(width: 200, height: 36)

                Rectangle()
                    .fill(.white.opacity(0.5))
                    .frame(width: 2, height: 36)

                Capsule()
                    .fill(monitor.isLevel ? Color.green : Color.yellow)
                    .frame(width: 44, height: 22)
                    .offset(x: min(max(CGFloat(monitor.rollDegrees) * 4, -78), 78))
                    .animation(.interactiveSpring, value: monitor.rollDegrees)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(monitor.isLevel ? "Level" : String(format: "%.1f°", monitor.rollDegrees))
                .font(.caption.monospacedDigit())
                .foregroundStyle(monitor.isLevel ? .green : .secondary)
        }
        .onAppear { monitor.start() }
        .onDisappear { monitor.stop() }
    }
}

#Preview {
    LevelIndicatorView()
        .padding()
        .background(Color.black)
}
