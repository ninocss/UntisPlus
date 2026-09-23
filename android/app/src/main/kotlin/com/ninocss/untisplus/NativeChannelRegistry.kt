package com.ninocss.untisplus

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine

internal object NativeChannelContract {
    const val NOTIFICATIONS = "untisplus/notifications"
    const val UI = "untisplus/ui"
    const val ALARM = "untisplus/alarm"
    const val ALARM_REFRESH = "untisplus/alarm_refresh"

    const val ACTION_ID = "notification_action_id"
    const val CURRENT_LESSON = "notification_current_lesson"
    const val NEXT_LESSON = "notification_next_lesson"
}

/** Owns the native channel lifecycle so MainActivity stays a Flutter host. */
internal class NativeChannelRegistry(
    private val activity: MainActivity,
    flutterEngine: FlutterEngine,
) {
    private val messenger = flutterEngine.dartExecutor.binaryMessenger
    private val notifications = NotificationChannelHandler(activity, messenger)
    private val ui = UiChannelHandler(activity, messenger)
    private val alarms = AlarmChannelHandler(activity, messenger)

    fun register() {
        notifications.register()
        ui.register()
        alarms.register()
    }

    fun handleIntent(intent: Intent?) {
        if (intent?.action == "com.ninocss.untisplus.OPEN_ASSISTANT" ||
            intent?.data?.host == "assistant"
        ) {
            ui.openAssistant(intent.data?.getQueryParameter("query"))
            intent.action = null
            return
        }

        val actionId = intent?.getStringExtra(NativeChannelContract.ACTION_ID) ?: return
        notifications.dispatchAction(
            mapOf(
                "actionId" to actionId,
                "currentLesson" to intent.getStringExtra(NativeChannelContract.CURRENT_LESSON),
                "nextLesson" to intent.getStringExtra(NativeChannelContract.NEXT_LESSON),
            ),
        )

        // A reused launch intent must not replay the same notification action.
        intent.removeExtra(NativeChannelContract.ACTION_ID)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        alarms.onActivityResult(requestCode, resultCode, data)
    }
}
