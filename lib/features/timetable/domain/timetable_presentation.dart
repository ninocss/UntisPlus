/// Layout preparation independent of Flutter and the screen lifecycle.
int lessonTimeMinutes(int hhmm) => (hhmm ~/ 100) * 60 + hhmm % 100;

class LessonSlot {
  const LessonSlot({
    required this.lesson,
    required this.startMin,
    required this.endMin,
    required this.column,
    required this.columnCount,
  });

  final Map<dynamic, dynamic> lesson;
  final int startMin;
  final int endMin;
  final int column;
  final int columnCount;
}

class LessonSlotCandidate {
  LessonSlotCandidate({
    required this.lesson,
    required this.startMin,
    required this.endMin,
  });

  final Map<dynamic, dynamic> lesson;
  final int startMin;
  final int endMin;
  int column = 0;
}

List<LessonSlot> computeLessonSlots(List<dynamic> rawLessons) {
  final entries =
      rawLessons
          .whereType<Map>()
          .map((lesson) {
            final map = lesson.cast<dynamic, dynamic>();
            final rawStart = (map['startTime'] as int?) ?? 800;
            final rawEnd = map['endTime'] as int?;
            return LessonSlotCandidate(
              lesson: map,
              startMin: lessonTimeMinutes(rawStart),
              endMin: rawEnd == null
                  ? lessonTimeMinutes(rawStart) + 45
                  : lessonTimeMinutes(rawEnd),
            );
          })
          .where((entry) => entry.endMin > entry.startMin)
          .toList()
        ..sort((a, b) {
          final byStart = a.startMin.compareTo(b.startMin);
          if (byStart != 0) return byStart;
          return a.endMin.compareTo(b.endMin);
        });

  if (entries.isEmpty) return const [];

  final slots = <LessonSlot>[];

  void flushCluster(List<LessonSlotCandidate> cluster) {
    if (cluster.isEmpty) return;
    final columnEnds = <int>[];

    for (final entry in cluster) {
      var assignedColumn = -1;
      for (var i = 0; i < columnEnds.length; i++) {
        if (columnEnds[i] <= entry.startMin) {
          assignedColumn = i;
          break;
        }
      }

      if (assignedColumn == -1) {
        columnEnds.add(entry.endMin);
        assignedColumn = columnEnds.length - 1;
      } else {
        columnEnds[assignedColumn] = entry.endMin;
      }

      entry.column = assignedColumn;
    }

    final columnCount = columnEnds.isEmpty ? 1 : columnEnds.length;
    for (final entry in cluster) {
      slots.add(
        LessonSlot(
          lesson: entry.lesson,
          startMin: entry.startMin,
          endMin: entry.endMin,
          column: entry.column,
          columnCount: columnCount,
        ),
      );
    }
  }

  final cluster = <LessonSlotCandidate>[];
  var clusterMaxEnd = -1;

  for (final entry in entries) {
    if (cluster.isEmpty) {
      cluster.add(entry);
      clusterMaxEnd = entry.endMin;
      continue;
    }

    if (entry.startMin < clusterMaxEnd) {
      cluster.add(entry);
      if (entry.endMin > clusterMaxEnd) {
        clusterMaxEnd = entry.endMin;
      }
    } else {
      flushCluster(cluster);
      cluster
        ..clear()
        ..add(entry);
      clusterMaxEnd = entry.endMin;
    }
  }
  flushCluster(cluster);

  return slots;
}
