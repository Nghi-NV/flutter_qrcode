import Cocoa
import FlutterMacOS
import AVFoundation
import Vision

public class FlutterQrcodePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_qrcode", binaryMessenger: registrar.messenger)
    let instance = FlutterQrcodePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Register platform view
    let factory = QRScannerViewFactory(messenger: registrar.messenger)
    registrar.register(factory, withId: "plugins.flutter_qrcode/scanner_view")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "scanImagePath":
      guard let args = call.arguments as? [String: Any],
            let imagePath = args["imagePath"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Image path is required", details: nil))
        return
      }
      scanImageFromPath(imagePath: imagePath, result: result)

    case "scanImageBytes":
      guard let args = call.arguments as? [String: Any],
            let imageData = args["imageBytes"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Image bytes are required", details: nil))
        return
      }
      scanImageFromBytes(imageData: imageData.data, result: result)

    case "requestCameraPermission":
      requestCameraPermission(result: result)

    case "hasCameraPermission":
      result(hasCameraPermission())

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func scanImageFromPath(imagePath: String, result: @escaping FlutterResult) {
    guard let image = NSImage(contentsOfFile: imagePath) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Failed to load image", details: nil))
      return
    }
    scanImage(image: image, result: result)
  }

  private func scanImageFromBytes(imageData: Data, result: @escaping FlutterResult) {
    guard let image = NSImage(data: imageData) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Failed to decode image", details: nil))
      return
    }
    scanImage(image: image, result: result)
  }

  private func scanImage(image: NSImage, result: @escaping FlutterResult) {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Failed to get CGImage", details: nil))
      return
    }

    let request = VNDetectBarcodesRequest { request, error in
      if let error = error {
        result(FlutterError(code: "SCAN_ERROR", message: error.localizedDescription, details: nil))
        return
      }

      guard let observations = request.results as? [VNBarcodeObservation], !observations.isEmpty else {
        result(nil)
        return
      }

      let barcodes = observations.compactMap { observation -> [String: Any?]? in
        return self.barcodeToMap(observation: observation, imageSize: image.size)
      }

      result(barcodes)
    }

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([request])
    } catch {
      result(FlutterError(code: "SCAN_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  private func barcodeToMap(observation: VNBarcodeObservation, imageSize: NSSize) -> [String: Any?] {
    let boundingBox = observation.boundingBox
    let rect = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))

    return [
      "rawValue": observation.payloadStringValue,
      "format": barcodeFormatToInt(symbology: observation.symbology),
      "cornerPoints": nil,
      "boundingBox": [
        "left": Double(rect.minX),
        "top": Double(rect.minY),
        "right": Double(rect.maxX),
        "bottom": Double(rect.maxY)
      ],
      "valueType": [
        "type": 0,
        "data": nil
      ]
    ]
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

  private func hasCameraPermission() -> Bool {
    if #available(macOS 10.14, *) {
      return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    return true
  }

  private func requestCameraPermission(result: @escaping FlutterResult) {
    if #available(macOS 10.14, *) {
      let status = AVCaptureDevice.authorizationStatus(for: .video)

      switch status {
      case .authorized:
        result(true)
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
          DispatchQueue.main.async {
            result(granted)
          }
        }
      case .denied, .restricted:
        result(false)
      @unknown default:
        result(false)
      }
    } else {
      result(true)
    }
  }
}
