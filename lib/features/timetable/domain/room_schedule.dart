import '../../../core/defensive_parsers.dart';
import '../../../core/time_utils.dart';

class SchoolRoom {
  const SchoolRoom({
    required this.id,
    required this.name,
    this.longName = '',
    this.building = '',
  });

  final int id;
  final String name;
  final String longName;
  final String building;

  String get displayName => name.isNotEmpty ? name : longName;

  factory SchoolRoom.fromJson(Map<String, dynamic> json) {
    final name = _firstText(json, const [
      'name',
      'shortName',
      'code',
      'displayName',
    ]);
    final longName = _firstText(json, const [
      'longName',
      'longname',
      'description',
    ]);
    final building = _firstText(json, const [
      'building',
      'buildingName',
      'location',
    ]);
    final id = asIntOrNull(json['id']) ?? 0;

    return SchoolRoom(
      id: id,
      name: name.isNotEmpty ? name : longName,
      longName: longName,
      building: building,
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        longName.toLowerCase().contains(normalized) ||
        building.toLowerCase().contains(normalized);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolRoom &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}

class RoomLessonLocation {
  const RoomLessonLocation({
    required this.subject,
    required this.teacher,
    required this.className,
    required this.startMinute,
    required this.endMinute,
  });

  final String subject;
  final String teacher;
  final String className;
  final int startMinute;
  final int endMinute;

  String get startTime => _formatTime(startMinute);
  String get endTime => _formatTime(endMinute);
}

class RoomScheduleSnapshot {
  const RoomScheduleSnapshot({
    this.current,
    this.next,
    this.lessons = const <RoomLessonLocation>[],
  });

  final RoomLessonLocation? current;
  final RoomLessonLocation? next;
  final List<RoomLessonLocation> lessons;

  bool isFreeDuring(int startMinute, int endMinute) =>
      lessonDuring(startMinute, endMinute) == null;

  RoomLessonLocation? lessonDuring(int startMinute, int endMinute) {
    for (final lesson in lessons) {
      if (lesson.startMinute < endMinute && lesson.endMinute > startMinute) {
        return lesson;
      }
    }
    return null;
  }

  factory RoomScheduleSnapshot.fromLessons(
    Iterable<dynamic> rawLessons, {
    required DateTime now,
  }) {
    final today = untisDateInt(now);
    final currentMinute = now.hour * 60 + now.minute;
    final parsed = <RoomLessonLocation>[];

    for (final raw in rawLessons) {
      if (raw is! Map) continue;
      final lesson = raw.map((k, v) => MapEntry(k.toString(), v));
      if (_isCancelled(lesson) || !_isToday(lesson['date'], today)) continue;

      final start = untisTimeToMinutes(lesson['startTime']);
      final end = untisTimeToMinutes(lesson['endTime']);
      if (start == null || end == null || end <= start) continue;

      parsed.add(
        RoomLessonLocation(
          subject:
              _elementName(lesson['su']) ??
              _text(lesson['subject'] ?? lesson['name']),
          teacher:
              _elementName(lesson['te']) ??
              _text(lesson['teacher'] ?? lesson['teacherName']),
          className:
              _elementName(lesson['kl']) ??
              _text(lesson['kl'] ?? lesson['class'] ?? lesson['className']),
          startMinute: start,
          endMinute: end,
        ),
      );
    }

    parsed.sort((a, b) => a.startMinute.compareTo(b.startMinute));

    RoomLessonLocation? current;
    RoomLessonLocation? next;

    for (final lesson in parsed) {
      if (lesson.startMinute <= currentMinute &&
          currentMinute < lesson.endMinute) {
        current ??= lesson;
      } else if (lesson.startMinute > currentMinute) {
        next ??= lesson;
        break;
      }
    }

    return RoomScheduleSnapshot(
      current: current,
      next: next,
      lessons: List.unmodifiable(parsed),
    );
  }
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

bool _isCancelled(Map<String, dynamic> lesson) {
  final code = lesson['code']?.toString().toLowerCase().trim();
  if (code == 'cancelled') return true;
  final cellState = lesson['cellState']?.toString().toLowerCase().trim();
  return cellState == 'cancelled';
}

bool _isToday(dynamic dateValue, int today) {
  if (dateValue == null) return true;
  final parsed = asIntOrNull(dateValue);
  return parsed == null || parsed == today;
}

String? _elementName(dynamic value) {
  if (value is Map) {
    for (final key in const ['longName', 'longname', 'name', 'shortName']) {
      final text = _text(value[key]);
      if (text.isNotEmpty) return text;
    }
  }
  if (value is List) {
    final names = value.map(_elementName).whereType<String>().toSet();
    if (names.isNotEmpty) return names.join(', ');
  }
  return value is String && value.trim().isNotEmpty ? value.trim() : null;
}

String _text(dynamic value) => value?.toString().trim() ?? '';

String _formatTime(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}
