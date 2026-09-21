import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/features/ai/data/ai_chat_history_store.dart';
import 'package:untisplus/features/ai/domain/ai_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads newest sessions first and skips malformed entries', () async {
    SharedPreferences.setMockInitialValues({
      aiChatHistoryStorageKey: jsonEncode([
        {
          'id': 'older',
          'title': 'Older',
          'messages': <Map<String, String>>[],
          'timestamp': '2026-09-20T08:00:00.000Z',
        },
        {'id': 'broken'},
        {
          'id': 'newer',
          'title': 'Newer',
          'messages': <Map<String, String>>[],
          'timestamp': '2026-09-21T08:00:00.000Z',
        },
      ]),
    });
    final store = AiChatHistoryStore(await SharedPreferences.getInstance());

    final sessions = store.read();

    expect(sessions.map((session) => session.id), ['newer', 'older']);
  });

  test('writes the existing storage key and round-trips messages', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = AiChatHistoryStore(preferences);
    final session = AiChatSession(
      id: 'chat-1',
      title: 'School day',
      messages: const [
        {'role': 'assistant', 'content': 'Your first lesson is Math.'},
      ],
      timestamp: DateTime.utc(2026, 9, 21),
    );

    expect(await store.write([session]), isTrue);
    expect(preferences.containsKey('aiChatHistory'), isTrue);
    expect(store.read().single.messages, session.messages);
  });

  test('returns an empty history for invalid top-level JSON', () async {
    SharedPreferences.setMockInitialValues({aiChatHistoryStorageKey: '{oops'});
    final store = AiChatHistoryStore(await SharedPreferences.getInstance());

    expect(store.read(), isEmpty);
  });
}
