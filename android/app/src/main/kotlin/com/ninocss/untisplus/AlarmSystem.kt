package com.ninocss.untisplus

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.Space
import android.widget.TextView
import androidx.core.content.ContextCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.UUID

private fun planCopy(plan: JSONObject, key: String, fallback: String): String =
    plan.optJSONObject("nativeCopy")?.optString(key)?.takeIf { it.isNotBlank() } ?: fallback

private fun planCopyFormat(plan: JSONObject, key: String, fallback: String, name: String, value: Any): String =
    planCopy(plan, key, fallback).replace("{$name}", value.toString())

private fun parseAlarmPlan(raw: String?): JSONObject? {
    if (raw.isNullOrBlank()) return null
    return try {
        JSONObject(raw)
    } catch (_: Exception) {
        null
    }
}

private fun parseAlarmPlanOrEmpty(raw: String?): JSONObject = parseAlarmPlan(raw) ?: JSONObject()

/** Native, durable scheduling layer. Dart supplies configuration; Android owns wake-up. */
object AlarmScheduler {
    const val alarmAction = "com.ninocss.untisplus.ALARM_RING"
    const val refreshAction = "com.ninocss.untisplus.ALARM_PRE_WAKE_REFRESH"
    const val reminderAction = "com.ninocss.untisplus.ALARM_UPCOMING_REMINDER"
    const val reminderDisableAction = "com.ninocss.untisplus.ALARM_REMINDER_DISABLE"
    const val extraPlan = "alarm_plan"
    const val extraAlarmId = "alarm_id"
    const val extraSessionId = "alarm_session_id"
    private const val prefsName = "untis_alarm_native"
    private const val plansKey = "plans"
    private const val suppressedSmartDateKey = "suppressed_smart_date"

    private fun prefs(context: Context) = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
    private fun alarmManager(context: Context) = context.getSystemService(AlarmManager::class.java)
    private fun requestCode(id: String, suffix: Int = 0) = 0x55aa0000 xor id.hashCode() xor suffix

    fun replacePlans(context: Context, plans: JSONArray): Map<String, Any> {
        val previous = storedPlans(context)
        // Desired state is durable before PendingIntents are changed.
        prefs(context).edit().putString(plansKey, plans.toString()).commit()
        val missing = missingRequiredPermissions(context)
        if (missing.isNotEmpty()) {
            cancelPlans(context, previous)
            cancelPlans(context, plans)
            return schedulingResult(plans.length(), 0, missing)
        }

        var scheduled = 0
        for (index in 0 until plans.length()) {
            if (schedulePlan(context, plans.optJSONObject(index) ?: continue)) scheduled++
        }
        if (scheduled != plans.length()) {
            // Preserve the previous safety net when any desired replacement
            // could not be installed. A later restore retries from saved data.
            return schedulingResult(plans.length(), scheduled, emptyList())
        }
        val currentIds = (0 until plans.length()).mapNotNull {
            plans.optJSONObject(it)?.optString("id")?.takeIf(String::isNotBlank)
        }.toSet()
        val previousIds = (0 until previous.length()).mapNotNull {
            previous.optJSONObject(it)?.optString("id")?.takeIf(String::isNotBlank)
        }.toSet()
        val staleIds = AlarmPolicy.staleIds(previousIds, currentIds)
        // New and changed alarms are now installed; only stale identities go.
        for (index in 0 until previous.length()) {
            val plan = previous.optJSONObject(index) ?: continue
            if (plan.optString("id") in staleIds) cancelPlan(context, plan.optString("id"))
        }
        return schedulingResult(plans.length(), scheduled, emptyList())
    }

    fun scheduleStoredPlans(context: Context): Map<String, Any> {
        val plans = storedPlans(context)
        val missing = missingRequiredPermissions(context)
        if (missing.isNotEmpty()) {
            cancelPlans(context, plans)
            return schedulingResult(plans.length(), 0, missing)
        }
        var scheduled = 0
        for (index in 0 until plans.length()) {
            val plan = plans.optJSONObject(index) ?: continue
            if (schedulePlan(context, plan)) scheduled++
        }
        return schedulingResult(plans.length(), scheduled, emptyList())
    }

