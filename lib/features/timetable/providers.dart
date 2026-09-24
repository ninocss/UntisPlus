// lib/features/timetable/providers.dart
// Riverpod providers for timetable feature

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_state.dart';
import '../../core/time_utils.dart';
import '../../core/timetable_date_utils.dart';
import '../../data/cache/offline_cache_store.dart';
import '../../data/webuntis/webuntis_client.dart';
import '../../features/timetable/data/timetable_repository.dart';
import '../../features/changes/data/change_repository.dart';
import '../../features/changes/domain/timetable_change.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository(client: ref.watch(webUntisClientProvider));
});

final changeRepositoryProvider = Provider<ChangeRepository>((ref) {
  return ChangeRepository(store: ref.watch(offlineCacheStoreProvider));
});

// Async notifier for timetable data
class TimetableNotifier extends AsyncNotifier<Map<int, List<dynamic>>> {
  Timer? _refreshTimer;
  int _fetchGeneration = 0;

  @override
  Future<Map<int, List<dynamic>>> build() async {
    final state = ref.read(appStateNotifierProvider);
    if (!state.demoMode && 
        (state.sessionID.isEmpty || state.schoolUrl.isEmpty)) {
      return {};
    }
    return await _fetchFullWeek();
  }

  Future<Map<int, List<dynamic>>> _fetchFullWeek({bool silent = false}) async {
    final generation = ++_fetchGeneration;
    final state = ref.read(appStateNotifierProvider);
    final repo = ref.read(timetableRepositoryProvider);
    final cache = ref.read(offlineCacheStoreProvider);
    final changeRepo = ref.read(changeRepositoryProvider);

    final context = ref.read(timetableRequestContextProvider);
    final (personId, personType) = ref.read(currentPersonIdentityProvider);
    final accountId = state.activeUntisAccountId ?? 'legacy';

    if (personId == 0) return {};

    if (!silent) {
      state = const AsyncLoading().copyWithPrevious(state);
    }

    try {
      // Try cache first
      final monday = resolveDefaultTimetableMonday(DateTime.now());
      final cached = await _loadWeekFromCache(
        cache: cache,
        accountId: accountId,
        personId: personId,
        personType: personType,
        monday: monday,
      );

      if (cached != null && cached.values.any((l) => l.isNotEmpty)) {
        if (generation != _fetchGeneration) return state.valueOrNull ?? {};
        
        // Apply cached data
        final enriched = _enrichWeek(cached, context, personId, personType);
        _applyKnownSubjects(enriched);
        
        // Load teacher changes
        _loadTeacherChanges(changeRepo, accountId);
        
        // Update widgets
        await _updateWidgets(enriched);
        
        if (!silent) {
          state = AsyncData(enriched);
        }
        return enriched;
      }

      // Fetch from network
      if (generation != _fetchGeneration) return state.valueOrNull ?? {};

      final friday = monday.add(const Duration(days: 4));
      final lessons = await repo.fetchTimetable(
        context: context,
        elementId: personId,
        elementType: personType,
        startDate: monday,
        endDate: friday,
      );

      if (generation != _fetchGeneration) return state.valueOrNull ?? {};

      final week = _parseWeekResult(lessons);
      if (week == null) return state.valueOrNull ?? {};

      final enriched = _enrichWeek(week, context, personId, personType);
      
      // Save to cache
      await _saveWeekToCache(
        cache: cache,
        accountId: accountId,
        personId: personId,
        personType: personType,
        weekData: enriched,
        monday: monday,
      );

      _applyKnownSubjects(enriched);
      _loadTeacherChanges(changeRepo, accountId);
      await _updateWidgets(enriched);

      if (!silent) {
        state = AsyncData(enriched);
      }
      return enriched;
    } catch (e, stack) {
      if (!silent) {
        state = AsyncError(e, stack);
      }
      rethrow;
    }
  }

  Future<void> refresh({bool silent = false}) async {
    await _fetchFullWeek(silent: silent);
  }

  // Prefetch adjacent weeks
  Future<void> prefetchAdjacentWeeks() async {
    if (ref.read(appStateNotifierProvider).demoMode) return;

    final state = ref.read(appStateNotifierProvider);
    final cache = ref.read(offlineCacheStoreProvider);
    final repo = ref.read(timetableRepositoryProvider);
    final context = ref.read(timetableRequestContextProvider);
    final (personId, personType) = ref.read(currentPersonIdentityProvider);
    final accountId = state.activeUntisAccountId ?? 'legacy';

    if (personId == 0) return;

    await _fetchMasterData(repo, context);
    
    for (final delta in [-1, 1, 2]) {
      final adjMonday = resolveDefaultTimetableMonday(DateTime.now()).add(Duration(days: 7 * delta));
      final key = _weekCacheKey(accountId, personId, personType, adjMonday);
      
      // Check cache first
      final cached = await cache.read(key);
      if (cached != null && cached.value['weekData'] != null) continue;

      try {
        final friday = adjMonday.add(const Duration(days: 4));
        final lessons = await repo.fetchTimetable(
          context: context,
          elementId: personId,
          elementType: personType,
          startDate: adjMonday,
          endDate: friday,
          requestId: 'week_prefetch',
        );
        final week = _parseWeekResult(lessons);
        if (week != null) {
          final enriched = _enrichWeek(week, context, personId, personType);
          await _saveWeekToCache(
            cache: cache,
            accountId: accountId,
            personId: personId,
            personType: personType,
            weekData: enriched,
            monday: adjMonday,
          );
        }
      } catch (_) {}
    }
  }

