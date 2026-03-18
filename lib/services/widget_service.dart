import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroupId = 'com.example.untisplus';
  static const String androidWidgetName = 'UntisWidgetProvider';
  static const String iOSWidgetName = 'UntisWidget';

  static Future<void> updateWidgets({
    required String currentLesson,
    required String nextLesson,
    required String timeRemaining,
    required String dailySchedule,
  }) async {
    // Save data to the group for the widget to read
    await HomeWidget.saveWidgetData<String>('current_lesson', currentLesson);
    await HomeWidget.saveWidgetData<String>('next_lesson', nextLesson);
    await HomeWidget.saveWidgetData<String>('time_remaining', timeRemaining);
    await HomeWidget.saveWidgetData<String>('daily_schedule', dailySchedule);

    // Trigger update for both widgets
    await HomeWidget.updateWidget(
      name: 'UntisWidgetCurrentLesson',
      iOSName: iOSWidgetName,
      qualifiedAndroidName: 'com.example.untisplus.UntisWidgetCurrentLesson',
    );
    await HomeWidget.updateWidget(
      name: 'UntisWidgetDailySchedule',
      iOSName: iOSWidgetName,
      qualifiedAndroidName: 'com.example.untisplus.UntisWidgetDailySchedule',
    );
  }
}