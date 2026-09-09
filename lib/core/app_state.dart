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

/// A locally stored WebUntis login. Credentials remain on-device, just like
/// the previous single-account setup; this only makes the old profile
/// switchable instead of overwriting it when another account is added.
class UntisAccount {
  final String id;
  final String username;
  final String schoolUrl;
  final String schoolName;
  final String password;
  final String credentialMode;
  final String sessionId;
  final int personId;
  final int personType;
  final DateTime lastUsedAt;

  const UntisAccount({
    required this.id,
    required this.username,
    required this.schoolUrl,
    required this.schoolName,
    required this.password,
    required this.credentialMode,
    required this.sessionId,
    required this.personId,
    required this.personType,
    required this.lastUsedAt,
  });

  String get label => username.isEmpty ? schoolName : username;

  /// Public profile metadata only. Secrets are stored by [CredentialVault].
  Map<String, dynamic> toJson({bool includeSecrets = false}) => {
    'id': id,
    'username': username,
    'schoolUrl': schoolUrl,
    'schoolName': schoolName,
    if (includeSecrets) 'password': password,
    if (includeSecrets) 'credentialMode': credentialMode,
    if (includeSecrets) 'sessionId': sessionId,
    'personId': personId,
    'personType': personType,
    'lastUsedAt': lastUsedAt.toIso8601String(),
  };

