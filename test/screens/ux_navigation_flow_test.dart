import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/core/sync_state.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';

void main() {
  Future<void> initialize(String locale, AppThemeId theme) async {
    SharedPreferences.setMockInitialValues({
      'viewMode': 0,
      'aiChatHistory': '[]',
    });
    await SettingsStore.initialize(
      preferences: await SharedPreferences.getInstance(),
    );
    demoModeNotifier.value = true;
    activeUntisAccountId = null;
    untisAccountsNotifier.value = const [];
    appLocaleNotifier.value = locale;
    visualThemeNotifier.value = theme;
    themeModeNotifier.value = ThemeMode.light;
    backgroundAnimationsNotifier.value = false;
    interactionAnimationsEnabledNotifier.value = false;
    hapticsEnabledNotifier.value = false;
    effectQualityNotifier.value = AppEffectQuality.balanced;
    aiEnabledNotifier.value = true;
    aiProvider = 'gemini';
    aiModel = 'gemini-2.5-flash';
    showChangelogOnStartup = false;
    homeworkSyncPhaseNotifier.value = SyncPhase.idle;
    homeworksNotifier.value = const [];
    customHomeworkNotifier.value = const [];
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    if (!const bool.fromEnvironment('UX_CAPTURE')) return;
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      await GoogleFonts.pendingFonts();
    });
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('.artifacts/ux').create(recursive: true);
      await File(
        '.artifacts/ux/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  final scenarios = [
    ('de', AppThemeId.defaultTheme, const Size(360, 800), 2.0),
    ('en', AppThemeId.manga, const Size(412, 915), 2.0),
    ('fr', AppThemeId.glass, const Size(360, 800), 2.0),
    ('es', AppThemeId.cyber, const Size(412, 915), 2.0),
    ('de', AppThemeId.defaultTheme, const Size(390, 844), 1.0),
    ('de', AppThemeId.defaultTheme, const Size(800, 1280), 1.0),
    ('fr', AppThemeId.glass, const Size(1280, 800), 1.0),
  ];
  for (final scenario in scenarios) {
    testWidgets(
      'main destinations remain usable ${scenario.$1} ${scenario.$2.name} ${scenario.$3} text ${scenario.$4}',
      (tester) async {
        await initialize(scenario.$1, scenario.$2);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = scenario.$3;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: UntisPlusApp(
              startScreen: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scenario.$4)),
                  child: const MainNavigationScreen(),
                ),
              ),
            ),
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'timetable');
        final l = appL10nFor(scenario.$1);
        await capture(
          tester,
          key,
          '${scenario.$1}-${scenario.$2.name}-${scenario.$3.width.toInt()}-timetable',
        );
        await tester.tap(find.text(l.ux('planner')).hitTestable().first);
        await settle(tester);
        expect(find.byType(ExamsPage), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'planner');
        await capture(
          tester,
          key,
          '${scenario.$1}-${scenario.$2.name}-${scenario.$3.width.toInt()}-planner',
        );
        await tester.tap(find.text(l.ux('more')).hitTestable().first);
        await settle(tester);
        expect(find.byType(StudentMorePage), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'more');
        await tester.pumpWidget(const SizedBox.shrink());
        await settle(tester);
      },
    );
  }

  testWidgets(
    'AI draft survives main tab changes and system back returns to timetable',
    (tester) async {
      await initialize('de', AppThemeId.defaultTheme);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        const UntisPlusApp(startScreen: MainNavigationScreen()),
      );
      await settle(tester);
      await tester.tap(find.text(appL10nFor('de').navAi).hitTestable().first);
      await settle(tester);
      expect(find.textContaining('KI-Anbieter'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Mein Entwurf');
      tester.testTextInput.hide();
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester);
      await tester.tap(
        find.text(appL10nFor('de').ux('schoolInfo')).hitTestable().first,
      );
      await settle(tester);
      await tester.tap(find.text(appL10nFor('de').navAi).hitTestable().first);
      await settle(tester);
      expect(find.text('Mein Entwurf'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(WeeklyTimetablePage), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
    },
  );

  testWidgets(
    'failed homework refresh retains personal assignments and never claims an empty list',
    (tester) async {
      await initialize('de', AppThemeId.defaultTheme);
      customHomeworkNotifier.value = [
        {
          'id': 'local-1',
          'subject': 'Mathematik',
          'text': 'Meine lokale Aufgabe',
          'dueDate': 20261102,
          'isDone': false,
        },
      ];
      homeworkSyncPhaseNotifier.value = SyncPhase.failed;
      await tester.pumpWidget(const UntisPlusApp(startScreen: HomeworkPage()));
      await settle(tester);
      expect(find.text(appL10nFor('de').ux('loadError')), findsOneWidget);
      expect(find.text('Meine lokale Aufgabe'), findsWidgets);
      expect(find.text(appL10nFor('de').homeworkNone), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
    },
  );
}
