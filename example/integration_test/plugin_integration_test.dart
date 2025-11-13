// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hasCameraPermission test', (WidgetTester tester) async {
    final FlutterQrcode plugin = FlutterQrcode.instance;
    final bool hasPermission = await plugin.hasCameraPermission();
    // Just assert that the method returns a boolean value
    expect(hasPermission, isA<bool>());
  });
}
