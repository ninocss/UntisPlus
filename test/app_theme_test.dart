import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';
import 'package:untisplus/services/backup_service.dart';

void main() {
  group('AppL10n', () {
    test('localizes the AI chat surface in every supported locale', () {
      final expectedTitles = <String, String>{
        'de': 'Dein KI-Chat',
        'en': 'Your AI chat',
        'fr': 'Ton chat IA',
        'es': 'Tu chat con IA',
      };

      for (final locale in AppL10n.supportedLocales) {
        final l = AppL10n.of(locale);
        expect(l.aiChatTitle, expectedTitles[locale]);
        expect(l.aiTyping, isNotEmpty);
        expect(l.aiChatSubtitle, isNotEmpty);
        expect(l.aiTryIt, isNotEmpty);
        expect(l.aiChatSuggestions, hasLength(3));
        expect(l.aiChatSuggestions.every((value) => value.isNotEmpty), isTrue);
      }
    });

    test('interpolates timetable and alarm labels without leaking tokens', () {
      for (final locale in AppL10n.supportedLocales) {
        final l = AppL10n.of(locale);
        final timetableError = l.timetableHttpError(503);
        final lesson = l.aiNextLessonSummary('Math', '204', '09:45');
        final alarm = l
            .ui('alarmAt')
            .replaceAll('{label}', l.ui('alarmSchedule'))
            .replaceAll('{time}', '07:15');

        expect(timetableError, contains('503'));
        expect(lesson, contains('Math'));
        expect(lesson, contains('204'));
        expect(lesson, contains('09:45'));
        expect(
          '$timetableError$lesson$alarm',
          isNot(contains(RegExp(r'\{\w+\}'))),
        );
      }
    });
  });

  test('theme ids are stable and unknown ids fall back to default', () {
    for (final theme in AppThemeId.values) {
      expect(AppThemeIdX.fromStorage(theme.storageKey), theme);
    }
    expect(AppThemeIdX.fromStorage('future-theme'), AppThemeId.defaultTheme);
    expect(AppThemeIdX.fromStorage(null), AppThemeId.defaultTheme);
  });

  test('blur and customization capability matrix stays intentional', () {
    expect(appThemeCapabilities(AppThemeId.defaultTheme).supportsBlur, isTrue);
    expect(appThemeCapabilities(AppThemeId.vivid).supportsBlur, isTrue);
    expect(appThemeCapabilities(AppThemeId.glass).supportsBlur, isTrue);
    expect(appThemeCapabilities(AppThemeId.cyber).supportsBlur, isTrue);
    expect(appThemeCapabilities(AppThemeId.manga).supportsBlur, isFalse);
    expect(appThemeCapabilities(AppThemeId.paper).supportsBlur, isFalse);
    expect(
      appThemeCapabilities(AppThemeId.defaultTheme).supportsAdvancedLessonStyle,
      isTrue,
    );
    expect(
      appThemeCapabilities(AppThemeId.glass).supportsAdvancedLessonStyle,
      isFalse,
    );
    expect(
      appThemeCapabilities(
        AppThemeId.defaultTheme,
      ).supportsExpressiveComponents,
      isTrue,
    );
    expect(
      appThemeCapabilities(AppThemeId.vivid).supportsExpressiveComponents,
      isTrue,
    );
    for (final theme in [
      AppThemeId.manga,
      AppThemeId.glass,
      AppThemeId.cyber,
      AppThemeId.paper,
    ]) {
      expect(appThemeCapabilities(theme).supportsExpressiveComponents, isFalse);
    }
  });

  test('glow effects default to disabled', () {
    expect(glowEffectsEnabledNotifier.value, isFalse);
  });

  testWidgets('Default and Vivid opt into native expressive controls', (
    tester,
  ) async {
    Future<ThemeData> pumpTheme(AppThemeId theme) async {
      visualThemeNotifier.value = theme;
      themeModeNotifier.value = ThemeMode.light;
      useMaterialYouNotifier.value = false;
      isAmoledNotifier.value = false;
      blurEnabledNotifier.value = false;
      glowEffectsEnabledNotifier.value = false;
      await tester.pumpWidget(
        const UntisPlusApp(startScreen: SizedBox.shrink()),
      );
      await tester.pump();
      return tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
    }

    for (final themeId in [AppThemeId.defaultTheme, AppThemeId.vivid]) {
      final theme = await pumpTheme(themeId);
      // ignore: deprecated_member_use
      expect(theme.sliderTheme.year2023, isFalse);
      // ignore: deprecated_member_use
      expect(theme.progressIndicatorTheme.year2023, isFalse);
      expect(
        theme.filledButtonTheme.style!.shape!.resolve({}),
        isA<StadiumBorder>(),
      );
      expect(
        theme.filledButtonTheme.style!.shape!.resolve({WidgetState.pressed}),
        isA<RoundedRectangleBorder>(),
      );
    }

    final manga = await pumpTheme(AppThemeId.manga);
    // ignore: deprecated_member_use
    expect(manga.sliderTheme.year2023, isTrue);
    // ignore: deprecated_member_use
    expect(manga.progressIndicatorTheme.year2023, isTrue);
  });

  test('every theme builds distinct light and dark schemes and tokens', () {
    for (final theme in AppThemeId.values) {
      final light = untisThemeScheme(theme, Brightness.light, 0xFF0F766E);
      final dark = untisThemeScheme(theme, Brightness.dark, 0xFF0F766E);
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.surface, isNot(dark.surface));
      expect(
        UntisThemeTokens.forTheme(theme, Brightness.light, light).id,
        theme,
      );
    }
  });

  test('redesigned themes keep distinct surface and navigation semantics', () {
    for (final theme in [
      AppThemeId.vivid,
      AppThemeId.glass,
      AppThemeId.cyber,
      AppThemeId.paper,
    ]) {
      final scheme = untisThemeScheme(theme, Brightness.dark, 0xFF0F766E);
      final tokens = UntisThemeTokens.forTheme(theme, Brightness.dark, scheme);
      expect(tokens.surfaceOpacity, inInclusiveRange(0.45, 1.0));
      expect(tokens.navigationOpacity, inInclusiveRange(0.45, 1.0));
      expect(tokens.lessonSurfaceOpacity, inInclusiveRange(0.55, 1.0));
    }

    final vivid = untisThemeScheme(
      AppThemeId.vivid,
      Brightness.dark,
      0xFF0F766E,
    );
    expect(vivid.surface, const Color(0xFF100C1D));

    final glassScheme = untisThemeScheme(
      AppThemeId.glass,
      Brightness.light,
      0xFF0F766E,
    );
    final glass = UntisThemeTokens.forTheme(
      AppThemeId.glass,
      Brightness.light,
      glassScheme,
    );
    expect(glass.surfaceOpacity, lessThan(0.6));
    expect(glass.navigationOpacity, lessThan(0.6));

    final paper = appThemeCapabilities(AppThemeId.paper);
    expect(paper.supportsBlur, isFalse);
    expect(paper.supportsBackgroundMotion, isFalse);
  });

  test('Cyber and Paper use theme-specific display typography', () {
    final cyber = untisThemeTextTheme(AppThemeId.cyber, Brightness.dark);
    final paper = untisThemeTextTheme(AppThemeId.paper, Brightness.light);

    expect(cyber.titleLarge?.fontFamily, contains('IBM Plex Mono'));
    expect(cyber.bodyMedium?.fontFamily, contains('Outfit'));
    expect(paper.titleLarge?.fontFamily, contains('Noto Serif'));
    expect(paper.bodyMedium?.fontFamily, contains('Noto Sans'));
  });

  test(
    'backup round-trips visual theme and per-theme blur preferences',
    () async {
      SharedPreferences.setMockInitialValues({
        'visualTheme': 'cyber',
        'themeBlurPreferences': jsonEncode({
          'default': true,
          'vivid': false,
          'glass': true,
          'cyber': false,
        }),
        'glowEffectsEnabled': true,
      });
      final service = BackupService();
      final exported = await service.exportAllToJsonText();

      SharedPreferences.setMockInitialValues({});
      await service.importAllFromJsonText(exported);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('visualTheme'), 'cyber');
      expect(
        jsonDecode(prefs.getString('themeBlurPreferences')!)['cyber'],
        isFalse,
      );
      expect(prefs.getBool('glowEffectsEnabled'), isTrue);
    },
  );
}
