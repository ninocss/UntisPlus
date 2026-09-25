import 'dart:math' as math;

import '../../core/time_utils.dart';
import '../../core/sync_state.dart';
import '../../data/cache/offline_cache_store.dart';
import '../../data/webuntis/webuntis_client.dart';
import '../../data/webuntis/webuntis_session_manager.dart';
import '../accounts/domain/untis_account.dart';
import '../exams/data/webuntis_exam_repository.dart';
import '../timetable/data/timetable_repository.dart';

class WrappedYear {
  const WrappedYear({
    required this.start,
    required this.end,
    this.manual = false,
  });
  final DateTime start;
  final DateTime end;
  final bool manual;
  String get id => untisDateString(start);
  String get label => '${start.year}/${end.year}';
  bool contains(DateTime day) => !day.isBefore(start) && !day.isAfter(end);
  bool get hasEnded {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).isAfter(end);
  }

  Map<String, dynamic> toJson() => {
    'start': untisDateInt(start),
    'end': untisDateInt(end),
    'manual': manual,
  };
  static WrappedYear? fromJson(Object? value) {
    if (value is! Map) return null;
    final start = parseUntisDate(value['start']);
    final end = parseUntisDate(value['end']);
    if (start == null || end == null || !end.isAfter(start)) return null;
    return WrappedYear(start: start, end: end, manual: value['manual'] == true);
  }
}

class WrappedSnapshot {
  const WrappedSnapshot({
    required this.year,
    required this.coveredWeeks,
    required this.expectedWeeks,
    required this.lessons,
    required this.lessonMinutes,
    required this.cancelled,
    required this.substitutions,
    required this.absentLessons,
    required this.absenceRecords,
    required this.excusedAbsences,
    required this.unexcusedAbsences,
    required this.freeWeekdays,
    required this.holidayNames,
    required this.grades,
    required this.gradeSubjects,
    required this.exams,
    required this.homework,
    required this.hasAbsenceSource,
    required this.hasHolidaySource,
    required this.hasExamSource,
    required this.hasHomeworkSource,
  });
  final WrappedYear year;
  final int coveredWeeks;
  final int expectedWeeks;
  final int lessons;
  final int lessonMinutes;
  final int cancelled;
  final int substitutions;
  final int absentLessons;
  final int absenceRecords;
  final int excusedAbsences;
  final int unexcusedAbsences;
  final int freeWeekdays;
  final List<String> holidayNames;
  final int grades;
  final Map<String, int> gradeSubjects;
  final int exams;
  final int homework;
  final bool hasAbsenceSource;
  final bool hasHolidaySource;
  final bool hasExamSource;
  final bool hasHomeworkSource;
  bool get incomplete => coveredWeeks < expectedWeeks;
}

/// Keeps each school year and its private snapshots under the Untis account ID.
class SchoolWrappedRepository {
  static final WebUntisClient _defaultClient = WebUntisClient();
  static final WebUntisSessionManager _defaultSessions = WebUntisSessionManager(
    client: _defaultClient,
  );
  SchoolWrappedRepository({
    OfflineCacheStore? store,
    WebUntisClient? client,
    WebUntisSessionManager? sessions,
  }) : _store = store ?? OfflineCacheStore.instance,
       _client = client ?? _defaultClient,
       _sessions =
           sessions ??
           (client == null
               ? _defaultSessions
               : WebUntisSessionManager(client: client));
  final OfflineCacheStore _store;
  final WebUntisClient _client;
  final WebUntisSessionManager _sessions;
  String _key(String accountId, String kind, String id) => _store.scopedKey(
    accountId: accountId,
    dataset: 'wrapped$kind',
    entityKey: id,
  );

  Future<List<WrappedYear>> years(String accountId) async {
    final raw = (await _store.read(
      _key(accountId, 'Index', 'years'),
    ))?.value['years'];
    if (raw is! List) return [];
    final result = raw
        .map(WrappedYear.fromJson)
        .whereType<WrappedYear>()
        .toList();
    result.sort((a, b) => b.start.compareTo(a.start));
    return result;
  }

