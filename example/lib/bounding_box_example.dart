// Example showing how to draw bounding box overlay on detected QR codes

import 'package:flutter/material.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';

/// Example showing bounding box overlay when QR code is detected
class BoundingBoxExample extends StatefulWidget {
  const BoundingBoxExample({super.key});

  @override
  State<BoundingBoxExample> createState() => _BoundingBoxExampleState();
}

class _BoundingBoxExampleState extends State<BoundingBoxExample> {
  QRScannerController? _controller;
  Barcode? _detectedBarcode;
  final GlobalKey _previewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bounding Box Example'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera preview
          QRScannerView(
            key: _previewKey,
            config: const ScannerConfig(
              formats: [BarcodeFormat.qrCode],
              autoPauseAfterScan: false, // Keep scanning to show overlay
              vibrateOnSuccess: false,
            ),
            onScannerCreated: (controller) {
              _controller = controller;
            },
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
          // Info panel
          if (_detectedBarcode != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black87,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detected QR Code:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _detectedBarcode!.rawValue ?? 'No value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_detectedBarcode!.boundingBox != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Position: ${_detectedBarcode!.boundingBox!.left.toInt()}, '
                        '${_detectedBarcode!.boundingBox!.top.toInt()}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Size: ${_detectedBarcode!.boundingBox!.width.toInt()} x '
                        '${_detectedBarcode!.boundingBox!.height.toInt()}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Size _getPreviewSize() {
    final RenderBox? renderBox =
        _previewKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size ?? Size.zero;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// Custom painter to draw bounding box
class BoundingBoxPainter extends CustomPainter {
  final Barcode barcode;
  final Size previewSize;

  BoundingBoxPainter({
    required this.barcode,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (previewSize == Size.zero) return;

    // Use the new helper method that handles both platforms automatically
    final boundingBox = barcode.getScaledBoundingBox(
      screenWidth: previewSize.width,
      screenHeight: previewSize.height,
    );

    if (boundingBox == null) return;

    final rect = boundingBox.toRect();

    // Draw semi-transparent background
    final bgPaint = Paint()
      ..color = Colors.green.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, bgPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - cornerLength),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );

    // Draw center point
    final centerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(rect.center.dx, rect.center.dy),
      6,
      centerPaint,
    );

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'QR CODE',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw label background
    final labelBgRect = Rect.fromLTWH(
      rect.left,
      rect.top - 24,
      textPainter.width + 8,
      20,
    );
    final labelBgPaint = Paint()..color = Colors.green;
    canvas.drawRect(labelBgRect, labelBgPaint);

    // Draw label text
    textPainter.paint(canvas, Offset(rect.left + 4, rect.top - 22));
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) {
    return oldDelegate.barcode != barcode ||
        oldDelegate.previewSize != previewSize;
  }
}

// ============================================================================
// EXAMPLE: Simple bounding box overlay
// ============================================================================

/// Simple example with just a rectangle
class SimpleBoundingBoxPainter extends CustomPainter {
  final Barcode barcode;
  final Size previewSize;

  SimpleBoundingBoxPainter({
    required this.barcode,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Use the helper method - much simpler!
    final boundingBox = barcode.getScaledBoundingBox(
      screenWidth: previewSize.width,
      screenHeight: previewSize.height,
    );

    if (boundingBox == null) return;

    // Draw simple green rectangle
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRect(boundingBox.toRect(), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// EXAMPLE: Animated bounding box
// ============================================================================

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
    // Use the helper method
    final boundingBox = barcode.getScaledBoundingBox(
      screenWidth: previewSize.width,
      screenHeight: previewSize.height,
    );

    if (boundingBox == null) return;

    final rect = boundingBox.toRect();

    // Pulsing effect
    final opacity = 0.5 + (animation.value * 0.5);

    // Draw border with pulsing opacity
    final paint = Paint()
      ..color = Colors.green.withOpacity(opacity)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);

    // Draw corner circles
    final cornerPaint = Paint()
      ..color = Colors.green.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    const radius = 6.0;
    canvas.drawCircle(Offset(rect.left, rect.top), radius, cornerPaint);
    canvas.drawCircle(Offset(rect.right, rect.top), radius, cornerPaint);
    canvas.drawCircle(Offset(rect.left, rect.bottom), radius, cornerPaint);
    canvas.drawCircle(Offset(rect.right, rect.bottom), radius, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
