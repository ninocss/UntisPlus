import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsStore.initialize(
      preferences: await SharedPreferences.getInstance(),
    );
    appLocaleNotifier.value = 'de';
  });

  testWidgets('AiCopilotStep renders provider options and local model card', (
    tester,
  ) async {
    var nextTapped = false;
    var skipTapped = false;
    String? selectedProvider;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AiCopilotStep(
                initialProvider: 'local',
                initialModel: 'gemma-2-2b-it-Q4_K_M.gguf',
                initialCustomCompatibility: 'openai',
                initialApiKeys: const {},
                initialCustomBaseUrl: '',
                onSave: (config) {
                  selectedProvider = config['provider'] as String?;
                },
                onNext: () => nextTapped = true,
                onSkip: () => skipTapped = true,
              );
            },
          ),
        ),
      ),
    );

    // Headline exists
    expect(find.text('KI-Assistent'), findsOneWidget);

    // Local model card elements (tested by regression test too)
    expect(find.text('Lokales Modell'), findsWidgets);
    expect(find.text('Herunterladen'), findsOneWidget);

    // Tap next
    await tester.tap(find.text('Weiter'));
    expect(nextTapped, isTrue);

    // Tap skip
    await tester.tap(find.text('Ohne KI fortfahren'));
    expect(skipTapped, isTrue);
  });
}
