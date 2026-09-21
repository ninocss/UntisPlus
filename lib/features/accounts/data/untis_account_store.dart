import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/security/credential_vault.dart';
import '../domain/untis_account.dart';

abstract interface class AccountCredentialStore {
  Future<AccountCredentials> read(String accountId);

  Future<bool> write(String accountId, AccountCredentials credentials);
}

class SecureAccountCredentialStore implements AccountCredentialStore {
  const SecureAccountCredentialStore(this._vault);

  final CredentialVault _vault;

  @override
  Future<AccountCredentials> read(String accountId) =>
      _vault.readAccount(accountId);

  @override
  Future<bool> write(String accountId, AccountCredentials credentials) => _vault
      .writeAndVerifyAccount(accountId: accountId, credentials: credentials);
}

/// Persistence boundary for account metadata and legacy account migration.
class UntisAccountStore {
  const UntisAccountStore({
    required SharedPreferences preferences,
    required AccountCredentialStore credentials,
  }) : _preferences = preferences,
       _credentials = credentials;

  final SharedPreferences _preferences;
  final AccountCredentialStore _credentials;

  List<UntisAccount> readPublicAccounts() {
    try {
      final decoded = jsonDecode(
        _preferences.getString(untisAccountsStorageKey) ?? '[]',
      );
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => UntisAccount.fromJson(Map<String, dynamic>.from(item)))
          .where(_isUsableAccount)
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<List<UntisAccount>> readHydratedAccounts() async {
    final requestedActiveId = _preferences.getString(
      activeUntisAccountStorageKey,
    );
    final hydrated = <UntisAccount>[];
    for (final account in readPublicAccounts()) {
      var credentials = await _credentials.read(account.id);
      final isRequestedActive = account.id == requestedActiveId;
      final legacyPassword = account.password.isNotEmpty
          ? account.password
          : isRequestedActive
          ? _preferences.getString('password') ?? ''
          : '';
      final legacyMode = account.credentialMode.isNotEmpty
          ? account.credentialMode
          : isRequestedActive
          ? _preferences.getString('loginCredentialMode') ?? 'password'
          : 'password';
      final legacySession = account.sessionId.isNotEmpty
          ? account.sessionId
          : isRequestedActive
          ? _preferences.getString('sessionId') ?? ''
          : '';

      if (credentials.isEmpty &&
          (legacyPassword.isNotEmpty || legacySession.isNotEmpty)) {
        final legacyCredentials = AccountCredentials(
          password: legacyPassword,
          credentialMode: legacyMode,
          sessionId: legacySession,
        );
        await _credentials.write(account.id, legacyCredentials);
        // Preserve the in-memory values if the secure store is unavailable;
        // the caller then keeps them in legacy JSON instead of losing access.
        credentials = legacyCredentials;
      }
      hydrated.add(
        account.copyWith(
          password: credentials.password,
          credentialMode: credentials.credentialMode,
          sessionId: credentials.sessionId,
        ),
      );
    }
    return hydrated;
  }

  Future<List<UntisAccount>> writeAccounts(
    List<UntisAccount> accounts, {
    bool includeSecrets = false,
  }) async {
    final ordered = List<UntisAccount>.from(accounts)
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    await _preferences.setString(
      untisAccountsStorageKey,
      jsonEncode(
        ordered
            .map((account) => account.toJson(includeSecrets: includeSecrets))
            .toList(growable: false),
      ),
    );
    return List.unmodifiable(ordered);
  }

  Future<void> copyLegacyPersonalData(String accountId) async {
    for (final key in const [
      'customHomework',
      'customExams',
      'customGrades',
      'hiddenSubjects',
    ]) {
      final scopedKey = personalDataKey(accountId, key);
      if (!_preferences.containsKey(scopedKey) &&
          _preferences.containsKey(key)) {
        await _preferences.setStringList(
          scopedKey,
          _preferences.getStringList(key) ?? const [],
        );
      }
    }
    const colorKey = 'subjectColors';
    final scopedColorKey = personalDataKey(accountId, colorKey);
    if (!_preferences.containsKey(scopedColorKey) &&
        _preferences.containsKey(colorKey)) {
      await _preferences.setString(
        scopedColorKey,
        _preferences.getString(colorKey) ?? '{}',
      );
    }
  }

  Future<void> publishBackgroundPersonalData(String accountId) async {
    for (final key in const ['hiddenSubjects']) {
      await _preferences.setStringList(
        key,
        _preferences.getStringList(personalDataKey(accountId, key)) ?? const [],
      );
    }
  }

  static String personalDataKey(String accountId, String key) =>
      'account.$accountId.$key';

  static bool _isUsableAccount(UntisAccount account) =>
      account.id.isNotEmpty &&
      account.schoolUrl.isNotEmpty &&
      account.schoolName.isNotEmpty;
}
