part of '../../../main.dart';

String _formatWeekForAi(Map<int, List<dynamic>> weekData, DateTime monday) {
  final l = appL10nFor(appLocaleNotifier.value);
  final days = l.weekDayFull;
  final buf = StringBuffer();
  for (int i = 0; i < 5; i++) {
    final date = monday.add(Duration(days: i));
    final dateStr = DateFormat('dd.MM.yyyy').format(date);
    final lessons = weekData[i] ?? [];
    buf.writeln('${days[i]}, $dateStr:');
    if (lessons.isEmpty) {
      buf.writeln('  ${l.noLesson}');
    } else {
      for (final lsn in lessons) {
        final start = formatUntisTime(lsn['startTime'].toString());
        final end = formatUntisTime(lsn['endTime'].toString());
        final subj = lsn['_subjectLong']?.toString().isNotEmpty == true
            ? lsn['_subjectLong'].toString()
            : lsn['_subjectShort']?.toString() ?? '?';
        final room = lsn['_room']?.toString() ?? '';
        final teacher = lsn['_teacher']?.toString() ?? '';
        final cancelled = (lsn['code'] ?? '') == 'cancelled';
        buf.write('  $start–$end: $subj');
        if (room.isNotEmpty) buf.write(' | ${l.detailRoom} $room');
        if (teacher.isNotEmpty) buf.write(' | $teacher');
        if (cancelled) buf.write(' [${l.detailCancelled}]');
        buf.writeln();
      }
    }
    buf.writeln();
  }
  return buf.toString();
}

/// The built-in prompt used before the structured prompt. Kept only so that a
/// stored copy of it can be recognised and reset by the settings migration.
String _legacyDefaultAiPromptTemplate(AppL10n l) {
  return '''${l.aiSystemPersona}
Heute: [today]
Heute (ISO): [today_iso]
Sprache: [locale]
Schule: [school_name]
Server: [school_url]
Demo-Modus: [demo_mode]
Personentyp: [person_type]
Personen-ID: [person_id]
Wochenbereich: [current_monday] bis [current_friday]

HEUTE:
[day_summary_today]

MORGEN:
[day_summary_tomorrow]

STUNDENPLAN DIESE WOCHE:
[timetable]

PRUEFUNGEN:
[exams]

ROHDATEN STUNDENPLAN (JSON):
[timetable_json]

ROHDATEN PRUEFUNGEN (JSON):
[exams_json]

${l.aiSystemRules}

${l.aiResponseFormat}''';
}

/// Built-in assistant prompt. It is compact, localized and free of the raw JSON
/// duplicates the previous version carried. [compact] drops the weekly
/// timetable, homework and grades so that small on-device models keep room for
/// the question.
String _buildDefaultAiPromptTemplate(AppL10n l, {bool compact = false}) {
  final buffer = StringBuffer()
    ..writeln(l.aiPromptRole)
    ..writeln('${l.aiPromptLblToday}: [today] ([today_iso])')
    ..writeln('${l.aiPromptLblSchool}: [school_name]')
    ..writeln('${l.aiPromptLblNow}: [current_lesson] | [next_lesson]');
  if (!compact) {
    buffer.writeln('${l.aiPromptLblNextFree}: [next_free_day]');
  }
  buffer
    ..writeln()
    ..writeln('${l.aiPromptHdrToday}:')
    ..writeln('[day_summary_today]')
    ..writeln()
    ..writeln('${l.aiPromptHdrTomorrow}:')
    ..writeln('[day_summary_tomorrow]');
  if (!compact) {
    buffer
      ..writeln()
      ..writeln('${l.aiPromptHdrWeek} ([current_monday] - [current_friday]):')
      ..writeln('[timetable]');
  }
  buffer
    ..writeln()
    ..writeln('${l.aiPromptHdrExams}:')
    ..writeln('[exams]');
  if (!compact) {
    buffer
      ..writeln()
      ..writeln('${l.aiPromptHdrHomework}:')
      ..writeln('[homework]')
      ..writeln()
      ..writeln('${l.aiPromptHdrGrades}:')
      ..writeln('[grades_summary]');
  }
  buffer
    ..writeln()
    ..write(l.aiSystemRules);
  return buffer.toString();
}

/// Text the app always appends after the editable prompt: custom user
/// instructions are placed last, below the assistant rules, so they can adjust
/// tone without being able to break the action protocol.
String _chatPromptSuffix(AppL10n l) {
  final instructions = aiCustomInstructions.trim();
  final buffer = StringBuffer()
    ..writeln(l.aiAssistantIntro)
    ..write(l.aiAssistantRules);
  if (instructions.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln()
      ..writeln(l.aiPromptCustomInstructionsHeader)
      ..write(instructions);
  }
  return buffer.toString();
}

