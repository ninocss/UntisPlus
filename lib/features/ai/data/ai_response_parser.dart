import 'dart:convert';

import '../domain/ai_models.dart';

AiSearchResult parseAiSearchResult({
  required String query,
  required String reply,
  required String emptyHeadline,
}) {
  final fallbackHeadline = reply.split(RegExp(r'[\n.!?]')).first.trim();
  final fallbackSummary = reply.trim().isEmpty ? query : reply.trim();

  try {
    final decoded = jsonDecode(_extractJsonCandidate(reply));
    if (decoded is Map<String, dynamic>) {
      final metrics = <AiMetric>[];
      final metricSource = decoded['metrics'] ?? decoded['stats'];
      if (metricSource is List) {
        for (final entry in metricSource.whereType<Map>()) {
          final metric = entry.cast<String, dynamic>();
          final label = _firstNonEmptyString(metric, const [
            'label',
            'name',
            'title',
          ]);
          final value = _firstNonEmptyString(metric, const [
            'value',
            'amount',
            'text',
          ]);
          if (label.isNotEmpty && value.isNotEmpty) {
            metrics.add(AiMetric(label: label, value: value));
          }
        }
      }

      final headline = _firstNonEmptyString(decoded, const [
        'headline',
        'title',
        'summaryTitle',
      ]);
      final summary = _firstNonEmptyString(decoded, const [
        'summary',
        'text',
        'result',
      ]);

      return AiSearchResult(
        query: query,
        headline: headline.isEmpty ? fallbackHeadline : headline,
        summary: summary.isEmpty ? fallbackSummary : summary,
        tags: _stringListFrom(decoded['tags']).take(6).toList(growable: false),
        metrics: metrics,
        lessons: _lessonsFromParsedPayload(decoded),
        rawReply: reply,
      );
    }
  } catch (_) {
    // Plain-text model responses remain valid assistant results.
  }

  return AiSearchResult(
    query: query,
    headline: fallbackHeadline.isEmpty ? emptyHeadline : fallbackHeadline,
    summary: fallbackSummary,
    tags: const [],
    metrics: const [],
    lessons: const [],
    rawReply: reply,
  );
}

List<AiProposedAction> parseUntisActions(String reply) {
  final actions = <AiProposedAction>[];
  final blocks = RegExp(
    r'```untis-action\s*([\s\S]*?)```',
    multiLine: true,
  ).allMatches(reply);
  for (final block in blocks) {
    try {
      final decoded = jsonDecode(block.group(1)!.trim());
      final values = decoded is List ? decoded : [decoded];
      for (final value in values.whereType<Map>()) {
        final action = AiProposedAction(Map<String, dynamic>.from(value));
        if (action.isSupported) actions.add(action);
      }
    } catch (_) {
      // Malformed action blocks are displayed as text and never executed.
    }
  }
  return actions;
}

String _extractJsonCandidate(String reply) {
  final trimmed = reply.trim();
  final fenced = RegExp(
    r'```(?:json)?\s*([\s\S]*?)```',
    caseSensitive: false,
  ).firstMatch(trimmed)?.group(1)?.trim();
  if (fenced != null && fenced.isNotEmpty) return fenced;

  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start >= 0 && end > start) {
    return trimmed.substring(start, end + 1).trim();
  }
  return trimmed;
}

String _firstNonEmptyString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

List<String> _stringListFrom(dynamic value) {
  if (value is List) {
    return value
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) return [value.trim()];
  return const [];
}

List<AiLessonCardData> _lessonsFromParsedPayload(Map<String, dynamic> data) {
  final rawLessons = data['lessons'] ?? data['stunden'] ?? data['items'];
  if (rawLessons is! List) return const [];

  return rawLessons
      .whereType<Map>()
      .map((rawLesson) {
        final lesson = rawLesson.cast<String, dynamic>();
        final time = _firstNonEmptyString(lesson, const [
          'time',
          'slot',
          'range',
          'period',
        ]);
        final subject = _firstNonEmptyString(lesson, const [
          'subject',
          'title',
          'name',
        ]);
        final subjectShort = _firstNonEmptyString(lesson, const [
          'subjectShort',
          'short',
          'abbr',
        ]);
        final room = _firstNonEmptyString(lesson, const [
          'room',
          'raum',
          'location',
        ]);
        final teacher = _firstNonEmptyString(lesson, const [
          'teacher',
          'lehrer',
          'person',
        ]);
        final status = _firstNonEmptyString(lesson, const ['status', 'state']);
        return AiLessonCardData(
          subject: subject.isEmpty
              ? (subjectShort.isEmpty ? '?' : subjectShort)
              : subject,
          subjectShort: subjectShort,
          room: room,
          teacher: teacher,
          time: time.isEmpty ? '—' : time,
          isCancelled:
              status.toLowerCase().contains('cancel') ||
              status.toLowerCase().contains('ausfall'),
        );
      })
      .where(
        (lesson) =>
            lesson.subject.isNotEmpty ||
            lesson.room.isNotEmpty ||
            lesson.teacher.isNotEmpty,
      )
      .toList(growable: false);
}
