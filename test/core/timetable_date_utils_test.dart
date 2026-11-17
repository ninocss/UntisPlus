import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/core/timetable_date_utils.dart';

void main() {
  group('resolveDefaultTimetableMonday', () {
    test('keeps current week on weekdays', () {
      final monday = resolveDefaultTimetableMonday(DateTime(2026, 9, 2));
      expect(monday, DateTime(2026, 8, 31));
    });

    test('uses next week on saturday', () {
      final monday = resolveDefaultTimetableMonday(DateTime(2026, 9, 5));
      expect(monday, DateTime(2026, 9, 7));
    });

    test('uses next week on sunday', () {
      final monday = resolveDefaultTimetableMonday(DateTime(2026, 9, 6));
      expect(monday, DateTime(2026, 9, 7));
    });
  });

  group('resolveInitialTimetableDayIndex', () {
    test('uses matching day during school week', () {
      expect(resolveInitialTimetableDayIndex(DateTime(2026, 8, 31)), 0);
      expect(resolveInitialTimetableDayIndex(DateTime(2026, 9, 4)), 4);
    });

    test('uses monday on weekends', () {
      expect(resolveInitialTimetableDayIndex(DateTime(2026, 9, 5)), 0);
      expect(resolveInitialTimetableDayIndex(DateTime(2026, 9, 6)), 0);
    });
  });

  group('isTimetableLessonPast', () {
    final now = DateTime(2026, 9, 2, 10, 30); // Wednesday 10:30 (630 min)

    test('returns true for all lessons on past days', () {
      final yesterday = DateTime(2026, 9, 1);
      expect(
        isTimetableLessonPast(dayDate: yesterday, endMin: 1200, now: now),
        isTrue,
      );
    });

    test('returns true for completed lessons on current day', () {
      final today = DateTime(2026, 9, 2);
      expect(
        isTimetableLessonPast(dayDate: today, endMin: 600, now: now), // 10:00
        isTrue,
      );
    });

    test('returns false for current and future lessons on current day', () {
      final today = DateTime(2026, 9, 2);
      expect(
        isTimetableLessonPast(dayDate: today, endMin: 645, now: now), // 10:45
        isFalse,
      );
      expect(
        isTimetableLessonPast(dayDate: today, endMin: 720, now: now), // 12:00
        isFalse,
      );
    });

    test('returns false for lessons on future days', () {
      final tomorrow = DateTime(2026, 9, 3);
      expect(
        isTimetableLessonPast(dayDate: tomorrow, endMin: 480, now: now), // 08:00
        isFalse,
      );
    });
  });
}
