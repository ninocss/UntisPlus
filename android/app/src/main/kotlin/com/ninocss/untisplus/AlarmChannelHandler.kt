package com.ninocss.untisplus

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

internal class AlarmChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger,
    private val activity: MainActivity? = context as? MainActivity,
) {
    companion object {
        private const val RINGTONE_PICK_REQUEST = 8341
    }

    private val channel = MethodChannel(messenger, NativeChannelContract.ALARM)
    private var ringtoneResult: MethodChannel.Result? = null

    fun register() {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "replacePlans" -> {
                    val maps = (call.arguments as? Map<*, *>)?.get("plans") as? List<*>
                    val plans = JSONArray()
                    maps?.forEach { value ->
                        if (value is Map<*, *>) plans.put(JSONObject(value))
                    }
                    result.success(AlarmScheduler.replacePlans(context, plans))
                }
                "getReadiness" -> result.success(readiness(context))
                "openPermissionSettings" -> {
                    val type = (call.arguments as? Map<*, *>)?.get("type") as? String
                    openPermissionSettings(type)
                    result.success(null)
                }
                "pickRingtone" -> pickRingtone(call.arguments as? Map<*, *>, result)
                else -> result.notImplemented()
            }
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != RINGTONE_PICK_REQUEST) return
        val pendingResult = ringtoneResult ?: return
        ringtoneResult = null
        val uri = if (resultCode == Activity.RESULT_OK) {
            @Suppress("DEPRECATION")
            data?.getParcelableExtra<Uri>(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)?.toString()
        } else {
            null
        }
        pendingResult.success(uri)
    }

    private fun readiness(target: Context): Map<String, Boolean> {
        val manager = target.getSystemService(NotificationManager::class.java)
        val fullScreenAllowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            manager.canUseFullScreenIntent()
        } else {
            true
        }
        return mapOf(
            "exactAlarms" to AlarmScheduler.canScheduleExact(target),
            "fullScreenIntent" to fullScreenAllowed,
            "dndAccess" to manager.isNotificationPolicyAccessGranted,
            "notifications" to (
                Build.VERSION.SDK_INT < Build.VERSION_CODES.N || manager.areNotificationsEnabled()
            ),
        )
    }

    private fun openPermissionSettings(type: String?) {
        val activity = activity ?: return
        val intent = when (type) {
            "exact" -> Intent(
                Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                Uri.parse("package:${activity.packageName}"),
            )
            "fullscreen" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                Intent(
                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                    Uri.parse("package:${activity.packageName}"),
                )
            } else {
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:${activity.packageName}"),
                )
            }
            "dnd" -> Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            else -> Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:${activity.packageName}"),
            )
        }
        try {
            activity.startActivity(intent)
        } catch (_: Exception) {
            // The settings page differs across Android vendors.
        }
    }

    private fun pickRingtone(args: Map<*, *>?, result: MethodChannel.Result) {
        val activity = activity
        if (activity == null) {
            result.error("activity_unavailable", "Ringtone picker requires a foreground activity.", null)
            return
        }
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
            activity.startActivityForResult(intent, RINGTONE_PICK_REQUEST)
        } catch (error: Exception) {
            ringtoneResult = null
            result.error("picker_failed", error.message, null)
        }
    }
}
