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

  String _sectionTitle(AppL10n l, String key) {
    const labels = <String, Map<String, String>>{
      'de': {
        'school': 'Schule & Stundenplan',
        'personalize': 'Darstellung & Widgets',
        'smart': 'KI & Automatisierung',
        'data': 'Account & Daten',
        'app': 'App & Support',
      },
      'en': {
        'school': 'School & timetable',
        'personalize': 'Appearance & widgets',
        'smart': 'AI & automation',
        'data': 'Account & data',
        'app': 'App & support',
      },
      'fr': {
        'school': 'École & emploi du temps',
        'personalize': 'Apparence & widgets',
        'smart': 'IA & automatisation',
        'data': 'Compte & données',
        'app': 'App & assistance',
      },
      'es': {
        'school': 'Escuela y horario',
        'personalize': 'Apariencia y widgets',
        'smart': 'IA y automatización',
        'data': 'Cuenta y datos',
        'app': 'App y soporte',
      },
    };
    return (labels[l.locale] ?? labels['en']!)[key] ?? key;
  }

  void _activateItem(
    BuildContext context,
    _SettingsHubItem item, {
    required bool expanded,
    required List<_SettingsHubItem> allItems,
  }) {
    if (item.onTap != null) {
      item.onTap!();
      return;
    }
    if (item.pageBuilder == null) return;

    if (expanded) {
      final index = allItems.indexOf(item);
      if (index >= 0 && index != _selectedDetail) {
        HapticFeedback.selectionClick();
        setState(() => _selectedDetail = index);
      }
      return;
    }

    Navigator.push(context, _buildBouncyRoute(item.pageBuilder!()));
  }

  Widget _buildHubItem(
    BuildContext context,
    _SettingsHubItem item, {
    required bool expanded,
    required List<_SettingsHubItem> allItems,
  }) {
    final cs = Theme.of(context).colorScheme;
    final itemIndex = allItems.indexOf(item);
    final selected =
        expanded && item.pageBuilder != null && itemIndex == _selectedDetail;
    final radius = BorderRadius.circular(
      _expressiveRadius(context, 18, expressiveRadius: 24),
    );

    final tile = Semantics(
      button: true,
      selected: selected,
      label: '${item.title}. ${item.subtitle}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? cs.secondaryContainer.withValues(alpha: 0.72)
              : Colors.transparent,
          borderRadius: radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _activateItem(
              context,
              item,
              expanded: expanded,
              allItems: allItems,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected
                          ? item.iconColor.withValues(alpha: 0.22)
                          : item.iconBackground,
                      borderRadius: BorderRadius.circular(
                        selected
                            ? _expressiveRadius(
                                context,
                                15,
                                expressiveRadius: 19,
                              )
                            : _expressiveRadius(
                                context,
                                14,
                                expressiveRadius: 16,
                              ),
                      ),
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 23),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                        fontSize: 15.5,
                        color: selected
                            ? cs.onSecondaryContainer
                            : cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    item.pageBuilder != null
                        ? (selected
                              ? Icons.check_circle_rounded
                              : Icons.chevron_right_rounded)
                        : Icons.open_in_new_rounded,
                    size: selected ? 22 : 21,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Tooltip(
      message: item.subtitle,
      triggerMode: TooltipTriggerMode.longPress,
      showDuration: const Duration(seconds: 4),
      preferBelow: false,
      verticalOffset: 30,
      child: tile,
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color accent,
    required List<_SettingsHubItem> items,
    required bool expanded,
    required List<_SettingsHubItem> allItems,
  }) {
    final cs = Theme.of(context).colorScheme;
    final sectionRadius = BorderRadius.circular(
      _expressiveRadius(context, 24, expressiveRadius: 32),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 9),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.15,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        ThemedSurface(
          borderRadius: sectionRadius,
          color: cs.surfaceContainerLow.withValues(alpha: 0.72),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in items)
                  _buildHubItem(
                    context,
                    item,
                    expanded: expanded,
                    allItems: allItems,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getAccent(int index) {
      return switch (index % 6) {
        0 => cs.primary,
        1 => cs.tertiary,
        2 => cs.secondary,
        3 => cs.error,
        4 => cs.inversePrimary,
        _ => isDark ? cs.onTertiaryContainer : cs.tertiary,
      };
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
      final iconColor = isDark
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.12), accent)
          : accent;
      return _SettingsHubItem(
        icon: icon,
        iconBackground: accent.withValues(alpha: isDark ? 0.20 : 0.12),
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
    final subjectsItem = makeItem(
      index: 1,
      icon: Icons.school_rounded,
      title: l.settingsSectionSubjects,
      subtitle: l.settingsSectionColors,
      pageBuilder: () => const SettingsSubjectsPage(),
    );
    final notificationsItem = makeItem(
      index: 2,
      icon: Icons.notifications_active_rounded,
      title: l.settingsHubNotifications,
      subtitle: l.settingsProgressivePush,
      pageBuilder: () => const SettingsNotificationsPage(),
    );
    final alarmItem = !kIsWeb && Platform.isAndroid
        ? makeItem(
            index: 3,
            icon: Icons.alarm_rounded,
            title: l.ui('alarmTitle'),
            subtitle: l.ui('alarmScheduleDesc'),
            pageBuilder: () => const SettingsAlarmPage(),
          )
        : null;
    final appearanceItem = makeItem(
      index: 4,
      icon: Icons.palette_rounded,
      title: l.settingsAppearance,
      subtitle: l.settingsCustomBackgrounds,
      pageBuilder: () => const SettingsAppearancePage(),
    );
    final widgetsItem = makeItem(
      index: 5,
      icon: Icons.widgets_rounded,
      title: l.ui('widgets'),
      subtitle: l.ui('widgetAccount'),
      pageBuilder: () => const SettingsWidgetsPage(),
    );
    final aiItem = makeItem(
      index: 6,
      icon: Icons.auto_awesome_rounded,
      title: l.settingsSectionAI,
      subtitle: l.settingsAiProvider,
      pageBuilder: () => const SettingsAiPage(),
    );
    final accountItem = makeItem(
      index: 7,
      icon: Icons.manage_accounts_rounded,
      title: l.settingsHubAccount,
      subtitle: l.settingsDemoMode,
      pageBuilder: () => const SettingsAccountPage(),
    );
    final backupItem = makeItem(
      index: 8,
      icon: Icons.cloud_sync_rounded,
      title: l.settingsHubDataBackup,
      subtitle: l.settingsHubDataBackupDesc,
      pageBuilder: () => const SettingsBackupPage(),
    );
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
      icon: Icons.volunteer_activism_rounded,
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

    final schoolItems = <_SettingsHubItem>[
      timetableItem,
      subjectsItem,
      notificationsItem,
      ?alarmItem,
    ];
    final personalizeItems = <_SettingsHubItem>[appearanceItem, widgetsItem];
    final smartItems = <_SettingsHubItem>[aiItem];
    final dataItems = <_SettingsHubItem>[accountItem, backupItem];
    final appItems = <_SettingsHubItem>[
      ?updatesItem,
      supportItem,
      reportItem,
    ];
    // Keep the internal detail indices stable for existing tablet navigation
    // and widget tests. Visual grouping is independent from this order.
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

    Widget settingsList({required bool expanded}) {
      final width = MediaQuery.sizeOf(context).width;
      final horizontal = expanded
          ? 18.0
          : width >= UntisLayout.tabletBreakpoint
          ? 24.0
          : 16.0;
      final bottom = mq.padding.bottom + (expanded ? 28 : 118);

      return CustomScrollView(
        key: PageStorageKey<String>(
          expanded ? 'settings-hub-expanded' : 'settings-hub-compact',
        ),
        primary: !expanded,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, bottom),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection(
                  context,
                  title: _sectionTitle(l, 'school'),
                  icon: Icons.school_rounded,
                  accent: cs.primary,
                  items: schoolItems,
                  expanded: expanded,
                  allItems: items,
                ),
                const SizedBox(height: 20),
                _buildSection(
                  context,
                  title: _sectionTitle(l, 'personalize'),
                  icon: Icons.brush_rounded,
                  accent: cs.tertiary,
                  items: personalizeItems,
                  expanded: expanded,
                  allItems: items,
                ),
                const SizedBox(height: 20),
                _buildSection(
                  context,
                  title: _sectionTitle(l, 'smart'),
                  icon: Icons.auto_awesome_rounded,
                  accent: cs.secondary,
                  items: smartItems,
                  expanded: expanded,
                  allItems: items,
                ),
                const SizedBox(height: 20),
                _buildSection(
                  context,
                  title: _sectionTitle(l, 'data'),
                  icon: Icons.folder_shared_rounded,
                  accent: cs.primary,
                  items: dataItems,
                  expanded: expanded,
                  allItems: items,
                ),
                const SizedBox(height: 20),
                _buildSection(
                  context,
                  title: _sectionTitle(l, 'app'),
                  icon: Icons.info_rounded,
                  accent: cs.tertiary,
                  items: appItems,
                  expanded: expanded,
                  allItems: items,
                ),
              ]),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 22, color: cs.primary),
            const SizedBox(width: 9),
            Text(
              l.settingsTitle,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        centerTitle: false,
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
            final masterWidth =
                (MediaQuery.sizeOf(context).width * 0.34)
                    .clamp(350.0, 420.0)
                    .toDouble();

            return Row(
              key: const ValueKey('settings-master-detail'),
              children: [
                SizedBox(
                  width: masterWidth,
                  child: settingsList(expanded: true),
                ),
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