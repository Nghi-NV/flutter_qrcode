import 'lumi_qr_scanner_platform_interface.dart';
import 'src/models/barcode.dart';

// Export models
export 'src/models/barcode.dart';
export 'src/models/barcode_format.dart';
export 'src/models/scanner_config.dart';
export 'src/models/scanner_overlay_config.dart'
    show ScannerOverlayConfig, ScanLineDirection;

// Export widgets
export 'src/widgets/qr_scanner_view.dart';
export 'src/widgets/scanner_overlay.dart';

/// Main class for Lumi QR Scanner plugin
class LumiQrScanner {
  static final LumiQrScanner _instance = LumiQrScanner._();

  LumiQrScanner._();

  /// Get singleton instance
  static LumiQrScanner get instance => _instance;

  /// Scan barcode/QR code from an image file
  ///
  /// [imagePath] - Path to the image file
  /// Returns a list of detected barcodes, or empty list if none found
  Future<List<Barcode>> scanImagePath(String imagePath) async {
    final result = await LumiQrScannerPlatform.instance.scanImagePath(
      imagePath,
    );
    return result ?? [];
  }

  /// Scan barcode/QR code from image bytes
  ///
  /// [imageBytes] - Raw image bytes
  /// Returns a list of detected barcodes, or empty list if none found
  Future<List<Barcode>> scanImageBytes(List<int> imageBytes) async {
    final result = await LumiQrScannerPlatform.instance.scanImageBytes(
      imageBytes,
    );
    return result ?? [];
  }

  /// Request camera permission
  ///
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestCameraPermission() {
    return LumiQrScannerPlatform.instance.requestCameraPermission();
  }

  /// Check if camera permission is granted
  ///
  /// Returns true if permission is granted, false otherwise
  Future<bool> hasCameraPermission() {
    return LumiQrScannerPlatform.instance.hasCameraPermission();
  }
}
