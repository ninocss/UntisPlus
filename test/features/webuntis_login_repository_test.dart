import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untisplus/data/webuntis/webuntis_client.dart';
import 'package:untisplus/features/accounts/data/webuntis_login_repository.dart';

void main() {
  test('password login normalizes a class identity', () async {
    late http.Request capturedRequest;
    final repository = WebUntisLoginRepository(
      client: WebUntisClient(
        maxRetries: 0,
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'result': {'sessionId': 'session-1', 'klasseId': 42},
            }),
            200,
          );
        }),
      ),
    );

    final result = await repository.authenticate(
      schoolUrl: 'school.example',
      schoolName: 'Example',
      username: 'student',
      credential: 'password',
      requestId: 'login-1',
    );

    expect(result.status, WebUntisLoginStatus.success);
    expect(result.sessionId, 'session-1');
    expect(result.personId, 42);
    expect(result.personType, 1);
    expect(capturedRequest.url.path, '/WebUntis/jsonrpc.do');
    expect(jsonDecode(capturedRequest.body), {
      'id': 'login-1',
      'method': 'authenticate',
      'params': {
        'user': 'student',
        'password': 'password',
        'client': 'UntisPlus',
      },
      'jsonrpc': '2.0',
    });
  });

  test('password login reports when a second factor is required', () async {
    final repository = WebUntisLoginRepository(
      client: WebUntisClient(
        maxRetries: 0,
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {
                'code': -8520,
                'message': 'Authentication failed',
                'data': 'OTP required',
              },
            }),
            200,
          ),
        ),
      ),
    );

    final result = await repository.authenticate(
      schoolUrl: 'school.example',
      schoolName: 'Example',
      username: 'student',
      credential: 'password',
    );

    expect(result.status, WebUntisLoginStatus.requiresTwoFactor);
  });

  test('password login treats a rejected supplied code as invalid', () async {
    final repository = WebUntisLoginRepository(
      client: WebUntisClient(
        maxRetries: 0,
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'code': -8520, 'message': 'Authentication failed'},
            }),
            200,
          ),
        ),
      ),
    );

    final result = await repository.authenticate(
      schoolUrl: 'school.example',
      schoolName: 'Example',
      username: 'student',
      credential: 'password',
      oneTimeCode: '123456',
    );

    expect(result.status, WebUntisLoginStatus.invalidOneTimeCode);
  });

  test('login key resolves session and person identity once', () async {
    final requests = <http.Request>[];
    final repository = WebUntisLoginRepository(
      client: WebUntisClient(
        maxRetries: 0,
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('jsonrpc_intern.do')) {
            return http.Response(
              jsonEncode({'result': {}}),
              200,
              headers: {'set-cookie': 'JSESSIONID=session-key; Path=/'},
            );
          }
          return http.Response(
            jsonEncode({
              'data': {
                'loginServiceConfig': {
                  'user': {
                    'personId': 7,
                    'persons': [
                      {'id': 7, 'type': 5},
                    ],
                  },
                },
              },
            }),
            200,
          );
        }),
      ),
    );

    final result = await repository.authenticate(
      schoolUrl: 'school.example',
      schoolName: 'Example',
      username: 'student',
      credential: 'JBSWY3DPEHPK3PXP',
      useLoginKey: true,
    );

    expect(result.status, WebUntisLoginStatus.success);
    expect(result.sessionId, 'session-key');
    expect(result.personId, 7);
    expect(result.personType, 5);
    expect(requests, hasLength(2));
    expect(requests.last.headers['cookie'], contains('JSESSIONID=session-key'));
  });
}
