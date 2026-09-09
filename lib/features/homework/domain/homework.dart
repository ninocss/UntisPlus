class Homework {
  const Homework({
    required this.id,
    required this.lessonId,
    required this.text,
    required this.dueDate,
    required this.isDone,
    required this.lesson,
    required this.raw,
  });

  final String id;
  final String lessonId;
  final String text;
  final int dueDate;
  final bool isDone;
  final Map<String, dynamic>? lesson;
  final Map<String, dynamic> raw;

  Map<String, dynamic> toLegacyJson() => {
    ...raw,
    if (lesson != null) '_lesson': lesson,
    if (isDone) '_done': true,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'lessonId': lessonId,
    'text': text,
    'dueDate': dueDate,
    'isDone': isDone,
    if (lesson != null) 'lesson': lesson,
    'raw': raw,
  };

  factory Homework.fromJson(Map<String, dynamic> value) => Homework(
    id: value['id']?.toString() ?? '',
    lessonId: value['lessonId']?.toString() ?? '',
    text: value['text']?.toString() ?? '',
    dueDate: int.tryParse(value['dueDate']?.toString() ?? '') ?? 0,
    isDone: value['isDone'] == true,
    lesson: value['lesson'] is Map
        ? Map<String, dynamic>.unmodifiable(
            Map<String, dynamic>.from(value['lesson'] as Map),
          )
        : null,
    raw: Map<String, dynamic>.unmodifiable(
      value['raw'] is Map
          ? Map<String, dynamic>.from(value['raw'] as Map)
          : const <String, dynamic>{},
    ),
  );
}

class LessonNote {
  const LessonNote({
    required this.id,
    required this.lessonId,
    required this.text,
    required this.lesson,
    required this.raw,
  });

  final String id;
  final String lessonId;
  final String text;
  final Map<String, dynamic>? lesson;
  final Map<String, dynamic> raw;

  Map<String, dynamic> toLegacyJson() => {
    ...raw,
    if (lesson != null) '_lesson': lesson,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'lessonId': lessonId,
    'text': text,
    if (lesson != null) 'lesson': lesson,
    'raw': raw,
  };

  factory LessonNote.fromJson(Map<String, dynamic> value) => LessonNote(
    id: value['id']?.toString() ?? '',
    lessonId: value['lessonId']?.toString() ?? '',
    text: value['text']?.toString() ?? '',
    lesson: value['lesson'] is Map
        ? Map<String, dynamic>.unmodifiable(
            Map<String, dynamic>.from(value['lesson'] as Map),
          )
        : null,
    raw: Map<String, dynamic>.unmodifiable(
      value['raw'] is Map
          ? Map<String, dynamic>.from(value['raw'] as Map)
          : const <String, dynamic>{},
    ),
  );
}

class HomeworkBundle {
  const HomeworkBundle({required this.homeworks, required this.lessonNotes});

  final List<Homework> homeworks;
  final List<LessonNote> lessonNotes;

  factory HomeworkBundle.fromWebUntis(
    dynamic rawResult, {
    Set<String> doneIds = const {},
  }) {
    final result = rawResult is Map
        ? Map<String, dynamic>.from(rawResult)
        : const <String, dynamic>{};
    final rawHomework = result['homeworks'] is List
        ? result['homeworks'] as List
        : const <dynamic>[];
    final rawNotes = result['lessonNotes'] is List
        ? result['lessonNotes'] as List
        : result['lessonInfos'] is List
        ? result['lessonInfos'] as List
        : const <dynamic>[];
    final rawLessons = result['lessons'] is List
        ? result['lessons'] as List
        : const <dynamic>[];
    final lessons = <String, Map<String, dynamic>>{
      for (final value in rawLessons.whereType<Map>())
        if (value['id'] != null)
          value['id'].toString(): Map<String, dynamic>.unmodifiable(
            Map<String, dynamic>.from(value),
          ),
    };

    final homeworks = rawHomework
        .whereType<Map>()
        .map((value) {
          final raw = Map<String, dynamic>.unmodifiable(
            Map<String, dynamic>.from(value),
          );
          final id = raw['id']?.toString() ?? '';
          final lessonId = raw['lessonId']?.toString() ?? '';
          return Homework(
            id: id,
            lessonId: lessonId,
            text: raw['text']?.toString() ?? '',
            dueDate:
                int.tryParse(
                  (raw['dueDate'] ?? raw['date'] ?? '').toString(),
                ) ??
                0,
            isDone: raw['isDone'] == true || doneIds.contains(id),
            lesson: lessons[lessonId],
            raw: raw,
          );
        })
        .toList(growable: false);
    final notes = rawNotes
        .whereType<Map>()
        .map((value) {
          final raw = Map<String, dynamic>.unmodifiable(
            Map<String, dynamic>.from(value),
          );
          final lessonId = raw['lessonId']?.toString() ?? '';
          return LessonNote(
            id: raw['id']?.toString() ?? '',
            lessonId: lessonId,
            text: (raw['text'] ?? raw['note'] ?? '').toString(),
            lesson: lessons[lessonId],
            raw: raw,
          );
        })
        .toList(growable: false);
    return HomeworkBundle(homeworks: homeworks, lessonNotes: notes);
  }

  factory HomeworkBundle.fromJson(
    Map<String, dynamic> value, {
    Set<String> doneIds = const {},
  }) => HomeworkBundle(
    homeworks: value['homeworks'] is List
        ? (value['homeworks'] as List)
              .whereType<Map>()
              .map((entry) {
                final homework = Homework.fromJson(
                  Map<String, dynamic>.from(entry),
                );
                return Homework(
                  id: homework.id,
                  lessonId: homework.lessonId,
                  text: homework.text,
                  dueDate: homework.dueDate,
                  isDone:
                      homework.raw['isDone'] == true ||
                      doneIds.contains(homework.id),
                  lesson: homework.lesson,
                  raw: homework.raw,
                );
              })
              .toList(growable: false)
        : const [],
    lessonNotes: value['lessonNotes'] is List
        ? (value['lessonNotes'] as List)
              .whereType<Map>()
              .map(
                (entry) =>
                    LessonNote.fromJson(Map<String, dynamic>.from(entry)),
              )
              .toList(growable: false)
        : const [],
  );

  Map<String, dynamic> toJson() => {
    'homeworks': homeworks.map((entry) => entry.toJson()).toList(),
    'lessonNotes': lessonNotes.map((entry) => entry.toJson()).toList(),
  };

  Map<String, List<Map<String, dynamic>>> toLegacyJson() => {
    'homeworks': homeworks.map((entry) => entry.toLegacyJson()).toList(),
    'lessonNotes': lessonNotes.map((entry) => entry.toLegacyJson()).toList(),
  };
}

bool isHomeworkDueSoon(int dueDate, {DateTime? now, int daysAhead = 7}) {
  final raw = dueDate.toString().padLeft(8, '0');
  if (raw.length != 8 || dueDate <= 0 || daysAhead < 0) return false;
  final year = int.tryParse(raw.substring(0, 4));
  final month = int.tryParse(raw.substring(4, 6));
  final day = int.tryParse(raw.substring(6, 8));
  if (year == null || month == null || day == null) return false;
  final due = DateTime(year, month, day);
  if (due.year != year || due.month != month || due.day != day) return false;
  final referenceValue = now ?? DateTime.now();
  final reference = DateTime(
    referenceValue.year,
    referenceValue.month,
    referenceValue.day,
  );
  return !due.isBefore(reference) &&
      !due.isAfter(reference.add(Duration(days: daysAhead)));
}
