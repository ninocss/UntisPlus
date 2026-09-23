import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../core/time_utils.dart';
import '../core/version_utils.dart';
import '../data/cache/offline_cache_store.dart';
import '../data/security/credential_vault.dart';
import '../data/webuntis/webuntis_client.dart';
import '../data/webuntis/webuntis_session_manager.dart';
import '../features/changes/data/change_repository.dart';
import '../features/changes/domain/timetable_change.dart';
import '../features/accounts/data/untis_account_store.dart';
import '../features/updates/data/github_release_repository.dart';
import '../l10n.dart';

import 'demo_mode_service.dart';
import 'live_activity_service.dart';
import 'notification_service.dart';
import 'alarm_service.dart';
import 'widget_service.dart';

const String kTimetableUpdateTask = 'update_timetable_task';
const String kGithubUpdateCheckTask = 'check_github_updates_task';
const String kProgressiveCacheRefreshTask = 'refresh_progressive_cache_task';

/// Fixed unique name for the one-off boundary refresh. iOS delivers the unique
/// name (not the task name) to the handler, so the dispatcher recognizes both.
const String kProgressiveBoundaryRefreshId =
    'untis_progressive_boundary_refresh';

final WebUntisClient _backgroundWebUntisClient = WebUntisClient();
final WebUntisSessionManager _backgroundWebUntisSessions =
    WebUntisSessionManager(client: _backgroundWebUntisClient);
final GithubReleaseRepository _backgroundGithubReleases =
    GithubReleaseRepository();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await NotificationService().init();
      if (task == kGithubUpdateCheckTask) {
        await checkGithubUpdateAndNotify();
      } else if (task == kProgressiveCacheRefreshTask ||
          task == kProgressiveBoundaryRefreshId) {
        await refreshProgressiveNotificationFromCache();
      } else {
        await updateUntisData();
      }
    } catch (e) {
      debugPrint("Background Task Error: $e");
    }
    return Future.value(true);
  });
}

