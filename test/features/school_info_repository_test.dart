import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untisplus/data/webuntis/webuntis_client.dart';
import 'package:untisplus/features/school_info/data/school_info_repository.dart';

void main() {
  test('uses matching cookie and JWT headers for the inbox', () async {
    final jwt =
        'header.${base64Url.encode(utf8.encode(jsonEncode({'tenant_id': 'tenant-7'}))).replaceAll('=', '')}.signature';
    final client = WebUntisClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/api/token/new')) {
          if (request.headers['cookie']?.contains('schoolname=_') == true) {
            return http.Response('Unauthorized', 401);
          }
          return http.Response(jsonEncode({'accessToken': jwt}), 200);
        }
        if (request.url.path.endsWith('/jsonrpc.do')) {
          return http.Response(
            jsonEncode({
              'result': {'id': 2026},
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/api/rest/view/v2/messages')) {
          expect(request.headers['authorization'], 'Bearer $jwt');
          expect(request.headers['tenant-id'], 'tenant-7');
          expect(request.headers['x-webuntis-api-school-year-id'], '2026');
          expect(
            request.headers['cookie'],
            contains('schoolname=Example School'),
          );
          return http.Response(
            jsonEncode({
              'incomingMessages': [
                {
                  'message': {
                    'id': 'message-7',
                    'title': 'Important',
                    'content': 'Read me',
                  },
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/news/newsWidgetData')) {
          return http.Response(
            jsonEncode({
              'data': {'messagesOfDay': []},
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      }),
      maxRetries: 0,
    );

    final result = await SchoolInfoRepository(client: client).fetch(
      schoolUrl: 'example.webuntis.com',
      schoolName: 'Example School',
      sessionId: 'session-id',
    );
    expect(result.inbox.single['id'], 'message-7');
    expect(result.inboxFailure, isNull);
  });

  test('keeps school news when inbox access is denied', () async {
    final client = WebUntisClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/api/token/new')) {
          return http.Response('jwt-token', 200);
        }
        if (request.url.path.contains('/api/rest/view/') &&
            request.url.path.endsWith('/messages')) {
          return http.Response('Forbidden', 403);
        }
        if (request.url.path.contains('/news/newsWidgetData')) {
          return http.Response(
            jsonEncode({
              'data': {
                'messagesOfDay': [
                  {'id': 'news-1', 'title': 'School news', 'text': 'Visible'},
                ],
              },
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      }),
      maxRetries: 0,
    );

    final result = await SchoolInfoRepository(client: client).fetch(
      schoolUrl: 'example.webuntis.com',
      schoolName: 'Example School',
      sessionId: 'session-id',
    );
    expect(result.news, isNotEmpty);
    expect(result.inbox, isEmpty);
    expect(result.inboxFailure?.statusCode, 403);
    expect(result.newsFailure, isNull);
  });

  test('keeps attachments stored beside a nested inbox message', () async {
    final client = WebUntisClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/api/token/new')) {
          return http.Response('inbox-token', 200);
        }
        if (request.url.path.endsWith('/api/rest/view/v1/messages')) {
          return http.Response(
            jsonEncode({
              'incomingMessages': [
                {
                  'fileAttachments': [
                    {'fileId': 'file-17', 'fileRegularName': 'Elternbrief.pdf'},
                  ],
                  'message': {
                    'id': 'message-1',
                    'title': 'Elternbrief',
                    'contentPreview': 'Bitte beachten',
                    'content': '<p>Bitte beachten</p>',
                    'sender': {'displayName': 'Frau Beispiel'},
                    'sentDateTime': '2026-09-22T08:15:00',
                  },
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/news/newsWidgetData')) {
          return http.Response(
            jsonEncode({
              'data': {
                'messagesOfDay': [
                  {'id': 'news-1', 'text': 'News'},
                ],
              },
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      }),
      maxRetries: 0,
    );

    final result = await SchoolInfoRepository(client: client).fetch(
      schoolUrl: 'example.webuntis.com',
      schoolName: 'Example School',
      sessionId: 'session-id',
    );

    expect(result.inbox, hasLength(1));
    expect(result.inbox.single['id'], 'message-1');
    expect(result.inbox.single['message'], 'Bitte beachten');
    expect(result.inbox.single['author'], 'Frau Beispiel');
    expect(result.inbox.single['attachments'], [
      {'fileId': 'file-17', 'fileRegularName': 'Elternbrief.pdf'},
    ]);
  });

  test('deduplicates attachments exposed on wrapper and message', () async {
    final attachment = {'id': 'shared-file', 'name': 'Stundenplan.png'};
    final client = WebUntisClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/api/token/new')) {
          return http.Response('inbox-token', 200);
        }
        if (request.url.path.endsWith('/api/rest/view/v1/messages')) {
          return http.Response(
            jsonEncode({
              'incomingMessages': [
                {
                  'attachments': [attachment],
                  'message': {
                    'id': 'message-2',
                    'title': 'Plan',
                    'content': 'Anbei der Plan',
                    'attachments': [attachment],
                  },
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/news/newsWidgetData')) {
          return http.Response(
            jsonEncode({
              'data': {
                'messagesOfDay': [
                  {'id': 'news-1', 'text': 'News'},
                ],
              },
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      }),
      maxRetries: 0,
    );

    final result = await SchoolInfoRepository(client: client).fetch(
      schoolUrl: 'example.webuntis.com',
      schoolName: 'Example School',
      sessionId: 'session-id',
    );

    expect(result.inbox.single['attachments'], [attachment]);
  });
}
