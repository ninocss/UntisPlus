import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(String root) => Directory(root)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

String _normalizedPath(File file) => file.path.replaceAll('\\', '/');

void main() {
  test(
    'feature screens do not reintroduce provider-specific AI configuration',
    () {
      const files = [
        'lib/screens/main_navigation_screen.dart',
        'lib/screens/custom_background_editor_screen.dart',
        'lib/screens/exams_page.dart',
        'lib/screens/homework_page.dart',
      ];
      const forbidden = [
        '_requestGeminiText',
        '_requestOpenAiCompatibleText',
        '_extractOpenAiCompatibleText',
        '_geminiCompatibleEndpointForExamImport',
        '_openAiCompatibleEndpointForExamImport',
        '_providerUsesGeminiProtocolGlobal',
        'createAIProvider(',
        'AiProviderConfiguration(',
        'AiProviderCapabilities.resolve(',
        '_activeAiApiKey',
      ];

      for (final path in files) {
        final source = File(path).readAsStringSync();
        expect(source, contains('AiRequestSpec'));
        for (final symbol in forbidden) {
          expect(source, isNot(contains(symbol)), reason: '$path owns $symbol');
        }
      }
    },
  );

  test('screens do not initialize SharedPreferences directly', () {
    for (final file in _dartFiles('lib/screens')) {
      expect(
        file.readAsStringSync(),
        isNot(contains('SharedPreferences.getInstance()')),
        reason: '${file.path} initializes preferences directly',
      );
    }
  });

  test('screens do not own WebUntis transport details', () {
    const forbidden = [
      '/WebUntis/',
      'JSESSIONID=',
      'jsonrpc.do',
      'jsonrpc_intern.do',
      "'jsonrpc': '2.0'",
      '"jsonrpc": "2.0"',
    ];
    for (final file in _dartFiles('lib/screens')) {
      final source = file.readAsStringSync();
      for (final token in forbidden) {
        expect(
          source,
          isNot(contains(token)),
          reason: '${file.path} owns WebUntis transport token $token',
        );
      }
    }
  });

  test('UI files do not perform HTTP requests directly', () {
    for (final root in ['lib/screens', 'lib/widgets']) {
      for (final file in _dartFiles(root)) {
        final source = file.readAsStringSync();
        expect(
          source,
          isNot(contains("package:http/http.dart")),
          reason: '${file.path} imports the HTTP transport directly',
        );
        expect(
          RegExp(r'\bhttp\.(get|post|put|patch|delete)\s*\(').hasMatch(source),
          isFalse,
          reason: '${file.path} performs an HTTP request directly',
        );
      }
    }
  });

  test('application entry point does not own WebUntis login protocol', () {
    final source = File('lib/main.dart').readAsStringSync();
    for (final token in [
      'jsonrpc_intern.do',
      'getUserData2017',
      'JSESSIONID=',
      '_authenticateUntis',
    ]) {
      expect(
        source,
        isNot(contains(token)),
        reason: 'lib/main.dart owns login transport token $token',
      );
    }
  });

  test('legacy dynamic localization access stays removed', () {
    for (final file in _dartFiles('lib')) {
      if (_normalizedPath(file).contains('/l10n/generated/')) continue;
      final source = file.readAsStringSync();
      for (final token in ['.ui(', 'uiFormat(']) {
        expect(
          source,
          isNot(contains(token)),
          reason: '${file.path} uses legacy localization API $token',
        );
      }
    }
  });

  test('screens use time_utils for Untis date encoding and parsing', () {
    const forbidden = [
      "DateFormat('yyyyMMdd')",
      'DateFormat("yyyyMMdd")',
      '.substring(0, 4)',
      '.substring(4, 6)',
      '.substring(6, 8)',
    ];
    for (final file in _dartFiles('lib/screens')) {
      final source = file.readAsStringSync();
      for (final token in forbidden) {
        expect(
          source,
          isNot(contains(token)),
          reason: '${file.path} manually handles an Untis date with $token',
        );
      }
    }
  });

  test('school HTML sanitization has one implementation boundary', () {
    const helperPath = 'lib/features/school_info/application/school_html.dart';
    final helperSource = File(helperPath).readAsStringSync();
    expect(helperSource, contains('sanitizeSchoolHtml'));
    expect(helperSource, contains("querySelectorAll("));

    for (final file in _dartFiles('lib/screens')) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains('_safeInfoDocument')),
        reason: '${file.path} duplicates school HTML sanitization',
      );
      expect(
        source,
        isNot(contains('_detailSafeInfoDocument')),
        reason: '${file.path} duplicates detail HTML sanitization',
      );
      expect(
        source,
        isNot(contains("querySelectorAll(\n      'script, style, iframe")),
        reason: '${file.path} owns a sanitizer implementation',
      );
    }
  });

  test('ARB catalogs expose shared semantic actions and blur copy', () {
    const locales = ['de', 'en', 'fr', 'es'];
    const sharedKeys = ['save', 'cancel', 'delete', 'reload', 'apply'];
    const blurKeys = [
      'settingsAppBgBlur',
      'settingsAppBgBlurDesc',
      'settingsAppBgBlurAmount',
    ];
    const removedGenericDuplicates = [
      'examsSave',
      'homeworkSave',
      'alarmSave',
      'settingsApiKeySave',
      'alarmApply',
    ];

    for (final locale in locales) {
      final file = File('lib/l10n/arb/app_$locale.arb');
      final catalog =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in [...sharedKeys, ...blurKeys]) {
        expect(
          catalog[key],
          isA<String>().having((value) => value.trim(), 'value', isNotEmpty),
          reason: '$locale is missing semantic localization key $key',
        );
      }
      for (final key in removedGenericDuplicates) {
        expect(
          catalog.containsKey(key),
          isFalse,
          reason: '$locale still contains duplicate generic key $key',
        );
      }
    }
  });

  test('shared UI abstractions stay centralized', () {
    final sharedUi = File('lib/core/shared_ui.dart').readAsStringSync();
    for (final symbol in [
      'class FeatureSummaryCard',
      'class UntisSheetScaffold',
      'abstract final class LessonCardVisualsResolver',
      'class SettingsPageShell',
    ]) {
      expect(sharedUi, contains(symbol));
    }

    final allOtherSources = _dartFiles('lib')
        .where((file) => _normalizedPath(file) != 'lib/core/shared_ui.dart')
        .map((file) => file.readAsStringSync())
        .join('\n');
    expect(
      RegExp(r'class\s+FeatureSummaryCard\b').allMatches(allOtherSources),
      isEmpty,
    );
    expect(
      RegExp(r'class\s+UntisSheetScaffold\b').allMatches(allOtherSources),
      isEmpty,
    );
  });

  test('native channel names stay centralized', () {
    for (final file in _dartFiles('lib')) {
      if (_normalizedPath(file).endsWith('native_channel_names.dart')) {
        continue;
      }
      expect(
        file.readAsStringSync(),
        isNot(contains("MethodChannel('untisplus/")),
        reason: '${file.path} declares a native channel inline',
      );
    }
  });
}
