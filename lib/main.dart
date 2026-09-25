import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/physics.dart';
import 'package:url_launcher/url_launcher_string.dart' as url_launcher;
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cryptography/dart.dart';
import 'package:dio/dio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'l10n.dart';
import 'core/time_utils.dart';
import 'core/settings_store.dart';
import 'core/defensive_parsers.dart';
import 'core/timetable_date_utils.dart';
import 'core/version_utils.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/alarm_service.dart';
import 'services/backup_service.dart';
import 'services/demo_mode_service.dart';
import 'services/homework_service.dart';
import 'services/webuntis_message_service.dart';
import 'services/widget_service.dart';
import 'core/app_providers.dart';
import 'data/cache/offline_cache_store.dart';
import 'data/security/credential_vault.dart';
import 'data/webuntis/webuntis_client.dart';
import 'data/webuntis/webuntis_session_manager.dart';
import 'features/changes/data/change_repository.dart';
import 'features/changes/domain/timetable_change.dart';
import 'features/exams/data/webuntis_exam_repository.dart';
import 'features/timetable/data/timetable_repository.dart';
import 'features/timetable/data/teacher_search_index_service.dart';
import 'features/timetable/domain/teacher_schedule.dart';
import 'features/wrapped/school_wrapped.dart';
import 'features/updates/data/github_release_repository.dart';
import 'features/updates/data/changelog_repository.dart';
import 'features/school_info/data/school_info_repository.dart';
import 'features/school_info/application/school_html.dart';
import 'features/absences/data/absence_repository.dart';
import 'features/absences/domain/absence.dart';
import 'features/homework/domain/homework.dart';
import 'features/timetable/domain/timetable_lesson_status.dart';
import 'features/ai/domain/ai_models.dart';
import 'features/ai/application/ai_request_coordinator.dart';
import 'features/ai/data/ai_chat_history_store.dart';
import 'features/ai/data/ai_response_parser.dart';
import 'features/ai/data/local_model_provider.dart';
import 'features/ai/data/remote_ai_provider.dart';
import 'features/accounts/domain/untis_account.dart';
import 'features/accounts/data/untis_account_store.dart';
import 'features/accounts/data/school_directory_repository.dart';
import 'features/accounts/data/webuntis_login_repository.dart';
import 'platform/native_ui_gateway.dart';
import 'core/sync_state.dart';
import 'core/school_models.dart';
import 'core/design_tokens.dart';

export 'features/accounts/domain/untis_account.dart';
export 'core/school_models.dart';
export 'core/design_tokens.dart';
export 'features/updates/data/github_release_repository.dart';

part 'core/app_theme.dart';
part 'app/untis_plus_app.dart';
part 'core/shared_ui.dart';
part 'core/app_state.dart';
part 'core/custom_backgrounds.dart';
part 'screens/onboarding_flow.dart';
part 'screens/weekly_timetable_page.dart';
part 'screens/teacher_search_page.dart';
part 'screens/homework_page.dart';
part 'screens/exams_page.dart';
part 'screens/custom_background_editor_screen.dart';
part 'screens/main_navigation_screen.dart';
part 'screens/ai/ai_ui_tokens.dart';
part 'features/ai/application/ai_prompt_helpers.dart';
part 'screens/ai/widgets/ai_suggestion_card.dart';
part 'screens/ai/widgets/ai_attachment_chip.dart';
part 'screens/ai/widgets/ai_composer.dart';
part 'screens/ai/widgets/ai_typing_indicator.dart';
part 'screens/ai/widgets/ai_chat_message.dart';
part 'screens/ai/widgets/ai_metric_tile.dart';
part 'screens/ai/widgets/ai_analysis_loading_state.dart';
part 'screens/ai/widgets/ai_analysis_result.dart';
part 'screens/ai/widgets/ai_chat_history_panel.dart';
part 'screens/ai/widgets/ai_action_confirmation.dart';
part 'screens/student_more_page.dart';
part 'screens/grades_tracker_page.dart';
part 'screens/school_wrapped_page.dart';
part 'screens/settings_hub.dart';
part 'screens/settings/settings_timetable_page.dart';
part 'screens/settings/settings_notifications_page.dart';
part 'screens/settings/settings_alarm_page.dart';
part 'screens/settings/settings_appearance_page.dart';
part 'screens/settings/settings_subjects_page.dart';
part 'screens/settings/subject_management_pages.dart';
part 'screens/settings/settings_ai_page.dart';
part 'screens/settings/settings_backup_page.dart';
part 'screens/settings/settings_widgets_page.dart';
part 'screens/settings/custom_widget_editor_page.dart';
part 'screens/settings/settings_account_page.dart';
part 'screens/settings/settings_about_updates_page.dart';
part 'screens/school_notification_detail_page.dart';
part 'screens/school_notifications_page.dart';
part 'screens/lesson_detail.dart';
part 'screens/message_compose_page.dart';
part 'widgets/animated_background.dart';
part 'widgets/expressive_refresh_indicator.dart';
part 'widgets/custom_background_view.dart';
part 'widgets/changelog_bottom_sheet.dart';
part 'widgets/rounded_blur_app_bar.dart';
part 'services/local_model_download.dart';

