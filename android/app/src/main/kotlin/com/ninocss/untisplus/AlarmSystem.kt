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
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/** Native, durable scheduling layer. Dart supplies configuration; Android owns wake-up. */
object AlarmScheduler {
    const val alarmAction = "com.ninocss.untisplus.ALARM_RING"
    const val refreshAction = "com.ninocss.untisplus.ALARM_PRE_WAKE_REFRESH"
    const val extraPlan = "alarm_plan"
    const val extraAlarmId = "alarm_id"
    private const val prefsName = "untis_alarm_native"
    private const val plansKey = "plans"

    private fun prefs(context: Context) = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
    private fun alarmManager(context: Context) = context.getSystemService(AlarmManager::class.java)
    private fun requestCode(id: String, suffix: Int = 0) = 0x55aa0000 xor id.hashCode() xor suffix

    fun replacePlans(context: Context, plans: JSONArray) {
        cancelAll(context)
        prefs(context).edit().putString(plansKey, plans.toString()).apply()
        scheduleStoredPlans(context)
    }

    fun scheduleStoredPlans(context: Context) {
        if (!canScheduleExact(context)) return
        val plans = storedPlans(context)
        for (index in 0 until plans.length()) {
            val plan = plans.optJSONObject(index) ?: continue
            schedulePlan(context, plan)
        }
    }

    fun cancelAll(context: Context) {
        val plans = storedPlans(context)
        for (index in 0 until plans.length()) {
            val plan = plans.optJSONObject(index) ?: continue
            cancelPlan(context, plan.optString("id"))
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

    private fun storedPlans(context: Context): JSONArray = try {
        JSONArray(prefs(context).getString(plansKey, "[]"))
    } catch (_: Exception) {
        JSONArray()
    }

    private fun schedulePlan(context: Context, plan: JSONObject) {
        val id = plan.optString("id")
        if (id.isBlank()) return
        val triggerAt = if (plan.optString("kind") == "manual") {
            nextRecurringTrigger(plan)
        } else {
            plan.optLong("triggerAtMillis", 0L)
        }
        if (triggerAt <= System.currentTimeMillis()) return
        val intent = Intent(context, AlarmReceiver::class.java)
            .setAction(alarmAction)
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
        alarmManager(context).setAlarmClock(AlarmManager.AlarmClockInfo(triggerAt, showIntent), operation)

        if (plan.optString("kind") == "smart") {
            val refreshAt = plan.optLong("preRefreshAtMillis", 0L)
            if (refreshAt > System.currentTimeMillis()) {
                val refreshIntent = Intent(context, AlarmPreWakeRefreshReceiver::class.java)
                    .setAction(refreshAction)
                    .putExtra(extraAlarmId, id)
                val refreshOperation = PendingIntent.getBroadcast(
                    context,
                    requestCode(id, 2),
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                alarmManager(context).setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    refreshAt,
                    refreshOperation,
                )
            }
        }
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
            Intent(context, AlarmReceiver::class.java).setAction(alarmAction),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (alarmIntent != null) manager.cancel(alarmIntent)
        val refreshIntent = PendingIntent.getBroadcast(
            context,
            requestCode(id, 2),
            Intent(context, AlarmPreWakeRefreshReceiver::class.java).setAction(refreshAction),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (refreshIntent != null) manager.cancel(refreshIntent)
    }

    fun scheduleSnooze(context: Context, plan: JSONObject, minutes: Int) {
        if (!canScheduleExact(context)) return
        val triggerAt = System.currentTimeMillis() + minutes.coerceIn(1, 60) * 60_000L
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
                .putExtra(extraPlan, snoozePlan.toString()),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val showIntent = PendingIntent.getActivity(
            context,
            requestCode(snoozePlan.getString("id"), 1),
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager(context).setAlarmClock(AlarmManager.AlarmClockInfo(triggerAt, showIntent), operation)
    }

    fun canScheduleExact(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager(context).canScheduleExactAlarms()
}

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val rawPlan = intent.getStringExtra(AlarmScheduler.extraPlan) ?: return
        val plan = try { JSONObject(rawPlan) } catch (_: Exception) { return }
        if (plan.optString("kind") == "manual") {
            // Re-arm before alerting so closing the app cannot lose a recurring alarm.
            AlarmScheduler.scheduleStoredPlans(context)
        } else if (plan.optString("kind") == "smart") {
            AlarmScheduler.removeOneShotPlan(context, plan.optString("id"))
        }
        val serviceIntent = Intent(context, AlarmAlertService::class.java)
            .setAction(AlarmAlertService.actionRing)
            .putExtra(AlarmScheduler.extraPlan, rawPlan)
        ContextCompat.startForegroundService(context, serviceIntent)
    }
}

class AlarmPreWakeRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ContextCompat.startForegroundService(
            context,
            Intent(context, AlarmRefreshService::class.java),
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
        private const val channelId = "untis_alarm_channel"
        private const val notificationId = 42001
    }

    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var audioManager: AudioManager? = null
    private var focusRequest: AudioFocusRequest? = null
    private var activePlan: JSONObject? = null
    private var stopping = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            actionRing -> {
                val rawPlan = intent.getStringExtra(AlarmScheduler.extraPlan) ?: return START_NOT_STICKY
                activePlan = try { JSONObject(rawPlan) } catch (_: Exception) { return START_NOT_STICKY }
                stopping = false
                startForeground(notificationId, buildNotification(activePlan!!))
                startAlert(activePlan!!)
            }
            actionSnooze -> {
                activePlan?.let { AlarmScheduler.scheduleSnooze(this, it, it.optInt("snoozeMinutes", 5)) }
                stopAlert()
            }
            actionDismiss -> stopAlert()
        }
        return START_NOT_STICKY
    }

