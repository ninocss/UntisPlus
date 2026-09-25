part of '../main.dart';

const Map<String, String> _settingsLocaleLabels = {
  'de': 'Deutsch',
  'en': 'English',
  'fr': 'Français',
  'es': 'Español',
};

final _appLocalePreference = stringPreference(
  key: 'appLocale',
  defaultValue: 'de',
  notifier: appLocaleNotifier,
);

final _themeModePreference = PreferenceBinding<ThemeMode>(
  key: 'themeMode',
  defaultValue: ThemeMode.system,
  notifier: themeModeNotifier,
  decoder: (raw) =>
      ThemeMode.values[((raw is int ? raw : 0).clamp(
        0,
        ThemeMode.values.length - 1,
      )).toInt()],
  encoder: (value) => ThemeMode.values.indexOf(value),
);

final _visualThemePreference = PreferenceBinding<AppThemeId>(
  key: 'visualTheme',
  defaultValue: AppThemeId.defaultTheme,
  notifier: visualThemeNotifier,
  decoder: (raw) => AppThemeIdX.fromStorage(raw?.toString()),
  encoder: (value) => value.storageKey,
);

final _showCancelledPreference = boolPreference(
  key: 'showCancelled',
  defaultValue: true,
  notifier: showCancelledNotifier,
);
final _timetableSwitchAnimationPreference = intPreference(
  key: 'timetableSwitchAnimation',
  defaultValue: 0,
  notifier: timetableSwitchAnimationNotifier,
  normalize: (value) => value.clamp(0, 2).toInt(),
);
final _backgroundAnimationsPreference = boolPreference(
  key: 'backgroundAnimations',
  defaultValue: true,
  notifier: backgroundAnimationsNotifier,
);
final _backgroundAnimationStylePreference = intPreference(
  key: 'backgroundAnimationStyle',
  defaultValue: 0,
  notifier: backgroundAnimationStyleNotifier,
  normalize: (value) => value.clamp(0, 10).toInt(),
);
final _backgroundGyroscopePreference = boolPreference(
  key: 'backgroundGyroscope',
  defaultValue: false,
  notifier: backgroundGyroscopeNotifier,
);
final _themeBlurPreferencesPreference = PreferenceBinding<Map<String, bool>>(
  key: 'themeBlurPreferences',
  defaultValue: Map<String, bool>.from(themeBlurPreferencesNotifier.value),
  notifier: themeBlurPreferencesNotifier,
  decoder: (raw) => AppThemeIdX.normalizeBlurPreferences(
    raw is String
        ? decodeJsonMap(raw)
        : raw is Map
        ? raw
        : null,
    defaultThemeBlur:
        SettingsStore.instance.preferences.getBool('blurEnabled') ?? true,
  ),
  encoder: (value) => jsonEncode(value),
);
final _blurStrengthPreference = doublePreference(
  key: 'blurStrength',
  defaultValue: 1.0,
  notifier: blurStrengthNotifier,
  normalize: (value) => value.clamp(0.25, 2.0).toDouble(),
);
final _headerStylePreference = intPreference(
  key: 'headerStyle',
  defaultValue: 0,
  notifier: headerStyleNotifier,
  normalize: (value) => value.clamp(0, 2).toInt(),
);
final _surfaceBlurEnabledPreference = boolPreference(
  key: 'surfaceBlurEnabled',
  defaultValue: true,
  notifier: surfaceBlurEnabledNotifier,
);
final _surfaceCornerModePreference = intPreference(
  key: 'surfaceCornerMode',
  defaultValue: 0,
  notifier: surfaceCornerModeNotifier,
  normalize: (value) => value.clamp(0, 2).toInt(),
);
final _surfaceCornerRadiusPreference = intPreference(
  key: 'surfaceCornerRadius',
  defaultValue: 24,
  notifier: surfaceCornerRadiusNotifier,
  normalize: (value) => value.clamp(0, 48).toInt(),
);
final _appBgBlurEnabledPreference = boolPreference(
  key: 'appBgBlurEnabled',
  defaultValue: false,
  notifier: appBgBlurEnabledNotifier,
);
final _appBgBlurAmountPreference = doublePreference(
  key: 'appBgBlurAmount',
  defaultValue: 10.0,
  notifier: appBgBlurAmountNotifier,
);
final _pageTransitionPreference = intPreference(
  key: 'pageTransition',
  defaultValue: 0,
  notifier: pageTransitionNotifier,
  normalize: (value) => value.clamp(0, 8).toInt(),
);
final _mainTabFadeUpPreference = boolPreference(
  key: 'mainTabFadeUpEnabled',
  defaultValue: false,
  notifier: mainTabFadeUpEnabledNotifier,
);
final _useMaterialYouPreference = boolPreference(
  key: 'useMaterialYou',
  defaultValue: true,
  notifier: useMaterialYouNotifier,
);
final _amoledPreference = boolPreference(
  key: 'isAmoled',
  defaultValue: false,
  notifier: isAmoledNotifier,
);
final _customColorSeedPreference = intPreference(
  key: 'customColorSeed',
  defaultValue: 0xFF0F766E,
  notifier: customColorSeedNotifier,
);
final _cancelledLessonColorPreference = intPreference(
  key: 'cancelledLessonColor',
  defaultValue: 0xFFFF1744,
  notifier: cancelledLessonColorNotifier,
);
final _monochromeLessonsPreference = boolPreference(
  key: 'monochromeLessons',
  defaultValue: false,
  notifier: monochromeLessonsNotifier,
);
final _monochromeLessonColorPreference = intPreference(
  key: 'monochromeLessonColor',
  defaultValue: 0xFF757575,
  notifier: monochromeLessonColorNotifier,
);
final _lessonCardStylePreference = intPreference(
  key: 'lessonCardStyle',
  defaultValue: 0,
  notifier: lessonCardStyleNotifier,
  normalize: (value) => value.clamp(0, 4).toInt(),
);
final _glowEffectsPreference = boolPreference(
  key: 'glowEffectsEnabled',
  defaultValue: false,
  notifier: glowEffectsEnabledNotifier,
);
final _lessonBlurEnabledPreference = boolPreference(
  key: 'lessonBlurEnabled',
  defaultValue: false,
  notifier: lessonBlurEnabledNotifier,
);
final _lessonBlurAmountPreference = doublePreference(
  key: 'lessonBlurAmount',
  defaultValue: 12.0,
  notifier: lessonBlurAmountNotifier,
);
final _lessonCardOpacityPreference = doublePreference(
  key: 'lessonCardOpacity',
  defaultValue: 0.9,
  notifier: lessonCardOpacityNotifier,
);
final _lessonBorderRadiusPreference = doublePreference(
  key: 'lessonBorderRadius',
  defaultValue: 12.0,
  notifier: lessonBorderRadiusNotifier,
);
final _lessonAccentStylePreference = intPreference(
  key: 'lessonAccentStyle',
  defaultValue: 0,
  notifier: lessonAccentStyleNotifier,
  normalize: (value) => value.clamp(0, 3).toInt(),
);
final _lessonShowTeacherPreference = boolPreference(
  key: 'lessonShowTeacher',
  defaultValue: true,
  notifier: lessonShowTeacherNotifier,
);
final _lessonFullTeacherNamesPreference = boolPreference(
  key: 'lessonFullTeacherNames',
  defaultValue: false,
  notifier: lessonFullTeacherNamesNotifier,
);
final _lessonShowSubjectIconsPreference = boolPreference(
  key: 'lessonShowSubjectIcons',
  defaultValue: false,
  notifier: lessonShowSubjectIconsNotifier,
);
final _lessonShowRoomPreference = boolPreference(
  key: 'lessonShowRoom',
  defaultValue: true,
  notifier: lessonShowRoomNotifier,
);
final _lessonCompactModePreference = boolPreference(
  key: 'lessonCompactMode',
  defaultValue: false,
  notifier: lessonCompactModeNotifier,
);
final _lessonDimPastPreference = boolPreference(
  key: 'lessonDimPast',
  defaultValue: true,
  notifier: lessonDimPastNotifier,
);
final _lessonCancelledPatternPreference = boolPreference(
  key: 'lessonCancelledPattern',
  defaultValue: true,
  notifier: lessonCancelledPatternNotifier,
);
final _progressivePushPreference = boolPreference(
  key: 'progressivePush',
  defaultValue: true,
  notifier: progressivePushNotifier,
);
final _dailyBriefingPushPreference = boolPreference(
  key: 'dailyBriefingPush',
  defaultValue: true,
  notifier: dailyBriefingPushNotifier,
);
final _importantChangesPushPreference = boolPreference(
  key: 'importantChangesPush',
  defaultValue: true,
  notifier: importantChangesPushNotifier,
);
final _notifyChangeCancellationsPreference = boolPreference(
  key: 'notifyChangeCancellations',
  defaultValue: true,
  notifier: notifyChangeCancellationsNotifier,
);
final _notifyChangeRoomPreference = boolPreference(
  key: 'notifyChangeRoom',
  defaultValue: true,
  notifier: notifyChangeRoomNotifier,
);
final _notifyChangeTeacherPreference = boolPreference(
  key: 'notifyChangeTeacher',
  defaultValue: true,
  notifier: notifyChangeTeacherNotifier,
);
final _notifyChangeOtherPreference = boolPreference(
  key: 'notifyChangeOther',
  defaultValue: true,
  notifier: notifyChangeOtherNotifier,
);
final _demoModePreference = boolPreference(
  key: 'demoMode',
  defaultValue: false,
  notifier: demoModeNotifier,
);

