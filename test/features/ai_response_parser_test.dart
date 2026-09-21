import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/ai/data/ai_response_parser.dart';

void main() {
  group('AI search response parser', () {
    test('reads fenced structured results and normalizes lesson aliases', () {
      final result = parseAiSearchResult(
        query: 'tomorrow',
        emptyHeadline: 'New search',
        reply: '''
```json
{
  "title": "Tuesday",
  "text": "Two lessons",
  "tags": ["schedule", "tomorrow"],
  "stats": [{"name": "Lessons", "amount": 2}],
  "stunden": [{
    "short": "M",
    "raum": "A12",
    "lehrer": "Ms Example",
    "slot": "08:00–08:45",
    "state": "Ausfall"
  }]
}
```
''',
      );

      expect(result.headline, 'Tuesday');
      expect(result.summary, 'Two lessons');
      expect(result.metrics.single.label, 'Lessons');
      expect(result.metrics.single.value, '2');
      expect(result.lessons.single.subject, 'M');
      expect(result.lessons.single.room, 'A12');
      expect(result.lessons.single.isCancelled, isTrue);
    });

    test('keeps plain-text answers as a readable fallback', () {
      final result = parseAiSearchResult(
        query: 'next lesson',
        reply: 'Math is next. Room A12.',
        emptyHeadline: 'New search',
      );

      expect(result.headline, 'Math is next');
      expect(result.summary, 'Math is next. Room A12.');
      expect(result.rawReply, 'Math is next. Room A12.');
    });

    test('uses localized empty headline for an empty reply', () {
      final result = parseAiSearchResult(
        query: 'today',
        reply: '',
        emptyHeadline: 'Neue Suche',
      );

      expect(result.headline, 'Neue Suche');
      expect(result.summary, 'today');
    });
  });

  group('Untis action parser', () {
    test('accepts supported single and list action blocks', () {
      final actions = parseUntisActions('''
```untis-action
{"kind":"create_homework","subject":"Math","text":"Page 4","date":"2026-09-22"}
```
```untis-action
[
  {"kind":"delete_exam","id":"exam-1"},
  {"kind":"change_timetable"}
]
```
''');

      expect(actions.map((action) => action.kind), [
        'create_homework',
        'delete_exam',
      ]);
    });

    test('ignores malformed action blocks instead of executing them', () {
      expect(parseUntisActions('```untis-action\n{oops}\n```'), isEmpty);
    });
  });
}
