import 'dart:convert';
import 'dart:typed_data';

import '../../../core/sync_state.dart';
import '../../../core/time_utils.dart';
import '../../../data/webuntis/webuntis_client.dart';
import '../../../data/webuntis/webuntis_message_context.dart';

class SchoolInfoReadResult {
  const SchoolInfoReadResult({
    required this.inbox,
    required this.news,
    this.inboxFailure,
    this.newsFailure,
  });

  final List<Map<String, dynamic>> inbox;
  final List<Map<String, dynamic>> news;
  final WebUntisFailure? inboxFailure;
  final WebUntisFailure? newsFailure;
}

class SchoolInfoRepository {
  SchoolInfoRepository({WebUntisClient? client})
    : _client = client ?? WebUntisClient();

  final WebUntisClient _client;

  Future<SchoolInfoReadResult> fetch({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
    Future<String?> Function()? reauthenticate,
  }) async {
    var activeSession = sessionId;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final result = await _fetchOnce(
          schoolUrl: schoolUrl,
          schoolName: schoolName,
          sessionId: activeSession,
        );
        final authFailure = [
          result.inboxFailure,
          result.newsFailure,
        ].any((failure) => failure?.kind == WebUntisFailureKind.authentication);
        if (attempt == 0 && authFailure && reauthenticate != null) {
          final refreshed = await reauthenticate();
          if (refreshed != null && refreshed.isNotEmpty) {
            activeSession = refreshed;
            continue;
          }
        }
        return result;
      } on WebUntisFailure catch (failure) {
        final canRetry =
            attempt == 0 &&
            reauthenticate != null &&
            (failure.kind == WebUntisFailureKind.authentication ||
                failure.kind == WebUntisFailureKind.permission);
        if (!canRetry) rethrow;
        final refreshed = await reauthenticate();
        if (refreshed == null || refreshed.isEmpty) rethrow;
        activeSession = refreshed;
      }
    }
    return const SchoolInfoReadResult(inbox: [], news: []);
  }

  Future<Uint8List> downloadAttachment({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
    required String attachmentId,
    Future<String?> Function()? reauthenticate,
  }) async {
    var activeSession = sessionId;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _downloadAttachmentOnce(
          schoolUrl: schoolUrl,
          schoolName: schoolName,
          sessionId: activeSession,
          attachmentId: attachmentId,
        );
      } on WebUntisFailure catch (failure) {
        final canRetry =
            attempt == 0 &&
            reauthenticate != null &&
            (failure.kind == WebUntisFailureKind.authentication ||
                failure.kind == WebUntisFailureKind.permission);
        if (!canRetry) rethrow;
        final refreshed = await reauthenticate();
        if (refreshed == null || refreshed.isEmpty) rethrow;
        activeSession = refreshed;
      }
    }
    throw const WebUntisFailure(
      WebUntisFailureKind.unknown,
      'WebUntis attachment download failed.',
    );
  }

  Future<Uint8List> _downloadAttachmentOnce({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
    required String attachmentId,
  }) async {
    WebUntisFailure? lastFailure;
    final uri = Uri.parse(
      'https://$schoolUrl/WebUntis/messageFileRequest.do'
      '?file=${Uri.encodeQueryComponent(attachmentId)}',
    );
    for (final cookie in _schoolCookies(schoolName)) {
      try {
        return await _client.getBytes(
          uri: uri,
          headers: {
            'Cookie': 'JSESSIONID=$sessionId; schoolname=$cookie',
            'Accept': 'application/octet-stream',
          },
        );
      } on WebUntisFailure catch (failure) {
        lastFailure = failure;
      }
    }
    if (lastFailure != null) throw lastFailure;
    throw const WebUntisFailure(
      WebUntisFailureKind.unknown,
      'WebUntis attachment download failed.',
    );
  }

  Future<SchoolInfoReadResult> _fetchOnce({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
  }) async {
    final cookies = _schoolCookies(schoolName);
    WebUntisFailure? inboxFailure;
    WebUntisFailure? newsFailure;
    final initial = await Future.wait<List<Map<String, dynamic>>>([
      _fetchInbox(
        schoolUrl: schoolUrl,
        schoolName: schoolName,
        sessionId: sessionId,
      ).onError<WebUntisFailure>((failure, _) {
        inboxFailure = failure;
        return const [];
      }),
      _fetchNewsWidget(
        schoolUrl: schoolUrl,
        schoolName: schoolName,
        sessionId: sessionId,
        cookies: cookies,
      ).onError<WebUntisFailure>((failure, _) {
        newsFailure = failure;
        return const [];
      }),
    ]);
    final inbox = initial[0];
    var news = initial[1];

    if (news.isEmpty) {
      final start = DateTime.now().subtract(const Duration(days: 45));
      final end = DateTime.now().add(const Duration(days: 90));
      final startStr = untisDateString(start);
      final endStr = untisDateString(end);
      final today = untisDateString(DateTime.now());

      final fallbacks = <Future<List<dynamic>> Function()>[
        () => _rpcList(
          schoolUrl: schoolUrl,
          schoolName: schoolName,
          sessionId: sessionId,
          cookies: cookies,
          method: 'getMessagesOfDay2017',
          params: {'date': today},
        ),
        () => _getList(
          schoolUrl: schoolUrl,
          sessionId: sessionId,
          cookies: cookies,
          path:
              '/WebUntis/api/public/messages?startDate=$startStr&endDate=$endStr',
        ),
        () => _getList(
          schoolUrl: schoolUrl,
          sessionId: sessionId,
          cookies: cookies,
          path: '/WebUntis/api/messages?startDate=$startStr&endDate=$endStr',
        ),
        () => _getList(
          schoolUrl: schoolUrl,
          sessionId: sessionId,
          cookies: cookies,
          path:
              '/WebUntis/api/public/notifications?startDate=$startStr&endDate=$endStr',
        ),
        () => _getList(
          schoolUrl: schoolUrl,
          sessionId: sessionId,
          cookies: cookies,
          path:
              '/WebUntis/api/public/notices?startDate=$startStr&endDate=$endStr',
        ),
        () => _rpcList(
          schoolUrl: schoolUrl,
          schoolName: schoolName,
          sessionId: sessionId,
          cookies: cookies,
          method: 'getMessagesOfDay',
          params: {'date': today},
        ),
        () => _rpcList(
          schoolUrl: schoolUrl,
          schoolName: schoolName,
          sessionId: sessionId,
          cookies: cookies,
          method: 'getMessages',
          params: {'startDate': startStr, 'endDate': endStr},
        ),
      ];
      for (final fallback in fallbacks) {
        List<dynamic> result;
        try {
          result = await fallback();
        } on WebUntisFailure catch (failure) {
          if (failure.statusCode != 404 || newsFailure == null) {
            newsFailure = failure;
          }
          continue;
        }
        if (result.isEmpty) continue;
        news = result
            .whereType<Map>()
            .map(_stringKeyedMap)
            .toList(growable: false);
        break;
      }
    }

    return SchoolInfoReadResult(
      inbox: inbox,
      news: news,
      inboxFailure: inboxFailure,
      newsFailure: news.isEmpty && newsFailure?.statusCode != 404
          ? newsFailure
          : null,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchInbox({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
  }) async {
    final context = await WebUntisMessageContextResolver(_client).resolve(
      schoolUrl: schoolUrl,
      schoolName: schoolName,
      sessionId: sessionId,
    );
    WebUntisFailure? lastFailure;
    for (final version in const ['v2', 'v1']) {
      try {
        final decoded = await _client.getJson(
          uri: Uri.parse(
            'https://$schoolUrl/WebUntis/api/rest/view/$version/messages',
          ),
          headers: context.headers,
        );
        final incoming = decoded is Map ? decoded['incomingMessages'] : null;
        if (incoming is List) return _normalizeInbox(incoming);
      } on WebUntisFailure catch (failure) {
        lastFailure = failure;
        if (failure.statusCode != 404 && failure.statusCode != 500) rethrow;
      }
    }
    if (lastFailure != null) throw lastFailure;
    throw const WebUntisFailure(
      WebUntisFailureKind.invalidData,
      'WebUntis did not return a compatible message list.',
    );
  }

  static List<Map<String, dynamic>> _normalizeInbox(List incoming) {
    return incoming
        .whereType<Map>()
        .map((raw) {
          final rawMap = _stringKeyedMap(raw);
          final nestedMessage = rawMap['message'] is Map
              ? _stringKeyedMap(rawMap['message'] as Map)
              : null;
          final map = <String, dynamic>{...rawMap};
          if (nestedMessage != null) {
            map
              ..remove('message')
              ..addAll(nestedMessage);
          }
          final sender = map['sender'];
          final preview =
              map['contentPreview'] ?? map['message'] ?? map['text'] ?? '';
          final attachments = _inboxAttachments(rawMap, nestedMessage);
          return <String, dynamic>{
            ...map,
            'message': preview,
            'fullBody': map['content'] ?? preview,
            'author': sender is Map
                ? sender['displayName'] ?? sender['name']
                : null,
            'date': map['sentDateTime'] ?? map['date'] ?? map['sendTime'],
            if (attachments.isNotEmpty) 'attachments': attachments,
          };
        })
        .toList(growable: false);
  }

  static List<dynamic> _inboxAttachments(
    Map<String, dynamic> entry,
    Map<String, dynamic>? message,
  ) {
    final attachments = <dynamic>[];
    final seen = <String>{};

    for (final source in [entry, ?message]) {
      for (final key in const [
        'attachments',
        'fileAttachments',
        'attachmentList',
        'files',
      ]) {
        final value = source[key];
        if (value is! List) continue;
        for (final rawAttachment in value) {
          if (rawAttachment is! Map) continue;
          final attachment = _stringKeyedMap(rawAttachment);
          final id =
              (attachment['fileId'] ??
                      attachment['attachmentId'] ??
                      attachment['fileAttachmentId'] ??
                      attachment['id'] ??
                      '')
                  .toString()
                  .trim();
          if (id.isEmpty || seen.add(id)) attachments.add(attachment);
        }
      }
    }

    return attachments;
  }

  Future<List<Map<String, dynamic>>> _fetchNewsWidget({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
    required List<String> cookies,
  }) async {
    final output = <Map<String, dynamic>>[];
    for (var index = 0; index < 4; index++) {
      final day = DateTime.now().subtract(Duration(days: index));
      final date = untisDateString(day);
      final decoded = await _getJson(
        uri: Uri.parse(
          'https://$schoolUrl/WebUntis/api/public/news/'
          'newsWidgetData?date=$date',
        ),
        sessionId: sessionId,
        cookies: cookies,
      );
      final data = decoded is Map ? decoded['data'] : null;
      final messages = data is Map ? data['messagesOfDay'] : null;
      if (messages is! List) continue;
      for (final raw in messages.whereType<Map>()) {
        final map = _stringKeyedMap(raw);
        output.add({
          ...map,
          'date': map['date'] ?? date,
          'message': map['text'] ?? map['message'] ?? '',
        });
      }
    }
    return output;
  }

  Future<List<dynamic>> _getList({
    required String schoolUrl,
    required String sessionId,
    required List<String> cookies,
    required String path,
  }) async {
    final decoded = await _getJson(
      uri: Uri.parse('https://$schoolUrl$path'),
      sessionId: sessionId,
      cookies: cookies,
    );
    return _extractList(decoded);
  }

  Future<List<dynamic>> _rpcList({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
    required List<String> cookies,
    required String method,
    required Map<String, dynamic> params,
  }) async {
    WebUntisFailure? lastFailure;
    for (final cookie in cookies) {
      try {
        final decoded = await _client.rpc(
          context: WebUntisRequestContext(
            schoolUrl: schoolUrl,
            schoolName: schoolName,
            sessionId: sessionId,
            cookieSchoolName: cookie,
          ),
          method: method,
          params: params,
          requestId: 'school-info',
        );
        return _extractList(decoded['result'] ?? decoded);
      } on WebUntisFailure catch (failure) {
        lastFailure = failure;
      } catch (_) {}
    }
    if (lastFailure != null) throw lastFailure;
    return const [];
  }

  Future<dynamic> _getJson({
    required Uri uri,
    required String sessionId,
    required List<String> cookies,
    Map<String, String> extraHeaders = const {},
  }) async {
    WebUntisFailure? lastFailure;
    for (final cookie in cookies) {
      try {
        return await _client.getJson(
          uri: uri,
          headers: {
            'Cookie': 'JSESSIONID=$sessionId; schoolname=$cookie',
            'Accept': 'application/json',
            ...extraHeaders,
          },
        );
      } on WebUntisFailure catch (failure) {
        lastFailure = failure;
      } catch (_) {}
    }
    if (lastFailure != null) throw lastFailure;
    return null;
  }

  static List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final value in decoded.values) {
        final nested = _extractList(value);
        if (nested.isNotEmpty) return nested;
      }
    }
    return const [];
  }

  static List<String> _schoolCookies(String schoolName) {
    final values = <String>[];
    if (schoolName.isNotEmpty) {
      try {
        values.add('_${base64Encode(utf8.encode(schoolName))}');
      } catch (_) {}
      values.add(schoolName);
    }
    return values.toSet().toList(growable: false);
  }

  static Map<String, dynamic> _stringKeyedMap(Map raw) =>
      raw.map((key, value) => MapEntry(key.toString(), value));
}
