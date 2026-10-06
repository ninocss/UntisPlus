import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/changes/domain/timetable_change.dart';
import 'package:untisplus/features/day_context/day_context.dart';

void main() {
  final monday = DateTime(2026, 9, 28);

  test('uses only active lessons and visible, open upcoming homework', () {
    final result = DayContextSnapshot.build(
      accountId: 'student-a',
      date: monday,
      now: DateTime(2026, 9, 28, 9),
      dataState: DayDataState.current,
      hiddenSubjects: const {'HIDDEN'},
      lessons: [
        {'startTime': 800, 'endTime': 845, '_subjectShort': 'PAST'},
        {'startTime': 900, 'endTime': 945, '_subjectShort': 'HIDDEN'},
        {'startTime': 1000, 'endTime': 1045, '_subjectShort': 'MATH'},
        {
          'startTime': 1100,
          'endTime': 1145,
          '_subjectShort': 'CANCEL',
          'code': 'cancelled',
        },
      ],
      homework: [
        {'subject': 'MATH', 'dueDate': 20260929, 'text': 'Page 2'},
        {'subject': 'HIDDEN', 'dueDate': 20260929},
        {
          '_lesson': {
            'su': [
              {'name': 'HIDDEN'},
            ],
          },
          'dueDate': 20260929,
        },
        {'subject': 'MATH', 'dueDate': 20260928, 'isDone': true},
        {'subject': 'MATH', 'dueDate': 20261002},
      ],
      changes: [
        TimetableChange(
          id: 'room',
          type: TimetableChangeType.room,
          detectedAt: monday,
          lessonIdentity: 'id:1',
          date: 20260928,
          subject: 'MATH',
        ),
        TimetableChange(
          id: 'other-day',
          type: TimetableChangeType.room,
          detectedAt: monday,
          lessonIdentity: 'id:2',
          date: 20260929,
          subject: 'MATH',
        ),
      ],
    );

    expect(result.accountId, 'student-a');
    expect(result.nextLesson?['_subjectShort'], 'MATH');
    expect(result.dueHomework.single['text'], 'Page 2');
    expect(result.changes.single.id, 'room');
  });

  test(
    'past days have no next lesson and unavailable state stays explicit',
    () {
      final result = DayContextSnapshot.build(
        accountId: 'student-a',
        date: monday,
        now: DateTime(2026, 9, 29, 9),
        dataState: DayDataState.unavailable,
        hiddenSubjects: const {},
        lessons: [
          {'startTime': 1000, 'endTime': 1045, '_subjectShort': 'MATH'},
        ],
        homework: const [],
        changes: const [],
      );
      expect(result.nextLesson, isNull);
      expect(result.dataState, DayDataState.unavailable);
    },
  );
}
