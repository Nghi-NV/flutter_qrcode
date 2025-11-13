import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelLumiQrScanner platform = MethodChannelLumiQrScanner();
  const MethodChannel channel = MethodChannel('lumi_qr_scanner');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'hasCameraPermission') {
          return true;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('hasCameraPermission', () async {
    expect(await platform.hasCameraPermission(), true);
  });
}
