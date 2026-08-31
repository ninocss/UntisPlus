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
String aiModel = 'gemini-3.6-flash';
String aiSystemPromptTemplate = '';
String aiCustomBaseUrl = '';
String aiCustomCompatibility = 'openai';
String aiLocalModelPath = '';
double aiTemperature = 0.2;
int aiMaxTokens = 2600;
double aiTopP = 0.95;
String aiPersona = 'helpful';

const List<String> kSupportedAiProviders = [
  'gemini',
  'openai',
  'mistral',
  'custom',
  'local',
];

const List<String> kSupportedAiCustomCompatibilities = ['openai', 'gemini'];

/// Available local models for on-device inference.
class LocalModelInfo {
  final String id;
  final String name;
  final String url;
  final double sizeGb;
  final String description;

  const LocalModelInfo({
    required this.id,
    required this.name,
    required this.url,
    required this.sizeGb,
    required this.description,
  });
}

const List<LocalModelInfo> kLocalModels = [
  LocalModelInfo(
    id: 'gemma-3-1b-it-q4_k_m',
    name: 'Gemma 3 1B-IT (Q4_K_M)',
    url: 'https://huggingface.co/bartowski/google_gemma-3-1b-it-GGUF/resolve/main/google_gemma-3-1b-it-Q4_K_M.gguf',
    sizeGb: 0.8,
    description: 'Klein, schnell, ideal für Mobilgeräte',
  ),
  LocalModelInfo(
    id: 'llama-3.2-1b-instruct-q4_k_m',
    name: 'Llama 3.2 1B-Instruct (Q4_K_M)',
    url: 'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
    sizeGb: 0.8,
    description: 'Ausgewogen, gute Qualität',
  ),
  LocalModelInfo(
    id: 'qwen-2.5-1.5b-instruct-q4_k_m',
    name: 'Qwen 2.5 1.5B-Instruct (Q4_K_M)',
    url: 'https://huggingface.co/bartowski/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf',
    sizeGb: 1.0,
    description: 'Stark bei Mehrsprachigkeit',
  ),
  LocalModelInfo(
    id: 'llama-3.2-3b-instruct-q4_k_m',
    name: 'Llama 3.2 3B-Instruct (Q4_K_M)',
    url: 'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    sizeGb: 2.0,
    description: 'Höhere Qualität, mehr Speicher',
  ),
  LocalModelInfo(
    id: 'phi-3.5-mini-instruct-q4_k_m',
    name: 'Phi-3.5-mini-Instruct (Q4_K_M)',
    url: 'https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf',
    sizeGb: 2.4,
    description: 'Sehr stark, aber größer',
  ),
];

LocalModelInfo _defaultLocalModel() => kLocalModels.first;

List<String> _localModelIds() => kLocalModels.map((m) => m.id).toList();

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
    case 'local':
      return _localModelIds();
    case 'gemini':
    default:
      return const ['gemini-3.6-flash', 'gemini-3.6-pro', 'gemini-3.6-flash-lite'];
  }
}

String _defaultModelForProvider(
  String provider, {
  String? customCompatibility,
}) {
  if (_normalizeAiProvider(provider) == 'local') {
    return _defaultLocalModel().id;
  }
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
    case 'local':
      return l.settingsAiProviderLocal;
    case 'gemini':
    default:
      return l.settingsAiProviderGemini;
  }
}

String _providerAwareMissingApiKeyMessage(AppL10n l, String provider) {
  return '${l.aiNoApiKey} (${_localizedAiProviderLabel(l, provider)})';
}


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
final ValueNotifier<bool> appBgBlurEnabledNotifier = ValueNotifier(false);
final ValueNotifier<double> appBgBlurAmountNotifier = ValueNotifier(10.0);
final ValueNotifier<bool> demoModeNotifier = ValueNotifier(false);
final ValueNotifier<int> pageTransitionNotifier = ValueNotifier(0);
final ValueNotifier<bool> useMaterialYouNotifier = ValueNotifier(true);
final ValueNotifier<bool> isAmoledNotifier = ValueNotifier(false);
final ValueNotifier<int> customColorSeedNotifier = ValueNotifier(0xFF0F766E);

// ── LESSON DESIGN & STYLING NOTIFIERS ───────────────────────────────────────
final ValueNotifier<int> lessonCardStyleNotifier = ValueNotifier(0);
final ValueNotifier<bool> lessonGlowEnabledNotifier = ValueNotifier(true);
final ValueNotifier<int> lessonGlowModeNotifier = ValueNotifier(0);
final ValueNotifier<double> lessonGlowIntensityNotifier = ValueNotifier(1.0);
final ValueNotifier<bool> lessonBlurEnabledNotifier = ValueNotifier(false);
final ValueNotifier<double> lessonBlurAmountNotifier = ValueNotifier(12.0);
final ValueNotifier<double> lessonCardOpacityNotifier = ValueNotifier(0.9);
final ValueNotifier<double> lessonBorderRadiusNotifier = ValueNotifier(12.0);
final ValueNotifier<int> lessonAccentStyleNotifier = ValueNotifier(0);
final ValueNotifier<bool> lessonShowTeacherNotifier = ValueNotifier(true);
final ValueNotifier<bool> lessonShowRoomNotifier = ValueNotifier(true);
final ValueNotifier<bool> lessonCompactModeNotifier = ValueNotifier(false);
final ValueNotifier<bool> lessonDimPastNotifier = ValueNotifier(true);
final ValueNotifier<bool> lessonCancelledPatternNotifier = ValueNotifier(true);

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

/// Latest fetched homework assignments, available app-wide so lesson detail
/// sheets can attach homework to the corresponding lesson.
final ValueNotifier<List<Map<String, dynamic>>> homeworksNotifier =
    ValueNotifier(const []);

/// Latest fetched lesson notes (class register remarks), available app-wide so
/// lesson detail sheets can attach register notes to the corresponding lesson.
final ValueNotifier<List<Map<String, dynamic>>> lessonNotesNotifier =
    ValueNotifier(const []);

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

