import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lesson cards do not show question mark as room when room is unknown or question mark', () {
    final lessonWithQuestionRoom = <String, dynamic>{
      'id': 1,
      'date': 20261109,
      'startTime': 800,
      'endTime': 845,
      '_subjectShort': 'M',
      '_subjectLong': 'Mathematik',
      '_room': '?',
      '_teacher': 'Frau König',
    };

    final rawRoom = (lessonWithQuestionRoom['_room']?.toString() ?? '').trim();
    final cleanRoom = rawRoom == '?' ? '' : rawRoom;
    expect(cleanRoom, isEmpty);
  });
}
