import '../../../core/sync_state.dart';
import '../../../data/webuntis/webuntis_auth.dart';
import '../../../data/webuntis/webuntis_client.dart';

enum WebUntisLoginStatus {
  success,
  failed,
  requiresTwoFactor,
  invalidOneTimeCode,
}

class WebUntisLoginResult {
  const WebUntisLoginResult._({
    required this.status,
    this.sessionId = '',
    this.personId = 0,
    this.personType = 5,
  });

  const WebUntisLoginResult.success({
    required String sessionId,
    int personId = 0,
    int personType = 5,
  }) : this._(
         status: WebUntisLoginStatus.success,
         sessionId: sessionId,
         personId: personId,
         personType: personType,
       );

  const WebUntisLoginResult.failed()
    : this._(status: WebUntisLoginStatus.failed);

  const WebUntisLoginResult.requiresTwoFactor()
    : this._(status: WebUntisLoginStatus.requiresTwoFactor);

  const WebUntisLoginResult.invalidOneTimeCode()
    : this._(status: WebUntisLoginStatus.invalidOneTimeCode);

  final WebUntisLoginStatus status;
  final String sessionId;
  final int personId;
  final int personType;

  bool get isSuccess => status == WebUntisLoginStatus.success;
}

/// Owns the two supported interactive WebUntis login protocols.
///
/// UI callers only receive a normalized result. JSON-RPC request shapes,
/// session-cookie parsing and app-config parsing stay inside the data layer.
class WebUntisLoginRepository {
  WebUntisLoginRepository({WebUntisClient? client})
    : _client =
          client ??
          WebUntisClient(timeout: const Duration(seconds: 8), maxRetries: 0);

  final WebUntisClient _client;

  Future<WebUntisLoginResult> authenticate({
    required String schoolUrl,
    required String schoolName,
    required String username,
    required String credential,
    String clientName = 'UntisPlus',
    String requestId = 'auth',
    String? oneTimeCode,
    bool useLoginKey = false,
  }) async {
    final context = WebUntisRequestContext(
      schoolUrl: schoolUrl.trim(),
      schoolName: schoolName.trim(),
    );
    return useLoginKey
        ? _authenticateWithLoginKey(
            context: context,
            username: username,
            loginKey: credential,
            requestId: requestId,
          )
        : _authenticateWithPassword(
            context: context,
            username: username,
            password: credential,
            clientName: clientName,
            requestId: requestId,
            oneTimeCode: oneTimeCode,
          );
  }

  Future<WebUntisLoginResult> _authenticateWithPassword({
    required WebUntisRequestContext context,
    required String username,
    required String password,
    required String clientName,
    required String requestId,
    String? oneTimeCode,
  }) async {
    final normalizedCode = oneTimeCode?.trim() ?? '';
    try {
      final response = await _client.rpc(
        context: context,
        method: 'authenticate',
        requestId: requestId,
        params: <String, dynamic>{
          'user': username,
          'password': password,
          'client': clientName,
          if (normalizedCode.isNotEmpty) 'otp': normalizedCode,
        },
      );
      final result = response['result'];
      if (result is! Map) return const WebUntisLoginResult.failed();

      final sessionId = result['sessionId']?.toString() ?? '';
      if (sessionId.isEmpty) return const WebUntisLoginResult.failed();

      final directPersonId = _asInt(result['personId']);
      final classId = _asInt(result['klasseId']);
      final fallbackId = directPersonId != 0 ? directPersonId : classId;
      final fallbackType = directPersonId != 0
          ? _asInt(result['personType'], fallback: 5)
          : classId != 0
          ? 1
          : 5;
      final element = _resolveTimetableElement(
        result,
        fallbackId,
        fallbackType,
      );
      return WebUntisLoginResult.success(
        sessionId: sessionId,
        personId: element.$1,
        personType: element.$2,
      );
    } on WebUntisFailure catch (failure) {
      if (failure.kind != WebUntisFailureKind.authentication &&
          failure.rpcCode == null) {
        rethrow;
      }
      final error = failure.message.toLowerCase();
      if (normalizedCode.isEmpty && _mentionsOneTimeCode(error)) {
        return const WebUntisLoginResult.requiresTwoFactor();
      }
      if (normalizedCode.isNotEmpty || _mentionsInvalidOneTimeCode(error)) {
        return const WebUntisLoginResult.invalidOneTimeCode();
      }
      return const WebUntisLoginResult.failed();
    }
  }

