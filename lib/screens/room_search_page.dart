part of '../main.dart';

class RoomSearchPage extends StatefulWidget {
  const RoomSearchPage({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<RoomSearchPage> createState() => _RoomSearchPageState();
}

class _TimeSlot {
  const _TimeSlot({
    required this.startMin,
    required this.endMin,
    required this.label,
  });

  final int startMin;
  final int endMin;
  final String label;

  String get timeLabel => '${_formatTime(startMin)} – ${_formatTime(endMin)}';

  static String _formatTime(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _RoomSearchPageState extends State<RoomSearchPage> {
  late final WebUntisRequestContext _requestContext;
  final RoomSearchService _roomSearchService = RoomSearchService();
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<SchoolRoom> _rooms = [];
  Map<int, List<dynamic>> _fallbackLessonsByRoomId = const {};
  bool _usingClassFallback = false;
  int _fallbackScannedClasses = 0;

  Timer? _clockTimer;
  bool _loadingRooms = true;
  bool _loadingSchedule = false;
  String? _roomError;
  String? _scheduleError;

  SchoolRoom? _selectedRoom;
  List<dynamic> _selectedRoomLessons = const [];

  bool _onlyFree = false;
  int _selectedSlotIndex = 0;
  List<_TimeSlot> _timeSlots = const [];

  AppL10n get _l => appL10nFor(appLocaleNotifier.value);
  DateTime get _now => widget.initialDate ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _requestContext = WebUntisRequestContext(
      schoolUrl: schoolUrl,
      schoolName: schoolName,
      sessionId: sessionID,
    );
    _queryController.addListener(_onQueryChanged);
    _initTimeSlots();
    if (widget.initialDate == null) {
      _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) return;
        _updateActiveSlotIfToday();
        setState(() {});
      });
    }
    unawaited(_loadRooms());
  }

  void _onQueryChanged() {
    if (mounted) setState(() {});
  }

  void _initTimeSlots() {
    // Standard school periods
    const standardPeriods = [
      (475, 520), // 07:55 - 08:40
      (525, 570), // 08:45 - 09:30
      (585, 630), // 09:45 - 10:30
      (635, 680), // 10:35 - 11:20
      (695, 740), // 11:35 - 12:20
      (745, 790), // 12:25 - 13:10
      (810, 855), // 13:30 - 14:15
      (860, 905), // 14:20 - 15:05
      (910, 955), // 15:10 - 15:55
    ];

    _timeSlots = [
      for (var i = 0; i < standardPeriods.length; i++)
        _TimeSlot(
          startMin: standardPeriods[i].$1,
          endMin: standardPeriods[i].$2,
          label: _l.roomSearchPeriod(i + 1),
        ),
    ];
    _updateActiveSlotIfToday();
  }

  void _updateActiveSlotIfToday() {
    final now = _now;
    final nowMin = now.hour * 60 + now.minute;
    final activeIdx = _timeSlots.indexWhere(
      (slot) => nowMin >= slot.startMin && nowMin < slot.endMin,
    );
    if (activeIdx >= 0) {
      _selectedSlotIndex = activeIdx;
    }
  }

  Future<void> _loadRooms({bool manualRefresh = false}) async {
    if (demoModeNotifier.value) {
      final demoList =
          DemoModeService.demoRooms().map(SchoolRoom.fromJson).toList()..sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          );

      final demoLessons = <int, List<dynamic>>{};
      for (final r in demoList) {
        demoLessons[r.id] = DemoModeService.demoRoomLessons(
          roomId: r.id,
          date: _now,
        );
      }

      setState(() {
        _rooms
          ..clear()
          ..addAll(demoList);
        _fallbackLessonsByRoomId = demoLessons;
        _loadingRooms = false;
        _roomError = null;
      });
      return;
    }

    if (_requestContext.schoolUrl.isEmpty ||
        _requestContext.schoolName.isEmpty) {
      setState(() {
        _loadingRooms = false;
        _roomError = _l.roomSearchNotSignedIn;
      });
      return;
    }

    setState(() {
      _loadingRooms = true;
      _roomError = null;
    });

