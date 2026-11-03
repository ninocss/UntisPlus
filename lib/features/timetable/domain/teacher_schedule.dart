import '../../../core/defensive_parsers.dart';
import '../../../core/time_utils.dart';

class SchoolTeacher {
  const SchoolTeacher({
    required this.id,
    required this.name,
    required this.abbreviation,
  });

  final int id;
  final String name;
  final String abbreviation;

  factory SchoolTeacher.fromJson(Map<String, dynamic> json) {
    final foreName = _firstText(json, const ['foreName', 'forename']);
    final lastName = _firstText(json, const ['longName', 'longname']);
    final composedName = [
      foreName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ');
    final name = composedName.isNotEmpty
        ? composedName
        : _firstText(json, const [
            'fullName',
            'displayName',
            'name',
            'shortName',
          ]);
    final id = asIntOrNull(json['id']);
    return SchoolTeacher(
      id: id ?? 0,
      name: name,
      abbreviation: _firstText(json, const ['name', 'shortName', 'code']),
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        abbreviation.toLowerCase().contains(normalized);
  }
}

class TeacherLessonLocation {
  const TeacherLessonLocation({
    required this.subject,
    required this.room,
    required this.startMinute,
    required this.endMinute,
  });

  final String subject;
  final String room;
  final int startMinute;
  final int endMinute;

  String get startTime => _formatTime(startMinute);
  String get endTime => _formatTime(endMinute);
}

class TeacherScheduleSnapshot {
  const TeacherScheduleSnapshot({this.current, this.next});

  final TeacherLessonLocation? current;
  final TeacherLessonLocation? next;

  factory TeacherScheduleSnapshot.fromLessons(
    Iterable<dynamic> lessons, {
    required DateTime now,
  }) {
    final today = untisDateInt(now);
    final currentMinute = now.hour * 60 + now.minute;
    final parsed = <TeacherLessonLocation>[];
    for (final raw in lessons) {
      if (raw is! Map) continue;
      final lesson = raw.map((key, value) => MapEntry(key.toString(), value));
      if (_isCancelled(lesson) || !_isToday(lesson['date'], today)) continue;
      final start = untisTimeToMinutes(lesson['startTime']);
      final end = untisTimeToMinutes(lesson['endTime']);
      if (start == null || end == null || end <= start) continue;
      parsed.add(
        TeacherLessonLocation(
          subject:
              _elementName(lesson['su']) ??
              _text(lesson['subject'] ?? lesson['name']),
          room: _elementName(lesson['ro']) ?? _text(lesson['room']),
          startMinute: start,
          endMinute: end,
        ),
      );
    }
    parsed.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    TeacherLessonLocation? current;
    TeacherLessonLocation? next;
    for (final lesson in parsed) {
      if (lesson.startMinute <= currentMinute &&
          currentMinute < lesson.endMinute) {
        current ??= lesson;
      } else if (lesson.startMinute > currentMinute) {
        next ??= lesson;
      }
    }
    return TeacherScheduleSnapshot(current: current, next: next);
  }
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _text(json[key]);
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _text(dynamic value) => value?.toString().trim() ?? '';

bool _isCancelled(Map<String, dynamic> lesson) =>
    _text(lesson['code']).toLowerCase() == 'cancelled' ||
    lesson['isCancelled'] == true ||
    lesson['cancelled'] == true;

bool _isToday(dynamic value, int today) {
  if (value == null) return true;
  final normalized = normalizeUntisDateInt(value);
  return normalized == null || normalized == today;
}

String? _elementName(dynamic value) {
  if (value is Map) {
    for (final key in const ['longName', 'longname', 'name', 'shortName']) {
      final name = _text(value[key]);
      if (name.isNotEmpty) return name;
    }
  }
  if (value is List) {
    final names = value.map(_elementName).whereType<String>().toSet();
    if (names.isNotEmpty) return names.join(', ');
  }
  if (value is String) return value.trim().isEmpty ? null : value.trim();
  return null;
}

String _formatTime(int minute) => formatMinutesOfDay(minute);