  factory UntisAccount.fromJson(Map<String, dynamic> json) {
    return UntisAccount(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      schoolUrl: json['schoolUrl']?.toString() ?? '',
      schoolName: json['schoolName']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      credentialMode: json['credentialMode']?.toString() ?? 'password',
      sessionId: json['sessionId']?.toString() ?? '',
      personId: (json['personId'] as num?)?.toInt() ?? 0,
      personType: (json['personType'] as num?)?.toInt() ?? 5,
      lastUsedAt:
          DateTime.tryParse(json['lastUsedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  UntisAccount copyWith({
    String? password,
    String? credentialMode,
    String? sessionId,
    DateTime? lastUsedAt,
  }) => UntisAccount(
    id: id,
    username: username,
    schoolUrl: schoolUrl,
    schoolName: schoolName,
    password: password ?? this.password,
    credentialMode: credentialMode ?? this.credentialMode,
    sessionId: sessionId ?? this.sessionId,
    personId: personId,
    personType: personType,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
}

const String _accountsStorageKey = 'untisAccountsV1';
const String _activeAccountStorageKey = 'activeUntisAccountId';
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
  return accountId == null ? key : 'account.$accountId.$key';
}

Future<void> _copyLegacyAccountData(
  SharedPreferences prefs,
  String accountId,
) async {
  for (final key in const [
    'customHomework',
    'customExams',
    'customGrades',
    'hiddenSubjects',
  ]) {
    final scopedKey = 'account.$accountId.$key';
    if (!prefs.containsKey(scopedKey) && prefs.containsKey(key)) {
      await prefs.setStringList(
        scopedKey,
        prefs.getStringList(key) ?? const [],
      );
    }
  }
  const colorKey = 'subjectColors';
  final scopedColorKey = 'account.$accountId.$colorKey';
  if (!prefs.containsKey(scopedColorKey) && prefs.containsKey(colorKey)) {
    await prefs.setString(scopedColorKey, prefs.getString(colorKey) ?? '{}');
  }
}

Future<void> _syncActiveAccountDataForBackground(
  SharedPreferences prefs,
) async {
  for (final key in const ['hiddenSubjects']) {
    await prefs.setStringList(
      key,
      prefs.getStringList(_accountDataKey(key)) ?? const [],
    );
  }
}

List<UntisAccount> _readUntisAccounts(SharedPreferences prefs) {
  try {
    final decoded = jsonDecode(prefs.getString(_accountsStorageKey) ?? '[]');
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => UntisAccount.fromJson(Map<String, dynamic>.from(item)))
        .where(
          (account) =>
              account.id.isNotEmpty &&
              account.schoolUrl.isNotEmpty &&
              account.schoolName.isNotEmpty,
        )
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}

Future<List<UntisAccount>> _readHydratedUntisAccounts(
  SharedPreferences prefs,
) async {
  final publicAccounts = _readUntisAccounts(prefs);
  final requestedActiveId = prefs.getString(_activeAccountStorageKey);
  final hydrated = <UntisAccount>[];
  for (final account in publicAccounts) {
    var credentials = await CredentialVault.instance.readAccount(account.id);
    final isRequestedActive = account.id == requestedActiveId;
    final legacyPassword = account.password.isNotEmpty
        ? account.password
        : isRequestedActive
        ? prefs.getString('password') ?? ''
        : '';
    final legacyMode = account.credentialMode.isNotEmpty
        ? account.credentialMode
        : isRequestedActive
        ? prefs.getString('loginCredentialMode') ?? 'password'
        : 'password';
    final legacySession = account.sessionId.isNotEmpty
        ? account.sessionId
        : isRequestedActive
        ? prefs.getString('sessionId') ?? ''
        : '';
    if (credentials.isEmpty &&
        (legacyPassword.isNotEmpty || legacySession.isNotEmpty)) {
      final legacy = AccountCredentials(
        password: legacyPassword,
        credentialMode: legacyMode,
        sessionId: legacySession,
      );
      await CredentialVault.instance.writeAndVerifyAccount(
        accountId: account.id,
        credentials: legacy,
      );
      // Keep the legacy values in memory even if the native store is
      // temporarily unavailable. The caller then preserves them in the
      // legacy JSON instead of destructively stripping them.
      credentials = legacy;
    }
    hydrated.add(
      account.copyWith(
        password: credentials.password,
        credentialMode: credentials.credentialMode,
        sessionId: credentials.sessionId,
      ),
    );
  }
  return hydrated;
}

Future<void> _writeUntisAccounts(
  SharedPreferences prefs,
  List<UntisAccount> accounts, {
  bool includeSecrets = false,
}) async {
  final ordered = List<UntisAccount>.from(accounts)
    ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  untisAccountsNotifier.value = List.unmodifiable(ordered);
  await prefs.setString(
    _accountsStorageKey,
    jsonEncode(
      ordered
          .map((account) => account.toJson(includeSecrets: includeSecrets))
          .toList(),
    ),
  );
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
    prefs.setString(_activeAccountStorageKey, account.id),
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
  final requestedId = prefs.getString(_activeAccountStorageKey);
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
  final prefs = await SharedPreferences.getInstance();
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
  final storedSecurely = await _writeActiveAccountFields(prefs, account);
  await _writeUntisAccounts(prefs, accounts, includeSecrets: !storedSecurely);
  await loadAccountPersonalData();
  await _syncActiveAccountDataForBackground(prefs);
}

Future<void> switchUntisAccount(String accountId) async {
  final prefs = await SharedPreferences.getInstance();
  final accounts = (await _readHydratedUntisAccounts(prefs)).toList();
  final index = accounts.indexWhere((account) => account.id == accountId);
  if (index < 0) return;
  final account = accounts[index].copyWith(lastUsedAt: DateTime.now());
  accounts[index] = account;
  final storedSecurely = await _writeActiveAccountFields(prefs, account);
  await _writeUntisAccounts(prefs, accounts, includeSecrets: !storedSecurely);
  await _syncActiveAccountDataForBackground(prefs);
  await loadAccountPersonalData();
  currentWeekDataNotifier.value = const {};
  homeworksNotifier.value = const [];
  lessonNotesNotifier.value = const [];
  apiExamsNotifier.value = const [];
  final changes = await ChangeRepository().loadChanges(accountId);
  unreadTimetableChangesNotifier.value = changes
      .where((change) => !change.isRead)
      .length;
}

Future<bool> removeUntisAccount(String accountId) async {
  final prefs = await SharedPreferences.getInstance();
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
    prefs.remove(_activeAccountStorageKey),
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
    url:
        'https://huggingface.co/bartowski/google_gemma-3-1b-it-GGUF/resolve/main/google_gemma-3-1b-it-Q4_K_M.gguf',
    sizeGb: 0.8,
    description: '',
  ),
  LocalModelInfo(
    id: 'llama-3.2-1b-instruct-q4_k_m',
    name: 'Llama 3.2 1B-Instruct (Q4_K_M)',
    url:
        'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
    sizeGb: 0.8,
    description: '',
  ),
  LocalModelInfo(
    id: 'qwen-2.5-1.5b-instruct-q4_k_m',
    name: 'Qwen 2.5 1.5B-Instruct (Q4_K_M)',
    url:
        'https://huggingface.co/bartowski/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf',
    sizeGb: 1.0,
    description: '',
  ),
  LocalModelInfo(
    id: 'llama-3.2-3b-instruct-q4_k_m',
    name: 'Llama 3.2 3B-Instruct (Q4_K_M)',
    url:
        'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    sizeGb: 2.0,
    description: '',
  ),
  LocalModelInfo(
    id: 'phi-3.5-mini-instruct-q4_k_m',
    name: 'Phi-3.5-mini-Instruct (Q4_K_M)',
    url:
        'https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf',
    sizeGb: 2.4,
    description: '',
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
final ValueNotifier<AppThemeId> visualThemeNotifier = ValueNotifier(
  AppThemeId.defaultTheme,
);
final ValueNotifier<Map<String, bool>> themeBlurPreferencesNotifier =
    ValueNotifier({
      AppThemeId.defaultTheme.storageKey: true,
      AppThemeId.vivid.storageKey: true,
      AppThemeId.glass.storageKey: true,
      AppThemeId.cyber.storageKey: true,
    });
final ValueNotifier<bool> showCancelledNotifier = ValueNotifier(true);
final ValueNotifier<int> cancelledLessonColorNotifier = ValueNotifier(
  0xFFFF1744,
);
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

/// A native Assistant or App Action can request opening the in-app AI screen.
final ValueNotifier<bool> pendingAssistantOpenNotifier = ValueNotifier(false);
final ValueNotifier<String?> pendingAssistantPromptNotifier = ValueNotifier(
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
final ValueNotifier<bool> glowEffectsEnabledNotifier = ValueNotifier(false);
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

Future<void> loadCustomData() async {
  final prefs = await SharedPreferences.getInstance();

  final rawHw = prefs.getStringList(_accountDataKey('customHomework')) ?? [];
  customHomeworkNotifier.value = rawHw
      .map((e) {
        try {
          return Map<String, dynamic>.from(jsonDecode(e) as Map);
        } catch (_) {
          return <String, dynamic>{};
        }
      })
      .where((e) => e.isNotEmpty)
      .toList();

  final rawExams = prefs.getStringList(_accountDataKey('customExams')) ?? [];
  customExamsNotifier.value = rawExams
      .map((e) {
        try {
          return Map<String, dynamic>.from(jsonDecode(e) as Map);
        } catch (_) {
          return <String, dynamic>{};
        }
      })
      .where((e) => e.isNotEmpty)
      .toList();

  final rawGrades = prefs.getStringList(_accountDataKey('customGrades')) ?? [];
  customGradesNotifier.value = rawGrades
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

Future<void> loadAccountPersonalData() async {
  final prefs = await SharedPreferences.getInstance();
  await loadCustomData();
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

Future<void> saveCustomHomework(List<Map<String, dynamic>> list) async {
  customHomeworkNotifier.value = List.from(list);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _accountDataKey('customHomework'),
    list.map((e) => jsonEncode(e)).toList(),
  );
}

Future<void> saveCustomExams(List<Map<String, dynamic>> list) async {
  customExamsNotifier.value = List.from(list);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _accountDataKey('customExams'),
    list.map((e) => jsonEncode(e)).toList(),
  );
}

Future<void> saveCustomGrades(List<Map<String, dynamic>> list) async {
  customGradesNotifier.value = List.from(list);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _accountDataKey('customGrades'),
    list.map((e) => jsonEncode(e)).toList(),
  );
}

final ValueNotifier<Set<String>> hiddenSubjectsNotifier = ValueNotifier({});

Future<void> _hideSubject(String key) async {
  if (key.isEmpty) return;
  final updated = Set<String>.from(hiddenSubjectsNotifier.value)..add(key);
  hiddenSubjectsNotifier.value = updated;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _accountDataKey('hiddenSubjects'),
    updated.toList(),
  );
  await _syncActiveAccountDataForBackground(prefs);
}

Future<void> _unhideSubject(String key) async {
  final updated = Set<String>.from(hiddenSubjectsNotifier.value)..remove(key);
  hiddenSubjectsNotifier.value = updated;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _accountDataKey('hiddenSubjects'),
    updated.toList(),
  );
  await _syncActiveAccountDataForBackground(prefs);
}

final ValueNotifier<Map<String, int>> subjectColorsNotifier = ValueNotifier({});

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

Future<void> _setSubjectColor(String key, int colorValue) async {
  if (key.isEmpty) return;
  final updated = Map<String, int>.from(subjectColorsNotifier.value)
    ..[key] = colorValue;
  subjectColorsNotifier.value = updated;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _accountDataKey('subjectColors'),
    jsonEncode(Map<String, dynamic>.from(updated)),
  );
}

Future<void> _clearSubjectColor(String key) async {
  final updated = Map<String, int>.from(subjectColorsNotifier.value)
    ..remove(key);
  subjectColorsNotifier.value = updated;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _accountDataKey('subjectColors'),
    jsonEncode(Map<String, dynamic>.from(updated)),
  );
}

String _formatUntisTime(String time) {
  return formatUntisTime(time);
}

Future<bool> _reAuthenticate() async {
  final prefs = await SharedPreferences.getInstance();
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
      final accounts = (await _readHydratedUntisAccounts(prefs)).toList();
      final index = accounts.indexWhere(
        (account) => account.id == activeUntisAccountId,
      );
      if (index >= 0) {
        accounts[index] = accounts[index].copyWith(
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
  } catch (_) {}
  return false;
}

// ── CLASS FAVORITES & DEFAULTS ──────────────────────────────────────────────
int? defaultClassId;
String? defaultClassName;
Set<int> favoriteClassIds = {};
