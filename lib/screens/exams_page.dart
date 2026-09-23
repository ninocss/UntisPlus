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
    await loadCustomData();
    _customExams = List<Map<String, dynamic>>.from(customExamsNotifier.value);
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
    final results = await _webUntisExamRepository.fetch(
      context: WebUntisRequestContext(
        schoolUrl: schoolUrl,
        schoolName: schoolName,
        sessionId: sessionID,
      ),
      personId: personId,
      start: start,
      end: end,
    );
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
    final parsed = parseUntisDate(date);
    if (parsed == null) return date.toString();
    return DateFormat(
      'EEEE, dd. MMMM yyyy',
      _icuLocale(appLocaleNotifier.value),
    ).format(parsed);
  }

  String _examSubject(Map<String, dynamic> e) =>
      (e['subject'] ?? e['name'] ?? e['examType'] ?? '').toString();

  String _examType(Map<String, dynamic> e) =>
      (e['examType'] ?? e['type'] ?? e['typeName'] ?? '').toString();

  Future<String> _requestExamImportResponse({
    required String prompt,
    required Uint8List fileBytes,
    required String mimeType,
  }) {
    final l = appL10nFor(appLocaleNotifier.value);
    final runtime = _currentAiRuntimeConfiguration();
    final provider = _aiRequestCoordinator.normalizeProvider(runtime.provider);
    final capabilities = _aiRequestCoordinator.capabilities(runtime);
    final attachment = AiChatAttachment(
      name: 'exam-import',
      mimeType: mimeType,
      bytes: fileBytes,
    );
    return _aiRequestCoordinator.generate(
      runtime: runtime,
      spec: AiRequestSpec(
        systemPrompt: capabilities.pdf
            ? l.aiExamJsonSystemPrompt
            : l.aiExamImageSystemPrompt,
        userPrompt: prompt,
        temperature: 0.1,
        maxTokens: 2200,
        topP: 1,
        requiresImages: mimeType.startsWith('image/'),
        requiresPdf: mimeType == 'application/pdf',
        allowLocal: false,
        attachments: [attachment],
        noReplyMessage: l.aiNoReply,
        missingApiKeyMessage: _providerAwareMissingApiKeyMessage(l, provider),
        customBaseUrlMissingMessage: l.aiCustomBaseUrlMissing,
        localProviderUnsupportedMessage: l.aiLocalModelExamNotSupported,
        unsupportedAttachmentMessage: (type) =>
            'Unsupported file type for this provider: $type',
      ),
    );
  }

  Future<void> _importExamsWithAI() async {
    final l = appL10nFor(appLocaleNotifier.value);
    final runtime = _currentAiRuntimeConfiguration();
    final provider = _aiRequestCoordinator.normalizeProvider(runtime.provider);
    final capabilities = _aiRequestCoordinator.capabilities(runtime);
    final preflight = AiRequestSpec(
      systemPrompt: '',
      userPrompt: '',
      noReplyMessage: l.aiNoReply,
      allowLocal: true,
      requireLocalModel: false,
      missingApiKeyMessage: _providerAwareMissingApiKeyMessage(l, provider),
      customBaseUrlMissingMessage: l.aiCustomBaseUrlMissing,
    );
    try {
      _aiRequestCoordinator.validate(runtime, preflight);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: CONFIG: ', '');
      if (mounted) context.showUntisSnackBar(message);
      return;
    }
    final providerUsesGeminiProtocol = capabilities.pdf;

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
    final importFile = await _pickAiImportFile(
      source,
      allowPdf: providerUsesGeminiProtocol,
    );
    if (importFile == null) return;

    if (!mounted) return;

    try {
      final prompt = l.aiExamVisionPrompt(
        providerUsesGeminiProtocol ? l.aiFileKindPdf : '',
        DateTime.now().year,
      );

      final text = await runWithUntisBlockingLoader(
        context,
        () => _requestExamImportResponse(
          prompt: prompt,
          fileBytes: importFile.bytes,
          mimeType: importFile.mimeType,
        ),
      );
      if (!mounted) return;

      final exams = parseJsonObjectArrayFromModelText(
        text,
        invalidMessage: l.examsImportInvalidJson,
      );

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
        context.showUntisSnackBar(l.examsImportSuccess);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      final isApiError = message.contains('API:');
      final isConfigError = message.contains('CONFIG:');
      final detail = isConfigError
          ? message.replaceFirst('Exception: CONFIG: ', '')
          : isApiError
          ? '${l.aiApiError} ${message.replaceFirst('Exception: API: ', '')}'
          : '${l.aiConnectionError} $e';
      context.showUntisSnackBar('${l.examsImportError}$detail');
    }
  }

  Future<void> _exportCustomExams() async {
    final l = appL10nFor(appLocaleNotifier.value);
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
    final l = appL10nFor(appLocaleNotifier.value);
    final exams = _allExams;
    final todayInt = untisDateInt(DateTime.now());

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
                            l.reload,
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
    final nextSubText = nextSubject != null && nextDateStr != null
        ? l.examsUpcomingNext(nextSubject, nextDateStr)
        : null;

    return FeatureSummaryCard(
      icon: Icons.assignment_turned_in_rounded,
      title: Text(
        l.examsUpcomingCount(count),
        style: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: cs.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      secondary: nextSubText == null
          ? null
          : Row(
              children: [
                Icon(Icons.near_me_rounded, size: 13, color: cs.primary),
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
    final l = appL10nFor(appLocaleNotifier.value);
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
    final l = appL10nFor(appLocaleNotifier.value);
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

    final examDate = parseUntisDate(exam['date'] ?? exam['examDate']);
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final daysUntil = examDate?.difference(today).inDays;

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
