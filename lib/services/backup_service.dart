import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/security/credential_vault.dart';
import 'alarm_service.dart';

class BackupService {
  static const int schemaVersion = 2;

  static const Set<String> _boolKeys = {
    'showCancelled',
    'blurEnabled',
    'glowEffectsEnabled',
    'backgroundAnimations',
    'backgroundGyroscope',
    'progressivePush',
    'dailyBriefingPush',
    'importantChangesPush',
    'demoMode',
  };

  static const Set<String> _intKeys = {'themeMode', 'backgroundAnimationStyle'};

  static const Set<String> _stringKeys = {
    'appLocale',
    'visualTheme',
    'appFontFamily',
    'themeBlurPreferences',
    'aiProvider',
    'aiModel',
    'aiCustomCompatibility',
    'aiCustomBaseUrl',
    'aiSystemPromptTemplate',
    'subjectColors',
    'selectedCustomBackgroundId',
    'alarmConfigV1',
  };

  static const Set<String> _sensitiveStringKeys = {
    'geminiApiKey',
    'openAiApiKey',
    'mistralApiKey',
    'customAiApiKey',
  };

  static const Set<String> _stringListKeys = {
    'hiddenSubjects',
    'customExams',
    'customBackgrounds',
  };

  Future<String> exportAllToJsonText({
    bool includeApiKeys = false,
    String? passphrase,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final boolValues = <String, bool>{};
    for (final key in _boolKeys) {
      final value = prefs.getBool(key);
      if (value != null) boolValues[key] = value;
    }

    final intValues = <String, int>{};
    for (final key in _intKeys) {
      final value = prefs.getInt(key);
      if (value != null) intValues[key] = value;
    }

    final stringValues = <String, String>{};
    for (final key in _stringKeys) {
      final value = prefs.getString(key);
      if (value != null) stringValues[key] = value;
    }
    final stringListValues = <String, List<String>>{};
    for (final key in _stringListKeys) {
      final value = prefs.getStringList(key);
      if (value != null) stringListValues[key] = List<String>.from(value);
    }

    String version = '';
    String build = '';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      version = packageInfo.version;
      build = packageInfo.buildNumber;
    } catch (_) {
      // Package info is optional in tests/limited environments.
    }

    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'app': <String, dynamic>{
        'name': 'Untis+',
        'version': version,
        'build': build,
      },
      'prefs': <String, dynamic>{
        'bool': boolValues,
        'int': intValues,
        'string': stringValues,
        'stringList': stringListValues,
      },
    };

