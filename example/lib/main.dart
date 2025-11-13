import 'package:flutter/material.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';
import 'package:image_picker/image_picker.dart';

import 'bounding_box_example.dart';
import 'test_qr_scan.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter QRCode Scanner',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter QRCode Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 100, color: Colors.blue),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScannerPage()),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan QR Code with Camera'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BoundingBoxExample(),
                  ),
                );
              },
              icon: const Icon(Icons.crop_free),
              label: const Text('Bounding Box Example'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestQRScanPage(),
                  ),
                );
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Test QR Scan (Debug)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                // Example: Scan QR code from gallery and show alert
                final picker = ImagePicker();
                try {
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (image == null) {
                    debugPrint('No image selected');
                    return;
                  }

                  if (!context.mounted) return;

                  debugPrint('Image selected: ${image.path}');

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) =>
                            const Center(child: CircularProgressIndicator()),
                  );

                  // Scan the selected image for QR codes
                  final barcodes = await FlutterQrcode.instance.scanImagePath(
                    image.path,
                  );

                  if (!context.mounted) return;

                  // Close loading dialog
                  Navigator.pop(context);

                  debugPrint('Found ${barcodes.length} barcodes');

                  if (barcodes.isEmpty) {
                    // Show detailed error message if no QR code found
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'No QR code found in image',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Possible reasons:',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '• QR code is too small or blurry',
                              style: TextStyle(fontSize: 11),
                            ),
                            Text(
                              '• Poor contrast or lighting',
                              style: TextStyle(fontSize: 11),
                            ),
                            Text(
                              '• QR code is damaged or incomplete',
                              style: TextStyle(fontSize: 11),
                            ),
                            Text(
                              '• Try a different image or angle',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red.shade700,
                        duration: const Duration(seconds: 6),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    // Show alert dialog with detected QR codes
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            icon: const Icon(
                              Icons.photo_library,
                              size: 48,
                              color: Colors.blue,
                            ),
                            title: Text(
                              'Found ${barcodes.length} QR Code${barcodes.length > 1 ? 's' : ''}!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    barcodes.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final barcode = entry.value;
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (barcodes.length > 1)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: Text(
                                                  'QR Code ${index + 1}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                            SelectableText(
                                              barcode.rawValue ?? 'No value',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Format: ${barcode.format.name.toUpperCase()}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                            actions: [
                              FilledButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    );
                  }
                } catch (e, stackTrace) {
                  debugPrint('Error scanning image: $e');
                  debugPrint('Stack trace: $stackTrace');

                  if (context.mounted) {
                    // Close loading dialog if open
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).popUntil((route) => route.isFirst);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Scan QR Code from Gallery'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  QRScannerController? _controller;
  bool _isTorchOn = false;
  bool _hasPermission = false;
  String? _scannedCode;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await FlutterQrcode.instance.hasCameraPermission();
    if (!hasPermission) {
      final granted = await FlutterQrcode.instance.requestCameraPermission();
      setState(() {
        _hasPermission = granted;
      });
    } else {
      setState(() {
        _hasPermission = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _controller?.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
        ],
      ),
      body:
          !_hasPermission
              ? const Center(
                child: Text('Camera permission is required to scan QR codes'),
              )
              : Stack(
                children: [
                  QRScannerView(
                    config: const ScannerConfig(
                      formats: [BarcodeFormat.qrCode],
                      autoFocus: true,
                      vibrateOnSuccess: true,
                      autoPauseAfterScan: true,
                    ),
                    onScannerCreated: (controller) {
                      _controller = controller;
                    },
                    onBarcodeScanned: (barcode) {
                      setState(() {
                        _scannedCode = barcode.rawValue;
                      });
                      _showResultDialog(barcode);
                    },
                    overlayConfig: ScannerOverlayConfig(
                      title: 'Scan QR Code',
                      topDescription: 'Position the QR code within the frame',
                      bottomDescription:
                          'Keep the code steady for best results',
                      showToggleTorchButton: true,
                      onToggleTorch: () {
                        _controller?.toggleTorch();
                      },
                      // borderColor: Colors.green,
                      // borderWidth: 2.0,
                      // cornerLength: 30.0,
                      // scanAreaSize: 0.7,
                      // showScanLine: true,
                      // scanLineDirection: ScanLineDirection.vertical,
                      // scanLineColor: Colors.green,
                      // scanLineWidth: 2.0,
                      // scanLineDuration: Duration(milliseconds: 2000),
                    ),
                  ),
                  if (_scannedCode != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.black87,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Last scanned:',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _scannedCode!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _controller?.resumeScanning();
                                setState(() {
                                  _scannedCode = null;
                                });
                              },
                              child: const Text('Scan Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
    );
  }

  void _showResultDialog(Barcode barcode) {
    // Example: Show alert dialog when QR code is detected
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder:
          (context) => AlertDialog(
            icon: const Icon(Icons.qr_code_2, size: 48, color: Colors.green),
            title: const Text(
              'QR Code Detected!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Content:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    barcode.rawValue ?? 'No value',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Format: ${barcode.format.name.toUpperCase()}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                if (barcode.valueType != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Type: ${barcode.valueType!.type.name}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _controller?.resumeScanning();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Done'),
              ),
            ],
            actionsPadding: const EdgeInsets.all(16),
            actionsAlignment: MainAxisAlignment.spaceBetween,
          ),
    );

    // Alternative examples of showing alerts:
    //
    // 1. Simple SnackBar (uncomment to use):
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('QR Code: ${barcode.rawValue}'),
    //     duration: const Duration(seconds: 3),
    //     action: SnackBarAction(
    //       label: 'OK',
    //       onPressed: () {},
    //     ),
    //   ),
    // );
    //
    // 2. Bottom Sheet (uncomment to use):
    // showModalBottomSheet(
    //   context: context,
    //   builder: (context) => Container(
    //     padding: const EdgeInsets.all(24),
    //     child: Column(
    //       mainAxisSize: MainAxisSize.min,
    //       children: [
    //         const Icon(Icons.qr_code_scanner, size: 64, color: Colors.blue),
    //         const SizedBox(height: 16),
    //         const Text('QR Code Detected!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    //         const SizedBox(height: 8),
    //         Text(barcode.rawValue ?? 'No value', textAlign: TextAlign.center),
    //         const SizedBox(height: 24),
    //         ElevatedButton(
    //           onPressed: () => Navigator.pop(context),
    //           child: const Text('Close'),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
