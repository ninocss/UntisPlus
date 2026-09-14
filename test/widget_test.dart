import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:untisplus/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appLocaleNotifier.value = 'de';
    activeUntisAccountId = null;
    untisAccountsNotifier.value = const [];
    themeModeNotifier.value = ThemeMode.light;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    blurEnabledNotifier.value = true;
    // An endless decorative animation is not relevant to theme selection and
    // would keep pumpAndSettle from completing in this widget test.
    backgroundAnimationsNotifier.value = false;
    tutorialReplayRequestNotifier.value = 0;
    themeBlurPreferencesNotifier.value = {
      'default': true,
      'vivid': true,
      'glass': true,
      'cyber': true,
    };
  });

  testWidgets('theme picker applies Manga immediately and disables blur', (
    tester,
  ) async {
    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SettingsAppearancePage()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('theme-manga')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('theme-manga')));
    await tester.pumpAndSettle();

    expect(visualThemeNotifier.value, AppThemeId.manga);
    expect(blurEnabledNotifier.value, isFalse);

    final context = tester.element(find.byType(SettingsAppearancePage));
    expect(
      Theme.of(context).extension<UntisThemeTokens>()?.id,
      AppThemeId.manga,
    );
  });

  testWidgets('all themes provide light and dark ThemeData', (tester) async {
    for (final theme in AppThemeId.values) {
      visualThemeNotifier.value = theme;
      themeModeNotifier.value = ThemeMode.light;
      await tester.pumpWidget(
        const UntisPlusApp(startScreen: Scaffold(body: SizedBox())),
      );
      await tester.pump();
      var context = tester.element(find.byType(Scaffold));
      expect(Theme.of(context).brightness, Brightness.light);
      expect(Theme.of(context).extension<UntisThemeTokens>()?.id, theme);

      themeModeNotifier.value = ThemeMode.dark;
      await tester.pump();
      context = tester.element(find.byType(Scaffold));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(Theme.of(context).extension<UntisThemeTokens>()?.id, theme);
    }
  });

  testWidgets('widget settings switches complete previews', (tester) async {
    final account = UntisAccount(
      id: 'account-test',
      username: 'Testkonto',
      schoolUrl: 'example.webuntis.com',
      schoolName: 'Testschule',
      password: '',
      credentialMode: 'password',
      sessionId: '',
      personId: 1,
      personType: 5,
      lastUsedAt: DateTime(2026),
    );
    activeUntisAccountId = account.id;
    untisAccountsNotifier.value = [account];

    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SettingsWidgetsPage()),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('widget-preview-current')),
      findsOneWidget,
    );
    expect(find.text('Testkonto'), findsWidgets);
    expect(find.text('Keine aktuelle Stunde'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tagesplan'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('widget-preview-schedule')),
      findsOneWidget,
    );
    expect(find.text('Noch keine Tagesdaten'), findsOneWidget);
    expect(find.text('Mittel oder groß'), findsOneWidget);
  });

  testWidgets('Paper onboarding hides unsupported visual controls', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const UntisPlusApp(startScreen: OnboardingFlow()));
    await tester.pump();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('onboarding-theme-paper')));
    await tester.pumpAndSettle();

    expect(visualThemeNotifier.value, AppThemeId.paper);
    expect(find.text('Hintergrundanimationen'), findsNothing);
    expect(find.text('Blur-Effekt'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme choices keep fixed heights and gain tablet columns', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 768);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SettingsAppearancePage()),
    );
    await tester.pump();

    final defaultCard = find.byKey(const ValueKey('theme-default'));
    final mangaCard = find.byKey(const ValueKey('theme-manga'));
    final vividCard = find.byKey(const ValueKey('theme-vivid'));
    final glassCard = find.byKey(const ValueKey('theme-glass'));
    expect(defaultCard, findsOneWidget);
    expect(tester.getSize(defaultCard).height, 148);
    expect(tester.getTopLeft(defaultCard).dy, tester.getTopLeft(mangaCard).dy);
    expect(tester.getTopLeft(defaultCard).dy, tester.getTopLeft(vividCard).dy);
    expect(tester.getTopLeft(defaultCard).dy, tester.getTopLeft(glassCard).dy);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const UntisPlusApp(startScreen: OnboardingFlow()));
    await tester.pump();
    await tester.tap(find.text('Weiter'));
    await tester.pump(const Duration(milliseconds: 650));

    final onboardingCard = find.byKey(
      const ValueKey('onboarding-theme-default'),
    );
    expect(onboardingCard, findsOneWidget);
    expect(tester.getSize(onboardingCard).height, 64);
    expect(
      find.byKey(const ValueKey('onboarding-theme-preview')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('new onboarding shell fits phone and tablet viewports', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final size in [
      const Size(375, 812),
      const Size(430, 932),
      const Size(768, 1024),
      const Size(1024, 768),
    ]) {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        UntisPlusApp(startScreen: OnboardingFlow(key: ValueKey(size))),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: 'welcome viewport: $size');

      await tester.tap(find.text('Weiter'));
      await tester.pump(const Duration(milliseconds: 650));
      expect(
        find.byKey(const ValueKey('onboarding-theme-preview')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: 'theme viewport: $size');
    }
  });

  testWidgets('interactive tutorial supports next back skip and replay', (
    tester,
  ) async {
    demoModeNotifier.value = true;
    addTearDown(() => demoModeNotifier.value = false);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const UntisPlusApp(
        startScreen: MainNavigationScreen(showTutorialOnStart: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('tutorial-callout')), findsOneWidget);
    expect(find.text('Stundenplan'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('tutorial-next')));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Prüfungen & Aufgaben'), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorial-back')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorial-back')));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Stundenplan'), findsWidgets);

    await tester.tap(find.text('Tour überspringen'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('tutorial-callout')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('tutorialVersionCompleted'), kCurrentTutorialVersion);

    tutorialReplayRequestNotifier.value++;
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byKey(const ValueKey('tutorial-callout')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local AI onboarding uses a model download instead of API key', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(768, 1024);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => demoModeNotifier.value = false);

    await tester.pumpWidget(const UntisPlusApp(startScreen: OnboardingFlow()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Weiter'));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.tap(find.text('Weiter'));
    await tester.pump(const Duration(milliseconds: 650));

    final demoButton = find.text('Demo-Modus starten');
    await tester.ensureVisible(demoButton);
    await tester.tap(demoButton);
    await tester.pump(const Duration(milliseconds: 650));

    await tester.tap(find.text('Google Gemini'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Lokal (On-Device)'));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Lokales Modell'), findsWidgets);
    expect(find.text('Herunterladen'), findsOneWidget);
    expect(find.textContaining('API-Schlüssel ·'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly timetable fits phone and tablet viewports', (
    tester,
  ) async {
    demoModeNotifier.value = true;
    addTearDown(() => demoModeNotifier.value = false);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final size in [
      const Size(375, 812),
      const Size(430, 932),
      const Size(768, 1024),
      const Size(1024, 768),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        UntisPlusApp(startScreen: WeeklyTimetablePage(key: ValueKey(size))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.calendar_view_week_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'viewport: $size');
    }
  });
}
