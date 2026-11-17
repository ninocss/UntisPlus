import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SettingsStore.initialize(preferences: prefs);
    demoModeNotifier.value = true;
    appLocaleNotifier.value = 'de';
  });

  tearDown(() {
    demoModeNotifier.value = false;
  });

  testWidgets('pendingTimetableAction open_free_rooms opens RoomSearchPage', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WeeklyTimetablePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger action
    pendingTimetableActionNotifier.value = 'open_free_rooms';
    await tester.pumpAndSettle();

    // Verify RoomSearchPage is opened
    expect(find.byType(RoomSearchPage), findsOneWidget);
  });
}
