import '../../../core/time_utils.dart';
import '../../../data/webuntis/webuntis_client.dart';

class TimetableMasterData {
  const TimetableMasterData({
    required this.subjects,
    required this.teachers,
    required this.rooms,
  });

  final List<Map<String, dynamic>> subjects;
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> rooms;
}

class TimetableClassCatalog {
  const TimetableClassCatalog({required this.classes, required this.sessionId});

  final List<Map<String, dynamic>> classes;
  final String sessionId;
}

class TimetableRepository {
  TimetableRepository({WebUntisClient? client})
    : _client = client ?? WebUntisClient();

  final WebUntisClient _client;

  Future<TimetableMasterData> fetchMasterData(
    WebUntisRequestContext context,
  ) async {
    final responses = await Future.wait([
      _client.rpc(
        context: context,
        method: 'getSubjects',
        params: const <String, dynamic>{},
        requestId: 'sub',
      ),
      _client.rpc(
        context: context,
        method: 'getTeachers',
        params: const <String, dynamic>{},
        requestId: 'tea',
      ),
      _client.rpc(
        context: context,
        method: 'getRooms',
        params: const <String, dynamic>{},
        requestId: 'roo',
      ),
    ]);
    return TimetableMasterData(
      subjects: _resultMaps(responses[0]),
      teachers: _resultMaps(responses[1]),
      rooms: _resultMaps(responses[2]),
    );
  }

  Future<List<dynamic>> fetchTimetable({
    required WebUntisRequestContext context,
    required int elementId,
    required int elementType,
    required DateTime startDate,
    required DateTime endDate,
    String requestId = 'week_req',
    bool showLessonText = true,
    bool showSubstitutionText = true,
    bool showInfo = true,
    bool showBooking = true,
    bool showRooms = false,
    bool showSubjects = false,
    bool showTeachers = false,
    bool showClasses = false,
  }) async {
    final response = await _client.rpc(
      context: context,
      method: 'getTimetable',
      requestId: requestId,
      params: {
        'options': {
          'element': {'id': elementId, 'type': elementType},
          'startDate': untisDateInt(startDate),
          'endDate': untisDateInt(endDate),
          if (showLessonText) 'showLsText': true,
          if (showSubstitutionText) 'showSubstText': true,
          if (showInfo) 'showInfo': true,
          if (showBooking) 'showBooking': true,
          if (showRooms) 'showRooms': true,
          if (showSubjects) 'showSubjects': true,
          if (showTeachers) 'showTeachers': true,
          if (showClasses) 'showClasses': true,
        },
      },
    );
    final result = response['result'];
    if (result is List) return List<dynamic>.from(result);
    if (result is Map && result['timetable'] is List) {
      return List<dynamic>.from(result['timetable'] as List);
    }
    return const <dynamic>[];
  }

  Future<Map<String, dynamic>?> fetchCurrentSchoolyear(
    WebUntisRequestContext context,
  ) async {
    final response = await _client.rpc(
      context: context,
      method: 'getCurrentSchoolyear',
      params: const <String, dynamic>{},
      requestId: 'sy_req',
    );
    final result = response['result'];
    if (result is! Map) return null;
    return result.map((key, value) => MapEntry(key.toString(), value));
  }

  Future<List<Map<String, dynamic>>> fetchHolidays(
    WebUntisRequestContext context,
  ) async {
    final response = await _client.rpc(
      context: context,
      method: 'getHolidays',
      params: const <String, dynamic>{},
      requestId: 'holidays',
    );
    return _resultMaps(response);
  }

  Future<String?> authenticateAnonymous({
    required String schoolUrl,
    required String schoolName,
  }) async {
    try {
      final response = await _client.rpc(
        context: WebUntisRequestContext(
          schoolUrl: schoolUrl,
          schoolName: schoolName,
        ),
        method: 'authenticate',
        requestId: 'anon',
        params: const {'user': '', 'password': '', 'client': 'UntisPlus'},
      );
      final result = response['result'];
      if (result is Map) return result['sessionId']?.toString();
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchClasses(
    WebUntisRequestContext context, {
    String requestId = 'fr_cl',
  }) async {
    final response = await _client.rpc(
      context: context,
      method: 'getKlassen',
      params: const <String, dynamic>{},
      requestId: requestId,
    );
    return _resultMaps(response);
  }

  Future<TimetableClassCatalog> fetchClassCatalog(
    WebUntisRequestContext context,
  ) async {
    if (context.sessionId.isNotEmpty) {
      try {
        final classes = await fetchClasses(context);
        if (classes.isNotEmpty) {
          return TimetableClassCatalog(
            classes: classes,
            sessionId: context.sessionId,
          );
        }
      } catch (_) {}
    }

    final anonymousSession = await authenticateAnonymous(
      schoolUrl: context.schoolUrl,
      schoolName: context.schoolName,
    );
    if (anonymousSession != null && anonymousSession.isNotEmpty) {
      try {
        final classes = await fetchClasses(
          context.copyWith(sessionId: anonymousSession),
          requestId: 'anon_cl',
        );
        if (classes.isNotEmpty) {
          return TimetableClassCatalog(
            classes: classes,
            sessionId: anonymousSession,
          );
        }
      } catch (_) {}
    }
    return TimetableClassCatalog(
      classes: const <Map<String, dynamic>>[],
      sessionId: context.sessionId,
    );
  }

  Future<List<dynamic>> fetchClassTimetable({
    required WebUntisRequestContext context,
    required int classId,
    required DateTime date,
    String requestId = 'fr_tt',
  }) => fetchTimetable(
    context: context,
    elementId: classId,
    elementType: 1,
    startDate: date,
    endDate: date,
    requestId: '${requestId}_$classId',
    showLessonText: false,
    showSubstitutionText: false,
    showInfo: false,
    showBooking: false,
    showRooms: true,
    showSubjects: true,
    showTeachers: true,
    showClasses: true,
  );

  Future<Map<String, dynamic>?> fetchPublicWeeklyData({
    required WebUntisRequestContext context,
    required int elementId,
    required int elementType,
    required DateTime date,
    int formatId = 2,
  }) async {
    final isoDate =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final uri = Uri.https(
      context.schoolUrl,
      '/WebUntis/api/public/timetable/weekly/data',
      {
        'elementType': elementType.toString(),
        'elementId': elementId.toString(),
        'date': isoDate,
        'formatId': formatId.toString(),
      },
    );
    final decoded = await _client.getJson(
      uri: uri,
      headers: {
        if (context.sessionId.isNotEmpty)
          'Cookie':
              'JSESSIONID=${context.sessionId}; schoolname=${context.schoolName}',
        'Accept': 'application/json',
      },
    );
    if (decoded is! Map) return null;
    final root = decoded['data'];
    final result = root is Map ? root['result'] : null;
    final data = result is Map ? result['data'] : null;
    if (data is! Map) return null;
    return data.map((key, value) => MapEntry(key.toString(), value));
  }

  static List<Map<String, dynamic>> _resultMaps(Map<String, dynamic> response) {
    final result = response['result'];
    if (result is! List) return const <Map<String, dynamic>>[];
    return result
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList(growable: false);
  }
}