int _toMinutes(int t) => (t ~/ 100) * 60 + (t % 100);

final WebUntisExamRepository _webUntisExamRepository = WebUntisExamRepository();
final TimetableRepository _timetableRepository = TimetableRepository();

/// WebUntis installations represent an absent teacher differently. Prefer
/// explicit flags, but also support the status text used by older servers.
bool _hasMissingTeacher(dynamic lesson) {
  if (lesson is! Map) return false;
  for (final key in const [
    'teacherMissing',
    'teacherAbsent',
    'isTeacherMissing',
    '_teacherMissing',
  ]) {
    if (lesson[key] == true) return true;
  }
  final code = lesson['code']?.toString().toLowerCase() ?? '';
  if (code == 'teacher_missing' ||
      code == 'teacherabsent' ||
      code == 'teacher_absent') {
    return true;
  }
  final teachers = lesson['te'];
  if (teachers is List &&
      teachers.any((teacher) {
        if (teacher is! Map) return false;
        return teacher['missing'] == true ||
            teacher['absent'] == true ||
            teacher['status']?.toString().toLowerCase() == 'missing';
      })) {
    return true;
  }
  final info = '${lesson['info'] ?? ''} ${lesson['substText'] ?? ''}'
      .toLowerCase();
  return RegExp(
    r'(teacher|lehrer).{0,24}(missing|absent|fehlt|fehlend)',
  ).hasMatch(info);
}

/// Invoked by the native exact pre-wake alarm. It deliberately reuses the
/// existing authenticated WebUntis sync, then tells Android the final plan.
@pragma('vm:entry-point')
void alarmRefreshDispatcher() async {
  WidgetsFlutterBinding.ensureInitialized();
  var refreshed = false;
  try {
    refreshed = await updateUntisData();
  } catch (_) {
    // The native scheduler retains the last confirmed alarm on a failed sync.
  } finally {
    await alarmRefreshGateway.completed(refreshed: refreshed);
  }
}

/// Factory to create AI provider instances.
AiGenerationSettings _currentAiGenerationSettings() {
  final l = appL10nFor(appLocaleNotifier.value);
  return AiGenerationSettings(
    temperature: aiTemperature,
    maxTokens: aiMaxTokens,
    topP: aiTopP,
    formatAttachmentText: (attachment) =>
        l.aiAttachmentText(attachment.name, attachment.textExcerpt),
    formatUnsupportedAttachment: (attachment) =>
        l.aiAttachmentUnsupported(attachment.name, attachment.mimeType),
  );
}

LocalModelRuntime _currentLocalModelRuntime({AiGenerationSettings? settings}) {
  final l = appL10nFor(appLocaleNotifier.value);
  return LocalModelRuntime(
    settings: settings ?? _currentAiGenerationSettings(),
    isValidModel: (path) =>
        _isValidLocalModelFile(path, model: _localModelForPath(path)),
    loadErrorMessage: l.aiLocalModelLoadError,
    noReplyMessage: l.aiNoReply,
  );
}

