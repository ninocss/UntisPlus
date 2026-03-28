import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart' as url_launcher;
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'l10n.dart';
import 'core/time_utils.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'widgets/rounded_blur_app_bar.dart';

part 'core/school_models.dart';
part 'app/untis_plus_app.dart';
part 'core/shared_ui.dart';
part 'core/app_state.dart';
part 'screens/onboarding_flow.dart';
part 'screens/main_navigation_screen.dart';
part 'widgets/animated_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  BackgroundService.initialize();

  await Future.wait([
    initializeDateFormatting('de_DE', null),
    initializeDateFormatting('en_US', null),
    initializeDateFormatting('fr_FR', null),
    initializeDateFormatting('es_ES', null),
  ]);

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.containsKey('sessionId');

  if (isLoggedIn) {
    sessionID = prefs.getString('sessionId') ?? "";
    schoolUrl = prefs.getString('schoolUrl') ?? "";
    schoolName = prefs.getString('schoolName') ?? "";
    personType = prefs.getInt('personType') ?? 0;
    personId = prefs.getInt('personId') ?? 0;
  }
  appLocaleNotifier.value = prefs.getString('appLocale') ?? 'de';
  themeModeNotifier.value = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
  showCancelledNotifier.value = prefs.getBool('showCancelled') ?? true;
  backgroundAnimationsNotifier.value =
      prefs.getBool('backgroundAnimations') ?? true;
  backgroundAnimationStyleNotifier.value =
      (prefs.getInt('backgroundAnimationStyle') ?? 0).clamp(0, 5);
  blurEnabledNotifier.value = prefs.getBool('blurEnabled') ?? true;

  hiddenSubjectsNotifier.value = (prefs.getStringList('hiddenSubjects') ?? [])
      .toSet();
  try {
    final colorsJson = prefs.getString('subjectColors');
    if (colorsJson != null) {
      final decoded = jsonDecode(colorsJson) as Map<String, dynamic>;
      subjectColorsNotifier.value = decoded.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      );
    }
  } catch (_) {}

  geminiApiKey = prefs.getString('geminiApiKey') ?? '';
  if (geminiApiKey.isEmpty) {
    final legacy = prefs.getString('openAiApiKey') ?? '';
    if (legacy.isNotEmpty) {
      geminiApiKey = legacy;
      await prefs.setString('geminiApiKey', legacy);
      await prefs.remove('openAiApiKey');
    }
  }

  runApp(
    UntisPlusApp(
      startScreen: isLoggedIn
          ? const MainNavigationScreen()
          : const OnboardingFlow(),
    ),
  );
}

Uri _webUntisRpcUri({String? serverUrl, String? school}) {
  final resolvedServer = serverUrl ?? schoolUrl;
  final resolvedSchool = school ?? schoolName;
  return Uri.parse(
    'https://$resolvedServer/WebUntis/jsonrpc.do?school=$resolvedSchool',
  );
}

