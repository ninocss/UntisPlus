part of '../main.dart';

class TeacherSearchPage extends StatefulWidget {
  const TeacherSearchPage({super.key});

  @override
  State<TeacherSearchPage> createState() => _TeacherSearchPageState();
}

class _TeacherSearchPageState extends State<TeacherSearchPage> {
  late final WebUntisRequestContext _requestContext;
  final TeacherSearchIndexService _teacherIndexService =
      TeacherSearchIndexService();
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<SchoolTeacher> _teachers = [];
  Map<int, List<dynamic>> _fallbackLessonsByTeacherId = const {};
  bool _usingClassFallback = false;
  int _fallbackScannedClasses = 0;
  Timer? _clockTimer;
  bool _loadingTeachers = true;
  bool _loadingSchedule = false;
  String? _teacherError;
  String? _scheduleError;
  SchoolTeacher? _selectedTeacher;
  List<dynamic> _scheduleLessons = const [];

  AppL10n get _l => appL10nFor(appLocaleNotifier.value);

  @override
  void initState() {
    super.initState();
    _requestContext = WebUntisRequestContext(
      schoolUrl: schoolUrl,
      schoolName: schoolName,
      sessionId: sessionID,
    );
    _queryController.addListener(_onQueryChanged);
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
    unawaited(_loadTeachers());
  }

