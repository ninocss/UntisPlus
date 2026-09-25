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

String? activeUntisAccountId;
final ValueNotifier<List<UntisAccount>> untisAccountsNotifier = ValueNotifier(
  const [],
);

UntisAccount? get activeUntisAccount {
  final activeId = activeUntisAccountId;
  if (activeId == null) return null;
  for (final account in untisAccountsNotifier.value) {
    if (account.id == activeId) return account;
  }
  return null;
}

/// Personal planning data follows the selected account. App appearance and
/// language deliberately remain shared device preferences.
String _accountDataKey(String key) {
  final accountId = activeUntisAccountId;
  return accountId == null
      ? key
      : UntisAccountStore.personalDataKey(accountId, key);
}

UntisAccountStore _accountStore(SharedPreferences prefs) => UntisAccountStore(
  preferences: prefs,
  credentials: SecureAccountCredentialStore(CredentialVault.instance),
);

Future<void> _copyLegacyAccountData(
  SharedPreferences prefs,
  String accountId,
) => _accountStore(prefs).copyLegacyPersonalData(accountId);

Future<void> _syncActiveAccountDataForBackground(
  SharedPreferences prefs,
) async {
  final accountId = activeUntisAccountId;
  if (accountId == null) return;
  await _accountStore(prefs).publishBackgroundPersonalData(accountId);
}

List<UntisAccount> _readUntisAccounts(SharedPreferences prefs) =>
    _accountStore(prefs).readPublicAccounts();

Future<List<UntisAccount>> _readHydratedUntisAccounts(
  SharedPreferences prefs,
) => _accountStore(prefs).readHydratedAccounts();

Future<void> _writeUntisAccounts(
  SharedPreferences prefs,
  List<UntisAccount> accounts, {
  bool includeSecrets = false,
}) async {
  final ordered = await _accountStore(
    prefs,
  ).writeAccounts(accounts, includeSecrets: includeSecrets);
  untisAccountsNotifier.value = ordered;
  unawaited(
    WidgetService.publishAccountCatalog(
      ordered.map(
        (account) => {
          'id': account.id,
          'label': account.label,
          'school': account.schoolName,
        },
      ),
    ),
  );
}

Future<bool> _writeActiveAccountFields(
  SharedPreferences prefs,
  UntisAccount account,
) async {
  sessionID = account.sessionId;
  schoolUrl = account.schoolUrl;
  schoolName = account.schoolName;
  personId = account.personId;
  personType = account.personType;
  activeUntisAccountId = account.id;
  demoModeNotifier.value = false;
  final storedSecurely = await CredentialVault.instance.writeAndVerifyAccount(
    accountId: account.id,
    credentials: AccountCredentials(
      password: account.password,
      credentialMode: account.credentialMode,
      sessionId: account.sessionId,
    ),
  );
  await Future.wait([
    prefs.setString(activeUntisAccountStorageKey, account.id),
    prefs.setString('schoolUrl', account.schoolUrl),
    prefs.setString('schoolName', account.schoolName),
    prefs.setString('username', account.username),
    prefs.setInt('personId', account.personId),
    prefs.setInt('personType', account.personType),
    prefs.setBool('demoMode', false),
  ]);
  if (storedSecurely) {
    await Future.wait([
      prefs.remove('sessionId'),
      prefs.remove('password'),
      prefs.remove('loginCredentialMode'),
    ]);
  }
  return storedSecurely;
}

/// Migrates the former one-account preference layout on first launch.
Future<void> initializeUntisAccounts(SharedPreferences prefs) async {
  var accounts = await _readHydratedUntisAccounts(prefs);
  if (accounts.isEmpty) {
    final username = prefs.getString('username') ?? '';
    final url = prefs.getString('schoolUrl') ?? '';
    final name = prefs.getString('schoolName') ?? '';
    if (username.isNotEmpty && url.isNotEmpty && name.isNotEmpty) {
      final migrated = UntisAccount(
        id: 'legacy-${DateTime.now().microsecondsSinceEpoch}',
        username: username,
        schoolUrl: url,
        schoolName: name,
        password: prefs.getString('password') ?? '',
        credentialMode: prefs.getString('loginCredentialMode') ?? 'password',
        sessionId: prefs.getString('sessionId') ?? '',
        personId: prefs.getInt('personId') ?? 0,
        personType: prefs.getInt('personType') ?? 5,
        lastUsedAt: DateTime.now(),
      );
      accounts = [migrated];
      final storedSecurely = await _writeActiveAccountFields(prefs, migrated);
      await _writeUntisAccounts(
        prefs,
        accounts,
        includeSecrets: !storedSecurely,
      );
      await _copyLegacyAccountData(prefs, migrated.id);
      return;
    }
  }

  // Rewriting strips secrets from legacy account JSON after they have been
  // verified in the native secure store.
  var canStripSecrets = true;
  for (final account in accounts) {
    if (account.password.isEmpty && account.sessionId.isEmpty) continue;
    final stored = await CredentialVault.instance.readAccount(account.id);
    if (stored.password != account.password ||
        stored.sessionId != account.sessionId) {
      canStripSecrets = false;
      break;
    }
  }
  await _writeUntisAccounts(prefs, accounts, includeSecrets: !canStripSecrets);
  untisAccountsNotifier.value = List.unmodifiable(accounts);
  unawaited(
    WidgetService.publishAccountCatalog(
      accounts.map(
        (account) => {
          'id': account.id,
          'label': account.label,
          'school': account.schoolName,
        },
      ),
    ),
  );
  if (accounts.isEmpty) return;
  final requestedId = prefs.getString(activeUntisAccountStorageKey);
  UntisAccount active = accounts.first;
  for (final account in accounts) {
    if (account.id == requestedId) {
      active = account;
      break;
    }
  }
  await _writeActiveAccountFields(prefs, active);
}

