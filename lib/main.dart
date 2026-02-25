import 'dart:ui';
import 'dart:convert';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    initializeDateFormatting('de_DE', null),
    initializeDateFormatting('en_US', null),
    initializeDateFormatting('fr_FR', null),
    initializeDateFormatting('es_ES', null),
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

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

  hiddenSubjectsNotifier.value =
      (prefs.getStringList('hiddenSubjects') ?? []).toSet();
  try {
    final colorsJson = prefs.getString('subjectColors');
    if (colorsJson != null) {
      final decoded = jsonDecode(colorsJson) as Map<String, dynamic>;
      subjectColorsNotifier.value =
          decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
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
          : const LoginPage(),
    ),
  );
}

class UntisPlusApp extends StatelessWidget {
  final Widget startScreen;
  const UntisPlusApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, themeMode, _) {
            return DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                final lightScheme = lightDynamic ??
                    ColorScheme.fromSeed(
                      seedColor: const Color(0xFF4F378B),
                      brightness: Brightness.light,
                    );
                final darkScheme = darkDynamic ??
                    ColorScheme.fromSeed(
                      seedColor: const Color(0xFF4F378B),
                      brightness: Brightness.dark,
                    );

                ThemeData themeFrom(ColorScheme scheme) => ThemeData(
                      useMaterial3: true,
                      colorScheme: scheme,
                      textTheme: GoogleFonts.outfitTextTheme(),
                      navigationBarTheme: NavigationBarThemeData(
                        labelBehavior:
                            NavigationDestinationLabelBehavior.onlyShowSelected,
                        height: 80,
                        indicatorColor: scheme.secondaryContainer,
                        indicatorShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelTextStyle: WidgetStateProperty.all(
                          GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    );

                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Untis+',
                  theme: themeFrom(lightScheme),
                  darkTheme: themeFrom(darkScheme),
                  themeMode: themeMode,
                  home: startScreen,
                );
              },
            );
          },
        );
      },
    );
  }
}

List<Color> _subjectColorPalette(ColorScheme cs) {
  final candidates = <Color>[
    cs.primary,
    cs.secondary,
    cs.tertiary,
    cs.error,
    cs.primaryContainer,
    cs.secondaryContainer,
    cs.tertiaryContainer,
    cs.errorContainer,
    cs.inversePrimary,
    cs.surfaceTint,
  ];
  final seen = <int>{};
  return [for (final c in candidates) if (seen.add(c.value)) c];
}

Color _autoLessonColor(String subjectKey, bool isDark) {
  if (subjectKey.isEmpty) {
    return isDark ? const Color(0xFF9580FF) : const Color(0xFF6750A4);
  }
  var hash = 5381;
  for (final c in subjectKey.codeUnits) {
    hash = ((hash * 33) ^ c) & 0x7FFFFFFF;
  }
  final hue = (hash % 360).toDouble();
  final lightness = isDark ? 0.68 : 0.42;
  final saturation = isDark ? 0.52 : 0.62;
  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}

String sessionID = "";
String schoolUrl = "";
String schoolName = "";
int personId = 0;
int personType = 0;
String geminiApiKey = "";

final ValueNotifier<String> appLocaleNotifier = ValueNotifier('de');
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<bool> showCancelledNotifier = ValueNotifier(true);

String _icuLocale(String locale) {
  switch (locale) {
    case 'en': return 'en_US';
    case 'fr': return 'fr_FR';
    case 'es': return 'es_ES';
    default:   return 'de_DE';
  }
}

final ValueNotifier<Set<String>> hiddenSubjectsNotifier = ValueNotifier({});

Future<void> _hideSubject(String key) async {
  if (key.isEmpty) return;
  final updated = Set<String>.from(hiddenSubjectsNotifier.value)..add(key);
  hiddenSubjectsNotifier.value = updated;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('hiddenSubjects', updated.toList());
}

Future<void> _unhideSubject(String key) async {
  final updated = Set<String>.from(hiddenSubjectsNotifier.value)..remove(key);
  hiddenSubjectsNotifier.value = updated;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('hiddenSubjects', updated.toList());
}

final ValueNotifier<Map<String, int>> subjectColorsNotifier = ValueNotifier({});

final ValueNotifier<Set<String>> knownSubjectsNotifier = ValueNotifier({});

Future<void> _setSubjectColor(String key, int colorValue) async {
  if (key.isEmpty) return;
  final updated = Map<String, int>.from(subjectColorsNotifier.value)..[key] = colorValue;
  subjectColorsNotifier.value = updated;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('subjectColors', jsonEncode(Map<String, dynamic>.from(updated)));
}

Future<void> _clearSubjectColor(String key) async {
  final updated = Map<String, int>.from(subjectColorsNotifier.value)..remove(key);
  subjectColorsNotifier.value = updated;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('subjectColors', jsonEncode(Map<String, dynamic>.from(updated)));
}

String _formatUntisTime(String time) {
  if (time.length < 3) return time;
  String formatted = time.padLeft(4, '0');
  return "${formatted.substring(0, 2)}:${formatted.substring(2)}";
}

