package com.ninocss.untisplus

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

internal class NotificationChannelHandler(
    private val activity: MainActivity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, NativeChannelContract.NOTIFICATIONS)

    fun register() {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showProgressiveNotification" -> {
                    val arguments = call.arguments as? Map<String, Any?>
                    result.success(showProgressiveNotification(arguments))
                }
                else -> result.notImplemented()
            }
        }
    }

    fun dispatchAction(payload: Map<String, String?>) {
        channel.invokeMethod("onNotificationAction", payload)
    }

    private fun showProgressiveNotification(arguments: Map<String, Any?>?): Boolean {
        if (arguments == null) return false

        val id = (arguments["id"] as? Number)?.toInt() ?: 1
        val channelId = arguments["channelId"] as? String ?: "current_lesson_channel"
        val title = arguments["title"] as? String ?: ""
        val body = arguments["body"] as? String ?: ""
        val progress = (arguments["progress"] as? Number)?.toInt() ?: 0
        val maxProgress = (arguments["maxProgress"] as? Number)?.toInt() ?: 100
        val endTimeMs = (arguments["endTimeMs"] as? Number)?.toLong()
        val locale = arguments["locale"] as? String ?: "de"

        val manager = activity.getSystemService(NotificationManager::class.java) ?: return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = if (locale.startsWith("de")) "Aktuelle Stunde" else "Current Lesson"
            val notificationChannel = NotificationChannel(
                channelId,
                name,
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                setShowBadge(false)
            }
            manager.createNotificationChannel(notificationChannel)
        }

        val openAppIntent = Intent(activity, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(NativeChannelContract.ACTION_ID, "open_timetable")
        }
        val pendingIntent = PendingIntent.getActivity(
            activity,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = Notification.Builder(activity, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)
            .setProgress(maxProgress, progress, false)
            .setCategory(Notification.CATEGORY_PROGRESS)

        if (endTimeMs != null && endTimeMs > 0) {
            builder.setWhen(endTimeMs)
            builder.setUsesChronometer(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                builder.setChronometerCountDown(true)
            }
        }

        applyPlatformProgressStyle(builder, progress)
        manager.notify(id, builder.build())
        return true
    }

    /** Uses Android's new progress style when available without raising minSdk. */
    private fun applyPlatformProgressStyle(builder: Notification.Builder, progress: Int) {
        if (Build.VERSION.SDK_INT < 35) return
        try {
            val progressStyleClass = Class.forName("android.app.Notification\$ProgressStyle")
            val style = progressStyleClass.getDeclaredConstructor().newInstance()
            progressStyleClass
                .getMethod("setProgress", Long::class.javaPrimitiveType)
                .invoke(style, progress.toLong())

            try {
                val segmentClass = Class.forName("android.app.Notification\$ProgressStyle\$Segment")
                val segment = segmentClass
                    .getDeclaredConstructor(Long::class.javaPrimitiveType)
                    .newInstance(progress.toLong())
                progressStyleClass
                    .getMethod("setProgressSegments", List::class.java)
                    .invoke(style, listOf(segment))
            } catch (_: Exception) {
                // Segments are optional and changed between preview SDKs.
            }

            builder.setStyle(style as Notification.Style)
        } catch (_: Exception) {
            // Reflection keeps preview-only APIs from affecting older devices.
        }
    }
}
