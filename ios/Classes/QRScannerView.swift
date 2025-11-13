import Flutter
import UIKit
import AVFoundation
import Vision

// Custom UIView subclass to handle layout updates
class PreviewView: UIView {
    var onLayoutSubviews: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayoutSubviews?()
    }
}

class QRScannerView: NSObject, FlutterPlatformView {
    private let frame: CGRect
    private let viewId: Int64
    private let channel: FlutterMethodChannel
    private let config: [String: Any]?

    private var previewView: PreviewView!
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var isScanning = true
    private var lastScanTime: TimeInterval = 0
    private let scanDelay: TimeInterval = 0.5

    init(
        frame: CGRect,
        viewId: Int64,
        args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        self.frame = frame
        self.viewId = viewId
        self.config = args as? [String: Any]
        self.channel = FlutterMethodChannel(
            name: "plugins.flutter_qrcode/scanner_view_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        previewView = PreviewView(frame: frame)
        previewView.backgroundColor = .black

        // Update preview layer frame when view layout changes
        previewView.onLayoutSubviews = { [weak self] in
            self?.updatePreviewLayerFrame()
        }

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call: call, result: result)
        }

        setupCamera()
    }

    func view() -> UIView {
        return previewView
    }

    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startScanning":
            startScanning()
            result(nil)
        case "stopScanning":
            stopScanning()
            result(nil)
        case "resumeScanning":
            isScanning = true
            result(nil)
        case "pauseScanning":
            isScanning = false
            result(nil)
        case "toggleTorch":
            toggleTorch()
            result(nil)
        case "setTorch":
            if let args = call.arguments as? [String: Any],
               let enabled = args["enabled"] as? Bool {
                setTorch(enabled: enabled)
            }
            result(nil)
        case "switchCamera":
            switchCamera()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high

        guard let captureSession = captureSession else { return }

        let useFrontCamera = config?["useFrontCamera"] as? Bool ?? false
        let position: AVCaptureDevice.Position = useFrontCamera ? .front : .back

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = previewView.bounds
        previewLayer?.videoGravity = .resizeAspectFill

        if let previewLayer = previewLayer {
            previewView.layer.addSublayer(previewLayer)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }

    private func updatePreviewLayerFrame() {
        guard let previewLayer = previewLayer else { return }

        // Update the preview layer frame to match the view's current bounds
        DispatchQueue.main.async {
            previewLayer.frame = self.previewView.bounds
        }
    }

    private func startScanning() {
        isScanning = true
        captureSession?.startRunning()
    }

    private func stopScanning() {
        isScanning = false
        captureSession?.stopRunning()
    }

    private func toggleTorch() {
        guard let device = getCurrentCamera() else { return }

        if device.hasTorch {
            try? device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            device.unlockForConfiguration()
        }
    }

    private func setTorch(enabled: Bool) {
        guard let device = getCurrentCamera() else { return }

        if device.hasTorch {
            try? device.lockForConfiguration()
            device.torchMode = enabled ? .on : .off
            device.unlockForConfiguration()
        }
    }

    private func switchCamera() {
        guard let captureSession = captureSession else { return }

        captureSession.beginConfiguration()

        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else {
            captureSession.commitConfiguration()
            return
        }

        captureSession.removeInput(currentInput)

        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
            captureSession.addInput(currentInput)
            captureSession.commitConfiguration()
            return
        }

        captureSession.addInput(newInput)
        captureSession.commitConfiguration()
    }

    private func getCurrentCamera() -> AVCaptureDevice? {
        guard let input = captureSession?.inputs.first as? AVCaptureDeviceInput else {
            return nil
        }
        return input.device
    }
}

