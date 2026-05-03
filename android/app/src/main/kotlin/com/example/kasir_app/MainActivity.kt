package com.example.kasir_app

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.kasir_app/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareToWhatsApp") {
                val phone = call.argument<String>("phone")
                val filePath = call.argument<String>("filePath")
                val text = call.argument<String>("text")
                
                try {
                    val intent = Intent(Intent.ACTION_SEND)
                    intent.type = "image/png"
                    intent.setPackage("com.whatsapp")
                    
                    if (phone != null && phone.isNotEmpty()) {
                        // WhatsApp uses JID to target a specific number
                        intent.putExtra("jid", "$phone@s.whatsapp.net")
                    }
                    if (text != null) {
                        intent.putExtra(Intent.EXTRA_TEXT, text)
                    }
                    if (filePath != null) {
                        val file = File(filePath)
                        val uri = FileProvider.getUriForFile(
                            context, 
                            "${context.packageName}.provider", 
                            file
                        )
                        intent.putExtra(Intent.EXTRA_STREAM, uri)
                        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        
                        // Explicitly grant permission to WhatsApp to avoid SecurityException
                        context.grantUriPermission("com.whatsapp", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    
                    val chooser = Intent.createChooser(intent, "Bagikan Struk")
                    startActivity(chooser)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
