import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';

void main() {
  setUp(() {
    lessonCleanDesignNotifier.value = false;
    lessonShowSubjectIconsNotifier.value = true;
    lessonShowTeacherNotifier.value = true;
    lessonShowRoomNotifier.value = true;
    lessonCompactModeNotifier.value = false;
  });

  testWidgets('renders classic layout when clean design is disabled', (
    tester,
  ) async {
    lessonCleanDesignNotifier.value = false;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 140,
              height: 90,
              child: TimetableLessonCard(
                isCancelled: false,
                isDark: false,
                fgColor: Colors.blue,
                bgColor: Colors.white,
                subject: 'Mathematik',
                teacher: 'Hr. Schmidt',
                room: 'R 102',
                isNow: false,
                subjectIcon: Icons.calculate_rounded,
              ),
            ),
          ),
        ),
      ),
    );

    // Subject text
    expect(find.text('Mathematik'), findsOneWidget);
    // Teacher & room text
    expect(find.text('Hr. Schmidt'), findsOneWidget);
    expect(find.text('R 102'), findsOneWidget);
    // In classic layout, watermark Key('lesson-watermark-icon') does not exist
    expect(find.byKey(const ValueKey('lesson-watermark-icon')), findsNothing);
    // Inline subject icon exists
    expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);
  });

  testWidgets(
    'renders watermark icon and streamlined meta line when clean design is enabled',
    (tester) async {
      lessonCleanDesignNotifier.value = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 140,
                height: 90,
                child: TimetableLessonCard(
                  isCancelled: false,
                  isDark: false,
                  fgColor: Colors.blue,
                  bgColor: Colors.white,
                  subject: 'Mathematik',
                  teacher: 'Hr. Schmidt',
                  room: 'R 102',
                  isNow: false,
                  subjectIcon: Icons.calculate_rounded,
                ),
              ),
            ),
          ),
        ),
      );

      // Subject text
      expect(find.text('Mathematik'), findsOneWidget);
      // Clean meta-line: displays room and teacher
      expect(find.byKey(const ValueKey('lesson-clean-meta-row')), findsOneWidget);
      expect(find.textContaining('R 102'), findsOneWidget);
      expect(find.textContaining('Hr. Schmidt'), findsOneWidget);
      // Watermark icon exists and uses ShaderMask
      expect(
        find.byKey(const ValueKey('lesson-watermark-icon')),
        findsOneWidget,
      );
      // Duplicate small inline icon is omitted in clean design
      expect(find.byKey(const ValueKey('lesson-inline-subject-icon')), findsNothing);
    },
  );
}
