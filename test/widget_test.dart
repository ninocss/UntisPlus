import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:untisplus/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appLocaleNotifier.value = 'de';
    activeUntisAccountId = null;
    untisAccountsNotifier.value = const [];
    themeModeNotifier.value = ThemeMode.light;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    blurEnabledNotifier.value = true;
    // An endless decorative animation is not relevant to theme selection and
    // would keep pumpAndSettle from completing in this widget test.
    backgroundAnimationsNotifier.value = false;
    themeBlurPreferencesNotifier.value = {
      'default': true,
      'vivid': true,
      'glass': true,
      'cyber': true,
    };
  });

  testWidgets('theme picker applies Manga immediately and disables blur', (
    tester,
  ) async {
    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SettingsAppearancePage()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('theme-manga')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('theme-manga')));
    await tester.pumpAndSettle();

    expect(visualThemeNotifier.value, AppThemeId.manga);
    expect(blurEnabledNotifier.value, isFalse);

    final context = tester.element(find.byType(SettingsAppearancePage));
    expect(
      Theme.of(context).extension<UntisThemeTokens>()?.id,
      AppThemeId.manga,
    );
  });

  testWidgets('all themes provide light and dark ThemeData', (tester) async {
    for (final theme in AppThemeId.values) {
      visualThemeNotifier.value = theme;
      themeModeNotifier.value = ThemeMode.light;
      await tester.pumpWidget(
        const UntisPlusApp(startScreen: Scaffold(body: SizedBox())),
      );
      await tester.pump();
      var context = tester.element(find.byType(Scaffold));
      expect(Theme.of(context).brightness, Brightness.light);
      expect(Theme.of(context).extension<UntisThemeTokens>()?.id, theme);

      themeModeNotifier.value = ThemeMode.dark;
      await tester.pump();
      context = tester.element(find.byType(Scaffold));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(Theme.of(context).extension<UntisThemeTokens>()?.id, theme);
    }
  });

  testWidgets('widget settings switches complete previews', (tester) async {
    final account = UntisAccount(
      id: 'account-test',
      username: 'Testkonto',
      schoolUrl: 'example.webuntis.com',
      schoolName: 'Testschule',
      password: '',
      credentialMode: 'password',
      sessionId: '',
      personId: 1,
      personType: 5,
      lastUsedAt: DateTime(2026),
    );
    activeUntisAccountId = account.id;
    untisAccountsNotifier.value = [account];

    await tester.pumpWidget(
      const UntisPlusApp(startScreen: SettingsWidgetsPage()),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('widget-preview-current')),
      findsOneWidget,
    );
    expect(find.text('Testkonto'), findsWidgets);
    expect(find.text('Keine aktuelle Stunde'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tagesplan'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('widget-preview-schedule')),
      findsOneWidget,
    );
    expect(find.text('Noch keine Tagesdaten'), findsOneWidget);
    expect(find.text('Mittel oder groß'), findsOneWidget);
  });
}
