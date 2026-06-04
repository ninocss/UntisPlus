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

  const AiAssistantPage({super.key, this.onBackToTimetable});

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

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _firstChipKey = GlobalKey();
  final FocusNode _promptFocusNode = FocusNode();
  Timer? _typingHintTimer;
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
  bool _showTypingHint = false;
  bool _showBanner = true;
  bool _bannerExpanded = false;
  String _loadedHistoryDate = '';

  @override
  void initState() {
    super.initState();
    _loadContext();
    _promptFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _promptFocusNode.dispose();
    _typingHintTimer?.cancel();
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

  String _extractJsonCandidate(String reply) {
    final trimmed = reply.trim();
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false)
        .firstMatch(trimmed)
        ?.group(1)
        ?.trim();
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
      return value.map((entry) => entry.toString().trim()).where((entry) => entry.isNotEmpty).toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  List<_AiLessonCardData> _lessonsFromParsedPayload(Map<String, dynamic> data) {
    final rawLessons = data['lessons'] ?? data['stunden'] ?? data['items'];
    if (rawLessons is! List) return const [];

    return rawLessons.whereType<Map>().map((rawLesson) {
      final lesson = rawLesson.cast<String, dynamic>();
      final time = _firstNonEmptyString(lesson, const ['time', 'slot', 'range', 'period']);
      final subject = _firstNonEmptyString(lesson, const ['subject', 'title', 'name']);
      final subjectShort = _firstNonEmptyString(lesson, const ['subjectShort', 'short', 'abbr']);
      final room = _firstNonEmptyString(lesson, const ['room', 'raum', 'location']);
      final teacher = _firstNonEmptyString(lesson, const ['teacher', 'lehrer', 'person']);
      final status = _firstNonEmptyString(lesson, const ['status', 'state']);
      return _AiLessonCardData(
        subject: subject.isEmpty ? (subjectShort.isEmpty ? '?' : subjectShort) : subject,
        subjectShort: subjectShort,
        room: room,
        teacher: teacher,
        time: time.isEmpty ? '—' : time,
        isCancelled: status.toLowerCase().contains('cancel') || status.toLowerCase().contains('ausfall'),
      );
    }).where((lesson) => lesson.subject.isNotEmpty || lesson.room.isNotEmpty || lesson.teacher.isNotEmpty).toList(growable: false);
  }

  List<_AiLessonCardData> _fallbackLessonsForResult() {
    final lessons = _todayLessons().whereType<Map>().map((raw) {
      final lesson = raw.cast<dynamic, dynamic>();
      final subject = lesson['_subjectLong']?.toString().isNotEmpty == true
          ? lesson['_subjectLong'].toString()
          : (lesson['_subjectShort']?.toString().isNotEmpty == true ? lesson['_subjectShort'].toString() : '?');
      final subjectShort = lesson['_subjectShort']?.toString() ?? '';
      final room = lesson['_room']?.toString().trim() ?? '';
      final teacher = lesson['_teacher']?.toString().trim() ?? '';
      final start = _formatUntisTime((lesson['startTime'] ?? 800).toString());
      final end = _formatUntisTime((lesson['endTime'] ?? 845).toString());
      return _AiLessonCardData(
        subject: subject,
        subjectShort: subjectShort,
        room: room,
        teacher: teacher,
        time: '$start–$end',
        isCancelled: (lesson['code'] ?? '') == 'cancelled',
      );
    }).toList(growable: false);

    return lessons.take(4).toList(growable: false);
  }

  _AiSearchResult _parseSearchResult({required String query, required String reply}) {
    final fallbackLessons = _fallbackLessonsForResult();
    final fallbackHeadline = reply.split(RegExp(r'[\n\.\!\?]')).first.trim();
    final fallbackSummary = reply.trim().isEmpty ? query : reply.trim();
    try {
      final decoded = jsonDecode(_extractJsonCandidate(reply));
      if (decoded is Map<String, dynamic>) {
        final metrics = <_AiMetric>[];
        final metricSource = decoded['metrics'] ?? decoded['stats'];
        if (metricSource is List) {
          for (final entry in metricSource.whereType<Map>()) {
            final metric = entry.cast<String, dynamic>();
            final label = _firstNonEmptyString(metric, const ['label', 'name', 'title']);
            final value = _firstNonEmptyString(metric, const ['value', 'amount', 'text']);
            if (label.isNotEmpty && value.isNotEmpty) {
              metrics.add(_AiMetric(label: label, value: value));
            }
          }
        }

        final tags = _stringListFrom(decoded['tags']).take(6).toList(growable: false);
        final lessons = _lessonsFromParsedPayload(decoded);

        return _AiSearchResult(
          query: query,
          headline: _firstNonEmptyString(decoded, const ['headline', 'title', 'summaryTitle']).isEmpty
              ? fallbackHeadline
              : _firstNonEmptyString(decoded, const ['headline', 'title', 'summaryTitle']),
          summary: _firstNonEmptyString(decoded, const ['summary', 'text', 'result']).isEmpty
              ? fallbackSummary
              : _firstNonEmptyString(decoded, const ['summary', 'text', 'result']),
          tags: tags.isEmpty ? [query] : tags,
          metrics: metrics.isEmpty
              ? [
                  _AiMetric(
                    label: appLocaleNotifier.value.toLowerCase().startsWith('de') ? 'Heute' : 'Today',
                    value: '${_lessonCountToday()}',
                  ),
                ]
              : metrics,
          lessons: lessons.isEmpty ? fallbackLessons : lessons,
          rawReply: reply,
        );
      }
    } catch (_) {}

    return _AiSearchResult(
      query: query,
      headline: fallbackHeadline.isEmpty
          ? (appLocaleNotifier.value.toLowerCase().startsWith('de') ? 'Neue Suche' : 'New search')
          : fallbackHeadline,
      summary: fallbackSummary,
      tags: [query],
      metrics: [
        _AiMetric(
          label: appLocaleNotifier.value.toLowerCase().startsWith('de') ? 'Heute' : 'Today',
          value: '${_lessonCountToday()}',
        ),
        _AiMetric(
          label: appLocaleNotifier.value.toLowerCase().startsWith('de') ? 'Prüfungen' : 'Exams',
          value: '${_examCountThisWeek()}',
        ),
      ],
      lessons: fallbackLessons,
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

  String _weekCacheKey() {
    final monday = DateFormat('yyyyMMdd').format(_currentMonday);
    return [
      'weekCacheV1',
      schoolUrl,
      schoolName,
      personType.toString(),
      personId.toString(),
      monday,
    ].join('|');
  }

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

  bool get _hasCancellations =>
      _todayLessons().whereType<Map>().any((lesson) {
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
        .map((lesson) => int.tryParse(lesson['startTime']?.toString() ?? '') ?? 0)
        .where((value) => value > 0)
        .fold<int?>(null, (min, value) => min == null || value < min ? value : min);
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
        .fold<int?>(null, (max, value) => max == null || value > max ? value : max);
    return lastEnd != null && nowMin > _toMinutes(lastEnd);
  }

  String _contextDateLabel() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final icu = _icuLocale(appLocaleNotifier.value);
    return DateFormat('EEEE, dd.MM', icu).format(DateTime.now());
  }

  int _lessonCountToday() => _todayLessons().length;

  int _examCountThisWeek() {
    final monday = DateTime(
      _currentMonday.year,
      _currentMonday.month,
      _currentMonday.day,
    );
    final friday = monday.add(const Duration(days: 4));
    final mondayStamp = int.parse(DateFormat('yyyyMMdd').format(monday));
    final fridayStamp = int.parse(DateFormat('yyyyMMdd').format(friday));

    return _exams.where((ex) {
      final raw = (ex['date'] ?? ex['examDate'] ?? ex['startDate'] ?? '')
          .toString();
      final stamp = int.tryParse(raw);
      return stamp != null && stamp >= mondayStamp && stamp <= fridayStamp;
    }).length;
  }

  Future<void> _loadContext() async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: now.weekday - 1),
    );

    Map<int, List<dynamic>> weekData = _emptyWeekData();
    List<Map<String, dynamic>> exams = [];

    if (demoModeNotifier.value) {
      weekData = DemoModeService.buildWeek(
        monday,
        locale: appLocaleNotifier.value,
      );
      exams = DemoModeService.demoExams();
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString([
          'weekCacheV1',
          schoolUrl,
          schoolName,
          personType.toString(),
          personId.toString(),
          DateFormat('yyyyMMdd').format(monday),
        ].join('|'));
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            final week = decoded['weekData'];
            if (week is Map) {
              weekData = _decodeWeek(week.cast<dynamic, dynamic>());
            }
          }
        }

        final rawExams = prefs.getStringList('customExams') ?? [];
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
            final res = await http.get(uri, headers: {'Accept': 'application/json'});
            if (res.statusCode == 200) {
              final decoded = jsonDecode(res.body);
              List<dynamic> list = [];
              if (decoded is List) {
                list = decoded;
              } else if (decoded is Map) {
                list = (decoded['data'] ?? decoded['exams'] ?? decoded['result'] ?? []) as List;
              }
              return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
      final da = int.tryParse((a['date'] ?? a['examDate'] ?? a['startDate'] ?? 0).toString()) ?? 0;
      final db = int.tryParse((b['date'] ?? b['examDate'] ?? b['startDate'] ?? 0).toString()) ?? 0;
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

  String _contextBannerText() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final lessonCount = _lessonCountToday();
    final examCount = _examCountThisWeek();
    final lessonText = lessonCount == 1
        ? (appLocaleNotifier.value.toLowerCase().startsWith('de') ? '1 Stunde' : '1 lesson')
        : (appLocaleNotifier.value.toLowerCase().startsWith('de') ? '$lessonCount Stunden' : '$lessonCount lessons');
    final examText = examCount == 1
        ? (appLocaleNotifier.value.toLowerCase().startsWith('de') ? '1 Prüfung diese Woche' : '1 exam this week')
        : (appLocaleNotifier.value.toLowerCase().startsWith('de') ? '$examCount Prüfungen diese Woche' : '$examCount exams this week');
    return '${_contextDateLabel()}  •  $lessonText  •  $examText';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: _kSoftBounce,
        );
      }
    });
  }

  void _scrollToFirstChip() {
    final context = _firstChipKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: _kSoftBounce,
      alignment: 0.5,
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsAiPage()),
    );
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
      '[today]': DateFormat('EEEE, dd. MMMM yyyy', _icuLocale(appLocaleNotifier.value)).format(DateTime.now()),
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
      '[day_summary_tomorrow]': _daySummaryForPrompt(DateTime.now().add(const Duration(days: 1))),
      '[timetable]': _formatWeekForAi(_weekData, _currentMonday),
      '[timetable_json]': jsonEncode(_jsonSafeValue(_weekData)),
      '[exams]': _formatExamsForAi(),
      '[exams_json]': jsonEncode(_jsonSafeValue(_exams)),
    };

    var resolved = template;
    final entries = vars.entries.toList()..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in entries) {
      resolved = resolved.replaceAll(entry.key, entry.value);
    }
    return '''$resolved

ANTWORTFORMAT:
- Antworte möglichst kurz und visuell.
- Liefere bevorzugt ein JSON-Objekt mit den Feldern: headline, summary, tags, metrics, lessons.
- metrics ist eine Liste aus Objekten mit label und value.
- lessons ist eine Liste aus Objekten mit subject, subjectShort, room, teacher, time und status.
- Nutze wenig Fließtext und formuliere Ergebnisse so, dass sie direkt als Suchergebnis-Karten gerendert werden können.''';
  }

  Future<String> _requestProviderResponse(
    String systemPrompt, {
    required String userQuery,
  }) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final provider = _normalizeAiProvider(aiProvider);
    final apiKey = _activeAiApiKey().trim();
    if (apiKey.isEmpty) {
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

    String _normalizedBaseUrl(String value) {
      var out = value.trim();
      while (out.endsWith('/')) {
        out = out.substring(0, out.length - 1);
      }
      return out;
    }

    String _openAiCompatibleEndpoint(String rawBaseUrl) {
      final base = _normalizedBaseUrl(rawBaseUrl);
      if (base.isEmpty) return '';
      if (base.endsWith('/chat/completions')) return base;
      if (base.endsWith('/v1')) return '$base/chat/completions';
      if (base.endsWith('/v1/chat')) return '$base/completions';
      return '$base/v1/chat/completions';
    }

    String _geminiCompatibleEndpoint(String rawBaseUrl, String model) {
      final base = _normalizedBaseUrl(rawBaseUrl);
      if (base.isEmpty) return '';
      if (base.contains('/models/')) return base;
      if (base.contains('/v1beta')) return '$base/models/$model:generateContent';
      if (base.contains('/v1')) return '$base/models/$model:generateContent';
      return '$base/v1beta/models/$model:generateContent';
    }

    Future<String> _requestGeminiResponse({
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
        final parts = (content is Map<String, dynamic>) ? content['parts'] : null;
        if (parts is List) {
          reply = parts
              .map((p) => (p is Map<String, dynamic>) ? p['text'] : null)
              .whereType<String>()
              .join();
        }
      }

      reply = reply.trim();
      if (reply.isEmpty) {
        throw Exception('API: ${AppL10n.of(appLocaleNotifier.value).aiNoReply}');
      }
      return reply;
    }

    Future<String> _requestOpenAiCompatibleResponse({
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
        throw Exception('API: ${AppL10n.of(appLocaleNotifier.value).aiNoReply}');
      }

      final first = choices.first;
      if (first is! Map<String, dynamic>) {
        throw Exception('API: ${AppL10n.of(appLocaleNotifier.value).aiNoReply}');
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
        return _requestOpenAiCompatibleResponse(
          endpoint: 'https://api.openai.com/v1/chat/completions',
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          userQuery: userQuery,
        );
      case 'mistral':
        return _requestOpenAiCompatibleResponse(
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
          return _requestGeminiResponse(
            endpoint: _geminiCompatibleEndpoint(baseUrl, model),
            apiKey: apiKey,
            systemPrompt: systemPrompt,
            userQuery: userQuery,
          );
        }
        return _requestOpenAiCompatibleResponse(
          endpoint: _openAiCompatibleEndpoint(baseUrl),
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          userQuery: userQuery,
        );
      case 'gemini':
      default:
        return _requestGeminiResponse(
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
    if (index < 0 || index > 4) return '$dateLabel: ${l.noLesson}';

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

  Object? _jsonSafeValue(Object? value) {
    if (value == null || value is String || value is num || value is bool) return value;
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

  String _formatExamsForAi() {
    if (_exams.isEmpty) return 'Keine Prüfungen eingetragen.';
    final buf = StringBuffer();
    for (final ex in _exams) {
      final subject = ex['subject'] ?? ex['subjectName'] ?? '?';
      final type = ex['type'] ?? 'Klausur';
      final dateRaw = (ex['date'] ?? ex['examDate'] ?? ex['startDate'] ?? '').toString();
      String dateStr = dateRaw;
      if (dateRaw.length == 8) {
        dateStr = '${dateRaw.substring(6, 8)}.${dateRaw.substring(4, 6)}.${dateRaw.substring(0, 4)}';
      }
      final name = ex['name'] ?? ex['text'] ?? '';
      buf.write('- $dateStr ($type): $subject');
      if (name.isNotEmpty) buf.write(' "$name"');
      buf.writeln();
    }
    return buf.toString();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _thinking) return;

    final generation = ++_searchGeneration;
    if (_activeAiApiKey().trim().isEmpty) {
      final l = AppL10n.of(appLocaleNotifier.value);
      final provider = _normalizeAiProvider(aiProvider);
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
    final isGerman = appLocaleNotifier.value.toLowerCase().startsWith('de');
    final chips = <String>[l.aiSuggestions.first];
    if (_hasTodayLessons) chips.add(isGerman ? 'Wann ist heute Schluss?' : 'When do I finish today?');
    if (_hasCancellations) chips.add(isGerman ? 'Was fällt heute aus?' : 'What is cancelled today?');
    if (_hasUpcomingExams) chips.add(isGerman ? 'Welche Prüfungen hab ich bald?' : 'Which exams are coming up?');
    if (_isBeforeSchool) chips.add(isGerman ? 'Was hab ich heute als erstes?' : 'What is my first lesson today?');
    if (_isDuringSchool) chips.add(isGerman ? 'Wann ist meine nächste Stunde?' : 'When is my next lesson?');
    if (_isAfterSchool) chips.add(isGerman ? 'Was hab ich morgen?' : 'What do I have tomorrow?');
    return chips.toSet().take(5).toList();
  }

  Widget _buildContextBanner(ColorScheme cs) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: !_showBanner
          ? const SizedBox.shrink()
          : InkWell(
              onTap: () => setState(() => _bannerExpanded = !_bannerExpanded),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                key: const ValueKey('context_banner'),
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
                ),
                child: AnimatedCrossFade(
                  firstChild: Row(
                    children: [
                      Icon(Icons.event_note_rounded, color: cs.onPrimaryContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _contextBannerText(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showBanner = false),
                        icon: Icon(Icons.close_rounded, color: cs.onPrimaryContainer),
                        visualDensity: VisualDensity.compact,
                        tooltip: appLocaleNotifier.value.toLowerCase().startsWith('de')
                            ? 'Ausblenden'
                            : 'Dismiss',
                      ),
                    ],
                  ),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event_note_rounded, color: cs.onPrimaryContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _contextBannerText(),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _showBanner = false),
                            icon: Icon(Icons.close_rounded, color: cs.onPrimaryContainer),
                            visualDensity: VisualDensity.compact,
                            tooltip: appLocaleNotifier.value.toLowerCase().startsWith('de')
                                ? 'Ausblenden'
                                : 'Dismiss',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appLocaleNotifier.value.toLowerCase().startsWith('de')
                            ? 'Ergebnisse werden als Karten und Stundenblöcke angezeigt.'
                            : 'Results appear as cards and lesson blocks.',
                        style: GoogleFonts.outfit(fontSize: 13, color: cs.onPrimaryContainer.withValues(alpha: 0.92)),
                      ),
                    ],
                  ),
                  crossFadeState: _bannerExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
              ),
            ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'clear':
        await _clearCurrentResult();
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
  Widget _buildSearchMetricCard(ColorScheme cs, _AiMetric metric) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.value,
            style: GoogleFonts.outfit(
              fontSize: 20,
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
    final isGerman = appLocaleNotifier.value.toLowerCase().startsWith('de');
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
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.22)),
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
                        _latestQuery.isEmpty ? (isGerman ? 'Suche läuft…' : 'Search running…') : _latestQuery,
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
                  isGerman
                      ? 'Die KI formt gerade Karten und Stundenblöcke aus deinem Stundenplan.'
                      : 'The AI is shaping cards and lesson blocks from your timetable.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (_latestQuery.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Chip(
                    label: Text(_latestQuery, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12)),
                    backgroundColor: cs.primaryContainer.withValues(alpha: 0.72),
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

  Widget _buildTypingBubble(ColorScheme cs) {
    final isGerman = appLocaleNotifier.value.toLowerCase().startsWith('de');
    final messages = isGerman
        ? ['Analysiert den Stundenplan…', 'Sortiert Ergebnisse…', 'Fast fertig…']
        : ['Analyzing timetable…', 'Sorting results…', 'Almost done…'];
    final text = messages.isEmpty ? '' : messages[_typingHintIndex % messages.length];

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
    final isGerman = appLocaleNotifier.value.toLowerCase().startsWith('de');
    final mq = MediaQuery.of(context);
    final keyboardHeight = mq.viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    final isFocused = _promptFocusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 20),
      curve: Curves.fastOutSlowIn,
      margin: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        isKeyboardOpen ? (keyboardHeight + 12) : (14 + mq.padding.bottom),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isFocused ? 12 : 8,
        vertical: 14,
      ),
      child: Row(
        children: [
          const SizedBox(width: 8), 
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
              ),
              decoration: InputDecoration(
                hintText: isGerman ? 'Stunden, Freistunden, Prüfungen …' : 'Lessons, free periods, exams ...',
                hintStyle: GoogleFonts.outfit(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
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
              icon: const Icon(Icons.clear_rounded),
              tooltip: isGerman ? 'Leeren' : 'Clear',
            ),
          ],
          const SizedBox(width: 8), 
          FilledButton(
            onPressed: _thinking ? null : _send,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isFocused ? 24 : 18, 
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isFocused ? 14 : 22),
              ),
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
                      Icons.search_rounded,
                      key: ValueKey<bool>(isFocused),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(ColorScheme cs) {
    final result = _latestResult;
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primaryContainer.withValues(alpha: 0.96),
                  cs.tertiaryContainer.withValues(alpha: 0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: cs.onPrimaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        result.headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  result.summary,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.92),
                    height: 1.35,
                  ),
                ),
                if (result.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.tags.take(4).map((tag) {
                      return Chip(
                        label: Text(tag, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12)),
                        side: BorderSide.none,
                        backgroundColor: cs.onPrimaryContainer.withValues(alpha: 0.12),
                        labelStyle: TextStyle(color: cs.onPrimaryContainer),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (result.metrics.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 460;
                final columns = isWide ? 3 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.7,
                  children: result.metrics.map((metric) => _buildSearchMetricCard(cs, metric)).toList(),
                );
              },
            ),
          if (result.lessons.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              appLocaleNotifier.value.toLowerCase().startsWith('de') ? 'Stunden' : 'Lessons',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
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
          if (_thinking) ...[
            const SizedBox(height: 8),
            _buildTypingBubble(cs),
          ],
        ],
      ),
    );
  }

  Widget _buildChipRow(ColorScheme cs) {
    final chips = _buildContextualChips();
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Scrollbar(
        thumbVisibility: true,
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
      onPressed: _thinking ? null : () => _sendQuickPrompt(text),
    );
    return first ? chip : chip;
  }

  Widget _buildBody(ColorScheme cs) {
    return Column(
      children: [
        _buildContextBanner(cs),
        if (_latestResult == null) _buildChipRow(cs),
        Expanded(
          child: _buildResultHeader(cs),
        ),
        _buildSearchBar(cs),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    final l = AppL10n.of(appLocaleNotifier.value);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.manage_search_rounded, size: 40, color: cs.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            appLocaleNotifier.value.toLowerCase().startsWith('de') ? 'Such dir Ergebnisse aus deinem Stundenplan.' : 'Search results from your timetable.',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            appLocaleNotifier.value.toLowerCase().startsWith('de')
                ? 'Die KI antwortet hier als kompakte Ergebnisansicht mit Karten, Kennzahlen und Stunden.'
                : 'The AI responds here as a compact result view with cards, metrics, and lessons.',
            style: GoogleFonts.outfit(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildContextualChips()
                .map(
                  (s) => ActionChip(
                    label: Text(
                      s,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    backgroundColor: cs.primaryContainer,
                    side: BorderSide.none,
                    onPressed: () => _sendQuickPrompt(s),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l.aiTitle)),
        body: Center(child: CircularProgressIndicator(color: cs.primary)),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBackToTimetable ?? () => Navigator.of(context).maybePop(),
          tooltip: appLocaleNotifier.value.toLowerCase().startsWith('de')
              ? 'Zurück'
              : 'Back',
        ),
        title: Text(l.aiTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: appLocaleNotifier.value.toLowerCase().startsWith('de')
                ? 'Mehr'
                : 'More',
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'settings',
                child: Text(
                  appLocaleNotifier.value.toLowerCase().startsWith('de')
                      ? 'KI-Einstellungen'
                      : 'AI settings',
                ),
              ),
              PopupMenuItem<String>(
                value: 'prompt',
                child: Text(
                  appLocaleNotifier.value.toLowerCase().startsWith('de')
                      ? 'System-Prompt'
                      : 'System prompt',
                ),
              ),
              PopupMenuItem<String>(
                value: 'clear',
                child: Text(appLocaleNotifier.value.toLowerCase().startsWith('de') ? 'Ergebnis leeren' : 'Clear result'),
              ),
              PopupMenuItem<String>(
                value: 'refresh',
                child: Text(appLocaleNotifier.value.toLowerCase().startsWith('de') ? 'Neu suchen' : 'Search again'),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(cs),
    );
  }

  }

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _showTutorial = false;
  int _tutorialStep = 0;
  StreamSubscription<NotificationActionEvent>? _notificationActionSub;

  static const List<int> _tutorialTargets = [0, 1, 2, 3];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _notificationActionSub = NotificationService().actionEvents.listen(
      _handleNotificationAction,
    );
    final pending = NotificationService().consumePendingActionEvent();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleNotificationAction(pending);
      });
    }
    if (widget.showTutorialOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showTutorial = true;
          _tutorialStep = 0;
          _selectedIndex = 0;
        });
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

    if (actionId == 'open_free_rooms' || actionId == 'open_next_lesson') {
      _onNavTap(0);
      pendingTimetableActionNotifier.value = actionId;
      return;
    }

    _onNavTap(0);
    pendingTimetableActionNotifier.value = 'open_timetable';
  }

  Future<void> _finishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorialCompleted', true);
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

  void _onNavTap(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }

    if (!_showTutorial) return;
    if (_tutorialStep >= _tutorialTargets.length) return;
    if (_tutorialTargets[_tutorialStep] != index) return;

    if (_tutorialStep == _tutorialTargets.length - 1) {
      setState(() => _tutorialStep = _tutorialTargets.length);
      return;
    }

    setState(() => _tutorialStep += 1);
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
        return l.tutorialStepSettingsDesc;
      default:
        return l.tutorialStepFinishDesc;
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      schoolUrl = prefs.getString('schoolUrl') ?? "";
      schoolName = prefs.getString('schoolName') ?? "";
      sessionID = prefs.getString('sessionId') ?? "";
      personType = prefs.getInt('personType') ?? 0;
      personId = prefs.getInt('personId') ?? 0;
    });
  }

  List<Widget> get _pages => <Widget>[
    WeeklyTimetablePage(key: ValueKey(sessionID)),
    const ExamsPage(),
    const SchoolNotificationsPage(),
    const SettingsHubPage(),
    AiAssistantPage(
      key: ValueKey(sessionID),
      onBackToTimetable: () => _onNavTap(0),
    ),
  ];

  @override
  void dispose() {
    _notificationActionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppL10n.of(appLocaleNotifier.value);

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Color.alphaBlend(
                            cs.primary.withValues(alpha: 0.18),
                            cs.surface,
                          ),
                          Color.alphaBlend(
                            cs.tertiary.withValues(alpha: 0.14),
                            cs.surface,
                          ),
                          cs.surface,
                        ]
                      : [
                          Color.alphaBlend(
                            cs.primary.withValues(alpha: 0.08),
                            cs.surface,
                          ),
                          Color.alphaBlend(
                            cs.secondary.withValues(alpha: 0.07),
                            cs.surface,
                          ),
                          cs.surface,
                        ],
                ),
              ),
            ),
          ),
          MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(bottom: mq.padding.bottom + 104),
            ),
            child: IndexedStack(index: _selectedIndex, children: _pages),
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
                        opacity: isDark ? 0.28 : 0.2,
                        child: _AnimatedBackgroundScene(style: style),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Floating nav bar
          Positioned(
            left: 16,
            right: 16,
            bottom: mq.padding.bottom + 16,
            child: ValueListenableBuilder<String>(
              valueListenable: appLocaleNotifier,
              builder: (context, locale, _) {
                return _buildFloatingNavBar(context, cs);
              },
            ),
          ),
          if (_showTutorial)
            Positioned(
              left: 16,
              right: 16,
              top: mq.padding.top + 10,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.school_rounded, color: cs.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.tutorialTitle,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _skipTutorial,
                            child: Text(l.tutorialSkip),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tutorialTitle(l),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tutorialDesc(l),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      if (_tutorialStep >= _tutorialTargets.length) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _finishTutorial,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(l.tutorialDone),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, ColorScheme cs) {
    final timetableSelected = _selectedIndex == 0;
    final l = AppL10n.of(appLocaleNotifier.value);

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: _withOptionalBackdropBlur(
                  sigmaX: 16,
                  sigmaY: 16,
                  child: const SizedBox.shrink(),
                  childBuilder: (enabled) => AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: _kSoftBounce,
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: enabled
                          ? Color.alphaBlend(
                              cs.primaryContainer.withValues(alpha: 0.18),
                              cs.surface.withValues(alpha: 0.72),
                            )
                          : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.18),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _navIconBtn(
                          cs: cs,
                          icon: Icons.assignment_outlined,
                          selectedIcon: Icons.assignment_rounded,
                          label: l.navExams,
                          selected: _selectedIndex == 1,
                          onTap: () => _onNavTap(1),
                          tutorialHighlight: _isTutorialTarget(1),
                        ),
                        const SizedBox(width: 4),
                        _navIconBtn(
                          cs: cs,
                          icon: Icons.campaign_outlined,
                          selectedIcon: Icons.campaign_rounded,
                          label: l.navInfo,
                          selected: _selectedIndex == 2,
                          onTap: () => _onNavTap(2),
                          tutorialHighlight: _isTutorialTarget(2),
                        ),
                        const SizedBox(width: 4),
                        _navIconBtn(
                          cs: cs,
                          icon: Icons.settings_outlined,
                          selectedIcon: Icons.settings_rounded,
                          label: l.navMenu,
                          selected: _selectedIndex == 3,
                          onTap: () => _onNavTap(3),
                          tutorialHighlight: _isTutorialTarget(3),
                        ),
                        const SizedBox(width: 4),
                        _navIconBtn(
                          cs: cs,
                          icon: Icons.auto_awesome_outlined,
                          selectedIcon: Icons.auto_awesome_rounded,
                          label: l.navAi,
                          selected: _selectedIndex == 4,
                          onTap: () => _onNavTap(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

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
              child: AnimatedScale(
                scale: timetableSelected ? 1.04 : 0.96,
                duration: const Duration(milliseconds: 360),
                curve: _kSmoothBounce,
                child: _BouncyButton(
                  onTap: () => _onNavTap(0),
                  scaleTarget: 0.9,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 420),
                    curve: _kSoftBounce,
                    height: timetableSelected ? 74 : 62,
                    width: timetableSelected ? 74 : 62,
                    decoration: BoxDecoration(
                      color: timetableSelected
                          ? cs.primary
                          : cs.surfaceContainerHigh.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(
                        timetableSelected ? 24 : 20,
                      ),
                      border: Border.all(
                        color: _isTutorialTarget(0)
                            ? cs.tertiary
                            : timetableSelected
                            ? cs.primary.withValues(alpha: 0.44)
                            : cs.outlineVariant.withValues(alpha: 0.36),
                        width: _isTutorialTarget(0) ? 2.0 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (timetableSelected
                                      ? cs.primary
                                      : cs.surfaceContainerHigh)
                                  .withValues(alpha: 0.38),
                          blurRadius: timetableSelected ? 22 : 14,
                          offset: Offset(0, timetableSelected ? 8 : 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 380),
                        switchInCurve: _kSmoothBounce,
                        switchOutCurve: _kSoftBounce,
                        transitionBuilder: (child, anim) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(anim);
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: slide,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.88,
                                  end: 1.0,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: AnimatedRotation(
                          turns: timetableSelected ? 0 : -0.04,
                          duration: const Duration(milliseconds: 360),
                          curve: _kSmoothBounce,
                          child: Icon(
                            timetableSelected
                                ? Icons.watch_later_rounded
                                : Icons.watch_later_outlined,
                            key: ValueKey('timetable_$timetableSelected'),
                            color: timetableSelected
                                ? cs.onPrimary
                                : cs.onSurfaceVariant,
                            size: timetableSelected ? 36 : 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIconBtn({
    required ColorScheme cs,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool tutorialHighlight = false,
  }) {
    return _BouncyButton(
      onTap: onTap,
      scaleTarget: 0.8,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: _kSoftBounce,
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: tutorialHighlight
              ? Border.all(color: cs.tertiary, width: 2)
              : selected
              ? Border.all(color: cs.primary.withValues(alpha: 0.22), width: 1)
              : Border.all(color: Colors.transparent, width: 0),
          boxShadow: tutorialHighlight
              ? [
                  BoxShadow(
                    color: cs.tertiary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: _kSmoothBounce,
              switchOutCurve: _kSoftBounce,
              transitionBuilder: (child, anim) {
                return ScaleTransition(scale: anim, child: child);
              },
              child: Icon(
                selected ? selectedIcon : icon,
                key: ValueKey(selected),
                size: selected ? 23 : 26,
                color: selected
                    ? cs.onPrimaryContainer
                    : cs.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: _kSoftBounce,
              alignment: Alignment.centerLeft,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        style: GoogleFonts.outfit(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

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
