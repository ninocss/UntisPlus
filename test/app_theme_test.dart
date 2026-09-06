import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/main.dart';
import 'package:untisplus/services/backup_service.dart';

void main() {
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
    },
  );
}