Future<bool> _reAuthenticate() async {
  final prefs = await SharedPreferences.getInstance();
  final user = prefs.getString('username') ?? '';
  final pass = prefs.getString('password') ?? '';
  if (user.isEmpty || pass.isEmpty) return false;

  try {
    final url = Uri.parse('https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName');
    final response = await http.post(url,
        body: jsonEncode({
          "id": "relogin",
          "method": "authenticate",
          "params": {"user": user, "password": pass, "client": "UntisPlus"},
          "jsonrpc": "2.0",
        }));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newSession = data['result']?['sessionId']?.toString();
      if (newSession != null && newSession.isNotEmpty) {
        sessionID = newSession;
        await prefs.setString('sessionId', sessionID);
        return true;
      }
    }
  } catch (_) {}
  return false;
}

// --- LOGIN SEITE ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _serverController = TextEditingController();
  final _schoolController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    HapticFeedback.heavyImpact();
    setState(() => _isLoading = true);

    schoolUrl = _serverController.text;
    schoolName = _schoolController.text;

    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          "id": "1",
          "method": "authenticate",
          "params": {
            "user": _userController.text,
            "password": _passwordController.text,
            "client": "UntisPlus",
          },
          "jsonrpc": "2.0",
        }),
      );

      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        sessionID = data['result']['sessionId']?.toString() ?? "";

        var rawId = data['result']['personId'];
        var rawType = data['result']['personType'];

        if (rawId != null && rawId.toString() != "0") {
          personId = int.tryParse(rawId.toString()) ?? 0;
          personType = int.tryParse(rawType.toString()) ?? 5;
        }

        else if (data['result']['klasseId'] != null) {
          personId = int.tryParse(data['result']['klasseId'].toString()) ?? 0;
          personType = 1;
        }

        else {
          personId = 0;
          personType = 5;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sessionId', sessionID);
        await prefs.setString('schoolUrl', schoolUrl);
        await prefs.setString('schoolName', schoolName);
        await prefs.setString('username', _userController.text);
        await prefs.setString('password', _passwordController.text);
        await prefs.setInt('personType', personType);
        await prefs.setInt('personId', personId);

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else {
        final l = AppL10n.of(appLocaleNotifier.value);
        _showError(l.loginFailed);
      }
    } catch (e) {
      final l = AppL10n.of(appLocaleNotifier.value);
      _showError('${l.loginConnectionError}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Icon(
                  Icons.school_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  "Untis+",
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 40),
                Builder(builder: (context) {
                  final l = AppL10n.of(appLocaleNotifier.value);
                  return Column(children: [
                    _buildField(_serverController, l.loginServer, Icons.dns),
                    const SizedBox(height: 15),
                    _buildField(_schoolController, l.loginSchool, Icons.location_city),
                    const SizedBox(height: 15),
                    _buildField(_userController, l.loginUsername, Icons.person),
                    const SizedBox(height: 15),
                    _buildField(_passwordController, l.loginPassword, Icons.key, obscure: true),
                    const SizedBox(height: 40),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : FilledButton(
                            onPressed: _handleLogin,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 64),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              l.loginButton,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ]);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController c,
    String l,
    IconData i, {
    bool obscure = false,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i),
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// --- HAUPT NAVIGATION ---
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
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
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: ValueListenableBuilder<String>(
        valueListenable: appLocaleNotifier,
        builder: (context, locale, _) {
          final l = AppL10n.of(locale);
          return NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              HapticFeedback.lightImpact();
              setState(() => _selectedIndex = index);
            },
            destinations: <Widget>[
              NavigationDestination(
                selectedIcon: const Icon(Icons.calendar_view_week),
                icon: const Icon(Icons.calendar_view_week_outlined),
                label: l.navWeek,
              ),
              NavigationDestination(
                selectedIcon: const Icon(Icons.assignment),
                icon: const Icon(Icons.assignment_outlined),
                label: l.navExams,
              ),
              NavigationDestination(
                selectedIcon: const Icon(Icons.settings),
                icon: const Icon(Icons.settings_outlined),
                label: l.navMenu,
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- WOCHENPLAN (TAB VIEW) ---
class WeeklyTimetablePage extends StatefulWidget {
  const WeeklyTimetablePage({super.key});

  @override
  State<WeeklyTimetablePage> createState() => _WeeklyTimetablePageState();
}

class _WeeklyTimetablePageState extends State<WeeklyTimetablePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<int, List<dynamic>> _weekData = {0: [], 1: [], 2: [], 3: [], 4: []};
  bool _loading = true;
  String? _loadError;
  int _viewMode = 0;

  static const double _ppm = 1.5;

  List<String> get _dayShort => AppL10n.of(appLocaleNotifier.value).weekDayShort;

  final Map<int, String> _subjectLong = {};
  final Map<int, String> _subjectShortMap = {};
  final Map<int, String> _teacherMap = {};
  final Map<int, String> _roomMap = {};

  Future<void> _fetchMasterData() async {
    final url = Uri.parse('https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName');
    final headers = {
      "Cookie": "JSESSIONID=$sessionID; schoolname=$schoolName",
      "Content-Type": "application/json",
    };

    Future<Map<String, dynamic>> rpc(String id, String method) async {
      final r = await http.post(url, headers: headers,
          body: jsonEncode({"id": id, "method": method, "params": {}, "jsonrpc": "2.0"}));
      return jsonDecode(r.body) as Map<String, dynamic>;
    }

    final results = await Future.wait([rpc("sub", "getSubjects"), rpc("tea", "getTeachers"), rpc("roo", "getRooms")]);

    for (var s in (results[0]['result'] as List? ?? [])) {
      final id = s['id'] as int?;
      if (id != null) {
        _subjectLong[id] = (s['longName'] ?? s['longname'] ?? s['name'] ?? '').toString();
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
    if (mounted) setState(() => _viewMode = (prefs.getInt('viewMode') ?? 0).clamp(0, 1));
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

  String get _weekRangeLabel {
    final start = _currentMonday;
    final end = _currentMonday.add(const Duration(days: 4));
    final icu = _icuLocale(appLocaleNotifier.value);
    final startFmt = DateFormat('dd. MMM', icu).format(start);
    final endFmt = DateFormat('dd. MMM yyyy', icu).format(end);
    return '$startFmt \u2013 $endFmt';
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

  static const List<double> _grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
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

  Widget _buildGridView(int dayIndex) {
    final lessons = (_weekData[dayIndex] ?? [])
        .where((l) =>
            !hiddenSubjectsNotifier.value
                .contains(l['_subjectShort']?.toString() ?? ''))
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
    for (int m = globalMin - (globalMin % 30) + 30;
        m < globalMax;
        m += 30) {
      ticks.add(m);
    }

    const double timeColWidth = 44;

    final now = DateTime.now();
    final dayDate = _currentMonday.add(Duration(days: dayIndex));
    final isToday = dayDate.year == now.year &&
      dayDate.month == now.month &&
      dayDate.day == now.day;
    final nowMin = now.hour * 60 + now.minute;
    final showNowLine =
      isToday && nowMin >= globalMin && nowMin <= globalMax;
    final nowTop = (nowMin - globalMin) * _ppm;

    final csG = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: csG.primary,
      backgroundColor: csG.surface,
      strokeWidth: 2.5,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32, top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: timeColWidth,
            height: totalHeight,
            child: Stack(
              children: ticks.map((tick) {
                final top = (tick - globalMin) * _ppm - 9;
                final hh = tick ~/ 60;
                final mm = tick % 60;
                return Positioned(
                  top: top,
                  left: 0,
                  right: 0,
                  child: Text(
                    '$hh:${mm.toString().padLeft(2, '0')}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: csG.onSurfaceVariant.withOpacity(0.7)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              height: totalHeight,
              child: Stack(
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
                  ...lessons
                    .where((l) => showCancelledNotifier.value ||
                        (l['code'] ?? '') != 'cancelled')
                    .map((l) {
                    final startMin =
                        _toMinutes((l['startTime'] as int?) ?? globalMin);
                    final endMin =
                        _toMinutes((l['endTime'] as int?) ?? (startMin + 45));
                    final top = (startMin - globalMin) * _ppm;
                    final height =
                        ((endMin - startMin) * _ppm).clamp(28.0, 9999.0);
                    final dim = isToday && endMin <= nowMin;
                    final isCancelled =
                        (l['code'] ?? '') == 'cancelled';
                    final subject = l['_subjectShort']?.toString().isNotEmpty ==
                            true
                        ? l['_subjectShort'].toString()
                        : (l['_subjectLong']?.toString().isNotEmpty == true
                            ? l['_subjectLong'].toString()
                            : '?');
                    final room = l['_room']?.toString() ?? '';
                    final teacher = l['_teacher']?.toString() ?? '';

                    final cs = Theme.of(context).colorScheme;
                    final sk = l['_subjectShort']?.toString() ?? '';
                    final cv = isCancelled ? null : subjectColorsNotifier.value[sk];
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final fgColor = isCancelled
                        ? cs.error
                        : cv != null
                            ? Color(cv)
                            : _autoLessonColor(sk, isDark);
                    final bgColor = isCancelled
                        ? cs.errorContainer
                        : fgColor.withOpacity(isDark ? 0.22 : 0.16);

                    return Positioned(
                      top: top,
                      left: 2,
                      right: 2,
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
                                    color: fgColor, width: 3.5),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(7, 4, 5, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  ),
                                ),
                                if (height >= 48 && room.isNotEmpty)
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
                                if (height >= 64 && teacher.isNotEmpty)
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
    for (int m = globalMin - (globalMin % 30) + 30; m < globalMax; m += 30) {
      ticks.add(m);
    }

    const double timeColWidth = 40.0;
    const double dayColWidth = 72.0;
    const double dayColGap = 4.0;
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();

    final todayDate = DateTime(today.year, today.month, today.day);
    final mondayDate =
      DateTime(_currentMonday.year, _currentMonday.month, _currentMonday.day);
    final todayIndex = todayDate.difference(mondayDate).inDays;
    final nowMin = today.hour * 60 + today.minute;
    final showNowLine =
      todayIndex >= 0 && todayIndex < 5 && nowMin >= globalMin && nowMin <= globalMax;
    final nowTop = (nowMin - globalMin) * _ppm;

    final csW = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: csW.primary,
      backgroundColor: csW.surface,
      strokeWidth: 2.5,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32, top: 8),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: timeColWidth + 6, bottom: 6),
              child: Row(
                children: List.generate(5, (i) {
                  final d = _currentMonday.add(Duration(days: i));
                  final isToday = d.year == today.year &&
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
                              color: isToday ? cs.primary : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${d.day}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color:
                                    isToday ? cs.onPrimary : cs.onSurface,
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
                    children: ticks.map((tick) {
                      final top = (tick - globalMin) * _ppm - 9;
                      final hh = tick ~/ 60;
                      final mm = tick % 60;
                      return Positioned(
                        top: top,
                        left: 0,
                        right: 0,
                        child: Text(
                          '$hh:${mm.toString().padLeft(2, '0')}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
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
                        .where((l) => !hiddenSubjectsNotifier.value
                            .contains(l['_subjectShort']?.toString() ?? ''))
                        .toList();
                    return Container(
                      width: dayColWidth,
                      height: totalHeight,
                      margin: const EdgeInsets.only(right: dayColGap),
                      child: Stack(
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
                          ...lessons
                            .where((l) => showCancelledNotifier.value ||
                                (l['code'] ?? '') != 'cancelled')
                            .map((l) {
                            final startMin =
                                _toMinutes((l['startTime'] as int?) ?? globalMin);
                            final endMin =
                                _toMinutes((l['endTime'] as int?) ?? (startMin + 45));
                            final top = (startMin - globalMin) * _ppm;
                            final height =
                                ((endMin - startMin) * _ppm).clamp(24.0, 9999.0);
                            final dim = (dayIndex == todayIndex) && endMin <= nowMin;
                            final isCancelled = (l['code'] ?? '') == 'cancelled';
                            final subject =
                                l['_subjectShort']?.toString().isNotEmpty == true
                                    ? l['_subjectShort'].toString()
                                    : (l['_subjectLong']?.toString().isNotEmpty == true
                                        ? l['_subjectLong'].toString()
                                        : '?');
                            final room = l['_room']?.toString() ?? '';
                            final sk2 = l['_subjectShort']?.toString() ?? '';
                            final cv2 = isCancelled ? null : subjectColorsNotifier.value[sk2];
                            final isDark2 = Theme.of(context).brightness == Brightness.dark;
                            final fgColor = isCancelled
                                ? cs.error
                                : cv2 != null
                                    ? Color(cv2)
                                    : _autoLessonColor(sk2, isDark2);
                            final bgColor = isCancelled
                                ? cs.errorContainer
                                : fgColor.withOpacity(isDark2 ? 0.22 : 0.16);
                            return Positioned(
                              top: top,
                              left: 1,
                              right: 1,
                              height: height,
                              child: _dimPastLesson(
                                dim: dim,
                                child: GestureDetector(
                                  onTap: () => _showLessonDetail(context, l),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border(
                                        left: BorderSide(color: fgColor, width: 3),
                                      ),
                                    ),
                                    padding:
                                        const EdgeInsets.fromLTRB(5, 3, 3, 3),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                          ),
                                        ),
                                        if (height >= 44 && room.isNotEmpty)
                                          Text(
                                            room,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 9,
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
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
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

    setState(() {
      if (!silent) _loading = true;
      _loadError = null;
    });

    await _fetchMasterData();

    DateTime friday = _currentMonday.add(const Duration(days: 4));
    int startDate = int.parse(DateFormat('yyyyMMdd').format(_currentMonday));
    int endDate = int.parse(DateFormat('yyyyMMdd').format(friday));

    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );

    int requestPersonId = personId;
    int requestPersonType = personType;

    if (requestPersonId == 0) {
      if (requestPersonType == 0) requestPersonType = 5;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          "Cookie": "JSESSIONID=$sessionID; schoolname=$schoolName",
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
        if (!mounted) return;
        setState(() {
          _loadError =
              "HTTP ${response.statusCode}: Stundenplan konnte nicht geladen werden.";
          _weekData = {0: [], 1: [], 2: [], 3: [], 4: []};
          _loading = false;
        });
        return;
      }

      final decodedResponse = jsonDecode(response.body);

      if (decodedResponse['error'] != null) {
        final errCode = decodedResponse['error']['code'] as int? ?? 0;
        final apiMsg = decodedResponse['error']['message']?.toString() ?? "Unbekannter API-Fehler";

        if (errCode == -8504 || apiMsg.toLowerCase().contains('not authenticated')) {
          final ok = await _reAuthenticate();
          if (ok) {
            await _fetchFullWeek();
            return;
          }
        }

        if (!mounted) return;
        setState(() {
          _loadError = apiMsg;
          _weekData = {0: [], 1: [], 2: [], 3: [], 4: []};
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
      Map<int, List<dynamic>> tempWeek = {0: [], 1: [], 2: [], 3: [], 4: []};

      for (var lesson in allLessons) {
        String dStr = lesson['date'].toString();
        if (dStr.length == 8) {
          DateTime lessonDate = DateTime.parse(
            "${dStr.substring(0, 4)}-${dStr.substring(4, 6)}-${dStr.substring(6, 8)}",
          );
          int dayIndex = lessonDate.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 5) {
            final subId = (lesson['su'] as List?)?.firstOrNull?['id'] as int?;
            final teId  = (lesson['te'] as List?)?.firstOrNull?['id'] as int?;
            final roId  = (lesson['ro'] as List?)?.firstOrNull?['id'] as int?;

            final resolvedLesson = Map<String, dynamic>.from(lesson as Map);
            resolvedLesson['_subjectLong']  = (lesson['su'] as List?)?.firstOrNull?['longname']
                ?? (lesson['su'] as List?)?.firstOrNull?['longName']
                ?? _subjectLong[subId] ?? '';
            resolvedLesson['_subjectShort'] = (lesson['su'] as List?)?.firstOrNull?['name']
                ?? _subjectShortMap[subId] ?? '';
            resolvedLesson['_teacher']      = _teacherMap[teId]
                ?? (lesson['te'] as List?)?.firstOrNull?['name'] ?? '';
            resolvedLesson['_room']         = (lesson['ro'] as List?)?.firstOrNull?['name']
                ?? _roomMap[roId] ?? '';

            tempWeek[dayIndex]!.add(resolvedLesson);
          }
        }
      }

      tempWeek.forEach((key, list) {
        list.sort(
          (a, b) => (a['startTime'] as int).compareTo(b['startTime'] as int),
        );
      });

      final allSubjects = <String>{};
      for (final list in tempWeek.values) {
        for (final l in list) {
          final s = l['_subjectShort']?.toString() ?? '';
          if (s.isNotEmpty) allSubjects.add(s);
        }
      }
      knownSubjectsNotifier.value = allSubjects;

      if (!mounted) return;
      setState(() {
        _weekData = tempWeek;
        _loading = false;
      });
    } catch (e) {
      print("Fehler beim Laden: $e");
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _weekData = {0: [], 1: [], 2: [], 3: [], 4: []};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.timetablePrevWeek,
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: _prevWeek,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.timetableTitle,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              Text(
                _weekRangeLabel,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l.timetableNextWeek,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _nextWeek,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: _viewMode == 0 ? l.timetableWeekView : l.timetableDayGrid,
              icon: Icon(_viewMode == 0
                  ? Icons.calendar_view_week_rounded
                  : Icons.calendar_view_day_rounded),
              onPressed: _toggleView,
            ),
          ),
        ],
        bottom: _viewMode == 1 ? null : TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 4,
          labelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          dividerColor: Colors.transparent,
          tabs: List.generate(5, (i) {
            final d = _currentMonday.add(Duration(days: i));
            final isToday = d.year == DateTime.now().year &&
                d.month == DateTime.now().month &&
                d.day == DateTime.now().day;
            return Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_dayShort[i]),
                  Text(
                    '${d.day}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      body: _loading
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
                      color: Colors.grey.withOpacity(0.35),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.timetableNotLoaded,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
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
          : TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: List.generate(5, (dayIndex) => _buildGridView(dayIndex)),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openGeminiChat,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        child: const Icon(Icons.auto_awesome_rounded),
      ),
    );
  }

  void _openGeminiChat() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    _customExams = raw.map((e) {
      try {
        return Map<String, dynamic>.from(jsonDecode(e) as Map);
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((e) => e.isNotEmpty).toList();
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
        final uri = Uri.parse('https://$schoolUrl$path?startDate=$startStr&endDate=$endStr');
        final res = await http.get(uri, headers: headers);
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
            '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}');
        return DateFormat('EEEE, dd. MMMM yyyy', _icuLocale(appLocaleNotifier.value)).format(d);
      } catch (_) {}
    }
    return s;
  }

  String _examSubject(Map<String, dynamic> e) =>
      (e['subject'] ?? e['name'] ?? e['examType'] ?? '').toString();

  String _examType(Map<String, dynamic> e) =>
      (e['examType'] ?? e['type'] ?? e['typeName'] ?? '').toString();

  Future<void> _showAddExamDialog(
      [Map<String, dynamic>? existing, int? editIndex]) async {
    final subjectCtrl =
        TextEditingController(text: existing?['subject']?.toString() ?? '');
    final typeCtrl =
        TextEditingController(text: existing?['examType']?.toString() ?? '');
    final descCtrl = TextEditingController(
        text: existing?['description']?.toString() ?? '');
    DateTime selectedDate = () {
      final s = existing?['date']?.toString() ?? '';
      if (s.length == 8) {
        try {
          return DateTime.parse(
              '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}');
        } catch (_) {}
      }
      return DateTime.now();
    }();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            existing == null
                ? AppL10n.of(appLocaleNotifier.value).examsAddTitle
                : AppL10n.of(appLocaleNotifier.value).examsEditTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectCtrl,
                  decoration: InputDecoration(
                  labelText: AppL10n.of(appLocaleNotifier.value).examsSubjectLabel,
                    prefixIcon: const Icon(Icons.book_outlined),
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: typeCtrl,
                  decoration: InputDecoration(
                  labelText: AppL10n.of(appLocaleNotifier.value).examsTypeLabel,
                    prefixIcon: const Icon(Icons.label_outline),
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
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
                    if (picked != null) setDlg(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd. MMM yyyy', _icuLocale(appLocaleNotifier.value))
                              .format(selectedDate),
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600, fontSize: 15),
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
                    labelText: AppL10n.of(appLocaleNotifier.value).examsNotesLabel,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 42),
                      child: Icon(Icons.notes_rounded),
                    ),
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null && editIndex != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _customExams.removeAt(editIndex));
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
              child: Text(AppL10n.of(appLocaleNotifier.value).examsCancel,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
            FilledButton(
              onPressed: () {
                final subj = subjectCtrl.text.trim();
                if (subj.isEmpty) return;
                final dateInt = int.parse(
                    DateFormat('yyyyMMdd').format(selectedDate));
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
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(AppL10n.of(appLocaleNotifier.value).examsSave,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final exams = _allExams;
    final todayInt =
        int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));

    final upcoming = exams
        .where((e) =>
            (int.tryParse(e['date']?.toString() ?? '') ?? 0) >= todayInt)
        .toList();
    final past = exams
        .where((e) =>
            (int.tryParse(e['date']?.toString() ?? '') ?? 0) < todayInt)
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          l.examsTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 26),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l.examsReload,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _loading = true;
                _apiExams = [];
              });
              _fetchApiExams().then((_) {
                if (mounted) setState(() => _loading = false);
              });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : exams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 80, color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        l.examsNone,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.examsNoneHint,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _loading = true;
                      _apiExams = [];
                    });
                    await _fetchApiExams();
                    if (mounted) setState(() => _loading = false);
                  },
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (upcoming.isNotEmpty) ...[
                        _sectionHeader(
                            cs, l.examsUpcoming, Icons.upcoming_rounded),
                        const SizedBox(height: 8),
                        ...upcoming.map(
                            (e) => _examCard(context, cs, e, true)),
                        const SizedBox(height: 20),
                      ],
                      if (past.isNotEmpty) ...[
                        _sectionHeader(
                            cs, l.examsPast, Icons.history_rounded),
                        const SizedBox(height: 8),
                        ...past.map(
                            (e) => _examCard(context, cs, e, false)),
                      ],
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAddExamDialog();
        },
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.primary,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.examsAdd,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
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
              fontWeight: FontWeight.w800, fontSize: 15, color: cs.primary),
        ),
      ],
    );
  }

  Widget _examCard(BuildContext context, ColorScheme cs,
      Map<String, dynamic> exam, bool showCountdown) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final isCustom = exam['_source'] == 'custom';
    final subject = _examSubject(exam);
    final type = _examType(exam);
    final dateStr =
        _formatExamDate(exam['date'] ?? exam['examDate'] ?? '');
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
            '${ds.substring(0, 4)}-${ds.substring(4, 6)}-${ds.substring(6, 8)}');
        daysUntil = d
            .difference(DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            ))
            .inDays;
      } catch (_) {}
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isCustom ? cs.tertiary : _autoLessonColor(subject, isDark);

    int? customIndex;
    if (isCustom) {
      customIndex = _customExams.indexWhere(
          (e) => e['subject'] == exam['subject'] && e['date'] == exam['date']);
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
                    customIndex);
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
                          letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    _infoRow(Icons.calendar_today_rounded, dateStr),
                    if (timeStr.isNotEmpty)
                      _infoRow(Icons.access_time_rounded, timeStr),
                    if (rooms.isNotEmpty)
                      _infoRow(Icons.room_outlined, rooms),
                    if (teachers.isNotEmpty)
                      _infoRow(Icons.person_outline_rounded, teachers),
                    if (desc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          desc,
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: Colors.black45),
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
                        horizontal: 10, vertical: 6),
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
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Icon(icon, size: 13, color: Colors.black45),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
            ),
          ],
        ),
      );
}

// --- KI-ASSISTENT HILFSFUNKTIONEN ---

String _formatWeekForAi(
    Map<int, List<dynamic>> weekData, DateTime monday) {
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
  State<_TimetableChatSheet> createState() =>
      _TimetableChatSheetState();
}

class _TimetableChatSheetState extends State<_TimetableChatSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _thinking = false;

  String get _systemPrompt {
    final l = AppL10n.of(appLocaleNotifier.value);
    final today = DateTime.now();
    final icu = _icuLocale(appLocaleNotifier.value);
    final todayStr = DateFormat('EEEE, dd. MMMM yyyy', icu).format(today);
    final schedule = _formatWeekForAi(widget.weekData, widget.currentMonday);
    return '''
      ${l.aiSystemPersona}
      Heute ist: $todayStr

      STUNDENPLAN DIESE WOCHE:
      $schedule
      ${l.aiSystemRules}
    ''';
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _thinking) return;

    if (geminiApiKey.isEmpty) {
      final l = AppL10n.of(appLocaleNotifier.value);
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': l.aiNoApiKey,
        });
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
            {'text': m['content'] ?? ''}
          ],
        };
      }).toList();

      final body = jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': _systemPrompt}
          ],
        },
        'contents': contents,
        'generationConfig': {
          'maxOutputTokens': 2600,
          'temperature': 0.2,
        },
      });

      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiApiKey',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
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
        _messages.add(
            {'role': 'assistant', 'content': '${AppL10n.of(appLocaleNotifier.value).aiConnectionError} $e'});
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
          curve: Curves.easeOut,
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.95),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
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
                          color: Colors.black12,
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
                          child: Icon(Icons.auto_awesome_rounded,
                              color: cs.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppL10n.of(appLocaleNotifier.value).aiTitle,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20),
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
                    Divider(
                        color: Colors.black.withOpacity(0.06),
                        height: 1),
                  ],
                ),
              ),

              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyHint(cs)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount:
                            _messages.length + (_thinking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return _buildTypingBubble(cs);
                          }
                          final msg = _messages[index];
                          final isUser = msg['role'] == 'user';
                          return _buildBubble(
                              cs, msg['content']!, isUser);
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
                          hintText: AppL10n.of(appLocaleNotifier.value).aiInputHint,
                          hintStyle:
                              GoogleFonts.outfit(color: Colors.black38),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest
                              .withOpacity(0.5),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
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
          Icon(Icons.tips_and_updates_rounded,
              size: 40, color: cs.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            l.aiKnowsSchedule,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            l.aiAskAnything,
            style: GoogleFonts.outfit(
                fontSize: 14, color: Colors.black45),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map(
                  (s) => ActionChip(
                    label: Text(s,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
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

  Widget _buildBubble(
      ColorScheme cs, String content, bool isUser) {
    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  color: Colors.white,
                ),
              )
            : MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                  p: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.25,
                  ),
                  strong: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  em: GoogleFonts.outfit(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  code: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

class _DotState extends State<_Dot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(Duration(milliseconds: widget.delay),
        () => mounted ? _ctrl.repeat(reverse: true) : null);
    _anim = Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
          color: Colors.black54,
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
  final room        = lesson['_room']?.toString().isNotEmpty == true ? lesson['_room'].toString() : '---';
  final teacher     = lesson['_teacher']?.toString() ?? '';
  final time        = '${_formatUntisTime(lesson['startTime'].toString())} – ${_formatUntisTime(lesson['endTime'].toString())}';
  final isCancelled = (lesson['code'] ?? '') == 'cancelled';
  final info        = (lesson['info'] ?? lesson['substText'] ?? '').toString().trim();
  final lessonNr    = lesson['lsnumber']?.toString() ?? '';
  final subjectKey  = lesson['_subjectShort']?.toString() ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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

class _AnimatedLessonCard extends StatelessWidget {
  final int index;
  final dynamic lesson;

  const _AnimatedLessonCard({required this.index, required this.lesson});

  String get _subjectKey => lesson['_subjectShort']?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 60 * (1 - value)),
              child: child,
            ),
          ),
        );
      },
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

  Widget _row(BuildContext context, IconData icon, String label, String value, {Color? iconColor}) {
    if (value.isEmpty || value == '---') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: iconColor ?? Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black45)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 17, fontWeight: FontWeight.w700)),
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
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (isCancelled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel_outlined, size: 16, color: cs.error),
                  const SizedBox(width: 6),
                  Text(l.detailCancelled,
                      style: GoogleFonts.outfit(
                          color: cs.error, fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: cs.tertiary),
                  const SizedBox(width: 6),
                  Text(l.detailRegular,
                      style: GoogleFonts.outfit(
                          color: cs.tertiary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ],
              ),
            ),

          const SizedBox(height: 16),

          Text(subject,
              style: GoogleFonts.outfit(
                  fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
          if (subjectShort.isNotEmpty)
            Text(subjectShort,
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: cs.primary.withOpacity(0.7))),

          const SizedBox(height: 24),
          Divider(color: Colors.black.withOpacity(0.06), height: 1),
          const SizedBox(height: 16),

          _row(context, Icons.access_time_rounded, l.detailTime, time),
          _row(context, Icons.person_rounded, l.detailTeacher, teacher),
          _row(context, Icons.room_rounded, l.detailRoom, room),
          if (lessonNr.isNotEmpty && lessonNr != '0')
            _row(context, Icons.tag_rounded, l.detailLesson, lessonNr),
          if (info.isNotEmpty)
            _row(context, Icons.info_outline_rounded, l.detailInfo, info,
                iconColor: Colors.orange),

          const SizedBox(height: 16),
          Divider(color: Colors.black.withOpacity(0.06), height: 1),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: onHideSubject,
            icon: const Icon(Icons.visibility_off_outlined, size: 18),
            label: Text(
              l.detailHideSubject,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              side: const BorderSide(color: Colors.black12),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 8),
        ],
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
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isCancelled
                    ? Theme.of(
                        context,
                      ).colorScheme.errorContainer.withOpacity(0.9)
                    : Theme.of(context).colorScheme.surface.withOpacity(0.85),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
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
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.room_outlined, size: 15, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              room,
                              style: GoogleFonts.outfit(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (teacher.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              const Icon(Icons.person_outline_rounded, size: 15, color: Colors.black54),
                              const SizedBox(width: 4),
                              Text(
                                teacher,
                                style: GoogleFonts.outfit(
                                  color: Colors.black87,
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
                      label: Text(AppL10n.of(appLocaleNotifier.value).detailCancelledBadge),
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

// --- EINSTELLUNGEN ---

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _username = '';
  String _serverDisplay = '';
  String _apiKeyDisplay = '';
  bool _apiKeySet = false;

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
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('geminiApiKey') ?? '';
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? '';
        _serverDisplay = prefs.getString('schoolUrl') ?? '';
        _apiKeySet = key.isNotEmpty;
        _apiKeyDisplay = key.length > 8
            ? '${key.substring(0, 7)}••••${key.substring(key.length - 4)}'
            : (key.isNotEmpty ? '••••••••' : '');
      });
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

  void _showLanguageDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(l.settingsLanguage,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _localeLabels.entries.map((e) {
            final selected = appLocaleNotifier.value == e.key;
            return ListTile(
              title: Text(e.value,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              trailing: selected
                  ? Icon(Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onTap: () {
                _setLocale(e.key);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSubjectColorPicker(BuildContext context, String subject, Color? current) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final palette = _subjectColorPalette(cs);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          l.settingsColorFor(subject),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: palette.map((c) {
                final isSelected = current != null && current.value == c.value;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
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
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 22)
                        : null,
                  ),
                );
              }).toList(),
            ),
            if (current != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _clearSubjectColor(subject);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l.settingsColorReset,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final ctrl = TextEditingController(text: geminiApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(l.settingsApiKeyDialogTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.settingsApiKeyDialogDesc,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'AIza...',
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.settingsApiKeyCancel,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
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
              child: Text(l.settingsApiKeyRemove,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error)),
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
                    borderRadius: BorderRadius.circular(14))),
            child: Text(l.settingsApiKeySave,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // ── Section card builder ───
  Widget _section(
      String title, IconData icon, List<Widget> tiles, ColorScheme cs) {
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
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, fontSize: 15.5)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: subtitleColor ?? Colors.grey.withOpacity(0.75)),
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
    final subjects = knownSubjectsNotifier.value.toList()..sort();
    final colors = subjectColorsNotifier.value;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 96,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 14),
              title: Text(
                l.settingsTitle,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900, fontSize: 23),
              ),
              collapseMode: CollapseMode.pin,
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 44),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SettingsAccountCard(
                  username: _username,
                  serverUrl: _serverDisplay,
                  l: l,
                  cs: cs,
                  onLogout: () => _logout(context),
                ),
                const SizedBox(height: 32),

                _section(l.settingsSectionGeneral, Icons.palette_outlined, [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _tileIcon(Icons.contrast_rounded, cs.primary),
                          const SizedBox(width: 14),
                          Text(l.settingsThemeMode,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.5)),
                        ]),
                        const SizedBox(height: 10),
                        SegmentedButton<ThemeMode>(
                          style: SegmentedButton.styleFrom(
                            textStyle: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            minimumSize: const Size(0, 40),
                          ),
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(l.settingsThemeLight),
                              icon: const Icon(Icons.light_mode_rounded,
                                  size: 17),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(l.settingsThemeSystem),
                              icon: const Icon(
                                  Icons.brightness_auto_rounded,
                                  size: 17),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(l.settingsThemeDark),
                              icon: const Icon(Icons.dark_mode_rounded,
                                  size: 17),
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
                  // Language tile
                  _tile(
                    leading:
                        _tileIcon(Icons.language_rounded, cs.primary),
                    title: l.settingsLanguage,
                    subtitle: _localeLabels[appLocaleNotifier.value],
                    trailing: const Icon(Icons.chevron_right_rounded,
                        size: 20, color: Colors.grey),
                    onTap: _showLanguageDialog,
                  ),
                ], cs),

                _section(l.settingsSectionTimetable,
                    Icons.calendar_today_outlined, [
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
                ], cs),

                _section(l.settingsSectionAI, Icons.auto_awesome_outlined, [
                  _tile(
                    leading: _apiKeySet
                        ? _tileIcon(
                            Icons.auto_awesome_rounded, cs.tertiary)
                        : _tileIcon(
                            Icons.key_off_rounded, cs.error),
                    title: l.settingsApiKey,
                    subtitle:
                        _apiKeySet ? _apiKeyDisplay : l.settingsApiKeyNotSet,
                    subtitleColor: _apiKeySet ? null : cs.error,
                    trailing: const Icon(Icons.chevron_right_rounded,
                        size: 20, color: Colors.grey),
                    onTap: _showApiKeyDialog,
                  ),
                ], cs),

                _section(l.settingsSectionHidden,
                    Icons.visibility_off_outlined, [
                  if (hidden.isEmpty)
                    _tile(
                      leading: _tileIcon(
                          Icons.check_circle_outline_rounded, Colors.green),
                      title: l.settingsNoHidden,
                      subtitle: l.settingsNoHiddenDesc,
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Text(
                        l.settingsHiddenCount(hidden.length),
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.45)),
                      ),
                    ),
                    ...hidden.map((subject) => _tile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                subject.isNotEmpty
                                    ? subject[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: cs.primary),
                              ),
                            ),
                          ),
                          title: subject,
                          trailing: SizedBox(
                            height: 36,
                            child: FilledButton.tonal(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _unhideSubject(subject);
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                              child: Text(l.settingsUnhide,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                          ),
                        )),
                  ],
                ], cs),

                // ── Subject Colors ───────────────────────────────────────
                _section(l.settingsSectionColors, Icons.palette_outlined, [
                  if (subjects.isEmpty)
                    _tile(
                      leading: _tileIcon(Icons.palette_outlined,
                          cs.onSurface.withOpacity(0.4)),
                      title: l.settingsNoSubjectsLoaded,
                      subtitle: l.settingsNoSubjectsLoadedDesc,
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Text(
                        l.settingsColorsDesc,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.45)),
                      ),
                    ),
                    ...subjects.map((subj) {
                      final colorVal = colors[subj];
                      final subjectColor =
                          colorVal != null ? Color(colorVal) : null;
                      return _tile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: subjectColor ?? cs.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: subjectColor != null
                                ? Border.all(
                                    color: subjectColor.withOpacity(0.35),
                                    width: 2)
                                : null,
                          ),
                          child: subjectColor == null
                              ? Icon(Icons.palette_outlined,
                                  color: cs.primary, size: 18)
                              : null,
                        ),
                        title: subj,
                        subtitle: subjectColor != null
                            ? l.settingsCustomColor
                            : l.settingsDefaultColor,
                        trailing: const Icon(Icons.chevron_right_rounded,
                            size: 20, color: Colors.grey),
                        onTap: () => _showSubjectColorPicker(
                            context, subj, subjectColor),
                      );
                    }),
                  ],
                ], cs),

                // ── About ────────────────────────────────────────────────
                _section(l.settingsSectionAbout, Icons.info_outline_rounded, [
                  _tile(
                    leading:
                        _tileIcon(Icons.rocket_launch_outlined, cs.primary),
                    title: 'Untis+',
                    subtitle: '${l.settingsAppVersion} 1.0.0',
                    trailing: const Icon(Icons.auto_awesome_rounded,
                        size: 16, color: Colors.amber),
                  ),
                ], cs),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Standalone account card for settings ─────────────────────────────────────
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
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
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
                          fontSize: 20, fontWeight: FontWeight.w900),
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
            label: Text(l.settingsLogout,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error.withOpacity(0.1),
              foregroundColor: cs.error,
              minimumSize: const Size(double.infinity, 46),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}
