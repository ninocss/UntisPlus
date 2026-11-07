part of '../main.dart';

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
    hiddenSubjectsNotifier.addListener(_onHiddenSubjectsChanged);
    subjectPresentationsNotifier.addListener(_onHiddenSubjectsChanged);
    aiEnabledNotifier.addListener(_onAiEnabledChanged);
    _load();
  }

  @override
  void dispose() {
    customExamsNotifier.removeListener(_onCustomExamsNotifierChanged);
    hiddenSubjectsNotifier.removeListener(_onHiddenSubjectsChanged);
    subjectPresentationsNotifier.removeListener(_onHiddenSubjectsChanged);
    aiEnabledNotifier.removeListener(_onAiEnabledChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onHiddenSubjectsChanged() {
    if (mounted) setState(() {});
  }

  void _onAiEnabledChanged() {
    if (mounted) setState(() {});
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
    final account = activeUntisAccount;
    final results = await _webUntisExamRepository.fetch(
      context: WebUntisRequestContext(
        schoolUrl: account?.schoolUrl ?? schoolUrl,
        schoolName: account?.schoolName ?? schoolName,
        sessionId: sessionID,
      ),
      personId: account?.personId ?? personId,
      start: start,
      end: end,
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
    );
    _apiExams = results;
    apiExamsNotifier.value = results;
    if (activeUntisAccountId != null && results.isNotEmpty) {
      final wrapped = SchoolWrappedRepository();
      for (final year in await wrapped.years(activeUntisAccountId!)) {
        if (year.contains(now)) {
          await wrapped.recordExams(
            accountId: activeUntisAccountId!,
            year: year,
            items: results,
          );
        }
      }
    }
  }

  List<Map<String, dynamic>> get _allExams {
    final all = [
      ..._apiExams.map((e) => {...e, '_source': 'api'}),
      ..._customExams.map((e) => {...e, '_source': 'custom'}),
    ].where((exam) => !_isSubjectHidden(_examSubject(exam))).toList();
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

  // Uses [AiRequestSpec] via [_requestAiVisionImportText].
  Future<void> _importExamsWithAI() async {
    final l = appL10nFor(appLocaleNotifier.value);
    final picked = await _pickAiImportFileFromSheet(
      context: context,
      sheetTitle: l.examsImportTitle,
    );
    if (picked == null || !mounted) return;

    try {
      final prompt = l.aiExamVisionPrompt(
        picked.supportsPdf ? l.aiFileKindPdf : '',
        DateTime.now().year,
      );

      final text = await runWithUntisBlockingLoader(
        context,
        () => _requestAiVisionImportText(
          prompt: prompt,
          fileBytes: picked.file.bytes,
          mimeType: picked.file.mimeType,
          attachmentName: 'exam-import',
          systemPromptBuilder: (capabilities, l) => capabilities.pdf
              ? l.aiExamJsonSystemPrompt
              : l.aiExamImageSystemPrompt,
          localProviderUnsupportedMessage: l.aiLocalModelExamNotSupported,
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
      context.showUntisSnackBar(
        '${l.examsImportError}${_formatAiErrorDetail(e, l)}',
      );
    }
  }

  Future<void> _exportCustomExams() async {
    final l = appL10nFor(appLocaleNotifier.value);
    if (_customExams.isEmpty) {
      context.showUntisSnackBar(l.examsExportEmpty);
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
    context.showUntisSnackBar(l.examsExportSuccess);
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
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
                            if (aiEnabledNotifier.value)
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
                            if (aiEnabledNotifier.value)
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
      body: Builder(
        builder: (context) => TabBarView(
          controller: _tabController,
          children: [
            ExpressiveRefreshIndicator(
              onRefresh: _refreshExams,
              child: ListView(
                padding: UntisLayout.pagePadding(
                  context,
                  bottom: 132,
                ).copyWith(top: MediaQuery.paddingOf(context).top + 16),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  if (_loading) ...[
                    const SizedBox(height: 140),
                    const Center(child: CircularProgressIndicator()),
                  ] else if (exams.isEmpty) ...[
                    _buildUnifiedEmptyState(
                      context: context,
                      icon: Icons.assignment_outlined,
                      title: l.examsNone,
                      hint: l.examsNoneHint,
                      action: TextButton.icon(
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
                    ),
                  ] else ...[
                    if (upcoming.isNotEmpty) ...[
                      _sectionHeader(
                        context,
                        l.examsUpcoming,
                        Icons.upcoming_rounded,
                        count: upcoming.length,
                      ),
                      const SizedBox(height: 8),
                      _buildAdaptiveCardGrid(
                        context,
                        upcoming.asMap().entries.map(
                          (e) => _animatedExamCard(
                            e.key,
                            context,
                            cs,
                            e.value,
                            true,
                          ),
                        ).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (past.isNotEmpty) ...[
                      _sectionHeader(
                        context,
                        l.examsPast,
                        Icons.history_rounded,
                        count: past.length,
                      ),
                      const SizedBox(height: 8),
                      _buildAdaptiveCardGrid(
                        context,
                        past.asMap().entries.map(
                          (e) => _animatedExamCard(
                            e.key,
                            context,
                            cs,
                            e.value,
                            false,
                          ),
                        ).toList(),
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
      ),
    );
  }

  final GlobalKey<_GradesTrackerPageState> _gradesTrackerKey = GlobalKey();

  Widget _animatedExamCard(
    int index,
    BuildContext context,
    ColorScheme cs,
    Map<String, dynamic> exam,
    bool showCountdown,
  ) {
    return _springEntry(
      key: ValueKey('exam_${exam['date']}_${exam['subject']}_$index'),
      duration: Duration(
        milliseconds: (420 + index * 45).clamp(420, 600).toInt(),
      ),
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
        ? '${formatUntisTime(timeStart.toString())} – ${formatUntisTime((timeEnd ?? timeStart).toString())}'
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // UTC calendar dates sidestep the 23/25-hour DST days, which would
    // otherwise truncate the elapsed-days countdown by one.
    final daysUntil = examDate == null
        ? null
        : DateTime.utc(
            examDate.year,
            examDate.month,
            examDate.day,
          ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;

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
                    AppHaptics.selection();
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Wrap(
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
                              ),
                              if (showCountdown && daysUntil != null) ...[
                                const SizedBox(width: 8),
                                _countdownChip(cs, daysUntil),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_customSubjectIcon(subject) != null)
                            Icon(_customSubjectIcon(subject), color: accent),
                          Text(
                            subject.isNotEmpty
                                ? _displaySubject(subject)
                                : l.examsUnknown,
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

Widget _buildAdaptiveCardGrid(
  BuildContext context,
  List<Widget> cards, {
  double spacing = 12,
  double runSpacing = 0,
}) {
  if (cards.isEmpty) return const SizedBox.shrink();
  if (!UntisLayout.isTablet(context)) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: cards,
    );
  }
  return LayoutBuilder(
    builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - spacing) / 2;
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: cards
            .map((card) => SizedBox(width: itemWidth, child: card))
            .toList(),
      );
    },
  );
}
