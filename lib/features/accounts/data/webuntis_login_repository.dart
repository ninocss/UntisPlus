import '../../../core/sync_state.dart';
import '../../../data/webuntis/untis_endpoint.dart';
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
    this.linkedPeople = const [],
  });

  const WebUntisLoginResult.success({
    required String sessionId,
    int personId = 0,
    int personType = 5,
    List<Map<String, dynamic>> linkedPeople = const [],
  }) : this._(
         status: WebUntisLoginStatus.success,
         sessionId: sessionId,
         personId: personId,
         personType: personType,
         linkedPeople: linkedPeople,
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

  /// Every person element the server linked to this login, combining the
  /// `people` and `persons` lists. Guardian accounts use it to find the first
  /// linked student, because the parent element itself has no timetable.
  final List<Map<String, dynamic>> linkedPeople;

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
      return WebUntisLoginResult.success(
        sessionId: sessionId,
        personId: directPersonId != 0 ? directPersonId : classId,
        personType: directPersonId != 0
            ? _asInt(result['personType'], fallback: 5)
            : classId != 0
            ? 1
            : 5,
        linkedPeople: _linkedPeopleOf(result),
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
        linkedPeople: identity.$3,
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

  Future<(int, int, List<Map<String, dynamic>>)> _loadLoginKeyIdentity({
    required WebUntisRequestContext context,
    required String sessionId,
  }) async {
    try {
      final response = await _client.getJson(
        uri: Uri.parse(
          '${untisBaseUrl(schoolUrl: context.schoolUrl)}/WebUntis/api/app/config',
        ),
        headers: <String, String>{
          'Cookie': 'JSESSIONID=$sessionId; schoolname=${context.schoolName}',
        },
      );
      final data = response is Map ? response['data'] : null;
      final loginConfig = data is Map ? data['loginServiceConfig'] : null;
      final user = loginConfig is Map ? loginConfig['user'] : null;
      if (user is! Map) return (0, 5, const <Map<String, dynamic>>[]);

      final personId = _asInt(user['personId']);
      final linked = _linkedPeopleOf(user);
      if (linked.isEmpty) return (personId, 5, const <Map<String, dynamic>>[]);
      final matchingPerson = linked.firstWhere(
        (person) => _asInt(person['id']) == personId,
        orElse: () => const <String, dynamic>{},
      );
      return (personId, _asInt(matchingPerson['type'], fallback: 5), linked);
    } on WebUntisFailure {
      // A valid session is still useful when older installations do not
      // expose the optional app-config endpoint.
      return (0, 5, const <Map<String, dynamic>>[]);
    }
  }

  /// Merges the `people` and `persons` lists a WebUntis login payload can use.
  /// Both keys describe the same relation, so either one is accepted and
  /// non-map entries are dropped rather than crashing the login.
  static List<Map<String, dynamic>> _linkedPeopleOf(Map<Object?, Object?> source) {
    final linked = <Map<String, dynamic>>[];
    for (final key in const ['people', 'persons']) {
      final raw = source[key];
      if (raw is! List) continue;
      for (final entry in raw) {
        if (entry is Map) linked.add(Map<String, dynamic>.from(entry));
      }
    }
    return linked;
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

  void close() => _client.close();
}
