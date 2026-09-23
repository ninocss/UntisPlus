package com.ninocss.untisplus

/** Pure policy shared by the Android alarm implementation and JVM tests. */
internal object AlarmPolicy {
    const val MAX_RING_DURATION_MILLIS = 5 * 60_000L

    fun staleIds(previousIds: Set<String>, desiredIds: Set<String>): Set<String> =
        previousIds - desiredIds

    fun pendingIdentity(id: String, role: String): String = "$id::$role"

    fun acceptsSession(activeSessionId: String?, incomingSessionId: String?): Boolean =
        incomingSessionId != null && (activeSessionId == null || activeSessionId == incomingSessionId)

    fun snoozeTriggerAt(nowMillis: Long, minutes: Int): Long =
        nowMillis + minutes.coerceIn(1, 60) * 60_000L

    fun maySchedule(exactAlarms: Boolean, notifications: Boolean): Boolean =
        exactAlarms && notifications
}
