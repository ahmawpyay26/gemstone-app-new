package com.gemstone.management

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.app.Activity
import java.io.OutputStreamWriter
import android.util.Base64

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.gemstone.management/backup"
    private var pendingResult: MethodChannel.Result? = null
    private val CREATE_DOCUMENT_REQUEST_CODE = 1001
    private val OPEN_DOCUMENT_REQUEST_CODE = 1002
    private var backupContent: String = ""
    private var isArchiveBackup: Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveBackupFile" -> {
                    val fileName = call.argument<String>("fileName") ?: return@setMethodCallHandler
                    val content = call.argument<String>("content") ?: return@setMethodCallHandler
                    val isArchive = call.argument<Boolean>("isArchive") ?: false
                    
                    pendingResult = result
                    backupContent = content
                    isArchiveBackup = isArchive
                    openSaveDialog(fileName)
                }
                "openRestoreFile" -> {
                    pendingResult = result
                    openRestoreDialog()
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

    private fun openRestoreDialog() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "application/octet-stream"))
            putExtra("android.content.extra.SHOW_ADVANCED", true)
        }
        
        startActivityForResult(intent, OPEN_DOCUMENT_REQUEST_CODE)
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
                            if (isArchiveBackup) {
                                // Decode base64 and write binary archive
                                try {
                                    val decodedBytes = Base64.decode(backupContent, Base64.DEFAULT)
                                    outputStream.write(decodedBytes)
                                    outputStream.flush()
                                } catch (e: IllegalArgumentException) {
                                    pendingResult?.error("DECODE_ERROR", "Failed to decode base64 content: ${e.message}", null)
                                    outputStream.close()
                                    pendingResult = null
                                    backupContent = ""
                                    isArchiveBackup = false
                                    return
                                }
                            } else {
                                // Write as plain text for legacy JSON backups
                                OutputStreamWriter(outputStream).use { writer ->
                                    writer.write(backupContent)
                                    writer.flush()
                                }
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
            isArchiveBackup = false
        } else if (requestCode == OPEN_DOCUMENT_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    try {
                        val inputStream = contentResolver.openInputStream(uri)
                        if (inputStream != null) {
                            // Read file as raw binary bytes
                            val fileBytes = inputStream.use { it.readBytes() }
                            
                            // Detect ZIP using magic signature: PK 03 04
                            val isArchive = fileBytes.size >= 4 &&
                                fileBytes[0] == 0x50.toByte() &&
                                fileBytes[1] == 0x4B.toByte() &&
                                fileBytes[2] == 0x03.toByte() &&
                                fileBytes[3] == 0x04.toByte()
                            
                            // If ZIP: Base64-encode the bytes; otherwise: decode as UTF-8 text
                            val content = if (isArchive) {
                                Base64.encodeToString(fileBytes, Base64.NO_WRAP)
                            } else {
                                fileBytes.toString(Charsets.UTF_8)
                            }
                            
                            val fileName = getFileNameFromUri(uri)
                            pendingResult?.success(mapOf(
                                "success" to true,
                                "fileName" to fileName,
                                "content" to content,
                                "isArchive" to isArchive
                            ))
                        } else {
                            pendingResult?.error("READ_ERROR", "Could not open input stream", null)
                        }
                    } catch (e: Exception) {
                        pendingResult?.error("READ_ERROR", e.message, null)
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