Future<void> _settingsSetLocale(String code) async {
  await ensureDateFormattingForLocale(code);
  await SettingsStore.instance.write(_appLocalePreference, code);
  unawaited(WidgetService.publishNativeCopy(code));
  unawaited(AlarmService.instance.refreshNativeCopy());
}

Future<void> _settingsSetThemeMode(ThemeMode mode) =>
    SettingsStore.instance.write(_themeModePreference, mode);

Future<void> _settingsSetVisualTheme(AppThemeId theme) async {
  final enabled =
      appThemeCapabilities(theme).supportsBlur &&
      (themeBlurPreferencesNotifier.value[theme.storageKey] ?? true);
  visualThemeNotifier.value = theme;
  blurEnabledNotifier.value = enabled;
  unawaited(nativeUiGateway.setWindowBlur(enabled));
  await SettingsStore.instance.write(_visualThemePreference, theme);
}

Future<void> _settingsSetShowCancelled(bool value) =>
    SettingsStore.instance.write(_showCancelledPreference, value);

Future<void> _settingsSetTimetableDaySpan(int value) async {
  final normalized = value.clamp(1, 3).toInt();
  timetableDaySpanNotifier.value = normalized;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('timetableDaySpan', normalized);
}

Future<void> _settingsSetShowFullTeacherNames(bool value) async {
  showFullTeacherNamesNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('showFullTeacherNames', value);
}