Future<void> saveOrUpdateUntisAccount({
  required String username,
  required String password,
  required String credentialMode,
}) async {
  final prefs = SettingsStore.instance.preferences;
  final accounts = (await _readHydratedUntisAccounts(prefs)).toList();
  final matchingIndex = accounts.indexWhere(
    (account) =>
        account.username.toLowerCase() == username.trim().toLowerCase() &&
        account.schoolUrl.toLowerCase() == schoolUrl.trim().toLowerCase() &&
        account.schoolName.toLowerCase() == schoolName.trim().toLowerCase(),
  );
  final account = UntisAccount(
    id: matchingIndex >= 0
        ? accounts[matchingIndex].id
        : 'account-${DateTime.now().microsecondsSinceEpoch}',
    username: username.trim(),
    schoolUrl: schoolUrl.trim(),
    schoolName: schoolName.trim(),
    password: password,
    credentialMode: credentialMode,
    sessionId: sessionID,
    personId: personId,
    personType: personType,
    lastUsedAt: DateTime.now(),
  );
  if (matchingIndex >= 0) {
    accounts[matchingIndex] = account;
  } else {
    accounts.add(account);
  }
  if (activeUntisAccountId != account.id || demoModeNotifier.value) {
    _clearTransientSchoolData();
  }
  final storedSecurely = await _writeActiveAccountFields(prefs, account);
  await _writeUntisAccounts(prefs, accounts, includeSecrets: !storedSecurely);
  await loadAccountPersonalData();
  await _syncActiveAccountDataForBackground(prefs);
}

Future<void> switchUntisAccount(String accountId) async {
  final prefs = SettingsStore.instance.preferences;
  final accounts = (await _readHydratedUntisAccounts(prefs)).toList();
  final index = accounts.indexWhere((account) => account.id == accountId);
  if (index < 0) return;
  final account = accounts[index].copyWith(lastUsedAt: DateTime.now());
  accounts[index] = account;
  _clearTransientSchoolData();
  final storedSecurely = await _writeActiveAccountFields(prefs, account);
  await _writeUntisAccounts(prefs, accounts, includeSecrets: !storedSecurely);
  await _syncActiveAccountDataForBackground(prefs);
  await loadAccountPersonalData();
  final changes = await ChangeRepository().loadChanges(accountId);
  unreadTimetableChangesNotifier.value = changes
      .where((change) => !change.isRead)
      .length;
}

Future<bool> removeUntisAccount(String accountId) async {
  final prefs = SettingsStore.instance.preferences;
  final accounts = _readUntisAccounts(
    prefs,
  ).where((account) => account.id != accountId).toList();
  await CredentialVault.instance.deleteAccount(accountId);
  await OfflineCacheStore.instance.deletePrefix('$accountId|');
  await _writeUntisAccounts(prefs, accounts);
  if (activeUntisAccountId != accountId) return accounts.isNotEmpty;
  if (accounts.isNotEmpty) {
    await switchUntisAccount(accounts.first.id);
    return true;
  }
  activeUntisAccountId = null;
  sessionID = '';
  schoolUrl = '';
  schoolName = '';
  personId = 0;
  personType = 0;
  unreadTimetableChangesNotifier.value = 0;
  demoModeNotifier.value = false;
  await Future.wait([
    prefs.remove(activeUntisAccountStorageKey),
    prefs.remove('sessionId'),
    prefs.remove('schoolUrl'),
    prefs.remove('schoolName'),
    prefs.remove('username'),
    prefs.remove('password'),
    prefs.remove('loginCredentialMode'),
    prefs.remove('personId'),
    prefs.remove('personType'),
    prefs.setBool('demoMode', false),
  ]);
  return false;
}

String geminiApiKey = "";
String openAiApiKey = "";
String mistralApiKey = "";
String customAiApiKey = "";

