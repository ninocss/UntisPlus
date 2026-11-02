part of '../main.dart';

class _RectTargetTween extends Tween<Rect> {
  _RectTargetTween({required Rect begin, required Rect end})
    : super(begin: begin, end: end);

  @override
  Rect lerp(double t) => Rect.lerp(begin!, end!, t)!;
}

// --- HAUPT NAVIGATION ---
class MainNavigationScreen extends StatefulWidget {
  final bool showTutorialOnStart;

  const MainNavigationScreen({super.key, this.showTutorialOnStart = false});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class AiAssistantPage extends StatefulWidget {
  final VoidCallback? onBackToTimetable;
  final void Function(Widget)? onOpenDrawer;

  const AiAssistantPage({super.key, this.onBackToTimetable, this.onOpenDrawer});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage>
    with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final FocusNode _promptFocusNode = FocusNode();
  late TabController _tabController;
  Timer? _streamRenderTimer;
  final StringBuffer _pendingStreamText = StringBuffer();
  final ValueNotifier<int> _streamRevision = ValueNotifier(0);
  final ValueNotifier<bool> _showChatJump = ValueNotifier(false);
  final ChatFollowState _chatFollow = ChatFollowState();
  bool get _followChat => _chatFollow.shouldFollow;
  bool _chatScrollQueued = false;
  int _searchGeneration = 0;
  AiRequestCancellation? _activeRequest;
  String _latestQuery = '';
  AiSearchResult? _latestResult;
  List<Map<String, dynamic>> _exams = [];
  Map<int, List<dynamic>> _weekData = {
    0: <dynamic>[],
    1: <dynamic>[],
    2: <dynamic>[],
    3: <dynamic>[],
    4: <dynamic>[],
  };
  DateTime _currentMonday = DateTime.now();
  bool _hasWeekData = false;
  bool _weekIsCached = false;
  List<TimetableChange> _contextChanges = const [];
  bool _loading = true;
  bool _thinking = false;
  bool _chatMode = false;
  final List<Map<String, String>> _chatMessages = [];
  final List<AiChatAttachment> _attachments = [];
  final List<AiChatSession> _chatHistory = [];
  String? _currentChatId;
  int _aiGreetingIndex = math.Random().nextInt(5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      animationDuration: Duration.zero,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final chatMode = _tabController.index == 1;
        if (_chatMode != chatMode && mounted) {
          setState(() => _chatMode = chatMode);
        }
        if (_chatMode) {
          _scrollToBottom();
        }
      }
    });
    _loadContext();
    _loadChatHistory();
    pendingAssistantPromptNotifier.addListener(_consumeNativeAssistantPrompt);
    hiddenSubjectsNotifier.addListener(_reloadContextForHiddenSubjects);
    // A native assistant request can arrive before this widget is built, in
    // which case no change event reaches the listener above. Consume any value
    // that is already waiting after the first frame.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _consumeNativeAssistantPrompt(),
    );
    _promptFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// A prompt received while the schedule/exam context is still loading. It is
  /// delivered as soon as [_loadContext] finishes so the assistant has data.
  String? _deferredAssistantPrompt;

  void _consumeNativeAssistantPrompt() {
    final raw = pendingAssistantPromptNotifier.value;
    pendingAssistantPromptNotifier.value = null;
    final prompt = normalizedAssistantPrompt(raw);
    if (!mounted || prompt == null || prompt.isEmpty) return;
    if (_deferredAssistantPrompt == prompt) return;
    _deferredAssistantPrompt = prompt;
    _deliverDeferredAssistantPrompt();
  }

  void _deliverDeferredAssistantPrompt() {
    if (!mounted) return;
    if (_loading) return;
    final prompt = _deferredAssistantPrompt;
    if (prompt == null) return;
    _deferredAssistantPrompt = null;
    _inputController.text = prompt;
    _send();
  }

  void _reloadContextForHiddenSubjects() {
    unawaited(_loadContext());
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = SettingsStore.instance.preferences;
      final sessions = AiChatHistoryStore(prefs).read();
      if (!mounted) return;
      setState(() {
        _chatHistory
          ..clear()
          ..addAll(sessions);
      });
    } catch (_) {}
  }

  Future<void> _saveChatHistory() async {
    if (_currentChatId != null) {
      final idx = _chatHistory.indexWhere((s) => s.id == _currentChatId);
      if (idx != -1) {
        if (!identical(_chatHistory[idx].messages, _chatMessages)) {
          _chatHistory[idx].messages.clear();
          _chatHistory[idx].messages.addAll(_chatMessages);
        }
      }
    }
    try {
      final prefs = SettingsStore.instance.preferences;
      await AiChatHistoryStore(prefs).write(_chatHistory);
    } catch (_) {}
  }

  void _startNewChat() {
    _cancelActiveRequest();
    setState(() {
      _currentChatId = null;
      _chatMessages.clear();
      _latestResult = null;
      _latestQuery = '';
      _chatMode = true;
      final nextGreeting = math.Random().nextInt(5);
      _aiGreetingIndex = nextGreeting == _aiGreetingIndex
          ? (nextGreeting + 1) % 5
          : nextGreeting;
    });
    _selectAiTab(1, haptic: false);
    _hapticAction();
    // Check if we are inside a drawer (Navigator.canPop is true in drawers)
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _loadSession(AiChatSession session) {
    _cancelActiveRequest();
    setState(() {
      _currentChatId = session.id;
      _chatMessages.clear();
      _chatMessages.addAll(session.messages);
      _chatMode = true;
      _latestResult = null;
    });
    _selectAiTab(1, haptic: false);
    _hapticSelection();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _activeRequest?.cancel();
    _searchGeneration++;
    pendingAssistantPromptNotifier.removeListener(
      _consumeNativeAssistantPrompt,
    );
    hiddenSubjectsNotifier.removeListener(_reloadContextForHiddenSubjects);
    _tabController.dispose();
    _promptFocusNode.dispose();
    _streamRenderTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _streamRevision.dispose();
    _showChatJump.dispose();
    super.dispose();
  }

  void _resetSearchState() {
    _thinking = false;
    _latestQuery = '';
    _latestResult = null;
  }

  void _hapticSelection() {
    unawaited(AppHaptics.selection());
  }

  void _hapticAction() {
    unawaited(AppHaptics.confirmation());
  }

  void _selectAiTab(int index, {bool haptic = true}) {
    final chatMode = index == 1;
    final changed = _chatMode != chatMode;
    if (changed) _cancelActiveRequest();
    if (changed && mounted) {
      setState(() => _chatMode = chatMode);
      if (haptic) _hapticSelection();
    }
    if (_tabController.index != index) {
      _tabController.animateTo(index, duration: Duration.zero);
    }
    if (chatMode) _scrollToBottom();
  }

  AiSearchResult _parseSearchResult({
    required String query,
    required String reply,
  }) {
    return parseAiSearchResult(
      query: query,
      reply: reply,
      emptyHeadline: appL10nFor(appLocaleNotifier.value).aiNewSearch,
    );
  }

  Map<int, List<dynamic>> _emptyWeekData() => {
    0: <dynamic>[],
    1: <dynamic>[],
    2: <dynamic>[],
    3: <dynamic>[],
    4: <dynamic>[],
  };

  Map<int, List<dynamic>> _decodeWeek(Map<dynamic, dynamic> week) {
    final tempWeek = _emptyWeekData();
    for (var i = 0; i < 5; i++) {
      final dayRaw = week['$i'];
      if (dayRaw is! List) continue;
      tempWeek[i] = dayRaw
          .whereType<Map>()
          .map(
            (lesson) =>
                Map<String, dynamic>.from(lesson.cast<String, dynamic>()),
          )
          .toList();
    }
    tempWeek.forEach((_, list) {
      list.sort((a, b) {
        final aStart = (a['startTime'] as int?) ?? 0;
        final bStart = (b['startTime'] as int?) ?? 0;
        return aStart.compareTo(bStart);
      });
    });
    return tempWeek;
  }

  List<dynamic> _todayLessons() {
    final index = DateTime.now().weekday - 1;
    if (index < 0 || index > 4) return const [];
    return _weekData[index] ?? const [];
  }

  bool get _hasTodayLessons => _todayLessons().isNotEmpty;

  bool get _hasCancellations => _todayLessons().whereType<Map>().any((lesson) {
    final map = lesson.cast<dynamic, dynamic>();
    return (map['code'] ?? '') == 'cancelled';
  });

  bool get _hasUpcomingExams {
    final monday = DateTime(
      _currentMonday.year,
      _currentMonday.month,
      _currentMonday.day,
    );
    final friday = monday.add(const Duration(days: 4));
    final mondayStamp = untisDateInt(monday);
    final fridayStamp = untisDateInt(friday);

    return _exams.any((ex) {
      final raw = (ex['date'] ?? ex['examDate'] ?? ex['startDate'] ?? '')
          .toString();
      final stamp = int.tryParse(raw);
      return stamp != null && stamp >= mondayStamp && stamp <= fridayStamp;
    });
  }

  bool get _isBeforeSchool {
    final lessons = _todayLessons().whereType<Map>().toList();
    if (lessons.isEmpty) return false;
    final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
    final firstStart = lessons
        .map(
          (lesson) => int.tryParse(lesson['startTime']?.toString() ?? '') ?? 0,
        )
        .where((value) => value > 0)
        .fold<int?>(
          null,
          (min, value) => min == null || value < min ? value : min,
        );
    return firstStart != null && nowMin < _toMinutes(firstStart);
  }

  bool get _isDuringSchool {
    final lessons = _todayLessons().whereType<Map>().toList();
    if (lessons.isEmpty) return false;
    final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
    for (final lesson in lessons) {
      final map = lesson.cast<dynamic, dynamic>();
      final start = _toMinutes((map['startTime'] as int?) ?? 800);
      final end = _toMinutes((map['endTime'] as int?) ?? 845);
      if (nowMin >= start && nowMin <= end) return true;
    }
    return false;
  }

  bool get _isAfterSchool {
    final lessons = _todayLessons().whereType<Map>().toList();
    if (lessons.isEmpty) return false;
    final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
    final lastEnd = lessons
        .map((lesson) => int.tryParse(lesson['endTime']?.toString() ?? '') ?? 0)
        .where((value) => value > 0)
        .fold<int?>(
          null,
          (max, value) => max == null || value > max ? value : max,
        );
    return lastEnd != null && nowMin > _toMinutes(lastEnd);
  }

  Future<void> _loadContext() async {
    final contextAccountId = activeUntisAccountId ?? 'legacy';
    final now = DateTime.now();
    final monday = resolveDefaultTimetableMonday(now);

    // The timetable tab is the source of truth while it is alive. Reading its
    // published snapshot avoids an outdated SharedPreferences cache claiming
    // that a currently loaded school day is free.
    Map<int, List<dynamic>> weekData = _emptyWeekData();
    bool hasWeekData = false;
    bool weekIsCached = false;
    List<TimetableChange> changes = const [];
    List<Map<String, dynamic>> exams = [];

    if (demoModeNotifier.value) {
      weekData = DemoModeService.buildWeek(
        monday,
        locale: appLocaleNotifier.value,
      );
      exams = DemoModeService.demoExams(locale: appLocaleNotifier.value);
      hasWeekData = true;
    } else {
      try {
        final prefs = SettingsStore.instance.preferences;
        final raw = prefs.getString(
          [
            'weekCacheV1',
            schoolUrl,
            schoolName,
            personType.toString(),
            personId.toString(),
            untisDateString(monday),
          ].join('|'),
        );
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            final week = decoded['weekData'];
            if (week is Map) {
              weekData = _decodeWeek(week.cast<dynamic, dynamic>());
              hasWeekData = true;
              weekIsCached = true;
            }
          }
        }

        final customExams = _decodeStoredMapList(
          prefs.getStringList(_accountDataKey('customExams')) ?? const [],
        );

        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 365));
        exams = await _webUntisExamRepository.fetch(
          context: WebUntisRequestContext(
            schoolUrl: schoolUrl,
            schoolName: schoolName,
            sessionId: sessionID,
          ),
          personId: personId,
          start: start,
          end: end,
        );
        exams = [
          ...exams.map((e) => {...e, '_source': 'api'}),
          ...customExams.map((e) => {...e, '_source': 'custom'}),
        ];
      } catch (_) {}
      try {
        changes = await ChangeRepository().loadChanges(contextAccountId);
      } catch (_) {}
    }

    final liveMonday = currentWeekMondayNotifier.value;
    if (liveMonday != null &&
        liveMonday.year == monday.year &&
        liveMonday.month == monday.month &&
        liveMonday.day == monday.day &&
        currentWeekDataNotifier.value.isNotEmpty) {
      weekData = Map<int, List<dynamic>>.from(currentWeekDataNotifier.value);
      hasWeekData = true;
      weekIsCached = currentWeekIsCachedNotifier.value;
    }

    final hiddenSubjectAliases = <String>{};
    for (final lesson in weekData.values.expand((lessons) => lessons)) {
      if (!_isLessonSubjectHidden(lesson) || lesson is! Map) continue;
      hiddenSubjectAliases
        ..add(_normalizedSubjectName(lesson['_subjectShort']))
        ..add(_normalizedSubjectName(lesson['_subjectLong']));
    }
    hiddenSubjectAliases.remove('');
    final visibleWeekData = <int, List<dynamic>>{
      for (final entry in weekData.entries)
        entry.key: entry.value
            .where((lesson) => !_isLessonSubjectHidden(lesson))
            .toList(growable: false),
    };
    exams = exams
        .where((exam) {
          final subject = exam['subject'] ?? exam['name'] ?? '';
          return !_isSubjectHidden(subject) &&
              !hiddenSubjectAliases.contains(_normalizedSubjectName(subject));
        })
        .toList(growable: true);
    exams.sort((a, b) {
      final da =
          int.tryParse(
            (a['date'] ?? a['examDate'] ?? a['startDate'] ?? 0).toString(),
          ) ??
          0;
      final db =
          int.tryParse(
            (b['date'] ?? b['examDate'] ?? b['startDate'] ?? 0).toString(),
          ) ??
          0;
      return da.compareTo(db);
    });

    if (!mounted || contextAccountId != (activeUntisAccountId ?? 'legacy')) {
      return;
    }
    setState(() {
      _currentMonday = monday;
      _weekData = visibleWeekData;
      _exams = exams;
      _contextChanges = changes;
      _hasWeekData = hasWeekData;
      _weekIsCached = weekIsCached;
      _loading = false;
    });
    // A native assistant prompt may have arrived while the context was still
    // loading; send it now that the timetable/exam data is available.
    _deliverDeferredAssistantPrompt();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(_buildBouncyRoute(const SettingsAiPage()));
    if (mounted) setState(() {});
  }

  Future<void> _openPromptEditor() async {
    await Navigator.of(
      context,
    ).push(_buildBouncyRoute(const SettingsAiPage(openPromptEditor: true)));
  }

  Future<void> _clearCurrentResult() async {
    setState(() {
      _resetSearchState();
    });
  }

  String _resolvedSystemPrompt() {
    final l = appL10nFor(appLocaleNotifier.value);
    final template = aiSystemPromptTemplate.trim().isNotEmpty
        ? aiSystemPromptTemplate
        : _buildDefaultAiPromptTemplate(l);
    final friday = _currentMonday.add(const Duration(days: 4));
    final vars = <String, String>{
      '[today]': DateFormat(
        'EEEE, dd. MMMM yyyy',
        _icuLocale(appLocaleNotifier.value),
      ).format(DateTime.now()),
      '[today_iso]': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      '[locale]': appLocaleNotifier.value,
      '[school_name]': schoolName.isEmpty ? '-' : schoolName,
      '[school_url]': schoolUrl.isEmpty ? '-' : schoolUrl,
      '[person_type]': '$personType',
      '[person_id]': '$personId',
      '[demo_mode]': '${demoModeNotifier.value}',
      '[current_monday]': DateFormat('dd.MM.yyyy').format(_currentMonday),
      '[current_friday]': DateFormat('dd.MM.yyyy').format(friday),
      '[day_summary_today]': _daySummaryForPrompt(DateTime.now()),
      '[day_summary_tomorrow]': _daySummaryForPrompt(
        DateTime.now().add(const Duration(days: 1)),
      ),
      '[timetable]': _hasWeekData
          ? _formatWeekForAi(_weekData, _currentMonday)
          : l.aiDayDataUnavailable(
              DateFormat('dd.MM.yyyy').format(DateTime.now()),
            ),
      '[timetable_json]': _hasWeekData
          ? jsonEncode(_jsonSafeValue(_weekData))
          : '{}',
      '[exams]': _formatExamsForAi(),
      '[exams_json]': jsonEncode(_jsonSafeValue(_exams)),
      '[current_lesson]': _currentLessonSummary(),
      '[next_lesson]': _nextLessonSummary(),
    };

    var resolved = template;
    final entries = vars.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in entries) {
      resolved = resolved.replaceAll(entry.key, entry.value);
    }
    return '''$resolved

VERIFIZIERTER TAGESKONTEXT:
${_dayContextForPrompt(DateTime.now())}
${_dayContextForPrompt(DateTime.now().add(const Duration(days: 1)))}
Nutze nur belegte Schuldaten. Erfinde keine Stunden, Aufgaben, Fristen oder Änderungen.

${l.aiResponseFormat}''';
  }

  String _resolvedChatSystemPrompt() {
    final l = appL10nFor(appLocaleNotifier.value);
    final template = aiSystemPromptTemplate.trim().isNotEmpty
        ? aiSystemPromptTemplate
        : _buildDefaultAiPromptTemplate(l);
    final friday = _currentMonday.add(const Duration(days: 4));
    final vars = <String, String>{
      '[today]': DateFormat(
        'EEEE, dd. MMMM yyyy',
        _icuLocale(appLocaleNotifier.value),
      ).format(DateTime.now()),
      '[today_iso]': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      '[locale]': appLocaleNotifier.value,
      '[school_name]': schoolName.isEmpty ? '-' : schoolName,
      '[school_url]': schoolUrl.isEmpty ? '-' : schoolUrl,
      '[person_type]': '$personType',
      '[person_id]': '$personId',
      '[demo_mode]': '${demoModeNotifier.value}',
      '[current_monday]': DateFormat('dd.MM.yyyy').format(_currentMonday),
      '[current_friday]': DateFormat('dd.MM.yyyy').format(friday),
      '[day_summary_today]': _daySummaryForPrompt(DateTime.now()),
      '[day_summary_tomorrow]': _daySummaryForPrompt(
        DateTime.now().add(const Duration(days: 1)),
      ),
      '[timetable]': _hasWeekData
          ? _formatWeekForAi(_weekData, _currentMonday)
          : l.aiDayDataUnavailable(
              DateFormat('dd.MM.yyyy').format(DateTime.now()),
            ),
      '[timetable_json]': _hasWeekData
          ? jsonEncode(_jsonSafeValue(_weekData))
          : '{}',
      '[exams]': _formatExamsForAi(),
      '[exams_json]': jsonEncode(_jsonSafeValue(_exams)),
      '[current_lesson]': _currentLessonSummary(),
      '[next_lesson]': _nextLessonSummary(),
    };

    var resolved = template;
    final entries = vars.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in entries) {
      resolved = resolved.replaceAll(entry.key, entry.value);
    }

    String personaInstruction = '';
    switch (aiPersona) {
      case 'strict':
        personaInstruction = l.aiPersonaStrict;
        break;
      case 'buddy':
        personaInstruction = l.aiPersonaBuddy;
        break;
      case 'helpful':
      default:
        personaInstruction = l.aiPersonaHelpful;
        break;
    }

    return '''$resolved

VERIFIZIERTER TAGESKONTEXT:
${_dayContextForPrompt(DateTime.now())}
${_dayContextForPrompt(DateTime.now().add(const Duration(days: 1)))}
Nutze nur belegte Schuldaten. Falls Daten fehlen oder gespeichert statt aktuell sind, sage das klar. Erfinde keine Stunden, Aufgaben, Fristen oder Änderungen.

${l.aiAssistantIntro}
$personaInstruction
${l.aiAssistantRules}''';
  }

  Future<String> _requestProviderResponse(
    String systemPrompt, {
    required String userQuery,
    AiRequestCancellation? cancellation,
  }) async {
    final l = appL10nFor(appLocaleNotifier.value);
    await _ensureAiConfigurationReady();
    final runtime = _currentAiRuntimeConfiguration();
    final provider = _aiRequestCoordinator.normalizeProvider(runtime.provider);
    return _aiRequestCoordinator.generate(
      runtime: runtime,
      cancellation: cancellation,
      spec: AiRequestSpec(
        systemPrompt: systemPrompt,
        userPrompt: userQuery,
        temperature: 0.2,
        maxTokens: 2600,
        topP: aiTopP,
        noReplyMessage: l.aiNoReply,
        missingApiKeyMessage: _providerAwareMissingApiKeyMessage(l, provider),
        customBaseUrlMissingMessage: l.aiCustomBaseUrlMissing,
        localModelMissingMessage: l.aiLocalModelLoadError,
      ),
    );
  }

  Future<void> _refreshChatDayContext() async {
    final accountId = activeUntisAccountId ?? 'legacy';
    final today = DateTime.now();
    final monday = resolveDefaultTimetableMonday(today);
    if (_currentMonday.year != monday.year ||
        _currentMonday.month != monday.month ||
        _currentMonday.day != monday.day) {
      await _loadContext();
    }
    final liveMonday = currentWeekMondayNotifier.value;
    if (liveMonday != null &&
        liveMonday.year == monday.year &&
        liveMonday.month == monday.month &&
        liveMonday.day == monday.day &&
        currentWeekDataNotifier.value.isNotEmpty) {
      _weekData = {
        for (final entry in currentWeekDataNotifier.value.entries)
          entry.key: entry.value
              .where((lesson) => !_isLessonSubjectHidden(lesson))
              .toList(growable: false),
      };
      _hasWeekData = true;
      _weekIsCached = currentWeekIsCachedNotifier.value;
    }
    if (demoModeNotifier.value) return;
    try {
      final changes = await ChangeRepository().loadChanges(accountId);
      if (mounted && accountId == (activeUntisAccountId ?? 'legacy')) {
        _contextChanges = changes;
      }
    } catch (_) {}
  }

  String _dayContextForPrompt(DateTime date) {
    final index = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(_currentMonday).inDays;
    final label = DateFormat('dd.MM.yyyy').format(date);
    if (!_hasWeekData || index < 0 || index > 4) {
      return '$label: Schuldaten nicht verfügbar.';
    }
    final snapshot = DayContextSnapshot.build(
      accountId: activeUntisAccountId ?? 'legacy',
      date: date,
      dataState: _weekIsCached ? DayDataState.cached : DayDataState.current,
      lessons: _weekData[index] ?? const [],
      homework: [...homeworksNotifier.value, ...customHomeworkNotifier.value],
      changes: _contextChanges,
      hiddenSubjects: hiddenSubjectsNotifier.value,
    );
    final lines = <String>[
      '$label (${_weekIsCached ? 'gespeicherter Stand, Aktualität unklar' : 'geladener Stand'}):',
      'Offene Aufgaben mit Fälligkeit in den nächsten zwei Tagen: ${snapshot.dueHomework.length}',
      for (final task in snapshot.dueHomework.take(6))
        '- ${task['subject'] ?? '?'}: ${task['text'] ?? task['description'] ?? ''} (Fälligkeit ${task['dueDate'] ?? task['date']})',
      'Stundenplanänderungen: ${snapshot.changes.length}',
      for (final change in snapshot.changes.take(6))
        '- ${change.type.name} ${change.subject}: ${change.before ?? '–'} → ${change.after ?? '–'}',
    ];
    return lines.join('\n');
  }

  String _daySummaryForPrompt(DateTime date) {
    final l = appL10nFor(appLocaleNotifier.value);
    final index = date.difference(_currentMonday).inDays;
    final dateLabel = DateFormat('dd.MM.yyyy').format(date);
    if (!_hasWeekData || index < 0 || index > 4) {
      return l.aiDayDataUnavailable(dateLabel);
    }

    final lessons = _weekData[index] ?? const [];
    if (lessons.isEmpty) return '$dateLabel: ${l.noLesson}';

    final buf = StringBuffer('$dateLabel:\n');
    for (final lsn in lessons.whereType<Map>()) {
      final lesson = lsn.cast<dynamic, dynamic>();
      final start = _formatUntisTime(lesson['startTime'].toString());
      final end = _formatUntisTime(lesson['endTime'].toString());
      final subj = lesson['_subjectLong']?.toString().isNotEmpty == true
          ? lesson['_subjectLong'].toString()
          : lesson['_subjectShort']?.toString() ?? '?';
      final room = lesson['_room']?.toString() ?? '';
      final cancelled = (lesson['code'] ?? '') == 'cancelled';
      buf.write('- $start-$end $subj');
      if (room.isNotEmpty) buf.write(' (${l.detailRoom} $room)');
      if (cancelled) buf.write(' [${l.detailCancelled}]');
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  String? _deterministicScheduleReply(String query) {
    final normalized = query.toLowerCase();
    final asksSchedule = RegExp(
      r'unterricht|stunde|stundenplan|schule|lesson|school|class',
    ).hasMatch(normalized);
    if (!asksSchedule) return null;
    final asksTomorrow = RegExp(
      r'\bmorgen\b|\btomorrow\b',
    ).hasMatch(normalized);
    final asksToday = RegExp(r'\bheute\b|\btoday\b').hasMatch(normalized);
    if (!asksTomorrow && !asksToday) return null;
    final date = DateTime.now().add(
      asksTomorrow ? const Duration(days: 1) : Duration.zero,
    );
    final index = date.difference(_currentMonday).inDays;
    final label = DateFormat(
      'EEEE, dd.MM.',
      _icuLocale(appLocaleNotifier.value),
    ).format(date);
    if (!_hasWeekData || index < 0 || index > 4) {
      return appL10nFor(appLocaleNotifier.value).aiWeekDataUnavailable(label);
    }
    final lessons = (_weekData[index] ?? const <dynamic>[])
        .whereType<Map>()
        .where(
          (lesson) => lesson['code']?.toString().toLowerCase() != 'cancelled',
        )
        .toList(growable: false);
    if (lessons.isEmpty) {
      final reply = appL10nFor(
        appLocaleNotifier.value,
      ).aiNoScheduledLessons(label);
      return _weekIsCached
          ? '${_studentCopy(de: 'Gespeicherter Stand, Aktualität unklar.', en: 'Saved data; freshness unknown.', fr: 'Données enregistrées, actualité incertaine.', es: 'Datos guardados; vigencia incierta.')}\n$reply'
          : reply;
    }
    final formatted = lessons
        .map((lesson) {
          final subject =
              lesson['_subjectLong'] ?? lesson['_subjectShort'] ?? '?';
          return '${_formatUntisTime(lesson['startTime'].toString())} $subject';
        })
        .join(', ');
    final reply = appL10nFor(
      appLocaleNotifier.value,
    ).aiScheduleReply(label, formatted);
    return _weekIsCached
        ? '${_studentCopy(de: 'Gespeicherter Stand, Aktualität unklar.', en: 'Saved data; freshness unknown.', fr: 'Données enregistrées, actualité incertaine.', es: 'Datos guardados; vigencia incierta.')}\n$reply'
        : reply;
  }

  Object? _jsonSafeValue(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is List) return value.map(_jsonSafeValue).toList();
    if (value is Map) {
      final out = <String, Object?>{};
      value.forEach((key, entryValue) {
        out[key.toString()] = _jsonSafeValue(entryValue);
      });
      return out;
    }
    return value.toString();
  }

  String _currentLessonSummary() {
    final l = appL10nFor(appLocaleNotifier.value);
    final now = DateTime.now();
    final todayIdx = now.weekday - 1;
    if (todayIdx < 0 || todayIdx > 4) return l.aiNoSchoolToday;
    final lessons = _weekData[todayIdx] ?? [];
    final nowMin = now.hour * 100 + now.minute;
    for (final lsn in lessons.whereType<Map>()) {
      final start = (lsn['startTime'] as int?) ?? 0;
      final end = (lsn['endTime'] as int?) ?? 0;
      if (nowMin >= start && nowMin <= end) {
        final subj = lsn['_subjectLong'] ?? lsn['_subjectShort'] ?? '?';
        final room = lsn['_room'] ?? '-';
        return l.aiCurrentLessonSummary(
          subj.toString(),
          room.toString(),
          _formatUntisTime(end.toString()),
        );
      }
    }
    return l.aiNoCurrentLesson;
  }

  String _nextLessonSummary() {
    final l = appL10nFor(appLocaleNotifier.value);
    final now = DateTime.now();
    final todayIdx = now.weekday - 1;
    if (todayIdx < 0 || todayIdx > 4) {
      return l.aiNoNextLessonSchool;
    }
    final lessons = _weekData[todayIdx] ?? [];
    final nowMin = now.hour * 100 + now.minute;
    for (final lsn in lessons.whereType<Map>()) {
      final start = (lsn['startTime'] as int?) ?? 0;
      if (start > nowMin) {
        final subj = lsn['_subjectLong'] ?? lsn['_subjectShort'] ?? '?';
        final room = lsn['_room'] ?? '-';
        return l.aiNextLessonSummary(
          subj.toString(),
          room.toString(),
          _formatUntisTime(start.toString()),
        );
      }
    }
    return l.aiNoMoreLessons;
  }

  String _formatExamsForAi() {
    final l = appL10nFor(appLocaleNotifier.value);
    final relevantExams = _exams
        .where(_examMatchesTimetable)
        .toList(growable: false);
    if (relevantExams.isEmpty) return l.examsNoneEntered;
    final buf = StringBuffer();
    for (final ex in relevantExams) {
      final subject = ex['subject'] ?? ex['subjectName'] ?? '?';
      final type = ex['type'] ?? l.aiDefaultExamType;
      final dateRaw = ex['date'] ?? ex['examDate'] ?? ex['startDate'];
      final parsedDate = parseUntisDate(dateRaw);
      final dateStr = parsedDate == null
          ? (dateRaw ?? '').toString()
          : DateFormat('dd.MM.yyyy').format(parsedDate);
      final name = ex['name'] ?? ex['text'] ?? '';
      buf.write('- $dateStr ($type): $subject');
      if (name.isNotEmpty) buf.write(' "$name"');
      buf.writeln();
    }
    return buf.toString();
  }

  bool _examMatchesTimetable(Map<String, dynamic> exam) {
    // Personal/API exams are already scoped to the active student. Imported
    // plans, however, must prove a teacher or class match before entering the
    // assistant context.
    if (exam['_source'] == 'api' || exam['_source'] == 'custom') return true;
    String normalized(Object? value) =>
        value?.toString().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9äöüß]'),
          '',
        ) ??
        '';
    final teacher = normalized(
      exam['teacher'] ?? exam['teacherName'] ?? exam['lehrer'],
    );
    final className = normalized(
      exam['class'] ?? exam['className'] ?? exam['klasse'],
    );
    if (teacher.isEmpty && className.isEmpty) return false;
    final lessons = _weekData.values.expand((day) => day).whereType<Map>();
    return lessons.any((lesson) {
      final lessonTeacher = normalized(lesson['_teacher']);
      final lessonClass = normalized(lesson['_classNames']);
      return (teacher.isNotEmpty && lessonTeacher.contains(teacher)) ||
          (className.isNotEmpty && lessonClass.contains(className));
    });
  }

  void _scrollToBottom({bool force = false, bool animated = true}) {
    if (!mounted || (!force && !_followChat) || _chatScrollQueued) return;
    _chatScrollQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatScrollQueued = false;
      if (!mounted ||
          !_scrollController.hasClients ||
          (!force && !_followChat)) {
        return;
      }
      final position = _scrollController.position;
      if (animated && AppMotion.enabled(context)) {
        unawaited(
          _scrollController.animateTo(
            position.maxScrollExtent,
            duration: AppMotion.duration(
              context,
              AppMotionTokens.standardEffects,
            ),
            curve: Curves.easeOutCubic,
          ),
        );
      } else {
        _scrollController.jumpTo(position.maxScrollExtent);
      }
    });
  }

  bool _onChatScroll(ScrollNotification notification) {
    if ((notification is ScrollStartNotification &&
            notification.dragDetails != null) ||
        (notification is UserScrollNotification &&
            notification.direction != ScrollDirection.idle)) {
      _chatFollow.beginUserScroll();
    } else if (notification is ScrollEndNotification ||
        (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle)) {
      _chatFollow.endScroll(notification.metrics.extentAfter);
    }
    _showChatJump.value = !_followChat;
    return false;
  }

  void _queueStreamingText(String chunk) {
    _pendingStreamText.write(chunk);
    _streamRenderTimer ??= Timer(
      const Duration(milliseconds: 48),
      _flushStreamingText,
    );
  }

  String _attachmentMimeType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'pdf' => 'application/pdf',
      'csv' => 'text/csv',
      'json' => 'application/json',
      'md' => 'text/markdown',
      _ => 'text/plain',
    };
  }

  Future<void> _pickAssistantAttachment() async {
    if (_thinking || _attachments.length >= 3) return;
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'png',
        'jpg',
        'jpeg',
        'webp',
        'gif',
        'txt',
        'md',
        'csv',
        'json',
      ],
    );
    final file = picked.singleOrNull;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return;
    if (bytes.length > 8 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appL10nFor(appLocaleNotifier.value).aiAttachmentTooLarge,
            ),
          ),
        );
      }
      return;
    }
    final mimeType = _attachmentMimeType(file.name);
    final textLike =
        mimeType.startsWith('text/') || mimeType == 'application/json';
    final excerpt = textLike
        ? utf8
              .decode(bytes, allowMalformed: true)
              .trim()
              .substring(
                0,
                math.min(
                  24000,
                  utf8.decode(bytes, allowMalformed: true).trim().length,
                ),
              )
        : '';
    setState(() {
      _attachments.add(
        AiChatAttachment(
          name: file.name,
          mimeType: mimeType,
          bytes: bytes,
          textExcerpt: excerpt,
        ),
      );
    });
  }

  Future<void> _applyActions(List<AiProposedAction> actions) async {
    for (final action in actions) {
      final date = action.date;
      switch (action.kind) {
        case 'create_homework':
        case 'update_homework':
          if (action.subject.isEmpty || action.text.isEmpty || date == null) {
            continue;
          }
          final current = List<Map<String, dynamic>>.from(
            customHomeworkNotifier.value,
          );
          final index = current.indexWhere(
            (item) => item['id']?.toString() == action.id,
          );
          final item = <String, dynamic>{
            'id': action.id.isEmpty
                ? 'hw_${DateTime.now().millisecondsSinceEpoch}'
                : action.id,
            'subject': action.subject,
            'text': action.text,
            'dueDate': date,
            'isDone': index >= 0 ? current[index]['isDone'] == true : false,
            '_custom': true,
          };
          if (index >= 0) {
            current[index] = item;
          } else {
            current.add(item);
          }
          await saveCustomHomework(current);
          break;
        case 'delete_homework':
          await saveCustomHomework(
            customHomeworkNotifier.value
                .where((item) => item['id']?.toString() != action.id)
                .toList(growable: false),
          );
          break;
        case 'complete_homework':
          final current = List<Map<String, dynamic>>.from(
            customHomeworkNotifier.value,
          );
          final index = current.indexWhere(
            (item) => item['id']?.toString() == action.id,
          );
          if (index >= 0) {
            current[index] = {...current[index], 'isDone': true};
            await saveCustomHomework(current);
          }
          break;
        case 'create_exam':
        case 'update_exam':
          if (action.subject.isEmpty || date == null) {
            continue;
          }
          final current = List<Map<String, dynamic>>.from(
            customExamsNotifier.value,
          );
          final index = current.indexWhere(
            (item) => item['id']?.toString() == action.id,
          );
          final item = <String, dynamic>{
            'id': action.id.isEmpty
                ? 'exam_${DateTime.now().millisecondsSinceEpoch}'
                : action.id,
            'subject': action.subject,
            'date': date,
            'description': action.text,
            'examType': action.data['examType']?.toString() ?? '',
            '_custom': true,
          };
          if (index >= 0) {
            current[index] = item;
          } else {
            current.add(item);
          }
          await saveCustomExams(current);
          break;
        case 'delete_exam':
          await saveCustomExams(
            customExamsNotifier.value
                .where((item) => item['id']?.toString() != action.id)
                .toList(growable: false),
          );
          break;
        case 'create_grade':
        case 'update_grade':
          final value = action.gradeValue;
          if (action.subject.isEmpty ||
              date == null ||
              value == null ||
              !value.isFinite ||
              !action.gradeWeight.isFinite ||
              action.gradeWeight <= 0) {
            continue;
          }
          final gradeDate = parseUntisDate(date);
          if (gradeDate == null) continue;
          final current = List<Map<String, dynamic>>.from(
            customGradesNotifier.value,
          );
          final index = current.indexWhere(
            (item) => item['id']?.toString() == action.id,
          );
          final item = <String, dynamic>{
            'id': action.id.isEmpty
                ? 'grade_${DateTime.now().millisecondsSinceEpoch}'
                : action.id,
            'subject': action.subject,
            'value': value,
            'weight': action.gradeWeight,
            'type': action.gradeType,
            'date': gradeDate.toIso8601String(),
          };
          if (index >= 0) {
            current[index] = item;
          } else {
            current.add(item);
          }
          await saveCustomGrades(current);
          break;
        case 'delete_grade':
          await saveCustomGrades(
            customGradesNotifier.value
                .where((item) => item['id']?.toString() != action.id)
                .toList(growable: false),
          );
          break;
      }
    }
  }

  Future<void> _confirmActions(List<AiProposedAction> actions) async {
    if (!mounted || actions.isEmpty) return;
    final l = appL10nFor(appLocaleNotifier.value);
    final approved = await showUntisDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.aiApplyChangesTitle),
        content: SingleChildScrollView(
          child: _AiActionConfirmationContent(actions: actions),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.apply),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await _applyActions(actions);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.aiChangesApplied)));
    }
  }

  void _flushStreamingText() {
    _streamRenderTimer?.cancel();
    _streamRenderTimer = null;
    if (!mounted || _pendingStreamText.isEmpty) return;
    final text = _pendingStreamText.toString();
    _pendingStreamText.clear();
    final lastIndex = _chatMessages.length - 1;
    if (lastIndex >= 0 && _chatMessages[lastIndex]['role'] == 'assistant') {
      final current = _chatMessages[lastIndex]['content'] ?? '';
      _chatMessages[lastIndex]['content'] = current + text;
      _streamRevision.value++;
    }
    _scrollToBottom(animated: false);
  }

  Future<void> _sendChat(String text, AiRequestCancellation request) async {
    _chatFollow.resume();
    _showChatJump.value = false;
    final requestAccountId = activeUntisAccountId ?? 'legacy';
    await _refreshChatDayContext();
    if (!mounted ||
        request.isCancelled ||
        requestAccountId != (activeUntisAccountId ?? 'legacy')) {
      return;
    }
    final l = appL10nFor(appLocaleNotifier.value);
    if (!await _prepareAiInteraction(context) ||
        !mounted ||
        request.isCancelled ||
        requestAccountId != (activeUntisAccountId ?? 'legacy')) {
      return;
    }
    final runtime = _currentAiRuntimeConfiguration();
    final provider = _aiRequestCoordinator.normalizeProvider(runtime.provider);
    final attachments = List<AiChatAttachment>.from(_attachments);
    final spec = AiRequestSpec(
      systemPrompt: _resolvedChatSystemPrompt(),
      userPrompt: text,
      noReplyMessage: l.aiNoReply,
      attachments: attachments,
      missingApiKeyMessage: _providerAwareMissingApiKeyMessage(l, provider),
      customBaseUrlMissingMessage: l.aiCustomBaseUrlMissing,
      localModelMissingMessage: l.aiLocalModelLoadError,
      unsupportedAttachmentMessage: (_) =>
          'Dieses lokale Modell kann nur Textdateien lesen. Nutze für Bilder oder PDFs einen passenden Remote-Anbieter.',
    );
    final factualReply = attachments.isEmpty
        ? _deterministicScheduleReply(text)
        : null;

    try {
      if (factualReply == null) _aiRequestCoordinator.validate(runtime, spec);
    } catch (e) {
      final message = e.toString();
      final isConfigError = message.contains('CONFIG:');
      final isApiError = message.contains('API:');
      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': isConfigError
              ? message.replaceFirst('Exception: CONFIG: ', '')
              : isApiError
              ? message.replaceFirst('Exception: API: ', '')
              : '${l.aiConnectionError} $e',
        });
      });
      return;
    }

    _inputController.clear();
    setState(() {
      _chatMessages.add({
        'role': 'user',
        'content': attachments.isEmpty
            ? text
            : '$text\n\n📎 ${attachments.map((attachment) => attachment.name).join(', ')}',
      });
      _thinking = true;
    });
    _hapticAction();

    if (_currentChatId == null) {
      _currentChatId = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() {
        _chatHistory.insert(
          0,
          AiChatSession(
            id: _currentChatId!,
            title: text.length > 30 ? '${text.substring(0, 27)}...' : text,
            messages: List<Map<String, String>>.from(_chatMessages),
            timestamp: DateTime.now(),
          ),
        );
      });
      _saveChatHistory();
    }
    _scrollToBottom();

    if (factualReply != null) {
      setState(() {
        _chatMessages.add({'role': 'assistant', 'content': factualReply});
        _thinking = false;
        _attachments.clear();
      });
      await _saveChatHistory();
      _scrollToBottom();
      return;
    }

    try {
      setState(() {
        _chatMessages.add({'role': 'assistant', 'content': ''});
      });

      final stream = _aiRequestCoordinator.stream(
        runtime: runtime,
        cancellation: request,
        spec: spec,
        history: _chatMessages.sublist(0, _chatMessages.length - 1),
      );

      await for (final chunk in stream) {
        if (!mounted ||
            request.isCancelled ||
            requestAccountId != (activeUntisAccountId ?? 'legacy')) {
          break;
        }
        _queueStreamingText(chunk);
      }
      if (!mounted || request.isCancelled) return;
      _flushStreamingText();
      final rawReply = _chatMessages.isNotEmpty
          ? _chatMessages.last['content'] ?? ''
          : '';
      final actions = parseUntisActions(rawReply);
      if (actions.isNotEmpty) {
        setState(() {
          _chatMessages.last['content'] = rawReply
              .replaceAll(
                RegExp(r'```untis-action\s*[\s\S]*?```', multiLine: true),
                '',
              )
              .trim();
        });
        await _confirmActions(actions);
      }
      _saveChatHistory();
    } catch (e) {
      if (!mounted || request.isCancelled) return;
      _flushStreamingText();
      final message = e.toString();
      final isApiError = message.contains('API:');
      final isConfigError = message.contains('CONFIG:');
      setState(() {
        if (_chatMessages.isNotEmpty &&
            _chatMessages.last['role'] == 'assistant') {
          final errorText = isConfigError
              ? message.replaceFirst('Exception: CONFIG: ', '')
              : isApiError
              ? '${l.aiApiError} ${message.replaceFirst('Exception: API: ', '')}'
              : '${l.aiConnectionError} $e';
          final current = _chatMessages.last['content'] ?? '';
          _chatMessages.last['content'] = current.isEmpty
              ? errorText
              : '$current\n\n$errorText';
        }
      });
    } finally {
      if (identical(_activeRequest, request)) {
        _flushStreamingText();
        if (mounted) {
          setState(() {
            _thinking = false;
            _attachments.clear();
          });
          _hapticSelection();
        }
        _scrollToBottom();
      }
    }
  }

  void _removeChatSession(AiChatSession session) {
    _hapticAction();
    setState(() {
      _chatHistory.removeWhere((entry) => entry.id == session.id);
      if (_currentChatId == session.id) {
        _currentChatId = null;
        _chatMessages.clear();
      }
    });
    unawaited(_saveChatHistory());
  }

  Widget _buildSidebar() {
    return _AiChatHistoryPanel(
      sessions: _chatHistory,
      selectedSessionId: _currentChatId,
      showResultActions:
          !_chatMode || _latestQuery.isNotEmpty || _latestResult != null,
      onNewChat: _startNewChat,
      onOpenSession: _loadSession,
      onDeleteSession: _removeChatSession,
      onSearchAgain: () {
        Navigator.pop(context);
        unawaited(_handleMenuAction('refresh'));
      },
      onClear: () {
        Navigator.pop(context);
        unawaited(_handleMenuAction('clear'));
      },
      onOpenPromptSettings: () {
        Navigator.pop(context);
        unawaited(_openPromptEditor());
      },
      onOpenAiSettings: () {
        Navigator.pop(context);
        unawaited(_openSettings());
      },
    );
  }

  void _cancelActiveRequest() {
    final request = _activeRequest;
    if (request == null) return;
    _flushStreamingText();
    request.cancel();
    _searchGeneration++;
    _activeRequest = null;
    final l = appL10nFor(appLocaleNotifier.value);
    setState(() {
      _thinking = false;
      if (_chatMode &&
          _chatMessages.isNotEmpty &&
          _chatMessages.last['role'] == 'assistant') {
        final partial = _chatMessages.last['content'] ?? '';
        _chatMessages.last['content'] = partial.isEmpty
            ? l.ux('aiCancelled')
            : '$partial\n\n${l.ux('aiCancelled')}';
        _streamRevision.value++;
        _attachments.clear();
      } else if (!_chatMode && _latestQuery.isNotEmpty) {
        _latestResult = _parseSearchResult(
          query: _latestQuery,
          reply: l.ux('aiCancelled'),
        );
        if (_inputController.text.isEmpty) _inputController.text = _latestQuery;
      }
    });
    unawaited(_saveChatHistory());
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _thinking || _activeRequest != null) return;
    final request = AiRequestCancellation();
    _activeRequest = request;
    final generation = ++_searchGeneration;
    setState(() => _thinking = true);
    try {
      if (_chatMode) {
        await _sendChat(text, request);
        return;
      }
      _inputController.clear();
      setState(() {
        _latestQuery = text;
        _latestResult = null;
      });
      try {
        final reply = await _requestProviderResponse(
          _resolvedSystemPrompt(),
          userQuery: text,
          cancellation: request,
        );
        if (!mounted || request.isCancelled || generation != _searchGeneration) {
          return;
        }
        setState(
          () => _latestResult = _parseSearchResult(query: text, reply: reply),
        );
      } catch (error) {
        if (!mounted || request.isCancelled || generation != _searchGeneration) {
          return;
        }
        final l = appL10nFor(appLocaleNotifier.value);
        final message = error.toString();
        final reply = message.contains('CONFIG:')
            ? message.replaceFirst('Exception: CONFIG: ', '')
            : message.contains('API:')
            ? '${l.aiApiError} ${message.replaceFirst('Exception: API: ', '')}'
            : '${l.aiConnectionError} $error';
        setState(
          () => _latestResult = _parseSearchResult(query: text, reply: reply),
        );
      }
    } finally {
      if (mounted && identical(_activeRequest, request)) {
        setState(() {
          _activeRequest = null;
          _thinking = false;
        });
      }
    }
  }

  Future<void> _sendQuickPrompt(String prompt) async {
    if (_thinking) return;
    _inputController.text = prompt;
    await _send();
  }

  List<String> _buildContextualChips() {
    final l = appL10nFor(appLocaleNotifier.value);
    final chips = <String>[l.aiSuggestions.first];
    if (_hasTodayLessons) chips.add(l.aiPromptWhenFinishToday);
    if (_hasCancellations) chips.add(l.aiPromptWhatCancelledToday);
    if (_hasUpcomingExams) chips.add(l.aiPromptUpcomingExams);
    if (_isBeforeSchool) chips.add(l.aiPromptFirstLessonToday);
    if (_isDuringSchool) chips.add(l.aiPromptNextLesson);
    if (_isAfterSchool) chips.add(l.aiPromptTomorrowSchedule);
    return chips.toSet().take(5).toList();
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'clear':
        _cancelActiveRequest();
        if (_chatMode) {
          setState(() => _chatMessages.clear());
        } else {
          await _clearCurrentResult();
        }
        break;
      case 'settings':
        await _openSettings();
        break;
      case 'prompt':
        await _openPromptEditor();
        break;
      case 'refresh':
        if (_latestQuery.trim().isNotEmpty) {
          await _sendQuickPrompt(_latestQuery);
        }
        break;
    }
  }

  IconData _metricIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('stunde') ||
        lower.contains('lesson') ||
        lower.contains('kurs')) {
      return Icons.school_rounded;
    }
    if (lower.contains('prüf') ||
        lower.contains('exam') ||
        lower.contains('test') ||
        lower.contains('klausur')) {
      return Icons.assignment_rounded;
    }
    if (lower.contains('raum') || lower.contains('room')) {
      return Icons.meeting_room_rounded;
    }
    if (lower.contains('lehrer') || lower.contains('teacher')) {
      return Icons.person_rounded;
    }
    if (lower.contains('frei') ||
        lower.contains('free') ||
        lower.contains('pause') ||
        lower.contains('break')) {
      return Icons.free_breakfast_rounded;
    }
    if (lower.contains('tag') ||
        lower.contains('day') ||
        lower.contains('heute')) {
      return Icons.today_rounded;
    }
    if (lower.contains('zeit') || lower.contains('time')) {
      return Icons.schedule_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  Widget _buildSearchLoadingState() {
    return _AiAnalysisLoadingState(query: _latestQuery);
  }

  Widget _buildSearchBar() {
    final l = appL10nFor(appLocaleNotifier.value);
    return _AiComposer(
      controller: _inputController,
      focusNode: _promptFocusNode,
      mode: _chatMode ? _AiMode.chat : _AiMode.analysis,
      thinking: _thinking,
      attachments: _attachments,
      hintText: _chatMode ? l.aiInputHint : l.aiSearchHintPlaceholder,
      onAttach: _chatMode && !_thinking
          ? () => unawaited(_pickAssistantAttachment())
          : null,
      onRemoveAttachment: (index) {
        if (_thinking || index < 0 || index >= _attachments.length) return;
        setState(() => _attachments.removeAt(index));
      },
      onSend: () => unawaited(_send()),
      onStop: _cancelActiveRequest,
      onClear: () => setState(_inputController.clear),
    );
  }

  Widget _buildResultHeader(ColorScheme cs) {
    final result = _latestResult;
    if (result == null) {
      if (_thinking) return _buildSearchLoadingState();
      return _buildEmptyState(cs);
    }

    return _AiAnalysisResult(
      result: result,
      thinking: _thinking,
      metricIcon: _metricIcon,
      onSearchAgain: () {
        final query = _latestQuery.trim();
        if (query.isNotEmpty) unawaited(_sendQuickPrompt(query));
      },
      onClear: () => unawaited(_clearCurrentResult()),
    );
  }

  Widget _buildChatView(ColorScheme cs) {
    if (_chatMessages.isEmpty && !_thinking) {
      return _buildEmptyState(cs);
    }

    String? activeTitle;
    if (_currentChatId != null) {
      for (final session in _chatHistory) {
        if (session.id == _currentChatId) {
          activeTitle = session.title;
          break;
        }
      }
    }

    final showExtraTyping =
        _thinking &&
        !(_chatMessages.isNotEmpty &&
            _chatMessages.last['role'] == 'assistant' &&
            (_chatMessages.last['content'] ?? '').isEmpty);

    final hasTitle = activeTitle != null && activeTitle.trim().isNotEmpty;
    final title = activeTitle;
    final headerCount = hasTitle ? 1 : 0;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onChatScroll,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            itemCount:
                headerCount + _chatMessages.length + (showExtraTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (hasTitle && index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 14),
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                );
              }
              final messageIndex = index - headerCount;
              if (messageIndex == _chatMessages.length) {
                return const _AiChatMessage(
                  content: '',
                  isUser: false,
                  streaming: true,
                );
              }
              Widget message() => _AiChatMessage(
                key: ValueKey('chat-message-$_currentChatId-$messageIndex'),
                content: _chatMessages[messageIndex]['content'] ?? '',
                isUser: _chatMessages[messageIndex]['role'] == 'user',
                streaming:
                    _thinking &&
                    messageIndex == _chatMessages.length - 1 &&
                    _chatMessages[messageIndex]['role'] == 'assistant',
              );
              if (messageIndex == _chatMessages.length - 1) {
                return ValueListenableBuilder<int>(
                  valueListenable: _streamRevision,
                  builder: (context, _, _) => message(),
                );
              }
              return message();
            },
          ),
        ),
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: ValueListenableBuilder<bool>(
            valueListenable: _showChatJump,
            builder: (context, visible, _) => visible
                ? Center(
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        _chatFollow.resume();
                        _showChatJump.value = false;
                        AppHaptics.selection();
                        _scrollToBottom(force: true);
                      },
                      icon: const Icon(Icons.arrow_downward_rounded),
                      label: Text(
                        appL10nFor(appLocaleNotifier.value).aiJumpToLatest,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ColorScheme cs) {
    final mode = _chatMode ? _AiMode.chat : _AiMode.analysis;
    final reduceMotion = _aiReduceMotion(context);

    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) {
              if (reduceMotion) {
                return FadeTransition(opacity: animation, child: child);
              }
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.985, end: 1).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(
                _chatMode
                    ? '${mode.name}_${_chatMessages.isEmpty && !_thinking}'
                    : mode.name,
              ),
              child: _chatMode ? _buildChatView(cs) : _buildResultHeader(cs),
            ),
          ),
        ),
        _buildSearchBar(),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    final l = appL10nFor(appLocaleNotifier.value);
    final analysisSuggestions = _buildContextualChips();
    const suggestionIcons = <IconData>[
      Icons.trending_up_rounded,
      Icons.lightbulb_outline_rounded,
      Icons.edit_note_rounded,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_chatMode) ...[
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 54, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primaryContainer.withValues(alpha: 0.72),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: cs.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l.aiGreetings[_aiGreetingIndex % l.aiGreetings.length],
                      textAlign: TextAlign.center,
                      style: untisThemeTextStyle(
                        context,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final prompt in [
                  _studentCopy(
                    de: 'Was habe ich morgen für Unterricht?',
                    en: 'What lessons do I have tomorrow?',
                    fr: 'Quels cours ai-je demain ?',
                    es: '¿Qué clases tengo mañana?',
                  ),
                  _studentCopy(
                    de: 'Plane meine bald fälligen Aufgaben.',
                    en: 'Help me plan my upcoming homework.',
                    fr: 'Aide-moi à planifier mes devoirs à venir.',
                    es: 'Ayúdame a planificar mis próximas tareas.',
                  ),
                  _studentCopy(
                    de: 'Erkläre mir die Änderungen für heute.',
                    en: 'Explain today’s timetable changes.',
                    fr: 'Explique les changements d’aujourd’hui.',
                    es: 'Explica los cambios de hoy.',
                  ),
                ])
                  _AiSuggestionCard(
                    compact: true,
                    text: prompt,
                    icon: Icons.auto_awesome_rounded,
                    onTap: () => unawaited(_sendQuickPrompt(prompt)),
                  ),
              ],
            ),
          ] else if (analysisSuggestions.isNotEmpty) ...[
            Text(
              l.aiTryIt,
              style: untisThemeTextStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in analysisSuggestions.indexed)
                  _AiSuggestionCard(
                    compact: true,
                    text: suggestion.$2,
                    icon:
                        suggestionIcons[suggestion.$1 % suggestionIcons.length],
                    onTap: () {
                      _hapticSelection();
                      unawaited(_sendQuickPrompt(suggestion.$2));
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);
    final mode = _chatMode ? _AiMode.chat : _AiMode.analysis;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _mainTabHeaderAppBar(
          context,
          l.aiTitle,
          bottom: _mainSectionTabBar(
            context,
            controller: _tabController,
            onTap: _selectAiTab,
            items: [
              (icon: Icons.analytics_rounded, label: l.aiTabAnalysis),
              (icon: Icons.chat_bubble_rounded, label: l.aiTabChat),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ThemedSurface(
                showShadow: false,
                borderRadius: BorderRadius.circular(_aiRadius(28)),
                color: cs.surfaceContainerHigh.withValues(alpha: 0.72),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: ExpressiveLoadingIndicator(
                          strokeWidth: 2.5,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l.aiAskAnything,
                          style: untisThemeTextStyle(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      appBar: _mainTabHeaderAppBar(
        context,
        l.aiTitle,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {
            _hapticSelection();
            widget.onOpenDrawer?.call(_buildSidebar());
          },
        ),
        bottom: _mainSectionTabBar(
          context,
          controller: _tabController,
          onTap: _selectAiTab,
          items: [
            (icon: Icons.analytics_rounded, label: l.aiTabAnalysis),
            (icon: Icons.chat_bubble_rounded, label: l.aiTabChat),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final body = Column(
            children: [
              _AiExecutionStatus(
                busy: _thinking,
                onSettings: () => unawaited(_openSettings()),
              ),
              Expanded(child: _buildBody(cs)),
            ],
          );
          if (!UntisLayout.isTablet(context)) return body;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _aiContentMaxWidth(context, mode),
              ),
              child: SizedBox(height: constraints.maxHeight, child: body),
            ),
          );
        },
      ),
    );
  }
}

class _MainTabTransitionLayer extends StatefulWidget {
  final bool active;
  final bool animate;
  final int relativePosition;
  final int transitionType;
  final Widget child;

  const _MainTabTransitionLayer({
    super.key,
    required this.active,
    required this.animate,
    required this.relativePosition,
    required this.transitionType,
    required this.child,
  });

  @override
  State<_MainTabTransitionLayer> createState() =>
      _MainTabTransitionLayerState();
}

class _MainTabTransitionLayerState extends State<_MainTabTransitionLayer> {
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    _hidden = !widget.active;
  }

  @override
  void didUpdateWidget(_MainTabTransitionLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active || oldWidget.active) _hidden = false;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = !widget.animate || !AppMotion.enabled(context);
    final type = widget.transitionType.clamp(0, 8);
    final duration = reduceMotion
        ? Duration.zero
        : AppMotion.duration(context, _pageMotionDuration(type));
    final direction = widget.relativePosition < 0 ? -1.0 : 1.0;
    final hiddenOffset = _pageMotionOffset(type, direction: direction);
    final hiddenScale = _pageMotionScale(type);
    final hiddenBlur = _pageMotionBlur(type);
    final curve = _pageMotionCurve(type);

    final active = widget.active;
    Widget content = widget.child;

    if (hiddenBlur > 0) {
      content = TweenAnimationBuilder<double>(
        key: ValueKey('main-tab-blur-$active-$type'),
        tween: Tween<double>(
          begin: active ? hiddenBlur : 0,
          end: active ? 0 : hiddenBlur,
        ),
        duration: duration,
        curve: curve,
        child: content,
        builder: (context, sigma, child) => ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: child,
        ),
      );
    }

    content = AnimatedScale(
      scale: active ? 1 : hiddenScale,
      duration: duration,
      curve: curve,
      alignment: Alignment.center,
      child: content,
    );

    content = AnimatedSlide(
      offset: active ? Offset.zero : hiddenOffset,
      duration: duration,
      curve: curve,
      child: content,
    );

    content = AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: duration,
      curve: Curves.easeOutCubic,
      onEnd: () {
        if (!mounted || widget.active || _hidden) return;
        // Zero-duration implicit animations can complete during tree updates.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !widget.active && !_hidden) {
            setState(() => _hidden = true);
          }
        });
      },
      child: content,
    );

    return Offstage(
      offstage: !active && (_hidden || reduceMotion),
      child: IgnorePointer(
        ignoring: !active,
        child: ExcludeSemantics(
          excluding: !active,
          child: RepaintBoundary(child: content),
        ),
      ),
    );
  }
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final Set<int> _visitedTabs = {0};
  String? _tabAccountId = activeUntisAccountId;
  bool _showTutorial = false;
  int _tutorialStep = 0;
  StreamSubscription<NotificationActionEvent>? _notificationActionSub;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Widget? _currentDrawer;

  final Map<int, GlobalKey> _tutorialNavKeys = {
    0: GlobalKey(debugLabel: 'tutorial-timetable'),
    1: GlobalKey(debugLabel: 'tutorial-exams'),
    2: GlobalKey(debugLabel: 'tutorial-info'),
    3: GlobalKey(debugLabel: 'tutorial-settings'),
    4: GlobalKey(debugLabel: 'tutorial-ai'),
  };
  final Map<int, GlobalKey> _tutorialNavLabelKeys = {
    0: GlobalKey(debugLabel: 'tutorial-timetable-label'),
    1: GlobalKey(debugLabel: 'tutorial-exams-label'),
    2: GlobalKey(debugLabel: 'tutorial-info-label'),
    3: GlobalKey(debugLabel: 'tutorial-settings-label'),
    4: GlobalKey(debugLabel: 'tutorial-ai-label'),
  };

  List<int> get _tutorialTargets =>
      aiEnabledNotifier.value ? const [0, 1, 2, 4, 3] : const [0, 1, 2, 3];

  @override
  void initState() {
    super.initState();
    _notificationActionSub = NotificationService().actionEvents.listen(
      _handleNotificationAction,
    );
    pendingAssistantOpenNotifier.addListener(_openAssistantFromNative);
    aiEnabledNotifier.addListener(_onAiEnabledChanged);
    untisAccountsNotifier.addListener(_refreshAccountTabs);
    if (pendingAssistantOpenNotifier.value) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openAssistantFromNative(),
      );
    }
    final pending = NotificationService().consumePendingActionEvent();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleNotificationAction(pending);
      });
    }
    if (widget.showTutorialOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTutorial());
    } else if (showChangelogOnStartup) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        showChangelogOnStartup = false;
        final p = SettingsStore.instance.preferences;
        await p.remove('showChangelogPending');
        if (mounted) {
          await showChangelogSheet(context);
          if (mounted) unawaited(_checkWrappedYearEnd());
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_checkWrappedYearEnd());
      });
    }
  }

  Future<void> _checkWrappedYearEnd() async {
    final account = activeUntisAccount;
    if (account == null || demoModeNotifier.value) return;
    final wrapped = SchoolWrappedRepository();
    final remoteYear = await wrapped.refreshSchoolYear(account);
    final currentYear =
        remoteYear ??
        (await wrapped.years(
          account.id,
        )).where((year) => year.contains(DateTime.now())).firstOrNull;
    if (currentYear != null) {
      unawaited(
        wrapped.captureCurrent(account, currentYear).catchError((_) {}),
      );
    }
    final pending = await wrapped.pendingAnnouncement(account.id);
    if (!mounted || account.id != activeUntisAccountId || pending == null) {
      return;
    }
    final l = appL10nFor(appLocaleNotifier.value);
    final open = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.wrapped('announcement')),
        content: Text(l.wrapped('announcementSub')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.wrapped('later')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.wrapped('begin')),
          ),
        ],
      ),
    );
    await wrapped.markAnnouncementSeen(account.id, pending);
    if (open == true && mounted && account.id == activeUntisAccountId) {
      Navigator.of(context).push(
        _buildBouncyRoute(SchoolWrappedStory(year: pending, account: account)),
      );
    }
  }

  void _handleNotificationAction(NotificationActionEvent event) {
    if (!mounted) return;

    final actionId = event.actionId.trim().isEmpty
        ? 'open_timetable'
        : event.actionId.trim();

    pendingTimetableCurrentLessonNotifier.value = event.currentLesson;
    pendingTimetableNextLessonNotifier.value = event.nextLesson;

    // An update notification used to fall through to the timetable. Keep its
    // payload self-contained so tapping it always lands at the release view
    // where the download action is available.
    if (event.payload?['type']?.toString() == 'update' ||
        actionId == 'open_updates') {
      _onNavTap(3);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(_buildBouncyRoute(const SettingsAboutUpdatesPage()));
      });
      return;
    }

    if (actionId == 'open_free_rooms' || actionId == 'open_next_lesson') {
      _onNavTap(0);
      pendingTimetableActionNotifier.value = actionId;
      return;
    }

    _onNavTap(0);
    final payload = event.payload;
    final changeDate = payload?['date'];
    final changeStartTime = payload?['startTime'];
    if ((actionId == 'open_timetable' || actionId == 'open_change') &&
        changeDate != null) {
      // Deep link from the important-changes notification: jump to the
      // changed day and highlight the affected lesson.
      pendingChangeHighlightDateNotifier.value = changeDate is num
          ? changeDate.toInt()
          : int.tryParse('$changeDate');
      pendingChangeHighlightStartTimeNotifier.value = changeStartTime is num
          ? changeStartTime.toInt()
          : (changeStartTime != null ? int.tryParse('$changeStartTime') : null);
      pendingTimetableActionNotifier.value = 'open_change';
      return;
    }
    pendingTimetableActionNotifier.value = 'open_timetable';
  }

  void _openAssistantFromNative() {
    if (!mounted || !pendingAssistantOpenNotifier.value) return;
    pendingAssistantOpenNotifier.value = false;
    if (aiEnabledNotifier.value) _onNavTap(4);
  }

  void _onAiEnabledChanged() {
    if (!mounted) return;
    if (!aiEnabledNotifier.value && _selectedIndex == 4) _selectedIndex = 0;
    setState(() {});
  }

  void _refreshAccountTabs() {
    if (!mounted || _tabAccountId == activeUntisAccountId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tabAccountId == activeUntisAccountId) return;
      setState(() {
        _tabAccountId = activeUntisAccountId;
        _visitedTabs
          ..clear()
          ..add(0)
          ..add(_selectedIndex);
        _currentDrawer = null;
      });
    });
  }

  void _startTutorial() {
    if (!mounted) return;
    setState(() {
      _showTutorial = true;
      _tutorialStep = 0;
      _selectedIndex = _tutorialTargets.first;
    });
  }

  Future<void> _finishTutorial() async {
    final prefs = SettingsStore.instance.preferences;
    await prefs.setBool('tutorialCompleted', true);
    await prefs.setInt('tutorialVersionCompleted', kCurrentTutorialVersion);
    if (!mounted) return;
    setState(() {
      _showTutorial = false;
      _tutorialStep = 0;
    });
    unawaited(_checkWrappedYearEnd());
  }

  Future<void> _skipTutorial() async {
    await _finishTutorial();
  }

  void _nextTutorialStep() {
    if (_tutorialStep >= _tutorialTargets.length - 1) {
      unawaited(_finishTutorial());
      return;
    }
    setState(() {
      _tutorialStep += 1;
      _selectedIndex = _tutorialTargets[_tutorialStep];
    });
  }

  void _previousTutorialStep() {
    if (_tutorialStep <= 0) return;
    setState(() {
      _tutorialStep -= 1;
      _selectedIndex = _tutorialTargets[_tutorialStep];
    });
  }

  void _onNavTap(int index) {
    if (index == 4 && !aiEnabledNotifier.value) return;
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  String _tutorialTitle(AppL10n l) {
    if (_tutorialStep >= _tutorialTargets.length) {
      return l.tutorialStepFinishTitle;
    }
    switch (_tutorialTargets[_tutorialStep]) {
      case 0:
        return l.tutorialStepWeekTitle;
      case 1:
        return l.tutorialStepExamsTitle;
      case 2:
        return l.tutorialStepInfoTitle;
      case 3:
        return l.tutorialStepSettingsTitle;
      case 4:
        return l.tutorialStepAiTitle;
      default:
        return l.tutorialStepFinishTitle;
    }
  }

  String _tutorialDesc(AppL10n l) {
    if (_tutorialStep >= _tutorialTargets.length) {
      return l.tutorialStepFinishDesc;
    }
    switch (_tutorialTargets[_tutorialStep]) {
      case 0:
        return l.tutorialStepWeekDesc;
      case 1:
        return l.tutorialStepExamsDesc;
      case 2:
        return l.tutorialStepInfoDesc;
      case 3:
        return l.tutorialStepSettingsDesc;
      case 4:
        return l.tutorialStepAiDesc;
      default:
        return l.tutorialStepFinishDesc;
    }
  }

  Widget _buildPageWithBackground(BuildContext context, Widget page) {
    return page;
  }

  List<Widget> get _pages {
    _visitedTabs.add(_selectedIndex);
    return <Widget>[
      WeeklyTimetablePage(key: ValueKey(activeUntisAccountId ?? 'active')),
      _visitedTabs.contains(1)
          ? ExamsPage(key: ValueKey('exams-$activeUntisAccountId'))
          : const SizedBox.shrink(),
      _visitedTabs.contains(2)
          ? SchoolNotificationsPage(
              key: ValueKey('info-$activeUntisAccountId'),
              isActive: _selectedIndex == 2,
            )
          : const SizedBox.shrink(),
      _visitedTabs.contains(3)
          ? StudentMorePage(
              openAssistant: () => _onNavTap(4),
              openTutorial: _startTutorial,
            )
          : const SizedBox.shrink(),
      aiEnabledNotifier.value && _visitedTabs.contains(4)
          ? AiAssistantPage(
              key: ValueKey(activeUntisAccountId ?? 'active'),
              onBackToTimetable: () => _onNavTap(0),
              onOpenDrawer: (drawer) {
                setState(() => _currentDrawer = drawer);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _scaffoldKey.currentState?.openDrawer();
                });
              },
            )
          : const SizedBox.shrink(),
    ];
  }

  @override
  void dispose() {
    _notificationActionSub?.cancel();
    pendingAssistantOpenNotifier.removeListener(_openAssistantFromNative);
    aiEnabledNotifier.removeListener(_onAiEnabledChanged);
    untisAccountsNotifier.removeListener(_refreshAccountTabs);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);
    final isTablet = UntisLayout.isTablet(context);

    return PopScope<Object?>(
      canPop: _selectedIndex == 0 && !_showTutorial,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showTutorial) {
          unawaited(_finishTutorial());
        } else {
          _onNavTap(0);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _currentDrawer,
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: isTablet || mq.viewInsets.bottom > 0
            ? null
            : SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: ValueListenableBuilder<String>(
                  valueListenable: appLocaleNotifier,
                  builder: (context, _, _) => ListenableBuilder(
                    listenable: Listenable.merge([
                      unreadTimetableChangesNotifier,
                      unreadInboxMessagesNotifier,
                    ]),
                    builder: (context, _) => _buildFloatingNavBar(context, cs),
                  ),
                ),
              ),
        body: _AnimatedBackground(
          child: Stack(
            children: [
              Row(
                children: [
                  if (isTablet)
                    SafeArea(
                      child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: _onNavTap,
                        labelType: NavigationRailLabelType.all,
                        groupAlignment: 0,
                        destinations: [
                          NavigationRailDestination(
                            icon: const Icon(Icons.watch_later_outlined),
                            selectedIcon: KeyedSubtree(
                              key: _tutorialNavKeys[0],
                              child: const Icon(Icons.watch_later_rounded),
                            ),
                            label: Text(
                              l.timetableTitle,
                              key: _tutorialNavLabelKeys[0],
                            ),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.event_note_outlined),
                            selectedIcon: KeyedSubtree(
                              key: _tutorialNavKeys[1],
                              child: const Icon(Icons.event_note_rounded),
                            ),
                            label: Text(
                              l.ux('planner'),
                              key: _tutorialNavLabelKeys[1],
                            ),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.campaign_outlined),
                            selectedIcon: KeyedSubtree(
                              key: _tutorialNavKeys[2],
                              child: const Icon(Icons.campaign_rounded),
                            ),
                            label: Text(
                              l.ux('schoolInfo'),
                              key: _tutorialNavLabelKeys[2],
                            ),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.grid_view_outlined),
                            selectedIcon: KeyedSubtree(
                              key: _tutorialNavKeys[3],
                              child: const Icon(Icons.grid_view_rounded),
                            ),
                            label: Text(
                              l.ux('more'),
                              key: _tutorialNavLabelKeys[3],
                            ),
                          ),
                          if (aiEnabledNotifier.value)
                            NavigationRailDestination(
                              icon: const Icon(Icons.auto_awesome_outlined),
                              selectedIcon: KeyedSubtree(
                                key: _tutorialNavKeys[4],
                                child: const Icon(Icons.auto_awesome_rounded),
                              ),
                              label: Text(
                                l.navAi,
                                key: _tutorialNavLabelKeys[4],
                              ),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: MediaQuery(
                      data: mq.copyWith(
                        viewInsets: mq.viewInsets.copyWith(bottom: 0),
                        padding: mq.padding.copyWith(bottom: mq.padding.bottom),
                      ),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: mainTabFadeUpEnabledNotifier,
                        builder: (context, animationsEnabled, _) {
                          final pages = _pages;

                          return ValueListenableBuilder<int>(
                            valueListenable: pageTransitionNotifier,
                            builder: (context, transitionType, _) {
                              return Stack(
                                fit: StackFit.expand,
                                children: pages
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final active =
                                          entry.key == _selectedIndex;
                                      return _MainTabTransitionLayer(
                                        key: ValueKey(
                                          'main-tab-layer-${entry.key}',
                                        ),
                                        active: active,
                                        animate: animationsEnabled,
                                        relativePosition:
                                            entry.key - _selectedIndex,
                                        transitionType: transitionType,
                                        child: TickerMode(
                                          enabled: active,
                                          child: _buildPageWithBackground(
                                            context,
                                            entry.value,
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(growable: false),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              if (_showTutorial)
                Positioned.fill(
                  child: _TutorialSpotlightOverlay(
                    key: ValueKey(_tutorialStep),
                    targetKey:
                        _tutorialNavKeys[_tutorialTargets[_tutorialStep]],
                    labelKey:
                        _tutorialNavLabelKeys[_tutorialTargets[_tutorialStep]],
                    step: _tutorialStep,
                    totalSteps: _tutorialTargets.length,
                    title: _tutorialTitle(l),
                    description: _tutorialDesc(l),
                    onBack: _tutorialStep == 0 ? null : _previousTutorialStep,
                    onNext: _nextTutorialStep,
                    onSkip: _skipTutorial,
                    isLast: _tutorialStep == _tutorialTargets.length - 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, ColorScheme cs) {
    final l = appL10nFor(appLocaleNotifier.value);
    final items = [
      _NavItem(
        icon: Icons.grid_view_outlined,
        selectedIcon: Icons.grid_view_rounded,
        label: l.ux('more'),
        pageIndex: 3,
        tutorialKey: _tutorialNavKeys[3],
        tutorialLabelKey: _tutorialNavLabelKeys[3],
      ),
      _NavItem(
        icon: Icons.campaign_outlined,
        selectedIcon: Icons.campaign_rounded,
        label: l.ux('schoolInfo'),
        pageIndex: 2,
        tutorialKey: _tutorialNavKeys[2],
        tutorialLabelKey: _tutorialNavLabelKeys[2],
        badgeCount: unreadInboxMessagesNotifier.value,
      ),
      _NavItem(
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment_rounded,
        label: l.ux('planner'),
        pageIndex: 1,
        tutorialKey: _tutorialNavKeys[1],
        tutorialLabelKey: _tutorialNavLabelKeys[1],
      ),
      if (aiEnabledNotifier.value)
        _NavItem(
          icon: Icons.auto_awesome_outlined,
          selectedIcon: Icons.auto_awesome_rounded,
          label: l.navAi,
          pageIndex: 4,
          tutorialKey: _tutorialNavKeys[4],
          tutorialLabelKey: _tutorialNavLabelKeys[4],
        ),
    ];
    final radius = untisThemeTokensOf(context).controlRadius;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _ExpressiveNavBar(
            items: items,
            selectedIndex: items.indexWhere(
              (item) => item.pageIndex == _selectedIndex,
            ),
            colorScheme: cs,
            onTap: _onNavTap,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 84,
          child: ThemedSurface(
            borderRadius: BorderRadius.circular(radius + 8),
            color: cs.surfaceContainerHigh,
            child: PrimaryDestinationButton(
              destination: PrimaryDestination(
                label: l.timetableTitle,
                icon: Icons.watch_later_outlined,
                selectedIcon: Icons.watch_later_rounded,
                targetKey: _tutorialNavKeys[0],
                labelKey: _tutorialNavLabelKeys[0],
              ),
              selected: _selectedIndex == 0,
              duration: AppMotion.duration(
                context,
                AppMotionTokens.standardEffects,
              ),
              radius: radius + 8,
              onPressed: () => _onNavTap(0),
            ),
          ),
        ),
      ],
    );
  }
}

class _TutorialSpotlightOverlay extends StatefulWidget {
  final GlobalKey? targetKey;
  final GlobalKey? labelKey;
  final int step;
  final int totalSteps;
  final String title;
  final String description;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool isLast;

  const _TutorialSpotlightOverlay({
    super.key,
    required this.targetKey,
    this.labelKey,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.description,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.isLast,
  });

  @override
  State<_TutorialSpotlightOverlay> createState() =>
      _TutorialSpotlightOverlayState();
}

class _TutorialSpotlightOverlayState extends State<_TutorialSpotlightOverlay> {
  bool _expandToLabel = false;
  bool _labelExpansionScheduled = false;
  Timer? _labelExpansionTimer;

  GlobalKey? get targetKey => widget.targetKey;
  GlobalKey? get labelKey => widget.labelKey;
  int get step => widget.step;
  int get totalSteps => widget.totalSteps;
  String get title => widget.title;
  String get description => widget.description;
  VoidCallback? get onBack => widget.onBack;
  VoidCallback get onNext => widget.onNext;
  VoidCallback get onSkip => widget.onSkip;
  bool get isLast => widget.isLast;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleLabelExpansion();
  }

  @override
  void didUpdateWidget(covariant _TutorialSpotlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step ||
        oldWidget.labelKey != widget.labelKey) {
      _labelExpansionTimer?.cancel();
      _expandToLabel = false;
      _labelExpansionScheduled = false;
      _scheduleLabelExpansion();
    }
  }

  void _scheduleLabelExpansion() {
    if (_labelExpansionScheduled || labelKey == null) return;
    _labelExpansionScheduled = true;

    final isTablet = MediaQuery.sizeOf(context).width >= 720;
    final delay = isTablet
        ? Duration.zero
        : AppMotion.duration(context, const Duration(milliseconds: 560));
    _labelExpansionTimer = Timer(delay, () {
      if (mounted) setState(() => _expandToLabel = true);
    });
  }

  @override
  void dispose() {
    _labelExpansionTimer?.cancel();
    super.dispose();
  }

  Rect? _rectForKey(GlobalKey? key) {
    final targetContext = key?.currentContext;
    final renderObject = targetContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    final useBackdropBlur = _usesModalBackdropBlur(context);
    final l = appL10nFor(appLocaleNotifier.value);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final tablet = size.width >= 720;
        final fallback = Rect.fromCenter(
          center: tablet
              ? Offset(44, size.height / 2)
              : Offset(size.width / 2, size.height - 68),
          width: tablet ? 56 : 68,
          height: 56,
        );
        final bounds = Offset.zero & size;
        final rawTarget = _rectForKey(targetKey) ?? fallback;
        final labelTarget = _rectForKey(labelKey);
        final combinedTarget = labelTarget == null
            ? rawTarget
            : rawTarget.expandToInclude(labelTarget);
        final startTarget = rawTarget.inflate(tablet ? 8 : 5).intersect(bounds);
        final endTarget = (_expandToLabel ? combinedTarget : rawTarget)
            .inflate(tablet ? 8 : 5)
            .intersect(bounds);

        final callout = _TutorialCallout(
          step: step,
          totalSteps: totalSteps,
          title: title,
          description: description,
          onBack: onBack,
          onNext: onNext,
          onSkip: onSkip,
          nextLabel: isLast ? l.tutorialDone : l.onboardingNext,
        );

        return TweenAnimationBuilder<Rect>(
          tween: _RectTargetTween(begin: startTarget, end: endTarget),
          duration: AppMotion.duration(
            context,
            const Duration(milliseconds: 360),
          ),
          curve: Curves.easeOutCubic,
          builder: (context, target, _) => Stack(
            children: [
              if (useBackdropBlur)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipPath(
                      clipper: _TutorialSpotlightClipper(target),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: math.min(tokens.blurSigma, 5),
                          sigmaY: math.min(tokens.blurSigma, 5),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _TutorialSpotlightPainter(
                      target: target,
                      scrim: useBackdropBlur
                          ? Colors.black.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.58),
                      accent: cs.primary,
                    ),
                  ),
                ),
              ),
              if (tablet)
                Positioned(
                  left: math.min(
                    math.max(target.right + 18, 94),
                    math.max(16, size.width - 406),
                  ),
                  top: (target.center.dy - 130).clamp(
                    mq.padding.top + 16,
                    math.max(mq.padding.top + 16, size.height - 310),
                  ),
                  width: math.min(380, size.width - 110),
                  child: callout,
                )
              else if (target.top > size.height * 0.48)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: size.height - target.top + 16,
                  child: callout,
                )
              else
                Positioned(
                  left: 16,
                  right: 16,
                  top: target.bottom + 16,
                  child: callout,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TutorialSpotlightClipper extends CustomClipper<Path> {
  final Rect target;

  const _TutorialSpotlightClipper(this.target);

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addRRect(RRect.fromRectAndRadius(target, const Radius.circular(18)));

  @override
  bool shouldReclip(_TutorialSpotlightClipper oldClipper) =>
      oldClipper.target != target;
}

class _TutorialCallout extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String description;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String nextLabel;

  const _TutorialCallout({
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.description,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);
    final reduceMotion = !AppMotion.enabled(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 12 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Material(
        key: const ValueKey('tutorial-callout'),
        color: cs.surface,
        elevation: 10,
        shadowColor: cs.shadow.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.primary.withValues(alpha: 0.28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.tutorialTitle,
                      style: untisThemeTextStyle(
                        context,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  TextButton(onPressed: onSkip, child: Text(l.tutorialSkip)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(totalSteps, (index) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 240),
                      height: 5,
                      margin: EdgeInsets.only(
                        right: index == totalSteps - 1 ? 0 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: index <= step
                            ? cs.primary
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: untisThemeTextStyle(
                  context,
                  display: true,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                style: untisThemeTextStyle(
                  context,
                  fontSize: 13.5,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onBack != null) ...[
                    OutlinedButton(
                      key: const ValueKey('tutorial-back'),
                      onPressed: onBack,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        semanticLabel: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('tutorial-next'),
                      onPressed: onNext,
                      icon: Icon(
                        step == totalSteps - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(nextLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialSpotlightPainter extends CustomPainter {
  final Rect target;
  final Color scrim;
  final Color accent;

  const _TutorialSpotlightPainter({
    required this.target,
    required this.scrim,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cutout = RRect.fromRectAndRadius(target, const Radius.circular(18));
    final scrimPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(cutout);
    canvas.drawPath(scrimPath, Paint()..color = scrim);
    canvas.drawRRect(
      cutout,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_TutorialSpotlightPainter oldDelegate) {
    return oldDelegate.target != target ||
        oldDelegate.scrim != scrim ||
        oldDelegate.accent != accent;
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int pageIndex;
  final GlobalKey? tutorialKey;
  final GlobalKey? tutorialLabelKey;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.pageIndex,
    this.tutorialKey,
    this.tutorialLabelKey,
    this.badgeCount = 0,
  });
}

/// Expressive surfaces around equally-sized, permanently labelled destinations.
class _ExpressiveNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ColorScheme colorScheme;
  final ValueChanged<int> onTap;

  const _ExpressiveNavBar({
    required this.items,
    required this.selectedIndex,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = untisThemeTokensOf(context);
    return ThemedSurface(
      respectSurfaceBlurPreference: false,
      respectSurfaceCornerPreference: false,
      borderRadius: BorderRadius.circular(tokens.controlRadius + 8),
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: PrimaryDestinationBar(
          destinations: [
            for (final item in items)
              PrimaryDestination(
                label: item.label,
                icon: item.icon,
                selectedIcon: item.selectedIcon,
                badgeCount: item.badgeCount,
                targetKey: item.tutorialKey,
                labelKey: item.tutorialLabelKey,
              ),
          ],
          selectedIndex: selectedIndex,
          radius: tokens.controlRadius,
          duration: AppMotion.duration(
            context,
            AppMotionTokens.standardEffects,
          ),
          onSelected: (index) {
            if (index != selectedIndex) unawaited(AppHaptics.selection());
            onTap(items[index].pageIndex);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

// Bouncy press helper (unchanged)
// ---------------------------------------------------------------------------
