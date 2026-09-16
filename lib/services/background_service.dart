import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otp_auth/otp_auth.dart';
import 'package:workmanager/workmanager.dart';
import '../core/time_utils.dart';
import '../data/cache/offline_cache_store.dart';
import '../data/security/credential_vault.dart';
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
const String kProgressiveBoundaryRefreshId = 'untis_progressive_boundary_refresh';

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

List<int> _extractVersionParts(String input) {
  final cleaned = input.trim().replaceFirst(RegExp(r'^[vV]'), '');
  final matches = RegExp(r'\d+').allMatches(cleaned);
  if (matches.isEmpty) return const [0];
  return matches
      .map((m) => int.tryParse(m.group(0) ?? '0') ?? 0)
      .toList(growable: false);
}

int _compareVersionStrings(String current, String latest) {
  final currentParts = _extractVersionParts(current);
  final latestParts = _extractVersionParts(latest);
  final maxLen = math.max(currentParts.length, latestParts.length);
  for (var i = 0; i < maxLen; i++) {
    final a = i < currentParts.length ? currentParts[i] : 0;
    final b = i < latestParts.length ? latestParts[i] : 0;
    if (a == b) continue;
    return a.compareTo(b);
  }
  return 0;
}

String _localizedUpdateTitle(String locale) {
  return AppL10n.of(locale).ui('bgUpdateTitle');
}

String _localizedDailyBriefingTitle(String locale) {
  return AppL10n.of(locale).ui('bgDailyBriefingTitle');
}

String _localizedDailyBriefingBody(
  String locale, {
  required String firstStart,
  required String lastEnd,
  required int lessonCount,
  required int breakCount,
}) {
  return AppL10n.of(locale).uiFormat('bgDailyBriefingBody', {
    'start': firstStart,
    'end': lastEnd,
    'lessons': lessonCount,
    'breaks': breakCount,
  });
}

String _localizedDailyBriefingExpanded(
  String locale, {
  required String firstStart,
  required String lastEnd,
  required int lessonCount,
  required int breakCount,
  required String nextLesson,
}) {
  return AppL10n.of(locale).uiFormat('bgDailyBriefingExpanded', {
    'start': firstStart,
    'end': lastEnd,
    'lessons': lessonCount,
    'breaks': breakCount,
    'next': nextLesson,
  });
}

String _normalizeWebUntisSecret(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  if (trimmed.startsWith('otpauth://')) {
    return OTPUri.extractSecret(
      trimmed,
    ).trim().replaceAll(' ', '').toUpperCase();
  }

  if (trimmed.startsWith('untis://')) {
    final uri = Uri.tryParse(trimmed);
    final extracted =
        uri?.queryParameters['key'] ?? uri?.queryParameters['secret'] ?? '';
    if (extracted.isNotEmpty) {
      return extracted.trim().replaceAll(' ', '').toUpperCase();
    }
  }

  return trimmed.replaceAll(' ', '').toUpperCase();
}

String _generateWebUntisOtp(String credential) {
  final secret = _normalizeWebUntisSecret(credential);
  if (secret.isEmpty) {
    throw ArgumentError('WebUntis secret must not be empty.');
  }

  return TOTP(
    secret: secret,
    digits: 6,
    algorithm: OTPAlgorithm.sha1,
    period: 30,
  ).now();
}

Future<String?> _loginWithWebUntisSecret({
  required String schoolUrl,
  required String schoolName,
  required String user,
  required String secret,
}) async {
  final response = await http.post(
    Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc_intern.do?school=$schoolName',
    ),
    body: jsonEncode({
      'id': 'bg_login',
      'method': 'getUserData2017',
      'params': [
        {
          'auth': {
            'clientTime': DateTime.now().millisecondsSinceEpoch,
            'user': user,
            'otp': _generateWebUntisOtp(secret),
          },
        },
      ],
      'jsonrpc': '2.0',
    }),
  );

  if (response.statusCode != 200 || response.body.trim().isEmpty) {
    return null;
  }

  final data = jsonDecode(response.body);
  if (data is Map && data['error'] != null) {
    return null;
  }

  final setCookie = response.headers['set-cookie'] ?? '';
  final sessionId =
      RegExp(r'JSESSIONID=([^;]+)').firstMatch(setCookie)?.group(1) ?? '';
  return sessionId.isEmpty ? null : sessionId;
}

String _localizedImportantChangesTitle(String locale) {
  return AppL10n.of(locale).ui('bgChangesTitle');
}

String _localizedImportantChangesBody(String locale) {
  return AppL10n.of(locale).ui('bgChangesBody');
}

