@preconcurrency import AVFoundation
import SwiftUI
import UIKit

struct BarcodeScannerView: UIViewControllerRepresentable {
    let onCode: (String) -> Void
    let onFailure: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let controller = BarcodeScannerViewController()
        controller.onCode = onCode
        controller.onFailure = onFailure
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

final class BarcodeScannerViewController: UIViewController, @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    var onFailure: ((String) -> Void)?
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasDeliveredCode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configurePermission()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [session] in session.stopRunning() }
        }
    }

    private func configurePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureSession()
                    } else {
                        self?.onFailure?("Autorisez la caméra dans Réglages pour scanner un produit.")
                    }
                }
            }
        default:
            onFailure?("Autorisez la caméra dans Réglages pour scanner un produit.")
        }
    }

    private func configureSession() {
        guard
            let camera = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: camera),
            session.canAddInput(input)
        else {
            onFailure?("La caméra n’est pas disponible.")
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            onFailure?("Le scanner n’est pas disponible.")
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer
        layer.frame = view.bounds

        DispatchQueue.global(qos: .userInitiated).async { [session] in session.startRunning() }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard
            !hasDeliveredCode,
            let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let code = object.stringValue
        else { return }
        hasDeliveredCode = true
        session.stopRunning()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onCode?(code)
    }
}
