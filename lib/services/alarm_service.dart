import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';

/// User-configured recurring alarm. Weekdays use [DateTime.weekday] (1 = Mon).
class ManualAlarmConfig {
  const ManualAlarmConfig({
    required this.id,
    required this.timeOfDayMinutes,
    required this.weekdays,
    this.enabled = true,
    this.label = 'Wecker',
  });

  final String id;
  final int timeOfDayMinutes;
  final List<int> weekdays;
  final bool enabled;
  final String label;

  ManualAlarmConfig copyWith({
    int? timeOfDayMinutes,
    List<int>? weekdays,
    bool? enabled,
    String? label,
  }) => ManualAlarmConfig(
    id: id,
    timeOfDayMinutes: timeOfDayMinutes ?? this.timeOfDayMinutes,
    weekdays: weekdays ?? this.weekdays,
    enabled: enabled ?? this.enabled,
    label: label ?? this.label,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'timeOfDayMinutes': timeOfDayMinutes,
    'weekdays': weekdays,
    'enabled': enabled,
    'label': label,
  };

  factory ManualAlarmConfig.fromJson(Map<String, dynamic> json) {
    final days =
        (json['weekdays'] as List? ?? const <dynamic>[])
            .map(
              (value) => value is num ? value.toInt() : int.tryParse('$value'),
            )
            .whereType<int>()
            .where(
              (value) => value >= DateTime.monday && value <= DateTime.sunday,
            )
            .toSet()
            .toList()
          ..sort();
    return ManualAlarmConfig(
      id: json['id']?.toString() ?? '',
      timeOfDayMinutes: ((json['timeOfDayMinutes'] as num?)?.toInt() ?? 420)
          .clamp(0, 1439),
      weekdays: days,
      enabled: json['enabled'] != false,
      label: json['label']?.toString().trim().isNotEmpty == true
          ? json['label'].toString().trim()
          : 'Wecker',
    );
  }
}

class AlarmConfig {
  const AlarmConfig({
    this.smartEnabled = false,
    this.leadMinutes = 45,
    this.snoozeMinutes = 5,
    this.preAlarmNotificationMinutes = 30,
    this.nextAlarmEarlierMinutes = 15,
    this.leadMinutesByFirstLessonStart = const {},
    this.ringtoneUri,
    this.manualAlarms = const [],
    this.dateOverrides = const {},
  });

  final bool smartEnabled;
  final int leadMinutes;
  final int snoozeMinutes;
  /// A heads-up is shown this long before the next alarm. Zero disables it.
  final int preAlarmNotificationMinutes;
  /// The amount offered by the "earlier next time" control.
  final int nextAlarmEarlierMinutes;
  /// Per-first-lesson lead-time overrides keyed by minutes after midnight.
  /// A value of -1 explicitly disables the timetable alarm for that start time.
  final Map<int, int> leadMinutesByFirstLessonStart;
  final String? ringtoneUri;
  final List<ManualAlarmConfig> manualAlarms;
  final Map<String, AlarmDateOverride> dateOverrides;

  AlarmConfig copyWith({
    bool? smartEnabled,
    int? leadMinutes,
    int? snoozeMinutes,
    int? preAlarmNotificationMinutes,
    int? nextAlarmEarlierMinutes,
    Map<int, int>? leadMinutesByFirstLessonStart,
    String? ringtoneUri,
    bool clearRingtone = false,
    List<ManualAlarmConfig>? manualAlarms,
    Map<String, AlarmDateOverride>? dateOverrides,
  }) => AlarmConfig(
    smartEnabled: smartEnabled ?? this.smartEnabled,
    leadMinutes: (leadMinutes ?? this.leadMinutes).clamp(0, 300),
    snoozeMinutes: (snoozeMinutes ?? this.snoozeMinutes).clamp(1, 60),
    preAlarmNotificationMinutes:
        (preAlarmNotificationMinutes ?? this.preAlarmNotificationMinutes)
            .clamp(0, 180),
    nextAlarmEarlierMinutes:
        (nextAlarmEarlierMinutes ?? this.nextAlarmEarlierMinutes).clamp(1, 120),
    leadMinutesByFirstLessonStart:
        leadMinutesByFirstLessonStart ?? this.leadMinutesByFirstLessonStart,
    ringtoneUri: clearRingtone ? null : ringtoneUri ?? this.ringtoneUri,
    manualAlarms: manualAlarms ?? this.manualAlarms,
    dateOverrides: dateOverrides ?? this.dateOverrides,
  );

