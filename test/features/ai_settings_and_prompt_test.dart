import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/features/ai/application/ai_request_coordinator.dart';
import 'package:untisplus/features/ai/data/remote_ai_provider.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SettingsStore.initialize(preferences: prefs);
    appLocaleNotifier.value = 'de';
    demoModeNotifier.value = true;
    backgroundAnimationsNotifier.value = false;
    aiProvider = 'gemini';
    aiModel = 'gemini-3.6-flash';
    aiCustomModel = '';
    aiCustomInstructions = '';
    aiShareGrades = false;
    aiEnabledNotifier.value = true;
  });

  group('Custom provider and bug fixes', () {
    test('localized provider label never returns Gemini for custom', () {
      for (final lang in ['de', 'en', 'es', 'fr']) {
        final l = appL10nFor(lang);
        final customLabel = localizedAiProviderLabel(l, 'custom');
        final geminiLabel = localizedAiProviderLabel(l, 'gemini');

        expect(customLabel, equals(l.settingsAiProviderCustom));
        expect(customLabel, isNot(equals(geminiLabel)));
      }
    });

    test('custom provider preserves arbitrary model names without reset', () async {
      final prefs = SettingsStore.instance.preferences;
      await prefs.setString('aiProvider', 'custom');
      await prefs.setString('aiCustomModel', 'deepseek-r1-distill-llama-70b');
      await prefs.setString('aiModel', 'deepseek-r1-distill-llama-70b');

      await loadAiPreferences(prefs);

      expect(aiProvider, equals('custom'));
      expect(aiCustomModel, equals('deepseek-r1-distill-llama-70b'));
      expect(aiModel, equals('deepseek-r1-distill-llama-70b'));
    });

    test('request coordinator requires model for custom provider', () {
      final coordinator = AiRequestCoordinator(isEnabled: () => true);
      final runtime = AiRuntimeConfiguration(
        provider: 'custom',
        apiKey: 'test-key',
        customBaseUrl: 'https://custom.endpoint/v1',
        customCompatibility: 'openai',
        model: '',
        localModelPath: '',
        generationSettings: const AiGenerationSettings(
          temperature: 0.2,
          maxTokens: 512,
          topP: 0.95,
          formatAttachmentText: _defaultFormatAttachment,
          formatUnsupportedAttachment: _defaultFormatUnsupported,
        ),
        providerFactory: (_, _) => throw UnimplementedError(),
        defaultModelResolver: (_, _) => '',
      );

      expect(
        () => coordinator.resolve(
          runtime,
          const AiRequestSpec(
            systemPrompt: 'prompt',
            userPrompt: 'query',
            noReplyMessage: 'no reply',
            customModelMissingMessage: 'Custom model name missing',
          ),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('CONFIG: Custom model name missing'),
          ),
        ),
      );
    });
  });

  group('Prompt template improvements', () {
    test('default template contains no duplicate raw JSON', () {
      final l = appL10nFor('de');
      final template = buildDefaultAiPromptTemplate(l);

      expect(template, isNot(contains('[timetable_json]')));
      expect(template, isNot(contains('[exams_json]')));
      expect(template, contains(l.aiPromptRole));
      expect(template, contains('[timetable]'));
      expect(template, contains('[homework]'));
    });

    test('compact mode for local models omits heavy weekly tables', () {
      final l = appL10nFor('de');
      final compact = buildDefaultAiPromptTemplate(l, compact: true);

      expect(compact, isNot(contains('[timetable]')));
      expect(compact, isNot(contains('[homework]')));
      expect(compact, isNot(contains('[grades_summary]')));
      expect(compact, contains(l.aiPromptHdrToday));
      expect(compact, contains(l.aiPromptHdrTomorrow));
      expect(compact, contains(l.aiPromptHdrExams));
    });

    test('local AI prompt template retains schedule while omitting heavy grades', () {
      final l = appL10nFor('de');
      final localPrompt = buildLocalAiPromptTemplate(l);

      expect(localPrompt, contains('[timetable]'));
      expect(localPrompt, contains('[homework]'));
      expect(localPrompt, contains('[exams]'));
      expect(localPrompt, contains(l.aiPromptHdrToday));
      expect(localPrompt, contains(l.aiPromptHdrTomorrow));
      expect(localPrompt, isNot(contains('[grades_summary]')));
      expect(localPrompt, isNot(contains('[next_free_day]')));
    });

    test('local chat prompt suffix is concise and includes untis-action', () {
      final l = appL10nFor('de');
      aiCustomInstructions = 'Kurze Sätze.';

      final suffix = localChatPromptSuffix(l);

      expect(suffix, contains(l.aiAssistantIntro));
      expect(suffix, contains('untis-action'));
      expect(suffix, contains(l.aiPromptCustomInstructionsHeader));
      expect(suffix, contains('Kurze Sätze.'));
      expect(suffix.length, lessThan(chatPromptSuffix(l).length));
    });

    test('chat prompt suffix appends custom instructions cleanly', () {
      final l = appL10nFor('de');
      aiCustomInstructions = 'Antworte stets in Reimen.';

      final suffix = chatPromptSuffix(l);

      expect(suffix, contains(l.aiAssistantIntro));
      expect(suffix, contains(l.aiAssistantRules));
      expect(suffix, contains(l.aiPromptCustomInstructionsHeader));
      expect(suffix, contains('Antworte stets in Reimen.'));
    });

    test('grade formatting respects share grades toggle', () {
      final l = appL10nFor('de');
      aiShareGrades = false;
      expect(formatGradesForAi(l), equals(l.aiPromptGradesHidden));

      aiShareGrades = true;
      customGradesNotifier.value = [
        {
          'subject': 'Mathe',
          'value': 2.0,
          'weight': 1.0,
          'date': '2026-11-01',
        },
        {
          'subject': 'Mathe',
          'value': 1.0,
          'weight': 1.0,
          'date': '2026-11-02',
        },
      ];
      final formatted = formatGradesForAi(l);
      expect(formatted, contains('Mathe'));
      expect(formatted, contains('1.50'));
    });
  });

  group('SettingsAiPage UI redesign', () {
    testWidgets('renders clean hero card and provider tile', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final l = appL10nFor('de');

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsAiPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final initialError = tester.takeException();
      if (initialError != null) {
        fail('Initial overflow on page load: $initialError');
      }

      // Hero card title exists
      expect(find.text(l.settingsSectionAI), findsWidgets);
      // Master switch exists
      expect(find.byType(Switch), findsWidgets);

      // Provider tile exists in Connection section
      expect(find.text(l.settingsAiProvider), findsOneWidget);
      expect(find.text(l.settingsAiProviderGemini), findsWidgets);

      // Custom instructions tile
      expect(find.text(l.settingsAiInstructions), findsOneWidget);

      // Privacy section
      expect(find.text(l.settingsAiShareGrades), findsOneWidget);
    });

    testWidgets('switching to custom provider via provider sheet displays custom fields', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final l = appL10nFor('de');

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsAiPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final initialError = tester.takeException();
      if (initialError != null) {
        fail('Initial overflow on page load: $initialError');
      }

      // Tap on the Provider tile to open sheet
      final providerTile = find.text(l.settingsAiProvider);
      expect(providerTile, findsOneWidget);
      await tester.tap(providerTile);
      await tester.pumpAndSettle();

      // Custom provider option is in the sheet
      final customOption = find.text(l.settingsAiProviderCustom);
      expect(customOption, findsOneWidget);
      await tester.tap(customOption);
      await tester.pumpAndSettle();

      // Custom-specific tiles should now be visible
      expect(find.text(l.settingsAiCustomBaseUrl), findsOneWidget);
      expect(find.text(l.settingsAiCustomModel), findsOneWidget);
      expect(find.text(l.settingsAiCompatibility), findsOneWidget);
    });

    test('remaining download time calculation and formatting', () {
      final l = appL10nFor('de');

      // Zero speed or complete -> null remaining time
      const stateZero = LocalModelDownloadState(
        phase: LocalModelDownloadPhase.downloading,
        received: 100,
        total: 1000,
        bytesPerSecond: 0,
      );
      expect(stateZero.estimatedRemainingTime, isNull);

      const stateDone = LocalModelDownloadState(
        phase: LocalModelDownloadPhase.completed,
        received: 1000,
        total: 1000,
        bytesPerSecond: 500,
      );
      expect(stateDone.estimatedRemainingTime, isNull);

      // 400 MB remaining at 10 MB/s -> 40 seconds
      const state40s = LocalModelDownloadState(
        phase: LocalModelDownloadPhase.downloading,
        received: 600 * 1024 * 1024,
        total: 1000 * 1024 * 1024,
        bytesPerSecond: 10 * 1024 * 1024,
      );
      expect(state40s.estimatedRemainingTime?.inSeconds, equals(40));
      expect(formatModelRemainingTime(state40s.estimatedRemainingTime, l), equals('Noch ca. 40s'));

      // 125 seconds -> 2m 5s
      const state125s = LocalModelDownloadState(
        phase: LocalModelDownloadPhase.downloading,
        received: 0,
        total: 1250,
        bytesPerSecond: 10,
      );
      expect(state125s.estimatedRemainingTime?.inSeconds, equals(125));
      expect(formatModelRemainingTime(state125s.estimatedRemainingTime, l), equals('Noch ca. 2m 5s'));
    });

    testWidgets('advanced prompt sheet opens without overflow on phone size (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final l = appL10nFor('de');

      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsAiPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final initialError = tester.takeException();
      if (initialError != null) {
        // print where the initial error came from!
        fail('Initial overflow on page load: $initialError');
      }

      // Scroll down to the Advanced Prompt tile
      final promptTile = find.text(l.settingsAiPromptAdvanced);
      await tester.ensureVisible(promptTile);
      await tester.pumpAndSettle();
      expect(promptTile, findsOneWidget);

      // Open the Advanced Prompt sheet
      FlutterErrorDetails? overflowDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        overflowDetails = details;
      };
      await tester.tap(promptTile);
      await tester.pumpAndSettle();
      FlutterError.onError = originalOnError;

      if (overflowDetails != null) {
        // ignore: avoid_print
        print('OVERFLOW SUMMARY: ${overflowDetails?.summary}');
        // ignore: avoid_print
        print('INFO: ${overflowDetails?.informationCollector?.call().map((d) => d.toString()).join("\n")}');
      }

      // Verify the sheet opened with reset and save buttons and no RenderFlex overflow
      expect(find.text(l.settingsAiPromptReset), findsOneWidget);
      expect(find.text(l.save), findsOneWidget);
      expect(overflowDetails, isNull);
    });
  });
}

String _defaultFormatAttachment(AiChatAttachment a) => a.textExcerpt;
String _defaultFormatUnsupported(AiChatAttachment a) => a.mimeType;
