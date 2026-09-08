import '../../../core/sync_state.dart';
import '../../../data/cache/offline_cache_store.dart';
import '../../../data/webuntis/webuntis_client.dart';
import '../../../data/webuntis/webuntis_capabilities.dart';
import '../../../data/webuntis/webuntis_session_manager.dart';
import '../domain/absence.dart';

class AbsenceRepository {
  AbsenceRepository({
    required WebUntisClient client,
    OfflineCacheStore? store,
    WebUntisSessionManager? sessionManager,
    WebUntisCapabilitiesRepository? capabilities,
  }) : _client = client,
       _store = store ?? OfflineCacheStore.instance,
       _sessionManager = sessionManager,
       _capabilities = capabilities;

  final WebUntisClient _client;
  final OfflineCacheStore _store;
  final WebUntisSessionManager? _sessionManager;
  final WebUntisCapabilitiesRepository? _capabilities;

  String _key(String accountId) => _store.scopedKey(
    accountId: accountId,
    dataset: 'absences',
    entityKey: 'schoolYear',
  );

  Future<SyncState<List<Absence>>> loadCached(String accountId) async {
    final cached = await _store.read(_key(accountId));
    if (cached == null) {
      return const SyncState<List<Absence>>(data: []);
    }
    final values = cached.value['absences'];
    final absences = values is List
        ? values
              .whereType<Map>()
              .map(
                (entry) => Absence.fromJson(Map<String, dynamic>.from(entry)),
              )
              .toList()
        : <Absence>[];
    return SyncState<List<Absence>>(
      data: absences,
      phase: SyncPhase.ready,
      source: SyncSource.cache,
      lastSuccessfulSync: cached.savedAt,
      isStale:
          DateTime.now().difference(cached.savedAt) > const Duration(hours: 6),
    );
  }

  Future<SyncState<List<Absence>>> refresh({
    required String accountId,
    required WebUntisRequestContext context,
    WebUntisAccountLogin? account,
    required DateTime start,
    required DateTime end,
  }) async {
    final cached = await loadCached(accountId);
    int dateInt(DateTime value) =>
        value.year * 10000 + value.month * 100 + value.day;
    try {
      Future<Map<String, dynamic>> request(
        WebUntisRequestContext requestContext,
      ) => _client.rpc(
        context: requestContext,
        method: 'getTimetableWithAbsences',
        requestId: 'absences_${dateInt(start)}_${dateInt(end)}',
        params: {
          'options': {'startDate': dateInt(start), 'endDate': dateInt(end)},
        },
      );
      final response = _sessionManager != null && account != null
          ? await _sessionManager.runAuthenticated(
              account: account,
              currentSessionId: context.sessionId,
              request: request,
            )
          : await request(context);
      final result = response['result'];
      final raw = result is List
          ? result
          : result is Map && result['periodsWithAbsences'] is List
          ? result['periodsWithAbsences'] as List
          : const <dynamic>[];
      final absences =
          raw
              .whereType<Map>()
              .map(
                (entry) => Absence.fromJson(Map<String, dynamic>.from(entry)),
              )
              .where((entry) => entry.date > 0)
              .toList()
            ..sort((a, b) {
              final dateOrder = b.date.compareTo(a.date);
              return dateOrder != 0
                  ? dateOrder
                  : a.startTime.compareTo(b.startTime);
            });
      await _store.write(_key(accountId), {
        'absences': absences.map((entry) => entry.toJson()).toList(),
      });
      await _recordCapabilitySuccess(accountId, context.schoolUrl);
      return SyncState<List<Absence>>(
        data: absences,
        phase: SyncPhase.ready,
        source: SyncSource.network,
        lastSuccessfulSync: DateTime.now(),
      );
    } on WebUntisFailure catch (failure) {
      await _recordCapabilityFailure(accountId, context.schoolUrl, failure);
      final unsupported =
          failure.kind == WebUntisFailureKind.unsupported ||
          failure.kind == WebUntisFailureKind.permission;
      final normalized = unsupported
          ? WebUntisFailure(
              WebUntisFailureKind.unsupported,
              'Diese Schule oder dieses Konto stellt Abwesenheiten nicht bereit.',
            )
          : failure;
      return cached.copyWith(
        phase: SyncPhase.failed,
        failure: normalized,
        isStale: cached.hasData,
      );
    } catch (error) {
      return cached.copyWith(
        phase: SyncPhase.failed,
        failure: WebUntisFailure(
          WebUntisFailureKind.unknown,
          'Abwesenheiten konnten nicht aktualisiert werden.',
          cause: error,
        ),
        isStale: cached.hasData,
      );
    }
  }

  Future<void> _recordCapabilitySuccess(
    String accountId,
    String schoolUrl,
  ) async {
    try {
      await _capabilities?.recordSuccess(
        accountId: accountId,
        schoolUrl: schoolUrl,
        module: WebUntisModule.absences,
      );
    } catch (_) {
      // Capability metadata must never hide successfully loaded user data.
    }
  }

  Future<void> _recordCapabilityFailure(
    String accountId,
    String schoolUrl,
    WebUntisFailure failure,
  ) async {
    try {
      await _capabilities?.recordFailure(
        accountId: accountId,
        schoolUrl: schoolUrl,
        module: WebUntisModule.absences,
        failure: failure,
      );
    } catch (_) {
      // The original, actionable request failure remains authoritative.
    }
  }
}
