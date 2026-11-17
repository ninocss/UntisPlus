import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untisplus/core/sync_state.dart';
import 'package:untisplus/data/webuntis/webuntis_client.dart';

const _context = WebUntisRequestContext(
  schoolUrl: 'example.webuntis.com',
  schoolName: 'Example School',
  sessionId: 'session',
);

void main() {
  test('deduplicates identical in-flight RPC reads', () async {
    var requests = 0;
    final client = WebUntisClient(
      client: MockClient((request) async {
        requests++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response(jsonEncode({'result': []}), 200);
      }),
    );

    await Future.wait([
      client.rpc(
        context: _context,
        method: 'getTimetable',
        params: const {'startDate': 20260908},
      ),
      client.rpc(
        context: _context,
        method: 'getTimetable',
        params: const {'startDate': 20260908},
      ),
    ]);

    expect(requests, 1);
  });

  test('retries a transient server failure once', () async {
    var requests = 0;
    final client = WebUntisClient(
      client: MockClient((request) async {
        requests++;
        return requests == 1
            ? http.Response('temporary', 503)
            : http.Response(jsonEncode({'result': []}), 200);
      }),
    );

    await client.rpc(
      context: _context,
      method: 'getTimetable',
      params: const {},
    );

    expect(requests, 2);
  });

  test('maps unsupported RPC methods to a typed failure', () async {
    final client = WebUntisClient(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'error': {'message': 'Method not found'},
          }),
          200,
        ),
      ),
      maxRetries: 0,
    );

    await expectLater(
      client.rpc(context: _context, method: 'missing', params: const {}),
      throwsA(
        isA<WebUntisFailure>().having(
          (failure) => failure.kind,
          'kind',
          WebUntisFailureKind.unsupported,
        ),
      ),
    );
  });

  test('maps authentication RPC errors to authentication failures', () async {
    final client = WebUntisClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'Benutzer oder Passwort falsch'},
          }),
          200,
        ),
      ),
      maxRetries: 0,
    );

    await expectLater(
      client.rpc(
        context: _context.copyWith(sessionId: ''),
        method: 'authenticate',
        params: const {},
      ),
      throwsA(
        isA<WebUntisFailure>().having(
          (failure) => failure.kind,
          'kind',
          WebUntisFailureKind.authentication,
        ),
      ),
    );
  });

  test('retries on SocketException and succeeds', () async {
    var requests = 0;
    final client = WebUntisClient(
      client: MockClient((request) async {
        requests++;
        if (requests == 1) {
          throw const SocketException('Connection reset by peer');
        }
        return http.Response(jsonEncode({'result': ['recovered']}), 200);
      }),
      maxRetries: 2,
    );

    final res = await client.rpc(
      context: _context,
      method: 'getTimetable',
      params: const {},
    );
    expect(res['result'], ['recovered']);
    expect(requests, 2);
  });

  test('retries on HttpException and succeeds', () async {
    var requests = 0;
    final client = WebUntisClient(
      client: MockClient((request) async {
        requests++;
        if (requests == 1) {
          throw const HttpException(
            'Connection closed before full header was received',
          );
        }
        return http.Response(jsonEncode({'result': ['ok']}), 200);
      }),
      maxRetries: 2,
    );

    final res = await client.rpc(
      context: _context,
      method: 'getTimetable',
      params: const {},
    );
    expect(res['result'], ['ok']);
    expect(requests, 2);
  });

  test('retries on HTTP 429 rate limit and succeeds', () async {
    var requests = 0;
    final client = WebUntisClient(
      client: MockClient((request) async {
        requests++;
        if (requests == 1) {
          return http.Response('Too Many Requests', 429);
        }
        return http.Response(jsonEncode({'result': ['rate_limited_ok']}), 200);
      }),
      maxRetries: 2,
    );

    final res = await client.rpc(
      context: _context,
      method: 'getTimetable',
      params: const {},
    );
    expect(res['result'], ['rate_limited_ok']);
    expect(requests, 2);
  });

  test('maps SocketException to offline failure kind on exhaustion', () async {
    final client = WebUntisClient(
      client: MockClient((request) async {
        throw const SocketException('Failed host lookup');
      }),
      maxRetries: 1,
    );

    await expectLater(
      client.rpc(context: _context, method: 'getTimetable', params: const {}),
      throwsA(
        isA<WebUntisFailure>().having(
          (failure) => failure.kind,
          'kind',
          WebUntisFailureKind.offline,
        ),
      ),
    );
  });
}
