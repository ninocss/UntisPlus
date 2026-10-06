part of '../main.dart';

class TeacherSearchPage extends StatefulWidget {
  const TeacherSearchPage({super.key});

  @override
  State<TeacherSearchPage> createState() => _TeacherSearchPageState();
}

class _TeacherSearchPageState extends State<TeacherSearchPage> {
  late final WebUntisRequestContext _requestContext;
  final String? _accountId = activeUntisAccountId;
  bool get _contextCurrent => mounted && _accountId == activeUntisAccountId;
  final TeacherSearchIndexService _teacherIndexService =
      TeacherSearchIndexService();
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<SchoolTeacher> _teachers = [];
  Map<int, List<dynamic>> _fallbackLessonsByTeacherId = const {};
  bool _usingClassFallback = false;
  int _fallbackScannedClasses = 0;

  bool _loadingTeachers = true;
  bool _loadingSchedule = false;
  String? _teacherError;
  String? _scheduleError;
  SchoolTeacher? _selectedTeacher;
  TeacherWeekSchedule _preparedSchedule = TeacherWeekSchedule.fromLessons(
    const [],
  );
  set _scheduleLessons(List<dynamic> value) {
    _preparedSchedule = TeacherWeekSchedule.fromLessons(value);
  }

  final Map<String, List<dynamic>> _weekCache = BoundedLruCache(capacity: 5);
  late DateTime _weekStart;
  late DateTime _selectedDay;
  int _scheduleRequest = 0;
  int _weekRequest = 0;

