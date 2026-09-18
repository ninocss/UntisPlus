part of '../main.dart';

const Map<String, String> _settingsLocaleLabels = {
  'de': 'Deutsch',
  'en': 'English',
  'fr': 'Français',
  'es': 'Español',
};

Future<void> _settingsSetLocale(String code) async {
  await ensureDateFormattingForLocale(code);
  appLocaleNotifier.value = code;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('appLocale', code);
  unawaited(WidgetService.publishNativeCopy(code));
  unawaited(AlarmService.instance.refreshNativeCopy());
}

Future<void> _settingsSetThemeMode(ThemeMode mode) async {
  themeModeNotifier.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('themeMode', ThemeMode.values.indexOf(mode));
}

Future<void> _settingsSetVisualTheme(AppThemeId theme) async {
  final enabled =
      appThemeCapabilities(theme).supportsBlur &&
      (themeBlurPreferencesNotifier.value[theme.storageKey] ?? true);
  visualThemeNotifier.value = theme;
  // Theme selection is reflected by ValueListenables synchronously. Keep the
  // dependent blur state in the same update so unsupported themes never show
  // a transient blur while preferences are being written.
  blurEnabledNotifier.value = enabled;
  unawaited(_applyAndroidWindowBlur(enabled));
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('visualTheme', theme.storageKey);
}

Future<void> _settingsSetShowCancelled(bool value) async {
  showCancelledNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('showCancelled', value);
}

Future<void> _settingsSetTimetableSwitchAnimation(int value) async {
  final normalized = value.clamp(0, 2);
  timetableSwitchAnimationNotifier.value = normalized;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('timetableSwitchAnimation', normalized);
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
  final theme = visualThemeNotifier.value;
  if (!appThemeCapabilities(theme).supportsBlur) return;
  final updated = Map<String, bool>.from(themeBlurPreferencesNotifier.value)
    ..[theme.storageKey] = value;
  themeBlurPreferencesNotifier.value = updated;
  blurEnabledNotifier.value = value;
  unawaited(_applyAndroidWindowBlur(value));
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('themeBlurPreferences', jsonEncode(updated));
  await prefs.setBool('blurEnabled', value);
}

Future<void> _settingsSetSurfaceBlurEnabled(bool value) async {
  surfaceBlurEnabledNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('surfaceBlurEnabled', value);
}

Future<void> _settingsSetSurfaceCornerMode(int value) async {
  final normalized = value.clamp(0, 2);
  surfaceCornerModeNotifier.value = normalized;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('surfaceCornerMode', normalized);
}