Future<void> loadSecureAiApiKeys(SharedPreferences prefs) async {
  final keys = await CredentialVault.instance.loadAndMigrateAiKeys(prefs);
  geminiApiKey = keys['gemini'] ?? geminiApiKey;
  openAiApiKey = keys['openai'] ?? openAiApiKey;
  mistralApiKey = keys['mistral'] ?? mistralApiKey;
  customAiApiKey = keys['custom'] ?? customAiApiKey;
}

Future<void> setSecureAiApiKey(String provider, String key) async {
  final normalized = _normalizeAiProvider(provider);
  switch (normalized) {
    case 'openai':
      openAiApiKey = key;
      break;
    case 'mistral':
      mistralApiKey = key;
      break;
    case 'custom':
      customAiApiKey = key;
      break;
    case 'gemini':
    default:
      geminiApiKey = key;
      break;
  }
  await CredentialVault.instance.writeAiApiKey(normalized, key);
}

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
final ValueNotifier<bool> aiEnabledNotifier = ValueNotifier(true);

Future<void> loadAiPreferences(SharedPreferences prefs) async {
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
  aiLocalModelPath = prefs.getString('aiLocalModelPath') ?? aiLocalModelPath;
  aiTemperature = prefs.getDouble('aiTemperature') ?? aiTemperature;
  aiMaxTokens = prefs.getInt('aiMaxTokens') ?? aiMaxTokens;
  aiTopP = prefs.getDouble('aiTopP') ?? aiTopP;
  aiPersona = prefs.getString('aiPersona') ?? aiPersona;
  await loadSecureAiApiKeys(prefs);
}

Future<void> saveAiProviderPreferences(SharedPreferences prefs) async {
  await Future.wait([
    prefs.setString('aiProvider', aiProvider),
    prefs.setString('aiModel', aiModel),
    prefs.setString('aiCustomCompatibility', aiCustomCompatibility),
    prefs.setString('aiCustomBaseUrl', aiCustomBaseUrl),
    prefs.setString('aiSystemPromptTemplate', aiSystemPromptTemplate),
    prefs.setString('aiLocalModelPath', aiLocalModelPath),
    CredentialVault.instance.writeAiApiKey('gemini', geminiApiKey),
    CredentialVault.instance.writeAiApiKey('openai', openAiApiKey),
    CredentialVault.instance.writeAiApiKey('mistral', mistralApiKey),
    CredentialVault.instance.writeAiApiKey('custom', customAiApiKey),
  ]);
}

const List<String> kSupportedAiProviders = [
  'gemini',
  'openai',
  'mistral',
  'custom',
  'local',
];

const List<String> kSupportedAiCustomCompatibilities = ['openai', 'gemini'];

/// Available local models for on-device inference.
///
/// [sha256] pins the exact artifact that this version of the app is built
/// against. A downloaded GGUF is only promoted to the final model path after
/// its digest matches the pinned value, so a tampered, swapped or compromised
/// upstream file is rejected before it ever reaches the native llama.cpp
/// parser. Keep the digest in sync whenever the upstream artifact changes.
///
/// Digests are the git-LFS SHA-256 of the resolved HuggingFace file and can be
/// looked up via
/// `https://huggingface.co/api/models/<repo>/tree/main?recursive=true`
/// (the `lfs.oid` field).
class LocalModelInfo {
  final String id;
  final String name;
  final String url;
  final double sizeGb;
  final String description;

  /// Lowercase hex SHA-256 of the exact file served by [url]. Empty means
  /// "no pinned digest" and skips checksum verification (never leave it empty
  /// for freshly added models when a digest can be pinned).
  final String sha256;

  const LocalModelInfo({
    required this.id,
    required this.name,
    required this.url,
    required this.sizeGb,
    required this.description,
    required this.sha256,
  });
}

