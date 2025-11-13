/// Supported barcode formats
enum BarcodeFormat {
  /// QR Code 2D barcode format
  qrCode,

  /// Aztec 2D barcode format
  aztec,

  /// Codabar 1D format
  codabar,

  /// Code 39 1D format
  code39,

  /// Code 93 1D format
  code93,

  /// Code 128 1D format
  code128,

  /// Data Matrix 2D barcode format
  dataMatrix,

  /// EAN-8 1D format
  ean8,

  /// EAN-13 1D format
  ean13,

  /// ITF (Interleaved Two of Five) 1D format
  itf,

  /// PDF417 format
  pdf417,

  /// UPC-A 1D format
  upcA,

  /// UPC-E 1D format
  upcE,

  /// All supported formats
  all,

  /// Unknown format
  unknown;

  /// Get the raw value for platform communication
  int get rawValue {
    switch (this) {
      case BarcodeFormat.qrCode:
        return 256;
      case BarcodeFormat.aztec:
        return 1;
      case BarcodeFormat.codabar:
        return 2;
      case BarcodeFormat.code39:
        return 4;
      case BarcodeFormat.code93:
        return 8;
      case BarcodeFormat.code128:
        return 16;
      case BarcodeFormat.dataMatrix:
        return 32;
      case BarcodeFormat.ean8:
        return 64;
      case BarcodeFormat.ean13:
        return 128;
      case BarcodeFormat.itf:
        return 512;
      case BarcodeFormat.pdf417:
        return 1024;
      case BarcodeFormat.upcA:
        return 2048;
      case BarcodeFormat.upcE:
        return 4096;
      case BarcodeFormat.all:
        return 8191;
      case BarcodeFormat.unknown:
        return 0;
    }
  }

  /// Create from raw value
  static BarcodeFormat fromRawValue(int value) {
    switch (value) {
      case 256:
        return BarcodeFormat.qrCode;
      case 1:
        return BarcodeFormat.aztec;
      case 2:
        return BarcodeFormat.codabar;
      case 4:
        return BarcodeFormat.code39;
      case 8:
        return BarcodeFormat.code93;
      case 16:
        return BarcodeFormat.code128;
      case 32:
        return BarcodeFormat.dataMatrix;
      case 64:
        return BarcodeFormat.ean8;
      case 128:
        return BarcodeFormat.ean13;
      case 512:
        return BarcodeFormat.itf;
      case 1024:
        return BarcodeFormat.pdf417;
      case 2048:
        return BarcodeFormat.upcA;
      case 4096:
        return BarcodeFormat.upcE;
      default:
        return BarcodeFormat.unknown;
    }
  }
}
