package com.melvinjjoseph.offlinepocket

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val BACKUP_CHANNEL = "com.melvinjjoseph.offlinepocket/backup"
    }

    private var pendingBackupBytes: ByteArray? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Read the intent BEFORE super.onCreate() so the bytes are stored
        // before Flutter's main() calls consumePendingBackup via the channel.
        readBackupIntent(intent)
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        readBackupIntent(intent)
    }

    private fun readBackupIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val uri = intent.data ?: return
        try {
            pendingBackupBytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
        } catch (_: Exception) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKUP_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "consumePendingBackup") {
                    result.success(pendingBackupBytes)
                    pendingBackupBytes = null
                } else {
                    result.notImplemented()
                }
            }
    }
}
