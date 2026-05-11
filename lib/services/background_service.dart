import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otp_auth/otp_auth.dart';
import 'package:workmanager/workmanager.dart';
import '../core/time_utils.dart';

import 'notification_service.dart';

const String kTimetableUpdateTask = 'update_timetable_task';
const String kGithubUpdateCheckTask = 'check_github_updates_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await NotificationService().init();
      if (task == kGithubUpdateCheckTask) {
        await checkGithubUpdateAndNotify();
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
    Workmanager().initialize(callbackDispatcher);
    Workmanager().registerPeriodicTask(
      "untis_school_notification_update",
      kTimetableUpdateTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );

    Workmanager().registerPeriodicTask(
      'untis_github_update_check',
      kGithubUpdateCheckTask,
      frequency: const Duration(hours: 6),
      constraints: Constraints(networkType: NetworkType.connected),
    );
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
  switch (locale) {
    case 'en':
      return 'Untis+ Update available';
    case 'fr':
      return 'Mise a jour Untis+ disponible';
    case 'es':
      return 'Actualizacion de Untis+ disponible';
    case 'el':
      return 'Διαθεσιμη ενημερωση Untis+';
    case 'de':
    default:
      return 'Untis+ Update verfugbar';
  }
}

String _localizedDailyBriefingTitle(String locale) {
  switch (locale) {
    case 'en':
      return 'Your school day at a glance';
    case 'fr':
      return 'Ton apercu de la journee';
    case 'es':
      return 'Resumen de tu dia escolar';
    case 'el':
      return 'Η ημερα σου με μια ματια';
    case 'de':
    default:
      return 'Dein Schultag auf einen Blick';
  }
}

String _localizedDailyBriefingBody(
  String locale, {
  required String firstStart,
  required String lastEnd,
  required int lessonCount,
  required int breakCount,
}) {
  switch (locale) {
    case 'en':
      return '$firstStart-$lastEnd, $lessonCount lessons, $breakCount breaks';
    case 'fr':
      return '$firstStart-$lastEnd, $lessonCount cours, $breakCount pauses';
    case 'es':
      return '$firstStart-$lastEnd, $lessonCount clases, $breakCount descansos';
    case 'el':
      return '$firstStart-$lastEnd, $lessonCount μαθηματα, $breakCount διαλειμματα';
    case 'de':
    default:
      return '$firstStart-$lastEnd, $lessonCount Stunden, $breakCount Pausen';
  }
}

String _localizedDailyBriefingExpanded(
  String locale, {
  required String firstStart,
  required String lastEnd,
  required int lessonCount,
  required int breakCount,
  required String nextLesson,
}) {
  switch (locale) {
    case 'en':
      return 'Start: $firstStart\nEnd: $lastEnd\nLessons: $lessonCount\nBreaks: $breakCount\nNext: $nextLesson';
    case 'fr':
      return 'Debut: $firstStart\nFin: $lastEnd\nCours: $lessonCount\nPauses: $breakCount\nSuivant: $nextLesson';
    case 'es':
      return 'Inicio: $firstStart\nFin: $lastEnd\nClases: $lessonCount\nDescansos: $breakCount\nSiguiente: $nextLesson';
    case 'el':
      return 'Εναρξη: $firstStart\nΛηξη: $lastEnd\nΜαθηματα: $lessonCount\nΔιαλειμματα: $breakCount\nΕπομενο: $nextLesson';
    case 'de':
    default:
      return 'Start: $firstStart\nEnde: $lastEnd\nStunden: $lessonCount\nPausen: $breakCount\nNächste Stunde: $nextLesson';
  }
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
  switch (locale) {
    case 'en':
      return 'Timetable updated';
    case 'fr':
      return 'Emploi du temps mis a jour';
    case 'es':
      return 'Horario actualizado';
    case 'el':
      return 'Το προγραμμα ενημερωθηκε';
    case 'de':
    default:
      return 'Stundenplan aktualisiert';
  }
}

String _localizedImportantChangesBody(String locale) {
  switch (locale) {
    case 'en':
      return 'There are new changes today. Tap to open your timetable.';
    case 'fr':
      return 'Il y a de nouveaux changements aujourd’hui. Ouvre ton emploi du temps.';
    case 'es':
      return 'Hay cambios nuevos hoy. Toca para abrir tu horario.';
    case 'el':
      return 'Υπαρχουν νεες αλλαγες σημερα. Πατησε για να ανοιξεις το προγραμμα.';
    case 'de':
    default:
      return 'Es gibt neue Änderungen heute. Tippe, um den Stundenplan zu öffnen.';
  }
}

String _localizedStatusCurrentLesson(String locale) {
  switch (locale) {
    case 'en':
      return 'Current lesson';
    case 'fr':
      return 'Cours actuel';
    case 'es':
      return 'Clase actual';
    case 'el':
      return 'Τρεχον μαθημα';
    case 'de':
    default:
      return 'Aktuelle Stunde';
  }
}

