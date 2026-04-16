import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../core/time_utils.dart';

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
    Workmanager().registerPeriodicTask(
      "untis_widget_update",
      "update_timetable_task",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}

Future<void> updateUntisData() async {
  final prefs = await SharedPreferences.getInstance();
  final schoolUrl = prefs.getString('schoolUrl') ?? '';
  final schoolName = prefs.getString('schoolName') ?? '';
  final user = prefs.getString('username') ?? '';
  final pass = prefs.getString('password') ?? '';

  if (schoolUrl.isEmpty || schoolName.isEmpty || user.isEmpty || pass.isEmpty) {
    return;
  }

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

  int personId = prefs.getInt('personId') ?? 0;
  int personType = prefs.getInt('personType') ?? 5;

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
    await WidgetService.updateWidgets(
      currentLesson: "Kein Unterricht heute",
      nextLesson: "-",
      timeRemaining: "",
      dailySchedule: "Kein Unterricht heute",
    );
    await NotificationService().cancelNotification(1);
    return;
  }

  lessons.sort(
    (a, b) => (a['startTime'] as int).compareTo(b['startTime'] as int),
  );

  String currentLessonName = "Frei";
  String nextLessonName = "-";
  String timeRemaining = "";

  StringBuffer dailyScheduleBuffer = StringBuffer();

  final currentTimeInt = now.hour * 100 + now.minute;
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
      return "Stunde $startStr - $endStr";
    }

    return "Stunde";
  }

  for (int i = 0; i < lessons.length; i++) {
    var l = lessons[i];
    int start = l['startTime'] as int;
    int end = l['endTime'] as int;

    final name = lessonDisplayName(l);

    String startStr = formatUntisTime(start.toString());
    String endStr = formatUntisTime(end.toString());

    dailyScheduleBuffer.writeln("$startStr - $endStr: $name");

    if (!foundCurrent) {
      if (currentTimeInt >= start && currentTimeInt <= end) {
        currentLessonName = name;
        timeRemaining = "Bis $endStr Uhr";
        foundCurrent = true;
        subTextInfo = "Aktuelle Stunde";

        DateTime startTimeDate = untisTimeToDate(start);
        DateTime endTimeDate = untisTimeToDate(end);

        maxProgress = endTimeDate.difference(startTimeDate).inMinutes;
        currentProgress = now.difference(startTimeDate).inMinutes;
        endTimeMs = endTimeDate.millisecondsSinceEpoch;

        if (i + 1 < lessons.length) {
          var nextL = lessons[i + 1];
          nextLessonName = lessonDisplayName(nextL);
        } else {
          nextLessonName = "Schluss";
        }
      } else if (currentTimeInt < start) {
        timeRemaining = "Start um $startStr";
        nextLessonName = name;
        foundCurrent = true;
        subTextInfo = "Nächste Stunde";
        endTimeMs = untisTimeToDate(start).millisecondsSinceEpoch;
      }
    }
  }

  if (!foundCurrent && currentTimeInt > (lessons.last['endTime'] as int)) {
    currentLessonName = "Schluss";
    nextLessonName = "-";
    timeRemaining = "";
    subTextInfo = "Kein Unterricht mehr";

    await WidgetService.updateWidgets(
      currentLesson: currentLessonName,
      nextLesson: nextLessonName,
      timeRemaining: timeRemaining,
      dailySchedule: dailyScheduleBuffer.toString(),
    );
    await NotificationService().cancelNotification(1);
    return;
  }

  await WidgetService.updateWidgets(
    currentLesson: currentLessonName,
    nextLesson: nextLessonName,
    timeRemaining: timeRemaining,
    dailySchedule: dailyScheduleBuffer.toString(),
  );

  final isProgressivePushEnabled = prefs.getBool('progressivePush') ?? true;
  await NotificationService().init();
  if (isProgressivePushEnabled) {
    await NotificationService().showProgressiveNotification(
      id: 1,
      title: currentLessonName,
      body:
          "${timeRemaining.isNotEmpty ? "$timeRemaining  |  " : ""}Danach: $nextLessonName",
      subText: subTextInfo,
      currentProgress: currentProgress,
      maxProgress: maxProgress,
      endTimeMs: endTimeMs,
    );
  } else {
    await NotificationService().cancelNotification(1);
  }
}