String _localizedStatusCurrentLesson(String locale) {
  return AppL10n.of(locale).ui('bgCurrentLesson');
}

// ignore: unused_element
String _localizedStatusNextLesson(String locale) {
  return AppL10n.of(locale).ui('bgNextLesson');
}

// ignore: unused_element
String _localizedStatusNoClasses(String locale) {
  return AppL10n.of(locale).ui('bgNoClasses');
}

String _localizedLessonStartsAt(String locale, String start) {
  return AppL10n.of(locale).uiFormat('bgLessonStarts', {'time': start});
}

String _localizedUntilTime(String locale, String end) {
  return AppL10n.of(locale).uiFormat('bgUntil', {'time': end});
}

// ignore: unused_element
String _localizedThen(String locale, String nextLesson) {
  return AppL10n.of(locale).uiFormat('bgThen', {'lesson': nextLesson});
}

String _localizedClosedLabel(String locale) {
  return AppL10n.of(locale).ui('bgFinished');
}

String _localizedFreeLabel(String locale) {
  return AppL10n.of(locale).ui('bgFreePeriod');
}

String _localizedFallbackLessonName(String locale, String start, String end) {
  return AppL10n.of(locale).uiFormat('bgFallbackLesson', {
    'start': start,
    'end': end,
  });
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
  final l = AppL10n.of(locale);
  final cancelled = counts['cancelled'] ?? 0;
  final room = counts['room'] ?? 0;
  final substitution = counts['substitution'] ?? 0;
  final other = counts['other'] ?? 0;
  final parts = <String>[];
  if (cancelled > 0) {
    parts.add(l.uiFormat('bgChangesCancelled', {'count': cancelled}));
  }
  if (room > 0) parts.add(l.uiFormat('bgChangesRoom', {'count': room}));
  if (substitution > 0) {
    parts.add(l.uiFormat('bgChangesSubstitution', {'count': substitution}));
  }
  if (other > 0 || parts.isEmpty) {
    parts.add(l.uiFormat('bgChangesOther', {'count': other > 0 ? other : 1}));
  }
  return parts.join(' · ');
}

String _localizedUpdateBody(String locale, String latestVersion) {
  return AppL10n.of(locale).uiFormat('bgUpdateBody', {
    'version': latestVersion,
  });
}

