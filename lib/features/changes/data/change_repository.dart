import '../../../data/cache/offline_cache_store.dart';
import '../domain/timetable_change.dart';

class ChangeRepository {
  ChangeRepository({OfflineCacheStore? store})
    : _store = store ?? OfflineCacheStore.instance;

  final OfflineCacheStore _store;
  static const TimetableChangeDetector _detector = TimetableChangeDetector();

  Future<List<TimetableChange>> recordSnapshot({
    required String accountId,
    required String rangeKey,
    required Iterable<Map<dynamic, dynamic>> lessons,
  }) async {
    final snapshotKey = _store.scopedKey(
      accountId: accountId,
      dataset: 'timetableSnapshot',
      entityKey: rangeKey,
    );
    final current = lessons.map(TimetableLessonSnapshot.fromJson).toList();
    final previousDocument = await _store.read(snapshotKey);
    final previous = (previousDocument?.value['lessons'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (entry) => TimetableLessonSnapshot.fromStorage(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();

    // The first complete snapshot establishes a baseline and must never flood
    // the user with synthetic "added" changes.
    final detected = previous.isEmpty
        ? <TimetableChange>[]
        : _detector.compare(before: previous, after: current);
    await _store.write(snapshotKey, {
      'lessons': current.map((entry) => entry.toJson()).toList(),
    });
    final existing = await loadChanges(accountId);
    final byId = {for (final change in existing) change.id: change};
    for (final change in detected) {
      byId.update(change.id, (_) => change, ifAbsent: () => change);
    }
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final retained =
        byId.values
            .where((change) => change.detectedAt.isAfter(cutoff))
            .toList()
          ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    await _saveChanges(accountId, retained);
    return retained;
  }

  Future<List<TimetableChange>> loadChanges(String accountId) async {
    final key = _store.scopedKey(
      accountId: accountId,
      dataset: 'timetableChanges',
      entityKey: 'recent',
    );
    final document = await _store.read(key);
    final values = document?.value['changes'];
    if (values is! List) return const [];
    final changes =
        values
            .whereType<Map>()
            .map(
              (entry) =>
                  TimetableChange.fromJson(Map<String, dynamic>.from(entry)),
            )
            .toList()
          ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return changes;
  }

  Future<void> markAllRead(String accountId) async {
    final changes = (await loadChanges(
      accountId,
    )).map((change) => change.copyWith(isRead: true)).toList();
    await _saveChanges(accountId, changes);
  }

  Future<void> _saveChanges(
    String accountId,
    List<TimetableChange> changes,
  ) async {
    final key = _store.scopedKey(
      accountId: accountId,
      dataset: 'timetableChanges',
      entityKey: 'recent',
    );
    await _store.write(key, {
      'changes': changes.map((change) => change.toJson()).toList(),
    });
  }
}