/// Builds a standardized [SettingsSwitchTile] for the "show full teacher names" setting.
/// Allows optional icon customization for contextual styling while keeping defaults consistent.
Widget _buildShowFullTeacherNamesTile({
  required AppL10n l,
  required ColorScheme cs,
  IconData? icon,
  Color? iconColor,
  Color? iconBackgroundColor,
}) {
  return ValueListenableBuilder<bool>(
    valueListenable: showFullTeacherNamesNotifier,
    builder: (context, value, _) => SettingsSwitchTile(
      icon: icon ?? Icons.badge_outlined,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      title: l.settingsShowFullTeacherNames,
      subtitle: l.settingsShowFullTeacherNamesDesc,
      value: value,
      onChanged: _settingsSetShowFullTeacherNames,
    ),
  );
}

Future<void> _settingsSetSwipeBackGesture(bool value) async {
  swipeBackGestureNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('swipeBackGesture', value);
}

Future<void> _settingsSetTimetableSwitchAnimation(int value) =>
    SettingsStore.instance.write(_timetableSwitchAnimationPreference, value);

Future<void> _settingsSetBackgroundAnimations(bool value) =>
    SettingsStore.instance.write(_backgroundAnimationsPreference, value);

Future<void> _settingsSetBackgroundAnimationStyle(int value) =>
    SettingsStore.instance.write(_backgroundAnimationStylePreference, value);

Future<void> _settingsSetBackgroundGyroscope(bool value) =>
    SettingsStore.instance.write(_backgroundGyroscopePreference, value);

