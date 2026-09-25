import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untisplus/services/webuntis_message_service.dart';

void main() {
  test(
    'compose permissions and recipients share token and fallback headers',
    () async {
      final jwt =
          'header.${base64Url.encode(utf8.encode(jsonEncode({'tenant_id': 'tenant-7'}))).replaceAll('=', '')}.signature';
      final service = WebUntisMessageService(
        client: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/api/token/new')) {
            return http.Response(jsonEncode({'accessToken': jwt}), 200);
          }
          if (path.endsWith('/jsonrpc.do')) {
            return http.Response(
              jsonEncode({
                'result': {'id': 2026},
              }),
              200,
            );
          }
          if (path.contains('/messages/')) {
            if (path.contains('/v2/')) return http.Response('Missing', 404);
            expect(request.headers['authorization'], 'Bearer $jwt');
            expect(request.headers['tenant-id'], 'tenant-7');
            expect(request.headers['x-webuntis-api-school-year-id'], '2026');
            if (path.endsWith('/permissions')) {
              return http.Response(
                jsonEncode({
                  'recipientOptions': ['TEACHER'],
                }),
                200,
              );
            }
            if (path.endsWith('/recipients/static/persons')) {
              return http.Response(
                jsonEncode([
                  {
                    'type': 'TEACHER',
                    'persons': [
                      {'userId': 42, 'displayName': 'Ada Beispiel'},
                    ],
                  },
                ]),
                200,
              );
            }
          }
          return http.Response('Missing', 404);
        }),
      );

      final data = await service.loadComposeData(
        schoolUrl: 'example.webuntis.com',
        schoolName: 'Example School',
        sessionId: 'session-id',
      );
      expect(data.recipients.single.name, 'Ada Beispiel');
      expect(data.permissions.recipientOptions, ['TEACHER']);
    },
  );

  test(
    'recipient permission failure is not presented as an empty list',
    () async {
      final service = WebUntisMessageService(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/api/token/new')) {
            return http.Response('token', 200);
          }
          if (request.url.path.endsWith('/jsonrpc.do')) {
            return http.Response(
              jsonEncode({
                'result': {'id': 2026},
              }),
              200,
            );
          }
          return http.Response('Forbidden', 403);
        }),
      );

      expect(
        service.loadComposeData(
          schoolUrl: 'example.webuntis.com',
          schoolName: 'Example School',
          sessionId: 'session-id',
        ),
        throwsA(
          isA<WebUntisMessageFailure>().having(
            (failure) => failure.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    },
  );
}
