import 'barcode_format.dart';

/// Configuration for the barcode scanner
class ScannerConfig {
  /// The barcode formats to scan for
  final List<BarcodeFormat> formats;

  /// Whether to enable auto focus
  final bool autoFocus;

  /// Whether to enable torch/flash
  final bool enableTorch;

  /// Delay between scans in milliseconds (to avoid duplicate scans)
  final int scanDelay;

  /// Whether to use front camera (default is back camera)
  final bool useFrontCamera;

  /// Whether to beep on successful scan
  final bool beepOnSuccess;

  /// Whether to vibrate on successful scan
  final bool vibrateOnSuccess;

  /// Whether to automatically pause after successful scan
  final bool autoPauseAfterScan;

  const ScannerConfig({
    this.formats = const [BarcodeFormat.all],
    this.autoFocus = true,
    this.enableTorch = false,
    this.scanDelay = 500,
    this.useFrontCamera = false,
    this.beepOnSuccess = false,
    this.vibrateOnSuccess = true,
    this.autoPauseAfterScan = false,
  });

  /// Convert to JSON map for platform communication
  Map<String, dynamic> toJson() {
    return {
      'formats': formats.map((f) => f.rawValue).toList(),
      'autoFocus': autoFocus,
      'enableTorch': enableTorch,
      'scanDelay': scanDelay,
      'useFrontCamera': useFrontCamera,
      'beepOnSuccess': beepOnSuccess,
      'vibrateOnSuccess': vibrateOnSuccess,
      'autoPauseAfterScan': autoPauseAfterScan,
    };
  }

  /// Create a copy with modified fields
  ScannerConfig copyWith({
    List<BarcodeFormat>? formats,
    bool? autoFocus,
    bool? enableTorch,
    int? scanDelay,
    bool? useFrontCamera,
    bool? beepOnSuccess,
    bool? vibrateOnSuccess,
    bool? autoPauseAfterScan,
  }) {
    return ScannerConfig(
      formats: formats ?? this.formats,
      autoFocus: autoFocus ?? this.autoFocus,
      enableTorch: enableTorch ?? this.enableTorch,
      scanDelay: scanDelay ?? this.scanDelay,
      useFrontCamera: useFrontCamera ?? this.useFrontCamera,
      beepOnSuccess: beepOnSuccess ?? this.beepOnSuccess,
      vibrateOnSuccess: vibrateOnSuccess ?? this.vibrateOnSuccess,
      autoPauseAfterScan: autoPauseAfterScan ?? this.autoPauseAfterScan,
    );
  }
}
