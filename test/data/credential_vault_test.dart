import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/data/security/credential_vault.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('keeps credentials isolated by account id', () async {
    await CredentialVault.instance.writeAccount(
      accountId: 'account-a',
      credentials: const AccountCredentials(
        password: 'secret-a',
        credentialMode: 'password',
        sessionId: 'session-a',
      ),
    );
    await CredentialVault.instance.writeAccount(
      accountId: 'account-b',
      credentials: const AccountCredentials(
        password: 'secret-b',
        credentialMode: 'loginKey',
        sessionId: 'session-b',
      ),
    );

    await CredentialVault.instance.deleteAccount('account-a');

    expect(
      (await CredentialVault.instance.readAccount('account-a')).isEmpty,
      isTrue,
    );
    final remaining = await CredentialVault.instance.readAccount('account-b');
    expect(remaining.password, 'secret-b');
    expect(remaining.sessionId, 'session-b');
  });

  test('writeAndVerifyAccount stores, verifies and is idempotent', () async {
    const credentials = AccountCredentials(
      password: 'secret',
      credentialMode: 'loginKey',
      sessionId: 'session',
    );

    expect(
      await CredentialVault.instance.writeAndVerifyAccount(
        accountId: 'account-a',
        credentials: credentials,
      ),
      isTrue,
    );
    // A second call finds identical values and must still report success.
    expect(
      await CredentialVault.instance.writeAndVerifyAccount(
        accountId: 'account-a',
        credentials: credentials,
      ),
      isTrue,
    );
    final stored = await CredentialVault.instance.readAccount('account-a');
    expect(stored.password, 'secret');
    expect(stored.credentialMode, 'loginKey');
    expect(stored.sessionId, 'session');

    // Changed values are written, not skipped.
    expect(
      await CredentialVault.instance.writeAndVerifyAccount(
        accountId: 'account-a',
        credentials: const AccountCredentials(
          password: 'rotated',
          credentialMode: 'password',
          sessionId: 'session-2',
        ),
      ),
      isTrue,
    );
    expect(
      (await CredentialVault.instance.readAccount('account-a')).password,
      'rotated',
    );
  });

  test(
    'removes a legacy API key only after verified secure migration',
    () async {
      SharedPreferences.setMockInitialValues({'geminiApiKey': 'legacy-key'});
      final prefs = await SharedPreferences.getInstance();

      final values = await CredentialVault.instance.loadAndMigrateAiKeys(prefs);

      expect(values['gemini'], 'legacy-key');
      expect(
        await CredentialVault.instance.readAiApiKey('gemini'),
        'legacy-key',
      );
      expect(prefs.containsKey('geminiApiKey'), isFalse);
    },
  );
}