  Map<String, dynamic> toJson() => {
    'version': 3,
    'smartEnabled': smartEnabled,
    'leadMinutes': leadMinutes,
    'snoozeMinutes': snoozeMinutes,
    'preAlarmNotificationMinutes': preAlarmNotificationMinutes,
    'nextAlarmEarlierMinutes': nextAlarmEarlierMinutes,
    'leadMinutesByFirstLessonStart': {
      for (final entry in leadMinutesByFirstLessonStart.entries)
        entry.key.toString(): entry.value,
    },
    'ringtoneUri': ringtoneUri,
    'manualAlarms': manualAlarms.map((alarm) => alarm.toJson()).toList(),
    'dateOverrides': {
      for (final entry in dateOverrides.entries) entry.key: entry.value.toJson(),
    },
  };

  factory AlarmConfig.fromJson(Map<String, dynamic> json) => AlarmConfig(
    smartEnabled: json['smartEnabled'] == true,
    leadMinutes: ((json['leadMinutes'] as num?)?.toInt() ?? 45).clamp(0, 300),
    snoozeMinutes: ((json['snoozeMinutes'] as num?)?.toInt() ?? 5).clamp(1, 60),
    preAlarmNotificationMinutes:
        ((json['preAlarmNotificationMinutes'] as num?)?.toInt() ?? 30).clamp(
          0,
          180,
        ),
    nextAlarmEarlierMinutes:
        ((json['nextAlarmEarlierMinutes'] as num?)?.toInt() ?? 15).clamp(1, 120),
    leadMinutesByFirstLessonStart:
        (json['leadMinutesByFirstLessonStart'] as Map? ?? const <dynamic, dynamic>{})
            .map(
              (key, value) => MapEntry(
                int.tryParse(key.toString()) ?? -2,
                (value as num?)?.toInt() ?? -2,
              ),
            )
          ..removeWhere(
            (start, minutes) =>
                start < 0 || start >= 24 * 60 || (minutes < -1 || minutes > 300),
          ),
    ringtoneUri: json['ringtoneUri']?.toString(),
    manualAlarms: (json['manualAlarms'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (value) =>
              ManualAlarmConfig.fromJson(Map<String, dynamic>.from(value)),
        )
        .where((alarm) => alarm.id.isNotEmpty)
        .toList(growable: false),
    dateOverrides: (json['dateOverrides'] as Map? ?? const <dynamic, dynamic>{})
        .map(
          (key, value) => MapEntry(
            key.toString(),
            value is Map
                ? AlarmDateOverride.fromJson(Map<String, dynamic>.from(value))
                : const AlarmDateOverride(),
          ),
        )
      ..removeWhere((key, value) => !_isAlarmDateKey(key) || value.isEmpty),
  );
}

/// An explicit exception for one timetable day. It never changes recurring
/// manual alarms; those stay a separate, predictable concept.
class AlarmDateOverride {
  const AlarmDateOverride({
    this.disabled = false,
    this.customTimeOfDayMinutes,
    this.earlierMinutes,
  });

  final bool disabled;
  final int? customTimeOfDayMinutes;
  final int? earlierMinutes;

  bool get isEmpty => !disabled && customTimeOfDayMinutes == null && earlierMinutes == null;

  AlarmDateOverride copyWith({
    bool? disabled,
    int? customTimeOfDayMinutes,
    int? earlierMinutes,
    bool clearCustomTime = false,
    bool clearEarlier = false,
  }) => AlarmDateOverride(
    disabled: disabled ?? this.disabled,
    customTimeOfDayMinutes: clearCustomTime
        ? null
        : customTimeOfDayMinutes ?? this.customTimeOfDayMinutes,
    earlierMinutes: clearEarlier ? null : earlierMinutes ?? this.earlierMinutes,
  );

