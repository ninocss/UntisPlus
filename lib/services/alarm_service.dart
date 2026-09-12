import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    this.ringtoneUri,
    this.manualAlarms = const [],
  });

  final bool smartEnabled;
  final int leadMinutes;
  final int snoozeMinutes;
  final String? ringtoneUri;
  final List<ManualAlarmConfig> manualAlarms;

  AlarmConfig copyWith({
    bool? smartEnabled,
    int? leadMinutes,
    int? snoozeMinutes,
    String? ringtoneUri,
    bool clearRingtone = false,
    List<ManualAlarmConfig>? manualAlarms,
  }) => AlarmConfig(
    smartEnabled: smartEnabled ?? this.smartEnabled,
    leadMinutes: (leadMinutes ?? this.leadMinutes).clamp(0, 300),
    snoozeMinutes: (snoozeMinutes ?? this.snoozeMinutes).clamp(1, 60),
    ringtoneUri: clearRingtone ? null : ringtoneUri ?? this.ringtoneUri,
    manualAlarms: manualAlarms ?? this.manualAlarms,
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'smartEnabled': smartEnabled,
    'leadMinutes': leadMinutes,
    'snoozeMinutes': snoozeMinutes,
    'ringtoneUri': ringtoneUri,
    'manualAlarms': manualAlarms.map((alarm) => alarm.toJson()).toList(),
  };

  factory AlarmConfig.fromJson(Map<String, dynamic> json) => AlarmConfig(
    smartEnabled: json['smartEnabled'] == true,
    leadMinutes: ((json['leadMinutes'] as num?)?.toInt() ?? 45).clamp(0, 300),
    snoozeMinutes: ((json['snoozeMinutes'] as num?)?.toInt() ?? 5).clamp(1, 60),
    ringtoneUri: json['ringtoneUri']?.toString(),
    manualAlarms: (json['manualAlarms'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (value) =>
              ManualAlarmConfig.fromJson(Map<String, dynamic>.from(value)),
        )
        .where((alarm) => alarm.id.isNotEmpty)
        .toList(growable: false),
  );
}

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
  const AlarmPlanCandidate({required this.at, required this.label});
  final DateTime at;
  final String label;
}

class AlarmPlanner {
  const AlarmPlanner._();

  static AlarmPlanCandidate? nextSmartAlarm(
    List<dynamic> lessons, {
    required int leadMinutes,
    required DateTime now,
  }) {
    final candidates = <AlarmPlanCandidate>[];
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
      final wakeAt = start.subtract(
        Duration(minutes: leadMinutes.clamp(0, 300)),
      );
      if (!wakeAt.isAfter(now)) continue;
      candidates.add(
        AlarmPlanCandidate(at: wakeAt, label: _lessonLabel(lesson)),
      );
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.at.compareTo(b.at));
    return candidates.first;
  }

  static String _lessonLabel(Map<dynamic, dynamic> lesson) {
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
    return 'Stundenplan-Wecker';
  }
}

class _SmartAlarmPlan {
  const _SmartAlarmPlan({required this.at, required this.label});
  final DateTime at;
  final String label;

  Map<String, dynamic> toJson() => {'at': at.toIso8601String(), 'label': label};

  factory _SmartAlarmPlan.fromJson(Map<String, dynamic> json) =>
      _SmartAlarmPlan(
        at: DateTime.parse(json['at'] as String),
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

  bool get _supported => !kIsWeb && Platform.isAndroid;

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
    final smartPlan = await _loadSmartPlan();
    await _pushPlans(config, smartPlan);
  }

  /// Recalculates the smart alarm from a raw WebUntis response. Hidden
  /// timetable subjects deliberately do not affect this safety-critical choice.
  Future<void> syncSmartAlarmWithTimetable(
    List<dynamic> lessons, {
    DateTime? now,
  }) async {
    if (!_supported) return;
    final config = await loadConfig();
    _SmartAlarmPlan? smartPlan;
    if (config.smartEnabled) {
      smartPlan = _findNextSmartPlan(lessons, config, now ?? DateTime.now());
    }
    final prefs = await SharedPreferences.getInstance();
    if (smartPlan == null) {
      await prefs.remove(_smartPlanKey);
    } else {
      await prefs.setString(_smartPlanKey, jsonEncode(smartPlan.toJson()));
    }
    await _pushPlans(config, smartPlan);
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
  ) {
    final candidate = AlarmPlanner.nextSmartAlarm(
      lessons,
      leadMinutes: config.leadMinutes,
      now: now,
    );
    if (candidate == null) return null;
    return _SmartAlarmPlan(
      at: candidate.at,
      label:
          '${candidate.label} um ${_formatTime(candidate.at.add(Duration(minutes: config.leadMinutes)))}',
    );
  }

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _pushPlans(
    AlarmConfig config,
    _SmartAlarmPlan? smartPlan,
  ) async {
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
            'ringtoneUri': config.ringtoneUri,
          },
      if (config.smartEnabled && smartPlan != null)
        {
          'id': 'smart-primary',
          'kind': 'smart',
          'label': smartPlan.label,
          'triggerAtMillis': smartPlan.at.millisecondsSinceEpoch,
          'preRefreshAtMillis': smartPlan.at
              .subtract(const Duration(minutes: 15))
              .millisecondsSinceEpoch,
          'snoozeMinutes': config.snoozeMinutes,
          'ringtoneUri': config.ringtoneUri,
        },
    ];
    try {
      await _channel.invokeMethod<void>('replacePlans', {'plans': plans});
    } on PlatformException catch (error) {
      debugPrint('Alarm scheduling unavailable: ${error.code}');
    }
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
