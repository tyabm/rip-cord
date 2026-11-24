package com.ripcord.rip_cord

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.ripcord.rip_cord/activation"
    private val nudgeChannelName = "com.ripcord.rip_cord/nudge"
    private var initialLink: String? = null
    private var notificationPermissionResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initialLink = extractLink(intent)
        ExpectationNudgeScheduler.rescheduleAfterBoot(this)
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, nudgeChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> requestNotificationPermission(result)
                    "schedule" -> {
                        val checkId = call.argument<String>("checkId")
                        val title = call.argument<String>("title")
                        val body = call.argument<String>("body")
                        val triggerAt = call.argument<Number>("triggerAtMillis")?.toLong()
                        if (checkId == null || title == null || body == null || triggerAt == null) {
                            result.success(false)
                        } else {
                            result.success(
                                ExpectationNudgeScheduler.schedule(
                                    this,
                                    checkId,
                                    title,
                                    body,
                                    triggerAt,
                                ),
                            )
                        }
                    }
                    "cancel" -> {
                        val checkId = call.argument<String>("checkId")
                        if (checkId != null) {
                            ExpectationNudgeScheduler.cancel(this, checkId)
                        }
                        result.success(null)
                    }
                    "cancelAll" -> {
                        ExpectationNudgeScheduler.cancelAll(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (ExpectationNudgeScheduler.notificationsAllowed(this)) {
            result.success(true)
            return
        }
        if (Build.VERSION.SDK_INT < 33) {
            result.success(false)
            return
        }
        notificationPermissionResult?.success(false)
        notificationPermissionResult = result
        requestPermissions(
            arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_NOTIFICATIONS,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_NOTIFICATIONS) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED &&
            ExpectationNudgeScheduler.notificationsAllowed(this)
        notificationPermissionResult?.success(granted)
        notificationPermissionResult = null
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
        private const val REQUEST_NOTIFICATIONS = 4102
    }
}
