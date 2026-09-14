package com.ninocss.untisplus

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

private fun widgetAccount(data: SharedPreferences, widgetId: Int): String =
    data.getString("widget_account_$widgetId", null)
        ?: data.getString("widget_active_account", "active")
        ?: "active"

private fun widgetValue(data: SharedPreferences, widgetId: Int, field: String, fallback: String): String {
    val account = widgetAccount(data, widgetId)
    val scoped = data.getString("widget.$account.$field", null)
    if (scoped != null) return scoped
    // A configured non-active account must never display another student's
    // data while its first background update is pending.
    if (data.contains("widget_account_$widgetId")) return fallback
    return data.getString(field, fallback) ?: fallback
}

private fun compact(value: String, max: Int): String =
    value.replace('\n', ' ').trim().let { if (it.length > max) "${it.take(max - 1)}…" else it }

private fun openAppIntent(context: Context, widgetId: Int, accountId: String): PendingIntent =
    PendingIntent.getActivity(
        context,
        widgetId,
        Intent(context, MainActivity::class.java).apply {
            action = "com.ninocss.untisplus.OPEN_WIDGET"
            putExtra("widget_account_id", accountId)
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

private fun configureIntent(context: Context, widgetId: Int): PendingIntent =
    PendingIntent.getActivity(
        context,
        widgetId + 100000,
        Intent(context, WidgetConfigActivity::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

private fun customConfiguration(data: SharedPreferences, widgetId: Int): JSONObject? {
    val id = data.getString("widget_configuration_$widgetId", null) ?: return null
    val raw = data.getString("widget_configurations_v1", "[]") ?: "[]"
    val values = try { JSONArray(raw) } catch (_: Exception) { JSONArray() }
    for (index in 0 until values.length()) {
        val item = values.optJSONObject(index) ?: continue
        if (item.optString("id") == id) return item
    }
    return null
}

private fun customContent(data: SharedPreferences, widgetId: Int, account: String, block: String): String = when (block) {
    "current" -> widgetValue(data, widgetId, "current_lesson", "")
    "next" -> widgetValue(data, widgetId, "next_lesson", "")
    "schedule" -> widgetValue(data, widgetId, "daily_schedule", "")
    "homework" -> widgetValue(data, widgetId, "homework_summary", "Keine offenen Aufgaben")
    "exams" -> widgetValue(data, widgetId, "exam_summary", "Keine Prüfungen synchronisiert")
    "notices" -> widgetValue(data, widgetId, "notification_summary", "Keine Mitteilungen")
    "account" -> widgetValue(data, widgetId, "account_label", "Untis+")
    "status" -> widgetValue(data, widgetId, "status", "")
    else -> ""
}

class UntisWidgetCurrentLesson : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) {
        ids.forEach { id ->
            val account = widgetAccount(data, id)
            val current = compact(widgetValue(data, id, "current_lesson", ""), 28)
            val next = compact(widgetValue(data, id, "next_lesson", ""), 44)
            val remaining = compact(widgetValue(data, id, "time_remaining", ""), 24)
            val views = RemoteViews(context.packageName, R.layout.widget_current_lesson).apply {
                setTextViewText(R.id.widget_account, compact(widgetValue(data, id, "account_label", "Untis+"), 22))
                setTextViewText(R.id.widget_current_lesson, current)
                setTextViewText(R.id.widget_next_lesson, next)
                setTextViewText(R.id.widget_time_remaining, remaining)
                setViewVisibility(R.id.widget_current_lesson, if (current.isEmpty()) View.GONE else View.VISIBLE)
                setViewVisibility(R.id.widget_next_lesson, if (next.isEmpty()) View.GONE else View.VISIBLE)
                setViewVisibility(R.id.widget_time_remaining, if (remaining.isEmpty()) View.GONE else View.VISIBLE)
                setTextViewText(R.id.widget_status, compact(widgetValue(data, id, "status", ""), 10))
                setOnClickPendingIntent(R.id.widget_current_root, openAppIntent(context, id, account))
                setOnClickPendingIntent(R.id.widget_current_settings, configureIntent(context, id))
            }
            manager.updateAppWidget(id, views)
        }
    }
}

class UntisWidgetDailySchedule : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) {
        ids.forEach { id ->
            val account = widgetAccount(data, id)
            val views = RemoteViews(context.packageName, R.layout.widget_daily_schedule).apply {
                setTextViewText(R.id.widget_schedule_account, compact(widgetValue(data, id, "account_label", "Untis+"), 22))
                val schedule = widgetValue(data, id, "daily_schedule", "").lineSequence().take(3).joinToString("\n")
                setTextViewText(R.id.widget_daily_schedule, schedule)
                setViewVisibility(R.id.widget_daily_schedule, if (schedule.isEmpty()) View.GONE else View.VISIBLE)
                setTextViewText(R.id.widget_schedule_status, compact(widgetValue(data, id, "status", ""), 10))
                setOnClickPendingIntent(R.id.widget_schedule_root, openAppIntent(context, id, account))
            }
            manager.updateAppWidget(id, views)
        }
    }
}

