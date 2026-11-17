import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';

void main() {
  setUp(() {
    lessonExpressiveDesignNotifier.value = false;
    lessonCleanDesignNotifier.value = false;
    lessonShowTeacherNotifier.value = true;
    lessonShowRoomNotifier.value = true;
  });

  testWidgets(
    'TimetableLessonCard renders ExpressiveLessonCard when expressive design is enabled',
    (tester) async {
      lessonExpressiveDesignNotifier.value = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                height: 100,
                child: TimetableLessonCard(
                  isCancelled: false,
                  isDark: false,
                  fgColor: Colors.blue,
                  bgColor: Colors.white,
                  subject: 'Mathematik',
                  teacher: 'Hr. Schmidt',
                  room: 'R 102',
                  isNow: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ExpressiveLessonCard), findsOneWidget);
      expect(find.text('Mathematik'), findsOneWidget);
      expect(find.text('Hr. Schmidt'), findsOneWidget);
      expect(find.text('R 102'), findsOneWidget);
    },
  );

  testWidgets(
    'TimetableLessonCard does not render ExpressiveLessonCard when expressive design is disabled',
    (tester) async {
      lessonExpressiveDesignNotifier.value = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                height: 100,
                child: TimetableLessonCard(
                  isCancelled: false,
                  isDark: false,
                  fgColor: Colors.blue,
                  bgColor: Colors.white,
                  subject: 'Mathematik',
                  teacher: 'Hr. Schmidt',
                  room: 'R 102',
                  isNow: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ExpressiveLessonCard), findsNothing);
      expect(find.text('Mathematik'), findsOneWidget);
    },
  );
}
