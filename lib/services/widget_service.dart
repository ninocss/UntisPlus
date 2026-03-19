import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroupId = 'gay.ninoio.untisplus';
  static const String androidWidgetName = 'UntisWidgetProvider';
  static const String iOSWidgetName = 'UntisWidget';

  static Future<void> updateWidgets({
    required String currentLesson,
    required String nextLesson,
    required String timeRemaining,
    required String dailySchedule,
  }) async {
    await HomeWidget.saveWidgetData<String>('current_lesson', currentLesson);
    await HomeWidget.saveWidgetData<String>('next_lesson', nextLesson);
    await HomeWidget.saveWidgetData<String>('time_remaining', timeRemaining);
    await HomeWidget.saveWidgetData<String>('daily_schedule', dailySchedule);

    await HomeWidget.updateWidget(
      name: 'UntisWidgetCurrentLesson',
      iOSName: iOSWidgetName,
      qualifiedAndroidName: 'gay.ninoio.untisplus.UntisWidgetCurrentLesson',
    );
    await HomeWidget.updateWidget(
      name: 'UntisWidgetDailySchedule',
      iOSName: iOSWidgetName,
      qualifiedAndroidName: 'gay.ninoio.untisplus.UntisWidgetDailySchedule',
    );
  }
}