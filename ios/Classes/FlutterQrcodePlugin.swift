import Flutter
import UIKit
import AVFoundation
import Vision

public class FlutterQrcodePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_qrcode", binaryMessenger: registrar.messenger())
    let instance = FlutterQrcodePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Register platform view
    let factory = QRScannerViewFactory(messenger: registrar.messenger())
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
    guard let image = UIImage(contentsOfFile: imagePath) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Failed to load image", details: nil))
      return
    }
    scanImage(image: image, result: result)
  }

  private func scanImageFromBytes(imageData: Data, result: @escaping FlutterResult) {
    guard let image = UIImage(data: imageData) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Failed to decode image", details: nil))
      return
    }
    scanImage(image: image, result: result)
  }

  private func scanImage(image: UIImage, result: @escaping FlutterResult) {
    guard let cgImage = image.cgImage else {
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

  private func barcodeToMap(observation: VNBarcodeObservation, imageSize: CGSize) -> [String: Any?] {
    let boundingBox = observation.boundingBox
    let rect = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))
    let valueTypeInfo = detectValueType(from: observation.payloadStringValue)

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
      "valueType": valueTypeInfo
    ]
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
    case .code39Checksum:
      return 4
    case .code39FullASCII:
      return 4
    case .code39FullASCIIChecksum:
      return 4
    case .code93:
      return 8
    case .code93i:
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
    return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
  }

  private func requestCameraPermission(result: @escaping FlutterResult) {
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
  }
}