Future<Map<String, dynamic>?> _authenticateUntis({
  required String user,
  required String password,
  required String client,
  String requestId = 'auth',
  String? serverUrl,
  String? school,
}) async {
  final response = await http.post(
    _webUntisRpcUri(serverUrl: serverUrl, school: school),
    body: jsonEncode({
      'id': requestId,
      'method': 'authenticate',
      'params': {'user': user, 'password': password, 'client': client},
      'jsonrpc': '2.0',
    }),
  );

  if (response.statusCode != 200 || response.body.trim().isEmpty) {
    return null;
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final result = decoded['result'];
  if (result is Map<String, dynamic>) {
    return result;
  }
  if (result is Map) {
    return Map<String, dynamic>.from(result);
  }
  return null;
}

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

class _WeeklyTimetablePageState extends State<WeeklyTimetablePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<int, List<dynamic>> _weekData = {0: [], 1: [], 2: [], 3: [], 4: []};
  bool _loading = true;
  String? _loadError;
  bool _showingCachedWeek = false;
  int _viewMode = 0;

  String? _tempSessionId;
  int? _viewingClassId;
  String? _viewingClassName;

  String get _currentSessionId =>
      (_viewingClassId != null && _tempSessionId != null)
      ? _tempSessionId!
      : sessionID;

  static const double _ppm = 1.5;

  List<String> get _dayShort =>
      AppL10n.of(appLocaleNotifier.value).weekDayShort;

  final Map<int, String> _subjectLong = {};
  final Map<int, String> _subjectShortMap = {};
  final Map<int, String> _teacherMap = {};
  final Map<int, String> _roomMap = {};

  String _weekCacheKey({
    required int requestPersonId,
    required int requestPersonType,
  }) {
    final monday = DateFormat('yyyyMMdd').format(_currentMonday);
    return [
      'weekCacheV1',
      schoolUrl,
      schoolName,
      requestPersonType.toString(),
      requestPersonId.toString(),
      monday,
    ].join('|');
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
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _weekCacheKey(
        requestPersonId: requestPersonId,
        requestPersonType: requestPersonType,
      );
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
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
          final aStart = (a['startTime'] as int?) ?? 0;
          final bStart = (b['startTime'] as int?) ?? 0;
          return aStart.compareTo(bStart);
        });
      });

      return tempWeek;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveWeekToCache({
    required int requestPersonId,
    required int requestPersonType,
    required Map<int, List<dynamic>> weekData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _weekCacheKey(
        requestPersonId: requestPersonId,
        requestPersonType: requestPersonType,
      );
      final payload = {
        'savedAt': DateTime.now().toIso8601String(),
        'weekData': {
          for (var i = 0; i < 5; i++) '$i': weekData[i] ?? const <dynamic>[],
        },
      };
      await prefs.setString(key, jsonEncode(payload));
    } catch (_) {}
  }

  String _extractTeacherNamesFromLesson(Map<dynamic, dynamic> lesson) {
    final teacherEntries = ((lesson['te'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .cast<Map<dynamic, dynamic>>()
        .toList();
    final teacherParts = <String>[];
    for (final te in teacherEntries) {
      final teId = te['id'] as int?;
      final mapped = teId != null ? _teacherMap[teId] : null;
      final direct =
          (te['longName'] ??
                  te['longname'] ??
                  te['displayName'] ??
                  te['fullName'] ??
                  te['name'] ??
                  '')
              .toString()
              .trim();
      final candidate = (mapped?.trim().isNotEmpty == true)
          ? mapped!.trim()
          : direct;
      if (candidate.isNotEmpty && !teacherParts.contains(candidate)) {
        teacherParts.add(candidate);
      }
    }
    return teacherParts.join(', ');
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
        ? ((lesson['ro'] as List?)?.firstOrNull?['id']?.toString() ?? '')
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

  Future<void> _fetchMasterData() async {
    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );
    final headers = {
      "Cookie": "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
      "Content-Type": "application/json",
    };

    Future<Map<String, dynamic>> rpc(String id, String method) async {
      final r = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "id": id,
          "method": method,
          "params": {},
          "jsonrpc": "2.0",
        }),
      );
      return jsonDecode(r.body) as Map<String, dynamic>;
    }

    final results = await Future.wait([
      rpc("sub", "getSubjects"),
      rpc("tea", "getTeachers"),
      rpc("roo", "getRooms"),
    ]);

    for (var s in (results[0]['result'] as List? ?? [])) {
      final id = s['id'] as int?;
      if (id != null) {
        _subjectLong[id] = (s['longName'] ?? s['longname'] ?? s['name'] ?? '')
            .toString();
        _subjectShortMap[id] = (s['name'] ?? '').toString();
      }
    }
    for (var t in (results[1]['result'] as List? ?? [])) {
      final id = t['id'] as int?;
      if (id != null) {
        final fore = (t['foreName'] ?? t['forename'] ?? '').toString().trim();
        final last = (t['longName'] ?? t['name'] ?? '').toString().trim();
        _teacherMap[id] = fore.isNotEmpty ? '$fore $last' : last;
      }
    }
    for (var r in (results[2]['result'] as List? ?? [])) {
      final id = r['id'] as int?;
      if (id != null) {
        _roomMap[id] = (r['name'] ?? '').toString();
      }
    }
  }

  DateTime _currentMonday = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: (DateTime.now().weekday - 1).clamp(0, 4),
    );
    hiddenSubjectsNotifier.addListener(_onHiddenSubjectsChanged);
    subjectColorsNotifier.addListener(_onHiddenSubjectsChanged);
    showCancelledNotifier.addListener(_onHiddenSubjectsChanged);
    if (sessionID.isNotEmpty) _fetchFullWeek();
    _loadViewPref();
  }

  Future<void> _loadViewPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _viewMode = (prefs.getInt('viewMode') ?? 0).clamp(0, 1));
    }
  }

  void _prevWeek() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonday = _currentMonday.subtract(const Duration(days: 7));
    });
    _fetchFullWeek();
  }

  void _nextWeek() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonday = _currentMonday.add(const Duration(days: 7));
    });
    _fetchFullWeek();
  }

  void _onSwipeLeft() {
    if (_tabController.index < 4) {
      HapticFeedback.selectionClick();
      _tabController.animateTo(_tabController.index + 1);
    } else {
      HapticFeedback.selectionClick();
      _nextWeek();
      _tabController.animateTo(0, duration: Duration.zero);
    }
  }

  void _onSwipeRight() {
    if (_tabController.index > 0) {
      HapticFeedback.selectionClick();
      _tabController.animateTo(_tabController.index - 1);
    } else {
      HapticFeedback.selectionClick();
      _prevWeek();
      _tabController.animateTo(4, duration: Duration.zero);
    }
  }

  Future<void> _toggleView() async {
    HapticFeedback.selectionClick();
    setState(() => _viewMode = (_viewMode + 1) % 2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('viewMode', _viewMode);
  }

  Future<void> _onRefresh() => _fetchFullWeek(silent: true);

  void _onHiddenSubjectsChanged() => setState(() {});

  @override
  void dispose() {
    hiddenSubjectsNotifier.removeListener(_onHiddenSubjectsChanged);
    subjectColorsNotifier.removeListener(_onHiddenSubjectsChanged);
    showCancelledNotifier.removeListener(_onHiddenSubjectsChanged);
    _tabController.dispose();
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

  List<_TimeRangeLabel> _collectTimeRangesFromWeek() {
    final seen = <String>{};
    final ranges = <_TimeRangeLabel>[];
    for (final day in _weekData.values) {
      final visibleDayLessons = day
          .where(
            (l) => !hiddenSubjectsNotifier.value.contains(
              l['_subjectShort']?.toString() ?? '',
            ),
          )
          .where(
            (l) =>
                showCancelledNotifier.value || (l['code'] ?? '') != 'cancelled',
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
      if ((map['code'] ?? '') == 'cancelled') continue;
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

  List<String> _findFreeRooms({
    required int dayIndex,
    required int startMin,
    required int endMin,
  }) {
    final occupiedIds = <int>{};
    final lessons = _weekData[dayIndex] ?? const <dynamic>[];

    for (final raw in lessons.whereType<Map>()) {
      final lesson = raw.cast<dynamic, dynamic>();
      if ((lesson['code'] ?? '') == 'cancelled') continue;

      final lessonStart = _lessonStartMinutes(lesson);
      final lessonEnd = _lessonEndMinutes(lesson);
      final overlaps = lessonStart < endMin && lessonEnd > startMin;
      if (!overlaps) continue;

      occupiedIds.addAll(_lessonRoomIds(lesson));
    }

    final freeRooms = <String>[];
    final seenNames = <String>{};
    final sortedEntries = _roomMap.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    for (final entry in sortedEntries) {
      if (occupiedIds.contains(entry.key)) continue;
      final name = entry.value.trim();
      if (name.isEmpty) continue;
      final normalized = name.toLowerCase();
      if (seenNames.add(normalized)) {
        freeRooms.add(name);
      }
    }

    return freeRooms;
  }

  Future<void> _showFreeRoomsDialog() async {
    final l = AppL10n.of(appLocaleNotifier.value);
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

    int selectedIndex = 0;
    final dayDate = _currentMonday.add(Duration(days: dayIndex));
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

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: _kBottomSheetAnimationStyle,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            final selectedRange = ranges[selectedIndex];
            final freeRooms = _findFreeRooms(
              dayIndex: dayIndex,
              startMin: selectedRange.startMin,
              endMin: selectedRange.endMin,
            );
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
                          '$dayName • ${_formatMinutes(selectedRange.startMin)} - ${_formatMinutes(selectedRange.endMin)}',
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
                                label: Text(
                                  '${_formatMinutes(ranges[i].startMin)} - ${_formatMinutes(ranges[i].endMin)}',
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
                              color: cs.surfaceContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              l.freeRoomsNoneFound,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
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
                                  color: cs.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: cs.outlineVariant.withOpacity(0.35),
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
    if (!dim) return child;
    return Opacity(
      opacity: 0.45,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: child,
      ),
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

  Widget _buildGridView(int dayIndex) {
    final media = MediaQuery.of(context);
    final topContentPadding =
        media.padding.top + kToolbarHeight + kTextTabBarHeight + 10;

    final lessons = (_weekData[dayIndex] ?? [])
        .where(
          (l) => !hiddenSubjectsNotifier.value.contains(
            l['_subjectShort']?.toString() ?? '',
          ),
        )
        .toList();

    int globalMin = 480;
    int globalMax = 1200;
    for (final day in _weekData.values) {
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

    const double timeColWidth = 56;
    final timeRanges = _collectTimeRangesFromWeek();

    final now = DateTime.now();
    final dayDate = _currentMonday.add(Duration(days: dayIndex));
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
              showCancelledNotifier.value || (l['code'] ?? '') != 'cancelled',
        )
        .toList();
    final mergedLessons = _mergeConsecutiveLessons(visibleLessons);
    final lessonSlots = _computeLessonSlots(mergedLessons);

    final csG = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _onRefresh,
      displacement: 40,
      edgeOffset: topContentPadding,
      color: csG.onPrimaryContainer,
      backgroundColor: csG.primaryContainer,
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
                children: timeRanges.isNotEmpty
                    ? timeRanges.map((range) {
                        final top = (range.startMin - globalMin) * _ppm;
                        final blockHeight =
                            ((range.endMin - range.startMin) * _ppm).clamp(
                              18.0,
                              9999.0,
                            );
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          height: blockHeight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatMinutes(range.startMin),
                                textAlign: TextAlign.right,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: csG.onSurfaceVariant.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                _formatMinutes(range.endMin),
                                textAlign: TextAlign.right,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: csG.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ),
                            ],
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
                              fontWeight: FontWeight.w600,
                              color: csG.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(width: 6),
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
                              height: 0.5,
                              color: csG.outlineVariant.withOpacity(0.6),
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
                          final isCancelled = (l['code'] ?? '') == 'cancelled';
                          final subject =
                              l['_subjectShort']?.toString().isNotEmpty == true
                              ? l['_subjectShort'].toString()
                              : (l['_subjectLong']?.toString().isNotEmpty ==
                                        true
                                    ? l['_subjectLong'].toString()
                                    : '?');
                          final room = l['_room']?.toString() ?? '';
                          final teacher = l['_teacher']?.toString() ?? '';

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

                          final cs = Theme.of(context).colorScheme;
                          final sk = l['_subjectShort']?.toString() ?? '';
                          final cv = isCancelled
                              ? null
                              : subjectColorsNotifier.value[sk];
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          final fgColor = isCancelled
                              ? cs.error
                              : cv != null
                              ? Color(cv)
                              : _autoLessonColor(sk, isDark);
                          final bgColor = isCancelled
                              ? cs.errorContainer
                              : fgColor.withOpacity(isDark ? 0.28 : 0.20);

                          return Positioned(
                            top: top,
                            left: left,
                            width: cardWidth,
                            height: height,
                            child: _dimPastLesson(
                              dim: dim,
                              child: GestureDetector(
                                onTap: () => _showLessonDetail(context, l),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border(
                                      left: BorderSide(
                                        color: fgColor,
                                        width: 3.5,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    7,
                                    4,
                                    5,
                                    4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        subject,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: fgColor,
                                          decoration: isCancelled
                                              ? TextDecoration.lineThrough
                                              : null,
                                          decorationColor: fgColor,
                                          decorationThickness: 2.0,
                                        ),
                                      ),
                                      if (height >= 32 && teacher.isNotEmpty)
                                        Text(
                                          teacher,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: fgColor.withOpacity(0.6),
                                          ),
                                        ),
                                      if (height >= 52 && room.isNotEmpty)
                                        Text(
                                          room,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: fgColor.withOpacity(0.75),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
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
                                    width: 6,
                                    height: 6,
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

  Widget _buildWeekView() {
    final media = MediaQuery.of(context);
    final topContentPadding = media.padding.top + kToolbarHeight + 10;

    int globalMin = 480;
    int globalMax = 900;
    for (final day in _weekData.values) {
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
    for (int m = globalMin - (globalMin % 60) + 60; m < globalMax; m += 60) {
      ticks.add(m);
    }

    const double timeColWidth = 52.0;
    const double dayColWidth = 72.0;
    const double dayColGap = 4.0;
    final timeRanges = _collectTimeRangesFromWeek();
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();

    final todayDate = DateTime(today.year, today.month, today.day);
    final mondayDate = DateTime(
      _currentMonday.year,
      _currentMonday.month,
      _currentMonday.day,
    );
    final todayIndex = todayDate.difference(mondayDate).inDays;
    final nowMin = today.hour * 60 + today.minute;
    final showNowLine =
        todayIndex >= 0 &&
        todayIndex < 5 &&
        nowMin >= globalMin &&
        nowMin <= globalMax;
    final nowTop = (nowMin - globalMin) * _ppm;

    final csW = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _onRefresh,
      displacement: 40,
      edgeOffset: topContentPadding,
      color: csW.onPrimaryContainer,
      backgroundColor: csW.primaryContainer,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 32, top: topContentPadding),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: timeColWidth + 6,
                  bottom: 6,
                ),
                child: Row(
                  children: List.generate(5, (i) {
                    final d = _currentMonday.add(Duration(days: i));
                    final isToday =
                        d.year == today.year &&
                        d.month == today.month &&
                        d.day == today.day;
                    return SizedBox(
                      width: dayColWidth + dayColGap,
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              _dayShort[i],
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isToday
                                    ? cs.primary
                                    : cs.onSurfaceVariant.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? cs.primary
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${d.day}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isToday ? cs.onPrimary : cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: timeColWidth,
                    height: totalHeight,
                    child: Stack(
                      children: timeRanges.isNotEmpty
                          ? timeRanges.map((range) {
                              final top = (range.startMin - globalMin) * _ppm;
                              final blockHeight =
                                  ((range.endMin - range.startMin) * _ppm)
                                      .clamp(16.0, 9999.0);
                              return Positioned(
                                top: top,
                                left: 0,
                                right: 0,
                                height: blockHeight,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatMinutes(range.startMin),
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurfaceVariant.withOpacity(
                                          0.8,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatMinutes(range.endMin),
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurfaceVariant.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                    ),
                                  ],
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
                                    color: cs.onSurfaceVariant.withOpacity(0.7),
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(5, (dayIndex) {
                      final lessons = (_weekData[dayIndex] ?? [])
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
                                (l['code'] ?? '') != 'cancelled',
                          )
                          .toList();
                      final mergedLessons = _mergeConsecutiveLessons(
                        visibleLessons,
                      );
                      final lessonSlots = _computeLessonSlots(mergedLessons);
                      return Container(
                        width: dayColWidth,
                        height: totalHeight,
                        margin: const EdgeInsets.only(right: dayColGap),
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
                                      height: 0.5,
                                      color: cs.outlineVariant.withOpacity(0.6),
                                    ),
                                  );
                                }),
                                ...lessonSlots.map((slot) {
                                  final l = slot.lesson;
                                  final startMin = slot.startMin;
                                  final endMin = slot.endMin;
                                  final top = (startMin - globalMin) * _ppm;
                                  final height = ((endMin - startMin) * _ppm)
                                      .clamp(24.0, 9999.0);
                                  final dim =
                                      (dayIndex == todayIndex) &&
                                      endMin <= nowMin;
                                  final isCancelled =
                                      (l['code'] ?? '') == 'cancelled';
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
                                  final teacher =
                                      l['_teacher']?.toString() ?? '';

                                  const horizontalInset = 1.0;
                                  const columnGap = 2.0;
                                  final columns = slot.columnCount;
                                  final availableWidth =
                                      constraints.maxWidth -
                                      (horizontalInset * 2);
                                  final totalGap = (columns - 1) * columnGap;
                                  final rawCardWidth =
                                      (availableWidth - totalGap) / columns;
                                  final cardWidth = rawCardWidth > 6
                                      ? rawCardWidth
                                      : 6.0;
                                  final left =
                                      horizontalInset +
                                      (slot.column * (cardWidth + columnGap));

                                  final sk2 =
                                      l['_subjectShort']?.toString() ?? '';
                                  final cv2 = isCancelled
                                      ? null
                                      : subjectColorsNotifier.value[sk2];
                                  final isDark2 =
                                      Theme.of(context).brightness ==
                                      Brightness.dark;
                                  final fgColor = isCancelled
                                      ? cs.error
                                      : cv2 != null
                                      ? Color(cv2)
                                      : _autoLessonColor(sk2, isDark2);
                                  final bgColor = isCancelled
                                      ? cs.errorContainer
                                      : fgColor.withOpacity(
                                          isDark2 ? 0.28 : 0.20,
                                        );
                                  return Positioned(
                                    top: top,
                                    left: left,
                                    width: cardWidth,
                                    height: height,
                                    child: _dimPastLesson(
                                      dim: dim,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showLessonDetail(context, l),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border(
                                              left: BorderSide(
                                                color: fgColor,
                                                width: 3,
                                              ),
                                            ),
                                          ),
                                          padding: const EdgeInsets.fromLTRB(
                                            5,
                                            3,
                                            3,
                                            3,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                subject,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: fgColor,
                                                  decoration: isCancelled
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                  decorationColor: fgColor,
                                                  decorationThickness: 2.0,
                                                ),
                                              ),
                                              if (height >= 30 &&
                                                  teacher.isNotEmpty)
                                                Text(
                                                  teacher,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w500,
                                                    color: fgColor.withOpacity(
                                                      0.6,
                                                    ),
                                                  ),
                                                ),
                                              if (height >= 45 &&
                                                  room.isNotEmpty)
                                                Text(
                                                  room,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color: fgColor.withOpacity(
                                                      0.75,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                if (showNowLine && dayIndex == todayIndex)
                                  Positioned(
                                    top: nowTop - 1,
                                    left: 0,
                                    right: 0,
                                    child: IgnorePointer(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: cs.error,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Container(
                                              height: 2,
                                              decoration: BoxDecoration(
                                                color: cs.error,
                                                borderRadius:
                                                    BorderRadius.circular(2),
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
      ),
    );
  }

  Future<void> _fetchFullWeek({bool silent = false}) async {
    if (personId == 0 && personType == 0) {}

    int requestPersonId = _viewingClassId ?? personId;
    int requestPersonType = _viewingClassId != null ? 1 : personType;

    if (requestPersonId == 0) {
      if (requestPersonType == 0) requestPersonType = 5;
    }

    setState(() {
      if (!silent) _loading = true;
      _loadError = null;
    });

    final cachedWeek = await _loadWeekFromCache(
      requestPersonId: requestPersonId,
      requestPersonType: requestPersonType,
    );
    final hasCachedWeek = cachedWeek != null;
    if (hasCachedWeek && mounted) {
      _applyKnownSubjectsFromWeek(cachedWeek);
      setState(() {
        _weekData = cachedWeek;
        _showingCachedWeek = true;
        _loading = false;
      });
    }

    try {
      await _fetchMasterData();
    } catch (e) {
      if (hasCachedWeek) {
        if (!mounted) return;
        setState(() {
          _loadError = null;
          _showingCachedWeek = true;
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _weekData = _emptyWeekData();
        _showingCachedWeek = false;
        _loading = false;
      });
      return;
    }

    DateTime friday = _currentMonday.add(const Duration(days: 4));
    int startDate = int.parse(DateFormat('yyyyMMdd').format(_currentMonday));
    int endDate = int.parse(DateFormat('yyyyMMdd').format(friday));

    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          "Cookie": "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "id": "week_req",
          "method": "getTimetable",
          "params": {
            "id": requestPersonId,
            "type": requestPersonType,
            "startDate": startDate,
            "endDate": endDate,
          },
          "jsonrpc": "2.0",
        }),
      );

      if (response.statusCode != 200) {
        if (hasCachedWeek) {
          if (!mounted) return;
          setState(() {
            _loadError = null;
            _showingCachedWeek = true;
            _loading = false;
          });
          return;
        }
        if (!mounted) return;
        setState(() {
          _loadError =
              "HTTP ${response.statusCode}: Stundenplan konnte nicht geladen werden.";
          _weekData = _emptyWeekData();
          _showingCachedWeek = false;
          _loading = false;
        });
        return;
      }

      final decodedResponse = jsonDecode(response.body);

      if (decodedResponse['error'] != null) {
        final errCode = decodedResponse['error']['code'] as int? ?? 0;
        final apiMsg =
            decodedResponse['error']['message']?.toString() ??
            "Unbekannter API-Fehler";

        if (errCode == -8504 ||
            apiMsg.toLowerCase().contains('not authenticated')) {
          final ok = await _reAuthenticate();
          if (ok) {
            await _fetchFullWeek();
            return;
          }
        }

        if (hasCachedWeek) {
          if (!mounted) return;
          setState(() {
            _loadError = null;
            _showingCachedWeek = true;
            _loading = false;
          });
          return;
        }

        if (!mounted) return;
        setState(() {
          _loadError = apiMsg;
          _weekData = _emptyWeekData();
          _showingCachedWeek = false;
          _loading = false;
        });
        return;
      }

      final dynamic result = decodedResponse['result'];
      final List<dynamic> allLessons = switch (result) {
        List<dynamic> r => r,
        Map r when r['timetable'] is List<dynamic> =>
          (r['timetable'] as List<dynamic>),
        _ => <dynamic>[],
      };
      Map<int, List<dynamic>> tempWeek = _emptyWeekData();
      final classIdsInWeek = <int>{};

      for (var lesson in allLessons) {
        String dStr = lesson['date'].toString();
        if (dStr.length == 8) {
          DateTime lessonDate = DateTime.parse(
            "${dStr.substring(0, 4)}-${dStr.substring(4, 6)}-${dStr.substring(6, 8)}",
          );
          int dayIndex = lessonDate.weekday - 1;
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

            final resolvedLesson = Map<String, dynamic>.from(lesson);
            resolvedLesson['_subjectLong'] =
                (lesson['su'] as List?)?.firstOrNull?['longname'] ??
                (lesson['su'] as List?)?.firstOrNull?['longName'] ??
                _subjectLong[subId] ??
                '';
            resolvedLesson['_subjectShort'] =
                (lesson['su'] as List?)?.firstOrNull?['name'] ??
                _subjectShortMap[subId] ??
                '';
            resolvedLesson['_teacher'] = teacherResolved;
            resolvedLesson['_room'] =
                (lesson['ro'] as List?)?.firstOrNull?['name'] ??
                _roomMap[roId] ??
                '';

            tempWeek[dayIndex]!.add(resolvedLesson);
          }
        }
      }

      final missingTeacherLessons = tempWeek.values
          .expand((day) => day)
          .where((l) => ((l['_teacher'] ?? '').toString().trim().isEmpty))
          .toList();

      if (missingTeacherLessons.isNotEmpty) {
        final exactKeyToTeacher = <String, String>{};
        final looseKeyToTeacher = <String, String>{};

        // Fallback 1: Public weekly endpoint often contains teacher IDs in
        // period elements (type=2) even when JSON-RPC omits `te`.
        try {
          final weeklyDate = DateFormat('yyyy-MM-dd').format(_currentMonday);
          final publicUri = Uri.https(
            schoolUrl,
            '/WebUntis/api/public/timetable/weekly/data',
            {
              'elementType': requestPersonType.toString(),
              'elementId': requestPersonId.toString(),
              'date': weeklyDate,
              'formatId': '2',
            },
          );
          final publicResp = await http.get(
            publicUri,
            headers: {
              "Cookie": "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
              "Accept": "application/json",
            },
          );
          if (publicResp.statusCode == 200) {
            final decoded = jsonDecode(publicResp.body);
            final data = decoded is Map
                ? (((decoded['data'] as Map?)?['result'] as Map?)?['data']
                      as Map?)
                : null;
            final elements = (data?['elements'] as List?) ?? const <dynamic>[];
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

            final elementPeriods =
                (data?['elementPeriods'] as Map?) ?? const {};
            final periodsForElement =
                elementPeriods[requestPersonId.toString()];
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
                  if (tn != null &&
                      tn.isNotEmpty &&
                      !teacherNames.contains(tn)) {
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

        // Fallback 2: Query related class timetables and try key matching.
        if (classIdsInWeek.isNotEmpty) {
          for (final classId in classIdsInWeek) {
            try {
              final classResp = await http.post(
                url,
                headers: {
                  "Cookie":
                      "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
                  "Content-Type": "application/json",
                  "Accept": "application/json",
                },
                body: jsonEncode({
                  "id": "week_class_$classId",
                  "method": "getTimetable",
                  "params": {
                    "id": classId,
                    "type": 1,
                    "startDate": startDate,
                    "endDate": endDate,
                  },
                  "jsonrpc": "2.0",
                }),
              );
              if (classResp.statusCode != 200) continue;
              final classJson = jsonDecode(classResp.body);
              if (classJson is! Map || classJson['error'] != null) continue;
              final classResult = classJson['result'];
              final List<dynamic> classLessons = switch (classResult) {
                List<dynamic> r => r,
                Map r when r['timetable'] is List<dynamic> =>
                  (r['timetable'] as List<dynamic>),
                _ => <dynamic>[],
              };
              for (final lRaw in classLessons) {
                if (lRaw is! Map) continue;
                final lMap = Map<dynamic, dynamic>.from(lRaw);
                final t = _extractTeacherNamesFromLesson(lMap);
                if (t.isEmpty) continue;
                exactKeyToTeacher.putIfAbsent(
                  _lessonTeacherKey(lMap, withRoom: true),
                  () => t,
                );
                looseKeyToTeacher.putIfAbsent(
                  _lessonTeacherKey(lMap, withRoom: false),
                  () => t,
                );
              }
            } catch (_) {}
          }
        }

        for (final l in missingTeacherLessons) {
          if (l is! Map) continue;
          final lMap = Map<dynamic, dynamic>.from(l);
          final exact =
              exactKeyToTeacher[_lessonTeacherKey(lMap, withRoom: true)];
          final loose =
              looseKeyToTeacher[_lessonTeacherKey(lMap, withRoom: false)];
          final fallbackTeacher = exact ?? loose ?? '';
          if (fallbackTeacher.isNotEmpty) {
            l['_teacher'] = fallbackTeacher;
          }
        }
      }

      tempWeek.forEach((key, list) {
        list.sort(
          (a, b) => (a['startTime'] as int).compareTo(b['startTime'] as int),
        );
      });

      _applyKnownSubjectsFromWeek(tempWeek);
      await _saveWeekToCache(
        requestPersonId: requestPersonId,
        requestPersonType: requestPersonType,
        weekData: tempWeek,
      );

      if (!mounted) return;
      setState(() {
        _weekData = tempWeek;
        _showingCachedWeek = false;
        _loading = false;
      });
    } catch (e) {
      print("Fehler beim Laden: $e");
      if (hasCachedWeek) {
        if (!mounted) return;
        setState(() {
          _loadError = null;
          _showingCachedWeek = true;
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _weekData = _emptyWeekData();
        _showingCachedWeek = false;
        _loading = false;
      });
    }
  }

  Future<String?> _authenticateAnonymous() async {
    try {
      final url = Uri.parse(
        'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
      );
      final response = await http.post(
        url,
        body: jsonEncode({
          "id": "anon",
          "method": "authenticate",
          "params": {"user": "", "password": "", "client": "UntisPlus"},
          "jsonrpc": "2.0",
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result']['sessionId'] != null) {
          return data['result']['sessionId'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _openClassSearch() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );

    Future<List<dynamic>> fetchClassesForSession(String sid) async {
      final response = await http.post(
        url,
        headers: {"Cookie": "JSESSIONID=$sid; schoolname=$schoolName"},
        body: jsonEncode({
          "id": "fe_kl",
          "method": "getKlassen",
          "params": {},
          "jsonrpc": "2.0",
        }),
      );
      if (response.statusCode != 200) return const <dynamic>[];
      final data = jsonDecode(response.body);
      if (data is Map && data['result'] is List) {
        return data['result'] as List<dynamic>;
      }
      return const <dynamic>[];
    }

    String? sid;
    String sidSource = 'account';
    List<dynamic> classes = [];

    if (sessionID.isNotEmpty) {
      try {
        classes = await fetchClassesForSession(sessionID);
        if (classes.isNotEmpty) {
          sid = sessionID;
          sidSource = 'account';
        }
      } catch (_) {}
    }

    if (classes.isEmpty) {
      try {
        final anonSid = await _authenticateAnonymous();
        if (anonSid != null && anonSid.isNotEmpty) {
          final anonClasses = await fetchClassesForSession(anonSid);
          if (anonClasses.isNotEmpty) {
            classes = anonClasses;
            sid = anonSid;
            sidSource = 'anonymous';
          }
        }
      } catch (_) {}
    }

    sid ??= sessionID;

    if (!mounted) return;
    Navigator.of(context).pop();

    try {
      if (classes.isNotEmpty) {
        classes.sort(
          (a, b) => (a['name']?.toString() ?? '').compareTo(
            b['name']?.toString() ?? '',
          ),
        );
      }
    } catch (_) {}

    final l = AppL10n.of(appLocaleNotifier.value);

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: _kBottomSheetAnimationStyle,
      builder: (ctx) {
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
                        color: Theme.of(context).colorScheme.outlineVariant,
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
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wähle einen Stundenplan aus',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        l.timetableMyTimetable,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
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
                  if (classes.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Andere Klassen',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...classes.asMap().entries.map((entry) {
                          final i = entry.key;
                          final c = entry.value;
                          final name = c['name'] ?? c['longName'] ?? '?';
                          final id = c['id'] as int?;
                          if (id == null) return const SizedBox.shrink();
                          return _springEntry(
                            duration: Duration(milliseconds: 300 + i * 45),
                            offsetY: 16,
                            startScale: 0.95,
                            curve: _kSmoothBounce,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Card(
                                elevation: 0,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.class_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  title: Text(
                                    name,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _viewingClassId = id;
                                      _viewingClassName = name;
                                      _tempSessionId =
                                          (sid != null && sid != sessionID)
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: RoundedBlurAppBar(
        leading: IconButton(
          tooltip: l.timetableSelectAnother,
          icon: const Icon(Icons.groups_rounded),
          onPressed: _openClassSearch,
        ),
        title: GestureDetector(
          onTap: () {
            final now = DateTime.now();
            final monday = now.subtract(Duration(days: now.weekday - 1));
            final thisMonday = DateTime(monday.year, monday.month, monday.day);
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
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              if (_showingCachedWeek)
                Tooltip(
                  message: 'Offline-Cache aktiv',
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8, top: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l.aiTitle,
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: _openGeminiChat,
          ),
          IconButton(
            tooltip: l.freeRoomsTitle,
            icon: const Icon(Icons.meeting_room_outlined),
            onPressed: _showFreeRoomsDialog,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: _viewMode == 0
                  ? l.timetableWeekView
                  : l.timetableDayGrid,
              icon: Icon(
                _viewMode == 0
                    ? Icons.calendar_view_week_rounded
                    : Icons.calendar_view_day_rounded,
              ),
              onPressed: _toggleView,
            ),
          ),
        ],
        bottom: _viewMode == 1
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorWeight: 4,
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                dividerColor: Colors.transparent,
                tabs: List.generate(5, (i) {
                  return Tab(child: Text(_dayShort[i]));
                }),
              ),
      ),
      body: _AnimatedBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_loadError != null)
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
                        ).colorScheme.onSurfaceVariant.withOpacity(0.35),
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
                        child: Text(l.timetableReload),
                      ),
                    ],
                  ),
                ),
              )
            : _viewMode == 1
            ? _buildWeekView()
            : GestureDetector(
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity < -400) _onSwipeLeft();
                  if (velocity > 400) _onSwipeRight();
                },
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    5,
                    (dayIndex) => _buildGridView(dayIndex),
                  ),
                ),
              ),
      ),
    );
  }

  void _openGeminiChat() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: _kBottomSheetAnimationStyle,
      builder: (_) => _TimetableChatSheet(
        weekData: _weekData,
        currentMonday: _currentMonday,
      ),
    );
  }
}

// --- PRÜFUNGEN ---

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  List<Map<String, dynamic>> _apiExams = [];
  List<Map<String, dynamic>> _customExams = [];
  bool _loading = true;

  Future<void> _refreshExams() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _apiExams = [];
      });
    }
    await _fetchApiExams();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openExamActionsDropdown() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final selected = await _showUnifiedOptionSheet<String>(
      context: context,
      title: l.examsAddTitle,
      options: const [
        _SheetOption(
          value: 'custom',
          title: 'Custom',
          subtitle: 'Eigene Prüfung erstellen',
          icon: Icons.edit_note_rounded,
        ),
        _SheetOption(
          value: 'scan',
          title: 'Scan',
          subtitle: 'Aus Datei oder Bild importieren',
          icon: Icons.document_scanner_rounded,
        ),
      ],
    );

    if (selected == 'custom') {
      _showAddExamDialog();
    } else if (selected == 'scan') {
      _importExamsWithAI();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_fetchApiExams(), _loadCustomExams()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCustomExams() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('customExams') ?? [];
    _customExams = raw
        .map((e) {
          try {
            return Map<String, dynamic>.from(jsonDecode(e) as Map);
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _saveCustomExams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'customExams',
      _customExams.map((e) => jsonEncode(e)).toList(),
    );
  }

  Future<void> _fetchApiExams() async {
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

  Future<void> _showAddExamDialog([
    Map<String, dynamic>? existing,
    int? editIndex,
  ]) async {
    final subjectCtrl = TextEditingController(
      text: existing?['subject']?.toString() ?? '',
    );
    final typeCtrl = TextEditingController(
      text: existing?['examType']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    DateTime selectedDate = () {
      final s = existing?['date']?.toString() ?? '';
      if (s.length == 8) {
        try {
          return DateTime.parse(
            '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}',
          );
        } catch (_) {}
      }
      return DateTime.now();
    }();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: _kBottomSheetAnimationStyle,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: _glassContainer(
              context: ctx,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        existing == null
                            ? AppL10n.of(appLocaleNotifier.value).examsAddTitle
                            : AppL10n.of(
                                appLocaleNotifier.value,
                              ).examsEditTitle,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: subjectCtrl,
                        decoration: InputDecoration(
                          labelText: AppL10n.of(
                            appLocaleNotifier.value,
                          ).examsSubjectLabel,
                          prefixIcon: const Icon(Icons.book_outlined),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withOpacity(
                            0.45,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: typeCtrl,
                        decoration: InputDecoration(
                          labelText: AppL10n.of(
                            appLocaleNotifier.value,
                          ).examsTypeLabel,
                          prefixIcon: const Icon(Icons.label_outline),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withOpacity(
                            0.45,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null)
                            setDlg(() => selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat(
                                  'dd. MMM yyyy',
                                  _icuLocale(appLocaleNotifier.value),
                                ).format(selectedDate),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: AppL10n.of(
                            appLocaleNotifier.value,
                          ).examsNotesLabel,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 42),
                            child: Icon(Icons.notes_rounded),
                          ),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withOpacity(
                            0.45,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (existing != null && editIndex != null)
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                setState(
                                  () => _customExams.removeAt(editIndex),
                                );
                                _saveCustomExams();
                              },
                              child: Text(
                                AppL10n.of(appLocaleNotifier.value).examsDelete,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              AppL10n.of(appLocaleNotifier.value).examsCancel,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: () {
                              final subj = subjectCtrl.text.trim();
                              if (subj.isEmpty) return;
                              final dateInt = int.parse(
                                DateFormat('yyyyMMdd').format(selectedDate),
                              );
                              final newExam = <String, dynamic>{
                                'subject': subj,
                                'examType': typeCtrl.text.trim(),
                                'date': dateInt,
                                'description': descCtrl.text.trim(),
                                '_custom': true,
                              };
                              setState(() {
                                if (editIndex != null) {
                                  _customExams[editIndex] = newExam;
                                } else {
                                  _customExams.add(newExam);
                                }
                              });
                              _saveCustomExams();
                              Navigator.pop(ctx);
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              AppL10n.of(appLocaleNotifier.value).examsSave,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _importExamsWithAI() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    if (geminiApiKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.aiNoApiKey)));
      return;
    }

    // Choose source
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
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      fileBytes = picked.files.first.bytes;
      final ext = picked.files.first.extension?.toLowerCase() ?? '';
      mimeType = ext == 'pdf'
          ? 'application/pdf'
          : (ext == 'png' ? 'image/png' : 'image/jpeg');
    }

    if (fileBytes == null) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: geminiApiKey,
      );
      final prompt = TextPart(
        '''Du bist ein Assistent, der Klausurpläne von Schulen strukturiert erfasst.
Extrahiere alle relevanten Klausuren/Prüfungen aus dem angehängten Bild oder PDF.
Antworte AUSSCHLIESSLICH im folgenden JSON Array Format (kein Markdown-Block, nur reines JSON, keine Grußformeln):
[
  {
    "subject": "Mathe",
    "examType": "Klausur",
    "date": "20240325",
    "description": "Ergänzende Infos oder leere Zeichenkette"
  }
]
WICHTIG: Das Datum MUSS als String im Format YYYYMMDD ausgegeben werden. Fehlt das Jahr, leiste es aus dem aktuellen Datum (${DateTime.now().year}) ab. Wenn die Datei keine Klausuren enthält, gib ein leeres Array [] zurück.''',
      );
      final dataPart = DataPart(mimeType, fileBytes);

      final response = await model.generateContent([
        Content.multi([prompt, dataPart]),
      ]);

      if (!mounted) return;
      Navigator.pop(context); // hide loading

      final text = response.text ?? '';
      final jsonStart = text.indexOf('[');
      final jsonEnd = text.lastIndexOf(']');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = text.substring(jsonStart, jsonEnd + 1);
        final List<dynamic> exams = jsonDecode(jsonStr);

        setState(() {
          for (var e in exams) {
            final newExam = <String, dynamic>{
              'subject': e['subject']?.toString() ?? 'Unbekannt',
              'examType': e['examType']?.toString() ?? 'Klausur',
              'date': (e['date']?.toString() ?? '').replaceAll('-', ''),
              'description': e['description']?.toString() ?? '',
              '_custom': true,
            };
            _customExams.add(newExam);
          }
        });
        _saveCustomExams();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.examsImportSuccess)));
      } else {
        throw Exception("Kein gültiges JSON gefunden.");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // hide loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l.examsImportError}$e')));
    }
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
      appBar: RoundedBlurAppBar(
        title: Text(
          l.examsTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 26),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: l.examsAddTitle,
              icon: const Icon(Icons.add_rounded),
              onPressed: _openExamActionsDropdown,
            ),
          ),
        ],
      ),
      body: _AnimatedBackground(
        child: RefreshIndicator(
          onRefresh: _refreshExams,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
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
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.examsNone,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.examsNoneHint,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.examsReload,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (upcoming.isNotEmpty) ...[
                  _sectionHeader(cs, l.examsUpcoming, Icons.upcoming_rounded),
                  const SizedBox(height: 8),
                  ...upcoming.asMap().entries.map(
                    (e) => _animatedExamCard(e.key, context, cs, e.value, true),
                  ),
                  const SizedBox(height: 20),
                ],
                if (past.isNotEmpty) ...[
                  _sectionHeader(cs, l.examsPast, Icons.history_rounded),
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
      ),
    );
  }

  Widget _sectionHeader(ColorScheme cs, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: cs.primary,
          ),
        ),
      ],
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
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isCustom && customIndex != null
            ? () {
                HapticFeedback.selectionClick();
                _showAddExamDialog(
                  Map<String, dynamic>.from(exam)..remove('_source'),
                  customIndex,
                );
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: accent.withOpacity(isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border(left: BorderSide(color: accent, width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (type.isNotEmpty)
                          _chip(type, accent.withOpacity(0.2), accent),
                        if (isCustom)
                          _chip(l.examsOwn, cs.tertiaryContainer, cs.tertiary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subject.isNotEmpty ? subject : l.examsUnknown,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _infoRow(Icons.calendar_today_rounded, dateStr),
                    if (timeStr.isNotEmpty)
                      _infoRow(Icons.access_time_rounded, timeStr),
                    if (rooms.isNotEmpty) _infoRow(Icons.room_outlined, rooms),
                    if (teachers.isNotEmpty)
                      _infoRow(Icons.person_outline_rounded, teachers),
                    if (desc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          desc,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (showCountdown && daysUntil != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: daysUntil == 0
                          ? cs.errorContainer
                          : daysUntil <= 3
                          ? cs.errorContainer.withOpacity(0.6)
                          : accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      daysUntil == 0
                          ? l.examsToday
                          : daysUntil == 1
                          ? l.examsTomorrow
                          : l.examsInDays(daysUntil),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: daysUntil <= 3 ? cs.error : accent,
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

  Widget _chip(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: fg,
      ),
    ),
  );

  Widget _infoRow(IconData icon, String text) {
    final onVar = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: onVar),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: onVar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- KI-ASSISTENT HILFSFUNKTIONEN ---

String _formatWeekForAi(Map<int, List<dynamic>> weekData, DateTime monday) {
  final l = AppL10n.of(appLocaleNotifier.value);
  final days = l.weekDayFull;
  final buf = StringBuffer();
  for (int i = 0; i < 5; i++) {
    final date = monday.add(Duration(days: i));
    final dateStr = DateFormat('dd.MM.yyyy').format(date);
    final lessons = weekData[i] ?? [];
    buf.writeln('${days[i]}, $dateStr:');
    if (lessons.isEmpty) {
      buf.writeln('  ${l.noLesson}');
    } else {
      for (final lsn in lessons) {
        final start = _formatUntisTime(lsn['startTime'].toString());
        final end = _formatUntisTime(lsn['endTime'].toString());
        final subj = lsn['_subjectLong']?.toString().isNotEmpty == true
            ? lsn['_subjectLong'].toString()
            : lsn['_subjectShort']?.toString() ?? '?';
        final room = lsn['_room']?.toString() ?? '';
        final teacher = lsn['_teacher']?.toString() ?? '';
        final cancelled = (lsn['code'] ?? '') == 'cancelled';
        buf.write('  $start–$end: $subj');
        if (room.isNotEmpty) buf.write(' | ${l.detailRoom} $room');
        if (teacher.isNotEmpty) buf.write(' | $teacher');
        if (cancelled) buf.write(' [${l.detailCancelled}]');
        buf.writeln();
      }
    }
    buf.writeln();
  }
  return buf.toString();
}

// --- KI-ASSISTENT CHAT ---

class _TimetableChatSheet extends StatefulWidget {
  final Map<int, List<dynamic>> weekData;
  final DateTime currentMonday;

  const _TimetableChatSheet({
    required this.weekData,
    required this.currentMonday,
  });

  @override
  State<_TimetableChatSheet> createState() => _TimetableChatSheetState();
}

class _TimetableChatSheetState extends State<_TimetableChatSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  List<Map<String, dynamic>> _exams = [];
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('customExams') ?? [];
    final customExams = raw
        .map((e) {
          try {
            return jsonDecode(e) as Map<String, dynamic>;
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();

    List<Map<String, dynamic>> apiExams = [];
    if (sessionID.isNotEmpty) {
      final now = DateTime.now();
      final startStr = DateFormat(
        'yyyyMMdd',
      ).format(now.subtract(const Duration(days: 14)));
      final endStr = DateFormat(
        'yyyyMMdd',
      ).format(now.add(const Duration(days: 90)));
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

      apiExams = await tryEndpoint('/WebUntis/api/exams');
      if (apiExams.isEmpty)
        apiExams = await tryEndpoint('/WebUntis/api/classreg/exams');
      if (apiExams.isEmpty && personId != 0)
        apiExams = await tryEndpoint('/WebUntis/api/exams/student/$personId');
    }

    if (mounted) {
      setState(() {
        _exams = [
          ...apiExams.map((e) => {...e, '_source': 'api'}),
          ...customExams.map((e) => {...e, '_source': 'custom'}),
        ];
        _exams.sort((a, b) {
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
      });
    }
  }

  String _formatExamsForAi() {
    if (_exams.isEmpty) return 'Keine Prüfungen eingetragen.';
    final buf = StringBuffer();
    for (var ex in _exams) {
      final subject = ex['subject'] ?? ex['subjectName'] ?? '?';
      final type = ex['type'] ?? 'Klausur';
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

  String get _systemPrompt {
    final l = AppL10n.of(appLocaleNotifier.value);
    final today = DateTime.now();
    final icu = _icuLocale(appLocaleNotifier.value);
    final todayStr = DateFormat('EEEE, dd. MMMM yyyy', icu).format(today);
    final schedule = _formatWeekForAi(widget.weekData, widget.currentMonday);
    final examsStr = _formatExamsForAi();
    return '''
      ${l.aiSystemPersona}
      Heute ist: $todayStr

      STUNDENPLAN DIESE WOCHE:
      $schedule

      GEPLANTE KLAUSUREN / PRÜFUNGEN:
      $examsStr

      ${l.aiSystemRules}
    ''';
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _thinking) return;

    if (geminiApiKey.isEmpty) {
      final l = AppL10n.of(appLocaleNotifier.value);
      setState(() {
        _messages.add({'role': 'assistant', 'content': l.aiNoApiKey});
      });
      return;
    }

    _inputController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _thinking = true;
    });
    _scrollToBottom();

    try {
      final contents = _messages.map((m) {
        final role = (m['role'] == 'user') ? 'user' : 'model';
        return {
          'role': role,
          'parts': [
            {'text': m['content'] ?? ''},
          ],
        };
      }).toList();

      final body = jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': _systemPrompt},
          ],
        },
        'contents': contents,
        'generationConfig': {'maxOutputTokens': 2600, 'temperature': 0.2},
      });

      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiApiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String reply = '';
        final candidates = (data is Map<String, dynamic>)
            ? data['candidates']
            : null;
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
          reply = AppL10n.of(appLocaleNotifier.value).aiNoReply;
        }
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
        });
      } else {
        Map<String, dynamic>? err;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) err = decoded;
        } catch (_) {}
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                '${AppL10n.of(appLocaleNotifier.value).aiApiError} ${err?['error']?['message'] ?? response.statusCode}',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              '${AppL10n.of(appLocaleNotifier.value).aiConnectionError} $e',
        });
      });
    } finally {
      if (mounted) setState(() => _thinking = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubicEmphasized,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: _withOptionalBackdropBlur(
        sigmaX: 24,
        sigmaY: 24,
        child: const SizedBox.shrink(),
        childBuilder: (enabled) => Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: enabled ? cs.surface.withOpacity(0.72) : cs.surface,
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.surface.withOpacity(0.78),
                      cs.surfaceContainerHigh.withOpacity(0.62),
                    ],
                  )
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 16, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: cs.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppL10n.of(appLocaleNotifier.value).aiTitle,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: cs.outlineVariant.withOpacity(0.5)),
                  ],
                ),
              ),

              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyHint(cs)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length + (_thinking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return _buildTypingBubble(cs);
                          }
                          final msg = _messages[index];
                          final isUser = msg['role'] == 'user';
                          return _buildBubble(cs, msg['content']!, isUser);
                        },
                      ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: GoogleFonts.outfit(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: AppL10n.of(
                            appLocaleNotifier.value,
                          ).aiInputHint,
                          hintStyle: GoogleFonts.outfit(
                            color: cs.onSurface.withOpacity(0.38),
                          ),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withOpacity(
                            0.5,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedOpacity(
                      opacity: _thinking ? 0.4 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: FilledButton(
                        onPressed: _thinking ? null : _send,
                        style: FilledButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(14),
                        ),
                        child: const Icon(Icons.send_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHint(ColorScheme cs) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final suggestions = l.aiSuggestions;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_rounded,
            size: 40,
            color: cs.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            l.aiKnowsSchedule,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.aiAskAnything,
            style: GoogleFonts.outfit(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map(
                  (s) => ActionChip(
                    label: Text(
                      s,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    backgroundColor: cs.primaryContainer,
                    side: BorderSide.none,
                    onPressed: () {
                      _inputController.text = s;
                      _send();
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(ColorScheme cs, String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? cs.primary
              : cs.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        child: isUser
            ? Text(
                content,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cs.onPrimary,
                ),
              )
            : MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                      p: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                        height: 1.25,
                      ),
                      strong: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      em: GoogleFonts.outfit(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                      code: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
              ),
      ),
    );
  }

  Widget _buildTypingBubble(ColorScheme cs) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            const SizedBox(width: 4),
            _Dot(delay: 150),
            const SizedBox(width: 4),
            _Dot(delay: 300),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    Future.delayed(
      Duration(milliseconds: widget.delay),
      () => mounted ? _ctrl.repeat(reverse: true) : null,
    );
    _anim = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubicEmphasized),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// --- DETAIL BOTTOM SHEET OPENER ---
void _showLessonDetail(BuildContext context, dynamic lesson) {
  HapticFeedback.mediumImpact();
  final subject = lesson['_subjectLong']?.toString().isNotEmpty == true
      ? lesson['_subjectLong'].toString()
      : (lesson['_subjectShort']?.toString().isNotEmpty == true
            ? lesson['_subjectShort'].toString()
            : '---');
  final subjectShort = lesson['_subjectShort']?.toString() ?? '';
  final room = lesson['_room']?.toString().isNotEmpty == true
      ? lesson['_room'].toString()
      : '---';
  final teacher = lesson['_teacher']?.toString() ?? '';
  final time =
      '${_formatUntisTime(lesson['startTime'].toString())} – ${_formatUntisTime(lesson['endTime'].toString())}';
  final isCancelled = (lesson['code'] ?? '') == 'cancelled';
  final info = (lesson['info'] ?? lesson['substText'] ?? '').toString().trim();
  final lessonNr = lesson['lsnumber']?.toString() ?? '';
  final subjectKey = lesson['_subjectShort']?.toString() ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: _kBottomSheetAnimationStyle,
    builder: (_) => _LessonDetailSheet(
      subject: subject,
      subjectShort: subjectShort,
      room: room,
      teacher: teacher,
      time: time,
      isCancelled: isCancelled,
      info: info,
      lessonNr: lessonNr,
      onHideSubject: () {
        Navigator.of(context).pop();
        _hideSubject(subjectKey);
      },
    ),
  );
}

// ignore: unused_element
class _AnimatedLessonCard extends StatelessWidget {
  final int index;
  final dynamic lesson;

  const _AnimatedLessonCard({required this.index, required this.lesson});

  String get _subjectKey => lesson['_subjectShort']?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return _springEntry(
      duration: Duration(milliseconds: 760 + (index * 140)),
      offsetY: 60,
      startScale: 0.9,
      curve: _kSmoothBounce,
      child: LessonCard(
        subject: lesson['_subjectLong']?.toString().isNotEmpty == true
            ? lesson['_subjectLong'].toString()
            : (lesson['_subjectShort']?.toString().isNotEmpty == true
                  ? lesson['_subjectShort'].toString()
                  : "---"),
        subjectShort: lesson['_subjectShort']?.toString() ?? "",
        room: lesson['_room']?.toString().isNotEmpty == true
            ? lesson['_room'].toString()
            : "---",
        teacher: lesson['_teacher']?.toString() ?? "",
        time:
            "${_formatUntisTime(lesson['startTime'].toString())} - ${_formatUntisTime(lesson['endTime'].toString())}",
        isCancelled: (lesson['code'] ?? "") == "cancelled",
        onTap: () => _showLessonDetail(context, lesson),
        onHideSubject: () => _hideSubject(_subjectKey),
      ),
    );
  }
}

class _LessonDetailSheet extends StatelessWidget {
  final String subject, subjectShort, room, teacher, time, info, lessonNr;
  final bool isCancelled;
  final VoidCallback? onHideSubject;

  const _LessonDetailSheet({
    required this.subject,
    required this.subjectShort,
    required this.room,
    required this.teacher,
    required this.time,
    required this.isCancelled,
    required this.info,
    required this.lessonNr,
    this.onHideSubject,
  });

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    if (value.isEmpty || value == '---') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).colorScheme.primary)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    return _sheetSurface(
      context: context,
      blur: blurEnabledNotifier.value,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (isCancelled)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel_outlined, size: 16, color: cs.error),
                    const SizedBox(width: 6),
                    Text(
                      l.detailCancelled,
                      style: GoogleFonts.outfit(
                        color: cs.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: cs.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.detailRegular,
                      style: GoogleFonts.outfit(
                        color: cs.tertiary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            Text(
              subject,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            if (subjectShort.isNotEmpty)
              Text(
                subjectShort,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.primary.withOpacity(0.7),
                ),
              ),

            const SizedBox(height: 24),
            Divider(color: cs.outlineVariant.withOpacity(0.5), height: 1),
            const SizedBox(height: 16),

            _row(context, Icons.access_time_rounded, l.detailTime, time),
            _row(context, Icons.person_rounded, l.detailTeacher, teacher),
            _row(context, Icons.room_rounded, l.detailRoom, room),
            if (lessonNr.isNotEmpty && lessonNr != '0')
              _row(context, Icons.tag_rounded, l.detailLesson, lessonNr),
            if (info.isNotEmpty)
              _row(
                context,
                Icons.info_outline_rounded,
                l.detailInfo,
                info,
                iconColor: cs.tertiary,
              ),

            const SizedBox(height: 16),
            Divider(color: cs.outlineVariant.withOpacity(0.5), height: 1),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: onHideSubject,
              icon: const Icon(Icons.visibility_off_outlined, size: 18),
              label: Text(
                l.detailHideSubject,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface.withOpacity(0.6),
                side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// --- EXPRESSIVE CARD DESIGN ---
class LessonCard extends StatelessWidget {
  final String subject, subjectShort, room, teacher, time;
  final bool isCancelled;
  final VoidCallback? onTap;
  final VoidCallback? onHideSubject;

  const LessonCard({
    super.key,
    required this.subject,
    this.subjectShort = "",
    required this.room,
    this.teacher = "",
    required this.time,
    this.isCancelled = false,
    this.onTap,
    this.onHideSubject,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      onTapDown: (_) => HapticFeedback.selectionClick(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: _withOptionalBackdropBlur(
            sigmaX: 12,
            sigmaY: 12,
            child: const SizedBox.shrink(),
            childBuilder: (enabled) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isCancelled
                    ? (enabled
                          ? Theme.of(
                              context,
                            ).colorScheme.errorContainer.withOpacity(0.9)
                          : Theme.of(context).colorScheme.errorContainer)
                    : (enabled
                          ? Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.85)
                          : Theme.of(context).colorScheme.surface),
                border: Border.all(
                  color: cs.outlineVariant.withOpacity(0.45),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          time,
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subject,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (subjectShort.isNotEmpty)
                          Text(
                            subjectShort,
                            style: GoogleFonts.outfit(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.room_outlined,
                              size: 15,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              room,
                              style: GoogleFonts.outfit(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (teacher.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.person_outline_rounded,
                                size: 15,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                teacher,
                                style: GoogleFonts.outfit(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isCancelled)
                    Badge(
                      label: Text(
                        AppL10n.of(
                          appLocaleNotifier.value,
                        ).detailCancelledBadge,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      textColor: Theme.of(context).colorScheme.onError,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SchoolNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime? date;
  final String? author;
  final String? url;

  const _SchoolNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.author,
    this.url,
  });

  int get sortValue => date?.millisecondsSinceEpoch ?? 0;
}

// --- INFO / SCHUL-BENACHRICHTIGUNGEN ---
class SchoolNotificationsPage extends StatefulWidget {
  const SchoolNotificationsPage({super.key});

  @override
  State<SchoolNotificationsPage> createState() =>
      _SchoolNotificationsPageState();
}

class _SchoolNotificationsPageState extends State<SchoolNotificationsPage> {
  List<_SchoolNotificationItem> _items = const [];
  bool _loading = true;
  String? _error;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (sessionID.isEmpty || schoolUrl.isEmpty || schoolName.isEmpty) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
        _error = null;
        _lastUpdated = DateTime.now();
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final fetched = await _fetchSchoolNotifications();
      if (!mounted) return;
      setState(() {
        _items = fetched;
        _loading = false;
        _error = null;
        _lastUpdated = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppL10n.of(appLocaleNotifier.value).infoFetchError;
        _lastUpdated = DateTime.now();
      });
    }
  }

  Future<List<_SchoolNotificationItem>> _fetchSchoolNotifications() async {
    final start = DateTime.now().subtract(const Duration(days: 45));
    final end = DateTime.now().add(const Duration(days: 90));
    final startStr = DateFormat('yyyyMMdd').format(start);
    final endStr = DateFormat('yyyyMMdd').format(end);

    final headers = {
      'Cookie': 'JSESSIONID=$sessionID; schoolname=$schoolName',
      'Accept': 'application/json',
    };

    List<dynamic> extractList(dynamic decoded) {
      if (decoded is List) return decoded;
      if (decoded is Map) {
        final keys = [
          'messages',
          'notifications',
          'items',
          'data',
          'result',
          'results',
          'entries',
        ];
        for (final key in keys) {
          final value = decoded[key];
          if (value is List) return value;
          if (value is Map) {
            for (final nested in keys) {
              final nestedValue = value[nested];
              if (nestedValue is List) return nestedValue;
            }
          }
        }
      }
      return const [];
    }

    Future<List<dynamic>> tryGet(String path) async {
      try {
        final uri = Uri.parse('https://$schoolUrl$path');
        final res = await http.get(uri, headers: headers);
        if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
          return extractList(jsonDecode(res.body));
        }
      } catch (_) {}
      return const [];
    }

    Future<List<dynamic>> tryJsonRpc(
      String method,
      Map<String, dynamic> params,
    ) async {
      try {
        final uri = Uri.parse(
          'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
        );
        final res = await http.post(
          uri,
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': 'school-info',
            'method': method,
            'params': params,
            'jsonrpc': '2.0',
          }),
        );
        if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map && decoded['error'] != null) {
            return const [];
          }
          if (decoded is Map) {
            return extractList(decoded['result'] ?? decoded);
          }
          return extractList(decoded);
        }
      } catch (_) {}
      return const [];
    }

    final candidates = <List<dynamic>>[
      await tryGet(
        '/WebUntis/api/public/messages?startDate=$startStr&endDate=$endStr',
      ),
      await tryGet(
        '/WebUntis/api/messages?startDate=$startStr&endDate=$endStr',
      ),
      await tryGet(
        '/WebUntis/api/public/notifications?startDate=$startStr&endDate=$endStr',
      ),
      await tryGet(
        '/WebUntis/api/public/notices?startDate=$startStr&endDate=$endStr',
      ),
      await tryJsonRpc('getMessagesOfDay', {
        'date': DateFormat('yyyyMMdd').format(DateTime.now()),
      }),
      await tryJsonRpc('getMessages', {
        'startDate': startStr,
        'endDate': endStr,
      }),
    ];

    final raw = candidates.firstWhere(
      (entry) => entry.isNotEmpty,
      orElse: () => const [],
    );
    final seen = <String>{};
    final items = <_SchoolNotificationItem>[];

    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);

      final title =
          (map['title'] ??
                  map['subject'] ??
                  map['headline'] ??
                  map['name'] ??
                  '')
              .toString()
              .trim();
      final body =
          (map['message'] ??
                  map['text'] ??
                  map['content'] ??
                  map['description'] ??
                  '')
              .toString()
              .trim();
      if (title.isEmpty && body.isEmpty) continue;

      final id =
          (map['id'] ?? map['messageId'] ?? map['uuid'] ?? '$title-$body')
              .toString();
      if (seen.contains(id)) continue;
      seen.add(id);

      final dt = _parseNotificationDate(
        map['date'] ??
            map['startDate'] ??
            map['publishDate'] ??
            map['timestamp'] ??
            map['created'] ??
            map['createdAt'] ??
            map['lastModified'],
      );

      items.add(
        _SchoolNotificationItem(
          id: id,
          title: title.isEmpty
              ? AppL10n.of(appLocaleNotifier.value).infoTitle
              : title,
          body: body,
          date: dt,
          author:
              (map['author'] ?? map['createdBy'] ?? map['publisher'] ?? '')
                  .toString()
                  .trim()
                  .isEmpty
              ? null
              : (map['author'] ?? map['createdBy'] ?? map['publisher'])
                    .toString()
                    .trim(),
          url: _pickNotificationUrl(map),
        ),
      );
    }

    items.sort((a, b) => b.sortValue.compareTo(a.sortValue));
    return items;
  }

  DateTime? _parseNotificationDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      if (raw > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      }
      if (raw > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
      }
      final s = raw.toString();
      if (s.length == 8) {
        try {
          return DateTime.parse(
            '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}',
          );
        } catch (_) {
          return null;
        }
      }
    }

    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    if (RegExp(r'^\d{8}$').hasMatch(value)) {
      try {
        return DateTime.parse(
          '${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6, 8)}',
        );
      } catch (_) {
        return null;
      }
    }
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  String? _pickNotificationUrl(Map<String, dynamic> map) {
    final candidates = [
      map['url'],
      map['link'],
      map['href'],
      map['targetUrl'],
      map['attachmentUrl'],
    ];
    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.startsWith('http://') || text.startsWith('https://')) {
        return text;
      }
    }
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat(
      'dd.MM.yyyy, HH:mm',
      _icuLocale(appLocaleNotifier.value),
    ).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.infoTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 22),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 140),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _lastUpdated == null
                              ? l.infoTitle
                              : '${l.infoUpdated}: ${_formatDate(_lastUpdated)}',
                          style: GoogleFonts.outfit(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l.infoReload,
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 8),
                      child: Text(
                        _error!,
                        style: GoogleFonts.outfit(
                          color: cs.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.infoEmpty,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l.infoEmptyHint,
                            style: GoogleFonts.outfit(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._items.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: cs.outlineVariant.withOpacity(0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.campaign_rounded,
                                  size: 18,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (item.body.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                item.body,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: cs.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (item.date != null)
                                  _infoChip(
                                    context,
                                    _formatDate(item.date),
                                    Icons.schedule_rounded,
                                  ),
                                if ((item.author ?? '').isNotEmpty)
                                  _infoChip(
                                    context,
                                    item.author!,
                                    Icons.person_outline_rounded,
                                  ),
                              ],
                            ),
                            if (item.url != null) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () async {
                                  final ok = await url_launcher.launchUrlString(
                                    item.url!,
                                    mode: url_launcher
                                        .LaunchMode
                                        .externalApplication,
                                  );
                                  if (!ok && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l.settingsGithubOpenFailed,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: Text(l.infoOpenLink),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, String text, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// --- EINSTELLUNGEN ---

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _username = '';
  String _apiKeyDisplay = '';
  bool _apiKeySet = false;
  bool _githubDirectDownload = false;
  bool _checkingGithubUpdate = false;

  static const Map<String, String> _localeLabels = {
    'de': 'Deutsch',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
  };

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    hiddenSubjectsNotifier.addListener(_onChanged);
    knownSubjectsNotifier.addListener(_onChanged);
    subjectColorsNotifier.addListener(_onChanged);
    appLocaleNotifier.addListener(_onChanged);
    showCancelledNotifier.addListener(_onChanged);
    themeModeNotifier.addListener(_onChanged);
    backgroundAnimationsNotifier.addListener(_onChanged);
    backgroundAnimationStyleNotifier.addListener(_onChanged);
    progressivePushNotifier.addListener(_onChanged);
    blurEnabledNotifier.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    hiddenSubjectsNotifier.removeListener(_onChanged);
    knownSubjectsNotifier.removeListener(_onChanged);
    subjectColorsNotifier.removeListener(_onChanged);
    appLocaleNotifier.removeListener(_onChanged);
    showCancelledNotifier.removeListener(_onChanged);
    themeModeNotifier.removeListener(_onChanged);
    backgroundAnimationsNotifier.removeListener(_onChanged);
    backgroundAnimationStyleNotifier.removeListener(_onChanged);
    progressivePushNotifier.removeListener(_onChanged);
    blurEnabledNotifier.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('geminiApiKey') ?? '';
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? '';
        _apiKeySet = key.isNotEmpty;
        _apiKeyDisplay = key.length > 8
            ? '${key.substring(0, 7)}••••${key.substring(key.length - 4)}'
            : (key.isNotEmpty ? '••••••••' : '');
        _githubDirectDownload =
            prefs.getBool('githubDirectUpdateDownload') ?? false;
      });
    }
  }

  Future<void> _setGithubDirectDownload(bool enabled) async {
    setState(() => _githubDirectDownload = enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('githubDirectUpdateDownload', enabled);
  }

  String? _pickGithubReleaseAssetUrl(List<dynamic> assets) {
    String? fallback;
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = (asset['name'] ?? '').toString().toLowerCase();
      final url = (asset['browser_download_url'] ?? '').toString();
      if (url.isEmpty) continue;
      fallback ??= url;
      if (name.endsWith('.apk')) return url;
    }
    return fallback;
  }

  Future<void> _checkGithubUpdate({bool forceDownload = false}) async {
    if (_checkingGithubUpdate) return;
    final l = AppL10n.of(appLocaleNotifier.value);
    setState(() => _checkingGithubUpdate = true);

    if (!forceDownload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.settingsGithubChecking),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      final resp = await http.get(
        Uri.parse(
          'https://api.github.com/repos/ninocss/UntisPlus/releases/latest',
        ),
        headers: const {'Accept': 'application/vnd.github+json'},
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('GitHub API error ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body);
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid GitHub response');
      }

      final tag = (data['tag_name'] ?? '').toString().trim();
      final htmlUrl =
          (data['html_url'] ?? 'https://github.com/ninocss/UntisPlus/releases')
              .toString();
      final assets = (data['assets'] is List)
          ? data['assets'] as List<dynamic>
          : const <dynamic>[];
      final assetUrl = _pickGithubReleaseAssetUrl(assets);
      final shouldDownload = forceDownload || _githubDirectDownload;
      final targetUrl = assetUrl ?? htmlUrl;

      if (shouldDownload) {
        if (assetUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.settingsGithubNoDownloadAsset),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        final launched = await url_launcher.launchUrlString(
          targetUrl,
          mode: url_launcher.LaunchMode.externalApplication,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              launched
                  ? l.settingsGithubDownloadStarted
                  : l.settingsGithubOpenFailed,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l.settingsGithubUpdateFound(tag.isEmpty ? 'latest' : tag),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: l.settingsGithubDownloadNow,
              onPressed: () {
                url_launcher.launchUrlString(
                  targetUrl,
                  mode: url_launcher.LaunchMode.externalApplication,
                );
              },
            ),
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.settingsGithubCheckFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingGithubUpdate = false);
      }
    }
  }

  Future<void> _setLocale(String code) async {
    appLocaleNotifier.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLocale', code);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', ThemeMode.values.indexOf(mode));
  }

  Future<void> _setShowCancelled(bool v) async {
    showCancelledNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showCancelled', v);
  }

  Future<void> _setBackgroundAnimations(bool v) async {
    backgroundAnimationsNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backgroundAnimations', v);
  }

  Future<void> _setBackgroundAnimationStyle(int style) async {
    final normalized = style.clamp(0, 5);
    backgroundAnimationStyleNotifier.value = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('backgroundAnimationStyle', normalized);
  }

  Future<void> _setBlurEnabled(bool v) async {
    blurEnabledNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('blurEnabled', v);
  }

  Future<void> _setProgressivePush(bool v) async {
    progressivePushNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('progressivePush', v);
    if (!v) {
      await NotificationService().cancelNotification(1);
    } else {
      updateUntisData().catchError((_) {});
    }
  }

  void _showLanguageDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsLanguage,
      options: _localeLabels.entries
          .map(
            (e) => _SheetOption(
              value: e.key,
              title: e.value,
              icon: Icons.language_rounded,
              selected: appLocaleNotifier.value == e.key,
            ),
          )
          .toList(),
    ).then((val) {
      if (val != null) {
        _setLocale(val);
      }
    });
  }

  String _backgroundStyleLabel(AppL10n l, int style) {
    switch (style) {
      case 1:
        return l.settingsBackgroundStyleSpace;
      case 2:
        return l.settingsBackgroundStyleBubbles;
      case 3:
        return l.settingsBackgroundStyleLines;
      case 4:
        return l.settingsBackgroundStyleThreeD;
      case 5:
        return l.settingsBackgroundStyleAurora;
      default:
        return l.settingsBackgroundStyleOrbs;
    }
  }

  IconData _backgroundStyleIcon(int style) {
    switch (style) {
      case 1:
        return Icons.nightlight_round;
      case 2:
        return Icons.bubble_chart_rounded;
      case 3:
        return Icons.show_chart_rounded;
      case 4:
        return Icons.view_in_ar_rounded;
      case 5:
        return Icons.water_drop_rounded;
      default:
        return Icons.blur_circular_rounded;
    }
  }

  void _showBackgroundStyleDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final styleOptions = List<int>.generate(6, (index) => index);

    _showUnifiedOptionSheet<int>(
      context: context,
      title: l.settingsBackgroundStyle,
      options: styleOptions
          .map(
            (style) => _SheetOption(
              value: style,
              title: _backgroundStyleLabel(l, style),
              icon: _backgroundStyleIcon(style),
              selected: backgroundAnimationStyleNotifier.value == style,
            ),
          )
          .toList(),
    ).then((style) {
      if (style != null) {
        _setBackgroundAnimationStyle(style);
      }
    });
  }

  void _showApiKeyDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final ctrl = TextEditingController(text: geminiApiKey);
    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  l.settingsApiKeyDialogTitle,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsApiKeyDialogDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  obscureText: true,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'AIza...',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        l.settingsApiKeyCancel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_apiKeySet)
                      TextButton(
                        onPressed: () async {
                          geminiApiKey = '';
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('geminiApiKey');
                          await prefs.remove('openAiApiKey');
                          Navigator.pop(ctx);
                          _loadPrefs();
                        },
                        child: Text(
                          l.settingsApiKeyRemove,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    FilledButton(
                      onPressed: () async {
                        final val = ctrl.text.trim();
                        geminiApiKey = val;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('geminiApiKey', val);
                        await prefs.remove('openAiApiKey');
                        Navigator.pop(ctx);
                        _loadPrefs();
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l.settingsApiKeySave,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingFlow()),
      (route) => false,
    );
  }

  // ── Section card builder ───
  Widget _section(
    String title,
    IconData icon,
    List<Widget> tiles,
    ColorScheme cs, {
    bool isAbout = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
          child: Row(
            children: [
              Icon(icon, size: 13, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: cs.primary,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            if (isAbout)
              Positioned.fill(
                left: -20,
                right: -20,
                top: -20,
                bottom: -20,
                child: Opacity(
                  opacity: 0.25,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE40303),
                            Color(0xFFFF8C00),
                            Color(0xFFFFED00),
                            Color(0xFF008026),
                            Color(0xFF24408E),
                            Color(0xFF732982),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Material(
                color: cs.surfaceContainerHighest.withOpacity(0.4),
                child: Column(
                  children: [
                    for (int i = 0; i < tiles.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 0.5,
                          thickness: 0.5,
                          indent: 66,
                          color: cs.outlineVariant.withOpacity(0.4),
                        ),
                      tiles[i],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  // ── Row tile inside a section card ────
  Widget _tile({
    Widget? leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? subtitleColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color:
                            subtitleColor ??
                            Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  // ── Rounded icon box for tile leading ─────
  Widget _tileIcon(IconData icon, Color color) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: color, size: 20),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final hidden = hiddenSubjectsNotifier.value.toList()..sort();

    return Scaffold(
      body: _AnimatedBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 96,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              flexibleSpace: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    _withOptionalBackdropBlur(
                      sigmaX: 16,
                      sigmaY: 16,
                      child: const SizedBox.shrink(),
                      childBuilder: (enabled) => Container(
                        color: enabled ? Colors.transparent : cs.surface,
                      ),
                    ),
                    FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 14),
                      title: Text(
                        l.settingsTitle,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 23,
                          color: cs.onSurface,
                        ),
                      ),
                      collapseMode: CollapseMode.pin,
                      background: ValueListenableBuilder<bool>(
                        valueListenable: backgroundAnimationsNotifier,
                        builder: (context, enabled, _) {
                          if (!enabled) return const SizedBox.shrink();
                          return ValueListenableBuilder<int>(
                            valueListenable: backgroundAnimationStyleNotifier,
                            builder: (context, style, _) =>
                                _AnimatedBackgroundScene(style: style),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 44),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  _section(l.settingsSectionQuick, Icons.tune_rounded, [
                    _tile(
                      leading: _tileIcon(
                        Icons.event_busy_rounded,
                        showCancelledNotifier.value ? cs.outline : cs.error,
                      ),
                      title: l.settingsShowCancelled,
                      subtitle: l.settingsShowCancelledDesc,
                      trailing: Switch.adaptive(
                        value: showCancelledNotifier.value,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          _setShowCancelled(v);
                        },
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _setShowCancelled(!showCancelledNotifier.value);
                      },
                    ),
                    _tile(
                      leading: _tileIcon(
                        Icons.notifications_active_rounded,
                        progressivePushNotifier.value ? cs.primary : cs.outline,
                      ),
                      title: l.settingsProgressivePush,
                      subtitle: l.settingsProgressivePushDesc,
                      trailing: Switch.adaptive(
                        value: progressivePushNotifier.value,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          _setProgressivePush(v);
                        },
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _setProgressivePush(!progressivePushNotifier.value);
                      },
                    ),
                  ], cs),

                  _section(l.settingsSectionGeneral, Icons.palette_outlined, [
                    _tile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _username.isNotEmpty
                                ? _username[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: l.settingsLoggedInAs,
                      subtitle: _username.isNotEmpty ? _username : '…',
                      trailing: IconButton(
                        tooltip: l.settingsLogout,
                        icon: Icon(Icons.logout_rounded, color: cs.error),
                        onPressed: () => _logout(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _tileIcon(Icons.contrast_rounded, cs.primary),
                              const SizedBox(width: 14),
                              Text(
                                l.settingsThemeMode,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.5,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<ThemeMode>(
                            style: SegmentedButton.styleFrom(
                              textStyle: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              minimumSize: const Size(0, 40),
                            ),
                            segments: [
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text(l.settingsThemeLight),
                                icon: const Icon(
                                  Icons.light_mode_rounded,
                                  size: 17,
                                ),
                              ),
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text(l.settingsThemeSystem),
                                icon: const Icon(
                                  Icons.brightness_auto_rounded,
                                  size: 17,
                                ),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text(l.settingsThemeDark),
                                icon: const Icon(
                                  Icons.dark_mode_rounded,
                                  size: 17,
                                ),
                              ),
                            ],
                            selected: {themeModeNotifier.value},
                            onSelectionChanged: (v) {
                              HapticFeedback.selectionClick();
                              _setThemeMode(v.first);
                            },
                          ),
                        ],
                      ),
                    ),
                    _tile(
                      leading: _tileIcon(
                        Icons.auto_awesome_motion_outlined,
                        backgroundAnimationsNotifier.value
                            ? cs.tertiary
                            : cs.outline,
                      ),
                      title: l.settingsBackgroundAnimations,
                      subtitle: l.settingsBackgroundAnimationsDesc,
                      trailing: Switch.adaptive(
                        value: backgroundAnimationsNotifier.value,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          _setBackgroundAnimations(v);
                        },
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _setBackgroundAnimations(
                          !backgroundAnimationsNotifier.value,
                        );
                      },
                    ),
                    _tile(
                      leading: _tileIcon(
                        _backgroundStyleIcon(
                          backgroundAnimationStyleNotifier.value,
                        ),
                        cs.secondary,
                      ),
                      title: l.settingsBackgroundStyle,
                      subtitle: _backgroundStyleLabel(
                        l,
                        backgroundAnimationStyleNotifier.value,
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                      onTap: _showBackgroundStyleDialog,
                    ),
                    _tile(
                      leading: _tileIcon(
                        Icons.blur_on_rounded,
                        blurEnabledNotifier.value ? cs.primary : cs.outline,
                      ),
                      title: l.settingsGlassEffect,
                      subtitle: l.settingsGlassEffectDesc,
                      trailing: Switch.adaptive(
                        value: blurEnabledNotifier.value,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          _setBlurEnabled(v);
                        },
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _setBlurEnabled(!blurEnabledNotifier.value);
                      },
                    ),
                    // Language tile
                    _tile(
                      leading: _tileIcon(Icons.language_rounded, cs.primary),
                      title: l.settingsLanguage,
                      subtitle: _localeLabels[appLocaleNotifier.value],
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                      onTap: _showLanguageDialog,
                    ),
                  ], cs),

                  _section(
                    l.settingsSectionTimetable,
                    Icons.calendar_today_outlined,
                    [
                      _tile(
                        leading: _tileIcon(
                          Icons.system_update_alt_rounded,
                          cs.primary,
                        ),
                        title: l.settingsRefreshPushWidgetNow,
                        subtitle: l.settingsRefreshPushWidgetNowDesc,
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        onTap: () async {
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l.settingsBackgroundLoading),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          await updateUntisData();
                        },
                      ),
                    ],
                    cs,
                  ),

                  _section(l.settingsSectionAI, Icons.auto_awesome_outlined, [
                    _tile(
                      leading: _apiKeySet
                          ? _tileIcon(Icons.auto_awesome_rounded, cs.tertiary)
                          : _tileIcon(Icons.key_off_rounded, cs.error),
                      title: l.settingsApiKey,
                      subtitle: _apiKeySet
                          ? _apiKeyDisplay
                          : l.settingsApiKeyNotSet,
                      subtitleColor: _apiKeySet ? null : cs.error,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                      onTap: _showApiKeyDialog,
                    ),
                  ], cs),

                  // ── Subjects & Colors (merged) ───────────────────────────
                  _section(l.settingsSectionSubjects, Icons.tune_rounded, [
                    _tile(
                      leading: _tileIcon(Icons.palette_outlined, cs.primary),
                      title: l.settingsSectionColors,
                      subtitle: l
                          .settingsColorsDesc, // "Customize the colors for your subjects"
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubjectColorsPage(),
                          ),
                        );
                      },
                    ),
                    _tile(
                      leading: _tileIcon(
                        Icons.visibility_off_outlined,
                        cs.secondary,
                      ),
                      title: l.settingsSectionHidden,
                      subtitle: hidden.isEmpty
                          ? l.settingsNoHidden
                          : l.settingsHiddenCount(hidden.length),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HiddenSubjectsPage(),
                          ),
                        );
                      },
                    ),
                  ], cs),

                  _section(l.settingsSectionUpdates, Icons.download_rounded, [
                    _tile(
                      leading: _tileIcon(
                        Icons.system_update_alt_rounded,
                        cs.primary,
                      ),
                      title: l.settingsGithubUpdateCheck,
                      subtitle: l.settingsGithubUpdateCheckDesc,
                      trailing: _checkingGithubUpdate
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  cs.primary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: cs.onSurface.withOpacity(0.4),
                            ),
                      onTap: _checkingGithubUpdate
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              _checkGithubUpdate();
                            },
                    ),
                    _tile(
                      leading: _tileIcon(
                        Icons.download_rounded,
                        _githubDirectDownload ? cs.primary : cs.outline,
                      ),
                      title: l.settingsGithubDirectDownload,
                      subtitle: l.settingsGithubDirectDownloadDesc,
                      trailing: Switch.adaptive(
                        value: _githubDirectDownload,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          _setGithubDirectDownload(v);
                        },
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _setGithubDirectDownload(!_githubDirectDownload);
                      },
                    ),
                    _tile(
                      leading: _tileIcon(
                        Icons.open_in_new_rounded,
                        cs.secondary,
                      ),
                      title: l.settingsGithubOpenReleasePage,
                      subtitle: 'github.com/ninocss/UntisPlus',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                      onTap: () {
                        url_launcher.launchUrlString(
                          'https://github.com/ninocss/UntisPlus/releases',
                          mode: url_launcher.LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ], cs),

                  // ── About ────────────────────────────────────────────────
                  _section(
                    l.settingsSectionAbout,
                    Icons.info_outline_rounded,
                    [
                      _tile(
                        leading: _tileIcon(
                          Icons.rocket_launch_outlined,
                          cs.primary,
                        ),
                        title: 'Untis+',
                        subtitle: '${l.settingsAppVersion} $APP_VERSION',
                        trailing: Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: cs.tertiary,
                        ),
                      ),
                    ],
                    cs,
                    isAbout: true,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Standalone account card for settings ─────────────────────────────────────
// ignore: unused_element
class _SettingsAccountCard extends StatelessWidget {
  final String username;
  final String serverUrl;
  final AppL10n l;
  final ColorScheme cs;
  final VoidCallback onLogout;

  const _SettingsAccountCard({
    required this.username,
    required this.serverUrl,
    required this.l,
    required this.cs,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primaryContainer, cs.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.settingsLoggedInAs,
                      style: GoogleFonts.outfit(
                        color: cs.onPrimaryContainer.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      username.isNotEmpty ? username : '…',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    if (serverUrl.isNotEmpty)
                      Text(
                        serverUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: cs.onPrimaryContainer.withOpacity(0.45),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              l.settingsLogout,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error.withOpacity(0.1),
              foregroundColor: cs.error,
              minimumSize: const Size(double.infinity, 46),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subject Colors Page ──────────────────────────────────────────────────────
class SubjectColorsPage extends StatelessWidget {
  const SubjectColorsPage({super.key});

  void _showCustomColorPicker(
    BuildContext context,
    String subject,
    Color? current,
  ) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final fallback = _autoLessonColor(
      subject,
      Theme.of(context).brightness == Brightness.dark,
    );

    double red = (current ?? fallback).red.toDouble();
    double green = (current ?? fallback).green.toDouble();
    double blue = (current ?? fallback).blue.toDouble();

    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final preview = Color.fromARGB(
            255,
            red.round(),
            green.round(),
            blue.round(),
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  l.settingsColorFor(subject),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 66,
                  decoration: BoxDecoration(
                    color: preview,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${l.settingsColorRed}: ${red.round()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: red,
                  min: 0,
                  max: 255,
                  activeColor: Colors.red,
                  onChanged: (v) => setStateDialog(() => red = v),
                ),
                Text(
                  '${l.settingsColorGreen}: ${green.round()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: green,
                  min: 0,
                  max: 255,
                  activeColor: Colors.green,
                  onChanged: (v) => setStateDialog(() => green = v),
                ),
                Text(
                  '${l.settingsColorBlue}: ${blue.round()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: blue,
                  min: 0,
                  max: 255,
                  activeColor: Colors.blue,
                  onChanged: (v) => setStateDialog(() => blue = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        l.settingsApiKeyCancel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        _setSubjectColor(subject, preview.value);
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        l.settingsColorApply,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showColorPicker(BuildContext context, String subject, Color? current) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final palette = _subjectColorPalette(cs);
    _showUnifiedSheet<void>(
      context: context,
      child: Builder(
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l.settingsColorFor(subject),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: palette.map((c) {
                  final isSelected =
                      current != null && current.value == c.value;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _setSubjectColor(subject, c.value);
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: cs.onSurface.withOpacity(0.65),
                                width: 3,
                              )
                            : Border.all(color: Colors.transparent),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: c.withOpacity(0.45),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color:
                                  ThemeData.estimateBrightnessForColor(c) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              size: 22,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showCustomColorPicker(context, subject, current);
                },
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  l.settingsColorCustomPicker,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (current != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _clearSubjectColor(subject);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    l.settingsColorReset,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsSectionColors,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ValueListenableBuilder(
          valueListenable: knownSubjectsNotifier,
          builder: (context, subjectsSet, _) {
            final subjects = subjectsSet.toList()..sort();
            if (subjects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.settingsNoSubjectsLoaded,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l.settingsNoSubjectsLoadedDesc,
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ValueListenableBuilder(
              valueListenable: subjectColorsNotifier,
              builder: (context, colors, _) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subj = subjects[index];
                    final colorVal = colors[subj];
                    final subjectColor = colorVal != null
                        ? Color(colorVal)
                        : null;
                    return _springEntry(
                      duration: Duration(milliseconds: 280 + index * 36),
                      offsetY: 14,
                      startScale: 0.95,
                      curve: _kSmoothBounce,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                subjectColor ??
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: subjectColor != null
                                ? Border.all(
                                    color: subjectColor.withOpacity(0.35),
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: subjectColor == null
                              ? Icon(
                                  Icons.palette_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                )
                              : null,
                        ),
                        title: Text(
                          subj,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          subjectColor != null
                              ? l.settingsCustomColor
                              : l.settingsDefaultColor,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () =>
                            _showColorPicker(context, subj, subjectColor),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Hidden Subjects Page ─────────────────────────────────────────────────────
class HiddenSubjectsPage extends StatelessWidget {
  const HiddenSubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsSectionHidden,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ValueListenableBuilder(
          valueListenable: hiddenSubjectsNotifier,
          builder: (context, hiddenSet, _) {
            final hidden = hiddenSet.toList()..sort();
            if (hidden.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_off_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.settingsNoHidden,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l.settingsNoHiddenDesc,
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: hidden.length,
              itemBuilder: (context, index) {
                final subject = hidden[index];
                return _springEntry(
                  duration: Duration(milliseconds: 280 + index * 36),
                  offsetY: 14,
                  startScale: 0.95,
                  curve: _kSmoothBounce,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          subject.isNotEmpty ? subject[0].toUpperCase() : '?',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      subject,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () {
                        _unhideSubject(subject);
                      },
                      child: Text(
                        l.settingsUnhide,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
