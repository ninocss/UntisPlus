import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetPreviewData {
  final String currentLesson;
  final String nextLesson;
  final String timeRemaining;
  final String dailySchedule;
  final String homeworkSummary;
  final String notificationSummary;
  final String accountLabel;
  final String status;

  const WidgetPreviewData({
    this.currentLesson = '',
    this.nextLesson = '',
    this.timeRemaining = '',
    this.dailySchedule = '',
    this.homeworkSummary = '',
    this.notificationSummary = '',
    this.accountLabel = '',
    this.status = '',
  });

  bool get hasPublishedData =>
      currentLesson.isNotEmpty ||
      dailySchedule.isNotEmpty ||
      homeworkSummary.isNotEmpty ||
      notificationSummary.isNotEmpty;
}

class WidgetService {
  static const String appGroupId = 'group.com.ninocss.untisplus';
  static const String androidWidgetName = 'UntisWidgetProvider';
  static const String iOSWidgetName = 'UntisWidget';
  static const String iOSScheduleWidgetName = 'UntisWidgetDailySchedule';
  static const String iOSHomeworkWidgetName = 'UntisWidgetHomework';
  static const String iOSNotificationsWidgetName = 'UntisWidgetNotifications';
  static Future<void>? _configuration;

  static String _key(String accountId, String field) =>
      'widget.$accountId.$field';

  static Future<void> _ensureConfigured() {
    if (kIsWeb) return Future.value();
    return _configuration ??= _configure();
  }

  static Future<void> _configure() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await HomeWidget.setAppGroupId(appGroupId);
    }
  }

  /// Makes the saved account names available to the native Android
  /// configuration activity and to WidgetKit's account picker. Credentials
  /// never leave Flutter preferences.
  static Future<void> publishAccountCatalog(
    Iterable<Map<String, String>> accounts,
  ) async {
    if (kIsWeb) return;
    await _ensureConfigured();
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
    await _ensureConfigured();
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
      iOSName: iOSHomeworkWidgetName,
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetHomework',
    );
    await HomeWidget.updateWidget(
      name: 'UntisWidgetNotifications',
      iOSName: iOSNotificationsWidgetName,
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetNotifications',
    );
    await HomeWidget.updateWidget(
      name: 'UntisWidgetDailySchedule',
      iOSName: iOSScheduleWidgetName,
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetDailySchedule',
    );
  }

  static Future<bool> requestPinWidget({
    required String name,
    required String qualifiedAndroidName,
    String? preferredAccountId,
  }) async {
    if (kIsWeb) return false;
    await _ensureConfigured();
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!supported) return false;
    if (preferredAccountId != null && preferredAccountId.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>(
        'widget_preferred_account',
        preferredAccountId,
      );
    }
    await HomeWidget.requestPinWidget(
      name: name,
      qualifiedAndroidName: qualifiedAndroidName,
    );
    return true;
  }

  static Future<WidgetPreviewData> readPreviewData(String accountId) async {
    if (kIsWeb || accountId.isEmpty) return const WidgetPreviewData();
    try {
      await _ensureConfigured();
      Future<String> read(String field) async =>
          await HomeWidget.getWidgetData<String>(
            _key(accountId, field),
            defaultValue: '',
          ) ??
          '';
      final values = await Future.wait([
        read('current_lesson'),
        read('next_lesson'),
        read('time_remaining'),
        read('daily_schedule'),
        read('homework_summary'),
        read('notification_summary'),
        read('account_label'),
        read('status'),
      ]);
      return WidgetPreviewData(
        currentLesson: values[0],
        nextLesson: values[1],
        timeRemaining: values[2],
        dailySchedule: values[3],
        homeworkSummary: values[4],
        notificationSummary: values[5],
        accountLabel: values[6],
        status: values[7],
      );
    } catch (_) {
      // The preview is also rendered on desktop builds where home_widget has
      // no platform implementation. An empty result keeps that screen useful.
      return const WidgetPreviewData();
    }
  }

  static Future<void> updateNotificationWidget(
    String summary, {
    String accountId = 'active',
  }) async {
    if (kIsWeb) return;
    await _ensureConfigured();
    await HomeWidget.saveWidgetData<String>(
      _key(accountId, 'notification_summary'),
      summary,
    );
    await HomeWidget.saveWidgetData<String>('notification_summary', summary);
    await HomeWidget.updateWidget(
      name: 'UntisWidgetNotifications',
      iOSName: iOSNotificationsWidgetName,
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetNotifications',
    );
  }
}
