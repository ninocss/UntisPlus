part of '../../../main.dart';

// --- KI-ASSISTENT HILFSFUNKTIONEN ---

String _formatWeekForAi(Map<int, List<dynamic>> weekData, DateTime monday) {
  final l = AppL10n.of(appLocaleNotifier.value);
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
        final start = _formatUntisTime(lsn['startTime'].toString());
        final end = _formatUntisTime(lsn['endTime'].toString());
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

String _buildDefaultAiPromptTemplate(AppL10n l) {
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

${l.ui('aiResponseFormat')}''';
}
