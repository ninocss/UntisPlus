part of '../../main.dart';

/// Repository for managing calendar sync configuration and operations
class CalendarSyncRepository {
  static const _prefsKeyConfigs = 'calendarSyncConfigs';
  static const _prefsKeyCalendars = 'calendarSyncSystemCalendars';
  static const _prefsKeyLastSync = 'calendarSyncLastSync';

  final SharedPreferences _prefs;
  final dynamic _nativeCalendar; // Use dynamic to avoid compile-time method checks

  CalendarSyncRepository(this._prefs, this._nativeCalendar);

  /// Load all sync configurations
  List<CalendarSyncConfig> loadConfigs() {
    final jsonList = _prefs.getStringList(_prefsKeyConfigs) ?? [];
    return jsonList
        .map((j) => CalendarSyncConfig.fromJson(jsonDecode(j) as Map<String, dynamic>))
        .toList();
  }

  /// Save all sync configurations
  Future<void> saveConfigs(List<CalendarSyncConfig> configs) async {
    final jsonList = configs.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList(_prefsKeyConfigs, jsonList);
  }

  /// Get config for a specific event type
  CalendarSyncConfig? getConfig(CalendarEventType type) {
    final configs = loadConfigs();
    for (final c in configs) {
      if (c.type == type) return c;
    }
    return null;
  }

  /// Update config for a specific event type
  Future<void> updateConfig(CalendarSyncConfig config) async {
    final configs = loadConfigs();
    int index = -1;
    for (int i = 0; i < configs.length; i++) {
      if (configs[i].type == config.type) {
        index = i;
        break;
      }
    }
    if (index >= 0) {
      configs[index] = config;
    } else {
      configs.add(config);
    }
    await saveConfigs(configs);
  }

  /// Enable/disable sync for a type
  Future<void> setEnabled(CalendarEventType type, bool enabled) async {
    final config = getConfig(type) ?? CalendarSyncConfig(type: type);
    await updateConfig(config.copyWith(enabled: enabled));
  }

  /// Set sub-calendar for a type
  Future<void> setSubCalendar(
    CalendarEventType type, {
    required String calendarId,
    String? name,
    String? color,
  }) async {
    final config = getConfig(type) ?? CalendarSyncConfig(type: type);
    await updateConfig(config.copyWith(
      subCalendarId: calendarId,
      subCalendarName: name,
      subCalendarColor: color,
      enabled: true,
    ));
  }

  /// Clear sub-calendar (use default)
  Future<void> clearSubCalendar(CalendarEventType type) async {
    final config = getConfig(type);
    if (config != null) {
      await updateConfig(config.copyWith(
        subCalendarId: null,
        subCalendarName: null,
        subCalendarColor: null,
      ));
    }
  }

  /// Load cached system calendars
  List<SystemCalendar> loadSystemCalendars() {
    final jsonList = _prefs.getStringList(_prefsKeyCalendars) ?? [];
    return jsonList
        .map((j) => SystemCalendar.fromJson(jsonDecode(j) as Map<String, dynamic>))
        .toList();
  }

  /// Fetch and cache system calendars
  Future<List<SystemCalendar>> fetchAndCacheSystemCalendars() async {
    try {
      // NativeCalendar API might differ - wrap in try-catch
      dynamic calendars;
      try {
        calendars = await _nativeCalendar.getCalendars();
      } catch (_) {
        calendars = <dynamic>[];
      }
      final systemCalendars = (calendars as List?)
          ?.map((c) => SystemCalendar(
                id: c['id']?.toString() ?? '',
                name: c['name']?.toString() ?? 'Unknown',
                color: c['color']?.toString() ?? '#000000',
                isReadOnly: c['isReadOnly'] as bool? ?? false,
                isDefault: c['isDefault'] as bool? ?? false,
              ))
          .where((c) => c.id.isNotEmpty)
          .toList() ?? <SystemCalendar>[];

      final jsonList = systemCalendars.map((c) => jsonEncode(c.toJson())).toList();
      await _prefs.setStringList(_prefsKeyCalendars, jsonList);
      return systemCalendars;
    } catch (e) {
      return loadSystemCalendars(); // return cached on error
    }
  }

  /// Get the target calendar ID for a given event type
  String? getTargetCalendarId(CalendarEventType type) {
    final config = getConfig(type);
    return config?.subCalendarId;
  }

  /// Get the target calendar name for a given event type
  String? getTargetCalendarName(CalendarEventType type) {
    final config = getConfig(type);
    return config?.subCalendarName;
  }

  /// Create a dedicated sub-calendar for an event type
  Future<String?> createSubCalendar(
    String name,
    Color color,
  ) async {
    try {
      final colorHex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
      return await _nativeCalendar.createCalendar(
        name: name,
        color: colorHex,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get last sync timestamp
  DateTime? getLastSyncTime() {
    final ts = _prefs.getInt(_prefsKeyLastSync);
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }

  /// Update last sync timestamp
  Future<void> setLastSyncTime(DateTime time) async {
    await _prefs.setInt(_prefsKeyLastSync, time.millisecondsSinceEpoch);
  }

  /// Initialize default configs for all event types
  Future<void> initializeDefaults() async {
    final existing = loadConfigs();
    if (existing.isNotEmpty) return;

    final defaults = CalendarEventType.values.map((type) {
      return CalendarSyncConfig(
        type: type,
        enabled: false,
      );
    }).toList();

    await saveConfigs(defaults);
  }
}