Future<void> _settingsSetBlurEnabled(bool value) async {
  final theme = visualThemeNotifier.value;
  if (!appThemeCapabilities(theme).supportsBlur) return;
  final updated = Map<String, bool>.from(themeBlurPreferencesNotifier.value)
    ..[theme.storageKey] = value;
  themeBlurPreferencesNotifier.value = updated;
  blurEnabledNotifier.value = value;
  unawaited(nativeUiGateway.setWindowBlur(value));
  await SettingsStore.instance.write(_themeBlurPreferencesPreference, updated);
  await SettingsStore.instance.writeRaw('blurEnabled', value);
}

Future<void> _settingsSetBlurStrength(double value) =>
    SettingsStore.instance.write(_blurStrengthPreference, value);

Future<void> _settingsSetHeaderStyle(int value) =>
    SettingsStore.instance.write(_headerStylePreference, value);

Future<void> _settingsSetSurfaceBlurEnabled(bool value) =>
    SettingsStore.instance.write(_surfaceBlurEnabledPreference, value);

Future<void> _settingsSetSurfaceCornerMode(int value) =>
    SettingsStore.instance.write(_surfaceCornerModePreference, value);

Future<void> _settingsSetSurfaceCornerRadius(double value) =>
    SettingsStore.instance.write(_surfaceCornerRadiusPreference, value.round());

Future<void> _settingsSetAppBgBlurEnabled(bool value) =>
    SettingsStore.instance.write(_appBgBlurEnabledPreference, value);

Future<void> _settingsSetAppBgBlurAmount(double value) =>
    SettingsStore.instance.write(_appBgBlurAmountPreference, value);

Future<void> _settingsSetPageTransition(int value) =>
    SettingsStore.instance.write(_pageTransitionPreference, value);

Future<void> _settingsSetMainTabFadeUpEnabled(bool value) =>
    SettingsStore.instance.write(_mainTabFadeUpPreference, value);

Future<void> _settingsSetUseMaterialYou(bool value) =>
    SettingsStore.instance.write(_useMaterialYouPreference, value);

Future<void> _settingsSetIsAmoled(bool value) =>
    SettingsStore.instance.write(_amoledPreference, value);

Future<void> _settingsSetCustomColorSeed(int value) =>
    SettingsStore.instance.write(_customColorSeedPreference, value);

Future<void> _settingsSetCancelledLessonColor(int value) =>
    SettingsStore.instance.write(_cancelledLessonColorPreference, value);

Future<void> _settingsSetMonochromeLessons(bool value) =>
    SettingsStore.instance.write(_monochromeLessonsPreference, value);

Future<void> _settingsSetMonochromeLessonColor(int value) =>
    SettingsStore.instance.write(_monochromeLessonColorPreference, value);

Future<void> _settingsSetLessonCardStyle(int value) =>
    SettingsStore.instance.write(_lessonCardStylePreference, value);

Future<void> _settingsSetGlowEffectsEnabled(bool value) =>
    SettingsStore.instance.write(_glowEffectsPreference, value);

Future<void> _settingsSetLessonBlurEnabled(bool value) =>
    SettingsStore.instance.write(_lessonBlurEnabledPreference, value);

Future<void> _settingsSetLessonBlurAmount(double value) =>
    SettingsStore.instance.write(_lessonBlurAmountPreference, value);

Future<void> _settingsSetLessonCardOpacity(double value) =>
    SettingsStore.instance.write(_lessonCardOpacityPreference, value);

Future<void> _settingsSetLessonBorderRadius(double value) =>
    SettingsStore.instance.write(_lessonBorderRadiusPreference, value);

Future<void> _settingsSetLessonAccentStyle(int value) =>
    SettingsStore.instance.write(_lessonAccentStylePreference, value);

Future<void> _settingsSetLessonShowTeacher(bool value) =>
    SettingsStore.instance.write(_lessonShowTeacherPreference, value);

Future<void> _settingsSetLessonFullTeacherNames(bool value) =>
    SettingsStore.instance.write(_lessonFullTeacherNamesPreference, value);

Future<void> _settingsSetLessonShowSubjectIcons(bool value) =>
    SettingsStore.instance.write(_lessonShowSubjectIconsPreference, value);

Future<void> _settingsSetLessonShowRoom(bool value) =>
    SettingsStore.instance.write(_lessonShowRoomPreference, value);

