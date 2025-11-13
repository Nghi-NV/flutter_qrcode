# Bounding Box Guide

This guide explains how to use the bounding box coordinates from detected QR codes to draw overlays or perform position-based actions.

## Understanding Coordinate Systems

Different platforms return bounding boxes in different coordinate systems:

### Android
- **Coordinate type**: Pixel coordinates
- **Origin**: Top-left (0, 0)
- **Range**: Actual pixel values based on camera resolution
- **Example**: `{left: 100, top: 200, right: 300, bottom: 400}`

### iOS/macOS
- **Coordinate type**: Normalized coordinates (0.0 to 1.0)
- **Origin**: Bottom-left (0, 0)
- **Range**: 0.0 to 1.0 (relative to image dimensions)
- **Example**: `{left: 0.1, top: 0.2, right: 0.3, bottom: 0.4}`

## BarcodeRect API

The `BarcodeRect` class provides several helper methods:

### Basic Properties

```dart
final rect = barcode.boundingBox;
print('Position: ${rect?.left}, ${rect?.top}');
print('Size: ${rect?.width} x ${rect?.height}');
print('Center: ${rect?.center}');
```

### Converting to Flutter Rect

```dart
// Get Flutter Rect for rendering
final rect = barcode.boundingBox?.toRect();
canvas.drawRect(rect, paint);
```

### Denormalizing iOS Coordinates

iOS returns normalized coordinates that need to be converted:

```dart
import 'dart:io' show Platform;

BarcodeRect? rect = barcode.boundingBox;

if (Platform.isIOS && rect != null) {
  // Check if coordinates are normalized (0-1 range)
  if (rect.right <= 1.0 && rect.bottom <= 1.0) {
    rect = rect.denormalize(
      width: previewWidth,   // Camera preview width
      height: previewHeight, // Camera preview height
      flipVertical: true,    // iOS has origin at bottom-left
    );
  }
}
```

### Scaling to Screen Size

If your widget size differs from the camera preview:

```dart
final screenRect = barcode.boundingBox?.scaleToSize(
  fromWidth: 1920,  // Camera preview width
  fromHeight: 1080, // Camera preview height
  toWidth: 400,     // Widget width on screen
  toHeight: 300,    // Widget height on screen
);
```

## Drawing Bounding Box Overlays

### Simple Rectangle

```dart
class SimpleBoundingBoxOverlay extends StatelessWidget {
  final Barcode barcode;
  final Size previewSize;

  const SimpleBoundingBoxOverlay({
    required this.barcode,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SimpleBoundingBoxPainter(
        barcode: barcode,
        previewSize: previewSize,
      ),
      size: Size.infinite,
    );
  }
}

class SimpleBoundingBoxPainter extends CustomPainter {
  final Barcode barcode;
  final Size previewSize;

  SimpleBoundingBoxPainter({
    required this.barcode,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (barcode.boundingBox == null) return;

    var rect = barcode.boundingBox!;

    // Handle iOS normalized coordinates
    if (Platform.isIOS && rect.right <= 1.0) {
      rect = rect.denormalize(
        width: previewSize.width,
        height: previewSize.height,
        flipVertical: true,
      );
    }

    // Draw rectangle
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect.toRect(), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

### Complete Example with Overlay

```dart
class ScannerWithBoundingBox extends StatefulWidget {
  @override
  State<ScannerWithBoundingBox> createState() => _ScannerWithBoundingBoxState();
}

class _ScannerWithBoundingBoxState extends State<ScannerWithBoundingBox> {
  QRScannerController? _controller;
  Barcode? _detectedBarcode;
  final GlobalKey _previewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera preview
        QRScannerView(
          key: _previewKey,
          config: const ScannerConfig(
            autoPauseAfterScan: false, // Keep scanning
          ),
          onBarcodeScanned: (barcode) {
            setState(() {
              _detectedBarcode = barcode;
            });
          },
        ),
        // Bounding box overlay
        if (_detectedBarcode != null)
          CustomPaint(
            painter: BoundingBoxPainter(
              barcode: _detectedBarcode!,
              previewSize: _getPreviewSize(),
            ),
            size: Size.infinite,
          ),
      ],
    );
  }

  Size _getPreviewSize() {
    final RenderBox? renderBox =
        _previewKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size ?? Size.zero;
  }
}
```

## Advanced Examples

### Drawing Corner Markers

```dart
void _drawCornerMarkers(Canvas canvas, Rect rect) {
  final paint = Paint()
    ..color = Colors.green
    ..strokeWidth = 4
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  const cornerLength = 20.0;

  // Top-left
  canvas.drawLine(
    Offset(rect.left, rect.top),
    Offset(rect.left + cornerLength, rect.top),
    paint,
  );
  canvas.drawLine(
    Offset(rect.left, rect.top),
    Offset(rect.left, rect.top + cornerLength),
    paint,
  );

  // Repeat for other corners...
}
```

### Animated Bounding Box

```dart
class AnimatedBoundingBoxPainter extends CustomPainter {
  final Barcode barcode;
  final Size previewSize;
  final Animation<double> animation;

