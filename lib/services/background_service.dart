import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'notification_service.dart';
import 'widget_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await updateUntisData();
    } catch (e) {
      print("Background Task Error: $e");
    }
    return Future.value(true);
  });
}

class BackgroundService {
  static void initialize() {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    // Registriere Background Task der alle 15 Minuten feuert (Minimum bei Android)
    Workmanager().registerPeriodicTask(
      "untis_widget_update",
      "update_timetable_task",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected, // Nur wenn Internet da ist
      ),
    );
  }
}

Future<void> updateUntisData() async {
  // 1. Hole prefs
  final prefs = await SharedPreferences.getInstance();
  final schoolUrl = prefs.getString('schoolUrl') ?? '';
  final schoolName = prefs.getString('schoolName') ?? '';
  final user = prefs.getString('username') ?? '';
  final pass = prefs.getString('password') ?? '';

  if (schoolUrl.isEmpty || schoolName.isEmpty || user.isEmpty || pass.isEmpty) {
    return;
  }

  // 2. Authenticate
  String sessionId = "";
  final authUrl = Uri.parse(
    'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
  );
  final authRes = await http.post(
    authUrl,
    body: jsonEncode({
      "id": "bg_login",
      "method": "authenticate",
      "params": {"user": user, "password": pass, "client": "UntisPlusWidget"},
      "jsonrpc": "2.0",
    }),
  );

  if (authRes.statusCode == 200) {
    final data = jsonDecode(authRes.body);
    sessionId = data['result']?['sessionId']?.toString() ?? "";
  }

  if (sessionId.isEmpty) return;

  // 3. Request Timetable für heute
  int personId = prefs.getInt('personId') ?? 0;
  int personType = prefs.getInt('personType') ?? 5; // Studenten standard

  if (personId == 0) return;

  final now = DateTime.now();
  int todayDate = int.parse(DateFormat('yyyyMMdd').format(now));

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
  List<dynamic> lessons = [];
  if (result is List) {
    lessons = result;
  } else if (result is Map && result['timetable'] is List) {
    lessons = result['timetable'];
  }

  if (lessons.isEmpty) {
    // Keine Schule heute
    await WidgetService.updateWidgets(
      currentLesson: "Kein Unterricht heute",
      nextLesson: "-",
      timeRemaining: "",
      dailySchedule: "Heute stehen keine Stunden an.",
    );
    await NotificationService().cancelNotification(1); // Notification entfernen
    return;
  }

  // 4. Lektionen sortieren
  lessons.sort(
    (a, b) => (a['startTime'] as int).compareTo(b['startTime'] as int),
  );

  // Daten aufbereiten
  String currentLessonName = "Frei / Pause";
  String nextLessonName = "-";
  String timeRemaining = "";

  StringBuffer dailyScheduleBuffer = StringBuffer();

  // Finde aktuelle und nächste Stunde
  final currentTimeInt = now.hour * 100 + now.minute; // z.B. 8:15 -> 815
  bool foundCurrent = false;

  int? currentProgress;
  int? maxProgress;
  int? endTimeMs;
  String subTextInfo = "Stundenplan";

  DateTime untisTimeToDate(int timeStr) {
    final hour = timeStr ~/ 100;
    final minute = timeStr % 100;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  for (int i = 0; i < lessons.length; i++) {
    var l = lessons[i];
    int start = l['startTime'] as int;
    int end = l['endTime'] as int;

    // Extrahiere Fachname
    String name = "Unbekannt";
    if (l['su'] != null && (l['su'] as List).isNotEmpty) {
      name = l['su'][0]['name'] ?? "Unbekannt";
    }

    String startStr = _formatUntisTime(start.toString());
    String endStr = _formatUntisTime(end.toString());

    dailyScheduleBuffer.writeln("$startStr - $endStr: $name");

    if (!foundCurrent) {
      if (currentTimeInt >= start && currentTimeInt <= end) {
        currentLessonName = name;
        timeRemaining = "Bis $endStr Uhr";
        foundCurrent = true;
        subTextInfo = "Laufende Stunde";

        DateTime startTimeDate = untisTimeToDate(start);
        DateTime endTimeDate = untisTimeToDate(end);

        maxProgress = endTimeDate.difference(startTimeDate).inMinutes;
        currentProgress = now.difference(startTimeDate).inMinutes;
        endTimeMs = endTimeDate.millisecondsSinceEpoch;

        if (i + 1 < lessons.length) {
          var nextL = lessons[i + 1];
          if (nextL['su'] != null && (nextL['su'] as List).isNotEmpty) {
            nextLessonName = nextL['su'][0]['name'] ?? "Unbekannt";
          }
        } else {
          nextLessonName = "Schulschluss!";
        }
      } else if (currentTimeInt < start) {
        // Noch vor der nächsten Stunde (z.B. Pause oder morgens)
        timeRemaining = "Start um $startStr";
        nextLessonName = name;
        foundCurrent = true; // Wir nehmen die anstehende als "Danach"
        subTextInfo = "Nächste Stunde";
        endTimeMs = untisTimeToDate(start).millisecondsSinceEpoch;
      }
    }
  }

  if (!foundCurrent && currentTimeInt > (lessons.last['endTime'] as int)) {
    currentLessonName = "Unterricht vorbei";
    timeRemaining = "Schönen Feierabend!";
    subTextInfo = "Feierabend";
  }

  // 5. Update Home Widgets
  await WidgetService.updateWidgets(
    currentLesson: currentLessonName,
    nextLesson: nextLessonName,
    timeRemaining: timeRemaining,
    dailySchedule: dailyScheduleBuffer.toString(),
  );

  // 6. Update Notification if enabled
  final isProgressivePushEnabled = prefs.getBool('progressivePush') ?? true;
  await NotificationService().init(); // Sicherstellen dass es initialisiert ist
  if (isProgressivePushEnabled) {
    await NotificationService().showProgressiveNotification(
      id: 1,
      title: currentLessonName,
      body:
          (timeRemaining.isNotEmpty ? "$timeRemaining  |  " : "") +
          "Danach: $nextLessonName",
      subText: subTextInfo,
      currentProgress: currentProgress,
      maxProgress: maxProgress,
      endTimeMs: endTimeMs,
    );
  } else {
    await NotificationService().cancelNotification(1);
  }
}

String _formatUntisTime(String time) {
  if (time.length < 3) return time;
  String formatted = time.padLeft(4, '0');
  return "${formatted.substring(0, 2)}:${formatted.substring(2)}";
}