  void _onQueryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTeachers({bool manualRefresh = false}) async {
    if (demoModeNotifier.value) {
      setState(() {
        _loadingTeachers = false;
        _teacherError = _l.teacherSearchDemoUnavailable;
      });
      return;
    }
    if (_requestContext.schoolUrl.isEmpty ||
        _requestContext.schoolName.isEmpty) {
      setState(() {
        _loadingTeachers = false;
        _teacherError = _l.teacherSearchNotSignedIn;
      });
      return;
    }
    if (_requestContext.sessionId.isEmpty) {
      try {
        final cached = await _teacherIndexService.read(
          accountId: activeUntisAccountId ?? 'legacy',
          context: _requestContext,
          date: DateTime.now(),
        );
        if (cached != null && cached.teachers.isNotEmpty) {
          _applyFallbackIndex(cached);
          return;
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _loadingTeachers = false;
        _teacherError = _l.teacherSearchNotSignedIn;
      });
      return;
    }

    setState(() {
      _loadingTeachers = true;
      _teacherError = null;
    });
    if (!_usingClassFallback || !manualRefresh) {
      try {
        final teachers = await _timetableRepository.fetchTeachers(
          _requestContext,
        );
        final parsed =
            teachers
                .map(SchoolTeacher.fromJson)
                .where((teacher) => teacher.id > 0 && teacher.name.isNotEmpty)
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
        if (parsed.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _teachers
              ..clear()
              ..addAll(parsed);
            _fallbackLessonsByTeacherId = const {};
            _usingClassFallback = false;
            _loadingTeachers = false;
          });
          return;
        }
      } on WebUntisFailure {
        // Continue with the class timetable fallback.
      } catch (_) {
        // Continue with the class timetable fallback.
      }
    }

    if (!mounted) return;
    setState(() => _usingClassFallback = true);
    try {
      final index = await _resolveFallbackIndex(forceRefresh: manualRefresh);
      _applyFallbackIndex(index);
    } catch (error) {
      if (!mounted) return;
      debugPrint(
        'Teacher search class fallback failed (${error.runtimeType}).',
      );
      setState(() {
        _loadingTeachers = false;
        if (_teachers.isEmpty) {
          _teacherError = error is WebUntisFailure
              ? _failureText(error)
              : _l.teacherSearchClassFallbackUnavailable;
        }
      });
      if (manualRefresh && _teachers.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l.teacherSearchLoadError)));
      }
    }
  }

  Future<TeacherSearchIndex> _resolveFallbackIndex({
    required bool forceRefresh,
  }) async {
    if (!forceRefresh) {
      final cached = await _teacherIndexService.read(
        accountId: activeUntisAccountId ?? 'legacy',
        context: _requestContext,
        date: DateTime.now(),
      );
      if (cached != null && cached.teachers.isNotEmpty) return cached;
    }
    return _teacherIndexService.refresh(
      accountId: activeUntisAccountId ?? 'legacy',
      context: _requestContext,
      date: DateTime.now(),
    );
  }

  void _applyFallbackIndex(TeacherSearchIndex index) {
    if (!mounted) return;
    setState(() {
      _teachers
        ..clear()
        ..addAll(index.teachers);
      _fallbackLessonsByTeacherId = index.lessonsByTeacherId;
      _fallbackScannedClasses = index.scannedClasses;
      _usingClassFallback = true;
      _loadingTeachers = false;
      _teacherError = index.teachers.isEmpty
          ? _l.teacherSearchUnavailable
          : null;
    });
  }

  Future<void> _selectTeacher(SchoolTeacher teacher) async {
    _searchFocusNode.unfocus();
    if (_usingClassFallback) {
      setState(() {
        _selectedTeacher = teacher;
        _scheduleLessons =
            _fallbackLessonsByTeacherId[teacher.id] ?? const <dynamic>[];
        _scheduleError = null;
        _loadingSchedule = false;
      });
      return;
    }
    setState(() {
      _selectedTeacher = teacher;
      _scheduleLessons = const [];
      _scheduleError = null;
      _loadingSchedule = true;
    });
    try {
      final lessons = await _timetableRepository.fetchTeacherTimetable(
        context: _requestContext,
        teacherId: teacher.id,
        date: DateTime.now(),
      );
      if (!mounted || _selectedTeacher?.id != teacher.id) return;
      setState(() {
        _scheduleLessons = lessons;
        _loadingSchedule = false;
      });
    } on WebUntisFailure catch (failure) {
      if (!mounted || _selectedTeacher?.id != teacher.id) return;
      if (failure.kind == WebUntisFailureKind.unsupported ||
          failure.kind == WebUntisFailureKind.permission) {
        try {
          final index = await _resolveFallbackIndex(forceRefresh: false);
          if (!mounted || _selectedTeacher?.id != teacher.id) return;
          setState(() {
            _usingClassFallback = true;
            _fallbackLessonsByTeacherId = index.lessonsByTeacherId;
            _fallbackScannedClasses = index.scannedClasses;
            _scheduleLessons =
                index.lessonsByTeacherId[teacher.id] ?? const <dynamic>[];
            _loadingSchedule = false;
            _scheduleError = null;
          });
          return;
        } catch (_) {}
      }
      setState(() {
        _loadingSchedule = false;
        _scheduleError = _failureText(failure);
      });
    } catch (_) {
      if (!mounted || _selectedTeacher?.id != teacher.id) return;
      setState(() {
        _loadingSchedule = false;
        _scheduleError = _l.teacherSearchLoadError;
      });
    }
  }

  Future<void> _refreshSearch() async {
    final selectedId = _selectedTeacher?.id;
    await _loadTeachers(manualRefresh: true);
    if (!mounted || selectedId == null || _teacherError != null) return;
    final selected = _teachers.where((teacher) => teacher.id == selectedId);
    await _selectTeacher(selected.isEmpty ? _selectedTeacher! : selected.first);
  }

  String _failureText(WebUntisFailure failure) => switch (failure.kind) {
    WebUntisFailureKind.authentication => _l.teacherSearchNotSignedIn,
    WebUntisFailureKind.permission => _l.teacherSearchNoPermission,
    WebUntisFailureKind.unsupported => _l.teacherSearchUnavailable,
    WebUntisFailureKind.offline ||
    WebUntisFailureKind.timeout => _l.teacherSearchNetworkError,
    _ => _l.teacherSearchLoadError,
  };

  List<SchoolTeacher> get _filteredTeachers => _teachers
      .where((teacher) => teacher.matches(_queryController.text))
      .toList(growable: false);

  @override
  void dispose() {
    _clockTimer?.cancel();
    _queryController
      ..removeListener(_onQueryChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = _l;
    final cs = Theme.of(context).colorScheme;
    final selected = _selectedTeacher;
    final filtered = _filteredTeachers;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.teacherSearchTitle),
        actions: [
          IconButton(
            tooltip: l.teacherSearchRefreshAll,
            onPressed:
                _loadingTeachers ||
                    _loadingSchedule ||
                    _requestContext.sessionId.isEmpty
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    unawaited(_refreshSearch());
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _queryController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onTap: HapticFeedback.selectionClick,
                onSubmitted: (_) => HapticFeedback.selectionClick(),
                decoration: InputDecoration(
                  hintText: l.teacherSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _queryController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l.teacherSearchClear,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _queryController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            if (_loadingTeachers) const LinearProgressIndicator(),
            if (_usingClassFallback)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.teacherSearchClassFallback(_fallbackScannedClasses),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            Expanded(
              child: _teacherError != null
                  ? _messageState(_teacherError!, cs)
                  : _loadingTeachers
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        if (selected != null) ...[
                          _buildScheduleCard(selected, cs, l),
                          const SizedBox(height: 14),
                        ],
                        if (filtered.isEmpty)
                          _messageState(l.teacherSearchNoMatch, cs)
                        else ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
                            child: Text(
                              l.teacherSearchResults(filtered.length),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                          for (final teacher in filtered)
                            Card(
                              elevation: 0,
                              color: selected?.id == teacher.id
                                  ? cs.secondaryContainer
                                  : cs.surfaceContainerLow,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: cs.primaryContainer,
                                  foregroundColor: cs.onPrimaryContainer,
                                  child: const Icon(Icons.person_rounded),
                                ),
                                title: Text(teacher.name),
                                subtitle:
                                    teacher.abbreviation.isEmpty ||
                                        teacher.abbreviation == teacher.name
                                    ? null
                                    : Text(teacher.abbreviation),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                ),
                                onTap: () => _selectTeacher(teacher),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageState(String message, ColorScheme colors) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
      ),
    ),
  );

  Widget _buildScheduleCard(
    SchoolTeacher teacher,
    ColorScheme colors,
    AppL10n l,
  ) {
    final schedule = _loadingSchedule || _scheduleError != null
        ? null
        : TeacherScheduleSnapshot.fromLessons(
            _scheduleLessons,
            now: DateTime.now(),
          );
    return Card(
      elevation: 0,
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    teacher.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Icon(Icons.today_rounded),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l.teacherSearchTimetableNote,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            if (_loadingSchedule) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ] else if (_scheduleError != null) ...[
              const SizedBox(height: 14),
              Text(_scheduleError!, style: TextStyle(color: colors.error)),
            ] else if (schedule != null) ...[
              const SizedBox(height: 12),
              if (schedule.current != null)
                _lessonTile(
                  icon: Icons.meeting_room_rounded,
                  title: l.teacherSearchCurrent,
                  lesson: schedule.current!,
                  detail: l.teacherSearchUntil(schedule.current!.endTime),
                  colors: colors,
                ),
              if (schedule.next != null) ...[
                if (schedule.current != null) const SizedBox(height: 8),
                _lessonTile(
                  icon: Icons.arrow_forward_rounded,
                  title: l.teacherSearchNext,
                  lesson: schedule.next!,
                  detail: l.teacherSearchFrom(schedule.next!.startTime),
                  colors: colors,
                ),
              ],
              if (schedule.current == null && schedule.next == null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    l.teacherSearchNoLessons,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lessonTile({
    required IconData icon,
    required String title,
    required TeacherLessonLocation lesson,
    required String detail,
    required ColorScheme colors,
  }) {
    final details = <String>[
      if (lesson.subject.isNotEmpty) lesson.subject,
      if (lesson.room.isNotEmpty) lesson.room,
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colors.primary),
      title: Text(title),
      subtitle: Text([if (details.isNotEmpty) details, detail].join('\n')),
      isThreeLine: details.isNotEmpty,
    );
  }
}
