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

    const val ASSISTANT_ACTION = "com.ninocss.untisplus.OPEN_ASSISTANT"
    const val ASSISTANT_URI_HOST = "assistant"
}

/** Owns the native channel lifecycle so MainActivity stays a Flutter host. */
internal class NativeChannelRegistry(
    private val activity: MainActivity,
    flutterEngine: FlutterEngine,
) {
    private val messenger = flutterEngine.dartExecutor.binaryMessenger
    private val notifications = NotificationChannelHandler(activity, messenger)
    private val ui = UiChannelHandler(activity, messenger)
    private val alarms = AlarmChannelHandler(activity, messenger, activity)

    fun register() {
        notifications.register()
        ui.register()
        alarms.register()
    }

    fun handleIntent(intent: Intent?) {
        if (isAssistantIntent(intent)) {
            ui.openAssistant(extractAssistantQuery(intent))
            intent?.action = null
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

    private fun isAssistantIntent(intent: Intent?): Boolean {
        if (intent?.action == NativeChannelContract.ASSISTANT_ACTION) return true
        // actions.intent.OPEN_APP_FEATURE explicit-intent fulfillment launches
        // MainActivity directly with the BII parameter delivered as an extra.
        if (intent?.getStringExtra("feature") != null) return true
        val host = intent?.data?.host ?: return false
        return intent.data?.scheme == "untisplus" && host == NativeChannelContract.ASSISTANT_URI_HOST
    }

    /**
     * Pulls the spoken/typed query out of any assistant-shaped intent:
     *
     *  1. explicit `query` deep-link parameter (`untisplus://assistant?query=…`),
     *  2. the App Actions `feature` parameter — either a URI query parameter or
     *     the intent extra that actions.intent.OPEN_APP_FEATURE sends for
     *     explicit-intent fulfillment.
     *
     * A matched inventory feature arrives as the shortcut id `ai_assistant`
     * (open assistant, no query); an unmatched phrase arrives verbatim and is
     * used as the prompt.
     */
    private fun extractAssistantQuery(intent: Intent?): String? {
        val uri = intent?.data
        var query = uri?.getQueryParameter("query")
        if (query.isNullOrBlank()) {
            query = uri?.getQueryParameter("feature")
                ?: intent?.getStringExtra("feature")
        }
        if (query.isNullOrBlank()) return null
        return query.trim()
    }
}