  Future<void> saveYear(String accountId, WrappedYear year) async {
    final all = await years(accountId);
    all.removeWhere((item) => item.id == year.id);
    all.add(year);
    await _store.write(_key(accountId, 'Index', 'years'), {
      'years': all.map((item) => item.toJson()).toList(),
    });
  }

  Future<WrappedYear?> refreshSchoolYear(UntisAccount account) async {
    try {
      final result = await _run(
        account,
        (context) => TimetableRepository(
          client: _client,
        ).fetchCurrentSchoolyear(context),
      );
      final start = parseUntisDate(result?['startDate']);
      final end = parseUntisDate(result?['endDate']);
      if (start == null || end == null || !end.isAfter(start)) return null;
      final year = WrappedYear(start: start, end: end);
      await saveYear(account.id, year);
      return year;
    } catch (_) {
      return null;
    }
  }

  Future<WrappedYear?> pendingAnnouncement(String accountId) async {
    for (final year in await years(accountId)) {
      if (!year.hasEnded) continue;
      if (await _store.read(_key(accountId, 'Seen', year.id)) == null) {
        return year;
      }
    }
    return null;
  }

  Future<void> markAnnouncementSeen(String accountId, WrappedYear year) =>
      _store.write(_key(accountId, 'Seen', year.id), {'shown': true});

  Future<void> recordWeek({
    required String accountId,
    required WrappedYear year,
    required DateTime monday,
    required Map<int, List<dynamic>> days,
  }) => _store.write(
    _key(accountId, 'Week', '${year.id}|${untisDateString(monday)}'),
    {
      'monday': untisDateInt(monday),
      'days': {for (var day = 0; day < 5; day++) '$day': days[day] ?? []},
    },
  );

  Future<void> recordHolidays({
    required String accountId,
    required WrappedYear year,
    required List<Map<String, dynamic>> holidays,
  }) async {
    final relevant = holidays.where((holiday) {
      final start = parseUntisDate(holiday['startDate']);
      final end = parseUntisDate(holiday['endDate']);
      return start != null &&
          end != null &&
          !end.isBefore(year.start) &&
          !start.isAfter(year.end);
    }).toList();
    if (relevant.isEmpty) return;
    await _store.write(_key(accountId, 'Holidays', year.id), {
      'holidays': relevant,
    });
  }

  Future<void> recordAbsences({
    required String accountId,
    required WrappedYear year,
    required List<Map<String, dynamic>> items,
  }) => _store.write(_key(accountId, 'Absences', year.id), {
    'items': items,
    'complete': false,
  });

  Future<void> recordExams({
    required String accountId,
    required WrappedYear year,
    required List<Map<String, dynamic>> items,
  }) async {
    final key = _key(accountId, 'Exams', year.id);
    final existing = await _store.read(key);
    if (existing?.value['complete'] == true) return;
    final merged = <String, Map<String, dynamic>>{};
    for (final item in [..._maps(existing?.value['items']), ...items]) {
      merged[item['id']?.toString() ?? item.toString()] = item;
    }
    await _store.write(key, {
      'items': merged.values.toList(),
      'complete': false,
    });
  }

  Future<void> recordHomework({
    required String accountId,
    required WrappedYear year,
    required List<Map<String, dynamic>> items,
  }) async {
    final key = _key(accountId, 'HomeworkRecent', year.id);
    final existing = await _store.read(key);
    final merged = <String, Map<String, dynamic>>{};
    for (final item in [..._maps(existing?.value['items']), ...items]) {
      merged[item['id']?.toString() ?? item.toString()] = item;
    }
    await _store.write(key, {'items': merged.values.toList()});
  }

