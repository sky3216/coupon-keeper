package com.example.coupon_keeper

import android.graphics.Rect
import android.net.Uri
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "coupon_keeper/ocr"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "recognizeText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val sourceRef = call.argument<String>("sourceRef")
                if (sourceRef.isNullOrBlank()) {
                    result.error("missing-source-ref", "A selected image reference is required.", null)
                    return@setMethodCallHandler
                }
                recognizeText(sourceRef, result)
            }
    }

    private fun recognizeText(sourceRef: String, result: MethodChannel.Result) {
        val image = try {
            InputImage.fromFilePath(this, Uri.parse(sourceRef))
        } catch (error: Exception) {
            result.error("invalid-source-ref", error.message, null)
            return
        }
        val latin = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        val korean = TextRecognition.getClient(
            KoreanTextRecognizerOptions.Builder().build(),
        )
        val tasks = listOf(latin.process(image), korean.process(image))

        Tasks.whenAllComplete(tasks).addOnCompleteListener {
            try {
                val recognized = tasks
                    .filter { task -> task.isSuccessful }
                    .mapNotNull { task -> task.result }
                if (recognized.isEmpty()) {
                    val message = tasks.firstNotNullOfOrNull { task -> task.exception?.message }
                    result.error("recognition-failed", message, null)
                    return@addOnCompleteListener
                }
                result.success(normalize(recognized, image.width, image.height))
            } finally {
                latin.close()
                korean.close()
            }
        }
    }

    private fun normalize(results: List<Text>, width: Int, height: Int): Map<String, Any?> {
        val seenBlocks = mutableSetOf<String>()
        val blocks = results.flatMap { recognized ->
            recognized.textBlocks.mapNotNull { block ->
                val key = block.text.trim()
                if (key.isEmpty() || !seenBlocks.add(key)) {
                    return@mapNotNull null
                }
                mapOf(
                    "text" to block.text,
                    "confidence" to null,
                    "bounds" to normalizedBounds(block.boundingBox, width, height),
                    "lines" to block.lines.map { line ->
                        mapOf(
                            "text" to line.text,
                            "confidence" to null,
                            "bounds" to normalizedBounds(line.boundingBox, width, height),
                        )
                    },
                )
            }
        }
        return mapOf(
            "fullText" to results.joinToString("\n") { recognized -> recognized.text },
            "blocks" to blocks,
        )
    }

    private fun normalizedBounds(rect: Rect?, width: Int, height: Int): Map<String, Double> {
        if (rect == null || width <= 0 || height <= 0) {
            return mapOf("left" to 0.0, "top" to 0.0, "width" to 0.0, "height" to 0.0)
        }
        return mapOf(
            "left" to rect.left.toDouble() / width,
            "top" to rect.top.toDouble() / height,
            "width" to rect.width().toDouble() / width,
            "height" to rect.height().toDouble() / height,
        )
    }
}
