package gay.ninoio.untisplus;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.widget.RemoteViews;
import es.antonborri.home_widget.HomeWidgetPlugin;

public class UntisWidgetDailySchedule extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            // "daily_schedule" sollte als String-Block oder formatiert ablegt sein
            String schedule = HomeWidgetPlugin.Companion.getData(context).getString("daily_schedule", "Lade Daten...");

            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_daily_schedule);
            views.setTextViewText(R.id.widget_daily_schedule_text, schedule);

            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}