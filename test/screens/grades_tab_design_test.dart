import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'customGrades': [
        jsonEncode({
          'id': 'g-1',
          'subject': 'Mathe',
          'value': 2.0,
          'weight': 1.0,
          'type': 'Klausur',
          'date': '2099-01-01T00:00:00.000',
        }),
      ],
    });
    await SettingsStore.initialize(
      preferences: await SharedPreferences.getInstance(),
    );
    activeUntisAccountId = null;
    sessionID = '';
    demoModeNotifier.value = false;
    appLocaleNotifier.value = 'de';
    themeModeNotifier.value = ThemeMode.light;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    backgroundAnimationsNotifier.value = false;
    hiddenSubjectsNotifier.value = {};
  });

  testWidgets('Grades tab has no FeatureSummaryCard, has unified section header, and renders subject cards', (tester) async {
    final l = appL10nFor('de');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExamsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap to Grades tab (index 2)
    await tester.tap(find.text(l.navGrades));
    await tester.pumpAndSettle();

    expect(find.byType(FeatureSummaryCard), findsNothing);
    expect(find.text(l.gradesAverage), findsOneWidget);
    expect(find.text('2.00'), findsWidgets);
    expect(find.text('Mathe'), findsOneWidget);
  });
}