AIProvider createAIProvider(
  AiProviderConfiguration configuration, {
  AiGenerationSettings? generationSettings,
}) {
  final settings = generationSettings ?? _currentAiGenerationSettings();
  switch (configuration.provider) {
    case 'gemini':
      return GeminiProvider(apiKey: configuration.apiKey, settings: settings);
    case 'openai':
      return OpenAICompatibleProvider(
        apiKey: configuration.apiKey,
        settings: settings,
        endpoint: 'https://api.openai.com/v1/chat/completions',
      );
    case 'mistral':
      return OpenAICompatibleProvider(
        apiKey: configuration.apiKey,
        settings: settings,
        endpoint: 'https://api.mistral.ai/v1/chat/completions',
      );
    case 'custom':
      final compat = _normalizeAiCustomCompatibility(
        configuration.customCompatibility,
      );
      if (compat == 'gemini') {
        return GeminiProvider(
          apiKey: configuration.apiKey,
          settings: settings,
          endpoint: geminiStreamingEndpoint(
            configuration.customBaseUrl,
            configuration.model,
          ),
        );
      }
      return OpenAICompatibleProvider(
        apiKey: configuration.apiKey,
        settings: settings,
        endpoint: openAiCompatibleEndpoint(configuration.customBaseUrl),
        baseUrl: configuration.customBaseUrl,
      );
    case 'local':
      if (configuration.localModelPath.isEmpty) {
        throw Exception('Local model path not configured');
      }
      return LocalModelProvider(
        modelPath: configuration.localModelPath,
        runtime: _currentLocalModelRuntime(settings: settings),
      );
    default:
      return GeminiProvider(apiKey: configuration.apiKey, settings: settings);
  }
}

final AiRequestCoordinator _aiRequestCoordinator = AiRequestCoordinator(
  isEnabled: () => aiEnabledNotifier.value,
);

AiRuntimeConfiguration _currentAiRuntimeConfiguration() =>
    AiRuntimeConfiguration(
      provider: aiProvider,
      apiKey: _activeAiApiKey(),
      customBaseUrl: aiCustomBaseUrl,
      customCompatibility: aiCustomCompatibility,
      model: aiModel,
      localModelPath: aiLocalModelPath,
      generationSettings: _currentAiGenerationSettings(),
      providerFactory: (configuration, settings) =>
          createAIProvider(configuration, generationSettings: settings),
      defaultModelResolver: (provider, compatibility) =>
          _defaultModelForProvider(
            provider,
            customCompatibility: compatibility,
          ),
    );

Future<void> _initializeDeferredNativeServices() async {
  if (kIsWeb) return;
  await NotificationService().init();
  BackgroundService.initialize();
  if (Platform.isAndroid || Platform.isIOS) {
    await AlarmService.instance.restore();
  }
  // Refresh the persistent "current lesson" notification immediately from the
  // offline cache on launch (no network required) and schedule the next one-off
  // boundary refresh so the notification can never be more than ~1 minute stale.
  try {
    await refreshProgressiveNotificationFromCache();
  } catch (_) {
    // Non-fatal: the periodic background sync will recover.
  }
}