    if (includeApiKeys) {
      if (passphrase == null || passphrase.length < 8) {
        throw const FormatException(
          'A passphrase with at least 8 characters is required.',
        );
      }
      final secrets = <String, String>{};
      for (final key in _sensitiveStringKeys) {
        final provider = switch (key) {
          'openAiApiKey' => 'openai',
          'mistralApiKey' => 'mistral',
          'customAiApiKey' => 'custom',
          _ => 'gemini',
        };
        final value = await CredentialVault.instance.readAiApiKey(provider);
        if (value.isNotEmpty) secrets[key] = value;
      }
      payload['encryptedSecrets'] = await _encryptSecrets(secrets, passphrase);
    }

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  bool requiresPassphrase(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText.trim());
      return decoded is Map && decoded['encryptedSecrets'] is Map;
    } catch (_) {
      return false;
    }
  }

  Future<void> importAllFromJsonText(
    String jsonText, {
    String? passphrase,
  }) async {
    var normalizedText = jsonText.trim();
    if (normalizedText.startsWith('\uFEFF')) {
      normalizedText = normalizedText.substring(1);
    }

    final decoded = jsonDecode(normalizedText);
    final root = _asStringDynamicMap(decoded);
    if (root == null) {
      throw const FormatException('Invalid backup format');
    }

    final version = _parseSchemaVersion(root['schemaVersion']);
    if (version == null) {
      throw const FormatException('Missing schemaVersion');
    }
    if (version != 1 && version != schemaVersion) {
      throw const FormatException('Unsupported schemaVersion');
    }

    final prefsRoot = _asStringDynamicMap(root['prefs']);
    if (prefsRoot == null) {
      throw const FormatException('Missing prefs');
    }

    final boolValues = _readTypedMap<bool>(prefsRoot['bool']);
    final intValues = _readTypedMap<num>(prefsRoot['int']);
    final stringValues = _readTypedMap<String>(prefsRoot['string']);

    final rawStringListValues = prefsRoot['stringList'];
    final stringListValues = <String, List<String>>{};
    if (rawStringListValues is Map) {
      rawStringListValues.forEach((key, value) {
        if (key is! String || !_stringListKeys.contains(key)) return;
        if (value is! List) return;
        final items = <String>[];
        for (final item in value) {
          if (item is String) items.add(item);
        }
        stringListValues[key] = items;
      });
    }

    final encryptedSecrets = root['encryptedSecrets'];
    Map<String, String>? decryptedSecrets;
    if (encryptedSecrets is Map) {
      if (passphrase == null || passphrase.isEmpty) {
        throw const FormatException('Backup passphrase required');
      }
      // Validate all encrypted content before changing a single preference.
      // A wrong password therefore cannot leave a partially imported backup.
      decryptedSecrets = await _decryptSecrets(
        Map<String, dynamic>.from(encryptedSecrets),
        passphrase,
      );
    }

    final prefs = await SharedPreferences.getInstance();

    for (final key in _boolKeys) {
      final value = boolValues[key];
      if (value != null) {
        await prefs.setBool(key, value);
      }
    }

    for (final key in _intKeys) {
      final value = intValues[key];
      if (value != null) {
        var normalized = value.toInt();
        if (key == 'themeMode') {
          normalized = normalized.clamp(0, 2);
        }
        if (key == 'backgroundAnimationStyle') {
          normalized = normalized.clamp(0, 10);
        }
        await prefs.setInt(key, normalized);
      }
    }

    for (final key in _stringKeys) {
      final value = stringValues[key];
      if (value != null) {
        await prefs.setString(key, value);
      }
    }

    for (final entry in stringListValues.entries) {
      await prefs.setStringList(entry.key, entry.value);
    }

    if (decryptedSecrets != null) {
      for (final entry in decryptedSecrets.entries) {
        final provider = switch (entry.key) {
          'openAiApiKey' => 'openai',
          'mistralApiKey' => 'mistral',
          'customAiApiKey' => 'custom',
          _ => 'gemini',
        };
        await CredentialVault.instance.writeAiApiKey(provider, entry.value);
      }
    } else if (version == 1) {
      // Legacy backups may contain plain API keys. Import them into the native
      // vault and never write them back to SharedPreferences.
      for (final key in _sensitiveStringKeys) {
        final value = stringValues[key];
        if (value == null || value.isEmpty) continue;
        final provider = switch (key) {
          'openAiApiKey' => 'openai',
          'mistralApiKey' => 'mistral',
          'customAiApiKey' => 'custom',
          _ => 'gemini',
        };
        await CredentialVault.instance.writeAiApiKey(provider, value);
      }
    }

    // Native AlarmManager state is separate from Flutter preferences. Rebuild
    // it immediately after restoring a backup instead of waiting for restart.
    await AlarmService.instance.restore();
  }

  Map<String, T> _readTypedMap<T>(dynamic value) {
    final map = <String, T>{};
    if (value is! Map) return map;
    value.forEach((key, val) {
      if (key is String && val is T) {
        map[key] = val;
      }
    });
    return map;
  }

  Map<String, dynamic>? _asStringDynamicMap(dynamic value) {
    if (value is! Map) return null;
    final map = <String, dynamic>{};
    value.forEach((key, val) {
      if (key is String) {
        map[key] = val;
      }
    });
    return map;
  }

  int? _parseSchemaVersion(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  Future<Map<String, dynamic>> _encryptSecrets(
    Map<String, String> secrets,
    String passphrase,
  ) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final algorithm = AesGcm.with256bits();
    final kdf = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 150000,
      bits: 256,
    );
    final key = await kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
    final box = await algorithm.encrypt(
      utf8.encode(jsonEncode(secrets)),
      secretKey: key,
    );
    return {
      'algorithm': 'AES-256-GCM',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': 150000,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'cipherText': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  Future<Map<String, String>> _decryptSecrets(
    Map<String, dynamic> envelope,
    String passphrase,
  ) async {
    try {
      if (envelope['algorithm'] != 'AES-256-GCM' ||
          envelope['kdf'] != 'PBKDF2-HMAC-SHA256') {
        throw const FormatException();
      }
      final iterations = (envelope['iterations'] as num?)?.toInt() ?? 150000;
      if (iterations < 10000 || iterations > 1000000) {
        throw const FormatException();
      }
      final salt = base64Decode(envelope['salt']?.toString() ?? '');
      final algorithm = AesGcm.with256bits();
      final kdf = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: 256,
      );
      final key = await kdf.deriveKey(
        secretKey: SecretKey(utf8.encode(passphrase)),
        nonce: salt,
      );
      final clear = await algorithm.decrypt(
        SecretBox(
          base64Decode(envelope['cipherText']?.toString() ?? ''),
          nonce: base64Decode(envelope['nonce']?.toString() ?? ''),
          mac: Mac(base64Decode(envelope['mac']?.toString() ?? '')),
        ),
        secretKey: key,
      );
      final decoded = jsonDecode(utf8.decode(clear));
      if (decoded is! Map) throw const FormatException();
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      throw const FormatException('Invalid backup passphrase or data');
    }
  }
}
