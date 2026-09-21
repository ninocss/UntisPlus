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

    expect(
      await decodeSseDataEvents(Stream.fromIterable(chunks)).toList(),
      [
        '{"choices":[{"delta":{"content":"Hallo"}}]}',
        '[DONE]',
      ],
    );
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
  });
}
