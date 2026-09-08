enum TimetableChangeType {
  added,
  removed,
  cancelled,
  restored,
  room,
  teacher,
  subject,
  time,
  other,
}

class TimetableLessonSnapshot {
  const TimetableLessonSnapshot({
    required this.identity,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.rooms,
    required this.teachers,
    required this.cancelled,
  });

  final String identity;
  final int date;
  final int startTime;
  final int endTime;
  final String subject;
  final List<String> rooms;
  final List<String> teachers;
  final bool cancelled;

  factory TimetableLessonSnapshot.fromJson(Map<dynamic, dynamic> json) {
    String joined(dynamic value) {
      if (value is Iterable) {
        return value
            .map(
              (entry) =>
                  entry is Map ? entry['name'] ?? entry['longName'] : entry,
            )
            .where((entry) => entry != null)
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .join(', ');
      }
      return value?.toString().trim() ?? '';
    }

    List<String> splitValues(dynamic value) =>
        joined(value)
            .split(',')
            .map((entry) => entry.trim())
            .where((entry) => entry.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final date = (json['date'] as num?)?.toInt() ?? 0;
    final start = (json['startTime'] as num?)?.toInt() ?? 0;
    final end = (json['endTime'] as num?)?.toInt() ?? 0;
    final subject =
        (json['_subjectShort'] ?? json['subject'] ?? json['su'] ?? '')
            .toString()
            .trim();
    final rawId = json['id'] ?? json['lsid'];
    final identity = rawId != null && rawId.toString().isNotEmpty
        ? 'id:$rawId'
        : 'fallback:$date|$start|$end|$subject';
    final code = json['code']?.toString().toLowerCase() ?? '';
    return TimetableLessonSnapshot(
      identity: identity,
      date: date,
      startTime: start,
      endTime: end,
      subject: subject,
      rooms: splitValues(json['_room'] ?? json['rooms'] ?? json['ro']),
      teachers: splitValues(
        json['_teacher'] ?? json['teachers'] ?? json['teacher'] ?? json['te'],
      ),
      cancelled: code == 'cancelled' || json['cancelled'] == true,
    );
  }

  factory TimetableLessonSnapshot.fromStorage(Map<String, dynamic> json) =>
      TimetableLessonSnapshot(
        identity: json['identity']?.toString() ?? '',
        date: (json['date'] as num?)?.toInt() ?? 0,
        startTime: (json['startTime'] as num?)?.toInt() ?? 0,
        endTime: (json['endTime'] as num?)?.toInt() ?? 0,
        subject: json['subject']?.toString() ?? '',
        rooms: (json['rooms'] as List? ?? const []).map((e) => '$e').toList(),
        teachers: (json['teachers'] as List? ?? const [])
            .map((e) => '$e')
            .toList(),
        cancelled: json['cancelled'] == true,
      );

  Map<String, dynamic> toJson() => {
    'identity': identity,
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
    'subject': subject,
    'rooms': rooms,
    'teachers': teachers,
    'cancelled': cancelled,
  };
}

class TimetableChange {
  const TimetableChange({
    required this.id,
    required this.type,
    required this.detectedAt,
    required this.lessonIdentity,
    required this.date,
    required this.subject,
    this.before,
    this.after,
    this.isRead = false,
  });

  final String id;
  final TimetableChangeType type;
  final DateTime detectedAt;
  final String lessonIdentity;
  final int date;
  final String subject;
  final String? before;
  final String? after;
  final bool isRead;

  TimetableChange copyWith({bool? isRead}) => TimetableChange(
    id: id,
    type: type,
    detectedAt: detectedAt,
    lessonIdentity: lessonIdentity,
    date: date,
    subject: subject,
    before: before,
    after: after,
    isRead: isRead ?? this.isRead,
  );

  factory TimetableChange.fromJson(Map<String, dynamic> json) =>
      TimetableChange(
        id: json['id']?.toString() ?? '',
        type: TimetableChangeType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => TimetableChangeType.other,
        ),
        detectedAt:
            DateTime.tryParse(json['detectedAt']?.toString() ?? '') ??
            DateTime.now(),
        lessonIdentity: json['lessonIdentity']?.toString() ?? '',
        date: (json['date'] as num?)?.toInt() ?? 0,
        subject: json['subject']?.toString() ?? '',
        before: json['before']?.toString(),
        after: json['after']?.toString(),
        isRead: json['isRead'] == true,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'detectedAt': detectedAt.toUtc().toIso8601String(),
    'lessonIdentity': lessonIdentity,
    'date': date,
    'subject': subject,
    if (before != null) 'before': before,
    if (after != null) 'after': after,
    'isRead': isRead,
  };
}

class TimetableChangeDetector {
  const TimetableChangeDetector();

  List<TimetableChange> compare({
    required List<TimetableLessonSnapshot> before,
    required List<TimetableLessonSnapshot> after,
    DateTime? detectedAt,
  }) {
    final timestamp = detectedAt ?? DateTime.now();
    final oldById = {for (final lesson in before) lesson.identity: lesson};
    final newById = {for (final lesson in after) lesson.identity: lesson};
    final changes = <TimetableChange>[];

    for (final entry in newById.entries) {
      final old = oldById[entry.key];
      final current = entry.value;
      if (old == null) {
        changes.add(_change(TimetableChangeType.added, current, timestamp));
        continue;
      }
      if (old.cancelled != current.cancelled) {
        changes.add(
          _change(
            current.cancelled
                ? TimetableChangeType.cancelled
                : TimetableChangeType.restored,
            current,
            timestamp,
            before: old.cancelled ? 'cancelled' : 'active',
            after: current.cancelled ? 'cancelled' : 'active',
          ),
        );
      }
      if (!_same(old.rooms, current.rooms)) {
        changes.add(
          _change(
            TimetableChangeType.room,
            current,
            timestamp,
            before: old.rooms.join(', '),
            after: current.rooms.join(', '),
          ),
        );
      }
      if (!_same(old.teachers, current.teachers)) {
        changes.add(
          _change(
            TimetableChangeType.teacher,
            current,
            timestamp,
            before: old.teachers.join(', '),
            after: current.teachers.join(', '),
          ),
        );
      }
      if (old.subject != current.subject) {
        changes.add(
          _change(
            TimetableChangeType.subject,
            current,
            timestamp,
            before: old.subject,
            after: current.subject,
          ),
        );
      }
      if (old.startTime != current.startTime ||
          old.endTime != current.endTime) {
        changes.add(
          _change(
            TimetableChangeType.time,
            current,
            timestamp,
            before: '${old.startTime}-${old.endTime}',
            after: '${current.startTime}-${current.endTime}',
          ),
        );
      }
    }

    for (final old in before) {
      if (!newById.containsKey(old.identity)) {
        changes.add(_change(TimetableChangeType.removed, old, timestamp));
      }
    }
    return changes;
  }

  bool _same(List<String> a, List<String> b) =>
      a.length == b.length &&
      a.asMap().entries.every((e) => e.value == b[e.key]);

  TimetableChange _change(
    TimetableChangeType type,
    TimetableLessonSnapshot lesson,
    DateTime timestamp, {
    String? before,
    String? after,
  }) {
    final seed = [
      type.name,
      lesson.identity,
      before ?? '',
      after ?? '',
    ].join('|');
    return TimetableChange(
      id: seed,
      type: type,
      detectedAt: timestamp,
      lessonIdentity: lesson.identity,
      date: lesson.date,
      subject: lesson.subject,
      before: before,
      after: after,
    );
  }
}
