import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untisplus/data/webuntis/webuntis_client.dart';
import 'package:untisplus/features/accounts/data/school_directory_repository.dart';

void main() {
  test(
    'school directory owns request shape and parses valid schools',
    () async {
      late http.Request capturedRequest;
      final repository = SchoolDirectoryRepository(
        client: WebUntisClient(
          maxRetries: 0,
          client: MockClient((request) async {
            capturedRequest = request;
            return http.Response(
              jsonEncode({
                'result': {
                  'schools': [
                    {
                      'schoolId': '42',
                      'loginName': 'example',
                      'displayName': 'Example School',
                      'server': 'school.example',
                      'address': 'Berlin',
                    },
                    {'displayName': 'Incomplete'},
                  ],
                },
              }),
              200,
            );
          }),
        ),
      );

      final schools = await repository.search('  exam  ');

      expect(capturedRequest.url, SchoolDirectoryRepository.endpoint);
      expect(
        capturedRequest.headers['content-type'],
        contains('application/json'),
      );
      expect(jsonDecode(capturedRequest.body), {
        'id': '1',
        'method': 'searchSchool',
        'params': [
          {'search': 'exam'},
        ],
        'jsonrpc': '2.0',
      });
      expect(schools, hasLength(1));
      expect(schools.single.id, 42);
      expect(schools.single.serverUrl, 'school.example');
    },
  );

  test('short school searches do not touch the network', () async {
    var requests = 0;
    final repository = SchoolDirectoryRepository(
      client: WebUntisClient(
        client: MockClient((request) async {
          requests++;
          return http.Response('{}', 200);
        }),
      ),
    );

    expect(await repository.search('ab'), isEmpty);
    expect(requests, 0);
  });
}
