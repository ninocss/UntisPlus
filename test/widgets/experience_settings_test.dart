import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'blurStrength': 1.7,
      'lessonBlurEnabled': true,
    });
    await SettingsStore.initialize(
      preferences: await SharedPreferences.getInstance(),
    );
    backgroundAnimationsNotifier.value = false;
    effectQualityNotifier.value = AppEffectQuality.full;
    interactionAnimationsEnabledNotifier.value = true;
    appLocaleNotifier.value = 'de';
    themeModeNotifier.value = ThemeMode.light;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
  });
  tearDown(() {
    SettingsStore.debugReset();
    effectQualityNotifier.value = AppEffectQuality.full;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
  });

  testWidgets(
    'profile picker applies immediately and preserves personal effect values',
    (tester) async {
      await tester.pumpWidget(
        const UntisPlusApp(startScreen: SettingsAppearancePage()),
      );
      final reduced = find.byKey(const ValueKey('effect-quality-reduced'));
      await tester.scrollUntilVisible(
        reduced,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(reduced);
      await tester.pumpAndSettle();
      expect(effectQualityNotifier.value, AppEffectQuality.reduced);
      expect(
        SettingsStore.instance.preferences.getString('effectQualityV1'),
        'reduced',
      );
      expect(SettingsStore.instance.preferences.getDouble('blurStrength'), 1.7);
      expect(
        SettingsStore.instance.preferences.getBool('lessonBlurEnabled'),
        isTrue,
      );
      expect(tester.widget<ChoiceChip>(reduced).selected, isTrue);
      final material = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(material.theme!.cardTheme.color!.a, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('profiles and all themes fit narrow screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final theme in AppThemeId.values) {
      for (final quality in AppEffectQuality.values) {
        visualThemeNotifier.value = theme;
        effectQualityNotifier.value = quality;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: const UntisPlusApp(startScreen: SettingsAppearancePage()),
          ),
        );
        await tester.pump();
        final picker = find.byKey(const ValueKey('effect-quality-balanced'));
        await tester.scrollUntilVisible(
          picker,
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${theme.name}/${quality.name}',
        );
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('manual animations switch controls button motion', (
    tester,
  ) async {
    interactionAnimationsEnabledNotifier.value = false;
    await tester.pumpWidget(const UntisPlusApp(startScreen: SizedBox()));
    final material = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      material.theme!.filledButtonTheme.style!.animationDuration,
      Duration.zero,
    );
    expect(
      material.theme!.iconButtonTheme.style!.animationDuration,
      Duration.zero,
    );
    interactionAnimationsEnabledNotifier.value = true;
    await tester.pump();
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme!
          .filledButtonTheme
          .style!
          .animationDuration,
      AppMotionTokens.standardEffects,
    );
  });
  testWidgets(
    'motion preference changes preserve the mounted timetable state',
    (tester) async {
      demoModeNotifier.value = true;
      addTearDown(() => demoModeNotifier.value = false);
      addTearDown(() => mainTabFadeUpEnabledNotifier.value = false);
      await tester.pumpWidget(
        const UntisPlusApp(startScreen: MainNavigationScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final timetable = tester.state(find.byType(WeeklyTimetablePage));
      mainTabFadeUpEnabledNotifier.value = true;
      await tester.pump();
      expect(tester.state(find.byType(WeeklyTimetablePage)), same(timetable));
      interactionAnimationsEnabledNotifier.value = false;
      await tester.pump();
      expect(tester.state(find.byType(WeeklyTimetablePage)), same(timetable));
      interactionAnimationsEnabledNotifier.value = true;
      await tester.pump();
      expect(tester.state(find.byType(WeeklyTimetablePage)), same(timetable));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
