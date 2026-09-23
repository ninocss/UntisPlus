package com.ninocss.untisplus

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class AlarmPolicyTest {
    @Test fun reconciliationRemovesOnlyStalePlans() {
        assertEquals(setOf("old"), AlarmPolicy.staleIds(setOf("same", "old"), setOf("same", "new")))
    }

    @Test fun pendingIntentIdentitiesIncludePlanAndRole() {
        assertNotEquals(AlarmPolicy.pendingIdentity("a", "ring"), AlarmPolicy.pendingIdentity("a", "refresh"))
        assertNotEquals(AlarmPolicy.pendingIdentity("a", "ring"), AlarmPolicy.pendingIdentity("b", "ring"))
    }

    @Test fun dismissOnlyAcceptsTheCurrentSession() {
        assertTrue(AlarmPolicy.acceptsSession("session-a", "session-a"))
        assertFalse(AlarmPolicy.acceptsSession("session-a", "session-b"))
        assertFalse(AlarmPolicy.acceptsSession("session-a", null))
    }

    @Test fun snoozeUsesConfiguredMinutes() {
        assertEquals(1_300_000L, AlarmPolicy.snoozeTriggerAt(1_000_000L, 5))
    }

    @Test fun ringingStopsAfterFiveMinutes() {
        assertEquals(300_000L, AlarmPolicy.MAX_RING_DURATION_MILLIS)
    }

    @Test fun restoreRequiresBothMandatoryPermissions() {
        assertTrue(AlarmPolicy.maySchedule(exactAlarms = true, notifications = true))
        assertFalse(AlarmPolicy.maySchedule(exactAlarms = false, notifications = true))
        assertFalse(AlarmPolicy.maySchedule(exactAlarms = true, notifications = false))
    }
}
