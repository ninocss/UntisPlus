package com.ninocss.untisplus

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

private fun openAppIntent(context: Context): PendingIntent = PendingIntent.getActivity(
    context, 0, Intent(context, MainActivity::class.java),
    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
)

class UntisWidgetCurrentLesson : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) {
        ids.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_current_lesson).apply {
                setTextViewText(R.id.widget_current_lesson, data.getString("current_lesson", "Keine aktuelle Stunde"))
                setTextViewText(R.id.widget_next_lesson, data.getString("next_lesson", ""))
                setTextViewText(R.id.widget_time_remaining, data.getString("time_remaining", ""))
                setOnClickPendingIntent(R.id.widget_current_root, openAppIntent(context))
            }
            manager.updateAppWidget(id, views)
        }
    }
}

class UntisWidgetDailySchedule : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) {
        ids.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_daily_schedule).apply {
                setTextViewText(R.id.widget_daily_schedule, data.getString("daily_schedule", "Stundenplan wird geladen …"))
                setOnClickPendingIntent(R.id.widget_schedule_root, openAppIntent(context))
            }
            manager.updateAppWidget(id, views)
        }
    }
}

private fun updateSummaryWidget(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences, title: String, key: String) {
    ids.forEach { id ->
        val views = RemoteViews(context.packageName, R.layout.widget_summary).apply {
            setTextViewText(R.id.widget_summary_title, title)
            setTextViewText(R.id.widget_summary_body, data.getString(key, "Wird aktualisiert …"))
            setOnClickPendingIntent(R.id.widget_summary_root, openAppIntent(context))
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
