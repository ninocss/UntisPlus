import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class WebUntisMessageFailure implements Exception {
  const WebUntisMessageFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class WebUntisMessageRecipient {
  const WebUntisMessageRecipient({
    required this.id,
    required this.type,
    required this.name,
    this.role,
  });

  final int id;
  final String type;
  final String name;
  final String? role;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'name': name,
    if (role != null) 'role': role,
  };

  factory WebUntisMessageRecipient.fromJson(Map<String, dynamic> json) =>
      WebUntisMessageRecipient(
        id: (json['id'] as num?)?.toInt() ?? 0,
        type: json['type']?.toString() ?? 'TEACHER',
        name: json['name']?.toString() ?? '',
        role: json['role']?.toString(),
      );
}

class WebUntisOutgoingAttachment {
  const WebUntisOutgoingAttachment({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}

class WebUntisMessagePermissions {
  const WebUntisMessagePermissions({
    this.recipientOptions = const ['TEACHER'],
    this.maxFileSize = 7000000,
    this.maxFileCount = 5,
  });

  final List<String> recipientOptions;
  final int maxFileSize;
  final int maxFileCount;
}

class WebUntisComposeData {
  const WebUntisComposeData({
    required this.recipients,
    required this.permissions,
  });

  final List<WebUntisMessageRecipient> recipients;
  final WebUntisMessagePermissions permissions;
}

class _MessageWriteContext {
  const _MessageWriteContext({
    required this.cookie,
    required this.token,
    required this.schoolYearId,
    required this.tenantId,
  });

  final String cookie;
  final String token;
  final int? schoolYearId;
  final String? tenantId;

  Map<String, String> get headers => {
    'Cookie': cookie,
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
    if (tenantId != null && tenantId!.isNotEmpty) 'Tenant-Id': tenantId!,
    if (schoolYearId != null)
      'X-Webuntis-Api-School-Year-Id': '$schoolYearId',
  };
}

/// Minimal MessageCenter 2021 client.
///
/// Reads use the same JWT endpoint as the inbox. Writes mirror the WebUntis
/// web client: multipart/form-data with a JSON `request` part, first against
/// v2 and then v1 for older installations.
class WebUntisMessageService {
  WebUntisMessageService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  List<String> _schoolCookies(String schoolName) {
    final values = <String>[];
    if (schoolName.isNotEmpty) {
      try {
        values.add('_${base64Encode(utf8.encode(schoolName))}');
      } catch (_) {}
      values.add(schoolName);
    }
    return values.toSet().toList(growable: false);
  }

  String _cookie(String sessionId, String schoolCookie) =>
      'JSESSIONID=$sessionId; schoolname=$schoolCookie';

  Future<_MessageWriteContext> _writeContext({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
  }) async {
    if (schoolUrl.isEmpty || schoolName.isEmpty || sessionId.isEmpty) {
      throw const WebUntisMessageFailure('Not signed in.', statusCode: 401);
    }

    String? token;
    String? selectedCookie;
    for (final schoolCookie in _schoolCookies(schoolName)) {
      final cookie = _cookie(sessionId, schoolCookie);
      try {
        final response = await _client
            .get(
              Uri.parse('https://$schoolUrl/WebUntis/api/token/new'),
              headers: {'Cookie': cookie, 'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) continue;
        final raw = response.body.trim();
        if (raw.isEmpty || raw.startsWith('<')) continue;
        token = _tokenFromResponse(raw);
        if (token != null && token.isNotEmpty) {
          selectedCookie = cookie;
          break;
        }
      } catch (_) {}
    }

    if (token == null || selectedCookie == null) {
      throw const WebUntisMessageFailure(
        'WebUntis session expired.',
        statusCode: 401,
      );
    }

    final schoolYearId = await _schoolYearId(
      schoolUrl: schoolUrl,
      schoolName: schoolName,
      cookie: selectedCookie,
    );

    return _MessageWriteContext(
      cookie: selectedCookie,
      token: token,
      schoolYearId: schoolYearId,
      tenantId: _tenantId(token),
    );
  }

  String? _tokenFromResponse(String raw) {
    if (!raw.startsWith('{')) {
      return raw.replaceAll('"', '').trim();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is String) return decoded.trim();
      if (decoded is Map) {
        for (final key in const [
          'accessToken',
          'token',
          'access_token',
          'jwt',
          'jwt_token',
        ]) {
          final value = decoded[key]?.toString().trim();
          if (value != null && value.isNotEmpty) return value;
        }
      }
    } catch (_) {}
    return null;
  }

  String? _tenantId(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      var payloadPart = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payloadPart.length % 4 != 0) {
        payloadPart += '=';
      }
      final payload = utf8.decode(base64Decode(payloadPart));
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final value = decoded['tenant_id'] ?? decoded['tenantId'];
      final tenant = value?.toString().trim();
      return tenant == null || tenant.isEmpty ? null : tenant;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _schoolYearId({
    required String schoolUrl,
    required String schoolName,
    required String cookie,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(
              'https://$schoolUrl/WebUntis/jsonrpc.do'
              '?school=${Uri.encodeQueryComponent(schoolName)}',
            ),
            headers: {
              'Cookie': cookie,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'id': 'message-school-year',
              'method': 'getCurrentSchoolyear',
              'params': {},
              'jsonrpc': '2.0',
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['result'] is Map) {
        return (decoded['result']['id'] as num?)?.toInt();
      }
    } catch (_) {}
    return null;
  }

  Future<WebUntisComposeData> loadComposeData({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
  }) async {
    final context = await _writeContext(
      schoolUrl: schoolUrl,
      schoolName: schoolName,
      sessionId: sessionId,
    );
    final results = await Future.wait<dynamic>([
      _fetchPermissions(schoolUrl, context),
      _fetchRecipients(schoolUrl, context),
    ]);
    return WebUntisComposeData(
      permissions: results[0] as WebUntisMessagePermissions,
      recipients: results[1] as List<WebUntisMessageRecipient>,
    );
  }

  Future<WebUntisMessagePermissions> _fetchPermissions(
    String schoolUrl,
    _MessageWriteContext context,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              'https://$schoolUrl/WebUntis/api/rest/view/v1/messages/permissions',
            ),
            headers: context.headers,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw WebUntisMessageFailure(
          'WebUntis session expired.',
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode != 200 || response.body.trim().startsWith('<')) {
        return const WebUntisMessagePermissions();
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return const WebUntisMessagePermissions();
      final options = (decoded['recipientOptions'] as List? ?? const [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      return WebUntisMessagePermissions(
        recipientOptions: options.isEmpty ? const ['TEACHER'] : options,
        maxFileSize:
            (decoded['maxFileSize'] as num?)?.toInt() ?? 7000000,
        maxFileCount:
            (decoded['maxFileCount'] as num?)?.toInt() ?? 5,
      );
    } on WebUntisMessageFailure {
      rethrow;
    } catch (_) {
      return const WebUntisMessagePermissions();
    }
  }

  Future<List<WebUntisMessageRecipient>> _fetchRecipients(
    String schoolUrl,
    _MessageWriteContext context,
  ) async {
    final paths = const [
      '/WebUntis/api/rest/view/v1/messages/recipients/static/persons',
    ];
    for (final path in paths) {
      try {
        final response = await _client
            .get(
              Uri.parse('https://$schoolUrl$path'),
              headers: context.headers,
            )
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw WebUntisMessageFailure(
            'WebUntis session expired.',
            statusCode: response.statusCode,
          );
        }
        if (response.statusCode != 200 || response.body.trim().startsWith('<')) {
          continue;
        }
        final decoded = jsonDecode(response.body);
        final groups = decoded is List
            ? decoded
            : decoded is Map && decoded['data'] is List
            ? decoded['data'] as List
            : const <dynamic>[];
        final recipients = <WebUntisMessageRecipient>[];
        final seen = <String>{};
        for (final rawGroup in groups) {
          if (rawGroup is! Map) continue;
          final type = (rawGroup['type'] ?? 'TEACHER')
              .toString()
              .toUpperCase();
          final people = rawGroup['persons'];
          if (people is! List) continue;
          for (final rawPerson in people) {
            if (rawPerson is! Map) continue;
            final id = (rawPerson['userId'] as num?)?.toInt() ??
                (rawPerson['id'] as num?)?.toInt();
            final name = (rawPerson['displayName'] ?? rawPerson['name'] ?? '')
                .toString()
                .trim();
            if (id == null || id <= 0 || name.isEmpty) continue;
            final key = '$type:$id';
            if (!seen.add(key)) continue;
            final tags = (rawPerson['tags'] as List? ?? const [])
                .map((tag) => tag.toString().trim())
                .where((tag) => tag.isNotEmpty)
                .join(', ');
            recipients.add(
              WebUntisMessageRecipient(
                id: id,
                type: type,
                name: name,
                role: tags.isEmpty ? null : tags,
              ),
            );
          }
        }
        recipients.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return recipients;
      } on WebUntisMessageFailure {
        rethrow;
      } catch (_) {}
    }
    return const [];
  }

  Future<void> sendMessage({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
    required String subject,
    required String content,
    required List<WebUntisMessageRecipient> recipients,
    List<WebUntisOutgoingAttachment> attachments = const [],
  }) async {
    final cleanSubject = subject.trim();
    final cleanContent = content.trim();
    if (recipients.isEmpty || cleanSubject.isEmpty || cleanContent.isEmpty) {
      throw const WebUntisMessageFailure('Message is incomplete.');
    }

    final context = await _writeContext(
      schoolUrl: schoolUrl,
      schoolName: schoolName,
      sessionId: sessionId,
    );
    final permissions = await _fetchPermissions(schoolUrl, context);
    if (attachments.length > permissions.maxFileCount) {
      throw WebUntisMessageFailure(
        'Too many attachments (max. ${permissions.maxFileCount}).',
      );
    }
    for (final attachment in attachments) {
      if (attachment.bytes.length > permissions.maxFileSize) {
        throw WebUntisMessageFailure(
          '${attachment.name} exceeds the attachment size limit.',
        );
      }
    }

    final option = permissions.recipientOptions.contains('TEACHER')
        ? 'TEACHER'
        : permissions.recipientOptions.firstOrNull ?? 'TEACHER';
    final meta = <String, dynamic>{
      'subject': cleanSubject,
      'content': cleanContent,
      'recipientOption': option,
      'recipientPersons': recipients.map((recipient) => {'id': recipient.id}).toList(),
      'recipientGroups': const <dynamic>[],
    };

    final paths = const [
      '/WebUntis/api/rest/view/v2/messages',
      '/WebUntis/api/rest/view/v1/messages',
    ];
    http.Response? lastResponse;
    for (final path in paths) {
      final response = await _multipartPost(
        Uri.parse('https://$schoolUrl$path'),
        headers: context.headers,
        requestJson: jsonEncode(meta),
        attachments: attachments,
      );
      lastResponse = response;
      if (response.statusCode == 404 || response.statusCode == 500) continue;
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw WebUntisMessageFailure(
          'WebUntis session expired.',
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw WebUntisMessageFailure(
        _serverMessage(response.body) ??
            'WebUntis rejected the message (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    throw WebUntisMessageFailure(
      _serverMessage(lastResponse?.body ?? '') ??
          'This WebUntis installation does not expose message sending.',
      statusCode: lastResponse?.statusCode,
    );
  }

  Future<http.Response> _multipartPost(
    Uri uri, {
    required Map<String, String> headers,
    required String requestJson,
    required List<WebUntisOutgoingAttachment> attachments,
  }) async {
    final boundary =
        '----UntisPlus${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';
    final builder = BytesBuilder(copy: false);

    void text(String value) => builder.add(utf8.encode(value));
    text('--$boundary\r\n');
    text('Content-Disposition: form-data; name="request"\r\n');
    text('Content-Type: application/json; charset=utf-8\r\n\r\n');
    text(requestJson);
    text('\r\n');

    for (final attachment in attachments) {
      final safeName = attachment.name
          .replaceAll('\\', '_')
          .replaceAll('"', '_')
          .replaceAll('\r', '_')
          .replaceAll('\n', '_');
      text('--$boundary\r\n');
      text(
        'Content-Disposition: form-data; name="attachments"; '
        'filename="$safeName"\r\n',
      );
      text('Content-Type: application/octet-stream\r\n\r\n');
      builder.add(attachment.bytes);
      text('\r\n');
    }
    text('--$boundary--\r\n');

    final request = http.Request('POST', uri)
      ..headers.addAll(headers)
      ..headers['Content-Type'] = 'multipart/form-data; boundary=$boundary'
      ..bodyBytes = builder.takeBytes();
    final streamed = await _client.send(request).timeout(
      const Duration(seconds: 30),
    );
    return http.Response.fromStream(streamed);
  }

  String? _serverMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final message = decoded['errorMessage']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
      final validation = decoded['validationErrors'];
      if (validation is List) {
        final text = validation
            .whereType<Map>()
            .map((item) => item['errorMessage']?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .join(' ');
        if (text.isNotEmpty) return text;
      }
    } catch (_) {}
    return null;
  }

  void close() => _client.close();
}
