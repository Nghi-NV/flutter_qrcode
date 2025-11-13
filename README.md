# flutter_qrcode

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
  flutter_qrcode: ^0.0.1
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
import 'package:flutter_qrcode/flutter_qrcode.dart';

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
        overlay: CustomPaint(
          painter: ScannerOverlayPainter(),
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
import 'package:flutter_qrcode/flutter_qrcode.dart';
import 'package:image_picker/image_picker.dart';

Future<void> scanFromGallery() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    final barcodes = await FlutterQrcode.instance.scanImagePath(image.path);

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
import 'package:flutter_qrcode/flutter_qrcode.dart';
import 'dart:typed_data';

Future<void> scanFromBytes(Uint8List imageBytes) async {
  final barcodes = await FlutterQrcode.instance.scanImageBytes(imageBytes);

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
import 'package:flutter_qrcode/flutter_qrcode.dart';

Future<void> requestPermission() async {
  final hasPermission = await FlutterQrcode.instance.hasCameraPermission();

  if (!hasPermission) {
    final granted = await FlutterQrcode.instance.requestCameraPermission();

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

## Configuration Options

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
