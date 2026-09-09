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
  final String examSummary;
  final String accountLabel;
  final String status;

  const WidgetPreviewData({
    this.currentLesson = '',
    this.nextLesson = '',
    this.timeRemaining = '',
    this.dailySchedule = '',
    this.homeworkSummary = '',
    this.notificationSummary = '',
    this.examSummary = '',
    this.accountLabel = '',
    this.status = '',
  });

  bool get hasPublishedData =>
      currentLesson.isNotEmpty ||
      dailySchedule.isNotEmpty ||
      homeworkSummary.isNotEmpty ||
      notificationSummary.isNotEmpty;
}

/// A portable profile for the native homescreen widget renderers. It contains
/// appearance and block choices only; account data is published separately.
class WidgetConfiguration {
  static const maxBlocks = 4;
  final String id;
  final String name;
  final String accountId;
  final String layout;
  final List<String> blocks;
  final int backgroundColor;
  final int accentColor;
  final int textColor;
  final double opacity;
  final double cornerRadius;
  final double textScale;
  final bool showIcons;

  const WidgetConfiguration({
    required this.id,
    required this.name,
    required this.accountId,
    this.layout = 'stacked',
    this.blocks = const ['current', 'next', 'status'],
    this.backgroundColor = 0xFF171C25,
    this.accentColor = 0xFF8AB4F8,
    this.textColor = 0xFFF7F9FF,
    this.opacity = 0.94,
    this.cornerRadius = 24,
    this.textScale = 1,
    this.showIcons = true,
  });

  WidgetConfiguration copyWith({
    String? name,
    String? accountId,
    String? layout,
    List<String>? blocks,
    int? backgroundColor,
    int? accentColor,
    int? textColor,
    double? opacity,
    double? cornerRadius,
    double? textScale,
    bool? showIcons,
  }) => WidgetConfiguration(
    id: id,
    name: name ?? this.name,
    accountId: accountId ?? this.accountId,
    layout: layout ?? this.layout,
    blocks: (blocks ?? this.blocks).take(maxBlocks).toList(growable: false),
    backgroundColor: backgroundColor ?? this.backgroundColor,
    accentColor: accentColor ?? this.accentColor,
    textColor: textColor ?? this.textColor,
    opacity: opacity ?? this.opacity,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    textScale: textScale ?? this.textScale,
    showIcons: showIcons ?? this.showIcons,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'accountId': accountId,
    'layout': layout,
    'blocks': blocks,
    'backgroundColor': backgroundColor,
    'accentColor': accentColor,
    'textColor': textColor,
    'opacity': opacity,
    'cornerRadius': cornerRadius,
    'textScale': textScale,
    'showIcons': showIcons,
  };

  factory WidgetConfiguration.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['blocks'];
    return WidgetConfiguration(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Widget',
      accountId: json['accountId']?.toString() ?? '',
      layout: json['layout']?.toString() ?? 'stacked',
      blocks: rawBlocks is List
          ? rawBlocks.map((value) => value.toString()).take(maxBlocks).toList()
          : const ['current', 'next', 'status'],
      backgroundColor: (json['backgroundColor'] as num?)?.toInt() ?? 0xFF171C25,
      accentColor: (json['accentColor'] as num?)?.toInt() ?? 0xFF8AB4F8,
      textColor: (json['textColor'] as num?)?.toInt() ?? 0xFFF7F9FF,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.94,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 24,
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1,
      showIcons: json['showIcons'] != false,
    );
  }
}

class WidgetService {
  static const configurationsKey = 'widget_configurations_v1';
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

  static Future<void> publishConfigurations(
    Iterable<WidgetConfiguration> configurations,
  ) async {
    if (kIsWeb) return;
    await _ensureConfigured();
    await HomeWidget.saveWidgetData<String>(
      configurationsKey,
      jsonEncode(configurations.map((item) => item.toJson()).toList()),
    );
    await HomeWidget.updateWidget(
      name: 'UntisWidgetCustom',
      iOSName: 'UntisWidgetCustom',
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetCustom',
    );
  }

  static Future<void> updateWidgets({
    required String currentLesson,
    required String nextLesson,
    required String timeRemaining,
    required String dailySchedule,
    required String homeworkSummary,
    required String notificationSummary,
    String? examSummary,
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
    if (examSummary != null) values['exam_summary'] = examSummary;
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
    await HomeWidget.updateWidget(
      name: 'UntisWidgetCustom',
      iOSName: 'UntisWidgetCustom',
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetCustom',
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

  static Future<bool> requestPinCustomWidget({
    required String configurationId,
  }) async {
    if (kIsWeb) return false;
    await _ensureConfigured();
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!supported) return false;
    await HomeWidget.saveWidgetData<String>(
      'widget_preferred_configuration',
      configurationId,
    );
    await HomeWidget.requestPinWidget(
      name: 'UntisWidgetCustom',
      qualifiedAndroidName: 'com.ninocss.untisplus.UntisWidgetCustom',
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
        read('exam_summary'),
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
        examSummary: values[6],
        accountLabel: values[7],
        status: values[8],
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
