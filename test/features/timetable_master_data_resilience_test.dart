import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untisplus/data/webuntis/webuntis_client.dart';
import 'package:untisplus/features/timetable/data/timetable_repository.dart';

void main() {
  const context = WebUntisRequestContext(
    schoolUrl: 'school.example',
    schoolName: 'school',
    sessionId: 'session-123',
  );

  test(
    'fetchMasterData succeeds and retains subjects and teachers even if getRooms fails with permission error',
    () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'getSubjects') {
          return http.Response(
            jsonEncode({
              'result': [
                {'id': 101, 'name': 'M', 'longName': 'Mathematik'},
                {'id': 102, 'name': 'D', 'longName': 'Deutsch'},
              ],
            }),
            200,
          );
        } else if (method == 'getTeachers') {
          return http.Response(
            jsonEncode({
              'result': [
                {'id': 201, 'name': 'KOE', 'longName': 'König'},
              ],
            }),
            200,
          );
        } else if (method == 'getRooms') {
          // School configuration denies student accounts permission for room master data
          return http.Response(
            jsonEncode({
              'error': {
                'message': 'No right for getRooms',
                'code': -8520,
              },
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'result': []}), 200);
      });

      final repository = TimetableRepository(
        client: WebUntisClient(client: client, maxRetries: 0),
      );

      final masterData = await repository.fetchMasterData(context);

      expect(masterData.subjects, hasLength(2));
      expect(masterData.subjects[0]['name'], 'M');
      expect(masterData.subjects[1]['name'], 'D');
      expect(masterData.teachers, hasLength(1));
      expect(masterData.teachers[0]['name'], 'KOE');
      expect(masterData.rooms, isEmpty);
    },
  );

  test(
    'fetchTimetable requests showRooms, showSubjects, showTeachers, and showClasses by default',
    () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['method'], 'getTimetable');
        final options =
            (body['params'] as Map<String, dynamic>)['options']
                as Map<String, dynamic>;
        expect(options['showRooms'], isTrue);
        expect(options['showSubjects'], isTrue);
        expect(options['showTeachers'], isTrue);
        expect(options['showClasses'], isTrue);
        return http.Response(jsonEncode({'result': []}), 200);
      });

      final repository = TimetableRepository(
        client: WebUntisClient(client: client, maxRetries: 0),
      );

      final lessons = await repository.fetchTimetable(
        context: context,
        elementId: 123,
        elementType: 5,
        startDate: DateTime(2026, 11, 9),
        endDate: DateTime(2026, 11, 13),
      );

      expect(lessons, isEmpty);
    },
  );

  test(
    'fetchMasterData succeeds and retains rooms and teachers even if getSubjects fails',
    () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'getSubjects') {
          return http.Response(
            jsonEncode({
              'error': {
                'message': 'No right for getSubjects',
                'code': -8520,
              },
            }),
            200,
          );
        } else if (method == 'getTeachers') {
          return http.Response(
            jsonEncode({
              'result': [
                {'id': 201, 'name': 'KOE', 'longName': 'König'},
              ],
            }),
            200,
          );
        } else if (method == 'getRooms') {
          return http.Response(
            jsonEncode({
              'result': [
                {'id': 301, 'name': 'R101'},
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'result': []}), 200);
      });

      final repository = TimetableRepository(
        client: WebUntisClient(client: client, maxRetries: 0),
      );

      final masterData = await repository.fetchMasterData(context);

      expect(masterData.subjects, isEmpty);
      expect(masterData.teachers, hasLength(1));
      expect(masterData.teachers[0]['name'], 'KOE');
      expect(masterData.rooms, hasLength(1));
      expect(masterData.rooms[0]['name'], 'R101');
    },
  );
}
