import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/features/wrapped/school_wrapped.dart';
import 'package:untisplus/main.dart';

void main() {
  testWidgets('Settings opens School Wrapped in demo mode', (tester) async {
    SharedPreferences.setMockInitialValues({'viewMode': 0});
    await SettingsStore.initialize(
      preferences: await SharedPreferences.getInstance(),
    );
    demoModeNotifier.value = true;
    backgroundAnimationsNotifier.value = false;
    addTearDown(() {
      demoModeNotifier.value = false;
      backgroundAnimationsNotifier.value = true;
    });
    await tester.pumpWidget(const UntisPlusApp(startScreen: SettingsHubPage()));
    await tester.pump(const Duration(milliseconds: 200));
    final entry = find.text('School Wrapped');
    final settingsScroll = find.byKey(
      const PageStorageKey<String>('settings-hub-compact'),
    );
    for (var i = 0; i < 8 && entry.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(settingsScroll, const Offset(0, -220));
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(entry.hitTestable(), findsOneWidget);
    await tester.tap(entry.hitTestable().first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.byType(SchoolWrappedHub), findsOneWidget);
    expect(find.text('Demo-Rückblick mit Beispieldaten'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('story fits phone and tablet viewports', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final now = DateTime.now();
    final year = WrappedYear(
      start: DateTime(now.year - 1, 8, 1),
      end: DateTime(now.year, 7, 31),
    );
    await tester.pumpWidget(
      MaterialApp(home: SchoolWrappedStory(year: year, account: null)),
    );
    for (final size in [
      const Size(375, 812),
      const Size(430, 932),
      const Size(768, 1024),
      const Size(1024, 768),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Wrapped viewport $size');
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('story can advance, go back, and toggle music', (tester) async {
    final now = DateTime.now();
    final year = WrappedYear(
      start: DateTime(now.year - 1, 8, 1),
      end: DateTime(now.year, 7, 31),
    );
    await tester.pumpWidget(
      MaterialApp(home: SchoolWrappedStory(year: year, account: null)),
    );
    await tester.pump();
    expect(find.text('SCHOOL WRAPPED'), findsOneWidget);
    expect(find.text('713'), findsNothing);

    await tester.tap(find.text('Weiter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('713'), findsOneWidget);
    await tester.tap(find.text('Zurück'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('SCHOOL WRAPPED'), findsOneWidget);

    expect(find.byTooltip('Musik ausschalten'), findsOneWidget);
    await tester.tap(find.byTooltip('Musik ausschalten'));
    await tester.pump();
    expect(find.byTooltip('Musik einschalten'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion changes slides without a transition', (
    tester,
  ) async {
    backgroundAnimationsNotifier.value = false;
    addTearDown(() => backgroundAnimationsNotifier.value = true);
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: SchoolWrappedStory(
          year: WrappedYear(
            start: DateTime(now.year - 1, 8, 1),
            end: DateTime(now.year, 7, 31),
          ),
          account: null,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Weiter'));
    await tester.pump();
    expect(find.text('713'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
