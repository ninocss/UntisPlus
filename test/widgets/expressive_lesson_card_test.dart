import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';

void main() {
  testWidgets('ExpressiveLessonCard renders subject badge, teacher and room', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 250,
              height: 100,
              child: ExpressiveLessonCard(
                subject: 'MA',
                teacher: 'Olivia Carter',
                room: 'A101',
                isCancelled: false,
                shapeVariant: ExpressiveShapeVariant.shape0,
                tone: ExpressiveTone.mint,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('MA'), findsOneWidget);
    expect(find.text('Olivia Carter'), findsOneWidget);
    expect(find.text('A101'), findsOneWidget);
    expect(find.byKey(const ValueKey('expressive-lesson-room-icon')), findsOneWidget);
    expect(find.byKey(const ValueKey('expressive-lesson-cancelled-pill')), findsNothing);
  });

  testWidgets(
    'ExpressiveLessonCard shows Entfaellt badge, hatch pattern, and strikethrough when cancelled',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                height: 100,
                child: ExpressiveLessonCard(
                  subject: 'GE',
                  teacher: 'Marcus Hill',
                  room: 'History Hall',
                  isCancelled: true,
                  shapeVariant: ExpressiveShapeVariant.shape6,
                  tone: ExpressiveTone.rose,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('GE'), findsOneWidget);
      expect(find.text('Marcus Hill'), findsOneWidget);
      expect(find.text('History Hall'), findsOneWidget);
      expect(find.text('Entfällt'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('expressive-lesson-cancelled-pill')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('expressive-lesson-hatch-pattern')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ExpressiveLessonCard shows Cancelled badge when locale is English',
    (tester) async {
      final prevLocale = appLocaleNotifier.value;
      appLocaleNotifier.value = 'en';
      addTearDown(() => appLocaleNotifier.value = prevLocale);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                height: 100,
                child: ExpressiveLessonCard(
                  subject: 'GE',
                  teacher: 'Marcus Hill',
                  room: 'History Hall',
                  isCancelled: true,
                  shapeVariant: ExpressiveShapeVariant.shape6,
                  tone: ExpressiveTone.rose,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cancelled'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('expressive-lesson-cancelled-pill')),
        findsOneWidget,
      );
    },
  );

  testWidgets('ExpressiveLessonCard responds to press interaction with morph', (
    tester,
  ) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 250,
              height: 100,
              child: ExpressiveLessonCard(
                subject: 'DE',
                teacher: 'Daniel Reed',
                room: 'Language Room',
                isCancelled: false,
                shapeVariant: ExpressiveShapeVariant.shape1,
                tone: ExpressiveTone.blue,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      ),
    );

    // Initial state before tap
    expect(find.text('DE'), findsOneWidget);

    // Tap and release
    await tester.tap(find.byType(ExpressiveLessonCard));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('ExpressiveLessonCard forwards taps to parent GestureDetector when onTap is not provided', (
    tester,
  ) async {
    bool parentTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 250,
              height: 100,
              child: GestureDetector(
                onTap: () => parentTapped = true,
                child: const ExpressiveLessonCard(
                  subject: 'EN',
                  teacher: 'Emily Müller',
                  room: 'English Studio',
                  isCancelled: false,
                  shapeVariant: ExpressiveShapeVariant.shape2,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ExpressiveLessonCard));
    await tester.pumpAndSettle();
    expect(parentTapped, isTrue);
  });

  testWidgets('ExpressiveLessonCard adapts to compact and minimal slot heights', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: 200,
                height: 50,
                child: ExpressiveLessonCard(
                  subject: 'IF',
                  teacher: 'Noah Bennett',
                  room: 'Tech Lab 3',
                  isCancelled: false,
                  availableHeight: 50,
                  availableWidth: 200,
                ),
              ),
              SizedBox(
                width: 200,
                height: 35,
                child: ExpressiveLessonCard(
                  subject: 'SP',
                  teacher: 'Coach Jordan',
                  room: 'Hall 2',
                  isCancelled: false,
                  availableHeight: 35,
                  availableWidth: 200,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('IF'), findsOneWidget);
    expect(find.text('SP'), findsOneWidget);
  });
}
