import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';

void main() {
  Future<void> setMockSettings(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    await SettingsStore.initialize(
      preferences: await SharedPreferences.getInstance(),
    );
  }

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

  setUp(() async {
    await setMockSettings({
      'viewMode': 0,
      'onboardingCheckpoint': 0,
    });
    demoModeNotifier.value = false;
    aiProvider = 'gemini';
    appLocaleNotifier.value = 'de';
    activeUntisAccountId = null;
    untisAccountsNotifier.value = const [];
    pageTransitionNotifier.value = 0;
    themeModeNotifier.value = ThemeMode.light;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    blurEnabledNotifier.value = true;
    timetableSwitchAnimationNotifier.value = 0;
    // An endless decorative animation is not relevant to theme selection and
    // would keep pumpAndSettle from completing in this widget test.
    backgroundAnimationsNotifier.value = false;
    themeBlurPreferencesNotifier.value = {
      'default': true,
      'glass': true,
      'cyber': true,
    };
  });

  testWidgets('modal backdrops blur only for active blur-capable themes', (
    tester,
  ) async {
    Future<void> pumpHost() async {
      await tester.pumpWidget(
        const UntisPlusApp(startScreen: _ModalBackdropTestHost()),
      );
      await tester.pump();
    }

    Future<void> closeModal() async {
      await tester.tapAt(const Offset(4, 4));
      await tester.pump(const Duration(milliseconds: 300));
    }

    await pumpHost();
    await tester.tap(find.byKey(const ValueKey('modal-test-sheet')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(BackdropFilter), findsOneWidget);
    await closeModal();

    await tester.tap(find.byKey(const ValueKey('modal-test-dialog')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(BackdropFilter), findsOneWidget);
    await closeModal();

    blurEnabledNotifier.value = false;
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('modal-test-sheet')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(BackdropFilter), findsNothing);
    await closeModal();

    blurEnabledNotifier.value = true;
    visualThemeNotifier.value = AppThemeId.manga;
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('modal-test-dialog')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('settings descriptions appear only after long press', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsTile(
            title: 'Test setting',
            subtitle: 'Long press description',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Long press description'), findsNothing);

    await tester.longPress(find.text('Test setting'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Long press description'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await setMockSettings({
      'viewMode': 0,
      // This test covers the theme page layout, not the welcome-page transition.
      'onboardingCheckpoint': 1,
    });
    await tester.pumpWidget(
      const UntisPlusApp(
        startScreen: OnboardingFlow(key: ValueKey('theme-layout-onboarding')),
      ),
    );

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
      await setMockSettings({
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

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await setMockSettings({
      'viewMode': 0,
      'onboardingCheckpoint': 0,
      'aiProvider': 'local',
    });
    aiProvider = 'local';
    addTearDown(() => aiProvider = 'gemini');
    await tester.pumpWidget(
      const UntisPlusApp(
        startScreen: OnboardingFlow(key: ValueKey('local-ai-onboarding')),
      ),
    );
    await pumpUntilFound(tester, find.text('Weiter'));

    await tapVisible(tester, find.text('Weiter'));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('onboarding-theme-default')),
    );
    await tapVisible(tester, find.text('Weiter'));

    final demoButton = find.text('Demo-Modus starten');
    await pumpUntilFound(tester, demoButton);
    await tapVisible(tester, demoButton);
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
    final refreshedDayCarousel = await ensureDayTimetableView(tester);
    expect(refreshedDayCarousel, findsOneWidget);

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

  testWidgets('timetable switch animation setting persists the selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SettingsTimetablePage()),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final animationEntry = find.text('Wechselanimation');
    expect(animationEntry, findsOneWidget);
    await tester.tap(animationEntry);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Standard'), findsWidgets);
    expect(find.text('Material 3 Carousel'), findsOneWidget);
    expect(find.text('Tiefe & Fade'), findsOneWidget);

    await tapVisible(tester, find.text('Material 3 Carousel'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(timetableSwitchAnimationNotifier.value, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('timetableSwitchAnimation'), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('alternate timetable switch animations render their own paths', (
    tester,
  ) async {
    demoModeNotifier.value = true;
    addTearDown(() {
      demoModeNotifier.value = false;
      timetableSwitchAnimationNotifier.value = 0;
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('viewMode', 0);

    timetableSwitchAnimationNotifier.value = 1;
    await tester.pumpWidget(
      const UntisPlusApp(
        startScreen: WeeklyTimetablePage(
          key: ValueKey('material-carousel-timetable'),
        ),
      ),
    );
    final materialDay = await ensureDayTimetableView(tester);
    expect(materialDay, findsOneWidget);
    expect(find.byType(CarouselView), findsOneWidget);
    await tester.tap(find.byIcon(Icons.calendar_view_week_rounded));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('material-week-timetable-carousel')),
    );
    expect(
      find.byKey(const ValueKey('material-week-timetable-carousel')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await prefs.setInt('viewMode', 0);
    timetableSwitchAnimationNotifier.value = 2;
    await tester.pumpWidget(
      const UntisPlusApp(
        startScreen: WeeklyTimetablePage(
          key: ValueKey('depth-fade-timetable'),
        ),
      ),
    );
    final depthDay = await ensureDayTimetableView(tester);
    expect(depthDay, findsOneWidget);
    expect(find.byType(CarouselView), findsNothing);
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

  testWidgets('notifications load when the Info tab becomes active', (
    tester,
  ) async {
    demoModeNotifier.value = true;
    addTearDown(() => demoModeNotifier.value = false);

    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SchoolNotificationsPage(isActive: false)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Willkommen bei Untis+'), findsNothing);

    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SchoolNotificationsPage(isActive: true)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Willkommen bei Untis+'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Focus Blur prepares its filter at startup', (tester) async {
    pageTransitionNotifier.value = 4;

    await tester.pumpWidget(const UntisPlusApp(startScreen: SizedBox.expand()));
    await tester.pump();

    expect(find.byKey(const ValueKey('focus-blur-warmup')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('localization catalogs stay complete and format native copy', () {
    final catalogs = <String, Map<String, dynamic>>{};
    for (final locale in AppL10n.supportedLocales) {
      final languageCode = locale.languageCode;
      catalogs[languageCode] = jsonDecode(
        File('lib/l10n/arb/app_$languageCode.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
    }
    final germanKeys = catalogs['de']!.keys
        .where((key) => !key.startsWith('@'))
        .toSet();
    final placeholderPattern = RegExp(r'\{([A-Za-z][A-Za-z0-9_]*)\}');
    for (final locale in AppL10n.supportedLocales) {
      final languageCode = locale.languageCode;
      final catalog = catalogs[languageCode]!;
      expect(
        catalog.keys.where((key) => !key.startsWith('@')).toSet(),
        germanKeys,
        reason: 'keys differ for $languageCode',
      );
      for (final key in germanKeys) {
        final value = catalog[key] as String;
        expect(value.trim(), isNotEmpty, reason: '$languageCode.$key is empty');
        final placeholders = placeholderPattern
            .allMatches(value)
            .map((match) => match.group(1))
            .toSet();
        final germanPlaceholders = placeholderPattern
            .allMatches(catalogs['de']![key] as String)
            .map((match) => match.group(1))
            .toSet();
        expect(
          placeholders,
          germanPlaceholders,
          reason: 'placeholders differ for $languageCode.$key',
        );
      }
      expect(
        appL10nFor(languageCode).nativeAlarmReminderTitle(15),
        isNot(contains('{minutes}')),
      );
    }
  });
}

class _ModalBackdropTestHost extends StatelessWidget {
  const _ModalBackdropTestHost();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            key: const ValueKey('modal-test-sheet'),
            onPressed: () => showUntisModalBottomSheet<void>(
              context: context,
              builder: (_) => const SizedBox(height: 120),
            ),
            child: const Text('Open sheet'),
          ),
          FilledButton(
            key: const ValueKey('modal-test-dialog'),
            onPressed: () => showUntisDialog<void>(
              context: context,
              builder: (_) => const Dialog(child: SizedBox(height: 120)),
            ),
            child: const Text('Open dialog'),
          ),
        ],
      ),
    ),
  );
}
