package gay.ninoio.untisplus

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.graphics.Color
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	companion object {
		private const val CHANNEL = "untisplus/notifications"
		private const val ACTION_EXTRA_KEY = "notification_action_id"
		private const val CURRENT_LESSON_EXTRA_KEY = "notification_current_lesson"
		private const val NEXT_LESSON_EXTRA_KEY = "notification_next_lesson"
	}

	private var methodChannel: MethodChannel? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
		methodChannel?.setMethodCallHandler { call, result ->
			when (call.method) {
				"showProgressCentricNotification" -> {
					@Suppress("UNCHECKED_CAST")
					val args = call.arguments as? Map<String, Any?>
					result.success(showProgressCentricNotification(args))
				}
				else -> result.notImplemented()
			}
		}

		forwardIntentActionIfPresent(intent)
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
		forwardIntentActionIfPresent(intent)
	}

	private fun forwardIntentActionIfPresent(intent: Intent?) {
		val safeIntent = intent ?: return
		val actionId = safeIntent.getStringExtra(ACTION_EXTRA_KEY)?.trim().orEmpty()
		if (actionId.isEmpty()) return

		val payload = mapOf(
			"actionId" to actionId,
			"currentLesson" to safeIntent.getStringExtra(CURRENT_LESSON_EXTRA_KEY).orEmpty(),
			"nextLesson" to safeIntent.getStringExtra(NEXT_LESSON_EXTRA_KEY).orEmpty(),
		)
		methodChannel?.invokeMethod("onNotificationAction", payload)
		safeIntent.removeExtra(ACTION_EXTRA_KEY)
		safeIntent.removeExtra(CURRENT_LESSON_EXTRA_KEY)
		safeIntent.removeExtra(NEXT_LESSON_EXTRA_KEY)
	}

	private fun showProgressCentricNotification(args: Map<String, Any?>?): Boolean {
		if (Build.VERSION.SDK_INT < 36 || args == null) return false

		return try {
			val notificationId = (args["id"] as? Number)?.toInt() ?: 1
			val channelId = (args["channelId"] as? String).orEmpty().ifEmpty { "current_lesson_channel" }
			val title = (args["title"] as? String).orEmpty()
			val body = (args["body"] as? String).orEmpty()
			val subText = args["subText"] as? String
			val currentLesson = (args["currentLesson"] as? String).orEmpty()
			val nextLesson = (args["nextLesson"] as? String).orEmpty()
			val locale = (args["locale"] as? String).orEmpty().ifEmpty { "de" }
			val progress = (args["currentProgress"] as? Number)?.toLong() ?: 0L
			val maxProgress = (args["maxProgress"] as? Number)?.toLong() ?: 0L
			val endTimeMs = (args["endTimeMs"] as? Number)?.toLong()

			val manager = getSystemService(NotificationManager::class.java) ?: return false
			ensureCurrentLessonChannel(manager, channelId)

			val openTimetableIntent = buildActionIntent(
				actionId = "open_timetable",
				requestCode = 1001,
				currentLesson = currentLesson,
				nextLesson = nextLesson,
			)
			val openNextLessonIntent = buildActionIntent(
				actionId = "open_next_lesson",
				requestCode = 1002,
				currentLesson = currentLesson,
				nextLesson = nextLesson,
			)
			val openFreeRoomsIntent = buildActionIntent(
				actionId = "open_free_rooms",
				requestCode = 1003,
				currentLesson = currentLesson,
				nextLesson = nextLesson,
			)

			val builder = Notification.Builder(this, channelId)
				.setSmallIcon(R.mipmap.ic_launcher)
				.setContentTitle(title)
				.setContentText(body)
				.setSubText(subText)
				.setOnlyAlertOnce(true)
				.setOngoing(true)
				.setAutoCancel(false)
				.setCategory(Notification.CATEGORY_PROGRESS)
				.setContentIntent(openTimetableIntent)
				.addAction(Notification.Action.Builder(0, actionLabel(locale, "open_timetable"), openTimetableIntent).build())
				.addAction(Notification.Action.Builder(0, actionLabel(locale, "open_next_lesson"), openNextLessonIntent).build())
				.addAction(Notification.Action.Builder(0, actionLabel(locale, "open_free_rooms"), openFreeRoomsIntent).build())

			if (endTimeMs != null && endTimeMs > 0L) {
				builder.setWhen(endTimeMs)
				builder.setUsesChronometer(true)
				builder.setChronometerCountDown(true)
			}

			// Reflection keeps this source compile-safe even if API 36 symbols are unavailable at compile time.
			val progressStyleClass = Class.forName("android.app.Notification\$ProgressStyle")
			val style = progressStyleClass.getDeclaredConstructor().newInstance()
			progressStyleClass.getMethod("setStyledByProgress", Boolean::class.javaPrimitiveType)
				.invoke(style, false)
			progressStyleClass.getMethod("setProgress", Long::class.javaPrimitiveType)
				.invoke(style, progress)

			if (maxProgress > 0L) {
				try {
					val segmentClass = Class.forName("android.app.Notification\$ProgressStyle\$Segment")
					val segmentCtor = segmentClass.getDeclaredConstructor(Long::class.javaPrimitiveType)
					val setColor = segmentClass.getMethod("setColor", Int::class.javaPrimitiveType)

					val completed = segmentCtor.newInstance(progress.coerceAtMost(maxProgress))
					setColor.invoke(completed, Color.parseColor("#4CAF50"))

					val remaining = segmentCtor.newInstance((maxProgress - progress).coerceAtLeast(0L))
					setColor.invoke(remaining, Color.parseColor("#B0BEC5"))

					val setSegments = progressStyleClass.getMethod("setProgressSegments", List::class.java)
					setSegments.invoke(style, listOf(completed, remaining))

					val pointClass = Class.forName("android.app.Notification\$ProgressStyle\$Point")
					val pointCtor = pointClass.getDeclaredConstructor(Long::class.javaPrimitiveType)
					val pointSetColor = pointClass.getMethod("setColor", Int::class.javaPrimitiveType)
					val milestone = pointCtor.newInstance(maxProgress)
					pointSetColor.invoke(milestone, Color.parseColor("#FF9800"))

					val setPoints = progressStyleClass.getMethod("setProgressPoints", List::class.java)
					setPoints.invoke(style, listOf(milestone))
				} catch (_: Throwable) {
					// Keep notification alive even if optional segment/point styling fails.
				}
			}

			if (maxProgress > 0L) {
				builder.setProgress(maxProgress.toInt(), progress.toInt(), false)
			}

			builder.setStyle(style as Notification.Style)
			manager.notify(notificationId, builder.build())
			true
		} catch (_: Throwable) {
			false
		}
	}

	private fun ensureCurrentLessonChannel(manager: NotificationManager, channelId: String) {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
		val existing = manager.getNotificationChannel(channelId)
		if (existing != null) return

		val channel = NotificationChannel(
			channelId,
			"Aktuelle Stunde / Pause",
			NotificationManager.IMPORTANCE_DEFAULT,
		).apply {
			description = "Zeigt die aktuelle Stunde oder Pause an."
		}
		manager.createNotificationChannel(channel)
	}

	private fun buildActionIntent(
		actionId: String,
		requestCode: Int,
		currentLesson: String,
		nextLesson: String,
	): PendingIntent {
		val intent = Intent(this, MainActivity::class.java).apply {
			flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
			putExtra(ACTION_EXTRA_KEY, actionId)
			putExtra(CURRENT_LESSON_EXTRA_KEY, currentLesson)
			putExtra(NEXT_LESSON_EXTRA_KEY, nextLesson)
		}

		return PendingIntent.getActivity(
			this,
			requestCode,
			intent,
			PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
		)
	}

	private fun actionLabel(locale: String, actionId: String): String {
		val normalized = locale.lowercase()
		if (normalized.startsWith("en")) {
			return when (actionId) {
				"open_next_lesson" -> "Next lesson"
				"open_free_rooms" -> "Free rooms"
				else -> "Timetable"
			}
		}
		if (normalized.startsWith("fr")) {
			return when (actionId) {
				"open_next_lesson" -> "Cours suivant"
				"open_free_rooms" -> "Salles libres"
				else -> "Emploi du temps"
			}
		}
		if (normalized.startsWith("es")) {
			return when (actionId) {
				"open_next_lesson" -> "Siguiente clase"
				"open_free_rooms" -> "Aulas libres"
				else -> "Horario"
			}
		}
		if (normalized.startsWith("el")) {
			return when (actionId) {
				"open_next_lesson" -> "Επόμενο μάθημα"
				"open_free_rooms" -> "Ελεύθερες αίθουσες"
				else -> "Πρόγραμμα"
			}
		}

		return when (actionId) {
			"open_next_lesson" -> "Nächste Stunde"
			"open_free_rooms" -> "Freie Räume"
			else -> "Stundenplan"
		}
	}
}
