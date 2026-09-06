import 'dart:convert';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const int schemaVersion = 1;

  static const Set<String> _boolKeys = {
    'showCancelled',
    'blurEnabled',
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
    'themeBlurPreferences',
    'aiProvider',
    'aiModel',
    'aiCustomCompatibility',
    'aiCustomBaseUrl',
    'aiSystemPromptTemplate',
    'subjectColors',
    'selectedCustomBackgroundId',
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

  Future<String> exportAllToJsonText({bool includeApiKeys = false}) async {
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
    if (includeApiKeys) {
      for (final key in _sensitiveStringKeys) {
        final value = prefs.getString(key);
        if (value != null) stringValues[key] = value;
      }
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

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> importAllFromJsonText(String jsonText) async {
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
    if (version != schemaVersion) {
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

    for (final key in {..._stringKeys, ..._sensitiveStringKeys}) {
      final value = stringValues[key];
      if (value != null) {
        await prefs.setString(key, value);
      }
    }

    for (final entry in stringListValues.entries) {
      await prefs.setStringList(entry.key, entry.value);
    }
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
}
