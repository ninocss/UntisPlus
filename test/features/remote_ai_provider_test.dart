import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/ai/data/remote_ai_provider.dart';

void main() {
  test('SSE decoder preserves events split across network chunks', () async {
    final chunks = [
      utf8.encode('data: {"choices":[{"del'),
      utf8.encode('ta":{"content":"Hallo"}}]}\n'),
      utf8.encode('\ndata: [DONE]\n\n'),
    ];

    expect(await decodeSseDataEvents(Stream.fromIterable(chunks)).toList(), [
      '{"choices":[{"delta":{"content":"Hallo"}}]}',
      '[DONE]',
    ]);
  });

  test('SSE decoder accepts a non-streaming JSON response', () async {
    final body = utf8.encode('{"choices":[{"message":{"content":"Hi"}}]}');

    expect(
      await decodeSseDataEvents(Stream.value(body)).single,
      '{"choices":[{"message":{"content":"Hi"}}]}',
    );
  });

  test('compatible endpoint helpers normalize common base URLs', () {
    expect(
      openAiCompatibleEndpoint('https://example.test/v1/'),
      'https://example.test/v1/chat/completions',
    );
    expect(
      openAiCompatibleEndpoint('https://example.test/v1/chat'),
      'https://example.test/v1/chat/completions',
    );
    expect(
      geminiCompatibleEndpoint('https://example.test/v1beta/', 'school-ai'),
      'https://example.test/v1beta/models/school-ai:generateContent',
    );
    expect(
      geminiStreamingEndpoint('https://example.test/v1beta/', 'school-ai'),
      'https://example.test/v1beta/models/school-ai:streamGenerateContent',
    );
  });

  test('provider capabilities keep PDF support limited to Gemini', () {
    expect(AiProviderCapabilities.resolve(provider: 'gemini').pdf, isTrue);
    expect(
      AiProviderCapabilities.resolve(
        provider: 'custom',
        customCompatibility: 'gemini',
      ).pdf,
      isTrue,
    );
    expect(AiProviderCapabilities.resolve(provider: 'openai').pdf, isFalse);
    expect(AiProviderCapabilities.resolve(provider: 'local').images, isFalse);
  });

  test(
    'text generation joins chunks and always disposes the provider',
    () async {
      final provider = _FakeProvider(['Hallo', ' Welt']);

      final result = await const AiTextGenerationService().generate(
        provider: provider,
        systemPrompt: 'system',
        userPrompt: 'user',
        model: 'model',
        noReplyMessage: 'empty',
      );

      expect(result, 'Hallo Welt');
      expect(provider.disposed, isTrue);
    },
  );

  test('text generation rejects empty replies after disposing', () async {
    final provider = _FakeProvider(['  ']);

    await expectLater(
      const AiTextGenerationService().generate(
        provider: provider,
        systemPrompt: 'system',
        userPrompt: 'user',
        model: 'model',
        noReplyMessage: 'empty',
      ),
      throwsA(predicate((error) => error.toString().contains('API: empty'))),
    );
    expect(provider.disposed, isTrue);
  });
}

class _FakeProvider implements AIProvider {
  _FakeProvider(this.chunks);

  final List<String> chunks;
  bool disposed = false;

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Stream<String> streamResponse({
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String model,
    List<AiChatAttachment> attachments = const [],
  }) => Stream.fromIterable(chunks);
}
