import 'dart:ui' show Rect, Size;

import 'barcode_format.dart';

/// Represents a scanned barcode/QR code
class Barcode {
  /// The raw value of the barcode
  final String? rawValue;

  /// The format of the barcode
  final BarcodeFormat format;

  /// The corner points of the barcode in the image
  final List<BarcodePoint>? cornerPoints;

  /// The bounding box of the barcode
  final BarcodeRect? boundingBox;

  /// Additional type-specific data
  final BarcodeValueType? valueType;

  /// The size of the image where the barcode was detected
  /// Used for coordinate transformation
  final Size? imageSize;

  const Barcode({
    required this.rawValue,
    required this.format,
    this.cornerPoints,
    this.boundingBox,
    this.valueType,
    this.imageSize,
  });

  /// Create from JSON map
  factory Barcode.fromJson(Map<String, dynamic> json) {
    return Barcode(
      rawValue: json['rawValue'] as String?,
      format: BarcodeFormat.fromRawValue(json['format'] as int? ?? 0),
      cornerPoints: (json['cornerPoints'] as List<dynamic>?)
          ?.map((e) => BarcodePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      boundingBox: json['boundingBox'] != null
          ? BarcodeRect.fromJson(json['boundingBox'] as Map<String, dynamic>)
          : null,
      valueType: json['valueType'] != null
          ? BarcodeValueType.fromJson(json['valueType'] as Map<String, dynamic>)
          : null,
      imageSize: json['imageSize'] != null
          ? Size(
              (json['imageSize']['width'] as num).toDouble(),
              (json['imageSize']['height'] as num).toDouble(),
            )
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'rawValue': rawValue,
      'format': format.rawValue,
      'cornerPoints': cornerPoints?.map((e) => e.toJson()).toList(),
      'boundingBox': boundingBox?.toJson(),
      'valueType': valueType?.toJson(),
      'imageSize': imageSize != null
          ? {'width': imageSize!.width, 'height': imageSize!.height}
          : null,
    };
  }

  /// Get bounding box scaled to screen size
  ///
  /// This automatically handles platform differences (iOS normalized vs Android pixels)
  /// and scales the coordinates to match your widget size.
  ///
  /// Example:
  /// ```dart
  /// final screenRect = barcode.getScaledBoundingBox(
  ///   screenWidth: widgetSize.width,
  ///   screenHeight: widgetSize.height,
  /// );
  /// ```
  BarcodeRect? getScaledBoundingBox({
    required double screenWidth,
    required double screenHeight,
  }) {
    if (boundingBox == null) return null;

    var rect = boundingBox!;

    // iOS: normalized coordinates (0-1), need to denormalize and flip Y
    if (rect.right <= 1.0 && rect.bottom <= 1.0) {
      return rect.denormalize(
        width: screenWidth,
        height: screenHeight,
        flipVertical: true, // iOS origin is bottom-left
      );
    }

    // Android: pixel coordinates from camera, need to scale to screen
    if (imageSize != null) {
      return rect.scaleToSize(
        fromWidth: imageSize!.width,
        fromHeight: imageSize!.height,
        toWidth: screenWidth,
        toHeight: screenHeight,
      );
    }

    // Fallback: return as-is
    return rect;
  }

  @override
  String toString() {
    return 'Barcode(rawValue: $rawValue, format: $format)';
  }
}

/// Represents a point in the barcode
class BarcodePoint {
  final double x;
  final double y;

  const BarcodePoint({required this.x, required this.y});

  factory BarcodePoint.fromJson(Map<String, dynamic> json) {
    return BarcodePoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y};
  }
}

/// Represents a rectangle bounding box
class BarcodeRect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const BarcodeRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;
  double get height => bottom - top;

  /// Get center point of the bounding box
  BarcodePoint get center => BarcodePoint(
        x: left + width / 2,
        y: top + height / 2,
      );

  /// Convert to Rect for Flutter rendering
  ///
  /// Note: The coordinates from native platforms need to be scaled to match
  /// your widget/screen size. Use [scaleToSize] for proper conversion.
  Rect toRect() {
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Scale bounding box to match a target size
  ///
  /// This is useful when the barcode was detected in a camera preview that
  /// has a different size than your display widget.
  ///
  /// Example:
  /// ```dart
  /// final screenRect = barcode.boundingBox?.scaleToSize(
  ///   fromWidth: 1920,  // Camera preview width
  ///   fromHeight: 1080, // Camera preview height
  ///   toWidth: 400,     // Widget width
  ///   toHeight: 300,    // Widget height
  /// );
  /// ```
  BarcodeRect scaleToSize({
    required double fromWidth,
    required double fromHeight,
    required double toWidth,
    required double toHeight,
  }) {
    final scaleX = toWidth / fromWidth;
    final scaleY = toHeight / fromHeight;

    return BarcodeRect(
      left: left * scaleX,
      top: top * scaleY,
      right: right * scaleX,
      bottom: bottom * scaleY,
    );
  }

  /// Transform normalized coordinates (0-1) to pixel coordinates
  ///
  /// iOS Vision framework returns normalized coordinates. Use this to convert
  /// them to pixel coordinates.
  ///
  /// [flipVertical] should be true for iOS (origin at bottom-left)
  BarcodeRect denormalize({
    required double width,
    required double height,
    bool flipVertical = false,
  }) {
    if (flipVertical) {
      // iOS: origin at bottom-left, need to flip Y axis
      return BarcodeRect(
        left: left * width,
        top: (1 - bottom) * height, // Flip Y
        right: right * width,
        bottom: (1 - top) * height, // Flip Y
      );
    } else {
      // Android: origin at top-left
      return BarcodeRect(
        left: left * width,
        top: top * height,
        right: right * width,
        bottom: bottom * height,
      );
    }
  }

  factory BarcodeRect.fromJson(Map<String, dynamic> json) {
    return BarcodeRect(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      right: (json['right'] as num).toDouble(),
      bottom: (json['bottom'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }

  @override
  String toString() {
    return 'BarcodeRect(left: $left, top: $top, right: $right, bottom: $bottom)';
  }
}

/// Additional barcode value type information
class BarcodeValueType {
  final BarcodeValueTypeKind type;
  final Map<String, dynamic>? data;

  const BarcodeValueType({
    required this.type,
    this.data,
  });

  factory BarcodeValueType.fromJson(Map<String, dynamic> json) {
    return BarcodeValueType(
      type: BarcodeValueTypeKind.values[json['type'] as int? ?? 0],
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'data': data,
    };
  }
}

/// Types of barcode value
enum BarcodeValueTypeKind {
  unknown,
  contactInfo,
  email,
  isbn,
  phone,
  product,
  sms,
  text,
  url,
  wifi,
  geo,
  calendarEvent,
  driverLicense,
}
