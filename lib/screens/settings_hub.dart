part of '../main.dart';

const Map<String, String> _settingsLocaleLabels = {
  'de': 'Deutsch',
  'en': 'English',
  'fr': 'Français',
  'es': 'Español',
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

Future<void> _settingsSetAppBgBlurEnabled(bool value) async {
  appBgBlurEnabledNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('appBgBlurEnabled', value);
}

Future<void> _settingsSetAppBgBlurAmount(double value) async {
  appBgBlurAmountNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('appBgBlurAmount', value);
}

Future<void> _settingsSetPageTransition(int value) async {
  final normalized = value.clamp(0, 7);
  pageTransitionNotifier.value = normalized;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('pageTransition', normalized);
}

Future<void> _settingsSetUseMaterialYou(bool value) async {
  useMaterialYouNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('useMaterialYou', value);
}

Future<void> _settingsSetIsAmoled(bool value) async {
  isAmoledNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isAmoled', value);
}

Future<void> _settingsSetCustomColorSeed(int value) async {
  customColorSeedNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('customColorSeed', value);
}

Future<void> _settingsSetCancelledLessonColor(int colorValue) async {
  cancelledLessonColorNotifier.value = colorValue;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('cancelledLessonColor', colorValue);
}

Future<void> _settingsSetMonochromeLessons(bool value) async {
  monochromeLessonsNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('monochromeLessons', value);
}

Future<void> _settingsSetLessonCardStyle(int style) async {
  final normalized = style.clamp(0, 4);
  lessonCardStyleNotifier.value = normalized;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('lessonCardStyle', normalized);
}

Future<void> _settingsSetLessonGlowEnabled(bool value) async {
  lessonGlowEnabledNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('lessonGlowEnabled', value);
}

Future<void> _settingsSetLessonGlowMode(int mode) async {
  final normalized = mode.clamp(0, 1);
  lessonGlowModeNotifier.value = normalized;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('lessonGlowMode', normalized);
}

Future<void> _settingsSetLessonGlowIntensity(double value) async {
  lessonGlowIntensityNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('lessonGlowIntensity', value);
}

Future<void> _settingsSetLessonBlurEnabled(bool value) async {
  lessonBlurEnabledNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('lessonBlurEnabled', value);
}

Future<void> _settingsSetLessonBlurAmount(double value) async {
  lessonBlurAmountNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('lessonBlurAmount', value);
}

Future<void> _settingsSetLessonCardOpacity(double value) async {
  lessonCardOpacityNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('lessonCardOpacity', value);
}

Future<void> _settingsSetLessonBorderRadius(double value) async {
  lessonBorderRadiusNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('lessonBorderRadius', value);
}

Future<void> _settingsSetLessonAccentStyle(int style) async {
  final normalized = style.clamp(0, 3);
  lessonAccentStyleNotifier.value = normalized;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('lessonAccentStyle', normalized);
}

Future<void> _settingsSetLessonShowTeacher(bool value) async {
  lessonShowTeacherNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('lessonShowTeacher', value);
}

Future<void> _settingsSetLessonShowRoom(bool value) async {
  lessonShowRoomNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('lessonShowRoom', value);
}

Future<void> _settingsSetLessonCompactMode(bool value) async {
  lessonCompactModeNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('lessonCompactMode', value);
}

Future<void> _settingsSetLessonDimPast(bool value) async {
  lessonDimPastNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('lessonDimPast', value);
}

Future<void> _settingsSetLessonCancelledPattern(bool value) async {
  lessonCancelledPatternNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('lessonCancelledPattern', value);
}

Future<void> _settingsSetProgressivePush(bool value) async {
  progressivePushNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('progressivePush', value);
  if (!value) {
    await NotificationService().cancelNotification(
      NotificationIds.currentLesson,
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
      NotificationIds.dailyBriefing,
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
  defaultClassId = null;
  defaultClassName = null;
  favoriteClassIds = {};
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
  pageTransitionNotifier.value =
      (prefs.getInt('pageTransition') ?? 0).clamp(0, 7);
  useMaterialYouNotifier.value =
      prefs.getBool('useMaterialYou') ?? true;
  isAmoledNotifier.value =
      prefs.getBool('isAmoled') ?? false;
  customColorSeedNotifier.value =
      prefs.getInt('customColorSeed') ?? 0xFF0F766E;
  lessonCardStyleNotifier.value =
      (prefs.getInt('lessonCardStyle') ?? 0).clamp(0, 4);
  lessonGlowEnabledNotifier.value =
      prefs.getBool('lessonGlowEnabled') ?? true;
  lessonGlowModeNotifier.value =
      (prefs.getInt('lessonGlowMode') ?? 0).clamp(0, 1);
  lessonGlowIntensityNotifier.value =
      prefs.getDouble('lessonGlowIntensity') ?? 1.0;
  lessonBlurEnabledNotifier.value =
      prefs.getBool('lessonBlurEnabled') ?? false;
  lessonBlurAmountNotifier.value =
      prefs.getDouble('lessonBlurAmount') ?? 12.0;
  lessonCardOpacityNotifier.value =
      prefs.getDouble('lessonCardOpacity') ?? 0.9;
  lessonBorderRadiusNotifier.value =
      prefs.getDouble('lessonBorderRadius') ?? 12.0;
  lessonAccentStyleNotifier.value =
      (prefs.getInt('lessonAccentStyle') ?? 0).clamp(0, 3);
  lessonShowTeacherNotifier.value =
      prefs.getBool('lessonShowTeacher') ?? true;
  lessonShowRoomNotifier.value =
      prefs.getBool('lessonShowRoom') ?? true;
  lessonCompactModeNotifier.value =
      prefs.getBool('lessonCompactMode') ?? false;
  lessonDimPastNotifier.value =
      prefs.getBool('lessonDimPast') ?? true;
  lessonCancelledPatternNotifier.value =
      prefs.getBool('lessonCancelledPattern') ?? true;
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
  
  defaultClassId = prefs.getInt('defaultClassId');
  defaultClassName = prefs.getString('defaultClassName');
  favoriteClassIds = (prefs.getStringList('favoriteClassIds') ?? [])
      .map((idStr) => int.tryParse(idStr))
      .whereType<int>()
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

  await loadCustomBackgroundsFromPrefs(prefs);
}

class SettingsHubPage extends StatelessWidget {
  const SettingsHubPage({super.key});

  Widget _buildGroupCard(ColorScheme cs, BuildContext context, List<_SettingsHubItem> groupItems) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: groupItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == groupItems.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(context, _buildBouncyRoute(item.pageBuilder()));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: item.iconBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 22),
                      ),
                      const SizedBox(width: 14),
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
                                fontSize: 15.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: cs.onSurfaceVariant,
                                fontSize: 12.5,
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
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 70,
                  endIndent: 16,
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

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
        subtitle: l.settingsAiProvider,
        pageBuilder: () => const SettingsAiPage(),
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
      if (!Platform.isIOS)
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
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, mq.padding.bottom + 132),
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
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
              child: _buildGroupCard(cs, context, [items[0], items[3], items[2]]),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
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
              child: _buildGroupCard(cs, context, [items[1], items[4], items[6]]),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
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
              child: _buildGroupCard(cs, context, [items[5], items[7]]),
            ),
          ],
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