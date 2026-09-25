import 'dart:convert';

import '../../core/sync_state.dart';
import 'webuntis_client.dart';

class WebUntisMessageContext {
  const WebUntisMessageContext({
    required this.cookie,
    required this.token,
    this.tenantId,
    this.schoolYearId,
  });

  final String cookie;
  final String token;
  final String? tenantId;
  final int? schoolYearId;

  Map<String, String> get headers => {
    'Cookie': cookie,
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
    // ignore: use_null_aware_elements
    if (tenantId != null) 'Tenant-Id': tenantId!,
    if (schoolYearId != null) 'X-Webuntis-Api-School-Year-Id': '$schoolYearId',
  };
}

class WebUntisMessageContextResolver {
  WebUntisMessageContextResolver(this.client);

  final WebUntisClient client;

  static List<String> schoolCookies(String schoolName) => <String>{
    '_${base64Encode(utf8.encode(schoolName))}',
    schoolName,
  }.toList(growable: false);

  Future<WebUntisMessageContext> resolve({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
  }) async {
    if (schoolUrl.isEmpty || schoolName.isEmpty || sessionId.isEmpty) {
      throw const WebUntisFailure(
        WebUntisFailureKind.authentication,
        'WebUntis session is missing.',
        statusCode: 401,
      );
    }
    WebUntisFailure? lastFailure;
    for (final schoolCookie in schoolCookies(schoolName)) {
      final cookie = 'JSESSIONID=$sessionId; schoolname=$schoolCookie';
      try {
        final raw = await client.getText(
          uri: Uri.parse('https://$schoolUrl/WebUntis/api/token/new'),
          headers: {'Cookie': cookie, 'Accept': 'application/json'},
        );
        final token = _token(raw);
        if (token == null) continue;
        int? schoolYearId;
        try {
          final schoolYear = await client.rpc(
            context: WebUntisRequestContext(
              schoolUrl: schoolUrl,
              schoolName: schoolName,
              sessionId: sessionId,
              cookieSchoolName: schoolCookie,
            ),
            method: 'getCurrentSchoolyear',
            params: {},
            requestId: 'message-school-year',
          );
          schoolYearId = (schoolYear['result']?['id'] as num?)?.toInt();
        } catch (_) {
          // Older installations do not expose the school-year endpoint.
        }
        return WebUntisMessageContext(
          cookie: cookie,
          token: token,
          tenantId: _tenantId(token),
          schoolYearId: schoolYearId,
        );
      } on WebUntisFailure catch (failure) {
        lastFailure = failure;
      }
    }
    throw lastFailure ??
        const WebUntisFailure(
          WebUntisFailureKind.authentication,
          'WebUntis did not provide a message token.',
          statusCode: 401,
        );
  }

  static String? _token(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('<')) return null;
    if (!trimmed.startsWith('{')) {
      final value = trimmed.replaceAll('"', '').trim();
      return value.isEmpty ? null : value;
    }
    try {
      final decoded = jsonDecode(trimmed);
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

  static String? _tenantId(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      final value = decoded is Map
          ? (decoded['tenant_id'] ?? decoded['tenantId'])?.toString().trim()
          : null;
      return value == null || value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }
}
