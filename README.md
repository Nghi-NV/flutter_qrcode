# lumi_qr_scanner

A fast and lightweight Flutter plugin for scanning barcodes and QR codes using the device's camera. Supports multiple barcode formats, real-time detection, and customization options for an optimized scanning experience on Android, iOS, and macOS.

## Features

- **Fast & Lightweight**: Optimized for performance with minimal dependencies
- **Real-time Camera Scanning**: Live barcode/QR code detection with customizable camera preview
- **Image Scanning**: Scan barcodes from images in the device's gallery or from memory
- **Multiple Barcode Formats**: Supports QR Code, Aztec, Codabar, Code 39, Code 93, Code 128, Data Matrix, EAN-8, EAN-13, ITF, PDF417, UPC-A, and UPC-E
- **Platform Native Implementation**:
  - **Android**: CameraX + ML Kit Barcode Scanning
  - **iOS/macOS**: AVFoundation + Vision Framework
- **Customizable**: Configure scan delay, auto-focus, torch/flash, vibration, and more
- **Easy to Use**: Simple API with minimal setup required

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  lumi_qr_scanner: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.VIBRATE" />

<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

**Minimum SDK**: API level 21 (Android 5.0)

### iOS

Add the following keys to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes</string>
```

**Minimum iOS version**: 12.0

### macOS

Add the following keys to your `macos/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes</string>
```

Also, enable camera entitlement in `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.device.camera</key>
<true/>
```

**Minimum macOS version**: 10.14

## Usage

### 1. Camera Scanning

```dart
import 'package:flutter/material.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  QRScannerController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: QRScannerView(
        config: const ScannerConfig(
          formats: [BarcodeFormat.qrCode],
          autoFocus: true,
          enableTorch: false,
          vibrateOnSuccess: true,
          autoPauseAfterScan: true,
        ),
        onScannerCreated: (controller) {
          _controller = controller;
        },
        onBarcodeScanned: (barcode) {
          // Handle scanned barcode
          final value = barcode.rawValue;
          final format = barcode.format.name;
          // Do something with the scanned data
        },
        overlayConfig: const ScannerOverlayConfig(
          title: 'Scan QR Code',
          topDescription: 'Position the QR code within the frame',
          bottomDescription: 'Make sure the QR code is clearly visible',
          borderColor: Colors.green,
          borderWidth: 4.0,
          cornerLength: 30.0,
        ),
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

### 2. Scan from Image

```dart
import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';
import 'package:image_picker/image_picker.dart';

Future<void> scanFromGallery() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    final barcodes = await LumiQrScanner.instance.scanImagePath(image.path);

    if (barcodes.isNotEmpty) {
      // Process found barcodes
      for (var barcode in barcodes) {
        final value = barcode.rawValue;
        final format = barcode.format.name;
        // Do something with the barcode data
      }
    }
  }
}
```

### 3. Scan from Image Bytes

```dart
import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';
import 'dart:typed_data';

Future<void> scanFromBytes(Uint8List imageBytes) async {
  final barcodes = await LumiQrScanner.instance.scanImageBytes(imageBytes);

  if (barcodes.isNotEmpty) {
    for (var barcode in barcodes) {
      // Process barcode
      final value = barcode.rawValue;
    }
  }
}
```

### 4. Request Camera Permission

```dart
import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';

Future<void> requestPermission() async {
  final hasPermission = await LumiQrScanner.instance.hasCameraPermission();

  if (!hasPermission) {
    final granted = await LumiQrScanner.instance.requestCameraPermission();

    if (granted) {
      // Camera permission granted, proceed with scanning
    } else {
      // Handle permission denied
    }
  }
}
```

### 5. Scanner Controller Methods

The `QRScannerController` provides methods to control the scanner:

```dart
// Start/stop scanning
await _controller?.startScanning();
await _controller?.stopScanning();

// Pause/resume scanning
await _controller?.pauseScanning();
await _controller?.resumeScanning();

// Toggle torch/flash
await _controller?.toggleTorch();
await _controller?.setTorch(true);

// Switch between front and back camera
await _controller?.switchCamera();
```

## Overlay Configuration Options

The `ScannerOverlayConfig` class provides various UI customization options for the scanner overlay:

```dart
ScannerOverlayConfig(
  // Title text displayed at the top
  title: 'Scan QR Code',

  // Top description text (above scan area)
  topDescription: 'Position the QR code within the frame',

  // Bottom description text (below scan area)
  bottomDescription: 'Make sure the QR code is clearly visible',

  // Custom widget to display at the top (replaces title if provided)
  topWidget: CustomWidget(),

  // Custom widget to display at the bottom (replaces bottom description if provided)
  bottomWidget: CustomWidget(),

  // Color of the scan frame border (default: Colors.green)
  borderColor: Colors.blue,

  // Width of the scan frame border (default: 4.0)
  borderWidth: 3.0,

  // Length of corner indicators (default: 30.0)
  cornerLength: 25.0,

  // Size of the scan area as a fraction of screen width 0.0-1.0 (default: 0.7)
  scanAreaSize: 0.8,

  // Color of the overlay background (default: Colors.black54)
  overlayColor: Colors.black.withOpacity(0.5),

  // Border radius of the scan area (default: 0.0)
  borderRadius: 12.0,

  // Whether to show corner indicators (default: true)
  showCorners: true,

  // Whether to show the overlay background (default: true)
  showOverlay: true,

  // Text styles for title and descriptions
  titleStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  topDescriptionStyle: TextStyle(fontSize: 16),
  bottomDescriptionStyle: TextStyle(fontSize: 14),

  // Scan line animation options
  showScanLine: true,                    // Enable animated scan line (default: false)
  scanLineDirection: ScanLineDirection.horizontal,  // horizontal or vertical
  scanLineColor: Colors.green,           // Color of the scan line
  scanLineWidth: 2.0,                    // Thickness of the scan line
  scanLineDuration: Duration(milliseconds: 2000),  // Animation speed
)
```

