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

  testWidgets('FeaturesReadyStep renders celebration header, feature cards and finish button', (
    tester,
  ) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: FeaturesReadyStep(
            onComplete: () => completed = true,
          ),
        ),
      ),
    );

    // Headline exists
    expect(find.text('Bereit zum Start!'), findsOneWidget);

    // Feature benefit cards exist
    expect(find.text('Stundenplan & Kalender'), findsOneWidget);
    expect(find.text('Prüfungen & Hausaufgaben'), findsOneWidget);

    // Tap Finish button
    await tester.tap(find.text('Einrichtung abschließen'));
    expect(completed, isTrue);
  });
}
