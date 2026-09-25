import '../../../data/cache/offline_cache_store.dart';
import '../../../data/webuntis/webuntis_client.dart';
import '../domain/teacher_schedule.dart';
import 'timetable_repository.dart';

class TeacherSearchIndex {
  const TeacherSearchIndex({
    required this.teachers,
    required this.lessonsByTeacherId,
    required this.savedAt,
    required this.scannedClasses,
  });

  final List<SchoolTeacher> teachers;
  final Map<int, List<dynamic>> lessonsByTeacherId;
  final DateTime savedAt;
  final int scannedClasses;
}

/// Builds a searchable teacher directory from the classes visible to the
/// signed-in WebUntis account and keeps that directory in the local cache.
class TeacherSearchIndexService {
  TeacherSearchIndexService({
    TimetableRepository? repository,
    OfflineCacheStore? cache,
  }) : _repository = repository ?? TimetableRepository(),
       _cache = cache ?? OfflineCacheStore.instance;

  final TimetableRepository _repository;
  final OfflineCacheStore _cache;

  DateTime _weekStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (day.weekday >= DateTime.saturday) {
      return day.add(Duration(days: 8 - day.weekday));
    }
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  String _cacheKey(
    String accountId,
    WebUntisRequestContext context,
    DateTime date,
  ) {
    final monday = _weekStart(date);
    final week =
        '${monday.year.toString().padLeft(4, '0')}'
        '${monday.month.toString().padLeft(2, '0')}'
        '${monday.day.toString().padLeft(2, '0')}';
    return _cache.scopedKey(
      accountId: accountId,
      dataset: 'teacherSearchIndexV1',
      entityKey: '${context.schoolUrl}|${context.schoolName}|$week',
    );
  }

  Future<TeacherSearchIndex?> read({
    required String accountId,
    required WebUntisRequestContext context,
    required DateTime date,
  }) async {
    final cached = await _cache.read(_cacheKey(accountId, context, date));
    if (cached == null) return null;
    return _decode(cached.value, cached.savedAt);
  }

  Future<TeacherSearchIndex> refresh({
    required String accountId,
    required WebUntisRequestContext context,
    required DateTime date,
  }) async {
    final catalog = await _repository.fetchClassCatalog(context);
    final classes = catalog.classes;
    if (classes.isEmpty) {
      throw StateError('No classes are available for teacher search.');
    }

    final monday = _weekStart(date);
    final friday = monday.add(const Duration(days: 4));
    final catalogContext = context.copyWith(sessionId: catalog.sessionId);
    final teachersById = <int, _TeacherIndexEntry>{};
    var scannedClasses = 0;
    Object? lastFailure;

    for (var offset = 0; offset < classes.length; offset += 4) {
      final batch = classes.skip(offset).take(4);
      final results = await Future.wait(
        batch.map((schoolClass) async {
          final classId = _asInt(schoolClass['id']);
          if (classId == null || classId <= 0) return null;
          try {
            final publicData = await _repository.fetchPublicWeeklyData(
              context: catalogContext,
              elementId: classId,
              elementType: 1,
              date: monday,
            );
            final publicLessons = publicData == null
                ? const <dynamic>[]
                : _lessonsFromPublicData(publicData, classId);
            if (publicLessons.isNotEmpty) return publicLessons;
          } catch (error) {
            lastFailure = error;
          }
          try {
            return await _repository.fetchTimetable(
              context: catalogContext,
              elementId: classId,
              elementType: 1,
              startDate: monday,
              endDate: friday,
              requestId: 'teacher_index_class_$classId',
              showLessonText: false,
              showSubstitutionText: false,
              showInfo: false,
              showBooking: false,
              showRooms: true,
              showSubjects: true,
              showTeachers: true,
              showClasses: true,
            );
          } catch (error) {
            lastFailure = error;
            return null;
          }
        }),
      );

      for (final lessons in results) {
        if (lessons == null) continue;
        scannedClasses++;
        for (final rawLesson in lessons) {
          if (rawLesson is! Map) continue;
          final lesson = rawLesson.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          for (final rawTeacher in _teacherMaps(lesson['te'])) {
            final teacherId = _asInt(rawTeacher['id']);
            if (teacherId == null || teacherId <= 0) continue;
            final name = _teacherName(rawTeacher);
            if (name.isEmpty) continue;
            final entry = teachersById.putIfAbsent(
              teacherId,
              () => _TeacherIndexEntry(
                teacher: SchoolTeacher(
                  id: teacherId,
                  name: name,
                  abbreviation: _text(
                    rawTeacher['name'] ?? rawTeacher['shortName'],
                  ),
                ),
              ),
            );
            if (name.length > entry.teacher.name.length) {
              entry.teacher = SchoolTeacher(
                id: teacherId,
                name: name,
                abbreviation: entry.teacher.abbreviation,
              );
            }
            final lessonKey = [
              lesson['date'],
              lesson['startTime'],
              lesson['endTime'],
              _elementName(lesson['su']),
              _elementName(lesson['ro']),
            ].join('|');
            entry.lessons.putIfAbsent(lessonKey, () => lesson);
          }
        }
      }
    }

    if (scannedClasses == 0 && lastFailure != null) throw lastFailure!;
    if (teachersById.isEmpty) {
      throw StateError(
        'No teachers were found in the available class schedules.',
      );
    }

    final payload = <String, dynamic>{
      'scannedClasses': scannedClasses,
      'teachers': teachersById.values
          .map(
            (entry) => {
              'id': entry.teacher.id,
              'name': entry.teacher.name,
              'abbreviation': entry.teacher.abbreviation,
              'lessons': entry.lessons.values.toList(growable: false),
            },
          )
          .toList(growable: false),
    };
    final key = _cacheKey(accountId, context, date);
    await _cache.write(key, payload);
    final saved = await _cache.read(key);
    return _decode(payload, saved?.savedAt ?? DateTime.now())!;
  }

