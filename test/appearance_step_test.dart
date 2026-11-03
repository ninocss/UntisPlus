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
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    appLocaleNotifier.value = 'de';
  });

  testWidgets('AppearanceStep renders preview, theme cards with fixed height, and toggles', (
    tester,
  ) async {
    var nextTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: AppearanceStep(
            onNext: () => nextTapped = true,
          ),
        ),
      ),
    );

    // Live preview card exists
    final preview = find.byKey(const ValueKey('onboarding-theme-preview'));
    expect(preview, findsOneWidget);

    // 4 supported themes exist with height 64
    final defaultCard = find.byKey(const ValueKey('onboarding-theme-default'));
    final cyberCard = find.byKey(const ValueKey('onboarding-theme-cyber'));
    final glassCard = find.byKey(const ValueKey('onboarding-theme-glass'));
    final mangaCard = find.byKey(const ValueKey('onboarding-theme-manga'));

    expect(defaultCard, findsOneWidget);
    expect(cyberCard, findsOneWidget);
    expect(glassCard, findsOneWidget);
    expect(mangaCard, findsOneWidget);
    expect(tester.getSize(defaultCard).height, 64);

    // Removed legacy themes must NOT exist
    expect(find.byKey(const ValueKey('onboarding-theme-vivid')), findsNothing);
    expect(find.byKey(const ValueKey('onboarding-theme-paper')), findsNothing);

    // Tapping Cyber switches visual theme
    await tester.tap(cyberCard);
    await tester.pumpAndSettle();
    expect(visualThemeNotifier.value, AppThemeId.cyber);

    // Toggles exist
    expect(find.text('Hintergrundanimationen'), findsOneWidget);
    expect(find.text('Blur-Effekt'), findsOneWidget);

    // Tapping next button triggers callback
    await tester.tap(find.text('Weiter'));
    expect(nextTapped, isTrue);
  });
}
