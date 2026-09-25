part of '../main.dart';

// --- WOCHENPLAN (TAB VIEW) ---
class WeeklyTimetablePage extends StatefulWidget {
  const WeeklyTimetablePage({super.key});

  @override
  State<WeeklyTimetablePage> createState() => _WeeklyTimetablePageState();
}

class _LessonSlot {
  const _LessonSlot({
    required this.lesson,
    required this.startMin,
    required this.endMin,
    required this.column,
    required this.columnCount,
  });

  final Map<dynamic, dynamic> lesson;
  final int startMin;
  final int endMin;
  final int column;
  final int columnCount;
}

class _LessonSlotCandidate {
  _LessonSlotCandidate({
    required this.lesson,
    required this.startMin,
    required this.endMin,
  });

  final Map<dynamic, dynamic> lesson;
  final int startMin;
  final int endMin;
  int column = 0;
}

class _TimeRangeLabel {
  const _TimeRangeLabel({required this.startMin, required this.endMin});

  final int startMin;
  final int endMin;
}

List<int> _filterTimeLabels(
  List<_TimeRangeLabel> ranges, {
  int minGapMinutes = 15,
}) {
  final sorted =
      ranges.expand((range) => [range.startMin, range.endMin]).toSet().toList()
        ..sort();
  final filtered = <int>[];
  for (final value in sorted) {
    if (filtered.isEmpty || value - filtered.last >= minGapMinutes) {
      filtered.add(value);
    }
  }
  return filtered;
}

