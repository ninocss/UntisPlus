package com.ninocss.untisplus

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentValues
import android.content.ContentUris
import android.content.Intent
import android.content.ComponentName
import android.content.pm.PackageManager
import android.database.Cursor
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.provider.CalendarContract
import android.provider.Settings
import android.media.RingtoneManager
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    companion object {
        private const val NOTIFICATION_CHANNEL = "untisplus/notifications"
        private const val UI_CHANNEL = "untisplus/ui"
        private const val ALARM_CHANNEL = "untisplus/alarm"
        private const val CALENDAR_CHANNEL = "untisplus/calendar"
        private const val RINGTONE_PICK_REQUEST = 8341
        
        private const val EXTRA_ACTION_ID = "notification_action_id"
        private const val EXTRA_CURRENT_LESSON = "notification_current_lesson"
        private const val EXTRA_NEXT_LESSON = "notification_next_lesson"
    }

    private var notificationChannel: MethodChannel? = null
    private var uiChannel: MethodChannel? = null
    private var alarmChannel: MethodChannel? = null
    private var calendarChannel: MethodChannel? = null
    private var ringtoneResult: MethodChannel.Result? = null

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

        // Alarm Channel
        alarmChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
        alarmChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "replacePlans" -> {
                    val maps = (call.arguments as? Map<*, *>)?.get("plans") as? List<*>
                    val plans = org.json.JSONArray()
                    maps?.forEach { value ->
                        if (value is Map<*, *>) plans.put(org.json.JSONObject(value))
                    }
                    AlarmScheduler.replacePlans(this, plans)
                    result.success(null)
                }
                "getReadiness" -> result.success(alarmReadiness())
                "openPermissionSettings" -> {
                    val type = (call.arguments as? Map<*, *>)?.get("type") as? String
                    openAlarmPermissionSettings(type)
                    result.success(null)
                }
                "pickRingtone" -> pickAlarmRingtone(call.arguments as? Map<*, *>, result)
                else -> result.notImplemented()
            }
        }

        // Calendar Channel
        calendarChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALENDAR_CHANNEL)
        calendarChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getCalendars" -> result.success(getCalendars())
                "createCalendar" -> {
                    val name = call.argument<String>("name") ?: "Untis+ Calendar"
                    val color = call.argument<String>("color") ?: "#FF0000"
                    val accountName = call.argument<String>("accountName") ?: "Untis+"
                    result.success(createCalendar(name, color, accountName))
                }
                "getEvents" -> {
                    val calendarId = call.argument<String>("calendarId")
                    val startMs = call.argument<Long>("startMs") ?: 0
                    val endMs = call.argument<Long>("endMs") ?: 0
                    result.success(getEvents(calendarId, startMs, endMs))
                }
                "deleteEvent" -> {
                    val calendarId = call.argument<String>("calendarId") ?: ""
                    val eventId = call.argument<String>("eventId") ?: ""
                    result.success(deleteEvent(calendarId, eventId))
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

    private fun alarmReadiness(): Map<String, Boolean> {
        val manager = getSystemService(NotificationManager::class.java)
        val fullScreenAllowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            manager.canUseFullScreenIntent()
        } else true
        return mapOf(
            "exactAlarms" to AlarmScheduler.canScheduleExact(this),
            "fullScreenIntent" to fullScreenAllowed,
            "dndAccess" to manager.isNotificationPolicyAccessGranted,
            "notifications" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.N || manager.areNotificationsEnabled()),
        )
    }

    private fun openAlarmPermissionSettings(type: String?) {
        val intent = when (type) {
            "exact" -> Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName"))
            "fullscreen" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, Uri.parse("package:$packageName"))
            } else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
            "dnd" -> Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            else -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
        }
        try { startActivity(intent) } catch (_: Exception) {}
    }

    private fun pickAlarmRingtone(args: Map<*, *>?, result: MethodChannel.Result) {
        if (ringtoneResult != null) {
            result.error("picker_busy", "The ringtone picker is already open.", null)
            return
        }
        val current = args?.get("currentUri") as? String
        ringtoneResult = result
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            if (!current.isNullOrBlank()) {
                putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(current))
            }
        }
        try {
            startActivityForResult(intent, RINGTONE_PICK_REQUEST)
        } catch (error: Exception) {
            ringtoneResult = null
            result.error("picker_failed", error.message, null)
        }
    }

    @Deprecated("Deprecated in AndroidX Activity but required by FlutterActivity's current host API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != RINGTONE_PICK_REQUEST) return
        val result = ringtoneResult ?: return
        ringtoneResult = null
        val uri = if (resultCode == RESULT_OK) {
            data?.getParcelableExtra<Uri>(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)?.toString()
        } else null
        result.success(uri)
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

    private fun getCalendars(): List<Map<String, Any>> {
        val calendars = mutableListOf<Map<String, Any>>()
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.CALENDAR_COLOR,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.ACCOUNT_TYPE,
            CalendarContract.Calendars.OWNER_ACCOUNT,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL
        )

        val cursor = contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            "${CalendarContract.Calendars.VISIBLE} = 1",
            null,
            "${CalendarContract.Calendars.CALENDAR_DISPLAY_NAME} ASC"
        )

        cursor?.use { c ->
            android.util.Log.d("UntisPlus", "getCalendars: found ${c.count} calendars")
            while (c.moveToNext()) {
                val id = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Calendars._ID)).toString()
                val name = c.getString(c.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME)) ?: "Unknown"
                val color = c.getInt(c.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_COLOR))
                val accountName = c.getString(c.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_NAME)) ?: ""
                val accountType = c.getString(c.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_TYPE)) ?: ""
                val ownerAccount = c.getString(c.getColumnIndexOrThrow(CalendarContract.Calendars.OWNER_ACCOUNT)) ?: ""
                val accessLevel = c.getInt(c.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL))

                val isReadOnly = accessLevel < CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR
                val isDefault = ownerAccount == accountName && accountType == "com.google"

                android.util.Log.d("UntisPlus", "Calendar: id=$id, name=$name, accountName=$accountName, accountType=$accountType, isReadOnly=$isReadOnly, isDefault=$isDefault")

                calendars.add(mapOf(
                    "id" to id,
                    "name" to name,
                    "color" to String.format("#%06X", (0xFFFFFF and color)),
                    "accountName" to accountName,
                    "accountType" to accountType,
                    "isReadOnly" to isReadOnly,
                    "isDefault" to isDefault
                ))
            }
        }

        return calendars
    }

    private fun createCalendar(name: String, colorHex: String, accountName: String): String? {
        val values = ContentValues().apply {
            put(CalendarContract.Calendars.NAME, name)
            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, name)
            put(CalendarContract.Calendars.ACCOUNT_NAME, accountName)
            put(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
            put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_OWNER)
            put(CalendarContract.Calendars.CALENDAR_COLOR, Color.parseColor(colorHex))
            put(CalendarContract.Calendars.OWNER_ACCOUNT, accountName)
            put(CalendarContract.Calendars.CALENDAR_TIME_ZONE, java.util.TimeZone.getDefault().id)
            put(CalendarContract.Calendars.VISIBLE, 1)
            put(CalendarContract.Calendars.SYNC_EVENTS, 1)
        }

        try {
            val uri = contentResolver.insert(
                CalendarContract.Calendars.CONTENT_URI.buildUpon()
                    .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
                    .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, accountName)
                    .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
                    .build(),
                values
            )
            val id = uri?.lastPathSegment
            android.util.Log.d("UntisPlus", "Created calendar: $name with id: $id")
            return id
        } catch (e: Exception) {
            android.util.Log.e("UntisPlus", "Failed to create calendar: ${e.message}")
            // Fallback: try without CALLER_IS_SYNCADAPTER
            try {
                val uri = contentResolver.insert(CalendarContract.Calendars.CONTENT_URI, values)
                val id = uri?.lastPathSegment
                android.util.Log.d("UntisPlus", "Created calendar (fallback): $name with id: $id")
                return id
            } catch (e2: Exception) {
                android.util.Log.e("UntisPlus", "Failed to create calendar (fallback): ${e2.message}")
                return null
            }
        }
    }

    private fun getEvents(calendarId: String?, startMs: Long, endMs: Long): List<Map<String, Any>> {
        val events = mutableListOf<Map<String, Any>>()
        val projection = arrayOf(
            CalendarContract.Events._ID,
            CalendarContract.Events.TITLE,
            CalendarContract.Events.DESCRIPTION,
            CalendarContract.Events.DTSTART,
            CalendarContract.Events.DTEND,
            CalendarContract.Events.EVENT_LOCATION,
            CalendarContract.Events.CALENDAR_ID,
            CalendarContract.Events.RRULE,
            CalendarContract.Events.STATUS
        )

        val selection = StringBuilder()
        val selectionArgs = mutableListOf<String>()

        if (calendarId != null && calendarId.isNotEmpty()) {
            selection.append("${CalendarContract.Events.CALENDAR_ID} = ?")
            selectionArgs.add(calendarId)
        }

        if (startMs > 0) {
            if (selection.isNotEmpty()) selection.append(" AND ")
            selection.append("${CalendarContract.Events.DTEND} >= ?")
            selectionArgs.add(startMs.toString())
        }
        if (endMs > 0) {
            if (selection.isNotEmpty()) selection.append(" AND ")
            selection.append("${CalendarContract.Events.DTSTART} <= ?")
            selectionArgs.add(endMs.toString())
        }

        val cursor = contentResolver.query(
            CalendarContract.Events.CONTENT_URI,
            projection,
            if (selection.isNotEmpty()) selection.toString() else null,
            selectionArgs.toTypedArray(),
            "${CalendarContract.Events.DTSTART} ASC"
        )

        cursor?.use { c ->
            while (c.moveToNext()) {
                val id = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Events._ID)).toString()
                val title = c.getString(c.getColumnIndexOrThrow(CalendarContract.Events.TITLE)) ?: ""
                val description = c.getString(c.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION)) ?: ""
                val start = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Events.DTSTART))
                val end = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Events.DTEND))
                val location = c.getString(c.getColumnIndexOrThrow(CalendarContract.Events.EVENT_LOCATION)) ?: ""
                val calId = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Events.CALENDAR_ID)).toString()
                val rrule = c.getString(c.getColumnIndexOrThrow(CalendarContract.Events.RRULE)) ?: ""
                val status = c.getInt(c.getColumnIndexOrThrow(CalendarContract.Events.STATUS))

                events.add(mapOf(
                    "id" to id,
                    "title" to title,
                    "description" to description,
                    "start" to start,
                    "end" to end,
                    "location" to location,
                    "calendarId" to calId,
                    "rrule" to rrule,
                    "status" to status
                ))
            }
        }
        return events
    }

    private fun deleteEvent(calendarId: String, eventId: String): Boolean {
        val uri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId.toLong())
        val rowsDeleted = contentResolver.delete(uri, null, null)
        return rowsDeleted > 0
    }
}
