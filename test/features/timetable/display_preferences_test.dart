import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart' as app;

void main() {
  tearDown(() {
    app.showFullTeacherNamesNotifier.value = true;
    app.timetableDaySpanNotifier.value = 1;
  });

  group('displayTeacherForLesson', () {
    final lesson = <String, Object?>{
      '_teacher': 'Anna Müller',
      '_teacherShort': 'AM',
    };

    test('prefers the full name when the setting is on', () {
      app.showFullTeacherNamesNotifier.value = true;
      expect(app.displayTeacherForLesson(lesson), 'Anna Müller');
    });

    test('prefers the Kürzel when the setting is off', () {
      app.showFullTeacherNamesNotifier.value = false;
      expect(app.displayTeacherForLesson(lesson), 'AM');
    });

    test('falls back to the full name when no Kürzel is known', () {
      app.showFullTeacherNamesNotifier.value = false;
      expect(
        app.displayTeacherForLesson(<String, Object?>{'_teacher': 'Anna Müller'}),
        'Anna Müller',
      );
    });

    test('returns an empty string rather than a placeholder when unset', () {
      app.showFullTeacherNamesNotifier.value = false;
      expect(app.displayTeacherForLesson(<String, Object?>{}), '');
    });

    test('trims surrounding whitespace off both candidates', () {
      app.showFullTeacherNamesNotifier.value = false;
      expect(
        app.displayTeacherForLesson(<String, Object?>{
          '_teacher': '  Anna Müller ',
          '_teacherShort': '  ',
        }),
        'Anna Müller',
      );
    });
  });

  group('timetable day span', () {
    test('defaults to a single day', () {
      expect(app.timetableDaySpanNotifier.value, 1);
    });

    test('accepts a multi-day span', () {
      app.timetableDaySpanNotifier.value = 3;
      expect(app.timetableDaySpanNotifier.value.clamp(1, 3), 3);
    });

    test('clamps out-of-range spans to what the grid can render', () {
      expect(app.timetableDaySpanNotifier.value.clamp(1, 3), 1);
      app.timetableDaySpanNotifier.value = 5;
      expect(app.timetableDaySpanNotifier.value.clamp(1, 3), 3);
      app.timetableDaySpanNotifier.value = 0;
      expect(app.timetableDaySpanNotifier.value.clamp(1, 3), 1);
    });
  });
}
