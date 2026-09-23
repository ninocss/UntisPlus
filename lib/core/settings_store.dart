import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef PreferenceDecoder<T> = T Function(Object? raw);
typedef PreferenceEncoder<T> = Object? Function(T value);
typedef PreferenceNormalizer<T> = T Function(T value);

class PreferenceBinding<T> {
  const PreferenceBinding({
    required this.key,
    required this.defaultValue,
    required this.notifier,
    required this.decoder,
    required this.encoder,
    this.normalize,
    this.accountNamespace,
  });

  final String key;
  final T defaultValue;
  final ValueNotifier<T> notifier;
  final PreferenceDecoder<T> decoder;
  final PreferenceEncoder<T> encoder;
  final PreferenceNormalizer<T>? normalize;
  final String? accountNamespace;

  String resolvedKey({String? accountId}) {
    final namespace = accountNamespace?.trim();
    final normalizedAccountId = accountId?.trim();
    if (namespace == null ||
        namespace.isEmpty ||
        normalizedAccountId == null ||
        normalizedAccountId.isEmpty) {
      return key;
    }
    return '$namespace.$normalizedAccountId.$key';
  }

  T decode(Object? raw) {
    if (raw == null) return defaultValue;
    try {
      final decoded = decoder(raw);
      return normalize?.call(decoded) ?? decoded;
    } catch (_) {
      return defaultValue;
    }
  }

  T normalized(T value) => normalize?.call(value) ?? value;
}

class SettingsStore {
  SettingsStore._(this.preferences);

  final SharedPreferences preferences;

  static SettingsStore? _instance;

  static SettingsStore get instance {
    final current = _instance;
    if (current == null) {
      throw StateError('SettingsStore has not been initialized.');
    }
    return current;
  }

  static Future<SettingsStore> initialize({
    SharedPreferences? preferences,
  }) async {
    final existing = _instance;
    if (existing != null && preferences == null) return existing;
    final store = SettingsStore._(
      preferences ?? await SharedPreferences.getInstance(),
    );
    _instance = store;
    return store;
  }

  static void debugReset() {
    assert(() {
      _instance = null;
      return true;
    }());
  }

  T read<T>(PreferenceBinding<T> binding, {String? accountId}) {
    final raw = preferences.get(binding.resolvedKey(accountId: accountId));
    return binding.decode(raw);
  }

  Future<T> load<T>(
    PreferenceBinding<T> binding, {
    String? accountId,
  }) async {
    final value = read(binding, accountId: accountId);
    binding.notifier.value = value;
    return value;
  }

  Future<void> write<T>(
    PreferenceBinding<T> binding,
    T value, {
    String? accountId,
  }) async {
    final normalized = binding.normalized(value);
    final key = binding.resolvedKey(accountId: accountId);
    binding.notifier.value = normalized;
    await writeRaw(key, binding.encoder(normalized));
  }

  Future<void> writeRaw(String key, Object? value) async {
    if (value == null) {
      await preferences.remove(key);
      return;
    }
    if (value is bool) {
      await preferences.setBool(key, value);
      return;
    }
    if (value is int) {
      await preferences.setInt(key, value);
      return;
    }
    if (value is double) {
      await preferences.setDouble(key, value);
      return;
    }
    if (value is String) {
      await preferences.setString(key, value);
      return;
    }
    if (value is List<String>) {
      await preferences.setStringList(key, value);
      return;
    }
    throw ArgumentError.value(value, key, 'Unsupported preference value');
  }

  Future<void> remove(String key) => preferences.remove(key);
}

PreferenceBinding<bool> boolPreference({
  required String key,
  required bool defaultValue,
  required ValueNotifier<bool> notifier,
  PreferenceNormalizer<bool>? normalize,
  String? accountNamespace,
}) => PreferenceBinding<bool>(
  key: key,
  defaultValue: defaultValue,
  notifier: notifier,
  decoder: (raw) => raw is bool ? raw : defaultValue,
  encoder: (value) => value,
  normalize: normalize,
  accountNamespace: accountNamespace,
);

PreferenceBinding<int> intPreference({
  required String key,
  required int defaultValue,
  required ValueNotifier<int> notifier,
  PreferenceNormalizer<int>? normalize,
  String? accountNamespace,
}) => PreferenceBinding<int>(
  key: key,
  defaultValue: defaultValue,
  notifier: notifier,
  decoder: (raw) => raw is int ? raw : defaultValue,
  encoder: (value) => value,
  normalize: normalize,
  accountNamespace: accountNamespace,
);

PreferenceBinding<double> doublePreference({
  required String key,
  required double defaultValue,
  required ValueNotifier<double> notifier,
  PreferenceNormalizer<double>? normalize,
  String? accountNamespace,
}) => PreferenceBinding<double>(
  key: key,
  defaultValue: defaultValue,
  notifier: notifier,
  decoder: (raw) => raw is num ? raw.toDouble() : defaultValue,
  encoder: (value) => value,
  normalize: normalize,
  accountNamespace: accountNamespace,
);

PreferenceBinding<String> stringPreference({
  required String key,
  required String defaultValue,
  required ValueNotifier<String> notifier,
  PreferenceNormalizer<String>? normalize,
  String? accountNamespace,
}) => PreferenceBinding<String>(
  key: key,
  defaultValue: defaultValue,
  notifier: notifier,
  decoder: (raw) => raw?.toString() ?? defaultValue,
  encoder: (value) => value,
  normalize: normalize,
  accountNamespace: accountNamespace,
);

PreferenceBinding<List<String>> stringListPreference({
  required String key,
  required List<String> defaultValue,
  required ValueNotifier<List<String>> notifier,
  PreferenceNormalizer<List<String>>? normalize,
  String? accountNamespace,
}) => PreferenceBinding<List<String>>(
  key: key,
  defaultValue: defaultValue,
  notifier: notifier,
  decoder: (raw) {
    if (raw is List<String>) return List<String>.from(raw);
    if (raw is List) return raw.map((value) => value.toString()).toList();
    return List<String>.from(defaultValue);
  },
  encoder: (value) => List<String>.from(value),
  normalize: normalize,
  accountNamespace: accountNamespace,
);

PreferenceBinding<T> jsonPreference<T>({
  required String key,
  required T defaultValue,
  required ValueNotifier<T> notifier,
  required T Function(Object? decoded) decodeJson,
  required Object? Function(T value) encodeJson,
  PreferenceNormalizer<T>? normalize,
  String? accountNamespace,
}) => PreferenceBinding<T>(
  key: key,
  defaultValue: defaultValue,
  notifier: notifier,
  decoder: (raw) {
    if (raw is! String || raw.trim().isEmpty) return defaultValue;
    try {
      return decodeJson(jsonDecode(raw));
    } catch (_) {
      return defaultValue;
    }
  },
  encoder: (value) => jsonEncode(encodeJson(value)),
  normalize: normalize,
  accountNamespace: accountNamespace,
);
