// lib/core/state/app_state.dart
// Centralized app state using Riverpod Notifier pattern

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/webuntis/webuntis_client.dart';
import '../../features/accounts/domain/untis_account.dart';
import '../../core/school_models.dart';
import '../../core/design_tokens.dart';
import '../../features/ai/domain/ai_models.dart';
import '../../features/changes/domain/timetable_change.dart';

part 'app_state.freezed.dart';

// ============================================================================
// App State (Centralized State Container)
// ============================================================================

@freezed
abstract class AppState with _$AppState {
  const factory AppState({
    // App version
    @Default('0.0.0') String appVersion,
    @Default('0') String appBuildNumber,
    @Default(false) bool showChangelogOnStartup,

    // Auth / Account
    @Default('') String sessionID,
    @Default('') String schoolUrl,
    @Default('') String schoolName,
    @Default(0) int personId,
    @Default(0) int personType,
    @Default([]) List<UntisAccount> untisAccounts,
    String? activeUntisAccountId,

    // Demo mode
    @Default(false) bool demoMode,

    // UI Preferences (device-wide)
    @Default('de') String appLocale,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(AppThemeId.defaultTheme) AppThemeId visualTheme,
    @Default({}) Map<String, bool> themeBlurPreferences,
    @Default(true) bool showCancelled,
    @Default(0) int timetableSwitchAnimation,
    @Default(0xFFFF1744) int cancelledLessonColor,
    @Default(false) bool monochromeLessons,
    @Default(0xFF757575) int monochromeLessonColor,
    @Default(true) bool backgroundAnimations,
    @Default(0) int backgroundAnimationStyle,
    @Default(false) bool backgroundGyroscope,
    @Default(true) bool progressivePush,
    @Default(true) bool dailyBriefingPush,
    @Default(true) bool importantChangesPush,
    @Default(true) bool notifyChangeCancellations,
    @Default(true) bool notifyChangeRoom,
    @Default(true) bool notifyChangeTeacher,
    @Default(true) bool notifyChangeOther,
    @Default(true) bool blurEnabled,
    @Default(1.0) double blurStrength,
    @Default(true) bool surfaceBlurEnabled,
    @Default(0) int surfaceCornerMode,
    @Default(24) int surfaceCornerRadius,
    @Default(false) bool appBgBlurEnabled,
    @Default(10.0) double appBgBlurAmount,
    @Default(0) int pageTransition,
    @Default(false) bool mainTabFadeUpEnabled,
    @Default(true) bool useMaterialYou,
    @Default(false) bool isAmoled,
    @Default(0xFF0F766E) int customColorSeed,
    @Default('default') String appIcon,

    // Lesson Design
    @Default(0) int lessonCardStyle,
    @Default(false) bool glowEffectsEnabled,
    @Default(false) bool lessonBlurEnabled,
    @Default(12.0) double lessonBlurAmount,
    @Default(0.9) double lessonCardOpacity,
    @Default(12.0) double lessonBorderRadius,
    @Default(0) int lessonAccentStyle,
    @Default(true) bool lessonShowTeacher,
    @Default(false) bool lessonShowSubjectIcons,
    @Default(true) bool lessonShowRoom,
    @Default(false) bool lessonCompactMode,
    @Default(true) bool lessonDimPast,
    @Default(true) bool lessonCancelledPattern,
    @Default(true) bool showFullTeacherNames,
    @Default(1) int timetableDaySpan,
    @Default(false) bool swipeBackGesture,

    // AI Settings
    @Default('gemini') String aiProvider,
    @Default('gemini-3.6-flash') String aiModel,
    @Default('') String aiSystemPromptTemplate,
    @Default('') String aiCustomBaseUrl,
    @Default('openai') String aiCustomCompatibility,
    @Default('') String aiLocalModelPath,
    @Default(0.2) double aiTemperature,
    @Default(2600) int aiMaxTokens,
    @Default(0.95) double aiTopP,
    @Default('helpful') String aiPersona,
    @Default('') String geminiApiKey,
    @Default('') String openAiApiKey,
    @Default('') String mistralApiKey,
    @Default('') String customAiApiKey,

    // Account-scoped data (updated when account changes)
    @Default({}) Set<String> hiddenSubjects,
    @Default({}) Map<String, int> subjectColors,
    @Default({}) Set<String> knownSubjects,
    @Default([]) List<Map<String, dynamic>> customHomework,
    @Default([]) List<Map<String, dynamic>> customExams,
    @Default([]) List<Map<String, dynamic>> customGrades,
    @Default({}) Map<int, List<dynamic>> currentWeekData,
    @Default([]) List<Map<String, dynamic>> homeworks,
    @Default([]) List<Map<String, dynamic>> lessonNotes,
    @Default([]) List<Map<String, dynamic>> apiExams,
    @Default(0) int unreadTimetableChanges,
    @Default(0) int unreadInboxMessages,

    // Pending actions from notifications
    String? pendingTimetableAction,
    String? pendingTimetableCurrentLesson,
    String? pendingTimetableNextLesson,
    int? pendingChangeHighlightDate,
    int? pendingChangeHighlightStartTime,

    // Native assistant integration
    @Default(false) bool pendingAssistantOpen,
    String? pendingAssistantPrompt,

    // Class favorites
    int? defaultClassId,
    String? defaultClassName,
    @Default({}) Set<int> favoriteClassIds,
  }) = _AppState;
}

