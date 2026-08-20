//
//  QRScannerView.swift
//  QuickCalories
//
//  Created by John N on 8/8/26.
//

import SwiftUI
import AVFoundation

import PhotosUI
import CoreImage

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    var onScanSuccess: (String) -> Void
    var onScanFailure: (String) -> Void
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isProcessingPhoto = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                CameraQRScannerView { payload in
                    onScanSuccess(payload)
                } onScanFailure: { error in
                    onScanFailure(error)
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Import from Photos")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.bottom, 40)
                    .disabled(isProcessingPhoto)
                }
                
                if isProcessingPhoto {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView("Decoding QR Code...")
                        .tint(.white)
                        .foregroundStyle(.white)
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                processSelectedPhoto(newItem)
            }
        }
    }
    
    private func processSelectedPhoto(_ item: PhotosPickerItem) {
        isProcessingPhoto = true
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw NSError(domain: "QRScanner", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image data"])
                }
                
                if let payload = decodeQRCode(from: image) {
                    await MainActor.run {
                        isProcessingPhoto = false
                        onScanSuccess(payload)
                    }
                } else {
                    throw NSError(domain: "QRScanner", code: -2, userInfo: [NSLocalizedDescriptionKey: "No QR code found in selected photo."])
                }
            } catch {
                await MainActor.run {
                    isProcessingPhoto = false
                    onScanFailure(error.localizedDescription)
                }
            }
        }
    }
    
    private func decodeQRCode(from image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options) else {
            return nil
        }
        
        let features = detector.features(in: ciImage)
        for feature in features {
            if let qrFeature = feature as? CIQRCodeFeature, let payload = qrFeature.messageString {
                return payload
            }
        }
        return nil
    }
}

struct CameraQRScannerView: UIViewControllerRepresentable {
    var onScanSuccess: (String) -> Void
    var onScanFailure: (String) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        #if targetEnvironment(simulator)
        return MockScannerViewController(delegate: context.coordinator)
        #else
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
        #endif
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: CameraQRScannerView
        
        init(parent: CameraQRScannerView) {
            self.parent = parent
        }
        
        func scannerDidFindCode(_ code: String) {
            parent.onScanSuccess(code)
        }
        
        func scannerDidFail(error: String) {
            parent.onScanFailure(error)
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func scannerDidFindCode(_ code: String)
    func scannerDidFail(error: String)
}

#if !targetEnvironment(simulator)
class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.scannerDidFail(error: "Camera not supported on this device.")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.scannerDidFail(error: "Failed to access camera. Please check camera permissions in iOS Settings.")
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            delegate?.scannerDidFail(error: "Failed to add camera input to session.")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            delegate?.scannerDidFail(error: "Failed to configure QR code scanning metadata output.")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        addViewfinderOverlay()
        
        // Start capture session asynchronously to prevent main thread hitches
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    private func addViewfinderOverlay() {
        // Darkened background layer
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let scannerSize = CGSize(width: 250, height: 250)
        let scannerFrame = CGRect(
            x: (view.bounds.width - scannerSize.width) / 2,
            y: (view.bounds.height - scannerSize.height) / 2,
            width: scannerSize.width,
            height: scannerSize.height
        )
        
        // Cut out center viewfinder shape
        let path = UIBezierPath(rect: overlayView.bounds)
        let cutoutPath = UIBezierPath(roundedRect: scannerFrame, cornerRadius: 20)
        path.append(cutoutPath.reversing())
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        overlayView.layer.mask = mask
        view.addSubview(overlayView)
        
        // Viewfinder borders
        let borderView = UIView(frame: scannerFrame)
        borderView.layer.borderColor = UIColor.systemGreen.cgColor
        borderView.layer.borderWidth = 3
        borderView.layer.cornerRadius = 20
        view.addSubview(borderView)
        
        // Help label
        let instructionLabel = UILabel()
        instructionLabel.text = "Center the QR code in the box to import"
        instructionLabel.textColor = .white
        instructionLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        instructionLabel.textAlignment = .center
        instructionLabel.frame = CGRect(
            x: 20,
            y: scannerFrame.maxY + 24,
            width: view.bounds.width - 40,
            height: 30
        )
        view.addSubview(instructionLabel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previewLayer != nil {
            previewLayer.frame = view.layer.bounds
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Success Haptic Feedback
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            delegate?.scannerDidFindCode(stringValue)
        }
    }
}
#endif

// Simulator Mock View Controller
class MockScannerViewController: UIViewController {
    weak var delegate: ScannerViewControllerDelegate?
    
    init(delegate: ScannerViewControllerDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 24
        container.alignment = .center
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        let iconView = UIImageView(image: UIImage(systemName: "qrcode.viewfinder"))
        iconView.tintColor = .systemGreen
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        iconView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        container.addArrangedSubview(iconView)
        
        let titleLabel = UILabel()
        titleLabel.text = "Simulator Camera Mock"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        container.addArrangedSubview(titleLabel)
        
        let descLabel = UILabel()
        descLabel.text = "Running in simulator. Click the button below to simulate scanning a shared QuickCalories QR code."
        descLabel.textColor = .lightGray
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        container.addArrangedSubview(descLabel)
        
        let mockButton = UIButton(type: .system)
        mockButton.setTitle("Simulate Scan: Peanut Butter", for: .normal)
        mockButton.setTitleColor(.white, for: .normal)
        mockButton.backgroundColor = .systemGreen
        mockButton.layer.cornerRadius = 10
        mockButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        mockButton.addTarget(self, action: #selector(simulateScan), for: .touchUpInside)
        container.addArrangedSubview(mockButton)
    }
    
    @objc private func simulateScan() {
        let mockPayload = """
        {
            "type": "quickcalories_food",
            "name": "Peanut Butter",
            "servingSize": 2.0,
            "unit": "tbsp",
            "calories": 190,
            "protein": 7.0,
            "carbs": 6.0,
            "fat": 16.0
        }
        """
        // Vibration haptic
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        delegate?.scannerDidFindCode(mockPayload)
    }
}
