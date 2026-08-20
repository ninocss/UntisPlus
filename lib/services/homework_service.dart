import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeworkService {
  static Future<Map<String, List<Map<String, dynamic>>>> fetchHomeworkAndNotes({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
    required int personId,
    required int personType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 30));
    final end = endDate ?? now.add(const Duration(days: 30));

    final startStr = DateFormat('yyyyMMdd').format(start);
    final endStr = DateFormat('yyyyMMdd').format(end);

    final url = Uri.parse('https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Cookie': 'JSESSIONID=$sessionId; schoolname=$schoolName',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "id": "homework_fetch",
          "method": "getHomeWork2017",
          "params": [{
            "id": personId,
            "type": personType == 5 ? "STUDENT" : "TEACHER",
            "startDate": int.parse(startStr),
            "endDate": int.parse(endStr),
          }],
          "jsonrpc": "2.0"
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['result'] != null) {
          final List<dynamic> hwList = decoded['result']['homeworks'] ?? [];
          final List<dynamic> notesList = decoded['result']['lessonNotes'] ?? decoded['result']['lessonInfos'] ?? [];
          final List<dynamic> lessons = decoded['result']['lessons'] ?? [];
          
          // Map lessons for better context
          final lessonMap = {
            for (var l in lessons) l['id']: l
          };

          final homeworks = hwList.map((hw) {
            final hwMap = Map<String, dynamic>.from(hw as Map);
            final lessonId = hwMap['lessonId'];
            if (lessonId != null && lessonMap.containsKey(lessonId)) {
              hwMap['_lesson'] = lessonMap[lessonId];
            }
            return hwMap;
          }).toList();

          final notes = notesList.map((n) {
            final nMap = Map<String, dynamic>.from(n as Map);
            final lessonId = nMap['lessonId'];
            if (lessonId != null && lessonMap.containsKey(lessonId)) {
              nMap['_lesson'] = lessonMap[lessonId];
            }
            return nMap;
          }).toList();

          return {
            'homeworks': homeworks,
            'lessonNotes': notes,
          };
        }
      }
    } catch (e) {
      print('Error fetching homework and notes: $e');
    }
    return {
      'homeworks': [],
      'lessonNotes': [],
    };
  }

  // Keep old method for compatibility if needed, but point to new one
  static Future<List<Map<String, dynamic>>> fetchHomework({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
    required int personId,
    required int personType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await fetchHomeworkAndNotes(
      schoolUrl: schoolUrl,
      schoolName: schoolName,
      sessionId: sessionId,
      personId: personId,
      personType: personType,
      startDate: startDate,
      endDate: endDate,
    );
    return res['homeworks']!;
  }

  static Future<void> toggleDone(int homeworkId, bool done) async {
    final prefs = await SharedPreferences.getInstance();
    final doneList = prefs.getStringList('homework_done_ids') ?? [];
    final idStr = homeworkId.toString();
    if (done) {
      if (!doneList.contains(idStr)) {
        doneList.add(idStr);
      }
    } else {
      doneList.remove(idStr);
    }
    await prefs.setStringList('homework_done_ids', doneList);
  }

  static Future<Set<String>> getDoneIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('homework_done_ids') ?? []).toSet();
  }
}
