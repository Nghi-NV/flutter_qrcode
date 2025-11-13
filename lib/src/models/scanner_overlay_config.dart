import 'package:flutter/material.dart';

/// Direction of the scan line animation
enum ScanLineDirection {
  /// Horizontal scan line (moves top to bottom)
  horizontal,

  /// Vertical scan line (moves left to right)
  vertical,
}

/// Configuration for the scanner overlay UI
class ScannerOverlayConfig {
  /// Title text displayed at the top
  final String? title;

  /// Top description text (above scan area)
  final String? topDescription;

  /// Bottom description text (below scan area)
  final String? bottomDescription;

  /// Custom widget to display at the top (replaces title if provided)
  final Widget? topWidget;

  /// Custom widget to display at the bottom (replaces bottom description if provided)
  final Widget? bottomWidget;

  /// Color of the scan frame border
  final Color borderColor;

  /// Width of the scan frame border
  final double borderWidth;

  /// Length of corner indicators
  final double cornerLength;

  /// Size of the scan area as a fraction of screen width (0.0 to 1.0)
  final double scanAreaSize;

  /// Color of the overlay (semi-transparent background)
  final Color overlayColor;

  /// Border radius of the scan area
  final double borderRadius;

  /// Whether to show corner indicators
  final bool showCorners;

  /// Whether to show the overlay background
  final bool showOverlay;

  /// Text style for title
  final TextStyle? titleStyle;

  /// Text style for top description
  final TextStyle? topDescriptionStyle;

  /// Text style for bottom description
  final TextStyle? bottomDescriptionStyle;

  /// Whether to show animated scan line
  final bool showScanLine;

  /// Direction of the scan line animation
  final ScanLineDirection scanLineDirection;

  /// Color of the scan line
  final Color scanLineColor;

  /// Width/thickness of the scan line
  final double scanLineWidth;

  /// Duration for one complete scan line animation cycle
  final Duration scanLineDuration;

  /// Whether to show toggle torch button
  final bool showToggleTorchButton;

  /// Callback when toggle torch button is pressed
  final VoidCallback? onToggleTorch;

  /// Icon for torch button when torch is off
  final IconData torchOffIcon;

  /// Icon for torch button when torch is on
  final IconData torchOnIcon;

  /// Color of the torch button
  final Color torchButtonColor;

  /// Background color of the torch button
  final Color? torchButtonBackgroundColor;

  /// Size of the torch button
  final double torchButtonSize;

  /// Position of the torch button (top-right corner by default)
  final Alignment torchButtonPosition;

  const ScannerOverlayConfig({
    this.title,
    this.topDescription,
    this.bottomDescription,
    this.topWidget,
    this.bottomWidget,
    this.borderColor = Colors.green,
    this.borderWidth = 3.0,
    this.cornerLength = 50.0,
    this.scanAreaSize = 0.7,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.54),
    this.borderRadius = 16.0,
    this.showCorners = true,
    this.showOverlay = true,
    this.titleStyle,
    this.topDescriptionStyle,
    this.bottomDescriptionStyle,
    this.showScanLine = true,
    this.scanLineDirection = ScanLineDirection.horizontal,
    this.scanLineColor = Colors.green,
    this.scanLineWidth = 1.0,
    this.scanLineDuration = const Duration(milliseconds: 2000),
    this.showToggleTorchButton = false,
    this.onToggleTorch,
    this.torchOffIcon = Icons.flash_off,
    this.torchOnIcon = Icons.flash_on,
    this.torchButtonColor = Colors.white,
    this.torchButtonBackgroundColor,
    this.torchButtonSize = 48.0,
    this.torchButtonPosition = Alignment.topRight,
  });

  /// Create a copy with modified fields
  ScannerOverlayConfig copyWith({
    String? title,
    String? topDescription,
    String? bottomDescription,
    Widget? topWidget,
    Widget? bottomWidget,
    Color? borderColor,
    double? borderWidth,
    double? cornerLength,
    double? scanAreaSize,
    Color? overlayColor,
    double? borderRadius,
    bool? showCorners,
    bool? showOverlay,
    TextStyle? titleStyle,
    TextStyle? topDescriptionStyle,
    TextStyle? bottomDescriptionStyle,
    bool? showScanLine,
    ScanLineDirection? scanLineDirection,
    Color? scanLineColor,
    double? scanLineWidth,
    Duration? scanLineDuration,
    bool? showToggleTorchButton,
    VoidCallback? onToggleTorch,
    IconData? torchOffIcon,
    IconData? torchOnIcon,
    Color? torchButtonColor,
    Color? torchButtonBackgroundColor,
    double? torchButtonSize,
    Alignment? torchButtonPosition,
  }) {
    return ScannerOverlayConfig(
      title: title ?? this.title,
      topDescription: topDescription ?? this.topDescription,
      bottomDescription: bottomDescription ?? this.bottomDescription,
      topWidget: topWidget ?? this.topWidget,
      bottomWidget: bottomWidget ?? this.bottomWidget,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      cornerLength: cornerLength ?? this.cornerLength,
      scanAreaSize: scanAreaSize ?? this.scanAreaSize,
      overlayColor: overlayColor ?? this.overlayColor,
      borderRadius: borderRadius ?? this.borderRadius,
      showCorners: showCorners ?? this.showCorners,
      showOverlay: showOverlay ?? this.showOverlay,
      titleStyle: titleStyle ?? this.titleStyle,
      topDescriptionStyle: topDescriptionStyle ?? this.topDescriptionStyle,
      bottomDescriptionStyle:
          bottomDescriptionStyle ?? this.bottomDescriptionStyle,
      showScanLine: showScanLine ?? this.showScanLine,
      scanLineDirection: scanLineDirection ?? this.scanLineDirection,
      scanLineColor: scanLineColor ?? this.scanLineColor,
      scanLineWidth: scanLineWidth ?? this.scanLineWidth,
      scanLineDuration: scanLineDuration ?? this.scanLineDuration,
      showToggleTorchButton:
          showToggleTorchButton ?? this.showToggleTorchButton,
      onToggleTorch: onToggleTorch ?? this.onToggleTorch,
      torchOffIcon: torchOffIcon ?? this.torchOffIcon,
      torchOnIcon: torchOnIcon ?? this.torchOnIcon,
      torchButtonColor: torchButtonColor ?? this.torchButtonColor,
      torchButtonBackgroundColor:
          torchButtonBackgroundColor ?? this.torchButtonBackgroundColor,
      torchButtonSize: torchButtonSize ?? this.torchButtonSize,
      torchButtonPosition: torchButtonPosition ?? this.torchButtonPosition,
    );
  }
}
