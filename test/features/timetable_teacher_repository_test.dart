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

  test('loads the teacher directory from the active school context', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'school.example');
      expect(request.headers['cookie'], contains('JSESSIONID=session-123'));
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['method'], 'getTeachers');
      return http.Response(
        jsonEncode({
          'result': [
            {'id': 4, 'name': 'AB', 'foreName': 'Anna', 'longName': 'Becker'},
          ],
        }),
        200,
      );
    });
    final repository = TimetableRepository(
      client: WebUntisClient(client: client, maxRetries: 0),
    );

    final teachers = await repository.fetchTeachers(context);

    expect(teachers, hasLength(1));
    expect(teachers.single['id'], 4);
  });

  test(
    'requests one teacher timetable with room and subject details',
    () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['method'], 'getTimetable');
        final options =
            (body['params'] as Map<String, dynamic>)['options']
                as Map<String, dynamic>;
        expect(options['element'], {'id': 42, 'type': 2});
        expect(options['showRooms'], isTrue);
        expect(options['showSubjects'], isTrue);
        expect(options['startDate'], 20260924);
        expect(options['endDate'], 20260924);
        return http.Response(jsonEncode({'result': []}), 200);
      });
      final repository = TimetableRepository(
        client: WebUntisClient(client: client, maxRetries: 0),
      );

      final lessons = await repository.fetchTeacherTimetable(
        context: context,
        teacherId: 42,
        date: DateTime(2026, 9, 24),
      );

      expect(lessons, isEmpty);
    },
  );

  test('fetches public day timetable data', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/WebUntis/api/public/timetable/day/data');
      expect(request.url.queryParameters['elementType'], '1');
      expect(request.url.queryParameters['elementId'], '10');
      expect(request.url.queryParameters['date'], '2026-11-03');
      return http.Response(
        jsonEncode({
          'data': {
            'result': {
              'data': {
                'elementIds': [10],
              },
            },
          },
        }),
        200,
      );
    });
    final repository = TimetableRepository(
      client: WebUntisClient(client: client, maxRetries: 0),
    );

    final data = await repository.fetchPublicDayData(
      context: context,
      elementId: 10,
      elementType: 1,
      date: DateTime(2026, 11, 3),
    );

    expect(data?['elementIds'], [10]);
  });

  test('fetches weekly page config', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/WebUntis/api/public/timetable/weekly/pageconfig');
      return http.Response(
        jsonEncode({
          'showTeacher': true,
        }),
        200,
      );
    });
    final repository = TimetableRepository(
      client: WebUntisClient(client: client, maxRetries: 0),
    );

    final config = await repository.fetchWeeklyPageConfig(context: context);
    expect(config?['showTeacher'], isTrue);
  });
}
