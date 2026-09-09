import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/homework/domain/homework.dart';

void main() {
  test('normalizes homework, lesson links, notes, and local done state', () {
    final bundle = HomeworkBundle.fromWebUntis(
      {
        'homeworks': [
          {
            'id': 7,
            'lessonId': 12,
            'text': 'Read chapter 4',
            'dueDate': 20260910,
          },
        ],
        'lessonNotes': [
          {'id': 9, 'lessonId': 12, 'text': 'Bring the workbook'},
        ],
        'lessons': [
          {
            'id': 12,
            'su': [
              {'name': 'ENG'},
            ],
          },
        ],
      },
      doneIds: const {'7'},
    );

    expect(bundle.homeworks.single.id, '7');
    expect(bundle.homeworks.single.isDone, isTrue);
    expect(bundle.homeworks.single.lesson?['id'], 12);
    expect(bundle.lessonNotes.single.text, 'Bring the workbook');
    expect(bundle.toLegacyJson()['homeworks']!.single['_done'], isTrue);
  });

  test('accepts lessonInfos fallback and survives malformed lists', () {
    final bundle = HomeworkBundle.fromWebUntis({
      'homeworks': [null, 'invalid'],
      'lessonInfos': [
        {'id': 'note', 'note': 'Fallback note'},
      ],
      'lessons': 'invalid',
    });

    expect(bundle.homeworks, isEmpty);
    expect(bundle.lessonNotes.single.text, 'Fallback note');
  });

  test('cache JSON round-trip preserves typed data', () {
    final original = HomeworkBundle.fromWebUntis({
      'homeworks': [
        {'id': 1, 'text': 'Task', 'date': 20260911},
      ],
    });

    final restored = HomeworkBundle.fromJson(original.toJson());

    expect(restored.homeworks.single.text, 'Task');
    expect(restored.homeworks.single.dueDate, 20260911);
  });

  test('current local completion state overrides stale cache state', () {
    final original = HomeworkBundle.fromWebUntis({
      'homeworks': [
        {'id': 1, 'text': 'Task', 'isDone': false},
      ],
    });

    final done = HomeworkBundle.fromJson(original.toJson(), doneIds: {'1'});
    final reopened = HomeworkBundle.fromJson(done.toJson(), doneIds: const {});

    expect(done.homeworks.single.isDone, isTrue);
    expect(reopened.homeworks.single.isDone, isFalse);
  });

  test('due-soon filter includes today and the next seven days only', () {
    final now = DateTime(2026, 9, 9, 22, 30);

    expect(isHomeworkDueSoon(20260909, now: now), isTrue);
    expect(isHomeworkDueSoon(20260916, now: now), isTrue);
    expect(isHomeworkDueSoon(20260917, now: now), isFalse);
    expect(isHomeworkDueSoon(20260908, now: now), isFalse);
    expect(isHomeworkDueSoon(20260230, now: now), isFalse);
    expect(isHomeworkDueSoon(0, now: now), isFalse);
  });
}
