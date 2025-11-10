package com.example.lian

import android.content.ContentValues
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "video_generator_app/save"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveVideo") {
                val path = call.argument<String>("path")!!
                val success = saveVideoToGallery(path)
                if (success) result.success(true) else result.error("ERROR", "Failed to save video", null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveVideoToGallery(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            val values = ContentValues().apply {
                put(MediaStore.Video.Media.DISPLAY_NAME, file.name)
                put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/AI Videos")
                }
            }

            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)
            if (uri != null) {
                val outStream: OutputStream? = resolver.openOutputStream(uri)
                val inStream = FileInputStream(file)
                inStream.copyTo(outStream!!)
                inStream.close()
                outStream.close()
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
