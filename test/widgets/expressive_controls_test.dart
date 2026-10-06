import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'viewMode': 0,
      'timetableViewModeV2': 0,
      'onboardingCheckpoint': 0,
    });
    await SettingsStore.initialize(
      preferences: await SharedPreferences.getInstance(),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('home_widget'),
          (_) async => true,
        );
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    themeModeNotifier.value = ThemeMode.light;
    useMaterialYouNotifier.value = false;
    isAmoledNotifier.value = false;
    appLocaleNotifier.value = 'de';
    backgroundAnimationsNotifier.value = false;
    interactionAnimationsEnabledNotifier.value = false;
    glowEffectsEnabledNotifier.value = false;
    blurEnabledNotifier.value = false;
    effectQualityNotifier.value = AppEffectQuality.balanced;
    demoModeNotifier.value = true;
    customHomeworkNotifier.value = [];
    homeworksNotifier.value = [];
    untisAccountsNotifier.value = [];
  });

  tearDown(() {
    demoModeNotifier.value = false;
    interactionAnimationsEnabledNotifier.value = true;
    customHomeworkNotifier.value = [];
    homeworksNotifier.value = [];
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    themeModeNotifier.value = ThemeMode.light;
    appLocaleNotifier.value = 'de';
    isAmoledNotifier.value = false;
    SettingsStore.debugReset();
  });

  testWidgets(
    'selection fields keep IDs distinct from duplicate labels and follow external changes',
    (tester) async {
      String? selected = 'a';
      late StateSetter update;
      await tester.pumpWidget(
        UntisPlusApp(
          startScreen: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return UntisSelectionField<String>(
                  label: 'Konto',
                  icon: Icons.person_rounded,
                  value: selected,
                  entries: const [
                    (value: 'a', label: 'Schule'),
                    (value: 'b', label: 'Schule'),
                  ],
                  onChanged: (value) => setState(() => selected = value),
                );
              },
            ),
          ),
        ),
      );
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      await tester.tap(find.byType(InputDecorator));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MenuItemButton).last);
      await tester.pumpAndSettle();
      expect(selected, 'b');
      update(() => selected = 'missing');
      await tester.pumpAndSettle();
      expect(
        tester.widget<InputDecorator>(find.byType(InputDecorator)).isEmpty,
        isTrue,
      );
      update(() => selected = 'a');
      await tester.pumpAndSettle();
      expect(
        tester.widget<InputDecorator>(find.byType(InputDecorator)).isEmpty,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'action rows expose selection and fire once; other themes retain native rows',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        UntisPlusApp(
          startScreen: Scaffold(
            body: UntisActionTile(
              title: const Text('Auswahl'),
              selected: true,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(MergeSemantics)),
        matchesSemantics(
          label: 'Auswahl',
          isSelected: true,
          hasSelectedState: true,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(find.text('Auswahl'));
      expect(taps, 1);
      for (final theme in [
        AppThemeId.manga,
        AppThemeId.glass,
        AppThemeId.cyber,
      ]) {
        visualThemeNotifier.value = theme;
        await tester.pumpAndSettle();
        expect(find.byType(ListTile), findsOneWidget);
        expect(find.byType(TextButton), findsNothing);
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'loader stops with reduced motion, hidden routes and preferences; determinate progress stays native',
    (tester) async {
      interactionAnimationsEnabledNotifier.value = true;
      var enabled = true;
      late StateSetter update;
      await tester.pumpWidget(
        UntisPlusApp(
          startScreen: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return TickerMode(
                enabled: enabled,
                child: const Center(child: ExpressiveLoadingIndicator()),
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.hasRunningAnimations, isTrue);
      update(() => enabled = false);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      update(() => enabled = true);
      await tester.pump();
      interactionAnimationsEnabledNotifier.value = false;
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.bySemanticsLabel('Wird geladen'), findsOneWidget);
      await tester.pumpWidget(
        const UntisPlusApp(
          startScreen: Center(child: ExpressiveLoadingIndicator(value: .6)),
        ),
      );
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        .6,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'homework filtering, completion and undo retain their data behavior',
    (tester) async {
      customHomeworkNotifier.value = [
        {
          'id': 'expressive-task',
          'subject': 'Mathematik',
          'text': 'Aufgabe bearbeiten',
          'dueDate': 20261009,
          'isDone': false,
        },
      ];
      await tester.pumpWidget(
        const UntisPlusApp(startScreen: Scaffold(body: HomeworkPage())),
      );
      await tester.pumpAndSettle();
      final completion = find.byKey(
        const ValueKey('homework-done-expressive-task'),
      );
      await tester.ensureVisible(completion);
      await tester.tap(completion);
      await tester.pumpAndSettle();
      expect(customHomeworkNotifier.value.single['isDone'], isTrue);
      await tester.tap(find.text(appL10nFor('de').commonUndo));
      await tester.pumpAndSettle();
      expect(customHomeworkNotifier.value.single['isDone'], isFalse);
      final open = find.byKey(const ValueKey('homework-filter-1'));
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(open).selected, isTrue);
      final done = find.byKey(const ValueKey('homework-filter-3'));
      await tester.ensureVisible(done);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(find.text('Aufgabe bearbeiten'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'timetable selection preserves day taps, lesson actions and alarm long press',
    (tester) async {
      await tester.pumpWidget(
        const UntisPlusApp(startScreen: WeeklyTimetablePage()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(UntisSelectionIndicator), findsOneWidget);
      final tab = find.byKey(const ValueKey('timetable-day-tab-1'));
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<UntisSelectionIndicator>(
              find.byType(UntisSelectionIndicator),
            )
            .index,
        1,
      );
      final lesson = find
          .byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'lesson-detail-',
                ),
          )
          .hitTestable()
          .first;
      await tester.tap(lesson);
      await tester.pumpAndSettle();
      final hide = find.byTooltip(appL10nFor('de').detailHideSubject);
      expect(hide, findsOneWidget);
      expect(tester.getSize(hide).shortestSide, greaterThanOrEqualTo(48));
      Navigator.of(tester.element(hide)).pop();
      await tester.pumpAndSettle();
      await tester.longPress(tab);
      await tester.pumpAndSettle();
      expect(find.byType(UntisActionTile), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Default screens fit phone/tablet, large text, dark and AMOLED with localized labels',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final screens = <String, Widget Function()>{
        'homework': () => const Scaffold(body: HomeworkPage()),
        'exams': () => const ExamsPage(),
        'grades': () => const Scaffold(body: GradesTrackerPage()),
        'notes': () => const StudentNotesPage(
          notes: 'Vorbereitung auf die nächste Unterrichtsstunde.',
          registerNotes: 'Arbeitsblatt besprechen.',
        ),
        'widget-editor': () => const CustomWidgetEditorPage(),
        'background-editor': () => const CustomBackgroundEditorScreen(),
        'notifications': () => const SchoolNotificationsPage(),
        'timetable': () => const WeeklyTimetablePage(),
      };
      final layoutErrors = <String>[];
      for (final config in [
        (
          size: const Size(360, 800),
          scale: 1.0,
          dark: false,
          amoled: false,
          locale: 'de',
        ),
        (
          size: const Size(360, 800),
          scale: 2.0,
          dark: true,
          amoled: false,
          locale: 'fr',
        ),
        (
          size: const Size(800, 1280),
          scale: 2.0,
          dark: true,
          amoled: true,
          locale: 'es',
        ),
      ]) {
        tester.view.physicalSize = config.size;
        themeModeNotifier.value = config.dark
            ? ThemeMode.dark
            : ThemeMode.light;
        isAmoledNotifier.value = config.amoled;
        appLocaleNotifier.value = config.locale;
        for (final entry in screens.entries) {
          await tester.pumpWidget(const SizedBox.shrink());
          const captureKey = ValueKey('expressive-qa-screen');
          await tester.pumpWidget(
            UntisPlusApp(
              startScreen: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(config.scale)),
                  child: RepaintBoundary(
                    key: captureKey,
                    child: ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
                      child: entry.value(),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final error = tester.takeException();
          if (error != null) layoutErrors.add('${entry.key}: $config: $error');
          if (const bool.fromEnvironment('EXPRESSIVE_QA')) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(captureKey),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'build/expressive-qa/${entry.key}-${config.locale}-${config.scale}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      expect(layoutErrors, isEmpty);
    },
  );
}