    private fun schedulingResult(stored: Int, scheduled: Int, missing: List<String>) = mapOf(
        "status" to when {
            missing.isNotEmpty() -> "paused_missing_permission"
            scheduled == stored -> "scheduled_exact"
            else -> "scheduling_failed"
        },
        "exactScheduled" to (missing.isEmpty() && scheduled == stored),
        "paused" to missing.isNotEmpty(),
        "storedCount" to stored,
        "scheduledCount" to scheduled,
        "missingPermissions" to missing,
    )

    private fun missingRequiredPermissions(context: Context): List<String> = buildList {
        if (!canScheduleExact(context)) add("exactAlarms")
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && !manager.areNotificationsEnabled()) {
            add("notifications")
        }
    }

    fun canActivate(context: Context): Boolean = missingRequiredPermissions(context).isEmpty()

    private fun cancelPlans(context: Context, plans: JSONArray) {
        for (index in 0 until plans.length()) {
            cancelPlan(context, plans.optJSONObject(index)?.optString("id") ?: "")
        }
    }

    fun removeOneShotPlan(context: Context, id: String) {
        val original = storedPlans(context)
        val remaining = JSONArray()
        for (index in 0 until original.length()) {
            val plan = original.optJSONObject(index) ?: continue
            if (plan.optString("id") == id) {
                cancelPlan(context, id)
            } else {
                remaining.put(plan)
            }
        }
        prefs(context).edit().putString(plansKey, remaining.toString()).apply()
    }

    fun planById(context: Context, id: String): JSONObject? {
        val plans = storedPlans(context)
        for (index in 0 until plans.length()) {
            val plan = plans.optJSONObject(index) ?: continue
            if (plan.optString("id") == id) return plan
        }
        return null
    }

    fun suppressSmartDate(context: Context, dateKey: String) {
        prefs(context).edit().putString(suppressedSmartDateKey, dateKey).commit()
        val plans = storedPlans(context)
        for (index in 0 until plans.length()) {
            val plan = plans.optJSONObject(index) ?: continue
            if (plan.optString("kind") == "smart" && plan.optString("dateKey") == dateKey) {
                cancelPlan(context, plan.optString("id"))
            }
        }
    }

    private fun storedPlans(context: Context): JSONArray = try {
        JSONArray(prefs(context).getString(plansKey, "[]"))
    } catch (_: Exception) {
        JSONArray()
    }

    private fun schedulePlan(context: Context, plan: JSONObject): Boolean {
        val id = plan.optString("id")
        if (id.isBlank()) return false
        if (plan.optString("kind") == "smart" &&
            plan.optString("dateKey") == prefs(context).getString(suppressedSmartDateKey, "")) {
            return false
        }
        val triggerAt = if (plan.optString("kind") == "manual") {
            nextRecurringTrigger(plan)
        } else {
            plan.optLong("triggerAtMillis", 0L)
        }
        if (triggerAt <= System.currentTimeMillis()) return false
        val intent = Intent(context, AlarmReceiver::class.java)
            .setAction(alarmAction)
            .setData(pendingIntentUri(id, "ring"))
            .putExtra(extraPlan, plan.toString())
        val operation = PendingIntent.getBroadcast(
            context,
            requestCode(id),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val showIntent = PendingIntent.getActivity(
            context,
            requestCode(id, 1),
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        if (!scheduleWakeup(context, triggerAt, operation, showIntent)) return false

        val reminderMinutes = plan.optInt("preAlarmNotificationMinutes", 30).coerceIn(0, 180)
        val reminderAt = triggerAt - reminderMinutes * 60_000L
        // Timetable alarms are deliberately gated by AlarmRefreshService: a
        // stale plan must never post a heads-up while today's refresh is still
        // in flight. Manual alarms have no timetable dependency.
        if (plan.optString("kind") != "smart" && reminderMinutes > 0 && reminderAt > System.currentTimeMillis()) {
            val reminderOperation = PendingIntent.getBroadcast(
                context,
                requestCode(id, 3),
                Intent(context, AlarmReminderReceiver::class.java)
                    .setAction(reminderAction)
                    .setData(pendingIntentUri(id, "reminder"))
                    .putExtra(extraPlan, plan.toString()),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            scheduleWakeup(
                context,
                reminderAt,
                reminderOperation,
            )
        } else {
            cancelAuxiliary(context, id, 3, AlarmReminderReceiver::class.java, reminderAction, "reminder")
        }

        if (plan.optString("kind") == "smart") {
            val refreshAt = plan.optLong("preRefreshAtMillis", 0L)
            if (refreshAt > System.currentTimeMillis()) {
                val refreshIntent = Intent(context, AlarmPreWakeRefreshReceiver::class.java)
                    .setAction(refreshAction)
                    .setData(pendingIntentUri(id, "refresh"))
                    .putExtra(extraAlarmId, id)
                val refreshOperation = PendingIntent.getBroadcast(
                    context,
                    requestCode(id, 2),
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                scheduleWakeup(
                    context,
                    refreshAt,
                    refreshOperation,
                )
            } else {
                cancelAuxiliary(context, id, 2, AlarmPreWakeRefreshReceiver::class.java, refreshAction, "refresh")
            }
        } else {
            cancelAuxiliary(context, id, 2, AlarmPreWakeRefreshReceiver::class.java, refreshAction, "refresh")
        }
        return true
    }

    private fun nextRecurringTrigger(plan: JSONObject): Long {
        val minutes = plan.optInt("timeOfDayMinutes", 420).coerceIn(0, 1439)
        val weekdayValues = plan.optJSONArray("weekdays") ?: JSONArray()
        val weekdays = (0 until weekdayValues.length()).mapNotNull { index ->
            weekdayValues.optInt(index, 0).takeIf { it in 1..7 }
        }.toSet()
        val calendar = Calendar.getInstance()
        for (offset in 0..7) {
            val candidate = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, offset)
                set(Calendar.HOUR_OF_DAY, minutes / 60)
                set(Calendar.MINUTE, minutes % 60)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            // Calendar starts on Sunday (1), Dart DateTime.weekday starts Monday (1).
            val dartWeekday = if (candidate.get(Calendar.DAY_OF_WEEK) == Calendar.SUNDAY) 7
            else candidate.get(Calendar.DAY_OF_WEEK) - 1
            if (dartWeekday in weekdays && candidate.timeInMillis > calendar.timeInMillis) {
                return candidate.timeInMillis
            }
        }
        return 0L
    }

    private fun cancelPlan(context: Context, id: String) {
        if (id.isBlank()) return
        val manager = alarmManager(context)
        val alarmIntent = PendingIntent.getBroadcast(
            context,
            requestCode(id),
            Intent(context, AlarmReceiver::class.java)
                .setAction(alarmAction)
                .setData(pendingIntentUri(id, "ring")),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (alarmIntent != null) manager.cancel(alarmIntent)
        val refreshIntent = PendingIntent.getBroadcast(
            context,
            requestCode(id, 2),
            Intent(context, AlarmPreWakeRefreshReceiver::class.java)
                .setAction(refreshAction)
                .setData(pendingIntentUri(id, "refresh")),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (refreshIntent != null) manager.cancel(refreshIntent)
        val reminderIntent = PendingIntent.getBroadcast(
            context,
            requestCode(id, 3),
            Intent(context, AlarmReminderReceiver::class.java)
                .setAction(reminderAction)
                .setData(pendingIntentUri(id, "reminder")),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (reminderIntent != null) manager.cancel(reminderIntent)
    }

    private fun cancelAuxiliary(
        context: Context,
        id: String,
        suffix: Int,
        receiver: Class<out BroadcastReceiver>,
        action: String,
        role: String,
    ) {
        val operation = PendingIntent.getBroadcast(
            context,
            requestCode(id, suffix),
            Intent(context, receiver).setAction(action).setData(pendingIntentUri(id, role)),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (operation != null) alarmManager(context).cancel(operation)
    }

    fun scheduleSnooze(context: Context, plan: JSONObject, minutes: Int) {
        if (!canActivate(context)) return
        val triggerAt = AlarmPolicy.snoozeTriggerAt(System.currentTimeMillis(), minutes)
        val snoozePlan = JSONObject(plan.toString()).apply {
            put("id", "${plan.optString("id")}-snooze-$triggerAt")
            put("kind", "snooze")
            put("triggerAtMillis", triggerAt)
        }
        val operation = PendingIntent.getBroadcast(
            context,
            requestCode(snoozePlan.getString("id")),
            Intent(context, AlarmReceiver::class.java)
                .setAction(alarmAction)
                .setData(pendingIntentUri(snoozePlan.getString("id"), "ring"))
                .putExtra(extraPlan, snoozePlan.toString()),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val showIntent = PendingIntent.getActivity(
            context,
            requestCode(snoozePlan.getString("id"), 1),
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        scheduleWakeup(context, triggerAt, operation, showIntent)
    }

    private fun scheduleWakeup(
        context: Context,
        triggerAt: Long,
        operation: PendingIntent,
        showIntent: PendingIntent? = null,
    ): Boolean {
        val manager = alarmManager(context)
        if (!canActivate(context)) return false
        val clockIntent = showIntent ?: PendingIntent.getActivity(
            context,
            operation.hashCode(),
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return try {
            manager.setAlarmClock(AlarmManager.AlarmClockInfo(triggerAt, clockIntent), operation)
            true
        } catch (_: SecurityException) {
            false
        }
    }

    private fun pendingIntentUri(id: String, role: String): Uri = Uri.parse(
        "untisplus://alarm/${Uri.encode(AlarmPolicy.pendingIdentity(id, role))}",
    )

    fun canScheduleExact(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager(context).canScheduleExactAlarms()

    fun postDueSmartReminder(context: Context) {
        for (index in 0 until storedPlans(context).length()) {
            val plan = storedPlans(context).optJSONObject(index) ?: continue
            if (plan.optString("kind") != "smart") continue
            if (plan.optString("dateKey") == prefs(context).getString(suppressedSmartDateKey, "")) continue
            val lead = plan.optInt("preAlarmNotificationMinutes", 30).coerceIn(0, 180)
            val remaining = plan.optLong("triggerAtMillis", 0L) - System.currentTimeMillis()
            if (lead > 0 && remaining in 1..(lead * 60_000L)) {
                AlarmReminderReceiver().showReminder(context, plan)
            }
        }
    }
}

/** Posted only after the smart-plan refresh had a chance to cancel or move it. */
class AlarmReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val plan = parseAlarmPlan(intent.getStringExtra(AlarmScheduler.extraPlan)) ?: return
        if (intent.action == AlarmScheduler.reminderDisableAction) {
            if (plan.optString("kind") == "smart") {
                AlarmScheduler.suppressSmartDate(context, plan.optString("dateKey"))
            }
            return
        }
        showReminder(context, plan)
    }

    fun showReminder(context: Context, plan: JSONObject) {
        val manager = context.getSystemService(NotificationManager::class.java)
        val channelId = "untis_alarm_upcoming"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(channelId, planCopy(plan, "channelReminder", "Untis+ Wecker-Erinnerungen"), NotificationManager.IMPORTANCE_HIGH).apply {
                    description = planCopy(plan, "channelReminderDescription", "Hinweise vor einem Untis+ Wecker")
                    lockscreenVisibility = Notification.VISIBILITY_PRIVATE
                },
            )
        }
        val minutes = plan.optInt("preAlarmNotificationMinutes", 30)
        val builder = Notification.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(planCopyFormat(plan, "reminderTitle", "Wecker in {minutes} Minuten", "minutes", minutes))
            .setContentText(plan.optString("label", planCopy(plan, "defaultLabel", "Untis+ Wecker")))
            .setCategory(Notification.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(PendingIntent.getActivity(
                context,
                plan.optString("id").hashCode(),
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            ))
        if (plan.optString("kind") == "smart") {
            @Suppress("DEPRECATION")
            builder.addAction(
                R.mipmap.ic_launcher,
                planCopy(plan, "disableToday", "Für diesen Tag ausschalten"),
                PendingIntent.getBroadcast(
                    context,
                    plan.optString("id").hashCode() xor 0x71,
                    Intent(context, AlarmReminderReceiver::class.java)
                        .setAction(AlarmScheduler.reminderDisableAction)
                        .putExtra(AlarmScheduler.extraPlan, plan.toString()),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
        }
        manager.notify(42050 + (plan.optString("id").hashCode() and 0x3ff), builder.build())
    }
}

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val rawPlan = intent.getStringExtra(AlarmScheduler.extraPlan) ?: return
        val plan = parseAlarmPlan(rawPlan) ?: return
        // Notification actions are the mandatory fallback when full-screen is
        // unavailable. Never start a ringing session without both permissions.
        if (!AlarmScheduler.canActivate(context)) return
        if (plan.optString("kind") == "manual") {
            // Re-arm before alerting so closing the app cannot lose a recurring alarm.
            AlarmScheduler.scheduleStoredPlans(context)
        } else if (plan.optString("kind") == "smart") {
            AlarmScheduler.removeOneShotPlan(context, plan.optString("id"))
        }
        val sessionId = UUID.randomUUID().toString()
        val sessionPlan = JSONObject(plan.toString()).apply {
            put(AlarmScheduler.extraSessionId, sessionId)
        }.toString()
        val serviceIntent = Intent(context, AlarmAlertService::class.java)
            .setAction(AlarmAlertService.actionRing)
            .putExtra(AlarmScheduler.extraPlan, sessionPlan)
            .putExtra(AlarmScheduler.extraSessionId, sessionId)
        ContextCompat.startForegroundService(context, serviceIntent)
    }
}

class AlarmPreWakeRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val plan = AlarmScheduler.planById(context, intent.getStringExtra(AlarmScheduler.extraAlarmId) ?: "")
        ContextCompat.startForegroundService(
            context,
            Intent(context, AlarmRefreshService::class.java)
                .putExtra(AlarmScheduler.extraPlan, plan?.toString()),
        )
    }
}

class AlarmRescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AlarmScheduler.scheduleStoredPlans(context)
    }
}

class AlarmAlertService : Service() {
    companion object {
        const val actionRing = "com.ninocss.untisplus.ALARM_ALERT_RING"
        const val actionDismiss = "com.ninocss.untisplus.ALARM_ALERT_DISMISS"
        const val actionSnooze = "com.ninocss.untisplus.ALARM_ALERT_SNOOZE"
        const val actionSessionEnded = "com.ninocss.untisplus.ALARM_SESSION_ENDED"
        private const val channelId = "untis_alarm_channel"
        private const val notificationId = 42001
        internal const val maxRingDurationMillis = AlarmPolicy.MAX_RING_DURATION_MILLIS
    }

    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var audioManager: AudioManager? = null
    private var focusRequest: AudioFocusRequest? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var activePlan: JSONObject? = null
    private var activeSessionId: String? = null
    private var stopping = false
    private val handler = Handler(Looper.getMainLooper())
    private val autoStop = Runnable { stopAlert(activeSessionId) }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            actionRing -> {
                val rawPlan = intent.getStringExtra(AlarmScheduler.extraPlan) ?: return START_NOT_STICKY
                activePlan = parseAlarmPlan(rawPlan) ?: return START_NOT_STICKY
                activeSessionId = intent.getStringExtra(AlarmScheduler.extraSessionId)
                    ?: activePlan?.optString(AlarmScheduler.extraSessionId)?.takeIf(String::isNotBlank)
                    ?: UUID.randomUUID().toString()
                stopping = false
                startForeground(notificationId, buildNotification(activePlan!!, activeSessionId!!))
                startAlert(activePlan!!)
            }
            actionSnooze -> {
                val sessionId = intent.getStringExtra(AlarmScheduler.extraSessionId)
                if (!accepts(sessionId)) return START_NOT_STICKY
                val plan = activePlan ?: parseAlarmPlan(intent.getStringExtra(AlarmScheduler.extraPlan))
                plan?.let { AlarmScheduler.scheduleSnooze(this, it, it.optInt("snoozeMinutes", 5)) }
                stopAlert(sessionId)
            }
            actionDismiss -> stopAlert(intent.getStringExtra(AlarmScheduler.extraSessionId))
        }
        return START_NOT_STICKY
    }

    private fun accepts(sessionId: String?): Boolean =
        AlarmPolicy.acceptsSession(activeSessionId, sessionId)

    private fun buildNotification(plan: JSONObject, sessionId: String): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        val dndGranted = manager.isNotificationPolicyAccessGranted
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // This dedicated channel is only used by user-configured alarms.
            val channel = NotificationChannel(channelId, planCopy(plan, "channelAlarm", "Untis+ Wecker"), NotificationManager.IMPORTANCE_HIGH).apply {
                description = planCopy(plan, "channelAlarmDescription", "Klingelnde Untis+ Wecker")
                setBypassDnd(dndGranted)
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(channel)
        }
        val activityIntent = Intent(this, AlarmActivity::class.java)
            .putExtra(AlarmScheduler.extraPlan, plan.toString())
            .putExtra(AlarmScheduler.extraSessionId, sessionId)
            .setData(Uri.parse("untisplus://alarm-session/$sessionId/view"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val fullScreenIntent = PendingIntent.getActivity(
            this,
            sessionId.hashCode(),
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        fun actionIntent(action: String, role: String) = PendingIntent.getService(
            this,
            sessionId.hashCode() xor role.hashCode(),
            Intent(this, AlarmAlertService::class.java)
                .setAction(action)
                .setData(Uri.parse("untisplus://alarm-session/$sessionId/$role"))
                .putExtra(AlarmScheduler.extraPlan, plan.toString())
                .putExtra(AlarmScheduler.extraSessionId, sessionId),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val snoozeLabel = planCopyFormat(
            plan,
            "snooze",
            "Schlummern · {minutes} Min.",
            "minutes",
            plan.optInt("snoozeMinutes", 5),
        )
        return Notification.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(planCopy(plan, "alarmTitle", "Wecker"))
            .setContentText(plan.optString("label", planCopy(plan, "defaultLabel", "Untis+ Wecker")))
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(Notification.PRIORITY_MAX)
            .setFullScreenIntent(fullScreenIntent, true)
            .addAction(Notification.Action.Builder(0, snoozeLabel, actionIntent(actionSnooze, "snooze")).build())
            .addAction(Notification.Action.Builder(0, planCopy(plan, "dismiss", "Ausschalten"), actionIntent(actionDismiss, "dismiss")).build())
            .build()
    }

    private fun startAlert(plan: JSONObject) {
        handler.removeCallbacks(autoStop)
        handler.postDelayed(autoStop, maxRingDurationMillis)
        wakeLock = getSystemService(PowerManager::class.java)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "$packageName:alarm")
            .apply { acquire(maxRingDurationMillis) }
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        audioManager = getSystemService(AudioManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(attributes)
                .build()
            audioManager?.requestAudioFocus(focusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager?.requestAudioFocus(null, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        }
        player?.run { release() }
        player = null
        val candidateUris = mutableListOf<Uri>()
        plan.optString("ringtoneUri").takeIf { it.isNotBlank() }?.let {
            candidateUris.add(Uri.parse(it))
        }
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)?.let {
            candidateUris.add(it)
        }
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)?.let {
            candidateUris.add(it)
        }
        for (uri in candidateUris.distinct()) {
            val candidatePlayer = MediaPlayer()
            val candidate = try {
                candidatePlayer.apply {
                    setAudioAttributes(attributes)
                    setDataSource(this@AlarmAlertService, uri)
                    isLooping = true
                    prepare()
                    start()
                }
            } catch (_: Exception) {
                candidatePlayer.release()
                null
            }
            if (candidate != null) {
                player = candidate
                break
            }
        }
        vibrator = getSystemService(Vibrator::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 800, 400), 0))
        } else {
            @Suppress("DEPRECATION") vibrator?.vibrate(longArrayOf(0, 800, 400), 0)
        }
    }

    private fun stopAlert(sessionId: String?) {
        if (!accepts(sessionId)) return
        if (stopping) return
        stopping = true
        releaseAlertResources()
        sendBroadcast(
            Intent(actionSessionEnded)
                .setPackage(packageName)
                .putExtra(AlarmScheduler.extraSessionId, sessionId),
        )
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun releaseAlertResources() {
        handler.removeCallbacks(autoStop)
        player?.run {
            try { stop() } catch (_: Exception) {}
            release()
        }
        player = null
        vibrator?.cancel()
        vibrator = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        }
        focusRequest = null
        audioManager = null
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    override fun onBind(intent: Intent?): IBinder? = null
    override fun onDestroy() {
        releaseAlertResources()
        super.onDestroy()
    }
}

class AlarmActivity : android.app.Activity() {
    private var downX = 0f
    private var plan: JSONObject = JSONObject()
    private var sessionId: String = ""
    private val sessionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.getStringExtra(AlarmScheduler.extraSessionId) == sessionId) finish()
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION") window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        plan = parseAlarmPlanOrEmpty(intent.getStringExtra(AlarmScheduler.extraPlan))
        sessionId = intent.getStringExtra(AlarmScheduler.extraSessionId)
            ?: plan.optString(AlarmScheduler.extraSessionId)
        ContextCompat.registerReceiver(
            this,
            sessionReceiver,
            IntentFilter(AlarmAlertService.actionSessionEnded),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        buildContent()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        plan = parseAlarmPlanOrEmpty(intent.getStringExtra(AlarmScheduler.extraPlan))
        sessionId = intent.getStringExtra(AlarmScheduler.extraSessionId)
            ?: plan.optString(AlarmScheduler.extraSessionId)
        buildContent()
    }

    private fun buildContent() {
        fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
        fun rounded(color: Int, radius: Int) = GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radius).toFloat()
        }
        fun text(value: String, size: Float, color: Int, weight: Int = Typeface.NORMAL) =
            TextView(this).apply {
                this.text = value
                textSize = size
                setTextColor(color)
                gravity = Gravity.CENTER
                typeface = Typeface.create("sans-serif", weight)
                includeFontPadding = false
            }
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(28), dp(48), dp(28), dp(28))
            setBackgroundColor(Color.rgb(39, 18, 16))
            setOnTouchListener { _, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> downX = event.rawX
                    MotionEvent.ACTION_UP -> {
                        val delta = event.rawX - downX
                        if (delta < -140) snooze() else if (delta > 140) dismiss()
                    }
                }
                // Returning true here prevented the visible buttons from
                // receiving taps. Observe the swipe and leave child handling
                // intact for an accessible fallback.
                false
            }
        }
        root.addView(Space(this), LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 0, 0.78f,
        ))
        root.addView(text("UNTIS+", 13f, Color.rgb(255, 183, 164), Typeface.BOLD).apply {
            letterSpacing = 0.16f
        })
        root.addView(text(
            java.text.SimpleDateFormat("HH:mm").format(java.util.Date()),
            88f,
            Color.rgb(255, 237, 233),
            Typeface.BOLD,
        ).apply { setPadding(0, dp(18), 0, dp(14)) })
        root.addView(text(plan.optString("label", planCopy(plan, "defaultLabel", "Untis+ Wecker")), 18f, Color.rgb(255, 222, 214), Typeface.BOLD).apply {
            background = rounded(Color.rgb(82, 38, 32), 28)
            setPadding(dp(22), dp(11), dp(22), dp(11))
        })
        root.addView(text(planCopy(plan, "swipeHint", "Nach links schlummern, nach rechts ausschalten"), 13f, Color.rgb(225, 190, 182)).apply {
            setPadding(0, dp(24), 0, dp(20))
        })
        root.addView(Space(this), LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 0, 1.22f,
        ))

        val actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(dp(8), dp(8), dp(8), dp(8))
            background = rounded(Color.rgb(65, 29, 25), 42)
        }
        fun actionButton(label: String, fill: Int, foreground: Int, onClick: () -> Unit) =
            Button(this).apply {
                text = label
                textSize = 16f
                isAllCaps = false
                setTextColor(foreground)
                typeface = Typeface.create("sans-serif", Typeface.BOLD)
                background = rounded(fill, 34)
                minHeight = 0
                minimumHeight = 0
                elevation = dp(2).toFloat()
                setOnClickListener { onClick() }
            }
        actions.addView(
            actionButton(
                planCopyFormat(plan, "snooze", "Schlummern · {minutes} Min.", "minutes", plan.optInt("snoozeMinutes", 5)),
                Color.rgb(120, 56, 45),
                Color.rgb(255, 238, 233),
            ) { snooze() },
            LinearLayout.LayoutParams(0, dp(68), 1f).apply { marginEnd = dp(8) },
        )
        actions.addView(
            actionButton(planCopy(plan, "dismiss", "Ausschalten"), Color.rgb(255, 118, 82), Color.rgb(61, 20, 12)) {
                dismiss()
            },
            LinearLayout.LayoutParams(0, dp(68), 0.88f),
        )
        root.addView(actions, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT,
        ))
        setContentView(root)
    }

    private fun snooze() {
        sendCommand(AlarmAlertService.actionSnooze)
        finish()
    }

    private fun dismiss() {
        sendCommand(AlarmAlertService.actionDismiss)
        finish()
    }

    private fun sendCommand(action: String) {
        startService(
            Intent(this, AlarmAlertService::class.java)
                .setAction(action)
                .setData(Uri.parse("untisplus://alarm-session/$sessionId/activity"))
                .putExtra(AlarmScheduler.extraPlan, plan.toString())
                .putExtra(AlarmScheduler.extraSessionId, sessionId),
        )
    }

    override fun onDestroy() {
        try { unregisterReceiver(sessionReceiver) } catch (_: IllegalArgumentException) {}
        super.onDestroy()
    }
}