// ignore: unused_element
String _localizedStatusNextLesson(String locale) {
  switch (locale) {
    case 'en':
      return 'Next lesson';
    case 'fr':
      return 'Cours suivant';
    case 'es':
      return 'Siguiente clase';
    case 'el':
      return 'Επομενο μαθημα';
    case 'de':
    default:
      return 'Nächste Stunde';
  }
}

// ignore: unused_element
String _localizedStatusNoClasses(String locale) {
  switch (locale) {
    case 'en':
      return 'No more classes';
    case 'fr':
      return 'Plus de cours';
    case 'es':
      return 'No hay más clases';
    case 'el':
      return 'Δεν υπαρχουν αλλα μαθηματα';
    case 'de':
    default:
      return 'Kein Unterricht mehr';
  }
}

String _localizedLessonStartsAt(String locale, String start) {
  switch (locale) {
    case 'en':
      return 'Starts at $start';
    case 'fr':
      return 'Debut a $start';
    case 'es':
      return 'Empieza a las $start';
    case 'el':
      return 'Ξεκινα στις $start';
    case 'de':
    default:
      return 'Start um $start';
  }
}

String _localizedUntilTime(String locale, String end) {
  switch (locale) {
    case 'en':
      return 'Until $end';
    case 'fr':
      return 'Jusqu’a $end';
    case 'es':
      return 'Hasta las $end';
    case 'el':
      return 'Μεχρι τις $end';
    case 'de':
    default:
      return 'Bis $end Uhr';
  }
}

// ignore: unused_element
String _localizedThen(String locale, String nextLesson) {
  switch (locale) {
    case 'en':
      return 'Then: $nextLesson';
    case 'fr':
      return 'Ensuite: $nextLesson';
    case 'es':
      return 'Luego: $nextLesson';
    case 'el':
      return 'Μετα: $nextLesson';
    case 'de':
    default:
      return 'Danach: $nextLesson';
  }
}

String _localizedClosedLabel(String locale) {
  switch (locale) {
    case 'en':
      return 'Finished';
    case 'fr':
      return 'Termine';
    case 'es':
      return 'Fin';
    case 'el':
      return 'Τελος';
    case 'de':
    default:
      return 'Schluss';
  }
}

String _localizedFreeLabel(String locale) {
  switch (locale) {
    case 'en':
      return 'Free period';
    case 'fr':
      return 'Heure libre';
    case 'es':
      return 'Hora libre';
    case 'el':
      return 'Κενο';
    case 'de':
    default:
      return 'Frei';
  }
}

String _localizedFallbackLessonName(String locale, String start, String end) {
  switch (locale) {
    case 'en':
      return 'Lesson $start - $end';
    case 'fr':
      return 'Cours $start - $end';
    case 'es':
      return 'Clase $start - $end';
    case 'el':
      return 'Μαθημα $start - $end';
    case 'de':
    default:
      return 'Stunde $start - $end';
  }
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
  final cancelled = counts['cancelled'] ?? 0;
  final room = counts['room'] ?? 0;
  final substitution = counts['substitution'] ?? 0;
  final other = counts['other'] ?? 0;

  if (locale == 'de') {
    final parts = <String>[];
    if (cancelled > 0) {
      parts.add('$cancelled Ausfälle');
    }
    if (room > 0) {
      parts.add('$room Raumwechsel');
    }
    if (substitution > 0) {
      parts.add('$substitution Vertretungen');
    }
    if (other > 0 || parts.isEmpty) {
      parts.add('${other > 0 ? other : 1} Änderungen');
    }
    return parts.join(' · ');
  }

  if (locale == 'en') {
    final parts = <String>[];
    if (cancelled > 0) {
      parts.add('$cancelled cancellations');
    }
    if (room > 0) {
      parts.add('$room room changes');
    }
    if (substitution > 0) {
      parts.add('$substitution substitutions');
    }
    if (other > 0 || parts.isEmpty) {
      parts.add('${other > 0 ? other : 1} updates');
    }
    return parts.join(' · ');
  }

  if (locale == 'fr') {
    final parts = <String>[];
    if (cancelled > 0) {
      parts.add('$cancelled annulations');
    }
    if (room > 0) {
      parts.add('$room changements de salle');
    }
    if (substitution > 0) {
      parts.add('$substitution remplacements');
    }
    if (other > 0 || parts.isEmpty) {
      parts.add('${other > 0 ? other : 1} changements');
    }
    return parts.join(' · ');
  }

  if (locale == 'es') {
    final parts = <String>[];
    if (cancelled > 0) {
      parts.add('$cancelled cancelaciones');
    }
    if (room > 0) {
      parts.add('$room cambios de aula');
    }
    if (substitution > 0) {
      parts.add('$substitution sustituciones');
    }
    if (other > 0 || parts.isEmpty) {
      parts.add('${other > 0 ? other : 1} cambios');
    }
    return parts.join(' · ');
  }

  final parts = <String>[];
  if (cancelled > 0) parts.add('$cancelled ακυρωσεις');
  if (room > 0) parts.add('$room αλλαγες αιθουσας');
  if (substitution > 0) parts.add('$substitution αναπληρωσεις');
  if (other > 0 || parts.isEmpty) parts.add('${other > 0 ? other : 1} αλλαγες');
  return parts.join(' · ');
}