const List<LocalModelInfo> kLocalModels = [
  LocalModelInfo(
    id: 'gemma-3-1b-it-q4_k_m',
    name: 'Gemma 3 1B-IT (Q4_K_M)',
    url:
        'https://huggingface.co/bartowski/google_gemma-3-1b-it-GGUF/resolve/main/google_gemma-3-1b-it-Q4_K_M.gguf',
    sizeGb: 0.8,
    description: '',
    sha256: '12bf0fff8815d5f73a3c9b586bd8fee8e7b248c935de70dec367679873d0f29d',
  ),
  LocalModelInfo(
    id: 'llama-3.2-1b-instruct-q4_k_m',
    name: 'Llama 3.2 1B-Instruct (Q4_K_M)',
    url:
        'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
    sizeGb: 0.8,
    description: '',
    sha256: '6f85a640a97cf2bf5b8e764087b1e83da0fdb51d7c9fab7d0fece9385611df83',
  ),
  LocalModelInfo(
    id: 'qwen-2.5-1.5b-instruct-q4_k_m',
    name: 'Qwen 2.5 1.5B-Instruct (Q4_K_M)',
    url:
        'https://huggingface.co/bartowski/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf',
    sizeGb: 1.0,
    description: '',
    sha256: '1adf0b11065d8ad2e8123ea110d1ec956dab4ab038eab665614adba04b6c3370',
  ),
  LocalModelInfo(
    id: 'llama-3.2-3b-instruct-q4_k_m',
    name: 'Llama 3.2 3B-Instruct (Q4_K_M)',
    url:
        'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    sizeGb: 2.0,
    description: '',
    sha256: '6c1a2b41161032677be168d354123594c0e6e67d2b9227c84f296ad037c728ff',
  ),
  LocalModelInfo(
    id: 'phi-3.5-mini-instruct-q4_k_m',
    name: 'Phi-3.5-mini-Instruct (Q4_K_M)',
    url:
        'https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf',
    sizeGb: 2.4,
    description: '',
    sha256: 'e4165e3a71af97f1b4820da61079826d8752a2088e313af0c7d346796c38eff5',
  ),
  LocalModelInfo(
    id: 'gemma-4-e4b-it-q4_k_m',
    name: 'Gemma 4 E4B-IT (Q4_K_M)',
    url:
        'https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-Q4_K_M.gguf',
    sizeGb: 4.98,
    description: '',
    sha256: '85a896a047553e842f25297ee5b031d64ff30147d9c4af17b1e4b394cd1fab87',
  ),
];

/// Returns the catalog entry whose served file name matches [path]'s file
/// name, or null when [path] does not correspond to any pinned model.
LocalModelInfo? _localModelForPath(String path) {
  final fileName = path.split(Platform.pathSeparator).last;
  if (fileName.isEmpty) return null;
  for (final model in kLocalModels) {
    if (model.url.split('/').last == fileName) return model;
  }
  return null;
}

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
    case 'custom':
      if (_normalizeAiCustomCompatibility(customCompatibility ?? 'openai') ==
          'gemini') {
        return const [
          'gemini-3.6-flash',
          'gemini-3.6-pro',
          'gemini-3.6-flash-lite',
        ];
      }
      return const ['gpt-4o-mini', 'gpt-4o', 'o4-mini', 'o3-mini'];
    case 'gemini':
    default:
      return const [
        'gemini-3.6-flash',
        'gemini-3.6-pro',
        'gemini-3.6-flash-lite',
      ];
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

const int kCurrentOnboardingVersion = 2;
const int kCurrentTutorialVersion = 2;

final ValueNotifier<String> appLocaleNotifier = ValueNotifier('de');
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);
final ValueNotifier<AppThemeId> visualThemeNotifier = ValueNotifier(
  AppThemeId.defaultTheme,
);
final ValueNotifier<Map<String, bool>> themeBlurPreferencesNotifier =
    ValueNotifier({
      AppThemeId.defaultTheme.storageKey: true,
      AppThemeId.glass.storageKey: true,
      AppThemeId.cyber.storageKey: true,
    });
final ValueNotifier<bool> showCancelledNotifier = ValueNotifier(true);
final ValueNotifier<int> timetableSwitchAnimationNotifier = ValueNotifier(0);
final ValueNotifier<int> cancelledLessonColorNotifier = ValueNotifier(
  0xFFFF1744,
);
final ValueNotifier<bool> monochromeLessonsNotifier = ValueNotifier(false);
final ValueNotifier<int> monochromeLessonColorNotifier = ValueNotifier(
  0xFF757575,
);
final ValueNotifier<bool> backgroundAnimationsNotifier = ValueNotifier(true);
final ValueNotifier<int> backgroundAnimationStyleNotifier = ValueNotifier(0);
final ValueNotifier<bool> backgroundGyroscopeNotifier = ValueNotifier(false);
final ValueNotifier<bool> progressivePushNotifier = ValueNotifier(true);
final ValueNotifier<bool> dailyBriefingPushNotifier = ValueNotifier(true);
final ValueNotifier<bool> importantChangesPushNotifier = ValueNotifier(true);
final ValueNotifier<bool> notifyChangeCancellationsNotifier = ValueNotifier(
  true,
);
final ValueNotifier<bool> notifyChangeRoomNotifier = ValueNotifier(true);
final ValueNotifier<bool> notifyChangeTeacherNotifier = ValueNotifier(true);
final ValueNotifier<bool> notifyChangeOtherNotifier = ValueNotifier(true);
final ValueNotifier<String?> pendingTimetableActionNotifier = ValueNotifier(
  null,
);
final ValueNotifier<String?> pendingTimetableCurrentLessonNotifier =
    ValueNotifier(null);
