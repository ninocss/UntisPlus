import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:url_launcher/url_launcher_string.dart' as url_launcher;
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:otp_auth/otp_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'l10n.dart';
import 'core/time_utils.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/backup_service.dart';
import 'services/demo_mode_service.dart';
import 'widgets/rounded_blur_app_bar.dart';

part 'core/school_models.dart';
part 'core/design_tokens.dart';
part 'app/untis_plus_app.dart';
part 'core/shared_ui.dart';
part 'core/app_state.dart';
part 'core/custom_backgrounds.dart';
part 'screens/onboarding_flow.dart';
part 'screens/custom_background_editor_screen.dart';
part 'screens/main_navigation_screen.dart';
part 'screens/settings_hub.dart';
part 'screens/settings/settings_timetable_page.dart';
part 'screens/settings/settings_notifications_page.dart';
part 'screens/settings/settings_appearance_page.dart';
part 'screens/settings/settings_subjects_page.dart';
part 'screens/settings/settings_ai_page.dart';
part 'screens/settings/settings_backup_page.dart';
part 'screens/settings/settings_account_page.dart';
part 'screens/settings/settings_about_updates_page.dart';
part 'widgets/animated_background.dart';
part 'widgets/custom_background_view.dart';
part 'widgets/changelog_bottom_sheet.dart';

int _toMinutes(int t) => (t ~/ 100) * 60 + (t % 100);

/// Platform channel for window-level UI effects (e.g. Android frosted blur).
const MethodChannel _uiChannel = MethodChannel('untisplus/ui');

/// Sends the desired backdrop blur radius to the native Android window.
/// On Android 12+ (API 31) this calls [Window.setBackdropBlurRadius].
/// Android 17 renders it as the full frosted-glass system effect.
/// Radius 0 disables the effect; ignored on older API levels and non-Android.
Future<void> _applyAndroidWindowBlur(bool enabled) async {
  if (kIsWeb) return;
  try {
    await _uiChannel.invokeMethod<void>(
      'setWindowBlur',
      enabled ? 80 : 0,
    );
  } catch (_) {
    // Silently ignore on platforms/API levels that don't support it.
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await NotificationService().init();
    BackgroundService.initialize();
  }

  await Future.wait([
    initializeDateFormatting('de_DE', null),
    initializeDateFormatting('en_US', null),
    initializeDateFormatting('fr_FR', null),
    initializeDateFormatting('es_ES', null),
    initializeDateFormatting('el_GR', null),
  ]);

  final prefs = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();
  appVersion = packageInfo.version;
  appBuildNumber = packageInfo.buildNumber;
  final previousAppVersion = prefs.getString('installedAppVersion');
  if (previousAppVersion == null || previousAppVersion != appVersion) {
    await prefs.setBool('showChangelogPending', true);
  }
  await prefs.setString('installedAppVersion', appVersion);
  showChangelogOnStartup = prefs.getBool('showChangelogPending') ?? false;
  demoModeNotifier.value = prefs.getBool('demoMode') ?? false;
  final bool isLoggedIn = prefs.containsKey('sessionId');
  final bool onboardingCompleted =
      prefs.getBool('onboardingCompleted') ?? false;
  final bool tutorialCompleted = prefs.getBool('tutorialCompleted') ?? false;

  if (isLoggedIn) {
    sessionID = prefs.getString('sessionId') ?? "";
    schoolUrl = prefs.getString('schoolUrl') ?? "";
    schoolName = prefs.getString('schoolName') ?? "";
    personType = prefs.getInt('personType') ?? 0;
    personId = prefs.getInt('personId') ?? 0;
  }
  defaultClassId = prefs.getInt('defaultClassId');
  defaultClassName = prefs.getString('defaultClassName');
  favoriteClassIds = (prefs.getStringList('favoriteClassIds') ?? [])
      .map((idStr) => int.tryParse(idStr))
      .whereType<int>()
      .toSet();

  appLocaleNotifier.value = prefs.getString('appLocale') ?? 'de';
  themeModeNotifier.value = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
  showCancelledNotifier.value = prefs.getBool('showCancelled') ?? true;
  cancelledLessonColorNotifier.value =
      prefs.getInt('cancelledLessonColor') ?? 0xFFFF1744;
  monochromeLessonsNotifier.value =
      prefs.getBool('monochromeLessons') ?? false;
  backgroundAnimationsNotifier.value =
      prefs.getBool('backgroundAnimations') ?? true;
  backgroundAnimationStyleNotifier.value =
      (prefs.getInt('backgroundAnimationStyle') ?? 0).clamp(0, 10);
  backgroundGyroscopeNotifier.value =
      prefs.getBool('backgroundGyroscope') ?? false;
  blurEnabledNotifier.value = prefs.getBool('blurEnabled') ?? true;
  appBgBlurEnabledNotifier.value = prefs.getBool('appBgBlurEnabled') ?? false;
  appBgBlurAmountNotifier.value = prefs.getDouble('appBgBlurAmount') ?? 10.0;
  unawaited(_applyAndroidWindowBlur(blurEnabledNotifier.value));

  pageTransitionNotifier.value =
      (prefs.getInt('pageTransition') ?? 0).clamp(0, 7);
  useMaterialYouNotifier.value =
      prefs.getBool('useMaterialYou') ?? true;
  customColorSeedNotifier.value =
      prefs.getInt('customColorSeed') ?? 0xFF0F766E;
  dailyBriefingPushNotifier.value = prefs.getBool('dailyBriefingPush') ?? true;
  importantChangesPushNotifier.value =
      prefs.getBool('importantChangesPush') ?? true;

  await loadCustomBackgroundsFromPrefs(prefs);

  hiddenSubjectsNotifier.value = (prefs.getStringList('hiddenSubjects') ?? [])
      .toSet();
  try {
    final colorsJson = prefs.getString('subjectColors');
    if (colorsJson != null) {
      final decoded = jsonDecode(colorsJson);
      if (decoded is Map) {
        subjectColorsNotifier.value = decoded.map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        );
      }
    }
  } catch (_) {}

  geminiApiKey = prefs.getString('geminiApiKey') ?? '';
  final hasProviderConfig = prefs.containsKey('aiProvider');
  if (!hasProviderConfig && geminiApiKey.isEmpty) {
    // Legacy migration: old versions stored the Gemini key under openAiApiKey.
    final legacy = prefs.getString('openAiApiKey') ?? '';
    if (legacy.isNotEmpty) {
      geminiApiKey = legacy;
      await prefs.remove('openAiApiKey');
    }
  }

  openAiApiKey = prefs.getString('openAiApiKey') ?? '';
  mistralApiKey = prefs.getString('mistralApiKey') ?? '';
  customAiApiKey = prefs.getString('customAiApiKey') ?? '';
  aiProvider = _normalizeAiProvider(prefs.getString('aiProvider') ?? 'gemini');
  aiCustomCompatibility = _normalizeAiCustomCompatibility(
    prefs.getString('aiCustomCompatibility') ?? 'openai',
  );
  aiCustomBaseUrl = prefs.getString('aiCustomBaseUrl') ?? '';
  aiSystemPromptTemplate = prefs.getString('aiSystemPromptTemplate') ?? '';
  final savedModel = prefs.getString('aiModel') ?? '';
  final availableModels = _modelsForProvider(
    aiProvider,
    customCompatibility: aiCustomCompatibility,
  );
  aiModel = savedModel.isNotEmpty
      ? savedModel
      : _defaultModelForProvider(
          aiProvider,
          customCompatibility: aiCustomCompatibility,
        );
  if (!availableModels.contains(aiModel)) {
    aiModel = _defaultModelForProvider(
      aiProvider,
      customCompatibility: aiCustomCompatibility,
    );
    await prefs.setString('aiModel', aiModel);
  }

  runApp(
    UntisPlusApp(
      startScreen: (isLoggedIn || demoModeNotifier.value)
          ? MainNavigationScreen(
              showTutorialOnStart: onboardingCompleted && !tutorialCompleted,
            )
          : const OnboardingFlow(),
    ),
  );

  unawaited(checkGithubUpdateAndNotify());
}

Uri _webUntisRpcUri({String? serverUrl, String? school}) {
  final resolvedServer = serverUrl ?? schoolUrl;
  final resolvedSchool = school ?? schoolName;
  return Uri.parse(
    'https://$resolvedServer/WebUntis/jsonrpc.do?school=$resolvedSchool',
  );
}

Uri _webUntisInternRpcUri({String? serverUrl, String? school}) {
  final resolvedServer = serverUrl ?? schoolUrl;
  final resolvedSchool = school ?? schoolName;
  return Uri.parse(
    'https://$resolvedServer/WebUntis/jsonrpc_intern.do?school=$resolvedSchool',
  );
}

String _normalizeWebUntisSecret(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  if (trimmed.startsWith('otpauth://')) {
    return OTPUri.extractSecret(
      trimmed,
    ).trim().replaceAll(' ', '').toUpperCase();
  }

  if (trimmed.startsWith('untis://')) {
    final uri = Uri.tryParse(trimmed);
    final extracted =
        uri?.queryParameters['key'] ?? uri?.queryParameters['secret'] ?? '';
    if (extracted.isNotEmpty) {
      return extracted.trim().replaceAll(' ', '').toUpperCase();
    }
  }

  return trimmed.replaceAll(' ', '').toUpperCase();
}

String _generateWebUntisOtp(String credential) {
  final secret = _normalizeWebUntisSecret(credential);
  if (secret.isEmpty) {
    throw ArgumentError('WebUntis secret must not be empty.');
  }

  final totp = TOTP(
    secret: secret,
    digits: 6,
    algorithm: OTPAlgorithm.sha1,
    period: 30,
  );
  return totp.now();
}