### Advanced Overlay Example

```dart
QRScannerView(
  config: const ScannerConfig(
    formats: [BarcodeFormat.qrCode],
  ),
  overlayConfig: ScannerOverlayConfig(
    title: 'Scan QR Code',
    topDescription: 'Align QR code within the frame',
    bottomDescription: 'Keep the code steady for best results',
    borderColor: Colors.blue,
    borderWidth: 3.0,
    cornerLength: 30.0,
    scanAreaSize: 0.75,
    borderRadius: 16.0,
    overlayColor: Colors.black.withOpacity(0.6),
    // Enable animated scan line
    showScanLine: true,
    scanLineDirection: ScanLineDirection.horizontal,
    scanLineColor: Colors.blue,
    scanLineWidth: 2.0,
    scanLineDuration: Duration(milliseconds: 2000),
  ),
  onBarcodeScanned: (barcode) {
    // Handle scanned barcode
  },
)
```

### Scan Line Animation Examples

**Horizontal scan line (top to bottom):**
```dart
overlayConfig: ScannerOverlayConfig(
  showScanLine: true,
  scanLineDirection: ScanLineDirection.horizontal,
  scanLineColor: Colors.green,
  scanLineWidth: 2.0,
  scanLineDuration: Duration(milliseconds: 2000),
)
```

**Vertical scan line (left to right):**
```dart
overlayConfig: ScannerOverlayConfig(
  showScanLine: true,
  scanLineDirection: ScanLineDirection.vertical,
  scanLineColor: Colors.blue,
  scanLineWidth: 3.0,
  scanLineDuration: Duration(milliseconds: 1500),
)
```

### Custom Widget Overlay

You can also use custom widgets instead of text:

```dart
QRScannerView(
  overlayConfig: ScannerOverlayConfig(
    topWidget: Column(
      children: [
        Icon(Icons.qr_code_scanner, size: 48, color: Colors.white),
        SizedBox(height: 8),
        Text('Scan QR Code', style: TextStyle(color: Colors.white, fontSize: 20)),
      ],
    ),
    bottomWidget: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, color: Colors.white70, size: 16),
        SizedBox(width: 4),
        Text('Point camera at QR code', style: TextStyle(color: Colors.white70)),
      ],
    ),
    borderColor: Colors.blue,
  ),
  onBarcodeScanned: (barcode) {
    // Handle scanned barcode
  },
)
```

## Scanner Configuration Options

The `ScannerConfig` class provides various customization options:

```dart
ScannerConfig(
  // Barcode formats to scan (default: [BarcodeFormat.all])
  formats: [BarcodeFormat.qrCode, BarcodeFormat.ean13],

  // Enable auto focus (default: true)
  autoFocus: true,

  // Enable torch/flash (default: false)
  enableTorch: false,

  // Delay between scans in milliseconds (default: 500)
  scanDelay: 500,

  // Use front camera (default: false)
  useFrontCamera: false,

  // Beep on successful scan (default: false)
  beepOnSuccess: false,

  // Vibrate on successful scan (default: true)
  vibrateOnSuccess: true,

  // Automatically pause after successful scan (default: false)
  autoPauseAfterScan: false,
)
```

## Supported Barcode Formats

- `BarcodeFormat.qrCode` - QR Code 2D barcode
- `BarcodeFormat.aztec` - Aztec 2D barcode
- `BarcodeFormat.codabar` - Codabar 1D format
- `BarcodeFormat.code39` - Code 39 1D format
- `BarcodeFormat.code93` - Code 93 1D format
- `BarcodeFormat.code128` - Code 128 1D format
- `BarcodeFormat.dataMatrix` - Data Matrix 2D barcode
- `BarcodeFormat.ean8` - EAN-8 1D format
- `BarcodeFormat.ean13` - EAN-13 1D format
- `BarcodeFormat.itf` - ITF (Interleaved Two of Five) 1D format
- `BarcodeFormat.pdf417` - PDF417 format
- `BarcodeFormat.upcA` - UPC-A 1D format
- `BarcodeFormat.upcE` - UPC-E 1D format
- `BarcodeFormat.all` - All supported formats

## Barcode Result

The `Barcode` class contains information about the scanned barcode:

```dart
class Barcode {
  final String? rawValue;           // The raw value of the barcode
  final BarcodeFormat format;        // The format of the barcode
  final List<BarcodePoint>? cornerPoints;  // Corner points of the barcode
  final BarcodeRect? boundingBox;    // Bounding box of the barcode
  final BarcodeValueType? valueType; // Additional type-specific data
}
```

## Example

Check out the [example](example/) directory for a complete working example that demonstrates:

- Camera scanning with custom overlay
- Image scanning from gallery
- Permission handling
- Scanner controls (torch, pause/resume)

## Performance

This plugin is optimized for performance:

- **Scan Delay**: Configurable delay between scans to prevent duplicate detections
- **Native Implementation**: Uses platform-native libraries (CameraX/ML Kit on Android, AVFoundation/Vision on iOS/macOS)
- **Lightweight**: Minimal dependencies and overhead

## Troubleshooting

### Camera not working on iOS/macOS

Make sure you've added the `NSCameraUsageDescription` key to your `Info.plist` file.

### Permission denied on Android

Check that you've added the camera permission to your `AndroidManifest.xml` file.

### Build errors on Android

Make sure your `minSdk` is set to at least 21 in `android/app/build.gradle`:

```gradle
defaultConfig {
    minSdk 21
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
