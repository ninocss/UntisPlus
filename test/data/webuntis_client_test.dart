import 'dart:convert';

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
}