class AlarmRefreshService : Service() {
    private var engine: FlutterEngine? = null
    private var schedulingChannel: AlarmChannelHandler? = null
    private var completed = false
    private val handler = Handler(Looper.getMainLooper())
    private val timeout = Runnable { complete(allowReminder = false) }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val plan = parseAlarmPlanOrEmpty(intent?.getStringExtra(AlarmScheduler.extraPlan))
        startForeground(42003, refreshNotification(plan))
        if (engine != null) return START_NOT_STICKY
        handler.postDelayed(timeout, 120_000)
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            engine = FlutterEngine(applicationContext)
            // The headless isolate recalculates and replaces the smart plan.
            // Register the same scheduling channel used by MainActivity so
            // that replacePlans is not lost as a MissingPluginException.
            schedulingChannel = AlarmChannelHandler(
                applicationContext,
                engine!!.dartExecutor.binaryMessenger,
            ).also { it.register() }
            MethodChannel(engine!!.dartExecutor.binaryMessenger, NativeChannelContract.ALARM_REFRESH)
                .setMethodCallHandler { call, result ->
                    if (call.method == "completed") {
                        result.success(null)
                        val args = call.arguments as? Map<*, *>
                        complete(allowReminder = args?.get("refreshed") == true)
                    } else result.notImplemented()
                }
            val entrypoint = DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                "alarmRefreshDispatcher",
            )
            engine!!.dartExecutor.executeDartEntrypoint(entrypoint)
        } catch (_: Exception) {
            // Do not let a refresh failure crash the process or outlive its
            // deadline. The already confirmed alarm remains scheduled.
            complete(allowReminder = false)
        }
        return START_NOT_STICKY
    }

    private fun refreshNotification(plan: JSONObject): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel("untis_alarm_refresh", planCopy(plan, "channelRefresh", "Untis+ Wecker-Aktualisierung"), NotificationManager.IMPORTANCE_LOW),
            )
        }
        return Notification.Builder(this, "untis_alarm_refresh")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(planCopy(plan, "refreshing", "Wecker wird aktualisiert"))
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()
    }

    private fun complete(allowReminder: Boolean) {
        if (completed) return
        completed = true
        handler.removeCallbacks(timeout)
        if (allowReminder) {
            // Flutter has just refreshed (and possibly replaced) the smart
            // plan. Only now may the upcoming-alarm notification be posted.
            AlarmScheduler.postDueSmartReminder(this)
        }
        engine?.destroy()
        engine = null
        schedulingChannel = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacks(timeout)
        engine?.destroy()
        engine = null
        schedulingChannel = null
        super.onDestroy()
    }
    override fun onBind(intent: Intent?): IBinder? = null
}
