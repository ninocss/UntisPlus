import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroupId = 'group.com.ninocss.untisplus';
  static const String androidWidgetName = 'UntisWidgetProvider';
  static const String iOSWidgetName = 'UntisWidget';

  static String _key(String accountId, String field) =>
      'widget.$accountId.$field';

  /// Makes the saved account names available to the native Android
  /// configuration activity and to WidgetKit's account picker. Credentials
  /// never leave Flutter preferences.
  static Future<void> publishAccountCatalog(
    Iterable<Map<String, String>> accounts,
  ) async {
    if (kIsWeb) return;
    final catalog = accounts
        .where((account) => (account['id'] ?? '').isNotEmpty)
        .map(
          (account) => {
            'id': account['id'],
            'label': account['label'],
            'school': account['school'],
          },
        )
        .toList(growable: false);
    await HomeWidget.saveWidgetData<String>(
      'widget_accounts',
      jsonEncode(catalog),
    );
  }

  static Future<void> updateWidgets({
    required String currentLesson,
    required String nextLesson,
    required String timeRemaining,
    required String dailySchedule,
    required String homeworkSummary,
    required String notificationSummary,
    String accountId = 'active',
    String accountLabel = '',
    String status = '',
  }) async {
    if (kIsWeb) return;
    final values = <String, String>{
      'current_lesson': currentLesson,
      'next_lesson': nextLesson,
      'time_remaining': timeRemaining,
      'daily_schedule': dailySchedule,
      'homework_summary': homeworkSummary,
      'notification_summary': notificationSummary,
      'account_label': accountLabel,
      'status': status,
    };
    for (final entry in values.entries) {
      await HomeWidget.saveWidgetData<String>(
        _key(accountId, entry.key),
        entry.value,
      );
    }
    await HomeWidget.saveWidgetData<String>('widget_active_account', accountId);

    // Keep the legacy keys alive for previously placed widgets until Android
    // gives them an account binding during their next configuration.
    for (final entry in values.entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    }

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

  static Future<bool> requestPinWidget({
    required String name,
    required String qualifiedAndroidName,
  }) async {
    if (kIsWeb) return false;
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!supported) return false;
    await HomeWidget.requestPinWidget(
      name: name,
      qualifiedAndroidName: qualifiedAndroidName,
    );
    return true;
  }

  static Future<void> updateNotificationWidget(String summary) async {
    if (kIsWeb) return;
    await HomeWidget.saveWidgetData<String>('notification_summary', summary);
    await HomeWidget.updateWidget(
      name: 'UntisWidgetNotifications',
      iOSName: iOSWidgetName,
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetNotifications',
    );
  }
}
