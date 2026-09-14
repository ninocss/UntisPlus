import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';

void main() {
  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 80,
    Duration step = const Duration(milliseconds: 50),
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(step);
    }
    expect(finder, findsWidgets);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    final visible = finder.hitTestable();
    if (visible.evaluate().isNotEmpty) {
      await tester.tap(visible.first);
      return;
    }
    await tester.ensureVisible(finder.first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(finder.hitTestable().first);
  }

  Future<Finder> ensureDayTimetableView(WidgetTester tester) async {
    final dayCarousel = find.byKey(const ValueKey('day-timetable-carousel'));
    for (var i = 0; i < 80; i++) {
      if (dayCarousel.evaluate().isNotEmpty) return dayCarousel;
      final switchToDay = find
          .byIcon(Icons.calendar_view_day_rounded)
          .hitTestable();
      if (switchToDay.evaluate().isNotEmpty) {
        await tester.tap(switchToDay.first);
        await tester.pump(const Duration(milliseconds: 100));
        continue;
      }
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(dayCarousel, findsOneWidget);
    return dayCarousel;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'viewMode': 0,
      'onboardingCheckpoint': 0,
    });
    demoModeNotifier.value = false;
    appLocaleNotifier.value = 'de';
    activeUntisAccountId = null;
    untisAccountsNotifier.value = const [];
    themeModeNotifier.value = ThemeMode.light;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    blurEnabledNotifier.value = true;
    // An endless decorative animation is not relevant to theme selection and
    // would keep pumpAndSettle from completing in this widget test.
    backgroundAnimationsNotifier.value = false;
    themeBlurPreferencesNotifier.value = {
      'default': true,
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

  testWidgets('onboarding only offers the four supported visual themes', (
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

    expect(find.byKey(const ValueKey('onboarding-theme-vivid')), findsNothing);
    expect(find.byKey(const ValueKey('onboarding-theme-paper')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('onboarding-theme-cyber')));
    await tester.pumpAndSettle();

    expect(visualThemeNotifier.value, AppThemeId.cyber);
    expect(find.text('Hintergrundanimationen'), findsOneWidget);
    expect(find.text('Blur-Effekt'), findsOneWidget);
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
    final glassCard = find.byKey(const ValueKey('theme-glass'));
    final cyberCard = find.byKey(const ValueKey('theme-cyber'));
    expect(defaultCard, findsOneWidget);
    expect(tester.getSize(defaultCard).height, 148);
    expect(tester.getTopLeft(defaultCard).dy, tester.getTopLeft(mangaCard).dy);
    expect(tester.getTopLeft(defaultCard).dy, tester.getTopLeft(glassCard).dy);
    expect(tester.getTopLeft(defaultCard).dy, tester.getTopLeft(cyberCard).dy);
    expect(find.byKey(const ValueKey('theme-vivid')), findsNothing);
    expect(find.byKey(const ValueKey('theme-paper')), findsNothing);
    expect(tester.takeException(), isNull);

    final onboardingPrefs = await SharedPreferences.getInstance();
    await onboardingPrefs.setInt('onboardingCheckpoint', 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const UntisPlusApp(startScreen: OnboardingFlow()));
    await tester.pump(const Duration(milliseconds: 100));
    await tapVisible(tester, find.text('Weiter'));

    final onboardingCard = find.byKey(
      const ValueKey('onboarding-theme-default'),
    );
    await pumpUntilFound(tester, onboardingCard);
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
      SharedPreferences.setMockInitialValues({
        'viewMode': 0,
        'onboardingCheckpoint': 0,
      });
      tester.view.physicalSize = size;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        UntisPlusApp(startScreen: OnboardingFlow(key: ValueKey(size))),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: 'welcome viewport: $size');

      await tapVisible(tester, find.text('Weiter'));
      final preview = find.byKey(const ValueKey('onboarding-theme-preview'));
      await pumpUntilFound(tester, preview);
      expect(preview, findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'theme viewport: $size');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('onboardingCheckpoint', 0);
    }
  });

  testWidgets('interactive tutorial supports next, back, and skip', (
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('onboardingCheckpoint', 0);
    await tester.pumpWidget(const UntisPlusApp(startScreen: OnboardingFlow()));
    await tester.pump(const Duration(milliseconds: 100));

    await tapVisible(tester, find.text('Weiter'));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('onboarding-theme-default')),
    );
    await tapVisible(tester, find.text('Weiter'));

    final demoButton = find.text('Demo-Modus starten');
    await pumpUntilFound(tester, demoButton);
    await tapVisible(tester, demoButton);
    await pumpUntilFound(tester, find.text('Google Gemini'));

    await tester.tap(find.text('Google Gemini'));
    await pumpUntilFound(tester, find.text('Lokal (On-Device)'));
    await tester.tap(find.text('Lokal (On-Device)'));
    await pumpUntilFound(tester, find.text('Lokales Modell'));

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('viewMode', 0);
      await tester.pumpWidget(
        UntisPlusApp(startScreen: WeeklyTimetablePage(key: ValueKey(size))),
      );
      final dayCarousel = await ensureDayTimetableView(tester);
      expect(dayCarousel, findsOneWidget, reason: 'day viewport: $size');
      await tester.tap(find.byIcon(Icons.calendar_view_week_rounded));
      final weekGrid = find.byKey(const ValueKey('week-grid-horizontal-scroll'));
      await pumpUntilFound(tester, weekGrid);
      expect(weekGrid, findsOneWidget, reason: 'week viewport: $size');
      expect(tester.takeException(), isNull, reason: 'viewport: $size');
      await prefs.setInt('viewMode', 0);
    }
  });

  testWidgets('timetable more menu uses the expressive menu actions', (
    tester,
  ) async {
    demoModeNotifier.value = true;
    addTearDown(() => demoModeNotifier.value = false);

    await tester.pumpWidget(
      const UntisPlusApp(startScreen: WeeklyTimetablePage()),
    );
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.byType(MenuAnchor), findsOneWidget);
    expect(find.text('Andere Klasse'), findsOneWidget);
    expect(find.text('Freie Räume'), findsOneWidget);
    expect(find.text('Stundenplan als Bild exportieren'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timetable date tabs and weekly swipe stay interactive', (
    tester,
  ) async {
    demoModeNotifier.value = true;
    addTearDown(() => demoModeNotifier.value = false);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('viewMode', 0);
    await tester.pumpWidget(const UntisPlusApp(startScreen: WeeklyTimetablePage()));
    final dayCarousel = await ensureDayTimetableView(tester);
    expect(dayCarousel, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('timetable-day-tab-1')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('day-timetable-carousel')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calendar_view_week_rounded));
    final weekGrid = find.byKey(const ValueKey('week-grid-horizontal-scroll'));
    await pumpUntilFound(tester, weekGrid);
    expect(weekGrid, findsOneWidget);
    await tester.drag(
      weekGrid,
      const Offset(-260, 0),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await prefs.setInt('viewMode', 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timetable settings owns the lesson and card design entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SettingsTimetablePage()),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final designEntry = find.text('Stunden- & Kartendesign');
    expect(designEntry, findsOneWidget);
    await tester.ensureVisible(designEntry);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(designEntry);
    await pumpUntilFound(tester, find.byType(SettingsLessonDesignPage));
    expect(find.byType(SettingsLessonDesignPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SettingsAppearancePage()),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Stunden- & Kartendesign'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings no longer exposes tutorial replay', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const UntisPlusApp(startScreen: SettingsHubPage()));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('App-Tutorial wiederholen'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet navigation and settings switch at shared breakpoints', (
    tester,
  ) async {
    demoModeNotifier.value = true;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 768);
    addTearDown(() => demoModeNotifier.value = false);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const UntisPlusApp(startScreen: MainNavigationScreen()),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NavigationRail), findsOneWidget);

    await tester.pumpWidget(const UntisPlusApp(startScreen: SettingsHubPage()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('settings-master-detail')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-detail-0')), findsOneWidget);

    await tester.tap(find.text('Erscheinungsbild').first);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey('settings-detail-2')), findsOneWidget);

    tester.view.physicalSize = const Size(768, 1024);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const UntisPlusApp(startScreen: SettingsHubPage()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('settings-master-detail')), findsNothing);
    final appearanceEntry = find.text('Erscheinungsbild').first;
    await tester.ensureVisible(appearanceEntry);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(appearanceEntry);
    await pumpUntilFound(tester, find.byType(SettingsAppearancePage));
    expect(find.byType(SettingsAppearancePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet notifications show a selectable detail pane', (tester) async {
    demoModeNotifier.value = true;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 1024);
    addTearDown(() => demoModeNotifier.value = false);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SchoolNotificationsPage()),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(const ValueKey('notifications-master-detail')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('localization catalogs stay complete and format native copy', () {
    final catalogs = AppL10n.catalogKeys;
    final placeholders = AppL10n.catalogPlaceholders;
    final german = catalogs['de'];

    expect(german, isNotNull);
    for (final locale in AppL10n.supportedLocales) {
      expect(catalogs[locale], german, reason: 'keys differ for $locale');
      expect(AppL10n.emptyCatalogValues[locale], isEmpty);
      expect(
        placeholders[locale],
        placeholders['de'],
        reason: 'placeholders differ for $locale',
      );
      expect(
        AppL10n.of(locale).uiFormat(
          'nativeAlarmReminderTitle',
          const {'minutes': 15},
        ),
        isNot(contains('{minutes}')),
      );
    }
  });
}
