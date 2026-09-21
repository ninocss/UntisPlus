import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/ai/domain/ai_models.dart';
import 'package:untisplus/l10n.dart';

void main() {
  test('chat sessions keep their persisted JSON contract', () {
    final timestamp = DateTime.utc(2026, 9, 21, 12, 30);
    final session = AiChatSession(
      id: 'chat-1',
      title: 'Tomorrow',
      messages: const [
        {'role': 'user', 'content': 'What is next?'},
      ],
      timestamp: timestamp,
    );

    final restored = AiChatSession.fromJson(session.toJson());

    expect(restored.id, 'chat-1');
    expect(restored.title, 'Tomorrow');
    expect(restored.messages, session.messages);
    expect(restored.timestamp, timestamp);
  });

  test('proposed actions normalize numeric values and dates', () {
    const action = AiProposedAction({
      'kind': 'create_grade',
      'subject': 'Math',
      'grade': '1,7',
      'weight': '0,5',
      'date': '2026-09-22',
    });

    expect(action.isSupported, isTrue);
    expect(action.gradeValue, 1.7);
    expect(action.gradeWeight, 0.5);
    expect(action.date, 20260922);
    expect(action.summary(AppL10n.of('en')), isNotEmpty);
  });

  test('unknown actions are never applied silently', () {
    const action = AiProposedAction({'kind': 'change_timetable'});

    expect(action.isSupported, isFalse);
    expect(action.summary(AppL10n.of('de')), isNotEmpty);
  });
}
