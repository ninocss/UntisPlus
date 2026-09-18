part of '../../main.dart';

/// Calendar event types that can be synced to the native calendar
enum CalendarEventType {
  tests('tests', Icons.quiz_rounded, Color(0xFFEF5350)),
  homework('homework', Icons.assignment_rounded, Color(0xFFFFA726)),
  conversations('conversations', Icons.forum_rounded, Color(0xFF26A69A)),
  learning('learning', Icons.menu_book_rounded, Color(0xFF66BB6A)),
  assignments('assignments', Icons.event_available_rounded, Color(0xFF5C6BC0));

  const CalendarEventType(this.key, this.icon, this.defaultColor);
  final String key;
  final IconData icon;
  final Color defaultColor;

  static CalendarEventType? fromKey(String? key) {
    if (key == null) return null;
    for (final e in CalendarEventType.values) {
      if (e.key == key) return e;
    }
    return null;
  }
}

/// Configuration for a calendar event type's sync destination
class CalendarSyncConfig {
  final CalendarEventType type;
  final String? subCalendarId; // null = use default calendar
  final String? subCalendarName;
  final String? subCalendarColor;
  final bool enabled;

  const CalendarSyncConfig({
    required this.type,
    this.subCalendarId,
    this.subCalendarName,
    this.subCalendarColor,
    this.enabled = false,
  });

  CalendarSyncConfig copyWith({
    CalendarEventType? type,
    String? subCalendarId,
    String? subCalendarName,
    String? subCalendarColor,
    bool? enabled,
  }) {
    return CalendarSyncConfig(
      type: type ?? this.type,
      subCalendarId: subCalendarId ?? this.subCalendarId,
      subCalendarName: subCalendarName ?? this.subCalendarName,
      subCalendarColor: subCalendarColor ?? this.subCalendarColor,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.key,
    'subCalendarId': subCalendarId,
    'subCalendarName': subCalendarName,
    'subCalendarColor': subCalendarColor,
    'enabled': enabled,
  };

  factory CalendarSyncConfig.fromJson(Map<String, dynamic> json) {
    return CalendarSyncConfig(
      type: CalendarEventType.fromKey(json['type'] as String?) ?? CalendarEventType.tests,
      subCalendarId: json['subCalendarId'] as String?,
      subCalendarName: json['subCalendarName'] as String?,
      subCalendarColor: json['subCalendarColor'] as String?,
      enabled: json['enabled'] as bool? ?? false,
    );
  }
}

/// Represents a native calendar from the system
class SystemCalendar {
  final String id;
  final String name;
  final String color; // hex string like '#FF0000'
  final bool isReadOnly;
  final bool isDefault;

  const SystemCalendar({
    required this.id,
    required this.name,
    required this.color,
    this.isReadOnly = false,
    this.isDefault = false,
  });

  Color get colorValue {
    try {
      final hex = color.replaceFirst('#', '');
      return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'isReadOnly': isReadOnly,
    'isDefault': isDefault,
  };

  factory SystemCalendar.fromJson(Map<String, dynamic> json) {
    return SystemCalendar(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      color: json['color'] as String? ?? '#000000',
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

/// Event to be synced to native calendar
class CalendarSyncEvent {
  final String id; // unique identifier (e.g., "test_123" or "homework_456")
  final CalendarEventType type;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? sourceId; // reference to original entity (test id, homework id, etc.)
  final Map<String, dynamic> metadata; // extra data for updates/deletion

  const CalendarSyncEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.sourceId,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.key,
    'title': title,
    'description': description,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'location': location,
    'sourceId': sourceId,
    'metadata': metadata,
  };

  factory CalendarSyncEvent.fromJson(Map<String, dynamic> json) {
    return CalendarSyncEvent(
      id: json['id'] as String? ?? '',
      type: CalendarEventType.fromKey(json['type'] as String?) ?? CalendarEventType.tests,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'] as String? ?? '') ?? DateTime.now(),
      location: json['location'] as String?,
      sourceId: json['sourceId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
}