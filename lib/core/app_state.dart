part of '../main.dart';

// ── APP VERSION ────────────────────────────────────────────────────────────
String appVersion = '0.0.0';
String appBuildNumber = '0';
bool showChangelogOnStartup = false;

String sessionID = "";
String schoolUrl = "";
String schoolName = "";
int personId = 0;
int personType = 0;
String geminiApiKey = "";
String openAiApiKey = "";
String mistralApiKey = "";
String customAiApiKey = "";

String aiProvider = 'gemini';
String aiModel = 'gemini-2.5-flash';
String aiSystemPromptTemplate = '';
String aiCustomBaseUrl = '';
String aiCustomCompatibility = 'openai';

const List<String> kSupportedAiProviders = [
  'gemini',
  'openai',
  'mistral',
  'custom',
];

const List<String> kSupportedAiCustomCompatibilities = ['openai', 'gemini'];

String _normalizeAiProvider(String value) {
  return kSupportedAiProviders.contains(value) ? value : 'gemini';
}

String _normalizeAiCustomCompatibility(String value) {
  return kSupportedAiCustomCompatibilities.contains(value) ? value : 'openai';
}

List<String> _modelsForProvider(
  String provider, {
  String? customCompatibility,
}) {
  switch (_normalizeAiProvider(provider)) {
    case 'openai':
      return const ['gpt-4o-mini', 'gpt-4o', 'o4-mini', 'o3-mini'];
    case 'mistral':
      return const [
        'mistral-small-latest',
        'mistral-medium-latest',
        'ministral-8b-latest',
      ];
    case 'custom':
      if (_normalizeAiCustomCompatibility(customCompatibility ?? 'openai') ==
          'gemini') {
        return const ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-2.0-flash'];
      }
      return const ['gpt-4o-mini', 'gpt-4o', 'mistral-small-latest'];
    case 'gemini':
    default:
      return const ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-2.0-flash'];
  }
}

String _defaultModelForProvider(
  String provider, {
  String? customCompatibility,
}) {
  return _modelsForProvider(
    provider,
    customCompatibility: customCompatibility,
  ).first;
}

String _activeAiApiKey() {
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

String _localizedAiProviderLabel(AppL10n l, String provider) {
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

String _providerAwareMissingApiKeyMessage(AppL10n l, String provider) {
  return '${l.aiNoApiKey} (${_localizedAiProviderLabel(l, provider)})';
}

const Map<String, String> aiPromptVariableDescriptions = {
  '[today]': 'Heutiges Datum in lokaler Schreibweise',
  '[today_iso]': 'Heutiges Datum im Format YYYY-MM-DD',
  '[locale]': 'Aktive App-Sprache (z.B. de, en)',
  '[school_name]': 'Name der Schule',
  '[school_url]': 'Server/Domain der Schule',
  '[person_type]': 'WebUntis Personentyp als Zahl',
  '[person_id]': 'WebUntis Personen-ID',
  '[demo_mode]': 'true, wenn Demo-Modus aktiv ist',
  '[current_monday]': 'Montag der geladenen Woche (DD.MM.YYYY)',
  '[current_friday]': 'Freitag der geladenen Woche (DD.MM.YYYY)',
  '[day_summary_today]': 'Kurzuebersicht fuer heute',
  '[day_summary_tomorrow]': 'Kurzuebersicht fuer morgen',
  '[timetable]': 'Formatierter Stundenplan der aktuellen Woche',
  '[timetable_json]': 'Rohdaten des Stundenplans als JSON',
  '[exams]': 'Formatierte Liste geplanter Pruefungen',
  '[exams_json]': 'Pruefungsdaten als JSON',
};

final ValueNotifier<String> appLocaleNotifier = ValueNotifier('de');
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);
final ValueNotifier<bool> showCancelledNotifier = ValueNotifier(true);
final ValueNotifier<int> cancelledLessonColorNotifier = ValueNotifier(0xFFFF1744);
final ValueNotifier<bool> monochromeLessonsNotifier = ValueNotifier(false);
final ValueNotifier<bool> backgroundAnimationsNotifier = ValueNotifier(true);
final ValueNotifier<int> backgroundAnimationStyleNotifier = ValueNotifier(0);
final ValueNotifier<bool> backgroundGyroscopeNotifier = ValueNotifier(false);
final ValueNotifier<bool> progressivePushNotifier = ValueNotifier(true);
final ValueNotifier<bool> dailyBriefingPushNotifier = ValueNotifier(true);
final ValueNotifier<bool> importantChangesPushNotifier = ValueNotifier(true);
final ValueNotifier<String?> pendingTimetableActionNotifier = ValueNotifier(
  null,
);
final ValueNotifier<String?> pendingTimetableCurrentLessonNotifier =
    ValueNotifier(null);
final ValueNotifier<String?> pendingTimetableNextLessonNotifier = ValueNotifier(
  null,
);
final ValueNotifier<bool> blurEnabledNotifier = ValueNotifier(true);
final ValueNotifier<bool> demoModeNotifier = ValueNotifier(false);
final ValueNotifier<int> pageTransitionNotifier = ValueNotifier(0);
final ValueNotifier<bool> useMaterialYouNotifier = ValueNotifier(true);
final ValueNotifier<int> customColorSeedNotifier = ValueNotifier(0xFF0F766E);

String _icuLocale(String locale) {
  switch (locale) {
    case 'en':
      return 'en_US';
    case 'fr':
      return 'fr_FR';
    case 'es':
      return 'es_ES';
    case 'el':
      return 'el_GR';
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
  return formatUntisTime(time);
}

Future<bool> _reAuthenticate() async {
  final prefs = await SharedPreferences.getInstance();
  final user = prefs.getString('username') ?? '';
  final pass = prefs.getString('password') ?? '';
  final useLoginKey = prefs.getString('loginCredentialMode') == 'loginKey';
  if (user.isEmpty || pass.isEmpty) return false;

  try {
    final authResult = await _authenticateUntis(
      user: user,
      password: pass,
      client: 'UntisPlus',
      requestId: 'relogin',
      useLoginKey: useLoginKey,
    );
    final newSession = authResult?['sessionId']?.toString();
    if (newSession != null && newSession.isNotEmpty) {
      sessionID = newSession;
      await prefs.setString('sessionId', sessionID);
      return true;
    }
  } catch (_) {}
  return false;
}

// ── CLASS FAVORITES & DEFAULTS ──────────────────────────────────────────────
int? defaultClassId;
String? defaultClassName;
Set<int> favoriteClassIds = {};

