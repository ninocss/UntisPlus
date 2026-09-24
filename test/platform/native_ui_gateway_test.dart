import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/platform/native_ui_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('untisplus/ui-test');
  const gateway = NativeUiGateway(channel: channel);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    lastDeliveredAssistantPrompt = null;
  });

  test('installApk keeps the native method and payload stable', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return 'opened';
        });

    expect(await gateway.installApk('C:/Downloads/untis.apk'), 'opened');
    expect(received?.method, 'installApk');
    expect(received?.arguments, {'path': 'C:/Downloads/untis.apk'});
  });

  test('assistant callback normalizes an empty native prompt', () async {
    String? received = 'not-called';
    gateway.registerAssistantOpenHandler((prompt) => received = prompt);

    final completer = Completer<ByteData?>();
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('openAssistant', '  '),
          ),
          completer.complete,
        );
    await completer.future;

    expect(received, isNull);
  });

  test('assistant callback strips quotes and feature markers', () async {
    String? received = 'not-called';
    gateway.registerAssistantOpenHandler((prompt) => received = prompt);

    Future<void> deliver(String payload) async {
      final completer = Completer<ByteData?>();
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channel.name,
            const StandardMethodCodec().encodeMethodCall(
              MethodCall('openAssistant', payload),
            ),
            completer.complete,
          );
      await completer.future;
    }

    await deliver(' "was habe ich morgen?" ');
    expect(received, 'was habe ich morgen?');

    await deliver('feature=ask about upcoming exams');
    expect(received, 'ask about upcoming exams');

    // A matched App Actions inventory id opens the feature without a prompt.
    await deliver('ai_assistant');
    expect(received, isNull);
  });

  test('replays a pending prompt that arrived before handler registration',
      () async {
    String? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getPendingAssistantPrompt') {
            return 'when is my next lesson?';
          }
          return null;
        });

    gateway.registerAssistantOpenHandler((prompt) => received = prompt);
    await pumpEventQueue();

    expect(received, 'when is my next lesson?');
  });

  test('pending replay is skipped when the channel is unavailable', () async {
    String? received = 'not-called';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'missing_plugin');
        });

    gateway.registerAssistantOpenHandler((prompt) => received = prompt);
    await pumpEventQueue();

    expect(received, 'not-called');
  });

  test('normalizedAssistantPrompt cleans spoken payloads', () {
    expect(
      normalizedAssistantPrompt('when is math?'),
      'when is math?',
    );
    expect(
      normalizedAssistantPrompt(' "was habe ich morgen?" '),
      'was habe ich morgen?',
    );
    expect(normalizedAssistantPrompt("'show me today'"), 'show me today');
    expect(
      normalizedAssistantPrompt('feature=ask about exams'),
      'ask about exams',
    );
    expect(normalizedAssistantPrompt('feature='), isNull);
    expect(normalizedAssistantPrompt('ai_assistant'), isNull);
    expect(normalizedAssistantPrompt('AI_ASSISTANT'), isNull);
    expect(normalizedAssistantPrompt('   '), isNull);
    expect(normalizedAssistantPrompt(''), isNull);
    expect(normalizedAssistantPrompt(null), isNull);
  });
}