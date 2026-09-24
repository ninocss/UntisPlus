// lib/features/homework/providers.dart
// Riverpod providers for homework feature

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_state.dart';
import '../../core/time_utils.dart';
import '../../data/cache/offline_cache_store.dart';
import '../../services/homework_service.dart';

final homeworkServiceProvider = Provider<HomeworkService>((ref) {
  return HomeworkService();
});

class HomeworkNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    final state = ref.watch(appStateNotifierProvider);
    return state.homeworks;
  }

  Future<void> refresh() async {
    final state = ref.read(appStateNotifierProvider);
    final service = ref.read(homeworkServiceProvider);
    final repo = ref.read(offlineCacheStoreProvider);

    final context = ref.read(timetableRequestContextProvider);
    final (personId, personType) = ref.read(currentPersonIdentityProvider);
    final accountId = state.activeUntisAccountId;

    if (!state.demoMode && (personId == 0 || state.sessionID.isEmpty)) return;

    state = const AsyncLoading().copyWithPrevious(state);

    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final end = now.add(const Duration(days: 30));

      final result = await service.fetchHomeworkAndNotes(
        schoolUrl: context.schoolUrl,
        schoolName: context.schoolName,
        sessionId: context.sessionId,
        personId: personId,
        personType: personType,
        accountId: accountId,
        startDate: start,
        endDate: end,
      );

      if (accountId != state.activeUntisAccountId) return;

      // Merge with custom homework
      final customHomework = ref.read(appStateNotifierProvider).customHomework;
      final allHomework = [...result['homeworks']!, ...customHomework];
      
      ref.read(appStateNotifierProvider.notifier).setHomeworks(allHomework);
      ref.read(appStateNotifierProvider.notifier).setLessonNotes(result['lessonNotes']!);
      
      state = AsyncData(allHomework);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> toggleDone(int homeworkId, bool done) async {
    final state = ref.read(appStateNotifierProvider);
    final service = ref.read(homeworkServiceProvider);
    final accountId = state.activeUntisAccountId;

    await service.toggleDone(homeworkId, done, accountId: accountId);
    
    // Optimistic update
    final current = List<Map<String, dynamic>>.from(state.homeworks);
    for (final item in current) {
      if (item['id']?.toString() == homeworkId.toString()) {
        item['_done'] = done;
        break;
      }
    }
    state = AsyncData(current);
  }

  Future<void> addCustomHomework(Map<String, dynamic> homework) async {
    final state = ref.read(appStateNotifierProvider);
    final current = List<Map<String, dynamic>>.from(state.customHomework);
    current.add(homework);
    ref.read(appStateNotifierProvider.notifier).setCustomHomework(current);
    
    // Update combined list
    final allHomework = List<Map<String, dynamic>>.from(state.homeworks);
    allHomework.add(homework);
    state = AsyncData(allHomework);
  }

  Future<void> updateCustomHomework(int index, Map<String, dynamic> homework) async {
    final state = ref.read(appStateNotifierProvider);
    final current = List<Map<String, dynamic>>.from(state.customHomework);
    if (index >= 0 && index < current.length) {
      current[index] = homework;
      ref.read(appStateNotifierProvider.notifier).setCustomHomework(current);
      
      // Update combined list
      final allHomework = List<Map<String, dynamic>>.from(state.homeworks);
      final existingIndex = allHomework.indexWhere((h) => h['id']?.toString() == homework['id']?.toString());
      if (existingIndex >= 0) {
        allHomework[existingIndex] = homework;
      } else {
        allHomework.add(homework);
      }
      state = AsyncData(allHomework);
    }
  }

  Future<void> deleteCustomHomework(String homeworkId) async {
    final state = ref.read(appStateNotifierProvider);
    final current = state.customHomework.where((h) => h['id']?.toString() != homeworkId).toList();
    ref.read(appStateNotifierProvider.notifier).setCustomHomework(current);
    
    // Update combined list
    final allHomework = state.homeworks.where((h) => h['id']?.toString() != homeworkId).toList();
    state = AsyncData(allHomework);
  }
}

final homeworkProvider = NotifierProvider<HomeworkNotifier, List<Map<String, dynamic>>>(
  HomeworkNotifier.new,
);

// Selectors
final openHomeworkProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final all = ref.watch(homeworkProvider);
  return all.where((h) => h['isDone'] != true && h['_done'] != true).toList();
});

final doneHomeworkProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final all = ref.watch(homeworkProvider);
  return all.where((h) => h['isDone'] == true || h['_done'] == true).toList();
});

final dueSoonHomeworkProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final open = ref.watch(openHomeworkProvider);
  return open.where((h) {
    final dueDate = int.tryParse(h['dueDate'].toString()) ?? 0;
    return isHomeworkDueSoon(dueDate);
  }).toList();
});

final homeworkCountsProvider = Provider<Map<String, int>>((ref) {
  final all = ref.watch(homeworkProvider);
  final open = all.where((h) => h['isDone'] != true && h['_done'] != true).length;
  final dueSoon = all.where((h) {
    if (h['isDone'] == true || h['_done'] == true) return false;
    final dueDate = int.tryParse(h['dueDate'].toString()) ?? 0;
    return isHomeworkDueSoon(dueDate);
  }).length;
  final done = all.where((h) => h['isDone'] == true || h['_done'] == true).length;
  return {
    'total': all.length,
    'open': open,
    'dueSoon': dueSoon,
    'done': done,
  };
});