    if (!manualRefresh) {
      try {
        final cached = await _roomSearchService.read(
          accountId: activeUntisAccountId ?? 'legacy',
          context: _requestContext,
          date: _now,
        );
        if (cached != null && cached.rooms.isNotEmpty) {
          _applyIndex(cached);
          return;
        }
      } catch (_) {}
    }

    try {
      final index = await _roomSearchService.refresh(
        accountId: activeUntisAccountId ?? 'legacy',
        context: _requestContext,
        date: _now,
      );
      _applyIndex(index);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingRooms = false;
        if (_rooms.isEmpty) {
          _roomError = error is WebUntisFailure
              ? _failureText(error)
              : _l.roomSearchLoadError;
        }
      });
      if (manualRefresh && _rooms.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l.roomSearchLoadError)));
      }
    }
  }

  void _applyIndex(RoomSearchIndex index) {
    if (!mounted) return;
    setState(() {
      _rooms
        ..clear()
        ..addAll(index.rooms);
      _fallbackLessonsByRoomId = index.lessonsByRoomId;
      _fallbackScannedClasses = index.scannedClasses;
      _usingClassFallback = index.scannedClasses > 0;
      _loadingRooms = false;
      _roomError = index.rooms.isEmpty ? _l.roomSearchUnavailable : null;
    });
  }

  Future<void> _selectRoom(SchoolRoom room) async {
    _searchFocusNode.unfocus();
    if (demoModeNotifier.value) {
      setState(() {
        _selectedRoom = room;
        _selectedRoomLessons =
            _fallbackLessonsByRoomId[room.id] ?? const <dynamic>[];
        _scheduleError = null;
        _loadingSchedule = false;
      });
      return;
    }

    if (_usingClassFallback && _fallbackLessonsByRoomId.containsKey(room.id)) {
      setState(() {
        _selectedRoom = room;
        _selectedRoomLessons = _fallbackLessonsByRoomId[room.id] ?? const [];
        _scheduleError = null;
        _loadingSchedule = false;
      });
      return;
    }

    setState(() {
      _selectedRoom = room;
      _selectedRoomLessons = const [];
      _scheduleError = null;
      _loadingSchedule = true;
    });

    try {
      final lessons = await _roomSearchService.fetchRoomTimetable(
        context: _requestContext,
        roomId: room.id,
        date: _now,
      );
      if (!mounted || _selectedRoom?.id != room.id) return;
      setState(() {
        _selectedRoomLessons = lessons;
        _loadingSchedule = false;
      });
    } on WebUntisFailure catch (failure) {
      if (!mounted || _selectedRoom?.id != room.id) return;
      if (failure.kind == WebUntisFailureKind.unsupported ||
          failure.kind == WebUntisFailureKind.permission) {
        setState(() {
          _selectedRoomLessons =
              _fallbackLessonsByRoomId[room.id] ?? const <dynamic>[];
          _loadingSchedule = false;
          _scheduleError = null;
        });
        return;
      }
      setState(() {
        _loadingSchedule = false;
        _scheduleError = _failureText(failure);
      });
    } catch (_) {
      if (!mounted || _selectedRoom?.id != room.id) return;
      setState(() {
        _selectedRoomLessons =
            _fallbackLessonsByRoomId[room.id] ?? const <dynamic>[];
        _loadingSchedule = false;
        _scheduleError = null;
      });
    }
  }

  Future<void> _refreshSearch() async {
    final selectedId = _selectedRoom?.id;
    await _loadRooms(manualRefresh: true);
    if (!mounted || selectedId == null || _roomError != null) return;
    final selected = _rooms.where((r) => r.id == selectedId);
    if (selected.isNotEmpty) {
      await _selectRoom(selected.first);
    }
  }

  String _failureText(WebUntisFailure failure) => switch (failure.kind) {
    WebUntisFailureKind.authentication => _l.roomSearchNotSignedIn,
    WebUntisFailureKind.permission => _l.roomSearchNoPermission,
    WebUntisFailureKind.unsupported => _l.roomSearchUnavailable,
    WebUntisFailureKind.offline ||
    WebUntisFailureKind.timeout => _l.roomSearchNetworkError,
    _ => _l.roomSearchLoadError,
  };

  _TimeSlot get _currentSlot =>
      _timeSlots.isNotEmpty && _selectedSlotIndex < _timeSlots.length
      ? _timeSlots[_selectedSlotIndex]
      : _TimeSlot(startMin: 480, endMin: 525, label: _l.roomSearchPeriod(1));

  RoomScheduleSnapshot _snapshotForRoom(SchoolRoom room) {
    final lessons =
        _selectedRoom?.id == room.id && _selectedRoomLessons.isNotEmpty
        ? _selectedRoomLessons
        : (_fallbackLessonsByRoomId[room.id] ?? const <dynamic>[]);
    return RoomScheduleSnapshot.fromLessons(lessons, now: _now);
  }

  List<SchoolRoom> get _filteredRooms {
    final query = _queryController.text;
    final slot = _currentSlot;

    final matched = _rooms.where((r) => r.matches(query)).toList();

    // Partition into free and occupied for selected slot
    final freeRooms = <SchoolRoom>[];
    final occupiedRooms = <SchoolRoom>[];

    for (final room in matched) {
      final snapshot = _snapshotForRoom(room);
      final isFree = snapshot.isFreeDuring(slot.startMin, slot.endMin);
      if (isFree) {
        freeRooms.add(room);
      } else {
        occupiedRooms.add(room);
      }
    }

    freeRooms.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    occupiedRooms.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );

    if (_onlyFree) {
      return freeRooms;
    }
    return [...freeRooms, ...occupiedRooms];
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _queryController
      ..removeListener(_onQueryChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = _l;
    final cs = Theme.of(context).colorScheme;
    final selected = _selectedRoom;
    final filtered = _filteredRooms;
    final slot = _currentSlot;

    final searchHeight =
        math.max(56.0, MediaQuery.textScalerOf(context).scale(24) + 32) + 20;
    final slotBarHeight = 52.0;
    final totalHeaderHeight = searchHeight + slotBarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: RoundedBlurAppBar(
        title: Text(l.roomSearchTitle),
        actions: [
          IconButton(
            tooltip: l.roomSearchRefreshAll,
            onPressed:
                _loadingRooms ||
                    _loadingSchedule ||
                    (!demoModeNotifier.value &&
                        _requestContext.sessionId.isEmpty)
                ? null
                : () {
                    AppHaptics.selection();
                    unawaited(_refreshSearch());
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(totalHeaderHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _queryController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onTap: AppHaptics.selection,
                  decoration: InputDecoration(
                    hintText: l.roomSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _queryController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l.roomSearchClear,
                            onPressed: () {
                              AppHaptics.selection();
                              _queryController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: slotBarHeight,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  children: [
                    FilterChip(
                      label: Text(l.roomSearchOnlyFree),
                      selected: _onlyFree,
                      onSelected: (val) {
                        AppHaptics.selection();
                        setState(() => _onlyFree = val);
                      },
                    ),
                    const SizedBox(width: 8),
                    for (int i = 0; i < _timeSlots.length; i++) ...[
                      ChoiceChip(
                        label: Text(_timeSlots[i].label),
                        selected: i == _selectedSlotIndex,
                        onSelected: (_) {
                          AppHaptics.selection();
                          setState(() => _selectedSlotIndex = i);
                        },
                      ),
                      if (i < _timeSlots.length - 1) const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top +
                kToolbarHeight +
                totalHeaderHeight +
                12,
            16,
            24,
          ),
          children: [
            if (_loadingRooms) const LinearProgressIndicator(),
            if (_usingClassFallback)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.roomSearchClassFallback(_fallbackScannedClasses),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            if (_roomError != null)
              _messageState(_roomError!, cs)
            else if (!_loadingRooms) ...[
              if (selected != null) ...[
                _buildRoomDetailCard(selected, cs, l, slot),
                const SizedBox(height: 14),
              ],
              if (filtered.isEmpty)
                _messageState(l.roomSearchNoMatch, cs)
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l.roomSearchResults(filtered.length),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        slot.timeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final room in filtered)
                  _buildRoomCard(
                    room,
                    cs,
                    l,
                    slot,
                    isSelected: selected?.id == room.id,
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(
    SchoolRoom room,
    ColorScheme cs,
    AppL10n l,
    _TimeSlot slot, {
    required bool isSelected,
  }) {
    final snapshot = _snapshotForRoom(room);
    final isFree = snapshot.isFreeDuring(slot.startMin, slot.endMin);
    final activeLesson = snapshot.lessonDuring(slot.startMin, slot.endMin);

    final subtitleParts = <String>[
      if (room.building.isNotEmpty) room.building,
      if (activeLesson != null) ...[
        if (activeLesson.subject.isNotEmpty) activeLesson.subject,
        if (activeLesson.teacher.isNotEmpty) activeLesson.teacher,
      ],
    ];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? cs.secondaryContainer : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: isSelected ? 0.75 : 0.45),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isFree
              ? Colors.green.withValues(alpha: 0.15)
              : cs.primaryContainer,
          foregroundColor: isFree
              ? Colors.green.shade700
              : cs.onPrimaryContainer,
          child: const Icon(Icons.meeting_room_rounded),
        ),
        title: Text(
          room.displayName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        subtitle: subtitleParts.isEmpty
            ? null
            : Text(
                subtitleParts.join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isFree
                    ? Colors.green.withValues(alpha: 0.16)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isFree ? l.roomSearchStatusFree : l.roomSearchStatusOccupied,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isFree ? Colors.green.shade800 : cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: () => _selectRoom(room),
      ),
    );
  }

  Widget _buildRoomDetailCard(
    SchoolRoom room,
    ColorScheme cs,
    AppL10n l,
    _TimeSlot slot,
  ) {
    final snapshot = _loadingSchedule || _scheduleError != null
        ? null
        : _snapshotForRoom(room);
    final isFreeInSlot =
        snapshot?.isFreeDuring(slot.startMin, slot.endMin) ?? false;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (room.building.isNotEmpty)
                        Text(
                          room.building,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isFreeInSlot
                        ? Colors.green.withValues(alpha: 0.16)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isFreeInSlot
                        ? l.roomSearchStatusFree
                        : l.roomSearchStatusOccupied,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isFreeInSlot
                          ? Colors.green.shade800
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l.roomSearchTimetableNote,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (_loadingSchedule) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ] else if (_scheduleError != null) ...[
              const SizedBox(height: 14),
              Text(_scheduleError!, style: TextStyle(color: cs.error)),
            ] else if (snapshot != null) ...[
              const SizedBox(height: 12),
              if (snapshot.current != null)
                _roomLessonTile(
                  icon: Icons.meeting_room_rounded,
                  title: l.roomSearchCurrent,
                  lesson: snapshot.current!,
                  detail: l.teacherSearchUntil(snapshot.current!.endTime),
                  colors: cs,
                ),
              if (snapshot.next != null) ...[
                if (snapshot.current != null) const SizedBox(height: 8),
                _roomLessonTile(
                  icon: Icons.arrow_forward_rounded,
                  title: l.roomSearchNext,
                  lesson: snapshot.next!,
                  detail: l.teacherSearchFrom(snapshot.next!.startTime),
                  colors: cs,
                ),
              ],
              if (snapshot.current == null && snapshot.next == null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    l.roomSearchNoLessons,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              else if (snapshot.current == null && snapshot.next != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.roomSearchFreeNow,
                          style: TextStyle(color: Colors.green.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roomLessonTile({
    required IconData icon,
    required String title,
    required RoomLessonLocation lesson,
    required String detail,
    required ColorScheme colors,
  }) {
    final details = <String>[
      if (lesson.subject.isNotEmpty) lesson.subject,
      if (lesson.teacher.isNotEmpty) lesson.teacher,
      if (lesson.className.isNotEmpty) lesson.className,
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colors.primary),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      subtitle: Text([if (details.isNotEmpty) details, detail].join('\n')),
      isThreeLine: details.isNotEmpty,
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
}