  Future<WebUntisLoginResult> _authenticateWithLoginKey({
    required WebUntisRequestContext context,
    required String username,
    required String loginKey,
    required String requestId,
  }) async {
    try {
      final exchange = await _client.rpcExchange(
        context: context,
        method: 'getUserData2017',
        internal: true,
        requestId: requestId,
        params: <Object?>[
          <String, Object?>{
            'auth': <String, Object?>{
              'clientTime': DateTime.now().millisecondsSinceEpoch,
              'user': username,
              'otp': generateWebUntisOtp(loginKey),
            },
          },
        ],
      );
      final sessionId = webUntisSessionIdFromCookie(
        exchange.headers['set-cookie'],
      );
      if (sessionId.isEmpty) return const WebUntisLoginResult.failed();

      final identity = await _loadLoginKeyIdentity(
        context: context,
        sessionId: sessionId,
      );
      return WebUntisLoginResult.success(
        sessionId: sessionId,
        personId: identity.$1,
        personType: identity.$2,
      );
    } on ArgumentError {
      return const WebUntisLoginResult.invalidOneTimeCode();
    } on WebUntisFailure catch (failure) {
      final error = failure.message.toLowerCase();
      if (failure.kind == WebUntisFailureKind.authentication ||
          error.contains('otp') ||
          error.contains('secret') ||
          error.contains('login')) {
        return const WebUntisLoginResult.invalidOneTimeCode();
      }
      rethrow;
    }
  }

  Future<(int, int)> _loadLoginKeyIdentity({
    required WebUntisRequestContext context,
    required String sessionId,
  }) async {
    try {
      final response = await _client.getJson(
        uri: Uri.parse('https://${context.schoolUrl}/WebUntis/api/app/config'),
        headers: <String, String>{
          'Cookie': 'JSESSIONID=$sessionId; schoolname=${context.schoolName}',
        },
      );
      final data = response is Map ? response['data'] : null;
      final loginConfig = data is Map ? data['loginServiceConfig'] : null;
      final user = loginConfig is Map ? loginConfig['user'] : null;
      if (user is! Map) return (0, 5);

      final personId = _asInt(user['personId']);
      final persons = user['persons'];
      if (persons is! List) return (personId, 5);
      final matchingPerson = persons.whereType<Map>().cast<Map>().firstWhere(
        (person) => _asInt(person['id']) == personId,
        orElse: () => const <Object?, Object?>{},
      );
      return _resolveTimetableElement(
        user,
        personId,
        _asInt(matchingPerson['type'], fallback: 5),
      );
    } on WebUntisFailure {
      // A valid session is still useful when older installations do not
      // expose the optional app-config endpoint.
      return (0, 5);
    }
  }

  static bool _mentionsOneTimeCode(String message) =>
      message.contains('2fa') ||
      message.contains('two factor') ||
      message.contains('mfa') ||
      message.contains('otp') ||
      message.contains('one-time') ||
      message.contains('verification code') ||
      message.contains('authenticator');

  static bool _mentionsInvalidOneTimeCode(String message) =>
      message.contains('invalid otp') ||
      message.contains('invalid verification') ||
      message.contains('wrong otp') ||
      message.contains('otp invalid');

  static int _asInt(Object? value, {int fallback = 0}) =>
      int.tryParse(value?.toString() ?? '') ?? fallback;

  /// Guardians have no timetable element of their own. Use their first linked
  /// student when WebUntis supplies the linked people in the login response.
  static (int, int) _resolveTimetableElement(
    Map result,
    int personId,
    int personType,
  ) {
    final linked = <Map>[];
    for (final key in ['people', 'persons']) {
      final value = result[key];
      if (value is List) linked.addAll(value.whereType<Map>());
    }
    for (final person in linked) {
      if (_asInt(person['id']) == personId) {
        personType = _asInt(person['type'], fallback: personType);
        break;
      }
    }
    if (personType == 3) {
      for (final person in linked) {
        final studentId = _asInt(person['id']);
        if (_asInt(person['type']) == 5 && studentId > 0) {
          return (studentId, 5);
        }
      }
    }
    return (personId, personType);
  }

  void close() => _client.close();
}
