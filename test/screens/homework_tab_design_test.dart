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
      'customHomework': [
        jsonEncode({
          'id': 'hw-1',
          'subject': 'Mathe',
          'text': 'Aufgaben S. 42',
          'dueDate': '20990101',
          'isDone': false,
        }),
        jsonEncode({
          'id': 'hw-2',
          'subject': 'Deutsch',
          'text': 'Aufsatz schreiben',
          'dueDate': '20990101',
          'isDone': true,
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
    homeworksNotifier.value = [];
  });

  testWidgets('Homework view has no FeatureSummaryCard, no filter chips, and shows Open and Done section headers', (tester) async {
    final l = appL10nFor('de');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExamsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap to Homework tab (index 1)
    await tester.tap(find.text(l.navHomework));
    await tester.pumpAndSettle();

    expect(find.byType(FeatureSummaryCard), findsNothing);
    expect(find.text(l.homeworkFilterAll), findsNothing);
    expect(find.text(l.homeworkFilterOpen), findsOneWidget);
    expect(find.text(l.homeworkFilterDone), findsOneWidget);
    expect(find.text('Aufgaben S. 42'), findsOneWidget);
    expect(find.text('Aufsatz schreiben'), findsOneWidget);
  });
}
