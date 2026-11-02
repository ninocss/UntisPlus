import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SettingsStore.initialize(preferences: prefs);
    lessonCleanDesignNotifier.value = false;
    appLocaleNotifier.value = 'de';
  });

  testWidgets(
    'SettingsLessonDesignPage renders Modernes Clean-Design switch and toggles it',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsLessonDesignPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final l = appL10nFor('de');
      // Find the clean design switch tile
      final tileFinder = find.widgetWithText(
        SettingsSwitchTile,
        l.settingsLessonCleanDesign,
      );
      expect(tileFinder, findsOneWidget);

      // Verify initial state is false
      expect(lessonCleanDesignNotifier.value, isFalse);

      // Tap the tile to toggle
      await tester.tap(tileFinder);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify notifier changed to true
      expect(lessonCleanDesignNotifier.value, isTrue);
    },
  );
}
