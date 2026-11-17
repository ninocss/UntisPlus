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
    activeUntisAccountId = null;
    sessionID = '';
    demoModeNotifier.value = false;
    appLocaleNotifier.value = 'de';
    themeModeNotifier.value = ThemeMode.light;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    backgroundAnimationsNotifier.value = false;
    hiddenSubjectsNotifier.value = {};
    customExamsNotifier.value = [];
  });

  testWidgets('Exams tab does not contain FeatureSummaryCard and shows unified empty state when empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ExamsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FeatureSummaryCard), findsNothing);
    expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
  });
}