class BackgroundService {
  static void initialize() {
    if (kIsWeb) return;

    Workmanager().initialize(callbackDispatcher);
    Workmanager().registerPeriodicTask(
      "untis_school_notification_update",
      kTimetableUpdateTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );

    if (!Platform.isIOS) {
      Workmanager().registerPeriodicTask(
        'untis_github_update_check',
        kGithubUpdateCheckTask,
        frequency: const Duration(hours: 6),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }
  }
}

String _localizedUpdateTitle(String locale) {
  return appL10nFor(locale).bgUpdateTitle;
}

String _localizedDailyBriefingTitle(String locale) {
  return appL10nFor(locale).bgDailyBriefingTitle;
}

String _localizedDailyBriefingBody(
  String locale, {
  required String firstStart,
  required String lastEnd,
  required int lessonCount,
  required int breakCount,
}) {
  return appL10nFor(
    locale,
  ).bgDailyBriefingBody(firstStart, lastEnd, lessonCount, breakCount);
}

String _localizedDailyBriefingExpanded(
  String locale, {
  required String firstStart,
  required String lastEnd,
  required int lessonCount,
  required int breakCount,
  required String nextLesson,
}) {
  return appL10nFor(locale).bgDailyBriefingExpanded(
    firstStart,
    lastEnd,
    lessonCount,
    breakCount,
    nextLesson,
  );
}

Future<String> _authenticateBackgroundAccount({
  required WebUntisAccountLogin account,
  required String password,
  required String credentialMode,
  required String clientName,
}) async {
  final session = await _backgroundWebUntisSessions.authenticateWithCredentials(
    account: account,
    credentials: AccountCredentials(
      password: password,
      credentialMode: credentialMode,
      sessionId: '',
    ),
    passwordClient: clientName,
  );
  return session.sessionId;
}

Future<List<dynamic>?> _fetchAuthenticatedTimetable({
  required WebUntisAccountLogin account,
  required String currentSessionId,
  required int startDate,
  required int endDate,
  required String requestId,
}) async {
  final response = await _backgroundWebUntisSessions.runAuthenticated(
    account: account,
    currentSessionId: currentSessionId,
    request: (context) => _backgroundWebUntisClient.rpc(
      context: context,
      method: 'getTimetable',
      requestId: requestId,
      params: {
        'options': {
          'element': {'id': account.personId, 'type': account.personType},
          'startDate': startDate,
          'endDate': endDate,
          'showLsText': true,
          'showSubstText': true,
          'showInfo': true,
          'showBooking': true,
        },
      },
    ),
  );
  final result = response['result'];
  return switch (result) {
    List<dynamic> value => value,
    Map value when value['timetable'] is List<dynamic> =>
      value['timetable'] as List<dynamic>,
    _ => null,
  };
}

String _localizedImportantChangesTitle(String locale) {
  return appL10nFor(locale).bgChangesTitle;
}

String _localizedImportantChangesBody(String locale) {
  return appL10nFor(locale).bgChangesBody;
}

String _localizedStatusCurrentLesson(String locale) {
  return appL10nFor(locale).bgCurrentLesson;
}

String _localizedLessonStartsAt(String locale, String start) {
  return appL10nFor(locale).bgLessonStarts(start);
}

String _localizedUntilTime(String locale, String end) {
  return appL10nFor(locale).bgUntil(end);
}

String _localizedClosedLabel(String locale) {
  return appL10nFor(locale).bgFinished;
}

String _localizedFreeLabel(String locale) {
  return appL10nFor(locale).bgFreePeriod;
}

String _localizedFallbackLessonName(String locale, String start, String end) {
  return appL10nFor(locale).bgFallbackLesson(start, end);
}

Map<String, int> _detectChangeCounts({
  required String previousSignature,
  required String currentSignature,
}) {
  if (previousSignature.trim().isEmpty) {
    return const {'cancelled': 0, 'room': 0, 'substitution': 0, 'other': 0};
  }

  List<dynamic> previousLessons;
  List<dynamic> currentLessons;
  try {
    previousLessons = jsonDecode(previousSignature) as List<dynamic>;
    currentLessons = jsonDecode(currentSignature) as List<dynamic>;
  } catch (_) {
    return const {'cancelled': 0, 'room': 0, 'substitution': 0, 'other': 1};
  }

  String keyFor(Map<dynamic, dynamic> lesson) {
    final start = lesson['startTime']?.toString() ?? '';
    final end = lesson['endTime']?.toString() ?? '';
    final su = lesson['su']?.toString() ?? '';
    return '$start|$end|$su';
  }

  final previousMap = <String, Map<dynamic, dynamic>>{};
  for (final lesson in previousLessons) {
    if (lesson is Map) {
      previousMap[keyFor(lesson)] = lesson;
    }
  }

  var cancelled = 0;
  var room = 0;
  var substitution = 0;
  var other = 0;

  for (final lesson in currentLessons) {
    if (lesson is! Map) continue;
    final key = keyFor(lesson);
    final prev = previousMap[key];
    if (prev == null) {
      other++;
      continue;
    }

    final prevCode = (prev['code'] ?? '').toString().toLowerCase();
    final nextCode = (lesson['code'] ?? '').toString().toLowerCase();
    if (prevCode != nextCode &&
        (nextCode.contains('cancel') || nextCode == 'cancelled')) {
      cancelled++;
      continue;
    }

    final prevRoom = (prev['ro'] ?? '').toString();
    final nextRoom = (lesson['ro'] ?? '').toString();
    if (prevRoom != nextRoom) {
      room++;
      continue;
    }

    final prevTeacher = (prev['te'] ?? '').toString();
    final nextTeacher = (lesson['te'] ?? '').toString();
    if (prevTeacher != nextTeacher) {
      substitution++;
      continue;
    }
  }

  return {
    'cancelled': cancelled,
    'room': room,
    'substitution': substitution,
    'other': other,
  };
}

String _localizedChangeSummary(String locale, Map<String, int> counts) {
  final l = appL10nFor(locale);
  final cancelled = counts['cancelled'] ?? 0;
  final room = counts['room'] ?? 0;
  final substitution = counts['substitution'] ?? 0;
  final other = counts['other'] ?? 0;
  final parts = <String>[];
  if (cancelled > 0) {
    parts.add(l.bgChangesCancelled(cancelled));
  }
  if (room > 0) parts.add(l.bgChangesRoom(room));
  if (substitution > 0) {
    parts.add(l.bgChangesSubstitution(substitution));
  }
  if (other > 0 || parts.isEmpty) {
    parts.add(l.bgChangesOther(other > 0 ? other : 1));
  }
  return parts.join(' · ');
}

String _backgroundLessonIdentity(Map<dynamic, dynamic> lesson) =>
    TimetableLessonSnapshot.fromJson(lesson).identity;

Future<bool> _notifyNewlyDetectedChanges({
  required SharedPreferences prefs,
  required List<Map<dynamic, dynamic>> fullLessons,
  required String locale,
  required String currentLesson,
  required String nextLesson,
  required bool isDemoMode,
  required String activeAccountId,
}) async {
  if (isDemoMode || activeAccountId.isEmpty || fullLessons.isEmpty) {
    return false;
  }

  final repository = ChangeRepository();
  final previousIds = (await repository.loadChanges(
    activeAccountId,
  )).map((change) => change.id).toSet();
  final byMonday = <String, List<Map<dynamic, dynamic>>>{};
  for (final lesson in fullLessons) {
    final day = parseUntisDate(lesson['date']);
    if (day == null) continue;
    final monday = day.subtract(Duration(days: day.weekday - 1));
    byMonday
        .putIfAbsent(untisDateString(monday), () => <Map<dynamic, dynamic>>[])
        .add(lesson);
  }

  for (final entry in byMonday.entries) {
    await repository.recordSnapshot(
      accountId: activeAccountId,
      rangeKey: entry.key,
      lessons: entry.value,
      dataset: 'backgroundSnapshot',
    );
  }

  final newChanges = (await repository.loadChanges(activeAccountId))
      .where((change) => !previousIds.contains(change.id))
      .toList(growable: false);
  if (newChanges.isEmpty) return false;

  final notifyCancellations =
      prefs.getBool('notifyChangeCancellations') ?? true;
  final notifyRoom = prefs.getBool('notifyChangeRoom') ?? true;
  final notifyTeacher = prefs.getBool('notifyChangeTeacher') ?? true;
  final notifyOther = prefs.getBool('notifyChangeOther') ?? true;
  final allowed = newChanges
      .where((change) {
        return switch (change.type) {
          TimetableChangeType.cancelled ||
          TimetableChangeType.restored => notifyCancellations,
          TimetableChangeType.room => notifyRoom,
          TimetableChangeType.teacher => notifyTeacher,
          _ => notifyOther,
        };
      })
      .toList(growable: false);
  if (allowed.isEmpty) return false;

  final lessonsByIdentity = <String, Map<dynamic, dynamic>>{
    for (final lesson in fullLessons) _backgroundLessonIdentity(lesson): lesson,
  };
  final first = allowed.first;
  final firstLesson = lessonsByIdentity[first.lessonIdentity];
  final firstDate = first.date == 0 ? null : first.date;
  final firstStart = (firstLesson?['startTime'] as num?)?.toInt();
  final day = parseUntisDate(firstDate);
  final dayLabel = day == null ? '' : DateFormat('dd.MM.').format(day);
  final detail =
      dayLabel.isNotEmpty && firstStart != null && first.subject.isNotEmpty
      ? '$dayLabel ${formatUntisTime(firstStart.toString())} · ${first.subject}'
      : _localizedChangeSummary(locale, const {'other': 1});

  await NotificationService().showImportantChangeNotification(
    title: _localizedImportantChangesTitle(locale),
    body: '${_localizedImportantChangesBody(locale)} · $detail',
    locale: locale,
    currentLesson: currentLesson,
    nextLesson: nextLesson,
    changeDate: firstDate,
    changeStartTime: firstStart,
  );
  return true;
}

String _localizedUpdateBody(String locale, String latestVersion) {
  return appL10nFor(locale).bgUpdateBody(latestVersion);
}

Future<void> checkGithubUpdateAndNotify() async {
  final prefs = await SharedPreferences.getInstance();
  final installedVersion = (await PackageInfo.fromPlatform()).version;
  final locale = prefs.getString('appLocale') ?? 'de';

  try {
    final release = await _backgroundGithubReleases.fetchLatest();
    final latestVersion = release.version;
    final hasComparableVersion = RegExp(r'\d').hasMatch(latestVersion);

    final hasUpdate =
        latestVersion.isNotEmpty &&
        (hasComparableVersion
            ? compareVersionStrings(installedVersion, latestVersion) < 0
            : true);

    if (!hasUpdate) {
      await NotificationService().cancelNotification(NotificationIds.update);
      return;
    }

    await NotificationService().showUpdateNotification(
      id: NotificationIds.update,
      title: _localizedUpdateTitle(locale),
      body: _localizedUpdateBody(locale, latestVersion),
      locale: locale,
    );
  } catch (_) {
    // Keep silent in background; no user-facing error notification needed.
  }
}

/// Returns true only after a valid current-day timetable response was applied.
Future<bool> updateUntisData() async {
  final prefs = await SharedPreferences.getInstance();
  final isDemoMode = prefs.getBool('demoMode') ?? false;
  final activeAccountId = prefs.getString('activeUntisAccountId') ?? '';
  final credentials = isDemoMode || activeAccountId.isEmpty
      ? const AccountCredentials(
          password: '',
          credentialMode: 'password',
          sessionId: '',
        )
      : await CredentialVault.instance.readAccount(activeAccountId);
  final schoolUrl = prefs.getString('schoolUrl') ?? '';
  final schoolName = prefs.getString('schoolName') ?? '';
  final user = prefs.getString('username') ?? '';
  // Legacy fallback remains read-only until foreground migration succeeds.
  final pass = credentials.password.isNotEmpty
      ? credentials.password
      : prefs.getString('password') ?? '';
  final useLoginKey = credentials.password.isNotEmpty
      ? credentials.credentialMode == 'loginKey'
      : prefs.getString('loginCredentialMode') == 'loginKey';
  final locale = prefs.getString('appLocale') ?? 'de';
  final l = appL10nFor(locale);

  if (!isDemoMode &&
      (schoolUrl.isEmpty ||
          schoolName.isEmpty ||
          user.isEmpty ||
          pass.isEmpty)) {
    return false;
  }

  final now = DateTime.now();
  List<dynamic> lessons = [];
  var hasValidTimetableResult = isDemoMode;
  if (isDemoMode) {
    // Keep enough future data for the smart alarm to bridge weekends and a
    // fully cancelled day as well.
    final firstDay = DateTime(now.year, now.month, now.day);
    for (var offset = 0; offset < 15; offset++) {
      final day = firstDay.add(Duration(days: offset));
      final monday = day.subtract(Duration(days: day.weekday - 1));
      lessons.addAll(
        DemoModeService.buildWeek(monday, locale: locale)[day.weekday - 1] ??
            const [],
      );
    }
  } else {
    final personId = prefs.getInt('personId') ?? 0;
    final personType = prefs.getInt('personType') ?? 5;
    if (personId == 0) return false;
    final todayDate = int.parse(DateFormat('yyyyMMdd').format(now));
    final finalPlanningDate = int.parse(
      DateFormat('yyyyMMdd').format(now.add(const Duration(days: 14))),
    );

    try {
      List<dynamic>? fetched;
      if (activeAccountId.isNotEmpty && credentials.password.isNotEmpty) {
        fetched = await _fetchAuthenticatedTimetable(
          account: WebUntisAccountLogin(
            accountId: activeAccountId,
            username: user,
            schoolUrl: schoolUrl,
            schoolName: schoolName,
            personId: personId,
            personType: personType,
          ),
          currentSessionId: credentials.sessionId,
          startDate: todayDate,
          endDate: finalPlanningDate,
          requestId: 'bg_req_$activeAccountId',
        );
      } else {
        final sessionId = await _authenticateBackgroundAccount(
          account: WebUntisAccountLogin(
            accountId: activeAccountId.isEmpty ? 'legacy' : activeAccountId,
            username: user,
            schoolUrl: schoolUrl,
            schoolName: schoolName,
            personId: personId,
            personType: personType,
          ),
          password: pass,
          credentialMode: useLoginKey ? 'loginKey' : 'password',
          clientName: 'UntisPlusWidget',
        );
        if (sessionId.isEmpty) return false;
        final response = await _backgroundWebUntisClient.rpc(
          context: WebUntisRequestContext(
            schoolUrl: schoolUrl,
            schoolName: schoolName,
            sessionId: sessionId,
          ),
          method: 'getTimetable',
          requestId: 'bg_req',
          params: {
            'options': {
              'element': {'id': personId, 'type': personType},
              'startDate': todayDate,
              'endDate': finalPlanningDate,
              'showLsText': true,
              'showSubstText': true,
              'showInfo': true,
              'showBooking': true,
            },
          },
        );
        final result = response['result'];
        fetched = switch (result) {
          List<dynamic> value => value,
          Map value when value['timetable'] is List<dynamic> =>
            value['timetable'] as List<dynamic>,
          _ => null,
        };
      }
      if (fetched != null) {
        lessons = fetched;
        hasValidTimetableResult = true;
      }
    } catch (_) {
      return false;
    }
  }

  // A malformed or incomplete server response must never silently remove an
  // already confirmed smart alarm. An actual empty timetable remains valid.
  if (!hasValidTimetableResult) return false;

  final fullLessons = lessons.whereType<Map>().toList(growable: false);

  // The alarm must see the raw server plan: hiding a subject is a display
  // preference, not a reason to sleep through a real lesson.
  await AlarmService.instance.syncSmartAlarmWithTimetable(lessons, now: now);

  // The notification/status UI below intentionally remains limited to today.
  final todayDate = int.parse(DateFormat('yyyyMMdd').format(now));
  lessons = lessons
      .whereType<Map>()
      .where(
        (lesson) =>
            lesson['date'] is num &&
            (lesson['date'] as num).toInt() == todayDate,
      )
      .toList(growable: false);

  // Respect user-hidden subjects and the "show cancelled" setting
  final hiddenSubjects = prefs.getStringList('hiddenSubjects') ?? <String>[];
  final showCancelled = prefs.getBool('showCancelled') ?? true;

  lessons = lessons
      .whereType<Map>()
      .where(
        (l) => !hiddenSubjects.contains(l['_subjectShort']?.toString() ?? ''),
      )
      .where((l) => showCancelled || (l['code'] ?? '') != 'cancelled')
      .toList(growable: false);

  if (lessons.isEmpty) {
    await NotificationService().cancelNotification(
      NotificationIds.currentLesson,
    );
    return true;
  }

  lessons.sort(
    (a, b) => (a['startTime'] as int).compareTo(b['startTime'] as int),
  );

  final lessonSignature = jsonEncode(
    lessons
        .whereType<Map>()
        .map(
          (lesson) => {
            'startTime': lesson['startTime'],
            'endTime': lesson['endTime'],
            'code': lesson['code'],
            'lstype': lesson['lstype'],
            'su': lesson['su'],
            'ro': lesson['ro'],
            'te': lesson['te'],
            'kl': lesson['kl'],
          },
        )
        .toList(growable: false),
  );

  String currentLessonName = _localizedFreeLabel(locale);
  String nextLessonName = "-";
  String timeRemaining = "";

  final currentTimeInt = now.hour * 100 + now.minute;
  bool hasActiveLesson = false;

  int? currentProgress;
  int? maxProgress;
  int? startTimeMs;
  int? endTimeMs;

  int computeBreakCount(List<dynamic> dayLessons) {
    var breaks = 0;
    for (var i = 0; i < dayLessons.length - 1; i++) {
      final currentEnd = dayLessons[i]['endTime'];
      final nextStart = dayLessons[i + 1]['startTime'];
      if (currentEnd is int && nextStart is int && nextStart > currentEnd) {
        breaks++;
      }
    }
    return breaks;
  }

  DateTime untisTimeToDate(int timeStr) {
    final hour = timeStr ~/ 100;
    final minute = timeStr % 100;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String lessonDisplayName(Map<dynamic, dynamic> lesson) {
    final subjectList = lesson['su'];
    if (subjectList is List && subjectList.isNotEmpty) {
      final first = subjectList.first;
      if (first is Map) {
        final raw =
            first['longName'] ?? first['longname'] ?? first['name'] ?? '';
        final label = raw.toString().trim();
        if (label.isNotEmpty) return label;
      }
    }

    final start = lesson['startTime'];
    final end = lesson['endTime'];
    if (start is int && end is int) {
      final startStr = formatUntisTime(start.toString());
      final endStr = formatUntisTime(end.toString());
      return _localizedFallbackLessonName(locale, startStr, endStr);
    }

    return _localizedStatusCurrentLesson(locale);
  }

  for (int i = 0; i < lessons.length; i++) {
    var l = lessons[i];
    int start = l['startTime'] as int;
    int end = l['endTime'] as int;

    final name = lessonDisplayName(l);

    String startStr = formatUntisTime(start.toString());
    String endStr = formatUntisTime(end.toString());

    if (currentTimeInt >= start && currentTimeInt <= end) {
      hasActiveLesson = true;
      currentLessonName = name;
      timeRemaining = _localizedUntilTime(locale, endStr);

      final startTimeDate = untisTimeToDate(start);
      final endTimeDate = untisTimeToDate(end);

      maxProgress = endTimeDate.difference(startTimeDate).inMinutes;
      currentProgress = now.difference(startTimeDate).inMinutes;
      startTimeMs = startTimeDate.millisecondsSinceEpoch;
      endTimeMs = endTimeDate.millisecondsSinceEpoch;

      if (i + 1 < lessons.length) {
        final nextL = lessons[i + 1];
        nextLessonName = lessonDisplayName(nextL);
      } else {
        nextLessonName = _localizedClosedLabel(locale);
      }
      break;
    }

    if (currentTimeInt < start) {
      timeRemaining = _localizedLessonStartsAt(locale, startStr);
      nextLessonName = name;
      endTimeMs = untisTimeToDate(start).millisecondsSinceEpoch;
      break;
    }
  }

  final firstLesson = lessons.first;
  final lastLesson = lessons.last;
  final firstStart = formatUntisTime(
    (firstLesson['startTime'] as int).toString(),
  );
  final lastEnd = formatUntisTime((lastLesson['endTime'] as int).toString());
  final breakCount = computeBreakCount(lessons);

  if (!hasActiveLesson && currentTimeInt > (lessons.last['endTime'] as int)) {
    await NotificationService().cancelNotification(
      NotificationIds.currentLesson,
    );
    await LiveActivityService.instance.end();
    return true;
  }

  final isProgressivePushEnabled = prefs.getBool('progressivePush') ?? true;
  final isDailyBriefingEnabled = prefs.getBool('dailyBriefingPush') ?? true;
  final isImportantChangesEnabled =
      prefs.getBool('importantChangesPush') ?? true;
  await NotificationService().init();

  final todayKey = DateFormat('yyyyMMdd').format(now);
  final lastBriefingDate = prefs.getString('lastDailyBriefingDate') ?? '';
  final firstStartInt = firstLesson['startTime'] as int;
  final canSendBriefingNow = currentTimeInt <= firstStartInt && now.hour < 12;

  if (isDailyBriefingEnabled &&
      lastBriefingDate != todayKey &&
      canSendBriefingNow) {
    await NotificationService().showDailyBriefingNotification(
      title: _localizedDailyBriefingTitle(locale),
      body: _localizedDailyBriefingBody(
        locale,
        firstStart: firstStart,
        lastEnd: lastEnd,
        lessonCount: lessons.length,
        breakCount: breakCount,
      ),
      expandedBody: _localizedDailyBriefingExpanded(
        locale,
        firstStart: firstStart,
        lastEnd: lastEnd,
        lessonCount: lessons.length,
        breakCount: breakCount,
        nextLesson: nextLessonName,
      ),
      locale: locale,
      currentLesson: currentLessonName,
      nextLesson: nextLessonName,
    );
    await prefs.setString('lastDailyBriefingDate', todayKey);
  }

  final signatureKey = 'lastLessonSignature_$todayKey';
  final previousSignature = prefs.getString(signatureKey) ?? '';
  final hasMeaningfulChange =
      previousSignature.isNotEmpty && previousSignature != lessonSignature;
  final changeCounts = _detectChangeCounts(
    previousSignature: previousSignature,
    currentSignature: lessonSignature,
  );

  var notifiedBySnapshot = false;
  if (isImportantChangesEnabled) {
    try {
      notifiedBySnapshot = await _notifyNewlyDetectedChanges(
        prefs: prefs,
        fullLessons: fullLessons,
        locale: locale,
        currentLesson: currentLessonName,
        nextLesson: nextLessonName,
        isDemoMode: isDemoMode,
        activeAccountId: activeAccountId,
      );
    } catch (_) {
      notifiedBySnapshot = false;
    }
  }

  if (isImportantChangesEnabled && !notifiedBySnapshot && hasMeaningfulChange) {
    await NotificationService().showImportantChangeNotification(
      title: _localizedImportantChangesTitle(locale),
      body:
          '${_localizedImportantChangesBody(locale)} (${_localizedChangeSummary(locale, changeCounts)}) · ${_localizedStatusCurrentLesson(locale)}: $currentLessonName',
      locale: locale,
      currentLesson: currentLessonName,
      nextLesson: nextLessonName,
    );
  }
  await prefs.setString(signatureKey, lessonSignature);

  if (isProgressivePushEnabled) {
    if (hasActiveLesson) {
      await NotificationService().showProgressiveNotification(
        id: NotificationIds.currentLesson,
        title: currentLessonName,
        body: timeRemaining,
        subText: null,
        currentProgress: currentProgress,
        maxProgress: maxProgress,
        endTimeMs: endTimeMs,
        locale: locale,
        nextLesson: nextLessonName,
      );
      await LiveActivityService.instance.upsert(
        lessonName: currentLessonName,
        nextLesson: nextLessonName,
        timeRemaining: timeRemaining,
        startTimeMs: startTimeMs,
        endTimeMs: endTimeMs,
      );
    } else {
      await NotificationService().cancelNotification(
        NotificationIds.currentLesson,
      );
      await LiveActivityService.instance.end();
    }
  } else {
    await NotificationService().cancelNotification(
      NotificationIds.currentLesson,
    );
    await LiveActivityService.instance.end();
  }

  // Widgets intentionally update independently of notification permissions.
  // Keep the payload compact: the native expressive layouts enforce the same
  // short hierarchy when the device is offline or the widget is very small.
  final widgetAccountId = activeAccountId.isEmpty ? 'active' : activeAccountId;
  final rawAccounts = prefs.getString('untisAccountsV1') ?? '[]';
  var accountLabel = schoolName;
  try {
    final accounts = jsonDecode(rawAccounts);
    if (accounts is List) {
      for (final raw in accounts) {
        if (raw is Map && raw['id']?.toString() == widgetAccountId) {
          accountLabel = raw['username']?.toString().trim().isNotEmpty == true
              ? raw['username'].toString()
              : raw['schoolName']?.toString() ?? schoolName;
          break;
        }
      }
    }
  } catch (_) {}
  await WidgetService.updateWidgets(
    currentLesson: hasActiveLesson ? currentLessonName : '',
    nextLesson: '',
    timeRemaining: hasActiveLesson ? timeRemaining : '',
    dailySchedule: lessons
        .take(3)
        .map(
          (lesson) =>
              '${formatUntisTime(lesson['startTime'].toString())} · ${lessonDisplayName(lesson)}',
        )
        .join('\n'),
    homeworkSummary: l.widgetNoOpenHomework,
    notificationSummary: l.widgetOpenNotifications,
    accountId: widgetAccountId,
    accountLabel: accountLabel,
    status: DateFormat('HH:mm').format(now),
    locale: locale,
  );
  if (!isDemoMode) {
    await _refreshInactiveWidgetAccounts(prefs, now: now, locale: locale);
  }
  // Keep the progressive notification fresh at the next lesson boundary even
  // when the app is never opened again (one-off task, no network required).
  _scheduleProgressiveBoundaryRefresh(lessons: lessons, now: now);
  return true;
}

/// Widget-bound accounts do not become notification accounts. This compact
/// refresh only writes their widget payload and deliberately leaves alarms,
/// change tracking and push state bound to the active account above.
Future<void> _refreshInactiveWidgetAccounts(
  SharedPreferences prefs, {
  required DateTime now,
  required String locale,
}) async {
  final l = appL10nFor(locale);
  final activeId = prefs.getString('activeUntisAccountId');
  final raw = prefs.getString('untisAccountsV1') ?? '[]';
  dynamic decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return;
  }
  if (decoded is! List) return;
  final today = int.parse(DateFormat('yyyyMMdd').format(now));
  final entries = decoded.whereType<Map>().toList(growable: false);
  for (var offset = 0; offset < entries.length; offset += 2) {
    final batch = entries.skip(offset).take(2);
    await Future.wait<void>(
      batch.map((entry) async {
        final id = entry['id']?.toString() ?? '';
        final url = entry['schoolUrl']?.toString() ?? '';
        final school = entry['schoolName']?.toString() ?? '';
        final user = entry['username']?.toString() ?? '';
        final credentials = id.isEmpty
            ? const AccountCredentials(
                password: '',
                credentialMode: 'password',
                sessionId: '',
              )
            : await CredentialVault.instance.readAccount(id);
        final password = credentials.password.isNotEmpty
            ? credentials.password
            : entry['password']?.toString() ?? '';
        final personId = (entry['personId'] as num?)?.toInt() ?? 0;
        final personType = (entry['personType'] as num?)?.toInt() ?? 5;
        if (id.isEmpty ||
            id == activeId ||
            url.isEmpty ||
            school.isEmpty ||
            user.isEmpty ||
            password.isEmpty ||
            personId == 0) {
          return;
        }
        try {
          List<dynamic>? source;
          if (credentials.password.isNotEmpty) {
            source = await _fetchAuthenticatedTimetable(
              account: WebUntisAccountLogin(
                accountId: id,
                username: user,
                schoolUrl: url,
                schoolName: school,
                personId: personId,
                personType: personType,
              ),
              currentSessionId: credentials.sessionId,
              startDate: today,
              endDate: today,
              requestId: 'widget_plan_$id',
            );
          } else {
            final mode = entry['credentialMode']?.toString() ?? 'password';
            final session = await _authenticateBackgroundAccount(
              account: WebUntisAccountLogin(
                accountId: id,
                username: user,
                schoolUrl: url,
                schoolName: school,
                personId: personId,
                personType: personType,
              ),
              password: password,
              credentialMode: mode,
              clientName: 'UntisPlusWidget',
            );
            if (session.isEmpty) return;
            final response = await _backgroundWebUntisClient.rpc(
              context: WebUntisRequestContext(
                schoolUrl: url,
                schoolName: school,
                sessionId: session,
              ),
              method: 'getTimetable',
              requestId: 'widget_plan_$id',
              params: {
                'options': {
                  'element': {'id': personId, 'type': personType},
                  'startDate': today,
                  'endDate': today,
                  'showLsText': true,
                },
              },
            );
            final result = response['result'];
            source = switch (result) {
              List<dynamic> value => value,
              Map value when value['timetable'] is List<dynamic> =>
                value['timetable'] as List<dynamic>,
              _ => null,
            };
          }
          if (source == null) return;
          final hiddenSubjects =
              (prefs.getStringList(
                        UntisAccountStore.personalDataKey(id, 'hiddenSubjects'),
                      ) ??
                      const <String>[])
                  .map((subject) => subject.trim().toLowerCase())
                  .toSet();
          String subjectKey(Map lesson) {
            final direct = lesson['_subjectShort']?.toString().trim();
            if (direct?.isNotEmpty == true) return direct!.toLowerCase();
            final subjects = lesson['su'];
            if (subjects is List &&
                subjects.isNotEmpty &&
                subjects.first is Map) {
              return ((subjects.first as Map)['name'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
            }
            return '';
          }

          final lessons =
              source
                  .whereType<Map>()
                  .where(
                    (lesson) => !hiddenSubjects.contains(subjectKey(lesson)),
                  )
                  .toList()
                ..sort(
                  (a, b) => ((a['startTime'] as num?)?.toInt() ?? 0).compareTo(
                    (b['startTime'] as num?)?.toInt() ?? 0,
                  ),
                );
          final nowValue = now.hour * 100 + now.minute;
          Map? current;
          Map? next;
          for (final lesson in lessons) {
            final start = (lesson['startTime'] as num?)?.toInt() ?? 0;
            final end = (lesson['endTime'] as num?)?.toInt() ?? 0;
            if (start <= nowValue && nowValue < end) current = lesson;
            if (start > nowValue && next == null) next = lesson;
          }
          String label(Map? lesson) {
            if (lesson == null) return '';
            final subjects = lesson['su'];
            if (subjects is List &&
                subjects.isNotEmpty &&
                subjects.first is Map) {
              final subject =
                  (subjects.first as Map)['longName'] ??
                  (subjects.first as Map)['name'];
              if (subject?.toString().trim().isNotEmpty == true) {
                return subject.toString().trim();
              }
            }
            return lesson['_subjectShort']?.toString() ?? l.widgetLesson;
          }

          await WidgetService.updateWidgets(
            currentLesson: current == null ? '' : label(current),
            nextLesson: '',
            timeRemaining: '',
            dailySchedule: lessons
                .take(3)
                .map(
                  (lesson) =>
                      '${formatUntisTime(lesson['startTime'].toString())} · ${label(lesson)}',
                )
                .join('\n'),
            homeworkSummary: l.widgetNoOpenHomework,
            notificationSummary: l.widgetOpenNotifications,
            accountId: id,
            accountLabel: user,
            status: DateFormat('HH:mm').format(now),
            locale: locale,
          );
        } catch (_) {
          // Retain the last confirmed widget payload for an unavailable account.
        }
      }),
    );
  }
}

/// Synchronizes the persistent "current lesson" progressive notification from
/// an already-available lesson list (no network required). Used by the foreground
/// timer, the offline cache refresh, and the periodic background sync.
Future<void> syncProgressiveNotification({
  required List<dynamic> lessons,
  required DateTime now,
  required String locale,
  required bool enabled,
}) async {
  await NotificationService().init();

  if (!enabled) {
    await NotificationService().cancelNotification(
      NotificationIds.currentLesson,
    );
    await LiveActivityService.instance.end();
    return;
  }

  final currentTimeInt = now.hour * 100 + now.minute;

  String currentLessonName = _localizedFreeLabel(locale);
  String nextLessonName = '-';
  String timeRemaining = '';
  int? currentProgress;
  int? maxProgress;
  int? startTimeMs;
  int? endTimeMs;
  bool hasActiveLesson = false;

  DateTime untisTimeToDate(int timeStr) {
    final hour = timeStr ~/ 100;
    final minute = timeStr % 100;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String lessonDisplayName(Map<dynamic, dynamic> lesson) {
    final subjectList = lesson['su'];
    if (subjectList is List && subjectList.isNotEmpty) {
      final first = subjectList.first;
      if (first is Map) {
        final raw =
            first['longName'] ?? first['longname'] ?? first['name'] ?? '';
        final label = raw.toString().trim();
        if (label.isNotEmpty) return label;
      }
    }
    final start = lesson['startTime'];
    final end = lesson['endTime'];
    if (start is int && end is int) {
      final startStr = formatUntisTime(start.toString());
      final endStr = formatUntisTime(end.toString());
      return _localizedFallbackLessonName(locale, startStr, endStr);
    }
    return _localizedStatusCurrentLesson(locale);
  }

  for (int i = 0; i < lessons.length; i++) {
    var lesson = lessons[i];
    int start = lesson['startTime'] as int;
    int end = lesson['endTime'] as int;

    final name = lessonDisplayName(lesson);

    String startStr = formatUntisTime(start.toString());
    String endStr = formatUntisTime(end.toString());

    if (currentTimeInt >= start && currentTimeInt <= end) {
      hasActiveLesson = true;
      currentLessonName = name;
      timeRemaining = _localizedUntilTime(locale, endStr);

      final startTimeDate = untisTimeToDate(start);
      final endTimeDate = untisTimeToDate(end);

      maxProgress = endTimeDate.difference(startTimeDate).inMinutes;
      currentProgress = now.difference(startTimeDate).inMinutes;
      startTimeMs = startTimeDate.millisecondsSinceEpoch;
      endTimeMs = endTimeDate.millisecondsSinceEpoch;

      if (i + 1 < lessons.length) {
        final nextL = lessons[i + 1];
        nextLessonName = lessonDisplayName(nextL);
      } else {
        nextLessonName = _localizedClosedLabel(locale);
      }
      break;
    }

    if (currentTimeInt < start) {
      timeRemaining = _localizedLessonStartsAt(locale, startStr);
      nextLessonName = name;
      endTimeMs = untisTimeToDate(start).millisecondsSinceEpoch;
      break;
    }
  }

  final lastLesson = lessons.isNotEmpty ? lessons.last : null;
  if (!hasActiveLesson &&
      lastLesson != null &&
      currentTimeInt > (lastLesson['endTime'] as int)) {
    await NotificationService().cancelNotification(
      NotificationIds.currentLesson,
    );
    await LiveActivityService.instance.end();
    return;
  }

  if (hasActiveLesson) {
    await NotificationService().showProgressiveNotification(
      id: NotificationIds.currentLesson,
      title: currentLessonName,
      body: timeRemaining,
      subText: null,
      currentProgress: currentProgress,
      maxProgress: maxProgress,
      endTimeMs: endTimeMs,
      locale: locale,
      nextLesson: nextLessonName,
    );
    await LiveActivityService.instance.upsert(
      lessonName: currentLessonName,
      nextLesson: nextLessonName,
      timeRemaining: timeRemaining,
      startTimeMs: startTimeMs,
      endTimeMs: endTimeMs,
    );
  } else {
    await NotificationService().cancelNotification(
      NotificationIds.currentLesson,
    );
    await LiveActivityService.instance.end();
  }
}

/// Loads today's lessons from the offline cache, applying user filters.
Future<List<dynamic>?> _loadTodaysLessonsFromCache(
  SharedPreferences prefs,
  String? accountId,
  DateTime now,
) async {
  final accountPrefix =
      '${(accountId?.trim().isNotEmpty ?? false) ? accountId!.trim() : 'legacy'}|timetableWeek|';
  final docs = await OfflineCacheStore.instance.readAllWithPrefix(
    accountPrefix,
  );
  if (docs.isEmpty) return null;

  final todayDate = int.parse(DateFormat('yyyyMMdd').format(now));
  final hiddenSubjects = prefs.getStringList('hiddenSubjects') ?? <String>[];
  final showCancelled = prefs.getBool('showCancelled') ?? true;

  final lessons = <dynamic>[];
  for (final doc in docs) {
    final week = doc.value['weekData'];
    if (week is! Map) continue;
    for (final dayRaw in week.values) {
      if (dayRaw is! List) continue;
      for (final lesson in dayRaw.whereType<Map>()) {
        if ((lesson['date'] as num?)?.toInt() != todayDate) continue;
        if (hiddenSubjects.contains(
          lesson['_subjectShort']?.toString() ?? '',
        )) {
          continue;
        }
        if (!showCancelled && (lesson['code'] ?? '') == 'cancelled') continue;
        lessons.add(lesson);
      }
    }
  }

  lessons.sort(
    (a, b) => ((a['startTime'] as num?)?.toInt() ?? 0).compareTo(
      (b['startTime'] as num?)?.toInt() ?? 0,
    ),
  );
  return lessons;
}

/// Schedules the next progressive notification refresh at the next lesson boundary.
void _scheduleProgressiveBoundaryRefresh({
  required List<dynamic> lessons,
  required DateTime now,
}) {
  if (kIsWeb) return;

  final nowInt = now.hour * 100 + now.minute;
  Duration? delay;

  for (final lesson in lessons.whereType<Map>()) {
    final start = (lesson['startTime'] as num?)?.toInt() ?? 0;
    final end = (lesson['endTime'] as num?)?.toInt() ?? 0;

    if (nowInt >= start && nowInt <= end) {
      // Currently in a lesson: schedule for 1 minute after it ends
      final endMinutes = (end ~/ 100) * 60 + (end % 100);
      final nowMinutes = now.hour * 60 + now.minute;
      delay = Duration(minutes: endMinutes - nowMinutes + 1);
      break;
    }

    if (nowInt < start) {
      // Next lesson hasn't started yet: schedule for its start
      final startMinutes = (start ~/ 100) * 60 + (start % 100);
      final nowMinutes = now.hour * 60 + now.minute;
      delay = Duration(minutes: startMinutes - nowMinutes);
      break;
    }
  }

  if (delay == null) return;
  // Clamp to reasonable bounds: at least 1 min, at most 12 hours
  if (delay < const Duration(minutes: 1)) delay = const Duration(minutes: 1);
  if (delay > const Duration(hours: 12)) return;

  // Fixed unique name with replace policy so every re-schedule replaces the
  // previous pending refresh instead of accumulating tasks.
  Workmanager().registerOneOffTask(
    kProgressiveBoundaryRefreshId,
    kProgressiveCacheRefreshTask,
    initialDelay: delay,
    constraints: Constraints(networkType: NetworkType.notRequired),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}

/// Refreshes the progressive notification from the offline cache and reschedules
/// the next boundary refresh. Can be called from the foreground timer or the
/// background one-off task.
Future<void> refreshProgressiveNotificationFromCache({DateTime? now}) async {
  final prefs = await SharedPreferences.getInstance();
  final locale = prefs.getString('appLocale') ?? 'de';
  final enabled = prefs.getBool('progressivePush') ?? true;
  final time = now ?? DateTime.now();
  final accountId = prefs.getString('activeUntisAccountId');

  final lessons = await _loadTodaysLessonsFromCache(prefs, accountId, time);
  if (lessons == null) return;

  await syncProgressiveNotification(
    lessons: lessons,
    now: time,
    locale: locale,
    enabled: enabled,
  );

  _scheduleProgressiveBoundaryRefresh(lessons: lessons, now: time);
}

@Deprecated('Use DemoModeService.buildWeek instead.')
List<Map<String, dynamic>> buildLegacyDemoLessons24x7(
  DateTime now,
  String locale,
) {
  final date = int.parse(DateFormat('yyyyMMdd').format(now));
  final blocks = <Map<String, dynamic>>[];

  // 8 x 3h Bloecke decken den ganzen Tag ab (00:00-23:59).
  const starts = <int>[0, 300, 600, 900, 1200, 1500, 1800, 2100];
  const ends = <int>[259, 559, 859, 1159, 1459, 1759, 2059, 2359];
  const codes = <String>['DM', 'MA', 'EN', 'IF', 'PH', 'CH', 'GE', 'SP'];

  for (var i = 0; i < starts.length; i++) {
    final short = codes[i % codes.length];
    blocks.add({
      'date': date,
      'startTime': starts[i],
      'endTime': ends[i],
      '_subjectShort': short,
      '_subjectLong': _demoSubjectName(short, locale),
      '_teacher': 'Demo',
      '_room': 'D${(i + 1).toString().padLeft(2, '0')}',
      'code': '',
    });
  }

  return blocks;
}

String _demoSubjectName(String code, String locale) {
  return appL10nFor(locale).bgDemoLesson(code);
}
