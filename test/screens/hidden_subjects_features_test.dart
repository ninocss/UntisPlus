import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';

void main() {
  Future<void> pumpUntilSettled(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'customExams': [
        jsonEncode({
          'subject': 'Mathematik',
          'examType': 'Versteckte Klausur',
          'date': '20990101',
        }),
        jsonEncode({
          'subject': 'D',
          'examType': 'Sichtbare Klausur',
          'date': '20990102',
        }),
      ],
      'customHomework': [
        jsonEncode({
          'id': 'hidden-homework',
          'subject': 'Mathematik',
          'text': 'Versteckte Hausaufgabe',
          'dueDate': '20990101',
        }),
        jsonEncode({
          'id': 'visible-homework',
          'subject': 'D',
          'text': 'Sichtbare Hausaufgabe',
          'dueDate': '20990102',
        }),
      ],
      'customGrades': [
        jsonEncode({
          'id': 'hidden-grade',
          'subject': 'Mathematik',
          'value': 1.0,
          'weight': 1.0,
          'type': 'Test',
          'date': '2099-01-01T00:00:00.000',
        }),
        jsonEncode({
          'id': 'visible-grade',
          'subject': 'D',
          'value': 2.0,
          'weight': 1.0,
          'type': 'Arbeit',
          'date': '2099-01-02T00:00:00.000',
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
    hiddenSubjectsNotifier.value = {'M'};
    knownSubjectsNotifier.value = {'M', 'D'};
    currentWeekDataNotifier.value = {
      0: [
        {'_subjectShort': 'M', '_subjectLong': 'Mathematik'},
        {'_subjectShort': 'D', '_subjectLong': 'Deutsch'},
      ],
    };
  });

  tearDown(() {
    hiddenSubjectsNotifier.value = {};
    knownSubjectsNotifier.value = {};
    currentWeekDataNotifier.value = {};
  });

  testWidgets('hidden subjects stay out of exams homework and grades', (
    tester,
  ) async {
    final l = appL10nFor('de');
    await tester.pumpWidget(const UntisPlusApp(startScreen: ExamsPage()));
    await pumpUntilSettled(tester);

    expect(find.text('Versteckte Klausur'), findsNothing);
    expect(find.text('Sichtbare Klausur'), findsOneWidget);

    await tester.tap(find.text(l.homeworkTitle));
    await pumpUntilSettled(tester);
    expect(find.text('Versteckte Hausaufgabe'), findsNothing);
    expect(find.text('Sichtbare Hausaufgabe'), findsOneWidget);

    await tester.tap(find.text(l.gradesTitle));
    await pumpUntilSettled(tester);
    expect(find.text('Mathematik'), findsNothing);
    expect(find.text('D'), findsWidgets);
  });
}