class _WeeklyTimetablePageState extends State<WeeklyTimetablePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<int, List<dynamic>> _weekData = {0: [], 1: [], 2: [], 3: [], 4: []};
  List<Map<String, dynamic>> _holidays = [];
  bool _loading = true;
  String? _loadError;
  bool _showingCachedWeek = false;
  int _viewMode = 0;
  bool get _isDailyView => _viewMode == 0;
  bool get _isThreeDayView => _viewMode == 1;
  bool get _isWeekView => _viewMode == 2;

  List<int> get _visibleGridDays {
    if (_isWeekView) return const [0, 1, 2, 3, 4];
    final selectedDay = _tabController.index.clamp(0, 4).toInt();
    final firstDay = (selectedDay - 1).clamp(0, 2);
    return List<int>.generate(3, (index) => firstDay + index);
  }

  // Carousel state for week switching
  double _carouselOffset = 0.0;
  AnimationController? _carouselAnimController;
  final Map<String, Map<int, List<dynamic>>> _adjacentWeekCache = {};
  bool _adjacentWeekRefreshScheduled = false;
  // The day view has its own carousel so its page follows the finger instead
  // of only changing the selected tab after a drag has finished.
  double _dayCarouselOffset = 0.0;
  // When a date tab is tapped, the incoming page may be farther than the
  // adjacent day. Keep it explicit until the carousel has completed.
  int? _dayCarouselTargetDay;
  AnimationController? _dayCarouselAnimController;
  Animation<double>? _dayCarouselAnimation;
  CarouselController? _materialDayCarouselController;
  CarouselController? _materialWeekCarouselController;
  int _materialDayIndex = 1;
  int _materialWeekIndex = 1;
  bool _isWeekCarouselAnimating = false;
  bool _isDayCarouselAnimating = false;
  bool _suppressDayTabControllerRebuild = false;
  late final AnimationController _cacheRefreshController;
  int _weekFetchGeneration = 0;
  bool _isExportingTimetable = false;
  final GlobalKey _timetableExportKey = GlobalKey();
  final Map<String, Map<dynamic, dynamic>> _temporaryLessonOriginals = {};
  final Map<String, String> _originalTeachers = {};
  int? _highlightDate;
  int? _highlightStartTime;
  AnimationController? _highlightController;
  Timer? _highlightTimer;
  AlarmConfig _alarmConfig = const AlarmConfig();
  Timer? _progressiveNotificationTimer;

  String? _tempSessionId;
  int? _viewingClassId;
  String? _viewingClassName;

  String get _currentSessionId =>
      (_viewingClassId != null && _tempSessionId != null)
      ? _tempSessionId!
      : sessionID;

  WebUntisRequestContext get _timetableRequestContext => WebUntisRequestContext(
    schoolUrl: schoolUrl,
    schoolName: schoolName,
    sessionId: _currentSessionId,
  );

  static const double _ppm = 1.5;

  List<String> get _dayShort =>
      appL10nFor(appLocaleNotifier.value).weekDayShort;

  final Map<int, String> _subjectLong = {};
  final Map<int, String> _subjectShortMap = {};
  final Map<int, String> _teacherMap = {};
  final Map<int, String> _roomMap = {};

  String _mondayKey(DateTime monday) => untisDateString(monday);

  String _lessonIdentityOf(Map<dynamic, dynamic> lesson) =>
      TimetableLessonSnapshot.fromJson(lesson).identity;

  void _applyOriginalTeachers(Iterable<TimetableChange> changes) {
    final originals = <String, String>{};
    for (final change in changes) {
      if (change.type == TimetableChangeType.teacher &&
          change.lessonIdentity.isNotEmpty &&
          (change.before ?? '').trim().isNotEmpty) {
        originals[change.lessonIdentity] = change.before!.trim();
      }
    }
    final changed =
        originals.length != _originalTeachers.length ||
        originals.entries.any(
          (entry) => _originalTeachers[entry.key] != entry.value,
        );
    _originalTeachers
      ..clear()
      ..addAll(originals);
    if (changed && mounted) setState(() {});
  }

  Future<void> _loadStoredTeacherChanges() async {
    try {
      final changes = await ChangeRepository().loadChanges(
        activeUntisAccountId ?? 'legacy',
      );
      _applyOriginalTeachers(changes);
    } catch (_) {}
  }

  String _weekCacheKeyFor({
    required DateTime monday,
    required int requestPersonId,
    required int requestPersonType,
  }) {
    final mondayStr = untisDateString(monday);
    return [
      'weekCacheV1',
      schoolUrl,
      schoolName,
      requestPersonType.toString(),
      requestPersonId.toString(),
      mondayStr,
    ].join('|');
  }

  String _weekCacheKey({
    required int requestPersonId,
    required int requestPersonType,
  }) {
    return _weekCacheKeyFor(
      monday: _currentMonday,
      requestPersonId: requestPersonId,
      requestPersonType: requestPersonType,
    );
  }

  Map<int, List<dynamic>> _emptyWeekData() => {
    0: <dynamic>[],
    1: <dynamic>[],
    2: <dynamic>[],
    3: <dynamic>[],
    4: <dynamic>[],
  };

  void _applyKnownSubjectsFromWeek(Map<int, List<dynamic>> weekData) {
    final allSubjects = <String>{};
    for (final list in weekData.values) {
      for (final l in list) {
        final s = l['_subjectShort']?.toString() ?? '';
        if (s.isNotEmpty) allSubjects.add(s);
      }
    }
    knownSubjectsNotifier.value = allSubjects;
  }

  Future<Map<int, List<dynamic>>?> _loadWeekFromCache({
    required int requestPersonId,
    required int requestPersonType,
    DateTime? monday,
  }) async {
    try {
      final prefs = SettingsStore.instance.preferences;
      final key = monday != null
          ? _weekCacheKeyFor(
              monday: monday,
              requestPersonId: requestPersonId,
              requestPersonType: requestPersonType,
            )
          : _weekCacheKey(
              requestPersonId: requestPersonId,
              requestPersonType: requestPersonType,
            );
      final storeKey = OfflineCacheStore.instance.scopedKey(
        accountId: activeUntisAccountId ?? 'legacy',
        dataset: 'timetableWeek',
        entityKey: key,
      );
      final stored = await OfflineCacheStore.instance.read(storeKey);
      dynamic decoded = stored?.value;
      if (decoded == null) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) return null;
        decoded = jsonDecode(raw);
        if (decoded is Map) {
          await OfflineCacheStore.instance.write(
            storeKey,
            Map<String, dynamic>.from(decoded),
          );
          await prefs.remove(key);
        }
      }
      if (decoded is! Map) return null;
      final week = decoded['weekData'];
      if (week is! Map) return null;

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
          final aStart = (a['startTime'] as num?)?.toInt() ?? 0;
          final bStart = (b['startTime'] as num?)?.toInt() ?? 0;
          return aStart.compareTo(bStart);
        });
      });

      final cachedHolidays = decoded['holidays'];
      if (cachedHolidays is List) {
        _holidays = cachedHolidays
            .whereType<Map>()
            .map((h) => Map<String, dynamic>.from(h.cast<String, dynamic>()))
            .toList();
      }

      return tempWeek;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveWeekToCache({
    required int requestPersonId,
    required int requestPersonType,
    required Map<int, List<dynamic>> weekData,
    DateTime? monday,
  }) async {
    try {
      final prefs = SettingsStore.instance.preferences;
      final key = monday != null
          ? _weekCacheKeyFor(
              monday: monday,
              requestPersonId: requestPersonId,
              requestPersonType: requestPersonType,
            )
          : _weekCacheKey(
              requestPersonId: requestPersonId,
              requestPersonType: requestPersonType,
            );
      final payload = {
        'savedAt': DateTime.now().toIso8601String(),
        'weekData': {
          for (var i = 0; i < 5; i++) '$i': weekData[i] ?? const <dynamic>[],
        },
        if (_holidays.isNotEmpty) 'holidays': _holidays,
      };
      final storeKey = OfflineCacheStore.instance.scopedKey(
        accountId: activeUntisAccountId ?? 'legacy',
        dataset: 'timetableWeek',
        entityKey: key,
      );
      await OfflineCacheStore.instance.write(storeKey, payload);
      if (!demoModeNotifier.value &&
          requestPersonId == personId &&
          requestPersonType == personType) {
        final wrapped = SchoolWrappedRepository();
        for (final year in await wrapped.years(
          activeUntisAccountId ?? 'legacy',
        )) {
          final weekStart = monday ?? _currentMonday;
          if (year.contains(weekStart.add(const Duration(days: 4))) ||
              year.contains(weekStart)) {
            await wrapped.recordWeek(
              accountId: activeUntisAccountId ?? 'legacy',
              year: year,
              monday: weekStart,
              days: weekData,
            );
          }
        }
      }
      // Remove a migrated legacy JSON cache only after the Hive write succeeds.
      await prefs.remove(key);
    } catch (_) {}
  }

  String _extractTeacherNamesFromLesson(
    Map<dynamic, dynamic> lesson, {
    bool full = false,
  }) {
    final teacherEntries = ((lesson['te'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .cast<Map<dynamic, dynamic>>()
        .toList();
    final teacherParts = <String>[];
    for (final te in teacherEntries) {
      final teId = te['id'] as int?;
      final mapped = teId != null ? _teacherMap[teId] : null;
      final short = (te['name'] ?? te['shortName'] ?? '').toString().trim();
      final directFull =
          (te['fullName'] ??
                  te['displayName'] ??
                  te['longName'] ??
                  te['longname'] ??
                  '')
              .toString()
              .trim();
      final candidate = full
          ? (mapped?.trim().isNotEmpty == true
                ? mapped!.trim()
                : (directFull.isNotEmpty ? directFull : short))
          : (short.isNotEmpty
                ? short
                : (directFull.isNotEmpty ? directFull : mapped ?? ''));
      if (candidate.isNotEmpty && !teacherParts.contains(candidate)) {
        teacherParts.add(candidate);
      }
    }
    return teacherParts.join(', ');
  }

  String _displayTeacher(Map<dynamic, dynamic> lesson) {
    final display = lessonTeacherDisplayName(lesson);
    if (!lessonFullTeacherNamesNotifier.value ||
        (lesson['_teacherFull']?.toString().trim().isNotEmpty ?? false)) {
      return display;
    }
    final fromEntries = _extractTeacherNamesFromLesson(lesson, full: true);
    return fromEntries.isNotEmpty ? fromEntries : display;
  }

  String _extractTeacherNamesFromTopLevel(Map<dynamic, dynamic> lesson) {
    final candidates = <String>[];

    void addValue(dynamic value) {
      if (value == null) return;
      if (value is List) {
        for (final v in value) {
          final s = v?.toString().trim() ?? '';
          if (s.isNotEmpty && !candidates.contains(s)) candidates.add(s);
        }
        return;
      }
      final s = value.toString().trim();
      if (s.isNotEmpty && !candidates.contains(s)) candidates.add(s);
    }

    addValue(lesson['teacher']);
    addValue(lesson['teacherName']);
    addValue(lesson['teacherLongName']);
    addValue(lesson['teachers']);
    addValue(lesson['teName']);
    addValue(lesson['teLongName']);
    addValue(lesson['orgTeacher']);
    addValue(lesson['orgTeacherName']);
    addValue(lesson['substTeacher']);
    addValue(lesson['substTeacherName']);
    addValue(lesson['teacherText']);
    addValue(lesson['teacherDisplay']);

    return candidates.join(', ');
  }

  String _lessonTeacherKey(
    Map<dynamic, dynamic> lesson, {
    bool withRoom = true,
  }) {
    final date = lesson['date']?.toString() ?? '';
    final start = lesson['startTime']?.toString() ?? '';
    final end = lesson['endTime']?.toString() ?? '';
    final subId = (lesson['su'] as List?)?.firstOrNull?['id']?.toString() ?? '';
    final roomId = withRoom
        ? ((() {
            final r = lesson['ro'];
            final list = r is List
                ? r
                : r is Map
                ? [r]
                : <dynamic>[];
            return list.firstOrNull?['id']?.toString() ?? '';
          })())
        : '';
    return '$date|$start|$end|$subId|$roomId';
  }

  String _lessonTeacherKeyFromParts({
    required dynamic date,
    required dynamic startTime,
    required dynamic endTime,
    required dynamic subjectId,
    dynamic roomId,
    bool withRoom = true,
  }) {
    final d = date?.toString() ?? '';
    final s = startTime?.toString() ?? '';
    final e = endTime?.toString() ?? '';
    final sub = subjectId?.toString() ?? '';
    final room = withRoom ? (roomId?.toString() ?? '') : '';
    return '$d|$s|$e|$sub|$room';
  }

  Future<void> _loadMasterDataFromCache() async {
    if (_subjectShortMap.isNotEmpty &&
        _teacherMap.isNotEmpty &&
        _roomMap.isNotEmpty) {
      return;
    }
    try {
      final storeKey = OfflineCacheStore.instance.scopedKey(
        accountId: activeUntisAccountId ?? 'legacy',
        dataset: 'masterData',
        entityKey: '$schoolUrl|$schoolName',
      );
      final stored = await OfflineCacheStore.instance.read(storeKey);
      if (stored == null) return;
      final val = stored.value;
      if (val['subjectsLong'] is Map) {
        (val['subjectsLong'] as Map).forEach((k, v) {
          final id = int.tryParse(k.toString());
          if (id != null) _subjectLong[id] = v.toString();
        });
      }
      if (val['subjectsShort'] is Map) {
        (val['subjectsShort'] as Map).forEach((k, v) {
          final id = int.tryParse(k.toString());
          if (id != null) _subjectShortMap[id] = v.toString();
        });
      }
      if (val['teachers'] is Map) {
        (val['teachers'] as Map).forEach((k, v) {
          final id = int.tryParse(k.toString());
          if (id != null) _teacherMap[id] = v.toString();
        });
      }
      if (val['rooms'] is Map) {
        (val['rooms'] as Map).forEach((k, v) {
          final id = int.tryParse(k.toString());
          if (id != null) _roomMap[id] = v.toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveMasterDataToCache() async {
    try {
      final storeKey = OfflineCacheStore.instance.scopedKey(
        accountId: activeUntisAccountId ?? 'legacy',
        dataset: 'masterData',
        entityKey: '$schoolUrl|$schoolName',
      );
      final payload = {
        'subjectsLong': {
          for (final e in _subjectLong.entries) e.key.toString(): e.value,
        },
        'subjectsShort': {
          for (final e in _subjectShortMap.entries) e.key.toString(): e.value,
        },
        'teachers': {
          for (final e in _teacherMap.entries) e.key.toString(): e.value,
        },
        'rooms': {for (final e in _roomMap.entries) e.key.toString(): e.value},
      };
      await OfflineCacheStore.instance.write(storeKey, payload);
    } catch (_) {}
  }

  Future<void> _fetchMasterData({bool force = false}) async {
    if (!force &&
        _subjectShortMap.isNotEmpty &&
        _teacherMap.isNotEmpty &&
        _roomMap.isNotEmpty) {
      return;
    }
    await _loadMasterDataFromCache();
    if (!force &&
        _subjectShortMap.isNotEmpty &&
        _teacherMap.isNotEmpty &&
        _roomMap.isNotEmpty) {
      return;
    }
    if (_currentSessionId.isEmpty || schoolUrl.isEmpty) return;

    try {
      final data = await _timetableRepository.fetchMasterData(
        _timetableRequestContext,
      );
      for (final subject in data.subjects) {
        final id = subject['id'] as int?;
        if (id == null) continue;
        _subjectLong[id] =
            (subject['longName'] ??
                    subject['longname'] ??
                    subject['name'] ??
                    '')
                .toString();
        _subjectShortMap[id] = (subject['name'] ?? '').toString();
      }
      for (final teacher in data.teachers) {
        final id = teacher['id'] as int?;
        if (id == null) continue;
        final fore = (teacher['foreName'] ?? teacher['forename'] ?? '')
            .toString()
            .trim();
        final last = (teacher['longName'] ?? teacher['name'] ?? '')
            .toString()
            .trim();
        _teacherMap[id] = fore.isNotEmpty ? '$fore $last' : last;
      }
      for (final room in data.rooms) {
        final id = room['id'] as int?;
        if (id != null) _roomMap[id] = (room['name'] ?? '').toString();
      }
      unawaited(_saveMasterDataToCache());
    } catch (_) {}
  }

  DateTime _currentMonday = resolveDefaultTimetableMonday(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: resolveInitialTimetableDayIndex(DateTime.now()),
    )..addListener(_onSelectedDayChanged);
    _cacheRefreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (defaultClassId != null) {
      _viewingClassId = defaultClassId;
      _viewingClassName = defaultClassName;
    }
    hiddenSubjectsNotifier.addListener(_onHiddenSubjectsChanged);
    subjectColorsNotifier.addListener(_onHiddenSubjectsChanged);
    subjectPresentationsNotifier.addListener(_onHiddenSubjectsChanged);
    monochromeLessonsNotifier.addListener(_onHiddenSubjectsChanged);
    monochromeLessonColorNotifier.addListener(_onHiddenSubjectsChanged);
    showCancelledNotifier.addListener(_onHiddenSubjectsChanged);
    timetableSwitchAnimationNotifier.addListener(
      _onTimetableSwitchAnimationChanged,
    );
    demoModeNotifier.addListener(_onDemoModeChanged);
    pendingTimetableActionNotifier.addListener(_onPendingTimetableAction);
    lessonCardStyleNotifier.addListener(_onHiddenSubjectsChanged);
    glowEffectsEnabledNotifier.addListener(_onHiddenSubjectsChanged);
    lessonBlurEnabledNotifier.addListener(_onHiddenSubjectsChanged);
    lessonBlurAmountNotifier.addListener(_onHiddenSubjectsChanged);
    lessonCardOpacityNotifier.addListener(_onHiddenSubjectsChanged);
    lessonBorderRadiusNotifier.addListener(_onHiddenSubjectsChanged);
    lessonAccentStyleNotifier.addListener(_onHiddenSubjectsChanged);
    lessonShowTeacherNotifier.addListener(_onHiddenSubjectsChanged);
    lessonFullTeacherNamesNotifier.addListener(_onHiddenSubjectsChanged);
    showFullTeacherNamesNotifier.addListener(_onTeacherNameModeChanged);
    timetableDaySpanNotifier.addListener(_onHiddenSubjectsChanged);
    lessonShowRoomNotifier.addListener(_onHiddenSubjectsChanged);
    lessonCompactModeNotifier.addListener(_onHiddenSubjectsChanged);
    lessonDimPastNotifier.addListener(_onHiddenSubjectsChanged);
    final hasActiveAccount =
        (activeUntisAccountId != null &&
            untisAccountsNotifier.value.any(
              (account) =>
                  account.id == activeUntisAccountId &&
                  (account.sessionId.isNotEmpty || account.password.isNotEmpty),
            )) ||
        sessionID.isNotEmpty;
    if (hasActiveAccount || demoModeNotifier.value) {
      _fetchFullWeek();
    }
    unawaited(_loadStoredTeacherChanges());
    _loadViewPref();
    _loadAlarmConfig();

    // Start foreground timer to keep the progressive notification fresh.
    // It reads from the offline cache (works without network) and updates
    // the ongoing "current lesson" notification every minute while the app
    // is open, preventing the notification from drifting hours behind.
    if (!kIsWeb) {
      _progressiveNotificationTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => unawaited(refreshProgressiveNotificationFromCache()),
      );
    }
  }

  Future<void> _loadAlarmConfig() async {
    final config = await AlarmService.instance.loadConfig();
    if (mounted) setState(() => _alarmConfig = config);
  }

  Future<void> _saveDateAlarmOverride(
    DateTime date,
    AlarmDateOverride? override,
  ) async {
    await AlarmService.instance.saveDateOverride(alarmDateKey(date), override);
    await _loadAlarmConfig();
    // Prefer a fresh current-day response. When offline, saveDateOverride has
    // already adjusted the durable next plan if it is the selected day.
    if (_alarmConfig.smartEnabled) {
      updateUntisData().catchError((_) => false);
    }
  }

  Future<void> _showDateAlarmActions(DateTime date) async {
    final l = appL10nFor(appLocaleNotifier.value);
    final key = alarmDateKey(date);
    final current =
        _alarmConfig.dateOverrides[key] ?? const AlarmDateOverride();
    final dateLabel = DateFormat(
      'EEEE, d. MMMM',
      _icuLocale(appLocaleNotifier.value),
    ).format(date);
    await showUntisModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.alarmDateActions(dateLabel),
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.alarmDateActionsDesc,
                style: GoogleFonts.outfit(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                value: current.disabled,
                secondary: Icon(
                  current.disabled
                      ? Icons.alarm_off_rounded
                      : Icons.alarm_rounded,
                ),
                title: Text(l.alarmDisableDate),
                onChanged: (disabled) async {
                  await _saveDateAlarmOverride(
                    date,
                    current.copyWith(disabled: disabled),
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: Text(l.alarmCustomTime),
                subtitle: current.customTimeOfDayMinutes == null
                    ? null
                    : Text(
                        TimeOfDay(
                          hour: current.customTimeOfDayMinutes! ~/ 60,
                          minute: current.customTimeOfDayMinutes! % 60,
                        ).format(sheetContext),
                      ),
                onTap: () async {
                  final initial = TimeOfDay(
                    hour: current.customTimeOfDayMinutes == null
                        ? 7
                        : current.customTimeOfDayMinutes! ~/ 60,
                    minute: current.customTimeOfDayMinutes == null
                        ? 0
                        : current.customTimeOfDayMinutes! % 60,
                  );
                  final chosen = await showTimePicker(
                    context: sheetContext,
                    initialTime: initial,
                  );
                  if (chosen == null) return;
                  await _saveDateAlarmOverride(
                    date,
                    current.copyWith(
                      disabled: false,
                      customTimeOfDayMinutes: chosen.hour * 60 + chosen.minute,
                    ),
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.fast_forward_rounded),
                title: Text(l.alarmEarlier),
                subtitle: Text(
                  l.alarmEarlierValue(_alarmConfig.nextAlarmEarlierMinutes),
                ),
                onTap: () async {
                  await _saveDateAlarmOverride(
                    date,
                    current.copyWith(
                      disabled: false,
                      earlierMinutes: _alarmConfig.nextAlarmEarlierMinutes,
                    ),
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              if (!current.isEmpty)
                TextButton.icon(
                  onPressed: () async {
                    await _saveDateAlarmOverride(date, null);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(l.alarmClearDate),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPendingTimetableAction() {
    if (!mounted) return;
    final action = pendingTimetableActionNotifier.value;
    if (action == null || action.isEmpty) return;

    final l = appL10nFor(appLocaleNotifier.value);
    final current = (pendingTimetableCurrentLessonNotifier.value ?? '').trim();
    final next = (pendingTimetableNextLessonNotifier.value ?? '').trim();

    pendingTimetableActionNotifier.value = null;

    if (action == 'open_free_rooms') {
      _showFreeRoomsDialog();
      return;
    }

    if (action == 'open_next_lesson') {
      final text = next.isNotEmpty
          ? l.notificationActionNextLesson
          : l.notificationActionNoNextLesson;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (action == 'open_change') {
      _handlePendingChangeHighlight();
      return;
    }

    if (current.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.notificationActionCurrentLesson(current)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handlePendingChangeHighlight() {
    final date = pendingChangeHighlightDateNotifier.value;
    final startTime = pendingChangeHighlightStartTimeNotifier.value;
    pendingChangeHighlightDateNotifier.value = null;
    pendingChangeHighlightStartTimeNotifier.value = null;
    final target = parseUntisDate(date);
    if (date == null || target == null) return;

    final monday = DateTime(
      _currentMonday.year,
      _currentMonday.month,
      _currentMonday.day,
    );
    final delta = target.difference(monday).inDays;
    if (delta < -2 || delta > 6) {
      context.showUntisSnackBar(
        appL10nFor(appLocaleNotifier.value).notificationChangeOutsideWeek,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
      _highlightDate = date;
      _highlightStartTime = startTime;
    });
    _highlightController
      ?..reset()
      ..forward();
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 3600), () {
      if (!mounted) return;
      setState(() {
        _highlightDate = null;
        _highlightStartTime = null;
      });
    });

    if (delta >= 0 && delta <= 4) {
      _animateDayTabTo(delta);
    } else if (delta < 0) {
      _commitMaterialDayIndex(0);
    } else {
      _commitMaterialDayIndex(6);
    }
  }

  bool _isHighlightMatch(Map<dynamic, dynamic> lesson) =>
      _highlightDate != null &&
      normalizeUntisDateInt(lesson['date']) == _highlightDate &&
      (lesson['startTime'] as num?)?.toInt() == _highlightStartTime;

  Widget _withChangeHighlight({
    required Widget child,
    required bool highlighted,
    required Color color,
  }) {
    final controller = _highlightController;
    if (!highlighted || controller == null) return child;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final glow = math.sin(t * math.pi) * (1 - t) * 0.75;
        if (glow <= 0.02) return child!;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: glow),
                blurRadius: 26,
                spreadRadius: 6,
              ),
            ],
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  Future<void> _loadViewPref() async {
    final prefs = SettingsStore.instance.preferences;
    if (mounted) {
      final savedMode = prefs.getInt('timetableViewModeV2');
      final legacyMode = prefs.getInt('viewMode') ?? 0;
      setState(() {
        _viewMode = (savedMode ?? (legacyMode == 1 ? 2 : 0)).clamp(0, 2);
      });
    }
  }

  bool _isNoAllowedDateError(String message) {
    final m = message.toLowerCase();
    return m.contains('no allowed date') ||
        m.contains('no allowed dates') ||
        m.contains('nicht erlaubtes datum') ||
        m.contains('not within a school year') ||
        m.contains('nicht in einem schuljahr');
  }

  Future<void> _toggleView() async {
    if (_isDayCarouselAnimating ||
        _isWeekCarouselAnimating ||
        _tabController.indexIsChanging) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _viewMode = (_viewMode + 1) % 3);
    final prefs = SettingsStore.instance.preferences;
    await prefs.setInt('timetableViewModeV2', _viewMode);
  }

  Future<void> _fetchHomeworkAndNotes() async {
    if (!demoModeNotifier.value &&
        (_currentSessionId.isEmpty || schoolUrl.isEmpty)) {
      return;
    }
    try {
      final requestAccountId = activeUntisAccountId;
      final account = activeUntisAccount;
      final requestStart = _currentMonday;
      final requestEnd = _currentMonday.add(const Duration(days: 6));
      final requestSchoolUrl = account?.schoolUrl ?? schoolUrl;
      final requestSchoolName = account?.schoolName ?? schoolName;
      final requestSessionId = _currentSessionId;
      final requestPersonId = account?.personId ?? personId;
      final requestPersonType = account?.personType ?? personType;
      if (!demoModeNotifier.value && requestAccountId != null) {
        final cached = await HomeworkService.loadCachedHomeworkAndNotes(
          accountId: requestAccountId,
          startDate: requestStart,
          endDate: requestEnd,
        );
        if (requestAccountId != activeUntisAccountId ||
            _currentMonday != requestStart) {
          return;
        }
        if (cached != null) {
          homeworksNotifier.value = cached['homeworks']!;
          lessonNotesNotifier.value = cached['lessonNotes']!;
        }
      }
      final res = demoModeNotifier.value
          ? DemoModeService.buildHomeworkAndNotes(
              requestStart,
              locale: appLocaleNotifier.value,
            )
          : await HomeworkService.fetchHomeworkAndNotes(
              schoolUrl: requestSchoolUrl,
              schoolName: requestSchoolName,
              sessionId: requestSessionId,
              personId: requestPersonId,
              personType: requestPersonType,
              accountId: requestAccountId,
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
              startDate: requestStart,
              endDate: requestEnd,
            );
      if (requestAccountId != activeUntisAccountId ||
          _currentMonday != requestStart) {
        return;
      }
      homeworksNotifier.value = res['homeworks']!;
      lessonNotesNotifier.value = res['lessonNotes']!;
      if (!demoModeNotifier.value && requestAccountId != null) {
        final wrapped = SchoolWrappedRepository();
        for (final year in await wrapped.years(requestAccountId)) {
          if (year.contains(requestStart)) {
            await wrapped.recordHomework(
              accountId: requestAccountId,
              year: year,
              items: res['homeworks']!,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching homework and notes: $e');
    }
  }

  void _onLessonTap(BuildContext context, Map<dynamic, dynamic> lesson) {
    _showLessonDetail(
      context,
      lesson,
      originalTeacher: _originalTeachers[_lessonIdentityOf(lesson)] ?? '',
    );
  }

  Future<void> _onRefresh() => _fetchFullWeek(silent: true);

  String _temporaryLessonKey(Map<dynamic, dynamic> lesson) =>
      '${lesson['id'] ?? lesson['lsid'] ?? ''}-${lesson['date'] ?? ''}-${lesson['startTime'] ?? ''}';

  void _replaceTemporaryLesson(
    Map<dynamic, dynamic> previous,
    Map<dynamic, dynamic> replacement,
  ) {
    final key = _temporaryLessonKey(previous);
    for (final lessons in _weekData.values) {
      final index = lessons.indexWhere(
        (item) =>
            identical(item, previous) ||
            (item is Map && _temporaryLessonKey(item) == key),
      );
      if (index >= 0) lessons[index] = replacement;
    }
    currentWeekDataNotifier.value = Map<int, List<dynamic>>.from(_weekData);
  }

  Future<void> _editLessonTemporarily(Map<dynamic, dynamic> lesson) async {
    final l = appL10nFor(appLocaleNotifier.value);
    final lessonKey = _temporaryLessonKey(lesson);
    _temporaryLessonOriginals.putIfAbsent(
      lessonKey,
      () => Map<dynamic, dynamic>.from(lesson),
    );
    final subject = TextEditingController(
      text: lesson['_subjectShort']?.toString() ?? '',
    );
    final teacher = TextEditingController(
      text: lesson['_teacher']?.toString() ?? '',
    );
    final room = TextEditingController(text: lesson['_room']?.toString() ?? '');
    var cancelled = isTimetableCancelled(lesson);
    await showUntisDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l.tempEditTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.tempEditDesc),
                const SizedBox(height: 12),
                TextField(
                  controller: subject,
                  decoration: InputDecoration(labelText: l.subject),
                ),
                TextField(
                  controller: teacher,
                  decoration: InputDecoration(labelText: l.teacher),
                ),
                TextField(
                  controller: room,
                  decoration: InputDecoration(labelText: l.room),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.absence),
                  value: cancelled,
                  onChanged: (value) => setDialogState(() => cancelled = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final original = _temporaryLessonOriginals.remove(lessonKey);
                if (original != null && mounted) {
                  setState(
                    () => _replaceTemporaryLesson(
                      lesson,
                      Map<dynamic, dynamic>.from(original),
                    ),
                  );
                }
                Navigator.pop(dialogContext);
              },
              child: Text(l.reset),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (!mounted) return;
                final updated = Map<dynamic, dynamic>.from(lesson);
                updated['_subjectShort'] = subject.text.trim();
                updated['_subjectLong'] = subject.text.trim();
                updated['_teacher'] = teacher.text.trim();
                updated['_room'] = room.text.trim();
                if (cancelled) {
                  updated['code'] = 'cancelled';
                } else if (isTimetableCancelled(updated)) {
                  updated.remove('code');
                }
                setState(() {
                  _replaceTemporaryLesson(lesson, updated);
                });
                Navigator.pop(dialogContext);
              },
              child: Text(l.localSave),
            ),
          ],
        ),
      ),
    );
    subject.dispose();
    teacher.dispose();
    room.dispose();
  }

  Future<void> _exportTimetableImage() async {
    final l = appL10nFor(appLocaleNotifier.value);
    try {
      // The on-screen timetable reserves space for the transparent app bar.
      // Temporarily remove that viewport-only padding from the repaint boundary
      // so the saved image starts with the actual timetable content.
      final pixelRatio = MediaQuery.of(
        context,
      ).devicePixelRatio.clamp(1.0, 3.0).toDouble();
      setState(() => _isExportingTimetable = true);
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _timetableExportKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      if (mounted) setState(() => _isExportingTimetable = false);
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) return;
      final result = await FilePicker.saveFile(
        dialogTitle: l.saveTimetableImage,
        fileName:
            'untisplus-${DateFormat('yyyy-MM-dd').format(_currentMonday)}.png',
        bytes: data.buffer.asUint8List(),
      );
      if (result != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.timetableImageSaved)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.imageExportFailed)));
      }
    } finally {
      if (mounted && _isExportingTimetable) {
        setState(() => _isExportingTimetable = false);
      }
    }
  }

  Future<void> _updateHomeWidgets(Map<int, List<dynamic>> week) async {
    if (kIsWeb) return;
    final l = appL10nFor(appLocaleNotifier.value);
    final now = DateTime.now();
    final todayLessons =
        List<dynamic>.from(week[now.weekday - 1] ?? [])
            .whereType<Map>()
            .where(
              (lesson) =>
                  !_isLessonSubjectHidden(lesson) &&
                  (showCancelledNotifier.value ||
                      !isTimetableCancelled(lesson)),
            )
            .toList(growable: false)
          ..sort(
            (a, b) => _toMinutes(
              (a['startTime'] as int?) ?? 0,
            ).compareTo(_toMinutes((b['startTime'] as int?) ?? 0)),
          );
    String label(dynamic lesson) {
      final subject = lesson['_subjectShort']?.toString();
      return subject?.isNotEmpty == true ? subject! : l.widgetLesson;
    }

    final nowMinutes = now.hour * 60 + now.minute;
    dynamic current;
    for (final lesson in todayLessons) {
      final start = _toMinutes((lesson['startTime'] as int?) ?? 0);
      final end = _toMinutes((lesson['endTime'] as int?) ?? 0);
      if (start <= nowMinutes && nowMinutes < end) {
        current = lesson;
      }
    }
    final schedule = todayLessons
        .take(7)
        .map((lesson) {
          final time = _formatUntisTime(lesson['startTime']?.toString() ?? '');
          return '$time · ${label(lesson)}';
        })
        .join('\n');
    final remaining = current == null
        ? ''
        : l.widgetMinutesRemaining(
            (_toMinutes((current['endTime'] as int?) ?? 0) - nowMinutes).clamp(
              0,
              999,
            ),
          );
    final homework = homeworksNotifier.value
        .where((item) => !_isLessonSubjectHidden(item))
        .where((item) => item['isDone'] != true)
        .take(3)
        .map((item) {
          final subject =
              item['subject'] ?? item['_lesson']?['_subjectShort'] ?? '';
          final text =
              item['text'] ??
              item['homework'] ??
              item['description'] ??
              l.widgetHomeworkItem;
          return '${subject.toString().isEmpty ? '' : '$subject · '}${text.toString()}';
        })
        .join('\n');
    var examSummary = l.widgetNoUpcomingExams;
    try {
      final prefs = SettingsStore.instance.preferences;
      final exams = (prefs.getStringList(_accountDataKey('customExams')) ?? [])
          .map((raw) {
            try {
              return jsonDecode(raw) as Map<String, dynamic>;
            } catch (_) {
              return <String, dynamic>{};
            }
          })
          .where((exam) => exam.isNotEmpty)
          .where(
            (exam) => !_isSubjectHidden(exam['subject'] ?? exam['subjectName']),
          )
          .take(2)
          .map((exam) {
            final subject =
                exam['subject'] ?? exam['subjectName'] ?? l.widgetExam;
            final date = parseUntisDate(exam['date'] ?? exam['examDate']);
            final formatted = date == null
                ? ''
                : DateFormat('dd.MM.').format(date);
            return formatted.isEmpty
                ? subject.toString()
                : '$formatted $subject';
          })
          .toList(growable: false);
      if (exams.isNotEmpty) examSummary = exams.join('\n');
    } catch (_) {}
    try {
      UntisAccount? activeAccount;
      for (final account in untisAccountsNotifier.value) {
        if (account.id == activeUntisAccountId) {
          activeAccount = account;
          break;
        }
      }
      await WidgetService.updateWidgets(
        // A homescreen widget is a "now" surface. Empty values intentionally
        // render as a neutral shell instead of inventing a Freistunde or
        // advertising a lesson that is not currently taking place.
        currentLesson: current == null ? '' : label(current),
        nextLesson: '',
        timeRemaining: remaining,
        dailySchedule: schedule,
        homeworkSummary: homework.isEmpty ? l.widgetNoOpenHomework : homework,
        notificationSummary: l.widgetOpenNotifications,
        examSummary: examSummary,
        accountId: activeUntisAccountId ?? 'active',
        accountLabel: activeAccount?.label ?? schoolName,
        status: DateFormat('HH:mm').format(now),
        locale: appLocaleNotifier.value,
      );
    } catch (_) {
      // A widget update must never block timetable rendering.
    }
  }

  void _onHiddenSubjectsChanged() => setState(() {});

  void _replaceMaterialDayCarouselController(int initialItem) {
    final previous = _materialDayCarouselController;
    _materialDayIndex = initialItem;
    _materialDayCarouselController = CarouselController(
      initialItem: initialItem,
    );
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  void _replaceMaterialWeekCarouselController() {
    final previous = _materialWeekCarouselController;
    _materialWeekIndex = 1;
    _materialWeekCarouselController = CarouselController(initialItem: 1);
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  void _onTimetableSwitchAnimationChanged() {
    if (!mounted) return;
    _carouselAnimController?.stop();
    _dayCarouselAnimController?.stop();
    _replaceMaterialDayCarouselController(_tabController.index + 1);
    _replaceMaterialWeekCarouselController();
    setState(() {
      _carouselOffset = 0;
      _dayCarouselOffset = 0;
      _dayCarouselTargetDay = null;
      _dayCarouselAnimation = null;
      _isWeekCarouselAnimating = false;
      _isDayCarouselAnimating = false;
    });
    unawaited(_prefetchAdjacentWeeks());
  }

  void _onSelectedDayChanged() {
    // A TabBar tap calls TabController.animateTo before its onTap callback.
    // Ignore that temporary controller state: the day carousel owns the
    // visual transition and commits the selected day only when it is finished.
    if (!mounted ||
        _isDayCarouselAnimating ||
        _suppressDayTabControllerRebuild ||
        _tabController.indexIsChanging) {
      return;
    }
    setState(() {});
  }

  void _onDemoModeChanged() {
    if (!mounted) return;
    if (demoModeNotifier.value) {
      _viewingClassId = null;
      _viewingClassName = null;
      _tempSessionId = null;
    }
    _fetchFullWeek();
  }

  // --- Week carousel ---

  DateTime _weekMondayFromDelta(int delta) =>
      _currentMonday.add(Duration(days: 7 * delta));

  Map<int, List<dynamic>>? _getAdjacentWeekData(DateTime monday) {
    return _adjacentWeekCache[_mondayKey(monday)];
  }

  /// Makes adjacent weeks available before the user reaches them. When the
  /// current week came from local storage, [allowNetwork] stays false so an
  /// offline swipe can still reveal the already cached cancellation state
  /// immediately instead of waiting for a new request to finish.
  void _notifyAdjacentWeekCacheChanged() {
    if (!mounted || _adjacentWeekRefreshScheduled) return;
    _adjacentWeekRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adjacentWeekRefreshScheduled = false;
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _prefetchAdjacentWeeks({
    bool allowNetwork = true,
    bool refreshFromDisk = false,
  }) async {
    if (demoModeNotifier.value) {
      for (final delta in [-1, 1, 2]) {
        final monday = _weekMondayFromDelta(delta);
        _adjacentWeekCache[_mondayKey(monday)] = DemoModeService.buildWeek(
          monday,
          locale: appLocaleNotifier.value,
        );
      }
      _notifyAdjacentWeekCacheChanged();
      return;
    }

    final pid = _viewingClassId ?? personId;
    final pType = _viewingClassId != null ? 1 : personType;
    if (pid == 0) return;

    // Disk first: the background updater can refresh an upcoming week while
    // this page is still alive. Reconcile that durable cache before a swipe so
    // cancellations/room changes are visible during the gesture, not only
    // after the new week has been committed or the app has been restarted.
    for (final delta in [-1, 1, 2]) {
      final adjMonday = _weekMondayFromDelta(delta);
      final key = _mondayKey(adjMonday);
      if (!refreshFromDisk && _adjacentWeekCache.containsKey(key)) continue;

      final cached = await _loadWeekFromCache(
        requestPersonId: pid,
        requestPersonType: pType,
        monday: adjMonday,
      );
      if (cached != null && cached.values.any((l) => l.isNotEmpty)) {
        _adjacentWeekCache[key] = cached;
        _notifyAdjacentWeekCacheChanged();
      }
    }

    if (!allowNetwork) return;

    await _fetchMasterData();
    for (final delta in [-1, 1, 2]) {
      final adjMonday = _weekMondayFromDelta(delta);
      final key = _mondayKey(adjMonday);
      if (_adjacentWeekCache.containsKey(key)) continue;
      try {
        final friday = adjMonday.add(const Duration(days: 4));
        final lessons = await _timetableRepository.fetchTimetable(
          context: _timetableRequestContext,
          elementId: pid,
          elementType: pType,
          startDate: adjMonday,
          endDate: friday,
          requestId: 'week_prefetch',
        );
        final tempWeek = _parseWeekResult(lessons);
        if (tempWeek != null) {
          _adjacentWeekCache[key] = tempWeek;
          await _saveWeekToCache(
            requestPersonId: pid,
            requestPersonType: pType,
            weekData: tempWeek,
            monday: adjMonday,
          );
          _notifyAdjacentWeekCacheChanged();
        }
      } catch (_) {}
    }
  }

  Map<int, List<dynamic>>? _parseWeekResult(dynamic result) {
    if (result is! List) return null;
    final week = _emptyWeekData();
    for (final entry in result) {
      if (entry is! Map) continue;
      final day = entry['date'];
      if (day is! int) continue;
      final date = parseUntisDateInt(day);
      if (date == null) continue;
      final dayIndex = date.weekday - 1;
      if (dayIndex < 0 || dayIndex > 4) continue;
      final lessonMap = Map<String, dynamic>.from(
        entry.cast<String, dynamic>(),
      );
      _enrichLesson(lessonMap);
      week[dayIndex] = [...week[dayIndex]!, lessonMap];
    }
    for (final i in week.keys) {
      week[i]!.sort((a, b) {
        final aStart = (a['startTime'] as int?) ?? 0;
        final bStart = (b['startTime'] as int?) ?? 0;
        return aStart.compareTo(bStart);
      });
    }
    return week;
  }

  void _enrichLesson(Map<String, dynamic> lesson) {
    final teList = (lesson['te'] as List?) ?? [];
    if (teList.isNotEmpty) {
      final firstTeacher = teList.first as Map?;
      if (firstTeacher != null) {
        final tId = firstTeacher['id'] as int?;
        final rawShort = firstTeacher['name']?.toString().trim() ?? '';
        final rawFull = firstTeacher['longName']?.toString().trim() ?? '';
        final mappedFull = tId == null ? '' : _teacherMap[tId]?.trim() ?? '';
        final previousShort = lesson['_teacherShort']?.toString().trim() ?? '';
        final previousFull = lesson['_teacherFull']?.toString().trim() ?? '';
        final short = rawShort.isNotEmpty
            ? rawShort
            : previousShort.isNotEmpty
            ? previousShort
            : '?';
        final full = mappedFull.isNotEmpty
            ? mappedFull
            : rawFull.isNotEmpty
            ? rawFull
            : previousFull.isNotEmpty
            ? previousFull
            : short;
        lesson['_teacherShort'] = short;
        lesson['_teacherFull'] = full;
        lesson['_teacher'] = showFullTeacherNamesNotifier.value ? full : short;
      }
    }
    final suList = (lesson['su'] as List?) ?? [];
    if (suList.isNotEmpty) {
      final firstSubject = suList.first as Map?;
      if (firstSubject != null) {
        final sId = firstSubject['id'] as int?;
        lesson['_subjectShort'] = sId != null
            ? (_subjectShortMap[sId] ??
                  (firstSubject['name']?.toString() ?? '?'))
            : '?';
        lesson['_subjectLong'] = sId != null
            ? (_subjectLong[sId] ??
                  (firstSubject['longName']?.toString() ??
                      firstSubject['name']?.toString() ??
                      '?'))
            : '?';
      }
    }
    final rawRo = lesson['ro'];
    final roList = rawRo is List
        ? rawRo
        : rawRo is Map
        ? [rawRo]
        : <dynamic>[];
    if (roList.isNotEmpty) {
      final names = roList
          .map((ro) {
            final rId = (ro as Map)['id'] as int?;
            return rId != null
                ? (_roomMap[rId] ?? (ro['name']?.toString() ?? '?'))
                : (ro['name']?.toString() ?? '?');
          })
          .where((name) => name != '?')
          .toSet()
          .toList();
      lesson['_room'] = names.isNotEmpty ? names.join(', ') : '?';
    }
  }

  void _onTeacherNameModeChanged() {
    for (final week in [_weekData, ..._adjacentWeekCache.values]) {
      for (final lessons in week.values) {
        for (final lesson in lessons) {
          if (lesson is Map<String, dynamic>) _enrichLesson(lesson);
        }
      }
    }
    currentWeekDataNotifier.value = Map<int, List<dynamic>>.from(_weekData);
    if (mounted) setState(() {});
  }

  Widget _buildAdjacentWeekView(int direction) {
    final adjMonday = _weekMondayFromDelta(direction);
    final cached = _getAdjacentWeekData(adjMonday);
    if (cached != null) {
      if (!_isDailyView) {
        return _buildWeekView(
          monday: adjMonday,
          weekData: cached,
          visibleDays: _visibleGridDays,
        );
      } else {
        final dayIndex = direction > 0 ? 0 : 4;
        return _buildDayContentView(
          dayIndex,
          monday: adjMonday,
          weekData: cached,
        );
      }
    }
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 8),
          Text(
            '${l.timetableTitle} …',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // --- Timetable switch animation styles ---

  Widget _buildTimetableSwitcher() {
    switch (timetableSwitchAnimationNotifier.value) {
      case 1:
        return _buildMaterialCarouselSwitcher();
      case 2:
        return _buildDepthCarouselSwitcher();
      case 0:
      default:
        // Keep the original switcher as the exact default behavior.
        return _buildWeekCarousel();
    }
  }

  Widget _buildMaterialCarouselSwitcher() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return _isDailyView
            ? _buildMaterialDayCarousel(width)
            : _buildMaterialWeekCarousel(width);
      },
    );
  }

  Widget _materialCarouselItem({
    required Widget child,
    required String keyName,
  }) {
    return KeyedSubtree(
      key: ValueKey(keyName),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 120) return child;

          // CarouselView compresses neighbouring items down to its
          // shrinkExtent. The timetable still needs a regular viewport for
          // layout; clip that viewport to create the narrow visual preview.
          return ClipRect(
            child: OverflowBox(
              minWidth: 320,
              maxWidth: 320,
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterialWeekCarousel(double width) {
    final controller = _materialWeekCarouselController ??= CarouselController(
      initialItem: 1,
    );
    // Keep a visible neighbour and let edge items collapse substantially.
    // This makes the official Material 3 uncontained carousel feel distinct
    // from a regular page swipe while retaining the timetable's full gesture
    // and index semantics.
    final itemExtent = width <= 0 ? 1.0 : math.max(1.0, width * 0.88);
    final shrinkExtent = math.max(56.0, itemExtent * 0.16);

    final children = <Widget>[
      _materialCarouselItem(
        keyName: 'm3-week-prev-${_mondayKey(_currentMonday)}',
        child: _buildAdjacentWeekView(-1),
      ),
      _materialCarouselItem(
        keyName: 'm3-week-current-${_mondayKey(_currentMonday)}',
        child: _buildWeekView(),
      ),
      _materialCarouselItem(
        keyName: 'm3-week-next-${_mondayKey(_currentMonday)}',
        child: _buildAdjacentWeekView(1),
      ),
    ];

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth != 0 ||
            notification.metrics.axis != Axis.horizontal) {
          return false;
        }
        if (notification is ScrollStartNotification) {
          unawaited(
            _prefetchAdjacentWeeks(allowNetwork: false, refreshFromDisk: true),
          );
          return false;
        }
        if (notification is! ScrollEndNotification) return false;
        final index = controller.hasClients
            ? controller.leadingItem.clamp(0, 2).toInt()
            : _materialWeekIndex;
        _materialWeekIndex = index;
        _commitMaterialWeekIndex(index);
        return false;
      },
      child: CarouselView(
        key: const ValueKey('material-week-timetable-carousel'),
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemExtent: itemExtent,
        shrinkExtent: shrinkExtent,
        itemSnapping: true,
        enableSplash: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        itemClipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        onIndexChanged: (index) => _materialWeekIndex = index,
        children: children,
      ),
    );
  }

  Widget _buildMaterialDayCarousel(double width) {
    final currentDay = _tabController.index.clamp(0, 4).toInt();
    final controller = _materialDayCarouselController ??= CarouselController(
      initialItem: currentDay + 1,
    );
    if (_materialDayIndex < 0 || _materialDayIndex > 6) {
      _materialDayIndex = currentDay + 1;
    }

    Widget dayForItem(int item) {
      if (item == 0) {
        final monday = _weekMondayFromDelta(-1);
        final cached = _getAdjacentWeekData(monday);
        if (cached != null) {
          return _buildDayContentView(4, monday: monday, weekData: cached);
        }
        return _buildAdjacentWeekView(-1);
      }
      if (item == 6) {
        final monday = _weekMondayFromDelta(1);
        final cached = _getAdjacentWeekData(monday);
        if (cached != null) {
          return _buildDayContentView(0, monday: monday, weekData: cached);
        }
        return _buildAdjacentWeekView(1);
      }
      return _buildDayContentView(item - 1);
    }

    // Keep a visible neighbour and let edge items collapse substantially.
    // This makes the official Material 3 uncontained carousel feel distinct
    // from a regular page swipe while retaining the timetable's full gesture
    // and index semantics.
    final itemExtent = width <= 0 ? 1.0 : math.max(1.0, width * 0.88);
    final shrinkExtent = math.max(56.0, itemExtent * 0.16);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth != 0 ||
            notification.metrics.axis != Axis.horizontal) {
          return false;
        }
        if (notification is ScrollStartNotification) {
          unawaited(
            _prefetchAdjacentWeeks(allowNetwork: false, refreshFromDisk: true),
          );
          return false;
        }
        if (notification is! ScrollEndNotification) return false;
        final index = controller.hasClients
            ? controller.leadingItem.clamp(0, 6).toInt()
            : _materialDayIndex;
        _materialDayIndex = index;
        _commitMaterialDayIndex(index);
        return false;
      },
      child: CarouselView(
        key: const ValueKey('day-timetable-carousel'),
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemExtent: itemExtent,
        shrinkExtent: shrinkExtent,
        itemSnapping: true,
        enableSplash: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        itemClipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        onIndexChanged: (index) => _materialDayIndex = index,
        children: List<Widget>.generate(
          7,
          (index) => _materialCarouselItem(
            keyName: 'm3-day-${_mondayKey(_currentMonday)}-$index',
            child: dayForItem(index),
          ),
        ),
      ),
    );
  }

  void _commitMaterialDayIndex(int index) {
    if (!mounted || timetableSwitchAnimationNotifier.value != 1) return;
    final normalized = index.clamp(0, 6).toInt();
    final currentItem = _tabController.index + 1;
    if (normalized == currentItem) return;

    if (normalized >= 1 && normalized <= 5) {
      final targetDay = normalized - 1;
      _suppressDayTabControllerRebuild = true;
      try {
        _tabController.animateTo(targetDay, duration: Duration.zero);
      } finally {
        _suppressDayTabControllerRebuild = false;
      }
      _materialDayIndex = normalized;
      setState(() {});
      HapticFeedback.selectionClick();
      return;
    }

    final weekDelta = normalized == 0 ? -1 : 1;
    final newMonday = _currentMonday.add(Duration(days: weekDelta * 7));
    final cached = _adjacentWeekCache[_mondayKey(newMonday)];
    final targetDay = normalized == 0 ? 4 : 0;
    setState(() {
      _currentMonday = newMonday;
      if (cached != null) {
        _weekData = cached;
        _showingCachedWeek = true;
        _loading = false;
      }
    });
    _suppressDayTabControllerRebuild = true;
    try {
      _tabController.animateTo(targetDay, duration: Duration.zero);
    } finally {
      _suppressDayTabControllerRebuild = false;
    }
    _replaceMaterialDayCarouselController(targetDay + 1);
    _replaceMaterialWeekCarouselController();
    HapticFeedback.selectionClick();
    unawaited(_fetchFullWeek());
    unawaited(_prefetchAdjacentWeeks());
  }

  void _commitMaterialWeekIndex(int index) {
    if (!mounted || timetableSwitchAnimationNotifier.value != 1) return;
    final normalized = index.clamp(0, 2).toInt();
    if (normalized == 1) return;

    final weekDelta = normalized == 0 ? -1 : 1;
    final newMonday = _currentMonday.add(Duration(days: weekDelta * 7));
    final cached = _adjacentWeekCache[_mondayKey(newMonday)];
    final targetDay = normalized == 0 ? 4 : 0;
    setState(() {
      _currentMonday = newMonday;
      if (cached != null) {
        _weekData = cached;
        _showingCachedWeek = true;
        _loading = false;
      }
    });
    _suppressDayTabControllerRebuild = true;
    try {
      _tabController.animateTo(targetDay, duration: Duration.zero);
    } finally {
      _suppressDayTabControllerRebuild = false;
    }
    _replaceMaterialWeekCarouselController();
    _replaceMaterialDayCarouselController(targetDay + 1);
    HapticFeedback.selectionClick();
    unawaited(_fetchFullWeek());
    unawaited(_prefetchAdjacentWeeks());
  }

  Widget _buildDepthCarouselSwitcher() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!_isDailyView) {
          return _buildDepthWeekCarousel(width);
        }
        return _buildDepthDayCarousel(width);
      },
    );
  }

  Widget _depthPage({
    required Widget child,
    required double x,
    required double scale,
    required double opacity,
  }) {
    return Transform.translate(
      offset: Offset(x, 0),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Widget _buildDepthWeekCarousel(double width) {
    final offset = _carouselOffset.clamp(-width, width).toDouble();
    final progress = width <= 0 ? 0.0 : (offset.abs() / width).clamp(0.0, 1.0);

    final carousel = ClipRect(
      child: Stack(
        children: [
          if (offset > 0)
            _depthPage(
              x: -width + offset,
              scale: 0.92 + (0.08 * progress),
              opacity: 0.32 + (0.68 * progress),
              child: SizedBox(width: width, child: _buildAdjacentWeekView(-1)),
            ),
          if (offset < 0)
            _depthPage(
              x: width + offset,
              scale: 0.92 + (0.08 * progress),
              opacity: 0.32 + (0.68 * progress),
              child: SizedBox(width: width, child: _buildAdjacentWeekView(1)),
            ),
          _depthPage(
            x: offset,
            scale: 1.0 - (0.04 * progress),
            opacity: 1.0 - (0.18 * progress),
            child: SizedBox(width: width, child: _buildWeekView()),
          ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onWeekCarouselDragStart,
      onHorizontalDragUpdate: _onWeekCarouselDragUpdate,
      onHorizontalDragEnd: _onWeekCarouselDragEnd,
      child: carousel,
    );
  }

  Widget _buildDepthDayCarousel(double width) {
    final dayIndex = _tabController.index.clamp(0, 4).toInt();

    Widget dayAt(int index) {
      if (index >= 0 && index < 5) return _buildDayContentView(index);
      final direction = index < 0 ? -1 : 1;
      final monday = _weekMondayFromDelta(direction);
      final cached = _getAdjacentWeekData(monday);
      if (cached != null) {
        return _buildDayContentView(
          index < 0 ? 4 : 0,
          monday: monday,
          weekData: cached,
        );
      }
      return _buildAdjacentWeekView(direction);
    }

    final targetDay = _dayCarouselTargetDay;
    final previousIndex = targetDay != null && targetDay < dayIndex
        ? targetDay
        : dayIndex - 1;
    final nextIndex = targetDay != null && targetDay > dayIndex
        ? targetDay
        : dayIndex + 1;

    final currentPage = SizedBox(width: width, child: dayAt(dayIndex));
    final previousPage = targetDay == null || targetDay < dayIndex
        ? SizedBox(width: width, child: dayAt(previousIndex))
        : null;
    final nextPage = targetDay == null || targetDay > dayIndex
        ? SizedBox(width: width, child: dayAt(nextIndex))
        : null;

    Widget buildPages(double rawOffset) {
      final offset = rawOffset.clamp(-width, width).toDouble();
      final progress = width <= 0
          ? 0.0
          : (offset.abs() / width).clamp(0.0, 1.0);
      return ClipRect(
        child: Stack(
          children: [
            if (offset > 0 && previousPage != null)
              _depthPage(
                x: -width + offset,
                scale: 0.92 + (0.08 * progress),
                opacity: 0.32 + (0.68 * progress),
                child: previousPage,
              ),
            if (offset < 0 && nextPage != null)
              _depthPage(
                x: width + offset,
                scale: 0.92 + (0.08 * progress),
                opacity: 0.32 + (0.68 * progress),
                child: nextPage,
              ),
            _depthPage(
              x: offset,
              scale: 1.0 - (0.04 * progress),
              opacity: 1.0 - (0.18 * progress),
              child: currentPage,
            ),
          ],
        ),
      );
    }

    final animation = _dayCarouselAnimation;
    final pages = _isDayCarouselAnimating && animation != null
        ? AnimatedBuilder(
            animation: animation,
            builder: (context, _) => buildPages(animation.value),
          )
        : buildPages(_dayCarouselOffset);

    return GestureDetector(
      key: const ValueKey('day-timetable-carousel'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onDayCarouselDragStart,
      onHorizontalDragUpdate: _onDayCarouselDragUpdate,
      onHorizontalDragEnd: _onDayCarouselDragEnd,
      child: pages,
    );
  }

  // --- Week carousel ---

  Widget _buildWeekCarousel() {
    final carousel = LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final offset = _carouselOffset.clamp(-w, w);

        return ClipRect(
          child: Stack(
            children: [
              if (offset > 0)
                Transform.translate(
                  // Keep the adjacent week exactly one viewport away.  This
                  // lets it meet the current week without a visible jump
                  // when the animation hands over to the new data.
                  offset: Offset(-w + offset, 0),
                  child: SizedBox(width: w, child: _buildAdjacentWeekView(-1)),
                ),
              if (offset < 0)
                Transform.translate(
                  offset: Offset(w + offset, 0),
                  child: SizedBox(width: w, child: _buildAdjacentWeekView(1)),
                ),
              Transform.translate(
                offset: Offset(offset, 0),
                child: SizedBox(
                  width: w,
                  child: KeyedSubtree(
                    key: ValueKey(
                      'carousel-${untisDateString(_currentMonday)}',
                    ),
                    child: _isDailyView
                        ? _buildDayCarousel(w)
                        : _buildWeekView(visibleDays: _visibleGridDays),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    // The weekly grid owns horizontal swipes again. The day carousel uses its
    // own gesture handler, while a vertical drag continues to reach the
    // scrollable timetable body.
    if (_isDailyView) return carousel;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onWeekCarouselDragStart,
      onHorizontalDragUpdate: _onWeekCarouselDragUpdate,
      onHorizontalDragEnd: _onWeekCarouselDragEnd,
      child: carousel,
    );
  }

  Widget _buildDayCarousel(double width) {
    final dayIndex = _tabController.index.clamp(0, 4).toInt();

    Widget dayAt(int index) {
      if (index >= 0 && index < 5) return _buildDayContentView(index);
      final direction = index < 0 ? -1 : 1;
      final monday = _weekMondayFromDelta(direction);
      final cached = _getAdjacentWeekData(monday);
      if (cached != null) {
        return _buildDayContentView(
          index < 0 ? 4 : 0,
          monday: monday,
          weekData: cached,
        );
      }
      return _buildAdjacentWeekView(direction);
    }

    final targetDay = _dayCarouselTargetDay;
    final previousIndex = targetDay != null && targetDay < dayIndex
        ? targetDay
        : dayIndex - 1;
    final nextIndex = targetDay != null && targetDay > dayIndex
        ? targetDay
        : dayIndex + 1;

    // Build the expensive timetable grids once. During a programmatic date-tab
    // animation only the cheap Transform widgets below are rebuilt.
    final currentPage = SizedBox(width: width, child: dayAt(dayIndex));
    final previousPage = targetDay == null || targetDay < dayIndex
        ? SizedBox(width: width, child: dayAt(previousIndex))
        : null;
    final nextPage = targetDay == null || targetDay > dayIndex
        ? SizedBox(width: width, child: dayAt(nextIndex))
        : null;

    Widget buildPages(double rawOffset) {
      final offset = rawOffset.clamp(-width, width).toDouble();
      return ClipRect(
        child: Stack(
          children: [
            if (offset > 0 && previousPage != null)
              Transform.translate(
                offset: Offset(-width + offset, 0),
                child: previousPage,
              ),
            if (offset < 0 && nextPage != null)
              Transform.translate(
                offset: Offset(width + offset, 0),
                child: nextPage,
              ),
            Transform.translate(offset: Offset(offset, 0), child: currentPage),
          ],
        ),
      );
    }

    final animation = _dayCarouselAnimation;
    final pages = _isDayCarouselAnimating && animation != null
        ? AnimatedBuilder(
            animation: animation,
            builder: (context, _) => buildPages(animation.value),
          )
        : buildPages(_dayCarouselOffset);

    return GestureDetector(
      key: const ValueKey('day-timetable-carousel'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onDayCarouselDragStart,
      onHorizontalDragUpdate: _onDayCarouselDragUpdate,
      onHorizontalDragEnd: _onDayCarouselDragEnd,
      child: pages,
    );
  }

  void _onDayCarouselDragStart(DragStartDetails details) {
    if (_isDayCarouselAnimating || _isWeekCarouselAnimating) return;
    setState(() {
      _dayCarouselOffset = 0;
      _dayCarouselTargetDay = null;
    });
    unawaited(
      _prefetchAdjacentWeeks(allowNetwork: false, refreshFromDisk: true),
    );
  }

  void _onDayCarouselDragUpdate(DragUpdateDetails details) {
    if (_isDayCarouselAnimating || _isWeekCarouselAnimating) return;
    final maxOffset = MediaQuery.of(context).size.width * 0.92;
    setState(() {
      _dayCarouselOffset = (_dayCarouselOffset + details.delta.dx)
          .clamp(-maxOffset, maxOffset)
          .toDouble();
    });
  }

  void _onDayCarouselDragEnd(DragEndDetails details) {
    if (_isDayCarouselAnimating || _isWeekCarouselAnimating) return;
    final width = MediaQuery.sizeOf(context).width;
    final threshold = width * 0.25;
    final velocity = details.primaryVelocity ?? 0;

    // A fast fling advances exactly one page in its drag direction. If the
    // finger has been pulled back across the starting point, the sign check
    // deliberately wins and the current day snaps back into place.
    if (_dayCarouselOffset < -threshold ||
        (_dayCarouselOffset < 0 && velocity < -400)) {
      _animateDayCarouselTo(1, width);
    } else if (_dayCarouselOffset > threshold ||
        (_dayCarouselOffset > 0 && velocity > 400)) {
      _animateDayCarouselTo(-1, width);
    } else {
      _animateDayCarouselTo(0, width);
    }
  }

  void _animateDayTabTo(int targetDay) {
    final currentDay = _tabController.index;
    if (targetDay == currentDay ||
        _isDayCarouselAnimating ||
        _isWeekCarouselAnimating) {
      return;
    }

    if (timetableSwitchAnimationNotifier.value == 1) {
      final controller = _materialDayCarouselController ??= CarouselController(
        initialItem: currentDay + 1,
      );
      _materialDayIndex = currentDay + 1;
      final targetItem = targetDay + 1;
      if (controller.hasClients) {
        unawaited(
          controller
              .animateToItem(
                targetItem,
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeInOutCubicEmphasized,
              )
              .then((_) {
                if (mounted) _commitMaterialDayIndex(targetItem);
              }),
        );
      } else {
        _commitMaterialDayIndex(targetItem);
      }
      return;
    }

    final width = MediaQuery.sizeOf(context).width;
    _animateDayCarouselTo(
      targetDay > currentDay ? 1 : -1,
      width,
      targetDay: targetDay,
    );
  }

  void _onDayTabBarTap(int targetDay) {
    // In 3-day and week mode the grid follows the header tab directly. The
    // full-screen day carousel transition belongs only to Daily view.
    if (!_isDailyView) return;
    if (_isDayCarouselAnimating || _isWeekCarouselAnimating) return;
    // Tapping the already-selected date must remain a no-op. For a real tab
    // change TabBar has already started animateTo(), so indexIsChanging is true.
    if (!_tabController.indexIsChanging && _tabController.index == targetDay) {
      return;
    }

    // TabBar has already started changing the controller when this callback
    // runs. Restore the previous day synchronously so the heavy timetable grid
    // never renders the target once before our own carousel begins.
    final previousDay = _tabController.index == targetDay
        ? _tabController.previousIndex
        : _tabController.index;
    if (previousDay == targetDay) return;

    _suppressDayTabControllerRebuild = true;
    try {
      _tabController.animateTo(previousDay, duration: Duration.zero);
    } finally {
      _suppressDayTabControllerRebuild = false;
    }
    _animateDayTabTo(targetDay);
  }

  void _animateDayCarouselTo(int direction, double width, {int? targetDay}) {
    if (_isDayCarouselAnimating || _isWeekCarouselAnimating) return;
    final dayBeforeAnimation = _tabController.index;
    final mondayBeforeAnimation = _currentMonday;
    final resolvedTargetDay = targetDay ?? dayBeforeAnimation + direction;
    setState(() {
      _isDayCarouselAnimating = true;
      _dayCarouselTargetDay = direction == 0 ? null : resolvedTargetDay;
    });
    _dayCarouselAnimController?.dispose();
    _dayCarouselAnimController = AnimationController(
      duration: Duration(milliseconds: direction == 0 ? 220 : 300),
      vsync: this,
    );
    final target = direction == 0 ? 0.0 : -direction * width;
    final animation = Tween<double>(begin: _dayCarouselOffset, end: target)
        .animate(
          CurvedAnimation(
            parent: _dayCarouselAnimController!,
            curve: Curves.easeOutCubic,
          ),
        );
    _dayCarouselAnimation = animation;
    _dayCarouselAnimController!.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;

      if (direction != 0) {
        if (resolvedTargetDay >= 0 && resolvedTargetDay < 5) {
          _tabController.animateTo(resolvedTargetDay, duration: Duration.zero);
        } else {
          final weekDirection = resolvedTargetDay < 0 ? -1 : 1;
          final newMonday = mondayBeforeAnimation.add(
            Duration(days: 7 * weekDirection),
          );
          final cached = _adjacentWeekCache[_mondayKey(newMonday)];
          setState(() {
            _currentMonday = newMonday;
            if (cached != null) {
              _weekData = cached;
              _showingCachedWeek = true;
              _loading = false;
            }
          });
          _tabController.animateTo(
            resolvedTargetDay < 0 ? 4 : 0,
            duration: Duration.zero,
          );
          _fetchFullWeek();
          _prefetchAdjacentWeeks();
        }
        HapticFeedback.selectionClick();
      }
      setState(() {
        _dayCarouselOffset = 0;
        _dayCarouselTargetDay = null;
        _dayCarouselAnimation = null;
        _isDayCarouselAnimating = false;
      });
    });
    _dayCarouselAnimController!.forward();
  }

  void _onWeekCarouselDragStart(DragStartDetails details) {
    if (_isWeekCarouselAnimating || _isDayCarouselAnimating) return;
    setState(() => _carouselOffset = 0);
    unawaited(
      _prefetchAdjacentWeeks(allowNetwork: false, refreshFromDisk: true),
    );
  }

  void _onWeekCarouselDragUpdate(DragUpdateDetails details) {
    if (_isWeekCarouselAnimating || _isDayCarouselAnimating) return;
    final maxOffset = MediaQuery.of(context).size.width * 0.92;
    setState(() {
      _carouselOffset = (_carouselOffset + details.delta.dx)
          .clamp(-maxOffset, maxOffset)
          .toDouble();
    });
  }

  void _onWeekCarouselDragEnd(DragEndDetails details) {
    if (_isWeekCarouselAnimating || _isDayCarouselAnimating) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 400.0;
    final velocity = details.primaryVelocity ?? 0;
    final threshold = width * 0.25;
    if (_carouselOffset < -threshold ||
        (_carouselOffset < 0 && velocity < -400)) {
      _animateCarouselTo(-1, width);
    } else if (_carouselOffset > threshold ||
        (_carouselOffset > 0 && velocity > 400)) {
      _animateCarouselTo(1, width);
    } else {
      _animateCarouselTo(0, width);
    }
  }

  void _animateCarouselTo(int direction, double width) {
    if (_isWeekCarouselAnimating) return;
    final mondayBeforeAnimation = _currentMonday;
    _isWeekCarouselAnimating = true;
    if (direction == 0) {
      _carouselAnimController?.dispose();
      _carouselAnimController = AnimationController(
        duration: const Duration(milliseconds: 250),
        vsync: this,
      );
      final anim = Tween<double>(begin: _carouselOffset, end: 0).animate(
        CurvedAnimation(
          parent: _carouselAnimController!,
          curve: Curves.easeOutCubic,
        ),
      );
      _carouselAnimController!.addListener(() {
        if (!mounted) return;
        setState(() => _carouselOffset = anim.value);
      });
      _carouselAnimController!.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _carouselOffset = 0;
          });
          _isWeekCarouselAnimating = false;
        }
      });
      _carouselAnimController!.forward();
      return;
    }

    // Finish exactly one viewport away so the incoming week is already at
    // x = 0 when its data becomes the active week.
    final target = direction * width;
    _carouselAnimController?.dispose();
    _carouselAnimController = AnimationController(
      duration: const Duration(milliseconds: 340),
      vsync: this,
    );
    final anim = Tween<double>(begin: _carouselOffset, end: target).animate(
      CurvedAnimation(
        parent: _carouselAnimController!,
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );
    _carouselAnimController!.addListener(() {
      if (!mounted) return;
      setState(() => _carouselOffset = anim.value);
    });
    _carouselAnimController!.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        final newMonday = direction > 0
            ? mondayBeforeAnimation.subtract(const Duration(days: 7))
            : mondayBeforeAnimation.add(const Duration(days: 7));
        final cacheKey = _mondayKey(newMonday);
        final cached = _adjacentWeekCache[cacheKey];
        setState(() {
          _currentMonday = newMonday;
          if (cached != null) {
            _weekData = cached;
            _showingCachedWeek = true;
            _loading = false;
          }
          _carouselOffset = 0;
          // Synchronize TabController index when jumping weeks
          if (direction < 0) {
            _tabController.animateTo(0, duration: Duration.zero);
          } else {
            _tabController.animateTo(4, duration: Duration.zero);
          }
        });
        _isWeekCarouselAnimating = false;
        HapticFeedback.selectionClick();
        _fetchFullWeek();
        _prefetchAdjacentWeeks();
      }
    });
    _carouselAnimController!.forward();
  }

  @override
  void dispose() {
    hiddenSubjectsNotifier.removeListener(_onHiddenSubjectsChanged);
    subjectColorsNotifier.removeListener(_onHiddenSubjectsChanged);
    subjectPresentationsNotifier.removeListener(_onHiddenSubjectsChanged);
    monochromeLessonsNotifier.removeListener(_onHiddenSubjectsChanged);
    monochromeLessonColorNotifier.removeListener(_onHiddenSubjectsChanged);
    showCancelledNotifier.removeListener(_onHiddenSubjectsChanged);
    timetableSwitchAnimationNotifier.removeListener(
      _onTimetableSwitchAnimationChanged,
    );
    demoModeNotifier.removeListener(_onDemoModeChanged);
    pendingTimetableActionNotifier.removeListener(_onPendingTimetableAction);
    lessonCardStyleNotifier.removeListener(_onHiddenSubjectsChanged);
    glowEffectsEnabledNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonBlurEnabledNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonBlurAmountNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonCardOpacityNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonBorderRadiusNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonAccentStyleNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonShowTeacherNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonFullTeacherNamesNotifier.removeListener(_onHiddenSubjectsChanged);
    showFullTeacherNamesNotifier.removeListener(_onTeacherNameModeChanged);
    timetableDaySpanNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonShowRoomNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonCompactModeNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonDimPastNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonCancelledPatternNotifier.removeListener(_onHiddenSubjectsChanged);
    _progressiveNotificationTimer?.cancel();
    _tabController
      ..removeListener(_onSelectedDayChanged)
      ..dispose();
    _carouselAnimController?.dispose();
    _dayCarouselAnimController?.dispose();
    _materialDayCarouselController?.dispose();
    _materialWeekCarouselController?.dispose();
    _highlightTimer?.cancel();
    _highlightController?.dispose();
    _cacheRefreshController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WeeklyTimetablePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (sessionID.isNotEmpty && _loading) {
      _fetchFullWeek();
    }
  }

  static int _toMinutes(int t) => (t ~/ 100) * 60 + (t % 100);

  static String _formatMinutes(int minutes) {
    final hh = minutes ~/ 60;
    final mm = minutes % 60;
    return '$hh:${mm.toString().padLeft(2, '0')}';
  }

  static int _lessonStartMinutes(Map<dynamic, dynamic> lesson) =>
      _toMinutes((lesson['startTime'] as int?) ?? 800);

  static int _lessonEndMinutes(Map<dynamic, dynamic> lesson) => _toMinutes(
    (lesson['endTime'] as int?) ??
        (((lesson['startTime'] as int?) ?? 800) + 45),
  );

  static String _norm(dynamic value) => value?.toString().trim() ?? '';

  /// Returns a Material icon glyph for common German/international school
  /// subjects, or null when the subject is unrecognized.
  static IconData? _subjectIconFor(String sk, String subject) {
    final key = (sk.isNotEmpty ? sk : subject).toLowerCase().trim();
    if (key.isEmpty) return null;

    // Exact short-name matches for common German abbreviations.
    switch (key) {
      case 'ma':
      case 'mat':
      case 'mathe':
      case 'math':
        return Icons.calculate_rounded;
      case 'de':
      case 'deu':
      case 'deutsch':
      case 'german':
        return Icons.abc_rounded;
      case 'en':
      case 'eng':
      case 'engl':
      case 'englisch':
      case 'english':
        return Icons.translate_rounded;
      case 'fr':
      case 'fre':
      case 'fran':
      case 'franz':
      case 'französisch':
        return Icons.translate_rounded;
      case 'la':
      case 'lat':
      case 'lati':
      case 'latein':
      case 'latin':
        return Icons.menu_book_rounded;
      case 'ph':
      case 'phy':
      case 'physik':
      case 'physics':
        return Icons.science_rounded;
      case 'ch':
      case 'chem':
      case 'chemie':
      case 'chemistry':
        return Icons.science_rounded;
      case 'bi':
      case 'bio':
      case 'biologie':
      case 'biology':
        return Icons.eco_rounded;
      case 'geo':
      case 'geog':
      case 'geographie':
      case 'geography':
        return Icons.public_rounded;
      case 'ge':
      case 'ges':
      case 'gesc':
      case 'geschichte':
      case 'history':
        return Icons.history_edu_rounded;
      case 'ek':
      case 'ev':
      case 'eth':
      case 'phil':
      case 'relig':
      case 'religion':
      case 'ethik':
      case 'philosophie':
        return Icons.auto_stories_rounded;
      case 'inf':
      case 'it':
      case 'info':
      case 'informatik':
      case 'comp':
      case 'cs':
        return Icons.computer_rounded;
      case 'mu':
      case 'mus':
      case 'musik':
      case 'music':
        return Icons.music_note_rounded;
      case 'ku':
      case 'kunst':
      case 'art':
        return Icons.palette_rounded;
      case 'sp':
      case 'sport':
      case 'pe':
        return Icons.sports_soccer_rounded;
      case 'wl':
      case 'pol':
      case 'poli':
      case 'soz':
      case 'politik':
        return Icons.groups_rounded;
      case 'sy':
      case 'psych':
      case 'psychologie':
        return Icons.psychology_rounded;
      case 'nw':
      case 'nwv':
      case 'ne':
        return Icons.biotech_rounded;
      case 'kr':
      case 'ko':
      case 'kl':
      case 'klassenstunde':
        return Icons.forum_rounded;
      case 'prak':
      case 'pd':
      case 'praktikum':
        return Icons.school_rounded;
    }

    // Substring fallbacks for longer subject names.
    if (key.contains('math')) return Icons.calculate_rounded;
    if (key.contains('deutsch')) return Icons.abc_rounded;
    if (key.contains('englisch') || key.contains('english')) {
      return Icons.translate_rounded;
    }
    if (key.contains('franz')) return Icons.translate_rounded;
    if (key.contains('latein')) return Icons.menu_book_rounded;
    if (key.contains('physik')) return Icons.science_rounded;
    if (key.contains('chemie') || key.contains('chem')) {
      return Icons.science_rounded;
    }
    if (key.contains('biologie') || key.contains('natur')) {
      return Icons.eco_rounded;
    }
    if (key.contains('geographie')) return Icons.public_rounded;
    if (key.contains('geschichte')) return Icons.history_edu_rounded;
    if (key.contains('religion') ||
        key.contains('ethik') ||
        key.contains('evangelisch') ||
        key.contains('katholisch')) {
      return Icons.auto_stories_rounded;
    }
    if (key.contains('informatik') || key.contains('computer')) {
      return Icons.computer_rounded;
    }
    if (key.contains('musik')) return Icons.music_note_rounded;
    if (key.contains('kunst')) return Icons.palette_rounded;
    if (key.contains('sport')) return Icons.sports_soccer_rounded;
    if (key.contains('politik') || key.contains('sozialkunde')) {
      return Icons.groups_rounded;
    }
    if (key.contains('psychologie') || key.contains('psycho')) {
      return Icons.psychology_rounded;
    }
    return null;
  }

  bool _isSameConsecutiveLessonBlock(
    Map<dynamic, dynamic> a,
    Map<dynamic, dynamic> b,
  ) {
    final sameSubjectShort =
        _norm(a['_subjectShort']) == _norm(b['_subjectShort']);
    final sameSubjectLong =
        _norm(a['_subjectLong']) == _norm(b['_subjectLong']);
    final sameTeacher = _norm(a['_teacher']) == _norm(b['_teacher']);
    final sameRoom = _norm(a['_room']) == _norm(b['_room']);
    final sameCode = _norm(a['code']) == _norm(b['code']);
    final sameDate = _norm(a['date']) == _norm(b['date']);

    if (!(sameSubjectShort &&
        sameSubjectLong &&
        sameTeacher &&
        sameRoom &&
        sameCode &&
        sameDate)) {
      return false;
    }

    final aEnd = _lessonEndMinutes(a);
    final bStart = _lessonStartMinutes(b);
    final gap = bStart - aEnd;

    // Treat short breaks between identical consecutive lessons as one block.
    return gap >= 0 && gap <= 10;
  }

  List<dynamic> _mergeConsecutiveLessons(List<dynamic> lessons) {
    final sorted =
        lessons
            .whereType<Map>()
            .map((l) => Map<dynamic, dynamic>.from(l.cast<dynamic, dynamic>()))
            .toList()
          ..sort((a, b) {
            final byStart = _lessonStartMinutes(
              a,
            ).compareTo(_lessonStartMinutes(b));
            if (byStart != 0) return byStart;
            return _lessonEndMinutes(a).compareTo(_lessonEndMinutes(b));
          });

    if (sorted.isEmpty) return const [];

    final merged = <Map<dynamic, dynamic>>[];
    for (final lesson in sorted) {
      if (merged.isEmpty) {
        merged.add(lesson);
        continue;
      }

      final previous = merged.last;
      if (_isSameConsecutiveLessonBlock(previous, lesson)) {
        final prevEnd = _lessonEndMinutes(previous);
        final lessonEnd = _lessonEndMinutes(lesson);
        if (lessonEnd > prevEnd) {
          previous['endTime'] = lesson['endTime'];
        }
      } else {
        merged.add(lesson);
      }
    }

    return merged;
  }

  List<_TimeRangeLabel> _collectTimeRangesFromData(
    Map<int, List<dynamic>> weekData,
  ) {
    final seen = <String>{};
    final ranges = <_TimeRangeLabel>[];
    for (final day in weekData.values) {
      final visibleDayLessons = day
          .where(
            (l) => !hiddenSubjectsNotifier.value.contains(
              l['_subjectShort']?.toString() ?? '',
            ),
          )
          .where(
            (l) =>
                showCancelledNotifier.value || !isTimetableCancelled(l),
          )
          .toList();
      final mergedDayLessons = _mergeConsecutiveLessons(visibleDayLessons);
      for (final lesson in mergedDayLessons) {
        final map = lesson as Map<dynamic, dynamic>;
        final start = _lessonStartMinutes(map);
        final end = _lessonEndMinutes(map);
        if (end <= start) continue;
        final key = '$start-$end';
        if (seen.add(key)) {
          ranges.add(_TimeRangeLabel(startMin: start, endMin: end));
        }
      }
    }
    ranges.sort((a, b) {
      final byStart = a.startMin.compareTo(b.startMin);
      if (byStart != 0) return byStart;
      return a.endMin.compareTo(b.endMin);
    });
    return ranges;
  }

  List<_TimeRangeLabel> _collectTimeRangesFromDay(int dayIndex) {
    final dayLessons = _weekData[dayIndex] ?? const <dynamic>[];
    final ranges = <_TimeRangeLabel>[];
    final seen = <String>{};

    for (final lesson in dayLessons.whereType<Map>()) {
      final map = lesson.cast<dynamic, dynamic>();
      if (isTimetableCancelled(map)) continue;
      final start = _lessonStartMinutes(map);
      final end = _lessonEndMinutes(map);
      if (end <= start) continue;
      final key = '$start-$end';
      if (seen.add(key)) {
        ranges.add(_TimeRangeLabel(startMin: start, endMin: end));
      }
    }

    ranges.sort((a, b) {
      final byStart = a.startMin.compareTo(b.startMin);
      if (byStart != 0) return byStart;
      return a.endMin.compareTo(b.endMin);
    });
    return ranges;
  }

  Set<int> _lessonRoomIds(Map<dynamic, dynamic> lesson) {
    final ids = <int>{};
    final ro = lesson['ro'];
    if (ro is List) {
      for (final entry in ro.whereType<Map>()) {
        final id = entry['id'];
        if (id is int) {
          ids.add(id);
        } else {
          final parsed = int.tryParse(id?.toString() ?? '');
          if (parsed != null) ids.add(parsed);
        }
      }
    }

    if (ids.isEmpty) {
      final roomName = (lesson['_room'] ?? '').toString().trim();
      if (roomName.isNotEmpty) {
        _roomMap.forEach((id, name) {
          if (name.trim().toLowerCase() == roomName.toLowerCase()) {
            ids.add(id);
          }
        });
      }
    }

    return ids;
  }

  List<String> _computeFreeRooms({
    required List<List<dynamic>> timetables,
    required int startMin,
    required int endMin,
  }) {
    final occupiedIds = <int>{};
    for (final periods in timetables) {
      for (final raw in periods) {
        if (raw is! Map) continue;
        final lesson = raw.cast<dynamic, dynamic>();
        if (isTimetableCancelled(lesson)) continue;
        final lessonStart = _lessonStartMinutes(lesson);
        final lessonEnd = _lessonEndMinutes(lesson);
        if (lessonStart < endMin && lessonEnd > startMin) {
          occupiedIds.addAll(_lessonRoomIds(lesson));
        }
      }
    }

    final freeRooms = <String>[];
    final seenNames = <String>{};
    final sortedEntries = _roomMap.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    for (final entry in sortedEntries) {
      if (occupiedIds.contains(entry.key)) continue;
      final name = entry.value.trim();
      if (name.isEmpty) continue;
      if (seenNames.add(name.toLowerCase())) {
        freeRooms.add(name);
      }
    }
    return freeRooms;
  }

  List<Map<String, dynamic>> _getHolidaysForDay(DateTime day) {
    final dayInt = untisDateInt(day);
    return _holidays.where((h) {
      final start = h['startDate'];
      final end = h['endDate'];
      if (start == null || end == null) return false;
      final s = int.tryParse(start.toString());
      final e = int.tryParse(end.toString());
      if (s == null || e == null) return false;
      return dayInt >= s && dayInt <= e;
    }).toList();
  }

  Future<void> _showFreeRoomsDialog() async {
    final l = appL10nFor(appLocaleNotifier.value);
    final dayIndex = _tabController.index.clamp(0, 4);
    final ranges = _collectTimeRangesFromDay(dayIndex);

    if (ranges.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.freeRoomsNoRangesHint),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dayDate = _currentMonday.add(Duration(days: dayIndex));
    int selectedIndex = 0;
    final now = DateTime.now();
    final isToday =
        dayDate.year == now.year &&
        dayDate.month == now.month &&
        dayDate.day == now.day;

    if (isToday) {
      final nowMin = now.hour * 60 + now.minute;
      final idx = ranges.indexWhere(
        (r) => nowMin >= r.startMin && nowMin < r.endMin,
      );
      if (idx >= 0) selectedIndex = idx;
    }

    if (!mounted) return;
    showUntisDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final List<List<String>> freeRoomsForRange;
    if (demoModeNotifier.value) {
      freeRoomsForRange = List.generate(
        ranges.length,
        DemoModeService.demoFreeRooms,
      );
    } else {
      final classes = await _fetchClasses();
      List<List<dynamic>> timetables = [];
      if (classes.isNotEmpty) {
        final results = await Future.wait(
          classes.map((c) => _fetchClassTimetable(c['id'] as int, dayDate)),
          eagerError: false,
        );
        timetables = results.whereType<List<dynamic>>().toList();
      }
      freeRoomsForRange = [
        for (final range in ranges)
          _computeFreeRooms(
            timetables: timetables,
            startMin: range.startMin,
            endMin: range.endMin,
          ),
      ];
    }

    if (!mounted) return;
    if (context.mounted) Navigator.of(context).pop();

    await showUntisModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: _kBottomSheetAnimationStyle,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            final freeRooms = freeRoomsForRange[selectedIndex];
            final dayName = _dayShort[dayIndex];

            return _glassContainer(
              context: ctx,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      children: [
                        Text(
                          l.freeRoomsTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$dayName • ${_formatMinutes(ranges[selectedIndex].startMin)} - ${_formatMinutes(ranges[selectedIndex].endMin)}',
                          style: GoogleFonts.outfit(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l.freeRoomsSelectTime,
                          style: GoogleFonts.outfit(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 0; i < ranges.length; i++)
                              ChoiceChip(
                                selected: i == selectedIndex,
                                showCheckmark: true,
                                side: BorderSide(
                                  color:
                                      (i == selectedIndex
                                              ? cs.primary
                                              : cs.outlineVariant)
                                          .withValues(
                                            alpha: i == selectedIndex
                                                ? 0.48
                                                : 0.65,
                                          ),
                                ),
                                backgroundColor: cs.surfaceContainerHigh
                                    .withValues(
                                      alpha: blurEnabledNotifier.value
                                          ? 0.86
                                          : 0.92,
                                    ),
                                selectedColor: cs.primaryContainer.withValues(
                                  alpha: 0.92,
                                ),
                                label: Text(
                                  '${_formatMinutes(ranges[i].startMin)} - ${_formatMinutes(ranges[i].endMin)}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: i == selectedIndex
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: i == selectedIndex
                                        ? cs.onPrimaryContainer
                                        : cs.onSurface.withValues(alpha: 0.98),
                                  ),
                                ),
                                onSelected: (_) {
                                  setDlg(() => selectedIndex = i);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l.freeRoomsCount(freeRooms.length),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (freeRooms.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withValues(
                                alpha: blurEnabledNotifier.value ? 0.88 : 0.94,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                            child: Text(
                              l.freeRoomsNoneFound,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.96,
                                ),
                              ),
                            ),
                          )
                        else
                          ...freeRooms.asMap().entries.map((entry) {
                            final i = entry.key;
                            final room = entry.value;
                            return _springEntry(
                              duration: Duration(milliseconds: 300 + i * 50),
                              offsetY: 16,
                              startScale: 0.95,
                              curve: _kSmoothBounce,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh.withValues(
                                    alpha: blurEnabledNotifier.value
                                        ? 0.86
                                        : 0.92,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.56,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.meeting_room_outlined,
                                    color: cs.primary,
                                  ),
                                  title: Text(
                                    room,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchClasses() async {
    final catalog = await _timetableRepository.fetchClassCatalog(
      WebUntisRequestContext(
        schoolUrl: schoolUrl,
        schoolName: schoolName,
        sessionId: sessionID,
      ),
    );
    return catalog.classes;
  }

  Future<List<dynamic>> _fetchClassTimetable(int classId, DateTime date) async {
    try {
      return await _timetableRepository.fetchClassTimetable(
        context: _timetableRequestContext,
        classId: classId,
        date: date,
      );
    } catch (_) {
      return const <dynamic>[];
    }
  }

  static const List<double> _grayscaleMatrix = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  Widget _dimPastLesson({required Widget child, required bool dim}) {
    if (!dim || !lessonDimPastNotifier.value) return child;
    return Opacity(
      opacity: 0.45,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: child,
      ),
    );
  }

  Widget _buildTimetableLessonCard({
    required BuildContext context,
    required bool isCancelled,
    bool isSubstitution = false,
    required bool isDark,
    required Color fgColor,
    required Color bgColor,
    required String subject,
    required String teacher,
    required String room,
    required bool isNow,
    IconData? subjectIcon,
    bool isTeacherMissing = false,
    bool hasHomework = false,
    bool hasExam = false,
    String originalTeacher = '',
    double? borderRadius,
    EdgeInsets? padding,
    double accentWidth = 3.5,
    double subjectFontSize = 11.5,
    double teacherFontSize = 9.5,
    double roomFontSize = 9.5,
    bool useStripes = true,
    double? availableWidth,
    double? availableHeight,
  }) {
    final tokens = untisThemeTokensOf(context);
    final visuals = LessonCardVisualsResolver.resolve(
      context: context,
      tokens: tokens,
      isDark: isDark,
      isCancelled: isCancelled,
      isNow: isNow,
      foregroundColor: fgColor,
      backgroundColor: bgColor,
      isTeacherMissing: isTeacherMissing,
      usePattern: useStripes,
      borderRadius: borderRadius,
      accentWidth: accentWidth,
    );
    final effectiveRadius = visuals.radius;
    final cardRadius = visuals.borderRadius;
    final blurEnabled = visuals.blurEnabled;
    final blurSigma = visuals.blurSigma;
    final accentStyle = visuals.accentStyle;
    final showPattern = visuals.showPattern;
    final showTeacher = lessonShowTeacherNotifier.value;
    final showRoom = lessonShowRoomNotifier.value;
    final isSubstituted =
        showTeacher && originalTeacher.isNotEmpty && originalTeacher != teacher;
    final compact = lessonCompactModeNotifier.value;

    final heightCompact = availableHeight != null && availableHeight < 58;
    final heightMinimal = availableHeight != null && availableHeight < 40;
    final widthCompact = availableWidth != null && availableWidth < 54;
    final effectivePadding = heightMinimal
        ? const EdgeInsets.fromLTRB(5, 2, 4, 2)
        : heightCompact
        ? const EdgeInsets.fromLTRB(6, 3, 5, 3)
        : padding != null
        ? (compact
              ? EdgeInsets.fromLTRB(
                  padding.left.clamp(3.0, 6.0),
                  (padding.top * 0.7).clamp(2.0, 5.0),
                  padding.right.clamp(3.0, 6.0),
                  (padding.bottom * 0.7).clamp(2.0, 5.0),
                )
              : padding)
        : (compact
              ? const EdgeInsets.fromLTRB(6, 3, 5, 3)
              : const EdgeInsets.fromLTRB(8, 5, 6, 5));

    final effectiveSubjectFontSize = compact || widthCompact || heightCompact
        ? (subjectFontSize * 0.92).clamp(8.5, 14.0)
        : subjectFontSize;
    final effectiveTeacherFontSize = compact
        ? (teacherFontSize * 0.90).clamp(7.5, 12.0)
        : teacherFontSize;
    final effectiveRoomFontSize = compact
        ? (roomFontSize * 0.90).clamp(7.5, 12.0)
        : roomFontSize;

    final shadows = visuals.shadows;
    final effectiveFillColor = visuals.fillColor;
    final effectiveGradient = visuals.gradient;
    final effectiveBorder = visuals.border;
    final effectiveTextColor = visuals.textColor;
    final effectiveSecondaryTextColor = visuals.secondaryTextColor;
    final effectiveAccentWidth = visuals.accentWidth;

    Widget cardContent = Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: effectiveFillColor,
            gradient: effectiveGradient,
            borderRadius: cardRadius,
            border: effectiveBorder,
          ),
        ),
        if (showPattern)
          Positioned.fill(
            child: CustomPaint(
              painter: _StripedHatchPainter(
                color: fgColor.withValues(alpha: isDark ? 0.18 : 0.12),
                stripeWidth: 2.0,
                gap: 7.0,
              ),
            ),
          ),
        if (accentStyle == 0 || accentStyle == 1)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: effectiveAccentWidth,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [fgColor, fgColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(effectiveRadius),
                  bottomLeft: Radius.circular(effectiveRadius),
                ),
              ),
            ),
          ),
        Padding(
          padding: effectivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (accentStyle == 2) ...[
                    Container(
                      width: 6.5,
                      height: 6.5,
                      margin: const EdgeInsets.only(right: 4.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fgColor,
                        boxShadow: _glowShadows(context, [
                          BoxShadow(
                            color: fgColor.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ]),
                      ),
                    ),
                  ],
                  Flexible(
                    child: Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: untisThemeTextStyle(
                        context,
                        display: true,
                        fontSize: effectiveSubjectFontSize,
                        fontWeight: FontWeight.w800,
                        color: effectiveTextColor,
                        decoration: isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: fgColor.withValues(alpha: 0.6),
                        decorationThickness: 1.6,
                      ),
                    ),
                  ),
                  if (lessonShowSubjectIconsNotifier.value &&
                      subjectIcon != null &&
                      !widthCompact &&
                      !heightMinimal) ...[
                    Icon(
                      subjectIcon,
                      size: (effectiveSubjectFontSize * 1.15).clamp(11.0, 17.0),
                      color: effectiveTextColor.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 3.5),
                  ],
                  if ((hasExam || hasHomework) && !widthCompact) ...[
                    const SizedBox(width: 4),
                    Icon(
                      hasExam
                          ? Icons.assignment_turned_in_rounded
                          : Icons.assignment_rounded,
                      size: (effectiveSubjectFontSize * 0.9).clamp(10.0, 16.0),
                      color: effectiveTextColor.withValues(alpha: 0.8),
                    ),
                  ],
                  if (isTeacherMissing && !widthCompact) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.person_off_rounded,
                      size: (effectiveSubjectFontSize * 0.9).clamp(10.0, 16.0),
                      color: Colors.deepOrange.withValues(alpha: 0.9),
                    ),
                  ],
                  if (isSubstitution && !widthCompact && !heightMinimal) ...[
                    const SizedBox(width: 3),
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: (effectiveSubjectFontSize * 0.95).clamp(10.0, 15.0),
                      color: effectiveTextColor.withValues(alpha: 0.9),
                    ),
                  ],
                ],
              ),
              if (!heightMinimal &&
                  showTeacher &&
                  teacher.isNotEmpty &&
                  (availableHeight == null || availableHeight >= 42))
                Text(
                  teacher,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: effectiveTeacherFontSize,
                    fontWeight: isSubstituted
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: isSubstituted
                        ? effectiveTextColor
                        : effectiveSecondaryTextColor,
                  ),
                ),
              if (isSubstituted &&
                  (availableHeight == null || availableHeight >= 54))
                Text(
                  originalTeacher,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: effectiveTeacherFontSize * 0.9,
                    fontWeight: FontWeight.w500,
                    color: effectiveSecondaryTextColor.withValues(alpha: 0.6),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: fgColor.withValues(alpha: 0.55),
                    decorationThickness: 1.4,
                  ),
                ),
              if (!heightCompact &&
                  showRoom &&
                  room.isNotEmpty &&
                  (availableHeight == null || availableHeight >= 58))
                Text(
                  room,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: effectiveRoomFontSize,
                    fontWeight: FontWeight.w600,
                    color: effectiveSecondaryTextColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (blurEnabled) {
      cardContent = ClipRRect(
        borderRadius: cardRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: cardContent,
        ),
      );
    } else {
      cardContent = ClipRRect(borderRadius: cardRadius, child: cardContent);
    }

    return Container(
      decoration: BoxDecoration(borderRadius: cardRadius, boxShadow: shadows),
      child: cardContent,
    );
  }

  List<_LessonSlot> _computeLessonSlots(List<dynamic> rawLessons) {
    final entries =
        rawLessons.whereType<Map>().map((lesson) {
          final map = lesson.cast<dynamic, dynamic>();
          final rawStart = (map['startTime'] as int?) ?? 800;
          final rawEnd = (map['endTime'] as int?) ?? (rawStart + 45);
          return _LessonSlotCandidate(
            lesson: map,
            startMin: _toMinutes(rawStart),
            endMin: _toMinutes(rawEnd),
          );
        }).toList()..sort((a, b) {
          final byStart = a.startMin.compareTo(b.startMin);
          if (byStart != 0) return byStart;
          return a.endMin.compareTo(b.endMin);
        });

    if (entries.isEmpty) return const [];

    final slots = <_LessonSlot>[];

    void flushCluster(List<_LessonSlotCandidate> cluster) {
      if (cluster.isEmpty) return;
      final columnEnds = <int>[];

      for (final entry in cluster) {
        var assignedColumn = -1;
        for (var i = 0; i < columnEnds.length; i++) {
          if (columnEnds[i] <= entry.startMin) {
            assignedColumn = i;
            break;
          }
        }

        if (assignedColumn == -1) {
          columnEnds.add(entry.endMin);
          assignedColumn = columnEnds.length - 1;
        } else {
          columnEnds[assignedColumn] = entry.endMin;
        }

        entry.column = assignedColumn;
      }

      final columnCount = columnEnds.isEmpty ? 1 : columnEnds.length;
      for (final entry in cluster) {
        slots.add(
          _LessonSlot(
            lesson: entry.lesson,
            startMin: entry.startMin,
            endMin: entry.endMin,
            column: entry.column,
            columnCount: columnCount,
          ),
        );
      }
    }

    final cluster = <_LessonSlotCandidate>[];
    var clusterMaxEnd = -1;

    for (final entry in entries) {
      if (cluster.isEmpty) {
        cluster.add(entry);
        clusterMaxEnd = entry.endMin;
        continue;
      }

      if (entry.startMin < clusterMaxEnd) {
        cluster.add(entry);
        if (entry.endMin > clusterMaxEnd) {
          clusterMaxEnd = entry.endMin;
        }
      } else {
        flushCluster(cluster);
        cluster
          ..clear()
          ..add(entry);
        clusterMaxEnd = entry.endMin;
      }
    }
    flushCluster(cluster);

    return slots;
  }

  Widget _buildDayContentView(
    int dayIndex, {
    DateTime? monday,
    Map<int, List<dynamic>>? weekData,
  }) {
    final span = timetableDaySpanNotifier.value.clamp(1, 3).toInt();
    if (span == 1) {
      return _buildGridView(dayIndex, monday: monday, weekData: weekData);
    }
    final start = dayIndex.clamp(0, 5 - span).toInt();
    return _buildWeekView(
      monday: monday,
      weekData: weekData,
      visibleDays: List<int>.generate(span, (offset) => start + offset),
    );
  }

  Widget _buildGridView(
    int dayIndex, {
    DateTime? monday,
    Map<int, List<dynamic>>? weekData,
  }) {
    final wd = weekData ?? _weekData;
    final m = monday ?? _currentMonday;
    final media = MediaQuery.of(context);
    final topContentPadding = _isExportingTimetable
        ? 10.0
        : media.padding.top + kToolbarHeight + kTextTabBarHeight + 10;

    final lessons = (wd[dayIndex] ?? [])
        .where(
          (l) => !hiddenSubjectsNotifier.value.contains(
            l['_subjectShort']?.toString() ?? '',
          ),
        )
        .toList();

    int globalMin = 480;
    int globalMax = 1200;
    for (final day in wd.values) {
      for (final l in day) {
        final s = _toMinutes((l['startTime'] as int?) ?? 480);
        final e = _toMinutes((l['endTime'] as int?) ?? 600);
        if (s < globalMin) globalMin = s;
        if (e > globalMax) globalMax = e;
      }
    }

    globalMin = (globalMin - 15).clamp(0, 23 * 60);
    globalMax = globalMax + 15;

    final totalMinutes = globalMax - globalMin;
    final totalHeight = totalMinutes * _ppm;

    final List<int> ticks = [];
    for (int m = globalMin - (globalMin % 60) + 60; m < globalMax; m += 60) {
      ticks.add(m);
    }

    const double timeColWidth = 40;
    // During a week swipe, render time and date labels from the incoming
    // cached week as well. Reading the active week here made those rails lag
    // behind the cards until the snap animation had already completed.
    final timeRanges = _collectTimeRangesFromData(wd);
    final filteredTimeLabels = _filterTimeLabels(timeRanges);

    final now = DateTime.now();
    final dayDate = m.add(Duration(days: dayIndex));
    final isToday =
        dayDate.year == now.year &&
        dayDate.month == now.month &&
        dayDate.day == now.day;
    final nowMin = now.hour * 60 + now.minute;
    final showNowLine = isToday && nowMin >= globalMin && nowMin <= globalMax;
    final nowTop = (nowMin - globalMin) * _ppm;
    final visibleLessons = lessons
        .where(
          (l) =>
              showCancelledNotifier.value || !isTimetableCancelled(l),
        )
        .toList();
    final mergedLessons = _mergeConsecutiveLessons(visibleLessons);
    final lessonSlots = _computeLessonSlots(mergedLessons);

    final csG = Theme.of(context).colorScheme;
    return ExpressiveRefreshIndicator(
      onRefresh: _onRefresh,
      // The expressive indicator starts immediately under the app bar rather
      // than in the middle of the timetable content.
      edgeOffset: topContentPadding,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 32, top: topContentPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: timeColWidth,
              height: totalHeight,
              child: Stack(
                children: filteredTimeLabels.isNotEmpty
                    ? filteredTimeLabels.map((value) {
                        final top = (value - globalMin) * _ppm - 9;
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          child: Text(
                            _formatMinutes(value),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: csG.onSurfaceVariant.withValues(
                                alpha: 0.54,
                              ),
                            ),
                          ),
                        );
                      }).toList()
                    : ticks.map((tick) {
                        final top = (tick - globalMin) * _ppm - 9;
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          child: Text(
                            _formatMinutes(tick),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: csG.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: totalHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        ...ticks.map((tick) {
                          final top = (tick - globalMin) * _ppm;
                          return Positioned(
                            top: top,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 0.45,
                              color: csG.outlineVariant.withValues(alpha: 0.28),
                            ),
                          );
                        }),
                        ..._getHolidaysForDay(dayDate).map((holiday) {
                          final holidayStartMin = _toMinutes(800);
                          final holidayEndMin = _toMinutes(1800);
                          final top = (holidayStartMin - globalMin) * _ppm;
                          final height =
                              ((holidayEndMin - holidayStartMin) * _ppm).clamp(
                                28.0,
                                9999.0,
                              );
                          final holidayName =
                              (holiday['longName'] ?? holiday['name'] ?? '')
                                  .toString();
                          return Positioned(
                            top: top,
                            left: 2,
                            right: 2,
                            height: height,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: csG.tertiaryContainer.withValues(
                                    alpha: 0.85,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: csG.tertiary.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.celebration_rounded,
                                      size: 20,
                                      color: csG.tertiary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      holidayName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: csG.onTertiaryContainer,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        ...lessonSlots.map((slot) {
                          final l = slot.lesson;
                          final startMin = slot.startMin;
                          final endMin = slot.endMin;
                          final top = (startMin - globalMin) * _ppm;
                          final height = ((endMin - startMin) * _ppm).clamp(
                            28.0,
                            9999.0,
                          );
                          final dim = isToday && endMin <= nowMin;

                          const horizontalInset = 2.0;
                          const columnGap = 4.0;
                          final columns = slot.columnCount;
                          final availableWidth =
                              constraints.maxWidth - (horizontalInset * 2);
                          final totalGap = (columns - 1) * columnGap;
                          final rawCardWidth =
                              (availableWidth - totalGap) / columns;
                          final cardWidth = rawCardWidth > 8
                              ? rawCardWidth
                              : 8.0;
                          final left =
                              horizontalInset +
                              (slot.column * (cardWidth + columnGap));

                          return Positioned(
                            top: top,
                            left: left,
                            width: cardWidth,
                            height: height,
                            child: _dimPastLesson(
                              dim: dim,
                              child: Builder(
                                builder: (context) {
                                  final cs = Theme.of(context).colorScheme;
                                  final isDark =
                                      Theme.of(context).brightness ==
                                      Brightness.dark;
                                  final isCancelled = isTimetableCancelled(l);
                                  final isSubstitution =
                                      isTimetableSubstitution(l);
                                  final isTeacherMissing = _hasMissingTeacher(
                                    l,
                                  );
                                  final sk =
                                      l['_subjectShort']?.toString() ?? '';
                                  final useMonochrome =
                                      monochromeLessonsNotifier.value;
                                  final cancelledColor = Color(
                                    cancelledLessonColorNotifier.value,
                                  );
                                  final cv = isCancelled || useMonochrome
                                      ? null
                                      : subjectColorsNotifier.value[sk];
                                  final fgColor = isCancelled
                                      ? cancelledColor
                                      : useMonochrome
                                      ? Color(
                                          monochromeLessonColorNotifier.value,
                                        )
                                      : cv != null
                                      ? Color(cv)
                                      : _autoLessonColor(sk, isDark);
                                  final bgColor = isCancelled
                                      ? Color.alphaBlend(
                                          cancelledColor.withValues(
                                            alpha: isDark ? 0.14 : 0.10,
                                          ),
                                          cs.surfaceContainerHighest,
                                        )
                                      : Color.alphaBlend(
                                          fgColor.withValues(
                                            alpha: isDark ? 0.14 : 0.10,
                                          ),
                                          cs.surfaceContainerHighest,
                                        );
                                  final subject =
                                      l['_subjectShort']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true
                                      ? l['_subjectShort'].toString()
                                      : (l['_subjectLong']
                                                    ?.toString()
                                                    .isNotEmpty ==
                                                true
                                            ? l['_subjectLong'].toString()
                                            : '?');
                                  final room = l['_room']?.toString() ?? '';
                                  final teacher = _displayTeacher(l);
                                  final isCurrent =
                                      (startMin <= nowMin && nowMin < endMin);
                                  final isNow = isCurrent;

                                  final lDateInt =
                                      int.tryParse(
                                        l['date']?.toString() ?? '',
                                      ) ??
                                      0;
                                  final hasHomework =
                                      homeworksNotifier.value.any(
                                        (hw) =>
                                            hw['dueDate'] == lDateInt &&
                                            (hw['subject'] == sk ||
                                                hw['subject'] == subject),
                                      ) ||
                                      customHomeworkNotifier.value.any(
                                        (hw) =>
                                            hw['dueDate'] == lDateInt &&
                                            (hw['subject'] == sk ||
                                                hw['subject'] == subject),
                                      );
                                  final hasExam =
                                      apiExamsNotifier.value.any(
                                        (ex) =>
                                            (ex['date'] ??
                                                    ex['examDate'] ??
                                                    0) ==
                                                lDateInt &&
                                            (ex['subject'] == sk ||
                                                ex['subjectName'] == sk ||
                                                ex['subject'] == subject),
                                      ) ||
                                      customExamsNotifier.value.any(
                                        (ex) =>
                                            (ex['date'] ?? 0) == lDateInt &&
                                            (ex['subject'] == sk ||
                                                ex['subject'] == subject),
                                      );

                                  final originalTeacher =
                                      _originalTeachers[_lessonIdentityOf(l)] ??
                                      '';
                                  final lessonTile = GestureDetector(
                                    onTap: () => _showLessonDetail(
                                      context,
                                      l,
                                      originalTeacher: originalTeacher,
                                    ),
                                    onLongPress: () =>
                                        _editLessonTemporarily(l),
                                    child: _buildTimetableLessonCard(
                                      context: context,
                                      isCancelled: isCancelled,
                                      isSubstitution: isSubstitution,
                                      isDark: isDark,
                                      fgColor: fgColor,
                                      bgColor: bgColor,
                                      subject: _displaySubject(
                                        sk.isNotEmpty ? sk : subject,
                                      ),
                                      subjectIcon:
                                          _customSubjectIcon(sk) ??
                                          _subjectIconFor(sk, subject),
                                      teacher: teacher,
                                      room: room,
                                      isNow: isNow,
                                      isTeacherMissing: isTeacherMissing,
                                      hasHomework: hasHomework,
                                      hasExam: hasExam,
                                      originalTeacher: originalTeacher,
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        5,
                                        6,
                                        5,
                                      ),
                                      accentWidth: 3.5,
                                      subjectFontSize: 11.5,
                                      teacherFontSize: 9.5,
                                      roomFontSize: 9.5,
                                      useStripes: true,
                                    ),
                                  );
                                  return _withChangeHighlight(
                                    child: lessonTile,
                                    highlighted: _isHighlightMatch(l),
                                    color: cs.tertiary,
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                        if (showNowLine)
                          Positioned(
                            top: nowTop - 1,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: csG.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: csG.error,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView({
    DateTime? monday,
    Map<int, List<dynamic>>? weekData,
    List<int>? visibleDays,
  }) {
    final wd = weekData ?? _weekData;
    final m = monday ?? _currentMonday;
    final shownDays = visibleDays ?? _visibleGridDays;
    final media = MediaQuery.of(context);
    final topContentPadding = _isExportingTimetable
        ? 10.0
        : media.padding.top + kToolbarHeight + kTextTabBarHeight + 10;

    int globalMin = 480;
    int globalMax = 900;
    for (final dayIndex in shownDays) {
      final day = wd[dayIndex] ?? const <dynamic>[];
      for (final l in day) {
        final s = _toMinutes((l['startTime'] as int?) ?? 480);
        final e = _toMinutes((l['endTime'] as int?) ?? 600);
        if (s < globalMin) globalMin = s;
        if (e > globalMax) globalMax = e;
      }
    }
    globalMin = (globalMin - 15).clamp(0, 23 * 60);
    globalMax = globalMax + 15;

    final totalHeight = (globalMax - globalMin) * _ppm;

    final List<int> ticks = [];
    for (
      int min = globalMin - (globalMin % 60) + 60;
      min < globalMax;
      min += 60
    ) {
      ticks.add(min);
    }

    const double timeColWidth = 40.0;
    const double minDayColWidth = 56.0;
    const double dayColGap = 4.0;
    // Leave a real trailing gutter inside the horizontal viewport. Without
    // it, the Friday column ends exactly at the clip edge on phones and its
    // card border/shadow can be cut off.
    const double trailingDayGridInset = 12.0;
    final visibleWeekData = <int, List<dynamic>>{
      for (final dayIndex in shownDays)
        dayIndex: wd[dayIndex] ?? const <dynamic>[],
    };
    final timeRanges = _collectTimeRangesFromData(visibleWeekData);
    final filteredTimeLabels = _filterTimeLabels(timeRanges);
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();

    final todayDate = DateTime(today.year, today.month, today.day);
    final mondayDate = DateTime(m.year, m.month, m.day);
    final todayIndex = todayDate.difference(mondayDate).inDays;
    final nowMin = today.hour * 60 + today.minute;
    final showNowLine =
        todayIndex >= 0 &&
        shownDays.contains(todayIndex) &&
        nowMin >= globalMin &&
        nowMin <= globalMax;
    final nowTop = (nowMin - globalMin) * _ppm;

    return ExpressiveRefreshIndicator(
      onRefresh: _onRefresh,
      // Keep the indicator directly under the transparent app bar.
      edgeOffset: topContentPadding,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          bottom: 32,
          top: topContentPadding,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dayGridWidth = math.max(
              (shownDays.length * minDayColWidth) +
                  (dayColGap * (shownDays.length - 1)),
              constraints.maxWidth - timeColWidth - 4 - trailingDayGridInset,
            );
            final dayColWidth =
                (dayGridWidth - (dayColGap * (shownDays.length - 1))) /
                shownDays.length;

            // On small screens all day columns cannot fit alongside the time
            // gutter. Keep their minimum readable width and scroll horizontally.
            return SingleChildScrollView(
              key: const ValueKey('week-grid-horizontal-scroll'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: timeColWidth + 4 + dayGridWidth + trailingDayGridInset,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: timeColWidth,
                          height: totalHeight,
                          child: Stack(
                            children: filteredTimeLabels.isNotEmpty
                                ? filteredTimeLabels.map((value) {
                                    final top = (value - globalMin) * _ppm - 9;
                                    return Positioned(
                                      top: top,
                                      left: 0,
                                      right: 0,
                                      child: Text(
                                        _formatMinutes(value),
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurfaceVariant.withValues(
                                            alpha: 0.54,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList()
                                : ticks.map((tick) {
                                    final top = (tick - globalMin) * _ppm - 9;
                                    return Positioned(
                                      top: top,
                                      left: 0,
                                      right: 0,
                                      child: Text(
                                        _formatMinutes(tick),
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurfaceVariant.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(shownDays.length, (
                            visibleIndex,
                          ) {
                            final dayIndex = shownDays[visibleIndex];
                            final lessons = (wd[dayIndex] ?? [])
                                .where(
                                  (l) => !hiddenSubjectsNotifier.value.contains(
                                    l['_subjectShort']?.toString() ?? '',
                                  ),
                                )
                                .toList();
                            final visibleLessons = lessons
                                .where(
                                  (l) =>
                                      showCancelledNotifier.value ||
                                      !isTimetableCancelled(l),
                                )
                                .toList();
                            final mergedLessons = _mergeConsecutiveLessons(
                              visibleLessons,
                            );
                            final lessonSlots = _computeLessonSlots(
                              mergedLessons,
                            );
                            return Container(
                              width: dayColWidth,
                              height: totalHeight,
                              margin: EdgeInsets.only(
                                right: visibleIndex == shownDays.length - 1
                                    ? 0
                                    : dayColGap,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Stack(
                                    children: [
                                      ...ticks.map((tick) {
                                        final top = (tick - globalMin) * _ppm;
                                        return Positioned(
                                          top: top,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 0.45,
                                            color: cs.outlineVariant.withValues(
                                              alpha: 0.28,
                                            ),
                                          ),
                                        );
                                      }),
                                      ..._getHolidaysForDay(
                                        m.add(Duration(days: dayIndex)),
                                      ).map((holiday) {
                                        final holidayStartMin = _toMinutes(800);
                                        final holidayEndMin = _toMinutes(1800);
                                        final top2 =
                                            (holidayStartMin - globalMin) *
                                            _ppm;
                                        final height2 =
                                            ((holidayEndMin - holidayStartMin) *
                                                    _ppm)
                                                .clamp(24.0, 9999.0);
                                        final holidayName =
                                            (holiday['longName'] ??
                                                    holiday['name'] ??
                                                    '')
                                                .toString();
                                        return Positioned(
                                          top: top2,
                                          left: 1,
                                          right: 1,
                                          height: height2,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: cs.tertiaryContainer
                                                  .withValues(alpha: 0.85),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: cs.tertiary.withValues(
                                                  alpha: 0.4,
                                                ),
                                                width: 1.5,
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.celebration_rounded,
                                                  size: 16,
                                                  color: cs.tertiary,
                                                ),
                                                const SizedBox(height: 2),
                                                Expanded(
                                                  child: Text(
                                                    holidayName,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: cs
                                                          .onTertiaryContainer,
                                                    ),
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                      ...lessonSlots.map((slot) {
                                        final l = slot.lesson;
                                        final startMin = slot.startMin;
                                        final endMin = slot.endMin;
                                        final top =
                                            (startMin - globalMin) * _ppm;
                                        final height =
                                            ((endMin - startMin) * _ppm).clamp(
                                              24.0,
                                              9999.0,
                                            );
                                        final dim =
                                            (dayIndex == todayIndex) &&
                                            endMin <= nowMin;
                                        const horizontalInset = 1.0;
                                        const columnGap = 2.0;
                                        final columns = slot.columnCount;
                                        final availableWidth =
                                            constraints.maxWidth -
                                            (horizontalInset * 2);
                                        final totalGap =
                                            (columns - 1) * columnGap;
                                        final rawCardWidth =
                                            (availableWidth - totalGap) /
                                            columns;
                                        final cardWidth = rawCardWidth > 6
                                            ? rawCardWidth
                                            : 6.0;
                                        final left =
                                            horizontalInset +
                                            (slot.column *
                                                (cardWidth + columnGap));

                                        return Positioned(
                                          top: top,
                                          left: left,
                                          width: cardWidth,
                                          height: height,
                                          child: Builder(
                                            builder: (context) {
                                              final cs = Theme.of(
                                                context,
                                              ).colorScheme;
                                              final isDark2 =
                                                  Theme.of(
                                                    context,
                                                  ).brightness ==
                                                  Brightness.dark;
                                              final isCancelled =
                                                  isTimetableCancelled(l);
                                              final isSubstitution =
                                                  isTimetableSubstitution(l);
                                              final isTeacherMissing =
                                                  _hasMissingTeacher(l);
                                              final subject =
                                                  l['_subjectShort']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true
                                                  ? l['_subjectShort']
                                                        .toString()
                                                  : (l['_subjectLong']
                                                                ?.toString()
                                                                .isNotEmpty ==
                                                            true
                                                        ? l['_subjectLong']
                                                              .toString()
                                                        : '?');
                                              final room =
                                                  l['_room']?.toString() ?? '';
                                              final teacher = _displayTeacher(
                                                l,
                                              );
                                              final sk2 =
                                                  l['_subjectShort']
                                                      ?.toString() ??
                                                  '';
                                              final useMonochrome2 =
                                                  monochromeLessonsNotifier
                                                      .value;
                                              final cancelledColor2 = Color(
                                                cancelledLessonColorNotifier
                                                    .value,
                                              );
                                              final cv2 =
                                                  isCancelled || useMonochrome2
                                                  ? null
                                                  : subjectColorsNotifier
                                                        .value[sk2];
                                              final fgColor = isCancelled
                                                  ? cancelledColor2
                                                  : useMonochrome2
                                                  ? Color(
                                                      monochromeLessonColorNotifier
                                                          .value,
                                                    )
                                                  : cv2 != null
                                                  ? Color(cv2)
                                                  : _autoLessonColor(
                                                      sk2,
                                                      isDark2,
                                                    );
                                              final bgColor = isCancelled
                                                  ? Color.alphaBlend(
                                                      cancelledColor2
                                                          .withValues(
                                                            alpha: isDark2
                                                                ? 0.14
                                                                : 0.10,
                                                          ),
                                                      cs.surfaceContainerHighest,
                                                    )
                                                  : Color.alphaBlend(
                                                      fgColor.withValues(
                                                        alpha: isDark2
                                                            ? 0.14
                                                            : 0.10,
                                                      ),
                                                      cs.surfaceContainerHighest,
                                                    );
                                              final isCurrent =
                                                  (dayIndex == todayIndex) &&
                                                  (slot.startMin <= nowMin &&
                                                      nowMin < slot.endMin);
                                              final isNow = isCurrent;

                                              final lDateInt =
                                                  int.tryParse(
                                                    l['date']?.toString() ?? '',
                                                  ) ??
                                                  0;
                                              final hasHomework =
                                                  homeworksNotifier.value.any(
                                                    (hw) =>
                                                        hw['dueDate'] ==
                                                            lDateInt &&
                                                        (hw['subject'] == sk2 ||
                                                            hw['subject'] ==
                                                                subject),
                                                  ) ||
                                                  customHomeworkNotifier.value
                                                      .any(
                                                        (hw) =>
                                                            hw['dueDate'] ==
                                                                lDateInt &&
                                                            (hw['subject'] ==
                                                                    sk2 ||
                                                                hw['subject'] ==
                                                                    subject),
                                                      );
                                              final hasExam =
                                                  apiExamsNotifier.value.any(
                                                    (ex) =>
                                                        (ex['date'] ??
                                                                ex['examDate'] ??
                                                                0) ==
                                                            lDateInt &&
                                                        (ex['subject'] == sk2 ||
                                                            ex['subjectName'] ==
                                                                sk2 ||
                                                            ex['subject'] ==
                                                                subject),
                                                  ) ||
                                                  customExamsNotifier.value.any(
                                                    (ex) =>
                                                        (ex['date'] ?? 0) ==
                                                            lDateInt &&
                                                        (ex['subject'] == sk2 ||
                                                            ex['subject'] ==
                                                                subject),
                                                  );

                                              final originalTeacher =
                                                  _originalTeachers[_lessonIdentityOf(
                                                    l,
                                                  )] ??
                                                  '';
                                              final lessonTile = GestureDetector(
                                                onTap: () =>
                                                    _onLessonTap(context, l),
                                                onLongPress: () =>
                                                    _editLessonTemporarily(l),
                                                child: _buildTimetableLessonCard(
                                                  context: context,
                                                  isCancelled: isCancelled,
                                                  isSubstitution:
                                                      isSubstitution,
                                                  isDark: isDark2,
                                                  fgColor: fgColor,
                                                  bgColor: bgColor,
                                                  subject: _displaySubject(
                                                    sk2.isNotEmpty
                                                        ? sk2
                                                        : subject,
                                                  ),
                                                  subjectIcon:
                                                      _customSubjectIcon(sk2) ??
                                                      _subjectIconFor(
                                                        sk2,
                                                        subject,
                                                      ),
                                                  teacher: teacher,
                                                  room: room,
                                                  isNow: isNow,
                                                  isTeacherMissing:
                                                      isTeacherMissing,
                                                  hasHomework: hasHomework,
                                                  hasExam: hasExam,
                                                  originalTeacher:
                                                      originalTeacher,
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        8,
                                                        5,
                                                        6,
                                                        5,
                                                      ),
                                                  accentWidth: 3.5,
                                                  subjectFontSize: 11.5,
                                                  teacherFontSize: 9.5,
                                                  roomFontSize: 9.5,
                                                  useStripes: true,
                                                  availableWidth: cardWidth,
                                                  availableHeight: height,
                                                ),
                                              );
                                              return _dimPastLesson(
                                                dim: dim,
                                                child: _withChangeHighlight(
                                                  child: lessonTile,
                                                  highlighted:
                                                      _isHighlightMatch(l),
                                                  color: cs.tertiary,
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      }),
                                      if (showNowLine && dayIndex == todayIndex)
                                        Positioned(
                                          top: nowTop - 1.5,
                                          left: 0,
                                          right: 0,
                                          child: IgnorePointer(
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: cs.error,
                                                    shape: BoxShape.circle,
                                                    boxShadow:
                                                        _glowShadows(context, [
                                                          BoxShadow(
                                                            color: cs.error
                                                                .withValues(
                                                                  alpha: 0.35,
                                                                ),
                                                            blurRadius: 3,
                                                            spreadRadius: 0.5,
                                                          ),
                                                        ]),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Container(
                                                    height: 2,
                                                    decoration: BoxDecoration(
                                                      color: cs.error,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            2,
                                                          ),
                                                      boxShadow: _glowShadows(
                                                        context,
                                                        [
                                                          BoxShadow(
                                                            color: cs.error
                                                                .withValues(
                                                                  alpha: 0.25,
                                                                ),
                                                            blurRadius: 3,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _fetchHolidays() async {
    try {
      final holidays = await _timetableRepository.fetchHolidays(
        _timetableRequestContext,
      );
      if (mounted) setState(() => _holidays = holidays);
      if (!demoModeNotifier.value) {
        final accountId = activeUntisAccountId ?? 'legacy';
        final wrapped = SchoolWrappedRepository();
        for (final year in await wrapped.years(accountId)) {
          if (year.contains(DateTime.now())) {
            await wrapped.recordHolidays(
              accountId: accountId,
              year: year,
              holidays: holidays,
            );
          }
        }
      }
    } catch (_) {}
  }

  bool _isSessionExpired() {
    if (_currentSessionId.isEmpty) return true;
    final account = activeUntisAccount;
    if (account == null) return false;
    final age = DateTime.now().difference(account.lastUsedAt);
    return age.inMinutes >= 8;
  }

  Future<void> _fetchFullWeek({bool silent = false}) async {
    final l = appL10nFor(appLocaleNotifier.value);
    final requestGeneration = ++_weekFetchGeneration;
    final requestedMonday = _currentMonday;
    final requestAccountId = activeUntisAccountId ?? 'legacy';
    bool isCurrentRequest() =>
        mounted &&
        requestGeneration == _weekFetchGeneration &&
        (activeUntisAccountId ?? 'legacy') == requestAccountId &&
        _currentMonday == requestedMonday;

    if (personId == 0 && personType == 0) {}

    _holidays = [];

    final isDemoMode = demoModeNotifier.value;

    int requestPersonId = _viewingClassId ?? personId;
    int requestPersonType = _viewingClassId != null ? 1 : personType;

    if (isDemoMode) {
      requestPersonId = DemoModeService.demoPersonId;
      requestPersonType = DemoModeService.demoPersonType;
    }

    if (requestPersonId == 0) {
      if (requestPersonType == 0) requestPersonType = 5;
    }

    if (isDemoMode) {
      final tempWeek = DemoModeService.buildWeek(
        requestedMonday,
        locale: appLocaleNotifier.value,
      );
      _applyKnownSubjectsFromWeek(tempWeek);
      if (!isCurrentRequest()) return;
      setState(() {
        _weekData = tempWeek;
        _showingCachedWeek = false;
        _loading = false;
        _loadError = null;
      });
      currentWeekDataNotifier.value = tempWeek;
      // Demo data is already complete. Persistence, homework and home-widget
      // refreshes must not keep the timetable behind a loading indicator.
      unawaited(_fetchHomeworkAndNotes());
      unawaited(
        _saveWeekToCache(
          requestPersonId: requestPersonId,
          requestPersonType: requestPersonType,
          weekData: tempWeek,
          monday: requestedMonday,
        ),
      );
      unawaited(_updateHomeWidgets(tempWeek));
      return;
    }

    final hasExistingWeek = _weekData.values.any((l) => l.isNotEmpty);
    final cachedWeek = (!silent || !hasExistingWeek)
        ? await _loadWeekFromCache(
            requestPersonId: requestPersonId,
            requestPersonType: requestPersonType,
          )
        : null;
    if (!isCurrentRequest()) return;
    final hasCachedWeek =
        hasExistingWeek ||
        (cachedWeek != null && cachedWeek.values.any((l) => l.isNotEmpty));
    if (cachedWeek != null &&
        cachedWeek.values.any((l) => l.isNotEmpty) &&
        mounted) {
      _applyKnownSubjectsFromWeek(cachedWeek);
      setState(() {
        _weekData = cachedWeek;
        _showingCachedWeek = true;
        _loading = false;
        _loadError = null;
      });
      currentWeekDataNotifier.value = cachedWeek;
      unawaited(_updateHomeWidgets(cachedWeek));
      // Populate the carousel from disk straight away. This avoids showing
      // stale lesson state during the first swipe while the online refresh is
      // still in flight (notably for already cached cancellations).
      unawaited(_prefetchAdjacentWeeks(allowNetwork: false));
    } else if (!silent && mounted && !hasCachedWeek) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    if (_subjectShortMap.isEmpty || _teacherMap.isEmpty || _roomMap.isEmpty) {
      await _loadMasterDataFromCache();
    }

    if ((_currentSessionId.isEmpty || _isSessionExpired()) && !isDemoMode) {
      final ok = await _reAuthenticate();
      if (!ok && !hasCachedWeek) {
        if (!mounted) return;
        setState(() {
          _loadError = l.timetableNotSignedIn;
          _weekData = _emptyWeekData();
          _showingCachedWeek = false;
          _loading = false;
        });
        return;
      }
    }

    final friday = requestedMonday.add(const Duration(days: 4));

    try {
      final timetableFuture = _timetableRepository.fetchTimetable(
        context: _timetableRequestContext,
        elementId: requestPersonId,
        elementType: requestPersonType,
        startDate: requestedMonday,
        endDate: friday,
        requestId: 'week_req',
      );

      await _fetchMasterData();
      if (!isCurrentRequest()) return;
      unawaited(_fetchHomeworkAndNotes());

      final allLessons = await timetableFuture;
      if (!isCurrentRequest()) return;

      Map<int, List<dynamic>> tempWeek = _emptyWeekData();
      final classIdsInWeek = <int>{};

      for (var lesson in allLessons) {
        final lessonDate = parseUntisDate(lesson['date']);
        if (lessonDate != null) {
          final dayIndex = lessonDate.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 5) {
            final subId = (lesson['su'] as List?)?.firstOrNull?['id'] as int?;
            final roId = (lesson['ro'] as List?)?.firstOrNull?['id'] as int?;
            final klId = (lesson['kl'] as List?)?.firstOrNull?['id'] as int?;
            if (klId != null) classIdsInWeek.add(klId);

            final lessonMap = lesson as Map<dynamic, dynamic>;
            final teacherFromTe = _extractTeacherNamesFromLesson(lessonMap);
            final teacherFromTopLevel = _extractTeacherNamesFromTopLevel(
              lessonMap,
            );
            final teacherResolved = teacherFromTe.isNotEmpty
                ? teacherFromTe
                : teacherFromTopLevel;

            final lstext = (lesson['lstext'] ?? '').toString().trim();
            final eventName = lstext.isNotEmpty
                ? lstext
                : (lesson['eventText'] ?? lesson['eventReason'] ?? '')
                      .toString()
                      .trim();
            final isAllDayEvent =
                (lesson['startTime'] == 0 && lesson['endTime'] != null);

            final resolvedLesson = Map<String, dynamic>.from(lesson);
            if (isAllDayEvent) {
              resolvedLesson['startTime'] = 800;
              resolvedLesson['endTime'] = 1800;
            }
            resolvedLesson['_subjectLong'] =
                (lesson['su'] as List?)?.firstOrNull?['longname'] ??
                (lesson['su'] as List?)?.firstOrNull?['longName'] ??
                _subjectLong[subId] ??
                (eventName.isNotEmpty ? eventName : '');
            resolvedLesson['_subjectShort'] =
                (lesson['su'] as List?)?.firstOrNull?['name'] ??
                _subjectShortMap[subId] ??
                (eventName.isNotEmpty ? eventName : '');
            resolvedLesson['_teacher'] = teacherResolved;
            resolvedLesson['_teacherFull'] = _extractTeacherNamesFromLesson(
              lessonMap,
              full: true,
            );
            // WebUntis returns `ro` as either a list, a single map or just an
            // ID depending on the timetable endpoint. Normalize every form so
            // a week fetched after the carousel snap cannot lose room #2.
            final rawRooms = lesson['ro'];
            final roomEntries = rawRooms is Iterable
                ? rawRooms
                : rawRooms == null
                ? const <dynamic>[]
                : <dynamic>[rawRooms];
            final roomNames = roomEntries
                .map((rawRoom) {
                  if (rawRoom is Map) {
                    final id = int.tryParse(rawRoom['id']?.toString() ?? '');
                    return (rawRoom['name']?.toString() ?? _roomMap[id] ?? '')
                        .trim();
                  }
                  final id = int.tryParse(rawRoom.toString());
                  return _roomMap[id] ?? '';
                })
                .where((name) => name.isNotEmpty)
                .toSet()
                .toList(growable: false);
            resolvedLesson['_room'] = roomNames.isNotEmpty
                ? roomNames.join(', ')
                : (_roomMap[roId] ?? '');
            resolvedLesson['_classNames'] =
                (lesson['kl'] as List?)
                    ?.map((k) => k['name']?.toString() ?? '')
                    .where((n) => n.isNotEmpty)
                    .join(', ') ??
                '';
            resolvedLesson['_activityType'] = (lesson['activityType'] ?? '')
                .toString();
            resolvedLesson['_eventName'] = eventName;
            resolvedLesson['_lessonInfo'] =
                (lesson['info'] ?? lesson['substText'] ?? '').toString().trim();
            resolvedLesson['_teacherMissing'] = _hasMissingTeacher(lesson);

            tempWeek[dayIndex]!.add(resolvedLesson);
          }
        }
      }

      tempWeek.forEach((key, list) {
        list.sort((a, b) {
          final aStart = (a['startTime'] as num?)?.toInt() ?? 0;
          final bStart = (b['startTime'] as num?)?.toInt() ?? 0;
          return aStart.compareTo(bStart);
        });
      });

      final missingTeacherLessons = tempWeek.values
          .expand((day) => day)
          .where((l) => ((l['_teacher'] ?? '').toString().trim().isEmpty))
          .toList();
      if (missingTeacherLessons.isNotEmpty) {
        // Resolve the data snapshot before it becomes visible. A week must
        // never repaint merely because its teacher directory arrived later.
        await _resolveMissingTeachers(
          tempWeek: tempWeek,
          missingTeacherLessons: missingTeacherLessons,
          requestGeneration: requestGeneration,
          requestedMonday: requestedMonday,
          requestAccountId: requestAccountId,
          requestPersonId: requestPersonId,
          requestPersonType: requestPersonType,
          startDate: requestedMonday,
          endDate: friday,
          classIdsInWeek: classIdsInWeek,
        );
      }
      if (!isCurrentRequest()) return;
      _applyKnownSubjectsFromWeek(tempWeek);
      setState(() {
        _weekData = tempWeek;
        _showingCachedWeek = false;
        _loading = false;
        _loadError = null;
      });
      currentWeekDataNotifier.value = tempWeek;
      unawaited(_updateHomeWidgets(tempWeek));
      unawaited(_fetchHolidays());

      final flattenedLessons = tempWeek.values
          .expand((day) => day)
          .whereType<Map>();
      if (!isDemoMode && flattenedLessons.isNotEmpty) {
        ChangeRepository()
            .recordSnapshot(
              accountId: requestAccountId,
              rangeKey: untisDateString(requestedMonday),
              lessons: flattenedLessons,
            )
            .then((changes) {
              _applyOriginalTeachers(changes);
              if (isCurrentRequest()) {
                unreadTimetableChangesNotifier.value = changes
                    .where((change) => !change.isRead)
                    .length;
              }
            })
            .catchError((_) {});
      }

      unawaited(
        _saveWeekToCache(
          requestPersonId: requestPersonId,
          requestPersonType: requestPersonType,
          weekData: tempWeek,
          monday: requestedMonday,
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (isCurrentRequest()) {
          _prefetchAdjacentWeeks();
        }
      });
    } on WebUntisFailure catch (e) {
      debugPrint("Fehler beim Laden: $e");
      final apiMsg = e.message;
      final lower = apiMsg.toLowerCase();

      if (lower.contains('not within a school year') ||
          lower.contains('nicht in einem schuljahr')) {
        try {
          final schoolyear = await _timetableRepository.fetchCurrentSchoolyear(
            _timetableRequestContext,
          );
          final schoolyearStart = parseUntisDate(schoolyear?['startDate']);
          if (schoolyearStart != null && isCurrentRequest()) {
            if (_currentMonday.isBefore(schoolyearStart)) {
              _currentMonday = schoolyearStart.subtract(
                Duration(days: schoolyearStart.weekday - 1),
              );
              await _fetchFullWeek(silent: silent);
              return;
            }
          }
        } catch (_) {}
      }

      if (e.rpcCode == -8504 ||
          e.kind == WebUntisFailureKind.authentication ||
          lower.contains('not authenticated')) {
        final ok = await _reAuthenticate();
        if (ok) {
          await _fetchFullWeek(silent: silent);
          return;
        }
      }

      if (!isCurrentRequest()) return;
      if (hasCachedWeek) {
        if (!mounted) return;
        setState(() {
          _loadError = null;
          _showingCachedWeek = true;
          _loading = false;
        });
        return;
      }

      if (_isNoAllowedDateError(apiMsg)) {
        if (!mounted) return;
        setState(() {
          _loadError = null;
          _weekData = _emptyWeekData();
          _showingCachedWeek = false;
          _loading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _loadError = e.statusCode != null
            ? l.timetableHttpError(e.statusCode!)
            : apiMsg;
        _weekData = _emptyWeekData();
        _showingCachedWeek = false;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Fehler beim Laden: $e");
      if (!isCurrentRequest()) return;
      if (hasCachedWeek) {
        if (!mounted) return;
        setState(() {
          _loadError = null;
          _showingCachedWeek = true;
          _loading = false;
        });
        return;
      }

      final errMsg = e.toString();
      if (_isNoAllowedDateError(errMsg)) {
        if (!mounted) return;
        setState(() {
          _loadError = null;
          _weekData = _emptyWeekData();
          _showingCachedWeek = false;
          _loading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _loadError = l.timetableLoadError;
        _weekData = _emptyWeekData();
        _showingCachedWeek = false;
        _loading = false;
      });
    }
  }

  Future<void> _resolveMissingTeachers({
    required Map<int, List<dynamic>> tempWeek,
    required List<dynamic> missingTeacherLessons,
    required int requestGeneration,
    required DateTime requestedMonday,
    required String requestAccountId,
    required int requestPersonId,
    required int requestPersonType,
    required DateTime startDate,
    required DateTime endDate,
    required Set<int> classIdsInWeek,
  }) async {
    bool isCurrent() =>
        mounted &&
        requestGeneration == _weekFetchGeneration &&
        (activeUntisAccountId ?? 'legacy') == requestAccountId &&
        _currentMonday == requestedMonday;

    if (!isCurrent()) return;

    final exactKeyToTeacher = <String, String>{};
    final looseKeyToTeacher = <String, String>{};

    // Fallback 1: Public weekly endpoint often contains teacher IDs in
    // period elements (type=2) even when JSON-RPC omits `te`.
    try {
      final data = await _timetableRepository.fetchPublicWeeklyData(
        context: _timetableRequestContext,
        elementId: requestPersonId,
        elementType: requestPersonType,
        date: requestedMonday,
      );
      if (data != null) {
        final elements = (data['elements'] as List?) ?? const <dynamic>[];
        final teacherNameById = <int, String>{};
        for (final e in elements) {
          if (e is! Map) continue;
          if ((e['type'] as int?) != 2) continue;
          final id = e['id'] as int?;
          if (id == null) continue;
          final n =
              (e['longName'] ??
                      e['longname'] ??
                      e['displayname'] ??
                      e['name'] ??
                      '')
                  .toString()
                  .trim();
          if (n.isNotEmpty) teacherNameById[id] = n;
        }

        final elementPeriods = (data['elementPeriods'] as Map?) ?? const {};
        final periodsForElement = elementPeriods[requestPersonId.toString()];
        final periods = periodsForElement is List
            ? periodsForElement
            : const <dynamic>[];
        for (final p in periods) {
          if (p is! Map) continue;
          final pElements = (p['elements'] as List?) ?? const <dynamic>[];
          int? subjectId;
          int? roomId;
          final teacherNames = <String>[];
          for (final pe in pElements) {
            if (pe is! Map) continue;
            final t = pe['type'] as int?;
            final id = pe['id'] as int?;
            if (t == 3 && id != null) subjectId ??= id;
            if (t == 4 && id != null) roomId ??= id;
            if (t == 2 && id != null) {
              final tn = teacherNameById[id];
              if (tn != null && tn.isNotEmpty && !teacherNames.contains(tn)) {
                teacherNames.add(tn);
              }
            }
          }
          final teacherJoined = teacherNames.join(', ');
          if (teacherJoined.isEmpty || subjectId == null) continue;

          final exactKey = _lessonTeacherKeyFromParts(
            date: p['date'],
            startTime: p['startTime'],
            endTime: p['endTime'],
            subjectId: subjectId,
            roomId: roomId,
            withRoom: true,
          );
          final looseKey = _lessonTeacherKeyFromParts(
            date: p['date'],
            startTime: p['startTime'],
            endTime: p['endTime'],
            subjectId: subjectId,
            withRoom: false,
          );
          exactKeyToTeacher.putIfAbsent(exactKey, () => teacherJoined);
          looseKeyToTeacher.putIfAbsent(looseKey, () => teacherJoined);
        }
      }
    } catch (_) {}

    if (!isCurrent()) return;

    // Fallback 2: Query related class timetables and try key matching.
    final stillMissing = missingTeacherLessons.any((l) {
      if (l is! Map) return false;
      final lMap = Map<dynamic, dynamic>.from(l);
      final exact = exactKeyToTeacher[_lessonTeacherKey(lMap, withRoom: true)];
      final loose = looseKeyToTeacher[_lessonTeacherKey(lMap, withRoom: false)];
      return (exact ?? loose ?? '').isEmpty;
    });

    if (stillMissing && classIdsInWeek.isNotEmpty) {
      final classesToQuery = classIdsInWeek.take(6);
      await Future.wait(
        classesToQuery.map((classId) async {
          try {
            final classLessons = await _timetableRepository.fetchTimetable(
              context: _timetableRequestContext,
              elementId: classId,
              elementType: 1,
              startDate: startDate,
              endDate: endDate,
              requestId: 'week_class_$classId',
            );
            for (final lRaw in classLessons) {
              if (lRaw is! Map) continue;
              final lMap = Map<dynamic, dynamic>.from(lRaw);
              final teacher = _extractTeacherNamesFromLesson(lMap);
              if (teacher.isEmpty) continue;
              exactKeyToTeacher.putIfAbsent(
                _lessonTeacherKey(lMap, withRoom: true),
                () => teacher,
              );
              looseKeyToTeacher.putIfAbsent(
                _lessonTeacherKey(lMap, withRoom: false),
                () => teacher,
              );
            }
          } catch (_) {}
        }),
      );
    }

    if (!isCurrent()) return;

    var updatedAny = false;
    for (final l in missingTeacherLessons) {
      if (l is! Map) continue;
      final lMap = Map<dynamic, dynamic>.from(l);
      final exact = exactKeyToTeacher[_lessonTeacherKey(lMap, withRoom: true)];
      final loose = looseKeyToTeacher[_lessonTeacherKey(lMap, withRoom: false)];
      final fallbackTeacher = exact ?? loose ?? '';
      if (fallbackTeacher.isNotEmpty && l['_teacher'] != fallbackTeacher) {
        l['_teacher'] = fallbackTeacher;
        updatedAny = true;
      }
    }

    // The caller publishes this complete snapshot atomically. Keeping this
    // method mutation-only prevents delayed teacher lookups from refreshing a
    // different week after the user has already switched away.
    if (updatedAny && !isCurrent()) return;
  }

  Future<void> _openClassSearch() async {
    final catalog = await runWithUntisBlockingLoader(context, () async {
      if (demoModeNotifier.value) {
        final classes = DemoModeService.demoClasses()
            .whereType<Map>()
            .map(
              (item) =>
                  item.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList(growable: false);
        return TimetableClassCatalog(classes: classes, sessionId: sessionID);
      }
      return _timetableRepository.fetchClassCatalog(
        WebUntisRequestContext(
          schoolUrl: schoolUrl,
          schoolName: schoolName,
          sessionId: sessionID,
        ),
      );
    });

    final classes = <dynamic>[...catalog.classes];
    final sid = catalog.sessionId;

    if (!mounted) return;

    try {
      if (classes.isNotEmpty) {
        classes.sort(
          (a, b) => (a['name']?.toString() ?? '').compareTo(
            b['name']?.toString() ?? '',
          ),
        );
      }
    } catch (_) {}

    final l = appL10nFor(appLocaleNotifier.value);

    showUntisModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: _kBottomSheetAnimationStyle,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final List<dynamic> sortedClasses = List.from(classes);
            sortedClasses.sort((a, b) {
              final idA = a['id'] as int?;
              final idB = b['id'] as int?;
              final isFavA = idA != null && favoriteClassIds.contains(idA);
              final isFavB = idB != null && favoriteClassIds.contains(idB);
              if (isFavA && !isFavB) return -1;
              if (!isFavA && isFavB) return 1;
              final nameA = (a['name'] ?? a['longName'] ?? '').toString();
              final nameB = (b['name'] ?? b['longName'] ?? '').toString();
              return nameA.compareTo(nameB);
            });

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return _glassContainer(
                  context: ctx,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l.timetableSelectClass,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.classPickerHeaderDesc,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.96),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 0,
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: blurEnabledNotifier.value ? 0.88 : 0.94,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            _expressiveRadius(
                              context,
                              16,
                              expressiveRadius: 28,
                            ),
                          ),
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.58),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.person,
                            color: cs.primary.withValues(alpha: 0.95),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.timetableMyTimetable,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: cs.onSurface.withValues(alpha: 0.99),
                                  ),
                                ),
                              ),
                              if (defaultClassId == null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l.classPickerDefaultBadge,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            tooltip: l.classPickerSetDefault,
                            icon: Icon(
                              defaultClassId == null
                                  ? Icons.home_rounded
                                  : Icons.add_rounded,
                              color: defaultClassId == null
                                  ? cs.primary
                                  : cs.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            onPressed: () async {
                              final prefs = SettingsStore.instance.preferences;
                              setSheetState(() {
                                defaultClassId = null;
                                defaultClassName = null;
                              });
                              await prefs.remove('defaultClassId');
                              await prefs.remove('defaultClassName');
                              setState(() {});
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _viewingClassId = null;
                              _viewingClassName = null;
                              _tempSessionId = null;
                            });
                            Navigator.pop(ctx);
                            _fetchFullWeek();
                          },
                        ),
                      ),
                      if (sortedClasses.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              l.classPickerOtherClasses,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.94,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...sortedClasses.asMap().entries.map((entry) {
                              final i = entry.key;
                              final c = entry.value;
                              final name = (c['name'] ?? c['longName'] ?? '?')
                                  .toString();
                              final id = c['id'] as int?;
                              if (id == null) return const SizedBox.shrink();

                              final isFavorite = favoriteClassIds.contains(id);
                              final isDefault = defaultClassId == id;

                              return _springEntry(
                                duration: Duration(milliseconds: 300 + i * 45),
                                offsetY: 16,
                                startScale: 0.95,
                                curve: _kSmoothBounce,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Card(
                                    elevation: 0,
                                    color: cs.surfaceContainerHigh.withValues(
                                      alpha: blurEnabledNotifier.value
                                          ? 0.86
                                          : 0.92,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        _expressiveRadius(
                                          context,
                                          16,
                                          expressiveRadius: 28,
                                        ),
                                      ),
                                      side: BorderSide(
                                        color: cs.outlineVariant.withValues(
                                          alpha: 0.54,
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        isFavorite
                                            ? Icons.star_rounded
                                            : Icons.class_outlined,
                                        color: isFavorite
                                            ? Colors.amber.shade600
                                            : cs.primary.withValues(
                                                alpha: 0.95,
                                              ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: GoogleFonts.outfit(
                                                fontWeight: isFavorite
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                fontSize: 16,
                                                color: cs.onSurface.withValues(
                                                  alpha: 0.99,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isDefault) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: cs.primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                l.classPickerDefaultBadge,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: cs.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: isFavorite
                                                ? l.classPickerRemoveFavorite
                                                : l.classPickerAddFavorite,
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.star_rounded
                                                  : Icons.star_outline_rounded,
                                              color: isFavorite
                                                  ? Colors.amber.shade600
                                                  : cs.onSurfaceVariant
                                                        .withValues(alpha: 0.6),
                                            ),
                                            onPressed: () async {
                                              final prefs = SettingsStore
                                                  .instance
                                                  .preferences;
                                              setSheetState(() {
                                                if (isFavorite) {
                                                  favoriteClassIds.remove(id);
                                                } else {
                                                  favoriteClassIds.add(id);
                                                }
                                              });
                                              await prefs.setStringList(
                                                'favoriteClassIds',
                                                favoriteClassIds
                                                    .map((id) => id.toString())
                                                    .toList(),
                                              );
                                              setState(() {});
                                            },
                                          ),
                                          IconButton(
                                            tooltip: isDefault
                                                ? l.classPickerDefaultBadge
                                                : l.classPickerSetDefault,
                                            icon: Icon(
                                              isDefault
                                                  ? Icons.home_rounded
                                                  : Icons.add_rounded,
                                              color: isDefault
                                                  ? cs.primary
                                                  : cs.onSurfaceVariant
                                                        .withValues(alpha: 0.6),
                                            ),
                                            onPressed: () async {
                                              final prefs = SettingsStore
                                                  .instance
                                                  .preferences;
                                              setSheetState(() {
                                                if (isDefault) {
                                                  defaultClassId = null;
                                                  defaultClassName = null;
                                                } else {
                                                  defaultClassId = id;
                                                  defaultClassName = name;
                                                }
                                              });
                                              if (defaultClassId == null) {
                                                await prefs.remove(
                                                  'defaultClassId',
                                                );
                                                await prefs.remove(
                                                  'defaultClassName',
                                                );
                                              } else {
                                                await prefs.setInt(
                                                  'defaultClassId',
                                                  defaultClassId!,
                                                );
                                                await prefs.setString(
                                                  'defaultClassName',
                                                  defaultClassName!,
                                                );
                                              }
                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _viewingClassId = id;
                                          _viewingClassName = name;
                                          _tempSessionId = sid != sessionID
                                              ? sid
                                              : null;
                                        });
                                        Navigator.pop(ctx);
                                        _fetchFullWeek();
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            l.timetableNoClassesFound,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openTeacherSearch() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TeacherSearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final dayIndicatorIndex = (_dayCarouselTargetDay ?? _tabController.index)
        .clamp(0, 4)
        .toInt();
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: RoundedBlurAppBar(
        leading: _untisDropdownMenu(
          context: context,
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.person_search_rounded),
              onPressed: _openTeacherSearch,
              child: Text(l.teacherSearchTitle),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.groups_rounded),
              onPressed: _openClassSearch,
              child: Text(l.timetableSelectAnother),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.meeting_room_outlined),
              onPressed: _showFreeRoomsDialog,
              child: Text(l.freeRoomsTitle),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.ios_share_rounded),
              onPressed: _exportTimetableImage,
              child: Text(l.timetableExportImage),
            ),
          ],
          builder: (context, controller, child) => IconButton(
            tooltip: l.timetableMoreActions,
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
        ),
        title: GestureDetector(
          onTap: () {
            final thisMonday = resolveDefaultTimetableMonday(DateTime.now());
            if (_currentMonday != thisMonday) {
              HapticFeedback.selectionClick();
              setState(() => _currentMonday = thisMonday);
              _fetchFullWeek();
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _viewingClassName ?? l.timetableTitle,
                style: untisThemeTextStyle(
                  context,
                  display: true,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.72,
                      end: 1,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _showingCachedWeek
                    ? Semantics(
                        key: const ValueKey('timetable-cache-sync'),
                        label: l.timetableOfflineCache,
                        child: Tooltip(
                          message: l.timetableOfflineCache,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: RotationTransition(
                              turns: _cacheRefreshController,
                              child: Icon(
                                Icons.sync_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(key: ValueKey('timetable-cache-idle')),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: _isDailyView
                  ? l.timetableThreeDayView
                  : _isThreeDayView
                  ? l.timetableWeekView
                  : l.timetableDayGrid,
              icon: Icon(
                _isDailyView
                    ? Icons.view_week_rounded
                    : _isThreeDayView
                    ? Icons.calendar_view_week_rounded
                    : Icons.calendar_view_day_rounded,
              ),
              onPressed: _toggleView,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kTextTabBarHeight),
          child: SizedBox(
            height: kTextTabBarHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AbsorbPointer(
                  absorbing:
                      _isDayCarouselAnimating || _isWeekCarouselAnimating,
                  child: TabBar(
                    controller: _tabController,
                    onTap: _onDayTabBarTap,
                    indicator: const BoxDecoration(),
                    indicatorWeight: 0,
                    labelStyle: untisThemeTextStyle(
                      context,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                    dividerColor: Colors.transparent,
                    tabs: List.generate(5, (i) {
                      final dayDate = _currentMonday.add(Duration(days: i));
                      final dayOverride =
                          _alarmConfig.dateOverrides[alarmDateKey(dayDate)];
                      final now = DateTime.now();
                      final isToday =
                          dayDate.year == now.year &&
                          dayDate.month == now.month &&
                          dayDate.day == now.day;
                      return Tab(
                        child: GestureDetector(
                          key: ValueKey('timetable-day-tab-$i'),
                          behavior: HitTestBehavior.opaque,
                          onLongPress: () {
                            HapticFeedback.mediumImpact();
                            _showDateAlarmActions(dayDate);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _dayShort[i],
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.1,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${dayDate.day}.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.2,
                                      color: isToday
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (dayOverride != null) ...[
                                    const SizedBox(width: 3),
                                    Icon(
                                      dayOverride.disabled
                                          ? Icons.alarm_off_rounded
                                          : dayOverride
                                                    .customTimeOfDayMinutes !=
                                                null
                                          ? Icons.alarm_rounded
                                          : Icons.fast_forward_rounded,
                                      size: 12,
                                      color: dayOverride.disabled
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    ),
                                    if (dayOverride.customTimeOfDayMinutes !=
                                        null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 2),
                                        child: Text(
                                          '${(dayOverride.customTimeOfDayMinutes! ~/ 60).toString().padLeft(2, '0')}:${(dayOverride.customTimeOfDayMinutes! % 60).toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 8,
                                            height: 1,
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                              if (isToday)
                                Container(
                                  width: 3,
                                  height: 3,
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                IgnorePointer(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tabWidth = constraints.maxWidth / 5;
                      return Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            left:
                                (tabWidth * dayIndicatorIndex) +
                                ((tabWidth - 38) / 2),
                            bottom: 0,
                            width: 38,
                            height: 3,
                            child: ColoredBox(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _AnimatedBackground(
        child:
            (_loading &&
                _weekData.values.every((list) => list.isEmpty) &&
                !_showingCachedWeek)
            ? const Center(child: CircularProgressIndicator())
            : (_loadError != null &&
                  _weekData.values.every((list) => list.isEmpty) &&
                  !_showingCachedWeek)
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 80,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.timetableNotLoaded,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.tonal(
                        onPressed: _fetchFullWeek,
                        child: Text(l.reload),
                      ),
                    ],
                  ),
                ),
              )
            : RepaintBoundary(
                key: _timetableExportKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  reverseDuration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.vertical,
                    alignment: Alignment.topCenter,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_viewMode),
                    child: _buildTimetableSwitcher(),
                  ),
                ),
              ),
      ),
    );
  }
}
