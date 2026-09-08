import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/changes/domain/timetable_change.dart';

TimetableLessonSnapshot lesson({
  String room = 'A101',
  String teacher = 'Miller',
  bool cancelled = false,
}) => TimetableLessonSnapshot(
  identity: 'id:42',
  date: 20260908,
  startTime: 800,
  endTime: 845,
  subject: 'MA',
  rooms: [room],
  teachers: [teacher],
  cancelled: cancelled,
);

void main() {
  const detector = TimetableChangeDetector();

  test('ignores identical snapshots', () {
    expect(detector.compare(before: [lesson()], after: [lesson()]), isEmpty);
  });

  test('detects room, teacher and cancellation changes', () {
    final changes = detector.compare(
      before: [lesson()],
      after: [lesson(room: 'B202', teacher: 'Schmidt', cancelled: true)],
    );
    expect(
      changes.map((change) => change.type),
      containsAll([
        TimetableChangeType.room,
        TimetableChangeType.teacher,
        TimetableChangeType.cancelled,
      ]),
    );
  });

  test('detects removed lessons', () {
    final changes = detector.compare(before: [lesson()], after: const []);
    expect(changes.single.type, TimetableChangeType.removed);
  });
}
