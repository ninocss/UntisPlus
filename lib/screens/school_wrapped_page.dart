part of '../main.dart';

Future<void> openSchoolWrapped(BuildContext context) async {
  final repository = SchoolWrappedRepository();
  final account = activeUntisAccount;
  WrappedYear? year;
  if (account == null || demoModeNotifier.value) {
    final now = DateTime.now();
    year = WrappedYear(
      start: DateTime(now.year - (now.month < 8 ? 1 : 0), 8, 1),
      end: DateTime(now.year + (now.month >= 8 ? 1 : 0), 7, 31),
    );
  } else {
    final years = await repository.years(account.id);
    if (!context.mounted || account.id != activeUntisAccountId) return;
    final today = DateTime.now();
    year = years.where((item) => item.contains(today)).firstOrNull;
    year ??= await repository.refreshSchoolYear(account);
    if (!context.mounted || account.id != activeUntisAccountId) return;
    year ??= years.firstOrNull;
    if (year == null) {
      final l = appL10nFor(appLocaleNotifier.value);
      final now = DateTime.now();
      final latest = DateTime(now.year + 2, 12, 31);
      final start = await showDatePicker(
        context: context,
        firstDate: DateTime(now.year - 5),
        lastDate: latest.subtract(const Duration(days: 1)),
        initialDate: DateTime(now.year - (now.month < 8 ? 1 : 0), 8, 1),
        helpText: l.wrapped('startDate'),
      );
      if (!context.mounted || start == null) return;
      final end = await showDatePicker(
        context: context,
        firstDate: start.add(const Duration(days: 1)),
        lastDate: latest,
        initialDate: DateTime(start.year + 1, 7, 31).isAfter(latest)
            ? latest
            : DateTime(start.year + 1, 7, 31),
        helpText: l.wrapped('endDate'),
      );
      if (!context.mounted || end == null) return;
      year = WrappedYear(start: start, end: end, manual: true);
      await repository.saveYear(account.id, year);
    }
  }
  if (!context.mounted) return;
  Navigator.of(context).push(
    _buildBouncyRoute(SchoolWrappedStory(year: year, account: account)),
  );
}

class SchoolWrappedHub extends StatefulWidget {
  const SchoolWrappedHub({super.key});
  @override
  State<SchoolWrappedHub> createState() => _SchoolWrappedHubState();
}