  TeacherSearchIndex? _decode(Map<String, dynamic> payload, DateTime savedAt) {
    final rawTeachers = payload['teachers'];
    if (rawTeachers is! List) return null;
    final teachers = <SchoolTeacher>[];
    final lessons = <int, List<dynamic>>{};
    for (final raw in rawTeachers.whereType<Map>()) {
      final data = raw.map((key, value) => MapEntry(key.toString(), value));
      final teacher = SchoolTeacher.fromJson(data);
      if (teacher.id <= 0 || teacher.name.isEmpty) continue;
      teachers.add(teacher);
      final rawLessons = data['lessons'];
      lessons[teacher.id] = rawLessons is List
          ? List<dynamic>.from(rawLessons)
          : const <dynamic>[];
    }
    teachers.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return TeacherSearchIndex(
      teachers: teachers,
      lessonsByTeacherId: lessons,
      savedAt: savedAt,
      scannedClasses: _asInt(payload['scannedClasses']) ?? 0,
    );
  }
}

class _TeacherIndexEntry {
  _TeacherIndexEntry({required this.teacher});

  SchoolTeacher teacher;
  final Map<String, Map<String, dynamic>> lessons = {};
}

List<Map<String, dynamic>> _teacherMaps(dynamic raw) {
  final values = raw is List
      ? raw
      : raw is Map
      ? [raw]
      : const [];
  return values
      .whereType<Map>()
      .map(
        (entry) => entry.map((key, value) => MapEntry(key.toString(), value)),
      )
      .toList(growable: false);
}

String _teacherName(Map<String, dynamic> teacher) {
  final first = _text(teacher['foreName'] ?? teacher['forename']);
  final last = _text(teacher['longName'] ?? teacher['longname']);
  final composed = [first, last].where((part) => part.isNotEmpty).join(' ');
  if (composed.isNotEmpty) return composed;
  for (final key in const [
    'fullName',
    'displayName',
    'displayname',
    'name',
    'shortName',
  ]) {
    final candidate = _text(teacher[key]);
    if (candidate.isNotEmpty) return candidate;
  }
  return '';
}

List<dynamic> _lessonsFromPublicData(Map<String, dynamic> data, int classId) {
  final elements = (data['elements'] as List?) ?? const <dynamic>[];
  final namesByElement = <String, Map<String, dynamic>>{};
  for (final raw in elements) {
    if (raw is! Map) continue;
    final element = raw.map((key, value) => MapEntry(key.toString(), value));
    final type = _asInt(element['type']);
    final id = _asInt(element['id']);
    if (type != null && id != null) namesByElement['$type:$id'] = element;
  }

  final periodsByClass = data['elementPeriods'];
  if (periodsByClass is! Map) return const <dynamic>[];
  final periods = periodsByClass[classId.toString()] ?? periodsByClass[classId];
  if (periods is! List) return const <dynamic>[];

  final lessons = <dynamic>[];
  for (final rawPeriod in periods) {
    if (rawPeriod is! Map) continue;
    final period = rawPeriod.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final periodElements = (period['elements'] as List?) ?? const <dynamic>[];
    final teachers = <Map<String, dynamic>>[];
    final subjects = <Map<String, dynamic>>[];
    final rooms = <Map<String, dynamic>>[];
    for (final rawElement in periodElements) {
      if (rawElement is! Map) continue;
      final element = rawElement.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final type = _asInt(element['type']);
      final id = _asInt(element['id']);
      if (type == null || id == null) continue;
      final detail = namesByElement['$type:$id'] ?? const <String, dynamic>{};
      final name = _teacherName(detail).isNotEmpty
          ? _teacherName(detail)
          : _teacherName(element);
      final normalized = <String, dynamic>{
        'id': id,
        'name': name,
        'longName': detail['longName'] ?? detail['longname'] ?? name,
      };
      if (type == 2 && name.isNotEmpty) teachers.add(normalized);
      if (type == 3 && name.isNotEmpty) subjects.add(normalized);
      if (type == 4 && name.isNotEmpty) rooms.add(normalized);
    }
    if (teachers.isEmpty) continue;
    lessons.add({
      'date': period['date'],
      'startTime': period['startTime'],
      'endTime': period['endTime'],
      'te': teachers,
      'su': subjects,
      'ro': rooms,
    });
  }
  return lessons;
}

String? _elementName(dynamic value) {
  if (value is Map) {
    for (final key in const ['longName', 'longname', 'name', 'shortName']) {
      final text = _text(value[key]);
      if (text.isNotEmpty) return text;
    }
  }
  if (value is List) {
    final names = value.map(_elementName).whereType<String>().toSet();
    if (names.isNotEmpty) return names.join(', ');
  }
  return value is String && value.trim().isNotEmpty ? value.trim() : null;
}

int? _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

String _text(dynamic value) => value?.toString().trim() ?? '';
