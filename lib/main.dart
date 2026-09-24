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
import 'features/updates/data/github_release_repository.dart';
import 'features/updates/data/changelog_repository.dart';
import 'features/school_info/data/school_info_repository.dart';
import 'features/school_info/application/school_html.dart';
import 'features/absences/data/absence_repository.dart';
import 'features/absences/domain/absence.dart';
import 'features/homework/domain/homework.dart';
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

final AiRequestCoordinator _aiRequestCoordinator = AiRequestCoordinator();

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
  surfaceBlurEnabledNotifier.value =
      prefs.getBool('surfaceBlurEnabled') ?? true;
  surfaceCornerModeNotifier.value = (prefs.getInt('surfaceCornerMode') ?? 0)
      .clamp(0, 2);
  surfaceCornerRadiusNotifier.value =
      (prefs.getInt('surfaceCornerRadius') ?? 24).clamp(0, 48);
  appBgBlurEnabledNotifier.value = prefs.getBool('appBgBlurEnabled') ?? false;
  appBgBlurAmountNotifier.value = prefs.getDouble('appBgBlurAmount') ?? 10.0;
  blurStrengthNotifier.value =
      (prefs.getDouble('blurStrength') ?? 1.0).clamp(0.25, 2.0).toDouble();
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
<<<<<<< HEAD
=======

Uri _webUntisRpcUri({String? serverUrl, String? school}) {
  final resolvedServer = serverUrl ?? schoolUrl;
  final resolvedSchool = school ?? schoolName;
  return Uri.parse(
    'https://$resolvedServer/WebUntis/jsonrpc.do?school=$resolvedSchool',
  );
}

Uri _webUntisInternRpcUri({String? serverUrl, String? school}) {
  final resolvedServer = serverUrl ?? schoolUrl;
  final resolvedSchool = school ?? schoolName;
  return Uri.parse(
    'https://$resolvedServer/WebUntis/jsonrpc_intern.do?school=$resolvedSchool',
  );
}

String _normalizeWebUntisSecret(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  if (trimmed.startsWith('otpauth://')) {
    return OTPUri.extractSecret(
      trimmed,
    ).trim().replaceAll(' ', '').toUpperCase();
  }

  if (trimmed.startsWith('untis://')) {
    final uri = Uri.tryParse(trimmed);
    final extracted =
        uri?.queryParameters['key'] ?? uri?.queryParameters['secret'] ?? '';
    if (extracted.isNotEmpty) {
      return extracted.trim().replaceAll(' ', '').toUpperCase();
    }
  }

  return trimmed.replaceAll(' ', '').toUpperCase();
}

String _generateWebUntisOtp(String credential) {
  final secret = _normalizeWebUntisSecret(credential);
  if (secret.isEmpty) {
    throw ArgumentError('WebUntis secret must not be empty.');
  }

  final totp = TOTP(
    secret: secret,
    digits: 6,
    algorithm: OTPAlgorithm.sha1,
    period: 30,
  );
  return totp.now();
}

/// Resolves the WebUntis element (person id + type) that timetable requests
/// should target after a successful authentication.
///
/// Guardian/Parent logins (person type 3) have no timetable of their own:
/// WebUntis returns an empty/invalid result for the guardian element. When the
/// authentication response lists linked persons (authenticate -> `people`,
/// app config -> `persons`), the first student (type 5) is used instead so a
/// parent account shows a child's timetable.
Map<String, dynamic> _resolveTimetableElementFromAuth(
  Map<String, dynamic> authResult,
  int fallbackPersonId,
  int fallbackPersonType,
) {
  var personId = fallbackPersonId;
  var personType = fallbackPersonType;

  final linked = <Map<dynamic, dynamic>>[];
  final rawPeople = authResult['people'];
  if (rawPeople is List) {
    for (final p in rawPeople) {
      if (p is Map) linked.add(Map<dynamic, dynamic>.from(p));
    }
  }
  final rawPersons = authResult['persons'];
  if (rawPersons is List) {
    for (final p in rawPersons) {
      if (p is Map) linked.add(Map<dynamic, dynamic>.from(p));
    }
  }

  Map<dynamic, dynamic>? self;
  for (final p in linked) {
    if ((p['id']?.toString()) == personId.toString()) {
      self = p;
      break;
    }
  }
  if (self != null) {
    final selfType = int.tryParse(self['type']?.toString() ?? '');
    if (selfType != null) personType = selfType;
  }

  if (personType == 3) {
    Map<dynamic, dynamic>? child;
    for (final p in linked) {
      if (int.tryParse(p['type']?.toString() ?? '-1') == 5) {
        child = p;
        break;
      }
    }
    if (child != null) {
      final childId = int.tryParse(child['id']?.toString() ?? '');
      if (childId != null && childId > 0) {
        personId = childId;
        personType = 5;
      }
    }
  }

  return {'personId': personId, 'personType': personType};
}

Future<Map<String, dynamic>?> _authenticateUntisWithSecret({
  required String user,
  required String secret,
  required String client,
  String requestId = 'auth',
  String? serverUrl,
  String? school,
}) async {
  final otp = _generateWebUntisOtp(secret);
  final response = await http
      .post(
        _webUntisInternRpcUri(serverUrl: serverUrl, school: school),
        body: jsonEncode({
          'id': requestId,
          'method': 'getUserData2017',
          'params': [
            {
              'auth': {
                'clientTime': DateTime.now().millisecondsSinceEpoch,
                'user': user,
                'otp': otp,
              },
            },
          ],
          'jsonrpc': '2.0',
        }),
      )
      .timeout(const Duration(seconds: 8));

  if (response.statusCode != 200 || response.body.trim().isEmpty) {
    return null;
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final error = decoded['error'];
  if (error is Map) {
    final err = Map<String, dynamic>.from(error);
    final message = (err['message'] ?? '').toString();
    final data = (err['data'] ?? '').toString();
    final combined = '${message.toLowerCase()} ${data.toLowerCase()}';
    if (combined.contains('otp') ||
        combined.contains('secret') ||
        combined.contains('login')) {
      return {
        'otpInvalid': true,
        'errorCode': err['code'],
        'errorMessage': message,
      };
    }
  }

  if (!response.headers.containsKey('set-cookie')) {
    return null;
  }

  final cookie = response.headers['set-cookie'];
  if (cookie == null || cookie.isEmpty) {
    return null;
  }

  final sessionId =
      RegExp(r'JSESSIONID=([^;]+)').firstMatch(cookie)?.group(1) ?? '';
  if (sessionId.isEmpty) {
    return null;
  }

  final appConfigResponse = await http
      .get(
        Uri.parse('https://${serverUrl ?? schoolUrl}/WebUntis/api/app/config'),
        headers: {
          'Cookie': 'JSESSIONID=$sessionId; schoolname=${school ?? schoolName}',
        },
      )
      .timeout(const Duration(seconds: 6));

  if (appConfigResponse.statusCode != 200 ||
      appConfigResponse.body.trim().isEmpty) {
    return {'sessionId': sessionId};
  }

  final appConfigDecoded = jsonDecode(appConfigResponse.body);
  if (appConfigDecoded is! Map<String, dynamic>) {
    return {'sessionId': sessionId};
  }

  final data = appConfigDecoded['data'];
  final loginConfigUser = data is Map
      ? data['loginServiceConfig'] is Map
            ? (data['loginServiceConfig'] as Map)['user']
            : null
      : null;
  if (loginConfigUser is Map) {
    final personId = loginConfigUser['personId'];
    final persons = loginConfigUser['persons'];
    int? personType;
    if (persons is List) {
      final person = persons.cast<dynamic>().firstWhere(
        (entry) => entry is Map && entry['id'] == personId,
        orElse: () => null,
      );
      if (person is Map && person['type'] != null) {
        personType = int.tryParse(person['type'].toString());
      }
    }
    final parsedId = int.tryParse(personId?.toString() ?? '') ?? 0;
    // Guardian logins are redirected to their first linked student so the
    // stored element always points at a valid timetable target.
    final element = _resolveTimetableElementFromAuth(
      {
        if (persons is List) 'persons': persons,
        'personId': parsedId,
        'personType': personType ?? 5,
      },
      parsedId,
      personType ?? 5,
    );
    return {
      'sessionId': sessionId,
      'personId': element['personId'] ?? parsedId,
      'personType': element['personType'] ?? 5,
    };
  }

  return {'sessionId': sessionId};
}

Future<Map<String, dynamic>?> _authenticateUntis({
  required String user,
  required String password,
  required String client,
  String requestId = 'auth',
  String? serverUrl,
  String? school,
  String? otp,
  bool useLoginKey = false,
}) async {
  if (useLoginKey) {
    return _authenticateUntisWithSecret(
      user: user,
      secret: password,
      client: client,
      requestId: requestId,
      serverUrl: serverUrl,
      school: school,
    );
  }

  final otpCode = otp?.trim();
  final params = <String, dynamic>{
    'user': user,
    'password': password,
    'client': client,
  };
  if (otpCode != null && otpCode.isNotEmpty) {
    params['otp'] = otpCode;
  }

  final response = await http
      .post(
        _webUntisRpcUri(serverUrl: serverUrl, school: school),
        body: jsonEncode({
          'id': requestId,
          'method': 'authenticate',
          'params': params,
          'jsonrpc': '2.0',
        }),
      )
      .timeout(const Duration(seconds: 8));

  if (response.statusCode != 200 || response.body.trim().isEmpty) {
    return null;
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final result = decoded['result'];
  if (result is Map<String, dynamic>) {
    return result;
  }
  if (result is Map) {
    return Map<String, dynamic>.from(result);
  }

  final error = decoded['error'];
  if (error is Map) {
    final err = Map<String, dynamic>.from(error);
    final message = (err['message'] ?? '').toString();
    final data = (err['data'] ?? '').toString();
    final combined = '${message.toLowerCase()} ${data.toLowerCase()}';
    final contains2faHint =
        combined.contains('2fa') ||
        combined.contains('two factor') ||
        combined.contains('mfa') ||
        combined.contains('otp') ||
        combined.contains('one-time') ||
        combined.contains('verification code') ||
        combined.contains('authenticator');

    if (contains2faHint && (otpCode == null || otpCode.isEmpty)) {
      return {
        'requires2fa': true,
        'errorCode': err['code'],
        'errorMessage': message,
      };
    }

    // Treat any server error as an invalid OTP when a code was provided, so
    // the caller can show the 2FA-specific error instead of the generic
    // "check your credentials" message.
    final invalidOtp =
        combined.contains('invalid otp') ||
        combined.contains('invalid verification') ||
        combined.contains('wrong otp') ||
        combined.contains('otp invalid') ||
        (otpCode != null && otpCode.isNotEmpty);
    if (invalidOtp) {
      return {
        'otpInvalid': true,
        'errorCode': err['code'],
        'errorMessage': message,
      };
    }
  }

  return null;
}

// --- WOCHENPLAN (TAB VIEW) ---
class WeeklyTimetablePage extends StatefulWidget {
  const WeeklyTimetablePage({super.key});

  @override
  State<WeeklyTimetablePage> createState() => _WeeklyTimetablePageState();
}

class _LessonSlot {
  const _LessonSlot({
    required this.lesson,
    required this.startMin,
    required this.endMin,
    required this.column,
    required this.columnCount,
  });

  final Map<dynamic, dynamic> lesson;
  final int startMin;
  final int endMin;
  final int column;
  final int columnCount;
}

class _LessonSlotCandidate {
  _LessonSlotCandidate({
    required this.lesson,
    required this.startMin,
    required this.endMin,
  });

  final Map<dynamic, dynamic> lesson;
  final int startMin;
  final int endMin;
  int column = 0;
}

class _TimeRangeLabel {
  const _TimeRangeLabel({required this.startMin, required this.endMin});

  final int startMin;
  final int endMin;
}

/// Filters time labels to prevent overlapping on the vertical time axis.
/// Keeps only labels spaced at least [minGapMinutes] apart (default 15).
List<int> _filterTimeLabels(List<_TimeRangeLabel> ranges, {int minGapMinutes = 15}) {
  final allTimes = <int>{};
  for (final r in ranges) {
    allTimes.add(r.startMin);
    allTimes.add(r.endMin);
  }
  final sorted = allTimes.toList()..sort();
  final filtered = <int>[];
  for (final t in sorted) {
    if (filtered.isEmpty || t - filtered.last >= minGapMinutes) {
      filtered.add(t);
    }
  }
  return filtered;
}

class _WeeklyTimetablePageState extends State<WeeklyTimetablePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<int, List<dynamic>> _weekData = {0: [], 1: [], 2: [], 3: [], 4: []};
  List<Map<String, dynamic>> _holidays = [];
  bool _loading = true;
  String? _loadError;
  bool _showingCachedWeek = false;
  int _viewMode = 0;
  // Carousel state for week switching
  double _carouselOffset = 0.0;
  AnimationController? _carouselAnimController;
  final Map<String, Map<int, List<dynamic>>> _adjacentWeekCache = {};
  bool _adjacentWeekRefreshScheduled = false;
  // The day view has its own carousel so its page follows the finger instead
  // of only changing the selected tab after a drag has finished.
  double _dayCarouselOffset = 0.0;
  // When a date tab is tapped, the incoming page may be farther than the
  // adjacent day. Keep it explicit until the carousel has completed.
  int? _dayCarouselTargetDay;
  AnimationController? _dayCarouselAnimController;
  Animation<double>? _dayCarouselAnimation;
  CarouselController? _materialDayCarouselController;
  CarouselController? _materialWeekCarouselController;
  int _materialDayIndex = 1;
  int _materialWeekIndex = 1;
  bool _isWeekCarouselAnimating = false;
  bool _isDayCarouselAnimating = false;
  bool _suppressDayTabControllerRebuild = false;
  late final AnimationController _cacheRefreshController;
  int _weekFetchGeneration = 0;
  bool _isExportingTimetable = false;
  final GlobalKey _timetableExportKey = GlobalKey();
  final Map<String, Map<dynamic, dynamic>> _temporaryLessonOriginals = {};

  // lessonIdentity -> original teacher (struck-through) when the lesson was
  // substituted. Filled from the ChangeRepository teacher changes.
  final Map<String, String> _originalTeachers = {};

  // #138: a tapped change notification deep-links to the changed day and
  // briefly pulses the affected lesson tile.
  int? _highlightDate;
  int? _highlightStartTime;
  AnimationController? _highlightController;
  Timer? _highlightTimer;

  static String _lessonIdentityOf(Map<dynamic, dynamic> lesson) {
    final rawId = lesson['id'] ?? lesson['lsid'];
    if (rawId != null && rawId.toString().isNotEmpty) return 'id:$rawId';
    final date = lesson['date'] ?? 0;
    final start = lesson['startTime'] ?? 0;
    final end = lesson['endTime'] ?? 0;
    final subject =
        (lesson['_subjectShort'] ?? lesson['subject'] ?? lesson['su'] ?? '')
            .toString()
            .trim();
    return 'fallback:$date|$start|$end|$subject';
  }

  /// Fills [_originalTeachers] from the stored teacher changes so lesson
  /// tiles can show "substitute teacher" with the original struck-through.
  void _applyOriginalTeachers(List<TimetableChange> changes) {
    final map = <String, String>{};
    for (final change in changes) {
      if (change.type == TimetableChangeType.teacher &&
          change.lessonIdentity.isNotEmpty &&
          (change.before ?? '').trim().isNotEmpty) {
        map[change.lessonIdentity] = change.before!.trim();
      }
    }
    final dirty =
        map.length != _originalTeachers.length ||
        map.entries.any((entry) => _originalTeachers[entry.key] != entry.value);
    _originalTeachers
      ..clear()
      ..addAll(map);
    if (dirty && mounted) setState(() {});
  }

  Future<void> _loadStoredTeacherChanges() async {
    try {
      final changes = await ChangeRepository().loadChanges(
        activeUntisAccountId ?? 'legacy',
      );
      _applyOriginalTeachers(changes);
    } catch (_) {}
  }
  AlarmConfig _alarmConfig = const AlarmConfig();
  Timer? _progressiveNotificationTimer;

  String? _tempSessionId;
  int? _viewingClassId;
  String? _viewingClassName;

  String get _currentSessionId =>
      (_viewingClassId != null && _tempSessionId != null)
      ? _tempSessionId!
      : sessionID;

  static const double _ppm = 1.5;

  List<String> get _dayShort =>
      AppL10n.of(appLocaleNotifier.value).weekDayShort;

  final Map<int, String> _subjectLong = {};
  final Map<int, String> _subjectShortMap = {};
  final Map<int, String> _teacherMap = {};
  // WebUntis short name/Kürzel per teacher id (e.g. "MUE"). Used when the
  // "full teacher names" display setting is turned off.
  final Map<int, String> _teacherShortMap = {};
  final Map<int, String> _roomMap = {};

  String _mondayKey(DateTime monday) => DateFormat('yyyyMMdd').format(monday);

  String _weekCacheKeyFor({
    required DateTime monday,
    required int requestPersonId,
    required int requestPersonType,
  }) {
    final mondayStr = DateFormat('yyyyMMdd').format(monday);
    return [
      'weekCacheV1',
      schoolUrl,
      schoolName,
      requestPersonType.toString(),
      requestPersonId.toString(),
      mondayStr,
    ].join('|');
  }

  String _weekCacheKey({
    required int requestPersonId,
    required int requestPersonType,
  }) {
    return _weekCacheKeyFor(
      monday: _currentMonday,
      requestPersonId: requestPersonId,
      requestPersonType: requestPersonType,
    );
  }

  Map<int, List<dynamic>> _emptyWeekData() => {
    0: <dynamic>[],
    1: <dynamic>[],
    2: <dynamic>[],
    3: <dynamic>[],
    4: <dynamic>[],
  };

  void _applyKnownSubjectsFromWeek(Map<int, List<dynamic>> weekData) {
    final allSubjects = <String>{};
    for (final list in weekData.values) {
      for (final l in list) {
        final s = l['_subjectShort']?.toString() ?? '';
        if (s.isNotEmpty) allSubjects.add(s);
      }
    }
    knownSubjectsNotifier.value = allSubjects;
  }

  Future<Map<int, List<dynamic>>?> _loadWeekFromCache({
    required int requestPersonId,
    required int requestPersonType,
    DateTime? monday,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = monday != null
          ? _weekCacheKeyFor(
              monday: monday,
              requestPersonId: requestPersonId,
              requestPersonType: requestPersonType,
            )
          : _weekCacheKey(
              requestPersonId: requestPersonId,
              requestPersonType: requestPersonType,
            );
      final storeKey = OfflineCacheStore.instance.scopedKey(
        accountId: activeUntisAccountId ?? 'legacy',
        dataset: 'timetableWeek',
        entityKey: key,
      );
      final stored = await OfflineCacheStore.instance.read(storeKey);
      dynamic decoded = stored?.value;
      if (decoded == null) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) return null;
        decoded = jsonDecode(raw);
        if (decoded is Map) {
          await OfflineCacheStore.instance.write(
            storeKey,
            Map<String, dynamic>.from(decoded),
          );
          await prefs.remove(key);
        }
      }
      if (decoded is! Map) return null;
      final week = decoded['weekData'];
      if (week is! Map) return null;

      final tempWeek = _emptyWeekData();
      for (var i = 0; i < 5; i++) {
        final dayRaw = week['$i'];
        if (dayRaw is! List) continue;
        tempWeek[i] = dayRaw
            .whereType<Map>()
            .map(
              (lesson) =>
                  Map<String, dynamic>.from(lesson.cast<String, dynamic>()),
            )
            .toList();
      }
      tempWeek.forEach((_, list) {
        list.sort((a, b) {
          final aStart = (a['startTime'] as num?)?.toInt() ?? 0;
          final bStart = (b['startTime'] as num?)?.toInt() ?? 0;
          return aStart.compareTo(bStart);
        });
      });
      // The cached week already carries enriched display values, but the
      // teacher name may have been stored under a different display setting.
      // Re-enrich so the current setting applies (falls back to stored values
      // while the master data maps are not loaded yet).
      _reEnrichWeek(tempWeek);

      final cachedHolidays = decoded['holidays'];
      if (cachedHolidays is List) {
        _holidays = cachedHolidays
            .whereType<Map>()
            .map((h) => Map<String, dynamic>.from(h.cast<String, dynamic>()))
            .toList();
      }

      return tempWeek;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveWeekToCache({
    required int requestPersonId,
    required int requestPersonType,
    required Map<int, List<dynamic>> weekData,
    DateTime? monday,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = monday != null
          ? _weekCacheKeyFor(
              monday: monday,
              requestPersonId: requestPersonId,
              requestPersonType: requestPersonType,
            )
          : _weekCacheKey(
              requestPersonId: requestPersonId,
              requestPersonType: requestPersonType,
            );
      final payload = {
        'savedAt': DateTime.now().toIso8601String(),
        'weekData': {
          for (var i = 0; i < 5; i++) '$i': weekData[i] ?? const <dynamic>[],
        },
        if (_holidays.isNotEmpty) 'holidays': _holidays,
      };
      final storeKey = OfflineCacheStore.instance.scopedKey(
        accountId: activeUntisAccountId ?? 'legacy',
        dataset: 'timetableWeek',
        entityKey: key,
      );
      await OfflineCacheStore.instance.write(storeKey, payload);
      // Remove a migrated legacy JSON cache only after the Hive write succeeds.
      await prefs.remove(key);
    } catch (_) {}
  }

  String _extractTeacherNamesFromLesson(Map<dynamic, dynamic> lesson) {
    final teacherEntries = ((lesson['te'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .cast<Map<dynamic, dynamic>>()
        .toList();
    final teacherParts = <String>[];
    for (final te in teacherEntries) {
      final teId = te['id'] as int?;
      final mapped = teId != null ? _teacherMap[teId] : null;
      final direct =
          (te['longName'] ??
                  te['longname'] ??
                  te['displayName'] ??
                  te['fullName'] ??
                  te['name'] ??
                  '')
              .toString()
              .trim();
      final candidate = (mapped?.trim().isNotEmpty == true)
          ? mapped!.trim()
          : direct;
      if (candidate.isNotEmpty && !teacherParts.contains(candidate)) {
        teacherParts.add(candidate);
      }
    }
    return teacherParts.join(', ');
  }

  String _extractTeacherNamesFromTopLevel(Map<dynamic, dynamic> lesson) {
    final candidates = <String>[];

    void addValue(dynamic value) {
      if (value == null) return;
      if (value is List) {
        for (final v in value) {
          final s = v?.toString().trim() ?? '';
          if (s.isNotEmpty && !candidates.contains(s)) candidates.add(s);
        }
        return;
      }
      final s = value.toString().trim();
      if (s.isNotEmpty && !candidates.contains(s)) candidates.add(s);
    }

    addValue(lesson['teacher']);
    addValue(lesson['teacherName']);
    addValue(lesson['teacherLongName']);
    addValue(lesson['teachers']);
    addValue(lesson['teName']);
    addValue(lesson['teLongName']);
    addValue(lesson['orgTeacher']);
    addValue(lesson['orgTeacherName']);
    addValue(lesson['substTeacher']);
    addValue(lesson['substTeacherName']);
    addValue(lesson['teacherText']);
    addValue(lesson['teacherDisplay']);

    return candidates.join(', ');
  }

  String _lessonTeacherKey(
    Map<dynamic, dynamic> lesson, {
    bool withRoom = true,
  }) {
    final date = lesson['date']?.toString() ?? '';
    final start = lesson['startTime']?.toString() ?? '';
    final end = lesson['endTime']?.toString() ?? '';
    final subId = (lesson['su'] as List?)?.firstOrNull?['id']?.toString() ?? '';
    final roomId = withRoom
        ? ((() {
            final r = lesson['ro'];
            final list = r is List
                ? r
                : r is Map
                ? [r]
                : <dynamic>[];
            return list.firstOrNull?['id']?.toString() ?? '';
          })())
        : '';
    return '$date|$start|$end|$subId|$roomId';
  }

  String _lessonTeacherKeyFromParts({
    required dynamic date,
    required dynamic startTime,
    required dynamic endTime,
    required dynamic subjectId,
    dynamic roomId,
    bool withRoom = true,
  }) {
    final d = date?.toString() ?? '';
    final s = startTime?.toString() ?? '';
    final e = endTime?.toString() ?? '';
    final sub = subjectId?.toString() ?? '';
    final room = withRoom ? (roomId?.toString() ?? '') : '';
    return '$d|$s|$e|$sub|$room';
  }

  Future<void> _loadMasterDataFromCache() async {
    if (_subjectShortMap.isNotEmpty &&
        _teacherMap.isNotEmpty &&
        _roomMap.isNotEmpty) {
      return;
    }
    try {
      final storeKey = OfflineCacheStore.instance.scopedKey(
        accountId: activeUntisAccountId ?? 'legacy',
        dataset: 'masterData',
        entityKey: '$schoolUrl|$schoolName',
      );
      final stored = await OfflineCacheStore.instance.read(storeKey);
      if (stored == null) return;
      final val = stored.value;
      if (val['subjectsLong'] is Map) {
        (val['subjectsLong'] as Map).forEach((k, v) {
          final id = int.tryParse(k.toString());
          if (id != null) _subjectLong[id] = v.toString();
        });
      }
      if (val['subjectsShort'] is Map) {
        (val['subjectsShort'] as Map).forEach((k, v) {
          final id = int.tryParse(k.toString());
          if (id != null) _subjectShortMap[id] = v.toString();
        });
      }
      if (val['teachers'] is Map) {
        (val['teachers'] as Map).forEach((k, v) {
          final id = int.tryParse(k.toString());
          if (id != null) _teacherMap[id] = v.toString();
        });
      }
      if (val['teacherShorts'] is Map) {
        (val['teacherShorts'] as Map).forEach((k, v) {
          final id = int.tryParse(k.toString());
          if (id != null) _teacherShortMap[id] = v.toString();
        });
      }
      if (val['rooms'] is Map) {
        (val['rooms'] as Map).forEach((k, v) {
          final id = int.tryParse(k.toString());
          if (id != null) _roomMap[id] = v.toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveMasterDataToCache() async {
    try {
      final storeKey = OfflineCacheStore.instance.scopedKey(
        accountId: activeUntisAccountId ?? 'legacy',
        dataset: 'masterData',
        entityKey: '$schoolUrl|$schoolName',
      );
      final payload = {
        'subjectsLong': {
          for (final e in _subjectLong.entries) e.key.toString(): e.value,
        },
        'subjectsShort': {
          for (final e in _subjectShortMap.entries) e.key.toString(): e.value,
        },
        'teachers': {
          for (final e in _teacherMap.entries) e.key.toString(): e.value,
        },
        'teacherShorts': {
          for (final e in _teacherShortMap.entries) e.key.toString(): e.value,
        },
        'rooms': {for (final e in _roomMap.entries) e.key.toString(): e.value},
      };
      await OfflineCacheStore.instance.write(storeKey, payload);
    } catch (_) {}
  }

  Future<void> _fetchMasterData({bool force = false}) async {
    if (!force &&
        _subjectShortMap.isNotEmpty &&
        _teacherMap.isNotEmpty &&
        _roomMap.isNotEmpty) {
      return;
    }
    await _loadMasterDataFromCache();
    if (!force &&
        _subjectShortMap.isNotEmpty &&
        _teacherMap.isNotEmpty &&
        _roomMap.isNotEmpty) {
      return;
    }
    if (_currentSessionId.isEmpty || schoolUrl.isEmpty) return;
    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );
    final headers = {
      "Cookie": "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
      "Content-Type": "application/json",
    };

    Future<Map<String, dynamic>> rpc(String id, String method) async {
      try {
        final r = await http
            .post(
              url,
              headers: headers,
              body: jsonEncode({
                "id": id,
                "method": method,
                "params": {},
                "jsonrpc": "2.0",
              }),
            )
            .timeout(const Duration(seconds: 6));
        final decoded = jsonDecode(r.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
      return <String, dynamic>{};
    }

    final results = await Future.wait([
      rpc("sub", "getSubjects"),
      rpc("tea", "getTeachers"),
      rpc("roo", "getRooms"),
    ]);

    for (var s in (results[0]['result'] as List? ?? [])) {
      final id = s['id'] as int?;
      if (id != null) {
        _subjectLong[id] = (s['longName'] ?? s['longname'] ?? s['name'] ?? '')
            .toString();
        _subjectShortMap[id] = (s['name'] ?? '').toString();
      }
    }
    for (var t in (results[1]['result'] as List? ?? [])) {
      final id = t['id'] as int?;
      if (id != null) {
        final fore = (t['foreName'] ?? t['forename'] ?? '').toString().trim();
        final last = (t['longName'] ?? t['name'] ?? '').toString().trim();
        _teacherMap[id] = fore.isNotEmpty ? '$fore $last' : last;
        _teacherShortMap[id] = (t['name'] ?? '').toString();
      }
    }
    for (var r in (results[2]['result'] as List? ?? [])) {
      final id = r['id'] as int?;
      if (id != null) {
        _roomMap[id] = (r['name'] ?? '').toString();
      }
    }
    unawaited(_saveMasterDataToCache());
    // A week may have been parsed while the teacher/subject maps were still
    // empty, leaving short-name fallbacks in the enriched fields. Re-enrich so
    // every lesson respects the current teacher-name display setting.
    if (_teacherMap.isNotEmpty || _teacherShortMap.isNotEmpty) {
      _reEnrichWeek(_weekData);
      for (final week in _adjacentWeekCache.values) {
        _reEnrichWeek(week);
      }
      _republishWeekDataAfterEnrichment();
    }
  }

  DateTime _currentMonday = resolveDefaultTimetableMonday(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: resolveInitialTimetableDayIndex(DateTime.now()),
    )..addListener(_onSelectedDayChanged);
    _cacheRefreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    if (defaultClassId != null) {
      _viewingClassId = defaultClassId;
      _viewingClassName = defaultClassName;
    }
    hiddenSubjectsNotifier.addListener(_onHiddenSubjectsChanged);
    subjectColorsNotifier.addListener(_onHiddenSubjectsChanged);
    monochromeLessonsNotifier.addListener(_onHiddenSubjectsChanged);
    monochromeLessonColorNotifier.addListener(_onHiddenSubjectsChanged);
    showCancelledNotifier.addListener(_onHiddenSubjectsChanged);
    timetableSwitchAnimationNotifier.addListener(
      _onTimetableSwitchAnimationChanged,
    );
    demoModeNotifier.addListener(_onDemoModeChanged);
    pendingTimetableActionNotifier.addListener(_onPendingTimetableAction);
    lessonCardStyleNotifier.addListener(_onHiddenSubjectsChanged);
    glowEffectsEnabledNotifier.addListener(_onHiddenSubjectsChanged);
    lessonBlurEnabledNotifier.addListener(_onHiddenSubjectsChanged);
    lessonBlurAmountNotifier.addListener(_onHiddenSubjectsChanged);
    lessonCardOpacityNotifier.addListener(_onHiddenSubjectsChanged);
    lessonBorderRadiusNotifier.addListener(_onHiddenSubjectsChanged);
    lessonAccentStyleNotifier.addListener(_onHiddenSubjectsChanged);
    lessonShowTeacherNotifier.addListener(_onHiddenSubjectsChanged);
    lessonShowRoomNotifier.addListener(_onHiddenSubjectsChanged);
    lessonCompactModeNotifier.addListener(_onHiddenSubjectsChanged);
    lessonDimPastNotifier.addListener(_onHiddenSubjectsChanged);
    showFullTeacherNamesNotifier.addListener(_onTeacherNameModeChanged);
    timetableDaySpanNotifier.addListener(_onDaySpanChanged);
    final hasActiveAccount =
        (activeUntisAccountId != null &&
            untisAccountsNotifier.value.any(
              (account) =>
                  account.id == activeUntisAccountId &&
                  (account.sessionId.isNotEmpty || account.password.isNotEmpty),
            )) ||
        sessionID.isNotEmpty;
    if (hasActiveAccount || demoModeNotifier.value) {
      _fetchFullWeek();
    }
    unawaited(_loadStoredTeacherChanges());
    _loadViewPref();
    _loadAlarmConfig();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Start foreground timer to keep the progressive notification fresh.
    // It reads from the offline cache (works without network) and updates
    // the ongoing "current lesson" notification every minute while the app
    // is open, preventing the notification from drifting hours behind.
    if (!kIsWeb) {
      _progressiveNotificationTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => unawaited(refreshProgressiveNotificationFromCache()),
      );
    }
  }

  Future<void> _loadAlarmConfig() async {
    final config = await AlarmService.instance.loadConfig();
    if (mounted) setState(() => _alarmConfig = config);
  }

  Future<void> _saveDateAlarmOverride(
    DateTime date,
    AlarmDateOverride? override,
  ) async {
    await AlarmService.instance.saveDateOverride(alarmDateKey(date), override);
    await _loadAlarmConfig();
    // Prefer a fresh current-day response. When offline, saveDateOverride has
    // already adjusted the durable next plan if it is the selected day.
    if (_alarmConfig.smartEnabled) {
      updateUntisData().catchError((_) => false);
    }
  }

  Future<void> _showDateAlarmActions(DateTime date) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final key = alarmDateKey(date);
    final current =
        _alarmConfig.dateOverrides[key] ?? const AlarmDateOverride();
    final dateLabel = DateFormat(
      'EEEE, d. MMMM',
      _icuLocale(appLocaleNotifier.value),
    ).format(date);
    await showUntisModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.ui('alarmDateActions').replaceAll('{date}', dateLabel),
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.ui('alarmDateActionsDesc'),
                style: GoogleFonts.outfit(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                value: current.disabled,
                secondary: Icon(
                  current.disabled
                      ? Icons.alarm_off_rounded
                      : Icons.alarm_rounded,
                ),
                title: Text(l.ui('alarmDisableDate')),
                onChanged: (disabled) async {
                  await _saveDateAlarmOverride(
                    date,
                    current.copyWith(disabled: disabled),
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: Text(l.ui('alarmCustomTime')),
                subtitle: current.customTimeOfDayMinutes == null
                    ? null
                    : Text(
                        TimeOfDay(
                          hour: current.customTimeOfDayMinutes! ~/ 60,
                          minute: current.customTimeOfDayMinutes! % 60,
                        ).format(sheetContext),
                      ),
                onTap: () async {
                  final initial = TimeOfDay(
                    hour: current.customTimeOfDayMinutes == null
                        ? 7
                        : current.customTimeOfDayMinutes! ~/ 60,
                    minute: current.customTimeOfDayMinutes == null
                        ? 0
                        : current.customTimeOfDayMinutes! % 60,
                  );
                  final chosen = await showTimePicker(
                    context: sheetContext,
                    initialTime: initial,
                  );
                  if (chosen == null) return;
                  await _saveDateAlarmOverride(
                    date,
                    current.copyWith(
                      disabled: false,
                      customTimeOfDayMinutes: chosen.hour * 60 + chosen.minute,
                    ),
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.fast_forward_rounded),
                title: Text(l.ui('alarmEarlier')),
                subtitle: Text(
                  l
                      .ui('alarmEarlierValue')
                      .replaceAll(
                        '{n}',
                        '${_alarmConfig.nextAlarmEarlierMinutes}',
                      ),
                ),
                onTap: () async {
                  await _saveDateAlarmOverride(
                    date,
                    current.copyWith(
                      disabled: false,
                      earlierMinutes: _alarmConfig.nextAlarmEarlierMinutes,
                    ),
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              if (!current.isEmpty)
                TextButton.icon(
                  onPressed: () async {
                    await _saveDateAlarmOverride(date, null);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(l.ui('alarmClearDate')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPendingTimetableAction() {
    if (!mounted) return;
    final action = pendingTimetableActionNotifier.value;
    if (action == null || action.isEmpty) return;

    final l = AppL10n.of(appLocaleNotifier.value);
    final current = (pendingTimetableCurrentLessonNotifier.value ?? '').trim();
    final next = (pendingTimetableNextLessonNotifier.value ?? '').trim();

    pendingTimetableActionNotifier.value = null;

    if (action == 'open_free_rooms') {
      _showFreeRoomsDialog();
      return;
    }

    if (action == 'open_next_lesson') {
      final text = next.isNotEmpty
          ? l.notificationActionNextLesson(next)
          : l.notificationActionNoNextLesson;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (action == 'open_change') {
      _handlePendingChangeHighlight();
      return;
    }

    if (current.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.notificationActionCurrentLesson(current)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Deep link from the important-changes notification (#138): jump to the
  /// changed day (switching the week when necessary) and pulse the tile.
  void _handlePendingChangeHighlight() {
    final date = pendingChangeHighlightDateNotifier.value;
    final startTime = pendingChangeHighlightStartTimeNotifier.value;
    pendingChangeHighlightDateNotifier.value = null;
    pendingChangeHighlightStartTimeNotifier.value = null;
    if (date == null) return;

    final dateStr = date.toString();
    DateTime? target;
    if (dateStr.length == 8) {
      try {
        target = DateTime(
          int.parse(dateStr.substring(0, 4)),
          int.parse(dateStr.substring(4, 6)),
          int.parse(dateStr.substring(6, 8)),
        );
      } catch (_) {}
    }
    if (target == null) return;

    final monday = DateTime(
      _currentMonday.year,
      _currentMonday.month,
      _currentMonday.day,
    );
    final dayOnly = DateTime(target.year, target.month, target.day);
    final delta = dayOnly.difference(monday).inDays;

    if (delta < -2 || delta > 6) {
      final l = AppL10n.of(appLocaleNotifier.value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.notificationChangeOutsideWeek),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _highlightDate = date;
      _highlightStartTime = startTime;
    });
    _highlightController?.reset();
    _highlightController?.forward();
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 3600), () {
      if (!mounted) return;
      setState(() {
        _highlightDate = null;
        _highlightStartTime = null;
      });
    });

    if (delta >= 0 && delta <= 4) {
      _animateDayTabTo(delta);
    } else if (delta < 0) {
      // Previous week, seen as Friday at the carousel's left edge.
      _commitMaterialDayIndex(0);
    } else {
      // Next week's Monday at the right edge.
      _commitMaterialDayIndex(6);
    }
  }

  /// Whether [lesson] is the tile targeted by the last tapped change
  /// notification.
  bool _isHighlightMatch(Map<dynamic, dynamic> lesson) {
    final highlightDate = _highlightDate;
    if (highlightDate == null) return false;
    final lessonDate = (lesson['date'] as num?)?.toInt();
    final lessonStart = (lesson['startTime'] as num?)?.toInt();
    return lessonDate == highlightDate && lessonStart == _highlightStartTime;
  }

  Future<void> _loadViewPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _viewMode = (prefs.getInt('viewMode') ?? 0).clamp(0, 1));
    }
  }

  bool _isNoAllowedDateError(String message) {
    final m = message.toLowerCase();
    return m.contains('no allowed date') ||
        m.contains('no allowed dates') ||
        m.contains('nicht erlaubtes datum') ||
        m.contains('not within a school year') ||
        m.contains('nicht in einem schuljahr');
  }

  Future<void> _toggleView() async {
    HapticFeedback.selectionClick();
    setState(() => _viewMode = (_viewMode + 1) % 2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('viewMode', _viewMode);
  }

  Future<void> _fetchHomeworkAndNotes() async {
    if (!demoModeNotifier.value &&
        (_currentSessionId.isEmpty || schoolUrl.isEmpty)) {
      return;
    }
    try {
      final requestAccountId = activeUntisAccountId;
      final account = activeUntisAccount;
      final requestStart = _currentMonday;
      final requestEnd = _currentMonday.add(const Duration(days: 6));
      final requestSchoolUrl = account?.schoolUrl ?? schoolUrl;
      final requestSchoolName = account?.schoolName ?? schoolName;
      final requestSessionId = _currentSessionId;
      final requestPersonId = account?.personId ?? personId;
      final requestPersonType = account?.personType ?? personType;
      if (!demoModeNotifier.value && requestAccountId != null) {
        final cached = await HomeworkService.loadCachedHomeworkAndNotes(
          accountId: requestAccountId,
          startDate: requestStart,
          endDate: requestEnd,
        );
        if (requestAccountId != activeUntisAccountId ||
            _currentMonday != requestStart) {
          return;
        }
        if (cached != null) {
          homeworksNotifier.value = cached['homeworks']!;
          lessonNotesNotifier.value = cached['lessonNotes']!;
        }
      }
      final res = demoModeNotifier.value
          ? DemoModeService.buildHomeworkAndNotes(
              requestStart,
              locale: appLocaleNotifier.value,
            )
          : await HomeworkService.fetchHomeworkAndNotes(
              schoolUrl: requestSchoolUrl,
              schoolName: requestSchoolName,
              sessionId: requestSessionId,
              personId: requestPersonId,
              personType: requestPersonType,
              accountId: requestAccountId,
              account: account == null
                  ? null
                  : WebUntisAccountLogin(
                      accountId: account.id,
                      username: account.username,
                      schoolUrl: account.schoolUrl,
                      schoolName: account.schoolName,
                      personId: account.personId,
                      personType: account.personType,
                    ),
              startDate: requestStart,
              endDate: requestEnd,
            );
      if (requestAccountId != activeUntisAccountId ||
          _currentMonday != requestStart) {
        return;
      }
      homeworksNotifier.value = res['homeworks']!;
      lessonNotesNotifier.value = res['lessonNotes']!;
    } catch (e) {
      debugPrint('Error fetching homework and notes: $e');
    }
  }

  void _onLessonTap(BuildContext context, Map<dynamic, dynamic> lesson) {
    _showLessonDetail(
      context,
      lesson,
      originalTeacher: _originalTeachers[_lessonIdentityOf(lesson)] ?? '',
    );
  }

  Future<void> _onRefresh() => _fetchFullWeek(silent: true);

  String _temporaryLessonKey(Map<dynamic, dynamic> lesson) =>
      '${lesson['id'] ?? lesson['lsid'] ?? ''}-${lesson['date'] ?? ''}-${lesson['startTime'] ?? ''}';

  void _replaceTemporaryLesson(
    Map<dynamic, dynamic> previous,
    Map<dynamic, dynamic> replacement,
  ) {
    final key = _temporaryLessonKey(previous);
    for (final lessons in _weekData.values) {
      final index = lessons.indexWhere(
        (item) =>
            identical(item, previous) ||
            (item is Map && _temporaryLessonKey(item) == key),
      );
      if (index >= 0) lessons[index] = replacement;
    }
    currentWeekDataNotifier.value = Map<int, List<dynamic>>.from(_weekData);
  }

  Future<void> _editLessonTemporarily(Map<dynamic, dynamic> lesson) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final lessonKey = _temporaryLessonKey(lesson);
    _temporaryLessonOriginals.putIfAbsent(
      lessonKey,
      () => Map<dynamic, dynamic>.from(lesson),
    );
    final subject = TextEditingController(
      text: lesson['_subjectShort']?.toString() ?? '',
    );
    final teacher = TextEditingController(
      text: lesson['_teacher']?.toString() ?? '',
    );
    final room = TextEditingController(text: lesson['_room']?.toString() ?? '');
    var cancelled = (lesson['code'] ?? '') == 'cancelled';
    await showUntisDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l.ui('tempEditTitle')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.ui('tempEditDesc')),
                const SizedBox(height: 12),
                TextField(
                  controller: subject,
                  decoration: InputDecoration(labelText: l.ui('subject')),
                ),
                TextField(
                  controller: teacher,
                  decoration: InputDecoration(labelText: l.ui('teacher')),
                ),
                TextField(
                  controller: room,
                  decoration: InputDecoration(labelText: l.ui('room')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.ui('absence')),
                  value: cancelled,
                  onChanged: (value) => setDialogState(() => cancelled = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final original = _temporaryLessonOriginals.remove(lessonKey);
                if (original != null && mounted) {
                  setState(
                    () => _replaceTemporaryLesson(
                      lesson,
                      Map<dynamic, dynamic>.from(original),
                    ),
                  );
                }
                Navigator.pop(dialogContext);
              },
              child: Text(l.ui('reset')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.ui('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (!mounted) return;
                final updated = Map<dynamic, dynamic>.from(lesson);
                updated['_subjectShort'] = subject.text.trim();
                updated['_subjectLong'] = subject.text.trim();
                updated['_teacher'] = teacher.text.trim();
                updated['_room'] = room.text.trim();
                if (cancelled) {
                  updated['code'] = 'cancelled';
                } else if (updated['code'] == 'cancelled') {
                  updated.remove('code');
                }
                setState(() {
                  _replaceTemporaryLesson(lesson, updated);
                });
                Navigator.pop(dialogContext);
              },
              child: Text(l.ui('localSave')),
            ),
          ],
        ),
      ),
    );
    subject.dispose();
    teacher.dispose();
    room.dispose();
  }

  Future<void> _exportTimetableImage() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    try {
      // The on-screen timetable reserves space for the transparent app bar.
      // Temporarily remove that viewport-only padding from the repaint boundary
      // so the saved image starts with the actual timetable content.
      final pixelRatio = MediaQuery.of(
        context,
      ).devicePixelRatio.clamp(1.0, 3.0).toDouble();
      setState(() => _isExportingTimetable = true);
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _timetableExportKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      if (mounted) setState(() => _isExportingTimetable = false);
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) return;
      final result = await FilePicker.saveFile(
        dialogTitle: l.ui('saveTimetableImage'),
        fileName:
            'untisplus-${DateFormat('yyyy-MM-dd').format(_currentMonday)}.png',
        bytes: data.buffer.asUint8List(),
      );
      if (result != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.ui('timetableImageSaved'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.ui('imageExportFailed'))));
      }
    } finally {
      if (mounted && _isExportingTimetable) {
        setState(() => _isExportingTimetable = false);
      }
    }
  }

  Future<void> _updateHomeWidgets(Map<int, List<dynamic>> week) async {
    if (kIsWeb) return;
    final l = AppL10n.of(appLocaleNotifier.value);
    final now = DateTime.now();
    final todayLessons =
        List<dynamic>.from(week[now.weekday - 1] ?? [])
            .whereType<Map>()
            .where(
              (lesson) =>
                  !hiddenSubjectsNotifier.value.contains(
                    lesson['_subjectShort']?.toString() ?? '',
                  ) &&
                  (showCancelledNotifier.value ||
                      lesson['code'] != 'cancelled'),
            )
            .toList(growable: false)
          ..sort(
            (a, b) => _toMinutes(
              (a['startTime'] as int?) ?? 0,
            ).compareTo(_toMinutes((b['startTime'] as int?) ?? 0)),
          );
    String label(dynamic lesson) {
      final subject = lesson['_subjectShort']?.toString();
      return subject?.isNotEmpty == true ? subject! : l.ui('widgetLesson');
    }

    final nowMinutes = now.hour * 60 + now.minute;
    dynamic current;
    for (final lesson in todayLessons) {
      final start = _toMinutes((lesson['startTime'] as int?) ?? 0);
      final end = _toMinutes((lesson['endTime'] as int?) ?? 0);
      if (start <= nowMinutes && nowMinutes < end) {
        current = lesson;
      }
    }
    final schedule = todayLessons
        .take(7)
        .map((lesson) {
          final time = _formatUntisTime(lesson['startTime']?.toString() ?? '');
          return '$time · ${label(lesson)}';
        })
        .join('\n');
    final remaining = current == null
        ? ''
        : l
              .ui('widgetMinutesRemaining')
              .replaceAll(
                '{n}',
                '${(_toMinutes((current['endTime'] as int?) ?? 0) - nowMinutes).clamp(0, 999)}',
              );
    final homework = homeworksNotifier.value
        .where((item) => item['isDone'] != true)
        .take(3)
        .map((item) {
          final subject =
              item['subject'] ?? item['_lesson']?['_subjectShort'] ?? '';
          final text =
              item['text'] ??
              item['homework'] ??
              item['description'] ??
              l.ui('widgetHomeworkItem');
          return '${subject.toString().isEmpty ? '' : '$subject · '}${text.toString()}';
        })
        .join('\n');
    var examSummary = l.ui('widgetNoUpcomingExams');
    try {
      final prefs = await SharedPreferences.getInstance();
      final exams = (prefs.getStringList(_accountDataKey('customExams')) ?? [])
          .map((raw) {
            try {
              return jsonDecode(raw) as Map<String, dynamic>;
            } catch (_) {
              return <String, dynamic>{};
            }
          })
          .where((exam) => exam.isNotEmpty)
          .take(2)
          .map((exam) {
            final subject =
                exam['subject'] ?? exam['subjectName'] ?? l.ui('widgetExam');
            final date = (exam['date'] ?? exam['examDate'] ?? '').toString();
            final formatted = date.length == 8
                ? '${date.substring(6, 8)}.${date.substring(4, 6)}.'
                : '';
            return formatted.isEmpty
                ? subject.toString()
                : '$formatted $subject';
          })
          .toList(growable: false);
      if (exams.isNotEmpty) examSummary = exams.join('\n');
    } catch (_) {}
    try {
      UntisAccount? activeAccount;
      for (final account in untisAccountsNotifier.value) {
        if (account.id == activeUntisAccountId) {
          activeAccount = account;
          break;
        }
      }
      await WidgetService.updateWidgets(
        // A homescreen widget is a "now" surface. Empty values intentionally
        // render as a neutral shell instead of inventing a Freistunde or
        // advertising a lesson that is not currently taking place.
        currentLesson: current == null ? '' : label(current),
        nextLesson: '',
        timeRemaining: remaining,
        dailySchedule: schedule,
        homeworkSummary: homework.isEmpty
            ? l.ui('widgetNoOpenHomework')
            : homework,
        notificationSummary: l.ui('widgetOpenNotifications'),
        examSummary: examSummary,
        accountId: activeUntisAccountId ?? 'active',
        accountLabel: activeAccount?.label ?? schoolName,
        status: DateFormat('HH:mm').format(now),
        locale: appLocaleNotifier.value,
      );
    } catch (_) {
      // A widget update must never block timetable rendering.
    }
  }

  void _onHiddenSubjectsChanged() => setState(() {});

  void _replaceMaterialDayCarouselController(int initialItem) {
    final previous = _materialDayCarouselController;
    _materialDayIndex = initialItem;
    _materialDayCarouselController = CarouselController(
      initialItem: initialItem,
    );
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  void _replaceMaterialWeekCarouselController() {
    final previous = _materialWeekCarouselController;
    _materialWeekIndex = 1;
    _materialWeekCarouselController = CarouselController(initialItem: 1);
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  void _onTimetableSwitchAnimationChanged() {
    if (!mounted) return;
    _carouselAnimController?.stop();
    _dayCarouselAnimController?.stop();
    _replaceMaterialDayCarouselController(_tabController.index + 1);
    _replaceMaterialWeekCarouselController();
    setState(() {
      _carouselOffset = 0;
      _dayCarouselOffset = 0;
      _dayCarouselTargetDay = null;
      _dayCarouselAnimation = null;
      _isWeekCarouselAnimating = false;
      _isDayCarouselAnimating = false;
    });
    unawaited(_prefetchAdjacentWeeks());
  }

  void _onSelectedDayChanged() {
    // A TabBar tap calls TabController.animateTo before its onTap callback.
    // Ignore that temporary controller state: the day carousel owns the
    // visual transition and commits the selected day only when it is finished.
    if (!mounted ||
        _isDayCarouselAnimating ||
        _suppressDayTabControllerRebuild ||
        _tabController.indexIsChanging) {
      return;
    }
    setState(() {});
  }

  void _onDemoModeChanged() {
    if (!mounted) return;
    if (demoModeNotifier.value) {
      _viewingClassId = null;
      _viewingClassName = null;
      _tempSessionId = null;
    }
    _fetchFullWeek();
  }

  // --- Week carousel ---

  DateTime _weekMondayFromDelta(int delta) =>
      _currentMonday.add(Duration(days: 7 * delta));

  Map<int, List<dynamic>>? _getAdjacentWeekData(DateTime monday) {
    return _adjacentWeekCache[_mondayKey(monday)];
  }

  /// Makes adjacent weeks available before the user reaches them. When the
  /// current week came from local storage, [allowNetwork] stays false so an
  /// offline swipe can still reveal the already cached cancellation state
  /// immediately instead of waiting for a new request to finish.
  void _notifyAdjacentWeekCacheChanged() {
    if (!mounted || _adjacentWeekRefreshScheduled) return;
    _adjacentWeekRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adjacentWeekRefreshScheduled = false;
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _prefetchAdjacentWeeks({
    bool allowNetwork = true,
    bool refreshFromDisk = false,
  }) async {
    if (demoModeNotifier.value) {
      for (final delta in [-1, 1, 2]) {
        final monday = _weekMondayFromDelta(delta);
        _adjacentWeekCache[_mondayKey(monday)] = DemoModeService.buildWeek(
          monday,
          locale: appLocaleNotifier.value,
        );
      }
      _notifyAdjacentWeekCacheChanged();
      return;
    }

    final pid = _viewingClassId ?? personId;
    final pType = _viewingClassId != null ? 1 : personType;
    if (pid == 0) return;

    // Disk first: the background updater can refresh an upcoming week while
    // this page is still alive. Reconcile that durable cache before a swipe so
    // cancellations/room changes are visible during the gesture, not only
    // after the new week has been committed or the app has been restarted.
    for (final delta in [-1, 1, 2]) {
      final adjMonday = _weekMondayFromDelta(delta);
      final key = _mondayKey(adjMonday);
      if (!refreshFromDisk && _adjacentWeekCache.containsKey(key)) continue;

      final cached = await _loadWeekFromCache(
        requestPersonId: pid,
        requestPersonType: pType,
        monday: adjMonday,
      );
      if (cached != null && cached.values.any((l) => l.isNotEmpty)) {
        _adjacentWeekCache[key] = cached;
        _notifyAdjacentWeekCacheChanged();
      }
    }

    if (!allowNetwork) return;

    await _fetchMasterData();
    for (final delta in [-1, 1, 2]) {
      final adjMonday = _weekMondayFromDelta(delta);
      final key = _mondayKey(adjMonday);
      if (_adjacentWeekCache.containsKey(key)) continue;
      try {
        DateTime friday = adjMonday.add(const Duration(days: 4));
        int startDate = int.parse(DateFormat('yyyyMMdd').format(adjMonday));
        int endDate = int.parse(DateFormat('yyyyMMdd').format(friday));
        final url = Uri.parse(
          'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
        );
        final response = await http
            .post(
              url,
              headers: {
                "Cookie":
                    "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
                "Content-Type": "application/json",
                "Accept": "application/json",
              },
              body: jsonEncode({
                "id": "week_prefetch",
                "method": "getTimetable",
                "params": {
                  "options": {
                    "element": {"id": pid, "type": pType},
                    "startDate": startDate,
                    "endDate": endDate,
                    "showLsText": true,
                    "showSubstText": true,
                    "showInfo": true,
                    "showBooking": true,
                  },
                },
                "jsonrpc": "2.0",
              }),
            )
            .timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['error'] == null && decoded['result'] != null) {
            final tempWeek = _parseWeekResult(decoded['result']);
            if (tempWeek != null) {
              _adjacentWeekCache[key] = tempWeek;
              await _saveWeekToCache(
                requestPersonId: pid,
                requestPersonType: pType,
                weekData: tempWeek,
                monday: adjMonday,
              );
              _notifyAdjacentWeekCacheChanged();
            }
          }
        }
      } catch (_) {}
    }
  }

  Map<int, List<dynamic>>? _parseWeekResult(dynamic result) {
    if (result is! List) return null;
    final week = _emptyWeekData();
    for (final entry in result) {
      if (entry is! Map) continue;
      final day = entry['date'];
      if (day is! int) continue;
      final dayStr = day.toString();
      if (dayStr.length != 8) continue;
      final date = DateTime.tryParse(
        '${dayStr.substring(0, 4)}-${dayStr.substring(4, 6)}-${dayStr.substring(6, 8)}',
      );
      if (date == null) continue;
      final dayIndex = date.weekday - 1;
      if (dayIndex < 0 || dayIndex > 4) continue;
      final lessonMap = Map<String, dynamic>.from(
        entry.cast<String, dynamic>(),
      );
      _enrichLesson(lessonMap);
      week[dayIndex] = [...week[dayIndex]!, lessonMap];
    }
    for (final i in week.keys) {
      week[i]!.sort((a, b) {
        final aStart = (a['startTime'] as int?) ?? 0;
        final bStart = (b['startTime'] as int?) ?? 0;
        return aStart.compareTo(bStart);
      });
    }
    return week;
  }

  void _enrichLesson(Map<String, dynamic> lesson) {
    final teList = (lesson['te'] as List?) ?? [];
    if (teList.isNotEmpty) {
      final firstTeacher = teList.first as Map?;
      if (firstTeacher != null) {
        final tId = firstTeacher['id'] as int?;
        final rawShort = (firstTeacher['name']?.toString() ?? '').trim();
        final rawFull =
            (firstTeacher['longName']?.toString() ??
                    firstTeacher['name']?.toString() ??
                    '')
                .trim();
        final fromShortMap = tId != null ? _teacherShortMap[tId] : null;
        final fromFullMap = tId != null ? _teacherMap[tId] : null;
        // Keep previously computed values when the master data is not loaded
        // yet (e.g. right after reading a cached week from disk), and fall
        // back to the raw WebUntis fields otherwise.
        final prevShort = (lesson['_teacherShort']?.toString() ?? '').trim();
        final prevFull = (lesson['_teacherFull']?.toString() ?? '').trim();
        final short =
            (fromShortMap ??
                (rawShort.isNotEmpty ? rawShort : null) ??
                (prevShort.isNotEmpty ? prevShort : null)) ??
            '?';
        final full =
            (fromFullMap ??
                (rawFull.isNotEmpty ? rawFull : null) ??
                (prevFull.isNotEmpty ? prevFull : null) ??
                (lesson['_teacher']?.toString().trim().isNotEmpty == true
                    ? lesson['_teacher'].toString().trim()
                    : null)) ??
            '?';
        lesson['_teacherShort'] = short;
        lesson['_teacherFull'] = full;
        lesson['_teacher'] = showFullTeacherNamesNotifier.value ? full : short;
      }
    }
    final suList = (lesson['su'] as List?) ?? [];
    if (suList.isNotEmpty) {
      final firstSubject = suList.first as Map?;
      if (firstSubject != null) {
        final sId = firstSubject['id'] as int?;
        lesson['_subjectShort'] = sId != null
            ? (_subjectShortMap[sId] ??
                  (firstSubject['name']?.toString() ?? '?'))
            : '?';
        lesson['_subjectLong'] = sId != null
            ? (_subjectLong[sId] ??
                  (firstSubject['longName']?.toString() ??
                      firstSubject['name']?.toString() ??
                      '?'))
            : '?';
      }
    }
    final rawRo = lesson['ro'];
    final roList = rawRo is List
        ? rawRo
        : rawRo is Map
        ? [rawRo]
        : <dynamic>[];
    if (roList.isNotEmpty) {
      final names = roList
          .map((ro) {
            final rId = (ro as Map)['id'] as int?;
            return rId != null
                ? (_roomMap[rId] ?? (ro['name']?.toString() ?? '?'))
                : (ro['name']?.toString() ?? '?');
          })
          .where((name) => name != '?')
          .toSet()
          .toList();
      lesson['_room'] = names.isNotEmpty ? names.join(', ') : '?';
    }
  }

  /// Re-runs [_enrichLesson] over every lesson of a week map so the displayed
  /// teacher name follows the current [showFullTeacherNamesNotifier] setting.
  /// Lessons that are not plain string-keyed maps (e.g. locally edited ones)
  /// are left untouched.
  void _reEnrichWeek(Map<int, List<dynamic>> week) {
    for (final list in week.values) {
      for (final l in list) {
        if (l is Map<String, dynamic>) _enrichLesson(l);
      }
    }
  }

  void _onTeacherNameModeChanged() {
    _reEnrichWeek(_weekData);
    for (final week in _adjacentWeekCache.values) {
      _reEnrichWeek(week);
    }
    _republishWeekDataAfterEnrichment();
  }

  void _onDaySpanChanged() {
    if (mounted) setState(() {});
  }

  /// Pushes the (possibly re-enriched) [_weekData] to the notifier and rebuilds
  /// the timetable so the teacher-name display setting is reflected.
  void _republishWeekDataAfterEnrichment() {
    currentWeekDataNotifier.value = Map<int, List<dynamic>>.from(_weekData);
    if (mounted) setState(() {});
  }

  Widget _buildAdjacentWeekView(int direction) {
    final adjMonday = _weekMondayFromDelta(direction);
    final cached = _getAdjacentWeekData(adjMonday);
    if (cached != null) {
      if (_viewMode == 1) {
        return _buildWeekView(monday: adjMonday, weekData: cached);
      } else {
        final dayIndex = direction > 0 ? 0 : 4;
        return _buildDayContentView(
          dayIndex,
          monday: adjMonday,
          weekData: cached,
        );
      }
    }
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 8),
          Text(
            '${l.timetableTitle} …',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // --- Timetable switch animation styles ---

  Widget _buildTimetableSwitcher() {
    switch (timetableSwitchAnimationNotifier.value) {
      case 1:
        return _buildMaterialCarouselSwitcher();
      case 2:
        return _buildDepthCarouselSwitcher();
      case 0:
      default:
        // Keep the original switcher as the exact default behavior.
        return _buildWeekCarousel();
    }
  }

  Widget _buildMaterialCarouselSwitcher() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return _viewMode == 1
            ? _buildMaterialWeekCarousel(width)
            : _buildMaterialDayCarousel(width);
      },
    );
  }

  Widget _materialCarouselItem({
    required Widget child,
    required String keyName,
  }) {
    return KeyedSubtree(
      key: ValueKey(keyName),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 120) return child;

          // CarouselView compresses neighbouring items down to its
          // shrinkExtent. The timetable still needs a regular viewport for
          // layout; clip that viewport to create the narrow visual preview.
          return ClipRect(
            child: OverflowBox(
              minWidth: 320,
              maxWidth: 320,
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterialWeekCarousel(double width) {
    final controller = _materialWeekCarouselController ??= CarouselController(
      initialItem: 1,
    );
    // Keep a visible neighbour and let edge items collapse substantially.
    // This makes the official Material 3 uncontained carousel feel distinct
    // from a regular page swipe while retaining the timetable's full gesture
    // and index semantics.
    final itemExtent = width <= 0 ? 1.0 : math.max(1.0, width * 0.88);
    final shrinkExtent = math.max(56.0, itemExtent * 0.16);

    final children = <Widget>[
      _materialCarouselItem(
        keyName: 'm3-week-prev-${_mondayKey(_currentMonday)}',
        child: _buildAdjacentWeekView(-1),
      ),
      _materialCarouselItem(
        keyName: 'm3-week-current-${_mondayKey(_currentMonday)}',
        child: _buildWeekView(),
      ),
      _materialCarouselItem(
        keyName: 'm3-week-next-${_mondayKey(_currentMonday)}',
        child: _buildAdjacentWeekView(1),
      ),
    ];

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth != 0 ||
            notification.metrics.axis != Axis.horizontal) {
          return false;
        }
        if (notification is ScrollStartNotification) {
          unawaited(
            _prefetchAdjacentWeeks(allowNetwork: false, refreshFromDisk: true),
          );
          return false;
        }
        if (notification is! ScrollEndNotification) return false;
        final index = controller.hasClients
            ? controller.leadingItem.clamp(0, 2).toInt()
            : _materialWeekIndex;
        _materialWeekIndex = index;
        _commitMaterialWeekIndex(index);
        return false;
      },
      child: CarouselView(
        key: const ValueKey('material-week-timetable-carousel'),
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemExtent: itemExtent,
        shrinkExtent: shrinkExtent,
        itemSnapping: true,
        enableSplash: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        itemClipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        onIndexChanged: (index) => _materialWeekIndex = index,
        children: children,
      ),
    );
  }

  Widget _buildMaterialDayCarousel(double width) {
    final currentDay = _tabController.index.clamp(0, 4).toInt();
    final controller = _materialDayCarouselController ??= CarouselController(
      initialItem: currentDay + 1,
    );
    if (_materialDayIndex < 0 || _materialDayIndex > 6) {
      _materialDayIndex = currentDay + 1;
    }

    Widget dayForItem(int item) {
      if (item == 0) {
        final monday = _weekMondayFromDelta(-1);
        final cached = _getAdjacentWeekData(monday);
        if (cached != null) {
          return _buildDayContentView(4, monday: monday, weekData: cached);
        }
        return _buildAdjacentWeekView(-1);
      }
      if (item == 6) {
        final monday = _weekMondayFromDelta(1);
        final cached = _getAdjacentWeekData(monday);
        if (cached != null) {
          return _buildDayContentView(0, monday: monday, weekData: cached);
        }
        return _buildAdjacentWeekView(1);
      }
      return _buildDayContentView(item - 1);
    }

    // Keep a visible neighbour and let edge items collapse substantially.
    // This makes the official Material 3 uncontained carousel feel distinct
    // from a regular page swipe while retaining the timetable's full gesture
    // and index semantics.
    final itemExtent = width <= 0 ? 1.0 : math.max(1.0, width * 0.88);
    final shrinkExtent = math.max(56.0, itemExtent * 0.16);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth != 0 ||
            notification.metrics.axis != Axis.horizontal) {
          return false;
        }
        if (notification is ScrollStartNotification) {
          unawaited(
            _prefetchAdjacentWeeks(allowNetwork: false, refreshFromDisk: true),
          );
          return false;
        }
        if (notification is! ScrollEndNotification) return false;
        final index = controller.hasClients
            ? controller.leadingItem.clamp(0, 6).toInt()
            : _materialDayIndex;
        _materialDayIndex = index;
        _commitMaterialDayIndex(index);
        return false;
      },
      child: CarouselView(
        key: const ValueKey('day-timetable-carousel'),
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemExtent: itemExtent,
        shrinkExtent: shrinkExtent,
        itemSnapping: true,
        enableSplash: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        itemClipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        onIndexChanged: (index) => _materialDayIndex = index,
        children: List<Widget>.generate(
          7,
          (index) => _materialCarouselItem(
            keyName: 'm3-day-${_mondayKey(_currentMonday)}-$index',
            child: dayForItem(index),
          ),
        ),
      ),
    );
  }

  void _commitMaterialDayIndex(int index) {
    if (!mounted || timetableSwitchAnimationNotifier.value != 1) return;
    final normalized = index.clamp(0, 6).toInt();
    final currentItem = _tabController.index + 1;
    if (normalized == currentItem) return;

    if (normalized >= 1 && normalized <= 5) {
      final targetDay = normalized - 1;
      _suppressDayTabControllerRebuild = true;
      try {
        _tabController.animateTo(targetDay, duration: Duration.zero);
      } finally {
        _suppressDayTabControllerRebuild = false;
      }
      _materialDayIndex = normalized;
      setState(() {});
      HapticFeedback.selectionClick();
      return;
    }

    final weekDelta = normalized == 0 ? -1 : 1;
    final newMonday = _currentMonday.add(Duration(days: weekDelta * 7));
    final cached = _adjacentWeekCache[_mondayKey(newMonday)];
    final targetDay = normalized == 0 ? 4 : 0;
    setState(() {
      _currentMonday = newMonday;
      if (cached != null) {
        _weekData = cached;
        _showingCachedWeek = true;
        _loading = false;
      }
    });
    _suppressDayTabControllerRebuild = true;
    try {
      _tabController.animateTo(targetDay, duration: Duration.zero);
    } finally {
      _suppressDayTabControllerRebuild = false;
    }
    _replaceMaterialDayCarouselController(targetDay + 1);
    _replaceMaterialWeekCarouselController();
    HapticFeedback.selectionClick();
    unawaited(_fetchFullWeek());
    unawaited(_prefetchAdjacentWeeks());
  }

  void _commitMaterialWeekIndex(int index) {
    if (!mounted || timetableSwitchAnimationNotifier.value != 1) return;
    final normalized = index.clamp(0, 2).toInt();
    if (normalized == 1) return;

    final weekDelta = normalized == 0 ? -1 : 1;
    final newMonday = _currentMonday.add(Duration(days: weekDelta * 7));
    final cached = _adjacentWeekCache[_mondayKey(newMonday)];
    final targetDay = normalized == 0 ? 4 : 0;
    setState(() {
      _currentMonday = newMonday;
      if (cached != null) {
        _weekData = cached;
        _showingCachedWeek = true;
        _loading = false;
      }
    });
    _suppressDayTabControllerRebuild = true;
    try {
      _tabController.animateTo(targetDay, duration: Duration.zero);
    } finally {
      _suppressDayTabControllerRebuild = false;
    }
    _replaceMaterialWeekCarouselController();
    _replaceMaterialDayCarouselController(targetDay + 1);
    HapticFeedback.selectionClick();
    unawaited(_fetchFullWeek());
    unawaited(_prefetchAdjacentWeeks());
  }

  Widget _buildDepthCarouselSwitcher() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (_viewMode == 1) {
          return _buildDepthWeekCarousel(width);
        }
        return _buildDepthDayCarousel(width);
      },
    );
  }

  Widget _depthPage({
    required Widget child,
    required double x,
    required double scale,
    required double opacity,
  }) {
    return Transform.translate(
      offset: Offset(x, 0),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Widget _buildDepthWeekCarousel(double width) {
    final offset = _carouselOffset.clamp(-width, width).toDouble();
    final progress = width <= 0 ? 0.0 : (offset.abs() / width).clamp(0.0, 1.0);

    final carousel = ClipRect(
      child: Stack(
        children: [
          if (offset > 0)
            _depthPage(
              x: -width + offset,
              scale: 0.92 + (0.08 * progress),
              opacity: 0.32 + (0.68 * progress),
              child: SizedBox(width: width, child: _buildAdjacentWeekView(-1)),
            ),
          if (offset < 0)
            _depthPage(
              x: width + offset,
              scale: 0.92 + (0.08 * progress),
              opacity: 0.32 + (0.68 * progress),
              child: SizedBox(width: width, child: _buildAdjacentWeekView(1)),
            ),
          _depthPage(
            x: offset,
            scale: 1.0 - (0.04 * progress),
            opacity: 1.0 - (0.18 * progress),
            child: SizedBox(width: width, child: _buildWeekView()),
          ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onWeekCarouselDragStart,
      onHorizontalDragUpdate: _onWeekCarouselDragUpdate,
      onHorizontalDragEnd: _onWeekCarouselDragEnd,
      child: carousel,
    );
  }

  Widget _buildDepthDayCarousel(double width) {
    final dayIndex = _tabController.index.clamp(0, 4).toInt();

    Widget dayAt(int index) {
      if (index >= 0 && index < 5) return _buildDayContentView(index);
      final direction = index < 0 ? -1 : 1;
      final monday = _weekMondayFromDelta(direction);
      final cached = _getAdjacentWeekData(monday);
      if (cached != null) {
        return _buildDayContentView(
          index < 0 ? 4 : 0,
          monday: monday,
          weekData: cached,
        );
      }
      return _buildAdjacentWeekView(direction);
    }

    final targetDay = _dayCarouselTargetDay;
    final previousIndex = targetDay != null && targetDay < dayIndex
        ? targetDay
        : dayIndex - 1;
    final nextIndex = targetDay != null && targetDay > dayIndex
        ? targetDay
        : dayIndex + 1;

    final currentPage = SizedBox(width: width, child: dayAt(dayIndex));
    final previousPage = targetDay == null || targetDay < dayIndex
        ? SizedBox(width: width, child: dayAt(previousIndex))
        : null;
    final nextPage = targetDay == null || targetDay > dayIndex
        ? SizedBox(width: width, child: dayAt(nextIndex))
        : null;

    Widget buildPages(double rawOffset) {
      final offset = rawOffset.clamp(-width, width).toDouble();
      final progress = width <= 0
          ? 0.0
          : (offset.abs() / width).clamp(0.0, 1.0);
      return ClipRect(
        child: Stack(
          children: [
            if (offset > 0 && previousPage != null)
              _depthPage(
                x: -width + offset,
                scale: 0.92 + (0.08 * progress),
                opacity: 0.32 + (0.68 * progress),
                child: previousPage,
              ),
            if (offset < 0 && nextPage != null)
              _depthPage(
                x: width + offset,
                scale: 0.92 + (0.08 * progress),
                opacity: 0.32 + (0.68 * progress),
                child: nextPage,
              ),
            _depthPage(
              x: offset,
              scale: 1.0 - (0.04 * progress),
              opacity: 1.0 - (0.18 * progress),
              child: currentPage,
            ),
          ],
        ),
      );
    }

    final animation = _dayCarouselAnimation;
    final pages = _isDayCarouselAnimating && animation != null
        ? AnimatedBuilder(
            animation: animation,
            builder: (context, _) => buildPages(animation.value),
          )
        : buildPages(_dayCarouselOffset);

    return GestureDetector(
      key: const ValueKey('day-timetable-carousel'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onDayCarouselDragStart,
      onHorizontalDragUpdate: _onDayCarouselDragUpdate,
      onHorizontalDragEnd: _onDayCarouselDragEnd,
      child: pages,
    );
  }

  // --- Week carousel ---

  Widget _buildWeekCarousel() {
    final carousel = LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final offset = _carouselOffset.clamp(-w, w);

        return ClipRect(
          child: Stack(
            children: [
              if (offset > 0)
                Transform.translate(
                  // Keep the adjacent week exactly one viewport away.  This
                  // lets it meet the current week without a visible jump
                  // when the animation hands over to the new data.
                  offset: Offset(-w + offset, 0),
                  child: SizedBox(width: w, child: _buildAdjacentWeekView(-1)),
                ),
              if (offset < 0)
                Transform.translate(
                  offset: Offset(w + offset, 0),
                  child: SizedBox(width: w, child: _buildAdjacentWeekView(1)),
                ),
              Transform.translate(
                offset: Offset(offset, 0),
                child: SizedBox(
                  width: w,
                  child: KeyedSubtree(
                    key: ValueKey(
                      'carousel-${DateFormat('yyyyMMdd').format(_currentMonday)}',
                    ),
                    child: _viewMode == 1
                        ? _buildWeekView()
                        : _buildDayCarousel(w),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    // The weekly grid owns horizontal swipes again. The day carousel uses its
    // own gesture handler, while a vertical drag continues to reach the
    // scrollable timetable body.
    if (_viewMode != 1) return carousel;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onWeekCarouselDragStart,
      onHorizontalDragUpdate: _onWeekCarouselDragUpdate,
      onHorizontalDragEnd: _onWeekCarouselDragEnd,
      child: carousel,
    );
  }

  Widget _buildDayCarousel(double width) {
    final dayIndex = _tabController.index.clamp(0, 4).toInt();

    Widget dayAt(int index) {
      if (index >= 0 && index < 5) return _buildDayContentView(index);
      final direction = index < 0 ? -1 : 1;
      final monday = _weekMondayFromDelta(direction);
      final cached = _getAdjacentWeekData(monday);
      if (cached != null) {
        return _buildDayContentView(
          index < 0 ? 4 : 0,
          monday: monday,
          weekData: cached,
        );
      }
      return _buildAdjacentWeekView(direction);
    }

    final targetDay = _dayCarouselTargetDay;
    final previousIndex = targetDay != null && targetDay < dayIndex
        ? targetDay
        : dayIndex - 1;
    final nextIndex = targetDay != null && targetDay > dayIndex
        ? targetDay
        : dayIndex + 1;

    // Build the expensive timetable grids once. During a programmatic date-tab
    // animation only the cheap Transform widgets below are rebuilt.
    final currentPage = SizedBox(width: width, child: dayAt(dayIndex));
    final previousPage = targetDay == null || targetDay < dayIndex
        ? SizedBox(width: width, child: dayAt(previousIndex))
        : null;
    final nextPage = targetDay == null || targetDay > dayIndex
        ? SizedBox(width: width, child: dayAt(nextIndex))
        : null;

    Widget buildPages(double rawOffset) {
      final offset = rawOffset.clamp(-width, width).toDouble();
      return ClipRect(
        child: Stack(
          children: [
            if (offset > 0 && previousPage != null)
              Transform.translate(
                offset: Offset(-width + offset, 0),
                child: previousPage,
              ),
            if (offset < 0 && nextPage != null)
              Transform.translate(
                offset: Offset(width + offset, 0),
                child: nextPage,
              ),
            Transform.translate(offset: Offset(offset, 0), child: currentPage),
          ],
        ),
      );
    }

    final animation = _dayCarouselAnimation;
    final pages = _isDayCarouselAnimating && animation != null
        ? AnimatedBuilder(
            animation: animation,
            builder: (context, _) => buildPages(animation.value),
          )
        : buildPages(_dayCarouselOffset);

    return GestureDetector(
      key: const ValueKey('day-timetable-carousel'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onDayCarouselDragStart,
      onHorizontalDragUpdate: _onDayCarouselDragUpdate,
      onHorizontalDragEnd: _onDayCarouselDragEnd,
      child: pages,
    );
  }

  void _onDayCarouselDragStart(DragStartDetails details) {
    if (_isDayCarouselAnimating || _isWeekCarouselAnimating) return;
    setState(() {
      _dayCarouselOffset = 0;
      _dayCarouselTargetDay = null;
    });
    unawaited(
      _prefetchAdjacentWeeks(allowNetwork: false, refreshFromDisk: true),
    );
  }

  void _onDayCarouselDragUpdate(DragUpdateDetails details) {
    if (_isDayCarouselAnimating || _isWeekCarouselAnimating) return;
    final maxOffset = MediaQuery.of(context).size.width * 0.92;
    setState(() {
      _dayCarouselOffset = (_dayCarouselOffset + details.delta.dx)
          .clamp(-maxOffset, maxOffset)
          .toDouble();
    });
  }

  void _onDayCarouselDragEnd(DragEndDetails details) {
    if (_isDayCarouselAnimating || _isWeekCarouselAnimating) return;
    final width = context.findRenderObject() != null
        ? (context.findRenderObject()! as RenderBox).size.width
        : 400.0;
    final threshold = width * 0.25;
    final velocity = details.primaryVelocity ?? 0;

    // A fast fling advances exactly one page in its drag direction. If the
    // finger has been pulled back across the starting point, the sign check
    // deliberately wins and the current day snaps back into place.
    if (_dayCarouselOffset < -threshold ||
        (_dayCarouselOffset < 0 && velocity < -400)) {
      _animateDayCarouselTo(1, width);
    } else if (_dayCarouselOffset > threshold ||
        (_dayCarouselOffset > 0 && velocity > 400)) {
      _animateDayCarouselTo(-1, width);
    } else {
      _animateDayCarouselTo(0, width);
    }
  }

  void _animateDayTabTo(int targetDay) {
    final currentDay = _tabController.index;
    if (targetDay == currentDay ||
        _isDayCarouselAnimating ||
        _isWeekCarouselAnimating) {
      return;
    }

    if (timetableSwitchAnimationNotifier.value == 1) {
      final controller = _materialDayCarouselController ??= CarouselController(
        initialItem: currentDay + 1,
      );
      _materialDayIndex = currentDay + 1;
      final targetItem = targetDay + 1;
      if (controller.hasClients) {
        unawaited(
          controller
              .animateToItem(
                targetItem,
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeInOutCubicEmphasized,
              )
              .then((_) {
                if (mounted) _commitMaterialDayIndex(targetItem);
              }),
        );
      } else {
        _commitMaterialDayIndex(targetItem);
      }
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 400.0;
    _animateDayCarouselTo(
      targetDay > currentDay ? 1 : -1,
      width,
      targetDay: targetDay,
    );
  }

  void _onDayTabBarTap(int targetDay) {
    if (_isDayCarouselAnimating || _isWeekCarouselAnimating) return;
    // Tapping the already-selected date must remain a no-op. For a real tab
    // change TabBar has already started animateTo(), so indexIsChanging is true.
    if (!_tabController.indexIsChanging && _tabController.index == targetDay) {
      return;
    }

    // TabBar has already started changing the controller when this callback
    // runs. Restore the previous day synchronously so the heavy timetable grid
    // never renders the target once before our own carousel begins.
    final previousDay = _tabController.index == targetDay
        ? _tabController.previousIndex
        : _tabController.index;
    if (previousDay == targetDay) return;

    _suppressDayTabControllerRebuild = true;
    try {
      _tabController.animateTo(previousDay, duration: Duration.zero);
    } finally {
      _suppressDayTabControllerRebuild = false;
    }
    _animateDayTabTo(targetDay);
  }

  void _animateDayCarouselTo(int direction, double width, {int? targetDay}) {
    if (_isDayCarouselAnimating || _isWeekCarouselAnimating) return;
    final dayBeforeAnimation = _tabController.index;
    final mondayBeforeAnimation = _currentMonday;
    final resolvedTargetDay = targetDay ?? dayBeforeAnimation + direction;
    setState(() {
      _isDayCarouselAnimating = true;
      _dayCarouselTargetDay = direction == 0 ? null : resolvedTargetDay;
    });
    _dayCarouselAnimController?.dispose();
    _dayCarouselAnimController = AnimationController(
      duration: Duration(milliseconds: direction == 0 ? 220 : 300),
      vsync: this,
    );
    final target = direction == 0 ? 0.0 : -direction * width;
    final animation = Tween<double>(begin: _dayCarouselOffset, end: target)
        .animate(
          CurvedAnimation(
            parent: _dayCarouselAnimController!,
            curve: Curves.easeOutCubic,
          ),
        );
    _dayCarouselAnimation = animation;
    _dayCarouselAnimController!.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;

      if (direction != 0) {
        if (resolvedTargetDay >= 0 && resolvedTargetDay < 5) {
          _tabController.animateTo(resolvedTargetDay, duration: Duration.zero);
        } else {
          final weekDirection = resolvedTargetDay < 0 ? -1 : 1;
          final newMonday = mondayBeforeAnimation.add(
            Duration(days: 7 * weekDirection),
          );
          final cached = _adjacentWeekCache[_mondayKey(newMonday)];
          setState(() {
            _currentMonday = newMonday;
            if (cached != null) {
              _weekData = cached;
              _showingCachedWeek = true;
              _loading = false;
            }
          });
          _tabController.animateTo(
            resolvedTargetDay < 0 ? 4 : 0,
            duration: Duration.zero,
          );
          _fetchFullWeek();
          _prefetchAdjacentWeeks();
        }
        HapticFeedback.selectionClick();
      }
      setState(() {
        _dayCarouselOffset = 0;
        _dayCarouselTargetDay = null;
        _dayCarouselAnimation = null;
        _isDayCarouselAnimating = false;
      });
    });
    _dayCarouselAnimController!.forward();
  }

  void _onWeekCarouselDragStart(DragStartDetails details) {
    if (_isWeekCarouselAnimating || _isDayCarouselAnimating) return;
    setState(() => _carouselOffset = 0);
    unawaited(
      _prefetchAdjacentWeeks(allowNetwork: false, refreshFromDisk: true),
    );
  }

  void _onWeekCarouselDragUpdate(DragUpdateDetails details) {
    if (_isWeekCarouselAnimating || _isDayCarouselAnimating) return;
    final maxOffset = MediaQuery.of(context).size.width * 0.92;
    setState(() {
      _carouselOffset = (_carouselOffset + details.delta.dx)
          .clamp(-maxOffset, maxOffset)
          .toDouble();
    });
  }

  void _onWeekCarouselDragEnd(DragEndDetails details) {
    if (_isWeekCarouselAnimating || _isDayCarouselAnimating) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 400.0;
    final velocity = details.primaryVelocity ?? 0;
    final threshold = width * 0.25;
    if (_carouselOffset < -threshold ||
        (_carouselOffset < 0 && velocity < -400)) {
      _animateCarouselTo(-1, width);
    } else if (_carouselOffset > threshold ||
        (_carouselOffset > 0 && velocity > 400)) {
      _animateCarouselTo(1, width);
    } else {
      _animateCarouselTo(0, width);
    }
  }

  void _animateCarouselTo(int direction, double width) {
    if (_isWeekCarouselAnimating) return;
    final mondayBeforeAnimation = _currentMonday;
    _isWeekCarouselAnimating = true;
    if (direction == 0) {
      _carouselAnimController?.dispose();
      _carouselAnimController = AnimationController(
        duration: const Duration(milliseconds: 250),
        vsync: this,
      );
      final anim = Tween<double>(begin: _carouselOffset, end: 0).animate(
        CurvedAnimation(
          parent: _carouselAnimController!,
          curve: Curves.easeOutCubic,
        ),
      );
      _carouselAnimController!.addListener(() {
        if (!mounted) return;
        setState(() => _carouselOffset = anim.value);
      });
      _carouselAnimController!.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _carouselOffset = 0;
          });
          _isWeekCarouselAnimating = false;
        }
      });
      _carouselAnimController!.forward();
      return;
    }

    // Finish exactly one viewport away so the incoming week is already at
    // x = 0 when its data becomes the active week.
    final target = direction * width;
    _carouselAnimController?.dispose();
    _carouselAnimController = AnimationController(
      duration: const Duration(milliseconds: 340),
      vsync: this,
    );
    final anim = Tween<double>(begin: _carouselOffset, end: target).animate(
      CurvedAnimation(
        parent: _carouselAnimController!,
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );
    _carouselAnimController!.addListener(() {
      if (!mounted) return;
      setState(() => _carouselOffset = anim.value);
    });
    _carouselAnimController!.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        final newMonday = direction > 0
            ? mondayBeforeAnimation.subtract(const Duration(days: 7))
            : mondayBeforeAnimation.add(const Duration(days: 7));
        final cacheKey = _mondayKey(newMonday);
        final cached = _adjacentWeekCache[cacheKey];
        setState(() {
          _currentMonday = newMonday;
          if (cached != null) {
            _weekData = cached;
            _showingCachedWeek = true;
            _loading = false;
          }
          _carouselOffset = 0;
          // Synchronize TabController index when jumping weeks
          if (direction < 0) {
            _tabController.animateTo(0, duration: Duration.zero);
          } else {
            _tabController.animateTo(4, duration: Duration.zero);
          }
        });
        _isWeekCarouselAnimating = false;
        HapticFeedback.selectionClick();
        _fetchFullWeek();
        _prefetchAdjacentWeeks();
      }
    });
    _carouselAnimController!.forward();
  }

  @override
  void dispose() {
    hiddenSubjectsNotifier.removeListener(_onHiddenSubjectsChanged);
    subjectColorsNotifier.removeListener(_onHiddenSubjectsChanged);
    monochromeLessonsNotifier.removeListener(_onHiddenSubjectsChanged);
    monochromeLessonColorNotifier.removeListener(_onHiddenSubjectsChanged);
    showCancelledNotifier.removeListener(_onHiddenSubjectsChanged);
    timetableSwitchAnimationNotifier.removeListener(
      _onTimetableSwitchAnimationChanged,
    );
    demoModeNotifier.removeListener(_onDemoModeChanged);
    pendingTimetableActionNotifier.removeListener(_onPendingTimetableAction);
    lessonCardStyleNotifier.removeListener(_onHiddenSubjectsChanged);
    glowEffectsEnabledNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonBlurEnabledNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonBlurAmountNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonCardOpacityNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonBorderRadiusNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonAccentStyleNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonShowTeacherNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonShowRoomNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonCompactModeNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonDimPastNotifier.removeListener(_onHiddenSubjectsChanged);
    lessonCancelledPatternNotifier.removeListener(_onHiddenSubjectsChanged);
    showFullTeacherNamesNotifier.removeListener(_onTeacherNameModeChanged);
    timetableDaySpanNotifier.removeListener(_onDaySpanChanged);
    _progressiveNotificationTimer?.cancel();
    _tabController
      ..removeListener(_onSelectedDayChanged)
      ..dispose();
    _carouselAnimController?.dispose();
    _dayCarouselAnimController?.dispose();
    _materialDayCarouselController?.dispose();
    _materialWeekCarouselController?.dispose();
    _highlightTimer?.cancel();
    _highlightController?.dispose();
    _cacheRefreshController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WeeklyTimetablePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (sessionID.isNotEmpty && _loading) {
      _fetchFullWeek();
    }
  }

  static int _toMinutes(int t) => (t ~/ 100) * 60 + (t % 100);

  static String _formatMinutes(int minutes) {
    final hh = minutes ~/ 60;
    final mm = minutes % 60;
    return '$hh:${mm.toString().padLeft(2, '0')}';
  }

  static int _lessonStartMinutes(Map<dynamic, dynamic> lesson) =>
      _toMinutes((lesson['startTime'] as int?) ?? 800);

  static int _lessonEndMinutes(Map<dynamic, dynamic> lesson) => _toMinutes(
    (lesson['endTime'] as int?) ??
        (((lesson['startTime'] as int?) ?? 800) + 45),
  );

  static String _norm(dynamic value) => value?.toString().trim() ?? '';

  /// Returns a Material icon glyph for common German/international school
  /// subjects, or null when the subject is unrecognized.
  static IconData? _subjectIconFor(String sk, String subject) {
    final key = (sk.isNotEmpty ? sk : subject).toLowerCase().trim();
    if (key.isEmpty) return null;

    // Exact short-name matches for common German abbreviations.
    switch (key) {
      case 'ma':
      case 'mat':
      case 'mathe':
      case 'math':
        return Icons.calculate_rounded;
      case 'de':
      case 'deu':
      case 'deutsch':
      case 'german':
        return Icons.abc_rounded;
      case 'en':
      case 'eng':
      case 'engl':
      case 'englisch':
      case 'english':
        return Icons.translate_rounded;
      case 'fr':
      case 'fre':
      case 'fran':
      case 'franz':
      case 'französisch':
        return Icons.translate_rounded;
      case 'la':
      case 'lat':
      case 'lati':
      case 'latein':
      case 'latin':
        return Icons.menu_book_rounded;
      case 'ph':
      case 'phy':
      case 'physik':
      case 'physics':
        return Icons.science_rounded;
      case 'ch':
      case 'chem':
      case 'chemie':
      case 'chemistry':
        return Icons.science_rounded;
      case 'bi':
      case 'bio':
      case 'biologie':
      case 'biology':
        return Icons.eco_rounded;
      case 'geo':
      case 'geog':
      case 'geographie':
      case 'geography':
        return Icons.public_rounded;
      case 'ge':
      case 'ges':
      case 'gesc':
      case 'geschichte':
      case 'history':
        return Icons.history_edu_rounded;
      case 'ek':
      case 'ev':
      case 'eth':
      case 'phil':
      case 'relig':
      case 'religion':
      case 'ethik':
      case 'philosophie':
        return Icons.auto_stories_rounded;
      case 'inf':
      case 'it':
      case 'info':
      case 'informatik':
      case 'comp':
      case 'cs':
        return Icons.computer_rounded;
      case 'mu':
      case 'mus':
      case 'musik':
      case 'music':
        return Icons.music_note_rounded;
      case 'ku':
      case 'kunst':
      case 'art':
        return Icons.palette_rounded;
      case 'sp':
      case 'sport':
      case 'pe':
        return Icons.sports_soccer_rounded;
      case 'wl':
      case 'pol':
      case 'poli':
      case 'soz':
      case 'politik':
        return Icons.groups_rounded;
      case 'sy':
      case 'psych':
      case 'psychologie':
        return Icons.psychology_rounded;
      case 'nw':
      case 'nwv':
      case 'ne':
        return Icons.biotech_rounded;
      case 'kr':
      case 'ko':
      case 'kl':
      case 'klassenstunde':
        return Icons.forum_rounded;
      case 'prak':
      case 'pd':
      case 'praktikum':
        return Icons.school_rounded;
    }

    // Substring fallbacks for longer subject names.
    if (key.contains('math')) return Icons.calculate_rounded;
    if (key.contains('deutsch')) return Icons.abc_rounded;
    if (key.contains('englisch') || key.contains('english')) {
      return Icons.translate_rounded;
    }
    if (key.contains('franz')) return Icons.translate_rounded;
    if (key.contains('latein')) return Icons.menu_book_rounded;
    if (key.contains('physik')) return Icons.science_rounded;
    if (key.contains('chemie') || key.contains('chem')) {
      return Icons.science_rounded;
    }
    if (key.contains('biologie') || key.contains('natur')) {
      return Icons.eco_rounded;
    }
    if (key.contains('geographie')) return Icons.public_rounded;
    if (key.contains('geschichte')) return Icons.history_edu_rounded;
    if (key.contains('religion') ||
        key.contains('ethik') ||
        key.contains('evangelisch') ||
        key.contains('katholisch')) {
      return Icons.auto_stories_rounded;
    }
    if (key.contains('informatik') || key.contains('computer')) {
      return Icons.computer_rounded;
    }
    if (key.contains('musik')) return Icons.music_note_rounded;
    if (key.contains('kunst')) return Icons.palette_rounded;
    if (key.contains('sport')) return Icons.sports_soccer_rounded;
    if (key.contains('politik') || key.contains('sozialkunde')) {
      return Icons.groups_rounded;
    }
    if (key.contains('psychologie') || key.contains('psycho')) {
      return Icons.psychology_rounded;
    }
    return null;
  }

  bool _isSameConsecutiveLessonBlock(
    Map<dynamic, dynamic> a,
    Map<dynamic, dynamic> b,
  ) {
    final sameSubjectShort =
        _norm(a['_subjectShort']) == _norm(b['_subjectShort']);
    final sameSubjectLong =
        _norm(a['_subjectLong']) == _norm(b['_subjectLong']);
    final sameTeacher = _norm(a['_teacher']) == _norm(b['_teacher']);
    final sameRoom = _norm(a['_room']) == _norm(b['_room']);
    final sameCode = _norm(a['code']) == _norm(b['code']);
    final sameDate = _norm(a['date']) == _norm(b['date']);

    if (!(sameSubjectShort &&
        sameSubjectLong &&
        sameTeacher &&
        sameRoom &&
        sameCode &&
        sameDate)) {
      return false;
    }

    final aEnd = _lessonEndMinutes(a);
    final bStart = _lessonStartMinutes(b);
    final gap = bStart - aEnd;

    // Treat short breaks between identical consecutive lessons as one block.
    return gap >= 0 && gap <= 10;
  }

  List<dynamic> _mergeConsecutiveLessons(List<dynamic> lessons) {
    final sorted =
        lessons
            .whereType<Map>()
            .map((l) => Map<dynamic, dynamic>.from(l.cast<dynamic, dynamic>()))
            .toList()
          ..sort((a, b) {
            final byStart = _lessonStartMinutes(
              a,
            ).compareTo(_lessonStartMinutes(b));
            if (byStart != 0) return byStart;
            return _lessonEndMinutes(a).compareTo(_lessonEndMinutes(b));
          });

    if (sorted.isEmpty) return const [];

    final merged = <Map<dynamic, dynamic>>[];
    for (final lesson in sorted) {
      if (merged.isEmpty) {
        merged.add(lesson);
        continue;
      }

      final previous = merged.last;
      if (_isSameConsecutiveLessonBlock(previous, lesson)) {
        final prevEnd = _lessonEndMinutes(previous);
        final lessonEnd = _lessonEndMinutes(lesson);
        if (lessonEnd > prevEnd) {
          previous['endTime'] = lesson['endTime'];
        }
      } else {
        merged.add(lesson);
      }
    }

    return merged;
  }

  List<_TimeRangeLabel> _collectTimeRangesFromData(
    Map<int, List<dynamic>> weekData,
  ) {
    final seen = <String>{};
    final ranges = <_TimeRangeLabel>[];
    for (final day in weekData.values) {
      final visibleDayLessons = day
          .where(
            (l) => !hiddenSubjectsNotifier.value.contains(
              l['_subjectShort']?.toString() ?? '',
            ),
          )
          .where(
            (l) =>
                showCancelledNotifier.value || (l['code'] ?? '') != 'cancelled',
          )
          .toList();
      final mergedDayLessons = _mergeConsecutiveLessons(visibleDayLessons);
      for (final lesson in mergedDayLessons) {
        final map = lesson as Map<dynamic, dynamic>;
        final start = _lessonStartMinutes(map);
        final end = _lessonEndMinutes(map);
        if (end <= start) continue;
        final key = '$start-$end';
        if (seen.add(key)) {
          ranges.add(_TimeRangeLabel(startMin: start, endMin: end));
        }
      }
    }
    ranges.sort((a, b) {
      final byStart = a.startMin.compareTo(b.startMin);
      if (byStart != 0) return byStart;
      return a.endMin.compareTo(b.endMin);
    });
    return ranges;
  }

  List<_TimeRangeLabel> _collectTimeRangesFromDay(int dayIndex) {
    final dayLessons = _weekData[dayIndex] ?? const <dynamic>[];
    final ranges = <_TimeRangeLabel>[];
    final seen = <String>{};

    for (final lesson in dayLessons.whereType<Map>()) {
      final map = lesson.cast<dynamic, dynamic>();
      if ((map['code'] ?? '') == 'cancelled') continue;
      final start = _lessonStartMinutes(map);
      final end = _lessonEndMinutes(map);
      if (end <= start) continue;
      final key = '$start-$end';
      if (seen.add(key)) {
        ranges.add(_TimeRangeLabel(startMin: start, endMin: end));
      }
    }

    ranges.sort((a, b) {
      final byStart = a.startMin.compareTo(b.startMin);
      if (byStart != 0) return byStart;
      return a.endMin.compareTo(b.endMin);
    });
    return ranges;
  }

  Set<int> _lessonRoomIds(Map<dynamic, dynamic> lesson) {
    final ids = <int>{};
    final ro = lesson['ro'];
    if (ro is List) {
      for (final entry in ro.whereType<Map>()) {
        final id = entry['id'];
        if (id is int) {
          ids.add(id);
        } else {
          final parsed = int.tryParse(id?.toString() ?? '');
          if (parsed != null) ids.add(parsed);
        }
      }
    }

    if (ids.isEmpty) {
      final roomName = (lesson['_room'] ?? '').toString().trim();
      if (roomName.isNotEmpty) {
        _roomMap.forEach((id, name) {
          if (name.trim().toLowerCase() == roomName.toLowerCase()) {
            ids.add(id);
          }
        });
      }
    }

    return ids;
  }

  List<String> _computeFreeRooms({
    required List<List<dynamic>> timetables,
    required int startMin,
    required int endMin,
  }) {
    final occupiedIds = <int>{};
    for (final periods in timetables) {
      for (final raw in periods) {
        if (raw is! Map) continue;
        final lesson = raw.cast<dynamic, dynamic>();
        if ((lesson['code'] ?? '') == 'cancelled') continue;
        final lessonStart = _lessonStartMinutes(lesson);
        final lessonEnd = _lessonEndMinutes(lesson);
        if (lessonStart < endMin && lessonEnd > startMin) {
          occupiedIds.addAll(_lessonRoomIds(lesson));
        }
      }
    }

    final freeRooms = <String>[];
    final seenNames = <String>{};
    final sortedEntries = _roomMap.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    for (final entry in sortedEntries) {
      if (occupiedIds.contains(entry.key)) continue;
      final name = entry.value.trim();
      if (name.isEmpty) continue;
      if (seenNames.add(name.toLowerCase())) {
        freeRooms.add(name);
      }
    }
    return freeRooms;
  }

  List<Map<String, dynamic>> _getHolidaysForDay(DateTime day) {
    final dayStr = DateFormat('yyyyMMdd').format(day);
    final dayInt = int.tryParse(dayStr);
    if (dayInt == null) return [];
    return _holidays.where((h) {
      final start = h['startDate'];
      final end = h['endDate'];
      if (start == null || end == null) return false;
      final s = int.tryParse(start.toString());
      final e = int.tryParse(end.toString());
      if (s == null || e == null) return false;
      return dayInt >= s && dayInt <= e;
    }).toList();
  }

  Future<void> _showFreeRoomsDialog() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final dayIndex = _tabController.index.clamp(0, 4);
    final ranges = _collectTimeRangesFromDay(dayIndex);

    if (ranges.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.freeRoomsNoRangesHint),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dayDate = _currentMonday.add(Duration(days: dayIndex));
    int selectedIndex = 0;
    final now = DateTime.now();
    final isToday =
        dayDate.year == now.year &&
        dayDate.month == now.month &&
        dayDate.day == now.day;

    if (isToday) {
      final nowMin = now.hour * 60 + now.minute;
      final idx = ranges.indexWhere(
        (r) => nowMin >= r.startMin && nowMin < r.endMin,
      );
      if (idx >= 0) selectedIndex = idx;
    }

    if (!mounted) return;
    showUntisDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final List<List<String>> freeRoomsForRange;
    if (demoModeNotifier.value) {
      freeRoomsForRange = List.generate(
        ranges.length,
        DemoModeService.demoFreeRooms,
      );
    } else {
      final classes = await _fetchClasses();
      List<List<dynamic>> timetables = [];
      if (classes.isNotEmpty) {
        final results = await Future.wait(
          classes.map((c) => _fetchClassTimetable(c['id'] as int, dayDate)),
          eagerError: false,
        );
        timetables = results.whereType<List<dynamic>>().toList();
      }
      freeRoomsForRange = [
        for (final range in ranges)
          _computeFreeRooms(
            timetables: timetables,
            startMin: range.startMin,
            endMin: range.endMin,
          ),
      ];
    }

    if (!mounted) return;
    if (context.mounted) Navigator.of(context).pop();

    await showUntisModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: _kBottomSheetAnimationStyle,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            final freeRooms = freeRoomsForRange[selectedIndex];
            final dayName = _dayShort[dayIndex];

            return _glassContainer(
              context: ctx,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      children: [
                        Text(
                          l.freeRoomsTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$dayName • ${_formatMinutes(ranges[selectedIndex].startMin)} - ${_formatMinutes(ranges[selectedIndex].endMin)}',
                          style: GoogleFonts.outfit(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l.freeRoomsSelectTime,
                          style: GoogleFonts.outfit(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 0; i < ranges.length; i++)
                              ChoiceChip(
                                selected: i == selectedIndex,
                                showCheckmark: true,
                                side: BorderSide(
                                  color:
                                      (i == selectedIndex
                                              ? cs.primary
                                              : cs.outlineVariant)
                                          .withValues(
                                            alpha: i == selectedIndex
                                                ? 0.48
                                                : 0.65,
                                          ),
                                ),
                                backgroundColor: cs.surfaceContainerHigh
                                    .withValues(
                                      alpha: blurEnabledNotifier.value
                                          ? 0.86
                                          : 0.92,
                                    ),
                                selectedColor: cs.primaryContainer.withValues(
                                  alpha: 0.92,
                                ),
                                label: Text(
                                  '${_formatMinutes(ranges[i].startMin)} - ${_formatMinutes(ranges[i].endMin)}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: i == selectedIndex
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: i == selectedIndex
                                        ? cs.onPrimaryContainer
                                        : cs.onSurface.withValues(alpha: 0.98),
                                  ),
                                ),
                                onSelected: (_) {
                                  setDlg(() => selectedIndex = i);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l.freeRoomsCount(freeRooms.length),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (freeRooms.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withValues(
                                alpha: blurEnabledNotifier.value ? 0.88 : 0.94,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                            child: Text(
                              l.freeRoomsNoneFound,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.96,
                                ),
                              ),
                            ),
                          )
                        else
                          ...freeRooms.asMap().entries.map((entry) {
                            final i = entry.key;
                            final room = entry.value;
                            return _springEntry(
                              duration: Duration(milliseconds: 300 + i * 50),
                              offsetY: 16,
                              startScale: 0.95,
                              curve: _kSmoothBounce,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh.withValues(
                                    alpha: blurEnabledNotifier.value
                                        ? 0.86
                                        : 0.92,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.56,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.meeting_room_outlined,
                                    color: cs.primary,
                                  ),
                                  title: Text(
                                    room,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchClasses() async {
    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );

    Future<List<dynamic>> fetchClassesForSession(String sid) async {
      final response = await http.post(
        url,
        headers: {"Cookie": "JSESSIONID=$sid; schoolname=$schoolName"},
        body: jsonEncode({
          "id": "fr_cl",
          "method": "getKlassen",
          "params": {},
          "jsonrpc": "2.0",
        }),
      );
      if (response.statusCode != 200) return const <dynamic>[];
      final data = jsonDecode(response.body);
      if (data is Map && data['result'] is List) {
        return data['result'] as List<dynamic>;
      }
      return const <dynamic>[];
    }

    List<dynamic> classes = [];
    if (sessionID.isNotEmpty) {
      try {
        classes = await fetchClassesForSession(sessionID);
      } catch (_) {}
    }
    if (classes.isEmpty) {
      try {
        final anonSid = await _authenticateAnonymous();
        if (anonSid != null && anonSid.isNotEmpty) {
          classes = await fetchClassesForSession(anonSid);
        }
      } catch (_) {}
    }
    return classes.cast<Map<String, dynamic>>();
  }

  Future<List<dynamic>> _fetchClassTimetable(int classId, DateTime date) async {
    final dateInt = int.parse(DateFormat('yyyyMMdd').format(date));
    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );
    try {
      final response = await http.post(
        url,
        headers: {
          "Cookie": "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "id": "fr_tt_$classId",
          "method": "getTimetable",
          "params": {
            "options": {
              "element": {"id": classId, "type": 1},
              "startDate": dateInt,
              "endDate": dateInt,
              "showRooms": true,
              "showSubjects": true,
              "showTeachers": true,
              "showClasses": true,
            },
          },
          "jsonrpc": "2.0",
        }),
      );
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      if (data is Map && data['result'] is List) {
        return data['result'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  static const List<double> _grayscaleMatrix = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  Widget _dimPastLesson({required Widget child, required bool dim}) {
    if (!dim || !lessonDimPastNotifier.value) return child;
    return Opacity(
      opacity: 0.45,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: child,
      ),
    );
  }

  Widget _buildTimetableLessonCard({
    required BuildContext context,
    required bool isCancelled,
    required bool isDark,
    required Color fgColor,
    required Color bgColor,
    required String subject,
    required String teacher,
    required String room,
    required bool isNow,
    IconData? subjectIcon,
    bool isTeacherMissing = false,
    bool hasHomework = false,
    bool hasExam = false,
    String originalTeacher = '',
    double? borderRadius,
    EdgeInsets? padding,
    double accentWidth = 3.5,
    double subjectFontSize = 11.5,
    double teacherFontSize = 9.5,
    double roomFontSize = 9.5,
    bool useStripes = true,
    double? availableWidth,
    double? availableHeight,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    final themeOwnsStyle = tokens.id != AppThemeId.defaultTheme;
    final effectiveRadius = themeOwnsStyle
        ? tokens.surfaceRadius
        : (borderRadius ?? lessonBorderRadiusNotifier.value);
    final cardRadius = BorderRadius.circular(effectiveRadius);

    final glowEnabled = tokens.glowEffectsEnabled;
    final cardStyle = themeOwnsStyle ? 3 : lessonCardStyleNotifier.value;
    final blurEnabled =
        tokens.supportsBlur &&
        blurEnabledNotifier.value &&
        (themeOwnsStyle || lessonBlurEnabledNotifier.value || cardStyle == 1);
    final blurSigma = themeOwnsStyle
        ? tokens.blurSigma
        : lessonBlurAmountNotifier.value;
    final cardOpacity = themeOwnsStyle
        ? tokens.lessonSurfaceOpacity
        : lessonCardOpacityNotifier.value;
    final accentStyle = themeOwnsStyle ? 0 : lessonAccentStyleNotifier.value;
    final showTeacher = lessonShowTeacherNotifier.value;
    final showRoom = lessonShowRoomNotifier.value;
    final isSubstituted =
        showTeacher &&
        originalTeacher.isNotEmpty &&
        originalTeacher != teacher;
    final compact = lessonCompactModeNotifier.value;
    final showPattern =
        (isCancelled || isTeacherMissing) &&
        useStripes &&
        lessonCancelledPatternNotifier.value;

    final heightCompact = availableHeight != null && availableHeight < 58;
    final heightMinimal = availableHeight != null && availableHeight < 40;
    final widthCompact = availableWidth != null && availableWidth < 54;
    final effectivePadding = heightMinimal
        ? const EdgeInsets.fromLTRB(5, 2, 4, 2)
        : heightCompact
        ? const EdgeInsets.fromLTRB(6, 3, 5, 3)
        : padding != null
        ? (compact
              ? EdgeInsets.fromLTRB(
                  padding.left.clamp(3.0, 6.0),
                  (padding.top * 0.7).clamp(2.0, 5.0),
                  padding.right.clamp(3.0, 6.0),
                  (padding.bottom * 0.7).clamp(2.0, 5.0),
                )
              : padding)
        : (compact
              ? const EdgeInsets.fromLTRB(6, 3, 5, 3)
              : const EdgeInsets.fromLTRB(8, 5, 6, 5));

    final effectiveSubjectFontSize = compact || widthCompact || heightCompact
        ? (subjectFontSize * 0.92).clamp(8.5, 14.0)
        : subjectFontSize;
    final effectiveTeacherFontSize = compact
        ? (teacherFontSize * 0.90).clamp(7.5, 12.0)
        : teacherFontSize;
    final effectiveRoomFontSize = compact
        ? (roomFontSize * 0.90).clamp(7.5, 12.0)
        : roomFontSize;

    List<BoxShadow>? shadows;
    if (glowEnabled) {
      if (isNow) {
        shadows = [
          BoxShadow(
            color: fgColor.withValues(alpha: 0.38),
            blurRadius: 14,
            spreadRadius: 1.5,
            offset: const Offset(0, 3),
          ),
        ];
      }
    }

    Color effectiveFillColor;
    Gradient? effectiveGradient;
    Border? effectiveBorder;
    Color effectiveTextColor = isCancelled
        ? fgColor.withValues(alpha: 0.6)
        : fgColor;
    Color effectiveSecondaryTextColor = isCancelled
        ? fgColor.withValues(alpha: 0.48)
        : fgColor.withValues(alpha: 0.75);

    switch (cardStyle) {
      case 1:
        effectiveFillColor = isCancelled
            ? bgColor.withValues(alpha: (0.28 * cardOpacity).clamp(0.0, 1.0))
            : cs.surfaceContainerLowest.withValues(
                alpha: (0.52 * cardOpacity).clamp(0.0, 1.0),
              );
        effectiveBorder = Border.all(
          color: isCancelled
              ? fgColor.withValues(alpha: 0.40)
              : fgColor.withValues(alpha: isDark ? 0.42 : 0.28),
          width: 1.2,
        );
        break;
      case 2:
        effectiveFillColor = Colors.transparent;
        effectiveGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCancelled
              ? [
                  fgColor.withValues(
                    alpha: (0.25 * cardOpacity).clamp(0.0, 1.0),
                  ),
                  bgColor.withValues(
                    alpha: (0.45 * cardOpacity).clamp(0.0, 1.0),
                  ),
                ]
              : [
                  fgColor.withValues(
                    alpha: ((isDark ? 0.35 : 0.25) * cardOpacity).clamp(
                      0.0,
                      1.0,
                    ),
                  ),
                  bgColor.withValues(alpha: cardOpacity.clamp(0.0, 1.0)),
                ],
        );
        effectiveBorder = Border.all(
          color: fgColor.withValues(alpha: isDark ? 0.30 : 0.18),
          width: 1.0,
        );
        break;
      case 3:
        effectiveFillColor = isCancelled
            ? cs.surfaceContainerLowest.withValues(
                alpha: (0.35 * cardOpacity).clamp(0.0, 1.0),
              )
            : cs.surfaceContainerLow.withValues(
                alpha: (0.60 * cardOpacity).clamp(0.0, 1.0),
              );
        effectiveBorder = Border.all(
          color: isCancelled
              ? fgColor.withValues(alpha: 0.50)
              : fgColor.withValues(alpha: isDark ? 0.85 : 0.70),
          width: 1.8,
        );
        break;
      case 4:
        effectiveFillColor = isCancelled
            ? fgColor.withValues(alpha: 0.45)
            : fgColor.withValues(alpha: cardOpacity.clamp(0.6, 1.0));
        effectiveBorder = null;
        final lum = effectiveFillColor.computeLuminance();
        final solidText = lum > 0.45 ? Colors.black87 : Colors.white;
        effectiveTextColor = solidText;
        effectiveSecondaryTextColor = solidText.withValues(alpha: 0.78);
        break;
      case 0:
      default:
        effectiveFillColor = isCancelled
            ? bgColor.withValues(alpha: (0.40 * cardOpacity).clamp(0.0, 1.0))
            : bgColor.withValues(alpha: cardOpacity.clamp(0.0, 1.0));
        effectiveBorder = Border.all(
          color: fgColor.withValues(alpha: isDark ? 0.25 : 0.15),
          width: 1.0,
        );
        break;
    }

    if (tokens.id == AppThemeId.manga) {
      effectiveFillColor = cs.surfaceContainerLow;
      effectiveGradient = null;
      effectiveBorder = Border.all(
        color: cs.outline,
        width: tokens.borderWidth,
      );
      effectiveTextColor = cs.onSurface;
      effectiveSecondaryTextColor = cs.onSurfaceVariant;
      shadows = [
        BoxShadow(
          color: tokens.shadowColor,
          offset: tokens.shadowOffset,
          blurRadius: 0,
        ),
      ];
    } else if (tokens.id == AppThemeId.cyber) {
      effectiveBorder = Border.all(
        color: isCancelled ? fgColor : cs.primary,
        width: tokens.borderWidth,
      );
    }

    final double effectiveAccentWidth = accentStyle == 0
        ? accentWidth
        : (accentStyle == 1 ? 1.8 : 0.0);

    Widget cardContent = Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: effectiveFillColor,
            gradient: effectiveGradient,
            borderRadius: cardRadius,
            border: effectiveBorder,
          ),
        ),
        if (showPattern)
          Positioned.fill(
            child: CustomPaint(
              painter: _StripedHatchPainter(
                color: fgColor.withValues(alpha: isDark ? 0.18 : 0.12),
                stripeWidth: 2.0,
                gap: 7.0,
              ),
            ),
          ),
        if (accentStyle == 0 || accentStyle == 1)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: effectiveAccentWidth,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [fgColor, fgColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(effectiveRadius),
                  bottomLeft: Radius.circular(effectiveRadius),
                ),
              ),
            ),
          ),
        Padding(
          padding: effectivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (accentStyle == 2) ...[
                    Container(
                      width: 6.5,
                      height: 6.5,
                      margin: const EdgeInsets.only(right: 4.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fgColor,
                        boxShadow: _glowShadows(context, [
                          BoxShadow(
                            color: fgColor.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ]),
                      ),
                    ),
                  ],
                  Flexible(
                    child: Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: untisThemeTextStyle(
                        context,
                        display: true,
                        fontSize: effectiveSubjectFontSize,
                        fontWeight: FontWeight.w800,
                        color: effectiveTextColor,
                        decoration: isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: fgColor.withValues(alpha: 0.6),
                        decorationThickness: 1.6,
                      ),
                    ),
                  ),
                  if (lessonShowSubjectIconsNotifier.value &&
                      subjectIcon != null &&
                      !widthCompact &&
                      !heightMinimal) ...[
                    Icon(
                      subjectIcon,
                      size: (effectiveSubjectFontSize * 1.15).clamp(11.0, 17.0),
                      color: effectiveTextColor.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 3.5),
                  ],
                  if ((hasExam || hasHomework) && !widthCompact) ...[
                    const SizedBox(width: 4),
                    Icon(
                      hasExam
                          ? Icons.assignment_turned_in_rounded
                          : Icons.assignment_rounded,
                      size: (effectiveSubjectFontSize * 0.9).clamp(10.0, 16.0),
                      color: effectiveTextColor.withValues(alpha: 0.8),
                    ),
                  ],
                  if (isTeacherMissing && !widthCompact) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.person_off_rounded,
                      size: (effectiveSubjectFontSize * 0.9).clamp(10.0, 16.0),
                      color: Colors.deepOrange.withValues(alpha: 0.9),
                    ),
                  ],
                ],
              ),
              if (!heightMinimal &&
                  showTeacher &&
                  teacher.isNotEmpty &&
                  (availableHeight == null || availableHeight >= 42))
                Text(
                  teacher,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: effectiveTeacherFontSize,
                    fontWeight: isSubstituted
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: isSubstituted
                        ? effectiveTextColor
                        : effectiveSecondaryTextColor,
                  ),
                ),
              // Original teacher of a substituted lesson, struck through.
              if (isSubstituted &&
                  (availableHeight == null || availableHeight >= 54))
                Text(
                  originalTeacher,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: effectiveTeacherFontSize * 0.9,
                    fontWeight: FontWeight.w500,
                    color: effectiveSecondaryTextColor.withValues(alpha: 0.6),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: fgColor.withValues(alpha: 0.55),
                    decorationThickness: 1.4,
                  ),
                ),
              if (!heightCompact &&
                  showRoom &&
                  room.isNotEmpty &&
                  (availableHeight == null || availableHeight >= 58))
                Text(
                  room,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: effectiveRoomFontSize,
                    fontWeight: FontWeight.w600,
                    color: effectiveSecondaryTextColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (blurEnabled) {
      cardContent = ClipRRect(
        borderRadius: cardRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: cardContent,
        ),
      );
    } else {
      cardContent = ClipRRect(borderRadius: cardRadius, child: cardContent);
    }

    return Container(
      decoration: BoxDecoration(borderRadius: cardRadius, boxShadow: shadows),
      child: cardContent,
    );
  }

  List<_LessonSlot> _computeLessonSlots(List<dynamic> rawLessons) {
    final entries =
        rawLessons.whereType<Map>().map((lesson) {
          final map = lesson.cast<dynamic, dynamic>();
          final rawStart = (map['startTime'] as int?) ?? 800;
          final rawEnd = (map['endTime'] as int?) ?? (rawStart + 45);
          return _LessonSlotCandidate(
            lesson: map,
            startMin: _toMinutes(rawStart),
            endMin: _toMinutes(rawEnd),
          );
        }).toList()..sort((a, b) {
          final byStart = a.startMin.compareTo(b.startMin);
          if (byStart != 0) return byStart;
          return a.endMin.compareTo(b.endMin);
        });

    if (entries.isEmpty) return const [];

    final slots = <_LessonSlot>[];

    void flushCluster(List<_LessonSlotCandidate> cluster) {
      if (cluster.isEmpty) return;
      final columnEnds = <int>[];

      for (final entry in cluster) {
        var assignedColumn = -1;
        for (var i = 0; i < columnEnds.length; i++) {
          if (columnEnds[i] <= entry.startMin) {
            assignedColumn = i;
            break;
          }
        }

        if (assignedColumn == -1) {
          columnEnds.add(entry.endMin);
          assignedColumn = columnEnds.length - 1;
        } else {
          columnEnds[assignedColumn] = entry.endMin;
        }

        entry.column = assignedColumn;
      }

      final columnCount = columnEnds.isEmpty ? 1 : columnEnds.length;
      for (final entry in cluster) {
        slots.add(
          _LessonSlot(
            lesson: entry.lesson,
            startMin: entry.startMin,
            endMin: entry.endMin,
            column: entry.column,
            columnCount: columnCount,
          ),
        );
      }
    }

    final cluster = <_LessonSlotCandidate>[];
    var clusterMaxEnd = -1;

    for (final entry in entries) {
      if (cluster.isEmpty) {
        cluster.add(entry);
        clusterMaxEnd = entry.endMin;
        continue;
      }

      if (entry.startMin < clusterMaxEnd) {
        cluster.add(entry);
        if (entry.endMin > clusterMaxEnd) {
          clusterMaxEnd = entry.endMin;
        }
      } else {
        flushCluster(cluster);
        cluster
          ..clear()
          ..add(entry);
        clusterMaxEnd = entry.endMin;
      }
    }
    flushCluster(cluster);

    return slots;
  }

  /// Builds the content shown by the day (grid) timetable mode. With the
  /// default span of 1 this is the classic single-day time grid. With a span
  /// of 2 or 3 the timetable shows that many consecutive days side by side,
  /// sliding the window towards the end of the week for late weekdays.
  Widget _buildDayContentView(
    int dayIndex, {
    DateTime? monday,
    Map<int, List<dynamic>>? weekData,
  }) {
    final span = timetableDaySpanNotifier.value.clamp(1, 3);
    if (span == 1) {
      return _buildGridView(dayIndex, monday: monday, weekData: weekData);
    }
    final start = dayIndex.clamp(0, 5 - span);
    return _buildWeekView(
      monday: monday,
      weekData: weekData,
      startDay: start,
      dayCount: span,
    );
  }

  Widget _buildGridView(
    int dayIndex, {
    DateTime? monday,
    Map<int, List<dynamic>>? weekData,
  }) {
    final wd = weekData ?? _weekData;
    final m = monday ?? _currentMonday;
    final media = MediaQuery.of(context);
    final topContentPadding = _isExportingTimetable
        ? 10.0
        : media.padding.top + kToolbarHeight + kTextTabBarHeight + 10;

    final lessons = (wd[dayIndex] ?? [])
        .where(
          (l) => !hiddenSubjectsNotifier.value.contains(
            l['_subjectShort']?.toString() ?? '',
          ),
        )
        .toList();

    int globalMin = 480;
    int globalMax = 1200;
    for (final day in wd.values) {
      for (final l in day) {
        final s = _toMinutes((l['startTime'] as int?) ?? 480);
        final e = _toMinutes((l['endTime'] as int?) ?? 600);
        if (s < globalMin) globalMin = s;
        if (e > globalMax) globalMax = e;
      }
    }

    globalMin = (globalMin - 15).clamp(0, 23 * 60);
    globalMax = globalMax + 15;

    final totalMinutes = globalMax - globalMin;
    final totalHeight = totalMinutes * _ppm;

    final List<int> ticks = [];
    for (int m = globalMin - (globalMin % 60) + 60; m < globalMax; m += 60) {
      ticks.add(m);
    }

    const double timeColWidth = 40;
    // During a week swipe, render time and date labels from the incoming
    // cached week as well. Reading the active week here made those rails lag
    // behind the cards until the snap animation had already completed.
    final timeRanges = _collectTimeRangesFromData(wd);

    final now = DateTime.now();
    final dayDate = m.add(Duration(days: dayIndex));
    final isToday =
        dayDate.year == now.year &&
        dayDate.month == now.month &&
        dayDate.day == now.day;
    final nowMin = now.hour * 60 + now.minute;
    final showNowLine = isToday && nowMin >= globalMin && nowMin <= globalMax;
    final nowTop = (nowMin - globalMin) * _ppm;
    final visibleLessons = lessons
        .where(
          (l) =>
              showCancelledNotifier.value || (l['code'] ?? '') != 'cancelled',
        )
        .toList();
    final mergedLessons = _mergeConsecutiveLessons(visibleLessons);
    final lessonSlots = _computeLessonSlots(mergedLessons);

    // Filter time labels to prevent overlapping on the vertical axis.
    final filteredTimeLabels = timeRanges.isNotEmpty
        ? _filterTimeLabels(timeRanges)
        : <int>[];

    final csG = Theme.of(context).colorScheme;
    return ExpressiveRefreshIndicator(
      onRefresh: _onRefresh,
      // The expressive indicator starts immediately under the app bar rather
      // than in the middle of the timetable content.
      edgeOffset: topContentPadding,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 32, top: topContentPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: timeColWidth,
              height: totalHeight,
              child: Stack(
                children: filteredTimeLabels.isNotEmpty
                    ? filteredTimeLabels.map((t) {
                        final top = (t - globalMin) * _ppm - 9;
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          child: Text(
                            _formatMinutes(t),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: csG.onSurfaceVariant.withValues(
                                alpha: 0.54,
                              ),
                            ),
                          ),
                        );
                      }).toList()
                    : ticks.map((tick) {
                        final top = (tick - globalMin) * _ppm - 9;
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          child: Text(
                            _formatMinutes(tick),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: csG.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: totalHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        ...ticks.map((tick) {
                          final top = (tick - globalMin) * _ppm;
                          return Positioned(
                            top: top,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 0.45,
                              color: csG.outlineVariant.withValues(alpha: 0.28),
                            ),
                          );
                        }),
                        ..._getHolidaysForDay(dayDate).map((holiday) {
                          final holidayStartMin = _toMinutes(800);
                          final holidayEndMin = _toMinutes(1800);
                          final top = (holidayStartMin - globalMin) * _ppm;
                          final height =
                              ((holidayEndMin - holidayStartMin) * _ppm).clamp(
                                28.0,
                                9999.0,
                              );
                          final holidayName =
                              (holiday['longName'] ?? holiday['name'] ?? '')
                                  .toString();
                          return Positioned(
                            top: top,
                            left: 2,
                            right: 2,
                            height: height,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: csG.tertiaryContainer.withValues(
                                    alpha: 0.85,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: csG.tertiary.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.celebration_rounded,
                                      size: 20,
                                      color: csG.tertiary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      holidayName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: csG.onTertiaryContainer,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        ...lessonSlots.map((slot) {
                          final l = slot.lesson;
                          final startMin = slot.startMin;
                          final endMin = slot.endMin;
                          final top = (startMin - globalMin) * _ppm;
                          final height = ((endMin - startMin) * _ppm).clamp(
                            28.0,
                            9999.0,
                          );
                          final dim = isToday && endMin <= nowMin;

                          const horizontalInset = 2.0;
                          const columnGap = 4.0;
                          final columns = slot.columnCount;
                          final availableWidth =
                              constraints.maxWidth - (horizontalInset * 2);
                          final totalGap = (columns - 1) * columnGap;
                          final rawCardWidth =
                              (availableWidth - totalGap) / columns;
                          final cardWidth = rawCardWidth > 8
                              ? rawCardWidth
                              : 8.0;
                          final left =
                              horizontalInset +
                              (slot.column * (cardWidth + columnGap));

                          return Positioned(
                            top: top,
                            left: left,
                            width: cardWidth,
                            height: height,
                            child: _dimPastLesson(
                              dim: dim,
                              child: Builder(
                                builder: (context) {
                                  final cs = Theme.of(context).colorScheme;
                                  final isDark =
                                      Theme.of(context).brightness ==
                                      Brightness.dark;
                                  final isCancelled =
                                      (l['code'] ?? '') == 'cancelled';
                                  final isTeacherMissing = _hasMissingTeacher(
                                    l,
                                  );
                                  final sk =
                                      l['_subjectShort']?.toString() ?? '';
                                  final useMonochrome =
                                      monochromeLessonsNotifier.value;
                                  final cancelledColor = Color(
                                    cancelledLessonColorNotifier.value,
                                  );
                                  final cv = isCancelled || useMonochrome
                                      ? null
                                      : subjectColorsNotifier.value[sk];
                                  final fgColor = isCancelled
                                      ? cancelledColor
                                      : useMonochrome
                                      ? Color(
                                          monochromeLessonColorNotifier.value,
                                        )
                                      : cv != null
                                      ? Color(cv)
                                      : _autoLessonColor(sk, isDark);
                                  final bgColor = isCancelled
                                      ? Color.alphaBlend(
                                          cancelledColor.withValues(
                                            alpha: isDark ? 0.14 : 0.10,
                                          ),
                                          cs.surfaceContainerHighest,
                                        )
                                      : Color.alphaBlend(
                                          fgColor.withValues(
                                            alpha: isDark ? 0.14 : 0.10,
                                          ),
                                          cs.surfaceContainerHighest,
                                        );
                                  final subject =
                                      l['_subjectShort']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true
                                      ? l['_subjectShort'].toString()
                                      : (l['_subjectLong']
                                                    ?.toString()
                                                    .isNotEmpty ==
                                                true
                                            ? l['_subjectLong'].toString()
                                            : '?');
                                  final room = l['_room']?.toString() ?? '';
                                  final teacher =
                                      l['_teacher']?.toString() ?? '';
                                  final isCurrent =
                                      (startMin <= nowMin && nowMin < endMin);
                                  final isNow = isCurrent;

                                  final lDateInt =
                                      int.tryParse(
                                        l['date']?.toString() ?? '',
                                      ) ??
                                      0;
                                  final hasHomework =
                                      homeworksNotifier.value.any(
                                        (hw) =>
                                            hw['dueDate'] == lDateInt &&
                                            (hw['subject'] == sk ||
                                                hw['subject'] == subject),
                                      ) ||
                                      customHomeworkNotifier.value.any(
                                        (hw) =>
                                            hw['dueDate'] == lDateInt &&
                                            (hw['subject'] == sk ||
                                                hw['subject'] == subject),
                                      );
                                  final hasExam =
                                      apiExamsNotifier.value.any(
                                        (ex) =>
                                            (ex['date'] ??
                                                    ex['examDate'] ??
                                                    0) ==
                                                lDateInt &&
                                            (ex['subject'] == sk ||
                                                ex['subjectName'] == sk ||
                                                ex['subject'] == subject),
                                      ) ||
                                      customExamsNotifier.value.any(
                                        (ex) =>
                                            (ex['date'] ?? 0) == lDateInt &&
                                            (ex['subject'] == sk ||
                                                ex['subject'] == subject),
                                      );

                                  final highlightMatch =
                                      _isHighlightMatch(l);
                                  Widget lessonTile = GestureDetector(
                                    onTap: () => _showLessonDetail(
                                      context,
                                      l,
                                      originalTeacher:
                                          _originalTeachers[
                                                _lessonIdentityOf(l)
                                              ] ??
                                          '',
                                    ),
                                    onLongPress: () =>
                                        _editLessonTemporarily(l),
                                    child: _buildTimetableLessonCard(
                                      context: context,
                                      isCancelled: isCancelled,
                                      isDark: isDark,
                                      fgColor: fgColor,
                                      bgColor: bgColor,
                                      subject: subject,
                                      subjectIcon: _subjectIconFor(sk, subject),
                                      teacher: teacher,
                                      room: room,
                                      isNow: isNow,
                                      isTeacherMissing: isTeacherMissing,
                                      hasHomework: hasHomework,
                                      hasExam: hasExam,
                                      originalTeacher:
                                          _originalTeachers[
                                                _lessonIdentityOf(l)
                                              ] ??
                                          '',
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        5,
                                        6,
                                        5,
                                      ),
                                      accentWidth: 3.5,
                                      subjectFontSize: 11.5,
                                      teacherFontSize: 9.5,
                                      roomFontSize: 9.5,
                                      useStripes: true,
                                    ),
                                  );
                                  if (highlightMatch) {
                                    lessonTile = AnimatedBuilder(
                                      animation: _highlightController!,
                                      builder: (context, child) {
                                        final t =
                                            _highlightController!.value;
                                        final glow =
                                            (math.sin(t * math.pi) *
                                                    (1 - t)) *
                                                0.75;
                                        if (glow <= 0.02) return child!;
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: csG.tertiary.withValues(
                                                  alpha: glow,
                                                ),
                                                blurRadius: 26,
                                                spreadRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: child,
                                        );
                                      },
                                      child: lessonTile,
                                    );
                                  }
                                  return lessonTile;
                                },
                              ),
                            ),
                          );
                        }),
                        if (showNowLine)
                          Positioned(
                            top: nowTop - 1,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: csG.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: csG.error,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView({
    DateTime? monday,
    Map<int, List<dynamic>>? weekData,
    int startDay = 0,
    int dayCount = 5,
  }) {
    final wd = weekData ?? _weekData;
    final m = monday ?? _currentMonday;
    final media = MediaQuery.of(context);
    final topContentPadding = _isExportingTimetable
        ? 10.0
        : media.padding.top +
              kToolbarHeight +
              // The day tabs are hidden in the dedicated week view but visible
              // whenever the day grid renders multiple days side by side.
              (_viewMode == 1 ? 0 : kTextTabBarHeight) +
              10;

    int globalMin = 480;
    int globalMax = 900;
    for (final day in wd.values) {
      for (final l in day) {
        final s = _toMinutes((l['startTime'] as int?) ?? 480);
        final e = _toMinutes((l['endTime'] as int?) ?? 600);
        if (s < globalMin) globalMin = s;
        if (e > globalMax) globalMax = e;
      }
    }
    globalMin = (globalMin - 15).clamp(0, 23 * 60);
    globalMax = globalMax + 15;

    final totalHeight = (globalMax - globalMin) * _ppm;

    final List<int> ticks = [];
    for (
      int min = globalMin - (globalMin % 60) + 60;
      min < globalMax;
      min += 60
    ) {
      ticks.add(min);
    }

    const double timeColWidth = 40.0;
    const double minDayColWidth = 56.0;
    const double dayColGap = 4.0;
    // Leave a real trailing gutter inside the horizontal viewport. Without
    // it, the Friday column ends exactly at the clip edge on phones and its
    // card border/shadow can be cut off.
    const double trailingDayGridInset = 12.0;
    final timeRanges = _collectTimeRangesFromData(wd);
    // Filter time labels to prevent overlapping on the vertical axis.
    final filteredTimeLabels = timeRanges.isNotEmpty
        ? _filterTimeLabels(timeRanges)
        : <int>[];
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();

    final todayDate = DateTime(today.year, today.month, today.day);
    final mondayDate = DateTime(m.year, m.month, m.day);
    final todayIndex = todayDate.difference(mondayDate).inDays;
    final nowMin = today.hour * 60 + today.minute;
    final showNowLine =
        todayIndex >= startDay &&
        todayIndex < startDay + dayCount &&
        nowMin >= globalMin &&
        nowMin <= globalMax;
    final nowTop = (nowMin - globalMin) * _ppm;

    return ExpressiveRefreshIndicator(
      onRefresh: _onRefresh,
      // Keep the indicator directly under the transparent app bar.
      edgeOffset: topContentPadding,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          bottom: 32,
          top: topContentPadding,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dayGridWidth = math.max(
              (dayCount * minDayColWidth) + (dayColGap * (dayCount - 1)),
              constraints.maxWidth - timeColWidth - 4 - trailingDayGridInset,
            );
            final dayColWidth =
                (dayGridWidth - (dayColGap * (dayCount - 1))) / dayCount;

            // On small screens five day columns cannot fit alongside the time
            // gutter. Keep their minimum readable width and scroll horizontally.
            return SingleChildScrollView(
              key: const ValueKey('week-grid-horizontal-scroll'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: timeColWidth + 4 + dayGridWidth + trailingDayGridInset,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: timeColWidth + 4,
                        bottom: 6,
                      ),
                      child: Row(
                        children: List.generate(dayCount, (i) {
                          final d = m.add(Duration(days: startDay + i));
                          final isToday =
                              d.year == today.year &&
                              d.month == today.month &&
                              d.day == today.day;
                          return Padding(
                            padding: EdgeInsets.only(
                              right: i == dayCount - 1 ? 0 : dayColGap,
                            ),
                            child: SizedBox(
                              width: dayColWidth,
                              child: Center(
                                child: Column(
                                  children: [
                                    Text(
                                      _dayShort[startDay + i],
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isToday
                                            ? cs.primary
                                            : cs.onSurfaceVariant.withValues(
                                                alpha: 0.8,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isToday
                                            ? cs.primary
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${d.day}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isToday
                                              ? cs.onPrimary
                                              : cs.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: timeColWidth,
                          height: totalHeight,
                          child: Stack(
                            children: filteredTimeLabels.isNotEmpty
                                ? filteredTimeLabels.map((t) {
                                    final top = (t - globalMin) * _ppm - 9;
                                    return Positioned(
                                      top: top,
                                      left: 0,
                                      right: 0,
                                      child: Text(
                                        _formatMinutes(t),
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurfaceVariant.withValues(
                                            alpha: 0.54,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList()
                                : ticks.map((tick) {
                                    final top = (tick - globalMin) * _ppm - 9;
                                    return Positioned(
                                      top: top,
                                      left: 0,
                                      right: 0,
                                      child: Text(
                                        _formatMinutes(tick),
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurfaceVariant.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(dayCount, (dayOffset) {
                            final dayIndex = startDay + dayOffset;
                            final lessons = (wd[dayIndex] ?? [])
                                .where(
                                  (l) => !hiddenSubjectsNotifier.value.contains(
                                    l['_subjectShort']?.toString() ?? '',
                                  ),
                                )
                                .toList();
                            final visibleLessons = lessons
                                .where(
                                  (l) =>
                                      showCancelledNotifier.value ||
                                      (l['code'] ?? '') != 'cancelled',
                                )
                                .toList();
                            final mergedLessons = _mergeConsecutiveLessons(
                              visibleLessons,
                            );
                            final lessonSlots = _computeLessonSlots(
                              mergedLessons,
                            );
                            return Container(
                              width: dayColWidth,
                              height: totalHeight,
                              margin: EdgeInsets.only(
                                right: dayOffset == dayCount - 1
                                    ? 0
                                    : dayColGap,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Stack(
                                    children: [
                                      ...ticks.map((tick) {
                                        final top = (tick - globalMin) * _ppm;
                                        return Positioned(
                                          top: top,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 0.45,
                                            color: cs.outlineVariant.withValues(
                                              alpha: 0.28,
                                            ),
                                          ),
                                        );
                                      }),
                                      ..._getHolidaysForDay(
                                        m.add(Duration(days: dayIndex)),
                                      ).map((holiday) {
                                        final holidayStartMin = _toMinutes(800);
                                        final holidayEndMin = _toMinutes(1800);
                                        final top2 =
                                            (holidayStartMin - globalMin) *
                                            _ppm;
                                        final height2 =
                                            ((holidayEndMin - holidayStartMin) *
                                                    _ppm)
                                                .clamp(24.0, 9999.0);
                                        final holidayName =
                                            (holiday['longName'] ??
                                                    holiday['name'] ??
                                                    '')
                                                .toString();
                                        return Positioned(
                                          top: top2,
                                          left: 1,
                                          right: 1,
                                          height: height2,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: cs.tertiaryContainer
                                                  .withValues(alpha: 0.85),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: cs.tertiary.withValues(
                                                  alpha: 0.4,
                                                ),
                                                width: 1.5,
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.celebration_rounded,
                                                  size: 16,
                                                  color: cs.tertiary,
                                                ),
                                                const SizedBox(height: 2),
                                                Expanded(
                                                  child: Text(
                                                    holidayName,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: cs
                                                          .onTertiaryContainer,
                                                    ),
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                      ...lessonSlots.map((slot) {
                                        final l = slot.lesson;
                                        final startMin = slot.startMin;
                                        final endMin = slot.endMin;
                                        final top =
                                            (startMin - globalMin) * _ppm;
                                        final height =
                                            ((endMin - startMin) * _ppm).clamp(
                                              24.0,
                                              9999.0,
                                            );
                                        final dim =
                                            (dayIndex == todayIndex) &&
                                            endMin <= nowMin;
                                        const horizontalInset = 1.0;
                                        const columnGap = 2.0;
                                        final columns = slot.columnCount;
                                        final availableWidth =
                                            constraints.maxWidth -
                                            (horizontalInset * 2);
                                        final totalGap =
                                            (columns - 1) * columnGap;
                                        final rawCardWidth =
                                            (availableWidth - totalGap) /
                                            columns;
                                        final cardWidth = rawCardWidth > 6
                                            ? rawCardWidth
                                            : 6.0;
                                        final left =
                                            horizontalInset +
                                            (slot.column *
                                                (cardWidth + columnGap));

                                        return Positioned(
                                          top: top,
                                          left: left,
                                          width: cardWidth,
                                          height: height,
                                          child: Builder(
                                            builder: (context) {
                                              final cs = Theme.of(
                                                context,
                                              ).colorScheme;
                                              final isDark2 =
                                                  Theme.of(
                                                    context,
                                                  ).brightness ==
                                                  Brightness.dark;
                                              final isCancelled =
                                                  (l['code'] ?? '') ==
                                                  'cancelled';
                                              final isTeacherMissing =
                                                  _hasMissingTeacher(l);
                                              final subject =
                                                  l['_subjectShort']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true
                                                  ? l['_subjectShort']
                                                        .toString()
                                                  : (l['_subjectLong']
                                                                ?.toString()
                                                                .isNotEmpty ==
                                                            true
                                                        ? l['_subjectLong']
                                                              .toString()
                                                        : '?');
                                              final room =
                                                  l['_room']?.toString() ?? '';
                                              final teacher =
                                                  l['_teacher']?.toString() ??
                                                  '';
                                              final sk2 =
                                                  l['_subjectShort']
                                                      ?.toString() ??
                                                  '';
                                              final useMonochrome2 =
                                                  monochromeLessonsNotifier
                                                      .value;
                                              final cancelledColor2 = Color(
                                                cancelledLessonColorNotifier
                                                    .value,
                                              );
                                              final cv2 =
                                                  isCancelled || useMonochrome2
                                                  ? null
                                                  : subjectColorsNotifier
                                                        .value[sk2];
                                              final fgColor = isCancelled
                                                  ? cancelledColor2
                                                  : useMonochrome2
                                                  ? Color(
                                                      monochromeLessonColorNotifier
                                                          .value,
                                                    )
                                                  : cv2 != null
                                                  ? Color(cv2)
                                                  : _autoLessonColor(
                                                      sk2,
                                                      isDark2,
                                                    );
                                              final bgColor = isCancelled
                                                  ? Color.alphaBlend(
                                                      cancelledColor2
                                                          .withValues(
                                                            alpha: isDark2
                                                                ? 0.14
                                                                : 0.10,
                                                          ),
                                                      cs.surfaceContainerHighest,
                                                    )
                                                  : Color.alphaBlend(
                                                      fgColor.withValues(
                                                        alpha: isDark2
                                                            ? 0.14
                                                            : 0.10,
                                                      ),
                                                      cs.surfaceContainerHighest,
                                                    );
                                              final isCurrent =
                                                  (dayIndex == todayIndex) &&
                                                  (slot.startMin <= nowMin &&
                                                      nowMin < slot.endMin);
                                              final isNow = isCurrent;

                                              final lDateInt =
                                                  int.tryParse(
                                                    l['date']?.toString() ?? '',
                                                  ) ??
                                                  0;
                                              final hasHomework =
                                                  homeworksNotifier.value.any(
                                                    (hw) =>
                                                        hw['dueDate'] ==
                                                            lDateInt &&
                                                        (hw['subject'] == sk2 ||
                                                            hw['subject'] ==
                                                                subject),
                                                  ) ||
                                                  customHomeworkNotifier.value
                                                      .any(
                                                        (hw) =>
                                                            hw['dueDate'] ==
                                                                lDateInt &&
                                                            (hw['subject'] ==
                                                                    sk2 ||
                                                                hw['subject'] ==
                                                                    subject),
                                                      );
                                              final hasExam =
                                                  apiExamsNotifier.value.any(
                                                    (ex) =>
                                                        (ex['date'] ??
                                                                ex['examDate'] ??
                                                                0) ==
                                                            lDateInt &&
                                                        (ex['subject'] == sk2 ||
                                                            ex['subjectName'] ==
                                                                sk2 ||
                                                            ex['subject'] ==
                                                                subject),
                                                  ) ||
                                                  customExamsNotifier.value.any(
                                                    (ex) =>
                                                        (ex['date'] ?? 0) ==
                                                            lDateInt &&
                                                        (ex['subject'] == sk2 ||
                                                            ex['subject'] ==
                                                                subject),
                                                  );

                                              final highlightMatch =
                                                  _isHighlightMatch(l);
                                              Widget lessonTile = GestureDetector(
                                                onTap: () =>
                                                    _onLessonTap(context, l),
                                                onLongPress: () =>
                                                    _editLessonTemporarily(l),
                                                child: _buildTimetableLessonCard(
                                                  context: context,
                                                  isCancelled: isCancelled,
                                                  isDark: isDark2,
                                                  fgColor: fgColor,
                                                  bgColor: bgColor,
                                                    subject: subject,
                                                    subjectIcon:
                                                        _subjectIconFor(
                                                          sk2,
                                                          subject,
                                                        ),
                                                    teacher: teacher,
                                                    room: room,
                                                    isNow: isNow,
                                                    isTeacherMissing:
                                                        isTeacherMissing,
                                                    hasHomework: hasHomework,
                                                    hasExam: hasExam,
                                                    originalTeacher:
                                                        _originalTeachers[
                                                              _lessonIdentityOf(
                                                                l,
                                                              )
                                                            ] ??
                                                        '',
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                          8,
                                                          5,
                                                          6,
                                                          5,
                                                        ),
                                                    accentWidth: 3.5,
                                                    subjectFontSize: 11.5,
                                                    teacherFontSize: 9.5,
                                                    roomFontSize: 9.5,
                                                    useStripes: true,
                                                    availableWidth: cardWidth,
                                                    availableHeight: height,
                                                  ),
                                                );
                                              if (highlightMatch) {
                                                lessonTile = AnimatedBuilder(
                                                  animation:
                                                      _highlightController!,
                                                  builder: (context, child) {
                                                    final t =
                                                        _highlightController!
                                                            .value;
                                                    final glow =
                                                        (math
                                                                    .sin(
                                                                      t *
                                                                          math
                                                                              .pi,
                                                                    ) *
                                                                (1 - t)) *
                                                            0.75;
                                                    if (glow <= 0.02) {
                                                      return child!;
                                                    }
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(18),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: cs.tertiary
                                                                .withValues(
                                                                  alpha: glow,
                                                                ),
                                                            blurRadius: 26,
                                                            spreadRadius: 6,
                                                          ),
                                                        ],
                                                      ),
                                                      child: child,
                                                    );
                                                  },
                                                  child: lessonTile,
                                                );
                                              }
                                              return _dimPastLesson(
                                                dim: dim,
                                                child: lessonTile,
                                              );
                                            },
                                          ),
                                        );
                                      }),
                                      if (showNowLine && dayIndex == todayIndex)
                                        Positioned(
                                          top: nowTop - 1.5,
                                          left: 0,
                                          right: 0,
                                          child: IgnorePointer(
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: cs.error,
                                                    shape: BoxShape.circle,
                                                    boxShadow:
                                                        _glowShadows(context, [
                                                          BoxShadow(
                                                            color: cs.error
                                                                .withValues(
                                                                  alpha: 0.35,
                                                                ),
                                                            blurRadius: 3,
                                                            spreadRadius: 0.5,
                                                          ),
                                                        ]),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Container(
                                                    height: 2,
                                                    decoration: BoxDecoration(
                                                      color: cs.error,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            2,
                                                          ),
                                                      boxShadow: _glowShadows(
                                                        context,
                                                        [
                                                          BoxShadow(
                                                            color: cs.error
                                                                .withValues(
                                                                  alpha: 0.25,
                                                                ),
                                                            blurRadius: 3,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _fetchHolidays() async {
    try {
      final url = Uri.parse(
        'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
      );
      final response = await http.post(
        url,
        headers: {
          "Cookie": "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "id": "holidays",
          "method": "getHolidays",
          "params": {},
          "jsonrpc": "2.0",
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['result'] is List) {
          final holidays = (decoded['result'] as List)
              .whereType<Map>()
              .map((h) => Map<String, dynamic>.from(h.cast<String, dynamic>()))
              .toList();
          if (mounted) {
            setState(() => _holidays = holidays);
          }
        }
      }
    } catch (_) {}
  }

  bool _isSessionExpired() {
    if (_currentSessionId.isEmpty) return true;
    final account = activeUntisAccount;
    if (account == null) return false;
    final age = DateTime.now().difference(account.lastUsedAt);
    return age.inMinutes >= 8;
  }

  Future<void> _fetchFullWeek({bool silent = false}) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final requestGeneration = ++_weekFetchGeneration;
    final requestedMonday = _currentMonday;
    final requestAccountId = activeUntisAccountId ?? 'legacy';
    bool isCurrentRequest() =>
        mounted &&
        requestGeneration == _weekFetchGeneration &&
        (activeUntisAccountId ?? 'legacy') == requestAccountId &&
        _currentMonday == requestedMonday;

    if (personId == 0 && personType == 0) {}

    _holidays = [];

    final isDemoMode = demoModeNotifier.value;

    var requestPersonId = _viewingClassId ?? personId;
    var requestPersonType = _viewingClassId != null ? 1 : personType;

    if (isDemoMode) {
      requestPersonId = DemoModeService.demoPersonId;
      requestPersonType = DemoModeService.demoPersonType;
    }

    if (requestPersonId == 0) {
      if (requestPersonType == 0) requestPersonType = 5;
    }

    if (isDemoMode) {
      final tempWeek = DemoModeService.buildWeek(
        requestedMonday,
        locale: appLocaleNotifier.value,
      );
      _applyKnownSubjectsFromWeek(tempWeek);
      if (!isCurrentRequest()) return;
      setState(() {
        _weekData = tempWeek;
        _showingCachedWeek = false;
        _loading = false;
        _loadError = null;
      });
      currentWeekDataNotifier.value = tempWeek;
      // Demo data is already complete. Persistence, homework and home-widget
      // refreshes must not keep the timetable behind a loading indicator.
      unawaited(_fetchHomeworkAndNotes());
      unawaited(
        _saveWeekToCache(
          requestPersonId: requestPersonId,
          requestPersonType: requestPersonType,
          weekData: tempWeek,
          monday: requestedMonday,
        ),
      );
      unawaited(_updateHomeWidgets(tempWeek));
      return;
    }

    final hasExistingWeek = _weekData.values.any((l) => l.isNotEmpty);
    final cachedWeek = (!silent || !hasExistingWeek)
        ? await _loadWeekFromCache(
            requestPersonId: requestPersonId,
            requestPersonType: requestPersonType,
          )
        : null;
    if (!isCurrentRequest()) return;
    final hasCachedWeek =
        hasExistingWeek ||
        (cachedWeek != null && cachedWeek.values.any((l) => l.isNotEmpty));
    if (cachedWeek != null &&
        cachedWeek.values.any((l) => l.isNotEmpty) &&
        mounted) {
      _applyKnownSubjectsFromWeek(cachedWeek);
      setState(() {
        _weekData = cachedWeek;
        _showingCachedWeek = true;
        _loading = false;
        _loadError = null;
      });
      currentWeekDataNotifier.value = cachedWeek;
      unawaited(_updateHomeWidgets(cachedWeek));
      // Populate the carousel from disk straight away. This avoids showing
      // stale lesson state during the first swipe while the online refresh is
      // still in flight (notably for already cached cancellations).
      unawaited(_prefetchAdjacentWeeks(allowNetwork: false));
    } else if (!silent && mounted && !hasCachedWeek) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    if (_subjectShortMap.isEmpty || _teacherMap.isEmpty || _roomMap.isEmpty) {
      await _loadMasterDataFromCache();
    }
    // The cached week is now (re)enriched with the freshly loaded master data
    // so teacher names follow the current display setting.
    if (hasCachedWeek &&
        (_teacherMap.isNotEmpty || _teacherShortMap.isNotEmpty)) {
      _reEnrichWeek(_weekData);
      currentWeekDataNotifier.value = Map<int, List<dynamic>>.from(_weekData);
    }

    // Guardian accounts (type 3) always re-authenticate so a linked student
    // can be resolved; the timetable for the parent element itself is empty.
    if ((_currentSessionId.isEmpty ||
            _isSessionExpired() ||
            requestPersonType == 3) &&
        !isDemoMode) {
      final ok = await _reAuthenticate();
      if (!ok && !hasCachedWeek) {
        if (!mounted) return;
        setState(() {
          _loadError = l.timetableNotSignedIn;
          _weekData = _emptyWeekData();
          _showingCachedWeek = false;
          _loading = false;
        });
        return;
      }
      // Re-read the person after a guardian account may have been redirected
      // to its first child during re-authentication.
      requestPersonId = _viewingClassId ?? personId;
      requestPersonType = _viewingClassId != null ? 1 : personType;
    }

    DateTime friday = requestedMonday.add(const Duration(days: 4));
    int startDate = int.parse(DateFormat('yyyyMMdd').format(requestedMonday));
    int endDate = int.parse(DateFormat('yyyyMMdd').format(friday));

    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );

    try {
      final timetableFuture = http
          .post(
            url,
            headers: {
              "Cookie": "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              "id": "week_req",
              "method": "getTimetable",
              "params": {
                "options": {
                  "element": {"id": requestPersonId, "type": requestPersonType},
                  "startDate": startDate,
                  "endDate": endDate,
                  "showLsText": true,
                  "showSubstText": true,
                  "showInfo": true,
                  "showBooking": true,
                },
              },
              "jsonrpc": "2.0",
            }),
          )
          .timeout(const Duration(seconds: 8));

      unawaited(_fetchMasterData());
      unawaited(_fetchHomeworkAndNotes());

      final response = await timetableFuture;

      if (!isCurrentRequest()) return;

      if (response.statusCode != 200) {
        if (hasCachedWeek) {
          if (!mounted) return;
          setState(() {
            _loadError = null;
            _showingCachedWeek = true;
            _loading = false;
          });
          return;
        }
        if (!mounted) return;
        setState(() {
          _loadError = l.timetableHttpError(response.statusCode);
          _weekData = _emptyWeekData();
          _showingCachedWeek = false;
          _loading = false;
        });
        return;
      }

      final decodedResponse = jsonDecode(response.body);

      if (decodedResponse['error'] != null) {
        final errCode = decodedResponse['error']['code'] as int? ?? 0;
        final apiMsg =
            decodedResponse['error']['message']?.toString() ??
            l.timetableUnknownApiError;

        if (apiMsg.toLowerCase().contains('not within a school year') ||
            apiMsg.toLowerCase().contains('nicht in einem schuljahr')) {
          try {
            final syRes = await http
                .post(
                  url,
                  headers: {
                    "Cookie":
                        "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
                    "Content-Type": "application/json",
                  },
                  body: jsonEncode({
                    "id": "sy_req",
                    "method": "getCurrentSchoolyear",
                    "params": {},
                    "jsonrpc": "2.0",
                  }),
                )
                .timeout(const Duration(seconds: 6));
            if (syRes.statusCode == 200) {
              final syDecoded = jsonDecode(syRes.body);
              if (syDecoded['result'] != null) {
                final sy = syDecoded['result'];
                final syStart = sy['startDate'].toString();
                if (syStart.length == 8) {
                  final syStartDate = DateTime.parse(
                    "${syStart.substring(0, 4)}-${syStart.substring(4, 6)}-${syStart.substring(6, 8)}",
                  );
                  // Adjust current monday to start of school year if we are far away
                  if (!isCurrentRequest()) return;
                  if (_currentMonday.isBefore(syStartDate)) {
                    _currentMonday = syStartDate.subtract(
                      Duration(days: syStartDate.weekday - 1),
                    );
                    await _fetchFullWeek(silent: silent);
                    return;
                  }
                }
              }
            }
          } catch (_) {}
        }

        if (errCode == -8504 ||
            apiMsg.toLowerCase().contains('not authenticated')) {
          final ok = await _reAuthenticate();
          if (ok) {
            await _fetchFullWeek(silent: silent);
            return;
          }
        }

        if (!isCurrentRequest()) return;
        if (hasCachedWeek) {
          if (!mounted) return;
          setState(() {
            _loadError = null;
            _showingCachedWeek = true;
            _loading = false;
          });
          return;
        }

        if (_isNoAllowedDateError(apiMsg)) {
          if (!mounted) return;
          setState(() {
            _loadError = null;
            _weekData = _emptyWeekData();
            _showingCachedWeek = false;
            _loading = false;
          });
          return;
        }

        if (!mounted) return;
        setState(() {
          _loadError = apiMsg;
          _weekData = _emptyWeekData();
          _showingCachedWeek = false;
          _loading = false;
        });
        return;
      }

      final dynamic result = decodedResponse['result'];
      final List<dynamic> allLessons = switch (result) {
        List<dynamic> r => r,
        Map r when r['timetable'] is List<dynamic> =>
          (r['timetable'] as List<dynamic>),
        _ => <dynamic>[],
      };
      Map<int, List<dynamic>> tempWeek = _emptyWeekData();
      final classIdsInWeek = <int>{};

      for (var lesson in allLessons) {
        String dStr = lesson['date'].toString();
        if (dStr.length == 8) {
          DateTime lessonDate = DateTime.parse(
            "${dStr.substring(0, 4)}-${dStr.substring(4, 6)}-${dStr.substring(6, 8)}",
          );
          int dayIndex = lessonDate.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 5) {
            final subId = (lesson['su'] as List?)?.firstOrNull?['id'] as int?;
            final roId = (lesson['ro'] as List?)?.firstOrNull?['id'] as int?;
            final klId = (lesson['kl'] as List?)?.firstOrNull?['id'] as int?;
            if (klId != null) classIdsInWeek.add(klId);

            final lessonMap = lesson as Map<dynamic, dynamic>;
            final teacherFromTe = _extractTeacherNamesFromLesson(lessonMap);
            final teacherFromTopLevel = _extractTeacherNamesFromTopLevel(
              lessonMap,
            );
            final teacherResolved = teacherFromTe.isNotEmpty
                ? teacherFromTe
                : teacherFromTopLevel;

            final lstext = (lesson['lstext'] ?? '').toString().trim();
            final eventName = lstext.isNotEmpty
                ? lstext
                : (lesson['eventText'] ?? lesson['eventReason'] ?? '')
                      .toString()
                      .trim();
            final isAllDayEvent =
                (lesson['startTime'] == 0 && lesson['endTime'] != null);

            final resolvedLesson = Map<String, dynamic>.from(lesson);
            if (isAllDayEvent) {
              resolvedLesson['startTime'] = 800;
              resolvedLesson['endTime'] = 1800;
            }
            resolvedLesson['_subjectLong'] =
                (lesson['su'] as List?)?.firstOrNull?['longname'] ??
                (lesson['su'] as List?)?.firstOrNull?['longName'] ??
                _subjectLong[subId] ??
                (eventName.isNotEmpty ? eventName : '');
            resolvedLesson['_subjectShort'] =
                (lesson['su'] as List?)?.firstOrNull?['name'] ??
                _subjectShortMap[subId] ??
                (eventName.isNotEmpty ? eventName : '');
            resolvedLesson['_teacher'] = teacherResolved;
            // WebUntis returns `ro` as either a list, a single map or just an
            // ID depending on the timetable endpoint. Normalize every form so
            // a week fetched after the carousel snap cannot lose room #2.
            final rawRooms = lesson['ro'];
            final roomEntries = rawRooms is Iterable
                ? rawRooms
                : rawRooms == null
                ? const <dynamic>[]
                : <dynamic>[rawRooms];
            final roomNames = roomEntries
                .map((rawRoom) {
                  if (rawRoom is Map) {
                    final id = int.tryParse(rawRoom['id']?.toString() ?? '');
                    return (rawRoom['name']?.toString() ?? _roomMap[id] ?? '')
                        .trim();
                  }
                  final id = int.tryParse(rawRoom.toString());
                  return _roomMap[id] ?? '';
                })
                .where((name) => name.isNotEmpty)
                .toSet()
                .toList(growable: false);
            resolvedLesson['_room'] = roomNames.isNotEmpty
                ? roomNames.join(', ')
                : (_roomMap[roId] ?? '');
            resolvedLesson['_classNames'] =
                (lesson['kl'] as List?)
                    ?.map((k) => k['name']?.toString() ?? '')
                    .where((n) => n.isNotEmpty)
                    .join(', ') ??
                '';
            resolvedLesson['_activityType'] = (lesson['activityType'] ?? '')
                .toString();
            resolvedLesson['_eventName'] = eventName;
            resolvedLesson['_lessonInfo'] =
                (lesson['info'] ?? lesson['substText'] ?? '').toString().trim();
            resolvedLesson['_teacherMissing'] = _hasMissingTeacher(lesson);

            tempWeek[dayIndex]!.add(resolvedLesson);
          }
        }
      }

      tempWeek.forEach((key, list) {
        list.sort((a, b) {
          final aStart = (a['startTime'] as num?)?.toInt() ?? 0;
          final bStart = (b['startTime'] as num?)?.toInt() ?? 0;
          return aStart.compareTo(bStart);
        });
      });

      final missingTeacherLessons = tempWeek.values
          .expand((day) => day)
          .where((l) => ((l['_teacher'] ?? '').toString().trim().isEmpty))
          .toList();
      if (missingTeacherLessons.isNotEmpty) {
        // Resolve the data snapshot before it becomes visible. A week must
        // never repaint merely because its teacher directory arrived later.
        await _resolveMissingTeachers(
          tempWeek: tempWeek,
          missingTeacherLessons: missingTeacherLessons,
          requestGeneration: requestGeneration,
          requestedMonday: requestedMonday,
          requestAccountId: requestAccountId,
          requestPersonId: requestPersonId,
          requestPersonType: requestPersonType,
          startDate: startDate,
          endDate: endDate,
          classIdsInWeek: classIdsInWeek,
        );
      }
      if (!isCurrentRequest()) return;
      _applyKnownSubjectsFromWeek(tempWeek);
      setState(() {
        _weekData = tempWeek;
        _showingCachedWeek = false;
        _loading = false;
        _loadError = null;
      });
      currentWeekDataNotifier.value = tempWeek;
      unawaited(_updateHomeWidgets(tempWeek));
      unawaited(_fetchHolidays());

      final flattenedLessons = tempWeek.values
          .expand((day) => day)
          .whereType<Map>();
      if (!isDemoMode && flattenedLessons.isNotEmpty) {
        ChangeRepository()
            .recordSnapshot(
              accountId: requestAccountId,
              rangeKey: DateFormat('yyyyMMdd').format(requestedMonday),
              lessons: flattenedLessons,
            )
            .then((changes) {
              _applyOriginalTeachers(changes);
              if (isCurrentRequest()) {
                unreadTimetableChangesNotifier.value = changes
                    .where((change) => !change.isRead)
                    .length;
              }
            })
            .catchError((_) {});
      }

      unawaited(
        _saveWeekToCache(
          requestPersonId: requestPersonId,
          requestPersonType: requestPersonType,
          weekData: tempWeek,
          monday: requestedMonday,
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (isCurrentRequest()) {
          _prefetchAdjacentWeeks();
        }
      });
    } catch (e) {
      debugPrint("Fehler beim Laden: $e");
      if (!isCurrentRequest()) return;
      if (hasCachedWeek) {
        if (!mounted) return;
        setState(() {
          _loadError = null;
          _showingCachedWeek = true;
          _loading = false;
        });
        return;
      }

      final errMsg = e.toString();
      if (_isNoAllowedDateError(errMsg)) {
        if (!mounted) return;
        setState(() {
          _loadError = null;
          _weekData = _emptyWeekData();
          _showingCachedWeek = false;
          _loading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _loadError = l.timetableLoadError;
        _weekData = _emptyWeekData();
        _showingCachedWeek = false;
        _loading = false;
      });
    }
  }

  Future<void> _resolveMissingTeachers({
    required Map<int, List<dynamic>> tempWeek,
    required List<dynamic> missingTeacherLessons,
    required int requestGeneration,
    required DateTime requestedMonday,
    required String requestAccountId,
    required int requestPersonId,
    required int requestPersonType,
    required int startDate,
    required int endDate,
    required Set<int> classIdsInWeek,
  }) async {
    bool isCurrent() =>
        mounted &&
        requestGeneration == _weekFetchGeneration &&
        (activeUntisAccountId ?? 'legacy') == requestAccountId &&
        _currentMonday == requestedMonday;

    if (!isCurrent()) return;

    final exactKeyToTeacher = <String, String>{};
    final looseKeyToTeacher = <String, String>{};

    // Fallback 1: Public weekly endpoint often contains teacher IDs in
    // period elements (type=2) even when JSON-RPC omits `te`.
    try {
      final weeklyDate = DateFormat('yyyy-MM-dd').format(requestedMonday);
      final publicUri =
          Uri.https(schoolUrl, '/WebUntis/api/public/timetable/weekly/data', {
            'elementType': requestPersonType.toString(),
            'elementId': requestPersonId.toString(),
            'date': weeklyDate,
            'formatId': '2',
          });
      final publicResp = await http
          .get(
            publicUri,
            headers: {
              "Cookie": "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 5));
      if (publicResp.statusCode == 200) {
        final decoded = jsonDecode(publicResp.body);
        final data = decoded is Map
            ? (((decoded['data'] as Map?)?['result'] as Map?)?['data'] as Map?)
            : null;
        final elements = (data?['elements'] as List?) ?? const <dynamic>[];
        final teacherNameById = <int, String>{};
        for (final e in elements) {
          if (e is! Map) continue;
          if ((e['type'] as int?) != 2) continue;
          final id = e['id'] as int?;
          if (id == null) continue;
          final n =
              (e['longName'] ??
                      e['longname'] ??
                      e['displayname'] ??
                      e['name'] ??
                      '')
                  .toString()
                  .trim();
          if (n.isNotEmpty) teacherNameById[id] = n;
        }

        final elementPeriods = (data?['elementPeriods'] as Map?) ?? const {};
        final periodsForElement = elementPeriods[requestPersonId.toString()];
        final periods = periodsForElement is List
            ? periodsForElement
            : const <dynamic>[];
        for (final p in periods) {
          if (p is! Map) continue;
          final pElements = (p['elements'] as List?) ?? const <dynamic>[];
          int? subjectId;
          int? roomId;
          final teacherNames = <String>[];
          for (final pe in pElements) {
            if (pe is! Map) continue;
            final t = pe['type'] as int?;
            final id = pe['id'] as int?;
            if (t == 3 && id != null) subjectId ??= id;
            if (t == 4 && id != null) roomId ??= id;
            if (t == 2 && id != null) {
              final tn = teacherNameById[id];
              if (tn != null && tn.isNotEmpty && !teacherNames.contains(tn)) {
                teacherNames.add(tn);
              }
            }
          }
          final teacherJoined = teacherNames.join(', ');
          if (teacherJoined.isEmpty || subjectId == null) continue;

          final exactKey = _lessonTeacherKeyFromParts(
            date: p['date'],
            startTime: p['startTime'],
            endTime: p['endTime'],
            subjectId: subjectId,
            roomId: roomId,
            withRoom: true,
          );
          final looseKey = _lessonTeacherKeyFromParts(
            date: p['date'],
            startTime: p['startTime'],
            endTime: p['endTime'],
            subjectId: subjectId,
            withRoom: false,
          );
          exactKeyToTeacher.putIfAbsent(exactKey, () => teacherJoined);
          looseKeyToTeacher.putIfAbsent(looseKey, () => teacherJoined);
        }
      }
    } catch (_) {}

    if (!isCurrent()) return;

    // Fallback 2: Query related class timetables and try key matching.
    final stillMissing = missingTeacherLessons.any((l) {
      if (l is! Map) return false;
      final lMap = Map<dynamic, dynamic>.from(l);
      final exact = exactKeyToTeacher[_lessonTeacherKey(lMap, withRoom: true)];
      final loose = looseKeyToTeacher[_lessonTeacherKey(lMap, withRoom: false)];
      return (exact ?? loose ?? '').isEmpty;
    });

    if (stillMissing && classIdsInWeek.isNotEmpty) {
      final url = Uri.parse(
        'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
      );
      final classesToQuery = classIdsInWeek.take(6);
      await Future.wait(
        classesToQuery.map((classId) async {
          try {
            final classResp = await http
                .post(
                  url,
                  headers: {
                    "Cookie":
                        "JSESSIONID=$_currentSessionId; schoolname=$schoolName",
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                  },
                  body: jsonEncode({
                    "id": "week_class_$classId",
                    "method": "getTimetable",
                    "params": {
                      "options": {
                        "element": {"id": classId, "type": 1},
                        "startDate": startDate,
                        "endDate": endDate,
                        "showLsText": true,
                        "showSubstText": true,
                        "showInfo": true,
                        "showBooking": true,
                      },
                    },
                    "jsonrpc": "2.0",
                  }),
                )
                .timeout(const Duration(seconds: 4));
            if (classResp.statusCode != 200) return;
            final classJson = jsonDecode(classResp.body);
            if (classJson is! Map || classJson['error'] != null) return;
            final classResult = classJson['result'];
            final List<dynamic> classLessons = switch (classResult) {
              List<dynamic> r => r,
              Map r when r['timetable'] is List<dynamic> =>
                (r['timetable'] as List<dynamic>),
              _ => <dynamic>[],
            };
            for (final lRaw in classLessons) {
              if (lRaw is! Map) continue;
              final lMap = Map<dynamic, dynamic>.from(lRaw);
              final t = _extractTeacherNamesFromLesson(lMap);
              if (t.isEmpty) continue;
              exactKeyToTeacher.putIfAbsent(
                _lessonTeacherKey(lMap, withRoom: true),
                () => t,
              );
              looseKeyToTeacher.putIfAbsent(
                _lessonTeacherKey(lMap, withRoom: false),
                () => t,
              );
            }
          } catch (_) {}
        }),
      );
    }

    if (!isCurrent()) return;

    var updatedAny = false;
    for (final l in missingTeacherLessons) {
      if (l is! Map) continue;
      final lMap = Map<dynamic, dynamic>.from(l);
      final exact = exactKeyToTeacher[_lessonTeacherKey(lMap, withRoom: true)];
      final loose = looseKeyToTeacher[_lessonTeacherKey(lMap, withRoom: false)];
      final fallbackTeacher = exact ?? loose ?? '';
      if (fallbackTeacher.isNotEmpty && l['_teacher'] != fallbackTeacher) {
        l['_teacher'] = fallbackTeacher;
        updatedAny = true;
      }
    }

    // The caller publishes this complete snapshot atomically. Keeping this
    // method mutation-only prevents delayed teacher lookups from refreshing a
    // different week after the user has already switched away.
    if (updatedAny && !isCurrent()) return;
  }

  Future<String?> _authenticateAnonymous() async {
    try {
      final url = Uri.parse(
        'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
      );
      final response = await http.post(
        url,
        body: jsonEncode({
          "id": "anon",
          "method": "authenticate",
          "params": {"user": "", "password": "", "client": "UntisPlus"},
          "jsonrpc": "2.0",
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result']['sessionId'] != null) {
          return data['result']['sessionId'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _openClassSearch() async {
    showUntisDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final url = Uri.parse(
      'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
    );

    Future<List<dynamic>> fetchClassesForSession(String sid) async {
      final response = await http.post(
        url,
        headers: {"Cookie": "JSESSIONID=$sid; schoolname=$schoolName"},
        body: jsonEncode({
          "id": "fe_kl",
          "method": "getKlassen",
          "params": {},
          "jsonrpc": "2.0",
        }),
      );
      if (response.statusCode != 200) return const <dynamic>[];
      final data = jsonDecode(response.body);
      if (data is Map && data['result'] is List) {
        return data['result'] as List<dynamic>;
      }
      return const <dynamic>[];
    }

    String? sid;
    List<dynamic> classes = demoModeNotifier.value
        ? DemoModeService.demoClasses()
        : [];

    if (!demoModeNotifier.value && sessionID.isNotEmpty) {
      try {
        classes = await fetchClassesForSession(sessionID);
        if (classes.isNotEmpty) {
          sid = sessionID;
        }
      } catch (_) {}
    }

    if (!demoModeNotifier.value && classes.isEmpty) {
      try {
        final anonSid = await _authenticateAnonymous();
        if (anonSid != null && anonSid.isNotEmpty) {
          final anonClasses = await fetchClassesForSession(anonSid);
          if (anonClasses.isNotEmpty) {
            classes = anonClasses;
            sid = anonSid;
          }
        }
      } catch (_) {}
    }

    sid ??= sessionID;

    if (!mounted) return;
    Navigator.of(context).pop();

    try {
      if (classes.isNotEmpty) {
        classes.sort(
          (a, b) => (a['name']?.toString() ?? '').compareTo(
            b['name']?.toString() ?? '',
          ),
        );
      }
    } catch (_) {}

    final l = AppL10n.of(appLocaleNotifier.value);

    showUntisModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: _kBottomSheetAnimationStyle,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final List<dynamic> sortedClasses = List.from(classes);
            sortedClasses.sort((a, b) {
              final idA = a['id'] as int?;
              final idB = b['id'] as int?;
              final isFavA = idA != null && favoriteClassIds.contains(idA);
              final isFavB = idB != null && favoriteClassIds.contains(idB);
              if (isFavA && !isFavB) return -1;
              if (!isFavA && isFavB) return 1;
              final nameA = (a['name'] ?? a['longName'] ?? '').toString();
              final nameB = (b['name'] ?? b['longName'] ?? '').toString();
              return nameA.compareTo(nameB);
            });

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return _glassContainer(
                  context: ctx,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l.timetableSelectClass,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.classPickerHeaderDesc,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.96),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 0,
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: blurEnabledNotifier.value ? 0.88 : 0.94,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            _expressiveRadius(
                              context,
                              16,
                              expressiveRadius: 28,
                            ),
                          ),
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.58),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.person,
                            color: cs.primary.withValues(alpha: 0.95),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.timetableMyTimetable,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: cs.onSurface.withValues(alpha: 0.99),
                                  ),
                                ),
                              ),
                              if (defaultClassId == null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l.classPickerDefaultBadge,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            tooltip: l.classPickerSetDefault,
                            icon: Icon(
                              defaultClassId == null
                                  ? Icons.home_rounded
                                  : Icons.add_rounded,
                              color: defaultClassId == null
                                  ? cs.primary
                                  : cs.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              setSheetState(() {
                                defaultClassId = null;
                                defaultClassName = null;
                              });
                              await prefs.remove('defaultClassId');
                              await prefs.remove('defaultClassName');
                              setState(() {});
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _viewingClassId = null;
                              _viewingClassName = null;
                              _tempSessionId = null;
                            });
                            Navigator.pop(ctx);
                            _fetchFullWeek();
                          },
                        ),
                      ),
                      if (sortedClasses.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              l.classPickerOtherClasses,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.94,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...sortedClasses.asMap().entries.map((entry) {
                              final i = entry.key;
                              final c = entry.value;
                              final name = (c['name'] ?? c['longName'] ?? '?')
                                  .toString();
                              final id = c['id'] as int?;
                              if (id == null) return const SizedBox.shrink();

                              final isFavorite = favoriteClassIds.contains(id);
                              final isDefault = defaultClassId == id;

                              return _springEntry(
                                duration: Duration(milliseconds: 300 + i * 45),
                                offsetY: 16,
                                startScale: 0.95,
                                curve: _kSmoothBounce,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Card(
                                    elevation: 0,
                                    color: cs.surfaceContainerHigh.withValues(
                                      alpha: blurEnabledNotifier.value
                                          ? 0.86
                                          : 0.92,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        _expressiveRadius(
                                          context,
                                          16,
                                          expressiveRadius: 28,
                                        ),
                                      ),
                                      side: BorderSide(
                                        color: cs.outlineVariant.withValues(
                                          alpha: 0.54,
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        isFavorite
                                            ? Icons.star_rounded
                                            : Icons.class_outlined,
                                        color: isFavorite
                                            ? Colors.amber.shade600
                                            : cs.primary.withValues(
                                                alpha: 0.95,
                                              ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: GoogleFonts.outfit(
                                                fontWeight: isFavorite
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                fontSize: 16,
                                                color: cs.onSurface.withValues(
                                                  alpha: 0.99,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isDefault) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: cs.primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                l.classPickerDefaultBadge,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: cs.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: isFavorite
                                                ? l.classPickerRemoveFavorite
                                                : l.classPickerAddFavorite,
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.star_rounded
                                                  : Icons.star_outline_rounded,
                                              color: isFavorite
                                                  ? Colors.amber.shade600
                                                  : cs.onSurfaceVariant
                                                        .withValues(alpha: 0.6),
                                            ),
                                            onPressed: () async {
                                              final prefs =
                                                  await SharedPreferences.getInstance();
                                              setSheetState(() {
                                                if (isFavorite) {
                                                  favoriteClassIds.remove(id);
                                                } else {
                                                  favoriteClassIds.add(id);
                                                }
                                              });
                                              await prefs.setStringList(
                                                'favoriteClassIds',
                                                favoriteClassIds
                                                    .map((id) => id.toString())
                                                    .toList(),
                                              );
                                              setState(() {});
                                            },
                                          ),
                                          IconButton(
                                            tooltip: isDefault
                                                ? l.classPickerDefaultBadge
                                                : l.classPickerSetDefault,
                                            icon: Icon(
                                              isDefault
                                                  ? Icons.home_rounded
                                                  : Icons.add_rounded,
                                              color: isDefault
                                                  ? cs.primary
                                                  : cs.onSurfaceVariant
                                                        .withValues(alpha: 0.6),
                                            ),
                                            onPressed: () async {
                                              final prefs =
                                                  await SharedPreferences.getInstance();
                                              setSheetState(() {
                                                if (isDefault) {
                                                  defaultClassId = null;
                                                  defaultClassName = null;
                                                } else {
                                                  defaultClassId = id;
                                                  defaultClassName = name;
                                                }
                                              });
                                              if (defaultClassId == null) {
                                                await prefs.remove(
                                                  'defaultClassId',
                                                );
                                                await prefs.remove(
                                                  'defaultClassName',
                                                );
                                              } else {
                                                await prefs.setInt(
                                                  'defaultClassId',
                                                  defaultClassId!,
                                                );
                                                await prefs.setString(
                                                  'defaultClassName',
                                                  defaultClassName!,
                                                );
                                              }
                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _viewingClassId = id;
                                          _viewingClassName = name;
                                          _tempSessionId =
                                              (sid != null && sid != sessionID)
                                              ? sid
                                              : null;
                                        });
                                        Navigator.pop(ctx);
                                        _fetchFullWeek();
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            l.timetableNoClassesFound,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final dayIndicatorIndex = (_dayCarouselTargetDay ?? _tabController.index)
        .clamp(0, 4)
        .toInt();
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: RoundedBlurAppBar(
        leading: _untisDropdownMenu(
          context: context,
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.groups_rounded),
              onPressed: _openClassSearch,
              child: Text(l.timetableSelectAnother),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.meeting_room_outlined),
              onPressed: _showFreeRoomsDialog,
              child: Text(l.freeRoomsTitle),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.ios_share_rounded),
              onPressed: _exportTimetableImage,
              child: Text(l.timetableExportImage),
            ),
          ],
          builder: (context, controller, child) => IconButton(
            tooltip: l.timetableMoreActions,
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
        ),
        title: GestureDetector(
          onTap: () {
            final thisMonday = resolveDefaultTimetableMonday(DateTime.now());
            if (_currentMonday != thisMonday) {
              HapticFeedback.selectionClick();
              setState(() => _currentMonday = thisMonday);
              _fetchFullWeek();
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _viewingClassName ?? l.timetableTitle,
                style: untisThemeTextStyle(
                  context,
                  display: true,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.72,
                      end: 1,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _showingCachedWeek
                    ? Semantics(
                        key: const ValueKey('timetable-cache-sync'),
                        label: l.timetableOfflineCache,
                        child: Tooltip(
                          message: l.timetableOfflineCache,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: RotationTransition(
                              turns: _cacheRefreshController,
                              child: Icon(
                                Icons.sync_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(key: ValueKey('timetable-cache-idle')),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: _viewMode == 0
                  ? l.timetableWeekView
                  : l.timetableDayGrid,
              icon: Icon(
                _viewMode == 0
                    ? Icons.calendar_view_week_rounded
                    : Icons.calendar_view_day_rounded,
              ),
              onPressed: _toggleView,
            ),
          ),
        ],
        bottom: _viewMode == 1
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(kTextTabBarHeight),
                child: SizedBox(
                  height: kTextTabBarHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TabBar(
                        controller: _tabController,
                        onTap: _onDayTabBarTap,
                        indicator: const BoxDecoration(),
                        indicatorWeight: 0,
                        labelStyle: untisThemeTextStyle(
                          context,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                        dividerColor: Colors.transparent,
                        tabs: List.generate(5, (i) {
                          final dayDate = _currentMonday.add(Duration(days: i));
                          final dayOverride =
                              _alarmConfig.dateOverrides[alarmDateKey(dayDate)];
                          final now = DateTime.now();
                          final isToday =
                              dayDate.year == now.year &&
                              dayDate.month == now.month &&
                              dayDate.day == now.day;
                          return Tab(
                            child: GestureDetector(
                              key: ValueKey('timetable-day-tab-$i'),
                              behavior: HitTestBehavior.opaque,
                              onLongPress: () {
                                HapticFeedback.mediumImpact();
                                _showDateAlarmActions(dayDate);
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _dayShort[i],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.1,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${dayDate.day}.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          height: 1.2,
                                          color: isToday
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      if (dayOverride != null) ...[
                                        const SizedBox(width: 3),
                                        Icon(
                                          dayOverride.disabled
                                              ? Icons.alarm_off_rounded
                                              : dayOverride
                                                        .customTimeOfDayMinutes !=
                                                    null
                                              ? Icons.alarm_rounded
                                              : Icons.fast_forward_rounded,
                                          size: 12,
                                          color: dayOverride.disabled
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.error
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                        ),
                                        if (dayOverride
                                                .customTimeOfDayMinutes !=
                                            null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 2,
                                            ),
                                            child: Text(
                                              '${(dayOverride.customTimeOfDayMinutes! ~/ 60).toString().padLeft(2, '0')}:${(dayOverride.customTimeOfDayMinutes! % 60).toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                fontSize: 8,
                                                height: 1,
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                  if (isToday)
                                    Container(
                                      width: 3,
                                      height: 3,
                                      margin: const EdgeInsets.only(top: 1),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      IgnorePointer(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final tabWidth = constraints.maxWidth / 5;
                            return Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  left:
                                      (tabWidth * dayIndicatorIndex) +
                                      ((tabWidth - 38) / 2),
                                  bottom: 0,
                                  width: 38,
                                  height: 3,
                                  child: ColoredBox(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      body: _AnimatedBackground(
        child:
            (_loading &&
                _weekData.values.every((list) => list.isEmpty) &&
                !_showingCachedWeek)
            ? const Center(child: CircularProgressIndicator())
            : (_loadError != null &&
                  _weekData.values.every((list) => list.isEmpty) &&
                  !_showingCachedWeek)
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 80,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.timetableNotLoaded,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.tonal(
                        onPressed: _fetchFullWeek,
                        child: Text(l.timetableReload),
                      ),
                    ],
                  ),
                ),
              )
            : RepaintBoundary(
                key: _timetableExportKey,
                child: _buildTimetableSwitcher(),
              ),
      ),
    );
  }
}

// --- HAUSAUFGABEN & PRÜFUNGEN ---

Widget _chip(String label, Color bg, Color fg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
  child: Text(
    label,
    style: GoogleFonts.outfit(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: fg,
    ),
  ),
);

List<DateTime> _findSubjectDates(String subject) {
  if (subject.isEmpty) return [];
  final week = currentWeekDataNotifier.value;
  final dates = <DateTime>{};
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (int dayIndex = 0; dayIndex < 5; dayIndex++) {
    final lessons = week[dayIndex] ?? [];
    for (final l in lessons) {
      final sShort = l['_subjectShort']?.toString() ?? '';
      final sLong = l['_subjectLong']?.toString() ?? '';
      if (sShort == subject || sLong == subject || l['subject'] == subject) {
        final dStr = l['date']?.toString() ?? '';
        if (dStr.length == 8) {
          final date = DateTime.parse(
            '${dStr.substring(0, 4)}-${dStr.substring(4, 6)}-${dStr.substring(6, 8)}',
          );
          if (!date.isBefore(today)) {
            dates.add(date);
          }
        }
      }
    }
  }
  final list = dates.toList()..sort();
  return list.take(4).toList();
}

Future<void> _showAddHomeworkDialog(
  BuildContext context, {
  Map<String, dynamic>? existing,
  int? editIndex,
  String? initialSubject,
}) async {
  final l = AppL10n.of(appLocaleNotifier.value);
  String selectedSubject =
      (initialSubject?.isNotEmpty == true ? initialSubject! : null) ??
      existing?['subject']?.toString() ??
      (knownSubjectsNotifier.value.isNotEmpty
          ? knownSubjectsNotifier.value.first
          : '');
  final subjectCtrl = TextEditingController(text: selectedSubject);
  final taskCtrl = TextEditingController(
    text:
        existing?['text']?.toString() ??
        existing?['description']?.toString() ??
        '',
  );
  DateTime selectedDate = () {
    final s =
        existing?['dueDate']?.toString() ?? existing?['date']?.toString() ?? '';
    if (s.length == 8) {
      try {
        return DateTime.parse(
          '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}',
        );
      } catch (_) {}
    }
    return DateTime.now().add(const Duration(days: 1));
  }();

  await showUntisModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: _kBottomSheetAnimationStyle,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) {
        final cs = Theme.of(ctx).colorScheme;
        final subjects = knownSubjectsNotifier.value.toList()..sort();
        if (selectedSubject.isNotEmpty && !subjects.contains(selectedSubject)) {
          subjects.add(selectedSubject);
          subjects.sort();
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _sheetSurface(
            context: ctx,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              existing == null
                                  ? l.homeworkAddTitle
                                  : l.homeworkEditTitle,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              l.homeworkAddDesc,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.assignment_rounded,
                            color: cs.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l.homeworkSubjectLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (subjects.isNotEmpty)
                    _m3SelectionMenu(
                      context: ctx,
                      value: selectedSubject,
                      entries: subjects,
                      icon: Icons.book_rounded,
                      onSelected: (value) => setDlg(() {
                        selectedSubject = value;
                        subjectCtrl.text = selectedSubject;
                      }),
                    )
                  else
                    TextField(
                      controller: subjectCtrl,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.book_rounded),
                        hintText: l.homeworkSubjectLabel,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    l.homeworkTaskLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: taskCtrl,
                    maxLines: 3,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 42),
                        child: Icon(Icons.assignment_rounded),
                      ),
                      hintText: l.homeworkTaskLabel,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.homeworkDueDateLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final suggested = _findSubjectDates(selectedSubject);
                      if (suggested.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: suggested.map((d) {
                              final isSelected =
                                  d.year == selectedDate.year &&
                                  d.month == selectedDate.month &&
                                  d.day == selectedDate.day;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    DateFormat(
                                      'E, dd.MM.',
                                      appLocaleNotifier.value,
                                    ).format(d),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) setDlg(() => selectedDate = d);
                                  },
                                  selectedColor: cs.primaryContainer,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? cs.onPrimaryContainer
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDlg(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat(
                              'dd. MMMM yyyy',
                              _icuLocale(appLocaleNotifier.value),
                            ).format(selectedDate),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      if (existing != null && editIndex != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final list = List<Map<String, dynamic>>.from(
                                customHomeworkNotifier.value,
                              );
                              if (editIndex >= 0 && editIndex < list.length) {
                                list.removeAt(editIndex);
                                await saveCustomHomework(list);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cs.error,
                              side: BorderSide(
                                color: cs.error.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              minimumSize: const Size(0, 60),
                            ),
                            child: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      if (existing != null && editIndex != null)
                        const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: FilledButton(
                          onPressed: () async {
                            final subj = subjectCtrl.text.trim();
                            final text = taskCtrl.text.trim();
                            if (subj.isEmpty || text.isEmpty) return;
                            final dateInt = int.parse(
                              DateFormat('yyyyMMdd').format(selectedDate),
                            );
                            final list = List<Map<String, dynamic>>.from(
                              customHomeworkNotifier.value,
                            );
                            final item = <String, dynamic>{
                              'id':
                                  existing?['id'] ??
                                  'hw_${DateTime.now().millisecondsSinceEpoch}',
                              'subject': subj,
                              'text': text,
                              'dueDate': dateInt,
                              'isDone': existing?['isDone'] ?? false,
                              '_custom': true,
                            };
                            if (editIndex != null &&
                                editIndex >= 0 &&
                                editIndex < list.length) {
                              list[editIndex] = item;
                            } else {
                              list.add(item);
                            }
                            await saveCustomHomework(list);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 60),
                          ),
                          child: Text(
                            l.homeworkSave,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _importHomeworkWithAI(BuildContext context) async {
  final l = AppL10n.of(appLocaleNotifier.value);
  final providerUsesGeminiProtocol = _providerUsesGeminiProtocolGlobal();
  final provider = _normalizeAiProvider(aiProvider);
  final isLocalProvider = provider == 'local';
  if (!isLocalProvider && _activeAiApiKey().trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_providerAwareMissingApiKeyMessage(l, provider))),
    );
    return;
  }

  final source = await _showUnifiedOptionSheet<String>(
    context: context,
    title: l.homeworkImportTitle,
    options: [
      _SheetOption(
        value: 'camera',
        title: l.examsImportCamera,
        icon: Icons.camera_alt_rounded,
      ),
      _SheetOption(
        value: 'gallery',
        title: l.examsImportGallery,
        icon: Icons.image_rounded,
      ),
      _SheetOption(
        value: 'file',
        title: l.examsImportFile,
        icon: Icons.picture_as_pdf_rounded,
      ),
    ],
  );

  if (source == null) return;

  Uint8List? fileBytes;
  String? mimeType;

  if (source == 'camera' || source == 'gallery') {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked == null) return;
    fileBytes = await picked.readAsBytes();
    mimeType = picked.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
  } else {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: providerUsesGeminiProtocol
          ? ['pdf', 'png', 'jpg', 'jpeg']
          : ['png', 'jpg', 'jpeg'],
    );
    if (picked == null) return;
    fileBytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    mimeType = ext == 'pdf'
        ? 'application/pdf'
        : (ext == 'png' ? 'image/png' : 'image/jpeg');
  }

  if (!context.mounted) return;

  var loadingVisible = true;
  showUntisDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final prompt = l.uiFormat('aiHomeworkVisionPrompt', {
      'fileKind': providerUsesGeminiProtocol ? l.ui('aiFileKindPdf') : '',
    });

    final text = await _requestAiVisionAnalysisGlobal(
      prompt: prompt,
      fileBytes: fileBytes,
      mimeType: mimeType,
    );

    if (!context.mounted) return;
    if (loadingVisible) {
      Navigator.pop(context);
      loadingVisible = false;
    }

    final jsonStart = text.indexOf('[');
    final jsonEnd = text.lastIndexOf(']');
    if (jsonStart != -1 && jsonEnd != -1) {
      final jsonStr = text.substring(jsonStart, jsonEnd + 1);
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) throw Exception(l.examsImportInvalidJson);

      final items = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final current = List<Map<String, dynamic>>.from(
        customHomeworkNotifier.value,
      );
      for (var e in items) {
        current.add({
          'id': 'hw_${DateTime.now().millisecondsSinceEpoch}_${current.length}',
          'subject': e['subject']?.toString() ?? 'Unbekannt',
          'text': e['text']?.toString() ?? '',
          'dueDate': (e['dueDate']?.toString() ?? '').replaceAll('-', ''),
          'isDone': false,
          '_custom': true,
        });
      }
      await saveCustomHomework(current);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.homeworkImportSuccess)));
    } else {
      throw Exception(l.examsImportInvalidJson);
    }
  } catch (e) {
    if (!context.mounted) return;
    if (loadingVisible) {
      Navigator.pop(context);
      loadingVisible = false;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${l.homeworkImportError}$e')));
  }
}

bool _providerUsesGeminiProtocolGlobal() {
  final provider = _normalizeAiProvider(aiProvider);
  if (provider == 'gemini') return true;
  if (provider == 'custom') {
    return _normalizeAiCustomCompatibility(aiCustomCompatibility) == 'gemini';
  }
  return false;
}

Future<String> _requestAiVisionAnalysisGlobal({
  required String prompt,
  required Uint8List fileBytes,
  required String mimeType,
}) async {
  final l = AppL10n.of(appLocaleNotifier.value);
  final provider = _normalizeAiProvider(aiProvider);
  final apiKey = _activeAiApiKey().trim();
  if (apiKey.isEmpty) {
    throw Exception(
      'CONFIG: ${_providerAwareMissingApiKeyMessage(l, provider)}',
    );
  }

  final model = aiModel.trim().isNotEmpty
      ? aiModel.trim()
      : _defaultModelForProvider(
          provider,
          customCompatibility: aiCustomCompatibility,
        );

  if (provider == 'gemini') {
    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
    final endpointUri = Uri.parse(endpoint);
    final mergedParams = Map<String, String>.from(endpointUri.queryParameters)
      ..putIfAbsent('key', () => apiKey);
    final uri = endpointUri.replace(queryParameters: mergedParams);

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(fileBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 2200},
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final candidates = decoded['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final parts = candidates.first['content']?['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        return parts.map((p) => p['text']?.toString() ?? '').join();
      }
    }
    throw Exception(l.aiNoReply);
  }

  throw Exception('Unsupported provider for vision: $provider');
}

class HomeworkPage extends StatelessWidget {
  const HomeworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: RoundedBlurAppBar(
        title: Text(
          l.homeworkTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 26),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddHomeworkDialog(context),
            tooltip: l.homeworkAddTitle,
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            onPressed: () => _importHomeworkWithAI(context),
            tooltip: l.homeworkActionImport,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _AnimatedBackground(child: const SizedBox.expand()),
          ),
          const Positioned.fill(child: _HomeworkView()),
        ],
      ),
    );
  }
}

class _HomeworkView extends StatefulWidget {
  const _HomeworkView();

  @override
  State<_HomeworkView> createState() => _HomeworkViewState();
}

class _HomeworkViewState extends State<_HomeworkView> {
  int _filterIndex = 0; // 0 = Alle, 1 = Offen, 2 = Bald, 3 = Erledigt

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);

    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: homeworksNotifier,
      builder: (context, apiHw, _) {
        return ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: customHomeworkNotifier,
          builder: (context, customHw, _) {
            final allItems = <Map<String, dynamic>>[];

            for (final hw in apiHw) {
              final id = hw['id']?.toString() ?? '';
              final subject =
                  hw['_lesson']?['su']?.first?['longname'] ??
                  hw['_lesson']?['su']?.first?['name'] ??
                  'Unbekannt';
              allItems.add({
                'id': id,
                'subject': subject,
                'text': hw['text'] ?? '',
                'dueDate': hw['dueDate'] ?? hw['date'] ?? 0,
                'isDone': (hw['isDone'] == true) || (hw['_done'] == true),
                '_source': 'untis',
                '_raw': hw,
              });
            }

            for (final hw in customHw) {
              allItems.add({
                'id': hw['id']?.toString() ?? '',
                'subject': hw['subject'] ?? 'Unbekannt',
                'text': hw['text'] ?? hw['description'] ?? '',
                'dueDate': hw['dueDate'] ?? hw['date'] ?? 0,
                'isDone': hw['isDone'] == true,
                '_source': 'custom',
                '_raw': hw,
              });
            }

            allItems.sort((a, b) {
              final aOpen = a['isDone'] != true ? 0 : 1;
              final bOpen = b['isDone'] != true ? 0 : 1;
              if (aOpen != bOpen) return aOpen.compareTo(bOpen);
              final da = int.tryParse(a['dueDate'].toString()) ?? 0;
              final db = int.tryParse(b['dueDate'].toString()) ?? 0;
              return da.compareTo(db);
            });

            final openItems = allItems
                .where((e) => e['isDone'] != true)
                .toList();
            final doneItems = allItems
                .where((e) => e['isDone'] == true)
                .toList();
            final dueSoonItems = openItems.where((entry) {
              final dueDate = int.tryParse(entry['dueDate'].toString()) ?? 0;
              return isHomeworkDueSoon(dueDate);
            }).toList();

            final filtered = _filterIndex == 1
                ? openItems
                : _filterIndex == 2
                ? dueSoonItems
                : (_filterIndex == 3 ? doneItems : allItems);

            return ExpressiveRefreshIndicator(
              onRefresh: () async {
                final requestAccountId = activeUntisAccountId;
                final account = activeUntisAccount;
                final res = demoModeNotifier.value
                    ? DemoModeService.buildHomeworkAndNotes(
                        resolveDefaultTimetableMonday(DateTime.now()),
                        locale: appLocaleNotifier.value,
                      )
                    : await HomeworkService.fetchHomeworkAndNotes(
                        schoolUrl: schoolUrl,
                        schoolName: schoolName,
                        sessionId: sessionID,
                        personId: personId,
                        personType: personType,
                        accountId: activeUntisAccountId,
                        account: account == null
                            ? null
                            : WebUntisAccountLogin(
                                accountId: account.id,
                                username: account.username,
                                schoolUrl: account.schoolUrl,
                                schoolName: account.schoolName,
                                personId: account.personId,
                                personType: account.personType,
                              ),
                      );
                if (requestAccountId != activeUntisAccountId) return;
                homeworksNotifier.value = res['homeworks']!;
                lessonNotesNotifier.value = res['lessonNotes']!;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  _buildHomeworkSummaryCard(
                    context,
                    cs,
                    openCount: openItems.length,
                    dueSoonCount: dueSoonItems.length,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _filterChip(
                          context,
                          cs,
                          '${l.homeworkFilterAll} (${allItems.length})',
                          Icons.clear_all_rounded,
                          0,
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          context,
                          cs,
                          '${l.homeworkFilterOpen} (${openItems.length})',
                          Icons.radio_button_unchecked_rounded,
                          1,
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          context,
                          cs,
                          '${_studentCopy(de: 'Bald fällig', en: 'Due soon', fr: 'Bientôt dues', es: 'Próximas')} (${dueSoonItems.length})',
                          Icons.upcoming_rounded,
                          2,
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          context,
                          cs,
                          '${l.homeworkFilterDone} (${doneItems.length})',
                          Icons.check_circle_rounded,
                          3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (filtered.isEmpty) ...[
                    const SizedBox(height: 60),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.assignment_turned_in_rounded,
                              size: 56,
                              color: cs.primary.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l.homeworkNone,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.homeworkNoneHint,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...filtered.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final hw = entry.value;
                      return _springEntry(
                        key: ValueKey('hw_${hw['id']}_$idx'),
                        duration: Duration(milliseconds: 380 + idx * 60),
                        offsetY: 24,
                        startScale: 0.94,
                        curve: _kSmoothBounce,
                        child: _buildHomeworkCard(context, cs, l, hw),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip(
    BuildContext context,
    ColorScheme cs,
    String label,
    IconData icon,
    int index,
  ) {
    final selected = _filterIndex == index;
    return _glassContainer(
      context: context,
      borderRadius: BorderRadius.circular(14),
      color: selected
          ? cs.primary
          : cs.surfaceContainerHighest.withValues(alpha: 0.4),
      border: Border.all(
        color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3),
        width: 1,
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filterIndex = index);
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeworkSummaryCard(
    BuildContext context,
    ColorScheme cs, {
    required int openCount,
    required int dueSoonCount,
  }) {
    final title = _studentCopy(
      de: openCount == 1 ? '1 offene Aufgabe' : '$openCount offene Aufgaben',
      en: openCount == 1 ? '1 open task' : '$openCount open tasks',
      fr: openCount == 1 ? '1 tâche ouverte' : '$openCount tâches ouvertes',
      es: openCount == 1 ? '1 tarea pendiente' : '$openCount tareas pendientes',
    );
    final detail = dueSoonCount == 0
        ? _studentCopy(
            de: 'Nichts ist bald fällig',
            en: 'Nothing is due soon',
            fr: 'Rien n’est bientôt dû',
            es: 'No hay nada próximo',
          )
        : _studentCopy(
            de: dueSoonCount == 1
                ? '1 Aufgabe ist bald fällig'
                : '$dueSoonCount Aufgaben sind bald fällig',
            en: dueSoonCount == 1
                ? '1 task is due soon'
                : '$dueSoonCount tasks are due soon',
            fr: dueSoonCount == 1
                ? '1 tâche est bientôt due'
                : '$dueSoonCount tâches sont bientôt dues',
            es: dueSoonCount == 1
                ? '1 tarea vence pronto'
                : '$dueSoonCount tareas vencen pronto',
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _glassContainer(
        context: context,
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.25),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _glowShadows(context, [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.upcoming_rounded,
                          size: 13,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            detail,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(
    BuildContext context,
    ColorScheme cs,
    AppL10n l,
    Map<String, dynamic> hw,
  ) {
    final isDone = hw['isDone'] == true;
    final isCustom = hw['_source'] == 'custom';
    final subject = hw['subject']?.toString() ?? 'Unbekannt';
    final text = hw['text']?.toString() ?? '';
    final dueDateRaw = hw['dueDate']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _autoLessonColor(subject, isDark);

    String formatDate(String d) {
      if (d.length != 8) return d;
      return '${d.substring(6, 8)}.${d.substring(4, 6)}.${d.substring(0, 4)}';
    }

    Future<void> setDone(bool value) async {
      final hwId = hw['id'];
      if (isCustom) {
        final list = customHomeworkNotifier.value
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
        final idx = list.indexWhere(
          (entry) => entry['id']?.toString() == hwId?.toString(),
        );
        if (idx != -1) {
          list[idx]['isDone'] = value;
          await saveCustomHomework(list);
        }
        return;
      }

      final numericId = int.tryParse(hwId.toString());
      if (numericId == null) return;
      await HomeworkService.toggleDone(
        numericId,
        value,
        accountId: activeUntisAccountId,
      );
      final currentApi = homeworksNotifier.value
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
      for (final item in currentApi) {
        if (item['id']?.toString() == numericId.toString()) {
          item['_done'] = value;
        }
      }
      homeworksNotifier.value = currentApi;
    }

    Future<void> toggleDone() async {
      HapticFeedback.selectionClick();
      await setDone(!isDone);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            !isDone
                ? _studentCopy(
                    de: 'Aufgabe als erledigt markiert.',
                    en: 'Task marked as done.',
                    fr: 'Tâche marquée comme terminée.',
                    es: 'Tarea marcada como completada.',
                  )
                : _studentCopy(
                    de: 'Aufgabe wieder geöffnet.',
                    en: 'Task reopened.',
                    fr: 'Tâche rouverte.',
                    es: 'Tarea reabierta.',
                  ),
          ),
          action: SnackBarAction(
            label: _studentCopy(
              de: 'Rückgängig',
              en: 'Undo',
              fr: 'Annuler',
              es: 'Deshacer',
            ),
            onPressed: () => unawaited(setDone(isDone)),
          ),
        ),
      );
    }

    Future<void> openHomework() async {
      HapticFeedback.selectionClick();
      if (!isCustom) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.ui('homeworkManaged'))));
        return;
      }
      final list = List<Map<String, dynamic>>.from(
        customHomeworkNotifier.value,
      );
      final editIndex = list.indexWhere(
        (item) => item['id']?.toString() == hw['id']?.toString(),
      );
      if (editIndex == -1) return;
      await _showAddHomeworkDialog(
        context,
        existing: list[editIndex],
        editIndex: editIndex,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _glassContainer(
        context: context,
        borderRadius: BorderRadius.circular(24),
        color: isDone
            ? cs.surfaceContainerLowest.withValues(alpha: 0.35)
            : accent.withValues(alpha: isDark ? 0.14 : 0.08),
        border: Border.all(
          color: isDone
              ? cs.outlineVariant.withValues(alpha: 0.25)
              : accent.withValues(alpha: 0.4),
          width: 1.2,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: openHomework,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkResponse(
                    onTap: toggleDone,
                    radius: 22,
                    containedInkWell: true,
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isDone ? cs.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDone
                              ? cs.primary
                              : accent.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        boxShadow:
                            isDone &&
                                untisThemeTokensOf(context).glowEffectsEnabled
                            ? [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isDone
                          ? Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: cs.onPrimary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _chip(
                              subject,
                              accent.withValues(alpha: 0.2),
                              accent,
                            ),
                            if (isCustom) ...[
                              const SizedBox(width: 6),
                              _chip(
                                l.examsOwn,
                                cs.tertiaryContainer,
                                cs.tertiary,
                              ),
                            ],
                            const Spacer(),
                            if (dueDateRaw.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? cs.surfaceContainerHighest.withValues(
                                          alpha: 0.5,
                                        )
                                      : cs.primaryContainer.withValues(
                                          alpha: 0.45,
                                        ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event_rounded,
                                      size: 12,
                                      color: isDone
                                          ? cs.onSurfaceVariant
                                          : cs.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatDate(dueDateRaw),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDone
                                            ? cs.onSurfaceVariant
                                            : cs.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          text,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: isDone
                                ? cs.onSurface.withValues(alpha: 0.45)
                                : cs.onSurface,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showAddExamDialog(
  BuildContext context, {
  Map<String, dynamic>? existing,
  int? editIndex,
  String? initialSubject,
}) async {
  String selectedSubject =
      (initialSubject?.isNotEmpty == true ? initialSubject! : null) ??
      existing?['subject']?.toString() ??
      (knownSubjectsNotifier.value.isNotEmpty
          ? knownSubjectsNotifier.value.first
          : '');
  final subjectCtrl = TextEditingController(text: selectedSubject);
  final typeCtrl = TextEditingController(
    text: existing?['examType']?.toString() ?? '',
  );
  final descCtrl = TextEditingController(
    text: existing?['description']?.toString() ?? '',
  );
  DateTime selectedDate = () {
    final s = existing?['date']?.toString() ?? '';
    if (s.length == 8) {
      try {
        return DateTime.parse(
          '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}',
        );
      } catch (_) {}
    }
    return DateTime.now();
  }();

  await showUntisModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: _kBottomSheetAnimationStyle,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) {
        final cs = Theme.of(ctx).colorScheme;
        final l = AppL10n.of(appLocaleNotifier.value);
        final subjects = knownSubjectsNotifier.value.toList()..sort();
        if (selectedSubject.isNotEmpty && !subjects.contains(selectedSubject)) {
          subjects.add(selectedSubject);
          subjects.sort();
        }
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _sheetSurface(
            context: ctx,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              existing == null
                                  ? l.examsAddTitle
                                  : l.examsEditTitle,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              l.examsAddDesc,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.edit_calendar_rounded,
                            color: cs.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l.examsSubjectLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (subjects.isNotEmpty)
                    _m3SelectionMenu(
                      context: ctx,
                      value: selectedSubject,
                      entries: subjects,
                      icon: Icons.book_rounded,
                      onSelected: (value) => setDlg(() {
                        selectedSubject = value;
                        subjectCtrl.text = selectedSubject;
                      }),
                    )
                  else
                    TextField(
                      controller: subjectCtrl,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.book_rounded),
                        hintText: l.examsSubjectLabel,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    l.examsTypeLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeCtrl,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.label_important_rounded),
                      hintText: l.examsTypeLabel,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.gradesDateLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final suggested = _findSubjectDates(selectedSubject);
                      if (suggested.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: suggested.map((d) {
                              final isSelected =
                                  d.year == selectedDate.year &&
                                  d.month == selectedDate.month &&
                                  d.day == selectedDate.day;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    DateFormat(
                                      'E, dd.MM.',
                                      appLocaleNotifier.value,
                                    ).format(d),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) setDlg(() => selectedDate = d);
                                  },
                                  selectedColor: cs.primaryContainer,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? cs.onPrimaryContainer
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDlg(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat(
                              'dd. MMMM yyyy',
                              _icuLocale(appLocaleNotifier.value),
                            ).format(selectedDate),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.examsNotesLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 42),
                        child: Icon(Icons.notes_rounded),
                      ),
                      hintText: l.examsNotesLabel,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      if (existing != null && editIndex != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final list = List<Map<String, dynamic>>.from(
                                customExamsNotifier.value,
                              );
                              if (editIndex >= 0 && editIndex < list.length) {
                                list.removeAt(editIndex);
                                await saveCustomExams(list);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cs.error,
                              side: BorderSide(
                                color: cs.error.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              minimumSize: const Size(0, 60),
                            ),
                            child: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      if (existing != null && editIndex != null)
                        const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: FilledButton(
                          onPressed: () async {
                            final subj = subjectCtrl.text.trim();
                            if (subj.isEmpty) return;
                            final dateInt = int.parse(
                              DateFormat('yyyyMMdd').format(selectedDate),
                            );
                            final newExam = <String, dynamic>{
                              'id':
                                  existing?['id'] ??
                                  'exam_${DateTime.now().millisecondsSinceEpoch}',
                              'subject': subj,
                              'examType': typeCtrl.text.trim(),
                              'date': dateInt,
                              'description': descCtrl.text.trim(),
                              '_custom': true,
                            };
                            final list = List<Map<String, dynamic>>.from(
                              customExamsNotifier.value,
                            );
                            if (editIndex != null &&
                                editIndex >= 0 &&
                                editIndex < list.length) {
                              list[editIndex] = newExam;
                            } else {
                              list.add(newExam);
                            }
                            await saveCustomExams(list);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 60),
                          ),
                          child: Text(
                            l.examsSave,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

// --- PRÜFUNGEN PAGE ---

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _apiExams = [];
  List<Map<String, dynamic>> _customExams = [];
  bool _loading = true;

  Future<void> _refreshExams({bool showSpinner = false}) async {
    if (showSpinner && mounted) {
      setState(() {
        _loading = true;
      });
    }
    await _fetchApiExams();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    customExamsNotifier.addListener(_onCustomExamsNotifierChanged);
    _load();
  }

  @override
  void dispose() {
    customExamsNotifier.removeListener(_onCustomExamsNotifierChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onCustomExamsNotifierChanged() {
    if (!mounted) return;
    setState(() {
      _customExams = List.from(customExamsNotifier.value);
    });
  }

  Future<void> _load() async {
    await Future.wait([_fetchApiExams(), _loadCustomExams()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCustomExams() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_accountDataKey('customExams')) ?? [];
    final list = raw
        .map((e) {
          try {
            return Map<String, dynamic>.from(jsonDecode(e) as Map);
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();
    _customExams = list;
    customExamsNotifier.value = list;
  }

  Future<void> _fetchApiExams() async {
    if (demoModeNotifier.value) {
      _apiExams = DemoModeService.demoExams(locale: appLocaleNotifier.value);
      return;
    }
    if (sessionID.isEmpty) return;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 14));
    final end = now.add(const Duration(days: 90));
    final startStr = DateFormat('yyyyMMdd').format(start);
    final endStr = DateFormat('yyyyMMdd').format(end);
    final headers = {
      'Cookie': 'JSESSIONID=$sessionID; schoolname=$schoolName',
      'Accept': 'application/json',
    };

    Future<List<Map<String, dynamic>>> tryEndpoint(String path) async {
      try {
        final uri = Uri.parse(
          'https://$schoolUrl$path?startDate=$startStr&endDate=$endStr',
        );
        final res = await http.get(uri, headers: headers);
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          List<dynamic> list = [];
          if (decoded is List) {
            list = decoded;
          } else if (decoded is Map) {
            list =
                (decoded['data'] ?? decoded['exams'] ?? decoded['result'] ?? [])
                    as List;
          }
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
      return [];
    }

    var results = await tryEndpoint('/WebUntis/api/exams');
    if (results.isEmpty) {
      results = await tryEndpoint('/WebUntis/api/classreg/exams');
    }
    if (results.isEmpty && personId != 0) {
      results = await tryEndpoint('/WebUntis/api/exams/student/$personId');
    }
    _apiExams = results;
    apiExamsNotifier.value = results;
  }

  List<Map<String, dynamic>> get _allExams {
    final all = [
      ..._apiExams.map((e) => {...e, '_source': 'api'}),
      ..._customExams.map((e) => {...e, '_source': 'custom'}),
    ];
    all.sort((a, b) => _examSortKey(a).compareTo(_examSortKey(b)));
    return all;
  }

  int _examSortKey(Map<String, dynamic> e) {
    final date = e['date'] ?? e['examDate'] ?? e['startDate'] ?? 0;
    final time = e['startTime'] ?? e['start'] ?? 0;
    return (int.tryParse(date.toString()) ?? 0) * 10000 +
        (int.tryParse(time.toString()) ?? 0);
  }

  String _formatExamDate(dynamic date) {
    final s = date.toString();
    if (s.length == 8) {
      try {
        final d = DateTime.parse(
          '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}',
        );
        return DateFormat(
          'EEEE, dd. MMMM yyyy',
          _icuLocale(appLocaleNotifier.value),
        ).format(d);
      } catch (_) {}
    }
    return s;
  }

  String _examSubject(Map<String, dynamic> e) =>
      (e['subject'] ?? e['name'] ?? e['examType'] ?? '').toString();

  String _examType(Map<String, dynamic> e) =>
      (e['examType'] ?? e['type'] ?? e['typeName'] ?? '').toString();

  bool _providerUsesGeminiProtocol() {
    final provider = _normalizeAiProvider(aiProvider);
    if (provider == 'gemini') return true;
    if (provider == 'custom') {
      return _normalizeAiCustomCompatibility(aiCustomCompatibility) == 'gemini';
    }
    return false;
  }

  String _normalizedAiBaseUrl(String value) {
    var out = value.trim();
    while (out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }

  String _openAiCompatibleEndpointForExamImport(String rawBaseUrl) {
    final base = _normalizedAiBaseUrl(rawBaseUrl);
    if (base.isEmpty) return '';
    if (base.endsWith('/chat/completions')) return base;
    if (base.endsWith('/v1')) return '$base/chat/completions';
    if (base.endsWith('/v1/chat')) return '$base/completions';
    return '$base/v1/chat/completions';
  }

  String _geminiCompatibleEndpointForExamImport(
    String rawBaseUrl,
    String model,
  ) {
    final base = _normalizedAiBaseUrl(rawBaseUrl);
    if (base.isEmpty) return '';
    if (base.contains('/models/')) return base;
    if (base.contains('/v1beta')) return '$base/models/$model:generateContent';
    if (base.contains('/v1')) return '$base/models/$model:generateContent';
    return '$base/v1beta/models/$model:generateContent';
  }

  String _extractOpenAiCompatibleText(Map<String, dynamic> payload, AppL10n l) {
    final choices = payload['choices'];
    if (choices is! List || choices.isEmpty) {
      throw Exception('API: ${l.aiNoReply}');
    }

    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw Exception('API: ${l.aiNoReply}');
    }

    final message = first['message'];
    if (message is Map<String, dynamic>) {
      final content = message['content'];
      if (content is String && content.trim().isNotEmpty) {
        return content.trim();
      }
      if (content is List) {
        final text = content
            .map((part) {
              if (part is Map<String, dynamic>) {
                return part['text']?.toString() ?? '';
              }
              return '';
            })
            .join()
            .trim();
        if (text.isNotEmpty) return text;
      }
    }

    final legacyText = first['text']?.toString().trim() ?? '';
    if (legacyText.isNotEmpty) return legacyText;
    throw Exception('API: ${l.aiNoReply}');
  }

  Future<String> _requestExamImportWithGemini({
    required String endpoint,
    required String apiKey,
    required String prompt,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final endpointUri = Uri.parse(endpoint);
    final mergedParams = Map<String, String>.from(endpointUri.queryParameters)
      ..putIfAbsent('key', () => apiKey);
    final uri = endpointUri.replace(queryParameters: mergedParams);

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': l.ui('aiExamJsonSystemPrompt')},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(fileBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 2200},
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: body,
    );

    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload?['error']?['message'] ?? response.statusCode;
      throw Exception('API: $message');
    }

    var reply = '';
    final candidates = payload?['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final content = candidates.first['content'];
      final parts = (content is Map<String, dynamic>) ? content['parts'] : null;
      if (parts is List) {
        reply = parts.map((part) {
          if (part is Map<String, dynamic>) {
            return part['text']?.toString() ?? '';
          }
          return '';
        }).join();
      }
    }

    reply = reply.trim();
    if (reply.isEmpty) {
      throw Exception('API: ${l.aiNoReply}');
    }
    return reply;
  }

  Future<String> _requestExamImportWithOpenAiCompatible({
    required String endpoint,
    required String apiKey,
    required String model,
    required String prompt,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    if (!mimeType.startsWith('image/')) {
      throw Exception(
        'API: Unsupported file type for this provider: $mimeType',
      );
    }
    final l = AppL10n.of(appLocaleNotifier.value);
    final dataUrl = 'data:$mimeType;base64,${base64Encode(fileBytes)}';
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': l.ui('aiExamImageSystemPrompt')},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl},
            },
          ],
        },
      ],
      'temperature': 0.1,
    });

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload?['error']?['message'] ?? response.statusCode;
      throw Exception('API: $message');
    }

    return _extractOpenAiCompatibleText(payload ?? const {}, l);
  }

  Future<String> _requestExamImportResponse({
    required String prompt,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final provider = _normalizeAiProvider(aiProvider);
    final apiKey = _activeAiApiKey().trim();
    if (apiKey.isEmpty) {
      throw Exception(
        'CONFIG: ${_providerAwareMissingApiKeyMessage(l, provider)}',
      );
    }

    final model = aiModel.trim().isNotEmpty
        ? aiModel.trim()
        : _defaultModelForProvider(
            provider,
            customCompatibility: aiCustomCompatibility,
          );

    switch (provider) {
      case 'openai':
        return _requestExamImportWithOpenAiCompatible(
          endpoint: 'https://api.openai.com/v1/chat/completions',
          apiKey: apiKey,
          model: model,
          prompt: prompt,
          fileBytes: fileBytes,
          mimeType: mimeType,
        );
      case 'mistral':
        return _requestExamImportWithOpenAiCompatible(
          endpoint: 'https://api.mistral.ai/v1/chat/completions',
          apiKey: apiKey,
          model: model,
          prompt: prompt,
          fileBytes: fileBytes,
          mimeType: mimeType,
        );
      case 'custom':
        final baseUrl = aiCustomBaseUrl.trim();
        if (baseUrl.isEmpty) {
          throw Exception('CONFIG: ${l.aiCustomBaseUrlMissing}');
        }
        final compat = _normalizeAiCustomCompatibility(aiCustomCompatibility);
        if (compat == 'gemini') {
          return _requestExamImportWithGemini(
            endpoint: _geminiCompatibleEndpointForExamImport(baseUrl, model),
            apiKey: apiKey,
            prompt: prompt,
            fileBytes: fileBytes,
            mimeType: mimeType,
          );
        }
        return _requestExamImportWithOpenAiCompatible(
          endpoint: _openAiCompatibleEndpointForExamImport(baseUrl),
          apiKey: apiKey,
          model: model,
          prompt: prompt,
          fileBytes: fileBytes,
          mimeType: mimeType,
        );
      case 'local':
        throw Exception(
          'CONFIG: ${AppL10n.of(appLocaleNotifier.value).aiLocalModelExamNotSupported}',
        );
      case 'gemini':
      default:
        return _requestExamImportWithGemini(
          endpoint:
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
          apiKey: apiKey,
          prompt: prompt,
          fileBytes: fileBytes,
          mimeType: mimeType,
        );
    }
  }

  Future<void> _importExamsWithAI() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final providerUsesGeminiProtocol = _providerUsesGeminiProtocol();
    final provider = _normalizeAiProvider(aiProvider);
    final isLocalProvider = provider == 'local';
    if (!isLocalProvider && _activeAiApiKey().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_providerAwareMissingApiKeyMessage(l, provider)),
        ),
      );
      return;
    }

    final source = await _showUnifiedOptionSheet<String>(
      context: context,
      title: l.examsImportTitle,
      options: [
        _SheetOption(
          value: 'camera',
          title: l.examsImportCamera,
          icon: Icons.camera_alt_rounded,
        ),
        _SheetOption(
          value: 'gallery',
          title: l.examsImportGallery,
          icon: Icons.image_rounded,
        ),
        _SheetOption(
          value: 'file',
          title: l.examsImportFile,
          icon: Icons.picture_as_pdf_rounded,
        ),
      ],
    );

    if (source == null) return;

    Uint8List? fileBytes;
    String? mimeType;

    if (source == 'camera' || source == 'gallery') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
      if (picked == null) return;
      fileBytes = await picked.readAsBytes();
      mimeType = picked.path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
    } else {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: providerUsesGeminiProtocol
            ? ['pdf', 'png', 'jpg', 'jpeg']
            : ['png', 'jpg', 'jpeg'],
      );
      if (picked == null) return;
      fileBytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      mimeType = ext == 'pdf'
          ? 'application/pdf'
          : (ext == 'png' ? 'image/png' : 'image/jpeg');
    }

    if (!mounted) return;

    var loadingVisible = true;
    showUntisDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prompt = l.uiFormat('aiExamVisionPrompt', {
        'fileKind': providerUsesGeminiProtocol ? l.ui('aiFileKindPdf') : '',
        'year': DateTime.now().year,
      });

      final text = await _requestExamImportResponse(
        prompt: prompt,
        fileBytes: fileBytes,
        mimeType: mimeType,
      );

      if (!mounted) return;
      if (loadingVisible) {
        Navigator.pop(context);
        loadingVisible = false;
      }

      final jsonStart = text.indexOf('[');
      final jsonEnd = text.lastIndexOf(']');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = text.substring(jsonStart, jsonEnd + 1);
        final decoded = jsonDecode(jsonStr);
        if (decoded is! List) {
          throw Exception('API: ${l.examsImportInvalidJson}');
        }
        final exams = decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        final current = List<Map<String, dynamic>>.from(
          customExamsNotifier.value,
        );
        for (var e in exams) {
          current.add({
            'subject': e['subject']?.toString() ?? 'Unbekannt',
            'examType': e['examType']?.toString() ?? 'Klausur',
            'date': (e['date']?.toString() ?? '').replaceAll('-', ''),
            'description': e['description']?.toString() ?? '',
            '_custom': true,
          });
        }
        await saveCustomExams(current);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.examsImportSuccess)));
      } else {
        throw Exception(l.examsImportInvalidJson);
      }
    } catch (e) {
      if (!mounted) return;
      if (loadingVisible) {
        Navigator.pop(context);
        loadingVisible = false;
      }
      final message = e.toString();
      final isApiError = message.contains('API:');
      final isConfigError = message.contains('CONFIG:');
      final detail = isConfigError
          ? message.replaceFirst('Exception: CONFIG: ', '')
          : isApiError
          ? '${l.aiApiError} ${message.replaceFirst('Exception: API: ', '')}'
          : '${l.aiConnectionError} $e';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l.examsImportError}$detail')));
    }
  }

  Future<void> _exportCustomExams() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    if (_customExams.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.examsExportEmpty)));
      return;
    }

    final exportPayload = _customExams
        .map(
          (e) => <String, dynamic>{
            'subject': _examSubject(e),
            'examType': _examType(e),
            'date': (e['date'] ?? e['examDate'] ?? e['startDate'] ?? '')
                .toString(),
            'description': (e['description'] ?? '').toString(),
          },
        )
        .toList();

    final jsonText = const JsonEncoder.withIndent('  ').convert(exportPayload);
    await Clipboard.setData(ClipboardData(text: jsonText));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.examsExportSuccess)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final exams = _allExams;
    final todayInt = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));

    final upcoming = exams
        .where(
          (e) => (int.tryParse(e['date']?.toString() ?? '') ?? 0) >= todayInt,
        )
        .toList();
    final past = exams
        .where(
          (e) => (int.tryParse(e['date']?.toString() ?? '') ?? 0) < todayInt,
        )
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _mainTabHeaderAppBar(
        context,
        _tabController.index == 0
            ? l.examsTitle
            : (_tabController.index == 1 ? l.homeworkTitle : l.gradesTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _tabController.index == 2
                ? IconButton(
                    tooltip: l.gradesAddTitle,
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () =>
                        _gradesTrackerKey.currentState?.showAddGradeDialog(),
                  )
                : _untisDropdownMenu(
                    context: context,
                    menuChildren: _tabController.index == 0
                        ? [
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.edit_note_rounded),
                              onPressed: () => _showAddExamDialog(context),
                              child: Text(l.examsActionCustom),
                            ),
                            MenuItemButton(
                              leadingIcon: const Icon(
                                Icons.upload_file_rounded,
                              ),
                              onPressed: _importExamsWithAI,
                              child: Text(l.examsActionImport),
                            ),
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.ios_share_rounded),
                              onPressed: _exportCustomExams,
                              child: Text(l.examsActionExport),
                            ),
                          ]
                        : [
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.edit_note_rounded),
                              onPressed: () => _showAddHomeworkDialog(context),
                              child: Text(l.homeworkActionCustom),
                            ),
                            MenuItemButton(
                              leadingIcon: const Icon(
                                Icons.upload_file_rounded,
                              ),
                              onPressed: () => _importHomeworkWithAI(context),
                              child: Text(l.homeworkActionImport),
                            ),
                          ],
                    builder: (context, controller, child) => IconButton(
                      tooltip: _tabController.index == 0
                          ? l.examsAddTitle
                          : l.homeworkAddTitle,
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
                    ),
                  ),
          ),
        ],
        bottom: _mainSectionTabBar(
          context,
          controller: _tabController,
          onTap: (index) => setState(() {}),
          items: [
            (icon: Icons.assignment_late_rounded, label: l.navExams),
            (icon: Icons.assignment_rounded, label: l.navHomework),
            (icon: Icons.auto_graph_rounded, label: l.navGrades),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExpressiveRefreshIndicator(
            onRefresh: _refreshExams,
            child: ListView(
              padding: UntisLayout.pagePadding(context, bottom: 132),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                _buildExamStatsHeader(cs, l, upcoming),
                if (_loading) ...[
                  const SizedBox(height: 140),
                  const Center(child: CircularProgressIndicator()),
                ] else if (exams.isEmpty) ...[
                  const SizedBox(height: 80),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.examsNone,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.examsNoneHint,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _refreshExams,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            l.examsReload,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  if (upcoming.isNotEmpty) ...[
                    _sectionHeader(
                      cs,
                      l.examsUpcoming,
                      Icons.upcoming_rounded,
                      upcoming.length,
                    ),
                    const SizedBox(height: 8),
                    ...upcoming.asMap().entries.map(
                      (e) =>
                          _animatedExamCard(e.key, context, cs, e.value, true),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (past.isNotEmpty) ...[
                    _sectionHeader(
                      cs,
                      l.examsPast,
                      Icons.history_rounded,
                      past.length,
                    ),
                    const SizedBox(height: 8),
                    ...past.asMap().entries.map(
                      (e) =>
                          _animatedExamCard(e.key, context, cs, e.value, false),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const _HomeworkView(),
          GradesTrackerPage(key: _gradesTrackerKey),
        ],
      ),
    );
  }

  Widget _buildExamStatsHeader(
    ColorScheme cs,
    AppL10n l,
    List<Map<String, dynamic>> upcoming,
  ) {
    final count = upcoming.length;
    final next = upcoming.isNotEmpty ? upcoming.first : null;
    final nextSubject = next != null ? _examSubject(next) : null;
    final nextDateStr = next != null
        ? _formatExamDate(next['date'] ?? next['examDate'] ?? '')
        : null;

    final upcomingTitle = l.examsUpcomingCount.replaceAll('{count}', '$count');

    final nextSubText = nextSubject != null && nextDateStr != null
        ? l.examsUpcomingNext
              .replaceAll(r'$subject', nextSubject)
              .replaceAll(r'$date', nextDateStr)
              .replaceAll('{subject}', nextSubject)
              .replaceAll('{date}', nextDateStr)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _glassContainer(
        context: context,
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.25),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _glowShadows(context, [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]),
                ),
                child: const Center(
                  child: Icon(
                    Icons.assignment_turned_in_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upcomingTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (nextSubText != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.near_me_rounded,
                            size: 13,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              nextSubText,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final GlobalKey<_GradesTrackerPageState> _gradesTrackerKey = GlobalKey();

  Widget _sectionHeader(
    ColorScheme cs,
    String title,
    IconData icon, [
    int? count,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: cs.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _animatedExamCard(
    int index,
    BuildContext context,
    ColorScheme cs,
    Map<String, dynamic> exam,
    bool showCountdown,
  ) {
    return _springEntry(
      key: ValueKey('exam_${exam['date']}_${exam['subject']}_$index'),
      duration: Duration(milliseconds: 420 + index * 75),
      offsetY: 28,
      startScale: 0.93,
      curve: _kSmoothBounce,
      child: _examCard(context, cs, exam, showCountdown),
    );
  }

  Widget _countdownChip(ColorScheme cs, int? daysUntil) {
    final l = AppL10n.of(appLocaleNotifier.value);
    if (daysUntil == null) return const SizedBox.shrink();
    String text;
    Color bg;
    Color fg = Colors.white;

    if (daysUntil == 0) {
      text = l.examsToday;
      bg = cs.error;
    } else if (daysUntil == 1) {
      text = l.examsTomorrow;
      bg = cs.tertiary;
    } else if (daysUntil > 1) {
      text = l.examsInDays(daysUntil);
      bg = cs.primary;
    } else {
      text = l.examsPast;
      bg = cs.onSurfaceVariant.withValues(alpha: 0.5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _examCard(
    BuildContext context,
    ColorScheme cs,
    Map<String, dynamic> exam,
    bool showCountdown,
  ) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final isCustom = exam['_source'] == 'custom';
    final subject = _examSubject(exam);
    final type = _examType(exam);
    final dateStr = _formatExamDate(exam['date'] ?? exam['examDate'] ?? '');
    final timeStart = exam['startTime'];
    final timeEnd = exam['endTime'];
    final timeStr = timeStart != null
        ? '${_formatUntisTime(timeStart.toString())} – ${_formatUntisTime((timeEnd ?? timeStart).toString())}'
        : '';
    final teachers = () {
      final t = exam['teachers'] ?? exam['teacher'];
      if (t is List) return t.join(', ');
      if (t is String && t.isNotEmpty) return t;
      return '';
    }();
    final rooms = () {
      final r = exam['rooms'] ?? exam['room'];
      if (r is List) return r.join(', ');
      if (r is String && r.isNotEmpty) return r;
      return '';
    }();
    final desc = (exam['description'] ?? '').toString().trim();

    final ds = (exam['date'] ?? exam['examDate'] ?? '').toString();
    int? daysUntil;
    if (ds.length == 8) {
      try {
        final d = DateTime.parse(
          '${ds.substring(0, 4)}-${ds.substring(4, 6)}-${ds.substring(6, 8)}',
        );
        daysUntil = d
            .difference(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
            )
            .inDays;
      } catch (_) {}
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isCustom ? cs.tertiary : _autoLessonColor(subject, isDark);

    int? customIndex;
    if (isCustom) {
      customIndex = _customExams.indexWhere(
        (e) => e['subject'] == exam['subject'] && e['date'] == exam['date'],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _glassContainer(
        context: context,
        borderRadius: BorderRadius.circular(24),
        color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: isCustom && customIndex != null
                ? () {
                    HapticFeedback.selectionClick();
                    _showAddExamDialog(
                      context,
                      existing: Map<String, dynamic>.from(exam)
                        ..remove('_source'),
                      editIndex: customIndex,
                    );
                  }
                : null,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (type.isNotEmpty)
                                    _chip(
                                      type,
                                      accent.withValues(alpha: 0.2),
                                      accent,
                                    ),
                                  if (isCustom)
                                    _chip(
                                      l.examsOwn,
                                      cs.tertiaryContainer,
                                      cs.tertiary,
                                    ),
                                ],
                              ),
                              const Spacer(),
                              if (showCountdown && daysUntil != null)
                                _countdownChip(cs, daysUntil),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subject.isNotEmpty ? subject : l.examsUnknown,
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              _infoBadge(
                                cs,
                                Icons.calendar_today_rounded,
                                dateStr,
                              ),
                              if (timeStr.isNotEmpty)
                                _infoBadge(
                                  cs,
                                  Icons.access_time_rounded,
                                  timeStr,
                                ),
                              if (rooms.isNotEmpty)
                                _infoBadge(
                                  cs,
                                  Icons.meeting_room_rounded,
                                  rooms,
                                ),
                              if (teachers.isNotEmpty)
                                _infoBadge(
                                  cs,
                                  Icons.person_outline_rounded,
                                  teachers,
                                ),
                            ],
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.notes_rounded,
                                    size: 14,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      desc,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurfaceVariant,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(ColorScheme cs, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- KI-ASSISTENT HILFSFUNKTIONEN ---

String _formatWeekForAi(Map<int, List<dynamic>> weekData, DateTime monday) {
  final l = AppL10n.of(appLocaleNotifier.value);
  final days = l.weekDayFull;
  final buf = StringBuffer();
  for (int i = 0; i < 5; i++) {
    final date = monday.add(Duration(days: i));
    final dateStr = DateFormat('dd.MM.yyyy').format(date);
    final lessons = weekData[i] ?? [];
    buf.writeln('${days[i]}, $dateStr:');
    if (lessons.isEmpty) {
      buf.writeln('  ${l.noLesson}');
    } else {
      for (final lsn in lessons) {
        final start = _formatUntisTime(lsn['startTime'].toString());
        final end = _formatUntisTime(lsn['endTime'].toString());
        final subj = lsn['_subjectLong']?.toString().isNotEmpty == true
            ? lsn['_subjectLong'].toString()
            : lsn['_subjectShort']?.toString() ?? '?';
        final room = lsn['_room']?.toString() ?? '';
        final teacher = lsn['_teacher']?.toString() ?? '';
        final cancelled = (lsn['code'] ?? '') == 'cancelled';
        buf.write('  $start–$end: $subj');
        if (room.isNotEmpty) buf.write(' | ${l.detailRoom} $room');
        if (teacher.isNotEmpty) buf.write(' | $teacher');
        if (cancelled) buf.write(' [${l.detailCancelled}]');
        buf.writeln();
      }
    }
    buf.writeln();
  }
  return buf.toString();
}

String _buildDefaultAiPromptTemplate(AppL10n l) {
  return '''${l.aiSystemPersona}
Heute: [today]
Heute (ISO): [today_iso]
Sprache: [locale]
Schule: [school_name]
Server: [school_url]
Demo-Modus: [demo_mode]
Personentyp: [person_type]
Personen-ID: [person_id]
Wochenbereich: [current_monday] bis [current_friday]

HEUTE:
[day_summary_today]

MORGEN:
[day_summary_tomorrow]

STUNDENPLAN DIESE WOCHE:
[timetable]

PRUEFUNGEN:
[exams]

ROHDATEN STUNDENPLAN (JSON):
[timetable_json]

ROHDATEN PRUEFUNGEN (JSON):
[exams_json]

${l.aiSystemRules}

${l.ui('aiResponseFormat')}''';
}

// --- KI-ASSISTENT CHAT ---

class _TimetableChatSheet extends StatefulWidget {
  final Map<int, List<dynamic>> weekData;
  final DateTime currentMonday;

  const _TimetableChatSheet({
    required this.weekData,
    required this.currentMonday,
  });

  @override
  State<_TimetableChatSheet> createState() => _TimetableChatSheetState();
}

class _TimetableChatSheetState extends State<_TimetableChatSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  List<Map<String, dynamic>> _exams = [];
  bool _thinking = false;

  List<String> get _quickPrompts {
    final suggestions = AppL10n.of(
      appLocaleNotifier.value,
    ).aiSuggestions.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (suggestions.isEmpty) return const [];

    final primary = suggestions.take(4).toList();

    final todayIdx = DateTime.now().weekday - 1;
    final hasTodayLessons =
        todayIdx >= 0 &&
        todayIdx < 5 &&
        (widget.weekData[todayIdx] ?? const []).isNotEmpty;
    final hasUpcomingExams = _exams.any((ex) {
      final raw = (ex['date'] ?? ex['examDate'] ?? ex['startDate'] ?? '')
          .toString();
      return raw.length == 8 &&
          (int.tryParse(raw) ?? 0) >=
              int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
    });

    if (hasTodayLessons && suggestions.length > 4) {
      primary.add(suggestions[4]);
    }
    if (hasUpcomingExams && suggestions.length > 5) {
      primary.add(suggestions[5]);
    }

    return primary.toSet().take(6).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_accountDataKey('customExams')) ?? [];
    final customExams = raw
        .map((e) {
          try {
            return jsonDecode(e) as Map<String, dynamic>;
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();

    if (demoModeNotifier.value) {
      final demoExams = DemoModeService.demoExams(
        locale: appLocaleNotifier.value,
      );
      if (mounted) {
        setState(() {
          _exams = [
            ...demoExams.map((e) => {...e, '_source': 'demo'}),
            ...customExams.map((e) => {...e, '_source': 'custom'}),
          ];
          _exams.sort((a, b) {
            final da =
                int.tryParse(
                  (a['date'] ?? a['examDate'] ?? a['startDate'] ?? 0)
                      .toString(),
                ) ??
                0;
            final db =
                int.tryParse(
                  (b['date'] ?? b['examDate'] ?? b['startDate'] ?? 0)
                      .toString(),
                ) ??
                0;
            return da.compareTo(db);
          });
        });
      }
      return;
    }

    List<Map<String, dynamic>> apiExams = [];
    if (sessionID.isNotEmpty) {
      final now = DateTime.now();
      final startStr = DateFormat(
        'yyyyMMdd',
      ).format(now.subtract(const Duration(days: 14)));
      final endStr = DateFormat(
        'yyyyMMdd',
      ).format(now.add(const Duration(days: 90)));
      final headers = {
        'Cookie': 'JSESSIONID=$sessionID; schoolname=$schoolName',
        'Accept': 'application/json',
      };

      Future<List<Map<String, dynamic>>> tryEndpoint(String path) async {
        try {
          final uri = Uri.parse(
            'https://$schoolUrl$path?startDate=$startStr&endDate=$endStr',
          );
          final res = await http.get(uri, headers: headers);
          if (res.statusCode == 200) {
            final decoded = jsonDecode(res.body);
            List<dynamic> list = [];
            if (decoded is List) {
              list = decoded;
            } else if (decoded is Map) {
              list =
                  (decoded['data'] ??
                          decoded['exams'] ??
                          decoded['result'] ??
                          [])
                      as List;
            }
            return list
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        } catch (_) {}
        return [];
      }

      apiExams = await tryEndpoint('/WebUntis/api/exams');
      if (apiExams.isEmpty) {
        apiExams = await tryEndpoint('/WebUntis/api/classreg/exams');
      }
      if (apiExams.isEmpty && personId != 0) {
        apiExams = await tryEndpoint('/WebUntis/api/exams/student/$personId');
      }
    }

    if (mounted) {
      setState(() {
        _exams = [
          ...apiExams.map((e) => {...e, '_source': 'api'}),
          ...customExams.map((e) => {...e, '_source': 'custom'}),
        ];
        _exams.sort((a, b) {
          final da =
              int.tryParse(
                (a['date'] ?? a['examDate'] ?? a['startDate'] ?? 0).toString(),
              ) ??
              0;
          final db =
              int.tryParse(
                (b['date'] ?? b['examDate'] ?? b['startDate'] ?? 0).toString(),
              ) ??
              0;
          return da.compareTo(db);
        });
      });
    }
  }

  String _formatExamsForAi() {
    final l = AppL10n.of(appLocaleNotifier.value);
    if (_exams.isEmpty) return l.examsNoneEntered;
    final buf = StringBuffer();
    for (var ex in _exams) {
      final subject = ex['subject'] ?? ex['subjectName'] ?? '?';
      final type = ex['type'] ?? 'Klausur';
      final dateRaw = (ex['date'] ?? ex['examDate'] ?? ex['startDate'] ?? '')
          .toString();
      String dateStr = dateRaw;
      if (dateRaw.length == 8) {
        dateStr =
            '${dateRaw.substring(6, 8)}.${dateRaw.substring(4, 6)}.${dateRaw.substring(0, 4)}';
      }
      final name = ex['name'] ?? ex['text'] ?? '';
      buf.write('- $dateStr ($type): $subject');
      if (name.isNotEmpty) buf.write(' "$name"');
      buf.writeln();
    }
    return buf.toString();
  }

  String _defaultPromptTemplate(AppL10n l) {
    return _buildDefaultAiPromptTemplate(l);
  }

  String _daySummaryForPrompt(DateTime date) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final index = date.difference(widget.currentMonday).inDays;
    final dateLabel = DateFormat('dd.MM.yyyy').format(date);
    if (index < 0 || index > 4) {
      return '$dateLabel: ${l.noLesson}';
    }

    final lessons = widget.weekData[index] ?? const [];
    if (lessons.isEmpty) {
      return '$dateLabel: ${l.noLesson}';
    }

    final buf = StringBuffer('$dateLabel:\n');
    for (final lsn in lessons) {
      final start = _formatUntisTime(lsn['startTime'].toString());
      final end = _formatUntisTime(lsn['endTime'].toString());
      final subj = lsn['_subjectLong']?.toString().isNotEmpty == true
          ? lsn['_subjectLong'].toString()
          : lsn['_subjectShort']?.toString() ?? '?';
      final room = lsn['_room']?.toString() ?? '';
      final cancelled = (lsn['code'] ?? '') == 'cancelled';
      buf.write('- $start-$end $subj');
      if (room.isNotEmpty) buf.write(' (${l.detailRoom} $room)');
      if (cancelled) buf.write(' [${l.detailCancelled}]');
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  Object? _jsonSafeValue(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is List) {
      return value.map(_jsonSafeValue).toList();
    }
    if (value is Map) {
      final out = <String, Object?>{};
      value.forEach((key, entryValue) {
        out[key.toString()] = _jsonSafeValue(entryValue);
      });
      return out;
    }
    return value.toString();
  }

  Map<String, String> _promptVariables() {
    final now = DateTime.now();
    final icu = _icuLocale(appLocaleNotifier.value);
    final schedule = _formatWeekForAi(widget.weekData, widget.currentMonday);
    final examsStr = _formatExamsForAi();
    final friday = widget.currentMonday.add(const Duration(days: 4));
    return {
      '[today]': DateFormat('EEEE, dd. MMMM yyyy', icu).format(now),
      '[today_iso]': DateFormat('yyyy-MM-dd').format(now),
      '[locale]': appLocaleNotifier.value,
      '[school_name]': schoolName.isEmpty ? '-' : schoolName,
      '[school_url]': schoolUrl.isEmpty ? '-' : schoolUrl,
      '[person_type]': '$personType',
      '[person_id]': '$personId',
      '[demo_mode]': '${demoModeNotifier.value}',
      '[current_monday]': DateFormat('dd.MM.yyyy').format(widget.currentMonday),
      '[current_friday]': DateFormat('dd.MM.yyyy').format(friday),
      '[day_summary_today]': _daySummaryForPrompt(now),
      '[day_summary_tomorrow]': _daySummaryForPrompt(
        now.add(const Duration(days: 1)),
      ),
      '[timetable]': schedule,
      '[timetable_json]': jsonEncode(_jsonSafeValue(widget.weekData)),
      '[exams]': examsStr,
      '[exams_json]': jsonEncode(_jsonSafeValue(_exams)),
    };
  }

  String _resolvedSystemPrompt() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final template = aiSystemPromptTemplate.trim().isNotEmpty
        ? aiSystemPromptTemplate
        : _defaultPromptTemplate(l);
    final vars = _promptVariables().entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    var resolved = template;
    for (final entry in vars) {
      resolved = resolved.replaceAll(entry.key, entry.value);
    }
    return resolved;
  }

  List<Map<String, String>> _historyForProvider() {
    return _messages
        .map(
          (m) => {
            'role': m['role'] == 'user' ? 'user' : 'assistant',
            'content': m['content'] ?? '',
          },
        )
        .toList();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _thinking) return;

    final provider = _normalizeAiProvider(aiProvider);
    final isLocalProvider = provider == 'local';
    final apiKey = _activeAiApiKey().trim();

    if (isLocalProvider && aiLocalModelPath.isEmpty) {
      final l = AppL10n.of(appLocaleNotifier.value);
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': l.aiLocalModelLoadError,
        });
      });
      return;
    }

    if (!isLocalProvider && apiKey.isEmpty) {
      final l = AppL10n.of(appLocaleNotifier.value);
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': _providerAwareMissingApiKeyMessage(l, provider),
        });
      });
      return;
    }

    _inputController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _thinking = true;
    });
    _scrollToBottom();

    AIProvider? aiProviderInstance;
    try {
      aiProviderInstance = createAIProvider(
        provider: provider,
        model: aiModel.trim().isNotEmpty
            ? aiModel.trim()
            : _defaultModelForProvider(
                provider,
                customCompatibility: aiCustomCompatibility,
              ),
        apiKey: apiKey,
        customBaseUrl: aiCustomBaseUrl,
        customCompatibility: aiCustomCompatibility,
        localModelPath: isLocalProvider ? aiLocalModelPath : null,
      );

      final history = _historyForProvider();
      final systemPrompt = _resolvedSystemPrompt();
      final model = aiModel.trim().isNotEmpty
          ? aiModel.trim()
          : _defaultModelForProvider(
              provider,
              customCompatibility: aiCustomCompatibility,
            );

      setState(() {
        _messages.add({'role': 'assistant', 'content': ''});
      });

      final stream = aiProviderInstance.streamResponse(
        systemPrompt: systemPrompt,
        history: history,
        model: model,
      );

      await for (final chunk in stream) {
        if (!mounted) break;
        setState(() {
          final lastIndex = _messages.length - 1;
          if (lastIndex >= 0 && _messages[lastIndex]['role'] == 'assistant') {
            final String currentContent = _messages[lastIndex]['content'] ?? '';
            _messages[lastIndex]['content'] = currentContent + chunk;
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      final message = e.toString();
      final l = AppL10n.of(appLocaleNotifier.value);
      final isApiError = message.contains('API:');
      final isConfigError = message.contains('CONFIG:');
      setState(() {
        if (_messages.isNotEmpty && _messages.last['role'] == 'assistant') {
          _messages.last['content'] = isConfigError
              ? message.replaceFirst('Exception: CONFIG: ', '')
              : isApiError
              ? '${l.aiApiError} ${message.replaceFirst('Exception: API: ', '')}'
              : '${l.aiConnectionError} $e';
        } else {
          _messages.add({
            'role': 'assistant',
            'content': isConfigError
                ? message.replaceFirst('Exception: CONFIG: ', '')
                : isApiError
                ? '${l.aiApiError} ${message.replaceFirst('Exception: API: ', '')}'
                : '${l.aiConnectionError} $e',
          });
        }
      });
    } finally {
      await aiProviderInstance?.dispose();
      if (mounted) setState(() => _thinking = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendQuickPrompt(String prompt) async {
    if (_thinking) return;
    _inputController.text = prompt;
    await _send();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: _kSoftBounce,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: _withOptionalBackdropBlur(
        sigma: 24,
        child: const SizedBox.shrink(),
        childBuilder: (enabled) => Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: enabled ? cs.surface.withValues(alpha: 0.78) : cs.surface,
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.surface.withValues(alpha: 0.85),
                      cs.surface.withValues(alpha: 0.78),
                      cs.surfaceContainerHigh.withValues(alpha: 0.66),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  )
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 16, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cs.primaryContainer,
                                cs.tertiaryContainer,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: cs.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppL10n.of(appLocaleNotifier.value).aiTitle,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              AppL10n.of(appLocaleNotifier.value).aiAskAnything,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
                    if (_quickPrompts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _quickPrompts.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final prompt = _quickPrompts[index];
                            return ActionChip(
                              avatar: const Icon(Icons.bolt_rounded, size: 15),
                              label: Text(
                                prompt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: cs.primaryContainer.withValues(
                                alpha: 0.7,
                              ),
                              side: BorderSide.none,
                              onPressed: _thinking
                                  ? null
                                  : () => _sendQuickPrompt(prompt),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyHint(cs)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length + (_thinking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return _buildTypingBubble(cs);
                          }
                          final msg = _messages[index];
                          final isUser = msg['role'] == 'user';
                          return _buildBubble(cs, msg['content']!, isUser);
                        },
                      ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.surfaceContainerHigh.withValues(alpha: 0.72),
                        cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          style: GoogleFonts.outfit(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: AppL10n.of(
                              appLocaleNotifier.value,
                            ).aiInputHint,
                            hintStyle: GoogleFonts.outfit(
                              color: cs.onSurface.withValues(alpha: 0.38),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedOpacity(
                        opacity: _thinking ? 0.4 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: FilledButton(
                          onPressed: _thinking ? null : _send,
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(14),
                          ),
                          child: const Icon(Icons.send_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHint(ColorScheme cs) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final suggestions = l.aiSuggestions;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_rounded,
            size: 40,
            color: cs.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            l.aiKnowsSchedule,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.aiAskAnything,
            style: GoogleFonts.outfit(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map(
                  (s) => ActionChip(
                    label: Text(
                      s,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    backgroundColor: cs.primaryContainer,
                    side: BorderSide.none,
                    onPressed: () {
                      _inputController.text = s;
                      _send();
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(ColorScheme cs, String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, cs.secondary],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.surfaceContainerHigh.withValues(alpha: 0.72),
                    cs.surfaceContainerHighest.withValues(alpha: 0.58),
                  ],
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isUser
            ? Text(
                content,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cs.onPrimary,
                ),
              )
            : MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                      p: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                        height: 1.25,
                      ),
                      strong: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      em: GoogleFonts.outfit(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                      code: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
              ),
      ),
    );
  }

  Widget _buildTypingBubble(ColorScheme cs) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            const SizedBox(width: 4),
            _Dot(delay: 150),
            const SizedBox(width: 4),
            _Dot(delay: 300),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    Future.delayed(
      Duration(milliseconds: widget.delay),
      () => mounted ? _ctrl.repeat(reverse: true) : null,
    );
    _anim = Tween(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: _kSmoothBounce));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// --- DETAIL BOTTOM SHEET OPENER ---
void _showLessonDetail(
  BuildContext context,
  dynamic lesson, {
  String originalTeacher = '',
}) {
  HapticFeedback.mediumImpact();
  final subject = lesson['_subjectLong']?.toString().isNotEmpty == true
      ? lesson['_subjectLong'].toString()
      : (lesson['_subjectShort']?.toString().isNotEmpty == true
            ? lesson['_subjectShort'].toString()
            : '---');
  final subjectShort = lesson['_subjectShort']?.toString() ?? '';
  final room = lesson['_room']?.toString().isNotEmpty == true
      ? lesson['_room'].toString()
      : '---';
  final teacher = lesson['_teacher']?.toString() ?? '';
  final time =
      '${_formatUntisTime(lesson['startTime'].toString())} – ${_formatUntisTime(lesson['endTime'].toString())}';
  final isCancelled = (lesson['code'] ?? '') == 'cancelled';
  final info = (lesson['info'] ?? lesson['substText'] ?? '').toString().trim();
  final lessonNr = lesson['lsnumber']?.toString() ?? '';
  final studentNotes = (lesson['lsText'] ?? lesson['lstext'] ?? '')
      .toString()
      .trim();
  final subjectKey = lesson['_subjectShort']?.toString() ?? '';
  final eventName = lesson['_eventName']?.toString() ?? '';
  final classNames = lesson['_classNames']?.toString() ?? '';
  final activityType = lesson['_activityType']?.toString() ?? '';

  // Attach homework and class-register notes for this specific lesson. The
  // lesson id alone is not unique across dates, so match on date as well.
  final lessonId = lesson['id'] ?? lesson['lsid'];
  final dateInt = lesson['date'] as int?;

  final homework = homeworksNotifier.value
      .where((h) => h['lessonId'] == lessonId)
      .map((h) => h['text']?.toString() ?? '')
      .where((t) => t.isNotEmpty)
      .join('\n');

  final registerNotes = lessonNotesNotifier.value
      .where((n) {
        final noteLessonId = n['lessonId'];
        final noteDate = n['date'] as int?;
        return noteLessonId == lessonId &&
            (noteDate == null || noteDate == dateInt);
      })
      .map((n) => n['text']?.toString() ?? '')
      .where((t) => t.isNotEmpty)
      .join('\n');

  _showUnifiedSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    builder: (_) => _LessonDetailSheet(
      subject: subject,
      subjectShort: subjectShort,
      room: room,
      teacher: teacher,
      originalTeacher: originalTeacher,
      time: time,
      isCancelled: isCancelled,
      info: info,
      lessonNr: lessonNr,
      eventName: eventName,
      classNames: classNames,
      activityType: activityType,
      studentNotes: studentNotes,
      registerNotes: registerNotes,
      homework: homework,
      onHideSubject: () {
        Navigator.of(context).pop();
        _hideSubject(subjectKey);
      },
    ),
  );
}

// ignore: unused_element
class _AnimatedLessonCard extends StatelessWidget {
  final int index;
  final dynamic lesson;

  const _AnimatedLessonCard({required this.index, required this.lesson});

  String get _subjectKey => lesson['_subjectShort']?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return _springEntry(
      duration: Duration(milliseconds: 760 + (index * 140)),
      offsetY: 60,
      startScale: 0.9,
      curve: _kSmoothBounce,
      child: LessonCard(
        subject: lesson['_subjectLong']?.toString().isNotEmpty == true
            ? lesson['_subjectLong'].toString()
            : (lesson['_subjectShort']?.toString().isNotEmpty == true
                  ? lesson['_subjectShort'].toString()
                  : "---"),
        subjectShort: lesson['_subjectShort']?.toString() ?? "",
        room: lesson['_room']?.toString().isNotEmpty == true
            ? lesson['_room'].toString()
            : "---",
        teacher: lesson['_teacher']?.toString() ?? "",
        time:
            "${_formatUntisTime(lesson['startTime'].toString())} - ${_formatUntisTime(lesson['endTime'].toString())}",
        isCancelled: (lesson['code'] ?? "") == "cancelled",
        onTap: () => _showLessonDetail(context, lesson),
        onHideSubject: () => _hideSubject(_subjectKey),
      ),
    );
  }
}

class _LessonDetailSheet extends StatelessWidget {
  final String subject, subjectShort, room, teacher, time, info, lessonNr;
  final String originalTeacher;
  final String eventName, classNames, activityType;
  final String studentNotes, registerNotes, homework;
  final bool isCancelled;
  final VoidCallback? onHideSubject;

  const _LessonDetailSheet({
    required this.subject,
    required this.subjectShort,
    required this.room,
    required this.teacher,
    required this.time,
    required this.isCancelled,
    required this.info,
    required this.lessonNr,
    this.originalTeacher = '',
    this.eventName = '',
    this.classNames = '',
    this.activityType = '',
    this.studentNotes = '',
    this.registerNotes = '',
    this.homework = '',
    this.onHideSubject,
  });

  Widget _topActionButton(
    BuildContext context,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    if (value.isEmpty || value == '---') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).colorScheme.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final cancelledColor = Color(
      cancelledLessonColorNotifier.value,
    ).harmonizeWith(cs.primary);
    return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isCancelled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cancelledColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          size: 16,
                          color: cancelledColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l.detailCancelled,
                          style: GoogleFonts.outfit(
                            color: cancelledColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: cs.tertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l.detailRegular,
                          style: GoogleFonts.outfit(
                            color: cs.tertiary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                _topActionButton(
                  context,
                  Icons.visibility_off_outlined,
                  cs.onSurface.withValues(alpha: 0.6),
                  onTap: onHideSubject,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              subject,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            if (subjectShort.isNotEmpty)
              Text(
                subjectShort,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.primary.withValues(alpha: 0.7),
                ),
              ),

            const SizedBox(height: 24),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 16),

            _row(context, Icons.access_time_rounded, l.detailTime, time),
            _row(context, Icons.person_rounded, l.detailTeacher, teacher),
            if (originalTeacher.isNotEmpty && originalTeacher != teacher)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.tertiary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        size: 20,
                        color: cs.tertiary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.detailOriginalTeacher,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            originalTeacher,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: cs.tertiary.withValues(
                                alpha: 0.7,
                              ),
                              decorationThickness: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            _row(context, Icons.room_rounded, l.detailRoom, room),
            if (classNames.isNotEmpty)
              _row(context, Icons.group_rounded, l.detailClass, classNames),
            if (activityType.isNotEmpty && activityType != 'Unterricht')
              _row(context, Icons.category_rounded, 'Art', activityType),
            if (lessonNr.isNotEmpty && lessonNr != '0')
              _row(context, Icons.tag_rounded, l.detailLesson, lessonNr),
            if (studentNotes.isNotEmpty)
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    _buildBouncyRoute(
                      StudentNotesPage(
                        notes: studentNotes,
                        registerNotes: registerNotes,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: _row(
                  context,
                  Icons.notes_rounded,
                  l.detailNotesForStudents,
                  studentNotes,
                ),
              ),
            if (registerNotes.isNotEmpty)
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    _buildBouncyRoute(
                      StudentNotesPage(
                        notes: studentNotes,
                        registerNotes: registerNotes,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: _row(
                  context,
                  Icons.book_rounded,
                  l.detailLessonNotes,
                  registerNotes,
                  iconColor: cs.primary,
                ),
              ),
            if (homework.isNotEmpty)
              InkWell(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(_buildBouncyRoute(const HomeworkPage()));
                },
                borderRadius: BorderRadius.circular(16),
                child: _row(
                  context,
                  Icons.assignment_rounded,
                  l.detailHomework,
                  homework,
                ),
              ),
            if (info.isNotEmpty)
              _row(
                context,
                Icons.info_outline_rounded,
                l.detailInfo,
                info,
                iconColor: cs.tertiary,
              ),

            const SizedBox(height: 48),
          ],
        ),
      );
  }
}

// --- NOTIZEN DETAIL SEITE ---

class StudentNotesPage extends StatelessWidget {
  /// Planned lesson text from the timetable (`lsText`).
  final String notes;

  /// Actual notes from the class register (WebUntis lessonNotes).
  final String registerNotes;

  const StudentNotesPage({
    super.key,
    required this.notes,
    this.registerNotes = '',
  });

  Widget _noteSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.detailNotesForStudents,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _AnimatedBackground(child: const SizedBox.expand()),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: _withOptionalBackdropBlur(
                sigma: 24,
                child: const SizedBox.shrink(),
                childBuilder: (enabled) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notes.isNotEmpty) ...[
                        _noteSectionHeader(
                          context,
                          icon: Icons.notes_rounded,
                          title: l.detailNotesForStudents,
                          iconColor: cs.tertiary,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          notes,
                          style: GoogleFonts.outfit(
                            fontSize: 17.5,
                            height: 1.7,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                      if (notes.isNotEmpty && registerNotes.isNotEmpty)
                        const SizedBox(height: 36),
                      if (registerNotes.isNotEmpty) ...[
                        _noteSectionHeader(
                          context,
                          icon: Icons.book_rounded,
                          title: l.detailLessonNotes,
                          iconColor: cs.primary,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          registerNotes,
                          style: GoogleFonts.outfit(
                            fontSize: 17.5,
                            height: 1.7,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- EXPRESSIVE CARD DESIGN ---
class LessonCard extends StatelessWidget {
  final String subject, subjectShort, room, teacher, time;
  final bool isCancelled;
  final VoidCallback? onTap;
  final VoidCallback? onHideSubject;

  const LessonCard({
    super.key,
    required this.subject,
    this.subjectShort = "",
    required this.room,
    this.teacher = "",
    required this.time,
    this.isCancelled = false,
    this.onTap,
    this.onHideSubject,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = untisThemeTokensOf(context);
    final themeOwnsStyle = tokens.id != AppThemeId.defaultTheme;
    final cancelledColor = Color(
      cancelledLessonColorNotifier.value,
    ).harmonizeWith(cs.primary);

    final effectiveRadius = themeOwnsStyle
        ? tokens.surfaceRadius
        : (lessonBorderRadiusNotifier.value * 2.0).clamp(16.0, 36.0);
    final cardRadius = BorderRadius.circular(effectiveRadius);

    final showTeacher = lessonShowTeacherNotifier.value;
    final showRoom = lessonShowRoomNotifier.value;
    final cardStyle = themeOwnsStyle ? 3 : lessonCardStyleNotifier.value;
    final blurEnabled =
        tokens.supportsBlur &&
        blurEnabledNotifier.value &&
        (themeOwnsStyle || lessonBlurEnabledNotifier.value || cardStyle == 1);
    final blurSigma = themeOwnsStyle
        ? tokens.blurSigma
        : lessonBlurAmountNotifier.value;
    final cardOpacity = themeOwnsStyle ? 0.84 : lessonCardOpacityNotifier.value;
    final glowEnabled = tokens.glowEffectsEnabled;
    final accentStyle = themeOwnsStyle ? 0 : lessonAccentStyleNotifier.value;

    final primaryColor = isCancelled ? cancelledColor : cs.primary;

    List<BoxShadow>? shadows;
    if (glowEnabled) {
      shadows = [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.18),
          blurRadius: 12,
          spreadRadius: 0.8,
          offset: const Offset(0, 3),
        ),
      ];
    }

    Color surfaceColor;
    Border? border;
    if (isCancelled) {
      surfaceColor = cancelledColor.withValues(
        alpha: (0.16 * cardOpacity).clamp(0.0, 1.0),
      );
      border = Border.all(
        color: cancelledColor.withValues(alpha: 0.40),
        width: 1.5,
      );
    } else if (cardStyle == 1 || blurEnabled) {
      surfaceColor = cs.surfaceContainerLowest.withValues(
        alpha: (0.65 * cardOpacity).clamp(0.0, 1.0),
      );
      border = Border.all(
        color: cs.outlineVariant.withValues(alpha: 0.45),
        width: 1.5,
      );
    } else if (cardStyle == 3) {
      surfaceColor = cs.surfaceContainerLow.withValues(
        alpha: (0.75 * cardOpacity).clamp(0.0, 1.0),
      );
      border = Border.all(
        color: primaryColor.withValues(alpha: isDark ? 0.70 : 0.50),
        width: 2.0,
      );
    } else {
      surfaceColor = cs.surfaceContainerLow.withValues(
        alpha: cardOpacity.clamp(0.4, 1.0),
      );
      border = Border.all(
        color: cs.outlineVariant.withValues(alpha: 0.35),
        width: 1.5,
      );
    }

    if (tokens.id == AppThemeId.manga) {
      surfaceColor = cs.surfaceContainerLow;
      border = Border.all(color: cs.outline, width: tokens.borderWidth);
      shadows = [
        BoxShadow(
          color: tokens.shadowColor,
          offset: tokens.shadowOffset,
          blurRadius: 0,
        ),
      ];
    } else if (tokens.id == AppThemeId.cyber) {
      border = Border.all(color: primaryColor, width: tokens.borderWidth);
    }

    Widget cardBody = Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: cardRadius,
        border: border,
      ),
      child: Stack(
        children: [
          if (accentStyle == 0 || accentStyle == 1)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: accentStyle == 0 ? 5.0 : 2.5,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(effectiveRadius),
                    bottomLeft: Radius.circular(effectiveRadius),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                if (accentStyle == 2) ...[
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      boxShadow: _glowShadows(context, [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ]),
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.outfit(
                          color: isCancelled ? cancelledColor : cs.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isCancelled ? cancelledColor : null,
                          decoration: isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: cancelledColor.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      if (subjectShort.isNotEmpty)
                        Text(
                          subjectShort,
                          style: GoogleFonts.outfit(
                            color: isCancelled
                                ? cancelledColor.withValues(alpha: 0.7)
                                : cs.primary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (showRoom && room.isNotEmpty) ...[
                            Icon(
                              Icons.room_outlined,
                              size: 15,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              room,
                              style: GoogleFonts.outfit(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          if (showTeacher && teacher.isNotEmpty) ...[
                            if (showRoom && room.isNotEmpty)
                              const SizedBox(width: 12),
                            Icon(
                              Icons.person_outline_rounded,
                              size: 15,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              teacher,
                              style: GoogleFonts.outfit(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCancelled)
                  Badge(
                    label: Text(
                      AppL10n.of(appLocaleNotifier.value).detailCancelledBadge,
                    ),
                    backgroundColor: cancelledColor,
                    textColor: cs.onError,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (blurEnabled) {
      cardBody = ClipRRect(
        borderRadius: cardRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: cardBody,
        ),
      );
    } else {
      cardBody = ClipRRect(borderRadius: cardRadius, child: cardBody);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(borderRadius: cardRadius, boxShadow: shadows),
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        onTapDown: (_) => HapticFeedback.selectionClick(),
        child: cardBody,
      ),
    );
  }
}

class _MessageAttachment {
  final String id;
  final String name;
  final bool isDemo;

  const _MessageAttachment({
    required this.id,
    required this.name,
    this.isDemo = false,
  });

  String get fileExtension {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toUpperCase();
  }
}

class _SchoolNotificationItem {
  final String id;
  final String title;
  final String body;
  final String fullBody;
  final DateTime? date;
  final String? author;
  final String? url;
  final List<_MessageAttachment> attachments;

  const _SchoolNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.fullBody = '',
    this.author,
    this.url,
    this.attachments = const [],
  });

  int get sortValue => date?.millisecondsSinceEpoch ?? 0;

  String get displayBody => fullBody.isEmpty ? body : fullBody;

  String? get uniformAttachmentExtension {
    if (attachments.isEmpty) return null;
    final first = attachments.first.fileExtension;
    if (first.isEmpty) return null;
    for (final attachment in attachments) {
      if (attachment.fileExtension != first) return null;
    }
    return first;
  }
}

// --- INFO / SCHUL-BENACHRICHTIGUNGEN ---
class SchoolNotificationsPage extends StatefulWidget {
  const SchoolNotificationsPage({super.key, this.isActive = true});

  /// The main navigation keeps its pages alive. Delay the first network load
  /// until this tab is actually shown, then refresh when it is revisited.
  final bool isActive;

  @override
  State<SchoolNotificationsPage> createState() =>
      _SchoolNotificationsPageState();
}

class _SchoolNotificationsPageState extends State<SchoolNotificationsPage> {
  List<_SchoolNotificationItem> _newsItems = const [];
  List<_SchoolNotificationItem> _inboxItems = const [];
  bool _showInbox = false;
  String? _selectedNotificationId;
  bool _loading = true;
  String? _error;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      unawaited(_reload(showSpinner: true));
    }
  }

  @override
  void didUpdateWidget(covariant SchoolNotificationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      unawaited(_reload(showSpinner: true));
    }
  }

  /// Unread inbox ids resolved for the current session (used for the little
  /// dot on unread list tiles).
  final Set<String> _unreadMessageIds = {};

  String get _seenAccountId => activeUntisAccountId ?? 'legacy';

  Future<Set<String>> _loadSeenMessageIds() async {
    final key = OfflineCacheStore.instance.scopedKey(
      accountId: _seenAccountId,
      dataset: 'inboxSeen',
      entityKey: 'ids',
    );
    final document = await OfflineCacheStore.instance.read(key);
    final values = document?.value['ids'];
    if (values is! List) return const {};
    return values.map((entry) => '$entry').toSet();
  }

  Future<void> _persistSeenMessageIds(Set<String> ids) async {
    final key = OfflineCacheStore.instance.scopedKey(
      accountId: _seenAccountId,
      dataset: 'inboxSeen',
      entityKey: 'ids',
    );
    await OfflineCacheStore.instance.write(key, {
      'ids': ids.take(500).toList(),
    });
  }

  /// Counts inbox messages that arrived since the last visit and merges the
  /// current ids into the seen watermark, so the next visit only counts
  /// messages arriving in between.
  Future<void> _refreshInboxUnread(List<_SchoolNotificationItem> inbox) async {
    if (demoModeNotifier.value) {
      unreadInboxMessagesNotifier.value = 0;
      return;
    }
    if (inbox.isEmpty) return;
    final seen = await _loadSeenMessageIds();
    final unread = inbox.where((item) => !seen.contains(item.id)).toList();
    _unreadMessageIds
      ..clear()
      ..addAll(unread.map((item) => item.id));
    unreadInboxMessagesNotifier.value = unread.length;
    await _persistSeenMessageIds({...seen, ...inbox.map((item) => item.id)});
  }

  /// Called when an inbox message is opened; its unread dot disappears.
  void _markMessageOpened(_SchoolNotificationItem item) {
    if (_unreadMessageIds.remove(item.id)) {
      unreadInboxMessagesNotifier.value = _unreadMessageIds.length;
    }
  }

  Future<void> _reload({bool showSpinner = false}) async {
    if (demoModeNotifier.value) {
      final locale = appLocaleNotifier.value;
      final fetchedNews = DemoModeService.demoNotifications(locale: locale).map(
        (raw) {
          return _SchoolNotificationItem(
            id: raw['id'].toString(),
            title: raw['title']?.toString() ?? '',
            body: raw['message']?.toString() ?? '',
            date: _parseNotificationDate(raw['date']),
            author: raw['author']?.toString(),
          );
        },
      ).toList();
      final fetchedInbox =
          DemoModeService.demoInboxNotifications(locale: locale).map((raw) {
            return _SchoolNotificationItem(
              id: raw['id'].toString(),
              title: raw['title']?.toString() ?? '',
              body:
                  raw['contentPreview']?.toString() ??
                  raw['message']?.toString() ??
                  '',
              fullBody: raw['content']?.toString() ?? '',
              date: _parseNotificationDate(raw['sentDateTime'] ?? raw['date']),
              author: raw['sender'] is Map
                  ? (raw['sender'] as Map)['displayName']?.toString()
                  : raw['author']?.toString(),
              attachments: (raw['attachments'] as List? ?? const [])
                  .whereType<Map>()
                  .map(
                    (m) => _MessageAttachment(
                      id: m['id'].toString(),
                      name: m['name'].toString(),
                      isDemo: true,
                    ),
                  )
                  .toList(),
            );
          }).toList();
      if (!mounted) return;
      setState(() {
        _newsItems = fetchedNews;
        _inboxItems = fetchedInbox;
        _selectedNotificationId = _firstNotificationId(
          _showInbox ? fetchedInbox : fetchedNews,
        );
        _loading = false;
        _error = null;
        _lastUpdated = DateTime.now();
      });
      unawaited(_refreshInboxUnread(fetchedInbox));
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final summary = fetchedNews
            .take(3)
            .map((item) => item.title)
            .join('\n');
        unawaited(
          WidgetService.updateNotificationWidget(
            summary,
            accountId: activeUntisAccountId ?? 'active',
          ),
        );
      }
      return;
    }

    if (sessionID.isEmpty || schoolUrl.isEmpty || schoolName.isEmpty) {
      final reAuthenticated = await _reAuthenticate();
      if (!reAuthenticated ||
          sessionID.isEmpty ||
          schoolUrl.isEmpty ||
          schoolName.isEmpty) {
        if (!mounted) return;
        setState(() {
          _newsItems = const [];
          _inboxItems = const [];
          _selectedNotificationId = null;
          _loading = false;
          _error = null;
          _lastUpdated = DateTime.now();
        });
        unreadInboxMessagesNotifier.value = 0;
        return;
      }
    }

    if ((showSpinner || (_newsItems.isEmpty && _inboxItems.isEmpty)) &&
        mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final fetched = await _fetchSchoolNotifications();
      if (!mounted) return;
      setState(() {
        _newsItems = fetched.news;
        _inboxItems = fetched.inbox;
        final active = _showInbox ? fetched.inbox : fetched.news;
        final hasExistingSelection = active.any(
          (item) => item.id == _selectedNotificationId,
        );
        _selectedNotificationId = hasExistingSelection
            ? _selectedNotificationId
            : _firstNotificationId(active);
        _loading = false;
        _error = null;
        _lastUpdated = DateTime.now();
      });
      unawaited(_refreshInboxUnread(fetched.inbox));
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final summary = fetched.news
            .take(3)
            .map((item) => item.title)
            .join('\n');
        unawaited(
          WidgetService.updateNotificationWidget(
            summary.isEmpty
                ? AppL10n.of(appLocaleNotifier.value).ui('notificationsNone')
                : summary,
            accountId: activeUntisAccountId ?? 'active',
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppL10n.of(appLocaleNotifier.value).infoFetchError;
        _lastUpdated = DateTime.now();
      });
    }
  }

  Future<
    ({List<_SchoolNotificationItem> inbox, List<_SchoolNotificationItem> news})
  >
  _fetchSchoolNotifications() async {
    final start = DateTime.now().subtract(const Duration(days: 45));
    final end = DateTime.now().add(const Duration(days: 90));
    final startStr = DateFormat('yyyyMMdd').format(start);
    final endStr = DateFormat('yyyyMMdd').format(end);

    String encodedSchoolName() {
      try {
        return '_${base64Encode(utf8.encode(schoolName))}';
      } catch (_) {
        return schoolName;
      }
    }

    final schoolCookieCandidates = <String>{
      encodedSchoolName(),
      schoolName,
    }.where((e) => e.isNotEmpty).toList(growable: false);

    Map<String, String> buildHeaders(
      String schoolCookie, {
      Map<String, String>? extra,
    }) {
      return {
        'Cookie': 'JSESSIONID=$sessionID; schoolname=$schoolCookie',
        'Accept': 'application/json',
        ...?extra,
      };
    }

    Future<http.Response?> requestWithCookieFallback(
      Future<http.Response> Function(Map<String, String> headers) sender, {
      bool retry = true,
    }) async {
      for (final schoolCookie in schoolCookieCandidates) {
        try {
          final response = await sender(buildHeaders(schoolCookie));
          if (response.statusCode == 200) return response;
          if ((response.statusCode == 401 || response.statusCode == 403) &&
              retry &&
              await _reAuthenticate()) {
            return await requestWithCookieFallback(sender, retry: false);
          }
        } catch (_) {}
      }
      return null;
    }

    List<dynamic> extractList(dynamic decoded) {
      if (decoded is List) return decoded;
      if (decoded is Map) {
        for (final value in decoded.values) {
          final nested = extractList(value);
          if (nested.isNotEmpty) return nested;
        }
      }
      return const [];
    }

    Future<String?> fetchJwtToken() async {
      final uri = Uri.parse('https://$schoolUrl/WebUntis/api/token/new');
      final response = await requestWithCookieFallback(
        (headers) => http.get(uri, headers: headers),
      );
      if (response == null || response.body.trim().isEmpty) return null;

      final raw = response.body.trim();
      if (!raw.startsWith('{')) return raw.replaceAll('"', '').trim();
      try {
        final decoded = jsonDecode(raw);
        if (decoded is String && decoded.trim().isNotEmpty) {
          return decoded.trim();
        }
        if (decoded is Map) {
          final token =
              decoded['token'] ??
              decoded['jwt'] ??
              decoded['jwt_token'] ??
              decoded['accessToken'];
          if (token != null && token.toString().trim().isNotEmpty) {
            return token.toString().trim();
          }
        }
      } catch (_) {}
      return null;
    }

    List<_MessageAttachment> parseMessageAttachments(Map<String, dynamic> map) {
      final out = <_MessageAttachment>[];
      dynamic rawAttachments;
      for (final key in const [
        'attachments',
        'fileAttachments',
        'attachmentList',
        'files',
      ]) {
        final value = map[key];
        if (value is List) {
          rawAttachments = value;
          break;
        }
      }
      if (rawAttachments is! List) return out;
      for (final entry in rawAttachments) {
        if (entry is! Map) continue;
        final attachment = Map<String, dynamic>.from(entry);
        final id =
            (attachment['fileId'] ??
                    attachment['attachmentId'] ??
                    attachment['fileAttachmentId'] ??
                    attachment['id'] ??
                    '')
                .toString();
        final name =
            (attachment['fileRegularName'] ??
                    attachment['fileName'] ??
                    attachment['regularName'] ??
                    attachment['name'] ??
                    '')
                .toString()
                .trim();
        if (id.isEmpty && name.isEmpty) continue;
        out.add(_MessageAttachment(id: id, name: name));
      }
      return out;
    }

    Future<List<Map<String, dynamic>>> fetchInboxMessages() async {
      final token = await fetchJwtToken();
      if (token == null || token.isEmpty) return const [];
      final uri = Uri.parse(
        'https://$schoolUrl/WebUntis/api/rest/view/v1/messages',
      );
      final response = await requestWithCookieFallback(
        (headers) => http.get(
          uri,
          headers: {...headers, 'Authorization': 'Bearer $token'},
        ),
      );
      if (response == null || response.body.trim().isEmpty) return const [];
      try {
        final decoded = jsonDecode(response.body);
        final incoming = decoded is Map ? decoded['incomingMessages'] : null;
        if (incoming is! List) return const [];
        return incoming
            .whereType<Map>()
            .map((raw) {
              final rawMap = Map<String, dynamic>.from(raw);
              // Some WebUntis deployments wrap the fields in a "message"
              // object, others expose them directly on the entry.
              final map = rawMap['message'] is Map
                  ? Map<String, dynamic>.from(rawMap['message'])
                  : rawMap;
              final sender = map['sender'];
              final preview =
                  map['contentPreview'] ?? map['message'] ?? map['text'] ?? '';
              final content = map['content'] ?? preview;
              return {
                ...map,
                'message': preview,
                'fullBody': content,
                'author': sender is Map
                    ? sender['displayName'] ?? sender['name']
                    : null,
                'date': map['sentDateTime'] ?? map['date'] ?? map['sendTime'],
                'attachments': parseMessageAttachments(map),
              };
            })
            .toList(growable: false);
      } catch (_) {
        return const [];
      }
    }

    Future<List<Map<String, dynamic>>> fetchNewsWidgetMessages() async {
      final out = <Map<String, dynamic>>[];
      final days = List.generate(
        4,
        (index) => DateTime.now().subtract(Duration(days: index)),
      );

      for (final day in days) {
        final untisDate = DateFormat('yyyyMMdd').format(day);
        final uri = Uri.parse(
          'https://$schoolUrl/WebUntis/api/public/news/newsWidgetData?date=$untisDate',
        );
        final response = await requestWithCookieFallback(
          (headers) => http.get(uri, headers: headers),
        );
        if (response == null || response.body.trim().isEmpty) continue;

        try {
          final decoded = jsonDecode(response.body);
          final data = decoded is Map ? decoded['data'] : null;
          final messagesOfDay = data is Map ? data['messagesOfDay'] : null;
          if (messagesOfDay is! List) continue;

          for (final entry in messagesOfDay) {
            if (entry is! Map) continue;
            final map = Map<String, dynamic>.from(entry);
            out.add({
              ...map,
              'date': map['date'] ?? untisDate,
              'message': map['text'] ?? map['message'] ?? '',
            });
          }
        } catch (_) {}
      }

      return out;
    }

    Future<List<dynamic>> tryGet(String path, {bool retry = true}) async {
      final uri = Uri.parse('https://$schoolUrl$path');
      final response = await requestWithCookieFallback(
        (headers) => http.get(uri, headers: headers),
        retry: retry,
      );

      if (response == null || response.body.trim().isEmpty) {
        return const [];
      }

      try {
        return extractList(jsonDecode(response.body));
      } catch (_) {}
      return const [];
    }

    Future<List<dynamic>> tryJsonRpc(
      String method,
      Map<String, dynamic> params, {
      bool retry = true,
    }) async {
      final uri = Uri.parse(
        'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
      );
      final response = await requestWithCookieFallback(
        (headers) => http.post(
          uri,
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': 'school-info',
            'method': method,
            'params': params,
            'jsonrpc': '2.0',
          }),
        ),
        retry: retry,
      );

      if (response == null || response.body.trim().isEmpty) {
        return const [];
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] != null) {
          return const [];
        }
        if (decoded is Map) {
          return extractList(decoded['result'] ?? decoded);
        }
        return extractList(decoded);
      } catch (_) {}
      return const [];
    }

    // WebUntis distinguishes personal Mitteilungen from its public Start
    // feed. Fetch both in parallel and keep them separate in the UI so a
    // reload cannot silently replace one category with the other.
    final initialResults = await Future.wait([
      fetchInboxMessages(),
      fetchNewsWidgetMessages(),
    ]);
    final inboxMessages = initialResults[0];
    List<dynamic> schoolMessages = initialResults[1];

    if (schoolMessages.isEmpty) {
      final schoolFallbacks = [
        () => tryJsonRpc('getMessagesOfDay2017', {
          'date': DateFormat('yyyyMMdd').format(DateTime.now()),
        }),
        () => tryGet(
          '/WebUntis/api/public/messages?startDate=$startStr&endDate=$endStr',
        ),
        () => tryGet(
          '/WebUntis/api/messages?startDate=$startStr&endDate=$endStr',
        ),
        () => tryGet(
          '/WebUntis/api/public/notifications?startDate=$startStr&endDate=$endStr',
        ),
        () => tryGet(
          '/WebUntis/api/public/notices?startDate=$startStr&endDate=$endStr',
        ),
        () => tryJsonRpc('getMessagesOfDay', {
          'date': DateFormat('yyyyMMdd').format(DateTime.now()),
        }),
        () => tryJsonRpc('getMessages', {
          'startDate': startStr,
          'endDate': endStr,
        }),
      ];

      for (final fallback in schoolFallbacks) {
        schoolMessages = await fallback();
        if (schoolMessages.isNotEmpty) break;
      }
    }

    List<_SchoolNotificationItem> toItems(List<dynamic> raw) {
      final seen = <String>{};
      final items = <_SchoolNotificationItem>[];

      for (final entry in raw) {
        if (entry is! Map) continue;
        final map = Map<String, dynamic>.from(entry);

        final title =
            (map['title'] ??
                    map['subject'] ??
                    map['headline'] ??
                    map['name'] ??
                    '')
                .toString()
                .trim();
        final body =
            (map['message'] ??
                    map['text'] ??
                    map['content'] ??
                    map['description'] ??
                    '')
                .toString()
                .trim();
        if (title.isEmpty && body.isEmpty) continue;

        final id =
            (map['id'] ?? map['messageId'] ?? map['uuid'] ?? '$title-$body')
                .toString();
        if (seen.contains(id)) continue;
        seen.add(id);

        final dt = _parseNotificationDate(
          map['date'] ??
              map['startDate'] ??
              map['publishDate'] ??
              map['timestamp'] ??
              map['created'] ??
              map['createdAt'] ??
              map['lastModified'],
        );

        items.add(
          _SchoolNotificationItem(
            id: id,
            title: title.isEmpty
                ? AppL10n.of(appLocaleNotifier.value).infoTitle
                : title,
            body: body,
            fullBody: (map['fullBody'] ?? map['content'] ?? '')
                .toString()
                .trim(),
            date: dt,
            author:
                (map['author'] ?? map['createdBy'] ?? map['publisher'] ?? '')
                    .toString()
                    .trim()
                    .isEmpty
                ? null
                : (map['author'] ?? map['createdBy'] ?? map['publisher'])
                      .toString()
                      .trim(),
            url: _pickNotificationUrl(map),
            attachments: parseMessageAttachments(map),
          ),
        );
      }

      items.sort((a, b) => b.sortValue.compareTo(a.sortValue));
      return items;
    }

    return (inbox: toItems(inboxMessages), news: toItems(schoolMessages));
  }

  DateTime? _parseNotificationDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      if (raw > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      }
      if (raw > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
      }
      final s = raw.toString();
      if (s.length == 8) {
        try {
          return DateTime.parse(
            '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}',
          );
        } catch (_) {
          return null;
        }
      }
    }

    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    if (RegExp(r'^\d{8}$').hasMatch(value)) {
      try {
        return DateTime.parse(
          '${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6, 8)}',
        );
      } catch (_) {
        return null;
      }
    }
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  String? _pickNotificationUrl(Map<String, dynamic> map) {
    final candidates = [
      map['url'],
      map['link'],
      map['href'],
      map['targetUrl'],
      map['attachmentUrl'],
    ];
    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.startsWith('http://') || text.startsWith('https://')) {
        return text;
      }
    }
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat(
      'dd.MM.yyyy, HH:mm',
      _icuLocale(appLocaleNotifier.value),
    ).format(date);
  }

  bool _isSafeExternalUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  html_dom.Document _safeInfoDocument(String source) {
    final document = html_parser.parse(source);

    // School notices are remote content. Keep their visual structure but never
    // render executable or embedded browser content inside the app.
    for (final element in document.querySelectorAll(
      'script, style, iframe, object, embed, form, input, button, video, audio, source',
    )) {
      element.remove();
    }

    for (final element in document.querySelectorAll('*')) {
      final attributes = element.attributes.keys.toList(growable: false);
      for (final rawAttribute in attributes) {
        final attribute = rawAttribute.toString();
        if (attribute.toLowerCase().startsWith('on')) {
          element.attributes.remove(attribute);
        }
      }
      for (final attribute in const ['href', 'src']) {
        final value = element.attributes[attribute];
        if (value != null && !_isSafeExternalUrl(value)) {
          element.attributes.remove(attribute);
        }
      }
    }
    return document;
  }

  Future<void> _openInfoUrl(BuildContext context, String? value) async {
    if (!_isSafeExternalUrl(value)) return;
    final ok = await url_launcher.launchUrlString(
      value!,
      mode: url_launcher.LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppL10n.of(appLocaleNotifier.value).settingsGithubOpenFailed,
          ),
        ),
      );
    }
  }

  Widget _buildFormattedInfoBody(BuildContext context, String body) {
    return _InfoHtmlBody(
      document: _safeInfoDocument(body),
      onOpenUrl: (url) => _openInfoUrl(context, url),
    );
  }

  String? _firstNotificationId(List<_SchoolNotificationItem> items) =>
      items.isEmpty ? null : items.first.id;

  _SchoolNotificationItem? _selectedItem(List<_SchoolNotificationItem> items) {
    for (final item in items) {
      if (item.id == _selectedNotificationId) return item;
    }
    return items.isEmpty ? null : items.first;
  }

  Widget _buildTabletNotificationList(
    BuildContext context,
    List<_SchoolNotificationItem> items,
    _SchoolNotificationItem? selected,
  ) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item.id == selected?.id;
        return Material(
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.72)
              : cs.surfaceContainerLow.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _selectedNotificationId = item.id),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    _showInbox
                        ? Icons.mail_outline_rounded
                        : Icons.campaign_rounded,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? cs.onPrimaryContainer
                                : cs.onSurface,
                          ),
                        ),
                        if (item.body.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            _normalizedDetailText(
                              _detailToPlainText(
                                _detailSafeInfoDocument(item.body),
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMessageComposer() async {
    final sent = await Navigator.push<bool>(
      context,
      _buildBouncyRoute(const _MessageComposePage()),
    );
    if (!mounted || sent != true) return;
    setState(() => _showInbox = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppL10n.of(appLocaleNotifier.value).messageSent),
        behavior: SnackBarBehavior.floating,
      ),
    );
    unawaited(_reload());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final activeItems = _showInbox ? _inboxItems : _newsItems;
    final isExpanded = UntisLayout.isExpanded(context);
    final selectedItem = _selectedItem(activeItems);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _mainTabHeaderAppBar(
        context,
        l.infoTitle,
        actions: [
          if (_showInbox)
            IconButton(
              tooltip: l.messageComposeTitle,
              onPressed: _openMessageComposer,
              icon: const Icon(Icons.edit_rounded),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: l.infoReload,
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _AnimatedBackground(child: SizedBox.expand())),
          ExpressiveRefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: UntisLayout.pagePadding(context, bottom: 150),
              children: [
                if (_loading && activeItems.isEmpty) ...[
                  const SizedBox(height: 140),
                  const Center(child: CircularProgressIndicator()),
                ] else ...[
                  _buildInfoSummaryCard(cs, l, activeItems.length),
                  Row(
                    children: [
                      Expanded(
                        child: _infoModeButton(
                          label: l.ui('start'),
                          icon: Icons.campaign_rounded,
                          selected: !_showInbox,
                          onTap: () => setState(() {
                            _showInbox = false;
                            _selectedNotificationId = _firstNotificationId(
                              _newsItems,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _infoModeButton(
                          label: l.ui('notifications'),
                          icon: Icons.mail_outline_rounded,
                          selected: _showInbox,
                          onTap: () => setState(() {
                            _showInbox = true;
                            _selectedNotificationId = _firstNotificationId(
                              _inboxItems,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _glassContainer(
                        context: context,
                        borderRadius: BorderRadius.circular(18),
                        color: cs.errorContainer.withValues(alpha: 0.55),
                        border: Border.all(
                          color: cs.error.withValues(alpha: 0.3),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            _error!,
                            style: GoogleFonts.outfit(
                              color: cs.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (activeItems.isEmpty)
                    _glassContainer(
                      context: context,
                      borderRadius: BorderRadius.circular(24),
                      color: cs.primaryContainer.withValues(alpha: 0.2),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.infoEmpty,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l.infoEmptyHint,
                              style: GoogleFonts.outfit(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (isExpanded)
                    SizedBox(
                      height: (MediaQuery.sizeOf(context).height - 250).clamp(
                        420.0,
                        980.0,
                      ),
                      child: Row(
                        key: const ValueKey('notifications-master-detail'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 360,
                            child: _buildTabletNotificationList(
                              context,
                              activeItems,
                              selectedItem,
                            ),
                          ),
                          VerticalDivider(
                            width: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.45),
                          ),
                          Expanded(
                            child: selectedItem == null
                                ? Center(
                                    child: Text(
                                      l.infoEmpty,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : _SchoolNotificationDetailPage(
                                    item: selectedItem,
                                    isInbox: _showInbox,
                                  ).buildEmbedded(context),
                          ),
                        ],
                      ),
                    )
                  else
                    ...activeItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _glassContainer(
                          context: context,
                          borderRadius: BorderRadius.circular(24),
                          color: cs.surfaceContainerLow.withValues(alpha: 0.62),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.3),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              if (_showInbox) _markMessageOpened(item);
                              Navigator.push(
                                context,
                                _buildBouncyRoute(
                                  _SchoolNotificationDetailPage(
                                    item: item,
                                    isInbox: _showInbox,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _showInbox
                                            ? Icons.mail_outline_rounded
                                            : Icons.campaign_rounded,
                                        size: 18,
                                        color: cs.primary,
                                      ),
                                      if (_showInbox &&
                                          _unreadMessageIds.contains(item.id)) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: cs.tertiary,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: cs.tertiary.withValues(
                                                  alpha: 0.45,
                                                ),
                                                blurRadius: 4,
                                                spreadRadius: 0.5,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: GoogleFonts.outfit(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            height: 1.15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.body.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _buildFormattedInfoBody(context, item.body),
                                  ],
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (item.date != null)
                                        _infoChip(
                                          context,
                                          _formatDate(item.date),
                                          Icons.schedule_rounded,
                                        ),
                                      if ((item.author ?? '').isNotEmpty)
                                        _infoChip(
                                          context,
                                          item.author!,
                                          Icons.person_outline_rounded,
                                        ),
                                    ],
                                  ),
                                  if (item.attachments.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    _infoAttachmentSummary(context, item),
                                  ],
                                  if (item.url != null) ...[
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _openInfoUrl(context, item.url),
                                      icon: const Icon(
                                        Icons.open_in_new_rounded,
                                      ),
                                      label: Text(l.infoOpenLink),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSummaryCard(ColorScheme cs, AppL10n l, int count) {
    final subtitle = _lastUpdated == null
        ? l.infoTitle
        : '${l.infoUpdated}: ${_formatDate(_lastUpdated)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _glassContainer(
        context: context,
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.25),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _showInbox
                      ? Icons.mail_outline_rounded
                      : Icons.campaign_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1 ? '1 ${l.infoTitle}' : '$count ${l.infoTitle}',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoModeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return _glassContainer(
      context: context,
      borderRadius: BorderRadius.circular(14),
      color: selected
          ? cs.primary
          : cs.surfaceContainerHighest.withValues(alpha: 0.4),
      border: Border.all(
        color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    color: selected ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, String text, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return _glassContainer(
      context: context,
      borderRadius: BorderRadius.circular(999),
      color: cs.surfaceContainerHigh.withValues(alpha: 0.55),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoAttachmentSummary(
    BuildContext context,
    _SchoolNotificationItem item,
  ) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final ext = item.uniformAttachmentExtension;
    final label = l.infoAttachmentLabel(item.attachments.length, ext);
    return Row(
      children: [
        Icon(Icons.attach_file_rounded, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Lightweight renderer for the safe subset of HTML returned by Untis.
/// It deliberately keeps layout elements such as headings, lists and tables
/// while avoiding a WebView or an HTML rendering package in the app bundle.
class _InfoHtmlBody extends StatelessWidget {
  const _InfoHtmlBody({required this.document, required this.onOpenUrl});

  final html_dom.Document document;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final nodes = document.body?.nodes ?? const <html_dom.Node>[];
    final blocks = nodes
        .map((node) => _block(context, node))
        .whereType<Widget>()
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  Widget? _block(BuildContext context, html_dom.Node node) {
    if (node is html_dom.Text) {
      final value = _normalizedText(node.data);
      // Whitespace-only nodes (e.g. the "\n\n" the parser keeps between two
      // <p> blocks) must not render as an empty paragraph.
      if (value.trim().isEmpty) return null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _richText(context, [node]),
      );
    }
    if (node is! html_dom.Element) return null;

    switch (node.localName) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
        final size = switch (node.localName) {
          'h1' => 22.0,
          'h2' => 19.0,
          'h3' => 17.0,
          _ => 15.0,
        };
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: _richText(
            context,
            node.nodes,
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w900),
          ),
        );
      case 'ul':
      case 'ol':
        final items = node.children.where((item) => item.localName == 'li');
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in items.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          node.localName == 'ol' ? '${entry.$1 + 1}.' : '•',
                          style: _baseStyle(context),
                        ),
                      ),
                      Expanded(child: _richText(context, entry.$2.nodes)),
                    ],
                  ),
                ),
            ],
          ),
        );
      case 'table':
        return _table(context, node);
      case 'img':
        final source = node.attributes['src'];
        if (source == null || source.isEmpty) return null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              source,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _richText(context, node.nodes),
        );
    }
  }

  Widget _table(BuildContext context, html_dom.Element table) {
    final cs = Theme.of(context).colorScheme;
    final rows = table.querySelectorAll('tr');
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(
            color: cs.outlineVariant.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
          ),
          children: [
            for (final row in rows)
              TableRow(
                children: [
                  for (final cell in row.children.where(
                    (item) => item.localName == 'th' || item.localName == 'td',
                  ))
                    Container(
                      constraints: const BoxConstraints(minWidth: 96),
                      color: cell.localName == 'th'
                          ? cs.primaryContainer
                          : cs.surfaceContainerHigh,
                      padding: const EdgeInsets.all(8),
                      child: _richText(
                        context,
                        cell.nodes,
                        style: cell.localName == 'th'
                            ? TextStyle(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _richText(
    BuildContext context,
    List<html_dom.Node> nodes, {
    TextStyle? style,
  }) {
    return Text.rich(
      TextSpan(
        style: _baseStyle(context).merge(style),
        children: _spans(context, nodes, style),
      ),
    );
  }

  /// Tags that start a new line. When such a tag appears *inside* an inline
  /// context (WebUntis bodies frequently nest <div>/<p> blocks), the spans
  /// must still break the line instead of gluing the paragraphs together.
  static const Set<String> _blockTags = {
    'div', 'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote',
    'section', 'article', 'ul', 'ol', 'table', 'pre',
  };

  List<InlineSpan> _spans(
    BuildContext context,
    List<html_dom.Node> nodes,
    TextStyle? inherited,
  ) {
    final spans = <InlineSpan>[];
    // Whether the last emitted span already ends on a new line, so that a
    // block-level element nested in inline content adds exactly one break.
    var endsWithBreak = false;

    for (final node in nodes) {
      if (node is html_dom.Text) {
        final value = _normalizedText(node.data);
        if (value.isNotEmpty) {
          spans.add(TextSpan(text: value));
          endsWithBreak = value.endsWith('\n');
        }
        continue;
      }
      if (node is! html_dom.Element) continue;
      if (node.localName == 'br') {
        spans.add(const TextSpan(text: '\n'));
        endsWithBreak = true;
        continue;
      }

      final style = switch (node.localName) {
        'strong' || 'b' => const TextStyle(fontWeight: FontWeight.w800),
        'em' || 'i' => const TextStyle(fontStyle: FontStyle.italic),
        'code' => TextStyle(
          fontFamily: 'monospace',
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
        ),
        _ => null,
      };
      if (node.localName == 'a') {
        final href = node.attributes['href'];
        final label = _normalizedText(node.text);
        if (href != null && href.isNotEmpty && label.isNotEmpty) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: InkWell(
                onTap: () => onOpenUrl(href),
                child: Text(
                  label,
                  style: _baseStyle(context).copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          );
        }
        continue;
      }
      if (_blockTags.contains(node.localName)) {
        // Nested block: begin a new line and finish it afterwards so the next
        // sibling starts on its own line.
        if (!endsWithBreak) {
          spans.add(const TextSpan(text: '\n'));
        }
        spans.add(
          TextSpan(
            style: inherited?.merge(style) ?? style,
            children: _spans(context, node.nodes, style),
          ),
        );
        spans.add(const TextSpan(text: '\n'));
        endsWithBreak = true;
        continue;
      }
      spans.add(
        TextSpan(
          style: inherited?.merge(style) ?? style,
          children: _spans(context, node.nodes, style),
        ),
      );
    }
    return spans;
  }

  TextStyle _baseStyle(BuildContext context) => GoogleFonts.outfit(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    fontSize: 14,
    height: 1.4,
  );

  String _normalizedText(String value) {
    var result = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');
    result = result.replaceAll(RegExp(r' *\n *'), '\n');
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return result;
  }
}

// --- EINSTELLUNGEN ---

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _username = '';
  String _apiKeyDisplay = '';
  bool _apiKeySet = false;
  bool _checkingGithubUpdate = false;

  static const Map<String, String> _localeLabels = {
    'de': 'Deutsch',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
  };

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    customBackgroundsNotifier.addListener(_onChanged);
    selectedCustomBackgroundIdNotifier.addListener(_onChanged);
    hiddenSubjectsNotifier.addListener(_onChanged);
    knownSubjectsNotifier.addListener(_onChanged);
    subjectColorsNotifier.addListener(_onChanged);
    appLocaleNotifier.addListener(_onChanged);
    showCancelledNotifier.addListener(_onChanged);
    themeModeNotifier.addListener(_onChanged);
    backgroundAnimationsNotifier.addListener(_onChanged);
    backgroundAnimationStyleNotifier.addListener(_onChanged);
    backgroundGyroscopeNotifier.addListener(_onChanged);
    progressivePushNotifier.addListener(_onChanged);
    dailyBriefingPushNotifier.addListener(_onChanged);
    importantChangesPushNotifier.addListener(_onChanged);
    notifyChangeCancellationsNotifier.addListener(_onChanged);
    notifyChangeRoomNotifier.addListener(_onChanged);
    notifyChangeTeacherNotifier.addListener(_onChanged);
    notifyChangeOtherNotifier.addListener(_onChanged);
    blurEnabledNotifier.addListener(_onChanged);
    demoModeNotifier.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    customBackgroundsNotifier.removeListener(_onChanged);
    selectedCustomBackgroundIdNotifier.removeListener(_onChanged);
    hiddenSubjectsNotifier.removeListener(_onChanged);
    knownSubjectsNotifier.removeListener(_onChanged);
    subjectColorsNotifier.removeListener(_onChanged);
    appLocaleNotifier.removeListener(_onChanged);
    showCancelledNotifier.removeListener(_onChanged);
    themeModeNotifier.removeListener(_onChanged);
    backgroundAnimationsNotifier.removeListener(_onChanged);
    backgroundAnimationStyleNotifier.removeListener(_onChanged);
    backgroundGyroscopeNotifier.removeListener(_onChanged);
    progressivePushNotifier.removeListener(_onChanged);
    dailyBriefingPushNotifier.removeListener(_onChanged);
    importantChangesPushNotifier.removeListener(_onChanged);
    notifyChangeCancellationsNotifier.removeListener(_onChanged);
    notifyChangeRoomNotifier.removeListener(_onChanged);
    notifyChangeTeacherNotifier.removeListener(_onChanged);
    notifyChangeOtherNotifier.removeListener(_onChanged);
    blurEnabledNotifier.removeListener(_onChanged);
    demoModeNotifier.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
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
    await loadSecureAiApiKeys(prefs);

    final validModels = _modelsForProvider(
      aiProvider,
      customCompatibility: aiCustomCompatibility,
    );
    if (!validModels.contains(aiModel)) {
      aiModel = _defaultModelForProvider(
        aiProvider,
        customCompatibility: aiCustomCompatibility,
      );
      await prefs.setString('aiModel', aiModel);
    }

    final key = _activeProviderApiKey();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? '';
        _apiKeySet = key.isNotEmpty;
        _apiKeyDisplay = _maskKey(key);
      });
    }
  }

  String _maskKey(String key) {
    if (key.isEmpty) return '';
    return key.length > 8
        ? '${key.substring(0, 7)}••••${key.substring(key.length - 4)}'
        : '••••••••';
  }

  String _activeProviderApiKey() {
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

  Future<void> _setProviderApiKey(String key) async {
    await setSecureAiApiKey(aiProvider, key);
  }

  String _providerLabel(AppL10n l, String provider) {
    switch (_normalizeAiProvider(provider)) {
      case 'openai':
        return l.settingsAiProviderOpenAi;
      case 'mistral':
        return l.settingsAiProviderMistral;
      case 'custom':
        return l.settingsAiProviderCustom;
      case 'gemini':
      default:
        return l.settingsAiProviderGemini;
    }
  }

  String _compatibilityLabel(AppL10n l, String value) {
    return _normalizeAiCustomCompatibility(value) == 'gemini'
        ? l.settingsAiCompatibilityGemini
        : l.settingsAiCompatibilityOpenAi;
  }

  String _apiKeyHintForProvider(String provider) {
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

  String _apiKeyPortalUrlForProvider(String provider) {
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

  Future<void> _openApiKeyPortal(BuildContext context) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final url = _apiKeyPortalUrlForProvider(aiProvider);
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

  Future<void> _setAiProvider(String provider) async {
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
    await _loadPrefs();
  }

  Future<void> _setAiModel(String model) async {
    aiModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiModel', aiModel);
    await _loadPrefs();
  }

  Future<void> _setAiCustomCompatibility(String compatibility) async {
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
    await _loadPrefs();
  }

  Future<void> _setAiCustomBaseUrl(String value) async {
    aiCustomBaseUrl = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiCustomBaseUrl', value);
    await _loadPrefs();
  }

  Future<void> _setAiSystemPromptTemplate(String value) async {
    aiSystemPromptTemplate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiSystemPromptTemplate', value);
    await _loadPrefs();
  }

  void _showAiProviderDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsAiProvider,
      fitContentHeight: true,
      bottomMargin: 0,
      options: kSupportedAiProviders
          .map(
            (provider) => _SheetOption(
              value: provider,
              title: _providerLabel(l, provider),
              icon: provider == 'gemini'
                  ? Icons.auto_awesome_rounded
                  : provider == 'openai'
                  ? Icons.chat_bubble_outline_rounded
                  : provider == 'mistral'
                  ? Icons.cloud_rounded
                  : Icons.settings_ethernet_rounded,
              selected: aiProvider == provider,
            ),
          )
          .toList(),
    ).then((value) {
      if (value != null) _setAiProvider(value);
    });
  }

  void _showAiModelDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final models = _modelsForProvider(
      aiProvider,
      customCompatibility: aiCustomCompatibility,
    );
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsAiModel,
      fitContentHeight: true,
      bottomMargin: 0,
      options: models
          .map(
            (model) => _SheetOption(
              value: model,
              title: model,
              icon: Icons.memory_rounded,
              selected: aiModel == model,
            ),
          )
          .toList(),
    ).then((value) {
      if (value != null) _setAiModel(value);
    });
  }

  void _showAiCompatibilityDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsAiCompatibility,
      options: kSupportedAiCustomCompatibilities
          .map(
            (compat) => _SheetOption(
              value: compat,
              title: _compatibilityLabel(l, compat),
              icon: compat == 'gemini'
                  ? Icons.auto_awesome_rounded
                  : Icons.chat_rounded,
              selected: aiCustomCompatibility == compat,
            ),
          )
          .toList(),
    ).then((value) {
      if (value != null) _setAiCustomCompatibility(value);
    });
  }

  void _showAiCustomBaseUrlDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final ctrl = TextEditingController(text: aiCustomBaseUrl);
    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.settingsAiCustomBaseUrl,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsAiCustomBaseUrlDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l.settingsAiCustomBaseUrlHint,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        l.settingsApiKeyCancel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await _setAiCustomBaseUrl(ctrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(
                        l.settingsApiKeySave,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAiPromptDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final defaultTemplate = _buildDefaultAiPromptTemplate(l);
    final ctrl = TextEditingController(
      text: aiSystemPromptTemplate.isEmpty
          ? defaultTemplate
          : aiSystemPromptTemplate,
    );

    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.settingsAiPromptEditTitle,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsAiPromptDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 260,
                  child: TextField(
                    controller: ctrl,
                    minLines: 10,
                    maxLines: 18,
                    style: GoogleFonts.jetBrainsMono(fontSize: 12.5),
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        l.settingsApiKeyCancel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ctrl.text = defaultTemplate;
                      },
                      child: Text(
                        l.settingsAiPromptReset,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await _setAiSystemPromptTemplate(ctrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(
                        l.settingsApiKeySave,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAiVariablesDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedSheet<void>(
      context: context,
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.settingsAiPromptVariables,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.settingsAiPromptVariablesDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 380),
                  child: ListView(
                    shrinkWrap: true,
                    children: l.aiPromptVariableDescriptions.entries
                        .map(
                          (entry) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.label_important_outline),
                            title: Text(
                              entry.key,
                              style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(
                              entry.value,
                              style: GoogleFonts.outfit(fontSize: 12.5),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      l.settingsApiKeyCancel,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _pickGithubReleaseAssetUrl(List<dynamic> assets) {
    String? fallback;
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = (asset['name'] ?? '').toString().toLowerCase();
      final url = (asset['browser_download_url'] ?? '').toString();
      if (url.isEmpty) continue;
      fallback ??= url;
      if (name.endsWith('.apk')) return url;
    }
    return fallback;
  }

  List<int> _extractVersionParts(String input) {
    final cleaned = input.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final matches = RegExp(r'\d+').allMatches(cleaned);
    if (matches.isEmpty) return const [0];
    return matches
        .map((m) => int.tryParse(m.group(0) ?? '0') ?? 0)
        .toList(growable: false);
  }

  int _compareVersionStrings(String current, String latest) {
    final currentParts = _extractVersionParts(current);
    final latestParts = _extractVersionParts(latest);
    final maxLen = math.max(currentParts.length, latestParts.length);
    for (var i = 0; i < maxLen; i++) {
      final a = i < currentParts.length ? currentParts[i] : 0;
      final b = i < latestParts.length ? latestParts[i] : 0;
      if (a == b) continue;
      return a.compareTo(b);
    }
    return 0;
  }

  Future<bool> _confirmGithubInstall({
    required AppL10n l,
    required String current,
    required String latest,
  }) async {
    final result = await showUntisDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(
            l.settingsGithubUpdateFound(latest),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l.settingsGithubCurrentVersion}: $current',
                style: GoogleFonts.outfit(),
              ),
              const SizedBox(height: 4),
              Text(
                '${l.settingsGithubLatestVersion}: $latest',
                style: GoogleFonts.outfit(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.settingsGithubInstallQuestion,
                style: GoogleFonts.outfit(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.settingsGithubInstallLater),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.settingsGithubInstallNow),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _checkGithubUpdate() async {
    if (_checkingGithubUpdate) return;
    final l = AppL10n.of(appLocaleNotifier.value);
    setState(() => _checkingGithubUpdate = true);

    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(l.settingsGithubChecking),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final resp = await http.get(
        Uri.parse(
          'https://api.github.com/repos/ninocss/UntisPlus/releases/latest',
        ),
        headers: const {'Accept': 'application/vnd.github+json'},
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('GitHub API error ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body);
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid GitHub response');
      }

      final tag = (data['tag_name'] ?? '').toString().trim();
      final htmlUrl =
          (data['html_url'] ?? 'https://github.com/ninocss/UntisPlus/releases')
              .toString();
      final assets = (data['assets'] is List)
          ? data['assets'] as List<dynamic>
          : const <dynamic>[];
      final assetUrl = _pickGithubReleaseAssetUrl(assets);
      final targetUrl = assetUrl ?? htmlUrl;
      final latestVersionRaw = tag.isEmpty
          ? (data['name'] ?? '').toString()
          : tag;
      final hasComparableVersion = RegExp(r'\d').hasMatch(latestVersionRaw);
      final hasUpdate = hasComparableVersion
          ? _compareVersionStrings(appVersion, latestVersionRaw) < 0
          : true;

      if (!hasUpdate) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.settingsGithubNoUpdate),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      final confirm = await _confirmGithubInstall(
        l: l,
        current: appVersion,
        latest: latestVersionRaw,
      );
      if (!confirm) return;

      if (assetUrl == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.settingsGithubNoDownloadAsset),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      final launched = await url_launcher.launchUrlString(
        targetUrl,
        mode: url_launcher.LaunchMode.externalApplication,
      );

      if (launched) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.settingsGithubInstallPrompted),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.settingsGithubOpenFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.settingsGithubCheckFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingGithubUpdate = false);
      }
    }
  }

  Future<void> _setLocale(String code) async {
    await ensureDateFormattingForLocale(code);
    appLocaleNotifier.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLocale', code);
    unawaited(WidgetService.publishNativeCopy(code));
    unawaited(AlarmService.instance.refreshNativeCopy());
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', ThemeMode.values.indexOf(mode));
  }

  Future<void> _setShowCancelled(bool v) async {
    showCancelledNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showCancelled', v);
  }

  Future<void> _setBackgroundAnimations(bool v) async {
    backgroundAnimationsNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backgroundAnimations', v);
  }

  Future<void> _setBackgroundAnimationStyle(int style) async {
    final normalized = style.clamp(0, 10);
    backgroundAnimationStyleNotifier.value = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('backgroundAnimationStyle', normalized);
  }

  Future<void> _setBackgroundGyroscope(bool v) async {
    backgroundGyroscopeNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backgroundGyroscope', v);
  }

  Future<void> _setBlurEnabled(bool v) async {
    blurEnabledNotifier.value = v;
    unawaited(nativeUiGateway.setWindowBlur(v));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('blurEnabled', v);
  }

  Future<void> _setProgressivePush(bool v) async {
    progressivePushNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('progressivePush', v);
    if (!v) {
      await NotificationService().cancelNotification(
        NotificationIds.currentLesson,
      );
    } else {
      updateUntisData().catchError((_) => false);
    }
  }

  Future<void> _setDailyBriefingPush(bool v) async {
    dailyBriefingPushNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailyBriefingPush', v);
    if (!v) {
      await NotificationService().cancelNotification(
        NotificationIds.dailyBriefing,
      );
    } else {
      updateUntisData().catchError((_) => false);
    }
  }

  Future<void> _setImportantChangesPush(bool v) async {
    importantChangesPushNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('importantChangesPush', v);
  }

  Future<void> _setDemoMode(bool enabled) async {
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

    if (sessionID.isEmpty && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        _buildBouncyRoute(const OnboardingFlow()),
        (route) => false,
      );
    }
  }

  void _showLanguageDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsLanguage,
      fitContentHeight: true,
      bottomMargin: 0,
      options: _localeLabels.entries
          .map(
            (e) => _SheetOption(
              value: e.key,
              title: e.value,
              icon: Icons.language_rounded,
              selected: appLocaleNotifier.value == e.key,
            ),
          )
          .toList(),
    ).then((val) {
      if (val != null) {
        _setLocale(val);
      }
    });
  }

  String _backgroundStyleLabel(AppL10n l, int style) {
    switch (style) {
      case 1:
        return l.settingsBackgroundStyleSpace;
      case 2:
        return l.settingsBackgroundStyleBubbles;
      case 3:
        return l.settingsBackgroundStyleLines;
      case 4:
        return l.settingsBackgroundStyleThreeD;
      case 5:
        return l.settingsBackgroundStyleNebula;
      case 6:
        return l.settingsBackgroundStylePrism;
      case 7:
        return l.settingsBackgroundStyleWaves;
      case 8:
        return l.settingsBackgroundStyleGrid;
      case 9:
        return l.settingsBackgroundStyleRings;
      case 10:
        return l.settingsBackgroundStyleCustom;
      default:
        return l.settingsBackgroundStyleOrbs;
    }
  }

  IconData _backgroundStyleIcon(int style) {
    switch (style) {
      case 1:
        return Icons.nightlight_round;
      case 2:
        return Icons.bubble_chart_rounded;
      case 3:
        return Icons.show_chart_rounded;
      case 4:
        return Icons.view_in_ar_rounded;
      case 5:
        return Icons.cloud_rounded;
      case 6:
        return Icons.change_history_rounded;
      case 7:
        return Icons.waves_rounded;
      case 8:
        return Icons.grid_on_rounded;
      case 9:
        return Icons.radio_button_checked_rounded;
      case 10:
        return Icons.wallpaper_rounded;
      default:
        return Icons.blur_circular_rounded;
    }
  }

  void _showBackgroundStyleDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final styleOptions = List<int>.generate(11, (index) => index);

    _showUnifiedOptionSheet<int>(
      context: context,
      title: l.settingsBackgroundStyle,
      options: styleOptions
          .map(
            (style) => _SheetOption(
              value: style,
              title: _backgroundStyleLabel(l, style),
              icon: _backgroundStyleIcon(style),
              selected: backgroundAnimationStyleNotifier.value == style,
            ),
          )
          .toList(),
    ).then((style) {
      if (style != null) {
        _setBackgroundAnimationStyle(style);
      }
    });
  }

  void _showApiKeyDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final providerLabel = _providerLabel(l, aiProvider);
    final providerPortalUrl = _apiKeyPortalUrlForProvider(aiProvider);
    final ctrl = TextEditingController(text: _activeProviderApiKey());
    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${l.settingsAiApiKey} ($providerLabel)',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsAiApiKeyDialogDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (providerPortalUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _openApiKeyPortal(ctx),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(
                        l.settingsAiApiKeyGet,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 54),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  obscureText: true,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _apiKeyHintForProvider(aiProvider),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                        ),
                        child: Text(
                          l.settingsApiKeyCancel,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.08,
                          ),
                        ),
                      ),
                    ),
                    if (_apiKeySet) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final navigator = Navigator.of(ctx);
                            await _setProviderApiKey('');
                            navigator.pop();
                            _loadPrefs();
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            side: BorderSide(color: cs.error),
                          ),
                          child: Text(
                            l.settingsApiKeyRemove,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.08,
                              color: cs.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final val = ctrl.text.trim();
                          final navigator = Navigator.of(ctx);
                          await _setProviderApiKey(val);
                          navigator.pop();
                          _loadPrefs();
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 50),
                        ),
                        label: Text(
                          l.settingsApiKeySave,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final navigator = Navigator.of(context);
    defaultClassId = null;
    defaultClassName = null;
    favoriteClassIds = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      _buildBouncyRoute(const OnboardingFlow()),
      (route) => false,
    );
  }

  // ── Section card builder ───
  Widget _section(
    String title,
    IconData icon,
    List<Widget> tiles,
    ColorScheme cs, {
    required Color accent,
    bool isAbout = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.34),
                      accent.withValues(alpha: 0.14),
                    ],
                  ),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.8,
                  color: accent,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            if (isAbout)
              Positioned.fill(
                left: -20,
                right: -20,
                top: -20,
                bottom: -20,
                child: Opacity(
                  opacity: 0.25,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE40303),
                            Color(0xFFFF8C00),
                            Color(0xFFFFED00),
                            Color(0xFF008026),
                            Color(0xFF24408E),
                            Color(0xFF732982),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            _glassContainer(
              context: context,
              borderRadius: BorderRadius.circular(24),
              sigma: 18,
              color: cs.surface.withValues(alpha: 0.52),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.08),
                  cs.surfaceContainerHighest.withValues(alpha: 0.46),
                ],
              ),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.15),
                width: 1,
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    for (int i = 0; i < tiles.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            indent: 74,
                            endIndent: 16,
                            color: cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                      tiles[i],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  // ── Row tile inside a section card ────
  Widget _tile({
    Widget? leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? subtitleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color:
                              subtitleColor ??
                              Theme.of(context).colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }

  // ── Rounded icon box for tile leading ─────
  Widget _tileIcon(IconData icon, Color color) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0.12)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      boxShadow: _glowShadows(context, [
        BoxShadow(
          color: color.withValues(alpha: 0.16),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ]),
    ),
    child: Icon(icon, color: color, size: 22),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final hidden = hiddenSubjectsNotifier.value.toList()..sort();
    final activeCustomBackground = _activeCustomBackgroundOrNull();

    return Scaffold(
      body: _AnimatedBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 96,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              flexibleSpace: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    _withOptionalBackdropBlur(
                      sigma: 24,
                      child: const SizedBox.shrink(),
                      childBuilder: (enabled) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        return Stack(
                          fit: StackFit.passthrough,
                          children: [
                            Container(
                              color: enabled
                                  ? (isDark
                                        ? Color.alphaBlend(
                                            cs.primary.withValues(alpha: 0.08),
                                            cs.surface.withValues(alpha: 0.65),
                                          )
                                        : cs.surface.withValues(alpha: 0.82))
                                  : cs.surface,
                            ),
                            if (enabled)
                              Positioned.fill(
                                child: Container(
                                  color: cs.primary.withValues(alpha: 0.06),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 14),
                      title: Text(
                        l.settingsTitle,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 23,
                          color: cs.onSurface,
                        ),
                      ),
                      collapseMode: CollapseMode.pin,
                      background: ValueListenableBuilder<bool>(
                        valueListenable: backgroundAnimationsNotifier,
                        builder: (context, enabled, _) {
                          if (!enabled) return const SizedBox.shrink();
                          return ValueListenableBuilder<int>(
                            valueListenable: backgroundAnimationStyleNotifier,
                            builder: (context, style, _) =>
                                _AnimatedBackgroundScene(style: style),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 44),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  _springEntry(
                    duration: const Duration(milliseconds: 380),
                    offsetY: 18,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionQuick,
                      Icons.bolt_rounded,
                      [
                        _tile(
                          leading: _tileIcon(
                            Icons.event_busy_rounded,
                            showCancelledNotifier.value ? cs.outline : cs.error,
                          ),
                          title: l.settingsShowCancelled,
                          subtitle: l.settingsShowCancelledDesc,
                          trailing: Switch(
                            value: showCancelledNotifier.value,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              _setShowCancelled(v);
                            },
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _setShowCancelled(!showCancelledNotifier.value);
                          },
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.science_rounded,
                            demoModeNotifier.value ? cs.tertiary : cs.outline,
                          ),
                          title: l.settingsDemoMode,
                          subtitle: l.settingsDemoModeDesc,
                          trailing: Switch(
                            value: demoModeNotifier.value,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              _setDemoMode(v);
                            },
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _setDemoMode(!demoModeNotifier.value);
                          },
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.notifications_active_rounded,
                            progressivePushNotifier.value
                                ? cs.primary
                                : cs.outline,
                          ),
                          title: l.settingsProgressivePush,
                          subtitle: l.settingsProgressivePushDesc,
                          trailing: Switch(
                            value: progressivePushNotifier.value,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              _setProgressivePush(v);
                            },
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _setProgressivePush(!progressivePushNotifier.value);
                          },
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.wb_sunny_rounded,
                            dailyBriefingPushNotifier.value
                                ? cs.tertiary
                                : cs.outline,
                          ),
                          title: l.settingsDailyBriefingPush,
                          subtitle: l.settingsDailyBriefingPushDesc,
                          trailing: Switch(
                            value: dailyBriefingPushNotifier.value,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              _setDailyBriefingPush(v);
                            },
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _setDailyBriefingPush(
                              !dailyBriefingPushNotifier.value,
                            );
                          },
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.warning_amber_rounded,
                            importantChangesPushNotifier.value
                                ? cs.error
                                : cs.outline,
                          ),
                          title: l.settingsImportantChangesPush,
                          subtitle: l.settingsImportantChangesPushDesc,
                          trailing: Switch(
                            value: importantChangesPushNotifier.value,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              _setImportantChangesPush(v);
                            },
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _setImportantChangesPush(
                              !importantChangesPushNotifier.value,
                            );
                          },
                        ),
                      ],
                      cs,
                      accent: cs.tertiary,
                    ),
                  ),

                  _springEntry(
                    duration: const Duration(milliseconds: 430),
                    offsetY: 20,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionGeneral,
                      Icons.tune_rounded,
                      [
                        _tile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                _username.isNotEmpty
                                    ? _username[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          title: l.settingsLoggedInAs,
                          subtitle: _username.isNotEmpty ? _username : '…',
                          trailing: IconButton(
                            tooltip: l.settingsLogout,
                            icon: Icon(Icons.logout_rounded, color: cs.error),
                            onPressed: () => _logout(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _tileIcon(Icons.contrast_rounded, cs.primary),
                                  const SizedBox(width: 14),
                                  Text(
                                    l.settingsThemeMode,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15.5,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SegmentedButton<ThemeMode>(
                                style: SegmentedButton.styleFrom(
                                  textStyle: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  minimumSize: const Size(0, 40),
                                ),
                                segments: [
                                  ButtonSegment(
                                    value: ThemeMode.light,
                                    label: Text(l.settingsThemeLight),
                                    icon: const Icon(
                                      Icons.light_mode_rounded,
                                      size: 17,
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.system,
                                    label: Text(l.settingsThemeSystem),
                                    icon: const Icon(
                                      Icons.brightness_auto_rounded,
                                      size: 17,
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.dark,
                                    label: Text(l.settingsThemeDark),
                                    icon: const Icon(
                                      Icons.dark_mode_rounded,
                                      size: 17,
                                    ),
                                  ),
                                ],
                                selected: {themeModeNotifier.value},
                                onSelectionChanged: (v) {
                                  HapticFeedback.selectionClick();
                                  _setThemeMode(v.first);
                                },
                              ),
                            ],
                          ),
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.auto_awesome_motion_outlined,
                            backgroundAnimationsNotifier.value
                                ? cs.tertiary
                                : cs.outline,
                          ),
                          title: l.settingsBackgroundAnimations,
                          subtitle: l.settingsBackgroundAnimationsDesc,
                          trailing: Switch(
                            value: backgroundAnimationsNotifier.value,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              _setBackgroundAnimations(v);
                            },
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _setBackgroundAnimations(
                              !backgroundAnimationsNotifier.value,
                            );
                          },
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.screen_rotation_alt_rounded,
                            backgroundGyroscopeNotifier.value
                                ? cs.secondary
                                : cs.outline,
                          ),
                          title: l.settingsBackgroundGyroscope,
                          subtitle: l.settingsBackgroundGyroscopeDesc,
                          trailing: Switch(
                            value: backgroundGyroscopeNotifier.value,
                            onChanged: backgroundAnimationsNotifier.value
                                ? (v) {
                                    HapticFeedback.selectionClick();
                                    _setBackgroundGyroscope(v);
                                  }
                                : null,
                          ),
                          onTap: backgroundAnimationsNotifier.value
                              ? () {
                                  HapticFeedback.selectionClick();
                                  _setBackgroundGyroscope(
                                    !backgroundGyroscopeNotifier.value,
                                  );
                                }
                              : null,
                        ),
                        _tile(
                          leading: _tileIcon(
                            _backgroundStyleIcon(
                              backgroundAnimationStyleNotifier.value,
                            ),
                            cs.secondary,
                          ),
                          title: l.settingsBackgroundStyle,
                          subtitle: _backgroundStyleLabel(
                            l,
                            backgroundAnimationStyleNotifier.value,
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showBackgroundStyleDialog,
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.wallpaper_rounded,
                            cs.tertiary,
                          ),
                          title: l.settingsCustomBackgrounds,
                          subtitle: activeCustomBackground == null
                              ? l.settingsCustomBackgroundsDesc
                              : l.settingsCustomBackgroundsSelected(
                                  activeCustomBackground.name,
                                ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              _buildBouncyRoute(
                                const CustomBackgroundEditorScreen(),
                              ),
                            );
                          },
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.blur_on_rounded,
                            blurEnabledNotifier.value ? cs.primary : cs.outline,
                          ),
                          title: l.settingsGlassEffect,
                          subtitle: l.settingsGlassEffectDesc,
                          trailing: Switch(
                            value: blurEnabledNotifier.value,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              _setBlurEnabled(v);
                            },
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _setBlurEnabled(!blurEnabledNotifier.value);
                          },
                        ),
                        // Language tile
                        _tile(
                          leading: _tileIcon(
                            Icons.language_rounded,
                            cs.primary,
                          ),
                          title: l.settingsLanguage,
                          subtitle: _localeLabels[appLocaleNotifier.value],
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showLanguageDialog,
                        ),
                      ],
                      cs,
                      accent: cs.primary,
                    ),
                  ),

                  _springEntry(
                    duration: const Duration(milliseconds: 480),
                    offsetY: 22,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionTimetable,
                      Icons.schedule_rounded,
                      [
                        _tile(
                          leading: _tileIcon(
                            Icons.system_update_alt_rounded,
                            cs.primary,
                          ),
                          title: l.settingsRefreshPushWidgetNow,
                          subtitle: l.settingsRefreshPushWidgetNowDesc,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: () async {
                            HapticFeedback.heavyImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l.settingsBackgroundLoading),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    _expressiveRadius(
                                      context,
                                      10,
                                      expressiveRadius: 24,
                                    ),
                                  ),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            await updateUntisData();
                          },
                        ),
                      ],
                      cs,
                      accent: cs.secondary,
                    ),
                  ),

                  _springEntry(
                    duration: const Duration(milliseconds: 530),
                    offsetY: 24,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionAI,
                      Icons.smart_toy_rounded,
                      [
                        _tile(
                          leading: _tileIcon(Icons.hub_rounded, cs.tertiary),
                          title: l.settingsAiProvider,
                          subtitle: _providerLabel(l, aiProvider),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showAiProviderDialog,
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.memory_rounded,
                            cs.secondary,
                          ),
                          title: l.settingsAiModel,
                          subtitle: aiModel,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showAiModelDialog,
                        ),
                        if (aiProvider == 'custom')
                          _tile(
                            leading: _tileIcon(
                              Icons.compare_arrows_rounded,
                              cs.primary,
                            ),
                            title: l.settingsAiCompatibility,
                            subtitle: _compatibilityLabel(
                              l,
                              aiCustomCompatibility,
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                            onTap: _showAiCompatibilityDialog,
                          ),
                        if (aiProvider == 'custom')
                          _tile(
                            leading: _tileIcon(Icons.link_rounded, cs.primary),
                            title: l.settingsAiCustomBaseUrl,
                            subtitle: aiCustomBaseUrl.isEmpty
                                ? l.settingsAiCustomBaseUrlHint
                                : aiCustomBaseUrl,
                            subtitleColor: aiCustomBaseUrl.isEmpty
                                ? cs.error
                                : null,
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                            onTap: _showAiCustomBaseUrlDialog,
                          ),
                        _tile(
                          leading: _apiKeySet
                              ? _tileIcon(
                                  Icons.auto_awesome_rounded,
                                  cs.tertiary,
                                )
                              : _tileIcon(Icons.key_off_rounded, cs.error),
                          title: l.settingsAiApiKey,
                          subtitle: _apiKeySet
                              ? _apiKeyDisplay
                              : l.settingsAiApiKeyNotSet,
                          subtitleColor: _apiKeySet ? null : cs.error,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showApiKeyDialog,
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.edit_note_rounded,
                            cs.tertiary,
                          ),
                          title: l.settingsAiPrompt,
                          subtitle: aiSystemPromptTemplate.trim().isEmpty
                              ? l.settingsAiPromptDesc
                              : aiSystemPromptTemplate.trim().split('\n').first,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showAiPromptDialog,
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.data_object_rounded,
                            cs.secondary,
                          ),
                          title: l.settingsAiPromptVariables,
                          subtitle: l.settingsAiPromptVariablesDesc,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: _showAiVariablesDialog,
                        ),
                      ],
                      cs,
                      accent: cs.tertiary,
                    ),
                  ),

                  // ── Subjects & Colors (merged) ───────────────────────────
                  _springEntry(
                    duration: const Duration(milliseconds: 580),
                    offsetY: 26,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionSubjects,
                      Icons.palette_rounded,
                      [
                        _tile(
                          leading: _tileIcon(
                            Icons.palette_outlined,
                            cs.primary,
                          ),
                          title: l.settingsSectionColors,
                          subtitle: l
                              .settingsColorsDesc, // "Customize the colors for your subjects"
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              _buildBouncyRoute(const SubjectColorsPage()),
                            );
                          },
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.visibility_off_outlined,
                            cs.secondary,
                          ),
                          title: l.settingsSectionHidden,
                          subtitle: hidden.isEmpty
                              ? l.settingsNoHidden
                              : l.settingsHiddenCount(hidden.length),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              _buildBouncyRoute(const HiddenSubjectsPage()),
                            );
                          },
                        ),
                      ],
                      cs,
                      accent: cs.primary,
                    ),
                  ),

                  _springEntry(
                    duration: const Duration(milliseconds: 630),
                    offsetY: 28,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionUpdates,
                      Icons.system_update_alt_rounded,
                      [
                        _tile(
                          leading: _tileIcon(
                            Icons.system_update_alt_rounded,
                            cs.primary,
                          ),
                          title: l.settingsGithubUpdateCheck,
                          subtitle: l.settingsGithubUpdateCheckDesc,
                          trailing: _checkingGithubUpdate
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      cs.primary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                ),
                          onTap: _checkingGithubUpdate
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  _checkGithubUpdate();
                                },
                        ),
                        _tile(
                          leading: _tileIcon(
                            Icons.open_in_new_rounded,
                            cs.secondary,
                          ),
                          title: l.settingsGithubOpenReleasePage,
                          subtitle: l.settingsGithubRepoLabel,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: () {
                            url_launcher.launchUrlString(
                              'https://github.com/ninocss/UntisPlus/releases',
                              mode: url_launcher.LaunchMode.externalApplication,
                            );
                          },
                        ),
                      ],
                      cs,
                      accent: cs.secondary,
                    ),
                  ),

                  // ── About ────────────────────────────────────────────────
                  _springEntry(
                    duration: const Duration(milliseconds: 680),
                    offsetY: 30,
                    startScale: 0.97,
                    child: _section(
                      l.settingsSectionAbout,
                      Icons.info_rounded,
                      [
                        _tile(
                          leading: _tileIcon(
                            Icons.rocket_launch_outlined,
                            cs.primary,
                          ),
                          title: l.appName,
                          subtitle:
                              '${l.settingsAppVersion} $appVersion (${l.settingsBuild} ${appBuildNumber.isEmpty ? '-' : appBuildNumber})',
                          trailing: Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: cs.tertiary,
                          ),
                        ),
                      ],
                      cs,
                      accent: cs.tertiary,
                      isAbout: true,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Standalone account card for settings ─────────────────────────────────────
// ignore: unused_element
class _SettingsAccountCard extends StatelessWidget {
  final String username;
  final String serverUrl;
  final AppL10n l;
  final ColorScheme cs;
  final VoidCallback onLogout;

  const _SettingsAccountCard({
    required this.username,
    required this.serverUrl,
    required this.l,
    required this.cs,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primaryContainer, cs.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  boxShadow: _glowShadows(context, [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]),
                ),
                child: Center(
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.settingsLoggedInAs,
                      style: GoogleFonts.outfit(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      username.isNotEmpty ? username : '…',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    if (serverUrl.isNotEmpty)
                      Text(
                        serverUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: cs.onPrimaryContainer.withValues(alpha: 0.45),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              l.settingsLogout,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error.withValues(alpha: 0.1),
              foregroundColor: cs.error,
              minimumSize: const Size(double.infinity, 46),
              elevation: 0,
              shape: _legacyButtonShape(context, 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subject Colors Page ──────────────────────────────────────────────────────
class SubjectColorsPage extends StatelessWidget {
  const SubjectColorsPage({super.key});

  void _showCustomColorPicker(
    BuildContext context,
    String subject,
    Color? current,
  ) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallback = _autoLessonColor(subject, isDark);

    double red = ((current ?? fallback).r * 255.0);
    double green = ((current ?? fallback).g * 255.0);
    double blue = ((current ?? fallback).b * 255.0);

    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final preview = Color.fromARGB(
            255,
            red.round(),
            green.round(),
            blue.round(),
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  l.settingsColorFor(subject),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 66,
                  decoration: BoxDecoration(
                    color: preview,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${l.settingsColorRed}: ${red.round()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: red,
                  min: 0,
                  max: 255,
                  activeColor: Colors.red,
                  onChanged: (v) => setStateDialog(() => red = v),
                ),
                Text(
                  '${l.settingsColorGreen}: ${green.round()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: green,
                  min: 0,
                  max: 255,
                  activeColor: Colors.green,
                  onChanged: (v) => setStateDialog(() => green = v),
                ),
                Text(
                  '${l.settingsColorBlue}: ${blue.round()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: blue,
                  min: 0,
                  max: 255,
                  activeColor: Colors.blue,
                  onChanged: (v) => setStateDialog(() => blue = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        l.settingsApiKeyCancel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        _setSubjectColor(subject, preview.toARGB32());
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        l.settingsColorApply,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showColorPicker(BuildContext context, String subject, Color? current) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final palette = _subjectColorPalette(cs);
    _showUnifiedSheet<void>(
      context: context,
      child: Builder(
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Text(
                l.settingsColorFor(subject),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: palette.map((c) {
                  final isSelected =
                      current != null && current.toARGB32() == c.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _setSubjectColor(subject, c.toARGB32());
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: cs.onSurface.withValues(alpha: 0.65),
                                width: 3,
                              )
                            : Border.all(color: Colors.transparent),
                        boxShadow:
                            isSelected &&
                                untisThemeTokensOf(context).glowEffectsEnabled
                            ? [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color:
                                  ThemeData.estimateBrightnessForColor(c) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              size: 22,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showCustomColorPicker(context, subject, current);
                },
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  l.settingsColorCustomPicker,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: _legacyButtonShape(context, 14),
                ),
              ),
              if (current != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _clearSubjectColor(subject);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    l.settingsColorReset,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: _legacyButtonShape(context, 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsSectionColors,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ValueListenableBuilder(
          valueListenable: knownSubjectsNotifier,
          builder: (context, subjectsSet, _) {
            final subjects = subjectsSet.toList()..sort();
            if (subjects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 56,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.settingsNoSubjectsLoaded,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.settingsNoSubjectsLoadedDesc,
                      style: GoogleFonts.outfit(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ValueListenableBuilder(
              valueListenable: subjectColorsNotifier,
              builder: (context, colors, _) {
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    mq.padding.bottom + 120,
                  ),
                  children: [
                    SettingsGroup(
                      children: subjects.map((subj) {
                        final colorVal = colors[subj];
                        final subjectColor = colorVal != null
                            ? Color(colorVal)
                            : null;
                        return SettingsTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: subjectColor ?? cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: subjectColor != null
                                  ? Border.all(
                                      color: subjectColor.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: subjectColor == null
                                ? Icon(
                                    Icons.palette_outlined,
                                    color: cs.primary,
                                    size: 20,
                                  )
                                : null,
                          ),
                          title: subj,
                          subtitle: subjectColor != null
                              ? l.settingsCustomColor
                              : l.settingsDefaultColor,
                          onTap: () =>
                              _showColorPicker(context, subj, subjectColor),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Hidden Subjects Page ─────────────────────────────────────────────────────
class HiddenSubjectsPage extends StatelessWidget {
  const HiddenSubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsSectionHidden,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ValueListenableBuilder(
          valueListenable: hiddenSubjectsNotifier,
          builder: (context, hiddenSet, _) {
            final hidden = hiddenSet.toList()..sort();
            if (hidden.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_off_outlined,
                      size: 56,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.settingsNoHidden,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.settingsNoHiddenDesc,
                      style: GoogleFonts.outfit(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
              children: [
                SettingsGroup(
                  children: hidden.map((subject) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                subject.isNotEmpty
                                    ? subject[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: cs.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              subject,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _unhideSubject(subject),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: _legacyButtonShape(context, 10),
                            ),
                            child: Text(
                              l.settingsUnhide,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
>>>>>>> pr-149