    private fun buildNotification(plan: JSONObject): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        val dndGranted = manager.isNotificationPolicyAccessGranted
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // This dedicated channel is only used by user-configured alarms.
            manager.deleteNotificationChannel(channelId)
            val channel = NotificationChannel(channelId, "Untis+ Wecker", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Klingelnde Untis+ Wecker"
                setBypassDnd(dndGranted)
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(channel)
        }
        val activityIntent = Intent(this, AlarmActivity::class.java)
            .putExtra(AlarmScheduler.extraPlan, plan.toString())
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val fullScreenIntent = PendingIntent.getActivity(
            this,
            42002,
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Wecker")
            .setContentText(plan.optString("label", "Untis+ Wecker"))
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(Notification.PRIORITY_MAX)
            .setFullScreenIntent(fullScreenIntent, true)
            .build()
    }

    private fun startAlert(plan: JSONObject) {
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

    private fun stopAlert() {
        if (stopping) return
        stopping = true
        releaseAlertResources()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun releaseAlertResources() {
        player?.run {
            try { stop() } catch (_: Exception) {}
            release()
        }
        player = null
        vibrator?.cancel()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        }
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
        plan = try { JSONObject(intent.getStringExtra(AlarmScheduler.extraPlan) ?: "{}") } catch (_: Exception) { JSONObject() }
        buildContent()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        plan = try { JSONObject(intent.getStringExtra(AlarmScheduler.extraPlan) ?: "{}") } catch (_: Exception) { JSONObject() }
        buildContent()
    }

    private fun buildContent() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(32, 48, 32, 48)
            setBackgroundColor(0xff102a2a.toInt())
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
        fun text(value: String, size: Float, alpha: Float = 1f) = TextView(this).apply {
            this.text = value
            textSize = size
            setTextColor(android.graphics.Color.WHITE)
            this.alpha = alpha
            gravity = Gravity.CENTER
        }
        root.addView(text(java.text.SimpleDateFormat("HH:mm").format(java.util.Date()), 72f))
        root.addView(text(plan.optString("label", "Untis+ Wecker"), 22f, .9f))
        root.addView(text("← Schlummern       Ausschalten →", 15f, .72f).apply {
            setPadding(0, 36, 0, 24)
        })
        root.addView(Button(this).apply {
            text = "Schlummern (${plan.optInt("snoozeMinutes", 5)} Min.)"
            setOnClickListener { snooze() }
        })
        root.addView(Button(this).apply {
            text = "Ausschalten"
            setOnClickListener { dismiss() }
        })
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
        startService(Intent(this, AlarmAlertService::class.java).setAction(action))
    }
}

class AlarmRefreshService : Service() {
    private var engine: FlutterEngine? = null
    private var completed = false
    private val handler = Handler(Looper.getMainLooper())
    private val timeout = Runnable { complete() }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(42003, refreshNotification())
        if (engine != null) return START_NOT_STICKY
        handler.postDelayed(timeout, 120_000)
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            engine = FlutterEngine(applicationContext)
            MethodChannel(engine!!.dartExecutor.binaryMessenger, "untisplus/alarm_refresh")
                .setMethodCallHandler { call, result ->
                    if (call.method == "completed") {
                        result.success(null)
                        complete()
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
            complete()
        }
        return START_NOT_STICKY
    }

    private fun refreshNotification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel("untis_alarm_refresh", "Untis+ Wecker-Aktualisierung", NotificationManager.IMPORTANCE_LOW),
            )
        }
        return Notification.Builder(this, "untis_alarm_refresh")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Wecker wird aktualisiert")
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()
    }

    private fun complete() {
        if (completed) return
        completed = true
        handler.removeCallbacks(timeout)
        engine?.destroy()
        engine = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacks(timeout)
        engine?.destroy()
        engine = null
        super.onDestroy()
    }
    override fun onBind(intent: Intent?): IBinder? = null
}
