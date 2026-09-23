import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untisplus/data/webuntis/webuntis_client.dart';
import 'package:untisplus/features/school_info/data/school_info_repository.dart';

void main() {
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