Future<void> checkGithubUpdateAndNotify() async {
  final prefs = await SharedPreferences.getInstance();
  final installedVersion = (await PackageInfo.fromPlatform()).version;
  final locale = prefs.getString('appLocale') ?? 'de';

  try {
    final resp = await http.get(
      Uri.parse(
        'https://api.github.com/repos/ninocss/UntisPlus/releases/latest',
      ),
      headers: const {'Accept': 'application/vnd.github+json'},
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      return;
    }

    final data = jsonDecode(resp.body);
    if (data is! Map<String, dynamic>) {
      return;
    }

    final tag = (data['tag_name'] ?? '').toString().trim();
    final latestVersion = tag.isEmpty
        ? (data['name'] ?? '').toString().trim()
        : tag;
    final hasComparableVersion = RegExp(r'\d').hasMatch(latestVersion);

    final hasUpdate =
        latestVersion.isNotEmpty &&
        (hasComparableVersion
            ? _compareVersionStrings(installedVersion, latestVersion) < 0
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
  final l = AppL10n.of(locale);

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
    String sessionId = "";
    final authUrl = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );
    if (useLoginKey) {
      sessionId =
          await _loginWithWebUntisSecret(
            schoolUrl: schoolUrl,
            schoolName: schoolName,
            user: user,
            secret: pass,
          ) ??
          '';
    } else {
      final authRes = await http.post(
        authUrl,
        body: jsonEncode({
          "id": "bg_login",
          "method": "authenticate",
          "params": {
            "user": user,
            "password": pass,
            "client": "UntisPlusWidget",
          },
          "jsonrpc": "2.0",
        }),
      );

      if (authRes.statusCode == 200) {
        final data = jsonDecode(authRes.body);
        sessionId = data['result']?['sessionId']?.toString() ?? "";
      }
    }

    if (sessionId.isEmpty) return false;

    final personId = prefs.getInt('personId') ?? 0;
    final personType = prefs.getInt('personType') ?? 5;

    if (personId == 0) return false;

    final todayDate = int.parse(DateFormat('yyyyMMdd').format(now));
    final finalPlanningDate = int.parse(
      DateFormat('yyyyMMdd').format(now.add(const Duration(days: 14))),
    );

    final timetableRes = await http.post(
      authUrl,
      headers: {
        "Cookie": "JSESSIONID=$sessionId; schoolname=$schoolName",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "id": "bg_req",
        "method": "getTimetable",
        "params": {
          "options": {
            "element": {"id": personId, "type": personType},
            "startDate": todayDate,
            "endDate": finalPlanningDate,
            "showLsText": true,
            "showSubstText": true,
            "showInfo": true,
            "showBooking": true,
          },
        },
        "jsonrpc": "2.0",
      }),
    );

    if (timetableRes.statusCode != 200) return false;

    final decoded = jsonDecode(timetableRes.body);
    final dynamic result = decoded['result'];
    if (result is List) {
      lessons = result;
      hasValidTimetableResult = true;
    } else if (result is Map && result['timetable'] is List) {
      lessons = result['timetable'];
      hasValidTimetableResult = true;
    }
  }

  // A malformed or incomplete server response must never silently remove an
  // already confirmed smart alarm. An actual empty timetable remains valid.
  if (!hasValidTimetableResult) return false;

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

  if (isImportantChangesEnabled && hasMeaningfulChange) {
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
    homeworkSummary: l.ui('widgetNoOpenHomework'),
    notificationSummary: l.ui('widgetOpenNotifications'),
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
  final l = AppL10n.of(locale);
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
  for (final entry in decoded) {
    if (entry is! Map) continue;
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
      continue;
    }
    try {
      final endpoint = Uri.parse(
        'https://$url/WebUntis/jsonrpc.do?school=$school',
      );
      String session = '';
      if ((credentials.password.isNotEmpty
              ? credentials.credentialMode
              : entry['credentialMode']?.toString()) ==
          'loginKey') {
        session =
            await _loginWithWebUntisSecret(
              schoolUrl: url,
              schoolName: school,
              user: user,
              secret: password,
            ) ??
            '';
      } else {
        final auth = await http.post(
          endpoint,
          body: jsonEncode({
            'id': 'widget_$id',
            'method': 'authenticate',
            'params': {
              'user': user,
              'password': password,
              'client': 'UntisPlusWidget',
            },
            'jsonrpc': '2.0',
          }),
        );
        if (auth.statusCode == 200) {
          session =
              jsonDecode(auth.body)['result']?['sessionId']?.toString() ?? '';
        }
      }
      if (session.isEmpty) continue;
      final response = await http.post(
        endpoint,
        headers: {
          'Cookie': 'JSESSIONID=$session; schoolname=$school',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': 'widget_plan_$id',
          'method': 'getTimetable',
          'params': {
            'options': {
              'element': {'id': personId, 'type': personType},
              'startDate': today,
              'endDate': today,
              'showLsText': true,
            },
          },
          'jsonrpc': '2.0',
        }),
      );
      if (response.statusCode != 200) continue;
      final result = jsonDecode(response.body)['result'];
      final source = result is List
          ? result
          : result is Map && result['timetable'] is List
          ? result['timetable'] as List
          : const <dynamic>[];
      final lessons = source.whereType<Map>().toList()
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
        if (subjects is List && subjects.isNotEmpty && subjects.first is Map) {
          final subject =
              (subjects.first as Map)['longName'] ??
              (subjects.first as Map)['name'];
          if (subject?.toString().trim().isNotEmpty == true) {
            return subject.toString().trim();
          }
        }
        return lesson['_subjectShort']?.toString() ?? l.ui('widgetLesson');
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
        homeworkSummary: l.ui('widgetNoOpenHomework'),
        notificationSummary: l.ui('widgetOpenNotifications'),
        accountId: id,
        accountLabel: user,
        status: DateFormat('HH:mm').format(now),
        locale: locale,
      );
    } catch (_) {
      // Retain the last confirmed widget payload for an unavailable account.
    }
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
    await NotificationService().cancelNotification(NotificationIds.currentLesson);
    await LiveActivityService.instance.end();
    return;
  }

  final currentTimeInt = now.hour * 100 + now.minute;

  String currentLessonName = _localizedFreeLabel(locale);
  String nextLessonName = '-';
  String timeRemaining = '';
  int? currentProgress;
  int? maxProgress;
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
  if (!hasActiveLesson && lastLesson != null && currentTimeInt > (lastLesson['endTime'] as int)) {
    await NotificationService().cancelNotification(NotificationIds.currentLesson);
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
    );
  } else {
    await NotificationService().cancelNotification(NotificationIds.currentLesson);
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
  final docs = await OfflineCacheStore.instance.readAllWithPrefix(accountPrefix);
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
        if (hiddenSubjects.contains(lesson['_subjectShort']?.toString() ?? '')) continue;
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
  return AppL10n.of(locale).uiFormat('bgDemoLesson', {'code': code});
}
