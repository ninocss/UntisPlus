import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/timetable/domain/room_schedule.dart';

void main() {
  group('SchoolRoom', () {
    test('parses json with id, name, and longName and matches query', () {
      final room = SchoolRoom.fromJson({
        'id': '42',
        'name': 'R101',
        'longName': 'Physik Fachraum',
        'building': 'Hauptgebäude',
      });

      expect(room.id, 42);
      expect(room.name, 'R101');
      expect(room.longName, 'Physik Fachraum');
      expect(room.building, 'Hauptgebäude');
      expect(room.displayName, 'R101');
      expect(room.matches('101'), isTrue);
      expect(room.matches('physik'), isTrue);
      expect(room.matches('haupt'), isTrue);
      expect(room.matches('chemie'), isFalse);
    });

    test('handles fallback display name when name is empty', () {
      final room = SchoolRoom.fromJson({
        'id': 7,
        'longName': 'Aula',
      });
      expect(room.id, 7);
      expect(room.name, 'Aula');
      expect(room.displayName, 'Aula');
    });
  });

  group('RoomScheduleSnapshot', () {
    final now = DateTime(2026, 9, 24, 10, 15);

    test('finds current and next lesson, checks slot occupancy', () {
      final snapshot = RoomScheduleSnapshot.fromLessons([
        _roomLesson(
          start: 1000,
          end: 1045,
          subject: 'Physik',
          teacher: 'Fr. Schmidt',
          className: '10A',
        ),
        _roomLesson(
          start: 1100,
          end: 1145,
          subject: 'Chemie',
          teacher: 'Hr. Müller',
          className: '10B',
        ),
        _roomLesson(
          start: 1030,
          end: 1115,
          subject: 'Biologie',
          code: 'cancelled',
        ),
      ], now: now);

      expect(snapshot.current?.subject, 'Physik');
      expect(snapshot.current?.teacher, 'Fr. Schmidt');
      expect(snapshot.current?.className, '10A');
      expect(snapshot.current?.endTime, '10:45');

      expect(snapshot.next?.subject, 'Chemie');
      expect(snapshot.next?.teacher, 'Hr. Müller');
      expect(snapshot.next?.className, '10B');
      expect(snapshot.next?.startTime, '11:00');

      // Slot from 10:00 to 10:45 (600 to 645 minutes) is occupied by Physik
      expect(snapshot.isFreeDuring(600, 645), isFalse);
      expect(snapshot.lessonDuring(600, 645)?.subject, 'Physik');

      // Slot from 10:45 to 11:00 (645 to 660 minutes) is free
      expect(snapshot.isFreeDuring(645, 660), isTrue);
      expect(snapshot.lessonDuring(645, 660), isNull);

      // Slot from 11:00 to 11:45 (660 to 705 minutes) is occupied by Chemie
      expect(snapshot.isFreeDuring(660, 705), isFalse);
      expect(snapshot.lessonDuring(660, 705)?.subject, 'Chemie');
    });

    test('treats boundary points strictly: endMinute == slotStart is free', () {
      final snapshot = RoomScheduleSnapshot.fromLessons([
        _roomLesson(start: 800, end: 845),
      ], now: DateTime(2026, 9, 24, 8, 45));

      // 8:45 is exactly 525 minutes. Slot 525 to 570 should be free
      expect(snapshot.isFreeDuring(525, 570), isTrue);
      // Slot 480 to 525 is occupied
      expect(snapshot.isFreeDuring(480, 525), isFalse);
    });

    test('ignores cancelled lessons and lessons from other dates', () {
      final snapshot = RoomScheduleSnapshot.fromLessons([
        _roomLesson(start: 1000, end: 1045, code: 'cancelled'),
        _roomLesson(start: 1000, end: 1045, date: 20260925),
      ], now: now);

      expect(snapshot.current, isNull);
      expect(snapshot.next, isNull);
      expect(snapshot.isFreeDuring(600, 645), isTrue);
    });
  });
}

Map<String, dynamic> _roomLesson({
  required int start,
  required int end,
  String subject = 'Subject',
  String teacher = 'Teacher',
  String className = 'Class',
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
  'te': [
    {'name': teacher},
  ],
  'kl': [
    {'name': className},
  ],
};
