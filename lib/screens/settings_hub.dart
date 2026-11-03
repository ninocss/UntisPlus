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
final _lessonCleanDesignPreference = boolPreference(
  key: 'lessonCleanDesign',
  defaultValue: false,
  notifier: lessonCleanDesignNotifier,
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
final _devModePreference = boolPreference(
  key: 'devMode',
  defaultValue: false,
  notifier: devModeNotifier,
);
final _devServerUrlPreference = stringPreference(
  key: 'devServerUrl',
  defaultValue: kDefaultDevServerUrl,
  notifier: devServerUrlNotifier,
  normalize: normalizeDevServerUrl,
);
final _devUseHttpsPreference = boolPreference(
  key: 'devUseHttps',
  defaultValue: false,
  notifier: devUseHttpsNotifier,
);
final _devServerSchoolNamePreference = stringPreference(
  key: 'devServerSchoolName',
  defaultValue: '',
  notifier: devServerSchoolNameNotifier,
);
final _devServerUsernamePreference = stringPreference(
  key: 'devServerUsername',
  defaultValue: '',
  notifier: devServerUsernameNotifier,
);
final _devServerPasswordPreference = stringPreference(
  key: 'devServerPassword',
  defaultValue: '',
  notifier: devServerPasswordNotifier,
);
final _devModeNotificationStylePreference =
    enumPreference<DevModeNotificationStyle>(
      key: 'devModeNotificationStyle',
      defaultValue: DevModeNotificationStyle.popup,
      notifier: devModeNotificationStyleNotifier,
      values: DevModeNotificationStyle.values,
    );
final _showFullTeacherNamesPreference = boolPreference(
  key: 'showFullTeacherNames',
  defaultValue: true,
  notifier: showFullTeacherNamesNotifier,
);
final _timetableDaySpanPreference = intPreference(
  key: 'timetableDaySpan',
  defaultValue: 1,
  notifier: timetableDaySpanNotifier,
  normalize: (value) => value.clamp(1, 3).toInt(),
);
final _swipeBackGesturePreference = boolPreference(
  key: 'swipeBackGesture',
  defaultValue: defaultTargetPlatform == TargetPlatform.iOS,
  notifier: swipeBackGestureNotifier,
);

/// Developer mode and demo mode never run at the same time: demo mode answers
/// from local sample data, so the development server would never be reached.
/// Enabling either one therefore turns the other off.
/// Dev mode CAN run alongside a real school account — the dev server simply
/// takes precedence when reachable.
Future<void> _settingsSetDevMode(bool value) async {
  if (value) demoModeNotifier.value = false;
  await SettingsStore.instance.write(_devModePreference, value);
  if (value) await SettingsStore.instance.write(_demoModePreference, false);
}

/// Validates and stores the development-server address, reporting whether the
/// input was accepted so the caller can show feedback.
///
/// Anything the user types in is reduced to a bare `host[:port]`; the input is
/// only rejected when what remains is not something that can be connected to,
/// i.e. it has no host part or a host that contains whitespace.
Future<bool> _settingsSetDevServerUrl(String value) async {
  final normalized = normalizeDevServerUrl(value);
  final host = normalized.split(':').first;
  if (host.isEmpty || host.contains(RegExp(r'\s'))) return false;
  await SettingsStore.instance.write(_devServerUrlPreference, normalized);
  return true;
}

Future<void> _settingsSetDevUseHttps(bool value) =>
    SettingsStore.instance.write(_devUseHttpsPreference, value);

Future<void> _settingsSetDevServerSchoolName(String value) =>
    SettingsStore.instance.write(_devServerSchoolNamePreference, value);

Future<void> _settingsSetDevServerUsername(String value) =>
    SettingsStore.instance.write(_devServerUsernamePreference, value);

Future<void> _settingsSetDevServerPassword(String value) =>
    SettingsStore.instance.write(_devServerPasswordPreference, value);

Future<void> _settingsSetDevModeNotificationStyle(
  DevModeNotificationStyle value,
) => SettingsStore.instance.write(_devModeNotificationStylePreference, value);

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
  await SettingsStore.instance.writeRaw('timetableDaySpan', normalized);
}

