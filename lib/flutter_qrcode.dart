import 'flutter_qrcode_platform_interface.dart';
import 'src/models/barcode.dart';

// Export models
export 'src/models/barcode.dart';
export 'src/models/barcode_format.dart';
export 'src/models/scanner_config.dart';

// Export widgets
export 'src/widgets/qr_scanner_view.dart';

/// Main class for Flutter QRCode plugin
class FlutterQrcode {
  static final FlutterQrcode _instance = FlutterQrcode._();

  FlutterQrcode._();

  /// Get singleton instance
  static FlutterQrcode get instance => _instance;

  /// Scan barcode/QR code from an image file
  ///
  /// [imagePath] - Path to the image file
  /// Returns a list of detected barcodes, or empty list if none found
  Future<List<Barcode>> scanImagePath(String imagePath) async {
    final result = await FlutterQrcodePlatform.instance.scanImagePath(imagePath);
    return result ?? [];
  }

  /// Scan barcode/QR code from image bytes
  ///
  /// [imageBytes] - Raw image bytes
  /// Returns a list of detected barcodes, or empty list if none found
  Future<List<Barcode>> scanImageBytes(List<int> imageBytes) async {
    final result = await FlutterQrcodePlatform.instance.scanImageBytes(imageBytes);
    return result ?? [];
  }

  /// Request camera permission
  ///
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestCameraPermission() {
    return FlutterQrcodePlatform.instance.requestCameraPermission();
  }

  /// Check if camera permission is granted
  ///
  /// Returns true if permission is granted, false otherwise
  Future<bool> hasCameraPermission() {
    return FlutterQrcodePlatform.instance.hasCameraPermission();
  }
}