final ValueNotifier<String?> pendingTimetableNextLessonNotifier = ValueNotifier(
  null,
);
final ValueNotifier<int?> pendingChangeHighlightDateNotifier = ValueNotifier(
  null,
);
final ValueNotifier<int?> pendingChangeHighlightStartTimeNotifier =
    ValueNotifier(null);

/// A native Assistant or App Action can request opening the in-app AI screen.
final ValueNotifier<bool> pendingAssistantOpenNotifier = ValueNotifier(false);
final ValueNotifier<String?> pendingAssistantPromptNotifier = ValueNotifier(
  null,
);

final ValueNotifier<bool> blurEnabledNotifier = ValueNotifier(true);
final ValueNotifier<int> headerStyleNotifier = ValueNotifier(0);
final ValueNotifier<double> blurStrengthNotifier = ValueNotifier(1.0);
final ValueNotifier<bool> surfaceBlurEnabledNotifier = ValueNotifier(true);
final ValueNotifier<int> surfaceCornerModeNotifier = ValueNotifier(0);
final ValueNotifier<int> surfaceCornerRadiusNotifier = ValueNotifier(24);
final ValueNotifier<bool> appBgBlurEnabledNotifier = ValueNotifier(false);
final ValueNotifier<double> appBgBlurAmountNotifier = ValueNotifier(10.0);
final ValueNotifier<bool> demoModeNotifier = ValueNotifier(false);
final ValueNotifier<int> pageTransitionNotifier = ValueNotifier(0);
final ValueNotifier<bool> mainTabFadeUpEnabledNotifier = ValueNotifier(false);
final ValueNotifier<bool> useMaterialYouNotifier = ValueNotifier(true);
final ValueNotifier<bool> isAmoledNotifier = ValueNotifier(false);
final ValueNotifier<int> customColorSeedNotifier = ValueNotifier(0xFF0F766E);

// ── LESSON DESIGN & STYLING NOTIFIERS ───────────────────────────────────────
final ValueNotifier<int> lessonCardStyleNotifier = ValueNotifier(0);
final ValueNotifier<bool> glowEffectsEnabledNotifier = ValueNotifier(false);
final ValueNotifier<bool> lessonBlurEnabledNotifier = ValueNotifier(false);
final ValueNotifier<double> lessonBlurAmountNotifier = ValueNotifier(12.0);
final ValueNotifier<double> lessonCardOpacityNotifier = ValueNotifier(0.9);
final ValueNotifier<double> lessonBorderRadiusNotifier = ValueNotifier(12.0);
final ValueNotifier<int> lessonAccentStyleNotifier = ValueNotifier(0);
final ValueNotifier<bool> lessonShowTeacherNotifier = ValueNotifier(true);
final ValueNotifier<bool> lessonFullTeacherNamesNotifier = ValueNotifier(false);

String lessonTeacherDisplayName(Map<dynamic, dynamic> lesson) {
  final short = lesson['_teacher']?.toString() ?? '';
  if (!lessonFullTeacherNamesNotifier.value) return short;
  final full = lesson['_teacherFull']?.toString().trim() ?? '';
  return full.isNotEmpty ? full : short;
}

final ValueNotifier<bool> lessonShowSubjectIconsNotifier = ValueNotifier(false);
final ValueNotifier<bool> lessonShowRoomNotifier = ValueNotifier(true);
final ValueNotifier<bool> lessonCompactModeNotifier = ValueNotifier(false);
final ValueNotifier<bool> lessonDimPastNotifier = ValueNotifier(true);
final ValueNotifier<bool> lessonCancelledPatternNotifier = ValueNotifier(true);

/// When true, the timetable shows teachers as "First Last" (full names when the
/// school exposes them). When false, the WebUntis short name/Kürzel is shown.
final ValueNotifier<bool> showFullTeacherNamesNotifier = ValueNotifier(true);

/// How many consecutive weekdays the day-grid timetable view shows at once
/// (1 = single day, 2 = two days, 3 = three days). The dedicated week view
/// always shows all five days.
final ValueNotifier<int> timetableDaySpanNotifier = ValueNotifier(1);

/// When true, pages pushed onto the navigator support the iOS-style "swipe
/// from the left edge to go back" gesture — the mobile equivalent of Android's
/// predictive back gesture. Defaults to enabled on iOS, where the system
/// otherwise offers no equivalent back-gesture affordance.
final ValueNotifier<bool> swipeBackGestureNotifier = ValueNotifier(
  defaultTargetPlatform == TargetPlatform.iOS,
);

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

final Set<String> _loadedDateFormattingLocales = <String>{};

