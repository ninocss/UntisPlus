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
}