Future<void> _settingsSetShowFullTeacherNames(bool value) async {
  showFullTeacherNamesNotifier.value = value;
  await SettingsStore.instance.writeRaw('showFullTeacherNames', value);
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
  await SettingsStore.instance.writeRaw('swipeBackGesture', value);
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

Future<void> _settingsSetLessonCleanDesign(bool value) =>
    SettingsStore.instance.write(_lessonCleanDesignPreference, value);

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
  // Demo mode serves local sample data and performs no requests, so it cannot
  // coexist with developer mode. See [_settingsSetDevMode].
  if (enabled) await SettingsStore.instance.write(_devModePreference, false);
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
  await store.load(_lessonCleanDesignPreference);
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
  await store.load(_devModePreference);
  await store.load(_devServerUrlPreference);
  await store.load(_devUseHttpsPreference);
  await store.load(_showFullTeacherNamesPreference);
  await store.load(_timetableDaySpanPreference);
  await store.load(_swipeBackGesturePreference);

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _hubLabel(AppL10n l, String key) {
    const labels = <String, Map<String, String>>{
      'de': {
        'teaching': 'Unterricht & Alltag',
        'design': 'Design & System',
        'ai': 'KI & Smarte Features',
        'data_support': 'Daten, App & Support',
        'search_hint': 'Einstellungen durchsuchen…',
        'search_empty': 'Keine passenden Einstellungen gefunden',
        'feedback_report': 'Feedback & Problem melden',
      },
      'en': {
        'teaching': 'Classes & daily life',
        'design': 'Design & system',
        'ai': 'AI & smart features',
        'data_support': 'Data, app & support',
        'search_hint': 'Search settings…',
        'search_empty': 'No matching settings found',
        'feedback_report': 'Feedback & report issue',
      },
      'fr': {
        'teaching': 'Cours & quotidien',
        'design': 'Design & système',
        'ai': 'IA & fonctions intelligentes',
        'data_support': 'Données, app & support',
        'search_hint': 'Rechercher dans les paramètres…',
        'search_empty': 'Aucun paramètre correspondant',
        'feedback_report': 'Avis & signaler un problème',
      },
      'es': {
        'teaching': 'Clases y día a día',
        'design': 'Diseño y sistema',
        'ai': 'IA y funciones inteligentes',
        'data_support': 'Datos, app y soporte',
        'search_hint': 'Buscar ajustes…',
        'search_empty': 'No se encontraron ajustes',
        'feedback_report': 'Comentarios y reportar problema',
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
      AppHaptics.selection();
      item.onTap!();
      return;
    }
    if (item.pageBuilder == null) return;

    if (expanded) {
      final index = allItems.indexOf(item);
      if (index >= 0 && index != _selectedDetail) {
        AppHaptics.selection();
        setState(() => _selectedDetail = index);
      }
      return;
    }

    AppHaptics.selection();
    Navigator.push(context, _buildBouncyRoute(item.pageBuilder!()));
  }

  Future<void> _showFeedbackAndIssueSheet(BuildContext context, AppL10n l) async {
    final choice = await _showUnifiedOptionSheet<String>(
      context: context,
      title: _hubLabel(l, 'feedback_report'),
      subtitle: l.settingsGiveFeedbackDesc,
      options: [
        _SheetOption(
          value: 'feedback',
          title: l.settingsGiveFeedback,
          subtitle: l.settingsGiveFeedbackDesc,
          icon: Icons.feedback_rounded,
        ),
        _SheetOption(
          value: 'issue',
          title: l.settingsReportIssue,
          subtitle: l.settingsReportIssueDesc,
          icon: Icons.bug_report_rounded,
        ),
      ],
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'issue') {
      await url_launcher.launchUrlString(
        'https://github.com/ninocss/UntisPlus/issues',
        mode: url_launcher.LaunchMode.externalApplication,
      );
      return;
    }
    if (!WishKit.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.settingsFeedbackNotConfigured),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: l.settingsOpenGitHub,
            onPressed: () => url_launcher.launchUrlString(
              'https://github.com/ninocss/UntisPlus/issues',
              mode: url_launcher.LaunchMode.externalApplication,
            ),
          ),
        ),
      );
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => WishKit.feedbackPage()));
  }

  Widget _buildCompactAccountHeader(
    BuildContext context, {
    required AppL10n l,
    required _SettingsHubItem accountItem,
    required bool expanded,
    required List<_SettingsHubItem> allItems,
  }) {
    final cs = Theme.of(context).colorScheme;
    final accountIndex = allItems.indexOf(accountItem);
    final selected = expanded && accountIndex == _selectedDetail;

    return AnimatedBuilder(
      animation: Listenable.merge([
        untisAccountsNotifier,
        demoModeNotifier,
        devModeNotifier,
      ]),
      builder: (context, _) {
        final prefs = SettingsStore.instance.preferences;
        final accounts = untisAccountsNotifier.value;
        UntisAccount? activeAccount;
        for (final acc in accounts) {
          if (acc.id == activeUntisAccountId) {
            activeAccount = acc;
            break;
          }
        }
        final rawUser =
            activeAccount?.username ?? (prefs.getString('username') ?? '');
        final rawSchool =
            activeAccount?.schoolName.isNotEmpty == true
                ? activeAccount!.schoolName
                : (schoolName.isNotEmpty
                      ? schoolName
                      : (prefs.getString('schoolName') ?? ''));
        final isDemo = demoModeNotifier.value;
        final isDev = devModeNotifier.value;

        final displayUser = rawUser.trim().isNotEmpty
            ? rawUser.trim()
            : (isDemo ? l.settingsDemoMode : l.settingsHubAccount);
        final displaySchool = rawSchool.trim().isNotEmpty
            ? rawSchool.trim()
            : (isDemo ? 'demo.school' : l.settingsDemoMode);

        final initials = rawUser.trim().isNotEmpty
            ? rawUser
                  .trim()
                  .split(RegExp(r'[\s._-]+'))
                  .where((part) => part.isNotEmpty)
                  .take(2)
                  .map((part) => part[0].toUpperCase())
                  .join()
            : '';

        return Semantics(
          button: true,
          selected: selected,
          label: '${l.settingsHubAccount}: $displayUser, $displaySchool',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: const ValueKey('settings-compact-account-header'),
              borderRadius: BorderRadius.circular(16),
              onTap: () => _activateItem(
                context,
                accountItem,
                expanded: expanded,
                allItems: allItems,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary
                            : cs.primaryContainer.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: initials.isNotEmpty
                          ? Text(
                              initials,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: selected
                                    ? cs.onPrimary
                                    : cs.onPrimaryContainer,
                              ),
                            )
                          : Icon(
                              isDemo
                                  ? Icons.science_rounded
                                  : Icons.person_rounded,
                              size: 20,
                              color: selected
                                  ? cs.onPrimary
                                  : cs.onPrimaryContainer,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayUser,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: cs.onSurface,
                                  ),
                                ),
                                if (isDemo || isDev) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDev
                                          ? cs.tertiaryContainer
                                          : cs.secondaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isDev ? 'DEV' : 'DEMO',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 0.4,
                                        color: isDev
                                            ? cs.onTertiaryContainer
                                            : cs.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            displaySchool,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              fontSize: 12.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.secondaryContainer
                            : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.settingsHubAccount,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: selected
                                  ? cs.onSecondaryContainer
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            selected
                                ? Icons.check_rounded
                                : Icons.chevron_right_rounded,
                            size: 16,
                            color: selected ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, AppL10n l) {
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    final radius = BorderRadius.circular(
      _resolvedSurfaceCornerRadius(tokens.surfaceRadius).clamp(16.0, 24.0),
    );

    return ThemedSurface(
      borderRadius: radius,
      border: Border.all(
        color: tokens.id == AppThemeId.manga
            ? cs.outline
            : cs.outlineVariant.withValues(alpha: 0.32),
        width: tokens.borderWidth,
      ),
      respectSurfaceCornerPreference: false,
      showShadow: false,
      child: TextField(
        key: const ValueKey('settings-search-field'),
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textAlignVertical: TextAlignVertical.center,
        style: GoogleFonts.outfit(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          fillColor: Colors.transparent,
          hintText: _hubLabel(l, 'search_hint'),
          hintStyle: GoogleFonts.outfit(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
          ),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: cs.primary),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
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

    final tile = Semantics(
      button: true,
      selected: selected,
      label: '${item.title}. ${item.subtitle}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: selected
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: selected
              ? cs.secondaryContainer.withValues(alpha: 0.76)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _activateItem(
            context,
            item,
            expanded: expanded,
            allItems: allItems,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 10 : 14,
              vertical: 10,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? item.iconColor.withValues(alpha: 0.22)
                        : item.iconBackground,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 20),
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
                              ? cs.onSecondaryContainer.withValues(alpha: 0.78)
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
                  size: 21,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ],
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
    if (items.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: tokens.id == AppThemeId.manga ? 20 : 13,
              color: cs.primary,
              letterSpacing: tokens.id == AppThemeId.cyber ? 1.1 : 0.25,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: Listenable.merge([
            surfaceCornerModeNotifier,
            surfaceCornerRadiusNotifier,
          ]),
          builder: (context, _) {
            final groupRadius = BorderRadius.circular(
              _resolvedSurfaceCornerRadius(tokens.surfaceRadius),
            );
            return ThemedSurface(
              borderRadius: groupRadius,
              border: Border.all(
                color: tokens.id == AppThemeId.manga
                    ? cs.outline
                    : cs.outlineVariant.withValues(alpha: 0.30),
                width: tokens.borderWidth,
              ),
              respectSurfaceCornerPreference: false,
              showShadow: false,
              child: Material(
                type: MaterialType.transparency,
                borderRadius: groupRadius,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _buildHubItem(
                        context,
                        items[index],
                        expanded: expanded,
                        allItems: allItems,
                      ),
                      if (index < items.length - 1)
                        Divider(
                          height: 1,
                          thickness: 0.7,
                          indent: 68,
                          endIndent: 16,
                          color: cs.outlineVariant.withValues(alpha: 0.26),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _matchesQuery(_SettingsHubItem item, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final terms = normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    final haystack =
        '${item.title} ${item.subtitle} ${item.searchKeywords}'.toLowerCase();
    return terms.every(haystack.contains);
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expanded = UntisLayout.isExpanded(context);

    _SettingsHubItem makeItem({
      required Color semanticColor,
      required IconData icon,
      required String title,
      required String subtitle,
      String searchKeywords = '',
      Widget Function()? pageBuilder,
      VoidCallback? onTap,
    }) {
      final harmonized = Color.alphaBlend(
        cs.primary.withValues(alpha: 0.22),
        semanticColor,
      );
      final iconColor = isDark
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.22), harmonized)
          : harmonized;
      return _SettingsHubItem(
        icon: icon,
        iconBackground: harmonized.withValues(alpha: isDark ? 0.22 : 0.14),
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        searchKeywords: searchKeywords,
        pageBuilder: pageBuilder,
        onTap: onTap,
      );
    }

    final timetableItem = makeItem(
      semanticColor: cs.primary,
      icon: Icons.calendar_view_week_rounded,
      title: l.settingsSectionTimetable,
      subtitle: l.settingsShowCancelled,
      searchKeywords:
          'stundenplan timetable raster woche tag ausfall lehrer animation karten design',
      pageBuilder: () => const SettingsTimetablePage(),
    );
    final subjectsItem = makeItem(
      semanticColor: const Color(0xFF00897B),
      icon: Icons.school_rounded,
      title: l.settingsSectionSubjects,
      subtitle: l.settingsSectionColors,
      searchKeywords: 'fächer subjects farben colors icons verstecken kürzel',
      pageBuilder: () => const SettingsSubjectsPage(),
    );
    final wrappedItem = makeItem(
      semanticColor: const Color(0xFFD81B60),
      icon: Icons.insights_rounded,
      title: l.wrapped('title'),
      subtitle: l.wrapped('settingsDesc'),
      searchKeywords: 'wrapped rückblick statistik jahresrückblick analyse',
      pageBuilder: () => const SchoolWrappedHub(),
    );
    final appearanceItem = makeItem(
      semanticColor: const Color(0xFF7E57C2),
      icon: Icons.palette_rounded,
      title: l.settingsAppearance,
      subtitle: l.settingsCustomBackgrounds,
      searchKeywords:
          'darstellung erscheinungsbild design theme dark mode amoled blur hintergrund icon sprache language material you',
      pageBuilder: () => const SettingsAppearancePage(),
    );
    final widgetsItem = makeItem(
      semanticColor: const Color(0xFF3949AB),
      icon: Icons.widgets_rounded,
      title: l.widgets,
      subtitle: l.widgetAccount,
      searchKeywords: 'widgets homescreen startbildschirm editor',
      pageBuilder: () => const SettingsWidgetsPage(),
    );
    final notificationsItem = makeItem(
      semanticColor: const Color(0xFFF57C00),
      icon: Icons.notifications_active_rounded,
      title: l.settingsHubNotifications,
      subtitle: l.settingsProgressivePush,
      searchKeywords:
          'benachrichtigungen push notifications briefing vertretung raumwechsel',
      pageBuilder: () => const SettingsNotificationsPage(),
    );
    final alarmItem = !kIsWeb && Platform.isAndroid
        ? makeItem(
            semanticColor: const Color(0xFFE64A19),
            icon: Icons.alarm_rounded,
            title: l.alarmTitle,
            subtitle: l.alarmScheduleDesc,
            searchKeywords: 'wecker alarm aufstehen klingeln',
            pageBuilder: () => const SettingsAlarmPage(),
          )
        : null;
    final aiItem = makeItem(
      semanticColor: const Color(0xFF8E24AA),
      icon: Icons.auto_awesome_rounded,
      title: l.settingsSectionAI,
      subtitle: l.settingsAiProvider,
      searchKeywords:
          'ki ai gemini openai mistral api key modell prompt assistent lokal',
      pageBuilder: () => const SettingsAiPage(),
    );
    final accountItem = makeItem(
      semanticColor: cs.primary,
      icon: Icons.manage_accounts_rounded,
      title: l.settingsHubAccount,
      subtitle: l.settingsDemoMode,
      searchKeywords:
          'konto account schule login abmelden wechseln demo entwickler dev server',
      pageBuilder: () => const SettingsAccountPage(),
    );
    final backupItem = makeItem(
      semanticColor: const Color(0xFF1E88E5),
      icon: Icons.cloud_sync_rounded,
      title: l.settingsHubDataBackup,
      subtitle: l.settingsHubDataBackupDesc,
      searchKeywords: 'backup daten export import sichern wiederherstellen',
      pageBuilder: () => const SettingsBackupPage(),
    );
    final updatesItem = kIsWeb || !Platform.isIOS
        ? makeItem(
            semanticColor: const Color(0xFF2E7D32),
            icon: Icons.system_update_alt_rounded,
            title: l.settingsHubUpdatesAbout,
            subtitle: l.settingsAppVersion,
            searchKeywords: 'updates version über about changelog github lizenz',
            pageBuilder: () => const SettingsAboutUpdatesPage(),
          )
        : null;
    final feedbackReportItem = makeItem(
      semanticColor: const Color(0xFF00ACC1),
      icon: Icons.rate_review_rounded,
      title: _hubLabel(l, 'feedback_report'),
      subtitle: l.settingsGiveFeedbackDesc,
      searchKeywords: 'feedback bug fehler problem melden ideen github wishkit',
      onTap: () => _showFeedbackAndIssueSheet(context, l),
    );
    final supportItem = makeItem(
      semanticColor: const Color(0xFFEC407A),
      icon: Icons.volunteer_activism_rounded,
      title: l.settingsSupport,
      subtitle: l.settingsSupportDesc,
      searchKeywords: 'support unterstützen spenden kofi',
      onTap: () {
        url_launcher.launchUrlString(
          'https://ko-fi.com/nino161er',
          mode: url_launcher.LaunchMode.externalApplication,
        );
      },
    );

    final teachingItems = <_SettingsHubItem>[
      timetableItem,
      subjectsItem,
      wrappedItem,
    ].where((item) => _matchesQuery(item, _searchQuery)).toList();

    final designItems = <_SettingsHubItem>[
      appearanceItem,
      widgetsItem,
      notificationsItem,
      ?alarmItem,
    ].where((item) => _matchesQuery(item, _searchQuery)).toList();

    final aiItems = <_SettingsHubItem>[
      aiItem,
    ].where((item) => _matchesQuery(item, _searchQuery)).toList();

    final dataSupportItems = <_SettingsHubItem>[
      if (_searchQuery.trim().isNotEmpty &&
          _matchesQuery(accountItem, _searchQuery))
        accountItem,
      backupItem,
      ?updatesItem,
      feedbackReportItem,
      supportItem,
    ].where((item) => _matchesQuery(item, _searchQuery)).toList();

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
      feedbackReportItem,
      wrappedItem,
    ];

    final hasAnySearchMatch =
        teachingItems.isNotEmpty ||
        designItems.isNotEmpty ||
        aiItems.isNotEmpty ||
        dataSupportItems.isNotEmpty;

    Widget settingsList({required bool expanded}) {
      final width = MediaQuery.sizeOf(context).width;
      final horizontal = expanded
          ? 18.0
          : width >= UntisLayout.tabletBreakpoint
          ? 24.0
          : 16.0;
      final bottom = mq.padding.bottom + (expanded ? 28 : 118);
      final top = mq.padding.top + kToolbarHeight + 10;

      final sections = <Widget>[];
      void addSection(String key, List<_SettingsHubItem> sectionItems) {
        if (sectionItems.isEmpty) return;
        if (sections.isNotEmpty) sections.add(const SizedBox(height: 16));
        sections.add(
          _buildSection(
            context,
            title: _hubLabel(l, key),
            items: sectionItems,
            expanded: expanded,
            allItems: items,
          ),
        );
      }

      addSection('teaching', teachingItems);
      addSection('design', designItems);
      addSection('ai', aiItems);
      addSection('data_support', dataSupportItems);

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
                _buildCompactAccountHeader(
                  context,
                  l: l,
                  accountItem: accountItem,
                  expanded: expanded,
                  allItems: items,
                ),
                const SizedBox(height: 10),
                _buildSearchBar(context, l),
                const SizedBox(height: 14),
                if (hasAnySearchMatch)
                  ...sections
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 36,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _hubLabel(l, 'search_empty'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ]),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: _mainTabHeaderAppBar(context, l.settingsTitle),
      body: LayoutBuilder(
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
              SizedBox(width: masterWidth, child: settingsList(expanded: true)),
              VerticalDivider(
                width: 1,
                color: cs.outlineVariant.withValues(alpha: 0.45),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey('settings-detail-$detailIndex'),
                    child: SafeArea(bottom: false, child: detail),
                  ),
                ),
              ),
            ],
          );
        },
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
  final String searchKeywords;
  final Widget Function()? pageBuilder;
  final VoidCallback? onTap;

  const _SettingsHubItem({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.searchKeywords = '',
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
