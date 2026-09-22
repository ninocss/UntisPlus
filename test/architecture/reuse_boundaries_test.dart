import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'feature screens do not reintroduce provider-specific AI transports',
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
      ];

      for (final path in files) {
        final source = File(path).readAsStringSync();
        for (final symbol in forbidden) {
          expect(source, isNot(contains(symbol)), reason: '$path owns $symbol');
        }
      }
    },
  );

  test('screens do not initialize SharedPreferences directly', () {
    final screenFiles = Directory('lib/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in screenFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains('SharedPreferences.getInstance()')),
        reason: '${file.path} initializes preferences directly',
      );
    }
  });

  test('native channel names stay centralized', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      if (file.path.endsWith('native_channel_names.dart')) continue;
      expect(
        file.readAsStringSync(),
        isNot(contains("MethodChannel('untisplus/")),
        reason: '${file.path} declares a native channel inline',
      );
    }
  });
}
