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
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'widgets/rounded_blur_app_bar.dart';

class SchoolSearchResult {
  final int id;
  final String loginName;
  final String displayName;
  final String serverUrl;
  final String address;

  SchoolSearchResult({
    required this.id,
    required this.loginName,
    required this.displayName,
    required this.serverUrl,
    required this.address,
  });

  factory SchoolSearchResult.fromJson(Map<String, dynamic> json) {
    return SchoolSearchResult(
      id: json['schoolId'] ?? 0,
      loginName: json['loginName'] ?? '',
      displayName: json['displayName'] ?? '',
      address: json['address'] ?? '',
      serverUrl: json['server'] ?? json['serverUrl'] ?? '',
    );
  }
}

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
                final lightScheme =
                    lightDynamic ??
                    ColorScheme.fromSeed(
                      seedColor: const Color(0xFF4F378B),
                      brightness: Brightness.light,
                    );
                final darkScheme =
                    darkDynamic ??
                    ColorScheme.fromSeed(
                      seedColor: const Color(0xFF4F378B),
                      brightness: Brightness.dark,
                    );

                ThemeData themeFrom(ColorScheme scheme) => ThemeData(
                  useMaterial3: true,
                  colorScheme: scheme,
                  textTheme:
                      GoogleFonts.outfitTextTheme(
                        ThemeData(
                          useMaterial3: true,
                          colorScheme: scheme,
                        ).textTheme,
                      ).apply(
                        bodyColor: scheme.onSurface,
                        displayColor: scheme.onSurface,
                      ),
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: ZoomPageTransitionsBuilder(),
                      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
                      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
                    },
                  ),
                  navigationBarTheme: NavigationBarThemeData(
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    height: 80,
                    indicatorColor: scheme.secondaryContainer,
                    indicatorShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelTextStyle: WidgetStateProperty.all(
                      GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );

                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Untis+',
                  theme: themeFrom(lightScheme),
                  darkTheme: themeFrom(darkScheme),
                  themeMode: themeMode,
                  builder: (context, child) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final overlayStyle = SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: isDark
                          ? Brightness.light
                          : Brightness.dark,
                      statusBarBrightness: isDark
                          ? Brightness.dark
                          : Brightness.light,
                      systemNavigationBarColor: Colors.transparent,
                      systemNavigationBarIconBrightness: isDark
                          ? Brightness.light
                          : Brightness.dark,
                    );
                    return AnnotatedRegion<SystemUiOverlayStyle>(
                      value: overlayStyle,
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
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
  return [
    for (final c in candidates)
      if (seen.add(c.value)) c,
  ];
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

// ── APP VERSION ────────────────────────────────────────────────────────────
const String APP_VERSION = '1.1.0';

String sessionID = "";
String schoolUrl = "";
String schoolName = "";
int personId = 0;
int personType = 0;
String geminiApiKey = "";

final ValueNotifier<String> appLocaleNotifier = ValueNotifier('de');
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);
final ValueNotifier<bool> showCancelledNotifier = ValueNotifier(true);
final ValueNotifier<bool> backgroundAnimationsNotifier = ValueNotifier(true);
final ValueNotifier<int> backgroundAnimationStyleNotifier = ValueNotifier(0);
final ValueNotifier<bool> progressivePushNotifier = ValueNotifier(true);
final ValueNotifier<bool> blurEnabledNotifier = ValueNotifier(true);

String _icuLocale(String locale) {
  switch (locale) {
    case 'en':
      return 'en_US';
    case 'fr':
      return 'fr_FR';
    case 'es':
      return 'es_ES';
    default:
      return 'de_DE';
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
  final updated = Map<String, int>.from(subjectColorsNotifier.value)
    ..[key] = colorValue;
  subjectColorsNotifier.value = updated;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'subjectColors',
    jsonEncode(Map<String, dynamic>.from(updated)),
  );
}