Future<void> _settingsSetLessonCompactMode(bool value) =>
    SettingsStore.instance.write(_lessonCompactModePreference, value);

Future<void> _settingsSetLessonDimPast(bool value) =>
    SettingsStore.instance.write(_lessonDimPastPreference, value);

Future<void> _settingsSetLessonCancelledPattern(bool value) =>
    SettingsStore.instance.write(_lessonCancelledPatternPreference, value);

Future<void> _settingsSetProgressivePush(bool value) async {
  await SettingsStore.instance.write(_progressivePushPreference, value);
  if (!value) {
    await NotificationService().cancelNotification(
      NotificationIds.currentLesson,
    );
  } else {
    updateUntisData().catchError((_) => false);
  }
}

Future<void> _settingsSetDailyBriefingPush(bool value) async {
  await SettingsStore.instance.write(_dailyBriefingPushPreference, value);
  if (!value) {
    await NotificationService().cancelNotification(
      NotificationIds.dailyBriefing,
    );
  } else {
    updateUntisData().catchError((_) => false);
  }
}

Future<void> _settingsSetImportantChangesPush(bool value) async {
  await SettingsStore.instance.write(_importantChangesPushPreference, value);
  if (value) {
    updateUntisData().catchError((_) => false);
  } else {
    await NotificationService().cancelNotification(
      NotificationIds.importantChanges,
    );
  }
}

Future<void> _settingsSetNotifyChangeCancellations(bool value) =>
    SettingsStore.instance.write(_notifyChangeCancellationsPreference, value);

Future<void> _settingsSetNotifyChangeRoom(bool value) =>
    SettingsStore.instance.write(_notifyChangeRoomPreference, value);

Future<void> _settingsSetNotifyChangeTeacher(bool value) =>
    SettingsStore.instance.write(_notifyChangeTeacherPreference, value);

Future<void> _settingsSetNotifyChangeOther(bool value) =>
    SettingsStore.instance.write(_notifyChangeOtherPreference, value);