Future<Map<String, dynamic>?> _authenticateUntisWithSecret({
  required String user,
  required String secret,
  required String client,
  String requestId = 'auth',
  String? serverUrl,
  String? school,
}) async {
  final otp = _generateWebUntisOtp(secret);
  final response = await http.post(
    _webUntisInternRpcUri(serverUrl: serverUrl, school: school),
    body: jsonEncode({
      'id': requestId,
      'method': 'getUserData2017',
      'params': [
        {
          'auth': {
            'clientTime': DateTime.now().millisecondsSinceEpoch,
            'user': user,
            'otp': otp,
          },
        },
      ],
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

  final error = decoded['error'];
  if (error is Map) {
    final err = Map<String, dynamic>.from(error);
    final message = (err['message'] ?? '').toString();
    final data = (err['data'] ?? '').toString();
    final combined = '${message.toLowerCase()} ${data.toLowerCase()}';
    if (combined.contains('otp') ||
        combined.contains('secret') ||
        combined.contains('login')) {
      return {
        'otpInvalid': true,
        'errorCode': err['code'],
        'errorMessage': message,
      };
    }
  }

  if (!response.headers.containsKey('set-cookie')) {
    return null;
  }

  final cookie = response.headers['set-cookie'];
  if (cookie == null || cookie.isEmpty) {
    return null;
  }

  final sessionId =
      RegExp(r'JSESSIONID=([^;]+)').firstMatch(cookie)?.group(1) ?? '';
  if (sessionId.isEmpty) {
    return null;
  }

  final appConfigResponse = await http.get(
    Uri.parse('https://${serverUrl ?? schoolUrl}/WebUntis/api/app/config'),
    headers: {
      'Cookie': 'JSESSIONID=$sessionId; schoolname=${school ?? schoolName}',
    },
  );

  if (appConfigResponse.statusCode != 200 ||
      appConfigResponse.body.trim().isEmpty) {
    return {'sessionId': sessionId};
  }

  final appConfigDecoded = jsonDecode(appConfigResponse.body);
  if (appConfigDecoded is! Map<String, dynamic>) {
    return {'sessionId': sessionId};
  }

  final data = appConfigDecoded['data'];
  final loginConfigUser = data is Map
      ? data['loginServiceConfig'] is Map
            ? (data['loginServiceConfig'] as Map)['user']
            : null
      : null;
  if (loginConfigUser is Map) {
    final personId = loginConfigUser['personId'];
    final persons = loginConfigUser['persons'];
    int? personType;
    if (persons is List) {
      final person = persons.cast<dynamic>().firstWhere(
        (entry) => entry is Map && entry['id'] == personId,
        orElse: () => null,
      );
      if (person is Map && person['type'] != null) {
        personType = int.tryParse(person['type'].toString());
      }
    }
    return {
      'sessionId': sessionId,
      'personId': int.tryParse(personId?.toString() ?? '') ?? 0,
      'personType': personType ?? 5,
    };
  }

  return {'sessionId': sessionId};
}

Future<Map<String, dynamic>?> _authenticateUntis({
  required String user,
  required String password,
  required String client,
  String requestId = 'auth',
  String? serverUrl,
  String? school,
  String? otp,
  bool useLoginKey = false,
}) async {
  if (useLoginKey) {
    return _authenticateUntisWithSecret(
      user: user,
      secret: password,
      client: client,
      requestId: requestId,
      serverUrl: serverUrl,
      school: school,
    );
  }

  final otpCode = otp?.trim();
  final params = <String, dynamic>{
    'user': user,
    'password': password,
    'client': client,
  };
  if (otpCode != null && otpCode.isNotEmpty) {
    params['otp'] = otpCode;
  }

  final response = await http.post(
    _webUntisRpcUri(serverUrl: serverUrl, school: school),
    body: jsonEncode({
      'id': requestId,
      'method': 'authenticate',
      'params': params,
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

  final error = decoded['error'];
  if (error is Map) {
    final err = Map<String, dynamic>.from(error);
    final message = (err['message'] ?? '').toString();
    final data = (err['data'] ?? '').toString();
    final combined = '${message.toLowerCase()} ${data.toLowerCase()}';
    final contains2faHint =
        combined.contains('2fa') ||
        combined.contains('two factor') ||
        combined.contains('mfa') ||
        combined.contains('otp') ||
        combined.contains('one-time') ||
        combined.contains('verification code') ||
        combined.contains('authenticator');

    if (contains2faHint && (otpCode == null || otpCode.isEmpty)) {
      return {
        'requires2fa': true,
        'errorCode': err['code'],
        'errorMessage': message,
      };
    }

    // Treat any server error as an invalid OTP when a code was provided, so
    // the caller can show the 2FA-specific error instead of the generic
    // "check your credentials" message.
    final invalidOtp =
        combined.contains('invalid otp') ||
        combined.contains('invalid verification') ||
        combined.contains('wrong otp') ||
        combined.contains('otp invalid') ||
        (otpCode != null && otpCode.isNotEmpty);
    if (invalidOtp) {
      return {
        'otpInvalid': true,
        'errorCode': err['code'],
        'errorMessage': message,
      };
    }
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
  List<Map<String, dynamic>> _holidays = [];
  bool _loading = true;
  String? _loadError;
  bool _showingCachedWeek = false;
  int _viewMode = 0;
  // Carousel state for week switching
  double _carouselOffset = 0.0;
  AnimationController? _carouselAnimController;
  final Map<String, Map<int, List<dynamic>>> _adjacentWeekCache = {};
  // Day swipe carousel state
  double _dayOffset = 0.0;
  AnimationController? _dayAnimController;

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

  String _mondayKey(DateTime monday) => DateFormat('yyyyMMdd').format(monday);

  String _weekCacheKeyFor({
    required DateTime monday,
    required int requestPersonId,
    required int requestPersonType,
  }) {
    final mondayStr = DateFormat('yyyyMMdd').format(monday);
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
      final prefs = await SharedPreferences.getInstance();
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
      final prefs = await SharedPreferences.getInstance();
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
        if (_holidays.isNotEmpty)
          'holidays': _holidays,
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
    if (defaultClassId != null) {
      _viewingClassId = defaultClassId;
      _viewingClassName = defaultClassName;
    }
    hiddenSubjectsNotifier.addListener(_onHiddenSubjectsChanged);
    subjectColorsNotifier.addListener(_onHiddenSubjectsChanged);
    showCancelledNotifier.addListener(_onHiddenSubjectsChanged);
    demoModeNotifier.addListener(_onDemoModeChanged);
    pendingTimetableActionNotifier.addListener(_onPendingTimetableAction);
    if (sessionID.isNotEmpty || demoModeNotifier.value) {
      _fetchFullWeek();
      _prefetchAdjacentWeeks();
    }
    _loadViewPref();
  }

  void _onPendingTimetableAction() {
    if (!mounted) return;
    final action = pendingTimetableActionNotifier.value;
    if (action == null || action.isEmpty) return;

    final l = AppL10n.of(appLocaleNotifier.value);
    final current = (pendingTimetableCurrentLessonNotifier.value ?? '').trim();
    final next = (pendingTimetableNextLessonNotifier.value ?? '').trim();

    pendingTimetableActionNotifier.value = null;

    if (action == 'open_free_rooms') {
      _showFreeRoomsDialog();
      return;
    }

    if (action == 'open_next_lesson') {
      final text = next.isNotEmpty
          ? l.notificationActionNextLesson(next)
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

  Future<void> _loadViewPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _viewMode = (prefs.getInt('viewMode') ?? 0).clamp(0, 1));
    }
  }

  bool _isNoAllowedDateError(String message) {
    final m = message.toLowerCase();
    return m.contains('no allowed date') ||
        m.contains('no allowed dates') ||
        m.contains('nicht erlaubtes datum');
  }

  void _navigateToWeek(DateTime newMonday, int direction) {
    final cacheKey = _mondayKey(newMonday);
    final cached = _adjacentWeekCache[cacheKey];
    setState(() {
      _currentMonday = newMonday;
      if (cached != null) {
        _weekData = cached;
        _showingCachedWeek = true;
        _loading = false;
      }
    });
    _fetchFullWeek();
  }

  void _prevWeek() {
    HapticFeedback.selectionClick();
    _navigateToWeek(
      _currentMonday.subtract(const Duration(days: 7)),
      -1,
    );
  }

  void _nextWeek() {
    HapticFeedback.selectionClick();
    _navigateToWeek(
      _currentMonday.add(const Duration(days: 7)),
      1,
    );
  }

  Future<void> _toggleView() async {
    HapticFeedback.selectionClick();
    setState(() => _viewMode = (_viewMode + 1) % 2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('viewMode', _viewMode);
  }

  Future<void> _onRefresh() => _fetchFullWeek(silent: true);

  void _onHiddenSubjectsChanged() => setState(() {});

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

  Future<void> _prefetchAdjacentWeeks() async {
    if (demoModeNotifier.value) return;
    final pid = _viewingClassId ?? personId;
    final pType = _viewingClassId != null ? 1 : personType;
    if (pid == 0) return;
    await _fetchMasterData();
    for (final delta in [-1, 1, 2]) {
      final adjMonday = _weekMondayFromDelta(delta);
      final key = _mondayKey(adjMonday);
      if (_adjacentWeekCache.containsKey(key)) continue;
      try {
        DateTime friday = adjMonday.add(const Duration(days: 4));
        int startDate = int.parse(DateFormat('yyyyMMdd').format(adjMonday));
        int endDate = int.parse(DateFormat('yyyyMMdd').format(friday));
        final url = Uri.parse(
          'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
        );
        final response = await http.post(
          url,
          headers: {
            "Cookie": "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          body: jsonEncode({
            "id": "week_prefetch",
            "method": "getTimetable",
            "params": {
              "options": {
                "element": {"id": pid, "type": pType},
                "startDate": startDate,
                "endDate": endDate,
                "showLsText": true,
                "showSubstText": true,
                "showInfo": true,
                "showBooking": true,
              },
            },
            "jsonrpc": "2.0",
          }),
        );
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['error'] == null && decoded['result'] != null) {
            final tempWeek = _parseWeekResult(decoded['result']);
            if (tempWeek != null) {
              _adjacentWeekCache[key] = tempWeek;
              await _saveWeekToCache(
                requestPersonId: pid,
                requestPersonType: pType,
                weekData: tempWeek,
                monday: adjMonday,
              );
            }
          }
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
      final dayStr = day.toString();
      final date = DateTime.tryParse(
        '${dayStr.substring(0, 4)}-${dayStr.substring(4, 6)}-${dayStr.substring(6, 8)}',
      );
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
        lesson['_teacher'] = tId != null
            ? (_teacherMap[tId] ??
                (firstTeacher['name']?.toString() ?? '?'))
            : '?';
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
                    firstSubject['name']?.toString() ?? '?'))
            : '?';
      }
    }
    final roList = (lesson['ro'] as List?) ?? [];
    if (roList.isNotEmpty) {
      final firstRoom = roList.first as Map?;
      if (firstRoom != null) {
        final rId = firstRoom['id'] as int?;
        lesson['_room'] = rId != null
            ? (_roomMap[rId] ??
                (firstRoom['name']?.toString() ?? '?'))
            : '?';
      }
    }
  }

  Widget _buildAdjacentWeekView(int direction) {
    final adjMonday = _weekMondayFromDelta(direction);
    final cached = _getAdjacentWeekData(adjMonday);
    if (cached != null) {
      return _buildWeekView(monday: adjMonday, weekData: cached);
    }
    final l = AppL10n.of(appLocaleNotifier.value);
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

  // ── DAY CAROUSEL ─────────────────────────────────────────────────
  Widget _buildDayCarousel() {
    return GestureDetector(
      onHorizontalDragStart: _onDayDragStart,
      onHorizontalDragUpdate: _onDayDragUpdate,
      onHorizontalDragEnd: _onDayDragEnd,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final offset = _dayOffset.clamp(-w, w);
          final double progress = (offset / w).abs().clamp(0.0, 1.0);
          final double curveP = Curves.easeOut.transform(progress);

          final double currentScale = 1.0 - (0.04 * curveP);
          final double currentOpacity = ((1.0 - progress) * 2.0).clamp(0.0, 1.0);
          final int currentDay = _tabController.index;
          final bool goingRight = offset > 0;
          final int adjacentDay = goingRight ? currentDay - 1 : currentDay + 1;
          final bool adjacentExists = adjacentDay >= 0 && adjacentDay <= 4;
          final double incomingScale = 0.96 + (0.04 * curveP);
          final double incomingOpacity = (progress * 2.0).clamp(0.0, 1.0);

          return ClipRect(
            child: Stack(
              children: [
                // Adjacent (incoming) day
                if (adjacentExists && offset != 0.0)
                  Transform.translate(
                    offset: Offset(goingRight ? -w + offset : w + offset, 0),
                    child: Transform.scale(
                      scale: incomingScale,
                      child: Opacity(
                        opacity: incomingOpacity,
                        child: SizedBox(width: w, child: _buildGridView(adjacentDay)),
                      ),
                    ),
                  ),
                // Current day
                Transform.translate(
                  offset: Offset(offset, 0),
                  child: Transform.scale(
                    scale: currentScale,
                    child: Opacity(
                      opacity: currentOpacity,
                      child: SizedBox(
                        width: w,
                        child: KeyedSubtree(
                          key: ValueKey('day-$currentDay'),
                          child: _buildGridView(currentDay),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onDayDragStart(DragStartDetails _) {
    _dayAnimController?.stop();
    setState(() => _dayOffset = 0.0);
  }

  void _onDayDragUpdate(DragUpdateDetails details) {
    final current = _tabController.index;
    final dx = details.delta.dx;
    if (dx > 0 && current == 0) return;
    if (dx < 0 && current == 4) return;
    setState(() => _dayOffset += dx);
  }

  void _onDayDragEnd(DragEndDetails details) {
    final width = (context.findRenderObject() as RenderBox?)?.size.width ?? 400.0;
    final velocity = details.primaryVelocity ?? 0;
    final threshold = width * 0.12;

    if (_dayOffset < -threshold || velocity < -200) {
      _snapDayCarousel(-1, width);
    } else if (_dayOffset > threshold || velocity > 200) {
      _snapDayCarousel(1, width);
    } else {
      _snapDayCarousel(0, width);
    }
  }

  void _snapDayCarousel(int direction, double width) {
    if (direction != 0) {
      // Update tab immediately so TabBar highlights the right day
      if (direction < 0 && _tabController.index == 4) {
        HapticFeedback.selectionClick();
        _nextWeek();
        _tabController.index = 0;
      } else if (direction > 0 && _tabController.index == 0) {
        HapticFeedback.selectionClick();
        _prevWeek();
        _tabController.index = 4;
      } else {
        HapticFeedback.selectionClick();
        _tabController.index = (_tabController.index - direction).clamp(0, 4);
      }
    }

    final target = direction == 0 ? 0.0 : (direction < 0 ? -width : width);
    _dayAnimController?.dispose();
    _dayAnimController = AnimationController(
      vsync: this,
      duration: direction == 0
          ? const Duration(milliseconds: 250)
          : const Duration(milliseconds: 300),
    );
    final anim = Tween<double>(begin: _dayOffset, end: target).animate(
      CurvedAnimation(
        parent: _dayAnimController!,
        curve: direction == 0 ? Curves.easeOutCubic : Curves.easeOutQuart,
      ),
    );
    _dayAnimController!.addListener(() {
      if (!mounted) return;
      setState(() => _dayOffset = anim.value);
    });
    _dayAnimController!.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _dayOffset = 0.0);
      }
    });
    _dayAnimController!.forward();
  }

  // ── WEEK CAROUSEL ─────────────────────────────────────────────────
  Widget _buildWeekCarousel() {
    return GestureDetector(
      onHorizontalDragStart: _onCarouselDragStart,
      onHorizontalDragUpdate: _onCarouselDragUpdate,
      onHorizontalDragEnd: _onCarouselDragEnd,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final offset = _carouselOffset.clamp(-w, w);
          final double progress = (offset / w).abs().clamp(0.0, 1.0);
          
          final double currentScale = 1.0 - (0.05 * Curves.easeOut.transform(progress));
          final double currentOpacity = ((1.0 - progress) * 1.5).clamp(0.0, 1.0);
          final double incomingScale = 0.95 + (0.05 * Curves.easeOut.transform(1.0 - progress));
          final double incomingOpacity = (progress * 1.5).clamp(0.0, 1.0);

          return ClipRect(
            child: Stack(
              children: [
                if (offset > 0)
                  Transform.translate(
                    offset: Offset(-w + offset, 0),
                    child: Transform.scale(
                      scale: incomingScale,
                      child: Opacity(
                        opacity: incomingOpacity,
                        child: SizedBox(
                          width: w,
                          child: _buildAdjacentWeekView(-1),
                        ),
                      ),
                    ),
                  ),
                if (offset < 0)
                  Transform.translate(
                    offset: Offset(w + offset, 0),
                    child: Transform.scale(
                      scale: incomingScale,
                      child: Opacity(
                        opacity: incomingOpacity,
                        child: SizedBox(
                          width: w,
                          child: _buildAdjacentWeekView(1),
                        ),
                      ),
                    ),
                  ),
                Transform.translate(
                  offset: Offset(offset, 0),
                  child: Transform.scale(
                    scale: currentScale,
                    child: Opacity(
                      opacity: currentOpacity,
                      child: SizedBox(
                        width: w,
                        child: KeyedSubtree(
                          key: ValueKey(
                            'carousel-${DateFormat('yyyyMMdd').format(_currentMonday)}',
                          ),
                          child: _buildWeekView(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onCarouselDragStart(DragStartDetails details) {
    setState(() {
      _carouselOffset = 0;
    });
    _prefetchAdjacentWeeks();
  }

  void _onCarouselDragUpdate(DragUpdateDetails details) {
    setState(() {
      _carouselOffset += details.delta.dx;
    });
  }

  void _onCarouselDragEnd(DragEndDetails details) {
    final width = context.findRenderObject() != null
        ? (context.findRenderObject()! as RenderBox).size.width
        : 400.0;
    final threshold = width * 0.12;
    final velocity = details.primaryVelocity ?? 0;

    if (_carouselOffset < -threshold || velocity < -200) {
      _animateCarouselTo(-1, width);
    } else if (_carouselOffset > threshold || velocity > 200) {
      _animateCarouselTo(1, width);
    } else {
      _animateCarouselTo(0, width);
    }
  }

  void _animateCarouselTo(int direction, double width) {
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
        }
      });
      _carouselAnimController!.forward();
      return;
    }

    final target = direction * width;
    _carouselAnimController?.dispose();
    _carouselAnimController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    final anim = Tween<double>(begin: _carouselOffset, end: target).animate(
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
        final newMonday = direction > 0
            ? _currentMonday.subtract(const Duration(days: 7))
            : _currentMonday.add(const Duration(days: 7));
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
        });
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
    showCancelledNotifier.removeListener(_onHiddenSubjectsChanged);
    demoModeNotifier.removeListener(_onDemoModeChanged);
    pendingTimetableActionNotifier.addListener(_onPendingTimetableAction);
    _tabController.dispose();
    _carouselAnimController?.dispose();
    _dayAnimController?.dispose();
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

  List<_TimeRangeLabel> _collectTimeRangesFromWeek() =>
      _collectTimeRangesFromData(_weekData);

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
        if ((lesson['code'] ?? '') == 'cancelled') continue;
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
    final dayStr = DateFormat('yyyyMMdd').format(day);
    final dayInt = int.tryParse(dayStr);
    if (dayInt == null) return [];
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final classes = await _fetchClasses();
    List<List<dynamic>> timetables = [];
    if (classes.isNotEmpty) {
      final results = await Future.wait(
        classes.map((c) => _fetchClassTimetable(c['id'] as int, dayDate)),
        eagerError: false,
      );
      timetables = results.whereType<List<dynamic>>().toList();
    }

    final freeRoomsForRange = <List<String>>[
      for (final range in ranges)
        _computeFreeRooms(
          timetables: timetables,
          startMin: range.startMin,
          endMin: range.endMin,
        ),
    ];

    if (!mounted) return;
    if (context.mounted) Navigator.of(context).pop();

    await showModalBottomSheet<void>(
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
    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );

    Future<List<dynamic>> fetchClassesForSession(String sid) async {
      final response = await http.post(
        url,
        headers: {"Cookie": "JSESSIONID=$sid; schoolname=$schoolName"},
        body: jsonEncode({
          "id": "fr_cl",
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

    List<dynamic> classes = [];
    if (sessionID.isNotEmpty) {
      try {
        classes = await fetchClassesForSession(sessionID);
      } catch (_) {}
    }
    if (classes.isEmpty) {
      try {
        final anonSid = await _authenticateAnonymous();
        if (anonSid != null && anonSid.isNotEmpty) {
          classes = await fetchClassesForSession(anonSid);
        }
      } catch (_) {}
    }
    return classes.cast<Map<String, dynamic>>();
  }

  Future<List<dynamic>> _fetchClassTimetable(int classId, DateTime date) async {
    final dateInt = int.parse(DateFormat('yyyyMMdd').format(date));
    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );
    try {
      final response = await http.post(
        url,
        headers: {
          "Cookie": "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "id": "fr_tt_$classId",
          "method": "getTimetable",
          "params": {
            "options": {
              "element": {"id": classId, "type": 1},
              "startDate": dateInt,
              "endDate": dateInt,
              "showRooms": true,
              "showSubjects": true,
              "showTeachers": true,
              "showClasses": true,
            },
          },
          "jsonrpc": "2.0",
        }),
      );
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      if (data is Map && data['result'] is List) {
        return data['result'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
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

  Widget _buildTimetableLessonCard({
    required BuildContext context,
    required bool isCancelled,
    required bool isDark,
    required Color fgColor,
    required Color bgColor,
    required String subject,
    required String teacher,
    required String room,
    required bool isNow,
    required double borderRadius,
    required EdgeInsets padding,
    required double accentWidth,
    required double subjectFontSize,
    required double teacherFontSize,
    required double roomFontSize,
    required bool useStripes,
  }) {
    final cardRadius = BorderRadius.circular(borderRadius);
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: cardRadius,
        boxShadow: isNow
            ? [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: Stack(
          children: [
            // Base background
            Container(
              decoration: BoxDecoration(
                color: isCancelled ? bgColor.withValues(alpha: 0.5) : bgColor,
                borderRadius: cardRadius,
                border: Border.all(
                  color: fgColor.withValues(alpha: 0.16),
                  width: 0.8,
                ),
              ),
            ),

            // Left accent bar instead of gradient
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: accentWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: fgColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    bottomLeft: Radius.circular(borderRadius),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: subjectFontSize,
                      fontWeight: FontWeight.w800,
                      color: isCancelled ? fgColor.withValues(alpha: 0.6) : fgColor,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                      decorationColor: fgColor.withValues(alpha: 0.5),
                      decorationThickness: 1.6,
                    ),
                  ),
                  if (teacher.isNotEmpty)
                    Text(
                      teacher,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: teacherFontSize,
                        fontWeight: FontWeight.w600,
                        color: isCancelled
                            ? fgColor.withValues(alpha: 0.48)
                            : fgColor.withValues(alpha: 0.72),
                      ),
                    ),
                  if (room.isNotEmpty)
                    Text(
                      room,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: roomFontSize,
                        fontWeight: FontWeight.w600,
                        color: isCancelled
                            ? fgColor.withValues(alpha: 0.48)
                            : fgColor.withValues(alpha: 0.72),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
                                          fontWeight: FontWeight.w600,
                                  color: csG.onSurfaceVariant.withValues(
                                            alpha: 0.54,
                                  ),
                                ),
                              ),
                              Text(
                                _formatMinutes(range.endMin),
                                textAlign: TextAlign.right,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: csG.onSurfaceVariant.withValues(
                                            alpha: 0.45,
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
                              height: 0.45,
                              color: csG.outlineVariant.withValues(
                                alpha: 0.28,
                              ),
                            ),
                          );
                        }),
                        ..._getHolidaysForDay(dayDate).map((holiday) {
                          final holidayStartMin = _toMinutes(800);
                          final holidayEndMin = _toMinutes(1800);
                          final top = (holidayStartMin - globalMin) * _ppm;
                          final height = ((holidayEndMin - holidayStartMin) * _ppm).clamp(28.0, 9999.0);
                          final holidayName = (holiday['longName'] ?? holiday['name'] ?? '').toString();
                          return Positioned(
                            top: top,
                            left: 2,
                            right: 2,
                            height: height,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: csG.tertiaryContainer.withValues(alpha: 0.85),
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
                                    Icon(Icons.celebration_rounded, size: 20, color: csG.tertiary),
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
                                  final isCancelled = (l['code'] ?? '') == 'cancelled';
                                  final sk = l['_subjectShort']?.toString() ?? '';
                                  final useMonochrome = monochromeLessonsNotifier.value;
                                  final cancelledColor = Color(cancelledLessonColorNotifier.value);
                                  final cv = isCancelled || useMonochrome
                                      ? null
                                      : subjectColorsNotifier.value[sk];
                                  final fgColor = isCancelled
                                      ? cancelledColor
                                      : useMonochrome
                                      ? cs.primary
                                      : cv != null
                                      ? Color(cv)
                                      : _autoLessonColor(sk, isDark);
                                  final bgColor = isCancelled
                                      ? Color.alphaBlend(
                                          cancelledColor.withValues(alpha: 0.10),
                                          cs.surfaceContainerHighest,
                                        )
                                      : Color.alphaBlend(
                                          fgColor.withValues(
                                            alpha: isDark ? 0.14 : 0.10,
                                          ),
                                          cs.surfaceContainerHighest,
                                        );
                                  final subject =
                                      l['_subjectShort']?.toString().isNotEmpty ==
                                              true
                                          ? l['_subjectShort'].toString()
                                          : (l['_subjectLong']?.toString().isNotEmpty ==
                                                  true
                                              ? l['_subjectLong'].toString()
                                              : '?');
                                  final room = l['_room']?.toString() ?? '';
                                  final teacher = l['_teacher']?.toString() ?? '';
                                  final isNow =
                                      (startMin <= nowMin && nowMin < endMin);

                                  return GestureDetector(
                                    onTap: () => _showLessonDetail(context, l),
                                    child: _buildTimetableLessonCard(
                                      context: context,
                                      isCancelled: isCancelled,
                                      isDark: isDark,
                                      fgColor: fgColor,
                                      bgColor: bgColor,
                                      subject: subject,
                                      teacher: teacher,
                                      room: room,
                                      isNow: isNow,
                                      borderRadius: 12,
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        5,
                                        6,
                                        5,
                                      ),
                                      accentWidth: 3,
                                      subjectFontSize: 11.5,
                                      teacherFontSize: 9.5,
                                      roomFontSize: 9.5,
                                      useStripes: true,
                                    ),
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
  }) {
    final m = monday ?? _currentMonday;
    final wd = weekData ?? _weekData;
    final media = MediaQuery.of(context);
    final topContentPadding = media.padding.top + kToolbarHeight + 10;

    int globalMin = 480;
    int globalMax = 900;
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

    final totalHeight = (globalMax - globalMin) * _ppm;

    final List<int> ticks = [];
    for (int min = globalMin - (globalMin % 60) + 60; min < globalMax; min += 60) {
      ticks.add(min);
    }

    const double timeColWidth = 52.0;
    const double minDayColWidth = 56.0;
    const double dayColGap = 4.0;
    final timeRanges = _collectTimeRangesFromData(wd);
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();

    final todayDate = DateTime(today.year, today.month, today.day);
    final mondayDate = DateTime(
      m.year,
      m.month,
      m.day,
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
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 32,
          top: topContentPadding,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableForDays = math.max(
              5 * minDayColWidth,
              constraints.maxWidth - timeColWidth - 6 - (dayColGap * 4),
            );
            final dayColWidth = availableForDays / 5;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: timeColWidth + 6,
                    bottom: 6,
                  ),
                  child: Row(
                    children: List.generate(5, (i) {
                      final d = m.add(Duration(days: i));
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
                                      : cs.onSurfaceVariant.withValues(
                                          alpha: 0.8,
                                        ),
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
                                    color: isToday
                                        ? cs.onPrimary
                                        : cs.onSurface,
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
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurfaceVariant.withValues(
                                            alpha: 0.54,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatMinutes(range.endMin),
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurfaceVariant.withValues(
                                            alpha: 0.45,
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
                                      color: cs.onSurfaceVariant.withValues(
                                        alpha: 0.7,
                                      ),
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
                                        height: 0.45,
                                        color: cs.outlineVariant.withValues(
                                          alpha: 0.28,
                                        ),
                                      ),
                                    );
                                  }),
                                  ..._getHolidaysForDay(m.add(Duration(days: dayIndex))).map((holiday) {
                                    final holidayStartMin = _toMinutes(800);
                                    final holidayEndMin = _toMinutes(1800);
                                    final top2 = (holidayStartMin - globalMin) * _ppm;
                                    final height2 = ((holidayEndMin - holidayStartMin) * _ppm).clamp(24.0, 9999.0);
                                    final holidayName = (holiday['longName'] ?? holiday['name'] ?? '').toString();
                                    return Positioned(
                                      top: top2,
                                      left: 1,
                                      right: 1,
                                      height: height2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: cs.tertiaryContainer.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: cs.tertiary.withValues(alpha: 0.4),
                                            width: 1.5,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.celebration_rounded, size: 16, color: cs.tertiary),
                                            const SizedBox(height: 2),
                                            Expanded(
                                              child: Text(
                                                holidayName,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: cs.onTertiaryContainer,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
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
                                    final top = (startMin - globalMin) * _ppm;
                                    final height = ((endMin - startMin) * _ppm)
                                        .clamp(24.0, 9999.0);
                                    final dim =
                                        (dayIndex == todayIndex) &&
                                        endMin <= nowMin;
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

                                    return Positioned(
                                      top: top,
                                      left: left,
                                      width: cardWidth,
                                      height: height,
                                      child: Builder(
                                        builder: (context) {
                                          final cs = Theme.of(context).colorScheme;
                                          final isDark2 =
                                              Theme.of(context).brightness ==
                                              Brightness.dark;
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
                                                        ? l['_subjectLong']
                                                            .toString()
                                                        : '?');
                                          final room = l['_room']?.toString() ?? '';
                                          final teacher =
                                              l['_teacher']?.toString() ?? '';
                                          final sk2 =
                                              l['_subjectShort']?.toString() ?? '';
                                          final useMonochrome2 = monochromeLessonsNotifier.value;
                                          final cancelledColor2 = Color(cancelledLessonColorNotifier.value);
                                          final cv2 = isCancelled || useMonochrome2
                                              ? null
                                              : subjectColorsNotifier.value[sk2];
                                          final fgColor = isCancelled
                                              ? cancelledColor2
                                              : useMonochrome2
                                              ? cs.primary
                                              : cv2 != null
                                              ? Color(cv2)
                                              : _autoLessonColor(sk2, isDark2);
                                          final bgColor = isCancelled
                                              ? Color.alphaBlend(
                                                  cancelledColor2.withValues(alpha: 0.10),
                                                  cs.surfaceContainerHighest,
                                                )
                                              : Color.alphaBlend(
                                                  fgColor.withValues(
                                                    alpha: isDark2 ? 0.14 : 0.10,
                                                  ),
                                                  cs.surfaceContainerHighest,
                                                );
                                          final isNow = (dayIndex == todayIndex) &&
                                              (slot.startMin <= nowMin &&
                                                  nowMin < slot.endMin);

                                          return _dimPastLesson(
                                            dim: dim,
                                            child: GestureDetector(
                                              onTap: () =>
                                                  _showLessonDetail(context, l),
                                              child: _buildTimetableLessonCard(
                                                context: context,
                                                isCancelled: isCancelled,
                                                isDark: isDark2,
                                                fgColor: fgColor,
                                                bgColor: bgColor,
                                                subject: subject,
                                                teacher: teacher,
                                                room: room,
                                                isNow: isNow,
                                                borderRadius: 12,
                                                padding: const EdgeInsets.fromLTRB(
                                                  8,
                                                  4,
                                                  5,
                                                  4,
                                                ),
                                                accentWidth: 3,
                                                subjectFontSize: 10,
                                                teacherFontSize: 9,
                                                roomFontSize: 9,
                                                useStripes: true,
                                              ),
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
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: cs.error.withValues(
                                                      alpha: 0.35,
                                                    ),
                                                    blurRadius: 3,
                                                    spreadRadius: 0.5,
                                                  ),
                                                ],
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
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: cs.error.withValues(
                                                        alpha: 0.25,
                                                      ),
                                                      blurRadius: 3,
                                                    ),
                                                  ],
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _fetchHolidays() async {
    try {
      final url = Uri.parse(
        'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
      );
      final response = await http.post(
        url,
        headers: {
          "Cookie": "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "id": "holidays",
          "method": "getHolidays",
          "params": {},
          "jsonrpc": "2.0",
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['result'] is List) {
          final holidays = (decoded['result'] as List).whereType<Map>().map(
            (h) => Map<String, dynamic>.from(h.cast<String, dynamic>()),
          ).toList();
          if (mounted) {
            setState(() => _holidays = holidays);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchFullWeek({bool silent = false}) async {
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

    setState(() {
      if (!silent) _loading = true;
      _loadError = null;
    });

    if (isDemoMode) {
      final tempWeek = DemoModeService.buildWeek(_currentMonday, locale: 'en');
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
        _loadError = null;
      });
      return;
    }

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
            "options": {
              "element": {
                "id": requestPersonId,
                "type": requestPersonType,
              },
              "startDate": startDate,
              "endDate": endDate,
              "showLsText": true,
              "showSubstText": true,
              "showInfo": true,
              "showBooking": true,
            },
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

            final lstext = (lesson['lstext'] ?? '').toString().trim();
            final eventName = lstext.isNotEmpty ? lstext : (lesson['eventText'] ?? lesson['eventReason'] ?? '').toString().trim();
            final isAllDayEvent = (lesson['startTime'] == 0 && lesson['endTime'] != null);

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
            resolvedLesson['_room'] =
                (lesson['ro'] as List?)?.firstOrNull?['name'] ??
                _roomMap[roId] ??
                '';
            resolvedLesson['_classNames'] =
                (lesson['kl'] as List?)?.map((k) => k['name']?.toString() ?? '').where((n) => n.isNotEmpty).join(', ') ?? '';
            resolvedLesson['_activityType'] = (lesson['activityType'] ?? '').toString();
            resolvedLesson['_eventName'] = eventName;
            resolvedLesson['_lessonInfo'] = (lesson['info'] ?? lesson['substText'] ?? '').toString().trim();

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
                    "options": {
                      "element": {
                        "id": classId,
                        "type": 1,
                      },
                      "startDate": startDate,
                      "endDate": endDate,
                      "showLsText": true,
                      "showSubstText": true,
                      "showInfo": true,
                      "showBooking": true,
                    },
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

      await _fetchHolidays();

      if (!mounted) return;
      setState(() {
        _weekData = tempWeek;
        _showingCachedWeek = false;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Fehler beim Laden: $e");
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
        _loadError = errMsg;
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
    List<dynamic> classes = [];

    if (sessionID.isNotEmpty) {
      try {
        classes = await fetchClassesForSession(sessionID);
        if (classes.isNotEmpty) {
          sid = sessionID;
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
                          borderRadius: BorderRadius.circular(16),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                              final prefs = await SharedPreferences.getInstance();
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
                                color: cs.onSurfaceVariant.withValues(alpha: 0.94),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...sortedClasses.asMap().entries.map((entry) {
                              final i = entry.key;
                              final c = entry.value;
                              final name = (c['name'] ?? c['longName'] ?? '?').toString();
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
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: cs.outlineVariant.withValues(
                                          alpha: 0.54,
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        isFavorite ? Icons.star_rounded : Icons.class_outlined,
                                        color: isFavorite
                                            ? Colors.amber.shade600
                                            : cs.primary.withValues(alpha: 0.95),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: GoogleFonts.outfit(
                                                fontWeight: isFavorite ? FontWeight.bold : FontWeight.w500,
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
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: isFavorite
                                                ? l.classPickerRemoveFavorite
                                                : l.classPickerAddFavorite,
                                            icon: Icon(
                                              isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                                              color: isFavorite ? Colors.amber.shade600 : cs.onSurfaceVariant.withValues(alpha: 0.6),
                                            ),
                                            onPressed: () async {
                                              final prefs = await SharedPreferences.getInstance();
                                              setSheetState(() {
                                                if (isFavorite) {
                                                  favoriteClassIds.remove(id);
                                                } else {
                                                  favoriteClassIds.add(id);
                                                }
                                              });
                                              await prefs.setStringList(
                                                'favoriteClassIds',
                                                favoriteClassIds.map((id) => id.toString()).toList(),
                                              );
                                              setState(() {});
                                            },
                                          ),
                                          IconButton(
                                            tooltip: isDefault
                                                ? l.classPickerDefaultBadge
                                                : l.classPickerSetDefault,
                                            icon: Icon(
                                              isDefault ? Icons.home_rounded : Icons.add_rounded,
                                              color: isDefault ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.6),
                                            ),
                                            onPressed: () async {
                                              final prefs = await SharedPreferences.getInstance();
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
                                                await prefs.remove('defaultClassId');
                                                await prefs.remove('defaultClassName');
                                              } else {
                                                await prefs.setInt('defaultClassId', defaultClassId!);
                                                await prefs.setString('defaultClassName', defaultClassName!);
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
                  fontSize: 17,
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
                indicatorWeight: 3,
                labelStyle: GoogleFonts.outfit(
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
                  final now = DateTime.now();
                  final isToday = dayDate.year == now.year &&
                      dayDate.month == now.month &&
                      dayDate.day == now.day;
                  return Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _dayShort[i],
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          '${dayDate.day}.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.2,
                            color: isToday
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isToday)
                          Container(
                            width: 3,
                            height: 3,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 4),
                      ],
                    ),
                  );
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
                        child: Text(l.timetableReload),
                      ),
                    ],
                  ),
                ),
              )
             : _viewMode == 1
             ? _buildWeekCarousel()
            : _buildDayCarousel(),
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
      fitContentHeight: true,
      bottomMargin: 0,
      options: [
        _SheetOption(
          value: 'custom',
          title: l.examsActionCustom,
          icon: Icons.edit_note_rounded,
        ),
        _SheetOption(
          value: 'import',
          title: l.examsActionImport,
          icon: Icons.upload_file_rounded,
        ),
        _SheetOption(
          value: 'export',
          title: l.examsActionExport,
          icon: Icons.ios_share_rounded,
        ),
      ],
    );

    if (selected == 'custom') {
      _showAddExamDialog();
    } else if (selected == 'import') {
      _importExamsWithAI();
    } else if (selected == 'export') {
      _exportCustomExams();
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
    if (demoModeNotifier.value) {
      _apiExams = DemoModeService.demoExams();
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
          {
            'text':
                'Extrahiere strukturierte Prüfungsdaten und antworte nur mit JSON.',
          },
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
        {
          'role': 'system',
          'content':
              'Extrahiere strukturierte Prüfungsdaten aus dem Bild. Antworte ausschließlich als JSON-Array.',
        },
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
                          fillColor: cs.surfaceContainerHighest.withValues(
                            alpha: 0.45,
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
                          fillColor: cs.surfaceContainerHighest.withValues(
                            alpha: 0.45,
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
                          if (picked != null) {
                            setDlg(() => selectedDate = picked);
                          }
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
                                .withValues(alpha: 0.5),
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
                          fillColor: cs.surfaceContainerHighest.withValues(
                            alpha: 0.45,
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
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.08,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              AppL10n.of(appLocaleNotifier.value).examsCancel,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.08,
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
    final providerUsesGeminiProtocol = _providerUsesGeminiProtocol();
    final provider = _normalizeAiProvider(aiProvider);
    if (_activeAiApiKey().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_providerAwareMissingApiKeyMessage(l, provider)),
        ),
      );
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prompt =
          '''Du bist ein Assistent, der Klausurpläne von Schulen strukturiert erfasst.
Extrahiere alle relevanten Klausuren/Prüfungen aus dem angehängten Bild${providerUsesGeminiProtocol ? ' oder PDF' : ''}.
Antworte AUSSCHLIESSLICH im folgenden JSON Array Format (kein Markdown-Block, nur reines JSON, keine Grußformeln):
[
  {
    "subject": "Mathe",
    "examType": "Klausur",
    "date": "20240325",
    "description": "Ergänzende Infos oder leere Zeichenkette"
  }
]
WICHTIG: Das Datum MUSS als String im Format YYYYMMDD ausgegeben werden. Fehlt das Jahr, leite es aus dem aktuellen Datum (${DateTime.now().year}) ab. Wenn die Datei keine Klausuren enthält, gib ein leeres Array [] zurück.''';

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
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
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: InkWell(
        onTap: isCustom && customIndex != null
            ? () {
                HapticFeedback.selectionClick();
                _showAddExamDialog(
                  Map<String, dynamic>.from(exam)..remove('_source'),
                  customIndex,
                );
              }
            : null,
        child: Padding(
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
                          _chip(type, accent.withValues(alpha: 0.2), accent),
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
                          ? cs.errorContainer.withValues(alpha: 0.6)
                          : accent.withValues(alpha: 0.15),
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

String _buildDefaultAiPromptTemplate(AppL10n l) {
  return '''${l.aiSystemPersona}
Heute: [today]
Heute (ISO): [today_iso]
Sprache: [locale]
Schule: [school_name]
Server: [school_url]
Demo-Modus: [demo_mode]
Personentyp: [person_type]
Personen-ID: [person_id]
Wochenbereich: [current_monday] bis [current_friday]

HEUTE:
[day_summary_today]

MORGEN:
[day_summary_tomorrow]

STUNDENPLAN DIESE WOCHE:
[timetable]

PRUEFUNGEN:
[exams]

ROHDATEN STUNDENPLAN (JSON):
[timetable_json]

ROHDATEN PRUEFUNGEN (JSON):
[exams_json]

${l.aiSystemRules}

ANTWORTFORMAT:
- Antworte kurz und visuell.
- Nutze bevorzugt ein JSON-Objekt mit den Feldern: headline, summary, tags, metrics und lessons.
- metrics ist eine Liste von Objekten mit label und value.
- lessons ist eine Liste von Objekten mit subject, subjectShort, room, teacher, time und status.
- Vermeide lange Fließtexte.
- WICHTIG: Gib NUR Felder an, die für die Frage relevant sind. Wenn die Frage nach keiner Metrik oder keinen Stunden verlangt, lasse metrics bzw. lessons im JSON einfach weg oder gib leere Arrays zurück.''';
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

  List<String> get _quickPrompts {
    final suggestions = AppL10n.of(
      appLocaleNotifier.value,
    ).aiSuggestions.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (suggestions.isEmpty) return const [];

    final primary = suggestions.take(4).toList();

    final todayIdx = DateTime.now().weekday - 1;
    final hasTodayLessons =
        todayIdx >= 0 &&
        todayIdx < 5 &&
        (widget.weekData[todayIdx] ?? const []).isNotEmpty;
    final hasUpcomingExams = _exams.any((ex) {
      final raw = (ex['date'] ?? ex['examDate'] ?? ex['startDate'] ?? '')
          .toString();
      return raw.length == 8 &&
          (int.tryParse(raw) ?? 0) >=
              int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
    });

    if (hasTodayLessons && suggestions.length > 4) {
      primary.add(suggestions[4]);
    }
    if (hasUpcomingExams && suggestions.length > 5) {
      primary.add(suggestions[5]);
    }

    return primary.toSet().take(6).toList();
  }

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

    if (demoModeNotifier.value) {
      final demoExams = DemoModeService.demoExams();
      if (mounted) {
        setState(() {
          _exams = [
            ...demoExams.map((e) => {...e, '_source': 'demo'}),
            ...customExams.map((e) => {...e, '_source': 'custom'}),
          ];
          _exams.sort((a, b) {
            final da =
                int.tryParse(
                  (a['date'] ?? a['examDate'] ?? a['startDate'] ?? 0)
                      .toString(),
                ) ??
                0;
            final db =
                int.tryParse(
                  (b['date'] ?? b['examDate'] ?? b['startDate'] ?? 0)
                      .toString(),
                ) ??
                0;
            return da.compareTo(db);
          });
        });
      }
      return;
    }

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
      if (apiExams.isEmpty) {
        apiExams = await tryEndpoint('/WebUntis/api/classreg/exams');
      }
      if (apiExams.isEmpty && personId != 0) {
        apiExams = await tryEndpoint('/WebUntis/api/exams/student/$personId');
      }
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
    final l = AppL10n.of(appLocaleNotifier.value);
    if (_exams.isEmpty) return l.examsNoneEntered;
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

  String _defaultPromptTemplate(AppL10n l) {
    return _buildDefaultAiPromptTemplate(l);
  }

  String _daySummaryForPrompt(DateTime date) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final index = date.difference(widget.currentMonday).inDays;
    final dateLabel = DateFormat('dd.MM.yyyy').format(date);
    if (index < 0 || index > 4) {
      return '$dateLabel: ${l.noLesson}';
    }

    final lessons = widget.weekData[index] ?? const [];
    if (lessons.isEmpty) {
      return '$dateLabel: ${l.noLesson}';
    }

    final buf = StringBuffer('$dateLabel:\n');
    for (final lsn in lessons) {
      final start = _formatUntisTime(lsn['startTime'].toString());
      final end = _formatUntisTime(lsn['endTime'].toString());
      final subj = lsn['_subjectLong']?.toString().isNotEmpty == true
          ? lsn['_subjectLong'].toString()
          : lsn['_subjectShort']?.toString() ?? '?';
      final room = lsn['_room']?.toString() ?? '';
      final cancelled = (lsn['code'] ?? '') == 'cancelled';
      buf.write('- $start-$end $subj');
      if (room.isNotEmpty) buf.write(' (${l.detailRoom} $room)');
      if (cancelled) buf.write(' [${l.detailCancelled}]');
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  Object? _jsonSafeValue(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is List) {
      return value.map(_jsonSafeValue).toList();
    }
    if (value is Map) {
      final out = <String, Object?>{};
      value.forEach((key, entryValue) {
        out[key.toString()] = _jsonSafeValue(entryValue);
      });
      return out;
    }
    return value.toString();
  }

  Map<String, String> _promptVariables() {
    final now = DateTime.now();
    final icu = _icuLocale(appLocaleNotifier.value);
    final schedule = _formatWeekForAi(widget.weekData, widget.currentMonday);
    final examsStr = _formatExamsForAi();
    final friday = widget.currentMonday.add(const Duration(days: 4));
    return {
      '[today]': DateFormat('EEEE, dd. MMMM yyyy', icu).format(now),
      '[today_iso]': DateFormat('yyyy-MM-dd').format(now),
      '[locale]': appLocaleNotifier.value,
      '[school_name]': schoolName.isEmpty ? '-' : schoolName,
      '[school_url]': schoolUrl.isEmpty ? '-' : schoolUrl,
      '[person_type]': '$personType',
      '[person_id]': '$personId',
      '[demo_mode]': '${demoModeNotifier.value}',
      '[current_monday]': DateFormat('dd.MM.yyyy').format(widget.currentMonday),
      '[current_friday]': DateFormat('dd.MM.yyyy').format(friday),
      '[day_summary_today]': _daySummaryForPrompt(now),
      '[day_summary_tomorrow]': _daySummaryForPrompt(
        now.add(const Duration(days: 1)),
      ),
      '[timetable]': schedule,
      '[timetable_json]': jsonEncode(_jsonSafeValue(widget.weekData)),
      '[exams]': examsStr,
      '[exams_json]': jsonEncode(_jsonSafeValue(_exams)),
    };
  }

  String _resolvedSystemPrompt() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final template = aiSystemPromptTemplate.trim().isNotEmpty
        ? aiSystemPromptTemplate
        : _defaultPromptTemplate(l);
    final vars = _promptVariables().entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    var resolved = template;
    for (final entry in vars) {
      resolved = resolved.replaceAll(entry.key, entry.value);
    }
    return resolved;
  }

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

  List<Map<String, String>> _historyForProvider() {
    return _messages
        .map(
          (m) => {
            'role': m['role'] == 'user' ? 'user' : 'assistant',
            'content': m['content'] ?? '',
          },
        )
        .toList();
  }

  Future<String> _requestGeminiResponse({
    required String endpoint,
    required String apiKey,
    required String systemPrompt,
  }) async {
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
  }) async {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ..._historyForProvider(),
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

  Future<String> _requestProviderResponse(String systemPrompt) async {
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
        return _requestOpenAiCompatibleResponse(
          endpoint: 'https://api.openai.com/v1/chat/completions',
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
        );
      case 'mistral':
        return _requestOpenAiCompatibleResponse(
          endpoint: 'https://api.mistral.ai/v1/chat/completions',
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
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
          );
        }
        return _requestOpenAiCompatibleResponse(
          endpoint: _openAiCompatibleEndpoint(baseUrl),
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
        );
      case 'gemini':
      default:
        return _requestGeminiResponse(
          endpoint:
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
          apiKey: apiKey,
          systemPrompt: systemPrompt,
        );
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _thinking) return;

    if (_activeAiApiKey().trim().isEmpty) {
      final l = AppL10n.of(appLocaleNotifier.value);
      final provider = _normalizeAiProvider(aiProvider);
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': _providerAwareMissingApiKeyMessage(l, provider),
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
      final reply = await _requestProviderResponse(_resolvedSystemPrompt());
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
      });
    } catch (e) {
      final message = e.toString();
      final l = AppL10n.of(appLocaleNotifier.value);
      final isApiError = message.contains('API:');
      final isConfigError = message.contains('CONFIG:');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': isConfigError
              ? message.replaceFirst('Exception: CONFIG: ', '')
              : isApiError
              ? '${l.aiApiError} ${message.replaceFirst('Exception: API: ', '')}'
              : '${l.aiConnectionError} $e',
        });
      });
    } finally {
      if (mounted) setState(() => _thinking = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendQuickPrompt(String prompt) async {
    if (_thinking) return;
    _inputController.text = prompt;
    await _send();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: _kSoftBounce,
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
              color: enabled ? cs.surface.withValues(alpha: 0.78) : cs.surface,
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.surface.withValues(alpha: 0.85),
                      cs.surface.withValues(alpha: 0.78),
                      cs.surfaceContainerHigh.withValues(alpha: 0.66),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  )
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.4),
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
                          color: cs.onSurface.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cs.primaryContainer,
                                cs.tertiaryContainer,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
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
                            Text(
                              AppL10n.of(appLocaleNotifier.value).aiAskAnything,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
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
                    Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
                    if (_quickPrompts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _quickPrompts.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final prompt = _quickPrompts[index];
                            return ActionChip(
                              avatar: const Icon(Icons.bolt_rounded, size: 15),
                              label: Text(
                                prompt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: cs.primaryContainer.withValues(
                                alpha: 0.7,
                              ),
                              side: BorderSide.none,
                              onPressed: _thinking
                                  ? null
                                  : () => _sendQuickPrompt(prompt),
                            );
                          },
                        ),
                      ),
                    ],
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
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.surfaceContainerHigh.withValues(alpha: 0.72),
                        cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
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
                              color: cs.onSurface.withValues(alpha: 0.38),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
            color: cs.primary.withValues(alpha: 0.5),
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
          gradient: isUser
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, cs.secondary],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.surfaceContainerHigh.withValues(alpha: 0.72),
                    cs.surfaceContainerHighest.withValues(alpha: 0.58),
                  ],
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
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
                        color: cs.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: 0.55),
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
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
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
    _anim = Tween(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: _kSmoothBounce));
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
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
  final eventName = lesson['_eventName']?.toString() ?? '';
  final classNames = lesson['_classNames']?.toString() ?? '';
  final activityType = lesson['_activityType']?.toString() ?? '';

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
      eventName: eventName,
      classNames: classNames,
      activityType: activityType,
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
  final String eventName, classNames, activityType;
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
    this.eventName = '',
    this.classNames = '',
    this.activityType = '',
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
                  .withValues(alpha: 0.12),
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
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
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
    final cancelledColor = Color(cancelledLessonColorNotifier.value);
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
                  color: cs.onSurface.withValues(alpha: 0.12),
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
                  color: cancelledColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel_outlined, size: 16, color: cancelledColor),
                    const SizedBox(width: 6),
                    Text(
                      l.detailCancelled,
                      style: GoogleFonts.outfit(
                        color: cancelledColor,
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
                  color: cs.primary.withValues(alpha: 0.7),
                ),
              ),

            const SizedBox(height: 24),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 16),

            _row(context, Icons.access_time_rounded, l.detailTime, time),
            _row(context, Icons.person_rounded, l.detailTeacher, teacher),
            _row(context, Icons.room_rounded, l.detailRoom, room),
            if (classNames.isNotEmpty)
              _row(context, Icons.group_rounded, l.detailClass, classNames),
            if (activityType.isNotEmpty && activityType != 'Unterricht')
              _row(context, Icons.category_rounded, 'Art', activityType),
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
            Divider(color: cs.outlineVariant.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: onHideSubject,
              icon: const Icon(Icons.visibility_off_outlined, size: 18),
              label: Text(
                l.detailHideSubject,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface.withValues(alpha: 0.6),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
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
    final cancelledColor = Color(cancelledLessonColorNotifier.value);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.transparent, // Let child background handle color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        onTapDown: (_) => HapticFeedback.selectionClick(),
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
                    ? cancelledColor.withValues(alpha: enabled ? 0.18 : 0.22)
                    : (enabled
                          ? Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.88)
                          : Theme.of(context).colorScheme.surface),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.45),
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
                              ).colorScheme.primary.withValues(alpha: 0.7),
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
                      backgroundColor: cancelledColor,
                      textColor: cs.onError,
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
    if (demoModeNotifier.value) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
        _error = null;
        _lastUpdated = DateTime.now();
      });
      return;
    }

    if (sessionID.isEmpty || schoolUrl.isEmpty || schoolName.isEmpty) {
      final reAuthenticated = await _reAuthenticate();
      if (!reAuthenticated ||
          sessionID.isEmpty ||
          schoolUrl.isEmpty ||
          schoolName.isEmpty) {
        if (!mounted) return;
        setState(() {
          _items = const [];
          _loading = false;
          _error = null;
          _lastUpdated = DateTime.now();
        });
        return;
      }
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

    String encodedSchoolName() {
      try {
        return '_${base64Encode(utf8.encode(schoolName))}';
      } catch (_) {
        return schoolName;
      }
    }

    final schoolCookieCandidates = <String>{
      encodedSchoolName(),
      schoolName,
    }.where((e) => e.isNotEmpty).toList(growable: false);

    Map<String, String> buildHeaders(
      String schoolCookie, {
      Map<String, String>? extra,
    }) {
      return {
        'Cookie': 'JSESSIONID=$sessionID; schoolname=$schoolCookie',
        'Accept': 'application/json',
        ...?extra,
      };
    }

    Future<http.Response?> requestWithCookieFallback(
      Future<http.Response> Function(Map<String, String> headers) sender, {
      bool retry = true,
    }) async {
      for (final schoolCookie in schoolCookieCandidates) {
        try {
          final response = await sender(buildHeaders(schoolCookie));
          if (response.statusCode == 200) return response;
          if ((response.statusCode == 401 || response.statusCode == 403) &&
              retry &&
              await _reAuthenticate()) {
            return await requestWithCookieFallback(sender, retry: false);
          }
        } catch (_) {}
      }
      return null;
    }

    List<dynamic> extractList(dynamic decoded) {
      if (decoded is List) return decoded;
      if (decoded is Map) {
        for (final value in decoded.values) {
          final nested = extractList(value);
          if (nested.isNotEmpty) return nested;
        }
      }
      return const [];
    }

    Future<String?> fetchJwtToken() async {
      final uri = Uri.parse('https://$schoolUrl/WebUntis/api/token/new');
      final response = await requestWithCookieFallback(
        (headers) => http.get(uri, headers: headers),
      );
      if (response == null || response.body.trim().isEmpty) return null;

      final raw = response.body.trim();
      if (!raw.startsWith('{') && raw.isNotEmpty) {
        return raw.replaceAll('"', '').trim();
      }

      try {
        final decoded = jsonDecode(raw);
        if (decoded is String && decoded.trim().isNotEmpty) {
          return decoded.trim();
        }
        if (decoded is Map) {
          final candidate =
              decoded['token'] ??
              decoded['jwt'] ??
              decoded['jwt_token'] ??
              decoded['accessToken'];
          if (candidate != null && candidate.toString().trim().isNotEmpty) {
            return candidate.toString().trim();
          }
        }
      } catch (_) {}

      return null;
    }

    Future<List<Map<String, dynamic>>> fetchNewsWidgetMessages() async {
      final out = <Map<String, dynamic>>[];
      final days = List.generate(
        4,
        (index) => DateTime.now().subtract(Duration(days: index)),
      );

      for (final day in days) {
        final untisDate = DateFormat('yyyyMMdd').format(day);
        final uri = Uri.parse(
          'https://$schoolUrl/WebUntis/api/public/news/newsWidgetData?date=$untisDate',
        );
        final response = await requestWithCookieFallback(
          (headers) => http.get(uri, headers: headers),
        );
        if (response == null || response.body.trim().isEmpty) continue;

        try {
          final decoded = jsonDecode(response.body);
          final data = decoded is Map ? decoded['data'] : null;
          final messagesOfDay = data is Map ? data['messagesOfDay'] : null;
          if (messagesOfDay is! List) continue;

          for (final entry in messagesOfDay) {
            if (entry is! Map) continue;
            final map = Map<String, dynamic>.from(entry);
            out.add({
              ...map,
              'date': map['date'] ?? untisDate,
              'message': map['text'] ?? map['message'] ?? '',
            });
          }
        } catch (_) {}
      }

      return out;
    }

    Future<List<Map<String, dynamic>>> fetchInboxMessages() async {
      final token = await fetchJwtToken();
      if (token == null || token.isEmpty) return const [];

      final uri = Uri.parse(
        'https://$schoolUrl/WebUntis/api/rest/view/v1/messages',
      );
      final response = await requestWithCookieFallback(
        (headers) => http.get(
          uri,
          headers: {...headers, 'Authorization': 'Bearer $token'},
        ),
      );

      if (response == null || response.body.trim().isEmpty) return const [];

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) return const [];
        final incoming = decoded['incomingMessages'];
        if (incoming is! List) return const [];

        return incoming
            .whereType<Map>()
            .map((raw) {
              final map = Map<String, dynamic>.from(raw);
              final sender = map['sender'];
              return {
                ...map,
                'message': map['contentPreview'] ?? map['message'] ?? '',
                'author': sender is Map
                    ? sender['displayName'] ?? sender['name']
                    : null,
                'date': map['sentDateTime'] ?? map['date'],
              };
            })
            .toList(growable: false);
      } catch (_) {
        return const [];
      }
    }

    Future<List<dynamic>> tryGet(String path, {bool retry = true}) async {
      final uri = Uri.parse('https://$schoolUrl$path');
      final response = await requestWithCookieFallback(
        (headers) => http.get(uri, headers: headers),
        retry: retry,
      );

      if (response == null || response.body.trim().isEmpty) {
        return const [];
      }

      try {
        return extractList(jsonDecode(response.body));
      } catch (_) {}
      return const [];
    }

    Future<List<dynamic>> tryJsonRpc(
      String method,
      Map<String, dynamic> params, {
      bool retry = true,
    }) async {
      final uri = Uri.parse(
        'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
      );
      final response = await requestWithCookieFallback(
        (headers) => http.post(
          uri,
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': 'school-info',
            'method': method,
            'params': params,
            'jsonrpc': '2.0',
          }),
        ),
        retry: retry,
      );

      if (response == null || response.body.trim().isEmpty) {
        return const [];
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] != null) {
          return const [];
        }
        if (decoded is Map) {
          return extractList(decoded['result'] ?? decoded);
        }
        return extractList(decoded);
      } catch (_) {}
      return const [];
    }

    final documentedCandidates = <List<dynamic>>[
      await fetchNewsWidgetMessages(),
      await fetchInboxMessages(),
    ];

    final candidates = <List<dynamic>>[
      ...documentedCandidates,
      await tryJsonRpc('getMessagesOfDay2017', {
        'date': DateFormat('yyyyMMdd').format(DateTime.now()),
      }),
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
                            color: cs.outlineVariant.withValues(alpha: 0.35),
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
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final ok = await url_launcher.launchUrlString(
                                    item.url!,
                                    mode: url_launcher
                                        .LaunchMode
                                        .externalApplication,
                                  );
                                  if (!ok) {
                                    messenger.showSnackBar(
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
    customBackgroundsNotifier.addListener(_onChanged);
    selectedCustomBackgroundIdNotifier.addListener(_onChanged);
    hiddenSubjectsNotifier.addListener(_onChanged);
    knownSubjectsNotifier.addListener(_onChanged);
    subjectColorsNotifier.addListener(_onChanged);
    appLocaleNotifier.addListener(_onChanged);
    showCancelledNotifier.addListener(_onChanged);
    themeModeNotifier.addListener(_onChanged);
    backgroundAnimationsNotifier.addListener(_onChanged);
    backgroundAnimationStyleNotifier.addListener(_onChanged);
    backgroundGyroscopeNotifier.addListener(_onChanged);
    progressivePushNotifier.addListener(_onChanged);
    dailyBriefingPushNotifier.addListener(_onChanged);
    importantChangesPushNotifier.addListener(_onChanged);
    blurEnabledNotifier.addListener(_onChanged);
    demoModeNotifier.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    customBackgroundsNotifier.removeListener(_onChanged);
    selectedCustomBackgroundIdNotifier.removeListener(_onChanged);
    hiddenSubjectsNotifier.removeListener(_onChanged);
    knownSubjectsNotifier.removeListener(_onChanged);
    subjectColorsNotifier.removeListener(_onChanged);
    appLocaleNotifier.removeListener(_onChanged);
    showCancelledNotifier.removeListener(_onChanged);
    themeModeNotifier.removeListener(_onChanged);
    backgroundAnimationsNotifier.removeListener(_onChanged);
    backgroundAnimationStyleNotifier.removeListener(_onChanged);
    backgroundGyroscopeNotifier.removeListener(_onChanged);
    progressivePushNotifier.removeListener(_onChanged);
    dailyBriefingPushNotifier.removeListener(_onChanged);
    importantChangesPushNotifier.removeListener(_onChanged);
    blurEnabledNotifier.removeListener(_onChanged);
    demoModeNotifier.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    aiProvider = _normalizeAiProvider(
      prefs.getString('aiProvider') ?? aiProvider,
    );
    aiCustomCompatibility = _normalizeAiCustomCompatibility(
      prefs.getString('aiCustomCompatibility') ?? aiCustomCompatibility,
    );
    aiModel = prefs.getString('aiModel') ?? aiModel;
    aiCustomBaseUrl = prefs.getString('aiCustomBaseUrl') ?? aiCustomBaseUrl;
    aiSystemPromptTemplate =
        prefs.getString('aiSystemPromptTemplate') ?? aiSystemPromptTemplate;
    geminiApiKey = prefs.getString('geminiApiKey') ?? geminiApiKey;
    openAiApiKey = prefs.getString('openAiApiKey') ?? openAiApiKey;
    mistralApiKey = prefs.getString('mistralApiKey') ?? mistralApiKey;
    customAiApiKey = prefs.getString('customAiApiKey') ?? customAiApiKey;

    final validModels = _modelsForProvider(
      aiProvider,
      customCompatibility: aiCustomCompatibility,
    );
    if (!validModels.contains(aiModel)) {
      aiModel = _defaultModelForProvider(
        aiProvider,
        customCompatibility: aiCustomCompatibility,
      );
      await prefs.setString('aiModel', aiModel);
    }

    final key = _activeProviderApiKey();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? '';
        _apiKeySet = key.isNotEmpty;
        _apiKeyDisplay = _maskKey(key);
      });
    }
  }

  String _maskKey(String key) {
    if (key.isEmpty) return '';
    return key.length > 8
        ? '${key.substring(0, 7)}••••${key.substring(key.length - 4)}'
        : '••••••••';
  }

  String _activeProviderApiKey() {
    switch (_normalizeAiProvider(aiProvider)) {
      case 'openai':
        return openAiApiKey;
      case 'mistral':
        return mistralApiKey;
      case 'custom':
        return customAiApiKey;
      case 'gemini':
      default:
        return geminiApiKey;
    }
  }

  Future<void> _setProviderApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    switch (_normalizeAiProvider(aiProvider)) {
      case 'openai':
        openAiApiKey = key;
        await prefs.setString('openAiApiKey', key);
        break;
      case 'mistral':
        mistralApiKey = key;
        await prefs.setString('mistralApiKey', key);
        break;
      case 'custom':
        customAiApiKey = key;
        await prefs.setString('customAiApiKey', key);
        break;
      case 'gemini':
      default:
        geminiApiKey = key;
        await prefs.setString('geminiApiKey', key);
        break;
    }
  }

  String _providerLabel(AppL10n l, String provider) {
    switch (_normalizeAiProvider(provider)) {
      case 'openai':
        return l.settingsAiProviderOpenAi;
      case 'mistral':
        return l.settingsAiProviderMistral;
      case 'custom':
        return l.settingsAiProviderCustom;
      case 'gemini':
      default:
        return l.settingsAiProviderGemini;
    }
  }

  String _compatibilityLabel(AppL10n l, String value) {
    return _normalizeAiCustomCompatibility(value) == 'gemini'
        ? l.settingsAiCompatibilityGemini
        : l.settingsAiCompatibilityOpenAi;
  }

  String _apiKeyHintForProvider(String provider) {
    switch (_normalizeAiProvider(provider)) {
      case 'openai':
        return 'sk-...';
      case 'mistral':
        return 'mistral-...';
      case 'custom':
        return 'token-...';
      case 'gemini':
      default:
        return 'AIza...';
    }
  }

  String _apiKeyPortalUrlForProvider(String provider) {
    switch (_normalizeAiProvider(provider)) {
      case 'openai':
        return 'https://platform.openai.com/api-keys';
      case 'mistral':
        return 'https://console.mistral.ai/api-keys/';
      case 'gemini':
        return 'https://aistudio.google.com/app/apikey';
      case 'custom':
      default:
        return '';
    }
  }

  Future<void> _openApiKeyPortal(BuildContext context) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final url = _apiKeyPortalUrlForProvider(aiProvider);
    if (url.isEmpty) return;
    final ok = await url_launcher.launchUrlString(
      url,
      mode: url_launcher.LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.settingsAiApiKeyOpenFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setAiProvider(String provider) async {
    aiProvider = _normalizeAiProvider(provider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiProvider', aiProvider);

    final models = _modelsForProvider(
      aiProvider,
      customCompatibility: aiCustomCompatibility,
    );
    if (!models.contains(aiModel)) {
      aiModel = models.first;
      await prefs.setString('aiModel', aiModel);
    }
    await _loadPrefs();
  }

  Future<void> _setAiModel(String model) async {
    aiModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiModel', aiModel);
    await _loadPrefs();
  }

  Future<void> _setAiCustomCompatibility(String compatibility) async {
    aiCustomCompatibility = _normalizeAiCustomCompatibility(compatibility);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiCustomCompatibility', aiCustomCompatibility);

    final models = _modelsForProvider(
      aiProvider,
      customCompatibility: aiCustomCompatibility,
    );
    if (!models.contains(aiModel)) {
      aiModel = models.first;
      await prefs.setString('aiModel', aiModel);
    }
    await _loadPrefs();
  }

  Future<void> _setAiCustomBaseUrl(String value) async {
    aiCustomBaseUrl = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiCustomBaseUrl', value);
    await _loadPrefs();
  }

  Future<void> _setAiSystemPromptTemplate(String value) async {
    aiSystemPromptTemplate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiSystemPromptTemplate', value);
    await _loadPrefs();
  }

  void _showAiProviderDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsAiProvider,
      fitContentHeight: true,
      bottomMargin: 0,
      options: kSupportedAiProviders
          .map(
            (provider) => _SheetOption(
              value: provider,
              title: _providerLabel(l, provider),
              icon: provider == 'gemini'
                  ? Icons.auto_awesome_rounded
                  : provider == 'openai'
                  ? Icons.chat_bubble_outline_rounded
                  : provider == 'mistral'
                  ? Icons.cloud_rounded
                  : Icons.settings_ethernet_rounded,
              selected: aiProvider == provider,
            ),
          )
          .toList(),
    ).then((value) {
      if (value != null) _setAiProvider(value);
    });
  }

  void _showAiModelDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final models = _modelsForProvider(
      aiProvider,
      customCompatibility: aiCustomCompatibility,
    );
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsAiModel,
      fitContentHeight: true,
      bottomMargin: 0,
      options: models
          .map(
            (model) => _SheetOption(
              value: model,
              title: model,
              icon: Icons.memory_rounded,
              selected: aiModel == model,
            ),
          )
          .toList(),
    ).then((value) {
      if (value != null) _setAiModel(value);
    });
  }

  void _showAiCompatibilityDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsAiCompatibility,
      options: kSupportedAiCustomCompatibilities
          .map(
            (compat) => _SheetOption(
              value: compat,
              title: _compatibilityLabel(l, compat),
              icon: compat == 'gemini'
                  ? Icons.auto_awesome_rounded
                  : Icons.chat_rounded,
              selected: aiCustomCompatibility == compat,
            ),
          )
          .toList(),
    ).then((value) {
      if (value != null) _setAiCustomCompatibility(value);
    });
  }

  void _showAiCustomBaseUrlDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final ctrl = TextEditingController(text: aiCustomBaseUrl);
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
                  l.settingsAiCustomBaseUrl,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsAiCustomBaseUrlDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l.settingsAiCustomBaseUrlHint,
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
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await _setAiCustomBaseUrl(ctrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
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

  void _showAiPromptDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final defaultTemplate = _buildDefaultAiPromptTemplate(l);
    final ctrl = TextEditingController(
      text: aiSystemPromptTemplate.isEmpty
          ? defaultTemplate
          : aiSystemPromptTemplate,
    );

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
                  l.settingsAiPromptEditTitle,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsAiPromptDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 260,
                  child: TextField(
                    controller: ctrl,
                    minLines: 10,
                    maxLines: 18,
                    style: GoogleFonts.jetBrainsMono(fontSize: 12.5),
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
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
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ctrl.text = defaultTemplate;
                      },
                      child: Text(
                        l.settingsAiPromptReset,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await _setAiSystemPromptTemplate(ctrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
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

  void _showAiVariablesDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedSheet<void>(
      context: context,
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.settingsAiPromptVariables,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.settingsAiPromptVariablesDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 380),
                  child: ListView(
                    shrinkWrap: true,
                    children: l.aiPromptVariableDescriptions.entries
                        .map(
                          (entry) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.label_important_outline),
                            title: Text(
                              entry.key,
                              style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(
                              entry.value,
                              style: GoogleFonts.outfit(fontSize: 12.5),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      l.settingsApiKeyCancel,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

  List<int> _extractVersionParts(String input) {
    final cleaned = input.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final matches = RegExp(r'\d+').allMatches(cleaned);
    if (matches.isEmpty) return const [0];
    return matches
        .map((m) => int.tryParse(m.group(0) ?? '0') ?? 0)
        .toList(growable: false);
  }

  int _compareVersionStrings(String current, String latest) {
    final currentParts = _extractVersionParts(current);
    final latestParts = _extractVersionParts(latest);
    final maxLen = math.max(currentParts.length, latestParts.length);
    for (var i = 0; i < maxLen; i++) {
      final a = i < currentParts.length ? currentParts[i] : 0;
      final b = i < latestParts.length ? latestParts[i] : 0;
      if (a == b) continue;
      return a.compareTo(b);
    }
    return 0;
  }

  Future<bool> _confirmGithubInstall({
    required AppL10n l,
    required String current,
    required String latest,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(
            l.settingsGithubUpdateFound(latest),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l.settingsGithubCurrentVersion}: $current',
                style: GoogleFonts.outfit(),
              ),
              const SizedBox(height: 4),
              Text(
                '${l.settingsGithubLatestVersion}: $latest',
                style: GoogleFonts.outfit(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.settingsGithubInstallQuestion,
                style: GoogleFonts.outfit(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.settingsGithubInstallLater),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.settingsGithubInstallNow),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _checkGithubUpdate() async {
    if (_checkingGithubUpdate) return;
    final l = AppL10n.of(appLocaleNotifier.value);
    setState(() => _checkingGithubUpdate = true);

    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(l.settingsGithubChecking),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

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
      final targetUrl = assetUrl ?? htmlUrl;
      final latestVersionRaw = tag.isEmpty
          ? (data['name'] ?? '').toString()
          : tag;
      final hasComparableVersion = RegExp(r'\d').hasMatch(latestVersionRaw);
      final hasUpdate = hasComparableVersion
          ? _compareVersionStrings(appVersion, latestVersionRaw) < 0
          : true;

      if (!hasUpdate) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.settingsGithubNoUpdate),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      final confirm = await _confirmGithubInstall(
        l: l,
        current: appVersion,
        latest: latestVersionRaw,
      );
      if (!confirm) return;

      if (assetUrl == null) {
        messenger.showSnackBar(
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

      if (launched) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.settingsGithubInstallPrompted),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.settingsGithubOpenFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
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
    final normalized = style.clamp(0, 10);
    backgroundAnimationStyleNotifier.value = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('backgroundAnimationStyle', normalized);
  }

  Future<void> _setBackgroundGyroscope(bool v) async {
    backgroundGyroscopeNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backgroundGyroscope', v);
  }

  Future<void> _setBlurEnabled(bool v) async {
    blurEnabledNotifier.value = v;
    unawaited(_applyAndroidWindowBlur(v));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('blurEnabled', v);
  }

  Future<void> _setProgressivePush(bool v) async {
    progressivePushNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('progressivePush', v);
    if (!v) {
      await NotificationService().cancelNotification(
        kCurrentLessonNotificationId,
      );
    } else {
      updateUntisData().catchError((_) {});
    }
  }

  Future<void> _setDailyBriefingPush(bool v) async {
    dailyBriefingPushNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailyBriefingPush', v);
    if (!v) {
      await NotificationService().cancelNotification(
        kDailyBriefingNotificationId,
      );
    } else {
      updateUntisData().catchError((_) {});
    }
  }

  Future<void> _setImportantChangesPush(bool v) async {
    importantChangesPushNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('importantChangesPush', v);
  }

  Future<void> _setDemoMode(bool enabled) async {
    demoModeNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('demoMode', enabled);

    if (enabled) {
      if (schoolName.isEmpty) schoolName = 'demo.school';
      if (schoolUrl.isEmpty) schoolUrl = 'demo.school';
      if (personType == 0) personType = DemoModeService.demoPersonType;
      if (personId == 0) personId = DemoModeService.demoPersonId;
      await prefs.setString('schoolName', schoolName);
      await prefs.setString('schoolUrl', schoolUrl);
      await prefs.setInt('personType', personType);
      await prefs.setInt('personId', personId);
      return;
    }

    if (sessionID.isEmpty && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        _buildBouncyRoute(const OnboardingFlow()),
        (route) => false,
      );
    }
  }

  void _showLanguageDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsLanguage,
      fitContentHeight: true,
      bottomMargin: 0,
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
        return l.settingsBackgroundStyleNebula;
      case 6:
        return l.settingsBackgroundStylePrism;
      case 7:
        return l.settingsBackgroundStyleWaves;
      case 8:
        return l.settingsBackgroundStyleGrid;
      case 9:
        return l.settingsBackgroundStyleRings;
      case 10:
        return l.settingsBackgroundStyleCustom;
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
        return Icons.cloud_rounded;
      case 6:
        return Icons.change_history_rounded;
      case 7:
        return Icons.waves_rounded;
      case 8:
        return Icons.grid_on_rounded;
      case 9:
        return Icons.radio_button_checked_rounded;
      case 10:
        return Icons.wallpaper_rounded;
      default:
        return Icons.blur_circular_rounded;
    }
  }

  void _showBackgroundStyleDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final styleOptions = List<int>.generate(11, (index) => index);

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
    final providerLabel = _providerLabel(l, aiProvider);
    final providerPortalUrl = _apiKeyPortalUrlForProvider(aiProvider);
    final ctrl = TextEditingController(text: _activeProviderApiKey());
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
                  '${l.settingsAiApiKey} ($providerLabel)',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsAiApiKeyDialogDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (providerPortalUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _openApiKeyPortal(ctx),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(
                        l.settingsAiApiKeyGet,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  obscureText: true,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _apiKeyHintForProvider(aiProvider),
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
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l.settingsApiKeyCancel,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.08,
                          ),
                        ),
                      ),
                    ),
                    if (_apiKeySet) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final navigator = Navigator.of(ctx);
                            await _setProviderApiKey('');
                            navigator.pop();
                            _loadPrefs();
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            side: BorderSide(color: cs.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            l.settingsApiKeyRemove,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.08,
                              color: cs.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final val = ctrl.text.trim();
                          final navigator = Navigator.of(ctx);
                          await _setProviderApiKey(val);
                          navigator.pop();
                          _loadPrefs();
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        label: Text(
                          l.settingsApiKeySave,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
    final navigator = Navigator.of(context);
    defaultClassId = null;
    defaultClassName = null;
    favoriteClassIds = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      _buildBouncyRoute(const OnboardingFlow()),
      (route) => false,
    );
  }

  // ── Section card builder ───
  Widget _section(
    String title,
    IconData icon,
    List<Widget> tiles,
    ColorScheme cs, {
    required Color accent,
    bool isAbout = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.34),
                      accent.withValues(alpha: 0.14),
                    ],
                  ),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.8,
                  color: accent,
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
            _glassContainer(
              context: context,
              borderRadius: BorderRadius.circular(24),
              sigmaX: 18,
              sigmaY: 18,
              color: cs.surface.withValues(alpha: 0.52),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.08),
                  cs.surfaceContainerHighest.withValues(alpha: 0.46),
                ],
              ),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.15),
                width: 1,
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    for (int i = 0; i < tiles.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            indent: 74,
                            endIndent: 16,
                            color: cs.outlineVariant.withValues(alpha: 0.35),
                          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              Theme.of(context).colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.75),
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
      ),
    );
  }

  // ── Rounded icon box for tile leading ─────
  Widget _tileIcon(IconData icon, Color color) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0.12)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.16),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Icon(icon, color: color, size: 22),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final hidden = hiddenSubjectsNotifier.value.toList()..sort();
    final activeCustomBackground = _activeCustomBackgroundOrNull();

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
                      sigmaX: 24,
                      sigmaY: 24,
                      child: const SizedBox.shrink(),
                      childBuilder: (enabled) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        return Stack(
                          fit: StackFit.passthrough,
                          children: [
                            Container(
                              color: enabled
                                  ? (isDark
                                        ? Color.alphaBlend(
                                            cs.primary.withValues(alpha: 0.08),
                                            cs.surface.withValues(alpha: 0.65),
                                          )
                                        : cs.surface.withValues(alpha: 0.82))
                                  : cs.surface,
                            ),
                            if (enabled)
                              Positioned.fill(
                                child: Container(
                                  color: cs.primary.withValues(alpha: 0.06),
                                ),
                              ),
                          ],
                        );
                      },
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

                  _springEntry(
                    duration: const Duration(milliseconds: 380),
                    offsetY: 18,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionQuick,
                      Icons.bolt_rounded,
                      [
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
                            Icons.science_rounded,
                            demoModeNotifier.value ? cs.tertiary : cs.outline,
                          ),
                          title: l.settingsDemoMode,
                          subtitle: l.settingsDemoModeDesc,
                          trailing: Switch.adaptive(
                            value: demoModeNotifier.value,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              _setDemoMode(v);
                            },
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _setDemoMode(!demoModeNotifier.value);
                          },
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.notifications_active_rounded,
                            progressivePushNotifier.value
                                ? cs.primary
                                : cs.outline,
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
                        _tile(
                          leading: _tileIcon(
                            Icons.wb_sunny_rounded,
                            dailyBriefingPushNotifier.value
                                ? cs.tertiary
                                : cs.outline,
                          ),
                          title: l.settingsDailyBriefingPush,
                          subtitle: l.settingsDailyBriefingPushDesc,
                          trailing: Switch.adaptive(
                            value: dailyBriefingPushNotifier.value,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              _setDailyBriefingPush(v);
                            },
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _setDailyBriefingPush(
                              !dailyBriefingPushNotifier.value,
                            );
                          },
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.warning_amber_rounded,
                            importantChangesPushNotifier.value
                                ? cs.error
                                : cs.outline,
                          ),
                          title: l.settingsImportantChangesPush,
                          subtitle: l.settingsImportantChangesPushDesc,
                          trailing: Switch.adaptive(
                            value: importantChangesPushNotifier.value,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              _setImportantChangesPush(v);
                            },
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _setImportantChangesPush(
                              !importantChangesPushNotifier.value,
                            );
                          },
                        ),
                      ],
                      cs,
                      accent: cs.tertiary,
                    ),
                  ),

                  _springEntry(
                    duration: const Duration(milliseconds: 430),
                    offsetY: 20,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionGeneral,
                      Icons.tune_rounded,
                      [
                        _tile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                _username.isNotEmpty
                                    ? _username[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
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
                            Icons.screen_rotation_alt_rounded,
                            backgroundGyroscopeNotifier.value
                                ? cs.secondary
                                : cs.outline,
                          ),
                          title: l.settingsBackgroundGyroscope,
                          subtitle: l.settingsBackgroundGyroscopeDesc,
                          trailing: Switch.adaptive(
                            value: backgroundGyroscopeNotifier.value,
                            onChanged: backgroundAnimationsNotifier.value
                                ? (v) {
                                    HapticFeedback.selectionClick();
                                    _setBackgroundGyroscope(v);
                                  }
                                : null,
                          ),
                          onTap: backgroundAnimationsNotifier.value
                              ? () {
                                  HapticFeedback.selectionClick();
                                  _setBackgroundGyroscope(
                                    !backgroundGyroscopeNotifier.value,
                                  );
                                }
                              : null,
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
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showBackgroundStyleDialog,
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.wallpaper_rounded,
                            cs.tertiary,
                          ),
                          title: l.settingsCustomBackgrounds,
                          subtitle: activeCustomBackground == null
                              ? l.settingsCustomBackgroundsDesc
                              : l.settingsCustomBackgroundsSelected(
                                  activeCustomBackground.name,
                                ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              _buildBouncyRoute(
                                const CustomBackgroundEditorScreen(),
                              ),
                            );
                          },
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
                          leading: _tileIcon(
                            Icons.language_rounded,
                            cs.primary,
                          ),
                          title: l.settingsLanguage,
                          subtitle: _localeLabels[appLocaleNotifier.value],
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showLanguageDialog,
                        ),
                      ],
                      cs,
                      accent: cs.primary,
                    ),
                  ),

                  _springEntry(
                    duration: const Duration(milliseconds: 480),
                    offsetY: 22,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionTimetable,
                      Icons.schedule_rounded,
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
                            color: cs.onSurface.withValues(alpha: 0.4),
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
                      accent: cs.secondary,
                    ),
                  ),

                  _springEntry(
                    duration: const Duration(milliseconds: 530),
                    offsetY: 24,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionAI,
                      Icons.smart_toy_rounded,
                      [
                        _tile(
                          leading: _tileIcon(Icons.hub_rounded, cs.tertiary),
                          title: l.settingsAiProvider,
                          subtitle: _providerLabel(l, aiProvider),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showAiProviderDialog,
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.memory_rounded,
                            cs.secondary,
                          ),
                          title: l.settingsAiModel,
                          subtitle: aiModel,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showAiModelDialog,
                        ),
                        if (aiProvider == 'custom')
                          _tile(
                            leading: _tileIcon(
                              Icons.compare_arrows_rounded,
                              cs.primary,
                            ),
                            title: l.settingsAiCompatibility,
                            subtitle: _compatibilityLabel(
                              l,
                              aiCustomCompatibility,
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                            onTap: _showAiCompatibilityDialog,
                          ),
                        if (aiProvider == 'custom')
                          _tile(
                            leading: _tileIcon(Icons.link_rounded, cs.primary),
                            title: l.settingsAiCustomBaseUrl,
                            subtitle: aiCustomBaseUrl.isEmpty
                                ? l.settingsAiCustomBaseUrlHint
                                : aiCustomBaseUrl,
                            subtitleColor: aiCustomBaseUrl.isEmpty
                                ? cs.error
                                : null,
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                            onTap: _showAiCustomBaseUrlDialog,
                          ),
                        _tile(
                          leading: _apiKeySet
                              ? _tileIcon(
                                  Icons.auto_awesome_rounded,
                                  cs.tertiary,
                                )
                              : _tileIcon(Icons.key_off_rounded, cs.error),
                          title: l.settingsAiApiKey,
                          subtitle: _apiKeySet
                              ? _apiKeyDisplay
                              : l.settingsAiApiKeyNotSet,
                          subtitleColor: _apiKeySet ? null : cs.error,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showApiKeyDialog,
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.edit_note_rounded,
                            cs.tertiary,
                          ),
                          title: l.settingsAiPrompt,
                          subtitle: aiSystemPromptTemplate.trim().isEmpty
                              ? l.settingsAiPromptDesc
                              : aiSystemPromptTemplate.trim().split('\n').first,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showAiPromptDialog,
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.data_object_rounded,
                            cs.secondary,
                          ),
                          title: l.settingsAiPromptVariables,
                          subtitle: l.settingsAiPromptVariablesDesc,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showAiVariablesDialog,
                        ),
                      ],
                      cs,
                      accent: cs.tertiary,
                    ),
                  ),

                  // ── Subjects & Colors (merged) ───────────────────────────
                  _springEntry(
                    duration: const Duration(milliseconds: 580),
                    offsetY: 26,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionSubjects,
                      Icons.palette_rounded,
                      [
                        _tile(
                          leading: _tileIcon(
                            Icons.palette_outlined,
                            cs.primary,
                          ),
                          title: l.settingsSectionColors,
                          subtitle: l
                              .settingsColorsDesc, // "Customize the colors for your subjects"
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              _buildBouncyRoute(const SubjectColorsPage()),
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
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              _buildBouncyRoute(const HiddenSubjectsPage()),
                            );
                          },
                        ),
                      ],
                      cs,
                      accent: cs.primary,
                    ),
                  ),

                  _springEntry(
                    duration: const Duration(milliseconds: 630),
                    offsetY: 28,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionUpdates,
                      Icons.system_update_alt_rounded,
                      [
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
                                  color: cs.onSurface.withValues(alpha: 0.4),
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
                            Icons.open_in_new_rounded,
                            cs.secondary,
                          ),
                          title: l.settingsGithubOpenReleasePage,
                          subtitle: l.settingsGithubRepoLabel,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: () {
                            url_launcher.launchUrlString(
                              'https://github.com/ninocss/UntisPlus/releases',
                              mode: url_launcher.LaunchMode.externalApplication,
                            );
                          },
                        ),
                      ],
                      cs,
                      accent: cs.secondary,
                    ),
                  ),

                  // ── About ────────────────────────────────────────────────
                  _springEntry(
                    duration: const Duration(milliseconds: 680),
                    offsetY: 30,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionAbout,
                      Icons.info_rounded,
                      [
                        _tile(
                          leading: _tileIcon(
                            Icons.rocket_launch_outlined,
                            cs.primary,
                          ),
                          title: l.appName,
                          subtitle:
                              '${l.settingsAppVersion} $appVersion (${l.settingsBuild} ${appBuildNumber.isEmpty ? '-' : appBuildNumber})',
                          trailing: Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: cs.tertiary,
                          ),
                        ),
                      ],
                      cs,
                      accent: cs.tertiary,
                      isAbout: true,
                    ),
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
                      color: cs.primary.withValues(alpha: 0.30),
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
                        color: cs.onPrimaryContainer.withValues(alpha: 0.55),
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
                          color: cs.onPrimaryContainer.withValues(alpha: 0.45),
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
              backgroundColor: cs.error.withValues(alpha: 0.1),
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

    double red = ((current ?? fallback).r * 255.0);
    double green = ((current ?? fallback).g * 255.0);
    double blue = ((current ?? fallback).b * 255.0);

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
                        _setSubjectColor(subject, preview.toARGB32());
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
                      current != null && current.toARGB32() == c.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _setSubjectColor(subject, c.toARGB32());
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: cs.onSurface.withValues(alpha: 0.65),
                                width: 3,
                              )
                            : Border.all(color: Colors.transparent),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.45),
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
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsSectionColors,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
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
                      size: 56,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.settingsNoSubjectsLoaded,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.settingsNoSubjectsLoadedDesc,
                      style: GoogleFonts.outfit(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ValueListenableBuilder(
              valueListenable: subjectColorsNotifier,
              builder: (context, colors, _) {
                return ListView(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
                  children: [
                    SettingsGroup(
                      children: subjects.map((subj) {
                        final colorVal = colors[subj];
                        final subjectColor = colorVal != null ? Color(colorVal) : null;
                        return SettingsTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: subjectColor ?? cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: subjectColor != null
                                  ? Border.all(
                                      color: subjectColor.withValues(alpha: 0.4),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: subjectColor == null
                                ? Icon(
                                    Icons.palette_outlined,
                                    color: cs.primary,
                                    size: 20,
                                  )
                                : null,
                          ),
                          title: subj,
                          subtitle: subjectColor != null
                              ? l.settingsCustomColor
                              : l.settingsDefaultColor,
                          onTap: () => _showColorPicker(context, subj, subjectColor),
                        );
                      }).toList(),
                    ),
                  ],
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
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsSectionHidden,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
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
                      size: 56,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.settingsNoHidden,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.settingsNoHiddenDesc,
                      style: GoogleFonts.outfit(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
              children: [
                SettingsGroup(
                  children: hidden.map((subject) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                subject.isNotEmpty ? subject[0].toUpperCase() : '?',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: cs.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              subject,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _unhideSubject(subject),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              l.settingsUnhide,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
