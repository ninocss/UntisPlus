package com.example.untisplus;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.widget.RemoteViews;
import es.antonborri.home_widget.HomeWidgetPlugin;

public class UntisWidgetCurrentLesson extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            // Holen der Daten aus HomeWidget
            String currentLesson = HomeWidgetPlugin.Companion.getData(context).getString("current_lesson", "Keine Stunde");
            String nextLesson = HomeWidgetPlugin.Companion.getData(context).getString("next_lesson", "Danach: -");
            String timeRemaining = HomeWidgetPlugin.Companion.getData(context).getString("time_remaining", "-");

            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_current_lesson);
            views.setTextViewText(R.id.widget_current_lesson, currentLesson);
            views.setTextViewText(R.id.widget_next_lesson, nextLesson);
            views.setTextViewText(R.id.widget_time_remaining, timeRemaining);

            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}