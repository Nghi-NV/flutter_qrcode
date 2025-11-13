import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qrcode/flutter_qrcode.dart';
import 'package:flutter_qrcode/flutter_qrcode_platform_interface.dart';
import 'package:flutter_qrcode/flutter_qrcode_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterQrcodePlatform
    with MockPlatformInterfaceMixin
    implements FlutterQrcodePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterQrcodePlatform initialPlatform = FlutterQrcodePlatform.instance;

  test('$MethodChannelFlutterQrcode is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterQrcode>());
  });

  test('getPlatformVersion', () async {
    FlutterQrcode flutterQrcodePlugin = FlutterQrcode();
    MockFlutterQrcodePlatform fakePlatform = MockFlutterQrcodePlatform();
    FlutterQrcodePlatform.instance = fakePlatform;

    expect(await flutterQrcodePlugin.getPlatformVersion(), '42');
  });
}