class _SchoolWrappedHubState extends State<SchoolWrappedHub> {
  final _repository = SchoolWrappedRepository();
  List<WrappedYear> _years = [];
  bool _loading = true;
  bool _needsDates = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final account = activeUntisAccount;
    if (account != null && !demoModeNotifier.value) {
      var years = await _repository.years(account.id);
      if (!mounted || account.id != activeUntisAccountId) return;
      setState(() {
        _years = years;
        _needsDates = !years.any((year) => year.contains(DateTime.now()));
        _loading = false;
      });
      final remote = await _repository.refreshSchoolYear(account);
      years = await _repository.years(account.id);
      if (!mounted || account.id != activeUntisAccountId) return;
      setState(() {
        _years = years;
        _needsDates =
            remote == null &&
            !years.any((year) => year.contains(DateTime.now()));
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _setDates() async {
    final l = appL10nFor(appLocaleNotifier.value);
    final now = DateTime.now();
    final earliest = DateTime(now.year - 5);
    final latest = DateTime(now.year + 2, 12, 31);
    final start = await showDatePicker(
      context: context,
      firstDate: earliest,
      lastDate: latest.subtract(const Duration(days: 1)),
      initialDate: DateTime(now.year - (now.month < 7 ? 1 : 0), 7, 1),
      helpText: l.wrapped('startDate'),
    );
    if (!mounted || start == null) return;
    final end = await showDatePicker(
      context: context,
      firstDate: start.add(const Duration(days: 1)),
      lastDate: latest,
      initialDate: DateTime(start.year + 1, 7, 31).isAfter(latest)
          ? latest
          : DateTime(start.year + 1, 7, 31),
      helpText: l.wrapped('endDate'),
    );
    if (!mounted || end == null) return;
    final account = activeUntisAccount;
    if (account == null) return;
    await _repository.saveYear(
      account.id,
      WrappedYear(start: start, end: end, manual: true),
    );
    final years = await _repository.years(account.id);
    if (mounted && account.id == activeUntisAccountId) {
      setState(() {
        _years = years;
        _needsDates = false;
      });
    }
  }

  void _open(WrappedYear year) {
    Navigator.of(context).push(
      _buildBouncyRoute(
        SchoolWrappedStory(year: year, account: activeUntisAccount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final demo = demoModeNotifier.value || activeUntisAccount == null;
    final demoYear = WrappedYear(
      start: DateTime(now.year - (now.month < 7 ? 1 : 0), 8, 1),
      end: DateTime(now.year + (now.month >= 7 ? 1 : 0), 7, 31),
    );
    return SettingsPageShell(
      title: l.wrapped('title'),
      children: [
        FeatureSummaryCard(
          icon: Icons.auto_awesome_rounded,
          title: Text(l.wrapped('intro')),
          secondary: Text(demo ? l.wrapped('demo') : l.wrapped('settingsDesc')),
        ),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          ),
        if (demo)
          SettingsTile(
            icon: Icons.play_circle_fill_rounded,
            iconBackgroundColor: cs.primaryContainer,
            iconColor: cs.onPrimaryContainer,
            title: l.wrapped('begin'),
            subtitle: l.wrapped('demo'),
            onTap: () => _open(demoYear),
          ),
        for (final year in _years)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SettingsTile(
              icon: Icons.bubble_chart_rounded,
              iconBackgroundColor: cs.tertiaryContainer,
              iconColor: cs.onTertiaryContainer,
              title: 'School Wrapped ${year.label}',
              subtitle: year.hasEnded
                  ? l.wrapped('complete')
                  : l.wrapped('partial'),
              onTap: () => _open(year),
            ),
          ),
        if (!_loading && !demo && _needsDates)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l.wrapped('datesInfo')),
          ),
        if (!_loading && !demo && _years.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l.wrapped('noYear')),
          ),
        if (!_loading && !demo)
          OutlinedButton.icon(
            onPressed: _setDates,
            icon: const Icon(Icons.edit_calendar_rounded),
            label: Text(l.wrapped('configure')),
          ),
      ],
    );
  }
}

class SchoolWrappedStory extends StatefulWidget {
  const SchoolWrappedStory({
    required this.year,
    required this.account,
    super.key,
  });
  final WrappedYear year;
  final UntisAccount? account;
  @override
  State<SchoolWrappedStory> createState() => _SchoolWrappedStoryState();
}

class _WrappedSlide {
  const _WrappedSlide({
    required this.title,
    required this.value,
    required this.unit,
    required this.caption,
    required this.icon,
    required this.colors,
    this.detail = '',
  });
  final String title;
  final String value;
  final String unit;
  final String caption;
  final String detail;
  final IconData icon;
  final List<Color> colors;
}

class _SchoolWrappedStoryState extends State<SchoolWrappedStory>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _repository = SchoolWrappedRepository();
  final _pages = PageController();
  final _player = AudioPlayer();
  late final AnimationController _motion;
  late final AnimationController _slideProgress;
  Timer? _advanceTimer;
  WrappedSnapshot? _snapshot;
  int _index = 0;
  int _progress = 0;
  int _total = 0;
  bool _loading = true;
  bool _muted = false;
  bool _stopped = false;
  bool _audioFailed = false;
  bool _autoAdvance = true;
  bool _appPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _slideProgress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _startAudio();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations ||
        !backgroundAnimationsNotifier.value) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  Future<void> _startAudio() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/city-loop.mp3'), volume: 0.28);
      if (_stopped) await _player.stop();
    } catch (_) {
      if (mounted) {
        setState(() => _audioFailed = true);
      }
    }
  }

  Future<void> _toggleAudio() async {
    if (_muted || _audioFailed) {
      setState(() {
        _muted = false;
        _audioFailed = false;
      });
      await _startAudio();
    } else {
      setState(() => _muted = true);
      await _player.pause();
    }
  }

  Future<void> _load() async {
    if (widget.account == null || demoModeNotifier.value) {
      final year = widget.year;
      final l = appL10nFor(appLocaleNotifier.value);
      setState(() {
        _snapshot = WrappedSnapshot(
          year: year,
          coveredWeeks: 36,
          expectedWeeks: 36,
          lessons: 713,
          lessonMinutes: 32085,
          cancelled: 42,
          substitutions: 31,
          absentLessons: 9,
          absenceRecords: 4,
          excusedAbsences: 3,
          unexcusedAbsences: 1,
          freeWeekdays: 54,
          holidayNames: [l.wrapped('summer'), l.wrapped('winter')],
          grades: 18,
          gradeSubjects: {l.wrapped('math'): 5, l.wrapped('language'): 4},
          exams: 12,
          homework: 87,
          hasAbsenceSource: true,
          hasHolidaySource: true,
          hasExamSource: true,
          hasHomeworkSource: true,
        );
        _loading = false;
      });
      _armAutoAdvance(_slides(_snapshot!, l).length);
      return;
    }
    final account = widget.account!;
    await loadCustomData();
    if (_stopped || !mounted || account.id != activeUntisAccountId) return;
    final current = await _repository.snapshot(
      accountId: account.id,
      year: widget.year,
      grades: customGradesNotifier.value,
      customExams: customExamsNotifier.value,
      customHomework: customHomeworkNotifier.value,
    );
    if (!mounted || _stopped) return;
    setState(() => _snapshot = current);
    _armAutoAdvance(
      _slides(current, appL10nFor(appLocaleNotifier.value)).length,
    );
    await _repository.fillMissing(
      account: account,
      year: widget.year,
      cancelled: () => _stopped || account.id != activeUntisAccountId,
      onProgress: (done, total) {
        if (mounted && !_stopped) {
          setState(() {
            _progress = done;
            _total = total;
          });
        }
      },
    );
    if (!mounted || _stopped || account.id != activeUntisAccountId) return;
    final updated = await _repository.snapshot(
      accountId: account.id,
      year: widget.year,
      grades: customGradesNotifier.value,
      customExams: customExamsNotifier.value,
      customHomework: customHomeworkNotifier.value,
    );
    if (mounted) {
      setState(() {
        _snapshot = updated;
        _loading = false;
      });
      _armAutoAdvance(_slides(updated, appL10nFor(appLocaleNotifier.value)).length);
    }
  }

  void _armAutoAdvance(int length) {
    _advanceTimer?.cancel();
    _slideProgress.stop();
    _slideProgress.value = 0;
    if (!mounted || _appPaused || !_autoAdvance || _stopped ||
        _index >= length - 1 || MediaQuery.of(context).disableAnimations ||
        !backgroundAnimationsNotifier.value) {
      return;
    }
    _slideProgress.forward();
    _advanceTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || _stopped || _index >= length - 1) return;
      _go(_index + 1, length);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_muted && !_audioFailed) {
      _player.resume();
    } else if (state != AppLifecycleState.resumed) {
      _player.pause();
    }
    _appPaused = state != AppLifecycleState.resumed;
    if (_appPaused) {
      _advanceTimer?.cancel();
      _slideProgress.stop();
      _motion.stop();
    } else {
      if (backgroundAnimationsNotifier.value &&
          !MediaQuery.of(context).disableAnimations) {
        _motion.repeat();
      }
      if (_snapshot != null) {
        _armAutoAdvance(_slides(_snapshot!, appL10nFor(appLocaleNotifier.value)).length);
      }
    }
  }

  @override
  void dispose() {
    _stopped = true;
    _advanceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    _pages.dispose();
    _motion.dispose();
    _slideProgress.dispose();
    super.dispose();
  }

  List<_WrappedSlide> _slides(WrappedSnapshot s, AppL10n l) {
    const ink = Color(0xFF111021);
    final slides = <_WrappedSlide>[
      _WrappedSlide(
        title: s.year.hasEnded ? l.wrapped('complete') : l.wrapped('partial'),
        value: s.year.label,
        unit: 'SCHOOL WRAPPED',
        caption: l.wrapped('intro'),
        icon: Icons.auto_awesome,
        colors: const [Color(0xFFFC4C74), Color(0xFF8027D2), ink],
      ),
    ];
    if (s.coveredWeeks > 0) {
      slides.addAll([
        _WrappedSlide(
          title: l.wrapped('lessonsTitle'),
          value: '${s.lessons}',
          unit: l.wrapped('lessons'),
          caption:
              '${(s.lessonMinutes / 60).toStringAsFixed(0)} h · ${l.wrapped('hours')}',
          icon: Icons.school_rounded,
          colors: const [Color(0xFFEEAD34), Color(0xFFE34368), ink],
        ),
        _WrappedSlide(
          title: l.wrapped('changesTitle'),
          value: '${s.cancelled}',
          unit: l.wrapped('cancelled'),
          caption: '${s.substitutions} · ${l.wrapped('substitutions')}',
          icon: Icons.bolt_rounded,
          colors: const [Color(0xFF7828E8), Color(0xFFED3D9D), ink],
        ),
      ]);
    }
    if (s.hasAbsenceSource) {
      slides.add(
        _WrappedSlide(
          title: l.wrapped('absenceTitle'),
          value: '${s.absentLessons}',
          unit: l.wrapped('absentLessons'),
          caption: '${s.absenceRecords} ${l.wrapped('absenceRecords')}',
          detail:
              '${s.excusedAbsences} ${l.wrapped('excused')} · '
              '${s.unexcusedAbsences} ${l.wrapped('unexcused')}',
          icon: Icons.event_busy_rounded,
          colors: const [Color(0xFF178FC2), Color(0xFF3ED1BC), ink],
        ),
      );
    }
    if (s.hasHolidaySource || s.freeWeekdays > 0) {
      slides.add(
        _WrappedSlide(
          title: l.wrapped('freeTitle'),
          value: '${s.freeWeekdays}',
          unit: l.wrapped('freeDays'),
          caption: l.wrapped('holidays'),
          detail: s.holidayNames.take(4).join(' · '),
          icon: Icons.wb_sunny_rounded,
          colors: const [Color(0xFFF18224), Color(0xFFF2C94C), ink],
        ),
      );
    }
    if (s.grades > 0) {
      final subjects = s.gradeSubjects.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      slides.add(
        _WrappedSlide(
          title: l.wrapped('gradeTitle'),
          value: '${s.grades}',
          unit: l.wrapped('grades'),
          caption: subjects
              .take(3)
              .map((e) => '${e.key} ${e.value}')
              .join(' · '),
          icon: Icons.grade_rounded,
          colors: const [Color(0xFF1BA698), Color(0xFF91DA68), ink],
        ),
      );
    }
    if (s.hasExamSource || s.hasHomeworkSource) {
      slides.add(
        _WrappedSlide(
          title: l.wrapped('workTitle'),
          value: '${s.exams}',
          unit: l.wrapped('exams'),
          caption: '${s.homework} · ${l.wrapped('homework')}',
          icon: Icons.edit_note_rounded,
          colors: const [Color(0xFF6042DF), Color(0xFF5C89EC), ink],
        ),
      );
    }
    slides.add(
      _WrappedSlide(
        title: l.wrapped('finalTitle'),
        value: '✦',
        unit: s.year.label,
        caption: l.wrapped('finalSub'),
        detail: [
          if (s.incomplete) l.wrapped('incomplete'),
          if (!s.hasAbsenceSource ||
              !s.hasHolidaySource ||
              !s.hasExamSource ||
              !s.hasHomeworkSource)
            l.wrapped('sourceMissing'),
        ].join('\n'),
        icon: Icons.favorite_rounded,
        colors: const [Color(0xFFDD357B), Color(0xFF8A3FE5), ink],
      ),
    );
    return slides;
  }

  void _go(int index, int length) {
    if (index < 0 || index >= length) return;
    _advanceTimer?.cancel();
    if (MediaQuery.of(context).disableAnimations ||
        !backgroundAnimationsNotifier.value) {
      _pages.jumpToPage(index);
      return;
    }
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 760),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final reduceMotion =
        MediaQuery.of(context).disableAnimations ||
        !backgroundAnimationsNotifier.value;
    if (_loading && (_snapshot == null || _snapshot!.coveredWeeks == 0)) {
      return Scaffold(
        backgroundColor: const Color(0xFF151126),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l.wrapped('loading'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 28),
                    LinearProgressIndicator(
                      value: _total == 0 ? null : _progress / _total,
                      color: const Color(0xFFFFC153),
                      backgroundColor: Colors.white24,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _total == 0 ? '' : '$_progress / $_total',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l.wrapped('close')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final snapshot = _snapshot;
    if (snapshot == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.wrapped('title'))),
        body: Center(
          child: FilledButton(
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
            child: Text(l.wrapped('retry')),
          ),
        ),
      );
    }
    if (!_loading &&
        snapshot.coveredWeeks == 0 &&
        snapshot.grades == 0 &&
        snapshot.exams == 0 &&
        snapshot.homework == 0 &&
        !demoModeNotifier.value) {
      return Scaffold(
        appBar: AppBar(title: Text(l.wrapped('title'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 52),
                const SizedBox(height: 18),
                Text(l.wrapped('noData'), textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    setState(() => _loading = true);
                    _load();
                  },
                  child: Text(l.wrapped('retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final slides = _slides(snapshot, l);
    final safeIndex = _index.clamp(0, slides.length - 1);
    final slide = slides[safeIndex];
    return Scaffold(
      backgroundColor: slide.colors.last,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: slide.colors,
                ),
              ),
            ),
          ),
          if (!reduceMotion)
            Positioned.fill(
              child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, _) => IgnorePointer(
                    child: CustomPaint(
                      painter: _WrappedGlowPainter(
                        phase: _motion.value,
                        colors: slide.colors,
                      ),
                    ),
                  ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                  child: Row(
                    children: [
                      for (var i = 0; i < slides.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 4,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ColoredBox(
                                      color: Colors.white.withValues(
                                        alpha: i < safeIndex ? 0.95 : 0.3,
                                      ),
                                    ),
                                    if (i == safeIndex)
                                      AnimatedBuilder(
                                        animation: _slideProgress,
                                        builder: (context, _) => Align(
                                          alignment: Alignment.centerLeft,
                                          child: FractionallySizedBox(
                                            widthFactor: _slideProgress.value,
                                            child: const ColoredBox(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: l.wrapped('close'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (_loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    IconButton(
                      tooltip: l.wrapped(_autoAdvance ? 'autoOn' : 'autoOff'),
                      onPressed: () {
                        setState(() => _autoAdvance = !_autoAdvance);
                        _armAutoAdvance(slides.length);
                      },
                      icon: Icon(
                        _autoAdvance
                            ? Icons.motion_photos_auto_rounded
                            : Icons.touch_app_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      tooltip: l.wrapped(
                        _muted || _audioFailed ? 'musicOff' : 'musicOn',
                      ),
                      onPressed: _toggleAudio,
                      icon: Icon(
                        _muted || _audioFailed
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: slides.length,
                    onPageChanged: (index) {
                      setState(() => _index = index);
                      _armAutoAdvance(slides.length);
                    },
                    itemBuilder: (context, index) => _WrappedSlideView(
                      slide: slides[index],
                      reduceMotion: reduceMotion,
                      idleAnimation: _motion,
                      footer: index == 0 && demoModeNotifier.value
                          ? l.wrapped('demo')
                          : index == 0 && snapshot.incomplete
                          ? l.wrapped('incomplete')
                          : null,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    math.max(20, MediaQuery.paddingOf(context).bottom),
                  ),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: safeIndex == 0
                            ? null
                            : () => _go(safeIndex - 1, slides.length),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(l.wrapped('back')),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white38,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => safeIndex == slides.length - 1
                            ? Navigator.pop(context)
                            : _go(safeIndex + 1, slides.length),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          l.wrapped(
                            safeIndex == slides.length - 1 ? 'close' : 'next',
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1B1736),
                        ),
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

class _WrappedSlideView extends StatelessWidget {
  const _WrappedSlideView({
    required this.slide,
    required this.reduceMotion,
    required this.idleAnimation,
    this.footer,
  });
  final _WrappedSlide slide;
  final bool reduceMotion;
  final Animation<double> idleAnimation;
  final String? footer;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final titleSize = size.width < 380 ? 30.0 : 38.0;
    final numberSize = size.width < 380 ? 84.0 : 112.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(slide.title),
              tween: Tween(begin: 0, end: 1),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 720),
              curve: Curves.easeOutBack,
              builder: (context, value, child) => Opacity(
                opacity: value.clamp(0, 1),
                child: Transform.scale(
                  scale: reduceMotion ? 1 : 0.92 + value * 0.08,
                  child: Transform.translate(
                    offset: Offset(0, reduceMotion ? 0 : (1 - value) * 45),
                    child: child,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: idleAnimation,
                    builder: (context, child) {
                      final phase = idleAnimation.value * math.pi * 2;
                      return Transform.translate(
                        offset: Offset(0, math.sin(phase) * 7),
                        child: Transform.rotate(
                          angle: math.sin(phase) * 0.045,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(slide.icon, color: Colors.white, size: 60),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      slide.value,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: numberSize,
                        fontWeight: FontWeight.w900,
                        height: 0.95,
                        letterSpacing: -5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    slide.unit.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    slide.caption,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (slide.detail.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      slide.detail,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 15,
                      ),
                    ),
                  ],
                  if (footer != null) ...[
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        footer!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WrappedGlowPainter extends CustomPainter {
  const _WrappedGlowPainter({required this.phase, required this.colors});
  final double phase;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final orbit = phase * math.pi * 2;
    final shortest = size.shortestSide;
    final blobs = <(double, double, double, Color)>[
      (0.82, 0.23, 0.34, colors.first),
      (0.14, 0.77, 0.28, colors.length > 1 ? colors[1] : colors.first),
      (0.55, 0.52, 0.18, Colors.white),
    ];
    for (var i = 0; i < blobs.length; i++) {
      final blob = blobs[i];
      final angle = orbit + i * 2.05;
      final center = Offset(
        size.width * (blob.$1 + math.sin(angle) * (i == 2 ? 0.08 : 0.055)),
        size.height * (blob.$2 + math.cos(angle * 0.8) * 0.06),
      );
      final radius = shortest * blob.$3 * (0.92 + math.sin(angle * 1.4) * 0.06);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blob.$4.withValues(alpha: i == 2 ? 0.20 : 0.30),
            blob.$4.withValues(alpha: 0.07),
            blob.$4.withValues(alpha: 0),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect);
      canvas.drawCircle(center, radius, paint);
    }
    final orbitPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.save();
    canvas.translate(size.width * 0.82, size.height * 0.24);
    canvas.rotate(orbit * 0.12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: shortest * 0.88,
        height: shortest * 0.30,
      ),
      orbitPaint,
    );
    canvas.restore();
    final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.42);
    for (var i = 0; i < 9; i++) {
      final seed = i * 2.4;
      final x = (0.08 + ((i * 37) % 83) / 100) * size.width;
      final y = (0.12 + ((i * 19) % 76) / 100) * size.height;
      final twinkle = (math.sin(orbit * 1.5 + seed) + 1) / 2;
      final radius = 0.8 + twinkle * 2.2;
      canvas.drawCircle(
        Offset(x + math.sin(orbit + seed) * 12, y + math.cos(orbit + seed) * 9),
        radius,
        sparklePaint..color = Colors.white.withValues(alpha: 0.12 + twinkle * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_WrappedGlowPainter oldDelegate) =>
      oldDelegate.phase != phase || !listEquals(oldDelegate.colors, colors);
}
