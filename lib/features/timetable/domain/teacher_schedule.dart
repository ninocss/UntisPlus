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
    final id = _asInt(json['id']);
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
    final today = now.year * 10000 + now.month * 100 + now.day;
    final currentMinute = now.hour * 60 + now.minute;
    final parsed = <TeacherLessonLocation>[];
    for (final raw in lessons) {
      if (raw is! Map) continue;
      final lesson = raw.map((key, value) => MapEntry(key.toString(), value));
      if (_isCancelled(lesson) || !_isToday(lesson['date'], today)) continue;
      final start = _untisMinute(lesson['startTime']);
      final end = _untisMinute(lesson['endTime']);
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

int? _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _text(dynamic value) => value?.toString().trim() ?? '';

bool _isCancelled(Map<String, dynamic> lesson) =>
    _text(lesson['code']).toLowerCase() == 'cancelled' ||
    lesson['isCancelled'] == true ||
    lesson['cancelled'] == true;

bool _isToday(dynamic value, int today) {
  if (value == null) return true;
  if (value is DateTime) {
    return value.year * 10000 + value.month * 100 + value.day == today;
  }
  final text = _text(value);
  if (text.contains('-')) {
    final date = DateTime.tryParse(text);
    if (date != null) {
      return date.year * 10000 + date.month * 100 + date.day == today;
    }
  }
  final parsed = _asInt(value);
  return parsed == null || parsed == today;
}

int? _untisMinute(dynamic value) {
  final time = _asInt(value);
  if (time == null || time < 0) return null;
  final hour = time ~/ 100;
  final minute = time % 100;
  if (hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
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

String _formatTime(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
