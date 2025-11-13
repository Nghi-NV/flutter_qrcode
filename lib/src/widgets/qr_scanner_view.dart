import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../models/barcode.dart';
import '../models/scanner_config.dart';
import '../models/scanner_overlay_config.dart';
import 'scanner_overlay.dart';

/// Callback for when a barcode is scanned
typedef OnBarcodeScanned = void Function(Barcode barcode);

/// Callback for when scanner controller is created
typedef OnScannerCreated = void Function(QRScannerController controller);

/// Widget for displaying the camera preview and scanning barcodes
class QRScannerView extends StatefulWidget {
  /// Called when a barcode is successfully scanned
  final OnBarcodeScanned? onBarcodeScanned;

  /// Called when the scanner controller is created
  final OnScannerCreated? onScannerCreated;

  /// Configuration for the scanner
  final ScannerConfig config;

  /// Overlay widget to display on top of the camera preview
  /// If null and overlayConfig is provided, a default overlay will be used
  final Widget? overlay;

  /// Configuration for the default scanner overlay
  /// If overlay is provided, this will be ignored
  final ScannerOverlayConfig? overlayConfig;

  /// Whether the scanner should start automatically
  final bool autoStart;

  const QRScannerView({
    super.key,
    this.onBarcodeScanned,
    this.onScannerCreated,
    this.config = const ScannerConfig(),
    this.overlay,
    this.overlayConfig,
    this.autoStart = true,
  });

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  QRScannerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      _initializeController();
    }
  }

  void _initializeController() {
    _controller = QRScannerController(
      config: widget.config,
      onBarcodeScanned: widget.onBarcodeScanned,
    );
    widget.onScannerCreated?.call(_controller!);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildNativeView(),
        if (widget.overlay != null)
          widget.overlay!
        else if (widget.overlayConfig != null)
          ScannerOverlay(config: widget.overlayConfig!),
      ],
    );
  }

  Widget _buildNativeView() {
    const String viewType = 'plugins.flutter_qrcode/scanner_view';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PlatformViewLink(
          viewType: viewType,
          surfaceFactory: (context, controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers:
                  const <Factory<OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (params) {
            final controller = PlatformViewsService.initExpensiveAndroidView(
              id: params.id,
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: widget.config.toJson(),
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () {
                params.onFocusChanged(true);
              },
            );

            controller.addOnPlatformViewCreatedListener((id) {
              params.onPlatformViewCreated(id);
              _controller?._setPlatformViewId(id);
            });

            return controller..create();
          },
        );

      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return UiKitView(
          viewType: viewType,
          creationParams: widget.config.toJson(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: (id) {
            _controller?._setPlatformViewId(id);
          },
        );

      default:
        return Center(
          child: Text(
            '${defaultTargetPlatform.name} is not yet supported.',
            style: const TextStyle(color: Colors.red),
          ),
        );
    }
  }
}

/// Controller for the QR scanner
class QRScannerController {
  // Platform view ID (stored for potential future use)
  // ignore: unused_field
  int? _platformViewId;
  MethodChannel? _channel;
  final ScannerConfig config;
  final OnBarcodeScanned? onBarcodeScanned;

  bool _isDisposed = false;
  bool _isScanning = false;

  QRScannerController({required this.config, this.onBarcodeScanned});

  void _setPlatformViewId(int id) {
    _platformViewId = id;
    _channel = MethodChannel('plugins.flutter_qrcode/scanner_view_$id');
    _channel!.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (_isDisposed) return;

    switch (call.method) {
      case 'onBarcodeScanned':
        try {
          // Convert Map<Object?, Object?> to Map<String, dynamic>
          final Map<String, dynamic> barcodeMap = _convertMap(call.arguments);
          final barcode = Barcode.fromJson(barcodeMap);
          onBarcodeScanned?.call(barcode);
        } catch (e) {
          // Error processing barcode, ignore
        }
        break;
    }
  }

  /// Convert `Map<Object?, Object?>` to `Map<String, dynamic>` recursively
  Map<String, dynamic> _convertMap(dynamic map) {
    if (map is! Map) return {};

    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (key is String) {
        if (value is Map) {
          result[key] = _convertMap(value);
        } else if (value is List) {
          result[key] = _convertList(value);
        } else {
          result[key] = value;
        }
      }
    });
    return result;
  }

  /// Convert `List` to `List<dynamic>` recursively
  List<dynamic> _convertList(List list) {
    return list.map((item) {
      if (item is Map) {
        return _convertMap(item);
      } else if (item is List) {
        return _convertList(item);
      }
      return item;
    }).toList();
  }

  /// Start scanning for barcodes
  Future<void> startScanning() async {
    if (_isDisposed || _channel == null) return;
    await _channel!.invokeMethod('startScanning');
    _isScanning = true;
  }

  /// Stop scanning for barcodes
  Future<void> stopScanning() async {
    if (_isDisposed || _channel == null) return;
    await _channel!.invokeMethod('stopScanning');
    _isScanning = false;
  }

  /// Resume scanning (after being paused)
  Future<void> resumeScanning() async {
    if (_isDisposed || _channel == null) return;
    await _channel!.invokeMethod('resumeScanning');
    _isScanning = true;
  }

  /// Pause scanning
  Future<void> pauseScanning() async {
    if (_isDisposed || _channel == null) return;
    await _channel!.invokeMethod('pauseScanning');
    _isScanning = false;
  }

  /// Toggle torch/flash
  Future<void> toggleTorch() async {
    if (_isDisposed || _channel == null) return;
    await _channel!.invokeMethod('toggleTorch');
  }

  /// Set torch/flash state
  Future<void> setTorch(bool enabled) async {
    if (_isDisposed || _channel == null) return;
    await _channel!.invokeMethod('setTorch', {'enabled': enabled});
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_isDisposed || _channel == null) return;
    await _channel!.invokeMethod('switchCamera');
  }

  /// Check if scanning
  bool get isScanning => _isScanning;

  /// Dispose the controller
  void dispose() {
    _isDisposed = true;
    _channel?.setMethodCallHandler(null);
    _channel = null;
  }
}
