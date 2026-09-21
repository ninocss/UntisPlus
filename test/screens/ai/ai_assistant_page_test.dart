import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'aiChatHistory': '[]',
      'viewMode': 0,
    });
    appLocaleNotifier.value = 'de';
    demoModeNotifier.value = true;
    themeModeNotifier.value = ThemeMode.light;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    blurEnabledNotifier.value = true;
    backgroundAnimationsNotifier.value = false;
    aiProvider = 'gemini';
  });

  testWidgets('AI assistant uses the shared app section tabs', (tester) async {
    final l = AppL10n.of('de');

    await tester.pumpWidget(
      const UntisPlusApp(startScreen: AiAssistantPage()),
    );
    await pumpUntil(tester, find.text(l.aiEmptyPromptTitle));

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expectCenteredSectionTabs(tabBar, 2);
    expect(find.text(l.aiTabAnalysis), findsOneWidget);
    expect(find.text(l.aiTabChat), findsOneWidget);
    expect(find.text(l.aiTitle), findsWidgets);
    expect(find.text(l.aiEmptyPromptTitle), findsOneWidget);
  });

  testWidgets('AI tabs keep chat functionality discoverable', (tester) async {
    final l = AppL10n.of('de');

    await tester.pumpWidget(
      const UntisPlusApp(startScreen: AiAssistantPage()),
    );
    await pumpUntil(tester, find.text(l.aiEmptyPromptTitle));

    await tester.tap(find.text(l.aiTabChat));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text(l.aiChatTitle), findsOneWidget);
    expect(find.text(l.aiTabAnalysis), findsOneWidget);
    expect(find.text(l.aiTabChat), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsWidgets);
  });

  testWidgets('AI assistant remains usable with animations disabled', (
    tester,
  ) async {
    final l = AppL10n.of('de');

    await tester.pumpWidget(
      UntisPlusApp(
        startScreen: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const AiAssistantPage(),
        ),
      ),
    );
    await pumpUntil(tester, find.text(l.aiEmptyPromptTitle));

    await tester.tap(find.text(l.aiTabChat));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text(l.aiChatTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Exams section tabs are centered and use shared styling', (
    tester,
  ) async {
    await tester.pumpWidget(
      const UntisPlusApp(startScreen: ExamsPage()),
    );
    await tester.pump();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expectCenteredSectionTabs(tabBar, 3);
    expect(tester.takeException(), isNull);
  });
}
