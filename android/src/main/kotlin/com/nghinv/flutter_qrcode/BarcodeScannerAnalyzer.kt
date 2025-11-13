package com.nghinv.flutter_qrcode

import android.annotation.SuppressLint
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage

class BarcodeScannerAnalyzer(
    private val formats: List<Int>,
    private val onBarcodeDetected: (List<Barcode>) -> Unit
) : ImageAnalysis.Analyzer {

    private val scanner: BarcodeScanner
    private var isProcessing = false
    private var lastScanTime = 0L
    private val scanDelay = 500L // milliseconds

    init {
        val optionsBuilder = BarcodeScannerOptions.Builder()

        // Set barcode formats
        val formatMask = formats.fold(0) { acc, format -> acc or format }
        if (formatMask != 0) {
            optionsBuilder.setBarcodeFormats(formatMask)
        }

        scanner = BarcodeScanning.getClient(optionsBuilder.build())
    }

    @SuppressLint("UnsafeOptInUsageError")
    override fun analyze(imageProxy: ImageProxy) {
        val currentTime = System.currentTimeMillis()

        if (isProcessing || currentTime - lastScanTime < scanDelay) {
            imageProxy.close()
            return
        }

        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            isProcessing = true
            val image = InputImage.fromMediaImage(
                mediaImage,
                imageProxy.imageInfo.rotationDegrees
            )

            scanner.process(image)
                .addOnSuccessListener { barcodes ->
                    if (barcodes.isNotEmpty()) {
                        lastScanTime = currentTime
                        onBarcodeDetected(barcodes)
                    }
                }
                .addOnFailureListener {
                    // Handle error silently
                }
                .addOnCompleteListener {
                    isProcessing = false
                    imageProxy.close()
                }
        } else {
            imageProxy.close()
        }
    }

    fun close() {
        scanner.close()
    }
}