  AnimatedBoundingBoxPainter({
    required this.barcode,
    required this.previewSize,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (barcode.boundingBox == null) return;

    var rect = barcode.boundingBox!;

    // Handle iOS coordinates
    if (Platform.isIOS && rect.right <= 1.0) {
      rect = rect.denormalize(
        width: previewSize.width,
        height: previewSize.height,
        flipVertical: true,
      );
    }

    // Pulsing effect
    final opacity = 0.5 + (animation.value * 0.5);

    final paint = Paint()
      ..color = Colors.green.withOpacity(opacity)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect.toRect(), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Usage
class _MyState extends State<MyWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AnimatedBoundingBoxPainter(
        barcode: _barcode,
        previewSize: _previewSize,
        animation: _animationController,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
```

### Multiple QR Codes

```dart
class MultipleBoundingBoxPainter extends CustomPainter {
  final List<Barcode> barcodes;
  final Size previewSize;

  MultipleBoundingBoxPainter({
    required this.barcodes,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var barcode in barcodes) {
      if (barcode.boundingBox == null) continue;

      var rect = barcode.boundingBox!;

      // Handle iOS coordinates
      if (Platform.isIOS && rect.right <= 1.0) {
        rect = rect.denormalize(
          width: previewSize.width,
          height: previewSize.height,
          flipVertical: true,
        );
      }

      // Draw each barcode
      final paint = Paint()
        ..color = Colors.green
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawRect(rect.toRect(), paint);

      // Draw label
      _drawLabel(canvas, rect.toRect(), barcode.rawValue ?? '');
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );
    textPainter.layout(maxWidth: rect.width);

    // Background
    final bgRect = Rect.fromLTWH(
      rect.left,
      rect.top - 16,
      textPainter.width + 4,
      14,
    );
    canvas.drawRect(bgRect, Paint()..color = Colors.green);

    // Text
    textPainter.paint(canvas, Offset(rect.left + 2, rect.top - 15));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

## Common Issues and Solutions

### Issue 1: Bounding box not showing

**Problem**: The overlay doesn't appear on the screen.

**Solutions**:
1. Check that `boundingBox` is not null
2. Verify preview size is calculated correctly
3. Ensure CustomPaint widget is in the Stack above the camera

```dart
// ✓ Correct
Stack(
  children: [
    QRScannerView(...),
    CustomPaint(...), // On top
  ],
)

// ✗ Wrong order
Stack(
  children: [
    CustomPaint(...),
    QRScannerView(...), // Covers the overlay
  ],
)
```

### Issue 2: Wrong position on iOS

**Problem**: Bounding box appears upside down or in wrong position.

**Solution**: Always use `flipVertical: true` when denormalizing iOS coordinates:

```dart
if (Platform.isIOS) {
  rect = rect.denormalize(
    width: previewSize.width,
    height: previewSize.height,
    flipVertical: true, // Important!
  );
}
```

### Issue 3: Coordinates out of bounds

**Problem**: Bounding box extends outside the visible area.

**Solution**: Ensure you're using the correct preview size:

```dart
// Get actual rendered size
Size _getPreviewSize() {
  final RenderBox? renderBox =
      _previewKey.currentContext?.findRenderObject() as RenderBox?;
  return renderBox?.size ?? Size.zero;
}

// Use GlobalKey
QRScannerView(
  key: _previewKey, // Add this
  ...
)
```

### Issue 4: Different sizes on Android/iOS

**Problem**: Camera preview has different resolutions.

**Solution**: Scale coordinates based on actual camera resolution:

```dart
// If you know the camera resolution
final scaledRect = rect.scaleToSize(
  fromWidth: cameraWidth,
  fromHeight: cameraHeight,
  toWidth: widgetWidth,
  toHeight: widgetHeight,
);
```

## Best Practices

1. **Always check for null**: `boundingBox` can be null
2. **Handle platform differences**: Use `Platform.isIOS` checks
3. **Use GlobalKey**: To get accurate widget sizes
4. **Test on both platforms**: iOS and Android behave differently
5. **Consider aspect ratio**: Camera and screen may have different ratios
6. **Performance**: Use `autoPauseAfterScan: false` carefully (may impact performance)

## Complete Working Example

See `example/lib/bounding_box_example.dart` for a complete, working example with:
- Platform-specific coordinate handling
- Multiple overlay styles
- Animated bounding boxes
- Corner markers and labels
- Info panel showing position and size

Run the example:
```bash
cd example
flutter run
```

Then tap "Bounding Box Example" to see it in action!
