import 'dart:async';
import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

class CachedDocument {
  const CachedDocument({required this.savedAt, required this.value});

  final DateTime savedAt;
  final Map<String, dynamic> value;
}

/// Versioned, lazy local storage for larger offline documents.
class OfflineCacheStore {
  OfflineCacheStore._();

  static final OfflineCacheStore instance = OfflineCacheStore._();
  static const String _boxName = 'offline_documents_v1';
  Future<Box<String>>? _boxFuture;

  Future<Box<String>> _box() => _boxFuture ??= _open();

  Future<Box<String>> _open() async {
    await Hive.initFlutter('untisplus_cache');
    return Hive.openBox<String>(_boxName);
  }

  String scopedKey({
    required String accountId,
    required String dataset,
    required String entityKey,
  }) => '${accountId.trim()}|${dataset.trim()}|${entityKey.trim()}';

  Future<CachedDocument?> read(String key) async {
    try {
      final raw = (await _box()).get(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final value = map['value'];
      if (value is! Map) return null;
      return CachedDocument(
        savedAt:
            DateTime.tryParse(map['savedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        value: Map<String, dynamic>.from(value),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Map<String, dynamic> value) async {
    final payload = jsonEncode({
      'schemaVersion': 1,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'value': value,
    });
    await (await _box()).put(key, payload);
  }

  Future<void> deletePrefix(String prefix) async {
    final box = await _box();
    final keys = box.keys.whereType<String>().where(
      (key) => key.startsWith(prefix),
    );
    await box.deleteAll(keys);
  }
}
