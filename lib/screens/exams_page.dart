part of '../main.dart';

// --- PRÜFUNGEN PAGE ---

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _apiExams = [];
  List<Map<String, dynamic>> _customExams = [];
  bool _loading = true;

  Future<void> _refreshExams({bool showSpinner = false}) async {
    if (showSpinner && mounted) {
      setState(() {
        _loading = true;
      });
    }
    await _fetchApiExams();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    customExamsNotifier.addListener(_onCustomExamsNotifierChanged);
    _load();
  }

  @override
  void dispose() {
    customExamsNotifier.removeListener(_onCustomExamsNotifierChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onCustomExamsNotifierChanged() {
    if (!mounted) return;
    setState(() {
      _customExams = List.from(customExamsNotifier.value);
    });
  }

  Future<void> _load() async {
    await Future.wait([_fetchApiExams(), _loadCustomExams()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCustomExams() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_accountDataKey('customExams')) ?? [];
    final list = raw
        .map((e) {
          try {
            return Map<String, dynamic>.from(jsonDecode(e) as Map);
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();
    _customExams = list;
    customExamsNotifier.value = list;
  }

  Future<void> _fetchApiExams() async {
    if (demoModeNotifier.value) {
      _apiExams = DemoModeService.demoExams(locale: appLocaleNotifier.value);
      return;
    }
    if (sessionID.isEmpty) return;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 14));
    final end = now.add(const Duration(days: 90));
    final startStr = DateFormat('yyyyMMdd').format(start);
    final endStr = DateFormat('yyyyMMdd').format(end);
    final headers = {
      'Cookie': 'JSESSIONID=$sessionID; schoolname=$schoolName',
      'Accept': 'application/json',
    };

    Future<List<Map<String, dynamic>>> tryEndpoint(String path) async {
      try {
        final uri = Uri.parse(
          'https://$schoolUrl$path?startDate=$startStr&endDate=$endStr',
        );
        final res = await http.get(uri, headers: headers);
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          List<dynamic> list = [];
          if (decoded is List) {
            list = decoded;
          } else if (decoded is Map) {
            list =
                (decoded['data'] ?? decoded['exams'] ?? decoded['result'] ?? [])
                    as List;
          }
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
      return [];
    }

    var results = await tryEndpoint('/WebUntis/api/exams');
    if (results.isEmpty) {
      results = await tryEndpoint('/WebUntis/api/classreg/exams');
    }
    if (results.isEmpty && personId != 0) {
      results = await tryEndpoint('/WebUntis/api/exams/student/$personId');
    }
    _apiExams = results;
    apiExamsNotifier.value = results;
  }

  List<Map<String, dynamic>> get _allExams {
    final all = [
      ..._apiExams.map((e) => {...e, '_source': 'api'}),
      ..._customExams.map((e) => {...e, '_source': 'custom'}),
    ];
    all.sort((a, b) => _examSortKey(a).compareTo(_examSortKey(b)));
    return all;
  }

  int _examSortKey(Map<String, dynamic> e) {
    final date = e['date'] ?? e['examDate'] ?? e['startDate'] ?? 0;
    final time = e['startTime'] ?? e['start'] ?? 0;
    return (int.tryParse(date.toString()) ?? 0) * 10000 +
        (int.tryParse(time.toString()) ?? 0);
  }

  String _formatExamDate(dynamic date) {
    final s = date.toString();
    if (s.length == 8) {
      try {
        final d = DateTime.parse(
          '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}',
        );
        return DateFormat(
          'EEEE, dd. MMMM yyyy',
          _icuLocale(appLocaleNotifier.value),
        ).format(d);
      } catch (_) {}
    }
    return s;
  }

  String _examSubject(Map<String, dynamic> e) =>
      (e['subject'] ?? e['name'] ?? e['examType'] ?? '').toString();

  String _examType(Map<String, dynamic> e) =>
      (e['examType'] ?? e['type'] ?? e['typeName'] ?? '').toString();

  bool _providerUsesGeminiProtocol() {
    final provider = _normalizeAiProvider(aiProvider);
    if (provider == 'gemini') return true;
    if (provider == 'custom') {
      return _normalizeAiCustomCompatibility(aiCustomCompatibility) == 'gemini';
    }
    return false;
  }

  String _normalizedAiBaseUrl(String value) {
    var out = value.trim();
    while (out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }

  String _openAiCompatibleEndpointForExamImport(String rawBaseUrl) {
    final base = _normalizedAiBaseUrl(rawBaseUrl);
    if (base.isEmpty) return '';
    if (base.endsWith('/chat/completions')) return base;
    if (base.endsWith('/v1')) return '$base/chat/completions';
    if (base.endsWith('/v1/chat')) return '$base/completions';
    return '$base/v1/chat/completions';
  }

  String _geminiCompatibleEndpointForExamImport(
    String rawBaseUrl,
    String model,
  ) {
    final base = _normalizedAiBaseUrl(rawBaseUrl);
    if (base.isEmpty) return '';
    if (base.contains('/models/')) return base;
    if (base.contains('/v1beta')) return '$base/models/$model:generateContent';
    if (base.contains('/v1')) return '$base/models/$model:generateContent';
    return '$base/v1beta/models/$model:generateContent';
  }

  String _extractOpenAiCompatibleText(Map<String, dynamic> payload, AppL10n l) {
    final choices = payload['choices'];
    if (choices is! List || choices.isEmpty) {
      throw Exception('API: ${l.aiNoReply}');
    }

    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw Exception('API: ${l.aiNoReply}');
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
    throw Exception('API: ${l.aiNoReply}');
  }

  Future<String> _requestExamImportWithGemini({
    required String endpoint,
    required String apiKey,
    required String prompt,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final endpointUri = Uri.parse(endpoint);
    final mergedParams = Map<String, String>.from(endpointUri.queryParameters)
      ..putIfAbsent('key', () => apiKey);
    final uri = endpointUri.replace(queryParameters: mergedParams);

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': l.ui('aiExamJsonSystemPrompt')},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(fileBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 2200},
    });

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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload?['error']?['message'] ?? response.statusCode;
      throw Exception('API: $message');
    }

    var reply = '';
    final candidates = payload?['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final content = candidates.first['content'];
      final parts = (content is Map<String, dynamic>) ? content['parts'] : null;
      if (parts is List) {
        reply = parts.map((part) {
          if (part is Map<String, dynamic>) {
            return part['text']?.toString() ?? '';
          }
          return '';
        }).join();
      }
    }

    reply = reply.trim();
    if (reply.isEmpty) {
      throw Exception('API: ${l.aiNoReply}');
    }
    return reply;
  }

  Future<String> _requestExamImportWithOpenAiCompatible({
    required String endpoint,
    required String apiKey,
    required String model,
    required String prompt,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    if (!mimeType.startsWith('image/')) {
      throw Exception(
        'API: Unsupported file type for this provider: $mimeType',
      );
    }
    final l = AppL10n.of(appLocaleNotifier.value);
    final dataUrl = 'data:$mimeType;base64,${base64Encode(fileBytes)}';
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': l.ui('aiExamImageSystemPrompt')},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl},
            },
          ],
        },
      ],
      'temperature': 0.1,
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

    return _extractOpenAiCompatibleText(payload ?? const {}, l);
  }

  Future<String> _requestExamImportResponse({
    required String prompt,
    required Uint8List fileBytes,
    required String mimeType,
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

    switch (provider) {
      case 'openai':
        return _requestExamImportWithOpenAiCompatible(
          endpoint: 'https://api.openai.com/v1/chat/completions',
          apiKey: apiKey,
          model: model,
          prompt: prompt,
          fileBytes: fileBytes,
          mimeType: mimeType,
        );
      case 'mistral':
        return _requestExamImportWithOpenAiCompatible(
          endpoint: 'https://api.mistral.ai/v1/chat/completions',
          apiKey: apiKey,
          model: model,
          prompt: prompt,
          fileBytes: fileBytes,
          mimeType: mimeType,
        );
      case 'custom':
        final baseUrl = aiCustomBaseUrl.trim();
        if (baseUrl.isEmpty) {
          throw Exception('CONFIG: ${l.aiCustomBaseUrlMissing}');
        }
        final compat = _normalizeAiCustomCompatibility(aiCustomCompatibility);
        if (compat == 'gemini') {
          return _requestExamImportWithGemini(
            endpoint: _geminiCompatibleEndpointForExamImport(baseUrl, model),
            apiKey: apiKey,
            prompt: prompt,
            fileBytes: fileBytes,
            mimeType: mimeType,
          );
        }
        return _requestExamImportWithOpenAiCompatible(
          endpoint: _openAiCompatibleEndpointForExamImport(baseUrl),
          apiKey: apiKey,
          model: model,
          prompt: prompt,
          fileBytes: fileBytes,
          mimeType: mimeType,
        );
      case 'local':
        throw Exception(
          'CONFIG: ${AppL10n.of(appLocaleNotifier.value).aiLocalModelExamNotSupported}',
        );
      case 'gemini':
      default:
        return _requestExamImportWithGemini(
          endpoint:
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
          apiKey: apiKey,
          prompt: prompt,
          fileBytes: fileBytes,
          mimeType: mimeType,
        );
    }
  }

  Future<void> _importExamsWithAI() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final providerUsesGeminiProtocol = _providerUsesGeminiProtocol();
    final provider = _normalizeAiProvider(aiProvider);
    final isLocalProvider = provider == 'local';
    if (!isLocalProvider && _activeAiApiKey().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_providerAwareMissingApiKeyMessage(l, provider)),
        ),
      );
      return;
    }

    final source = await _showUnifiedOptionSheet<String>(
      context: context,
      title: l.examsImportTitle,
      options: [
        _SheetOption(
          value: 'camera',
          title: l.examsImportCamera,
          icon: Icons.camera_alt_rounded,
        ),
        _SheetOption(
          value: 'gallery',
          title: l.examsImportGallery,
          icon: Icons.image_rounded,
        ),
        _SheetOption(
          value: 'file',
          title: l.examsImportFile,
          icon: Icons.picture_as_pdf_rounded,
        ),
      ],
    );

    if (source == null) return;

    Uint8List? fileBytes;
    String? mimeType;

    if (source == 'camera' || source == 'gallery') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
      if (picked == null) return;
      fileBytes = await picked.readAsBytes();
      mimeType = picked.path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
    } else {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: providerUsesGeminiProtocol
            ? ['pdf', 'png', 'jpg', 'jpeg']
            : ['png', 'jpg', 'jpeg'],
      );
      if (picked == null) return;
      fileBytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      mimeType = ext == 'pdf'
          ? 'application/pdf'
          : (ext == 'png' ? 'image/png' : 'image/jpeg');
    }

    if (!mounted) return;

    var loadingVisible = true;
    showUntisDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prompt = l.uiFormat('aiExamVisionPrompt', {
        'fileKind': providerUsesGeminiProtocol ? l.ui('aiFileKindPdf') : '',
        'year': DateTime.now().year,
      });

      final text = await _requestExamImportResponse(
        prompt: prompt,
        fileBytes: fileBytes,
        mimeType: mimeType,
      );

      if (!mounted) return;
      if (loadingVisible) {
        Navigator.pop(context);
        loadingVisible = false;
      }

      final jsonStart = text.indexOf('[');
      final jsonEnd = text.lastIndexOf(']');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = text.substring(jsonStart, jsonEnd + 1);
        final decoded = jsonDecode(jsonStr);
        if (decoded is! List) {
          throw Exception('API: ${l.examsImportInvalidJson}');
        }
        final exams = decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        final current = List<Map<String, dynamic>>.from(
          customExamsNotifier.value,
        );
        for (var e in exams) {
          current.add({
            'subject': e['subject']?.toString() ?? 'Unbekannt',
            'examType': e['examType']?.toString() ?? 'Klausur',
            'date': (e['date']?.toString() ?? '').replaceAll('-', ''),
            'description': e['description']?.toString() ?? '',
            '_custom': true,
          });
        }
        await saveCustomExams(current);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.examsImportSuccess)));
      } else {
        throw Exception(l.examsImportInvalidJson);
      }
    } catch (e) {
      if (!mounted) return;
      if (loadingVisible) {
        Navigator.pop(context);
        loadingVisible = false;
      }
      final message = e.toString();
      final isApiError = message.contains('API:');
      final isConfigError = message.contains('CONFIG:');
      final detail = isConfigError
          ? message.replaceFirst('Exception: CONFIG: ', '')
          : isApiError
          ? '${l.aiApiError} ${message.replaceFirst('Exception: API: ', '')}'
          : '${l.aiConnectionError} $e';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l.examsImportError}$detail')));
    }
  }

  Future<void> _exportCustomExams() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    if (_customExams.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.examsExportEmpty)));
      return;
    }

    final exportPayload = _customExams
        .map(
          (e) => <String, dynamic>{
            'subject': _examSubject(e),
            'examType': _examType(e),
            'date': (e['date'] ?? e['examDate'] ?? e['startDate'] ?? '')
                .toString(),
            'description': (e['description'] ?? '').toString(),
          },
        )
        .toList();

    final jsonText = const JsonEncoder.withIndent('  ').convert(exportPayload);
    await Clipboard.setData(ClipboardData(text: jsonText));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.examsExportSuccess)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final exams = _allExams;
    final todayInt = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));

    final upcoming = exams
        .where(
          (e) => (int.tryParse(e['date']?.toString() ?? '') ?? 0) >= todayInt,
        )
        .toList();
    final past = exams
        .where(
          (e) => (int.tryParse(e['date']?.toString() ?? '') ?? 0) < todayInt,
        )
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _mainTabHeaderAppBar(
        context,
        _tabController.index == 0
            ? l.examsTitle
            : (_tabController.index == 1 ? l.homeworkTitle : l.gradesTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _tabController.index == 2
                ? IconButton(
                    tooltip: l.gradesAddTitle,
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () =>
                        _gradesTrackerKey.currentState?.showAddGradeDialog(),
                  )
                : _untisDropdownMenu(
                    context: context,
                    menuChildren: _tabController.index == 0
                        ? [
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.edit_note_rounded),
                              onPressed: () => _showAddExamDialog(context),
                              child: Text(l.examsActionCustom),
                            ),
                            MenuItemButton(
                              leadingIcon: const Icon(
                                Icons.upload_file_rounded,
                              ),
                              onPressed: _importExamsWithAI,
                              child: Text(l.examsActionImport),
                            ),
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.ios_share_rounded),
                              onPressed: _exportCustomExams,
                              child: Text(l.examsActionExport),
                            ),
                          ]
                        : [
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.edit_note_rounded),
                              onPressed: () => _showAddHomeworkDialog(context),
                              child: Text(l.homeworkActionCustom),
                            ),
                            MenuItemButton(
                              leadingIcon: const Icon(
                                Icons.upload_file_rounded,
                              ),
                              onPressed: () => _importHomeworkWithAI(context),
                              child: Text(l.homeworkActionImport),
                            ),
                          ],
                    builder: (context, controller, child) => IconButton(
                      tooltip: _tabController.index == 0
                          ? l.examsAddTitle
                          : l.homeworkAddTitle,
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
                    ),
                  ),
          ),
        ],
        bottom: _mainSectionTabBar(
          context,
          controller: _tabController,
          onTap: (index) => setState(() {}),
          items: [
            (icon: Icons.assignment_late_rounded, label: l.navExams),
            (icon: Icons.assignment_rounded, label: l.navHomework),
            (icon: Icons.auto_graph_rounded, label: l.navGrades),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExpressiveRefreshIndicator(
            onRefresh: _refreshExams,
            child: ListView(
              padding: UntisLayout.pagePadding(context, bottom: 132),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                _buildExamStatsHeader(cs, l, upcoming),
                if (_loading) ...[
                  const SizedBox(height: 140),
                  const Center(child: CircularProgressIndicator()),
                ] else if (exams.isEmpty) ...[
                  const SizedBox(height: 80),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.examsNone,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.examsNoneHint,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _refreshExams,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            l.examsReload,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  if (upcoming.isNotEmpty) ...[
                    _sectionHeader(
                      cs,
                      l.examsUpcoming,
                      Icons.upcoming_rounded,
                      upcoming.length,
                    ),
                    const SizedBox(height: 8),
                    ...upcoming.asMap().entries.map(
                      (e) =>
                          _animatedExamCard(e.key, context, cs, e.value, true),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (past.isNotEmpty) ...[
                    _sectionHeader(
                      cs,
                      l.examsPast,
                      Icons.history_rounded,
                      past.length,
                    ),
                    const SizedBox(height: 8),
                    ...past.asMap().entries.map(
                      (e) =>
                          _animatedExamCard(e.key, context, cs, e.value, false),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const _HomeworkView(),
          GradesTrackerPage(key: _gradesTrackerKey),
        ],
      ),
    );
  }

  Widget _buildExamStatsHeader(
    ColorScheme cs,
    AppL10n l,
    List<Map<String, dynamic>> upcoming,
  ) {
    final count = upcoming.length;
    final next = upcoming.isNotEmpty ? upcoming.first : null;
    final nextSubject = next != null ? _examSubject(next) : null;
    final nextDateStr = next != null
        ? _formatExamDate(next['date'] ?? next['examDate'] ?? '')
        : null;

    final upcomingTitle = l.examsUpcomingCount.replaceAll('{count}', '$count');

    final nextSubText = nextSubject != null && nextDateStr != null
        ? l.examsUpcomingNext
              .replaceAll(r'$subject', nextSubject)
              .replaceAll(r'$date', nextDateStr)
              .replaceAll('{subject}', nextSubject)
              .replaceAll('{date}', nextDateStr)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _glassContainer(
        context: context,
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.25),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _glowShadows(context, [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]),
                ),
                child: const Center(
                  child: Icon(
                    Icons.assignment_turned_in_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upcomingTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (nextSubText != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.near_me_rounded,
                            size: 13,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              nextSubText,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final GlobalKey<_GradesTrackerPageState> _gradesTrackerKey = GlobalKey();

  Widget _sectionHeader(
    ColorScheme cs,
    String title,
    IconData icon, [
    int? count,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: cs.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _animatedExamCard(
    int index,
    BuildContext context,
    ColorScheme cs,
    Map<String, dynamic> exam,
    bool showCountdown,
  ) {
    return _springEntry(
      key: ValueKey('exam_${exam['date']}_${exam['subject']}_$index'),
      duration: Duration(milliseconds: 420 + index * 75),
      offsetY: 28,
      startScale: 0.93,
      curve: _kSmoothBounce,
      child: _examCard(context, cs, exam, showCountdown),
    );
  }

  Widget _countdownChip(ColorScheme cs, int? daysUntil) {
    final l = AppL10n.of(appLocaleNotifier.value);
    if (daysUntil == null) return const SizedBox.shrink();
    String text;
    Color bg;
    Color fg = Colors.white;

    if (daysUntil == 0) {
      text = l.examsToday;
      bg = cs.error;
    } else if (daysUntil == 1) {
      text = l.examsTomorrow;
      bg = cs.tertiary;
    } else if (daysUntil > 1) {
      text = l.examsInDays(daysUntil);
      bg = cs.primary;
    } else {
      text = l.examsPast;
      bg = cs.onSurfaceVariant.withValues(alpha: 0.5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _examCard(
    BuildContext context,
    ColorScheme cs,
    Map<String, dynamic> exam,
    bool showCountdown,
  ) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final isCustom = exam['_source'] == 'custom';
    final subject = _examSubject(exam);
    final type = _examType(exam);
    final dateStr = _formatExamDate(exam['date'] ?? exam['examDate'] ?? '');
    final timeStart = exam['startTime'];
    final timeEnd = exam['endTime'];
    final timeStr = timeStart != null
        ? '${_formatUntisTime(timeStart.toString())} – ${_formatUntisTime((timeEnd ?? timeStart).toString())}'
        : '';
    final teachers = () {
      final t = exam['teachers'] ?? exam['teacher'];
      if (t is List) return t.join(', ');
      if (t is String && t.isNotEmpty) return t;
      return '';
    }();
    final rooms = () {
      final r = exam['rooms'] ?? exam['room'];
      if (r is List) return r.join(', ');
      if (r is String && r.isNotEmpty) return r;
      return '';
    }();
    final desc = (exam['description'] ?? '').toString().trim();

    final ds = (exam['date'] ?? exam['examDate'] ?? '').toString();
    int? daysUntil;
    if (ds.length == 8) {
      try {
        final d = DateTime.parse(
          '${ds.substring(0, 4)}-${ds.substring(4, 6)}-${ds.substring(6, 8)}',
        );
        daysUntil = d
            .difference(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
            )
            .inDays;
      } catch (_) {}
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isCustom ? cs.tertiary : _autoLessonColor(subject, isDark);

    int? customIndex;
    if (isCustom) {
      customIndex = _customExams.indexWhere(
        (e) => e['subject'] == exam['subject'] && e['date'] == exam['date'],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _glassContainer(
        context: context,
        borderRadius: BorderRadius.circular(24),
        color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: isCustom && customIndex != null
                ? () {
                    HapticFeedback.selectionClick();
                    _showAddExamDialog(
                      context,
                      existing: Map<String, dynamic>.from(exam)
                        ..remove('_source'),
                      editIndex: customIndex,
                    );
                  }
                : null,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (type.isNotEmpty)
                                    _chip(
                                      type,
                                      accent.withValues(alpha: 0.2),
                                      accent,
                                    ),
                                  if (isCustom)
                                    _chip(
                                      l.examsOwn,
                                      cs.tertiaryContainer,
                                      cs.tertiary,
                                    ),
                                ],
                              ),
                              const Spacer(),
                              if (showCountdown && daysUntil != null)
                                _countdownChip(cs, daysUntil),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subject.isNotEmpty ? subject : l.examsUnknown,
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              _infoBadge(
                                cs,
                                Icons.calendar_today_rounded,
                                dateStr,
                              ),
                              if (timeStr.isNotEmpty)
                                _infoBadge(
                                  cs,
                                  Icons.access_time_rounded,
                                  timeStr,
                                ),
                              if (rooms.isNotEmpty)
                                _infoBadge(
                                  cs,
                                  Icons.meeting_room_rounded,
                                  rooms,
                                ),
                              if (teachers.isNotEmpty)
                                _infoBadge(
                                  cs,
                                  Icons.person_outline_rounded,
                                  teachers,
                                ),
                            ],
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.notes_rounded,
                                    size: 14,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      desc,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurfaceVariant,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(ColorScheme cs, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
