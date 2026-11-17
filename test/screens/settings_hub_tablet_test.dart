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
    tempDir = await Directory.systemTemp.createTemp('untisplus_settings_hub_tablet_test_');
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
    aiEnabledNotifier.value = false;
    unreadTimetableChangesNotifier.value = 0;
    unreadInboxMessagesNotifier.value = 0;
    untisAccountsNotifier.value = [];
  });

  group('SettingsHubPage tablet layout', () {
    testWidgets(
      'On phone screen size (390x844), renders in single-pane list mode',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const UntisPlusApp(startScreen: SettingsHubPage()),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('settings-master-detail')), findsNothing);
        expect(find.byKey(const PageStorageKey<String>('settings-hub-compact')), findsOneWidget);
        expect(find.byKey(const PageStorageKey<String>('settings-hub-expanded')), findsNothing);
      },
    );

    testWidgets(
      'On tablet portrait screen size (768x1024), renders in master-detail split mode',
      (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const UntisPlusApp(startScreen: SettingsHubPage()),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('settings-master-detail')), findsOneWidget);
        expect(find.byKey(const PageStorageKey<String>('settings-hub-expanded')), findsOneWidget);

        // Verify master pane width clamped to 280.0 (768 * 0.32 = 245.76 clamped to 280.0)
        final row = tester.widget<Row>(find.byKey(const ValueKey('settings-master-detail')));
        final masterSizedBox = row.children.first as SizedBox;
        expect(masterSizedBox.width, 280.0);
      },
    );

    testWidgets(
      'On tablet landscape screen size (1024x768), renders in master-detail split mode with proportional width',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const UntisPlusApp(startScreen: SettingsHubPage()),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('settings-master-detail')), findsOneWidget);
        final row = tester.widget<Row>(find.byKey(const ValueKey('settings-master-detail')));
        final masterSizedBox = row.children.first as SizedBox;
        // 1024 * 0.32 = 327.68
        expect(masterSizedBox.width, closeTo(327.68, 0.01));
      },
    );
  });

  group('SchoolNotificationsPage tablet layout', () {
    testWidgets(
      'On phone screen size (390x844), renders in single-pane list mode',
      (tester) async {
        demoModeNotifier.value = true;
        addTearDown(() => demoModeNotifier.value = false);

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const UntisPlusApp(startScreen: SchoolNotificationsPage(isActive: true)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('notifications-master-detail')), findsNothing);
      },
    );

    testWidgets(
      'On tablet portrait screen size (768x1024), renders in master-detail split mode',
      (tester) async {
        demoModeNotifier.value = true;
        addTearDown(() => demoModeNotifier.value = false);

        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const UntisPlusApp(startScreen: SchoolNotificationsPage(isActive: true)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('notifications-master-detail')), findsOneWidget);

        // Verify master list width clamped to 280.0 (768 * 0.34 = 261.12 clamped to 280.0)
        final row = tester.widget<Row>(find.byKey(const ValueKey('notifications-master-detail')));
        final masterSizedBox = row.children.first as SizedBox;
        expect(masterSizedBox.width, 280.0);
      },
    );
  });
}
