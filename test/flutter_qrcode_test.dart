import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner_platform_interface.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterQrcodePlatform
    with MockPlatformInterfaceMixin
    implements FlutterQrcodePlatform {
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
  final FlutterQrcodePlatform initialPlatform = FlutterQrcodePlatform.instance;

  test('$MethodChannelFlutterQrcode is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterQrcode>());
  });

  test('hasCameraPermission', () async {
    final flutterQrcodePlugin = FlutterQrcode.instance;
    final fakePlatform = MockFlutterQrcodePlatform();
    FlutterQrcodePlatform.instance = fakePlatform;

    expect(await flutterQrcodePlugin.hasCameraPermission(), true);
  });
}
