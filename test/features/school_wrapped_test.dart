import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/wrapped/school_wrapped.dart';

void main() {
  final year = WrappedYear(
    start: DateTime(2025, 9, 1),
    end: DateTime(2026, 7, 31),
  );

  test('year-end announcement cannot start on the final school day', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    expect(
      WrappedYear(
        start: today.subtract(const Duration(days: 100)),
        end: today,
      ).hasEnded,
      isFalse,
    );
    expect(
      WrappedYear(
        start: today.subtract(const Duration(days: 100)),
        end: today.subtract(const Duration(days: 1)),
      ).hasEnded,
      isTrue,
    );
  });

  test(
    'counts unique final lessons, overlapping absences, and free weekdays',
    () {
      final snapshot = buildWrappedSnapshot(
        year: year,
        today: DateTime(2025, 9, 12),
        weekDocuments: [
          {
            'monday': 20250901,
            'days': {
              '0': [
                {'id': 1, 'date': 20250901, 'startTime': 800, 'endTime': 900},
                {'id': 1, 'date': 20250901, 'startTime': 800, 'endTime': 900},
                {'id': 2, 'date': 20250901, 'startTime': 900, 'endTime': 1000},
              ],
              '1': [
                {
                  'id': 3,
                  'date': 20250902,
                  'startTime': 800,
                  'endTime': 900,
                  'code': 'cancelled',
                },
              ],
            },
          },
        ],
        holidays: [
          {'name': 'Autumn break', 'startDate': 20250908, 'endDate': 20250912},
          {'name': 'Autumn break', 'startDate': 20250909, 'endDate': 20250910},
        ],
        absences: [
          {
            'id': 10,
            'date': 20250901,
            'startTime': 830,
            'endTime': 930,
            'status': 'excused',
          },
          {
            'id': 10,
            'date': 20250901,
            'startTime': 830,
            'endTime': 930,
            'status': 'excused',
          },
        ],
        grades: [
          {
            'id': 'g1',
            'subject': 'Math',
            'date': '2025-09-05T12:00:00',
            'value': 2,
          },
          {
            'id': 'g2',
            'subject': 'Math',
            'date': '2025-08-05T12:00:00',
            'value': 1,
          },
        ],
        exams: [
          {'id': 4, 'date': 20250905},
          {'id': 4, 'date': 20250905},
        ],
        homework: [
          {'id': 5, 'dueDate': 20250905},
          {'id': 5, 'dueDate': 20250905},
        ],
        hasAbsenceSource: true,
        hasHolidaySource: true,
      );
      expect(snapshot.coveredWeeks, 1);
      expect(snapshot.expectedWeeks, 2);
      expect(snapshot.incomplete, isTrue);
      expect(snapshot.lessons, 2);
      expect(snapshot.lessonMinutes, 120);
      expect(snapshot.cancelled, 1);
      expect(snapshot.absenceRecords, 1);
      expect(snapshot.absentLessons, 2);
      expect(snapshot.freeWeekdays, 6);
      expect(snapshot.holidayNames, ['Autumn break']);
      expect(snapshot.grades, 1);
      expect(snapshot.gradeSubjects, {'Math': 1});
      expect(snapshot.exams, 1);
      expect(snapshot.homework, 1);
    },
  );

  test('empty fetched days are not invented as school-free days', () {
    final snapshot = buildWrappedSnapshot(
      year: year,
      today: DateTime(2025, 9, 5),
      weekDocuments: [
        {
          'monday': 20250901,
          'days': {'0': <Map<String, dynamic>>[]},
        },
      ],
      holidays: const [],
      absences: const [],
      exams: const [],
      homework: const [],
      grades: const [],
      hasAbsenceSource: false,
      hasHolidaySource: false,
    );
    expect(snapshot.freeWeekdays, 0);
    expect(snapshot.absentLessons, 0);
  });
}
