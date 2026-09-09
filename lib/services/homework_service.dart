import 'package:shared_preferences/shared_preferences.dart';

import '../core/sync_state.dart';
import '../data/cache/offline_cache_store.dart';
import '../data/webuntis/webuntis_capabilities.dart';
import '../data/webuntis/webuntis_client.dart';
import '../data/webuntis/webuntis_session_manager.dart';
import '../features/homework/domain/homework.dart';

class HomeworkService {
  static final WebUntisClient _client = WebUntisClient();
  static final WebUntisSessionManager _sessions = WebUntisSessionManager(
    client: _client,
  );
  static final WebUntisCapabilitiesRepository _capabilities =
      WebUntisCapabilitiesRepository();
  static final OfflineCacheStore _store = OfflineCacheStore.instance;

  static Future<Map<String, List<Map<String, dynamic>>>> fetchHomeworkAndNotes({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
    required int personId,
    required int personType,
    String? accountId,
    WebUntisAccountLogin? account,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 30));
    final end = endDate ?? now.add(const Duration(days: 30));
    final scopedAccountId = accountId?.trim() ?? '';
    final context = WebUntisRequestContext(
      schoolUrl: schoolUrl,
      schoolName: schoolName,
      sessionId: sessionId,
    );

    try {
      Future<Map<String, dynamic>> request(WebUntisRequestContext value) =>
          _client.rpc(
            context: value,
            method: 'getHomeWork2017',
            requestId: 'homework_${_dateInt(start)}_${_dateInt(end)}',
            params: [
              {
                'id': personId,
                'type': personType == 5 ? 'STUDENT' : 'TEACHER',
                'startDate': _dateInt(start),
                'endDate': _dateInt(end),
              },
            ],
          );
      final response = account == null
          ? await request(context)
          : await _sessions.runAuthenticated(
              account: account,
              currentSessionId: sessionId,
              request: request,
            );
      final bundle = await _normalize(
        response['result'],
        accountId: scopedAccountId,
      );
      if (scopedAccountId.isNotEmpty) {
        try {
          await _store.write(
            _cacheKey(scopedAccountId, start, end),
            bundle.toJson(),
          );
        } catch (_) {
          // A cache write problem must not discard fresh WebUntis data.
        }
        await _recordCapabilitySuccess(scopedAccountId, schoolUrl);
      }
      return bundle.toLegacyJson();
    } on WebUntisFailure catch (failure) {
      if (scopedAccountId.isNotEmpty) {
        await _recordCapabilityFailure(scopedAccountId, schoolUrl, failure);
        final cached = await _readCached(scopedAccountId, start, end);
        if (cached != null) return cached;
      }
      rethrow;
    } catch (_) {
      if (scopedAccountId.isNotEmpty) {
        final cached = await _readCached(scopedAccountId, start, end);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchHomework({
    required String schoolUrl,
    required String schoolName,
    required String sessionId,
    required int personId,
    required int personType,
    String? accountId,
    WebUntisAccountLogin? account,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await fetchHomeworkAndNotes(
      schoolUrl: schoolUrl,
      schoolName: schoolName,
      sessionId: sessionId,
      personId: personId,
      personType: personType,
      accountId: accountId,
      account: account,
      startDate: startDate,
      endDate: endDate,
    );
    return result['homeworks']!;
  }

  static Future<Map<String, List<Map<String, dynamic>>>?>
  loadCachedHomeworkAndNotes({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) => _readCached(accountId, startDate, endDate);

  static Future<void> toggleDone(
    int homeworkId,
    bool done, {
    String? accountId,
  }) async {
    final doneIds = await getDoneIds(accountId: accountId);
    final id = homeworkId.toString();
    done ? doneIds.add(id) : doneIds.remove(id);
    final scopedAccountId = accountId?.trim() ?? '';
    if (scopedAccountId.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('homework_done_ids', doneIds.toList()..sort());
      return;
    }
    await _store.write(_completionKey(scopedAccountId), {
      'ids': doneIds.toList()..sort(),
    });
  }

  static Future<Set<String>> getDoneIds({String? accountId}) async {
    final scopedAccountId = accountId?.trim() ?? '';
    final prefs = await SharedPreferences.getInstance();
    if (scopedAccountId.isEmpty) {
      return (prefs.getStringList('homework_done_ids') ?? const []).toSet();
    }
    final stored = await _store.read(_completionKey(scopedAccountId));
    final values = stored?.value['ids'];
    if (values is List) return values.map((value) => value.toString()).toSet();

    // One-time migration of the former global completion list to the active
    // account. Removal happens only after the scoped copy was persisted.
    final legacy = prefs.getStringList('homework_done_ids') ?? const <String>[];
    if (legacy.isNotEmpty) {
      try {
        await _store.write(_completionKey(scopedAccountId), {'ids': legacy});
        await prefs.remove('homework_done_ids');
      } catch (_) {
        // Keep the legacy list intact so a later launch can retry migration.
      }
      return legacy.toSet();
    }
    return <String>{};
  }

  static Future<HomeworkBundle> _normalize(
    dynamic rawResult, {
    required String accountId,
  }) async {
    final doneIds = await getDoneIds(accountId: accountId);
    return HomeworkBundle.fromWebUntis(rawResult, doneIds: doneIds);
  }

  static Future<Map<String, List<Map<String, dynamic>>>?> _readCached(
    String accountId,
    DateTime start,
    DateTime end,
  ) async {
    final cached =
        await _store.read(_cacheKey(accountId, start, end)) ??
        await _store.readLatestPrefix('$accountId|homework|');
    if (cached == null) return null;
    final doneIds = await getDoneIds(accountId: accountId);
    return HomeworkBundle.fromJson(
      cached.value,
      doneIds: doneIds,
    ).toLegacyJson();
  }

  static String _cacheKey(String accountId, DateTime start, DateTime end) =>
      _store.scopedKey(
        accountId: accountId,
        dataset: 'homework',
        entityKey: '${_dateInt(start)}-${_dateInt(end)}',
      );

  static String _completionKey(String accountId) => _store.scopedKey(
    accountId: accountId,
    dataset: 'homeworkLocal',
    entityKey: 'completed',
  );

  static int _dateInt(DateTime value) =>
      value.year * 10000 + value.month * 100 + value.day;

  static Future<void> _recordCapabilitySuccess(
    String accountId,
    String schoolUrl,
  ) async {
    try {
      await _capabilities.recordSuccess(
        accountId: accountId,
        schoolUrl: schoolUrl,
        module: WebUntisModule.homework,
      );
    } catch (_) {}
  }

  static Future<void> _recordCapabilityFailure(
    String accountId,
    String schoolUrl,
    WebUntisFailure failure,
  ) async {
    try {
      await _capabilities.recordFailure(
        accountId: accountId,
        schoolUrl: schoolUrl,
        module: WebUntisModule.homework,
        failure: failure,
      );
    } catch (_) {}
  }
}
