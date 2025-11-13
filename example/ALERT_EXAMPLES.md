# QR Code Alert Examples

This document explains how to show alerts when QR codes are detected using the lumi_qr_scanner plugin.

## Quick Start

The simplest way to show an alert when a QR code is detected:

```dart
QRScannerView(
  onBarcodeScanned: (barcode) {
    // Show alert when QR code is detected
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Detected!'),
        content: Text(barcode.rawValue ?? 'No value'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  },
)
```

## Alert Examples

### 1. Basic Alert Dialog

Simple alert dialog with title, content, and OK button:

```dart
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
```

**When to use:** Simple scenarios where you just need to display the QR code value.

### 2. Styled Alert with Icon

Enhanced alert with icon, colors, and formatted content:

```dart
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
```

**When to use:** When you want a more polished UI with visual feedback.

### 3. SnackBar Alert (Non-blocking)

Lightweight notification that doesn't block the UI:

```dart
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
          // Show detailed dialog
        },
      ),
    ),
  );
}
```

**When to use:** Continuous scanning where you don't want to interrupt the user flow.

### 4. Bottom Sheet Alert

Modern bottom sheet presentation:

```dart
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
          const Icon(Icons.qr_code_scanner, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'QR Code Detected!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(barcode.rawValue ?? 'No value'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}
```

**When to use:** Mobile-friendly design, especially for longer content.

### 5. Custom Alert with Actions

Alert with multiple action buttons (copy, share, etc.):

```dart
void showCustomAlert(
  BuildContext context,
  Barcode barcode, {
  VoidCallback? onCopy,
  VoidCallback? onShare,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('QR Code Detected'),
      content: SelectableText(barcode.rawValue ?? 'No value'),
      actions: [
        TextButton.icon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
        ),
        TextButton.icon(
          onPressed: onShare,
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
```

**When to use:** When you need to perform actions on the scanned QR code.

### 6. Alert with Feedback

Visual feedback with success styling:

```dart
void showAlertWithFeedback(BuildContext context, Barcode barcode) {
  showDialog(
    context: context,
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
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
      ),
      content: Text(barcode.rawValue ?? 'No value'),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
}
```

**When to use:** When you want to provide clear success feedback to users.

## Complete Example

See `simple_alert_example.dart` for a complete working example with all alert styles.

### Usage in Camera Scanner

```dart
class ScannerPage extends StatefulWidget {
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  QRScannerController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: QRScannerView(
        config: const ScannerConfig(
          formats: [BarcodeFormat.qrCode],
          autoPauseAfterScan: true, // Important: pause after scan
        ),
        onScannerCreated: (controller) {
          _controller = controller;
        },
        onBarcodeScanned: (barcode) {
          // Show your preferred alert style here
          _showAlert(barcode);
        },
      ),
    );
  }

  void _showAlert(Barcode barcode) {
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
```

### Usage with Image Picker

```dart
Future<void> scanFromGallery(BuildContext context) async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    final barcodes = await LumiQrScanner.instance.scanImagePath(image.path);

    if (barcodes.isEmpty) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR code found')),
      );
    } else {
      // Show alert with first detected QR code
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('QR Code Found!'),
          content: Text(barcodes.first.rawValue ?? 'No value'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
```

## Best Practices

1. **Auto-pause after scan**: Set `autoPauseAfterScan: true` in `ScannerConfig` to prevent multiple rapid scans.

2. **Resume scanning**: Call `controller.resumeScanning()` after dismissing the alert to continue scanning.

3. **Handle permission**: Always check camera permission before showing the scanner.

4. **Barcode validation**: Validate barcode content before performing actions.

5. **User feedback**: Provide clear visual feedback (icons, colors) to indicate success or failure.

6. **Selectable text**: Use `SelectableText` for QR code content so users can copy it.

## Configuration Options

The `ScannerConfig` provides options to customize the scanning experience:

```dart
ScannerConfig(
  formats: [BarcodeFormat.qrCode],        // Which formats to scan
  autoFocus: true,                         // Enable auto-focus
  autoPauseAfterScan: true,               // Pause after detecting QR code
  vibrateOnSuccess: true,                  // Vibrate on successful scan
  beepOnSuccess: false,                    // Beep on successful scan
  scanDelay: 500,                          // Delay between scans (ms)
)
```

## Handling Different QR Code Types

The `Barcode` object provides information about the detected code:

```dart
void handleBarcode(Barcode barcode) {
  // Check value type
  switch (barcode.valueType?.type) {
    case BarcodeValueTypeKind.url:
      // Handle URL
      launchUrl(barcode.rawValue!);
      break;
    case BarcodeValueTypeKind.wifi:
      // Handle WiFi credentials
      showWifiDialog(barcode);
      break;
    case BarcodeValueTypeKind.email:
      // Handle email
      composeEmail(barcode.rawValue!);
      break;
    default:
      // Handle as text
      showTextDialog(barcode);
  }
}
```

## Troubleshooting

**Alert not showing:**
- Ensure `context.mounted` is true before showing dialog
- Check that you're using a valid BuildContext

**Multiple alerts appearing:**
- Set `autoPauseAfterScan: true` in ScannerConfig
- Implement a debounce mechanism if needed

**Can't scan after alert:**
- Call `controller.resumeScanning()` after dismissing the alert
- Ensure controller is not disposed

## See Also

- `main.dart` - Full-featured example with camera and gallery scanning
- `simple_alert_example.dart` - Minimal example focusing on alerts
- Plugin documentation: Check README.md for complete API reference