private fun updateSummaryWidget(
    context: Context,
    manager: AppWidgetManager,
    ids: IntArray,
    data: SharedPreferences,
    title: String,
    key: String,
) {
    ids.forEach { id ->
        val account = widgetAccount(data, id)
        val views = RemoteViews(context.packageName, R.layout.widget_summary).apply {
            setTextViewText(R.id.widget_summary_title, title)
            setTextViewText(R.id.widget_summary_account, compact(widgetValue(data, id, "account_label", "Untis+"), 22))
            setTextViewText(R.id.widget_summary_body, compact(widgetValue(data, id, key, "Wird aktualisiert …"), 88))
            setTextViewText(R.id.widget_summary_status, compact(widgetValue(data, id, "status", ""), 10))
            setOnClickPendingIntent(R.id.widget_summary_root, openAppIntent(context, id, account))
        }
        manager.updateAppWidget(id, views)
    }
}

class UntisWidgetHomework : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) =
        updateSummaryWidget(context, manager, ids, data, "HAUSAUFGABEN", "homework_summary")
}

class UntisWidgetNotifications : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) =
        updateSummaryWidget(context, manager, ids, data, "MITTEILUNGEN", "notification_summary")
}

class UntisWidgetCustom : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) {
        ids.forEach { id ->
            val config = customConfiguration(data, id)
            val account = config?.optString("accountId")?.takeIf { it.isNotEmpty() } ?: widgetAccount(data, id)
            val blocks = config?.optJSONArray("blocks") ?: JSONArray().put("current").put("next").put("status")
            val useSystemColors = config?.optString("colorMode", "custom") == "system"
            val textColor = if (useSystemColors) context.getColor(R.color.widget_on_surface)
                else config?.optInt("textColor", Color.WHITE) ?: Color.WHITE
            val accent = if (useSystemColors) context.getColor(R.color.widget_primary)
                else config?.optInt("accentColor", textColor) ?: textColor
            val background = if (useSystemColors) context.getColor(R.color.widget_surface)
                else config?.optInt("backgroundColor", Color.rgb(23, 28, 37)) ?: Color.rgb(23, 28, 37)
            val scale = (config?.optDouble("textScale", 1.0) ?: 1.0).toFloat()
            val idsForText = intArrayOf(R.id.widget_custom_one, R.id.widget_custom_two, R.id.widget_custom_three, R.id.widget_custom_four)
            val views = RemoteViews(context.packageName, R.layout.widget_custom).apply {
                setInt(R.id.widget_custom_root, "setBackgroundColor", background)
                idsForText.forEachIndexed { index, viewId ->
                    val text = if (index < blocks.length()) customContent(data, id, account, blocks.optString(index)) else ""
                    setViewVisibility(viewId, if (text.isEmpty()) View.GONE else View.VISIBLE)
                    setTextViewText(viewId, compact(text, if (index == 0) 56 else 96))
                    setTextColor(viewId, if (index == 0) accent else textColor)
                    setFloat(viewId, "setTextSize", if (index == 0) 18f * scale else 14f * scale)
                }
                setOnClickPendingIntent(R.id.widget_custom_root, openAppIntent(context, id, account))
            }
            manager.updateAppWidget(id, views)
        }
    }
}
