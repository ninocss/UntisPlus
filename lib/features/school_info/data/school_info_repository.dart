import 'dart:convert';
import 'dart:typed_data';

import '../../../core/sync_state.dart';
import '../../../core/time_utils.dart';
import '../../../data/webuntis/webuntis_client.dart';

class SchoolInfoReadResult {
  const SchoolInfoReadResult({
    required this.inbox,
    required this.news,
  });

  final List<Map<String, dynamic>> inbox;
  final List<Map<String, dynamic>> news;
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
        return await _fetchOnce(
          schoolUrl: schoolUrl,
          schoolName: schoolName,
          sessionId: activeSession,
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
    final initial = await Future.wait<List<Map<String, dynamic>>>([
      _fetchInbox(
        schoolUrl: schoolUrl,
        schoolName: schoolName,
        sessionId: sessionId,
        cookies: cookies,
      ),
      _fetchNewsWidget(
        schoolUrl: schoolUrl,
        schoolName: schoolName,
        sessionId: sessionId,
        cookies: cookies,
      ),
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
        final result = await fallback();
        if (result.isEmpty) continue;
        news = result
            .whereType<Map>()
            .map(_stringKeyedMap)
            .toList(growable: false);
        break;
      }
    }

    return SchoolInfoReadResult(inbox: inbox, news: news);
  }

  Future<List<Map<String, dynamic>>> _fetchInbox({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
    required List<String> cookies,
  }) async {
    final token = await _fetchToken(
      schoolUrl: schoolUrl,
      sessionId: sessionId,
      cookies: cookies,
    );
    if (token == null || token.isEmpty) return const [];

    final decoded = await _getJson(
      uri: Uri.parse(
        'https://$schoolUrl/WebUntis/api/rest/view/v1/messages',
      ),
      sessionId: sessionId,
      cookies: cookies,
      extraHeaders: {'Authorization': 'Bearer $token'},
    );
    final incoming = decoded is Map ? decoded['incomingMessages'] : null;
    if (incoming is! List) return const [];

    return incoming
        .whereType<Map>()
        .map((raw) {
          final rawMap = _stringKeyedMap(raw);
          final map = rawMap['message'] is Map
              ? _stringKeyedMap(rawMap['message'] as Map)
              : rawMap;
          final sender = map['sender'];
          final preview =
              map['contentPreview'] ?? map['message'] ?? map['text'] ?? '';
          return <String, dynamic>{
            ...map,
            'message': preview,
            'fullBody': map['content'] ?? preview,
            'author': sender is Map
                ? sender['displayName'] ?? sender['name']
                : null,
            'date': map['sentDateTime'] ?? map['date'] ?? map['sendTime'],
          };
        })
        .toList(growable: false);
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

  Future<String?> _fetchToken({
    required String schoolUrl,
    required String sessionId,
    required List<String> cookies,
  }) async {
    final raw = await _getText(
      uri: Uri.parse('https://$schoolUrl/WebUntis/api/token/new'),
      sessionId: sessionId,
      cookies: cookies,
    );
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    if (!trimmed.startsWith('{')) {
      return trimmed.replaceAll('"', '').trim();
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded.trim();
      }
      if (decoded is Map) {
        for (final key in const [
          'token',
          'jwt',
          'jwt_token',
          'accessToken',
        ]) {
          final value = decoded[key]?.toString().trim();
          if (value != null && value.isNotEmpty) return value;
        }
      }
    } catch (_) {}
    return null;
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
    var sawAuthenticationFailure = false;
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
        if (failure.kind == WebUntisFailureKind.authentication ||
            failure.kind == WebUntisFailureKind.permission) {
          sawAuthenticationFailure = true;
        }
      } catch (_) {}
    }
    if (sawAuthenticationFailure) {
      throw const WebUntisFailure(
        WebUntisFailureKind.authentication,
        'WebUntis session expired.',
      );
    }
    return const [];
  }

  Future<dynamic> _getJson({
    required Uri uri,
    required String sessionId,
    required List<String> cookies,
    Map<String, String> extraHeaders = const {},
  }) async {
    var sawAuthenticationFailure = false;
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
        if (failure.kind == WebUntisFailureKind.authentication ||
            failure.kind == WebUntisFailureKind.permission) {
          sawAuthenticationFailure = true;
        }
      } catch (_) {}
    }
    if (sawAuthenticationFailure) {
      throw const WebUntisFailure(
        WebUntisFailureKind.authentication,
        'WebUntis session expired.',
      );
    }
    return null;
  }

  Future<String?> _getText({
    required Uri uri,
    required String sessionId,
    required List<String> cookies,
  }) async {
    var sawAuthenticationFailure = false;
    for (final cookie in cookies) {
      try {
        return await _client.getText(
          uri: uri,
          headers: {
            'Cookie': 'JSESSIONID=$sessionId; schoolname=$cookie',
            'Accept': 'application/json',
          },
        );
      } on WebUntisFailure catch (failure) {
        if (failure.kind == WebUntisFailureKind.authentication ||
            failure.kind == WebUntisFailureKind.permission) {
          sawAuthenticationFailure = true;
        }
      } catch (_) {}
    }
    if (sawAuthenticationFailure) {
      throw const WebUntisFailure(
        WebUntisFailureKind.authentication,
        'WebUntis session expired.',
      );
    }
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

  static Map<String, dynamic> _stringKeyedMap(Map raw) => raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
}
