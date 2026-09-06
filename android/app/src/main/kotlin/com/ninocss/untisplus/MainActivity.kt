package com.ninocss.untisplus

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.ComponentName
import android.content.pm.PackageManager
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val NOTIFICATION_CHANNEL = "untisplus/notifications"
        private const val UI_CHANNEL = "untisplus/ui"
        
        private const val EXTRA_ACTION_ID = "notification_action_id"
        private const val EXTRA_CURRENT_LESSON = "notification_current_lesson"
        private const val EXTRA_NEXT_LESSON = "notification_next_lesson"
    }

    private var notificationChannel: MethodChannel? = null
    private var uiChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Notification Channel for custom native actions
        notificationChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
        notificationChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showProgressiveNotification" -> {
                    val args = call.arguments as? Map<String, Any?>
                    result.success(showProgressiveNotification(args))
                }
                else -> result.notImplemented()
            }
        }

        // UI / System Effects Channel
        uiChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UI_CHANNEL)
        uiChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setWindowBlur" -> {
                    val radius = (call.arguments as? Number)?.toInt() ?: 0
                    applyWindowBlur(radius)
                    result.success(null)
                }
                "setLauncherIcon" -> {
                    val icon = call.arguments as? String
                    result.success(icon?.let { setLauncherIcon(it) } ?: false)
                }
                "getSupportedAbis" -> result.success(Build.SUPPORTED_ABIS.toList())
                "installApk" -> {
                    val path = (call.arguments as? Map<*, *>)?.get("path") as? String
                    if (path.isNullOrBlank()) {
                        result.error("invalid_path", "No APK path supplied.", null)
                    } else {
                        installApk(path, result)
                    }
                }
                else -> result.notImplemented()
            }
        }

        handleIntent(intent)
    }

    private fun applyWindowBlur(radius: Int) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        try {
            val method = window.javaClass.getMethod("setBackdropBlurRadius", Int::class.javaPrimitiveType)
            method.invoke(window, radius.coerceAtLeast(0))
        } catch (_: Exception) {}
    }

    private fun setLauncherIcon(icon: String): Boolean {
        val aliases = mapOf(
            "default" to ".IconDefault",
            "3d" to ".Icon3D",
            "chrom" to ".IconChrom",
            "galaxy" to ".IconGalaxy",
            "gradiant" to ".IconGradiant",
            "marmor" to ".IconMarmor",
            "paper" to ".IconPaper",
        )
        val target = aliases[icon] ?: return false
        val manager = packageManager
        aliases.values.forEach { alias ->
            manager.setComponentEnabledSetting(
                ComponentName(packageName, "$packageName$alias"),
                if (alias == target) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
        return true
    }

    /**
     * Opens the Android package installer for an APK that was downloaded into
     * the app cache. Keeping the file below cache/updates prevents arbitrary
     * paths received through the platform channel from being exposed.
     */
    private fun installApk(path: String, result: MethodChannel.Result) {
        val updatesDirectory = File(cacheDir, "updates").canonicalFile
        val apk = File(path).canonicalFile
        val isAllowedFile = apk.path.startsWith(updatesDirectory.path + File.separator) &&
            apk.isFile &&
            apk.name.endsWith(".apk", ignoreCase = true)
        if (!isAllowedFile) {
            result.error("invalid_path", "APK must be stored in the update cache.", null)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            result.success("permission")
            return
        }

        try {
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                apk,
            )
            val intent = Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            result.success("installer")
        } catch (error: Exception) {
            result.error("installer_failed", error.message, null)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == "com.ninocss.untisplus.OPEN_ASSISTANT" ||
            intent?.data?.host == "assistant") {
            uiChannel?.invokeMethod("openAssistant", intent?.data?.getQueryParameter("query"))
            intent?.action = null
            return
        }
        val actionId = intent?.getStringExtra(EXTRA_ACTION_ID) ?: return
        val payload = mapOf(
            "actionId" to actionId,
            "currentLesson" to intent.getStringExtra(EXTRA_CURRENT_LESSON),
            "nextLesson" to intent.getStringExtra(EXTRA_NEXT_LESSON)
        )
        notificationChannel?.invokeMethod("onNotificationAction", payload)
        
        // Clear extras to avoid re-triggering
        intent.removeExtra(EXTRA_ACTION_ID)
    }

    private fun showProgressiveNotification(args: Map<String, Any?>?): Boolean {
        if (args == null) return false
        
        val id = (args["id"] as? Number)?.toInt() ?: 1
        val channelId = args["channelId"] as? String ?: "current_lesson_channel"
        val title = args["title"] as? String ?: ""
        val body = args["body"] as? String ?: ""
        val progress = (args["progress"] as? Number)?.toInt() ?: 0
        val maxProgress = (args["maxProgress"] as? Number)?.toInt() ?: 100
        val endTimeMs = (args["endTimeMs"] as? Number)?.toLong()
        val locale = args["locale"] as? String ?: "de"

        val manager = getSystemService(NotificationManager::class.java) ?: return false
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = if (locale.startsWith("de")) "Aktuelle Stunde" else "Current Lesson"
            val channel = NotificationChannel(channelId, name, NotificationManager.IMPORTANCE_LOW).apply {
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_ACTION_ID, "open_timetable")
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = Notification.Builder(this, channelId)
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

        // Optional: High-end ProgressStyle reflection for Android 15/16+ (Vanir)
        // This is kept but made safer and only used if explicitly available.
        if (Build.VERSION.SDK_INT >= 35) {
            try {
                val progressStyleClass = Class.forName("android.app.Notification\$ProgressStyle")
                val style = progressStyleClass.getDeclaredConstructor().newInstance()
                progressStyleClass.getMethod("setProgress", Long::class.javaPrimitiveType).invoke(style, progress.toLong())
                
                // Set segments if reflection succeeds
                try {
                    val segmentClass = Class.forName("android.app.Notification\$ProgressStyle\$Segment")
                    val segmentCtor = segmentClass.getDeclaredConstructor(Long::class.javaPrimitiveType)
                    val completed = segmentCtor.newInstance(progress.toLong())
                    val setSegments = progressStyleClass.getMethod("setProgressSegments", List::class.java)
                    setSegments.invoke(style, listOf(completed))
                } catch (_: Exception) {}

                builder.setStyle(style as Notification.Style)
            } catch (_: Exception) {}
        }

        manager.notify(id, builder.build())
        return true
    }
}
