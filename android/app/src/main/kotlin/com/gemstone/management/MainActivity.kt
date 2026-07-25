package com.gemstone.management

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.app.Activity
import java.io.OutputStreamWriter

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.gemstone.management/backup"
    private var pendingResult: MethodChannel.Result? = null
    private val CREATE_DOCUMENT_REQUEST_CODE = 1001
    private var backupContent: String = ""

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveBackupFile" -> {
                    val fileName = call.argument<String>("fileName") ?: return@setMethodCallHandler
                    val content = call.argument<String>("content") ?: return@setMethodCallHandler
                    
                    pendingResult = result
                    backupContent = content
                    openSaveDialog(fileName)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openSaveDialog(fileName: String) {
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/octet-stream"
            putExtra(Intent.EXTRA_TITLE, fileName)
            putExtra("android.content.extra.SHOW_ADVANCED", true)
        }
        
        startActivityForResult(intent, CREATE_DOCUMENT_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == CREATE_DOCUMENT_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    try {
                        val outputStream = contentResolver.openOutputStream(uri)
                        if (outputStream != null) {
                            OutputStreamWriter(outputStream).use { writer ->
                                writer.write(backupContent)
                                writer.flush()
                            }
                            outputStream.close()
                            
                            val fileName = getFileNameFromUri(uri)
                            pendingResult?.success(mapOf(
                                "success" to true,
                                "fileName" to fileName,
                                "uri" to uri.toString()
                            ))
                        } else {
                            pendingResult?.error("WRITE_ERROR", "Could not open output stream", null)
                        }
                    } catch (e: Exception) {
                        pendingResult?.error("WRITE_ERROR", e.message, null)
                    }
                } else {
                    pendingResult?.error("NO_URI", "No URI returned from file picker", null)
                }
            } else if (resultCode == Activity.RESULT_CANCELED) {
                pendingResult?.success(mapOf("success" to false, "cancelled" to true))
            } else {
                pendingResult?.error("UNKNOWN_ERROR", "Unknown error occurred", null)
            }
            
            pendingResult = null
            backupContent = ""
        }
    }

    private fun getFileNameFromUri(uri: Uri): String {
        var fileName = "backup.gmbak"
        
        try {
            val cursor = contentResolver.query(uri, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                    if (nameIndex >= 0) {
                        fileName = it.getString(nameIndex)
                    }
                }
            }
        } catch (e: Exception) {
            // Use default fileName if query fails
        }
        
        return fileName
    }
}
