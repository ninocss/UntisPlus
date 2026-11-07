import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';

void main() {
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 60,
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(finder, findsWidgets);
  }

  void expectCenteredSectionTabs(TabBar tabBar, int count) {
    expect(tabBar.tabs, hasLength(count));
    expect(tabBar.indicatorWeight, 3);
    expect(tabBar.dividerColor, Colors.transparent);

    for (final tabWidget in tabBar.tabs) {
      final tab = tabWidget as Tab;
      final row = tab.child! as Row;
      expect(row.mainAxisAlignment, MainAxisAlignment.center);
      expect(row.mainAxisSize, MainAxisSize.max);
      expect(row.children.whereType<Expanded>(), isEmpty);
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'aiChatHistory': '[]',
      'viewMode': 0,
    });
    await SettingsStore.initialize(
      preferences: await SharedPreferences.getInstance(),
    );
    appLocaleNotifier.value = 'de';
    demoModeNotifier.value = true;
    themeModeNotifier.value = ThemeMode.light;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    blurEnabledNotifier.value = true;
    backgroundAnimationsNotifier.value = false;
    aiProvider = 'gemini';
  });

  testWidgets('AI assistant loads into unified expressive chat', (
    tester,
  ) async {
    final l = appL10nFor('de');

    await tester.pumpWidget(const UntisPlusApp(startScreen: AiAssistantPage()));
    await pumpUntil(tester, find.byType(TextField));

    expect(find.text(l.aiTitle), findsWidgets);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.byIcon(Icons.edit_square), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      l.aiGreetings.any(
        (greeting) => find.text(greeting).evaluate().isNotEmpty,
      ),
      isTrue,
    );
  });

  testWidgets('AI greeting fades away after sending a message', (tester) async {
    final l = appL10nFor('de');

    await tester.pumpWidget(const UntisPlusApp(startScreen: AiAssistantPage()));
    await pumpUntil(tester, find.byType(TextField));

    final visibleGreeting = l.aiGreetings.singleWhere(
      (greeting) => find.text(greeting).evaluate().isNotEmpty,
    );
    await tester.enterText(find.byType(TextField), 'Hallo');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded).hitTestable());
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      if (find.text(visibleGreeting).evaluate().isEmpty) break;
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text(visibleGreeting), findsNothing);
    expect(find.text('Hallo'), findsOneWidget);
  });

  testWidgets('AI assistant remains usable with animations disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      UntisPlusApp(
        startScreen: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const AiAssistantPage(),
        ),
      ),
    );
    await pumpUntil(tester, find.byType(TextField));

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Exams section tabs are centered and use shared styling', (
    tester,
  ) async {
    await tester.pumpWidget(const UntisPlusApp(startScreen: ExamsPage()));
    await tester.pump();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expectCenteredSectionTabs(tabBar, 3);
    expect(tester.takeException(), isNull);
  });
}
