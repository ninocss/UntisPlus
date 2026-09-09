import '../../core/sync_state.dart';
import '../cache/offline_cache_store.dart';

enum WebUntisModule {
  timetable,
  homework,
  exams,
  grades,
  absences,
  messages,
  changes,
}

enum WebUntisCapabilityState { unknown, supported, unsupported, forbidden }

class WebUntisCapabilities {
  const WebUntisCapabilities({required this.modules, this.updatedAt});

  const WebUntisCapabilities.unknown() : modules = const {}, updatedAt = null;

  final Map<WebUntisModule, WebUntisCapabilityState> modules;
  final DateTime? updatedAt;

  WebUntisCapabilityState stateOf(WebUntisModule module) =>
      modules[module] ?? WebUntisCapabilityState.unknown;

  bool supports(WebUntisModule module) =>
      stateOf(module) == WebUntisCapabilityState.supported;
}

/// Persists module support per account and school. Transient network and
/// authentication failures never downgrade a capability.
class WebUntisCapabilitiesRepository {
  WebUntisCapabilitiesRepository({OfflineCacheStore? store})
    : _store = store ?? OfflineCacheStore.instance;

  final OfflineCacheStore _store;

  String _key(String accountId, String schoolUrl) => _store.scopedKey(
    accountId: accountId,
    dataset: 'capabilities',
    entityKey: schoolUrl.trim().toLowerCase(),
  );

  Future<WebUntisCapabilities> load({
    required String accountId,
    required String schoolUrl,
  }) async {
    final cached = await _store.read(_key(accountId, schoolUrl));
    if (cached == null) return const WebUntisCapabilities.unknown();
    final values = cached.value['modules'];
    final modules = <WebUntisModule, WebUntisCapabilityState>{};
    if (values is Map) {
      for (final module in WebUntisModule.values) {
        final raw = values[module.name]?.toString();
        modules[module] = WebUntisCapabilityState.values.firstWhere(
          (state) => state.name == raw,
          orElse: () => WebUntisCapabilityState.unknown,
        );
      }
    }
    return WebUntisCapabilities(modules: modules, updatedAt: cached.savedAt);
  }

  Future<WebUntisCapabilities> recordSuccess({
    required String accountId,
    required String schoolUrl,
    required WebUntisModule module,
  }) => _record(
    accountId: accountId,
    schoolUrl: schoolUrl,
    module: module,
    state: WebUntisCapabilityState.supported,
  );

  Future<WebUntisCapabilities> recordFailure({
    required String accountId,
    required String schoolUrl,
    required WebUntisModule module,
    required WebUntisFailure failure,
  }) async {
    final state = switch (failure.kind) {
      WebUntisFailureKind.unsupported => WebUntisCapabilityState.unsupported,
      WebUntisFailureKind.permission => WebUntisCapabilityState.forbidden,
      _ => null,
    };
    if (state == null) return load(accountId: accountId, schoolUrl: schoolUrl);
    return _record(
      accountId: accountId,
      schoolUrl: schoolUrl,
      module: module,
      state: state,
    );
  }

  Future<WebUntisCapabilities> _record({
    required String accountId,
    required String schoolUrl,
    required WebUntisModule module,
    required WebUntisCapabilityState state,
  }) async {
    final current = await load(accountId: accountId, schoolUrl: schoolUrl);
    final updated = Map<WebUntisModule, WebUntisCapabilityState>.from(
      current.modules,
    )..[module] = state;
    await _store.write(_key(accountId, schoolUrl), {
      'modules': {
        for (final entry in updated.entries) entry.key.name: entry.value.name,
      },
    });
    return WebUntisCapabilities(modules: updated, updatedAt: DateTime.now());
  }
}
