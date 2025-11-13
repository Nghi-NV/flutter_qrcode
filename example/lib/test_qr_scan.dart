import 'package:flutter/material.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';
import 'package:image_picker/image_picker.dart';

/// Test page to verify QR code scanning from images works
class TestQRScanPage extends StatefulWidget {
  const TestQRScanPage({super.key});

  @override
  State<TestQRScanPage> createState() => _TestQRScanPageState();
}

class _TestQRScanPageState extends State<TestQRScanPage> {
  String _result = 'No scan yet';
  bool _isScanning = false;

  Future<void> _scanFromGallery() async {
    setState(() {
      _isScanning = true;
      _result = 'Selecting image...';
    });

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        setState(() {
          _result = 'No image selected';
          _isScanning = false;
        });
        return;
      }

      setState(() {
        _result = 'Scanning image...\nPath: ${image.path}';
      });

      final barcodes = await FlutterQrcode.instance.scanImagePath(image.path);

      setState(() {
        if (barcodes.isEmpty) {
          _result = '''
❌ No QR code found in image

This could mean:
1. The image doesn't contain a QR code
2. The QR code is too small or blurry
3. Poor image quality or contrast
4. QR code is damaged

Please try:
- A clearer image
- Larger QR code
- Better lighting when taking photo
- Generate a test QR code from: https://www.qr-code-generator.com
          ''';
        } else {
          _result = '''
✅ Found ${barcodes.length} QR code(s)!

${barcodes.map((b) => '''
Content: ${b.rawValue}
Format: ${b.format.name}
Type: ${b.valueType?.type.name ?? 'unknown'}
''').join('\n---\n')}
          ''';
        }
        _isScanning = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _result = '''
❌ Error scanning image:
$e

Stack trace:
$stackTrace
        ''';
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test QR Code Scanning'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Instructions:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Generate a test QR code at:\n'
                      '   https://www.qr-code-generator.com\n\n'
                      '2. Save the QR code image\n\n'
                      '3. Tap the button below to scan it\n\n'
                      '4. Select the saved QR code image',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _scanFromGallery,
              icon: _isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library),
              label: Text(_isScanning ? 'Scanning...' : 'Select Image from Gallery'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Result:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