  AppL10n get _l => appL10nFor(appLocaleNotifier.value);

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _weekStart = _monday(_selectedDay);
    _requestContext = WebUntisRequestContext(
      schoolUrl: schoolUrl,
      schoolName: schoolName,
      sessionId: sessionID,
    );
    unawaited(_loadTeachers());
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
          accountId: _accountId ?? 'legacy',
          context: _requestContext,
          date: _weekStart,
        );
        if (cached != null && cached.teachers.isNotEmpty) {
          _applyFallbackIndex(cached);
          return;
        }
      } catch (_) {}
      if (!_contextCurrent) return;
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
    if (!manualRefresh && _teachers.isEmpty) {
      try {
        final cached = await _teacherIndexService.read(
          accountId: _accountId ?? 'legacy',
          context: _requestContext,
          date: _weekStart,
        );
        if (cached != null && cached.teachers.isNotEmpty) {
          _applyFallbackIndex(cached);
        }
      } catch (_) {}
    }
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
          if (!_contextCurrent) return;
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

    if (!_contextCurrent) return;
    setState(() => _usingClassFallback = true);
    try {
      final index = await _resolveFallbackIndex(forceRefresh: manualRefresh);
      _applyFallbackIndex(index);
    } catch (error) {
      if (!_contextCurrent || !mounted) return;
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
        accountId: _accountId ?? 'legacy',
        context: _requestContext,
        date: _weekStart,
      );
      if (cached != null && cached.teachers.isNotEmpty) return cached;
    }
    return _teacherIndexService.refresh(
      accountId: _accountId ?? 'legacy',
      context: _requestContext,
      date: _weekStart,
    );
  }

  void _applyFallbackIndex(TeacherSearchIndex index) {
    if (!_contextCurrent) return;
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
    AppHaptics.selection();
    final request = ++_scheduleRequest;
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
    final cacheKey =
        '${teacher.id}:${_weekStart.year}-${_weekStart.month}-${_weekStart.day}';
    final cached = _weekCache[cacheKey];
    if (cached != null) {
      setState(() {
        _selectedTeacher = teacher;
        _scheduleLessons = cached;
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
        date: _weekStart,
        endDate: _weekStart.add(const Duration(days: 6)),
      );
      if (!_contextCurrent || request != _scheduleRequest) return;
      _weekCache[cacheKey] = lessons;
      setState(() {
        _scheduleLessons = lessons;
        _loadingSchedule = false;
      });
    } on WebUntisFailure catch (failure) {
      if (!_contextCurrent || request != _scheduleRequest) return;
      if (failure.kind == WebUntisFailureKind.unsupported ||
          failure.kind == WebUntisFailureKind.permission) {
        try {
          final index = await _resolveFallbackIndex(forceRefresh: false);
          if (!_contextCurrent || request != _scheduleRequest) return;
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
      if (!_contextCurrent || request != _scheduleRequest) return;
      setState(() {
        _loadingSchedule = false;
        _scheduleError = _l.teacherSearchLoadError;
      });
    }
  }

  Future<void> _refreshSearch() async {
    _weekCache.clear();
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

  DateTime _monday(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  Future<void> _changeWeek(int weeks) async {
    AppHaptics.selection();
    final request = ++_weekRequest;
    final nextWeek = _weekStart.add(Duration(days: weeks * 7));
    final selectedWeekday = _selectedDay.weekday;
    setState(() {
      _weekStart = nextWeek;
      _selectedDay = nextWeek.add(Duration(days: selectedWeekday - 1));
      _scheduleLessons = const [];
      _scheduleError = null;
    });
    ++_scheduleRequest;
    if (_usingClassFallback) {
      setState(() => _loadingTeachers = true);
      try {
        final index = await _resolveFallbackIndex(forceRefresh: false);
        if (!_contextCurrent || request != _weekRequest) return;
        _applyFallbackIndex(index);
      } catch (_) {
        if (_contextCurrent && request == _weekRequest) {
          setState(() {
            _loadingTeachers = false;
            _teacherError = _l.teacherSearchClassFallbackUnavailable;
          });
        }
      }
    }
    if (!_contextCurrent || request != _weekRequest) return;
    final teacher = _selectedTeacher;
    if (teacher != null && mounted) await _selectTeacher(teacher);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = _l;
    final cs = Theme.of(context).colorScheme;
    final selected = _selectedTeacher;
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
                    AppHaptics.selection();
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
                onTap: AppHaptics.selection,
                onSubmitted: (_) => AppHaptics.selection(),
                decoration: InputDecoration(
                  hintText: l.teacherSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _queryController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l.teacherSearchClear,
                          onPressed: () {
                            AppHaptics.selection();
                            _queryController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      _expressiveRadius(context, 18, expressiveRadius: 28),
                    ),
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
                  : _loadingTeachers && _teachers.isEmpty
                  ? const SizedBox.shrink()
                  : ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _queryController,
                      builder: (context, query, _) {
                        final filtered = _filteredTeachers;
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (selected != null) ...[
                                    _buildScheduleCard(selected, cs, l),
                                    const SizedBox(height: 14),
                                  ],
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      4,
                                      2,
                                      4,
                                      8,
                                    ),
                                    child: Text(
                                      filtered.isEmpty
                                          ? l.teacherSearchNoMatch
                                          : l.teacherSearchResults(
                                              filtered.length,
                                            ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            final teacher = filtered[index - 1];
                            return Card(
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
                            );
                          },
                        );
                      },
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
    final schedule = _preparedSchedule;
    final lessons = schedule.on(_selectedDay);
    final locale = l.localeName;
    final weekEnd = _weekStart.add(const Duration(days: 6));
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
                Icon(Icons.calendar_view_week_rounded, color: colors.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l.teacherSearchTimetableNote,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  tooltip: l.teacherWeekPrevious,
                  onPressed: () => unawaited(_changeWeek(-1)),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '${DateFormat.MMMd(locale).format(_weekStart)} – ${DateFormat.yMMMd(locale).format(weekEnd)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: l.teacherWeekNext,
                  onPressed: () => unawaited(_changeWeek(1)),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final day in List.generate(
                  7,
                  (index) => _weekStart.add(Duration(days: index)),
                ))
                  ChoiceChip(
                    label: Text(
                      '${DateFormat.E(locale).format(day)} ${day.day}'
                      '${_loadingSchedule ? '' : ' · ${schedule.on(day).length}'}',
                    ),
                    selected: day == _selectedDay,
                    onSelected: (_) {
                      AppHaptics.selection();
                      setState(() => _selectedDay = day);
                    },
                  ),
              ],
            ),
            if (_loadingSchedule) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ] else if (_scheduleError != null) ...[
              const SizedBox(height: 14),
              Text(_scheduleError!, style: TextStyle(color: colors.error)),
            ] else ...[
              const SizedBox(height: 14),
              if (lessons.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l.teacherWeekNoLessons,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              for (final hour in _visibleHours(lessons))
                _hourRow(hour, lessons, colors, l),
            ],
          ],
        ),
      ),
    );
  }

  Iterable<int> _visibleHours(List<TeacherLessonLocation> lessons) sync* {
    if (lessons.isEmpty) return;
    final first = lessons.first.startMinute ~/ 60;
    final last =
        (lessons.map((e) => e.endMinute).reduce((a, b) => a > b ? a : b) - 1) ~/
        60;
    for (var hour = first; hour <= last; hour++) {
      yield hour;
    }
  }

  Widget _hourRow(
    int hour,
    List<TeacherLessonLocation> lessons,
    ColorScheme colors,
    AppL10n l,
  ) {
    final starting = lessons.where((e) => e.startMinute ~/ 60 == hour).toList();
    final ongoing = lessons.any(
      (e) => e.startMinute < hour * 60 && e.endMinute > hour * 60,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: starting.isEmpty
                ? Container(
                    constraints: const BoxConstraints(minHeight: 38),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: Text(
                      ongoing ? l.teacherWeekContinues : l.teacherWeekFree,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (final lesson in starting)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(
                              _expressiveRadius(
                                context,
                                14,
                                expressiveRadius: 24,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${lesson.startTime}–${lesson.endTime}',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: colors.onPrimaryContainer,
                                    ),
                              ),
                              Text(
                                lesson.subject.isEmpty
                                    ? l.teacherWeekLesson
                                    : lesson.subject,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              if (lesson.room.isNotEmpty)
                                Text(
                                  lesson.room,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
