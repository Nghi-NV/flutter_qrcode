import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'lumi_qr_scanner_platform_interface.dart';
import 'src/models/barcode.dart';

/// An implementation of [FlutterQrcodePlatform] that uses method channels.
class MethodChannelFlutterQrcode extends FlutterQrcodePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('lumi_qr_scanner');

  /// Recursively convert Map<Object?, Object?> to Map<String, dynamic>
  Map<String, dynamic> _convertMap(dynamic map) {
    if (map is! Map) return {};
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (key is String) {
        if (value is Map) {
          result[key] = _convertMap(value);
        } else if (value is List) {
          result[key] = _convertList(value);
        } else {
          result[key] = value;
        }
      }
    });
    return result;
  }

  /// Recursively convert List with nested Maps
  List<dynamic> _convertList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map) {
        return _convertMap(item);
      } else if (item is List) {
        return _convertList(item);
      }
      return item;
    }).toList();
  }

  @override
  Future<List<Barcode>?> scanImagePath(String imagePath) async {
    try {
      final result = await methodChannel.invokeMethod<List<dynamic>>(
        'scanImagePath',
        {'imagePath': imagePath},
      );
      if (result == null) return null;
      return result
          .map((e) => Barcode.fromJson(_convertMap(e)))
          .toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Barcode>?> scanImageBytes(List<int> imageBytes) async {
    try {
      final result = await methodChannel.invokeMethod<List<dynamic>>(
        'scanImageBytes',
        {'imageBytes': Uint8List.fromList(imageBytes)},
      );
      if (result == null) return null;
      return result
          .map((e) => Barcode.fromJson(_convertMap(e)))
          .toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> requestCameraPermission() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('requestCameraPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> hasCameraPermission() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('hasCameraPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