Future<void> _clearSubjectColor(String key) async {
  final updated = Map<String, int>.from(subjectColorsNotifier.value)
    ..remove(key);
  subjectColorsNotifier.value = updated;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'subjectColors',
    jsonEncode(Map<String, dynamic>.from(updated)),
  );
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
    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );
    final response = await http.post(
      url,
      body: jsonEncode({
        "id": "relogin",
        "method": "authenticate",
        "params": {"user": user, "password": pass, "client": "UntisPlus"},
        "jsonrpc": "2.0",
      }),
    );
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

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Login controllers
  final _serverController = TextEditingController();
  final _schoolController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogginIn = false;

  bool _manualSchoolEntry = false;
  bool _isSearching = false;
  List<SchoolSearchResult> _searchResults = [];
  Timer? _debounce;
  final _geminiController = TextEditingController();

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _handleLogin() async {
    HapticFeedback.heavyImpact();
    setState(() => _isLogginIn = true);

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
        } else if (data['result']['klasseId'] != null) {
          personId = int.tryParse(data['result']['klasseId'].toString()) ?? 0;
          personType = 1;
        } else {
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

        updateUntisData().catchError((_) {});

        if (mounted) _nextPage();
      } else {
        _showError(AppL10n.of(appLocaleNotifier.value).loginFailed);
      }
    } catch (e) {
      final l = AppL10n.of(appLocaleNotifier.value);
      _showError('${l.loginConnectionError}: $e');
    } finally {
      if (mounted) setState(() => _isLogginIn = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (_geminiController.text.isNotEmpty) {
      geminiApiKey = _geminiController.text;
      await prefs.setString('geminiApiKey', geminiApiKey);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const MainNavigationScreen(),
        transitionsBuilder: (context, anim1, anim2, child) =>
            FadeTransition(opacity: anim1, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Gradient Background
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _currentPage % 2 == 0
                      ? colors.primaryContainer
                      : colors.secondaryContainer,
                  colors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          ValueListenableBuilder<bool>(
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

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Progress Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: List.generate(5, (index) {
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage >= index
                                ? colors.primary
                                : colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    children: [
                      _buildLanguageStep(),
                      _buildThemeStep(),
                      _buildLoginStep(),
                      _buildGeminiStep(),
                      _buildTutorialStep(),
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

  // --- Step 1: Language ---
  Widget _buildLanguageStep() {
    final l = AppL10n.of(appLocaleNotifier.value);

    return _StepWrapper(
      icon: Icons.language,
      title: l.onboardingWelcomeTitle,
      subtitle: l.onboardingChooseLanguageSubtitle,
      content: ValueListenableBuilder<String>(
        valueListenable: appLocaleNotifier,
        builder: (context, currentLang, _) {
          return Column(
            children: [
              _buildLangBtn('de', 'Deutsch', '🇩🇪', currentLang),
              const SizedBox(height: 12),
              _buildLangBtn('en', 'English', '🇬🇧', currentLang),
              const SizedBox(height: 12),
              _buildLangBtn('fr', 'Français', '🇫🇷', currentLang),
              const SizedBox(height: 12),
              _buildLangBtn('es', 'Español', '🇪🇸', currentLang),
              const Spacer(),
              _buildNextBtn(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLangBtn(String code, String name, String flag, String current) {
    final colors = Theme.of(context).colorScheme;
    final isSel = current == code;
    return InkWell(
      onTap: () async {
        appLocaleNotifier.value = code;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('appLocale', code);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: isSel ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? colors.primary : colors.outlineVariant,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? colors.onPrimaryContainer : colors.onSurface,
              ),
            ),
            const Spacer(),
            if (isSel) Icon(Icons.check_circle, color: colors.primary),
          ],
        ),
      ),
    );
  }

  // --- Step 2: Theme & Animations ---
  Widget _buildThemeStep() {
    final l = AppL10n.of(appLocaleNotifier.value);

    return _StepWrapper(
      icon: Icons.palette,
      title: l.onboardingAppearanceTitle,
      subtitle: l.onboardingAppearanceSubtitle,
      content: Column(
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, val, _) => SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  icon: const Icon(Icons.brightness_auto),
                  label: Text(l.onboardingThemeSystem),
                ),
                ButtonSegment(
                  value: 1,
                  icon: const Icon(Icons.light_mode),
                  label: Text(l.onboardingThemeLight),
                ),
                ButtonSegment(
                  value: 2,
                  icon: const Icon(Icons.dark_mode),
                  label: Text(l.onboardingThemeDark),
                ),
              ],
              selected: {val.index},
              onSelectionChanged: (set) async {
                final mode = ThemeMode.values[set.first];
                themeModeNotifier.value = mode;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('themeMode', mode.index);
              },
            ),
          ),
          const SizedBox(height: 32),
          ValueListenableBuilder<bool>(
            valueListenable: backgroundAnimationsNotifier,
            builder: (context, val, _) => SwitchListTile(
              title: Text(l.settingsAppearance),
              subtitle: Text(l.onboardingAnimationsHint),
              value: val,
              onChanged: (nv) async {
                backgroundAnimationsNotifier.value = nv;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('backgroundAnimations', nv);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              tileColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          const Spacer(),
          _buildNextBtn(),
        ],
      ),
    );
  }

  // --- Step 3: School Login ---
  Widget _buildLoginStep() {
    final l = AppL10n.of(appLocaleNotifier.value);

    Widget content;
    if (!_manualSchoolEntry && _schoolController.text.isEmpty) {
      content = Column(
        children: [
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              labelText: l.loginSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onChanged: (val) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 800), () {
                if (!mounted) return;
                _searchSchool(val);
              });
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 10),
                        Text(l.loginNoSchoolsFound),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final s = _searchResults[index];
                      return ListTile(
                        title: Text(s.displayName),
                        subtitle: Text(
                          s.address.isNotEmpty
                              ? '${s.address}\n${s.loginName} • ${s.serverUrl}'
                              : '${s.loginName} • ${s.serverUrl}',
                        ),
                        isThreeLine: s.address.isNotEmpty,
                        onTap: () {
                          setState(() {
                            _schoolController.text = s.loginName;
                            _serverController.text = s.serverUrl;
                            _searchResults = [];
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _manualSchoolEntry = true),
            child: Text(l.loginManualEntry),
          ),
        ],
      );
    } else {
      content = SingleChildScrollView(
        child: Column(
          children: [
            if (!_manualSchoolEntry && _schoolController.text.isNotEmpty) ...[
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.school),
                  title: Text(_schoolController.text),
                  subtitle: Text(_serverController.text),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: l.loginChangeSchool,
                    onPressed: () {
                      setState(() {
                        _schoolController.clear();
                        _serverController.clear();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              _buildField(_serverController, l.loginServer, Icons.dns),
              const SizedBox(height: 12),
              _buildField(
                _schoolController,
                l.loginSchool,
                Icons.location_city,
              ),
              const SizedBox(height: 12),
            ],
            _buildField(_userController, l.loginUsername, Icons.person),
            const SizedBox(height: 12),
            _buildField(
              _passwordController,
              l.loginPassword,
              Icons.key,
              obscure: true,
            ),
            const SizedBox(height: 32),
            _isLogginIn
                ? const CircularProgressIndicator()
                : FilledButton(
                    onPressed: _handleLogin,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      l.loginButton,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            if (_manualSchoolEntry) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() {
                  _manualSchoolEntry = false;
                  _schoolController.clear();
                  _serverController.clear();
                }),
                child: Text(l.loginSwitchToSearch),
              ),
            ],
          ],
        ),
      );
    }

    return _StepWrapper(
      icon: Icons.school_rounded,
      title: l.onboardingSchoolLoginTitle,
      subtitle: l.onboardingSchoolLoginSubtitle,
      content: content,
    );
  }

  // --- Step 4: Gemini AI ---
  Widget _buildGeminiStep() {
    final l = AppL10n.of(appLocaleNotifier.value);

    return _StepWrapper(
      icon: Icons.auto_awesome,
      title: l.onboardingGeminiTitle,
      subtitle: l.onboardingGeminiSubtitle,
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, size: 32),
                const SizedBox(height: 12),
                Text(
                  l.onboardingGeminiInfo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l.onboardingGeminiGetApiKey),
                  onPressed: () => url_launcher.launchUrlString(
                    'https://aistudio.google.com/app/apikey',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildField(_geminiController, l.settingsApiKey, Icons.key),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _nextPage,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    l.onboardingSkip,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_geminiController.text.isNotEmpty) {
                      _nextPage();
                    } else {
                      _showError(l.onboardingGeminiEnterKeyOrSkip);
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    l.onboardingNext,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Step 5: Features Tutorial ---
  Widget _buildTutorialStep() {
    final l = AppL10n.of(appLocaleNotifier.value);

    return _StepWrapper(
      icon: Icons.rocket_launch,
      title: l.onboardingReadyTitle,
      subtitle: l.onboardingReadySubtitle,
      content: Column(
        children: [
          _buildFeatureRow(
            Icons.calendar_month,
            l.onboardingFeatureTimetableTitle,
            l.onboardingFeatureTimetableDesc,
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.draw,
            l.onboardingFeatureExamsTitle,
            l.onboardingFeatureExamsDesc,
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.auto_awesome,
            l.onboardingFeatureAiTitle,
            l.onboardingFeatureAiDesc,
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.notifications_active,
            l.onboardingFeatureNotifyTitle,
            l.onboardingFeatureNotifyDesc,
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _completeOnboarding,
            icon: const Icon(Icons.check),
            label: Text(
              l.onboardingFinishSetup,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Helpers ---
  Widget _buildNextBtn([String? lbl, VoidCallback? onTap]) {
    final l = AppL10n.of(appLocaleNotifier.value);

    return FilledButton(
      onPressed: onTap ?? _nextPage,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        lbl ?? l.onboardingNext,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _searchSchool(String query) async {
    if (query.length < 3) return;
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final url = Uri.parse('https://mobile.webuntis.com/ms/schoolquery2');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id": "1",
          "method": "searchSchool",
          "params": [
            {"search": query},
          ],
          "jsonrpc": "2.0",
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result']['schools'] != null) {
          final list = (data['result']['schools'] as List)
              .map((e) => SchoolSearchResult.fromJson(e))
              .toList();
          if (mounted) setState(() => _searchResults = list);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Widget _buildField(
    TextEditingController c,
    String l,
    IconData i, {
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i),
        suffixIcon: suffix,
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _StepWrapper extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget content;

  const _StepWrapper({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Expanded(child: content),
        ],
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
  final ValueNotifier<int> _chatRequest = ValueNotifier(0);

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
    WeeklyTimetablePage(key: ValueKey(sessionID), chatRequest: _chatRequest),
    const ExamsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(bottom: mq.padding.bottom + 104),
            ),
            child: IndexedStack(index: _selectedIndex, children: _pages),
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
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutBack,
              builder: (context, val, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - val) * 26),
                  child: Opacity(opacity: val.clamp(0, 1), child: child),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
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
                          selected: _selectedIndex == 1,
                          onTap: () {
                            if (_selectedIndex != 1) {
                              setState(() => _selectedIndex = 1);
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        _navIconBtn(
                          cs: cs,
                          icon: Icons.auto_awesome_outlined,
                          selectedIcon: Icons.auto_awesome_rounded,
                          selected: false,
                          onTap: () {
                            if (_selectedIndex != 0) {
                              setState(() => _selectedIndex = 0);
                            }
                            Future.delayed(
                              const Duration(milliseconds: 50),
                              () {
                                _chatRequest.value++;
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        _navIconBtn(
                          cs: cs,
                          icon: Icons.settings_outlined,
                          selectedIcon: Icons.settings_rounded,
                          selected: _selectedIndex == 2,
                          onTap: () {
                            if (_selectedIndex != 2) {
                              setState(() => _selectedIndex = 2);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            AnimatedScale(
              scale: _selectedIndex == 0 ? 1.05 : 0.95,
              duration: const Duration(milliseconds: 320),
              curve: Curves.elasticOut,
              child: _BouncyButton(
                onTap: () {
                  if (_selectedIndex != 0) {
                    setState(() => _selectedIndex = 0);
                  }
                },
                scaleTarget: 0.9,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  height: _selectedIndex == 0 ? 72 : 60,
                  width: _selectedIndex == 0 ? 72 : 60,
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0
                        ? cs.primary
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      _selectedIndex == 0 ? 24 : 30,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_selectedIndex == 0
                                    ? cs.primary
                                    : cs.surfaceContainerHighest)
                                .withOpacity(0.4),
                        blurRadius: _selectedIndex == 0 ? 24 : 12,
                        offset: Offset(0, _selectedIndex == 0 ? 8 : 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.elasticOut,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) {
                        return RotationTransition(
                          turns: Tween(begin: 0.8, end: 1.0).animate(anim),
                          child: ScaleTransition(scale: anim, child: child),
                        );
                      },
                      child: Icon(
                        _selectedIndex == 0
                            ? Icons.watch_later_rounded
                            : Icons.watch_later_outlined,
                        key: ValueKey(_selectedIndex == 0),
                        color: _selectedIndex == 0
                            ? cs.onPrimary
                            : cs.onSurfaceVariant,
                        size: _selectedIndex == 0 ? 34 : 28,
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
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _BouncyButton(
      onTap: onTap,
      scaleTarget: 0.8,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        width: selected ? 64 : 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? cs.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: selected
              ? Border.all(
                  color: cs.secondaryContainer.withOpacity(0.5),
                  width: 0,
                )
              : Border.all(color: Colors.transparent, width: 0),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.elasticOut,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) {
            return ScaleTransition(scale: anim, child: child);
          },
          child: Icon(
            selected ? selectedIcon : icon,
            key: ValueKey(selected),
            size: 24,
            color: selected
                ? cs.onSecondaryContainer
                : cs.onSurfaceVariant.withOpacity(0.8),
          ),
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
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleTarget)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.elasticOut,
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

// --- WOCHENPLAN (TAB VIEW) ---
class WeeklyTimetablePage extends StatefulWidget {
  final ValueNotifier<int> chatRequest;
  const WeeklyTimetablePage({super.key, required this.chatRequest});

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
  int _viewMode = 0;

  String? _tempSessionId;
  int? _viewingClassId;
  String? _viewingClassName;
  String _classSessionSource = 'account';

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
    widget.chatRequest.addListener(_onChatRequest);
    if (sessionID.isNotEmpty) _fetchFullWeek();
    _loadViewPref();
  }

  void _onChatRequest() {
    _openGeminiChat();
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
    widget.chatRequest.removeListener(_onChatRequest);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WeeklyTimetablePage oldWidget) {
    if (widget.chatRequest != oldWidget.chatRequest) {
      oldWidget.chatRequest.removeListener(_onChatRequest);
      widget.chatRequest.addListener(_onChatRequest);
    }
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
      edgeOffset: 120,
      color: csG.onPrimaryContainer,
      backgroundColor: csG.primaryContainer,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32, top: 130),
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
      edgeOffset: 120,
      color: csW.onPrimaryContainer,
      backgroundColor: csW.primaryContainer,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32, top: 100),
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

    int requestPersonId = _viewingClassId ?? personId;
    int requestPersonType = _viewingClassId != null ? 1 : personType;

    if (requestPersonId == 0) {
      if (requestPersonType == 0) requestPersonType = 5;
    }

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
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
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
                          _classSessionSource = 'account';
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
                        ...classes.map((c) {
                          final name = c['name'] ?? c['longName'] ?? '?';
                          final id = c['id'] as int?;
                          if (id == null) return const SizedBox.shrink();
                          return Padding(
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
                                  color: Theme.of(context).colorScheme.primary,
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
                                    _classSessionSource = _tempSessionId != null
                                        ? sidSource
                                        : 'account';
                                  });
                                  Navigator.pop(ctx);
                                  _fetchFullWeek();
                                },
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
          child: Text(
            _viewingClassName ?? l.timetableTitle,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
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
                  final d = _currentMonday.add(Duration(days: i));
                  final isToday =
                      d.year == DateTime.now().year &&
                      d.month == DateTime.now().month &&
                      d.day == DateTime.now().day;
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

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            existing == null
                ? AppL10n.of(appLocaleNotifier.value).examsAddTitle
                : AppL10n.of(appLocaleNotifier.value).examsEditTitle,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectCtrl,
                  decoration: InputDecoration(
                    labelText: AppL10n.of(
                      appLocaleNotifier.value,
                    ).examsSubjectLabel,
                    prefixIcon: const Icon(Icons.book_outlined),
                    filled: true,
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
                    if (picked != null) setDlg(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        ctx,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
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
              child: Text(
                AppL10n.of(appLocaleNotifier.value).examsCancel,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
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
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
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

    final cs = Theme.of(context).colorScheme;

    // Choose source
    final source = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          l.examsImportTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: cs.primary),
              title: Text(l.examsImportCamera),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: Icon(Icons.image_rounded, color: cs.primary),
              title: Text(l.examsImportGallery),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf_rounded, color: cs.primary),
              title: Text(l.examsImportFile),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
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
          IconButton(
            tooltip: l.examsImportTitle,
            icon: const Icon(Icons.document_scanner_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              _importExamsWithAI();
            },
          ),
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
      body: _AnimatedBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : exams.isEmpty
            ? Center(
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      _sectionHeader(
                        cs,
                        l.examsUpcoming,
                        Icons.upcoming_rounded,
                      ),
                      const SizedBox(height: 8),
                      ...upcoming.asMap().entries.map(
                        (e) => _animatedExamCard(
                          e.key,
                          context,
                          cs,
                          e.value,
                          true,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (past.isNotEmpty) ...[
                      _sectionHeader(cs, l.examsPast, Icons.history_rounded),
                      const SizedBox(height: 8),
                      ...past.asMap().entries.map(
                        (e) => _animatedExamCard(
                          e.key,
                          context,
                          cs,
                          e.value,
                          false,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showAddExamDialog();
          },
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.primary,
          child: const Icon(Icons.add_rounded),
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
    return TweenAnimationBuilder<double>(
      key: ValueKey('exam_${exam['date']}_${exam['subject']}_$index'),
      duration: Duration(milliseconds: 350 + index * 70),
      curve: Curves.easeInOutCubicEmphasized,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, 28 * (1 - v)),
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.95),
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
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 800 + (index * 150)),
      curve: Curves.easeInOutCubicEmphasized,
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
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
        _serverDisplay = prefs.getString('schoolUrl') ?? '';
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          l.settingsLanguage,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _localeLabels.entries.map((e) {
            final selected = appLocaleNotifier.value == e.key;
            return ListTile(
              title: Text(
                e.value,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              trailing: selected
                  ? Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
    final cs = Theme.of(context).colorScheme;
    final styleOptions = List<int>.generate(6, (index) => index);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          l.settingsBackgroundStyle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: cs.onSurface,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: styleOptions.map((style) {
              final selected = backgroundAnimationStyleNotifier.value == style;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(
                  _backgroundStyleIcon(style),
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                title: Text(
                  _backgroundStyleLabel(l, style),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                trailing: selected
                    ? Icon(Icons.check_rounded, color: cs.primary)
                    : null,
                onTap: () {
                  _setBackgroundAnimationStyle(style);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
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
        title: Text(
          l.settingsApiKeyDialogTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.settingsApiKeyDialogDesc,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
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
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              flexibleSpace: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: Stack(
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(color: Colors.transparent),
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
                            _username.isNotEmpty ? _username[0].toUpperCase() : '?',
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

// ── Reusable animated background wrapper ───────────────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  final Widget child;
  const _AnimatedBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: backgroundAnimationsNotifier,
      builder: (context, enabled, _) {
        if (!enabled) return child;
        return ValueListenableBuilder<int>(
          valueListenable: backgroundAnimationStyleNotifier,
          builder: (context, style, _) {
            return Stack(
              children: [
                Positioned.fill(child: _AnimatedBackgroundScene(style: style)),
                child,
              ],
            );
          },
        );
      },
    );
  }
}

class _AnimatedBackgroundScene extends StatefulWidget {
  final int style;
  const _AnimatedBackgroundScene({required this.style});

  @override
  State<_AnimatedBackgroundScene> createState() =>
      _AnimatedBackgroundSceneState();
}

class _AnimatedBackgroundSceneState extends State<_AnimatedBackgroundScene>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => _buildStyle(cs, _ctrl.value),
    );
  }

  Widget _buildStyle(ColorScheme cs, double t) {
    final style = widget.style.clamp(0, 5);
    switch (style) {
      case 1:
        return _SpaceLayer(t: t, cs: cs);
      case 2:
        return _BubblesLayer(t: t, cs: cs);
      case 3:
        return _LinesLayer(t: t, cs: cs);
      case 4:
        return _ThreeDLayer(t: t, cs: cs);
      case 5:
        return _AuroraLayer(t: t, cs: cs);
      default:
        return _OrbsLayer(t: t, cs: cs);
    }
  }
}

class _OrbsLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _OrbsLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    final t2 = Curves.easeInOutCubicEmphasized.transform(t);
    final t3 = Curves.slowMiddle.transform(1.0 - t);
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          top: -80 + t * 65,
          right: -40 + t2 * 50,
          child: _orb(240, cs.primaryContainer.withOpacity(0.38)),
        ),
        Positioned(
          bottom: -70 + t2 * 55,
          left: -45 + t * 40,
          child: _orb(210, cs.secondaryContainer.withOpacity(0.34)),
        ),
        Positioned(
          top: 85 + t3 * 90,
          right: 15 - t2 * 30,
          child: _orb(150, cs.tertiaryContainer.withOpacity(0.27)),
        ),
        Positioned(
          top: 175 + t2 * 80,
          left: 8 + t * 45,
          child: _orb(170, cs.primaryContainer.withOpacity(0.20)),
        ),
        Positioned(
          bottom: 55 - t3 * 35,
          right: 35 + t * 60,
          child: _orb(125, cs.secondaryContainer.withOpacity(0.22)),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _SpaceLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _SpaceLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.8),
                radius: 1.35,
                colors: [
                  cs.primaryContainer.withOpacity(0.24),
                  cs.surface.withOpacity(0.04),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _StarfieldPainter(t: t, cs: cs),
          ),
        ),
      ],
    );
  }
}

class _BubblesLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _BubblesLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    final bubbles = List<Widget>.generate(18, (i) {
      final f = (i + 1) / 19;
      final drift = math.sin((t * math.pi * 2) + i) * 0.06;
      final x = ((i * 0.13) % 1.0).clamp(0.04, 0.96) - 0.5 + drift;
      final y = 0.6 - (((t + f) % 1.0) * 1.4);
      final size = 18.0 + (i % 5) * 11.0;
      final color = Color.lerp(
        cs.secondaryContainer,
        cs.tertiaryContainer,
        (i % 7) / 6,
      )!.withOpacity(0.22);
      return Align(
        alignment: Alignment(x * 2, y * 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(0.92),
                color.withOpacity(0.45),
                color.withOpacity(0.12),
              ],
            ),
          ),
        ),
      );
    });

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.tertiaryContainer.withOpacity(0.20),
                  cs.primaryContainer.withOpacity(0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        ...bubbles,
      ],
    );
  }
}

class _LinesLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _LinesLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinesPainter(t: t, cs: cs),
    );
  }
}

class _ThreeDLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _ThreeDLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    final layers = List<Widget>.generate(6, (i) {
      final p = (t + i * 0.13) % 1.0;
      final size = 120.0 + i * 32.0;
      final x = math.sin((p * math.pi * 2) + i) * 90;
      final y = math.cos((p * math.pi * 2 * 0.7) + i) * 70;
      final color = Color.lerp(
        cs.primaryContainer,
        cs.secondaryContainer,
        i / 5,
      )!.withOpacity(0.12 + i * 0.02);
      return Positioned.fill(
        child: Transform.translate(
          offset: Offset(x, y),
          child: Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX((p * math.pi) / 3)
                ..rotateZ((p * math.pi) / 2),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cs.onSurface.withOpacity(0.08),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
    return Stack(children: layers);
  }
}

class _AuroraLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _AuroraLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AuroraPainter(t: t, cs: cs),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  _StarfieldPainter({required this.t, required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 120; i++) {
      final seed = i * 0.6180339;
      final x = ((seed * 9973) % 1.0) * size.width;
      final yBase = ((seed * 6967) % 1.0) * size.height;
      final y = (yBase + (t * (10 + (i % 7)))) % size.height;
      final twinkle =
          0.25 + 0.75 * (0.5 + 0.5 * math.sin((t * 8 + i) * math.pi));
      final r = 0.5 + (i % 3) * 0.5;
      starPaint.color = Color.lerp(
        cs.onSurface,
        cs.primary,
        (i % 5) / 4,
      )!.withOpacity(0.08 + 0.20 * twinkle);
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) => true;
}

class _LinesPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  _LinesPainter({required this.t, required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (int i = -2; i < 15; i++) {
      final y = i * 52.0 + (t * 120.0);
      final path = Path()
        ..moveTo(-40, y)
        ..lineTo(size.width + 40, y - 70);
      paint.color = Color.lerp(
        cs.primary,
        cs.tertiary,
        ((i + 2) % 6) / 5,
      )!.withOpacity(0.12 + ((i + 2) % 3) * 0.05);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter oldDelegate) => true;
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  _AuroraPainter({required this.t, required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          cs.primaryContainer.withOpacity(0.15),
          cs.secondaryContainer.withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final phase = t * math.pi * 2 + i * 0.8;
      final top = 60.0 + i * 65.0;
      path.moveTo(0, top + math.sin(phase) * 18);
      for (double x = 0; x <= size.width; x += 20) {
        final y =
            top +
            math.sin((x / size.width) * math.pi * 2 + phase) * (20 + i * 4);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = Color.lerp(
          cs.primary,
          cs.tertiary,
          i / 3,
        )!.withOpacity(0.09 + i * 0.03);
      canvas.drawPath(path, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) => true;
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final preview = Color.fromARGB(
            255,
            red.round(),
            green.round(),
            blue.round(),
          );
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: Text(
              l.settingsColorFor(subject),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
            actions: [
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
          );
        },
      ),
    );
  }

  void _showColorPicker(BuildContext context, String subject, Color? current) {
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
                Navigator.pop(context);
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
                  Navigator.pop(context);
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
      body: ValueListenableBuilder(
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
                  return ListTile(
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showColorPicker(context, subj, subjectColor),
                  );
                },
              );
            },
          );
        },
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
      body: ValueListenableBuilder(
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
              return ListTile(
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
                    HapticFeedback.selectionClick();
                    _unhideSubject(subject);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l.settingsUnhide,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}