// ============================================================================
// Derived State Providers (select for granular rebuilds)
// ============================================================================

// Active account getter
final activeUntisAccountProvider = Provider<UntisAccount?>((ref) {
  final state = ref.watch(appStateNotifierProvider);
  final activeId = state.activeUntisAccountId;
  if (activeId == null) return null;
  for (final account in state.untisAccounts) {
    if (account.id == activeId) return account;
  }
  return null;
});

// Visible subjects (filtered by hidden)
final visibleKnownSubjectsProvider = Provider<List<String>>((ref) {
  final state = ref.watch(appStateNotifierProvider);
  final hidden = state.hiddenSubjects
      .map((s) => s.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toSet();
  return state.knownSubjects
      .where((s) => !hidden.contains(s.trim().toLowerCase()))
      .toList()
        ..sort();
});

// Filtered week data (hiding subjects)
final filteredWeekDataProvider = Provider<Map<int, List<dynamic>>>((ref) {
  final state = ref.watch(appStateNotifierProvider);
  final hidden = state.hiddenSubjects
      .map((s) => s.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toSet();

  if (state.currentWeekData.isEmpty) return {};

  final result = <int, List<dynamic>>{};
  state.currentWeekData.forEach((dayIndex, lessons) {
    result[dayIndex] = lessons.where((lesson) {
      final subject = lesson['_subjectShort']?.toString().trim().toLowerCase() ?? '';
      return !hidden.contains(subject);
    }).toList();
  });
  return result;
});

// Current timetable request context
final timetableRequestContextProvider = Provider<WebUntisRequestContext>((ref) {
  final state = ref.watch(appStateNotifierProvider);
  final account = ref.watch(activeUntisAccountProvider);
  final sessionId = account?.sessionId ?? state.sessionID;
  return WebUntisRequestContext(
    schoolUrl: account?.schoolUrl ?? state.schoolUrl,
    schoolName: account?.schoolName ?? state.schoolName,
    sessionId: sessionId,
  );
});

// Current person ID/type for API calls
final currentPersonIdentityProvider = Provider<(int personId, int personType)>((ref) {
  final state = ref.watch(appStateNotifierProvider);
  final account = ref.watch(activeUntisAccountProvider);
  return (
    account?.personId ?? state.personId,
    account?.personType ?? state.personType,
  );
});

// ============================================================================
// Notifier
// ============================================================================

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    return const AppState();
  }

  // Hydrate from storage (called during app initialization)
  Future<void> hydrate(AppState initialState) {
    state = initialState;
  }

  // Auth methods
  void setActiveAccount(UntisAccount account) {
    state = state.copyWith(
      activeUntisAccountId: account.id,
      sessionID: account.sessionId,
      schoolUrl: account.schoolUrl,
      schoolName: account.schoolName,
      personId: account.personId,
      personType: account.personType,
      demoMode: false,
    );
  }

  void clearActiveAccount() {
    state = state.copyWith(
      activeUntisAccountId: null,
      sessionID: '',
      schoolUrl: '',
      schoolName: '',
      personId: 0,
      personType: 0,
      demoMode: false,
    );
  }

  void updateSessionId(String sessionId) {
    state = state.copyWith(sessionID: sessionId);
  }

  void setDemoMode(bool enabled) {
    state = state.copyWith(demoMode: enabled);
  }

  // Account management
  void setAccounts(List<UntisAccount> accounts) {
    state = state.copyWith(untisAccounts: accounts);
  }

  void addAccount(UntisAccount account) {
    state = state.copyWith(
      untisAccounts: [...state.untisAccounts, account],
    );
  }

  void removeAccount(String accountId) {
    state = state.copyWith(
      untisAccounts: state.untisAccounts.where((a) => a.id != accountId).toList(),
      activeUntisAccountId: state.activeUntisAccountId == accountId ? null : state.activeUntisAccountId,
    );
  }

  // UI Preferences
  void setLocale(String locale) {
    state = state.copyWith(appLocale: locale);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setVisualTheme(AppThemeId theme) {
    final enabled = appThemeCapabilities(theme).supportsBlur &&
        (state.themeBlurPreferences[theme.storageKey] ?? true);
    state = state.copyWith(
      visualTheme: theme,
      blurEnabled: enabled,
    );
  }

  void setThemeBlurPreference(String themeKey, bool enabled) {
    final updated = Map<String, bool>.from(state.themeBlurPreferences)
      ..[themeKey] = enabled;
    state = state.copyWith(
      themeBlurPreferences: updated,
      blurEnabled: state.visualTheme.storageKey == themeKey ? enabled : state.blurEnabled,
    );
  }

  void setBlurStrength(double strength) {
    state = state.copyWith(blurStrength: strength.clamp(0.25, 2.0));
  }

  // Batch update for multiple UI prefs
  void updateUIPreferences({
    bool? showCancelled,
    int? timetableSwitchAnimation,
    int? cancelledLessonColor,
    bool? monochromeLessons,
    int? monochromeLessonColor,
    bool? backgroundAnimations,
    int? backgroundAnimationStyle,
    bool? backgroundGyroscope,
    bool? progressivePush,
    bool? dailyBriefingPush,
    bool? importantChangesPush,
    bool? notifyChangeCancellations,
    bool? notifyChangeRoom,
    bool? notifyChangeTeacher,
    bool? notifyChangeOther,
    bool? surfaceBlurEnabled,
    int? surfaceCornerMode,
    int? surfaceCornerRadius,
    bool? appBgBlurEnabled,
    double? appBgBlurAmount,
    int? pageTransition,
    bool? mainTabFadeUpEnabled,
    bool? useMaterialYou,
    bool? isAmoled,
    int? customColorSeed,
    int? lessonCardStyle,
    bool? glowEffectsEnabled,
    bool? lessonBlurEnabled,
    double? lessonBlurAmount,
    double? lessonCardOpacity,
    double? lessonBorderRadius,
    int? lessonAccentStyle,
    bool? lessonShowTeacher,
    bool? lessonShowSubjectIcons,
    bool? lessonShowRoom,
    bool? lessonCompactMode,
    bool? lessonDimPast,
    bool? lessonCancelledPattern,
    bool? showFullTeacherNames,
    int? timetableDaySpan,
    bool? swipeBackGesture,
    String? appIcon,
  }) {
    state = state.copyWith(
      showCancelled: showCancelled ?? state.showCancelled,
      timetableSwitchAnimation: timetableSwitchAnimation?.clamp(0, 2) ?? state.timetableSwitchAnimation,
      cancelledLessonColor: cancelledLessonColor ?? state.cancelledLessonColor,
      monochromeLessons: monochromeLessons ?? state.monochromeLessons,
      monochromeLessonColor: monochromeLessonColor ?? state.monochromeLessonColor,
      backgroundAnimations: backgroundAnimations ?? state.backgroundAnimations,
      backgroundAnimationStyle: backgroundAnimationStyle?.clamp(0, 10) ?? state.backgroundAnimationStyle,
      backgroundGyroscope: backgroundGyroscope ?? state.backgroundGyroscope,
      progressivePush: progressivePush ?? state.progressivePush,
      dailyBriefingPush: dailyBriefingPush ?? state.dailyBriefingPush,
      importantChangesPush: importantChangesPush ?? state.importantChangesPush,
      notifyChangeCancellations: notifyChangeCancellations ?? state.notifyChangeCancellations,
      notifyChangeRoom: notifyChangeRoom ?? state.notifyChangeRoom,
      notifyChangeTeacher: notifyChangeTeacher ?? state.notifyChangeTeacher,
      notifyChangeOther: notifyChangeOther ?? state.notifyChangeOther,
      surfaceBlurEnabled: surfaceBlurEnabled ?? state.surfaceBlurEnabled,
      surfaceCornerMode: surfaceCornerMode?.clamp(0, 2) ?? state.surfaceCornerMode,
      surfaceCornerRadius: surfaceCornerRadius?.clamp(0, 48) ?? state.surfaceCornerRadius,
      appBgBlurEnabled: appBgBlurEnabled ?? state.appBgBlurEnabled,
      appBgBlurAmount: appBgBlurAmount ?? state.appBgBlurAmount,
      pageTransition: pageTransition?.clamp(0, 8) ?? state.pageTransition,
      mainTabFadeUpEnabled: mainTabFadeUpEnabled ?? state.mainTabFadeUpEnabled,
      useMaterialYou: useMaterialYou ?? state.useMaterialYou,
      isAmoled: isAmoled ?? state.isAmoled,
      customColorSeed: customColorSeed ?? state.customColorSeed,
      lessonCardStyle: lessonCardStyle?.clamp(0, 4) ?? state.lessonCardStyle,
      glowEffectsEnabled: glowEffectsEnabled ?? state.glowEffectsEnabled,
      lessonBlurEnabled: lessonBlurEnabled ?? state.lessonBlurEnabled,
      lessonBlurAmount: lessonBlurAmount ?? state.lessonBlurAmount,
      lessonCardOpacity: lessonCardOpacity ?? state.lessonCardOpacity,
      lessonBorderRadius: lessonBorderRadius ?? state.lessonBorderRadius,
      lessonAccentStyle: lessonAccentStyle?.clamp(0, 3) ?? state.lessonAccentStyle,
      lessonShowTeacher: lessonShowTeacher ?? state.lessonShowTeacher,
      lessonShowSubjectIcons: lessonShowSubjectIcons ?? state.lessonShowSubjectIcons,
      lessonShowRoom: lessonShowRoom ?? state.lessonShowRoom,
      lessonCompactMode: lessonCompactMode ?? state.lessonCompactMode,
      lessonDimPast: lessonDimPast ?? state.lessonDimPast,
      lessonCancelledPattern: lessonCancelledPattern ?? state.lessonCancelledPattern,
      showFullTeacherNames: showFullTeacherNames ?? state.showFullTeacherNames,
      timetableDaySpan: timetableDaySpan?.clamp(1, 3) ?? state.timetableDaySpan,
      swipeBackGesture: swipeBackGesture ?? state.swipeBackGesture,
      appIcon: appIcon ?? state.appIcon,
    );
  }

  // AI Settings
  void updateAISettings({
    String? provider,
    String? model,
    String? systemPromptTemplate,
    String? customBaseUrl,
    String? customCompatibility,
    String? localModelPath,
    double? temperature,
    int? maxTokens,
    double? topP,
    String? persona,
  }) {
    state = state.copyWith(
      aiProvider: provider ?? state.aiProvider,
      aiModel: model ?? state.aiModel,
      aiSystemPromptTemplate: systemPromptTemplate ?? state.aiSystemPromptTemplate,
      aiCustomBaseUrl: customBaseUrl ?? state.aiCustomBaseUrl,
      aiCustomCompatibility: customCompatibility ?? state.aiCustomCompatibility,
      aiLocalModelPath: localModelPath ?? state.aiLocalModelPath,
      aiTemperature: temperature ?? state.aiTemperature,
      aiMaxTokens: maxTokens ?? state.aiMaxTokens,
      aiTopP: topP ?? state.aiTopP,
      aiPersona: persona ?? state.aiPersona,
    );
  }

  void setAIApiKey(String provider, String key) {
    switch (provider) {
      case 'gemini':
        state = state.copyWith(geminiApiKey: key);
        break;
      case 'openai':
        state = state.copyWith(openAiApiKey: key);
        break;
      case 'mistral':
        state = state.copyWith(mistralApiKey: key);
        break;
      case 'custom':
        state = state.copyWith(customAiApiKey: key);
        break;
    }
  }

  // Account-scoped data
  void setHiddenSubjects(Set<String> subjects) {
    state = state.copyWith(hiddenSubjects: subjects);
  }

  void setSubjectColors(Map<String, int> colors) {
    state = state.copyWith(subjectColors: colors);
  }

  void setKnownSubjects(Set<String> subjects) {
    state = state.copyWith(knownSubjects: subjects);
  }

  void setCustomHomework(List<Map<String, dynamic>> list) {
    state = state.copyWith(customHomework: list);
  }

  void setCustomExams(List<Map<String, dynamic>> list) {
    state = state.copyWith(customExams: list);
  }

  void setCustomGrades(List<Map<String, dynamic>> list) {
    state = state.copyWith(customGrades: list);
  }

  void setCurrentWeekData(Map<int, List<dynamic>> data) {
    state = state.copyWith(currentWeekData: data);
  }

  void setHomeworks(List<Map<String, dynamic>> list) {
    state = state.copyWith(homeworks: list);
  }

  void setLessonNotes(List<Map<String, dynamic>> list) {
    state = state.copyWith(lessonNotes: list);
  }

  void setApiExams(List<Map<String, dynamic>> list) {
    state = state.copyWith(apiExams: list);
  }

  void setUnreadTimetableChanges(int count) {
    state = state.copyWith(unreadTimetableChanges: count);
  }

  void setUnreadInboxMessages(int count) {
    state = state.copyWith(unreadInboxMessages: count);
  }

  // Pending actions from notifications
  void setPendingTimetableAction({
    String? action,
    String? currentLesson,
    String? nextLesson,
    int? changeDate,
    int? changeStartTime,
  }) {
    state = state.copyWith(
      pendingTimetableAction: action ?? state.pendingTimetableAction,
      pendingTimetableCurrentLesson: currentLesson ?? state.pendingTimetableCurrentLesson,
      pendingTimetableNextLesson: nextLesson ?? state.pendingTimetableNextLesson,
      pendingChangeHighlightDate: changeDate ?? state.pendingChangeHighlightDate,
      pendingChangeHighlightStartTime: changeStartTime ?? state.pendingChangeHighlightStartTime,
    );
  }

  void clearPendingTimetableAction() {
    state = state.copyWith(
      pendingTimetableAction: null,
      pendingTimetableCurrentLesson: null,
      pendingTimetableNextLesson: null,
      pendingChangeHighlightDate: null,
      pendingChangeHighlightStartTime: null,
    );
  }

  // Native assistant
  void setPendingAssistantPrompt(String? prompt) {
    state = state.copyWith(
      pendingAssistantOpen: prompt != null,
      pendingAssistantPrompt: prompt,
    );
  }

  // Class favorites
  void setDefaultClass(int? classId, String? className) {
    state = state.copyWith(
      defaultClassId: classId,
      defaultClassName: className,
    );
  }

  void toggleFavoriteClass(int classId) {
    final updated = Set<int>.from(state.favoriteClassIds);
    if (updated.contains(classId)) {
      updated.remove(classId);
    } else {
      updated.add(classId);
    }
    state = state.copyWith(favoriteClassIds: updated);
  }

  // App version
  void setAppVersion(String version, String buildNumber) {
    state = state.copyWith(
      appVersion: version,
      appBuildNumber: buildNumber,
    );
  }

  void setShowChangelogOnStartup(bool show) {
    state = state.copyWith(showChangelogOnStartup: show);
  }
}

// ============================================================================
// Provider
// ============================================================================

final appStateNotifierProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);