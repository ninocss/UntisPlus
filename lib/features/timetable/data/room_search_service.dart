import '../../../core/defensive_parsers.dart';
import '../../../core/time_utils.dart';
import '../../../core/timetable_date_utils.dart';
import '../../../data/cache/offline_cache_store.dart';
import '../../../data/webuntis/webuntis_client.dart';
import '../domain/room_schedule.dart';
import 'timetable_repository.dart';

class RoomSearchIndex {
  const RoomSearchIndex({
    required this.rooms,
    required this.lessonsByRoomId,
    required this.savedAt,
    required this.scannedClasses,
  });

  final List<SchoolRoom> rooms;
  final Map<int, List<dynamic>> lessonsByRoomId;
  final DateTime savedAt;
  final int scannedClasses;
}

class RoomSearchService {
  RoomSearchService({
    TimetableRepository? repository,
    OfflineCacheStore? cache,
  }) : _repository = repository ?? TimetableRepository(),
       _cache = cache ?? OfflineCacheStore.instance;

  final TimetableRepository _repository;
  final OfflineCacheStore _cache;

  String _cacheKey(
    String accountId,
    WebUntisRequestContext context,
    DateTime date,
  ) {
    final monday = resolveDefaultTimetableMonday(date);
    final week = untisDateString(monday);
    return _cache.scopedKey(
      accountId: accountId,
      dataset: 'roomSearchIndexV1',
      entityKey: '${context.schoolUrl}|${context.schoolName}|$week',
    );
  }

  Future<RoomSearchIndex?> read({
    required String accountId,
    required WebUntisRequestContext context,
    required DateTime date,
  }) async {
    final cached = await _cache.read(_cacheKey(accountId, context, date));
    if (cached == null) return null;
    return _decode(cached.value, cached.savedAt);
  }

  Future<RoomSearchIndex> refresh({
    required String accountId,
    required WebUntisRequestContext context,
    required DateTime date,
  }) async {
    final index = await buildIndexFromCatalogAndRooms(
      context: context,
      date: date,
    );
    await _cache.write(
      _cacheKey(accountId, context, date),
      _encode(index),
    );
    return index;
  }

  Future<RoomSearchIndex> buildIndexFromCatalogAndRooms({
    required WebUntisRequestContext context,
    required DateTime date,
  }) async {
    final roomsById = <int, SchoolRoom>{};
    final lessonsByRoomId = <int, List<dynamic>>{};
    var scannedClasses = 0;

    // 1. Try fetching direct rooms from master data / getRooms
    try {
      final masterData = await _repository.fetchMasterData(context);
      for (final raw in masterData.rooms) {
        final room = SchoolRoom.fromJson(raw);
        if (room.id > 0 && room.displayName.isNotEmpty) {
          roomsById[room.id] = room;
        }
      }
    } catch (_) {
      // Continue with class timetable fallback
    }

    // 2. Fetch classes catalog and scan class timetables for room assignments
    TimetableClassCatalog? catalog;
    try {
      catalog = await _repository.fetchClassCatalog(context);
    } catch (_) {
      // Direct room access only if class catalog fails
    }

    if (catalog != null && catalog.classes.isNotEmpty) {
      final monday = resolveDefaultTimetableMonday(date);
      final friday = monday.add(const Duration(days: 4));
      final catalogContext = context.copyWith(sessionId: catalog.sessionId);
      final classes = catalog.classes;

      for (var offset = 0; offset < classes.length; offset += 4) {
        final batch = classes.skip(offset).take(4);
        final results = await Future.wait(
          batch.map((schoolClass) async {
            final classId = asIntOrNull(schoolClass['id']);
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
            } catch (_) {}

            try {
              return await _repository.fetchTimetable(
                context: catalogContext,
                elementId: classId,
                elementType: 1,
                startDate: monday,
                endDate: friday,
                requestId: 'room_index_class_$classId',
                showLessonText: false,
                showSubstitutionText: false,
                showInfo: false,
                showBooking: false,
                showRooms: true,
                showSubjects: true,
                showTeachers: true,
                showClasses: true,
              );
            } catch (_) {
              return null;
            }
          }),
        );

        for (final lessonList in results) {
          if (lessonList == null || lessonList.isEmpty) continue;
          scannedClasses++;
          for (final raw in lessonList) {
            if (raw is! Map) continue;
            final lesson = raw.map((k, v) => MapEntry(k.toString(), v));
            final roomElements = (lesson['ro'] as List?) ?? const <dynamic>[];
            for (final rawRoom in roomElements) {
              if (rawRoom is! Map) continue;
              final r = rawRoom.map((k, v) => MapEntry(k.toString(), v));
              final roomId = asIntOrNull(r['id']);
              final roomName = (r['name'] ?? r['shortName'] ?? '').toString().trim();
              if (roomId != null && roomId > 0) {
                if (!roomsById.containsKey(roomId) && roomName.isNotEmpty) {
                  roomsById[roomId] = SchoolRoom(
                    id: roomId,
                    name: roomName,
                    longName: (r['longName'] ?? r['longname'] ?? roomName).toString(),
                  );
                }
                lessonsByRoomId.putIfAbsent(roomId, () => <dynamic>[]).add(lesson);
              }
            }
          }
        }
      }
    }