Future<void> ensureDateFormattingForLocale(String locale) async {
  final icuLocale = _icuLocale(locale);
  if (!_loadedDateFormattingLocales.add(icuLocale)) return;
  try {
    await initializeDateFormatting(icuLocale, null);
  } catch (_) {
    _loadedDateFormattingLocales.remove(icuLocale);
    rethrow;
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

/// Latest fetched exams from the school server.
final ValueNotifier<List<Map<String, dynamic>>> apiExamsNotifier =
    ValueNotifier(const []);

final ValueNotifier<List<Map<String, dynamic>>> customHomeworkNotifier =
    ValueNotifier(const []);
final ValueNotifier<List<Map<String, dynamic>>> customExamsNotifier =
    ValueNotifier(const []);
final ValueNotifier<List<Map<String, dynamic>>> customGradesNotifier =
    ValueNotifier(const []);

List<Map<String, dynamic>> _decodeStoredMapList(List<String> values) => values
    .map((value) {
      try {
        return Map<String, dynamic>.from(jsonDecode(value) as Map);
      } catch (_) {
        return <String, dynamic>{};
      }
    })
    .where((value) => value.isNotEmpty)
    .toList(growable: false);

void _loadCustomList(
  SharedPreferences prefs,
  String field,
  ValueNotifier<List<Map<String, dynamic>>> notifier,
) {
  notifier.value = _decodeStoredMapList(
    prefs.getStringList(_accountDataKey(field)) ?? const [],
  );
}

Future<void> loadCustomData() async {
  final prefs = SettingsStore.instance.preferences;
  _loadCustomList(prefs, 'customHomework', customHomeworkNotifier);
  _loadCustomList(prefs, 'customExams', customExamsNotifier);
  _loadCustomList(prefs, 'customGrades', customGradesNotifier);
}

Future<void> loadAccountPersonalData() async {
  final prefs = SettingsStore.instance.preferences;
  await loadCustomData();
  try {
    final raw = prefs.getString(_accountDataKey('subjectPresentations'));
    final decoded = raw == null ? null : jsonDecode(raw);
    subjectPresentationsNotifier.value = decoded is Map
        ? decoded.map(
            (key, value) => MapEntry(
              key.toString(),
              value is Map
                  ? SubjectPresentation.fromJson(value)
                  : const SubjectPresentation(),
            ),
          )
        : const {};
  } catch (_) {
    subjectPresentationsNotifier.value = const {};
  }
  hiddenSubjectsNotifier.value =
      (prefs.getStringList(_accountDataKey('hiddenSubjects')) ?? const [])
          .toSet();
  try {
    final colorsJson = prefs.getString(_accountDataKey('subjectColors'));
    if (colorsJson == null) {
      subjectColorsNotifier.value = const {};
      return;
    }
    final decoded = jsonDecode(colorsJson);
    if (decoded is Map) {
      subjectColorsNotifier.value = decoded.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      );
    }
  } catch (_) {
    subjectColorsNotifier.value = const {};
  }
}

Future<void> _saveCustomList(
  String field,
  ValueNotifier<List<Map<String, dynamic>>> notifier,
  List<Map<String, dynamic>> values,
) async {
  notifier.value = List<Map<String, dynamic>>.from(values);
  final prefs = SettingsStore.instance.preferences;
  await prefs.setStringList(
    _accountDataKey(field),
    values.map(jsonEncode).toList(growable: false),
  );
}

Future<void> saveCustomHomework(List<Map<String, dynamic>> list) =>
    _saveCustomList('customHomework', customHomeworkNotifier, list);

Future<void> saveCustomExams(List<Map<String, dynamic>> list) =>
    _saveCustomList('customExams', customExamsNotifier, list);

Future<void> saveCustomGrades(List<Map<String, dynamic>> list) =>
    _saveCustomList('customGrades', customGradesNotifier, list);

final ValueNotifier<Set<String>> hiddenSubjectsNotifier = ValueNotifier({});

String _normalizedSubjectName(Object? value) =>
    value?.toString().trim().toLowerCase() ?? '';

/// Returns every known name for a subject (usually its short and long name).
/// Hidden subjects are persisted by short name, while exams and homework can
/// contain the long name, so consumers must compare against both forms.
Set<String> _subjectAliases(Object? subject) {
  final normalized = _normalizedSubjectName(subject);
  if (normalized.isEmpty) return const <String>{};
  final aliases = <String>{normalized};
  for (final lessons in currentWeekDataNotifier.value.values) {
    for (final lesson in lessons.whereType<Map>()) {
      final shortName = _normalizedSubjectName(lesson['_subjectShort']);
      final longName = _normalizedSubjectName(lesson['_subjectLong']);
      if (shortName == normalized || longName == normalized) {
        if (shortName.isNotEmpty) aliases.add(shortName);
        if (longName.isNotEmpty) aliases.add(longName);
      }
    }
  }
  return aliases;
}

bool _isSubjectHidden(Object? subject) {
  final aliases = _subjectAliases(subject);
  if (aliases.isEmpty) return false;
  final hidden = hiddenSubjectsNotifier.value
      .map(_normalizedSubjectName)
      .where((value) => value.isNotEmpty)
      .toSet();
  return aliases.any(hidden.contains);
}

bool _isLessonSubjectHidden(Object? lesson) {
  if (lesson is! Map) return false;
  final directCandidates = <Object?>[
    lesson['_subjectShort'],
    lesson['_subjectLong'],
    lesson['subject'],
    lesson['subjectName'],
    lesson['name'],
  ];
  final subjects = lesson['su'];
  if (subjects is List) {
    for (final subject in subjects.whereType<Map>()) {
      directCandidates
        ..add(subject['name'])
        ..add(subject['longName'])
        ..add(subject['longname']);
    }
  }
  final nestedLesson = lesson['_lesson'];
  if (nestedLesson is Map) {
    directCandidates
      ..add(nestedLesson['_subjectShort'])
      ..add(nestedLesson['_subjectLong']);
    final nestedSubjects = nestedLesson['su'];
    if (nestedSubjects is List) {
      for (final subject in nestedSubjects.whereType<Map>()) {
        directCandidates
          ..add(subject['name'])
          ..add(subject['longName'])
          ..add(subject['longname']);
      }
    }
  }
  return directCandidates.any(_isSubjectHidden);
}

List<String> _visibleKnownSubjects() {
  final subjects = knownSubjectsNotifier.value
      .where((subject) => !_isSubjectHidden(subject))
      .toList();
  subjects.sort();
  return subjects;
}

Future<void> _updateHiddenSubjects(
  void Function(Set<String> values) update,
) async {
  final updated = Set<String>.from(hiddenSubjectsNotifier.value);
  update(updated);
  hiddenSubjectsNotifier.value = updated;
  final prefs = SettingsStore.instance.preferences;
  await prefs.setStringList(
    _accountDataKey('hiddenSubjects'),
    updated.toList(),
  );
  await _syncActiveAccountDataForBackground(prefs);
}

Future<void> _hideSubject(String key) => key.isEmpty
    ? Future.value()
    : _updateHiddenSubjects((values) => values.add(key));

Future<void> _unhideSubject(String key) =>
    _updateHiddenSubjects((values) => values.remove(key));

final ValueNotifier<Map<String, int>> subjectColorsNotifier = ValueNotifier({});

class SubjectPresentation {
  const SubjectPresentation({
    this.name = '',
    this.icon = '',
    this.aliases = const [],
  });

  final String name;
  final String icon;
  final List<String> aliases;

  factory SubjectPresentation.fromJson(Map value) => SubjectPresentation(
    name: value['name']?.toString().trim() ?? '',
    icon: value['icon']?.toString().trim() ?? '',
    aliases: (value['aliases'] as List? ?? const [])
        .map((entry) => entry.toString())
        .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'aliases': aliases,
  };
}

void _clearTransientSchoolData() {
  currentWeekDataNotifier.value = const {};
  homeworksNotifier.value = const [];
  lessonNotesNotifier.value = const [];
  apiExamsNotifier.value = const [];
}

const Map<String, IconData> subjectIconChoices = {
  'book': Icons.menu_book_rounded,
  'calculate': Icons.calculate_rounded,
  'language': Icons.translate_rounded,
  'science': Icons.science_rounded,
  'nature': Icons.eco_rounded,
  'history': Icons.history_edu_rounded,
  'globe': Icons.public_rounded,
  'computer': Icons.computer_rounded,
  'music': Icons.music_note_rounded,
  'art': Icons.palette_rounded,
  'sport': Icons.sports_soccer_rounded,
  'people': Icons.groups_rounded,
  'school': Icons.school_rounded,
};

final ValueNotifier<Map<String, SubjectPresentation>>
subjectPresentationsNotifier = ValueNotifier(const {});

SubjectPresentation? _subjectPresentation(Object? original) {
  final aliases = _subjectAliases(original);
  for (final entry in subjectPresentationsNotifier.value.entries) {
    if (aliases.contains(_normalizedSubjectName(entry.key)) ||
        entry.value.aliases.any(
          (alias) => aliases.contains(_normalizedSubjectName(alias)),
        )) {
      return entry.value;
    }
  }
  return null;
}

String _displaySubject(Object? original) {
  final custom = _subjectPresentation(original)?.name ?? '';
  return custom.isNotEmpty ? custom : original?.toString() ?? '';
}

IconData? _customSubjectIcon(Object? original) =>
    subjectIconChoices[_subjectPresentation(original)?.icon];

Future<void> _setSubjectPresentation(
  String key,
  SubjectPresentation? presentation,
) async {
  final updated = Map<String, SubjectPresentation>.from(
    subjectPresentationsNotifier.value,
  );
  if (presentation == null ||
      (presentation.name.isEmpty && presentation.icon.isEmpty)) {
    updated.remove(key);
  } else {
    updated[key] = presentation;
  }
  subjectPresentationsNotifier.value = updated;
  await SettingsStore.instance.preferences.setString(
    _accountDataKey('subjectPresentations'),
    jsonEncode(updated.map((key, value) => MapEntry(key, value.toJson()))),
  );
}

final ValueNotifier<Set<String>> knownSubjectsNotifier = ValueNotifier({});

/// Launcher icon chosen by the user. Android applies this through aliases;
/// other platforms keep the preference so a later native implementation can use it.
final ValueNotifier<String> appIconNotifier = ValueNotifier('default');

/// Latest loaded timetable week data.
final ValueNotifier<Map<int, List<dynamic>>> currentWeekDataNotifier =
    ValueNotifier({});

/// Transitional bridge for the expressive navigation badge. The persisted
/// source of truth lives in ChangeRepository and remains account-scoped.
final ValueNotifier<int> unreadTimetableChangesNotifier = ValueNotifier(0);

/// Number of unread inbox messages since the user last opened the Info tab.
final ValueNotifier<int> unreadInboxMessagesNotifier = ValueNotifier(0);

Future<void> _updateSubjectColors(
  void Function(Map<String, int> values) update,
) async {
  final updated = Map<String, int>.from(subjectColorsNotifier.value);
  update(updated);
  subjectColorsNotifier.value = updated;
  final prefs = SettingsStore.instance.preferences;
  await prefs.setString(
    _accountDataKey('subjectColors'),
    jsonEncode(Map<String, dynamic>.from(updated)),
  );
}

Future<void> _setSubjectColor(String key, int colorValue) => key.isEmpty
    ? Future.value()
    : _updateSubjectColors((values) => values[key] = colorValue);

Future<void> _clearSubjectColor(String key) =>
    _updateSubjectColors((values) => values.remove(key));

String _formatUntisTime(String time) {
  return formatUntisTime(time);
}

Future<bool>? _reAuthenticationInFlight;

/// Shares a refresh across concurrent requests. The Info tab loads Inbox and
/// school news together, so an expired session must be renewed once before
/// each request retries with the new cookie.
Future<bool> _reAuthenticate() {
  final inFlight = _reAuthenticationInFlight;
  if (inFlight != null) return inFlight;

  return _reAuthenticationInFlight = _performReAuthentication().whenComplete(
    () => _reAuthenticationInFlight = null,
  );
}

Future<bool> _performReAuthentication() async {
  final prefs = SettingsStore.instance.preferences;
  final activeId = activeUntisAccountId;
  final account = activeId == null
      ? null
      : (await _readHydratedUntisAccounts(
          prefs,
        )).where((entry) => entry.id == activeId).firstOrNull;
  final user = account?.username ?? prefs.getString('username') ?? '';
  final pass = account?.password ?? '';
  final useLoginKey = account?.credentialMode == 'loginKey';
  if (user.isEmpty || pass.isEmpty) return false;

  final loginRepository = WebUntisLoginRepository();
  try {
    final authResult = await loginRepository.authenticate(
      schoolUrl: account?.schoolUrl ?? schoolUrl,
      schoolName: account?.schoolName ?? schoolName,
      username: user,
      credential: pass,
      clientName: 'UntisPlus',
      requestId: 'relogin',
      useLoginKey: useLoginKey,
    );
    if (authResult.isSuccess) {
      sessionID = authResult.sessionId;
      final accounts = (await _readHydratedUntisAccounts(prefs)).toList();
      final index = accounts.indexWhere(
        (account) => account.id == activeUntisAccountId,
      );
      if (index >= 0) {
        var corrected = accounts[index];
        // Guardian accounts target a parent element that has no timetable.
        // Every re-authentication is another chance to redirect the stored
        // element to the first linked student.
        if (corrected.personType == 3 && authResult != null) {
          final element = _resolveTimetableElementFromAuth(
            authResult,
            corrected.personId,
            corrected.personType,
          );
          final childId = element['personId'] as int?;
          final childType = element['personType'] as int?;
          if (childId != null &&
              childType != null &&
              (childId != corrected.personId ||
                  childType != corrected.personType)) {
            corrected = corrected.copyWith(
              personId: childId,
              personType: childType,
            );
          }
        }
        accounts[index] = corrected.copyWith(
          sessionId: sessionID,
          lastUsedAt: DateTime.now(),
        );
        final storedSecurely = await _writeActiveAccountFields(
          prefs,
          accounts[index],
        );
        await _writeUntisAccounts(
          prefs,
          accounts,
          includeSecrets: !storedSecurely,
        );
      }
      return true;
    }
  } catch (_) {
    // A failed background re-authentication is surfaced by the original
    // request through its existing error state.
  } finally {
    loginRepository.close();
  }
  return false;
}

// ── CLASS FAVORITES & DEFAULTS ──────────────────────────────────────────────
int? defaultClassId;
String? defaultClassName;
Set<int> favoriteClassIds = {};
