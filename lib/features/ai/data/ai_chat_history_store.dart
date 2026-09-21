import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_models.dart';

const String aiChatHistoryStorageKey = 'aiChatHistory';

/// Persists assistant conversations without coupling JSON recovery to the UI.
class AiChatHistoryStore {
  const AiChatHistoryStore(this._preferences);

  final SharedPreferences _preferences;

  List<AiChatSession> read() {
    final raw = _preferences.getString(aiChatHistoryStorageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final sessions = <AiChatSession>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          sessions.add(
            AiChatSession.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (_) {
          // One malformed conversation must not hide the remaining history.
        }
      }
      sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return sessions;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> write(Iterable<AiChatSession> sessions) {
    final raw = jsonEncode(
      sessions.map((session) => session.toJson()).toList(growable: false),
    );
    return _preferences.setString(aiChatHistoryStorageKey, raw);
  }
}
