## 0.0.2

* Rename package from `flutter_qrcode` to `lumi_qr_scanner`
* Update all class names: `FlutterQrcode` → `LumiQrScanner`, `FlutterQrcodePlatform` → `LumiQrScannerPlatform`, etc.
* Update plugin class names in native code (Android, iOS, macOS)
* Update GitHub repository URLs
* Fix Android plugin file naming to match class name

## 0.0.1

* Initial release
* Real-time camera scanning with QRScannerView widget
* Image scanning from file path and bytes
* Support for multiple barcode formats (QR Code, Aztec, Code128, EAN13, etc.)
* Camera permission handling
* Scanner controls (torch, pause/resume, switch camera)
* Bounding box and corner points detection
* Value type detection (URL, email, WiFi, phone, etc.)
* Platform support: Android (CameraX + ML Kit), iOS/macOS (AVFoundation + Vision)
* Customizable scanner overlay with ScannerOverlayConfig
  * Title, descriptions, and custom widgets
  * Configurable border colors, width, corner length, and border radius
  * Animated scan line (horizontal or vertical)
  * Toggle torch button with customizable position and styling