Future<void> _settingsSetSurfaceCornerRadius(double value) async {
  final normalized = value.round().clamp(0, 48);
  surfaceCornerRadiusNotifier.value = normalized;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('surfaceCornerRadius', normalized);
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

Future<void> _settingsSetMainTabFadeUpEnabled(bool value) async {
  mainTabFadeUpEnabledNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('mainTabFadeUpEnabled', value);
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

Future<void> _settingsSetMonochromeLessonColor(int colorValue) async {
  monochromeLessonColorNotifier.value = colorValue;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('monochromeLessonColor', colorValue);
}

Future<void> _settingsSetLessonCardStyle(int style) async {
  final normalized = style.clamp(0, 4);
  lessonCardStyleNotifier.value = normalized;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('lessonCardStyle', normalized);
}

Future<void> _settingsSetGlowEffectsEnabled(bool value) async {
  glowEffectsEnabledNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('glowEffectsEnabled', value);
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

Future<void> _settingsSetLessonShowSubjectIcons(bool value) async {
  lessonShowSubjectIconsNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('lessonShowSubjectIcons', value);
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
    updateUntisData().catchError((_) => false);
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
    updateUntisData().catchError((_) => false);
  }
}

Future<void> _settingsSetImportantChangesPush(bool value) async {
  importantChangesPushNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('importantChangesPush', value);
  if (value) {
    updateUntisData().catchError((_) => false);
  } else {
    await NotificationService().cancelNotification(
      NotificationIds.importantChanges,
    );
  }
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
  await setSecureAiApiKey(aiProvider, key);
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
  final savedVisualTheme = prefs.getString('visualTheme');
  visualThemeNotifier.value = AppThemeIdX.fromStorage(savedVisualTheme);
  if (AppThemeIdX.isRemovedStorageKey(savedVisualTheme)) {
    await prefs.setString('visualTheme', AppThemeId.defaultTheme.storageKey);
  }
  showCancelledNotifier.value =
      prefs.getBool('showCancelled') ?? showCancelledNotifier.value;
  timetableSwitchAnimationNotifier.value =
      (prefs.getInt('timetableSwitchAnimation') ??
              timetableSwitchAnimationNotifier.value)
          .clamp(0, 2);
  backgroundAnimationsNotifier.value =
      prefs.getBool('backgroundAnimations') ??
      backgroundAnimationsNotifier.value;
  backgroundAnimationStyleNotifier.value =
      (prefs.getInt('backgroundAnimationStyle') ?? 0).clamp(0, 10);
  backgroundGyroscopeNotifier.value =
      prefs.getBool('backgroundGyroscope') ?? backgroundGyroscopeNotifier.value;
  Map? rawThemeBlurs;
  try {
    rawThemeBlurs = jsonDecode(prefs.getString('themeBlurPreferences') ?? '{}');
  } catch (_) {}
  final savedThemeBlurs = AppThemeIdX.normalizeBlurPreferences(
    rawThemeBlurs,
    defaultThemeBlur: prefs.getBool('blurEnabled') ?? true,
  );
  themeBlurPreferencesNotifier.value = savedThemeBlurs;
  final hadUnsupportedThemeBlur =
      rawThemeBlurs is Map &&
      rawThemeBlurs.keys.any(
        (key) => key is! String || !AppThemeIdX.isSupportedStorageKey(key),
      );
  if (hadUnsupportedThemeBlur) {
    await prefs.setString('themeBlurPreferences', jsonEncode(savedThemeBlurs));
  }
  final activeTheme = visualThemeNotifier.value;
  blurEnabledNotifier.value =
      appThemeCapabilities(activeTheme).supportsBlur &&
      (themeBlurPreferencesNotifier.value[activeTheme.storageKey] ?? true);
  surfaceBlurEnabledNotifier.value =
      prefs.getBool('surfaceBlurEnabled') ?? true;
  surfaceCornerModeNotifier.value =
      (prefs.getInt('surfaceCornerMode') ?? 0).clamp(0, 2);
  surfaceCornerRadiusNotifier.value =
      (prefs.getInt('surfaceCornerRadius') ?? 24).clamp(0, 48);
  pageTransitionNotifier.value = (prefs.getInt('pageTransition') ?? 0).clamp(
    0,
    7,
  );
  mainTabFadeUpEnabledNotifier.value =
      prefs.getBool('mainTabFadeUpEnabled') ?? false;
  useMaterialYouNotifier.value = prefs.getBool('useMaterialYou') ?? true;
  isAmoledNotifier.value = prefs.getBool('isAmoled') ?? false;
  customColorSeedNotifier.value = prefs.getInt('customColorSeed') ?? 0xFF0F766E;
  lessonCardStyleNotifier.value = (prefs.getInt('lessonCardStyle') ?? 0).clamp(
    0,
    4,
  );
  glowEffectsEnabledNotifier.value =
      prefs.getBool('glowEffectsEnabled') ?? false;
  lessonBlurEnabledNotifier.value = prefs.getBool('lessonBlurEnabled') ?? false;
  lessonBlurAmountNotifier.value = prefs.getDouble('lessonBlurAmount') ?? 12.0;
  lessonCardOpacityNotifier.value = prefs.getDouble('lessonCardOpacity') ?? 0.9;
  lessonBorderRadiusNotifier.value =
      prefs.getDouble('lessonBorderRadius') ?? 12.0;
  lessonAccentStyleNotifier.value = (prefs.getInt('lessonAccentStyle') ?? 0)
      .clamp(0, 3);
  lessonShowTeacherNotifier.value = prefs.getBool('lessonShowTeacher') ?? true;
  lessonShowSubjectIconsNotifier.value =
      prefs.getBool('lessonShowSubjectIcons') ?? false;
  lessonShowRoomNotifier.value = prefs.getBool('lessonShowRoom') ?? true;
  lessonCompactModeNotifier.value = prefs.getBool('lessonCompactMode') ?? false;
  lessonDimPastNotifier.value = prefs.getBool('lessonDimPast') ?? true;
  lessonCancelledPatternNotifier.value =
      prefs.getBool('lessonCancelledPattern') ?? true;
  progressivePushNotifier.value =
      prefs.getBool('progressivePush') ?? progressivePushNotifier.value;
  dailyBriefingPushNotifier.value =
      prefs.getBool('dailyBriefingPush') ?? dailyBriefingPushNotifier.value;
  importantChangesPushNotifier.value =
      prefs.getBool('importantChangesPush') ??
      importantChangesPushNotifier.value;
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
  await loadSecureAiApiKeys(prefs);

  await loadAccountPersonalData();

  defaultClassId = prefs.getInt('defaultClassId');
  defaultClassName = prefs.getString('defaultClassName');
  favoriteClassIds = (prefs.getStringList('favoriteClassIds') ?? [])
      .map((idStr) => int.tryParse(idStr))
      .whereType<int>()
      .toSet();

  await loadCustomBackgroundsFromPrefs(prefs);
}

class SettingsHubPage extends StatefulWidget {
  const SettingsHubPage({super.key});

  @override
  State<SettingsHubPage> createState() => _SettingsHubPageState();
}

class _SettingsHubPageState extends State<SettingsHubPage> {
  int _selectedDetail = 0;

  Widget _buildGroupCard(
    ColorScheme cs,
    BuildContext context,
    List<_SettingsHubItem> groupItems, {
    required bool expanded,
    required List<_SettingsHubItem> allItems,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          _expressiveRadius(context, 22, expressiveRadius: 28),
        ),
      ),
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
                  if (item.onTap != null) {
                    item.onTap!();
                  } else if (item.pageBuilder != null) {
                    if (expanded) {
                      setState(() => _selectedDetail = allItems.indexOf(item));
                    } else {
                      Navigator.push(
                        context,
                        _buildBouncyRoute(item.pageBuilder!()),
                      );
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
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
                      if (item.pageBuilder != null)
                        Icon(
                          expanded && allItems.indexOf(item) == _selectedDetail
                              ? Icons.check_circle_rounded
                              : Icons.chevron_right_rounded,
                          color:
                              expanded &&
                                  allItems.indexOf(item) == _selectedDetail
                              ? cs.primary
                              : cs.onSurfaceVariant,
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getAccent(int index) {
      switch (index) {
        case 0:
          return cs.primary;
        case 1:
          return cs.error;
        case 2:
          return cs.tertiary;
        case 3:
          return cs.secondary;
        case 4:
          return cs.surfaceTint;
        case 5:
          return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
        case 6:
          return isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
        case 7:
          return isDark ? const Color(0xFFF472B6) : const Color(0xFFDB2777);
        case 8:
        default:
          return isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
      }
    }

    _SettingsHubItem makeItem({
      required int index,
      required IconData icon,
      required String title,
      required String subtitle,
      Widget Function()? pageBuilder,
      VoidCallback? onTap,
    }) {
      final accent = getAccent(index);
      final bgAlpha = isDark ? 0.22 : 0.14;
      final iconColor = isDark
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.18), accent)
          : accent;

      return _SettingsHubItem(
        icon: icon,
        iconBackground: accent.withValues(alpha: bgAlpha),
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        pageBuilder: pageBuilder,
        onTap: onTap,
      );
    }

    final timetableItem = makeItem(
      index: 0,
      icon: Icons.calendar_view_week_rounded,
      title: l.settingsSectionTimetable,
      subtitle: l.settingsShowCancelled,
      pageBuilder: () => const SettingsTimetablePage(),
    );
    final notificationsItem = makeItem(
      index: 1,
      icon: Icons.notifications_active_rounded,
      title: l.settingsHubNotifications,
      subtitle: l.settingsProgressivePush,
      pageBuilder: () => const SettingsNotificationsPage(),
    );
    final appearanceItem = makeItem(
      index: 2,
      icon: Icons.palette_rounded,
      title: l.settingsAppearance,
      subtitle: l.settingsCustomBackgrounds,
      pageBuilder: () => const SettingsAppearancePage(),
    );
    final subjectsItem = makeItem(
      index: 3,
      icon: Icons.color_lens_rounded,
      title: l.settingsSectionSubjects,
      subtitle: l.settingsSectionColors,
      pageBuilder: () => const SettingsSubjectsPage(),
    );
    final aiItem = makeItem(
      index: 4,
      icon: Icons.auto_awesome_rounded,
      title: l.settingsSectionAI,
      subtitle: l.settingsAiProvider,
      pageBuilder: () => const SettingsAiPage(),
    );
    final backupItem = makeItem(
      index: 5,
      icon: Icons.cloud_sync_rounded,
      title: l.settingsHubDataBackup,
      subtitle: l.settingsHubDataBackupDesc,
      pageBuilder: () => const SettingsBackupPage(),
    );
    final accountItem = makeItem(
      index: 6,
      icon: Icons.manage_accounts_rounded,
      title: l.settingsHubAccount,
      subtitle: l.settingsDemoMode,
      pageBuilder: () => const SettingsAccountPage(),
    );
    final widgetsItem = makeItem(
      index: 7,
      icon: Icons.widgets_rounded,
      title: l.ui('widgets'),
      subtitle: l.ui('widgetAccount'),
      pageBuilder: () => const SettingsWidgetsPage(),
    );
    final alarmItem = !kIsWeb && Platform.isAndroid
        ? makeItem(
            index: 8,
            icon: Icons.alarm_rounded,
            title: l.ui('alarmTitle'),
            subtitle: l.ui('alarmScheduleDesc'),
            pageBuilder: () => const SettingsAlarmPage(),
          )
        : null;
    final updatesItem = kIsWeb || !Platform.isIOS
        ? makeItem(
            index: 9,
            icon: Icons.system_update_alt_rounded,
            title: l.settingsHubUpdatesAbout,
            subtitle: l.settingsAppVersion,
            pageBuilder: () => const SettingsAboutUpdatesPage(),
          )
        : null;
    final supportItem = makeItem(
      index: 10,
      icon: Icons.coffee_rounded,
      title: l.settingsSupport,
      subtitle: l.settingsSupportDesc,
      onTap: () {
        url_launcher.launchUrlString(
          'https://ko-fi.com/nino161er',
          mode: url_launcher.LaunchMode.externalApplication,
        );
      },
    );
    final reportItem = makeItem(
      index: 11,
      icon: Icons.bug_report_rounded,
      title: l.settingsReportIssue,
      subtitle: l.settingsReportIssueDesc,
      onTap: () {
        url_launcher.launchUrlString(
          'https://github.com/ninocss/UntisPlus/issues',
          mode: url_launcher.LaunchMode.externalApplication,
        );
      },
    );

    final items = <_SettingsHubItem>[
      timetableItem,
      notificationsItem,
      appearanceItem,
      subjectsItem,
      aiItem,
      backupItem,
      accountItem,
      widgetsItem,
      ?alarmItem,
      ?updatesItem,
      supportItem,
      reportItem,
    ];

    Widget settingsList({required bool expanded}) => ListView(
      padding: UntisLayout.pagePadding(
        context,
        bottom: mq.padding.bottom + (expanded ? 28 : 132),
      ),
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0, end: 1),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 16),
              child: child,
            ),
          ),
          child: _buildGroupCard(
            cs,
            context,
            [
              timetableItem,
              subjectsItem,
              appearanceItem,
              ?alarmItem,
            ],
            expanded: expanded,
            allItems: items,
          ),
        ),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: 0, end: 1),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 16),
              child: child,
            ),
          ),
          child: _buildGroupCard(
            cs,
            context,
            [notificationsItem, aiItem, accountItem, widgetsItem],
            expanded: expanded,
            allItems: items,
          ),
        ),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0, end: 1),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 16),
              child: child,
            ),
          ),
          child: _buildGroupCard(
            cs,
            context,
            [
              backupItem,
              ?updatesItem,
              supportItem,
              reportItem,
            ],
            expanded: expanded,
            allItems: items,
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: LayoutBuilder(
          builder: (context, _) {
            final expanded = UntisLayout.isExpanded(context);
            if (!expanded) return settingsList(expanded: false);
            final detailIndex = _selectedDetail
                .clamp(0, items.length - 1)
                .toInt();
            final detail =
                items[detailIndex].pageBuilder?.call() ??
                const SettingsTimetablePage();
            return Row(
              key: const ValueKey('settings-master-detail'),
              children: [
                SizedBox(width: 360, child: settingsList(expanded: true)),
                VerticalDivider(
                  width: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.45),
                ),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey('settings-detail-$detailIndex'),
                    child: detail,
                  ),
                ),
              ],
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
  final Widget Function()? pageBuilder;
  final VoidCallback? onTap;

  const _SettingsHubItem({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.pageBuilder,
    this.onTap,
  });
}

Future<void> _settingsSetAppIcon(String icon) async {
  const supported = {
    'default',
    '3d',
    'chrom',
    'galaxy',
    'gradiant',
    'marmor',
    'paper',
  };
  if (!supported.contains(icon)) return;
  final applied = await _applyLauncherIcon(icon);
  if (!applied && !kIsWeb) return;
  appIconNotifier.value = icon;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('appIcon', icon);
}