  Map<String, dynamic> toJson() => {
    'disabled': disabled,
    'customTimeOfDayMinutes': customTimeOfDayMinutes,
    'earlierMinutes': earlierMinutes,
  };

  factory AlarmDateOverride.fromJson(Map<String, dynamic> json) =>
      AlarmDateOverride(
        disabled: json['disabled'] == true,
        customTimeOfDayMinutes:
            ((json['customTimeOfDayMinutes'] as num?)?.toInt())?.clamp(0, 1439),
        earlierMinutes: ((json['earlierMinutes'] as num?)?.toInt())?.clamp(1, 120),
      );
}

bool _isAlarmDateKey(String value) => RegExp(r'^\d{8}$').hasMatch(value);

String alarmDateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';

class AlarmReadiness {
  const AlarmReadiness({
    required this.exactAlarms,
    required this.fullScreenIntent,
    required this.dndAccess,
    required this.notifications,
  });

  final bool exactAlarms;
  final bool fullScreenIntent;
  final bool dndAccess;
  final bool notifications;

  bool get isReady =>
      exactAlarms && fullScreenIntent && dndAccess && notifications;

  factory AlarmReadiness.fromMap(Map<dynamic, dynamic> map) => AlarmReadiness(
    exactAlarms: map['exactAlarms'] == true,
    fullScreenIntent: map['fullScreenIntent'] == true,
    dndAccess: map['dndAccess'] == true,
    notifications: map['notifications'] == true,
  );
}

/// Pure timetable-to-wake-time calculation. It has no Android dependency and
/// is intentionally available to unit tests.
class AlarmPlanCandidate {
  const AlarmPlanCandidate({
    required this.at,
    required this.baseAt,
    required this.lessonStartsAt,
    required this.dateKey,
    required this.label,
  });
  final DateTime at;
  final DateTime baseAt;
  final DateTime lessonStartsAt;
  final String dateKey;
  final String label;
}

class AlarmPlanner {
  const AlarmPlanner._();

