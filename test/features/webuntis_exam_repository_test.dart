import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untisplus/data/webuntis/webuntis_client.dart';
import 'package:untisplus/features/exams/data/webuntis_exam_repository.dart';

void main() {
  test('exam repository falls back and forwards session context', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/api/exams')) {
        return http.Response(jsonEncode({'data': []}), 200);
      }
      return http.Response(
        jsonEncode({
          'exams': [
            {'id': 7, 'name': 'Mathematik'},
          ],
        }),
        200,
      );
    });
    final repository = WebUntisExamRepository(
      client: WebUntisClient(client: client, maxRetries: 0),
    );

    final result = await repository.fetch(
      context: const WebUntisRequestContext(
        schoolUrl: 'school.example',
        schoolName: 'Example School',
        sessionId: 'session-123',
      ),
      personId: 42,
      start: DateTime(2026, 9, 2),
      end: DateTime(2026, 10, 3),
    );

    expect(result.single['id'], 7);
    expect(requests, hasLength(2));
    expect(requests.first.url.queryParameters, {
      'startDate': '20260902',
      'endDate': '20261003',
    });
    expect(
      requests.first.headers['cookie'],
      'JSESSIONID=session-123; schoolname=Example School',
    );
  });

  test(
    'exam repository reaches person endpoint after empty responses',
    () async {
      final paths = <String>[];
      final client = MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/student/42')) {
          return http.Response(
            jsonEncode([
              {'id': 9},
            ]),
            200,
          );
        }
        return http.Response('[]', 200);
      });
      final repository = WebUntisExamRepository(
        client: WebUntisClient(client: client, maxRetries: 0),
      );

      final result = await repository.fetch(
        context: const WebUntisRequestContext(
          schoolUrl: 'school.example',
          schoolName: 'School',
        ),
        personId: 42,
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 2, 1),
      );

      expect(result.single['id'], 9);
      expect(paths.last, endsWith('/api/exams/student/42'));
    },
  );
}
