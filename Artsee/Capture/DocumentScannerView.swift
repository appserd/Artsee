import SwiftUI
import VisionKit

/// Wraps VisionKit's document scanner — the same edge-detection and
/// perspective-correction UI as the iOS Files document scanner — to
/// capture a real piece of art, straightened, with no warp at the corners.
struct DocumentScannerView: UIViewControllerRepresentable {
    var onScanned: (UIImage) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned, onCancel: onCancel)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScanned: (UIImage) -> Void
        let onCancel: () -> Void

        init(onScanned: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onScanned = onScanned
            self.onCancel = onCancel
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                onCancel()
                return
            }
            // The user scans one piece of art at a time; take the last page
            // captured in case they retook the shot.
            let image = scan.imageOfPage(at: scan.pageCount - 1)
            onScanned(image)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onCancel()
        }
    }
}
