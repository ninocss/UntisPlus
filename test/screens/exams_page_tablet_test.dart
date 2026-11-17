import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SettingsStore.initialize(preferences: prefs);
    activeUntisAccountId = null;
    sessionID = '';
    demoModeNotifier.value = false;
    appLocaleNotifier.value = 'de';
    themeModeNotifier.value = ThemeMode.light;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    backgroundAnimationsNotifier.value = false;
    hiddenSubjectsNotifier.value = {};
    customExamsNotifier.value = [];
    customHomeworkNotifier.value = [];
    customGradesNotifier.value = [];
    homeworksNotifier.value = [];
    apiExamsNotifier.value = [];
    aiEnabledNotifier.value = false;
  });

  testWidgets(
    'On phone width (390x844), exam cards render full width in a vertical column',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final today = DateTime.now();
      final futureDate = today.add(const Duration(days: 3));
      final futureStr =
          '${futureDate.year}${futureDate.month.toString().padLeft(2, '0')}${futureDate.day.toString().padLeft(2, '0')}';

      await saveCustomExams([
        {
          'subject': 'Mathematik',
          'examType': 'Klausur',
          'date': futureStr,
          'description': 'Mathe Klausur',
        },
        {
          'subject': 'Deutsch',
          'examType': 'Schulaufgabe',
          'date': futureStr,
          'description': 'Deutsch Aufsatz',
        },
      ]);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExamsPage()),
        ),
      );
      await tester.pumpAndSettle();

      final card0Finder = find.byKey(ValueKey('exam_${futureStr}_Mathematik_0'));
      final card1Finder = find.byKey(ValueKey('exam_${futureStr}_Deutsch_1'));

      expect(card0Finder, findsOneWidget);
      expect(card1Finder, findsOneWidget);

      final card0Size = tester.getSize(card0Finder);
      final card1Size = tester.getSize(card1Finder);
      final card0TopLeft = tester.getTopLeft(card0Finder);
      final card1TopLeft = tester.getTopLeft(card1Finder);

      // On phone (390 width, 16px horizontal padding each side -> 358px available width)
      expect(card0Size.width, 358.0);
      expect(card1Size.width, 358.0);

      // Cards stacked vertically (card 0 above card 1, aligned to left padding of 16)
      expect(card0TopLeft.dx, 16.0);
      expect(card1TopLeft.dx, 16.0);
      expect(card1TopLeft.dy, greaterThan(card0TopLeft.dy));
    },
  );

  testWidgets(
    'On tablet width (1024x768), exam cards render in a 2-column layout',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final today = DateTime.now();
      final futureDate = today.add(const Duration(days: 3));
      final futureStr =
          '${futureDate.year}${futureDate.month.toString().padLeft(2, '0')}${futureDate.day.toString().padLeft(2, '0')}';

      await saveCustomExams([
        {
          'subject': 'Mathematik',
          'examType': 'Klausur',
          'date': futureStr,
          'description': 'Mathe Klausur',
        },
        {
          'subject': 'Deutsch',
          'examType': 'Schulaufgabe',
          'date': futureStr,
          'description': 'Deutsch Aufsatz',
        },
      ]);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExamsPage()),
        ),
      );
      await tester.pumpAndSettle();

      final card0Finder = find.byKey(ValueKey('exam_${futureStr}_Mathematik_0'));
      final card1Finder = find.byKey(ValueKey('exam_${futureStr}_Deutsch_1'));

      expect(card0Finder, findsOneWidget);
      expect(card1Finder, findsOneWidget);

      final card0Size = tester.getSize(card0Finder);
      final card1Size = tester.getSize(card1Finder);
      final card0TopLeft = tester.getTopLeft(card0Finder);
      final card1TopLeft = tester.getTopLeft(card1Finder);

      // On tablet expanded (1024 width, 28px padding each side -> 968px content width)
      // 2-column item width: (968 - 12) / 2 = 478px
      expect(card0Size.width, 478.0);
      expect(card1Size.width, 478.0);

      // Side by side in 2 columns at the same vertical offset:
      // Column 1 starts at 28.0, Column 2 starts at 28.0 + 478.0 + 12.0 = 518.0
      expect(card0TopLeft.dx, 28.0);
      expect(card1TopLeft.dx, 518.0);
      expect(card0TopLeft.dy, equals(card1TopLeft.dy));
    },
  );

  testWidgets(
    'Empty states render centered across full width on both phone and tablet',
    (tester) async {
      // 1. Phone width
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExamsPage()),
        ),
      );
      await tester.pumpAndSettle();

      final emptyIconPhone = find.byIcon(Icons.assignment_outlined);
      expect(emptyIconPhone, findsOneWidget);
      final phoneCenter = tester.getCenter(emptyIconPhone);
      expect(phoneCenter.dx, closeTo(195.0, 1.0));

      // 2. Tablet width
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExamsPage()),
        ),
      );
      await tester.pumpAndSettle();

      final emptyIconTablet = find.byIcon(Icons.assignment_outlined);
      expect(emptyIconTablet, findsOneWidget);
      final tabletCenter = tester.getCenter(emptyIconTablet);
      expect(tabletCenter.dx, closeTo(512.0, 1.0));
    },
  );

  testWidgets(
    'On tablet width (1024x768), homework cards render in a 2-column layout',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final today = DateTime.now();
      final futureDate = today.add(const Duration(days: 2));
      final futureStr =
          '${futureDate.year}${futureDate.month.toString().padLeft(2, '0')}${futureDate.day.toString().padLeft(2, '0')}';

      await saveCustomHomework([
        {
          'id': 'hw1',
          'subject': 'Mathematik',
          'text': 'Buch S. 42 Nr. 1-3',
          'dueDate': futureStr,
          'isDone': false,
        },
        {
          'id': 'hw2',
          'subject': 'Deutsch',
          'text': 'Aufsatz schreiben',
          'dueDate': futureStr,
          'isDone': false,
        },
      ]);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExamsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Homework tab (index 1)
      await tester.tap(find.text('Hausaufgaben'));
      await tester.pumpAndSettle();

      final hw0Finder = find.byKey(const ValueKey('hw_open_hw1_0'));
      final hw1Finder = find.byKey(const ValueKey('hw_open_hw2_1'));

      expect(hw0Finder, findsOneWidget);
      expect(hw1Finder, findsOneWidget);

      final hw0Size = tester.getSize(hw0Finder);
      final hw1Size = tester.getSize(hw1Finder);
      final hw0TopLeft = tester.getTopLeft(hw0Finder);
      final hw1TopLeft = tester.getTopLeft(hw1Finder);

      // On tablet expanded (1024 width, 28px padding -> 968px content width)
      // 2-column item width: (968 - 12) / 2 = 478px
      expect(hw0Size.width, 478.0);
      expect(hw1Size.width, 478.0);

      // Side by side in 2 columns: left column at 28.0, right column at 518.0
      expect(hw0TopLeft.dx, 28.0);
      expect(hw1TopLeft.dx, 518.0);
      expect(hw0TopLeft.dy, equals(hw1TopLeft.dy));
    },
  );

  testWidgets(
    'On tablet width (1024x768), grades subject cards render in a 2-column layout',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await saveCustomGrades([
        {
          'id': 'g1',
          'subject': 'Mathematik',
          'value': 2.0,
          'weight': 1.0,
          'type': 'Klausur',
          'date': DateTime.now().toIso8601String(),
        },
        {
          'id': 'g2',
          'subject': 'Deutsch',
          'value': 1.5,
          'weight': 1.0,
          'type': 'Klausur',
          'date': DateTime.now().toIso8601String(),
        },
      ]);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExamsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Grades tab (index 2)
      await tester.tap(find.text('Noten'));
      await tester.pumpAndSettle();

      final gradeSubj0Finder = find.byKey(const ValueKey('grade_subject_Deutsch'));
      final gradeSubj1Finder = find.byKey(const ValueKey('grade_subject_Mathematik'));

      expect(gradeSubj0Finder, findsOneWidget);
      expect(gradeSubj1Finder, findsOneWidget);

      final grade0Size = tester.getSize(gradeSubj0Finder);
      final grade1Size = tester.getSize(gradeSubj1Finder);
      final grade0TopLeft = tester.getTopLeft(gradeSubj0Finder);
      final grade1TopLeft = tester.getTopLeft(gradeSubj1Finder);

      expect(grade0Size.width, 478.0);
      expect(grade1Size.width, 478.0);

      expect(grade0TopLeft.dx, 28.0);
      expect(grade1TopLeft.dx, 518.0);
      expect(grade0TopLeft.dy, equals(grade1TopLeft.dy));
    },
  );
}
