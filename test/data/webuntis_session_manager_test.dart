import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untisplus/core/sync_state.dart';
import 'package:untisplus/data/security/credential_vault.dart';
import 'package:untisplus/data/webuntis/webuntis_client.dart';
import 'package:untisplus/data/webuntis/webuntis_session_manager.dart';

const _account = WebUntisAccountLogin(
  accountId: 'account-a',
  username: 'student',
  schoolUrl: 'example.webuntis.com',
  schoolName: 'Example School',
  personId: 42,
  personType: 5,
);

void main() {
  test(
    'concurrent authentication failures share one session renewal',
    () async {
      var authenticationCalls = 0;
      AccountCredentials? written;
      final client = WebUntisClient(
        client: MockClient((request) async {
          authenticationCalls++;
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          expect(payload['method'], 'authenticate');
          return http.Response(
            jsonEncode({
              'result': {'sessionId': 'fresh-session', 'personId': 42},
            }),
            200,
          );
        }),
        maxRetries: 0,
      );
      final manager = WebUntisSessionManager(
        client: client,
        readCredentials: (_) async => const AccountCredentials(
          password: 'secret',
          credentialMode: 'password',
          sessionId: 'expired-session',
        ),
        writeCredentials: (_, credentials) async => written = credentials,
      );
      var protectedCalls = 0;

      Future<String> protected(WebUntisRequestContext context) async {
        protectedCalls++;
        if (context.sessionId != 'fresh-session') {
          throw const WebUntisFailure(
            WebUntisFailureKind.authentication,
            'expired',
          );
        }
        return context.sessionId;
      }

      final results = await Future.wait([
        manager.runAuthenticated(
          account: _account,
          currentSessionId: 'expired-session',
          request: protected,
        ),
        manager.runAuthenticated(
          account: _account,
          currentSessionId: 'expired-session',
          request: protected,
        ),
      ]);

      expect(results, everyElement('fresh-session'));
      expect(authenticationCalls, 1);
      expect(protectedCalls, 4);
      expect(written?.sessionId, 'fresh-session');
    },
  );

  test('non-authentication failures never trigger login', () async {
    var authenticationCalls = 0;
    final client = WebUntisClient(
      client: MockClient((_) async {
        authenticationCalls++;
        return http.Response('{}', 200);
      }),
      maxRetries: 0,
    );
    final manager = WebUntisSessionManager(
      client: client,
      readCredentials: (_) async => const AccountCredentials(
        password: 'secret',
        credentialMode: 'password',
        sessionId: 'session',
      ),
      writeCredentials: (_, _) async {},
    );

    await expectLater(
      manager.runAuthenticated<void>(
        account: _account,
        currentSessionId: 'session',
        request: (_) async =>
            throw const WebUntisFailure(WebUntisFailureKind.offline, 'offline'),
      ),
      throwsA(
        isA<WebUntisFailure>().having(
          (failure) => failure.kind,
          'kind',
          WebUntisFailureKind.offline,
        ),
      ),
    );
    expect(authenticationCalls, 0);
  });

  test('an operation is retried only once after renewal', () async {
    var authenticationCalls = 0;
    var protectedCalls = 0;
    final client = WebUntisClient(
      client: MockClient((_) async {
        authenticationCalls++;
        return http.Response(
          jsonEncode({
            'result': {'sessionId': 'fresh-session'},
          }),
          200,
        );
      }),
      maxRetries: 0,
    );
    final manager = WebUntisSessionManager(
      client: client,
      readCredentials: (_) async => const AccountCredentials(
        password: 'secret',
        credentialMode: 'password',
        sessionId: 'expired-session',
      ),
      writeCredentials: (_, _) async {},
    );

    await expectLater(
      manager.runAuthenticated<void>(
        account: _account,
        currentSessionId: 'expired-session',
        request: (_) async {
          protectedCalls++;
          throw const WebUntisFailure(
            WebUntisFailureKind.authentication,
            'still rejected',
          );
        },
      ),
      throwsA(isA<WebUntisFailure>()),
    );
    expect(authenticationCalls, 1);
    expect(protectedCalls, 2);
  });

  test('login-key authentication reads the WebUntis session cookie', () async {
    final client = WebUntisClient(
      client: MockClient((request) async {
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['method'], 'getUserData2017');
        expect(request.url.path, endsWith('jsonrpc_intern.do'));
        return http.Response(
          jsonEncode({'result': const {}}),
          200,
          headers: {'set-cookie': 'JSESSIONID=login-key-session; Path=/'},
        );
      }),
      maxRetries: 0,
    );
    final manager = WebUntisSessionManager(
      client: client,
      readCredentials: (_) async => const AccountCredentials(
        password: 'JBSWY3DPEHPK3PXP',
        credentialMode: 'loginKey',
        sessionId: '',
      ),
      writeCredentials: (_, _) async {},
    );

    final session = await manager.renewSession(_account);

    expect(session.sessionId, 'login-key-session');
    expect(session.personId, _account.personId);
  });
}
