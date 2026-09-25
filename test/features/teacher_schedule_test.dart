import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/timetable/domain/teacher_schedule.dart';

void main() {
  group('SchoolTeacher', () {
    test('builds a full name and searches by abbreviation', () {
      final teacher = SchoolTeacher.fromJson({
        'id': '12',
        'name': 'AB',
        'foreName': 'Anna',
        'longName': 'Becker',
      });

      expect(teacher.id, 12);
      expect(teacher.name, 'Anna Becker');
      expect(teacher.matches('ab'), isTrue);
      expect(teacher.matches('anna'), isTrue);
      expect(teacher.matches('müller'), isFalse);
    });
  });

  group('TeacherScheduleSnapshot', () {
    final now = DateTime(2026, 9, 24, 10, 15);

    test('finds the current and next non-cancelled lesson with locations', () {
      final snapshot = TeacherScheduleSnapshot.fromLessons([
        _lesson(start: 1000, end: 1045, subject: 'English', room: 'A1'),
        _lesson(start: 1100, end: 1145, subject: 'Math', room: 'B2'),
        _lesson(
          start: 1030,
          end: 1115,
          subject: 'Cancelled',
          room: 'X',
          code: 'cancelled',
        ),
      ], now: now);

      expect(snapshot.current?.subject, 'English');
      expect(snapshot.current?.room, 'A1');
      expect(snapshot.current?.endTime, '10:45');
      expect(snapshot.next?.subject, 'Math');
      expect(snapshot.next?.room, 'B2');
      expect(snapshot.next?.startTime, '11:00');
    });

    test('treats a lesson start as inclusive and its end as exclusive', () {
      final snapshot = TeacherScheduleSnapshot.fromLessons([
        _lesson(start: 900, end: 945),
        _lesson(start: 945, end: 1030),
      ], now: DateTime(2026, 9, 24, 9, 45));

      expect(snapshot.current?.startTime, '09:45');
      expect(snapshot.next, isNull);
    });

    test('ignores past lessons, cancelled lessons, and other dates', () {
      final snapshot = TeacherScheduleSnapshot.fromLessons([
        _lesson(start: 900, end: 945),
        _lesson(start: 1100, end: 1145, date: 20260925),
        _lesson(start: 1200, end: 1245, code: 'cancelled'),
      ], now: now);

      expect(snapshot.current, isNull);
      expect(snapshot.next, isNull);
    });

    test('returns no lesson for invalid times or an empty day', () {
      final snapshot = TeacherScheduleSnapshot.fromLessons([
        _lesson(start: 1260, end: 1300),
        {'startTime': 'bad', 'endTime': 1400},
      ], now: now);

      expect(snapshot.current, isNull);
      expect(snapshot.next, isNull);
    });
  });
}

Map<String, dynamic> _lesson({
  required int start,
  required int end,
  String subject = 'Subject',
  String room = 'R1',
  String? code,
  dynamic date = 20260924,
}) => {
  'date': date,
  'startTime': start,
  'endTime': end,
  'code': code,
  'su': [
    {'name': subject},
  ],
  'ro': [
    {'name': room},
  ],
};
