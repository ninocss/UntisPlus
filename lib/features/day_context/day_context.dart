import '../changes/domain/timetable_change.dart';

enum DayDataState { unavailable, cached, current }

class DayContextSnapshot {
  const DayContextSnapshot({
    required this.accountId,
    required this.date,
    required this.dataState,
    required this.lessons,
    required this.dueHomework,
    required this.changes,
    required this.nextLesson,
  });

  final String accountId;
  final DateTime date;
  final DayDataState dataState;
  final List<Map<String, dynamic>> lessons;
  final List<Map<String, dynamic>> dueHomework;
  final List<TimetableChange> changes;
  final Map<String, dynamic>? nextLesson;

  static DayContextSnapshot build({
    required String accountId,
    required DateTime date,
    required DayDataState dataState,
    required Iterable<dynamic> lessons,
    required Iterable<Map<String, dynamic>> homework,
    required Iterable<TimetableChange> changes,
    required Set<String> hiddenSubjects,
    DateTime? now,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    final today = now ?? DateTime.now();
    final visibleLessons =
        lessons
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) => !_hidden(item['_subjectShort'], hiddenSubjects))
            .toList()
          ..sort(
            (a, b) =>
                _number(a['startTime']).compareTo(_number(b['startTime'])),
          );
    final upcoming = visibleLessons.where((lesson) {
      if (lesson['code']?.toString().toLowerCase() == 'cancelled' ||
          lesson['cancelled'] == true) {
        return false;
      }
      if (day.isBefore(DateTime(today.year, today.month, today.day))) {
        return false;
      }
      if (!_sameDay(day, today)) return true;
      return _number(lesson['endTime']) > today.hour * 100 + today.minute;
    });
    final due =
        homework.where((item) {
          if (item['isDone'] == true ||
              item['_done'] == true ||
              _hidden(_homeworkSubject(item), hiddenSubjects)) {
            return false;
          }
          final dueDate = _date(item['dueDate'] ?? item['date']);
          if (dueDate == null) return false;
          final distance = dueDate.difference(day).inDays;
          return distance >= 0 && distance <= 2;
        }).toList()..sort(
          (a, b) => _date(
            a['dueDate'] ?? a['date'],
          )!.compareTo(_date(b['dueDate'] ?? b['date'])!),
        );
    final dateKey = day.year * 10000 + day.month * 100 + day.day;
    final dayChanges =
        changes
            .where(
              (change) =>
                  change.date == dateKey &&
                  !_hidden(change.subject, hiddenSubjects),
            )
            .toList()
          ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return DayContextSnapshot(
      accountId: accountId,
      date: day,
      dataState: dataState,
      lessons: visibleLessons,
      dueHomework: due,
      changes: dayChanges,
      nextLesson: upcoming.isEmpty ? null : upcoming.first,
    );
  }

  static bool _hidden(Object? subject, Set<String> hidden) =>
      hidden.contains(subject?.toString() ?? '');

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int _number(Object? value) => int.tryParse('$value') ?? 0;

  static Object? _homeworkSubject(Map<String, dynamic> item) {
    final lesson = item['_lesson'];
    final subjects = lesson is Map ? lesson['su'] : null;
    if (subjects is List && subjects.isNotEmpty && subjects.first is Map) {
      return (subjects.first as Map)['name'] ?? item['subject'];
    }
    return item['subject'];
  }

  static DateTime? _date(Object? value) {
    if (value is DateTime) return DateTime(value.year, value.month, value.day);
    final raw = '$value';
    if (raw.length != 8) {
      final parsed = DateTime.tryParse(raw);
      return parsed == null
          ? null
          : DateTime(parsed.year, parsed.month, parsed.day);
    }
    final year = int.tryParse(raw.substring(0, 4));
    final month = int.tryParse(raw.substring(4, 6));
    final day = int.tryParse(raw.substring(6, 8));
    if (year == null || month == null || day == null) return null;
    final result = DateTime(year, month, day);
    return result.year == year && result.month == month && result.day == day
        ? result
        : null;
  }
}
