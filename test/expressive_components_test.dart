import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appLocaleNotifier.value = 'de';
    appFontFamilyNotifier.value = AppFontId.googleSansFlex;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    themeModeNotifier.value = ThemeMode.light;
    useMaterialYouNotifier.value = false;
    isAmoledNotifier.value = false;
    blurEnabledNotifier.value = false;
    glowEffectsEnabledNotifier.value = false;
    backgroundAnimationsNotifier.value = false;
  });

  Future<ThemeData> pumpAppTheme(
    WidgetTester tester,
    AppThemeId themeId,
  ) async {
    visualThemeNotifier.value = themeId;
    await tester.pumpWidget(
      const UntisPlusApp(startScreen: Scaffold(body: SizedBox())),
    );
    await tester.pump();
    return tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
  }

  ThemeData componentTheme(AppThemeId id) {
    final scheme = untisThemeScheme(id, Brightness.light, 0xFF0F766E);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [UntisThemeTokens.forTheme(id, Brightness.light, scheme)],
    );
  }

  testWidgets('Default common and icon buttons expose all expressive states', (
    tester,
  ) async {
    final theme = await pumpAppTheme(tester, AppThemeId.defaultTheme);
    final common = theme.filledButtonTheme.style!;
    expect(common.minimumSize!.resolve({}), const Size(48, 48));
    expect(common.shape!.resolve({}), isA<StadiumBorder>());
    expect(
      common.shape!.resolve({WidgetState.pressed}),
      isA<RoundedSuperellipseBorder>(),
    );

    final icon = theme.iconButtonTheme.style!;
    expect(icon.minimumSize!.resolve({}), const Size(48, 48));
    expect(icon.shape!.resolve({}), isA<CircleBorder>());
    expect(
      icon.shape!.resolve({WidgetState.pressed}),
      isA<RoundedSuperellipseBorder>(),
    );
    final normal = icon.backgroundColor!.resolve({});
    final selected = icon.backgroundColor!.resolve({WidgetState.selected});
    final pressed = icon.backgroundColor!.resolve({WidgetState.pressed});
    final hovered = icon.backgroundColor!.resolve({WidgetState.hovered});
    final focused = icon.backgroundColor!.resolve({WidgetState.focused});
    final disabled = icon.backgroundColor!.resolve({WidgetState.disabled});
    expect({normal, selected, pressed, hovered, focused, disabled}.length, 6);
  });

  testWidgets('full component rules are gated to Default', (tester) async {
    for (final id in AppThemeId.values) {
      final theme = await pumpAppTheme(tester, id);
      final tokens = theme.extension<UntisThemeTokens>()!;
      expect(tokens.expressive != null, id == AppThemeId.defaultTheme);
      if (id == AppThemeId.defaultTheme) {
        expect(theme.cardTheme.shape, isA<RoundedSuperellipseBorder>());
        expect(theme.dialogTheme.shape, isA<RoundedSuperellipseBorder>());
        expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
        expect(theme.searchBarTheme.shape, isNotNull);
        expect(theme.checkboxTheme.fillColor, isNotNull);
      } else {
        expect(theme.searchBarTheme.shape, isNull);
        expect(theme.checkboxTheme.fillColor, isNull);
      }
    }

    final vivid = await pumpAppTheme(tester, AppThemeId.vivid);
    expect(
      vivid.filledButtonTheme.style!.shape!.resolve({WidgetState.pressed}),
      isA<RoundedRectangleBorder>(),
    );
  });

  testWidgets('common components keep at least 48 dp touch targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      UntisPlusApp(
        startScreen: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(onPressed: () {}, child: const Text('Save')),
                IconButton(onPressed: () {}, icon: const Icon(Icons.star)),
                ExpressiveSplitButton(
                  label: const Text('Add'),
                  onPressed: () {},
                  menuTooltip: 'More',
                  menuChildren: const [
                    MenuItemButton(onPressed: null, child: Text('Import')),
                  ],
                ),
                ExpressiveButtonGroup<int>(
                  items: const [
                    ExpressiveButtonGroupItem(value: 1, label: Text('One')),
                    ExpressiveButtonGroupItem(value: 2, label: Text('Two')),
                  ],
                  selected: const {1},
                  onSelectionChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.getSize(find.widgetWithText(FilledButton, 'Save')).height,
      48,
    );
    expect(tester.getSize(find.byType(IconButton)).shortestSide, 48);
    for (final element in find.byType(FilledButton).evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(
      tester.getSize(find.byType(SegmentedButton<int>)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets(
    'Settings groups use a solid shared expressive surface only in Default',
    (tester) async {
      Future<void> pumpGroup(AppThemeId id) => tester.pumpWidget(
        MaterialApp(
          theme: componentTheme(id),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: ListView(
                children: const [
                  SettingsGroup(
                    title: 'A very long localized settings group title',
                    children: [
                      SettingsTile(
                        title: 'A very long localized setting label',
                        subtitle:
                            'A long description remains in the same accessible group.',
                      ),
                      SettingsTile(title: 'Second setting'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await pumpGroup(AppThemeId.defaultTheme);
      expect(find.byType(ExpressiveCardGroup), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpGroup(AppThemeId.vivid);
      expect(find.byType(ExpressiveCardGroup), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Default blur requires an explicitly allowed shared surface', (
    tester,
  ) async {
    blurEnabledNotifier.value = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: componentTheme(AppThemeId.defaultTheme),
        home: Scaffold(
          body: Column(
            children: const [
              ThemedSurface(child: SizedBox(height: 20, width: 20)),
              ThemedSurface(
                allowDefaultBlur: true,
                child: SizedBox(height: 20, width: 20),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('only Default receives the expressive navigation rail theme', (
    tester,
  ) async {
    final defaultTheme = await pumpAppTheme(tester, AppThemeId.defaultTheme);
    expect(
      defaultTheme.navigationRailTheme.indicatorShape,
      isA<StadiumBorder>(),
    );
    expect(defaultTheme.navigationRailTheme.useIndicator, isTrue);

    final vividTheme = await pumpAppTheme(tester, AppThemeId.vivid);
    expect(vividTheme.navigationRailTheme.indicatorShape, isNull);
    expect(vividTheme.navigationRailTheme.useIndicator, isNull);
  });

  testWidgets('Reduced Motion and TickerMode stop loader animations', (
    tester,
  ) async {
    final loadingKey = GlobalKey<ExpressiveLoadingIndicatorState>();
    final progressKey = GlobalKey<ExpressiveProgressIndicatorState>();

    Widget subject({required bool tickers, required bool reduceMotion}) {
      return MaterialApp(
        theme: componentTheme(AppThemeId.defaultTheme),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: TickerMode(
            enabled: tickers,
            child: Scaffold(
              body: Column(
                children: [
                  ExpressiveLoadingIndicator(key: loadingKey),
                  ExpressiveProgressIndicator(key: progressKey),
                  Builder(
                    builder: (context) {
                      final duration = untisThemeTokensOf(
                        context,
                      ).expressive!.motionDuration(context);
                      return Text('${duration.inMilliseconds}');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(subject(tickers: true, reduceMotion: false));
    expect(loadingKey.currentState!.isAnimating, isTrue);
    expect(progressKey.currentState!.isAnimating, isTrue);
    expect(find.text('200'), findsOneWidget);

    await tester.pumpWidget(subject(tickers: true, reduceMotion: true));
    expect(loadingKey.currentState!.isAnimating, isFalse);
    expect(progressKey.currentState!.isAnimating, isFalse);
    expect(find.text('0'), findsOneWidget);

    await tester.pumpWidget(subject(tickers: false, reduceMotion: false));
    expect(loadingKey.currentState!.isAnimating, isFalse);
    expect(progressKey.currentState!.isAnimating, isFalse);
  });

  testWidgets('loader lifecycle disposes cleanly and non-Default falls back', (
    tester,
  ) async {
    final key = GlobalKey<ExpressiveLoadingIndicatorState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: componentTheme(AppThemeId.defaultTheme),
        home: ExpressiveLoadingIndicator(key: key, contained: false),
      ),
    );
    expect(key.currentState!.isAnimating, isTrue);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: componentTheme(AppThemeId.vivid),
        home: const ExpressiveLoadingIndicator(),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expressive-loading-paint')),
      findsNothing,
    );
  });

  testWidgets('determinate progress remains static', (tester) async {
    final key = GlobalKey<ExpressiveProgressIndicatorState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: componentTheme(AppThemeId.defaultTheme),
        home: ExpressiveProgressIndicator(key: key, value: .65),
      ),
    );
    expect(key.currentState!.isAnimating, isFalse);
    expect(tester.takeException(), isNull);
  });
}
