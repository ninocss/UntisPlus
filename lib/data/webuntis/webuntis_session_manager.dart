import 'dart:async';

import 'package:otp_auth/otp_auth.dart';

import '../../core/sync_state.dart';
import '../security/credential_vault.dart';
import 'webuntis_client.dart';

class WebUntisAccountLogin {
  const WebUntisAccountLogin({
    required this.accountId,
    required this.username,
    required this.schoolUrl,
    required this.schoolName,
    this.personId = 0,
    this.personType = 5,
  });

  final String accountId;
  final String username;
  final String schoolUrl;
  final String schoolName;
  final int personId;
  final int personType;
}

class WebUntisSession {
  const WebUntisSession({
    required this.sessionId,
    required this.personId,
    required this.personType,
  });

  final String sessionId;
  final int personId;
  final int personType;
}

/// Owns authentication and guarantees at most one renewal request per account.
///
/// Callers may retry an authenticated operation exactly once through
/// [runAuthenticated]. Concurrent callers share the same renewal future.
class WebUntisSessionManager {
  WebUntisSessionManager({
    required WebUntisClient client,
    Future<AccountCredentials> Function(String accountId)? readCredentials,
    Future<void> Function(String accountId, AccountCredentials credentials)?
    writeCredentials,
  }) : _client = client,
       _readCredentials =
           readCredentials ?? CredentialVault.instance.readAccount,
       _writeCredentials =
           writeCredentials ??
           ((accountId, credentials) => CredentialVault.instance.writeAccount(
             accountId: accountId,
             credentials: credentials,
           ));

  final WebUntisClient _client;
  final Future<AccountCredentials> Function(String accountId) _readCredentials;
  final Future<void> Function(String accountId, AccountCredentials credentials)
  _writeCredentials;
  final Map<String, Future<WebUntisSession>> _renewals = {};
  final Map<String, WebUntisSession> _latestSessions = {};

  Future<T> runAuthenticated<T>({
    required WebUntisAccountLogin account,
    required String currentSessionId,
    required Future<T> Function(WebUntisRequestContext context) request,
  }) async {
    final current = _latestSessions[account.accountId]?.sessionId;
    final initialContext = _context(
      account,
      current != null && current.isNotEmpty ? current : currentSessionId,
    );
    try {
      return await request(initialContext);
    } on WebUntisFailure catch (failure) {
      if (failure.kind != WebUntisFailureKind.authentication) rethrow;
    }

    final renewed = await renewSession(account);
    return request(_context(account, renewed.sessionId));
  }

  Future<WebUntisSession> renewSession(WebUntisAccountLogin account) {
    final active = _renewals[account.accountId];
    if (active != null) return active;
    final renewal = _authenticateStored(account);
    _renewals[account.accountId] = renewal;
    return renewal.whenComplete(() => _renewals.remove(account.accountId));
  }

  Future<WebUntisSession> _authenticateStored(
    WebUntisAccountLogin account,
  ) async {
    final credentials = await _readCredentials(account.accountId);
    if (account.username.isEmpty || credentials.password.isEmpty) {
      throw const WebUntisFailure(
        WebUntisFailureKind.authentication,
        'No stored credentials are available for this account.',
      );
    }

    final session = credentials.credentialMode == 'loginKey'
        ? await _authenticateWithLoginKey(account, credentials.password)
        : await _authenticateWithPassword(account, credentials.password);
    await _writeCredentials(
      account.accountId,
      AccountCredentials(
        password: credentials.password,
        credentialMode: credentials.credentialMode,
        sessionId: session.sessionId,
      ),
    );
    _latestSessions[account.accountId] = session;
    return session;
  }

  Future<WebUntisSession> _authenticateWithPassword(
    WebUntisAccountLogin account,
    String password,
  ) async {
    final response = await _client.rpc(
      context: _context(account, ''),
      method: 'authenticate',
      requestId: 'renew_${account.accountId}',
      params: {
        'user': account.username,
        'password': password,
        'client': 'UntisPlus',
      },
    );
    final result = response['result'];
    final sessionId = result is Map
        ? result['sessionId']?.toString() ?? ''
        : '';
    if (sessionId.isEmpty) {
      throw const WebUntisFailure(
        WebUntisFailureKind.authentication,
        'WebUntis did not create a new session.',
      );
    }
    return WebUntisSession(
      sessionId: sessionId,
      personId: _asInt(result['personId'], fallback: account.personId),
      personType: _asInt(result['personType'], fallback: account.personType),
    );
  }

  Future<WebUntisSession> _authenticateWithLoginKey(
    WebUntisAccountLogin account,
    String loginKey,
  ) async {
    final secret = _normalizeSecret(loginKey);
    if (secret.isEmpty) {
      throw const WebUntisFailure(
        WebUntisFailureKind.authentication,
        'The stored WebUntis login key is empty.',
      );
    }
    final exchange = await _client.rpcExchange(
      context: _context(account, ''),
      method: 'getUserData2017',
      internal: true,
      requestId: 'renew_${account.accountId}',
      params: [
        {
          'auth': {
            'clientTime': DateTime.now().millisecondsSinceEpoch,
            'user': account.username,
            'otp': TOTP(
              secret: secret,
              digits: 6,
              algorithm: OTPAlgorithm.sha1,
              period: 30,
            ).now(),
          },
        },
      ],
    );
    final cookie = exchange.headers['set-cookie'] ?? '';
    final sessionId =
        RegExp(r'JSESSIONID=([^;]+)').firstMatch(cookie)?.group(1) ?? '';
    if (sessionId.isEmpty) {
      throw const WebUntisFailure(
        WebUntisFailureKind.authentication,
        'WebUntis did not return a session cookie.',
      );
    }
    return WebUntisSession(
      sessionId: sessionId,
      personId: account.personId,
      personType: account.personType,
    );
  }

  WebUntisRequestContext _context(
    WebUntisAccountLogin account,
    String sessionId,
  ) => WebUntisRequestContext(
    schoolUrl: account.schoolUrl,
    schoolName: account.schoolName,
    sessionId: sessionId,
  );

  static int _asInt(dynamic value, {required int fallback}) =>
      int.tryParse(value?.toString() ?? '') ?? fallback;

  static String _normalizeSecret(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('otpauth://')) {
      return OTPUri.extractSecret(
        trimmed,
      ).trim().replaceAll(' ', '').toUpperCase();
    }
    if (trimmed.startsWith('untis://')) {
      final uri = Uri.tryParse(trimmed);
      final extracted =
          uri?.queryParameters['key'] ?? uri?.queryParameters['secret'] ?? '';
      if (extracted.isNotEmpty) {
        return extracted.trim().replaceAll(' ', '').toUpperCase();
      }
    }
    return trimmed.replaceAll(' ', '').toUpperCase();
  }
}
