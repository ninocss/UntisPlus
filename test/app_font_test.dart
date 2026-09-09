import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/main.dart';
import 'package:untisplus/services/backup_service.dart';
import 'package:untisplus/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  configureBundledFonts();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appFontFamilyNotifier.value = AppFontId.googleSansFlex;
    visualThemeNotifier.value = AppThemeId.defaultTheme;
    themeModeNotifier.value = ThemeMode.light;
    useMaterialYouNotifier.value = false;
    isAmoledNotifier.value = false;
    backgroundAnimationsNotifier.value = false;
  });

  test('font storage ids and migration fallback are stable', () async {
    expect(AppFontId.values.map((font) => font.storageKey), [
      'googleSansFlex',
      'outfit',
      'robotoFlex',
    ]);
    for (final font in AppFontId.values) {
      expect(AppFontIdX.fromStorage(font.storageKey), font);
    }
    for (final stored in [null, '', 'future-font']) {
      expect(AppFontIdX.fromStorage(stored), AppFontId.googleSansFlex);
      final prefs = await SharedPreferences.getInstance();
      if (stored != null) await prefs.setString('appFontFamily', stored);
      appFontFamilyNotifier.value = AppFontId.outfit;
      loadAppFont(prefs);
      expect(appFontFamilyNotifier.value, AppFontId.googleSansFlex);
    }
  });

  test(
    'selection applies synchronously and survives backup and startup',
    () async {
      for (final font in AppFontId.values) {
        final write = setAppFontFamily(font);
        expect(appFontFamilyNotifier.value, font);
        await write;
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('appFontFamily'), font.storageKey);
        final backup = await BackupService().exportAllToJsonText();
        await prefs.clear();
        await BackupService().importAllFromJsonText(backup);
        appFontFamilyNotifier.value = AppFontId.googleSansFlex;
        loadAppFont(prefs);
        expect(appFontFamilyNotifier.value, font);
      }
    },
  );

  test('Default fallback is expressive in both brightness modes', () {
    for (final brightness in Brightness.values) {
      const seed = 0xFF0F766E;
      expect(
        untisThemeScheme(AppThemeId.defaultTheme, brightness, seed),
        ColorScheme.fromSeed(
          seedColor: const Color(seed),
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.expressive,
        ),
      );
      for (final id in AppThemeId.values) {
        final tokens = UntisThemeTokens.forTheme(
          id,
          brightness,
          untisThemeScheme(id, brightness, seed),
        );
        expect(tokens.expressive != null, id == AppThemeId.defaultTheme);
      }
    }
  });

  test('all fifteen text roles use the selected font across themes', () {
    for (final font in AppFontId.values) {
      for (final id in AppThemeId.values) {
        for (final brightness in Brightness.values) {
          final t = untisThemeTextTheme(id, brightness, font: font);
          for (final style in [
            t.displayLarge,
            t.displayMedium,
            t.displaySmall,
            t.headlineLarge,
            t.headlineMedium,
            t.headlineSmall,
            t.titleLarge,
            t.titleMedium,
            t.titleSmall,
            t.bodyLarge,
            t.bodyMedium,
            t.bodySmall,
            t.labelLarge,
            t.labelMedium,
            t.labelSmall,
          ]) {
            expect(style!.fontFamily, font.family);
          }
        }
      }
    }
    expect(AppTypography.variations(AppFontId.outfit, 14), isEmpty);
  });

  testWidgets('font changes rebuild light and dark app themes immediately', (
    tester,
  ) async {
    await tester.pumpWidget(const UntisPlusApp(startScreen: Scaffold()));
    for (final font in AppFontId.values) {
      final write = setAppFontFamily(font);
      await tester.pump();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme!.textTheme.bodyMedium!.fontFamily, font.family);
      expect(app.darkTheme!.textTheme.bodyMedium!.fontFamily, font.family);
      expect(app.theme!.primaryTextTheme.bodyMedium!.fontFamily, font.family);
      await write;
    }
    isAmoledNotifier.value = true;
    themeModeNotifier.value = ThemeMode.dark;
    await tester.pump();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.darkTheme!.colorScheme.surface, Colors.black);
    expect(
      app.darkTheme!.colorScheme.primary,
      untisThemeScheme(
        AppThemeId.defaultTheme,
        Brightness.dark,
        customColorSeedNotifier.value,
      ).primary,
    );
  });

  testWidgets('localized font picker supports selection and scaled previews', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final locale in ['de', 'en', 'fr', 'es']) {
      appLocaleNotifier.value = locale;
      appFontFamilyNotifier.value = AppFontId.googleSansFlex;
      await tester.pumpWidget(
        UntisPlusApp(
          key: ValueKey(locale),
          startScreen: const SettingsAppearancePage(),
        ),
      );
      await tester.pumpAndSettle();
      final option = find.byKey(const ValueKey('font-robotoFlex'));
      await tester.scrollUntilVisible(option, 250);
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(appFontFamilyNotifier.value, AppFontId.robotoFlex);
      expect(
        find.text(AppL10n.of(locale).ui('appearanceFontPreview')),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    }
  });

  test(
    'bundled variable fonts expose exactly the supported optical axes',
    () async {
      final manifest =
          jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
      for (final font in AppFontId.values) {
        final entry = manifest.cast<Map<String, dynamic>>().singleWhere(
          (entry) => entry['family'] == font.family,
        );
        final data = await rootBundle.load(
          entry['fonts'][0]['asset'] as String,
        );
        final axes = <String, (double, double)>{};
        for (var i = 0; i < data.getUint16(4); i++) {
          final table = 12 + i * 16;
          if (data.getUint32(table) != 0x66766172) continue; // fvar
          final offset = data.getUint32(table + 8);
          final start = offset + data.getUint16(offset + 4);
          final count = data.getUint16(offset + 8);
          final size = data.getUint16(offset + 10);
          for (var j = 0; j < count; j++) {
            final axis = start + j * size;
            final tag = String.fromCharCodes(
              List.generate(4, (k) => data.getUint8(axis + k)),
            );
            axes[tag] = (
              data.getInt32(axis + 4) / 65536,
              data.getInt32(axis + 12) / 65536,
            );
          }
        }
        expect(axes, contains('wght'));
        if (font == AppFontId.outfit) {
          expect(axes.keys, ['wght']);
        } else {
          expect(axes['opsz'], (
            font == AppFontId.googleSansFlex ? 6.0 : 8.0,
            144.0,
          ));
          for (final axis in AppTypography.variations(font, 22)) {
            expect(axes, contains(axis.axis));
            expect(
              axis.value,
              inInclusiveRange(axes[axis.axis]!.$1, axes[axis.axis]!.$2),
            );
          }
        }
      }
    },
  );
}
