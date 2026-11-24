package com.ripcord.rip_cord

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * One local reminder per pull, about two hours later.
 * Inexact on purpose: no exact-alarm permission. Not repeated.
 * If the phone is off when it is due, the boot receiver drops it
 * instead of delivering it late.
 */
object ExpectationNudgeScheduler {
    private const val PREFS = "expectation_nudge"
    private const val KEY_ID = "check_id"
    private const val KEY_TITLE = "title"
    private const val KEY_BODY = "body"
    private const val KEY_AT = "trigger_at"
    const val EXTRA_ID = "check_id"
    const val EXTRA_TITLE = "title"
    const val EXTRA_BODY = "body"
    private const val CHANNEL_ID = "expectation_check"
    private const val NOTIFICATION_ID = 2401
    private const val REQUEST_CODE = 2401

    fun schedule(
        context: Context,
        checkId: String,
        title: String,
        body: String,
        triggerAtMillis: Long,
    ): Boolean {
        if (checkId.isEmpty() || body.isEmpty()) return false
        if (triggerAtMillis <= System.currentTimeMillis()) return false
        if (!notificationsAllowed(context)) return false
        cancelCurrent(context)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_ID, checkId)
            .putString(KEY_TITLE, title)
            .putString(KEY_BODY, body)
            .putLong(KEY_AT, triggerAtMillis)
            .apply()
        return try {
            val alarm = context.getSystemService(AlarmManager::class.java)
            alarm.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingBroadcast(context, checkId, title, body),
            )
            true
        } catch (_: Exception) {
            clear(context)
            false
        }
    }

    fun cancel(context: Context, checkId: String) {
        val stored = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_ID, null)
        if (stored != null && stored != checkId) return
        cancelCurrent(context)
    }

    fun cancelAll(context: Context) {
        cancelCurrent(context)
    }

    fun rescheduleAfterBoot(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val id = prefs.getString(KEY_ID, null)
        val title = prefs.getString(KEY_TITLE, null)
        val body = prefs.getString(KEY_BODY, null)
        val at = prefs.getLong(KEY_AT, 0L)
        if (id.isNullOrEmpty() || title.isNullOrEmpty() || body.isNullOrEmpty()) {
            clear(context)
            return
        }
        if (at <= System.currentTimeMillis()) {
            clear(context)
            return
        }
        schedule(context, id, title, body, at)
    }

    fun show(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val id = intent.getStringExtra(EXTRA_ID) ?: prefs.getString(KEY_ID, null)
        val title = intent.getStringExtra(EXTRA_TITLE)
            ?: prefs.getString(KEY_TITLE, null)
            ?: "See if it was worth it"
        val body = intent.getStringExtra(EXTRA_BODY) ?: prefs.getString(KEY_BODY, null)
        clear(context)
        if (id.isNullOrEmpty() || body.isNullOrEmpty()) return
        if (!notificationsAllowed(context)) return

        val manager = context.getSystemService(NotificationManager::class.java)
        ensureChannel(manager)
        val open = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            action = Intent.ACTION_VIEW
            data = android.net.Uri.parse("ripcord://rate")
        }
        val content = PendingIntent.getActivity(
            context,
            REQUEST_CODE + 1,
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_ripcord)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setContentIntent(content)
            .build()
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun cancelCurrent(context: Context) {
        val alarm = context.getSystemService(AlarmManager::class.java)
        val intent = Intent(context, ExpectationNudgeReceiver::class.java)
        val pending = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (pending != null) {
            alarm.cancel(pending)
            pending.cancel()
        }
        clear(context)
    }

    private fun pendingBroadcast(
        context: Context,
        checkId: String,
        title: String,
        body: String,
    ): PendingIntent {
        val intent = Intent(context, ExpectationNudgeReceiver::class.java).apply {
            putExtra(EXTRA_ID, checkId)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun clear(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
    }

    private fun ensureChannel(manager: NotificationManager) {
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Expectation check",
            NotificationManager.IMPORTANCE_DEFAULT,
        )
        channel.description =
            "One optional reminder to rate whether an urge delivered. Off unless you turn it on in Rip-Cord."
        manager.createNotificationChannel(channel)
    }

    fun notificationsAllowed(context: Context): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java)
        val enabled = manager.areNotificationsEnabled()
        if (Build.VERSION.SDK_INT >= 33) {
            val granted = context.checkSelfPermission(
                android.Manifest.permission.POST_NOTIFICATIONS,
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
            return enabled && granted
        }
        return enabled
    }
}

class ExpectationNudgeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ExpectationNudgeScheduler.show(context, intent)
    }
}

class ExpectationNudgeBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        ExpectationNudgeScheduler.rescheduleAfterBoot(context)
    }
}
