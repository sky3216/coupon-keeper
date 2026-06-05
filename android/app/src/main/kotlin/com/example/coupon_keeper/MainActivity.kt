package com.example.coupon_keeper

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.database.Cursor
import android.graphics.Rect
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import java.io.File
import java.security.MessageDigest
import java.util.UUID
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
    private val ocrChannelName = "coupon_keeper/ocr"
    private val sourcePickerChannelName = "coupon_keeper/source_picker"
    private val sourceCleanupChannelName = "coupon_keeper/source_cleanup"
    private val photoRequestCode = 4101
    private val documentRequestCode = 4102
    private val folderRequestCode = 4103
    private var pendingPickResult: MethodChannel.Result? = null
    private var pendingSourceType: String? = null
    private val retryHandles = mutableMapOf<String, RetryableSource>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ocrChannelName)
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sourcePickerChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickSources" -> {
                        val sourceType = call.argument<String>("sourceType")
                        if (sourceType.isNullOrBlank()) {
                            result.error("missing-source-type", "A source type is required.", null)
                            return@setMethodCallHandler
                        }
                        pickSources(sourceType, result)
                    }
                    "retryFailures" -> {
                        val handles = call.argument<List<String>>("handles").orEmpty()
                        result.success(stageRetryHandles(handles))
                    }
                    "releaseSources" -> {
                        val sourceRefs = call.argument<List<String>>("sourceRefs").orEmpty()
                        val handles = call.argument<List<String>>("handles").orEmpty()
                        releaseSources(sourceRefs, handles)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sourceCleanupChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "openSource") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val originalUri = call.argument<String>("originalUri")
                if (originalUri.isNullOrBlank()) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                result.success(openOriginalSource(originalUri))
            }
    }

    private fun openOriginalSource(originalUri: String): Boolean {
        val uri = Uri.parse(originalUri)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "image/*")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }

    private fun pickSources(sourceType: String, result: MethodChannel.Result) {
        if (pendingPickResult != null) {
            result.error("picker-busy", "A source picker is already open.", null)
            return
        }
        pendingPickResult = result
        pendingSourceType = sourceType

        when (sourceType) {
            "photos" -> launchPhotoPicker()
            "downloads" -> launchDocumentPicker()
            "folder" -> launchFolderPicker()
            else -> {
                pendingPickResult = null
                pendingSourceType = null
                result.error("unknown-source-type", "Unknown source type: $sourceType", null)
            }
        }
    }

    private fun launchPhotoPicker() {
        // Android Photo Picker equivalent. The official Activity Result contract is
        // PickMultipleVisualMedia; this Activity keeps result handling in one place.
        val intent = if (Build.VERSION.SDK_INT >= 33) {
            Intent(MediaStore.ACTION_PICK_IMAGES).apply {
                type = "image/*"
                putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, 100)
            }
        } else {
            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "image/*"
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
        }
        startActivityForResult(intent, photoRequestCode)
    }

    private fun launchDocumentPicker() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }
        startActivityForResult(intent, documentRequestCode)
    }

    private fun launchFolderPicker() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        startActivityForResult(intent, folderRequestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val result = pendingPickResult ?: return
        val sourceType = pendingSourceType ?: "downloads"
        pendingPickResult = null
        pendingSourceType = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(mapOf("status" to "cancelled"))
            return
        }

        val payload = when (requestCode) {
            photoRequestCode, documentRequestCode -> stageSelectedUris(sourceType, extractUris(data))
            folderRequestCode -> stageSelectedFolder(data.data)
            else -> mapOf("status" to "fileUnavailable")
        }
        result.success(payload)
    }

    private fun extractUris(data: Intent): List<Uri> {
        val clipData = data.clipData
        if (clipData != null) {
            return (0 until clipData.itemCount).mapNotNull { index -> clipData.getItemAt(index).uri }
        }
        return listOfNotNull(data.data)
    }

    private fun stageSelectedFolder(treeUri: Uri?): Map<String, Any?> {
        if (treeUri == null) {
            return mapOf("status" to "fileUnavailable")
        }
        val childUris = mutableListOf<Uri>()
        val treeDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, treeDocumentId)
        contentResolver.query(
            childrenUri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE,
            ),
            null,
            null,
            null,
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
            val mimeIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
            while (cursor.moveToNext()) {
                val mimeType = cursor.getStringOrNull(mimeIndex)
                if (mimeType?.startsWith("image/") == true) {
                    val documentId = cursor.getString(idIndex)
                    childUris.add(DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId))
                }
            }
        }
        return stageSelectedUris("folder", childUris)
    }

    private fun stageSelectedUris(sourceType: String, uris: List<Uri>): Map<String, Any?> {
        val items = mutableListOf<Map<String, Any?>>()
        val failures = mutableListOf<Map<String, Any?>>()
        for (uri in uris) {
            val displayName = displayName(uri)
            try {
                items.add(stageUri(sourceType, uri, displayName))
            } catch (error: Exception) {
                val handle = UUID.randomUUID().toString()
                retryHandles[handle] = RetryableSource(uri, sourceType, displayName)
                failures.add(mapOf("handle" to handle, "displayName" to displayName))
            }
        }
        return mapOf("status" to "selected", "items" to items, "failures" to failures)
    }

    private fun stageRetryHandles(handles: List<String>): Map<String, Any?> {
        val retrySources = handles.mapNotNull { handle -> retryHandles[handle] }
        val items = mutableListOf<Map<String, Any?>>()
        val failures = mutableListOf<Map<String, Any?>>()
        for (source in retrySources) {
            try {
                items.add(stageUri(source.sourceType, source.uri, source.displayName))
            } catch (error: Exception) {
                val handle = UUID.randomUUID().toString()
                retryHandles[handle] = source
                failures.add(mapOf("handle" to handle, "displayName" to source.displayName))
            }
        }
        return mapOf("status" to "selected", "items" to items, "failures" to failures)
    }

    private fun releaseSources(sourceRefs: List<String>, handles: List<String>) {
        for (sourceRef in sourceRefs) {
            val uri = Uri.parse(sourceRef)
            if (uri.scheme == "file") {
                runCatching { File(uri.path ?: return@runCatching).delete() }
            }
        }
        for (handle in handles) {
            retryHandles.remove(handle)
        }
    }

    private fun stageUri(sourceType: String, uri: Uri, displayName: String): Map<String, Any?> {
        val selectedDir = File(cacheDir, "coupon-keeper-selected")
        selectedDir.mkdirs()
        val destination = File(selectedDir, "${UUID.randomUUID()}.image")
        val digest = MessageDigest.getInstance("SHA-256")
        var byteSize = 0L
        contentResolver.openInputStream(uri).use { input ->
            if (input == null) {
                throw IllegalStateException("Selected image could not be opened.")
            }
            destination.outputStream().use { output ->
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                while (true) {
                    val read = input.read(buffer)
                    if (read < 0) break
                    digest.update(buffer, 0, read)
                    output.write(buffer, 0, read)
                    byteSize += read
                }
            }
        }
        return mapOf(
            "sourceType" to sourceType,
            "sourceToken" to "sha256:${digest.digest().toHex()}",
            "platformSourceRef" to destination.toURI().toString(),
            "displayName" to displayName,
            "byteSize" to byteSize,
            "modifiedAt" to null,
        )
    }

    private fun displayName(uri: Uri): String {
        var name: String? = null
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor: Cursor ->
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0) {
                        name = cursor.getString(index)
                    }
                }
            }
        return name ?: "selected-image"
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

private data class RetryableSource(
    val uri: Uri,
    val sourceType: String,
    val displayName: String,
)

private fun Cursor.getStringOrNull(index: Int): String? {
    if (index < 0 || isNull(index)) {
        return null
    }
    return getString(index)
}

private fun ByteArray.toHex(): String {
    return joinToString("") { byte -> "%02x".format(byte) }
}
