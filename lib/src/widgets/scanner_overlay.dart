import 'dart:math' as Math;

import 'package:flutter/material.dart';
import '../models/scanner_overlay_config.dart';

class ScannerOverlay extends StatefulWidget {
  final ScannerOverlayConfig config;

  const ScannerOverlay({super.key, required this.config});

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.config.scanLineDuration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    if (widget.config.showScanLine) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.showScanLine != oldWidget.config.showScanLine) {
      if (widget.config.showScanLine) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
    if (widget.config.scanLineDuration != oldWidget.config.scanLineDuration) {
      _animationController.duration = widget.config.scanLineDuration;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          if (widget.config.showOverlay)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ScannerOverlayPainter(
                    config: widget.config,
                    animationValue:
                        widget.config.showScanLine ? _animation.value : 0.0,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          // UI elements (title, descriptions, widgets)
          _buildUIElements(context),
          // Toggle torch button
          if (widget.config.showToggleTorchButton &&
              widget.config.onToggleTorch != null)
            _buildToggleTorchButton(context),
        ],
      ),
    );
  }

  Widget _buildUIElements(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final scanAreaSize = screenSize.width * widget.config.scanAreaSize;

    final scanAreaTop = (screenSize.height - scanAreaSize) / 2;
    final scanAreaBottom = scanAreaTop + scanAreaSize;

    return Stack(
      children: [
        if (widget.config.topWidget != null ||
            widget.config.title != null ||
            widget.config.topDescription != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: screenSize.height - scanAreaTop,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child:
                    widget.config.topWidget != null
                        ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: widget.config.topWidget!,
                        )
                        : (widget.config.title != null ||
                            widget.config.topDescription != null)
                        ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.config.title != null)
                                Text(
                                  widget.config.title!,
                                  style:
                                      widget.config.titleStyle ??
                                      Theme.of(
                                        context,
                                      ).textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              if (widget.config.title != null &&
                                  widget.config.topDescription != null)
                                const SizedBox(height: 8),
                              if (widget.config.topDescription != null)
                                Text(
                                  widget.config.topDescription!,
                                  style:
                                      widget.config.topDescriptionStyle ??
                                      Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ),
          ),
        // Bottom content - positioned below scan area
        if (widget.config.bottomWidget != null ||
            widget.config.bottomDescription != null)
          Positioned(
            top: scanAreaBottom,
            left: 0,
            right: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child:
                    widget.config.bottomWidget != null
                        ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: widget.config.bottomWidget!,
                        )
                        : widget.config.bottomDescription != null
                        ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            widget.config.bottomDescription!,
                            style:
                                widget.config.bottomDescriptionStyle ??
                                Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToggleTorchButton(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    // Calculate position based on alignment
    double? top, bottom, left, right;
    final alignment = widget.config.torchButtonPosition;

    if (alignment == Alignment.topLeft) {
      top = 16.0;
      left = 16.0;
    } else if (alignment == Alignment.topRight) {
      top = 16.0;
      right = 16.0;
    } else if (alignment == Alignment.bottomLeft) {
      bottom = 16.0;
      left = 16.0;
    } else if (alignment == Alignment.bottomRight) {
      bottom = 16.0;
      right = 16.0;
    } else if (alignment == Alignment.topCenter) {
      top = 16.0;
      left = (screenSize.width - widget.config.torchButtonSize) / 2;
    } else if (alignment == Alignment.bottomCenter) {
      bottom = 16.0;
      left = (screenSize.width - widget.config.torchButtonSize) / 2;
    } else {
      top = 16.0;
      right = 16.0;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Material(
        color:
            widget.config.torchButtonBackgroundColor ??
            Colors.black.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            setState(() {
              _isTorchOn = !_isTorchOn;
            });
            widget.config.onToggleTorch?.call();
          },
          borderRadius: BorderRadius.circular(
            widget.config.torchButtonSize / 2,
          ),
          child: Container(
            width: widget.config.torchButtonSize,
            height: widget.config.torchButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  widget.config.torchButtonBackgroundColor ??
                  Colors.black.withValues(alpha: 0.2),
            ),
            child: Icon(
              _isTorchOn
                  ? widget.config.torchOnIcon
                  : widget.config.torchOffIcon,
              color: widget.config.torchButtonColor,
              size: widget.config.torchButtonSize * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final ScannerOverlayConfig config;
  final double animationValue;

  ScannerOverlayPainter({required this.config, this.animationValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final scanAreaSize = size.width * config.scanAreaSize;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final rect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(config.borderRadius),
    );

    if (config.showOverlay) {
      final overlayPaint =
          Paint()
            ..color = config.overlayColor
            ..style = PaintingStyle.fill;

      final path =
          Path()
            ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
            ..addRRect(rrect)
            ..fillType = PathFillType.evenOdd;

      canvas.drawPath(path, overlayPaint);
    }

    if (config.showCorners && config.cornerLength > 0) {
      final cornerPaint =
          Paint()
            ..color = config.borderColor
            ..strokeWidth = config.borderWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.miter;

      final cornerLength = config.cornerLength;
      final radius = config.borderRadius;

      if (radius > 0 && cornerLength > radius) {
        final cornerPath =
            Path()
              ..moveTo(left + cornerLength, top)
              ..lineTo(left + radius, top)
              ..arcToPoint(
                Offset(left, top + radius),
                radius: Radius.circular(radius),
                clockwise: false,
              )
              ..lineTo(left, top + cornerLength);
        canvas.drawPath(cornerPath, cornerPaint);
      } else {
        final cornerPath =
            Path()
              ..moveTo(left, top + cornerLength)
              ..lineTo(left, top)
              ..lineTo(left + cornerLength, top);
        canvas.drawPath(cornerPath, cornerPaint);
      }

      if (radius > 0 && cornerLength > radius) {
        final cornerPath =
            Path()
              ..moveTo(left + scanAreaSize, top + cornerLength)
              ..lineTo(left + scanAreaSize, top + radius)
              ..arcToPoint(
                Offset(left + scanAreaSize - radius, top),
                radius: Radius.circular(radius),
                clockwise: false,
              )
              ..lineTo(left + scanAreaSize - cornerLength, top);
        canvas.drawPath(cornerPath, cornerPaint);
      } else {
        final cornerPath =
            Path()
              ..moveTo(left + scanAreaSize - cornerLength, top)
              ..lineTo(left + scanAreaSize, top)
              ..lineTo(left + scanAreaSize, top + cornerLength);
        canvas.drawPath(cornerPath, cornerPaint);
      }

      if (radius > 0 && cornerLength > radius) {
        final cornerPath =
            Path()
              ..moveTo(left, top + scanAreaSize - cornerLength)
              ..lineTo(left, top + scanAreaSize - radius)
              ..arcToPoint(
                Offset(left + radius, top + scanAreaSize),
                radius: Radius.circular(radius),
                clockwise: false,
              )
              ..lineTo(left + cornerLength, top + scanAreaSize);
        canvas.drawPath(cornerPath, cornerPaint);
      } else {
        final cornerPath =
            Path()
              ..moveTo(left, top + scanAreaSize - cornerLength)
              ..lineTo(left, top + scanAreaSize)
              ..lineTo(left + cornerLength, top + scanAreaSize);
        canvas.drawPath(cornerPath, cornerPaint);
      }

      if (radius > 0 && cornerLength > radius) {
        final cornerPath =
            Path()
              ..moveTo(left + scanAreaSize - cornerLength, top + scanAreaSize)
              ..lineTo(left + scanAreaSize - radius, top + scanAreaSize)
              ..arcToPoint(
                Offset(left + scanAreaSize, top + scanAreaSize - radius),
                radius: Radius.circular(radius),
                clockwise: false,
              )
              ..lineTo(left + scanAreaSize, top + scanAreaSize - cornerLength);
        canvas.drawPath(cornerPath, cornerPaint);
      } else {
        final cornerPath =
            Path()
              ..moveTo(left + scanAreaSize - cornerLength, top + scanAreaSize)
              ..lineTo(left + scanAreaSize, top + scanAreaSize)
              ..lineTo(left + scanAreaSize, top + scanAreaSize - cornerLength);
        canvas.drawPath(cornerPath, cornerPaint);
      }
    }

    if (config.showScanLine && animationValue > 0) {
      final scanLinePaint =
          Paint()
            ..color = config.scanLineColor
            ..strokeWidth = config.scanLineWidth
            ..style = PaintingStyle.stroke;

      if (config.scanLineDirection == ScanLineDirection.horizontal) {
        final y =
            top +
            (scanAreaSize * Math.min(Math.max(animationValue, 0.02), 0.98));
        final scanLinePath =
            Path()
              ..moveTo(left + 8, y)
              ..lineTo(left + scanAreaSize - 8, y);

        canvas.drawPath(scanLinePath, scanLinePaint);
      } else {
        final x =
            left +
            (scanAreaSize * Math.min(Math.max(animationValue, 0.02), 0.98));
        final scanLinePath =
            Path()
              ..moveTo(x, top + 8)
              ..lineTo(x, top + scanAreaSize - 8);
        canvas.drawPath(scanLinePath, scanLinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) {
    return oldDelegate.config.borderColor != config.borderColor ||
        oldDelegate.config.borderWidth != config.borderWidth ||
        oldDelegate.config.cornerLength != config.cornerLength ||
        oldDelegate.config.scanAreaSize != config.scanAreaSize ||
        oldDelegate.config.overlayColor != config.overlayColor ||
        oldDelegate.config.borderRadius != config.borderRadius ||
        oldDelegate.config.showCorners != config.showCorners ||
        oldDelegate.config.showOverlay != config.showOverlay ||
        oldDelegate.config.showScanLine != config.showScanLine ||
        oldDelegate.config.scanLineDirection != config.scanLineDirection ||
        oldDelegate.config.scanLineColor != config.scanLineColor ||
        oldDelegate.config.scanLineWidth != config.scanLineWidth ||
        oldDelegate.animationValue != animationValue;
  }
}