String _localizedUpdateBody(String locale, String latestVersion) {
  switch (locale) {
    case 'en':
      return 'Version $latestVersion is available on GitHub Releases.';
    case 'fr':
      return 'La version $latestVersion est disponible sur GitHub Releases.';
    case 'es':
      return 'La version $latestVersion esta disponible en GitHub Releases.';
    case 'el':
      return 'Η εκδοση $latestVersion ειναι διαθεσιμη στα GitHub Releases.';
    case 'de':
    default:
      return 'Version $latestVersion ist in den GitHub Releases verfugbar.';
  }
}

Future<void> checkGithubUpdateAndNotify() async {
  final prefs = await SharedPreferences.getInstance();
  final installedVersion = prefs.getString('installedAppVersion') ?? '0.0.0';
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
      await NotificationService().cancelNotification(kUpdateNotificationId);
      return;
    }

    await NotificationService().showUpdateNotification(
      id: kUpdateNotificationId,
      title: _localizedUpdateTitle(locale),
      body: _localizedUpdateBody(locale, latestVersion),
    );
  } catch (_) {
    // Keep silent in background; no user-facing error notification needed.
  }
}

Future<void> updateUntisData() async {
  final prefs = await SharedPreferences.getInstance();
  final isDemoMode = prefs.getBool('demoMode') ?? false;
  final schoolUrl = prefs.getString('schoolUrl') ?? '';
  final schoolName = prefs.getString('schoolName') ?? '';
  final user = prefs.getString('username') ?? '';
  final pass = prefs.getString('password') ?? '';
  final useLoginKey = prefs.getString('loginCredentialMode') == 'loginKey';
  final locale = prefs.getString('appLocale') ?? 'de';

  if (!isDemoMode &&
      (schoolUrl.isEmpty ||
          schoolName.isEmpty ||
          user.isEmpty ||
          pass.isEmpty)) {
    return;
  }

  final now = DateTime.now();
  List<dynamic> lessons = [];
  if (isDemoMode) {
    lessons = _buildDemoLessons24x7(now, locale);
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

    if (sessionId.isEmpty) return;

    final personId = prefs.getInt('personId') ?? 0;
    final personType = prefs.getInt('personType') ?? 5;

    if (personId == 0) return;

    final todayDate = int.parse(DateFormat('yyyyMMdd').format(now));

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
          "id": personId,
          "type": personType,
          "startDate": todayDate,
          "endDate": todayDate,
        },
        "jsonrpc": "2.0",
      }),
    );

    if (timetableRes.statusCode != 200) return;

    final decoded = jsonDecode(timetableRes.body);
    final dynamic result = decoded['result'];
    if (result is List) {
      lessons = result;
    } else if (result is Map && result['timetable'] is List) {
      lessons = result['timetable'];
    }
  }

  // Respect user-hidden subjects and the "show cancelled" setting
  final hiddenSubjects = prefs.getStringList('hiddenSubjects') ?? <String>[];
  final showCancelled = prefs.getBool('showCancelled') ?? true;

  lessons = lessons
      .whereType<Map>()
      .where((l) => !hiddenSubjects
          .contains(l['_subjectShort']?.toString() ?? ''))
      .where((l) => showCancelled || (l['code'] ?? '') != 'cancelled')
      .toList(growable: false);

  if (lessons.isEmpty) {
    await NotificationService().cancelNotification(
      kCurrentLessonNotificationId,
    );
    return;
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
      kCurrentLessonNotificationId,
    );
    return;
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
        id: kCurrentLessonNotificationId,
        title: currentLessonName,
        body: timeRemaining,
        subText: null,
        currentProgress: currentProgress,
        maxProgress: maxProgress,
        endTimeMs: endTimeMs,
        locale: locale,
        nextLesson: nextLessonName,
      );
    } else {
      await NotificationService().cancelNotification(
        kCurrentLessonNotificationId,
      );
    }
  } else {
    await NotificationService().cancelNotification(
      kCurrentLessonNotificationId,
    );
  }
}

List<Map<String, dynamic>> _buildDemoLessons24x7(DateTime now, String locale) {
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
  switch (locale) {
    case 'en':
      return 'Demo Lesson $code';
    case 'fr':
      return 'Cours demo $code';
    case 'es':
      return 'Clase demo $code';
    case 'el':
      return 'Μαθημα demo $code';
    case 'de':
    default:
      return 'Demo-Stunde $code';
  }
}
