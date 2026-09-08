import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/sync_state.dart';

class WebUntisRequestContext {
  const WebUntisRequestContext({
    required this.schoolUrl,
    required this.schoolName,
    this.sessionId = '',
  });

  final String schoolUrl;
  final String schoolName;
  final String sessionId;
}

/// Shared transport boundary for JSON-RPC and REST WebUntis APIs.
class WebUntisClient {
  WebUntisClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.maxRetries = 1,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;
  final int maxRetries;
  final Map<String, Future<dynamic>> _inFlight = {};

  Future<Map<String, dynamic>> rpc({
    required WebUntisRequestContext context,
    required String method,
    required Object params,
    String requestId = 'untisplus',
    bool internal = false,
  }) {
    final uri = Uri.parse(
      'https://${context.schoolUrl}/WebUntis/'
      '${internal ? 'jsonrpc_intern.do' : 'jsonrpc.do'}'
      '?school=${Uri.encodeQueryComponent(context.schoolName)}',
    );
    final body = jsonEncode({
      'id': requestId,
      'method': method,
      'params': params,
      'jsonrpc': '2.0',
    });
    final dedupeKey = 'POST|$uri|$body|${context.sessionId}';
    return _dedupe<Map<String, dynamic>>(dedupeKey, () async {
      final response = await _send(
        () => _client.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (context.sessionId.isNotEmpty)
              'Cookie':
                  'JSESSIONID=${context.sessionId}; schoolname=${context.schoolName}',
          },
          body: body,
        ),
      );
      final decoded = _decode(response);
      if (decoded['error'] != null) {
        final error = decoded['error'];
        final message = error is Map
            ? (error['message'] ?? error['data'] ?? error).toString()
            : error.toString();
        final normalized = message.toLowerCase();
        throw WebUntisFailure(
          normalized.contains('method') || normalized.contains('not found')
              ? WebUntisFailureKind.unsupported
              : normalized.contains('permission') ||
                    normalized.contains('right')
              ? WebUntisFailureKind.permission
              : normalized.contains('session') || normalized.contains('auth')
              ? WebUntisFailureKind.authentication
              : WebUntisFailureKind.server,
          message,
          statusCode: response.statusCode,
        );
      }
      return decoded;
    });
  }

  Future<dynamic> getJson({
    required Uri uri,
    Map<String, String> headers = const {},
  }) {
    final dedupeKey = 'GET|$uri|${jsonEncode(headers)}';
    return _dedupe<dynamic>(dedupeKey, () async {
      final response = await _send(() => _client.get(uri, headers: headers));
      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw const WebUntisFailure(
          WebUntisFailureKind.invalidData,
          'WebUntis returned invalid JSON.',
        );
      }
    });
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await request().timeout(timeout);
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw WebUntisFailure(
            response.statusCode == 401
                ? WebUntisFailureKind.authentication
                : WebUntisFailureKind.permission,
            'WebUntis rejected the request.',
            statusCode: response.statusCode,
          );
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          if (response.statusCode >= 500 && attempt < maxRetries) {
            await _backoff(attempt);
            continue;
          }
          throw WebUntisFailure(
            WebUntisFailureKind.server,
            'WebUntis returned HTTP ${response.statusCode}.',
            statusCode: response.statusCode,
          );
        }
        return response;
      } on TimeoutException {
        if (attempt < maxRetries) {
          await _backoff(attempt);
          continue;
        }
        throw const WebUntisFailure(
          WebUntisFailureKind.timeout,
          'The WebUntis request timed out.',
        );
      } on http.ClientException {
        if (attempt < maxRetries) {
          await _backoff(attempt);
          continue;
        }
        throw const WebUntisFailure(
          WebUntisFailureKind.offline,
          'No network connection is available.',
        );
      }
    }
    throw const WebUntisFailure(
      WebUntisFailureKind.unknown,
      'The WebUntis request failed.',
    );
  }

  Future<void> _backoff(int attempt) => Future<void>.delayed(
    Duration(milliseconds: 250 * (1 << attempt.clamp(0, 3))),
  );

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Converted into the typed failure below.
    }
    throw const WebUntisFailure(
      WebUntisFailureKind.invalidData,
      'WebUntis returned an unexpected response.',
    );
  }

  Future<T> _dedupe<T>(String key, Future<T> Function() request) {
    final current = _inFlight[key];
    if (current != null) return current as Future<T>;
    final future = request();
    _inFlight[key] = future;
    return future.whenComplete(() => _inFlight.remove(key));
  }

  void close() => _client.close();
}
