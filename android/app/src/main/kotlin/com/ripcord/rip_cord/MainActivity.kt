package com.ripcord.rip_cord

import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.ripcord.rip_cord/activation"
    private var initialLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initialLink = extractLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val link = extractLink(intent)
        if (link != null) {
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, channelName).invokeMethod("onNewLink", link)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> result.success(initialLink)
                    "openSideKeySettings" -> result.success(openSideKeySettings())
                    else -> result.notImplemented()
                }
            }
    }

    private fun extractLink(intent: Intent?): String? {
        if (intent == null) return null
        val data = intent.data
        if (data != null && (data.scheme == "ripcord" || data.path?.contains("activate") == true)) {
            return data.toString()
        }
        // Fallback: custom extras from tile/widget
        val source = intent.getStringExtra(EXTRA_SOURCE)
        if (intent.getBooleanExtra(EXTRA_ACTIVATE, false) || source != null) {
            val src = source ?: "deepLink"
            return "ripcord://activate?source=$src"
        }
        return null
    }

    /** Best-effort open of Samsung One UI Side button / Side key settings. */
    private fun openSideKeySettings(): Boolean {
        val attempts = listOf(
            Intent("com.samsung.android.settings.action.SIDE_KEY_SETTINGS"),
            Intent().setComponent(
                ComponentName(
                    "com.android.settings",
                    "com.samsung.android.settings.usefulfeature.functionkey.FunctionKeySettings",
                ),
            ),
            Intent().setComponent(
                ComponentName(
                    "com.android.settings",
                    "com.samsung.android.settings.usefulfeature.UsefulfeatureHubActivity",
                ),
            ),
            Intent().setComponent(
                ComponentName(
                    "com.android.settings",
                    "com.samsung.android.settings.usefulfeature.UsefulfeatureActivity",
                ),
            ),
            Intent(Settings.ACTION_VOICE_INPUT_SETTINGS),
            Intent(Settings.ACTION_SETTINGS),
        )
        for (intent in attempts) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    return true
                }
            } catch (_: Exception) {
                // try next
            }
        }
        return false
    }

    companion object {
        const val EXTRA_ACTIVATE = "ripcord_activate"
        const val EXTRA_SOURCE = "ripcord_source"
    }
}
