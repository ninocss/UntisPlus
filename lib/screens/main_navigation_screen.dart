part of '../main.dart';

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

class _AiMetric {
  final String label;
  final String value;

  const _AiMetric({required this.label, required this.value});
}

class _AiLessonCardData {
  final String subject;
  final String subjectShort;
  final String room;
  final String teacher;
  final String time;
  final bool isCancelled;

  const _AiLessonCardData({
    required this.subject,
    required this.subjectShort,
    required this.room,
    required this.teacher,
    required this.time,
    required this.isCancelled,
  });
}

class _AiSearchResult {
  final String query;
  final String headline;
  final String summary;
  final List<String> tags;
  final List<_AiMetric> metrics;
  final List<_AiLessonCardData> lessons;
  final String rawReply;

  const _AiSearchResult({
    required this.query,
    required this.headline,
    required this.summary,
    required this.tags,
    required this.metrics,
    required this.lessons,
    required this.rawReply,
  });
}

class _ChatSession {
  final String id;
  String title;
  final List<Map<String, String>> messages;
  final DateTime timestamp;

  _ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages,
    'timestamp': timestamp.toIso8601String(),
  };

  factory _ChatSession.fromJson(Map<String, dynamic> json) => _ChatSession(
    id: json['id'],
    title: json['title'] ?? 'Chat',
    messages: List<Map<String, String>>.from(
      (json['messages'] as List).map((m) => Map<String, String>.from(m)),
    ),
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class _AiProposedAction {
  const _AiProposedAction(this.data);

  final Map<String, dynamic> data;
  String get kind => data['kind']?.toString() ?? '';
  String get id => data['id']?.toString() ?? '';
  String get subject => data['subject']?.toString().trim() ?? '';
  String get text =>
      (data['text'] ?? data['description'] ?? data['title'] ?? '')
          .toString()
          .trim();
  int? get date => int.tryParse(
    (data['date'] ?? data['dueDate'] ?? data['examDate'] ?? '')
        .toString()
        .replaceAll('-', ''),
  );
  double? get gradeValue => double.tryParse(
    (data['value'] ?? data['grade'] ?? '').toString().replaceAll(',', '.'),
  );
  double get gradeWeight =>
      double.tryParse((data['weight'] ?? '1').toString().replaceAll(',', '.')) ??
      1;
  String get gradeType => data['type']?.toString().trim() ?? '';

  String summary(AppL10n l) {
    final values = {'subject': subject, 'text': text, 'id': id, 'value': gradeValue};
    return switch (kind) {
      'create_homework' => l.uiFormat('aiActionCreateHomework', values),
      'update_homework' => l.uiFormat('aiActionUpdateHomework', values),
      'delete_homework' => l.uiFormat('aiActionDeleteHomework', values),
      'complete_homework' => l.uiFormat('aiActionCompleteHomework', values),
      'create_exam' => l.uiFormat('aiActionCreateExam', values),
      'update_exam' => l.uiFormat('aiActionUpdateExam', values),
      'delete_exam' => l.uiFormat('aiActionDeleteExam', values),
      'create_grade' => l.uiFormat('aiActionCreateGrade', values),
      'update_grade' => l.uiFormat('aiActionUpdateGrade', values),
      'delete_grade' => l.uiFormat('aiActionDeleteGrade', values),
      _ => l.ui('aiActionUnknown'),
    };
  }

  bool get isSupported => const {
    'create_homework',
    'update_homework',
    'delete_homework',
    'complete_homework',
    'create_exam',
    'update_exam',
    'delete_exam',
    'create_grade',
    'update_grade',
    'delete_grade',
  }.contains(kind);
}

class _AiAssistantPageState extends State<AiAssistantPage>
    with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _firstChipKey = GlobalKey();
  final FocusNode _promptFocusNode = FocusNode();
  late TabController _tabController;
  Timer? _typingHintTimer;
  Timer? _streamRenderTimer;
  final StringBuffer _pendingStreamText = StringBuffer();
  DateTime? _lastStreamingHapticAt;
  int _typingHintIndex = 0;
  int _searchGeneration = 0;
  String _latestQuery = '';
  _AiSearchResult? _latestResult;
  List<Map<String, dynamic>> _exams = [];
  Map<int, List<dynamic>> _weekData = {
    0: <dynamic>[],
    1: <dynamic>[],
    2: <dynamic>[],
    3: <dynamic>[],
    4: <dynamic>[],
  };
  DateTime _currentMonday = DateTime.now();
  bool _loading = true;
  bool _thinking = false;
  bool _chatMode = false;
  final List<Map<String, String>> _chatMessages = [];
  final List<AiChatAttachment> _attachments = [];
  final List<_ChatSession> _chatHistory = [];
  String? _currentChatId;

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
    _promptFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _consumeNativeAssistantPrompt() {
    final prompt = pendingAssistantPromptNotifier.value?.trim() ?? '';
    if (!mounted || prompt.isEmpty) return;
    pendingAssistantPromptNotifier.value = null;
    _inputController.text = prompt;
    _send();
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('aiChatHistory');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final sessions = <_ChatSession>[];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              try {
                sessions.add(_ChatSession.fromJson(item));
              } catch (_) {
                // Skip corrupted sessions
              }
            }
          }
          setState(() {
            _chatHistory.clear();
            _chatHistory.addAll(sessions);
            _chatHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          });
        }
      }
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
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_chatHistory.map((s) => s.toJson()).toList());
      await prefs.setString('aiChatHistory', raw);
    } catch (_) {}
  }

  void _startNewChat() {
    setState(() {
      _currentChatId = null;
      _chatMessages.clear();
      _latestResult = null;
      _latestQuery = '';
      _chatMode = true;
    });
    _selectAiTab(1, haptic: false);
    _hapticAction();
    // Check if we are inside a drawer (Navigator.canPop is true in drawers)
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _loadSession(_ChatSession session) {
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
    pendingAssistantPromptNotifier.removeListener(
      _consumeNativeAssistantPrompt,
    );
    _tabController.dispose();
    _promptFocusNode.dispose();
    _typingHintTimer?.cancel();
    _streamRenderTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetSearchState() {
    _typingHintTimer?.cancel();
    _typingHintIndex = 0;
    _thinking = false;
    _latestQuery = '';
    _latestResult = null;
  }

  void _hapticSelection() {
    unawaited(HapticFeedback.selectionClick());
  }

  void _hapticAction() {
    unawaited(HapticFeedback.mediumImpact());
  }

  void _selectAiTab(int index, {bool haptic = true}) {
    final chatMode = index == 1;
    final changed = _chatMode != chatMode;
    if (changed && mounted) {
      setState(() => _chatMode = chatMode);
      if (haptic) _hapticSelection();
    }
    if (_tabController.index != index) {
      _tabController.animateTo(index, duration: Duration.zero);
    }
    if (chatMode) _scrollToBottom();
  }

  String _extractJsonCandidate(String reply) {
    final trimmed = reply.trim();
    final fenced = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    ).firstMatch(trimmed)?.group(1)?.trim();
    if (fenced != null && fenced.isNotEmpty) return fenced;

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return trimmed.substring(start, end + 1).trim();
    }
    return trimmed;
  }

  String _firstNonEmptyString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  List<String> _stringListFrom(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  List<_AiLessonCardData> _lessonsFromParsedPayload(Map<String, dynamic> data) {
    final rawLessons = data['lessons'] ?? data['stunden'] ?? data['items'];
    if (rawLessons is! List) return const [];

    return rawLessons
        .whereType<Map>()
        .map((rawLesson) {
          final lesson = rawLesson.cast<String, dynamic>();
          final time = _firstNonEmptyString(lesson, const [
            'time',
            'slot',
            'range',
            'period',
          ]);
          final subject = _firstNonEmptyString(lesson, const [
            'subject',
            'title',
            'name',
          ]);
          final subjectShort = _firstNonEmptyString(lesson, const [
            'subjectShort',
            'short',
            'abbr',
          ]);
          final room = _firstNonEmptyString(lesson, const [
            'room',
            'raum',
            'location',
          ]);
          final teacher = _firstNonEmptyString(lesson, const [
            'teacher',
            'lehrer',
            'person',
          ]);
          final status = _firstNonEmptyString(lesson, const [
            'status',
            'state',
          ]);
          return _AiLessonCardData(
            subject: subject.isEmpty
                ? (subjectShort.isEmpty ? '?' : subjectShort)
                : subject,
            subjectShort: subjectShort,
            room: room,
            teacher: teacher,
            time: time.isEmpty ? '—' : time,
            isCancelled:
                status.toLowerCase().contains('cancel') ||
                status.toLowerCase().contains('ausfall'),
          );
        })
        .where(
          (lesson) =>
              lesson.subject.isNotEmpty ||
              lesson.room.isNotEmpty ||
              lesson.teacher.isNotEmpty,
        )
        .toList(growable: false);
  }

  _AiSearchResult _parseSearchResult({
    required String query,
    required String reply,
  }) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final fallbackHeadline = reply.split(RegExp(r'[\n.!?]')).first.trim();
    final fallbackSummary = reply.trim().isEmpty ? query : reply.trim();
    try {
      final decoded = jsonDecode(_extractJsonCandidate(reply));
      if (decoded is Map<String, dynamic>) {
        final metrics = <_AiMetric>[];
        final metricSource = decoded['metrics'] ?? decoded['stats'];
        if (metricSource is List) {
          for (final entry in metricSource.whereType<Map>()) {
            final metric = entry.cast<String, dynamic>();
            final label = _firstNonEmptyString(metric, const [
              'label',
              'name',
              'title',
            ]);
            final value = _firstNonEmptyString(metric, const [
              'value',
              'amount',
              'text',
            ]);
            if (label.isNotEmpty && value.isNotEmpty) {
              metrics.add(_AiMetric(label: label, value: value));
            }
          }
        }

        final tags = _stringListFrom(
          decoded['tags'],
        ).take(6).toList(growable: false);
        final lessons = _lessonsFromParsedPayload(decoded);

        return _AiSearchResult(
          query: query,
          headline:
              _firstNonEmptyString(decoded, const [
                'headline',
                'title',
                'summaryTitle',
              ]).isEmpty
              ? fallbackHeadline
              : _firstNonEmptyString(decoded, const [
                  'headline',
                  'title',
                  'summaryTitle',
                ]),
          summary:
              _firstNonEmptyString(decoded, const [
                'summary',
                'text',
                'result',
              ]).isEmpty
              ? fallbackSummary
              : _firstNonEmptyString(decoded, const [
                  'summary',
                  'text',
                  'result',
                ]),
          tags: tags,
          metrics: metrics,
          lessons: lessons,
          rawReply: reply,
        );
      }
    } catch (_) {}

    return _AiSearchResult(
      query: query,
      headline: fallbackHeadline.isEmpty ? l.aiNewSearch : fallbackHeadline,
      summary: fallbackSummary,
      tags: const [],
      metrics: const [],
      lessons: const [],
      rawReply: reply,
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
    final mondayStamp = int.parse(DateFormat('yyyyMMdd').format(monday));
    final fridayStamp = int.parse(DateFormat('yyyyMMdd').format(friday));

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
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    // The timetable tab is the source of truth while it is alive. Reading its
    // published snapshot avoids an outdated SharedPreferences cache claiming
    // that a currently loaded school day is free.
    Map<int, List<dynamic>> weekData = currentWeekDataNotifier.value.isEmpty
        ? _emptyWeekData()
        : Map<int, List<dynamic>>.from(currentWeekDataNotifier.value);
    List<Map<String, dynamic>> exams = [];

    if (demoModeNotifier.value) {
      weekData = DemoModeService.buildWeek(
        monday,
        locale: appLocaleNotifier.value,
      );
      exams = DemoModeService.demoExams(locale: appLocaleNotifier.value);
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(
          [
            'weekCacheV1',
            schoolUrl,
            schoolName,
            personType.toString(),
            personId.toString(),
            DateFormat('yyyyMMdd').format(monday),
          ].join('|'),
        );
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            final week = decoded['weekData'];
            if (week is Map) {
              weekData = _decodeWeek(week.cast<dynamic, dynamic>());
            }
          }
        }

        final rawExams =
            prefs.getStringList(_accountDataKey('customExams')) ?? [];
        final customExams = rawExams
            .map((e) {
              try {
                return jsonDecode(e) as Map<String, dynamic>;
              } catch (_) {
                return <String, dynamic>{};
              }
            })
            .where((e) => e.isNotEmpty)
            .toList();

        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 365));
        final startStr = DateFormat('yyyyMMdd').format(start);
        final endStr = DateFormat('yyyyMMdd').format(end);

        Future<List<Map<String, dynamic>>> tryEndpoint(String path) async {
          try {
            final uri = Uri.parse(
              'https://$schoolUrl$path?startDate=$startStr&endDate=$endStr',
            );
            final res = await http.get(
              uri,
              headers: {'Accept': 'application/json'},
            );
            if (res.statusCode == 200) {
              final decoded = jsonDecode(res.body);
              List<dynamic> list = [];
              if (decoded is List) {
                list = decoded;
              } else if (decoded is Map) {
                list =
                    (decoded['data'] ??
                            decoded['exams'] ??
                            decoded['result'] ??
                            [])
                        as List;
              }
              return list
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            }
          } catch (_) {}
          return [];
        }

        exams = await tryEndpoint('/WebUntis/api/exams');
        if (exams.isEmpty) {
          exams = await tryEndpoint('/WebUntis/api/classreg/exams');
        }
        if (exams.isEmpty && personId != 0) {
          exams = await tryEndpoint('/WebUntis/api/exams/student/$personId');
        }
        exams = [
          ...exams.map((e) => {...e, '_source': 'api'}),
          ...customExams.map((e) => {...e, '_source': 'custom'}),
        ];
      } catch (_) {}
    }

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

    if (!mounted) return;
    setState(() {
      _currentMonday = monday;
      _weekData = weekData;
      _exams = exams;
      _loading = false;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsAiPage()));
  }

  Future<void> _openPromptEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsAiPage(openPromptEditor: true),
      ),
    );
  }

  Future<void> _clearCurrentResult() async {
    setState(() {
      _resetSearchState();
    });
  }

  String _resolvedSystemPrompt() {
    final l = AppL10n.of(appLocaleNotifier.value);
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
      '[timetable]': _formatWeekForAi(_weekData, _currentMonday),
      '[timetable_json]': jsonEncode(_jsonSafeValue(_weekData)),
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

${l.ui('aiResponseFormat')}''';
  }

  String _resolvedChatSystemPrompt() {
    final l = AppL10n.of(appLocaleNotifier.value);
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
      '[timetable]': _formatWeekForAi(_weekData, _currentMonday),
      '[timetable_json]': jsonEncode(_jsonSafeValue(_weekData)),
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
        personaInstruction = l.ui('aiPersonaStrict');
        break;
      case 'buddy':
        personaInstruction = l.ui('aiPersonaBuddy');
        break;
      case 'helpful':
      default:
        personaInstruction = l.ui('aiPersonaHelpful');
        break;
    }

    return '''$resolved

${l.ui('aiAssistantIntro')}
$personaInstruction
${l.ui('aiAssistantRules')}''';
  }

  Future<String> _requestProviderResponse(
    String systemPrompt, {
    required String userQuery,
  }) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final provider = _normalizeAiProvider(aiProvider);
    final isLocalProvider = provider == 'local';
    final apiKey = _activeAiApiKey().trim();
    if (!isLocalProvider && apiKey.isEmpty) {
      throw Exception(
        'CONFIG: ${_providerAwareMissingApiKeyMessage(l, provider)}',
      );
    }

    final model = aiModel.trim().isNotEmpty
        ? aiModel.trim()
        : _defaultModelForProvider(
            provider,
            customCompatibility: aiCustomCompatibility,
          );

    String normalizedBaseUrl(String value) {
      var out = value.trim();
      while (out.endsWith('/')) {
        out = out.substring(0, out.length - 1);
      }
      return out;
    }

    String openAiCompatibleEndpoint(String rawBaseUrl) {
      final base = normalizedBaseUrl(rawBaseUrl);
      if (base.isEmpty) return '';
      if (base.endsWith('/chat/completions')) return base;
      if (base.endsWith('/v1')) return '$base/chat/completions';
      if (base.endsWith('/v1/chat')) return '$base/completions';
      return '$base/v1/chat/completions';
    }

    String geminiCompatibleEndpoint(String rawBaseUrl, String model) {
      final base = normalizedBaseUrl(rawBaseUrl);
      if (base.isEmpty) return '';
      if (base.contains('/models/')) return base;
      if (base.contains('/v1beta')) {
        return '$base/models/$model:generateContent';
      }
      if (base.contains('/v1')) {
        return '$base/models/$model:generateContent';
      }
      return '$base/v1beta/models/$model:generateContent';
    }

    Future<String> requestGeminiResponse({
      required String endpoint,
      required String apiKey,
      required String systemPrompt,
      required String userQuery,
    }) async {
      final contents = [
        {
          'role': 'user',
          'parts': [
            {'text': userQuery},
          ],
        },
      ];

      final body = jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': contents,
        'generationConfig': {'maxOutputTokens': 2600, 'temperature': 0.2},
      });

      final endpointUri = Uri.parse(endpoint);
      final mergedParams = Map<String, String>.from(endpointUri.queryParameters)
        ..putIfAbsent('key', () => apiKey);
      final uri = endpointUri.replace(queryParameters: mergedParams);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
        body: body,
      );

      Map<String, dynamic>? payload;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) payload = decoded;
      } catch (_) {}

      if (response.statusCode != 200) {
        final message = payload?['error']?['message'] ?? response.statusCode;
        throw Exception('API: $message');
      }

      var reply = '';
      final candidates = payload?['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final content = candidates.first['content'];
        final parts = (content is Map<String, dynamic>)
            ? content['parts']
            : null;
        if (parts is List) {
          reply = parts
              .map((p) => (p is Map<String, dynamic>) ? p['text'] : null)
              .whereType<String>()
              .join();
        }
      }

      reply = reply.trim();
      if (reply.isEmpty) {
        throw Exception(
          'API: ${AppL10n.of(appLocaleNotifier.value).aiNoReply}',
        );
      }
      return reply;
    }

    Future<String> requestOpenAiCompatibleResponse({
      required String endpoint,
      required String apiKey,
      required String model,
      required String systemPrompt,
      required String userQuery,
    }) async {
      final messages = [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userQuery},
      ];

      final body = jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.2,
      });

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      );

      Map<String, dynamic>? payload;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) payload = decoded;
      } catch (_) {}

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = payload?['error']?['message'] ?? response.statusCode;
        throw Exception('API: $message');
      }

      final choices = payload?['choices'];
      if (choices is! List || choices.isEmpty) {
        throw Exception(
          'API: ${AppL10n.of(appLocaleNotifier.value).aiNoReply}',
        );
      }

      final first = choices.first;
      if (first is! Map<String, dynamic>) {
        throw Exception(
          'API: ${AppL10n.of(appLocaleNotifier.value).aiNoReply}',
        );
      }

      final message = first['message'];
      if (message is Map<String, dynamic>) {
        final content = message['content'];
        if (content is String && content.trim().isNotEmpty) {
          return content.trim();
        }
        if (content is List) {
          final text = content
              .map((part) {
                if (part is Map<String, dynamic>) {
                  return part['text']?.toString() ?? '';
                }
                return '';
              })
              .join()
              .trim();
          if (text.isNotEmpty) return text;
        }
      }

      final legacyText = first['text']?.toString().trim() ?? '';
      if (legacyText.isNotEmpty) return legacyText;
      throw Exception('API: ${AppL10n.of(appLocaleNotifier.value).aiNoReply}');
    }

    switch (provider) {
      case 'openai':
        return requestOpenAiCompatibleResponse(
          endpoint: 'https://api.openai.com/v1/chat/completions',
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          userQuery: userQuery,
        );
      case 'mistral':
        return requestOpenAiCompatibleResponse(
          endpoint: 'https://api.mistral.ai/v1/chat/completions',
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          userQuery: userQuery,
        );
      case 'custom':
        final baseUrl = aiCustomBaseUrl.trim();
        if (baseUrl.isEmpty) {
          throw Exception('CONFIG: ${l.aiCustomBaseUrlMissing}');
        }
        final compat = _normalizeAiCustomCompatibility(aiCustomCompatibility);
        if (compat == 'gemini') {
          return requestGeminiResponse(
            endpoint: geminiCompatibleEndpoint(baseUrl, model),
            apiKey: apiKey,
            systemPrompt: systemPrompt,
            userQuery: userQuery,
          );
        }
        return requestOpenAiCompatibleResponse(
          endpoint: openAiCompatibleEndpoint(baseUrl),
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          userQuery: userQuery,
        );
      case 'local':
        return _requestLocalModelText(
          systemPrompt: systemPrompt,
          userQuery: userQuery,
          modelPath: aiLocalModelPath,
        );
      case 'gemini':
      default:
        return requestGeminiResponse(
          endpoint:
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
          apiKey: apiKey,
          systemPrompt: systemPrompt,
          userQuery: userQuery,
        );
    }
  }

  String _daySummaryForPrompt(DateTime date) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final index = date.difference(_currentMonday).inDays;
    final dateLabel = DateFormat('dd.MM.yyyy').format(date);
    if (index < 0 || index > 4) {
      return l
          .ui('aiDayDataUnavailable')
          .replaceAll('{date}', dateLabel);
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
    if (index < 0 || index > 4) {
      return AppL10n.of(appLocaleNotifier.value)
          .ui('aiWeekDataUnavailable')
          .replaceAll('{date}', label);
    }
    final lessons = (_weekData[index] ?? const <dynamic>[])
        .whereType<Map>()
        .where(
          (lesson) => lesson['code']?.toString().toLowerCase() != 'cancelled',
        )
        .toList(growable: false);
    if (lessons.isEmpty) {
      return AppL10n.of(appLocaleNotifier.value)
          .ui('aiNoScheduledLessons')
          .replaceAll('{date}', label);
    }
    final formatted = lessons
        .map((lesson) {
          final subject =
              lesson['_subjectLong'] ?? lesson['_subjectShort'] ?? '?';
          return '${_formatUntisTime(lesson['startTime'].toString())} $subject';
        })
        .join(', ');
    return AppL10n.of(appLocaleNotifier.value)
        .ui('aiScheduleReply')
        .replaceAll('{date}', label)
        .replaceAll('{lessons}', formatted);
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
    final l = AppL10n.of(appLocaleNotifier.value);
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
    final l = AppL10n.of(appLocaleNotifier.value);
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
    final l = AppL10n.of(appLocaleNotifier.value);
    final relevantExams = _exams
        .where(_examMatchesTimetable)
        .toList(growable: false);
    if (relevantExams.isEmpty) return l.examsNoneEntered;
    final buf = StringBuffer();
    for (final ex in relevantExams) {
      final subject = ex['subject'] ?? ex['subjectName'] ?? '?';
      final type = ex['type'] ?? l.aiDefaultExamType;
      final dateRaw = (ex['date'] ?? ex['examDate'] ?? ex['startDate'] ?? '')
          .toString();
      String dateStr = dateRaw;
      if (dateRaw.length == 8) {
        dateStr =
            '${dateRaw.substring(6, 8)}.${dateRaw.substring(4, 6)}.${dateRaw.substring(0, 4)}';
      }
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

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
        );
      }
    });
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
            content: Text(AppL10n.of(appLocaleNotifier.value).ui('aiAttachmentTooLarge')),
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

  List<_AiProposedAction> _actionsFromReply(String reply) {
    final actions = <_AiProposedAction>[];
    final blocks = RegExp(
      r'```untis-action\s*([\s\S]*?)```',
      multiLine: true,
    ).allMatches(reply);
    for (final block in blocks) {
      try {
        final decoded = jsonDecode(block.group(1)!.trim());
        final values = decoded is List ? decoded : [decoded];
        for (final value in values.whereType<Map>()) {
          final action = _AiProposedAction(Map<String, dynamic>.from(value));
          if (action.isSupported) actions.add(action);
        }
      } catch (_) {}
    }
    return actions;
  }

  Future<void> _applyActions(List<_AiProposedAction> actions) async {
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
          final dateText = date.toString();
          if (dateText.length != 8) continue;
          final gradeDate = DateTime.tryParse(
            '${dateText.substring(0, 4)}-${dateText.substring(4, 6)}-${dateText.substring(6, 8)}',
          );
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

  Future<void> _confirmActions(List<_AiProposedAction> actions) async {
    if (!mounted || actions.isEmpty) return;
    final l = AppL10n.of(appLocaleNotifier.value);
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.ui('aiApplyChangesTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.ui('aiApplyChangesDesc')),
            const SizedBox(height: 12),
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• ${action.summary(l)}'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.ui('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.ui('apply')),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await _applyActions(actions);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.ui('aiChangesApplied'))));
    }
  }

  void _flushStreamingText() {
    _streamRenderTimer?.cancel();
    _streamRenderTimer = null;
    if (!mounted || _pendingStreamText.isEmpty) return;

    final text = _pendingStreamText.toString();
    _pendingStreamText.clear();
    setState(() {
      final lastIndex = _chatMessages.length - 1;
      if (lastIndex >= 0 && _chatMessages[lastIndex]['role'] == 'assistant') {
        final current = _chatMessages[lastIndex]['content'] ?? '';
        _chatMessages[lastIndex]['content'] = current + text;
      }
    });
    _streamingProgressHaptic();
    _scrollToBottom();
  }

  void _streamingProgressHaptic() {
    final now = DateTime.now();
    if (_lastStreamingHapticAt != null &&
        now.difference(_lastStreamingHapticAt!) <
            const Duration(milliseconds: 500)) {
      return;
    }
    _lastStreamingHapticAt = now;
    unawaited(HapticFeedback.lightImpact());
  }

  Future<void> _sendChat(String text) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final provider = _normalizeAiProvider(aiProvider);
    final isLocalProvider = provider == 'local';
    final apiKey = _activeAiApiKey().trim();

    if (isLocalProvider && aiLocalModelPath.isEmpty) {
      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': l.aiLocalModelLoadError,
        });
      });
      return;
    }

    if (!isLocalProvider && apiKey.isEmpty) {
      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': _providerAwareMissingApiKeyMessage(l, provider),
        });
      });
      return;
    }

    final attachments = List<AiChatAttachment>.from(_attachments);
    if (isLocalProvider &&
        attachments.any((attachment) => !attachment.isText)) {
      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content':
              'Dieses lokale Modell kann nur Textdateien lesen. Nutze für Bilder oder PDFs einen passenden Remote-Anbieter.',
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
          _ChatSession(
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

    final factualReply = _deterministicScheduleReply(text);
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

    AIProvider? aiProviderInstance;
    try {
      final model = aiModel.trim().isNotEmpty
          ? aiModel.trim()
          : _defaultModelForProvider(
              provider,
              customCompatibility: aiCustomCompatibility,
            );

      aiProviderInstance = createAIProvider(
        provider: provider,
        model: model,
        apiKey: apiKey,
        customBaseUrl: aiCustomBaseUrl,
        customCompatibility: aiCustomCompatibility,
        localModelPath: isLocalProvider ? aiLocalModelPath : null,
      );

      final systemPrompt = _resolvedChatSystemPrompt();

      setState(() {
        _chatMessages.add({'role': 'assistant', 'content': ''});
      });

      final stream = aiProviderInstance.streamResponse(
        systemPrompt: systemPrompt,
        history: _chatMessages.sublist(0, _chatMessages.length - 1),
        model: model,
        attachments: attachments,
      );

      await for (final chunk in stream) {
        if (!mounted) break;
        _queueStreamingText(chunk);
      }
      _flushStreamingText();
      final rawReply = _chatMessages.isNotEmpty
          ? _chatMessages.last['content'] ?? ''
          : '';
      final actions = _actionsFromReply(rawReply);
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
      _flushStreamingText();
      await aiProviderInstance?.dispose();
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

  String get _currentChatTitle {
    final l = AppL10n.of(appLocaleNotifier.value);
    if (!_chatMode || _currentChatId == null) return l.aiTitle;
    for (final s in _chatHistory) {
      if (s.id == _currentChatId) return s.title;
    }
    return l.aiTitle;
  }

  void _removeChatSession(_ChatSession session) {
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

  Widget _buildSidebar(ColorScheme cs) {
    final l = AppL10n.of(appLocaleNotifier.value);
    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ThemedSurface(
        blur: true,
        respectSurfaceBlurPreference: false,
        borderRadius: BorderRadius.zero,
        color: cs.surface.withValues(alpha: 0.88),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.aiTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.aiAskAnything,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _BouncyButton(
                  onTap: _startNewChat,
                  child: ThemedSurface(
                    blur: false,
                    borderRadius: BorderRadius.circular(18),
                    color: cs.primaryContainer,
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_comment_rounded,
                            color: cs.onPrimaryContainer,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l.bgEditorNew,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text(
                        l.aiTabChat,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    if (_chatHistory.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l.aiAskAnything,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            height: 1.35,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      ..._chatHistory.map((session) {
                        final isSelected = session.id == _currentChatId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _loadSession(session),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  6,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cs.primaryContainer.withValues(
                                          alpha: 0.72,
                                        )
                                      : cs.surfaceContainerHigh.withValues(
                                          alpha: 0.32,
                                        ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? cs.primary.withValues(alpha: 0.28)
                                        : cs.outlineVariant.withValues(
                                            alpha: 0.16,
                                          ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.chat_bubble_rounded
                                          : Icons.chat_bubble_outline_rounded,
                                      size: 18,
                                      color: isSelected
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        session.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? cs.onPrimaryContainer
                                              : cs.onSurface,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l.aiClearResult,
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      onPressed: () =>
                                          _removeChatSession(session),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              if (!_chatMode ||
                  _latestQuery.isNotEmpty ||
                  _latestResult != null) ...[
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: Text(
                    l.aiSearchAgain,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    _hapticSelection();
                    Navigator.pop(context);
                    _handleMenuAction('refresh');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: Text(
                    l.aiClearResult,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    _hapticAction();
                    Navigator.pop(context);
                    _handleMenuAction('clear');
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: Text(
                  l.settingsAiPrompt,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  _hapticSelection();
                  Navigator.pop(context);
                  _openPromptEditor();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(
                  l.aiSettingsMenu,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  _hapticSelection();
                  Navigator.pop(context);
                  _openSettings();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _thinking) return;

    if (_chatMode) {
      await _sendChat(text);
      return;
    }

    final generation = ++_searchGeneration;
    final provider = _normalizeAiProvider(aiProvider);
    final isLocalProvider = provider == 'local';
    if (!isLocalProvider && _activeAiApiKey().trim().isEmpty) {
      final l = AppL10n.of(appLocaleNotifier.value);
      final reply = _providerAwareMissingApiKeyMessage(l, provider);
      if (!mounted) return;
      setState(() {
        _latestQuery = text;
        _latestResult = _parseSearchResult(query: text, reply: reply);
      });
      return;
    }

    _inputController.clear();
    setState(() {
      _latestQuery = text;
      _latestResult = null;
      _thinking = true;
      _typingHintIndex = 0;
    });
    _typingHintTimer?.cancel();
    _typingHintTimer = Timer.periodic(const Duration(milliseconds: 2500), (t) {
      if (!mounted || !_thinking) {
        t.cancel();
        return;
      }
      setState(() => _typingHintIndex = _typingHintIndex + 1);
    });

    try {
      final reply = await _requestProviderResponse(
        _resolvedSystemPrompt(),
        userQuery: text,
      );
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _latestResult = _parseSearchResult(query: text, reply: reply);
      });
    } catch (e) {
      if (!mounted || generation != _searchGeneration) return;
      final message = e.toString();
      final l = AppL10n.of(appLocaleNotifier.value);
      final isApiError = message.contains('API:');
      final isConfigError = message.contains('CONFIG:');
      setState(() {
        final reply = isConfigError
            ? message.replaceFirst('Exception: CONFIG: ', '')
            : isApiError
            ? '${l.aiApiError} ${message.replaceFirst('Exception: API: ', '')}'
            : '${l.aiConnectionError} $e';
        _latestResult = _parseSearchResult(query: text, reply: reply);
      });
    } finally {
      _typingHintTimer?.cancel();
      if (mounted) setState(() => _thinking = false);
      _typingHintIndex = 0;
    }
  }

  Future<void> _sendQuickPrompt(String prompt) async {
    if (_thinking) return;
    _inputController.text = prompt;
    await _send();
  }

  List<String> _buildContextualChips() {
    final l = AppL10n.of(appLocaleNotifier.value);
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

  Widget _buildSearchMetricCard(ColorScheme cs, _AiMetric metric) {
    final icon = _metricIcon(metric.label);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: cs.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchLoadingState(ColorScheme cs) {
    final l = AppL10n.of(appLocaleNotifier.value);
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.manage_search_rounded, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _latestQuery.isEmpty ? l.aiSearchRunning : _latestQuery,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l.aiSearchShapingDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (_latestQuery.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Chip(
                    label: Text(
                      _latestQuery,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: cs.primaryContainer.withValues(
                      alpha: 0.72,
                    ),
                    side: BorderSide.none,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildTypingBubble(cs),
        ],
      ),
    );
  }

  Widget _buildTypingBubble(ColorScheme cs, {bool isChat = false}) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final messages = [
      l.aiStepAnalyzingTimetable,
      l.aiStepSortingResults,
      l.aiStepAlmostDone,
    ];
    final text = isChat
        ? l.aiTyping
        : messages[_typingHintIndex % messages.length];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _Dot(delay: 0),
              SizedBox(width: 4),
              _Dot(delay: 150),
              SizedBox(width: 4),
              _Dot(delay: 300),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                text,
                key: ValueKey(text),
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme cs) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final mq = MediaQuery.of(context);
    final keyboardHeight = mq.viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    final isFocused = _promptFocusNode.hasFocus;

    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        isKeyboardOpen ? (keyboardHeight + 12) : (14 + mq.padding.bottom),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_attachments.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _attachments.indexed
                    .map(
                      (entry) => InputChip(
                        avatar: const Icon(Icons.attach_file_rounded, size: 16),
                        label: Text(entry.$2.name),
                        onDeleted: _thinking
                            ? null
                            : () => setState(
                                () => _attachments.removeAt(entry.$1),
                              ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          Row(
            children: [
              const SizedBox(width: 8),
              if (_chatMode)
                IconButton(
                  onPressed: _thinking ? null : _pickAssistantAttachment,
                  icon: const Icon(Icons.attach_file_rounded),
                  tooltip: AppL10n.of(appLocaleNotifier.value).ui('aiAttachFile'),
                ),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _promptFocusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _send(),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: isFocused ? FontWeight.w700 : FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: _chatMode
                        ? l.aiInputHint
                        : l.aiSearchHintPlaceholder,
                    hintStyle: GoogleFonts.outfit(color: cs.onSurfaceVariant),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_inputController.text.isNotEmpty) ...[
                IconButton(
                  onPressed: _thinking
                      ? null
                      : () {
                          setState(() => _inputController.clear());
                        },
                  icon: Icon(Icons.clear_rounded, color: cs.onSurfaceVariant),
                  tooltip: l.aiClearInput,
                ),
              ],
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _thinking ? null : _send,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: _legacyButtonShape(context, 18),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _thinking
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: cs.onPrimary,
                          ),
                        )
                      : Icon(
                          _chatMode ? Icons.send_rounded : Icons.search_rounded,
                          key: ValueKey<bool>(isFocused ^ _chatMode),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(ColorScheme cs) {
    final result = _latestResult;
    final l = AppL10n.of(appLocaleNotifier.value);
    if (result == null) {
      if (_thinking) {
        return _buildSearchLoadingState(cs);
      }
      return _buildEmptyState(cs);
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        result.headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                          color: cs.onSurface,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  result.summary,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                if (result.tags.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.tags.take(4).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: cs.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (result.metrics.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  l.aiOverview,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                final columns = isWide ? 3 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: result.metrics
                      .map((metric) => _buildSearchMetricCard(cs, metric))
                      .toList(),
                );
              },
            ),
          ],
          if (result.lessons.isNotEmpty) ...[
            const SizedBox(height: 26),
            Row(
              children: [
                Icon(Icons.school_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  l.aiLessons,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...result.lessons.map(
              (lesson) => LessonCard(
                subject: lesson.subject,
                subjectShort: lesson.subjectShort,
                room: lesson.room,
                teacher: lesson.teacher,
                time: lesson.time,
                isCancelled: lesson.isCancelled,
              ),
            ),
          ],
          if (_thinking) ...[const SizedBox(height: 8), _buildTypingBubble(cs)],
        ],
      ),
    );
  }

  Widget _buildChipRow(ColorScheme cs) {
    final chips = _buildContextualChips();
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _buildChip(cs, chips[i], i == 0),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(ColorScheme cs, String text, bool first) {
    final chip = ActionChip(
      key: first ? _firstChipKey : null,
      label: Text(
        text,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      backgroundColor: cs.primaryContainer.withValues(alpha: 0.72),
      side: BorderSide.none,
      onPressed: _thinking
          ? null
          : () {
              _hapticSelection();
              _sendQuickPrompt(text);
            },
    );
    return first ? chip : chip;
  }

  Widget _buildChatView(ColorScheme cs) {
    if (_chatMessages.isEmpty && !_thinking) {
      return _buildEmptyState(cs);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      itemCount: _chatMessages.length + (_thinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _chatMessages.length) {
          final isThinkingOfLastMessage =
              _chatMessages.isNotEmpty &&
              _chatMessages.last['role'] == 'assistant' &&
              _chatMessages.last['content']!.isEmpty;
          if (isThinkingOfLastMessage) return const SizedBox.shrink();
          return _buildTypingBubble(cs, isChat: true);
        }
        final msg = _chatMessages[index];
        final isUser = msg['role'] == 'user';
        return _buildChatBubble(cs, msg['content']!, isUser);
      },
    );
  }

  Widget _buildChatBubble(ColorScheme cs, String content, bool isUser) {
    if (!isUser && content.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _Dot(delay: 0),
              SizedBox(width: 4),
              _Dot(delay: 150),
              SizedBox(width: 4),
              _Dot(delay: 300),
            ],
          ),
        ),
      );
    }
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? cs.primary
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: isUser
              ? null
              : Border.all(color: cs.outlineVariant.withValues(alpha: 0.1)),
          boxShadow: isUser && untisThemeTokensOf(context).glowEffectsEnabled
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isUser
            ? Text(
                content,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimary,
                ),
              )
            : MarkdownBody(
                data: content,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                      p: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                        height: 1.5,
                      ),
                      strong: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                      listBullet: GoogleFonts.outfit(color: cs.primary),
                    ),
              ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    return Column(
      children: [
        if (!_chatMode && _latestResult == null && !_thinking)
          _buildChipRow(cs),
        Expanded(
          child: _chatMode ? _buildChatView(cs) : _buildResultHeader(cs),
        ),
        _buildSearchBar(cs),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    final l = AppL10n.of(appLocaleNotifier.value);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _glowShadows(context, [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 32,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _chatMode ? l.aiChatTitle : l.aiEmptyPromptTitle,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -1.0,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _chatMode ? l.aiChatSubtitle : l.aiEmptyPromptSubtitle,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          if (_chatMode) ...[
            Text(
              l.aiTryIt,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: cs.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            for (final suggestion in l.aiChatSuggestions.indexed)
              _buildChatSuggestion(
                cs,
                suggestion.$2,
                const [
                  Icons.trending_up_rounded,
                  Icons.lightbulb_outline_rounded,
                  Icons.edit_note_rounded,
                ][suggestion.$1],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatSuggestion(ColorScheme cs, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _hapticSelection();
          _sendQuickPrompt(text);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: cs.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: RoundedBlurAppBar(
          title: Text(
            l.aiTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(child: CircularProgressIndicator(color: cs.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      appBar: RoundedBlurAppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {
            _hapticSelection();
            widget.onOpenDrawer?.call(_buildSidebar(cs));
          },
        ),
        title: Text(
          _currentChatTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: _selectAiTab,
          indicatorColor: cs.primary,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.analytics_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(l.aiTabAnalysis),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(l.aiTabChat),
                ],
              ),
            ),
          ],
        ),
      ),
      // MainNavigationScreen already provides the shared themed backdrop.
      // Adding a second animated scene here doubled paint work for this tab.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final body = _buildBody(cs);
          if (!UntisLayout.isTablet(context)) return body;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: SizedBox(height: constraints.maxHeight, child: body),
            ),
          );
        },
      ),
    );
  }
}

class _MainTabFadeUp extends StatefulWidget {
  final bool active;
  final bool enabled;
  final Widget child;

  const _MainTabFadeUp({
    required this.active,
    required this.enabled,
    required this.child,
  });

  @override
  State<_MainTabFadeUp> createState() => _MainTabFadeUpState();
}

class _MainTabFadeUpState extends State<_MainTabFadeUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    final expo = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(expo);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.055),
      end: Offset.zero,
    ).animate(expo);

    if (!widget.enabled) {
      _controller.value = 1;
    } else if (widget.active) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _MainTabFadeUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _controller.value = 1;
      return;
    }
    if (!oldWidget.enabled && widget.active) {
      // Enabling the setting from the currently visible Settings tab should
      // not make that screen jump. The animation starts on the next tab entry.
      _controller.value = 1;
    } else if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
    } else if (!widget.active && oldWidget.active) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || MediaQuery.of(context).disableAnimations) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _MainTabTransitionLayer extends StatelessWidget {
  final bool active;
  final int relativePosition;
  final int transitionType;
  final Widget child;

  const _MainTabTransitionLayer({
    super.key,
    required this.active,
    required this.relativePosition,
    required this.transitionType,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final type = transitionType.clamp(0, 7);
    final duration = reduceMotion
        ? Duration.zero
        : Duration(
            milliseconds: switch (type) {
              0 => 420,
              7 => 440,
              _ => 340,
            },
          );

    final motionCurve = switch (type) {
      0 => Curves.easeOutBack,
      5 => Curves.easeInCubic,
      6 => Curves.easeOutCubic,
      7 => const Cubic(0.16, 1.0, 0.3, 1.0),
      _ => Curves.easeOutCubic,
    };
    final fadeCurve = switch (type) {
      5 => Curves.easeInCubic,
      7 => const Cubic(0.16, 1.0, 0.3, 1.0),
      _ => Curves.easeOutCubic,
    };

    final direction = relativePosition < 0 ? -1.0 : 1.0;
    var targetOffset = Offset.zero;
    var targetScale = 1.0;

    if (!active) {
      switch (type) {
        case 0:
          targetOffset = const Offset(0, 0.035);
          targetScale = 0.965;
          break;
        case 2:
          targetOffset = Offset(0.065 * direction, 0);
          break;
        case 3:
          targetScale = 0.92;
          break;
        case 4:
          targetScale = 0.985;
          break;
        case 5:
        case 6:
          targetOffset = const Offset(0, 0.045);
          break;
        case 7:
          targetOffset = const Offset(0, 0.065);
          targetScale = 0.985;
          break;
      }
    }

    Widget content = child;
    if (type == 4) {
      content = AnimatedScale(
        scale: targetScale,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: content,
      );
    } else {
      content = AnimatedScale(
        scale: targetScale,
        duration: duration,
        curve: motionCurve,
        child: content,
      );
    }

    content = AnimatedSlide(
      offset: targetOffset,
      duration: duration,
      curve: motionCurve,
      child: content,
    );
    content = AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: duration,
      curve: fadeCurve,
      child: content,
    );

    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: RepaintBoundary(child: content),
      ),
    );
  }
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
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

  List<int> get _tutorialTargets => const [0, 1, 2, 4, 3];

  @override
  void initState() {
    super.initState();
    _notificationActionSub = NotificationService().actionEvents.listen(
      _handleNotificationAction,
    );
    pendingAssistantOpenNotifier.addListener(_openAssistantFromNative);
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
        final p = await SharedPreferences.getInstance();
        await p.remove('showChangelogPending');
        if (mounted) showChangelogSheet(context);
      });
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
    pendingTimetableActionNotifier.value = 'open_timetable';
  }

  void _openAssistantFromNative() {
    if (!mounted || !pendingAssistantOpenNotifier.value) return;
    pendingAssistantOpenNotifier.value = false;
    _onNavTap(4);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorialCompleted', true);
    await prefs.setInt('tutorialVersionCompleted', kCurrentTutorialVersion);
    if (!mounted) return;
    setState(() {
      _showTutorial = false;
      _tutorialStep = 0;
    });
  }

  Future<void> _skipTutorial() async {
    await _finishTutorial();
  }

  bool _isTutorialTarget(int index) {
    if (!_showTutorial || _tutorialStep >= _tutorialTargets.length) {
      return false;
    }
    return _tutorialTargets[_tutorialStep] == index;
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
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  String _tutorialTitle(AppL10n l) {
    switch (_tutorialStep) {
      case 0:
        return l.tutorialStepWeekTitle;
      case 1:
        return l.tutorialStepExamsTitle;
      case 2:
        return l.tutorialStepInfoTitle;
      case 3:
        return l.tutorialStepAiTitle;
      case 4:
        return l.tutorialStepSettingsTitle;
      default:
        return l.tutorialStepFinishTitle;
    }
  }

  String _tutorialDesc(AppL10n l) {
    switch (_tutorialStep) {
      case 0:
        return l.tutorialStepWeekDesc;
      case 1:
        return l.tutorialStepExamsDesc;
      case 2:
        return l.tutorialStepInfoDesc;
      case 3:
        return l.tutorialStepAiDesc;
      case 4:
        return l.tutorialStepSettingsDesc;
      default:
        return l.tutorialStepFinishDesc;
    }
  }

  Widget _buildPageWithBackground(BuildContext context, Widget page) {
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    if (tokens.id != AppThemeId.defaultTheme) {
      return ValueListenableBuilder<int>(
        valueListenable: backgroundAnimationStyleNotifier,
        builder: (context, style, _) => ValueListenableBuilder<bool>(
          valueListenable: backgroundAnimationsNotifier,
          builder: (context, enabled, _) => ThemedBackdrop(
            animate: enabled,
            backgroundStyle: style,
            child: page,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(color: cs.surface)),
        ),
        Positioned.fill(
          child: ValueListenableBuilder<bool>(
            valueListenable: backgroundAnimationsNotifier,
            builder: (context, enabled, _) {
              if (!enabled) return const SizedBox.shrink();
              return ValueListenableBuilder<int>(
                valueListenable: backgroundAnimationStyleNotifier,
                builder: (context, style, _) {
                  return IgnorePointer(
                    ignoring: true,
                    child: Opacity(
                      opacity: Theme.of(context).brightness == Brightness.dark
                          ? 0.28
                          : 0.2,
                      child: _AnimatedBackgroundScene(style: style),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Positioned.fill(child: page),
      ],
    );
  }

  List<Widget> get _pages => <Widget>[
    WeeklyTimetablePage(key: ValueKey(activeUntisAccountId ?? 'active')),
    const ExamsPage(),
    const SchoolNotificationsPage(),
    const SettingsHubPage(),
    AiAssistantPage(
      key: ValueKey(activeUntisAccountId ?? 'active'),
      onBackToTimetable: () => _onNavTap(0),
      onOpenDrawer: (drawer) {
        setState(() => _currentDrawer = drawer);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scaffoldKey.currentState?.openDrawer();
        });
      },
    ),
  ];

  @override
  void dispose() {
    _notificationActionSub?.cancel();
    pendingAssistantOpenNotifier.removeListener(_openAssistantFromNative);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final isTablet = UntisLayout.isTablet(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _currentDrawer,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Row(
            children: [
              if (isTablet)
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onNavTap,
                    labelType: NavigationRailLabelType.selected,
                    groupAlignment: 0,
                    destinations: [
                      NavigationRailDestination(
                        icon: const Icon(Icons.watch_later_outlined),
                        selectedIcon: KeyedSubtree(
                          key: _tutorialNavKeys[0],
                          child: const Icon(Icons.watch_later_rounded),
                        ),
                        label: Text(l.timetableTitle),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.event_note_outlined),
                        selectedIcon: KeyedSubtree(
                          key: _tutorialNavKeys[1],
                          child: const Icon(Icons.event_note_rounded),
                        ),
                        label: Text(l.examsTitle),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.campaign_outlined),
                        selectedIcon: KeyedSubtree(
                          key: _tutorialNavKeys[2],
                          child: const Icon(Icons.campaign_rounded),
                        ),
                        label: Text(l.navInfo),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.settings_outlined),
                        selectedIcon: KeyedSubtree(
                          key: _tutorialNavKeys[3],
                          child: const Icon(Icons.settings_rounded),
                        ),
                        label: Text(l.navMenu),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.auto_awesome_outlined),
                        selectedIcon: KeyedSubtree(
                          key: _tutorialNavKeys[4],
                          child: const Icon(Icons.auto_awesome_rounded),
                        ),
                        label: Text(l.navAi),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: MediaQuery(
                  data: mq.copyWith(
                    padding: mq.padding.copyWith(
                      bottom: isTablet
                          ? mq.padding.bottom
                          : mq.padding.bottom + 104,
                    ),
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: pageTransitionNotifier,
                    builder: (context, transitionType, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: mainTabFadeUpEnabledNotifier,
                        builder: (context, fadeUpEnabled, _) {
                          final pages = _pages;
                          return Stack(
                            fit: StackFit.expand,
                            children: pages.asMap().entries.map((entry) {
                              final active = entry.key == _selectedIndex;
                              return _MainTabTransitionLayer(
                                key: ValueKey('main-tab-layer-${entry.key}'),
                                active: active,
                                relativePosition: entry.key - _selectedIndex,
                                transitionType: transitionType,
                                child: TickerMode(
                                  enabled: active,
                                  child: _buildPageWithBackground(
                                    context,
                                    _MainTabFadeUp(
                                      active: active,
                                      enabled: fadeUpEnabled,
                                      child: entry.value,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(growable: false),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          // Floating nav bar
          if (!isTablet)
            Positioned(
              left: 16,
              right: 16,
              bottom: mq.padding.bottom + 16,
              child: ValueListenableBuilder<String>(
                valueListenable: appLocaleNotifier,
                builder: (context, locale, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: unreadTimetableChangesNotifier,
                    builder: (context, unreadChanges, _) =>
                        _buildFloatingNavBar(context, cs),
                  );
                },
              ),
            ),
          if (_showTutorial)
            Positioned.fill(
              child: _TutorialSpotlightOverlay(
                key: ValueKey(_tutorialStep),
                targetKey: _tutorialNavKeys[_tutorialTargets[_tutorialStep]],
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
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, ColorScheme cs) {
    final timetableSelected = _selectedIndex == 0;
    final l = AppL10n.of(appLocaleNotifier.value);

    // ---- Secondary items (indices 1-4) shown in the pill bar ----
    final items = [
      _NavItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: l.navMenu,
        pageIndex: 3,
        tutorialKey: _tutorialNavKeys[3],
        tutorialHighlight: _isTutorialTarget(3),
      ),
      _NavItem(
        icon: Icons.campaign_outlined,
        selectedIcon: Icons.campaign_rounded,
        label: l.navInfo,
        pageIndex: 2,
        tutorialKey: _tutorialNavKeys[2],
        tutorialHighlight: _isTutorialTarget(2),
      ),
      _NavItem(
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment_rounded,
        label: l.navExams,
        pageIndex: 1,
        tutorialKey: _tutorialNavKeys[1],
        tutorialHighlight: _isTutorialTarget(1),
      ),
      _NavItem(
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome_rounded,
        label: l.navAi,
        pageIndex: 4,
        tutorialKey: _tutorialNavKeys[4],
        tutorialHighlight: _isTutorialTarget(4),
      ),
    ];

    // Which item in the secondary bar is selected? -1 = none (timetable active)
    final selectedBarIndex = items.indexWhere(
      (item) => item.pageIndex == _selectedIndex,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ---- Pill nav bar ----
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 560),
              curve: _kSmoothBounce,
              builder: (context, val, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - val) * 26),
                  child: Opacity(opacity: val.clamp(0, 1), child: child),
                );
              },
              child: _ExpressiveNavBar(
                items: items,
                selectedIndex: selectedBarIndex,
                colorScheme: cs,
                onTap: (pageIndex) => _onNavTap(pageIndex),
              ),
            ),

            const SizedBox(width: 12),

            // ---- FAB timetable button ----
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 620),
              curve: _kSmoothBounce,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - value) * 20),
                  child: Transform.scale(
                    scale: 0.92 + (value * 0.08),
                    child: Opacity(opacity: value.clamp(0, 1), child: child),
                  ),
                );
              },
              child: KeyedSubtree(
                key: _tutorialNavKeys[0],
                child: _BouncyButton(
                  onTap: () => _onNavTap(0),
                  scaleTarget: 0.88,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: blurEnabledNotifier,
                    builder: (context, blurEnabled, _) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 480),
                        curve: _kSoftBounce,
                        height: _ExpressiveNavBarState._barHeight,
                        width: _ExpressiveNavBarState._barHeight,
                        child: ThemedSurface(
                          blur: !timetableSelected,
                          respectSurfaceBlurPreference: false,
                          respectSurfaceCornerPreference: false,
                          color: timetableSelected
                              ? cs.primary
                              : cs.surfaceContainerHigh.withValues(
                                  alpha: blurEnabled ? 0.72 : 1,
                                ),
                          borderRadius: BorderRadius.circular(
                            timetableSelected ? 22 : 18,
                          ),
                          border: Border.all(
                            color: _isTutorialTarget(0)
                                ? cs.tertiary
                                : timetableSelected
                                ? cs.primary.withValues(alpha: 0.38)
                                : cs.outlineVariant.withValues(alpha: 0.30),
                            width: _isTutorialTarget(0) ? 2.0 : 0.8,
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              switchInCurve: _kSmoothBounce,
                              switchOutCurve: _kSoftBounce,
                              transitionBuilder: (child, anim) {
                                final slide = Tween<Offset>(
                                  begin: const Offset(0, 0.15),
                                  end: Offset.zero,
                                ).animate(anim);
                                return FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: slide,
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 0.85,
                                        end: 1.0,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: AnimatedRotation(
                                turns: timetableSelected ? 0 : -0.03,
                                duration: const Duration(milliseconds: 400),
                                curve: _kSmoothBounce,
                                child: Icon(
                                  timetableSelected
                                      ? Icons.watch_later_rounded
                                      : Icons.watch_later_outlined,
                                  key: ValueKey('timetable_$timetableSelected'),
                                  color: timetableSelected
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                  size: timetableSelected ? 34 : 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Material You Expressive Navigation Bar
// ---------------------------------------------------------------------------

class _TutorialSpotlightOverlay extends StatelessWidget {
  final GlobalKey? targetKey;
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
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.description,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.isLast,
  });

  Rect? _targetRect() {
    final targetContext = targetKey?.currentContext;
    final renderObject = targetContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);

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
        final target = (_targetRect() ?? fallback).inflate(9).intersect(bounds);

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

        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TutorialSpotlightPainter(
                    target: target,
                    scrim: Colors.black.withValues(alpha: 0.58),
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
        );
      },
    );
  }
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
    final l = AppL10n.of(appLocaleNotifier.value);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
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
  final bool tutorialHighlight;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.pageIndex,
    this.tutorialKey,
    this.tutorialHighlight = false,
  });
}

/// A pill-indicator navigation bar whose indicator morphs via spring physics
/// between destinations – matching the Material 3 Expressive spec.
class _ExpressiveNavBar extends StatefulWidget {
  final List<_NavItem> items;
  final int selectedIndex; // -1 = nothing selected
  final ColorScheme colorScheme;
  final void Function(int pageIndex) onTap;

  const _ExpressiveNavBar({
    required this.items,
    required this.selectedIndex,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  State<_ExpressiveNavBar> createState() => _ExpressiveNavBarState();
}

class _ExpressiveNavBarState extends State<_ExpressiveNavBar>
    with TickerProviderStateMixin {
  // Morphing stage: a spring simulation drives t (0..1, with slight overshoot)
  // between the previously rendered layout ("from") and the target layout ("to").
  late AnimationController _morphController;

  // Alpha animation for the "no selection" state (pill fades out)
  late AnimationController _visibilityController;
  late Animation<double> _pillAlpha;

  // Per-item icon wiggle
  final List<AnimationController> _iconWiggle = [];

  static const _itemWidth = 46.0;
  static const _pillBaseWidth = 42.0;
  static const _pillExpandedExtra = 56.0; // extra px when label visible
  static const _pillHeight = 44.0;
  static const _barHeight = 64.0;
  static const _barHPad = 8.0;
  static const _itemGap = 2.0;

  // From-state (frozen at the start of the current morph)
  List<double> _fromWidths = const [];
  double _fromLeft = 0;
  double _fromWidth = _pillBaseWidth;

  // Target selection
  int _targetSel = -1;
  double _targetFrac = 1.0;

  // Last rendered state (used as the start point of the next morph)
  List<double> _lastWidths = const [];
  double _lastLeft = 0;
  double _lastWidth = _pillBaseWidth;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController.unbounded(vsync: this);

    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.selectedIndex >= 0 ? 1.0 : 0.0,
    );
    _pillAlpha = _visibilityController;

    for (int i = 0; i < widget.items.length; i++) {
      _iconWiggle.add(
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 380),
        ),
      );
    }

    final sel = widget.selectedIndex;
    _targetSel = sel;
    _targetFrac = 1.0;
    if (sel >= 0) {
      final layout = _layoutFor(sel, 1.0);
      _fromLeft = _lastLeft = layout.left;
      _fromWidth = _lastWidth = layout.width;
      _fromWidths = _lastWidths = List.of(layout.widths);
      _morphController.value = 1.0;
    } else {
      _fromWidths = _lastWidths = List.generate(
        widget.items.length,
        (_) => _itemWidth,
        growable: false,
      );
    }
  }

  @override
  void didUpdateWidget(_ExpressiveNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex == widget.selectedIndex) return;

    final newSel = widget.selectedIndex;
    final wasHidden = _pillAlpha.value < 0.05;

    // Freeze the currently rendered layout as the morph start point.
    _fromLeft = _lastLeft;
    _fromWidth = _lastWidth;
    _fromWidths = List.of(_lastWidths);

    if (newSel < 0) {
      // Timetable selected -> fold pill to compact size in place and fade out.
      _targetSel = _targetSel >= 0 ? _targetSel : 0;
      _targetFrac = 0.0;
      _visibilityController.reverse();
    } else if (wasHidden) {
      // Coming from a hidden state -> grow the compact pill at the new tab.
      final compact = _layoutFor(newSel, 0.0);
      _fromLeft = compact.left;
      _fromWidth = compact.width;
      _fromWidths = List.of(compact.widths);
      _targetSel = newSel;
      _targetFrac = 1.0;
      _visibilityController.forward();
    } else {
      // Secondary tab -> secondary tab: morph between the two layouts.
      _targetSel = newSel;
      _targetFrac = 1.0;
      _visibilityController.forward();
    }

    if (newSel >= 0 && newSel < _iconWiggle.length) {
      _iconWiggle[newSel].forward(from: 0);
    }

    _animateMorph();
  }

  void _animateMorph() {
    _morphController.value = 0;
    final spring = SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: 460,
      ratio: 0.78,
    );
    final sim = SpringSimulation(
      spring,
      0,
      1.0,
      0, // initial velocity
    );
    _morphController.animateWith(sim);
  }

  ({double left, double width, List<double> widths}) _layoutFor(
    int sel,
    double frac,
  ) {
    final widths = List.generate(widget.items.length, (i) {
      if (sel >= 0 && i == sel) {
        return _pillBaseWidth + frac * _pillExpandedExtra;
      }
      return _itemWidth;
    });
    var left = _barHPad;
    if (sel >= 0) {
      left += widths.take(sel).fold(0.0, (a, b) => a + b) + sel * _itemGap;
    }
    final width = sel >= 0 ? widths[sel] : _pillBaseWidth;
    return (left: left, width: width, widths: widths);
  }

  @override
  void dispose() {
    _morphController.dispose();
    _visibilityController.dispose();
    for (final c in _iconWiggle) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    final n = widget.items.length;
    final tokens = untisThemeTokensOf(context);
    final navRadius = BorderRadius.circular(switch (tokens.id) {
      AppThemeId.defaultTheme => 35,
      AppThemeId.manga => 2,
      _ => tokens.controlRadius + 8,
    });

    return ThemedSurface(
      respectSurfaceBlurPreference: false,
      respectSurfaceCornerPreference: false,
      borderRadius: navRadius,
      color: cs.surfaceContainerHigh.withValues(
        alpha:
            tokens.id == AppThemeId.defaultTheme ||
                tokens.id == AppThemeId.manga
            ? 0.66
            : tokens.navigationOpacity,
      ),
      border: Border.all(
        color: tokens.id == AppThemeId.manga
            ? cs.outline
            : cs.outlineVariant.withValues(alpha: 0.32),
        width: tokens.borderWidth,
      ),
      child: Container(
        height: _barHeight,
        padding: const EdgeInsets.symmetric(horizontal: _barHPad),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _morphController,
            _visibilityController,
          ]),
          builder: (context, _) {
            final t = _morphController.value.clamp(0.0, 1.1);
            final to = _layoutFor(_targetSel, _targetFrac);

            // Interpolate every item width (and the pill rect) from the frozen
            // start layout toward the target layout – this keeps the pill glued
            // to the moving items without the reference-frame jumps.
            final widths = List.generate(n, (i) {
              final from = i < _fromWidths.length ? _fromWidths[i] : _itemWidth;
              return from + (to.widths[i] - from) * t;
            });
            final pillLeft = _fromLeft + (to.left - _fromLeft) * t;
            final pillWidth = _fromWidth + (to.width - _fromWidth) * t;

            // Render snapshot (start point for the next morph).
            _lastWidths = List.of(widths);
            _lastLeft = pillLeft;
            _lastWidth = pillWidth;

            // Total bar content width
            final totalW =
                widths.fold(0.0, (a, b) => a + b) +
                (n - 1) * _itemGap; // gaps between items
            final pillAlpha = _pillAlpha.value;

            return SizedBox(
              width: totalW,
              height: _barHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ---- Morphing pill indicator ----
                  Positioned(
                    left: pillLeft - _barHPad,
                    child: Opacity(
                      opacity: pillAlpha.clamp(0.0, 1.0),
                      child: Container(
                        width: pillWidth,
                        height: _pillHeight,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(
                            tokens.id == AppThemeId.cyber
                                ? tokens.controlRadius
                                : _pillHeight / 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ---- Items row ----
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < n; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        _buildItem(i, widths[i], t, cs),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItem(int i, double width, double labelT, ColorScheme cs) {
    final item = widget.items[i];
    final selected = widget.selectedIndex == i;
    final wiggle = _iconWiggle[i];

    return GestureDetector(
      key: item.tutorialKey,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap(item.pageIndex);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: _barHeight,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Icon with wiggle ---
              AnimatedBuilder(
                animation: wiggle,
                builder: (context, child) {
                  // Spring-style wiggle: sin wave decaying
                  final t = wiggle.value;
                  final angle = math.sin(t * math.pi * 4) * 0.08 * (1 - t);
                  return Transform.rotate(angle: angle, child: child);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: _kSmoothBounce,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: Tween(begin: 0.7, end: 1.0).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    key: ValueKey('${item.pageIndex}_$selected'),
                    size: selected ? 22 : 24,
                    color: selected
                        ? cs.onPrimary
                        : item.tutorialHighlight
                        ? cs.tertiary
                        : cs.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ),

              // --- Label (slides in/out with the morph) ---
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: selected ? labelT.clamp(0.0, 1.0) : 0,
                  child: Opacity(
                    opacity: (selected ? labelT : 0.0).clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        item.label,
                        style: untisThemeTextStyle(
                          context,
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

// Bouncy press helper (unchanged)
// ---------------------------------------------------------------------------
class _BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleTarget;

  const _BouncyButton({
    required this.child,
    required this.onTap,
    this.scaleTarget = 0.9,
  });

  @override
  State<_BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<_BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _tapLocked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleTarget)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: _kSoftBounce,
            reverseCurve: _kSmoothBounce,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (_tapLocked) return;
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTap: () {
        if (_tapLocked) return;
        _tapLocked = true;
        widget.onTap();
        _controller.reverse();
        Future.delayed(const Duration(milliseconds: 140), () {
          if (!mounted) return;
          _tapLocked = false;
        });
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
