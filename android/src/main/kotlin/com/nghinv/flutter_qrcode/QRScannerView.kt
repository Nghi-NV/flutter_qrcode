package com.nghinv.flutter_qrcode

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.View
import android.widget.FrameLayout
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.barcode.common.Barcode
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class QRScannerView(
    private val context: Context,
    private val id: Int,
    private val creationParams: Map<String, Any>?,
    private val messenger: io.flutter.plugin.common.BinaryMessenger
) : PlatformView, MethodChannel.MethodCallHandler {

    private val frameLayout: FrameLayout = FrameLayout(context)
    private val previewView: PreviewView = PreviewView(context)
    private val methodChannel: MethodChannel = MethodChannel(
        messenger,
        "plugins.lumi_qr_scanner/scanner_view_$id"
    )

    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var camera: Camera? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var imageAnalysis: ImageAnalysis? = null
    private var barcodeAnalyzer: BarcodeScannerAnalyzer? = null
    private var isScanning = true
    private var useFrontCamera = false
    private val mainHandler = Handler(Looper.getMainLooper())
    private val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator

    init {
        methodChannel.setMethodCallHandler(this)
        frameLayout.addView(previewView)

        // Parse configuration
        useFrontCamera = creationParams?.get("useFrontCamera") as? Boolean ?: false

        if (hasPermission()) {
            startCamera()
        }
    }

    override fun getView(): View = frameLayout

    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
        barcodeAnalyzer?.close()
        cameraExecutor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startScanning" -> {
                isScanning = true
                result.success(null)
            }
            "stopScanning" -> {
                isScanning = false
                result.success(null)
            }
            "resumeScanning" -> {
                isScanning = true
                result.success(null)
            }
            "pauseScanning" -> {
                isScanning = false
                result.success(null)
            }
            "toggleTorch" -> {
                toggleTorch()
                result.success(null)
            }
            "setTorch" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setTorch(enabled)
                result.success(null)
            }
            "switchCamera" -> {
                useFrontCamera = !useFrontCamera
                startCamera()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun hasPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()

            // Preview
            val preview = Preview.Builder()
                .build()
                .also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

            // Image analysis
            imageAnalysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()

            // Get barcode formats from params
            val formats = (creationParams?.get("formats") as? List<*>)
                ?.mapNotNull { it as? Int } ?: listOf(Barcode.FORMAT_ALL_FORMATS)

            barcodeAnalyzer = BarcodeScannerAnalyzer(formats) { barcodes ->
                if (isScanning) {
                    handleBarcodes(barcodes)
                }
            }

            imageAnalysis?.setAnalyzer(cameraExecutor, barcodeAnalyzer!!)

            // Camera selector
            val cameraSelector = if (useFrontCamera) {
                CameraSelector.DEFAULT_FRONT_CAMERA
            } else {
                CameraSelector.DEFAULT_BACK_CAMERA
            }

            try {
                cameraProvider?.unbindAll()
                camera = cameraProvider?.bindToLifecycle(
                    context as LifecycleOwner,
                    cameraSelector,
                    preview,
                    imageAnalysis
                )
            } catch (e: Exception) {
                // Handle error
            }

        }, ContextCompat.getMainExecutor(context))
    }

    private fun handleBarcodes(barcodes: List<Barcode>) {
        if (!isScanning) return

        val vibrateOnSuccess = creationParams?.get("vibrateOnSuccess") as? Boolean ?: true
        if (vibrateOnSuccess) {
            vibrate()
        }

        // Get preview view dimensions for coordinate transformation
        val previewWidth = previewView.width.toDouble()
        val previewHeight = previewView.height.toDouble()

        barcodes.forEach { barcode ->
            val barcodeData = mapOf(
                "rawValue" to barcode.rawValue,
                "format" to barcode.format,
                "cornerPoints" to barcode.cornerPoints?.map { point ->
                    mapOf("x" to point.x.toDouble(), "y" to point.y.toDouble())
                },
                "boundingBox" to barcode.boundingBox?.let { rect ->
                    mapOf(
                        "left" to rect.left.toDouble(),
                        "top" to rect.top.toDouble(),
                        "right" to rect.right.toDouble(),
                        "bottom" to rect.bottom.toDouble()
                    )
                },
                "valueType" to mapOf(
                    "type" to barcode.valueType,
                    "data" to getBarcodeValueTypeData(barcode)
                ),
                // Send image dimensions for coordinate transformation
                "imageSize" to mapOf(
                    "width" to previewWidth,
                    "height" to previewHeight
                )
            )

            mainHandler.post {
                methodChannel.invokeMethod("onBarcodeScanned", barcodeData)
            }
        }

        val autoPause = creationParams?.get("autoPauseAfterScan") as? Boolean ?: false
        if (autoPause) {
            isScanning = false
        }
    }

    private fun getBarcodeValueTypeData(barcode: Barcode): Map<String, Any?>? {
        return when (barcode.valueType) {
            Barcode.TYPE_URL -> mapOf("url" to barcode.url?.url)
            Barcode.TYPE_EMAIL -> mapOf(
                "address" to barcode.email?.address,
                "subject" to barcode.email?.subject,
                "body" to barcode.email?.body
            )
            Barcode.TYPE_PHONE -> mapOf("number" to barcode.phone?.number)
            Barcode.TYPE_SMS -> mapOf(
                "message" to barcode.sms?.message,
                "phoneNumber" to barcode.sms?.phoneNumber
            )
            Barcode.TYPE_WIFI -> mapOf(
                "ssid" to barcode.wifi?.ssid,
                "password" to barcode.wifi?.password,
                "type" to barcode.wifi?.encryptionType
            )
            Barcode.TYPE_GEO -> mapOf(
                "latitude" to barcode.geoPoint?.lat,
                "longitude" to barcode.geoPoint?.lng
            )
            else -> null
        }
    }

    private fun vibrate() {
        vibrator?.let {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                it.vibrate(VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                it.vibrate(100)
            }
        }
    }

    private fun toggleTorch() {
        camera?.cameraControl?.let { control ->
            val torchState = camera?.cameraInfo?.torchState?.value ?: TorchState.OFF
            control.enableTorch(torchState == TorchState.OFF)
        }
    }

    private fun setTorch(enabled: Boolean) {
        camera?.cameraControl?.enableTorch(enabled)
    }
}