  // Cache helpers
  String _weekCacheKey(String accountId, int personId, int personType, DateTime monday) {
    return OfflineCacheStore.instance.scopedKey(
      accountId: accountId,
      dataset: 'timetableWeek',
      entityKey: 'weekCacheV1|${accountId}|$personType|$personId|${untisDateString(monday)}',
    );
  }

  Future<Map<int, List<dynamic>>?> _loadWeekFromCache({
    required OfflineCacheStore cache,
    required String accountId,
    required int personId,
    required int personType,
    required DateTime monday,
  }) async {
    try {
      final key = _weekCacheKey(accountId, personId, personType, monday);
      final stored = await cache.read(key);
      if (stored == null) return null;
      
      final week = stored.value['weekData'];
      if (week is! Map) return null;

      final tempWeek = _emptyWeekData();
      for (var i = 0; i < 5; i++) {
        final dayRaw = week['$i'];
        if (dayRaw is! List) continue;
        tempWeek[i] = dayRaw
            .whereType<Map>()
            .map((lesson) => Map<String, dynamic>.from(lesson.cast<String, dynamic>()))
            .toList();
      }
      tempWeek.forEach((_, list) {
        list.sort((a, b) {
          final aStart = (a['startTime'] as num?)?.toInt() ?? 0;
          final bStart = (b['startTime'] as num?)?.toInt() ?? 0;
          return aStart.compareTo(bStart);
        });
      });
      return tempWeek;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveWeekToCache({
    required OfflineCacheStore cache,
    required String accountId,
    required int personId,
    required int personType,
    required Map<int, List<dynamic>> weekData,
    required DateTime monday,
  }) async {
    try {
      final key = _weekCacheKey(accountId, personId, personType, monday);
      final payload = {
        'savedAt': DateTime.now().toIso8601String(),
        'weekData': {
          for (var i = 0; i < 5; i++) '$i': weekData[i] ?? const <dynamic>[],
        },
      };
      await cache.write(key, payload);
    } catch (_) {}
  }

  Map<int, List<dynamic>> _emptyWeekData() => {
    0: <dynamic>[],
    1: <dynamic>[],
    2: <dynamic>[],
    3: <dynamic>[],
    4: <dynamic>[],
  };

  Map<int, List<dynamic>>? _parseWeekResult(dynamic result) {
    if (result is! List) return null;
    final week = _emptyWeekData();
    for (final entry in result) {
      if (entry is! Map) continue;
      final day = entry['date'];
      if (day is! int) continue;
      final date = parseUntisDateInt(day);
      if (date == null) continue;
      final dayIndex = date.weekday - 1;
      if (dayIndex < 0 || dayIndex > 4) continue;
      final lessonMap = Map<String, dynamic>.from(entry.cast<String, dynamic>());
      week[dayIndex] = [...week[dayIndex]!, lessonMap];
    }
    for (final i in week.keys) {
      week[i]!.sort((a, b) {
        final aStart = (a['startTime'] as int?) ?? 0;
        final bStart = (b['startTime'] as int?) ?? 0;
        return aStart.compareTo(bStart);
      });
    }
    return week;
  }

  Future<void> _fetchMasterData(TimetableRepository repo, WebUntisRequestContext context) async {
    final state = ref.read(appStateNotifierProvider);
    if (state.subjectShortMap.isNotEmpty &&
        state.teacherMap.isNotEmpty &&
        state.roomMap.isNotEmpty) {
      return;
    }

    try {
      final data = await repo.fetchMasterData(context);
      for (final subject in data.subjects) {
        final id = subject['id'] as int?;
        if (id == null) continue;
        // We can't directly update the notifier's private maps from here
        // This would need to be refactored to use the central state
      }
    } catch (_) {}
  }

  Map<int, List<dynamic>> _enrichWeek(
    Map<int, List<dynamic>> week,
    WebUntisRequestContext context,
    int personId,
    int personType,
  ) {
    // Enrichment logic - uses the central state's maps
    final state = ref.read(appStateNotifierProvider);
    for (final lessons in week.values) {
      for (final lesson in lessons) {
        if (lesson is! Map) continue;
        final lessonMap = lesson as Map<String, dynamic>;
        
        // Teacher
        final teList = (lessonMap['te'] as List?) ?? [];
        if (teList.isNotEmpty) {
          final firstTeacher = teList.first as Map?;
          if (firstTeacher != null) {
            final tId = firstTeacher['id'] as int?;
            lessonMap['_teacher'] = tId != null
                ? (state.teacherMap[tId] ?? (firstTeacher['name']?.toString() ?? '?'))
                : '?';
          }
        }
        
        // Subject
        final suList = (lessonMap['su'] as List?) ?? [];
        if (suList.isNotEmpty) {
          final firstSubject = suList.first as Map?;
          if (firstSubject != null) {
            final sId = firstSubject['id'] as int?;
            lessonMap['_subjectShort'] = sId != null
                ? (state.subjectShortMap[sId] ?? (firstSubject['name']?.toString() ?? '?'))
                : '?';
            lessonMap['_subjectLong'] = sId != null
                ? (state.subjectLongMap[sId] ?? (firstSubject['longName']?.toString() ?? firstSubject['name']?.toString() ?? '?'))
                : '?';
          }
        }
        
        // Room
        final rawRo = lessonMap['ro'];
        final roList = rawRo is List
            ? rawRo
            : rawRo is Map
            ? [rawRo]
            : <dynamic>[];
        if (roList.isNotEmpty) {
          final names = roList
              .map((ro) {
                final rId = (ro as Map)['id'] as int?;
                return rId != null
                    ? (state.roomMap[rId] ?? (ro['name']?.toString() ?? '?'))
                    : (ro['name']?.toString() ?? '?');
              })
              .where((name) => name != '?')
              .toSet()
              .toList();
          lessonMap['_room'] = names.isNotEmpty ? names.join(', ') : '?';
        }
      }
    }
    return week;
  }

  void _applyKnownSubjects(Map<int, List<dynamic>> weekData) {
    final allSubjects = <String>{};
    for (final list in weekData.values) {
      for (final l in list) {
        final s = l['_subjectShort']?.toString() ?? '';
        if (s.isNotEmpty) allSubjects.add(s);
      }
    }
    ref.read(appStateNotifierProvider.notifier).setKnownSubjects(allSubjects);
  }

  void _loadTeacherChanges(ChangeRepository repo, String accountId) {
    unawaited(repo.loadChanges(accountId).then((changes) {
      final originals = <String, String>{};
      for (final change in changes) {
        if (change.type == TimetableChangeType.teacher &&
            change.lessonIdentity.isNotEmpty &&
            (change.before ?? '').trim().isNotEmpty) {
          originals[change.lessonIdentity] = change.before!.trim();
        }
      }
      // Store in central state or local map
    }));
  }

  Future<void> _updateWidgets(Map<int, List<dynamic>> week) async {
    // Widget update logic
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final timetableProvider = AsyncNotifierProvider<TimetableNotifier, Map<int, List<dynamic>>>(
  TimetableNotifier.new,
);

// Selectors for granular rebuilds
final currentDayLessonsProvider = Provider<List<dynamic>>((ref) {
  final week = ref.watch(timetableProvider);
  final now = DateTime.now();
  final dayIndex = now.weekday - 1;
  if (dayIndex < 0 || dayIndex > 4) return const [];
  return week.value?[dayIndex] ?? const [];
});

final currentLessonProvider = Provider<Map<String, dynamic>?>((ref) {
  final lessons = ref.watch(currentDayLessonsProvider);
  final now = DateTime.now();
  final nowMin = now.hour * 100 + now.minute;
  
  for (final lesson in lessons) {
    if (lesson is! Map) continue;
    final start = (lesson['startTime'] as int?) ?? 0;
    final end = (lesson['endTime'] as int?) ?? 0;
    if (nowMin >= start && nowMin <= end) {
      return lesson as Map<String, dynamic>;
    }
  }
  return null;
});

final nextLessonProvider = Provider<Map<String, dynamic>?>((ref) {
  final lessons = ref.watch(currentDayLessonsProvider);
  final now = DateTime.now();
  final nowMin = now.hour * 100 + now.minute;
  
  for (final lesson in lessons) {
    if (lesson is! Map) continue;
    final start = (lesson['startTime'] as int?) ?? 0;
    if (start > nowMin) {
      return lesson as Map<String, dynamic>;
    }
  }
  return null;
});

final hasActiveLessonProvider = Provider<bool>((ref) {
  return ref.watch(currentLessonProvider) != null;
});

final unreadChangesProvider = Provider<int>((ref) {
  return ref.watch(appStateNotifierProvider.select((s) => s.unreadTimetableChanges));
});