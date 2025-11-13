package com.nghinv.flutter_qrcode

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.exifinterface.media.ExifInterface
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.InputStream

/** LumiQrScannerPlugin */
class LumiQrScannerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private var pendingResult: Result? = null

  companion object {
    private const val CAMERA_PERMISSION_REQUEST_CODE = 9877
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "lumi_qr_scanner")
    channel.setMethodCallHandler(this)

    // Register platform view
    flutterPluginBinding.platformViewRegistry.registerViewFactory(
      "plugins.lumi_qr_scanner/scanner_view",
      QRScannerViewFactory(flutterPluginBinding.binaryMessenger)
    )
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "scanImagePath" -> {
        val imagePath = call.argument<String>("imagePath")
        if (imagePath != null) {
          scanImageFromPath(imagePath, result)
        } else {
          result.error("INVALID_ARGUMENT", "Image path is required", null)
        }
      }
      "scanImageBytes" -> {
        val imageBytes = call.argument<ByteArray>("imageBytes")
        if (imageBytes != null) {
          scanImageFromBytes(imageBytes, result)
        } else {
          result.error("INVALID_ARGUMENT", "Image bytes are required", null)
        }
      }
      "requestCameraPermission" -> {
        requestCameraPermission(result)
      }
      "hasCameraPermission" -> {
        result.success(hasCameraPermission())
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun scanImageFromPath(imagePath: String, result: Result) {
    try {
      // Load image as Bitmap first for better compatibility
      var bitmap: Bitmap? = null
      var exifOrientation = ExifInterface.ORIENTATION_NORMAL

      try {
        if (imagePath.startsWith("content://")) {
          // Load from content URI
          val uri = Uri.parse(imagePath)
          val inputStream = context.contentResolver.openInputStream(uri)
          bitmap = BitmapFactory.decodeStream(inputStream)
          inputStream?.close()

          // Try to read EXIF data from content URI
          context.contentResolver.openInputStream(uri)?.use { exifStream ->
            try {
              val exif = ExifInterface(exifStream)
              exifOrientation = exif.getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL
              )
            } catch (e: Exception) {
              // EXIF read failed, continue with default orientation
            }
          }
        } else {
          // Load from file path
          val file = File(imagePath)

          // Read EXIF data before loading bitmap
          try {
            val exif = ExifInterface(file.absolutePath)
            exifOrientation = exif.getAttributeInt(
              ExifInterface.TAG_ORIENTATION,
              ExifInterface.ORIENTATION_NORMAL
            )
          } catch (e: Exception) {
            // EXIF read failed, continue with default orientation
          }

          bitmap = BitmapFactory.decodeFile(file.absolutePath)
        }
      } catch (e: Exception) {
        android.util.Log.e("LumiQrScannerPlugin", "Failed to decode bitmap", e)
      }

      if (bitmap == null) {
        result.error("SCAN_ERROR", "Failed to load image", null)
        return
      }

      // Rotate bitmap according to EXIF orientation
      val rotatedBitmap = rotateBitmapByExif(bitmap, exifOrientation)

      // Try multi-scale scanning for better detection
      scanImageMultiScale(rotatedBitmap, result)
    } catch (e: Exception) {
      android.util.Log.e("LumiQrScannerPlugin", "Error scanning image", e)
      result.error("SCAN_ERROR", "Failed to scan image: ${e.message}", null)
    }
  }

  private fun scanImageMultiScale(bitmap: Bitmap, result: Result) {
    // Try different scales for better detection
    val scales = listOf(
      Triple(1920, "medium (1920px)", true),    // Standard scale
      Triple(2560, "large (2560px)", true),      // Larger scale for small QR codes
      Triple(1280, "small (1280px)", true),      // Smaller scale for large QR codes
      Triple(0, "original size", false)          // Original size as last resort
    )

    // Try scanning at each scale recursively
    tryNextScale(bitmap, scales, 0, result)
  }

  private fun tryNextScale(
    originalBitmap: Bitmap,
    scales: List<Triple<Int, String, Boolean>>,
    scaleIndex: Int,
    result: Result
  ) {
    // If we've tried all scales, return null
    if (scaleIndex >= scales.size) {
      result.success(null)
      return
    }

    val (maxDimension, _, shouldScale) = scales[scaleIndex]

    try {
      val processedBitmap = if (shouldScale) {
        scaleToSize(originalBitmap, maxDimension)
      } else {
        originalBitmap
      }

      val image = InputImage.fromBitmap(processedBitmap, 0)
      scanImageAsync(image) { barcodes ->
        // Clean up scaled bitmap if it's different from original
        if (processedBitmap != originalBitmap) {
          processedBitmap.recycle()
        }

        if (barcodes != null && barcodes.isNotEmpty()) {
          result.success(barcodes)
        } else {
          // Try next scale
          tryNextScale(originalBitmap, scales, scaleIndex + 1, result)
        }
      }
    } catch (e: Exception) {
      android.util.Log.e("LumiQrScannerPlugin", "Error scanning image", e)
      // Try next scale on error
      tryNextScale(originalBitmap, scales, scaleIndex + 1, result)
    }
  }

  private fun scanImageAsync(image: InputImage, callback: (List<Map<String, Any?>>?) -> Unit) {
    val options = BarcodeScannerOptions.Builder()
      .setBarcodeFormats(
        Barcode.FORMAT_QR_CODE,
        Barcode.FORMAT_AZTEC,
        Barcode.FORMAT_DATA_MATRIX,
        Barcode.FORMAT_PDF417,
        Barcode.FORMAT_CODE_128,
        Barcode.FORMAT_CODE_39,
        Barcode.FORMAT_CODE_93,
        Barcode.FORMAT_CODABAR,
        Barcode.FORMAT_EAN_13,
        Barcode.FORMAT_EAN_8,
        Barcode.FORMAT_ITF,
        Barcode.FORMAT_UPC_A,
        Barcode.FORMAT_UPC_E
      )
      .build()

    val scanner = BarcodeScanning.getClient(options)

    scanner.process(image)
      .addOnSuccessListener { barcodes ->
        val barcodeList = barcodes.map { barcode ->
          mapOf(
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
              "data" to null
            )
          )
        }
        callback(barcodeList)
      }
      .addOnFailureListener {
        callback(null)
      }
  }

  private fun scaleToSize(bitmap: Bitmap, maxDimension: Int): Bitmap {
    val width = bitmap.width
    val height = bitmap.height

    // If image is already smaller or equal, return as-is
    if (width <= maxDimension && height <= maxDimension) {
      return bitmap
    }

    // Calculate scale factor
    val scale = if (width > height) {
      maxDimension.toFloat() / width
    } else {
      maxDimension.toFloat() / height
    }

    val newWidth = (width * scale).toInt()
    val newHeight = (height * scale).toInt()

    return Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
  }

  private fun rotateBitmapByExif(bitmap: Bitmap, exifOrientation: Int): Bitmap {
    val matrix = Matrix()

    when (exifOrientation) {
      ExifInterface.ORIENTATION_ROTATE_90 -> {
        matrix.postRotate(90f)
      }
      ExifInterface.ORIENTATION_ROTATE_180 -> {
        matrix.postRotate(180f)
      }
      ExifInterface.ORIENTATION_ROTATE_270 -> {
        matrix.postRotate(270f)
      }
      ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> {
        matrix.postScale(-1f, 1f)
      }
      ExifInterface.ORIENTATION_FLIP_VERTICAL -> {
        matrix.postScale(1f, -1f)
      }
      ExifInterface.ORIENTATION_TRANSPOSE -> {
        matrix.postRotate(90f)
        matrix.postScale(-1f, 1f)
      }
      ExifInterface.ORIENTATION_TRANSVERSE -> {
        matrix.postRotate(-90f)
        matrix.postScale(-1f, 1f)
      }
      else -> {
        // ORIENTATION_NORMAL or ORIENTATION_UNDEFINED - no rotation needed
        return bitmap
      }
    }

    return try {
      val rotatedBitmap = Bitmap.createBitmap(
        bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
      )
      // Recycle old bitmap if it's different from the new one
      if (rotatedBitmap != bitmap) {
        bitmap.recycle()
      }
      rotatedBitmap
    } catch (e: Exception) {
      android.util.Log.e("LumiQrScannerPlugin", "Failed to rotate bitmap", e)
      bitmap
    }
  }

  private fun scaleDownIfNeeded(bitmap: Bitmap): Bitmap {
    // MLKit works better with moderately sized images
    // Recommended max dimensions: around 1920x1080
    val maxDimension = 1920
    val width = bitmap.width
    val height = bitmap.height

    // If image is already small enough, return as-is
    if (width <= maxDimension && height <= maxDimension) {
      return bitmap
    }

    // Calculate scale factor to fit within maxDimension while maintaining aspect ratio
    val scale = if (width > height) {
      maxDimension.toFloat() / width
    } else {
      maxDimension.toFloat() / height
    }

    val newWidth = (width * scale).toInt()
    val newHeight = (height * scale).toInt()

    return try {
      val scaledBitmap = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
      // Recycle old bitmap if it's different from the new one
      if (scaledBitmap != bitmap) {
        bitmap.recycle()
      }
      scaledBitmap
    } catch (e: Exception) {
      android.util.Log.e("LumiQrScannerPlugin", "Failed to scale bitmap", e)
      bitmap
    }
  }

  private fun scanImageFromBytes(imageBytes: ByteArray, result: Result) {
    try {
      val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)

      // Try multi-scale scanning for better detection
      scanImageMultiScale(bitmap, result)
    } catch (e: Exception) {
      result.error("SCAN_ERROR", "Failed to scan image: ${e.message}", null)
    }
  }

  private fun scanImage(image: InputImage, result: Result) {
    // Enhanced scanner options for better detection
    val options = BarcodeScannerOptions.Builder()
      .setBarcodeFormats(
        Barcode.FORMAT_QR_CODE,
        Barcode.FORMAT_AZTEC,
        Barcode.FORMAT_DATA_MATRIX,
        Barcode.FORMAT_PDF417,
        Barcode.FORMAT_CODE_128,
        Barcode.FORMAT_CODE_39,
        Barcode.FORMAT_CODE_93,
        Barcode.FORMAT_CODABAR,
        Barcode.FORMAT_EAN_13,
        Barcode.FORMAT_EAN_8,
        Barcode.FORMAT_ITF,
        Barcode.FORMAT_UPC_A,
        Barcode.FORMAT_UPC_E
      )
      .build()

    val scanner = BarcodeScanning.getClient(options)

    scanner.process(image)
      .addOnSuccessListener { barcodes ->
        if (barcodes.isEmpty()) {
          result.success(null)
        } else {
          val barcodeList = barcodes.map { barcode ->
            mapOf(
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
                "data" to null
              )
            )
          }
          result.success(barcodeList)
        }
      }
      .addOnFailureListener { e ->
        android.util.Log.e("LumiQrScannerPlugin", "Scan failed", e)
        result.error("SCAN_ERROR", "Failed to scan: ${e.message}", null)
      }
  }

  private fun hasCameraPermission(): Boolean {
    return ContextCompat.checkSelfPermission(
      context,
      Manifest.permission.CAMERA
    ) == PackageManager.PERMISSION_GRANTED
  }

  private fun requestCameraPermission(result: Result) {
    if (hasCameraPermission()) {
      result.success(true)
      return
    }

    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null)
      return
    }

    pendingResult = result
    ActivityCompat.requestPermissions(
      activity!!,
      arrayOf(Manifest.permission.CAMERA),
      CAMERA_PERMISSION_REQUEST_CODE
    )
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
      val granted = grantResults.isNotEmpty() &&
        grantResults[0] == PackageManager.PERMISSION_GRANTED
      pendingResult?.success(granted)
      pendingResult = null
      return true
    }
    return false
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
