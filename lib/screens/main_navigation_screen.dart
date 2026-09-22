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

class _AiAssistantPageState extends State<AiAssistantPage>
    with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final FocusNode _promptFocusNode = FocusNode();
  late TabController _tabController;
  Timer? _streamRenderTimer;
  final StringBuffer _pendingStreamText = StringBuffer();
  DateTime? _lastStreamingHapticAt;
  int _searchGeneration = 0;
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
  bool _loading = true;
  bool _thinking = false;
  bool _chatMode = false;
  final List<Map<String, String>> _chatMessages = [];
  final List<AiChatAttachment> _attachments = [];
  final List<AiChatSession> _chatHistory = [];
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
      final prefs = await SharedPreferences.getInstance();
      await AiChatHistoryStore(prefs).write(_chatHistory);
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

  void _loadSession(AiChatSession session) {
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
    _streamRenderTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetSearchState() {
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

  AiSearchResult _parseSearchResult({
    required String query,
    required String reply,
  }) {
    return parseAiSearchResult(
      query: query,
      reply: reply,
      emptyHeadline: AppL10n.of(appLocaleNotifier.value).aiNewSearch,
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
    await Navigator.of(context).push(_buildBouncyRoute(const SettingsAiPage()));
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
        return requestLocalModelText(
          systemPrompt: systemPrompt,
          userQuery: userQuery,
          modelPath: aiLocalModelPath,
          runtime: _currentLocalModelRuntime(),
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
      return l.ui('aiDayDataUnavailable').replaceAll('{date}', dateLabel);
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
      return AppL10n.of(
        appLocaleNotifier.value,
      ).ui('aiWeekDataUnavailable').replaceAll('{date}', label);
    }
    final lessons = (_weekData[index] ?? const <dynamic>[])
        .whereType<Map>()
        .where(
          (lesson) => lesson['code']?.toString().toLowerCase() != 'cancelled',
        )
        .toList(growable: false);
    if (lessons.isEmpty) {
      return AppL10n.of(
        appLocaleNotifier.value,
      ).ui('aiNoScheduledLessons').replaceAll('{date}', label);
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
            content: Text(
              AppL10n.of(appLocaleNotifier.value).ui('aiAttachmentTooLarge'),
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

  Future<void> _confirmActions(List<AiProposedAction> actions) async {
    if (!mounted || actions.isEmpty) return;
    final l = AppL10n.of(appLocaleNotifier.value);
    final approved = await showUntisDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.ui('aiApplyChangesTitle')),
        content: SingleChildScrollView(
          child: _AiActionConfirmationContent(actions: actions),
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
      if (mounted) setState(() => _thinking = false);
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

    Widget _buildSearchLoadingState() {
    return _AiAnalysisLoadingState(query: _latestQuery);
  }

  Widget _buildSearchBar() {
    final l = AppL10n.of(appLocaleNotifier.value);
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

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      children: [
        if (activeTitle != null && activeTitle.trim().isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 14),
            child: Text(
              activeTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: untisThemeTextStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
        for (final entry in _chatMessages.indexed)
          _AiChatMessage(
            content: entry.$2['content'] ?? '',
            isUser: entry.$2['role'] == 'user',
            streaming:
                _thinking &&
                entry.$2['role'] == 'assistant' &&
                entry.$1 == _chatMessages.length - 1,
          ),
        if (showExtraTyping)
          const _AiChatMessage(
            content: '',
            isUser: false,
            streaming: true,
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
                ? _kAiReducedMotion
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
              key: ValueKey(mode),
              child: _chatMode ? _buildChatView(cs) : _buildResultHeader(cs),
            ),
          ),
        ),
        _buildSearchBar(),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    final l = AppL10n.of(appLocaleNotifier.value);
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
            for (final suggestion in l.aiChatSuggestions.indexed)
              _AiSuggestionCard(
                text: suggestion.$2,
                icon: suggestionIcons[suggestion.$1 % suggestionIcons.length],
                onTap: () {
                  _hapticSelection();
                  unawaited(_sendQuickPrompt(suggestion.$2));
                },
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
                    icon: suggestionIcons[
                        suggestion.$1 % suggestionIcons.length
                    ],
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
    final l = AppL10n.of(appLocaleNotifier.value);
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
                        child: CircularProgressIndicator(
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
          final body = _buildBody(cs);
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
    final duration = reduceMotion ? Duration.zero : _pageMotionDuration(type);
    final direction = relativePosition < 0 ? -1.0 : 1.0;
    final hiddenOffset = _pageMotionOffset(type, direction: direction);
    final hiddenScale = _pageMotionScale(type);
    final hiddenBlur = _pageMotionBlur(type);
    final curve = _pageMotionCurve(type);

    Widget content = child;

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
    SchoolNotificationsPage(isActive: _selectedIndex == 2),
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
                  child: ValueListenableBuilder<bool>(
                    valueListenable: mainTabFadeUpEnabledNotifier,
                    builder: (context, animationsEnabled, _) {
                      final pages = _pages;

                      if (!animationsEnabled ||
                          MediaQuery.of(context).disableAnimations) {
                        return IndexedStack(
                          index: _selectedIndex,
                          children: pages
                              .asMap()
                              .entries
                              .map((entry) {
                                final active = entry.key == _selectedIndex;
                                return TickerMode(
                                  enabled: active,
                                  child: _buildPageWithBackground(
                                    context,
                                    entry.value,
                                  ),
                                );
                              })
                              .toList(growable: false),
                        );
                      }

                      return ValueListenableBuilder<int>(
                        valueListenable: pageTransitionNotifier,
                        builder: (context, transitionType, _) {
                          return Stack(
                            fit: StackFit.expand,
                            children: pages
                                .asMap()
                                .entries
                                .map((entry) {
                                  final active = entry.key == _selectedIndex;
                                  return _MainTabTransitionLayer(
                                    key: ValueKey(
                                      'main-tab-layer-${entry.key}',
                                    ),
                                    active: active,
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
          // Floating nav bar
          if (!isTablet)
            Positioned(
              left: 16,
              right: 16,
              bottom: mq.padding.bottom + 16,
              child: ValueListenableBuilder<String>(
                valueListenable: appLocaleNotifier,
                builder: (context, locale, _) {
                  return ListenableBuilder(
                    listenable: Listenable.merge([
                      unreadTimetableChangesNotifier,
                      unreadInboxMessagesNotifier,
                    ]),
                    builder: (context, _) =>
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
        badgeCount: unreadInboxMessagesNotifier.value,
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
    final tokens = untisThemeTokensOf(context);
    final useBackdropBlur = _usesModalBackdropBlur(context);
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
            if (useBackdropBlur)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _TutorialSpotlightClipper(target),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: tokens.blurSigma,
                        sigmaY: tokens.blurSigma,
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
                        ? Colors.transparent
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
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.pageIndex,
    this.tutorialKey,
    this.tutorialHighlight = false,
    this.badgeCount = 0,
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

  // Per-item label reveal controller. The pill width morphs for both the
  // outgoing and the incoming tab, so the label must animate out as well –
  // otherwise a deselected tab's label/width snaps back instantly.
  final List<AnimationController> _labelControllers = [];

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

    final initialSel = widget.selectedIndex;
    for (int i = 0; i < widget.items.length; i++) {
      _labelControllers.add(
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
          value: i == initialSel ? 1.0 : 0.0,
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

    final oldSel = oldWidget.selectedIndex;
    if (oldSel >= 0 && oldSel < _labelControllers.length) {
      // Outgoing tab label slides away while the pill morphs to the new tab.
      _labelControllers[oldSel].reverse();
    }
    if (newSel >= 0 && newSel < _labelControllers.length) {
      _labelControllers[newSel].forward();
    }

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
    for (final c in _labelControllers) {
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
            ..._labelControllers,
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
              Stack(
                clipBehavior: Clip.none,
                children: [
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
                  if (item.badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3.5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(minWidth: 13),
                        decoration: BoxDecoration(
                          color: cs.error,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: cs.surfaceContainerHigh,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          item.badgeCount > 99
                              ? '99+'
                              : '${item.badgeCount}',
                          style: TextStyle(
                            color: cs.onError,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              // --- Label (slides in/out with the morph) ---
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: _labelControllers[i].value,
                  child: Opacity(
                    opacity: _labelControllers[i].value,
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
