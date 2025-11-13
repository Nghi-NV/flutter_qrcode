import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner_platform_interface.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLumiQrScannerPlatform
    with MockPlatformInterfaceMixin
    implements LumiQrScannerPlatform {
  @override
  Future<List<Barcode>?> scanImagePath(String imagePath) async => [];

  @override
  Future<List<Barcode>?> scanImageBytes(List<int> imageBytes) async => [];

  @override
  Future<bool> requestCameraPermission() async => true;

  @override
  Future<bool> hasCameraPermission() async => true;
}

void main() {
  final LumiQrScannerPlatform initialPlatform = LumiQrScannerPlatform.instance;

  test('$MethodChannelLumiQrScanner is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLumiQrScanner>());
  });

  test('hasCameraPermission', () async {
    final lumiQrScannerPlugin = LumiQrScanner.instance;
    final fakePlatform = MockLumiQrScannerPlatform();
    LumiQrScannerPlatform.instance = fakePlatform;

    expect(await lumiQrScannerPlugin.hasCameraPermission(), true);
  });
}
