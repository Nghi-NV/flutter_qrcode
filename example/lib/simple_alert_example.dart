// Simple example showing how to display an alert when QR code is detected

import 'package:flutter/material.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';

/// Minimal example of QR scanning with alert dialog
class SimpleAlertExample extends StatefulWidget {
  const SimpleAlertExample({super.key});

  @override
  State<SimpleAlertExample> createState() => _SimpleAlertExampleState();
}

class _SimpleAlertExampleState extends State<SimpleAlertExample> {
  QRScannerController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple QR Alert Example'),
      ),
      body: QRScannerView(
        // Configure scanner for QR codes only
        config: const ScannerConfig(
          formats: [BarcodeFormat.qrCode],
          autoPauseAfterScan: true, // Pause after detecting QR code
        ),
        // Called when scanner is ready
        onScannerCreated: (controller) {
          _controller = controller;
        },
        // Called when QR code is detected - SHOW ALERT HERE
        onBarcodeScanned: (barcode) {
          _showQRCodeAlert(barcode);
        },
        // Overlay configuration with scan line animation
        overlayConfig: const ScannerOverlayConfig(
          title: 'Scan QR Code',
          topDescription: 'Point your camera at the QR code',
          bottomDescription: 'QR code will be detected automatically',
          borderColor: Colors.blue,
          showScanLine: true,
          scanLineDirection: ScanLineDirection.horizontal,
        ),
      ),
    );
  }

  /// Display alert dialog when QR code is detected
  void _showQRCodeAlert(Barcode barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Detected!'),
        content: Text(barcode.rawValue ?? 'No value'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Resume scanning for next QR code
              _controller?.resumeScanning();
            },
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 1: Basic Alert Dialog
// ============================================================================

void showBasicAlert(BuildContext context, Barcode barcode) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('QR Code Detected'),
      content: Text(barcode.rawValue ?? 'No value'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

// ============================================================================
// EXAMPLE 2: Styled Alert with Icon
// ============================================================================

void showStyledAlert(BuildContext context, Barcode barcode) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.qr_code_2, size: 60, color: Colors.green),
      title: const Text('Success!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            barcode.rawValue ?? 'No value',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Format: ${barcode.format.name}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
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

// ============================================================================
// EXAMPLE 3: SnackBar Alert (non-blocking)
// ============================================================================

void showSnackBarAlert(BuildContext context, Barcode barcode) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text('QR Code: ${barcode.rawValue}'),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'VIEW',
        textColor: Colors.white,
        onPressed: () {
          showBasicAlert(context, barcode);
        },
      ),
    ),
  );
}

// ============================================================================
// EXAMPLE 4: Bottom Sheet Alert
// ============================================================================

void showBottomSheetAlert(BuildContext context, Barcode barcode) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.qr_code_scanner, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'QR Code Detected!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              barcode.rawValue ?? 'No value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Format: ${barcode.format.name.toUpperCase()}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    ),
  );
}

// ============================================================================
// EXAMPLE 5: Custom Alert with Actions
// ============================================================================

void showCustomAlert(
  BuildContext context,
  Barcode barcode, {
  VoidCallback? onCopy,
  VoidCallback? onShare,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.qr_code_2, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          const Text('QR Code Detected'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: SelectableText(
              barcode.rawValue ?? 'No value',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Format: ${barcode.format.name.toUpperCase()}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onCopy?.call();
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onShare?.call();
          },
          icon: const Icon(Icons.share),
          label: const Text('Share'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

// ============================================================================
// EXAMPLE 6: Alert with Vibration and Sound Feedback
// ============================================================================

void showAlertWithFeedback(BuildContext context, Barcode barcode) {
  // Note: For vibration, add 'vibration' package to pubspec.yaml
  // For sound, add 'audioplayers' or similar package

  // Visual feedback
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.green[50],
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 48, color: Colors.white),
      ),
      title: const Text(
        'Scan Successful!',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            barcode.rawValue ?? 'No value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            barcode.format.name.toUpperCase(),
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Continue'),
          ),
        ),
      ],
    ),
  );
}