  static AlarmPlanCandidate? nextSmartAlarm(
    List<dynamic> lessons, {
    required int leadMinutes,
    required DateTime now,
    String locale = 'de',
    Map<String, AlarmDateOverride> dateOverrides = const {},
    Map<int, int> leadMinutesByFirstLessonStart = const {},
  }) {
    // A timetable alarm is a wake-up alarm, never a reminder for a later
    // period. Pick only the first real lesson of each school day. This also
    // prevents a newly planned alarm while the student is already in class.
    final firstLessonByDate = <int, Map<dynamic, dynamic>>{};
    for (final raw in lessons.whereType<Map>()) {
      final lesson = Map<dynamic, dynamic>.from(raw);
      if (lesson['code']?.toString().toLowerCase() == 'cancelled') continue;
      final dateNumber = lesson['date'];
      final startNumber = lesson['startTime'];
      if (dateNumber is! num || startNumber is! num) continue;
      final dateText = dateNumber.toInt().toString().padLeft(8, '0');
      final time = startNumber.toInt();
      if (dateText.length != 8 || time < 0 || time > 2359) continue;
      final start = DateTime(
        int.parse(dateText.substring(0, 4)),
        int.parse(dateText.substring(4, 6)),
        int.parse(dateText.substring(6, 8)),
        time ~/ 100,
        time % 100,
      );
      // Weekends and holidays have no timetable entries. The explicit weekday
      // check additionally guards malformed imported timetable rows.
      if (start.weekday > DateTime.friday) continue;
      final existing = firstLessonByDate[dateNumber.toInt()];
      final existingStart = existing?['startTime'] as num?;
      if (existing == null ||
          startNumber.toInt() < (existingStart?.toInt() ?? time)) {
        firstLessonByDate[dateNumber.toInt()] = lesson;
      }
    }

    final candidates = <AlarmPlanCandidate>[];
    for (final lesson in firstLessonByDate.values) {
      final dateText = (lesson['date'] as num).toInt().toString().padLeft(
        8,
        '0',
      );
      final time = (lesson['startTime'] as num).toInt();
      final start = DateTime(
        int.parse(dateText.substring(0, 4)),
        int.parse(dateText.substring(4, 6)),
        int.parse(dateText.substring(6, 8)),
        time ~/ 100,
        time % 100,
      );
      final startOfDayMinutes = start.hour * 60 + start.minute;
      final matchedLeadMinutes = leadMinutesByFirstLessonStart[startOfDayMinutes];
      if (matchedLeadMinutes == -1) continue;
      final baseWakeAt = start.subtract(
        Duration(minutes: (matchedLeadMinutes ?? leadMinutes).clamp(0, 300)),
      );
      final override = dateOverrides[alarmDateKey(start)];
      if (override?.disabled == true) continue;
      var wakeAt = override?.customTimeOfDayMinutes == null
          ? baseWakeAt
          : DateTime(
              start.year,
              start.month,
              start.day,
              override!.customTimeOfDayMinutes! ~/ 60,
              override.customTimeOfDayMinutes! % 60,
            );
      if (override?.earlierMinutes != null) {
        wakeAt = wakeAt.subtract(Duration(minutes: override!.earlierMinutes!));
      }
      // Once the first wake moment has passed, skip that entire school day.
      if (!wakeAt.isAfter(now)) continue;
      candidates.add(AlarmPlanCandidate(
        at: wakeAt,
        baseAt: baseWakeAt,
        lessonStartsAt: start,
        dateKey: alarmDateKey(start),
        label: _lessonLabel(lesson, locale),
      ));
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.at.compareTo(b.at));
    return candidates.first;
  }

  static String _lessonLabel(Map<dynamic, dynamic> lesson, String locale) {
    final subjects = lesson['su'];
    if (subjects is List && subjects.isNotEmpty && subjects.first is Map) {
      final first = subjects.first as Map;
      final value =
          first['longName'] ??
          first['longname'] ??
          first['name'] ??
          first['displayName'];
      if (value?.toString().trim().isNotEmpty == true) {
        return value.toString().trim();
      }
    }
    return AppL10n.of(locale).ui('alarmSchedule');
  }
}

class _SmartAlarmPlan {
  const _SmartAlarmPlan({
    required this.at,
    required this.baseAt,
    required this.dateKey,
    required this.label,
  });
  final DateTime at;
  final DateTime baseAt;
  final String dateKey;
  final String label;

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'baseAt': baseAt.toIso8601String(),
    'dateKey': dateKey,
    'label': label,
  };

  factory _SmartAlarmPlan.fromJson(Map<String, dynamic> json) =>
      _SmartAlarmPlan(
        at: DateTime.parse(json['at'] as String),
        baseAt: DateTime.tryParse(json['baseAt']?.toString() ?? '') ??
            DateTime.parse(json['at'] as String),
        dateKey: json['dateKey']?.toString() ??
            alarmDateKey(DateTime.parse(json['at'] as String)),
        label: json['label']?.toString() ?? 'Stundenplan-Wecker',
      );
}

