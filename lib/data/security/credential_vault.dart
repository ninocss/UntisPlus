import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secrets belonging to one WebUntis account.
class AccountCredentials {
  const AccountCredentials({
    required this.password,
    required this.credentialMode,
    required this.sessionId,
  });

  final String password;
  final String credentialMode;
  final String sessionId;

  bool get isEmpty => password.isEmpty && sessionId.isEmpty;
}

/// Native, account-scoped storage for credentials and remote AI API keys.
///
/// Public profile metadata intentionally remains in SharedPreferences so
/// widgets can enumerate accounts without receiving their secrets.
class CredentialVault {
  CredentialVault._();

  static final CredentialVault instance = CredentialVault._();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _prefix = 'untisplus.secure.v1';

  String _accountKey(String accountId, String field) =>
      '$_prefix.account.$accountId.$field';

  String _aiKey(String provider) => '$_prefix.ai.$provider.apiKey';

  Future<AccountCredentials> readAccount(String accountId) async {
    if (accountId.isEmpty) {
      return const AccountCredentials(
        password: '',
        credentialMode: 'password',
        sessionId: '',
      );
    }
    try {
      return AccountCredentials(
        password:
            await _storage.read(key: _accountKey(accountId, 'password')) ?? '',
        credentialMode:
            await _storage.read(
              key: _accountKey(accountId, 'credentialMode'),
            ) ??
            'password',
        sessionId:
            await _storage.read(key: _accountKey(accountId, 'sessionId')) ?? '',
      );
    } catch (_) {
      return const AccountCredentials(
        password: '',
        credentialMode: 'password',
        sessionId: '',
      );
    }
  }

  Future<void> writeAccount({
    required String accountId,
    required AccountCredentials credentials,
  }) async {
    if (accountId.isEmpty) return;
    await Future.wait([
      _storage.write(
        key: _accountKey(accountId, 'password'),
        value: credentials.password,
      ),
      _storage.write(
        key: _accountKey(accountId, 'credentialMode'),
        value: credentials.credentialMode,
      ),
      _storage.write(
        key: _accountKey(accountId, 'sessionId'),
        value: credentials.sessionId,
      ),
    ]);
  }

  Future<bool> writeAndVerifyAccount({
    required String accountId,
    required AccountCredentials credentials,
  }) async {
    try {
      await writeAccount(accountId: accountId, credentials: credentials);
      final stored = await readAccount(accountId);
      return stored.password == credentials.password &&
          stored.credentialMode == credentials.credentialMode &&
          stored.sessionId == credentials.sessionId;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteAccount(String accountId) async {
    if (accountId.isEmpty) return;
    await Future.wait([
      _storage.delete(key: _accountKey(accountId, 'password')),
      _storage.delete(key: _accountKey(accountId, 'credentialMode')),
      _storage.delete(key: _accountKey(accountId, 'sessionId')),
    ]);
  }

  Future<String> readAiApiKey(String provider) async {
    try {
      return await _storage.read(key: _aiKey(provider)) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> writeAiApiKey(String provider, String value) async {
    final normalized = provider.trim().toLowerCase();
    if (normalized.isEmpty) return;
    if (value.isEmpty) {
      await _storage.delete(key: _aiKey(normalized));
    } else {
      await _storage.write(key: _aiKey(normalized), value: value);
    }
  }

  /// Moves legacy API keys only after the native store can read them back.
  Future<Map<String, String>> loadAndMigrateAiKeys(
    SharedPreferences prefs,
  ) async {
    const legacyKeys = <String, String>{
      'gemini': 'geminiApiKey',
      'openai': 'openAiApiKey',
      'mistral': 'mistralApiKey',
      'custom': 'customAiApiKey',
    };
    final result = <String, String>{};
    for (final entry in legacyKeys.entries) {
      var value = await readAiApiKey(entry.key);
      final legacy = prefs.getString(entry.value) ?? '';
      if (value.isEmpty && legacy.isNotEmpty) {
        try {
          await writeAiApiKey(entry.key, legacy);
          value = await readAiApiKey(entry.key);
          if (value == legacy) await prefs.remove(entry.value);
        } catch (_) {
          value = legacy;
        }
      }
      result[entry.key] = value;
    }
    return result;
  }
}