  /// A small, throttled capture makes annual data durable even when the
  /// student never visits the individual absence, exam, or homework pages.
  Future<void> captureCurrent(UntisAccount account, WrappedYear year) async {
    final now = DateTime.now();
    if (year.hasEnded || !year.contains(now)) return;
    final markerKey = _key(account.id, 'Capture', year.id);
    final marker = await _store.read(markerKey);
    if (marker != null &&
        now.difference(marker.savedAt) < const Duration(days: 7)) {
      return;
    }
    var succeeded = false;
    try {
      final response = await _run(
        account,
        (context) => _client.rpc(
          context: context,
          method: 'getTimetableWithAbsences',
          requestId: 'wrapped_capture_absences',
          params: {
            'options': {
              'startDate': untisDateInt(year.start),
              'endDate': untisDateInt(now),
            },
          },
        ),
      );
      final value = response['result'];
      if (value is! List &&
          !(value is Map && value['periodsWithAbsences'] is List)) {
        throw const FormatException('Unexpected absence response');
      }
      final raw = value is List
          ? value
          : value is Map && value['periodsWithAbsences'] is List
          ? value['periodsWithAbsences'] as List
          : const <dynamic>[];
      await recordAbsences(
        accountId: account.id,
        year: year,
        items: raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
      succeeded = true;
    } catch (_) {}
    try {
      final holidays = await _run(
        account,
        TimetableRepository(client: _client).fetchHolidays,
      );
      await recordHolidays(
        accountId: account.id,
        year: year,
        holidays: holidays,
      );
      if (holidays.isNotEmpty) succeeded = true;
    } catch (_) {}
    final examFrom = marker == null
        ? year.start
        : marker.savedAt.toLocal().subtract(const Duration(days: 7));
    final examStart = examFrom.isBefore(year.start) ? year.start : examFrom;
    try {
      final exams = await _run(
        account,
        (context) => WebUntisExamRepository(client: _client).fetch(
          context: context,
          personId: account.personId,
          start: examStart,
          end: now.add(const Duration(days: 60)),
        ),
      );
      if (exams.isNotEmpty) {
        await recordExams(accountId: account.id, year: year, items: exams);
        succeeded = true;
      }
    } catch (_) {}
    var homeworkThrough = parseUntisDate(marker?.value['homeworkThrough']);
    final homeworkStart = homeworkThrough == null
        ? year.start
        : homeworkThrough.subtract(const Duration(days: 7));
    var chunkStart = homeworkStart.isBefore(year.start)
        ? year.start
        : homeworkStart;
    while (!chunkStart.isAfter(now)) {
      final end = chunkStart.add(const Duration(days: 41));
      final chunkEnd = end.isAfter(now) ? now : end;
      try {
        final response = await _run(
          account,
          (context) => _client.rpc(
            context: context,
            method: 'getHomeWork2017',
            requestId: 'wrapped_capture_hw_${untisDateString(chunkStart)}',
            params: [
              {
                'id': account.personId,
                'type': account.personType == 5 ? 'STUDENT' : 'TEACHER',
                'startDate': untisDateInt(chunkStart),
                'endDate': untisDateInt(chunkEnd),
              },
            ],
          ),
        );
        final result = response['result'];
        if (result is Map && result['homeworks'] is List) {
          await recordHomework(
            accountId: account.id,
            year: year,
            items: (result['homeworks'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
          );
          succeeded = true;
          homeworkThrough = chunkEnd;
        }
      } catch (_) {
        // The next launch retries the missing interval.
        break;
      }
      chunkStart = chunkEnd.add(const Duration(days: 1));
    }
    if (succeeded) {
      await _store.write(markerKey, {
        'capturedThrough': untisDateInt(now),
        if (homeworkThrough != null)
          'homeworkThrough': untisDateInt(homeworkThrough),
      });
    }
  }

  Future<T> _run<T>(
    UntisAccount account,
    Future<T> Function(WebUntisRequestContext) request,
  ) => _sessions.runAuthenticated<T>(
    account: WebUntisAccountLogin(
      accountId: account.id,
      username: account.username,
      schoolUrl: account.schoolUrl,
      schoolName: account.schoolName,
      personId: account.personId,
      personType: account.personType,
    ),
    currentSessionId: account.sessionId,
    request: request,
  );

  Future<void> fillMissing({
    required UntisAccount account,
    required WrappedYear year,
    void Function(int done, int total)? onProgress,
    bool Function()? cancelled,
  }) async {
    final today = DateTime.now();
    final lastDay = year.end.isBefore(today) ? year.end : today;
    var monday = year.start.subtract(Duration(days: year.start.weekday - 1));
    final mondays = <DateTime>[];
    while (!monday.isAfter(lastDay)) {
      mondays.add(monday);
      monday = monday.add(const Duration(days: 7));
    }
    var done = 0;
    final total = mondays.length + 4;
    void step() => onProgress?.call(++done, total);
    final timetable = TimetableRepository(client: _client);
    for (final weekStart in mondays) {
      if (cancelled?.call() == true) return;
      final wrappedKey = _key(
        account.id,
        'Week',
        '${year.id}|${untisDateString(weekStart)}',
      );
      if (await _store.read(wrappedKey) != null) {
        step();
        continue;
      }
      final legacyKey = _store.scopedKey(
        accountId: account.id,
        dataset: 'timetableWeek',
        entityKey:
            'weekCacheV1|${account.schoolUrl}|${account.schoolName}|'
            '${account.personType}|${account.personId}|${untisDateString(weekStart)}',
      );
      final cached = await _store.read(legacyKey);
      if (cached?.value['weekData'] is Map) {
        await _store.write(wrappedKey, {
          'monday': untisDateInt(weekStart),
          'days': cached!.value['weekData'],
        });
        step();
        continue;
      }
      try {
        final raw = await _run(
          account,
          (context) => timetable.fetchTimetable(
            context: context,
            elementId: account.personId,
            elementType: account.personType,
            startDate: weekStart.isBefore(year.start) ? year.start : weekStart,
            endDate: weekStart.add(const Duration(days: 4)).isAfter(lastDay)
                ? lastDay
                : weekStart.add(const Duration(days: 4)),
            requestId: 'wrapped_${untisDateString(weekStart)}',
          ),
        );
        final days = <String, List<dynamic>>{
          for (var i = 0; i < 5; i++) '$i': <dynamic>[],
        };
        for (final item in raw.whereType<Map>()) {
          final date = parseUntisDate(item['date']);
          if (date == null || date.weekday > 5 || !year.contains(date)) {
            continue;
          }
          days['${date.weekday - 1}']!.add(Map<String, dynamic>.from(item));
        }
        await _store.write(wrappedKey, {
          'monday': untisDateInt(weekStart),
          'days': days,
        });
      } on WebUntisFailure catch (failure) {
        if (failure.kind == WebUntisFailureKind.authentication ||
            failure.kind == WebUntisFailureKind.offline ||
            failure.kind == WebUntisFailureKind.timeout ||
            failure.kind == WebUntisFailureKind.permission) {
          return;
        }
        // An unavailable historic week remains absent and can be retried.
      } catch (_) {
        // Failed weeks remain absent and can be retried later.
      }
      step();
    }
    if (cancelled?.call() == true) return;
    if (await _store.read(_key(account.id, 'Holidays', year.id)) == null) {
      try {
        final holidays = await _run(account, timetable.fetchHolidays);
        await recordHolidays(
          accountId: account.id,
          year: year,
          holidays: holidays,
        );
      } catch (_) {}
    }
    step();
    if (cancelled?.call() == true) return;
    if ((await _store.read(
          _key(account.id, 'Absences', year.id),
        ))?.value['complete'] !=
        true) {
      try {
        final response = await _run(
          account,
          (context) => _client.rpc(
            context: context,
            method: 'getTimetableWithAbsences',
            requestId: 'wrapped_absences_${year.id}',
            params: {
              'options': {
                'startDate': untisDateInt(year.start),
                'endDate': untisDateInt(lastDay),
              },
            },
          ),
        );
        final value = response['result'];
        if (value is! List &&
            !(value is Map && value['periodsWithAbsences'] is List)) {
          throw const FormatException('Unexpected absence response');
        }
        final raw = value is List
            ? value
            : value is Map && value['periodsWithAbsences'] is List
            ? value['periodsWithAbsences'] as List
            : const <dynamic>[];
        await _store.write(_key(account.id, 'Absences', year.id), {
          'items': raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
          'complete': true,
        });
      } catch (_) {}
    }
    step();
    if (cancelled?.call() == true) return;
    if ((await _store.read(
          _key(account.id, 'Exams', year.id),
        ))?.value['complete'] !=
        true) {
      try {
        final exams = await _run(
          account,
          (context) => WebUntisExamRepository(client: _client).fetch(
            context: context,
            personId: account.personId,
            start: year.start,
            end: lastDay,
          ),
        );
        if (exams.isNotEmpty) {
          await _store.write(_key(account.id, 'Exams', year.id), {
            'items': exams,
            'complete': true,
          });
        }
      } catch (_) {}
    }
    step();
    if (cancelled?.call() == true) return;
    var from = year.start;
    while (!from.isAfter(lastDay)) {
      if (cancelled?.call() == true) return;
      final until = from.add(const Duration(days: 41));
      final to = until.isAfter(lastDay) ? lastDay : until;
      final key = _key(
        account.id,
        'Homework',
        '${year.id}|${untisDateString(from)}',
      );
      if (await _store.read(key) == null) {
        try {
          final response = await _run(
            account,
            (context) => _client.rpc(
              context: context,
              method: 'getHomeWork2017',
              requestId: 'wrapped_hw_${untisDateString(from)}',
              params: [
                {
                  'id': account.personId,
                  'type': account.personType == 5 ? 'STUDENT' : 'TEACHER',
                  'startDate': untisDateInt(from),
                  'endDate': untisDateInt(to),
                },
              ],
            ),
          );
          final result = response['result'];
          final items = <Map<String, dynamic>>[];
          if (result is Map && result['homeworks'] is List) {
            items.addAll(
              (result['homeworks'] as List).whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ),
            );
          }
          await _store.write(key, {'items': items});
        } catch (_) {
          // Failed chunks remain absent and can be retried independently.
        }
      }
      from = to.add(const Duration(days: 1));
    }
    step();
  }

  Future<WrappedSnapshot> snapshot({
    required String accountId,
    required WrappedYear year,
    required List<Map<String, dynamic>> grades,
    required List<Map<String, dynamic>> customExams,
    required List<Map<String, dynamic>> customHomework,
  }) async {
    final weekDocs = await _store.readEntriesWithPrefix(
      '$accountId|wrappedWeek|${year.id}|',
    );
    final holidayDoc = await _store.read(_key(accountId, 'Holidays', year.id));
    final absenceDoc = await _store.read(_key(accountId, 'Absences', year.id));
    final examDoc = await _store.read(_key(accountId, 'Exams', year.id));
    final homeworkDocs = await _store.readEntriesWithPrefix(
      '$accountId|wrappedHomework|${year.id}|',
    );
    final recentHomework = await _store.read(
      _key(accountId, 'HomeworkRecent', year.id),
    );
    return buildWrappedSnapshot(
      year: year,
      weekDocuments: weekDocs.values.map((e) => e.value).toList(),
      holidays: _maps(holidayDoc?.value['holidays']),
      absences: _maps(absenceDoc?.value['items']),
      exams: [..._maps(examDoc?.value['items']), ...customExams],
      homework: [
        for (final doc in homeworkDocs.values) ..._maps(doc.value['items']),
        ..._maps(recentHomework?.value['items']),
        ...customHomework,
      ],
      grades: grades,
      hasAbsenceSource: absenceDoc != null,
      hasHolidaySource: holidayDoc != null,
      hasExamSource: examDoc != null || customExams.isNotEmpty,
      hasHomeworkSource:
          homeworkDocs.isNotEmpty ||
          recentHomework != null ||
          customHomework.isNotEmpty,
    );
  }
}

List<Map<String, dynamic>> _maps(Object? raw) => raw is List
    ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

WrappedSnapshot buildWrappedSnapshot({
  required WrappedYear year,
  required List<Map<String, dynamic>> weekDocuments,
  required List<Map<String, dynamic>> holidays,
  required List<Map<String, dynamic>> absences,
  required List<Map<String, dynamic>> exams,
  required List<Map<String, dynamic>> homework,
  required List<Map<String, dynamic>> grades,
  required bool hasAbsenceSource,
  required bool hasHolidaySource,
  bool hasExamSource = false,
  bool hasHomeworkSource = false,
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final through = year.end.isBefore(now) ? year.end : now;
  final firstMonday = year.start.subtract(
    Duration(days: year.start.weekday - 1),
  );
  final expectedWeeks = through.isBefore(year.start)
      ? 0
      : (through.difference(firstMonday).inDays ~/ 7) + 1;
  final periods = <String, Map<String, dynamic>>{};
  final coveredDays = <int>{};
  final coveredMondays = <int>{};
  for (final document in weekDocuments) {
    final monday = parseUntisDate(document['monday']);
    final days = document['days'];
    if (monday == null || days is! Map) continue;
    if (!monday.isAfter(through) &&
        !monday.add(const Duration(days: 4)).isBefore(year.start)) {
      coveredMondays.add(untisDateInt(monday));
    }
    for (var index = 0; index < 5; index++) {
      final day = monday.add(Duration(days: index));
      if (!year.contains(day) || day.isAfter(through)) continue;
      coveredDays.add(untisDateInt(day));
      final lessons = days['$index'];
      if (lessons is! List) continue;
      for (final raw in lessons.whereType<Map>()) {
        final lesson = Map<String, dynamic>.from(raw);
        final date = parseUntisDate(lesson['date']) ?? day;
        if (!year.contains(date) || date.isAfter(through)) continue;
        final start = lesson['startTime']?.toString() ?? '';
        final end = lesson['endTime']?.toString() ?? '';
        final id =
            lesson['id'] ??
            lesson['lsid'] ??
            lesson['_subjectShort'] ??
            lesson['subject'] ??
            '';
        periods['${untisDateInt(date)}|$start|$end|$id'] = lesson;
      }
    }
  }
  var lessonCount = 0;
  var cancelled = 0;
  var substitutions = 0;
  var minutes = 0;
  final taught = <MapEntry<int, Map<String, dynamic>>>[];
  for (final lesson in periods.values) {
    final code = lesson['code']?.toString().toLowerCase() ?? '';
    if (code == 'cancelled' || lesson['cancelled'] == true) {
      cancelled++;
      continue;
    }
    lessonCount++;
    if (code == 'irregular' || code == 'substitution') substitutions++;
    final start = untisTimeToMinutes(lesson['startTime']);
    final end = untisTimeToMinutes(lesson['endTime']);
    if (start != null && end != null && end > start) {
      minutes += math.min(end - start, 240);
    }
    final date = normalizeUntisDateInt(lesson['date']);
    if (date != null) taught.add(MapEntry(date, lesson));
  }

  final absentPeriodKeys = <String>{};
  final absenceIds = <String>{};
  var excused = 0;
  var unexcused = 0;
  for (final absence in absences) {
    final date = normalizeUntisDateInt(absence['date'] ?? absence['startDate']);
    if (date == null ||
        date < untisDateInt(year.start) ||
        date > untisDateInt(through)) {
      continue;
    }
    final key =
        '$date|${absence['id'] ?? ''}|'
        '${absence['startTime']}|${absence['endTime']}';
    if (!absenceIds.add(key)) continue;
    final status = (absence['status'] ?? absence['excuseStatus'] ?? '')
        .toString()
        .toLowerCase();
    if (absence['excused'] == true ||
        status == 'excused' ||
        status == 'entschuldigt') {
      excused++;
    }
    if (status == 'unexcused' || status == 'unentschuldigt') {
      unexcused++;
    }
    final from = untisTimeToMinutes(absence['startTime']);
    final to = untisTimeToMinutes(absence['endTime']);
    if (from == null || to == null) continue;
    for (final item in taught.where((item) => item.key == date)) {
      final start = untisTimeToMinutes(item.value['startTime']);
      final end = untisTimeToMinutes(item.value['endTime']);
      if (start == null || end == null || start >= to || end <= from) {
        continue;
      }
      absentPeriodKeys.add('$date|$start|$end');
    }
  }

  final holidayDays = <int>{};
  final names = <String>{};
  for (final holiday in holidays) {
    final start = parseUntisDate(holiday['startDate']);
    final end = parseUntisDate(holiday['endDate']);
    if (start == null || end == null) continue;
    final name = (holiday['longName'] ?? holiday['name'] ?? '')
        .toString()
        .trim();
    if (name.isNotEmpty &&
        !end.isBefore(year.start) &&
        !start.isAfter(through)) {
      names.add(name);
    }
    var day = start.isBefore(year.start) ? year.start : start;
    final last = end.isAfter(through) ? through : end;
    while (!day.isAfter(last)) {
      if (day.weekday <= 5) {
        holidayDays.add(untisDateInt(day));
      }
      day = day.add(const Duration(days: 1));
    }
  }
  final freeDays = <int>{...holidayDays};
  final cancelledDays = <int>{};
  for (final lesson in periods.values) {
    if (lesson['code']?.toString().toLowerCase() == 'cancelled' ||
        lesson['cancelled'] == true) {
      final date = normalizeUntisDateInt(lesson['date']);
      if (date != null) cancelledDays.add(date);
    }
  }
  for (final date in coveredDays.intersection(cancelledDays)) {
    if (!periods.values.any(
      (lesson) =>
          normalizeUntisDateInt(lesson['date']) == date &&
          lesson['code']?.toString().toLowerCase() != 'cancelled' &&
          lesson['cancelled'] != true,
    )) {
      freeDays.add(date);
    }
  }

  final gradeIds = <String>{};
  final subjectCounts = <String, int>{};
  for (final grade in grades) {
    final date = DateTime.tryParse(grade['date']?.toString() ?? '');
    if (date == null || !year.contains(date) || date.isAfter(through)) continue;
    final value = num.tryParse(grade['value']?.toString() ?? '');
    if (value == null || !value.isFinite) continue;
    final id =
        grade['id']?.toString() ??
        '${grade['subject']}|${grade['date']}|$value';
    if (!gradeIds.add(id)) continue;
    final subject = grade['subject']?.toString().trim() ?? '';
    if (subject.isNotEmpty) {
      subjectCounts.update(subject, (n) => n + 1, ifAbsent: () => 1);
    }
  }

  int uniqueDated(List<Map<String, dynamic>> items, List<String> fields) {
    final ids = <String>{};
    for (final item in items) {
      DateTime? date;
      for (final field in fields) {
        date =
            parseUntisDate(item[field]) ??
            DateTime.tryParse(item[field]?.toString() ?? '');
        if (date != null) break;
      }
      if (date == null || !year.contains(date) || date.isAfter(through)) {
        continue;
      }
      ids.add(item['id']?.toString() ?? item.toString());
    }
    return ids.length;
  }

  return WrappedSnapshot(
    year: year,
    coveredWeeks: coveredMondays.length,
    expectedWeeks: expectedWeeks,
    lessons: lessonCount,
    lessonMinutes: minutes,
    cancelled: cancelled,
    substitutions: substitutions,
    absentLessons: absentPeriodKeys.length,
    absenceRecords: absenceIds.length,
    excusedAbsences: excused,
    unexcusedAbsences: unexcused,
    freeWeekdays: freeDays.length,
    holidayNames: names.toList()..sort(),
    grades: gradeIds.length,
    gradeSubjects: subjectCounts,
    exams: uniqueDated(exams, ['date', 'examDate', 'startDate']),
    homework: uniqueDated(homework, ['dueDate', 'date']),
    hasAbsenceSource: hasAbsenceSource,
    hasHolidaySource: hasHolidaySource,
    hasExamSource: hasExamSource,
    hasHomeworkSource: hasHomeworkSource,
  );
}