    final sortedRooms = roomsById.values.toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    return RoomSearchIndex(
      rooms: List.unmodifiable(sortedRooms),
      lessonsByRoomId: lessonsByRoomId.map(
        (key, value) => MapEntry(key, List<dynamic>.unmodifiable(value)),
      ),
      savedAt: DateTime.now(),
      scannedClasses: scannedClasses,
    );
  }

  Future<List<dynamic>> fetchRoomTimetable({
    required WebUntisRequestContext context,
    required int roomId,
    required DateTime date,
  }) => _repository.fetchTimetable(
    context: context,
    elementId: roomId,
    elementType: 4,
    startDate: date,
    endDate: date,
    requestId: 'room_day_$roomId',
    showLessonText: false,
    showSubstitutionText: false,
    showInfo: false,
    showBooking: false,
    showRooms: true,
    showSubjects: true,
    showTeachers: true,
    showClasses: true,
  );

  Map<String, dynamic> _encode(RoomSearchIndex index) => {
    'version': 1,
    'scannedClasses': index.scannedClasses,
    'rooms': [
      for (final room in index.rooms)
        {
          'id': room.id,
          'name': room.name,
          'longName': room.longName,
          'building': room.building,
        },
    ],
    'lessonsByRoomId': {
      for (final entry in index.lessonsByRoomId.entries)
        entry.key.toString(): entry.value,
    },
  };

  RoomSearchIndex _decode(Map<String, dynamic> raw, DateTime savedAt) {
    final rawRooms = (raw['rooms'] as List?) ?? const <dynamic>[];
    final rooms = rawRooms
        .whereType<Map>()
        .map((m) => SchoolRoom.fromJson(m.cast<String, dynamic>()))
        .toList();

    final rawLessons = (raw['lessonsByRoomId'] as Map?) ?? const <dynamic, dynamic>{};
    final lessonsByRoomId = <int, List<dynamic>>{};
    for (final entry in rawLessons.entries) {
      final id = int.tryParse(entry.key.toString());
      if (id != null && entry.value is List) {
        lessonsByRoomId[id] = (entry.value as List).toList();
      }
    }

    return RoomSearchIndex(
      rooms: rooms,
      lessonsByRoomId: lessonsByRoomId,
      savedAt: savedAt,
      scannedClasses: asIntOrNull(raw['scannedClasses']) ?? 0,
    );
  }
}

List<dynamic> _lessonsFromPublicData(Map<String, dynamic> data, int classId) {
  final result = data['result'];
  if (result is! Map) return const <dynamic>[];
  final dataMap = result['data'];
  if (dataMap is! Map) return const <dynamic>[];
  final elements = (dataMap['elements'] as List?) ?? const <dynamic>[];
  final namesByElement = <String, Map<String, dynamic>>{};

  for (final raw in elements) {
    if (raw is! Map) continue;
    final element = raw.map((k, v) => MapEntry(k.toString(), v));
    final type = asIntOrNull(element['type']);
    final id = asIntOrNull(element['id']);
    if (type == null || id == null) continue;
    namesByElement['$type:$id'] = element;
  }

  final elementPeriods = dataMap['elementPeriods'];
  if (elementPeriods is! Map) return const <dynamic>[];
  final periods = elementPeriods[classId.toString()] ?? elementPeriods[classId];
  if (periods is! List) return const <dynamic>[];

  final lessons = <dynamic>[];
  for (final rawPeriod in periods) {
    if (rawPeriod is! Map) continue;
    final period = rawPeriod.map((k, v) => MapEntry(k.toString(), v));
    final periodElements = (period['elements'] as List?) ?? const <dynamic>[];

    final teachers = <Map<String, dynamic>>[];
    final subjects = <Map<String, dynamic>>[];
    final rooms = <Map<String, dynamic>>[];
    final classes = <Map<String, dynamic>>[];

    for (final rawElement in periodElements) {
      if (rawElement is! Map) continue;
      final element = rawElement.map((k, v) => MapEntry(k.toString(), v));
      final type = asIntOrNull(element['type']);
      final id = asIntOrNull(element['id']);
      if (type == null || id == null) continue;
      final detail = namesByElement['$type:$id'] ?? const <String, dynamic>{};
      final name = (detail['name'] ?? element['name'] ?? '').toString().trim();
      final longName = (detail['longName'] ?? detail['longname'] ?? name).toString().trim();
      final normalized = {'id': id, 'name': name, 'longName': longName};

      if (type == 1 && name.isNotEmpty) classes.add(normalized);
      if (type == 2 && name.isNotEmpty) teachers.add(normalized);
      if (type == 3 && name.isNotEmpty) subjects.add(normalized);
      if (type == 4 && name.isNotEmpty) rooms.add(normalized);
    }

    if (rooms.isEmpty) continue;
    lessons.add({
      'date': period['date'],
      'startTime': period['startTime'],
      'endTime': period['endTime'],
      'te': teachers,
      'su': subjects,
      'ro': rooms,
      'kl': classes,
    });
  }

  return lessons;
}
