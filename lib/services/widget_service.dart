import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroupId = 'group.com.ninocss.untisplus';
  static const String androidWidgetName = 'UntisWidgetProvider';
  static const String iOSWidgetName = 'UntisWidget';

  static Future<void> updateWidgets({
    required String currentLesson,
    required String nextLesson,
    required String timeRemaining,
    required String dailySchedule,
    required String homeworkSummary,
    required String notificationSummary,
  }) async {
    await HomeWidget.saveWidgetData<String>('current_lesson', currentLesson);
    await HomeWidget.saveWidgetData<String>('next_lesson', nextLesson);
    await HomeWidget.saveWidgetData<String>('time_remaining', timeRemaining);
    await HomeWidget.saveWidgetData<String>('daily_schedule', dailySchedule);
    await HomeWidget.saveWidgetData<String>('homework_summary', homeworkSummary);
    await HomeWidget.saveWidgetData<String>('notification_summary', notificationSummary);

    await HomeWidget.updateWidget(
      name: 'UntisWidgetCurrentLesson',
      iOSName: iOSWidgetName,
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetCurrentLesson',
    );
    await HomeWidget.updateWidget(
      name: 'UntisWidgetHomework',
      iOSName: iOSWidgetName,
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetHomework',
    );
    await HomeWidget.updateWidget(
      name: 'UntisWidgetNotifications',
      iOSName: iOSWidgetName,
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetNotifications',
    );
    await HomeWidget.updateWidget(
      name: 'UntisWidgetDailySchedule',
      iOSName: iOSWidgetName,
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetDailySchedule',
    );
  }

  static Future<void> updateNotificationWidget(String summary) async {
    await HomeWidget.saveWidgetData<String>('notification_summary', summary);
    await HomeWidget.updateWidget(
      name: 'UntisWidgetNotifications',
      iOSName: iOSWidgetName,
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetNotifications',
    );
  }
}
