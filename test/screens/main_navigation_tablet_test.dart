import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('untisplus_main_nav_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
  });

  tearDownAll(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
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
    aiEnabledNotifier.value = true;
    unreadTimetableChangesNotifier.value = 0;
    unreadInboxMessagesNotifier.value = 0;
    untisAccountsNotifier.value = [];
  });

  tearDown(() {
    demoModeNotifier.value = false;
    untisAccountsNotifier.value = [];
  });

  testWidgets(
    'MainNavigationScreen shows TabletGlassSidebar and hides NavigationRail and floating nav on tablet widths',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(TabletGlassSidebar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byKey(const ValueKey('main-floating-nav-bar')), findsNothing);
    },
  );

  testWidgets(
    'Tapping an item in TabletGlassSidebar updates selected tab',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationScreen(),
        ),
      );
      await tester.pump();

      // Initially timetable tab is selected (watch_later_rounded is active icon)
      expect(
        find.descendant(
          of: find.byType(TabletGlassSidebar),
          matching: find.byIcon(Icons.watch_later_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TabletGlassSidebar),
          matching: find.byIcon(Icons.assignment_outlined),
        ),
        findsOneWidget,
      );

      // Tap Exams icon in sidebar
      await tester.tap(
        find.descendant(
          of: find.byType(TabletGlassSidebar),
          matching: find.byIcon(Icons.assignment_outlined),
        ),
      );
      await tester.pump();

      // Now Exams tab is selected (assignment_rounded is active in sidebar and ExamsPage is mounted)
      expect(
        find.descendant(
          of: find.byType(TabletGlassSidebar),
          matching: find.byIcon(Icons.assignment_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TabletGlassSidebar),
          matching: find.byIcon(Icons.watch_later_outlined),
        ),
        findsOneWidget,
      );
      expect(find.byType(ExamsPage), findsOneWidget);
    },
  );

  testWidgets(
    'MainNavigationScreen hides TabletGlassSidebar and shows floating nav bar on phone widths',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(TabletGlassSidebar), findsNothing);
      expect(find.byKey(const ValueKey('main-floating-nav-bar')), findsOneWidget);
    },
  );
}