extension QRScannerView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isScanning else { return }

        let currentTime = Date().timeIntervalSince1970
        guard currentTime - lastScanTime >= scanDelay else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNBarcodeObservation],
                  !observations.isEmpty else {
                return
            }

            self.lastScanTime = currentTime
            self.handleBarcodes(observations: observations)
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }

    private func handleBarcodes(observations: [VNBarcodeObservation]) {
        let vibrateOnSuccess = config?["vibrateOnSuccess"] as? Bool ?? true
        if vibrateOnSuccess {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }

        for observation in observations {
            let valueTypeInfo = detectValueType(from: observation.payloadStringValue)

            let barcodeData: [String: Any?] = [
                "rawValue": observation.payloadStringValue,
                "format": barcodeFormatToInt(symbology: observation.symbology),
                "cornerPoints": nil,
                "boundingBox": [
                    "left": Double(observation.boundingBox.minX),
                    "top": Double(observation.boundingBox.minY),
                    "right": Double(observation.boundingBox.maxX),
                    "bottom": Double(observation.boundingBox.maxY)
                ],
                "valueType": valueTypeInfo
            ]

            DispatchQueue.main.async { [weak self] in
                self?.channel.invokeMethod("onBarcodeScanned", arguments: barcodeData)
            }
        }

        let autoPause = config?["autoPauseAfterScan"] as? Bool ?? false
        if autoPause {
            isScanning = false
        }
    }

    private func detectValueType(from value: String?) -> [String: Any?] {
        guard let value = value else {
            return ["type": 0, "data": nil] // unknown
        }

        let lowercased = value.lowercased()

        // Check for URL (type 8)
        if lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") {
            return ["type": 8, "data": ["url": value]]
        }

        // Check for Email (type 2)
        if lowercased.hasPrefix("mailto:") {
            let email = String(value.dropFirst(7)) // Remove "mailto:"
            return ["type": 2, "data": ["address": email]]
        }

        // Check for Phone (type 4)
        if lowercased.hasPrefix("tel:") {
            let phone = String(value.dropFirst(4)) // Remove "tel:"
            return ["type": 4, "data": ["number": phone]]
        }

        // Check for SMS (type 6)
        if lowercased.hasPrefix("sms:") || lowercased.hasPrefix("smsto:") {
            let prefix = lowercased.hasPrefix("sms:") ? 4 : 6
            let phone = String(value.dropFirst(prefix))
            return ["type": 6, "data": ["phoneNumber": phone]]
        }

        // Check for WiFi (type 9) - Format: WIFI:T:WPA;S:ssid;P:password;;
        if lowercased.hasPrefix("wifi:") {
            var ssid: String?
            var password: String?
            var encryption: String?

            let components = value.components(separatedBy: ";")
            for component in components {
                if component.hasPrefix("S:") {
                    ssid = String(component.dropFirst(2))
                } else if component.hasPrefix("P:") {
                    password = String(component.dropFirst(2))
                } else if component.hasPrefix("T:") {
                    encryption = String(component.dropFirst(2))
                }
            }

            return ["type": 9, "data": [
                "ssid": ssid,
                "password": password,
                "encryptionType": encryption
            ]]
        }

        // Check for GEO (type 10) - Format: geo:latitude,longitude
        if lowercased.hasPrefix("geo:") {
            let coords = String(value.dropFirst(4))
            let parts = coords.components(separatedBy: ",")
            if parts.count >= 2 {
                return ["type": 10, "data": [
                    "latitude": Double(parts[0]),
                    "longitude": Double(parts[1])
                ]]
            }
        }

        // Check for simple email pattern
        if value.contains("@") && value.contains(".") {
            let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            if let regex = try? NSRegularExpression(pattern: emailPattern),
               regex.firstMatch(in: value, range: NSRange(location: 0, length: value.utf16.count)) != nil {
                return ["type": 2, "data": ["address": value]]
            }
        }

        // Default to text (type 7)
        return ["type": 7, "data": nil]
    }

    private func barcodeFormatToInt(symbology: VNBarcodeSymbology) -> Int {
        switch symbology {
        case .qr:
            return 256
        case .aztec:
            return 1
        case .code39:
            return 4
        case .code93:
            return 8
        case .code128:
            return 16
        case .dataMatrix:
            return 32
        case .ean8:
            return 64
        case .ean13:
            return 128
        case .itf14:
            return 512
        case .pdf417:
            return 1024
        case .upce:
            return 4096
        default:
            return 0
        }
    }
}
