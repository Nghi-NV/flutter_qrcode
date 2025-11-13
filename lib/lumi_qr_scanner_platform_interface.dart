import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'lumi_qr_scanner_method_channel.dart';
import 'src/models/barcode.dart';

abstract class FlutterQrcodePlatform extends PlatformInterface {
  /// Constructs a FlutterQrcodePlatform.
  FlutterQrcodePlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterQrcodePlatform _instance = MethodChannelFlutterQrcode();

  /// The default instance of [FlutterQrcodePlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterQrcode].
  static FlutterQrcodePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterQrcodePlatform] when
  /// they register themselves.
  static set instance(FlutterQrcodePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Scan barcode from an image file
  ///
  /// [imagePath] - Path to the image file
  /// Returns a list of detected barcodes, or null if none found
  Future<List<Barcode>?> scanImagePath(String imagePath) {
    throw UnimplementedError('scanImagePath() has not been implemented.');
  }

  /// Scan barcode from image bytes
  ///
  /// [imageBytes] - Raw image bytes
  /// Returns a list of detected barcodes, or null if none found
  Future<List<Barcode>?> scanImageBytes(List<int> imageBytes) {
    throw UnimplementedError('scanImageBytes() has not been implemented.');
  }

  /// Request camera permission
  ///
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestCameraPermission() {
    throw UnimplementedError('requestCameraPermission() has not been implemented.');
  }

  /// Check if camera permission is granted
  ///
  /// Returns true if permission is granted, false otherwise
  Future<bool> hasCameraPermission() {
    throw UnimplementedError('hasCameraPermission() has not been implemented.');
  }
}
