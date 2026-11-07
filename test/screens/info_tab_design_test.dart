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
  });

  testWidgets('Info page has no FeatureSummaryCard, has expressive search pill, and shows unified empty state when empty', (tester) async {
    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SchoolNotificationsPage(isActive: true)),
    );
    await tester.pumpAndSettle();

    // FeatureSummaryCard must be removed
    expect(find.byType(FeatureSummaryCard), findsNothing);

    // Expressive search bar should be present
    expect(find.byKey(const ValueKey('info-search-field')), findsOneWidget);

    // Segmented button for Start vs Nachrichten
    expect(find.byType(SegmentedButton<bool>), findsOneWidget);

    // Unified empty state
    expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
  });

  testWidgets('Info page in demo mode shows expressive items and search filters them', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    demoModeNotifier.value = true;
    addTearDown(() => demoModeNotifier.value = false);

    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SchoolNotificationsPage(isActive: true)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Item should be visible
    expect(find.text('Willkommen bei Untis+'), findsOneWidget);
    // Squircle icon for news
    expect(find.byIcon(Icons.campaign_rounded), findsWidgets);

    // Search for existing text
    final searchField = find.byKey(const ValueKey('info-search-field'));
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'Willkommen');
    await tester.pumpAndSettle();
    expect(find.text('Willkommen bei Untis+'), findsOneWidget);

    // Search for non-existent text
    await tester.enterText(searchField, 'ZzzNonExistentString123');
    await tester.pumpAndSettle();
    expect(find.text('Willkommen bei Untis+'), findsNothing);
  });
}
