import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsStore.initialize(
      preferences: await SharedPreferences.getInstance(),
    );
    appLocaleNotifier.value = 'de';
  });

  testWidgets('WelcomeHeroStep displays title, language selector, and buttons', (
    tester,
  ) async {
    var started = false;
    var demoTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: WelcomeHeroStep(
            onGetStarted: () => started = true,
            onTryDemo: () => demoTapped = true,
          ),
        ),
      ),
    );

    // Headline is displayed
    expect(find.text('Willkommen bei Untis+'), findsOneWidget);

    // Language pills exist
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Switch language to English
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(appLocaleNotifier.value, 'en');

    // Tap CTA
    await tester.tap(find.text('Next'));
    expect(started, isTrue);

    // Tap Demo
    await tester.tap(find.text('Start demo mode'));
    expect(demoTapped, isTrue);
  });
}
