part of '../main.dart';

const Map<String, String> _settingsLocaleLabels = {
  'de': 'Deutsch',
  'en': 'English',
  'fr': 'Français',
  'es': 'Español',
  'el': 'Ελληνικά',
};

Future<void> _settingsSetLocale(String code) async {
  appLocaleNotifier.value = code;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('appLocale', code);
}

Future<void> _settingsSetThemeMode(ThemeMode mode) async {
  themeModeNotifier.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('themeMode', ThemeMode.values.indexOf(mode));
}

Future<void> _settingsSetShowCancelled(bool value) async {
  showCancelledNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('showCancelled', value);
}

Future<void> _settingsSetBackgroundAnimations(bool value) async {
  backgroundAnimationsNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('backgroundAnimations', value);
}

Future<void> _settingsSetBackgroundAnimationStyle(int style) async {
  final normalized = style.clamp(0, 10);
  backgroundAnimationStyleNotifier.value = normalized;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('backgroundAnimationStyle', normalized);
}

Future<void> _settingsSetBackgroundGyroscope(bool value) async {
  backgroundGyroscopeNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('backgroundGyroscope', value);
}

Future<void> _settingsSetBlurEnabled(bool value) async {
  blurEnabledNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('blurEnabled', value);
}

Future<void> _settingsSetProgressivePush(bool value) async {
  progressivePushNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('progressivePush', value);
  if (!value) {
    await NotificationService().cancelNotification(
      kCurrentLessonNotificationId,
    );
  } else {
    updateUntisData().catchError((_) {});
  }
}

Future<void> _settingsSetDailyBriefingPush(bool value) async {
  dailyBriefingPushNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('dailyBriefingPush', value);
  if (!value) {
    await NotificationService().cancelNotification(
      kDailyBriefingNotificationId,
    );
  } else {
    updateUntisData().catchError((_) {});
  }
}

Future<void> _settingsSetImportantChangesPush(bool value) async {
  importantChangesPushNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('importantChangesPush', value);
}

Future<void> _settingsSetDemoMode(BuildContext context, bool enabled) async {
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

  if (sessionID.isEmpty && context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      _buildBouncyRoute(const OnboardingFlow()),
      (route) => false,
    );
  }
}

Future<void> _settingsLogout(BuildContext context) async {
  HapticFeedback.heavyImpact();
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    _buildBouncyRoute(const OnboardingFlow()),
    (route) => false,
  );
}

String _settingsAiCompatibilityLabel(AppL10n l, String value) {
  return _normalizeAiCustomCompatibility(value) == 'gemini'
      ? l.settingsAiCompatibilityGemini
      : l.settingsAiCompatibilityOpenAi;
}

