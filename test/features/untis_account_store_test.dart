import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/data/security/credential_vault.dart';
import 'package:untisplus/features/accounts/data/untis_account_store.dart';
import 'package:untisplus/features/accounts/domain/untis_account.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'hydrates the active legacy account through the credential store',
    () async {
    final account = _account(id: 'legacy-account');
    SharedPreferences.setMockInitialValues({
      untisAccountsStorageKey: jsonEncode([
        {...account.toJson(), 'credentialMode': ''},
      ]),
        activeUntisAccountStorageKey: account.id,
        'password': 'legacy-password',
        'sessionId': 'legacy-session',
        'loginCredentialMode': 'loginKey',
      });
      final credentials = _FakeCredentialStore();
      final store = UntisAccountStore(
        preferences: await SharedPreferences.getInstance(),
        credentials: credentials,
      );

      final hydrated = await store.readHydratedAccounts();

      expect(hydrated.single.password, 'legacy-password');
      expect(hydrated.single.sessionId, 'legacy-session');
      expect(credentials.saved[account.id]?.credentialMode, 'loginKey');
    },
  );

  test('writes newest accounts first without leaking secrets', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = UntisAccountStore(
      preferences: preferences,
      credentials: _FakeCredentialStore(),
    );

    final ordered = await store.writeAccounts([
      _account(id: 'older', lastUsedAt: DateTime.utc(2026, 1, 1)),
      _account(id: 'newer', lastUsedAt: DateTime.utc(2026, 2, 1)),
    ]);
    final saved =
        jsonDecode(preferences.getString(untisAccountsStorageKey)!)
            as List<dynamic>;

    expect(ordered.map((account) => account.id), ['newer', 'older']);
    expect(saved.first['id'], 'newer');
    expect(saved.first, isNot(contains('password')));
    expect(saved.first, isNot(contains('sessionId')));
  });

  test(
    'copies legacy personal data into the stable account namespace',
    () async {
      SharedPreferences.setMockInitialValues({
        'customHomework': ['homework'],
        'subjectColors': '{"Math":123}',
      });
      final preferences = await SharedPreferences.getInstance();
      final store = UntisAccountStore(
        preferences: preferences,
        credentials: _FakeCredentialStore(),
      );

      await store.copyLegacyPersonalData('account-7');

      expect(preferences.getStringList('account.account-7.customHomework'), [
        'homework',
      ]);
      expect(
        preferences.getString('account.account-7.subjectColors'),
        '{"Math":123}',
      );
    },
  );
}

UntisAccount _account({required String id, DateTime? lastUsedAt}) =>
    UntisAccount(
      id: id,
      username: 'student',
      schoolUrl: 'school.example',
      schoolName: 'Example School',
      password: 'secret',
      credentialMode: 'password',
      sessionId: 'session',
      personId: 42,
      personType: 5,
      lastUsedAt: lastUsedAt ?? DateTime.utc(2026, 9, 21),
    );

class _FakeCredentialStore implements AccountCredentialStore {
  final saved = <String, AccountCredentials>{};

  @override
  Future<AccountCredentials> read(String accountId) async =>
      saved[accountId] ??
      const AccountCredentials(
        password: '',
        credentialMode: 'password',
        sessionId: '',
      );

  @override
  Future<bool> write(String accountId, AccountCredentials credentials) async {
    saved[accountId] = credentials;
    return true;
  }
}
