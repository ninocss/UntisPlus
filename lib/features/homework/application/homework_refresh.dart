part of '../../../main.dart';

/// The timetable and Planner use the same refresh and freshness state. Existing
/// payloads and account-scoped cache keys remain owned by HomeworkService.
Future<void> _refreshActiveHomework({
  DateTime? monday,
  String? sessionId,
}) async {
  final generation = ++_homeworkRefreshGeneration;
  final accountId = activeUntisAccountId;
  final account = activeUntisAccount;
  final demo = demoModeNotifier.value;
  final start =
      monday ??
      currentWeekMondayNotifier.value ??
      resolveDefaultTimetableMonday(DateTime.now());
  final end = start.add(const Duration(days: 6));
  bool current() =>
      generation == _homeworkRefreshGeneration &&
      accountId == activeUntisAccountId &&
      demo == demoModeNotifier.value;
  homeworkSyncPhaseNotifier.value = homeworksNotifier.value.isEmpty
      ? SyncPhase.loading
      : SyncPhase.refreshing;
  try {
    if (!demo && accountId != null) {
      try {
        final cached = await HomeworkService.loadCachedHomeworkAndNotes(
          accountId: accountId,
          startDate: start,
          endDate: end,
        );
        if (!current()) return;
        if (cached != null) {
          homeworksNotifier.value = cached['homeworks']!;
          lessonNotesNotifier.value = cached['lessonNotes']!;
          homeworkCachedNotifier.value = true;
        }
      } catch (_) {
        // An unavailable cache must not prevent a live request.
      }
    }
    if (!current()) return;
    final result = demo
        ? DemoModeService.buildHomeworkAndNotes(
            start,
            locale: appLocaleNotifier.value,
          )
        : await HomeworkService.fetchHomeworkAndNotes(
            schoolUrl: account?.schoolUrl ?? schoolUrl,
            schoolName: account?.schoolName ?? schoolName,
            sessionId: sessionId ?? sessionID,
            personId: account?.personId ?? personId,
            personType: account?.personType ?? personType,
            accountId: accountId,
            account: account == null
                ? null
                : WebUntisAccountLogin(
                    accountId: account.id,
                    username: account.username,
                    schoolUrl: account.schoolUrl,
                    schoolName: account.schoolName,
                    personId: account.personId,
                    personType: account.personType,
                  ),
            startDate: start,
            endDate: end,
            allowCachedFallback: false,
          );
    if (!current()) return;
    homeworksNotifier.value = result['homeworks']!;
    lessonNotesNotifier.value = result['lessonNotes']!;
    homeworkCachedNotifier.value = false;
    homeworkSyncPhaseNotifier.value = SyncPhase.ready;
    if (!demo && accountId != null) {
      // Archiving does not change whether the school request succeeded.
      try {
        final wrapped = SchoolWrappedRepository();
        for (final year in await wrapped.years(accountId)) {
          if (!current()) return;
          if (year.contains(start)) {
            await wrapped.recordHomework(
              accountId: accountId,
              year: year,
              items: result['homeworks']!,
            );
          }
        }
      } catch (_) {}
    }
  } catch (_) {
    if (current()) homeworkSyncPhaseNotifier.value = SyncPhase.failed;
  }
}