String _settingsApiKeyHintForProvider(String provider) {
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

String _settingsApiKeyPortalUrlForProvider(String provider) {
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

Future<void> _settingsOpenApiKeyPortal(BuildContext context) async {
  final l = AppL10n.of(appLocaleNotifier.value);
  final url = _settingsApiKeyPortalUrlForProvider(aiProvider);
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

Future<void> _settingsSetAiProvider(String provider) async {
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
}

Future<void> _settingsSetAiModel(String model) async {
  aiModel = model;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('aiModel', aiModel);
}

Future<void> _settingsSetAiCustomCompatibility(String compatibility) async {
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
}

Future<void> _settingsSetAiCustomBaseUrl(String value) async {
  aiCustomBaseUrl = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('aiCustomBaseUrl', value);
}

Future<void> _settingsSetAiSystemPromptTemplate(String value) async {
  aiSystemPromptTemplate = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('aiSystemPromptTemplate', value);
}

Future<void> _settingsSetProviderApiKey(String key) async {
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

String _settingsMaskKey(String key) {
  if (key.isEmpty) return '';
  return key.length > 8
      ? '${key.substring(0, 7)}••••${key.substring(key.length - 4)}'
      : '••••••••';
}

Future<void> _settingsSyncFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();

  appLocaleNotifier.value =
      prefs.getString('appLocale') ?? appLocaleNotifier.value;
  themeModeNotifier.value =
      ThemeMode.values[(prefs.getInt('themeMode') ?? 0).clamp(0, 2)];
  showCancelledNotifier.value =
      prefs.getBool('showCancelled') ?? showCancelledNotifier.value;
  backgroundAnimationsNotifier.value =
      prefs.getBool('backgroundAnimations') ?? backgroundAnimationsNotifier.value;
  backgroundAnimationStyleNotifier.value =
      (prefs.getInt('backgroundAnimationStyle') ?? 0).clamp(0, 10);
  backgroundGyroscopeNotifier.value =
      prefs.getBool('backgroundGyroscope') ?? backgroundGyroscopeNotifier.value;
  blurEnabledNotifier.value =
      prefs.getBool('blurEnabled') ?? blurEnabledNotifier.value;
  progressivePushNotifier.value =
      prefs.getBool('progressivePush') ?? progressivePushNotifier.value;
  dailyBriefingPushNotifier.value =
      prefs.getBool('dailyBriefingPush') ?? dailyBriefingPushNotifier.value;
  importantChangesPushNotifier.value =
      prefs.getBool('importantChangesPush') ?? importantChangesPushNotifier.value;
  demoModeNotifier.value = prefs.getBool('demoMode') ?? demoModeNotifier.value;

  aiProvider = _normalizeAiProvider(
    prefs.getString('aiProvider') ?? aiProvider,
  );
  aiModel = prefs.getString('aiModel') ?? aiModel;
  aiCustomCompatibility = _normalizeAiCustomCompatibility(
    prefs.getString('aiCustomCompatibility') ?? aiCustomCompatibility,
  );
  aiCustomBaseUrl = prefs.getString('aiCustomBaseUrl') ?? aiCustomBaseUrl;
  aiSystemPromptTemplate =
      prefs.getString('aiSystemPromptTemplate') ?? aiSystemPromptTemplate;
  geminiApiKey = prefs.getString('geminiApiKey') ?? geminiApiKey;
  openAiApiKey = prefs.getString('openAiApiKey') ?? openAiApiKey;
  mistralApiKey = prefs.getString('mistralApiKey') ?? mistralApiKey;
  customAiApiKey = prefs.getString('customAiApiKey') ?? customAiApiKey;

  hiddenSubjectsNotifier.value =
      (prefs.getStringList('hiddenSubjects') ?? const <String>[]).toSet();
  try {
    final colorsJson = prefs.getString('subjectColors');
    if (colorsJson != null) {
      final decoded = jsonDecode(colorsJson) as Map<String, dynamic>;
      subjectColorsNotifier.value = decoded.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      );
    }
  } catch (_) {}

  await loadCustomBackgroundsFromPrefs(prefs);
}

class SettingsHubPage extends StatelessWidget {
  const SettingsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    final items = <_SettingsHubItem>[
      _SettingsHubItem(
        icon: Icons.calendar_view_week_rounded,
        iconBackground: cs.primaryContainer,
        iconColor: cs.onPrimaryContainer,
        title: l.settingsSectionTimetable,
        subtitle: l.settingsShowCancelled,
        pageBuilder: () => const SettingsTimetablePage(),
      ),
      _SettingsHubItem(
        icon: Icons.notifications_active_rounded,
        iconBackground: cs.secondaryContainer,
        iconColor: cs.onSecondaryContainer,
        title: l.settingsHubNotifications,
        subtitle: l.settingsProgressivePush,
        pageBuilder: () => const SettingsNotificationsPage(),
      ),
      _SettingsHubItem(
        icon: Icons.palette_outlined,
        iconBackground: cs.tertiaryContainer,
        iconColor: cs.onTertiaryContainer,
        title: l.settingsAppearance,
        subtitle: l.settingsCustomBackgrounds,
        pageBuilder: () => const SettingsAppearancePage(),
      ),
      _SettingsHubItem(
        icon: Icons.auto_awesome_motion_rounded,
        iconBackground: cs.primaryContainer,
        iconColor: cs.onPrimaryContainer,
        title: l.settingsSectionSubjects,
        subtitle: l.settingsSectionColors,
        pageBuilder: () => const SettingsSubjectsPage(),
      ),
      _SettingsHubItem(
        icon: Icons.smart_toy_outlined,
        iconBackground: cs.secondaryContainer,
        iconColor: cs.onSecondaryContainer,
        title: l.settingsSectionAI,
        subtitle: l.aiAskAnything,
        pageBuilder: () => const AiAssistantPage(),
      ),
      _SettingsHubItem(
        icon: Icons.cloud_sync_rounded,
        iconBackground: cs.tertiaryContainer,
        iconColor: cs.onTertiaryContainer,
        title: l.settingsHubDataBackup,
        subtitle: l.settingsHubDataBackupDesc,
        pageBuilder: () => const SettingsBackupPage(),
      ),
      _SettingsHubItem(
        icon: Icons.manage_accounts_outlined,
        iconBackground: cs.primaryContainer,
        iconColor: cs.onPrimaryContainer,
        title: l.settingsHubAccount,
        subtitle: l.settingsDemoMode,
        pageBuilder: () => const SettingsAccountPage(),
      ),
      _SettingsHubItem(
        icon: Icons.system_update_alt_rounded,
        iconBackground: cs.secondaryContainer,
        iconColor: cs.onSecondaryContainer,
        title: l.settingsHubUpdatesAbout,
        subtitle: l.settingsAppVersion,
        pageBuilder: () => const SettingsAboutUpdatesPage(),
      ),
    ];

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 16, 16, mq.padding.bottom + 132),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 240 + index * 40),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 16),
                    child: child,
                  ),
                );
              },
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: cs.surfaceContainerHigh,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      _buildBouncyRoute(item.pageBuilder()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: item.iconBackground,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(item.icon, color: item.iconColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SettingsHubItem {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget Function() pageBuilder;

  const _SettingsHubItem({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.pageBuilder,
  });
}