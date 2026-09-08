package com.ninocss.untisplus

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

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

class UntisWidgetCurrentLesson : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) {
        ids.forEach { id ->
            val account = widgetAccount(data, id)
            val views = RemoteViews(context.packageName, R.layout.widget_current_lesson).apply {
                setTextViewText(R.id.widget_account, compact(widgetValue(data, id, "account_label", "Untis+"), 22))
                setTextViewText(R.id.widget_current_lesson, compact(widgetValue(data, id, "current_lesson", "Freistunde"), 28))
                setTextViewText(R.id.widget_next_lesson, compact(widgetValue(data, id, "next_lesson", "Heute keine weitere Stunde"), 44))
                setTextViewText(R.id.widget_time_remaining, compact(widgetValue(data, id, "time_remaining", ""), 24))
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
                setTextViewText(R.id.widget_daily_schedule, widgetValue(data, id, "daily_schedule", "Stundenplan wird geladen …").lineSequence().take(3).joinToString("\n"))
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