/// Owns the durable alarm configuration and hands only normalized alarm plans
/// to Android. Android, not a Dart timer, owns the actual wake-up event.
class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  static const _channel = MethodChannel('untisplus/alarm');
  static const _configKey = 'alarmConfigV1';
  static const _smartPlanKey = 'alarmSmartPlanV1';

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<AlarmConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKey);
    if (raw == null) return const AlarmConfig();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AlarmConfig.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return const AlarmConfig();
  }

  Future<void> saveConfig(AlarmConfig config, {bool reschedule = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
    if (reschedule) await syncStoredPlans();
  }

  Future<void> restore() => syncStoredPlans();

  Future<void> syncStoredPlans() async {
    if (!_supported) return;
    final config = await loadConfig();
    final smartPlan = _applyDateOverride(await _loadSmartPlan(), config);
    await _pushPlans(config, smartPlan);
  }

  /// Persists a visible day marker immediately. The caller can then refresh
  /// the timetable; if offline, the stored next plan is still adjusted when it
  /// refers to this date.
  Future<void> saveDateOverride(
    String dateKey,
    AlarmDateOverride? override,
  ) async {
    if (!_isAlarmDateKey(dateKey)) return;
    final config = await loadConfig();
    final next = Map<String, AlarmDateOverride>.from(config.dateOverrides);
    if (override == null || override.isEmpty) {
      next.remove(dateKey);
    } else {
      next[dateKey] = override;
    }
    await saveConfig(config.copyWith(dateOverrides: next));
  }

  /// Adds the configured early offset to the currently scheduled timetable
  /// day. This makes the quick action deterministic even if tomorrow changes.
  Future<bool> makeNextSmartAlarmEarlier() async {
    final config = await loadConfig();
    final plan = _applyDateOverride(await _loadSmartPlan(), config);
    if (plan == null) return false;
    final existing = config.dateOverrides[plan.dateKey] ??
        const AlarmDateOverride();
    final next = Map<String, AlarmDateOverride>.from(config.dateOverrides)
      ..[plan.dateKey] = existing.copyWith(
        earlierMinutes: config.nextAlarmEarlierMinutes,
      );
    await saveConfig(config.copyWith(dateOverrides: next));
    return true;
  }

  /// Recalculates the smart alarm from a raw WebUntis response. Hidden
  /// timetable subjects deliberately do not affect this safety-critical choice.
  Future<void> syncSmartAlarmWithTimetable(
    List<dynamic> lessons, {
    DateTime? now,
  }) async {
    if (!_supported) return;
    final config = await loadConfig();
    final prefs = await SharedPreferences.getInstance();
    final locale = prefs.getString('appLocale') ?? 'de';
    _SmartAlarmPlan? smartPlan;
    if (config.smartEnabled) {
      smartPlan = _findNextSmartPlan(
        lessons,
        config,
        now ?? DateTime.now(),
        locale,
      );
    }
    if (smartPlan == null) {
      await prefs.remove(_smartPlanKey);
    } else {
      await prefs.setString(_smartPlanKey, jsonEncode(smartPlan.toJson()));
    }
    await _pushPlans(config, _applyDateOverride(smartPlan, config));
  }

  Future<_SmartAlarmPlan?> _loadSmartPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_smartPlanKey);
    if (raw == null) return null;
    try {
      final plan = _SmartAlarmPlan.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      return plan.at.isAfter(DateTime.now()) ? plan : null;
    } catch (_) {
      return null;
    }
  }

  _SmartAlarmPlan? _findNextSmartPlan(
    List<dynamic> lessons,
    AlarmConfig config,
    DateTime now,
    String locale,
  ) {
    final candidate = AlarmPlanner.nextSmartAlarm(
      lessons,
      leadMinutes: config.leadMinutes,
      now: now,
      locale: locale,
      dateOverrides: config.dateOverrides,
      leadMinutesByFirstLessonStart: config.leadMinutesByFirstLessonStart,
    );
    if (candidate == null) return null;
    return _SmartAlarmPlan(
      at: candidate.at,
      baseAt: candidate.baseAt,
      dateKey: candidate.dateKey,
      label: AppL10n.of(locale)
          .ui('alarmAt')
          .replaceAll('{label}', candidate.label)
          .replaceAll(
            '{time}',
            _formatTime(candidate.lessonStartsAt),
          ),
    );
  }

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  _SmartAlarmPlan? _applyDateOverride(
    _SmartAlarmPlan? plan,
    AlarmConfig config,
  ) {
    if (plan == null) return null;
    final override = config.dateOverrides[plan.dateKey];
    if (override == null) return plan;
    if (override.disabled) return null;
    var at = override.customTimeOfDayMinutes == null
        ? plan.baseAt
        : DateTime(
            plan.baseAt.year,
            plan.baseAt.month,
            plan.baseAt.day,
            override.customTimeOfDayMinutes! ~/ 60,
            override.customTimeOfDayMinutes! % 60,
          );
    if (override.earlierMinutes != null) {
      at = at.subtract(Duration(minutes: override.earlierMinutes!));
    }
    if (!at.isAfter(DateTime.now())) return null;
    return _SmartAlarmPlan(
      at: at,
      baseAt: plan.baseAt,
      dateKey: plan.dateKey,
      label: plan.label,
    );
  }

  Future<void> _pushPlans(
    AlarmConfig config,
    _SmartAlarmPlan? smartPlan,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final locale = prefs.getString('appLocale') ?? 'de';
    final nativeCopy = AppL10n.of(locale).nativeAlarmCopy();
    final plans = <Map<String, dynamic>>[
      for (final alarm in config.manualAlarms)
        if (alarm.enabled && alarm.weekdays.isNotEmpty)
          {
            'id': 'manual-${alarm.id}',
            'kind': 'manual',
            'label': alarm.label,
            'timeOfDayMinutes': alarm.timeOfDayMinutes,
            'weekdays': alarm.weekdays,
            'snoozeMinutes': config.snoozeMinutes,
            'preAlarmNotificationMinutes': config.preAlarmNotificationMinutes,
            'ringtoneUri': config.ringtoneUri,
            'locale': locale,
            'nativeCopy': nativeCopy,
          },
      if (config.smartEnabled && smartPlan != null)
        {
          'id': 'smart-primary',
          'kind': 'smart',
          'label': smartPlan.label,
          'triggerAtMillis': smartPlan.at.millisecondsSinceEpoch,
          'dateKey': smartPlan.dateKey,
          'preAlarmNotificationMinutes': config.preAlarmNotificationMinutes,
          // The background refresh runs shortly before the heads-up. It can
          // cancel or move the plan before Android ever posts that message.
          'preRefreshAtMillis': smartPlan.at
              .subtract(Duration(
                minutes: config.preAlarmNotificationMinutes > 0
                    ? config.preAlarmNotificationMinutes + 1
                    : 15,
              ))
              .millisecondsSinceEpoch,
          'snoozeMinutes': config.snoozeMinutes,
          'ringtoneUri': config.ringtoneUri,
          'locale': locale,
          'nativeCopy': nativeCopy,
        },
    ];
    try {
      await _channel.invokeMethod<void>('replacePlans', {'plans': plans});
    } on PlatformException catch (error) {
      debugPrint('Alarm scheduling unavailable: ${error.code}');
    }
  }

  /// Re-publishes saved alarms after the app language changes. The schedules
  /// themselves are untouched; only their native-process copy is refreshed.
  Future<void> refreshNativeCopy() async {
    if (!_supported) return;
    final config = await loadConfig();
    await _pushPlans(config, await _loadSmartPlan());
  }

  Future<AlarmReadiness> readiness() async {
    if (!_supported) {
      return const AlarmReadiness(
        exactAlarms: false,
        fullScreenIntent: false,
        dndAccess: false,
        notifications: false,
      );
    }
    try {
      final raw = await _channel.invokeMethod<dynamic>('getReadiness');
      if (raw is Map) return AlarmReadiness.fromMap(raw);
    } on PlatformException catch (error) {
      debugPrint('Alarm readiness unavailable: ${error.code}');
    } catch (_) {}
    return const AlarmReadiness(
      exactAlarms: false,
      fullScreenIntent: false,
      dndAccess: false,
      notifications: false,
    );
  }

  Future<void> openPermissionSettings(String type) async {
    if (_supported) {
      try {
        await _channel.invokeMethod<void>('openPermissionSettings', {
          'type': type,
        });
      } catch (_) {}
    }
  }

  Future<String?> pickRingtone(String? currentUri) async {
    if (!_supported) return currentUri;
    try {
      return await _channel.invokeMethod<String>('pickRingtone', {
        'currentUri': currentUri,
      });
    } catch (_) {
      return currentUri;
    }
  }
}