Future<void> _initializeDeferredAccountData() async {
  final accountId = activeUntisAccountId;
  if (accountId == null) return;
  final changes = await ChangeRepository().loadChanges(accountId);
  unreadTimetableChangesNotifier.value = changes
      .where((change) => !change.isRead)
      .length;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(OfflineCacheStore.instance.preWarm());
  nativeUiGateway.registerAssistantOpenHandler((prompt) {
    pendingAssistantPromptNotifier.value = prompt;
    pendingAssistantOpenNotifier.value = true;
  });

  final settingsStore = await SettingsStore.initialize();
  final prefs = settingsStore.preferences;
  appLocaleNotifier.value = prefs.getString('appLocale') ?? 'de';
  await ensureDateFormattingForLocale(appLocaleNotifier.value);
  unawaited(WidgetService.publishNativeCopy(appLocaleNotifier.value));
  final packageInfo = await PackageInfo.fromPlatform();
  appVersion = packageInfo.version;
  appBuildNumber = packageInfo.buildNumber;
  final previousAppVersion = prefs.getString('installedAppVersion');
  if (previousAppVersion == null || previousAppVersion != appVersion) {
    await prefs.setBool('showChangelogPending', true);
  }
  await prefs.setString('installedAppVersion', appVersion);
  showChangelogOnStartup = prefs.getBool('showChangelogPending') ?? false;
  aiEnabledNotifier.value = prefs.getBool('aiEnabled') ?? true;
  demoModeNotifier.value = prefs.getBool('demoMode') ?? false;
  // Demo mode is an explicit temporary choice; do not silently replace it
  // with the last saved account during startup.
  if (!demoModeNotifier.value) {
    await initializeUntisAccounts(prefs);
  } else {
    untisAccountsNotifier.value = List.unmodifiable(_readUntisAccounts(prefs));
  }
  final bool isLoggedIn =
      activeUntisAccountId != null &&
      untisAccountsNotifier.value.any(
        (account) =>
            account.id == activeUntisAccountId &&
            (account.sessionId.isNotEmpty || account.password.isNotEmpty),
      );
  final legacyOnboardingCompleted =
      prefs.getBool('onboardingCompleted') ?? false;
  final legacyTutorialCompleted = prefs.getBool('tutorialCompleted') ?? false;
  var onboardingVersion = prefs.getInt('onboardingVersion') ?? 0;
  var tutorialVersionCompleted = prefs.getInt('tutorialVersionCompleted') ?? 0;

  // Existing installations must never be forced through a redesigned setup.
  // The legacy flags are promoted once; genuinely new/incomplete installs keep
  // version 0 and use the new resumable flow.
  final looksLikeConfiguredLegacyInstall =
      (isLoggedIn || demoModeNotifier.value) &&
      !prefs.containsKey('onboardingCheckpoint');
  if ((legacyOnboardingCompleted || looksLikeConfiguredLegacyInstall) &&
      onboardingVersion == 0) {
    onboardingVersion = kCurrentOnboardingVersion;
    await prefs.setInt('onboardingVersion', onboardingVersion);
    if (tutorialVersionCompleted == 0) {
      tutorialVersionCompleted = kCurrentTutorialVersion;
      await prefs.setInt('tutorialVersionCompleted', tutorialVersionCompleted);
    }
  }
  final onboardingCompleted =
      legacyOnboardingCompleted || onboardingVersion > 0;
  final tutorialCompleted =
      legacyTutorialCompleted ||
      tutorialVersionCompleted >= kCurrentTutorialVersion;

  // Account initialization has already hydrated the active session from the
  // native secure store. SharedPreferences now contains public metadata only.
  defaultClassId = prefs.getInt('defaultClassId');
  defaultClassName = prefs.getString('defaultClassName');
  favoriteClassIds = (prefs.getStringList('favoriteClassIds') ?? [])
      .map((idStr) => int.tryParse(idStr))
      .whereType<int>()
      .toSet();

  const supportedAppIcons = {
    'default',
    '3d',
    'chrom',
    'galaxy',
    'gradiant',
    'marmor',
    'paper',
  };
  final savedAppIcon = prefs.getString('appIcon') ?? 'default';
  appIconNotifier.value = supportedAppIcons.contains(savedAppIcon)
      ? savedAppIcon
      : 'default';
  themeModeNotifier.value = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
  final savedVisualTheme = prefs.getString('visualTheme');
  visualThemeNotifier.value = AppThemeIdX.fromStorage(savedVisualTheme);
  if (AppThemeIdX.isRemovedStorageKey(savedVisualTheme)) {
    await prefs.setString('visualTheme', AppThemeId.defaultTheme.storageKey);
  }
  showCancelledNotifier.value = prefs.getBool('showCancelled') ?? true;
  timetableSwitchAnimationNotifier.value =
      (prefs.getInt('timetableSwitchAnimation') ?? 0).clamp(0, 2);
  cancelledLessonColorNotifier.value =
      prefs.getInt('cancelledLessonColor') ?? 0xFFFF1744;
  monochromeLessonsNotifier.value = prefs.getBool('monochromeLessons') ?? false;
  monochromeLessonColorNotifier.value =
      prefs.getInt('monochromeLessonColor') ?? 0xFF757575;
  backgroundAnimationsNotifier.value =
      prefs.getBool('backgroundAnimations') ?? true;
  backgroundAnimationStyleNotifier.value =
      (prefs.getInt('backgroundAnimationStyle') ?? 0).clamp(0, 10);
  backgroundGyroscopeNotifier.value =
      prefs.getBool('backgroundGyroscope') ?? false;
  Map? rawThemeBlurs;
  try {
    rawThemeBlurs = jsonDecode(prefs.getString('themeBlurPreferences') ?? '{}');
  } catch (_) {}
  final themeBlurPreferences = AppThemeIdX.normalizeBlurPreferences(
    rawThemeBlurs,
    defaultThemeBlur: prefs.getBool('blurEnabled') ?? true,
  );
  final hadUnsupportedThemeBlur =
      rawThemeBlurs is Map &&
      rawThemeBlurs.keys.any(
        (key) => key is! String || !AppThemeIdX.isSupportedStorageKey(key),
      );
  if (hadUnsupportedThemeBlur) {
    await prefs.setString(
      'themeBlurPreferences',
      jsonEncode(themeBlurPreferences),
    );
  }
  themeBlurPreferencesNotifier.value = themeBlurPreferences;
  final activeVisualTheme = visualThemeNotifier.value;
  blurEnabledNotifier.value =
      appThemeCapabilities(activeVisualTheme).supportsBlur &&
      (themeBlurPreferences[activeVisualTheme.storageKey] ?? true);
  headerStyleNotifier.value = (prefs.getInt('headerStyle') ?? 0).clamp(0, 2);
  surfaceBlurEnabledNotifier.value =
      prefs.getBool('surfaceBlurEnabled') ?? true;
  surfaceCornerModeNotifier.value = (prefs.getInt('surfaceCornerMode') ?? 0)
      .clamp(0, 2);
  surfaceCornerRadiusNotifier.value =
      (prefs.getInt('surfaceCornerRadius') ?? 24).clamp(0, 48);
  appBgBlurEnabledNotifier.value = prefs.getBool('appBgBlurEnabled') ?? false;
  appBgBlurAmountNotifier.value = prefs.getDouble('appBgBlurAmount') ?? 10.0;
  blurStrengthNotifier.value = (prefs.getDouble('blurStrength') ?? 1.0)
      .clamp(0.25, 2.0)
      .toDouble();
  unawaited(nativeUiGateway.setWindowBlur(blurEnabledNotifier.value));
  await loadAccountPersonalData();
  pageTransitionNotifier.value = (prefs.getInt('pageTransition') ?? 0).clamp(
    0,
    8,
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
  lessonFullTeacherNamesNotifier.value =
      prefs.getBool('lessonFullTeacherNames') ?? false;
  lessonShowSubjectIconsNotifier.value =
      prefs.getBool('lessonShowSubjectIcons') ?? false;
  lessonShowRoomNotifier.value = prefs.getBool('lessonShowRoom') ?? true;
  lessonCompactModeNotifier.value = prefs.getBool('lessonCompactMode') ?? false;
  lessonDimPastNotifier.value = prefs.getBool('lessonDimPast') ?? true;
  lessonCancelledPatternNotifier.value =
      prefs.getBool('lessonCancelledPattern') ?? true;
  dailyBriefingPushNotifier.value = prefs.getBool('dailyBriefingPush') ?? true;
  importantChangesPushNotifier.value =
      prefs.getBool('importantChangesPush') ?? true;
  progressivePushNotifier.value = prefs.getBool('progressivePush') ?? true;
  notifyChangeCancellationsNotifier.value =
      prefs.getBool('notifyChangeCancellations') ?? true;
  notifyChangeRoomNotifier.value = prefs.getBool('notifyChangeRoom') ?? true;
  notifyChangeTeacherNotifier.value =
      prefs.getBool('notifyChangeTeacher') ?? true;
  notifyChangeOtherNotifier.value = prefs.getBool('notifyChangeOther') ?? true;

  await loadCustomBackgroundsFromPrefs(prefs);

  final hasProviderConfig = prefs.containsKey('aiProvider');
  if (!hasProviderConfig && (prefs.getString('geminiApiKey') ?? '').isEmpty) {
    // Legacy migration: old versions stored the Gemini key under openAiApiKey.
    final legacy = prefs.getString('openAiApiKey') ?? '';
    if (legacy.isNotEmpty) {
      await CredentialVault.instance.writeAiApiKey('gemini', legacy);
      await prefs.remove('openAiApiKey');
    }
  }
  final secureAiKeys = await CredentialVault.instance.loadAndMigrateAiKeys(
    prefs,
  );
  geminiApiKey = secureAiKeys['gemini'] ?? '';

  openAiApiKey = secureAiKeys['openai'] ?? '';
  mistralApiKey = secureAiKeys['mistral'] ?? '';
  customAiApiKey = secureAiKeys['custom'] ?? '';
  aiProvider = _normalizeAiProvider(prefs.getString('aiProvider') ?? 'gemini');
  aiCustomCompatibility = _normalizeAiCustomCompatibility(
    prefs.getString('aiCustomCompatibility') ?? 'openai',
  );
  aiCustomBaseUrl = prefs.getString('aiCustomBaseUrl') ?? '';
  aiSystemPromptTemplate = prefs.getString('aiSystemPromptTemplate') ?? '';
  aiTemperature = prefs.getDouble('aiTemperature') ?? 0.2;
  aiMaxTokens = prefs.getInt('aiMaxTokens') ?? 2600;
  aiTopP = prefs.getDouble('aiTopP') ?? 0.95;
  aiPersona = prefs.getString('aiPersona') ?? 'helpful';
  aiLocalModelPath = prefs.getString('aiLocalModelPath') ?? aiLocalModelPath;
  if (aiLocalModelPath.isNotEmpty) {
    // A stale or tampered path (file deleted, moved, truncated or replaced
    // with something that is not a GGUF) must never reach the native
    // llama.cpp parser. Validate it with the same magic/size rules used on
    // download and fall back to a cleared path on failure.
    if (!await _isValidLocalModelFile(
      aiLocalModelPath,
      model: _localModelForPath(aiLocalModelPath),
    )) {
      aiLocalModelPath = '';
      await prefs.setString('aiLocalModelPath', '');
      // With no usable model file a 'local' provider is a broken state.
      // Mirror _deleteLocalModel and fall back to Gemini.
      if (_normalizeAiProvider(aiProvider) == 'local') {
        aiProvider = 'gemini';
        aiModel = _defaultModelForProvider('gemini');
        await prefs.setString('aiProvider', aiProvider);
        await prefs.setString('aiModel', aiModel);
      }
    }
  }
  final savedModel = prefs.getString('aiModel') ?? '';
  final availableModels = _modelsForProvider(
    aiProvider,
    customCompatibility: aiCustomCompatibility,
  );
  aiModel = savedModel.isNotEmpty
      ? savedModel
      : _defaultModelForProvider(
          aiProvider,
          customCompatibility: aiCustomCompatibility,
        );
  if (!availableModels.contains(aiModel)) {
    aiModel = _defaultModelForProvider(
      aiProvider,
      customCompatibility: aiCustomCompatibility,
    );
    await prefs.setString('aiModel', aiModel);
  }

  runApp(
    ProviderScope(
      child: UntisPlusApp(
        startScreen:
            onboardingCompleted && (isLoggedIn || demoModeNotifier.value)
            ? MainNavigationScreen(
                showTutorialOnStart: onboardingCompleted && !tutorialCompleted,
              )
            : const OnboardingFlow(),
      ),
    ),
  );

  // Native integrations are important but do not need to delay the first UI.
  unawaited(_initializeDeferredNativeServices());
  unawaited(_initializeDeferredAccountData());
  if (!kIsWeb && !Platform.isIOS) {
    unawaited(checkGithubUpdateAndNotify());
  }
}
