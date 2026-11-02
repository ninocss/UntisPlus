import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';

void main() {
  Future<void> initialize(Map<String, Object> preferences) async {
    SharedPreferences.setMockInitialValues(preferences);
    await SettingsStore.initialize(
      preferences: await SharedPreferences.getInstance(),
    );
    appLocaleNotifier.value = 'de';
    demoModeNotifier.value = false;
    backgroundAnimationsNotifier.value = false;
    interactionAnimationsEnabledNotifier.value = false;
    hapticsEnabledNotifier.value = false;
    blurEnabledNotifier.value = false;
    aiEnabledNotifier.value = false;
  }

  testWidgets('new setup goes directly from language to school login', (
    tester,
  ) async {
    await initialize({});
    final l = appL10nFor('de');
    await tester.pumpWidget(const UntisPlusApp(startScreen: OnboardingFlow()));
    await tester.pump();
    expect(find.text('1/2'), findsOneWidget);
    await tester.tap(find.text(l.onboardingNext).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text(l.onboardingUseDemoMode), findsOneWidget);
    expect(find.text(l.onboardingGeminiTitle), findsNothing);
    expect(tester.takeException(), isNull);
    // Dispose focus/listeners before the next setup instance.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'legacy AI checkpoint resumes at school login without AI initialization',
    (tester) async {
      await initialize({'onboardingCheckpoint': 3});
      await tester.pumpWidget(
        const UntisPlusApp(startScreen: OnboardingFlow()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('2/2'), findsOneWidget);
      expect(find.text(appL10nFor('de').onboardingUseDemoMode), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'demo completes setup without mandatory AI, tutorial or release notes',
    (tester) async {
      await initialize({
        'onboardingCheckpoint': 1,
        'onboardingCheckpointSchema': 2,
        'showChangelogPending': true,
      });
      showChangelogOnStartup = true;
      await tester.pumpWidget(
        const UntisPlusApp(startScreen: OnboardingFlow()),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.text(appL10nFor('de').onboardingUseDemoMode));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.byType(ChangelogWidget), findsNothing);
      expect(find.byKey(const ValueKey('tutorial-callout')), findsNothing);
      expect(
        SettingsStore.instance.preferences.getBool('onboardingCompleted'),
        isTrue,
      );
      expect(
        SettingsStore.instance.preferences.get('onboardingCheckpoint'),
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