/// Compact prompt template optimized for on-device models. Preserves the full
/// week timetable, homework and exams while dropping heavy optional grade tables
/// to maximize prompt budget.
String _buildLocalAiPromptTemplate(AppL10n l) {
  final buffer = StringBuffer()
    ..writeln(l.aiPromptRole)
    ..writeln('${l.aiPromptLblToday}: [today] ([today_iso])')
    ..writeln('${l.aiPromptLblSchool}: [school_name]')
    ..writeln('${l.aiPromptLblNow}: [current_lesson] | [next_lesson]')
    ..writeln()
    ..writeln('${l.aiPromptHdrToday}:')
    ..writeln('[day_summary_today]')
    ..writeln()
    ..writeln('${l.aiPromptHdrTomorrow}:')
    ..writeln('[day_summary_tomorrow]')
    ..writeln()
    ..writeln('${l.aiPromptHdrWeek} ([current_monday] - [current_friday]):')
    ..writeln('[timetable]')
    ..writeln()
    ..writeln('${l.aiPromptHdrExams}:')
    ..writeln('[exams]')
    ..writeln()
    ..writeln('${l.aiPromptHdrHomework}:')
    ..writeln('[homework]')
    ..writeln()
    ..write(l.aiSystemRules);
  return buffer.toString();
}

/// Concise assistant instructions for on-device inference, saving ~200 tokens
/// compared to the verbose remote prompt suffix.
String _localChatPromptSuffix(AppL10n l) {
  final instructions = aiCustomInstructions.trim();
  final buffer = StringBuffer()
    ..writeln(l.aiAssistantIntro)
    ..writeln(
      'Antworte direkt auf Deutsch, präzise und freundlich mit Markdown. '
      'Bei gewünschten Änderungen nutze am Ende ```untis-action {"kind":"create_homework|update_homework|delete_homework|complete_homework|create_exam|update_exam|delete_exam|create_grade|update_grade|delete_grade","id":"optional","subject":"Fach","text":"Text","dueDate":"YYYYMMDD"}```.',
    );
  if (instructions.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln(l.aiPromptCustomInstructionsHeader)
      ..write(instructions);
  }
  return buffer.toString();
}

/// Per-subject weighted grade average, or a localized hint when the user did
/// not allow sharing grades with the AI.
String _formatGradesForAi(AppL10n l) {
  if (!aiShareGrades) return l.aiPromptGradesHidden;
  final sums = <String, double>{};
  final weights = <String, double>{};
  final counts = <String, int>{};
  for (final grade in customGradesNotifier.value) {
    final subject = grade['subject']?.toString().trim() ?? '';
    final value = double.tryParse(grade['value']?.toString() ?? '');
    final weight = double.tryParse(grade['weight']?.toString() ?? '') ?? 1;
    if (subject.isEmpty || value == null || !value.isFinite || weight <= 0) {
      continue;
    }
    sums[subject] = (sums[subject] ?? 0) + value * weight;
    weights[subject] = (weights[subject] ?? 0) + weight;
    counts[subject] = (counts[subject] ?? 0) + 1;
  }
  if (sums.isEmpty) return l.aiPromptNone;
  final subjects = sums.keys.toList()..sort();
  return subjects
      .map((s) {
        final average = (sums[s]! / weights[s]!).toStringAsFixed(2);
        return '- $s: \u00D8 $average (${counts[s]})';
      })
      .join('\n');
}

/// Open homework from WebUntis and the local list, nearest due date first.
String _formatHomeworkForAi(AppL10n l, {int limit = 15}) {
  String subjectOf(Map<String, dynamic> item) {
    for (final lessonKey in const ['_lesson', 'lesson']) {
      final lesson = item[lessonKey];
      if (lesson is Map) {
        final value = lesson['_subjectLong'] ?? lesson['_subjectShort'];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
    }
    return item['subject']?.toString() ?? '';
  }

  final open = <Map<String, dynamic>>[
    for (final item in [
      ...homeworksNotifier.value,
      ...customHomeworkNotifier.value,
    ])
      if (item['isDone'] != true && item['_done'] != true) item,
  ];
  int dueOf(Map<String, dynamic> item) =>
      int.tryParse(item['dueDate']?.toString() ?? '') ?? 99999999;
  open.sort((a, b) => dueOf(a).compareTo(dueOf(b)));
  if (open.isEmpty) return l.aiPromptNone;
  return open
      .take(limit)
      .map((item) {
        final due = parseUntisDate(item['dueDate']);
        final dueLabel = due == null
            ? '?'
            : DateFormat('dd.MM.yyyy').format(due);
        final subject = subjectOf(item);
        var text = (item['text'] ?? item['description'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (text.length > 140) text = '${text.substring(0, 140)}...';
        return '- $dueLabel${subject.isEmpty ? '' : ' | $subject'}: $text';
      })
      .join('\n');
}

@visibleForTesting
String buildDefaultAiPromptTemplate(AppL10n l, {bool compact = false}) =>
    _buildDefaultAiPromptTemplate(l, compact: compact);

@visibleForTesting
String buildLocalAiPromptTemplate(AppL10n l) => _buildLocalAiPromptTemplate(l);

@visibleForTesting
String chatPromptSuffix(AppL10n l) => _chatPromptSuffix(l);

@visibleForTesting
String localChatPromptSuffix(AppL10n l) => _localChatPromptSuffix(l);

@visibleForTesting
String formatGradesForAi(AppL10n l) => _formatGradesForAi(l);