Future<void> _settingsSetDemoMode(BuildContext context, bool enabled) async {
  await SettingsStore.instance.write(_demoModePreference, enabled);
  if (enabled) {
    if (schoolName.isEmpty) schoolName = 'demo.school';
    if (schoolUrl.isEmpty) schoolUrl = 'demo.school';
    if (personType == 0) personType = DemoModeService.demoPersonType;
    if (personId == 0) personId = DemoModeService.demoPersonId;
    await SettingsStore.instance.writeRaw('schoolName', schoolName);
    await SettingsStore.instance.writeRaw('schoolUrl', schoolUrl);
    await SettingsStore.instance.writeRaw('personType', personType);
    await SettingsStore.instance.writeRaw('personId', personId);
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
  final l = appL10nFor(appLocaleNotifier.value);
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
  await SettingsStore.instance.writeRaw('aiProvider', aiProvider);

  final models = _modelsForProvider(
    aiProvider,
    customCompatibility: aiCustomCompatibility,
  );
  if (!models.contains(aiModel)) {
    aiModel = models.first;
    await SettingsStore.instance.writeRaw('aiModel', aiModel);
  }
}

Future<void> _settingsSetAiModel(String model) async {
  aiModel = model;
  await SettingsStore.instance.writeRaw('aiModel', aiModel);
}

Future<void> _settingsSetAiCustomCompatibility(String compatibility) async {
  aiCustomCompatibility = _normalizeAiCustomCompatibility(compatibility);
  await SettingsStore.instance.writeRaw(
    'aiCustomCompatibility',
    aiCustomCompatibility,
  );

  final models = _modelsForProvider(
    aiProvider,
    customCompatibility: aiCustomCompatibility,
  );
  if (!models.contains(aiModel)) {
    aiModel = models.first;
    await SettingsStore.instance.writeRaw('aiModel', aiModel);
  }
}

Future<void> _settingsSetAiCustomBaseUrl(String value) async {
  aiCustomBaseUrl = value;
  await SettingsStore.instance.writeRaw('aiCustomBaseUrl', value);
}

Future<void> _settingsSetAiSystemPromptTemplate(String value) async {
  aiSystemPromptTemplate = value;
  await SettingsStore.instance.writeRaw('aiSystemPromptTemplate', value);
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
  final store = SettingsStore.instance;
  final prefs = store.preferences;

  await store.load(_appLocalePreference);
  await store.load(_themeModePreference);
  final savedVisualTheme = prefs.getString('visualTheme');
  await store.load(_visualThemePreference);
  if (AppThemeIdX.isRemovedStorageKey(savedVisualTheme)) {
    await store.write(_visualThemePreference, AppThemeId.defaultTheme);
  }
  await store.load(_showCancelledPreference);
  await store.load(_timetableSwitchAnimationPreference);
  await store.load(_backgroundAnimationsPreference);
  await store.load(_backgroundAnimationStylePreference);
  await store.load(_backgroundGyroscopePreference);

  final rawThemeBlurs = decodeJsonMap(
    prefs.getString('themeBlurPreferences') ?? '{}',
  );
  await store.load(_themeBlurPreferencesPreference);
  final hadUnsupportedThemeBlur = rawThemeBlurs.keys.any(
    (key) => !AppThemeIdX.isSupportedStorageKey(key),
  );
  if (hadUnsupportedThemeBlur) {
    await store.write(
      _themeBlurPreferencesPreference,
      themeBlurPreferencesNotifier.value,
    );
  }
  final activeTheme = visualThemeNotifier.value;
  blurEnabledNotifier.value =
      appThemeCapabilities(activeTheme).supportsBlur &&
      (themeBlurPreferencesNotifier.value[activeTheme.storageKey] ?? true);
  showFullTeacherNamesNotifier.value =
      prefs.getBool('showFullTeacherNames') ?? true;
  timetableDaySpanNotifier.value = (prefs.getInt('timetableDaySpan') ?? 1)
      .clamp(1, 3)
      .toInt();
  swipeBackGestureNotifier.value =
      prefs.getBool('swipeBackGesture') ??
      (defaultTargetPlatform == TargetPlatform.iOS);

  await store.load(_blurStrengthPreference);
  await store.load(_headerStylePreference);
  await store.load(_surfaceBlurEnabledPreference);
  await store.load(_surfaceCornerModePreference);
  await store.load(_surfaceCornerRadiusPreference);
  await store.load(_appBgBlurEnabledPreference);
  await store.load(_appBgBlurAmountPreference);
  await store.load(_pageTransitionPreference);
  await store.load(_mainTabFadeUpPreference);
  await store.load(_useMaterialYouPreference);
  await store.load(_amoledPreference);
  await store.load(_customColorSeedPreference);
  await store.load(_cancelledLessonColorPreference);
  await store.load(_monochromeLessonsPreference);
  await store.load(_monochromeLessonColorPreference);
  await store.load(_lessonCardStylePreference);
  await store.load(_glowEffectsPreference);
  await store.load(_lessonBlurEnabledPreference);
  await store.load(_lessonBlurAmountPreference);
  await store.load(_lessonCardOpacityPreference);
  await store.load(_lessonBorderRadiusPreference);
  await store.load(_lessonAccentStylePreference);
  await store.load(_lessonShowTeacherPreference);
  await store.load(_lessonFullTeacherNamesPreference);
  await store.load(_lessonShowSubjectIconsPreference);
  await store.load(_lessonShowRoomPreference);
  await store.load(_lessonCompactModePreference);
  await store.load(_lessonDimPastPreference);
  await store.load(_lessonCancelledPatternPreference);
  await store.load(_progressivePushPreference);
  await store.load(_dailyBriefingPushPreference);
  await store.load(_importantChangesPushPreference);
  await store.load(_notifyChangeCancellationsPreference);
  await store.load(_notifyChangeRoomPreference);
  await store.load(_notifyChangeTeacherPreference);
  await store.load(_notifyChangeOtherPreference);
  await store.load(_demoModePreference);

  await loadAiPreferences(prefs);
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
      HapticFeedback.selectionClick();
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

    HapticFeedback.selectionClick();
    Navigator.push(context, _buildBouncyRoute(item.pageBuilder!()));
  }

  Widget _buildHubItem(
    BuildContext context,
    _SettingsHubItem item, {
    required bool expanded,
    required List<_SettingsHubItem> allItems,
    required bool isFirst,
    required bool isLast,
  }) {
    final cs = Theme.of(context).colorScheme;
    final itemIndex = allItems.indexOf(item);
    final selected =
        expanded && item.pageBuilder != null && itemIndex == _selectedDetail;
    final radius = _settingsSegmentRadius(
      context,
      isFirst: isFirst,
      isLast: isLast,
    );

    final tile = Semantics(
      button: true,
      selected: selected,
      label: '${item.title}. ${item.subtitle}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected
              ? cs.secondaryContainer.withValues(alpha: 0.78)
              : cs.surfaceContainerLow.withValues(alpha: 0.82),
          borderRadius: radius,
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.42)
                : cs.outlineVariant.withValues(alpha: 0.30),
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected
                          ? item.iconColor.withValues(alpha: 0.20)
                          : item.iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 21),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 15,
                            color: selected
                                ? cs.onSecondaryContainer
                                : cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w500,
                            fontSize: 12.5,
                            color: selected
                                ? cs.onSecondaryContainer.withValues(
                                    alpha: 0.75,
                                  )
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    item.pageBuilder != null
                        ? (selected
                              ? Icons.check_rounded
                              : Icons.chevron_right_rounded)
                        : Icons.open_in_new_rounded,
                    size: 22,
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
    required List<_SettingsHubItem> items,
    required bool expanded,
    required List<_SettingsHubItem> allItems,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 7),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: cs.primary,
              letterSpacing: 0.15,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _buildHubItem(
                context,
                items[index],
                expanded: expanded,
                allItems: allItems,
                isFirst: index == 0,
                isLast: index == items.length - 1,
              ),
              if (index < items.length - 1) const SizedBox(height: 4),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expanded = UntisLayout.isExpanded(context);

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
    final wrappedItem = makeItem(
      index: 12,
      icon: Icons.auto_awesome_rounded,
      title: l.wrapped('title'),
      subtitle: l.wrapped('settingsDesc'),
      onTap: () => unawaited(openSchoolWrapped(context)),
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
            title: l.alarmTitle,
            subtitle: l.alarmScheduleDesc,
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
      title: l.widgets,
      subtitle: l.widgetAccount,
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
      wrappedItem,
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
      wrappedItem,
    ];

    Widget settingsList({required bool expanded}) {
      final width = MediaQuery.sizeOf(context).width;
      final horizontal = expanded
          ? 18.0
          : width >= UntisLayout.tabletBreakpoint
          ? 24.0
          : 16.0;
      final bottom = mq.padding.bottom + (expanded ? 28 : 118);
      final top = expanded ? 14.0 : mq.padding.top + kToolbarHeight + 14;

      return CustomScrollView(
        key: PageStorageKey<String>(
          expanded ? 'settings-hub-expanded' : 'settings-hub-compact',
        ),
        primary: false,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection(
                  context,
                  title: _sectionTitle(l, 'school'),
                  items: schoolItems,
                  expanded: expanded,
                  allItems: items,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: _sectionTitle(l, 'personalize'),
                  items: personalizeItems,
                  expanded: expanded,
                  allItems: items,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: _sectionTitle(l, 'smart'),
                  items: smartItems,
                  expanded: expanded,
                  allItems: items,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: _sectionTitle(l, 'data'),
                  items: dataItems,
                  expanded: expanded,
                  allItems: items,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: _sectionTitle(l, 'app'),
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
      extendBodyBehindAppBar: !expanded,
      backgroundColor: Colors.transparent,
      appBar: _mainTabHeaderAppBar(context, l.settingsTitle),
      body: _AnimatedBackground(
        child: LayoutBuilder(
          builder: (context, _) {
            if (!expanded) return settingsList(expanded: false);

            final detailIndex = _selectedDetail
                .clamp(0, items.length - 1)
                .toInt();
            final detail =
                items[detailIndex].pageBuilder?.call() ??
                const SettingsTimetablePage();
            final masterWidth = (MediaQuery.sizeOf(context).width * 0.34)
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
  final applied = await nativeUiGateway.setLauncherIcon(icon);
  if (!applied && !kIsWeb) return;
  appIconNotifier.value = icon;
  final prefs = SettingsStore.instance.preferences;
  await prefs.setString('appIcon', icon);
}
