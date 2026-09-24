// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppState implements DiagnosticableTreeMixin {

// App version
 String get appVersion; String get appBuildNumber; bool get showChangelogOnStartup;// Auth / Account
 String get sessionID; String get schoolUrl; String get schoolName; int get personId; int get personType; List<UntisAccount> get untisAccounts; String? get activeUntisAccountId;// Demo mode
 bool get demoMode;// UI Preferences (device-wide)
 String get appLocale; ThemeMode get themeMode; AppThemeId get visualTheme; Map<String, bool> get themeBlurPreferences; bool get showCancelled; int get timetableSwitchAnimation; int get cancelledLessonColor; bool get monochromeLessons; int get monochromeLessonColor; bool get backgroundAnimations; int get backgroundAnimationStyle; bool get backgroundGyroscope; bool get progressivePush; bool get dailyBriefingPush; bool get importantChangesPush; bool get notifyChangeCancellations; bool get notifyChangeRoom; bool get notifyChangeTeacher; bool get notifyChangeOther; bool get blurEnabled; double get blurStrength; bool get surfaceBlurEnabled; int get surfaceCornerMode; int get surfaceCornerRadius; bool get appBgBlurEnabled; double get appBgBlurAmount; int get pageTransition; bool get mainTabFadeUpEnabled; bool get useMaterialYou; bool get isAmoled; int get customColorSeed; String get appIcon;// Lesson Design
 int get lessonCardStyle; bool get glowEffectsEnabled; bool get lessonBlurEnabled; double get lessonBlurAmount; double get lessonCardOpacity; double get lessonBorderRadius; int get lessonAccentStyle; bool get lessonShowTeacher; bool get lessonShowSubjectIcons; bool get lessonShowRoom; bool get lessonCompactMode; bool get lessonDimPast; bool get lessonCancelledPattern; bool get showFullTeacherNames; int get timetableDaySpan; bool get swipeBackGesture;// AI Settings
 String get aiProvider; String get aiModel; String get aiSystemPromptTemplate; String get aiCustomBaseUrl; String get aiCustomCompatibility; String get aiLocalModelPath; double get aiTemperature; int get aiMaxTokens; double get aiTopP; String get aiPersona; String get geminiApiKey; String get openAiApiKey; String get mistralApiKey; String get customAiApiKey;// Account-scoped data (updated when account changes)
 Set<String> get hiddenSubjects; Map<String, int> get subjectColors; Set<String> get knownSubjects; List<Map<String, dynamic>> get customHomework; List<Map<String, dynamic>> get customExams; List<Map<String, dynamic>> get customGrades; Map<int, List<dynamic>> get currentWeekData; List<Map<String, dynamic>> get homeworks; List<Map<String, dynamic>> get lessonNotes; List<Map<String, dynamic>> get apiExams; int get unreadTimetableChanges; int get unreadInboxMessages;// Pending actions from notifications
 String? get pendingTimetableAction; String? get pendingTimetableCurrentLesson; String? get pendingTimetableNextLesson; int? get pendingChangeHighlightDate; int? get pendingChangeHighlightStartTime;// Native assistant integration
 bool get pendingAssistantOpen; String? get pendingAssistantPrompt;// Class favorites
 int? get defaultClassId; String? get defaultClassName; Set<int> get favoriteClassIds;
/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppStateCopyWith<AppState> get copyWith => _$AppStateCopyWithImpl<AppState>(this as AppState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AppState'))
    ..add(DiagnosticsProperty('appVersion', appVersion))..add(DiagnosticsProperty('appBuildNumber', appBuildNumber))..add(DiagnosticsProperty('showChangelogOnStartup', showChangelogOnStartup))..add(DiagnosticsProperty('sessionID', sessionID))..add(DiagnosticsProperty('schoolUrl', schoolUrl))..add(DiagnosticsProperty('schoolName', schoolName))..add(DiagnosticsProperty('personId', personId))..add(DiagnosticsProperty('personType', personType))..add(DiagnosticsProperty('untisAccounts', untisAccounts))..add(DiagnosticsProperty('activeUntisAccountId', activeUntisAccountId))..add(DiagnosticsProperty('demoMode', demoMode))..add(DiagnosticsProperty('appLocale', appLocale))..add(DiagnosticsProperty('themeMode', themeMode))..add(DiagnosticsProperty('visualTheme', visualTheme))..add(DiagnosticsProperty('themeBlurPreferences', themeBlurPreferences))..add(DiagnosticsProperty('showCancelled', showCancelled))..add(DiagnosticsProperty('timetableSwitchAnimation', timetableSwitchAnimation))..add(DiagnosticsProperty('cancelledLessonColor', cancelledLessonColor))..add(DiagnosticsProperty('monochromeLessons', monochromeLessons))..add(DiagnosticsProperty('monochromeLessonColor', monochromeLessonColor))..add(DiagnosticsProperty('backgroundAnimations', backgroundAnimations))..add(DiagnosticsProperty('backgroundAnimationStyle', backgroundAnimationStyle))..add(DiagnosticsProperty('backgroundGyroscope', backgroundGyroscope))..add(DiagnosticsProperty('progressivePush', progressivePush))..add(DiagnosticsProperty('dailyBriefingPush', dailyBriefingPush))..add(DiagnosticsProperty('importantChangesPush', importantChangesPush))..add(DiagnosticsProperty('notifyChangeCancellations', notifyChangeCancellations))..add(DiagnosticsProperty('notifyChangeRoom', notifyChangeRoom))..add(DiagnosticsProperty('notifyChangeTeacher', notifyChangeTeacher))..add(DiagnosticsProperty('notifyChangeOther', notifyChangeOther))..add(DiagnosticsProperty('blurEnabled', blurEnabled))..add(DiagnosticsProperty('blurStrength', blurStrength))..add(DiagnosticsProperty('surfaceBlurEnabled', surfaceBlurEnabled))..add(DiagnosticsProperty('surfaceCornerMode', surfaceCornerMode))..add(DiagnosticsProperty('surfaceCornerRadius', surfaceCornerRadius))..add(DiagnosticsProperty('appBgBlurEnabled', appBgBlurEnabled))..add(DiagnosticsProperty('appBgBlurAmount', appBgBlurAmount))..add(DiagnosticsProperty('pageTransition', pageTransition))..add(DiagnosticsProperty('mainTabFadeUpEnabled', mainTabFadeUpEnabled))..add(DiagnosticsProperty('useMaterialYou', useMaterialYou))..add(DiagnosticsProperty('isAmoled', isAmoled))..add(DiagnosticsProperty('customColorSeed', customColorSeed))..add(DiagnosticsProperty('appIcon', appIcon))..add(DiagnosticsProperty('lessonCardStyle', lessonCardStyle))..add(DiagnosticsProperty('glowEffectsEnabled', glowEffectsEnabled))..add(DiagnosticsProperty('lessonBlurEnabled', lessonBlurEnabled))..add(DiagnosticsProperty('lessonBlurAmount', lessonBlurAmount))..add(DiagnosticsProperty('lessonCardOpacity', lessonCardOpacity))..add(DiagnosticsProperty('lessonBorderRadius', lessonBorderRadius))..add(DiagnosticsProperty('lessonAccentStyle', lessonAccentStyle))..add(DiagnosticsProperty('lessonShowTeacher', lessonShowTeacher))..add(DiagnosticsProperty('lessonShowSubjectIcons', lessonShowSubjectIcons))..add(DiagnosticsProperty('lessonShowRoom', lessonShowRoom))..add(DiagnosticsProperty('lessonCompactMode', lessonCompactMode))..add(DiagnosticsProperty('lessonDimPast', lessonDimPast))..add(DiagnosticsProperty('lessonCancelledPattern', lessonCancelledPattern))..add(DiagnosticsProperty('showFullTeacherNames', showFullTeacherNames))..add(DiagnosticsProperty('timetableDaySpan', timetableDaySpan))..add(DiagnosticsProperty('swipeBackGesture', swipeBackGesture))..add(DiagnosticsProperty('aiProvider', aiProvider))..add(DiagnosticsProperty('aiModel', aiModel))..add(DiagnosticsProperty('aiSystemPromptTemplate', aiSystemPromptTemplate))..add(DiagnosticsProperty('aiCustomBaseUrl', aiCustomBaseUrl))..add(DiagnosticsProperty('aiCustomCompatibility', aiCustomCompatibility))..add(DiagnosticsProperty('aiLocalModelPath', aiLocalModelPath))..add(DiagnosticsProperty('aiTemperature', aiTemperature))..add(DiagnosticsProperty('aiMaxTokens', aiMaxTokens))..add(DiagnosticsProperty('aiTopP', aiTopP))..add(DiagnosticsProperty('aiPersona', aiPersona))..add(DiagnosticsProperty('geminiApiKey', geminiApiKey))..add(DiagnosticsProperty('openAiApiKey', openAiApiKey))..add(DiagnosticsProperty('mistralApiKey', mistralApiKey))..add(DiagnosticsProperty('customAiApiKey', customAiApiKey))..add(DiagnosticsProperty('hiddenSubjects', hiddenSubjects))..add(DiagnosticsProperty('subjectColors', subjectColors))..add(DiagnosticsProperty('knownSubjects', knownSubjects))..add(DiagnosticsProperty('customHomework', customHomework))..add(DiagnosticsProperty('customExams', customExams))..add(DiagnosticsProperty('customGrades', customGrades))..add(DiagnosticsProperty('currentWeekData', currentWeekData))..add(DiagnosticsProperty('homeworks', homeworks))..add(DiagnosticsProperty('lessonNotes', lessonNotes))..add(DiagnosticsProperty('apiExams', apiExams))..add(DiagnosticsProperty('unreadTimetableChanges', unreadTimetableChanges))..add(DiagnosticsProperty('unreadInboxMessages', unreadInboxMessages))..add(DiagnosticsProperty('pendingTimetableAction', pendingTimetableAction))..add(DiagnosticsProperty('pendingTimetableCurrentLesson', pendingTimetableCurrentLesson))..add(DiagnosticsProperty('pendingTimetableNextLesson', pendingTimetableNextLesson))..add(DiagnosticsProperty('pendingChangeHighlightDate', pendingChangeHighlightDate))..add(DiagnosticsProperty('pendingChangeHighlightStartTime', pendingChangeHighlightStartTime))..add(DiagnosticsProperty('pendingAssistantOpen', pendingAssistantOpen))..add(DiagnosticsProperty('pendingAssistantPrompt', pendingAssistantPrompt))..add(DiagnosticsProperty('defaultClassId', defaultClassId))..add(DiagnosticsProperty('defaultClassName', defaultClassName))..add(DiagnosticsProperty('favoriteClassIds', favoriteClassIds));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppState&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.appBuildNumber, appBuildNumber) || other.appBuildNumber == appBuildNumber)&&(identical(other.showChangelogOnStartup, showChangelogOnStartup) || other.showChangelogOnStartup == showChangelogOnStartup)&&(identical(other.sessionID, sessionID) || other.sessionID == sessionID)&&(identical(other.schoolUrl, schoolUrl) || other.schoolUrl == schoolUrl)&&(identical(other.schoolName, schoolName) || other.schoolName == schoolName)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.personType, personType) || other.personType == personType)&&const DeepCollectionEquality().equals(other.untisAccounts, untisAccounts)&&(identical(other.activeUntisAccountId, activeUntisAccountId) || other.activeUntisAccountId == activeUntisAccountId)&&(identical(other.demoMode, demoMode) || other.demoMode == demoMode)&&(identical(other.appLocale, appLocale) || other.appLocale == appLocale)&&const DeepCollectionEquality().equals(other.themeMode, themeMode)&&const DeepCollectionEquality().equals(other.visualTheme, visualTheme)&&const DeepCollectionEquality().equals(other.themeBlurPreferences, themeBlurPreferences)&&(identical(other.showCancelled, showCancelled) || other.showCancelled == showCancelled)&&(identical(other.timetableSwitchAnimation, timetableSwitchAnimation) || other.timetableSwitchAnimation == timetableSwitchAnimation)&&(identical(other.cancelledLessonColor, cancelledLessonColor) || other.cancelledLessonColor == cancelledLessonColor)&&(identical(other.monochromeLessons, monochromeLessons) || other.monochromeLessons == monochromeLessons)&&(identical(other.monochromeLessonColor, monochromeLessonColor) || other.monochromeLessonColor == monochromeLessonColor)&&(identical(other.backgroundAnimations, backgroundAnimations) || other.backgroundAnimations == backgroundAnimations)&&(identical(other.backgroundAnimationStyle, backgroundAnimationStyle) || other.backgroundAnimationStyle == backgroundAnimationStyle)&&(identical(other.backgroundGyroscope, backgroundGyroscope) || other.backgroundGyroscope == backgroundGyroscope)&&(identical(other.progressivePush, progressivePush) || other.progressivePush == progressivePush)&&(identical(other.dailyBriefingPush, dailyBriefingPush) || other.dailyBriefingPush == dailyBriefingPush)&&(identical(other.importantChangesPush, importantChangesPush) || other.importantChangesPush == importantChangesPush)&&(identical(other.notifyChangeCancellations, notifyChangeCancellations) || other.notifyChangeCancellations == notifyChangeCancellations)&&(identical(other.notifyChangeRoom, notifyChangeRoom) || other.notifyChangeRoom == notifyChangeRoom)&&(identical(other.notifyChangeTeacher, notifyChangeTeacher) || other.notifyChangeTeacher == notifyChangeTeacher)&&(identical(other.notifyChangeOther, notifyChangeOther) || other.notifyChangeOther == notifyChangeOther)&&(identical(other.blurEnabled, blurEnabled) || other.blurEnabled == blurEnabled)&&(identical(other.blurStrength, blurStrength) || other.blurStrength == blurStrength)&&(identical(other.surfaceBlurEnabled, surfaceBlurEnabled) || other.surfaceBlurEnabled == surfaceBlurEnabled)&&(identical(other.surfaceCornerMode, surfaceCornerMode) || other.surfaceCornerMode == surfaceCornerMode)&&(identical(other.surfaceCornerRadius, surfaceCornerRadius) || other.surfaceCornerRadius == surfaceCornerRadius)&&(identical(other.appBgBlurEnabled, appBgBlurEnabled) || other.appBgBlurEnabled == appBgBlurEnabled)&&(identical(other.appBgBlurAmount, appBgBlurAmount) || other.appBgBlurAmount == appBgBlurAmount)&&(identical(other.pageTransition, pageTransition) || other.pageTransition == pageTransition)&&(identical(other.mainTabFadeUpEnabled, mainTabFadeUpEnabled) || other.mainTabFadeUpEnabled == mainTabFadeUpEnabled)&&(identical(other.useMaterialYou, useMaterialYou) || other.useMaterialYou == useMaterialYou)&&(identical(other.isAmoled, isAmoled) || other.isAmoled == isAmoled)&&(identical(other.customColorSeed, customColorSeed) || other.customColorSeed == customColorSeed)&&(identical(other.appIcon, appIcon) || other.appIcon == appIcon)&&(identical(other.lessonCardStyle, lessonCardStyle) || other.lessonCardStyle == lessonCardStyle)&&(identical(other.glowEffectsEnabled, glowEffectsEnabled) || other.glowEffectsEnabled == glowEffectsEnabled)&&(identical(other.lessonBlurEnabled, lessonBlurEnabled) || other.lessonBlurEnabled == lessonBlurEnabled)&&(identical(other.lessonBlurAmount, lessonBlurAmount) || other.lessonBlurAmount == lessonBlurAmount)&&(identical(other.lessonCardOpacity, lessonCardOpacity) || other.lessonCardOpacity == lessonCardOpacity)&&(identical(other.lessonBorderRadius, lessonBorderRadius) || other.lessonBorderRadius == lessonBorderRadius)&&(identical(other.lessonAccentStyle, lessonAccentStyle) || other.lessonAccentStyle == lessonAccentStyle)&&(identical(other.lessonShowTeacher, lessonShowTeacher) || other.lessonShowTeacher == lessonShowTeacher)&&(identical(other.lessonShowSubjectIcons, lessonShowSubjectIcons) || other.lessonShowSubjectIcons == lessonShowSubjectIcons)&&(identical(other.lessonShowRoom, lessonShowRoom) || other.lessonShowRoom == lessonShowRoom)&&(identical(other.lessonCompactMode, lessonCompactMode) || other.lessonCompactMode == lessonCompactMode)&&(identical(other.lessonDimPast, lessonDimPast) || other.lessonDimPast == lessonDimPast)&&(identical(other.lessonCancelledPattern, lessonCancelledPattern) || other.lessonCancelledPattern == lessonCancelledPattern)&&(identical(other.showFullTeacherNames, showFullTeacherNames) || other.showFullTeacherNames == showFullTeacherNames)&&(identical(other.timetableDaySpan, timetableDaySpan) || other.timetableDaySpan == timetableDaySpan)&&(identical(other.swipeBackGesture, swipeBackGesture) || other.swipeBackGesture == swipeBackGesture)&&(identical(other.aiProvider, aiProvider) || other.aiProvider == aiProvider)&&(identical(other.aiModel, aiModel) || other.aiModel == aiModel)&&(identical(other.aiSystemPromptTemplate, aiSystemPromptTemplate) || other.aiSystemPromptTemplate == aiSystemPromptTemplate)&&(identical(other.aiCustomBaseUrl, aiCustomBaseUrl) || other.aiCustomBaseUrl == aiCustomBaseUrl)&&(identical(other.aiCustomCompatibility, aiCustomCompatibility) || other.aiCustomCompatibility == aiCustomCompatibility)&&(identical(other.aiLocalModelPath, aiLocalModelPath) || other.aiLocalModelPath == aiLocalModelPath)&&(identical(other.aiTemperature, aiTemperature) || other.aiTemperature == aiTemperature)&&(identical(other.aiMaxTokens, aiMaxTokens) || other.aiMaxTokens == aiMaxTokens)&&(identical(other.aiTopP, aiTopP) || other.aiTopP == aiTopP)&&(identical(other.aiPersona, aiPersona) || other.aiPersona == aiPersona)&&(identical(other.geminiApiKey, geminiApiKey) || other.geminiApiKey == geminiApiKey)&&(identical(other.openAiApiKey, openAiApiKey) || other.openAiApiKey == openAiApiKey)&&(identical(other.mistralApiKey, mistralApiKey) || other.mistralApiKey == mistralApiKey)&&(identical(other.customAiApiKey, customAiApiKey) || other.customAiApiKey == customAiApiKey)&&const DeepCollectionEquality().equals(other.hiddenSubjects, hiddenSubjects)&&const DeepCollectionEquality().equals(other.subjectColors, subjectColors)&&const DeepCollectionEquality().equals(other.knownSubjects, knownSubjects)&&const DeepCollectionEquality().equals(other.customHomework, customHomework)&&const DeepCollectionEquality().equals(other.customExams, customExams)&&const DeepCollectionEquality().equals(other.customGrades, customGrades)&&const DeepCollectionEquality().equals(other.currentWeekData, currentWeekData)&&const DeepCollectionEquality().equals(other.homeworks, homeworks)&&const DeepCollectionEquality().equals(other.lessonNotes, lessonNotes)&&const DeepCollectionEquality().equals(other.apiExams, apiExams)&&(identical(other.unreadTimetableChanges, unreadTimetableChanges) || other.unreadTimetableChanges == unreadTimetableChanges)&&(identical(other.unreadInboxMessages, unreadInboxMessages) || other.unreadInboxMessages == unreadInboxMessages)&&(identical(other.pendingTimetableAction, pendingTimetableAction) || other.pendingTimetableAction == pendingTimetableAction)&&(identical(other.pendingTimetableCurrentLesson, pendingTimetableCurrentLesson) || other.pendingTimetableCurrentLesson == pendingTimetableCurrentLesson)&&(identical(other.pendingTimetableNextLesson, pendingTimetableNextLesson) || other.pendingTimetableNextLesson == pendingTimetableNextLesson)&&(identical(other.pendingChangeHighlightDate, pendingChangeHighlightDate) || other.pendingChangeHighlightDate == pendingChangeHighlightDate)&&(identical(other.pendingChangeHighlightStartTime, pendingChangeHighlightStartTime) || other.pendingChangeHighlightStartTime == pendingChangeHighlightStartTime)&&(identical(other.pendingAssistantOpen, pendingAssistantOpen) || other.pendingAssistantOpen == pendingAssistantOpen)&&(identical(other.pendingAssistantPrompt, pendingAssistantPrompt) || other.pendingAssistantPrompt == pendingAssistantPrompt)&&(identical(other.defaultClassId, defaultClassId) || other.defaultClassId == defaultClassId)&&(identical(other.defaultClassName, defaultClassName) || other.defaultClassName == defaultClassName)&&const DeepCollectionEquality().equals(other.favoriteClassIds, favoriteClassIds));
}


@override
int get hashCode => Object.hashAll([runtimeType,appVersion,appBuildNumber,showChangelogOnStartup,sessionID,schoolUrl,schoolName,personId,personType,const DeepCollectionEquality().hash(untisAccounts),activeUntisAccountId,demoMode,appLocale,const DeepCollectionEquality().hash(themeMode),const DeepCollectionEquality().hash(visualTheme),const DeepCollectionEquality().hash(themeBlurPreferences),showCancelled,timetableSwitchAnimation,cancelledLessonColor,monochromeLessons,monochromeLessonColor,backgroundAnimations,backgroundAnimationStyle,backgroundGyroscope,progressivePush,dailyBriefingPush,importantChangesPush,notifyChangeCancellations,notifyChangeRoom,notifyChangeTeacher,notifyChangeOther,blurEnabled,blurStrength,surfaceBlurEnabled,surfaceCornerMode,surfaceCornerRadius,appBgBlurEnabled,appBgBlurAmount,pageTransition,mainTabFadeUpEnabled,useMaterialYou,isAmoled,customColorSeed,appIcon,lessonCardStyle,glowEffectsEnabled,lessonBlurEnabled,lessonBlurAmount,lessonCardOpacity,lessonBorderRadius,lessonAccentStyle,lessonShowTeacher,lessonShowSubjectIcons,lessonShowRoom,lessonCompactMode,lessonDimPast,lessonCancelledPattern,showFullTeacherNames,timetableDaySpan,swipeBackGesture,aiProvider,aiModel,aiSystemPromptTemplate,aiCustomBaseUrl,aiCustomCompatibility,aiLocalModelPath,aiTemperature,aiMaxTokens,aiTopP,aiPersona,geminiApiKey,openAiApiKey,mistralApiKey,customAiApiKey,const DeepCollectionEquality().hash(hiddenSubjects),const DeepCollectionEquality().hash(subjectColors),const DeepCollectionEquality().hash(knownSubjects),const DeepCollectionEquality().hash(customHomework),const DeepCollectionEquality().hash(customExams),const DeepCollectionEquality().hash(customGrades),const DeepCollectionEquality().hash(currentWeekData),const DeepCollectionEquality().hash(homeworks),const DeepCollectionEquality().hash(lessonNotes),const DeepCollectionEquality().hash(apiExams),unreadTimetableChanges,unreadInboxMessages,pendingTimetableAction,pendingTimetableCurrentLesson,pendingTimetableNextLesson,pendingChangeHighlightDate,pendingChangeHighlightStartTime,pendingAssistantOpen,pendingAssistantPrompt,defaultClassId,defaultClassName,const DeepCollectionEquality().hash(favoriteClassIds)]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AppState(appVersion: $appVersion, appBuildNumber: $appBuildNumber, showChangelogOnStartup: $showChangelogOnStartup, sessionID: $sessionID, schoolUrl: $schoolUrl, schoolName: $schoolName, personId: $personId, personType: $personType, untisAccounts: $untisAccounts, activeUntisAccountId: $activeUntisAccountId, demoMode: $demoMode, appLocale: $appLocale, themeMode: $themeMode, visualTheme: $visualTheme, themeBlurPreferences: $themeBlurPreferences, showCancelled: $showCancelled, timetableSwitchAnimation: $timetableSwitchAnimation, cancelledLessonColor: $cancelledLessonColor, monochromeLessons: $monochromeLessons, monochromeLessonColor: $monochromeLessonColor, backgroundAnimations: $backgroundAnimations, backgroundAnimationStyle: $backgroundAnimationStyle, backgroundGyroscope: $backgroundGyroscope, progressivePush: $progressivePush, dailyBriefingPush: $dailyBriefingPush, importantChangesPush: $importantChangesPush, notifyChangeCancellations: $notifyChangeCancellations, notifyChangeRoom: $notifyChangeRoom, notifyChangeTeacher: $notifyChangeTeacher, notifyChangeOther: $notifyChangeOther, blurEnabled: $blurEnabled, blurStrength: $blurStrength, surfaceBlurEnabled: $surfaceBlurEnabled, surfaceCornerMode: $surfaceCornerMode, surfaceCornerRadius: $surfaceCornerRadius, appBgBlurEnabled: $appBgBlurEnabled, appBgBlurAmount: $appBgBlurAmount, pageTransition: $pageTransition, mainTabFadeUpEnabled: $mainTabFadeUpEnabled, useMaterialYou: $useMaterialYou, isAmoled: $isAmoled, customColorSeed: $customColorSeed, appIcon: $appIcon, lessonCardStyle: $lessonCardStyle, glowEffectsEnabled: $glowEffectsEnabled, lessonBlurEnabled: $lessonBlurEnabled, lessonBlurAmount: $lessonBlurAmount, lessonCardOpacity: $lessonCardOpacity, lessonBorderRadius: $lessonBorderRadius, lessonAccentStyle: $lessonAccentStyle, lessonShowTeacher: $lessonShowTeacher, lessonShowSubjectIcons: $lessonShowSubjectIcons, lessonShowRoom: $lessonShowRoom, lessonCompactMode: $lessonCompactMode, lessonDimPast: $lessonDimPast, lessonCancelledPattern: $lessonCancelledPattern, showFullTeacherNames: $showFullTeacherNames, timetableDaySpan: $timetableDaySpan, swipeBackGesture: $swipeBackGesture, aiProvider: $aiProvider, aiModel: $aiModel, aiSystemPromptTemplate: $aiSystemPromptTemplate, aiCustomBaseUrl: $aiCustomBaseUrl, aiCustomCompatibility: $aiCustomCompatibility, aiLocalModelPath: $aiLocalModelPath, aiTemperature: $aiTemperature, aiMaxTokens: $aiMaxTokens, aiTopP: $aiTopP, aiPersona: $aiPersona, geminiApiKey: $geminiApiKey, openAiApiKey: $openAiApiKey, mistralApiKey: $mistralApiKey, customAiApiKey: $customAiApiKey, hiddenSubjects: $hiddenSubjects, subjectColors: $subjectColors, knownSubjects: $knownSubjects, customHomework: $customHomework, customExams: $customExams, customGrades: $customGrades, currentWeekData: $currentWeekData, homeworks: $homeworks, lessonNotes: $lessonNotes, apiExams: $apiExams, unreadTimetableChanges: $unreadTimetableChanges, unreadInboxMessages: $unreadInboxMessages, pendingTimetableAction: $pendingTimetableAction, pendingTimetableCurrentLesson: $pendingTimetableCurrentLesson, pendingTimetableNextLesson: $pendingTimetableNextLesson, pendingChangeHighlightDate: $pendingChangeHighlightDate, pendingChangeHighlightStartTime: $pendingChangeHighlightStartTime, pendingAssistantOpen: $pendingAssistantOpen, pendingAssistantPrompt: $pendingAssistantPrompt, defaultClassId: $defaultClassId, defaultClassName: $defaultClassName, favoriteClassIds: $favoriteClassIds)';
}


}

/// @nodoc
abstract mixin class $AppStateCopyWith<$Res>  {
  factory $AppStateCopyWith(AppState value, $Res Function(AppState) _then) = _$AppStateCopyWithImpl;
@useResult
$Res call({
 String appVersion, String appBuildNumber, bool showChangelogOnStartup, String sessionID, String schoolUrl, String schoolName, int personId, int personType, List<UntisAccount> untisAccounts, String? activeUntisAccountId, bool demoMode, String appLocale, ThemeMode themeMode, AppThemeId visualTheme, Map<String, bool> themeBlurPreferences, bool showCancelled, int timetableSwitchAnimation, int cancelledLessonColor, bool monochromeLessons, int monochromeLessonColor, bool backgroundAnimations, int backgroundAnimationStyle, bool backgroundGyroscope, bool progressivePush, bool dailyBriefingPush, bool importantChangesPush, bool notifyChangeCancellations, bool notifyChangeRoom, bool notifyChangeTeacher, bool notifyChangeOther, bool blurEnabled, double blurStrength, bool surfaceBlurEnabled, int surfaceCornerMode, int surfaceCornerRadius, bool appBgBlurEnabled, double appBgBlurAmount, int pageTransition, bool mainTabFadeUpEnabled, bool useMaterialYou, bool isAmoled, int customColorSeed, String appIcon, int lessonCardStyle, bool glowEffectsEnabled, bool lessonBlurEnabled, double lessonBlurAmount, double lessonCardOpacity, double lessonBorderRadius, int lessonAccentStyle, bool lessonShowTeacher, bool lessonShowSubjectIcons, bool lessonShowRoom, bool lessonCompactMode, bool lessonDimPast, bool lessonCancelledPattern, bool showFullTeacherNames, int timetableDaySpan, bool swipeBackGesture, String aiProvider, String aiModel, String aiSystemPromptTemplate, String aiCustomBaseUrl, String aiCustomCompatibility, String aiLocalModelPath, double aiTemperature, int aiMaxTokens, double aiTopP, String aiPersona, String geminiApiKey, String openAiApiKey, String mistralApiKey, String customAiApiKey, Set<String> hiddenSubjects, Map<String, int> subjectColors, Set<String> knownSubjects, List<Map<String, dynamic>> customHomework, List<Map<String, dynamic>> customExams, List<Map<String, dynamic>> customGrades, Map<int, List<dynamic>> currentWeekData, List<Map<String, dynamic>> homeworks, List<Map<String, dynamic>> lessonNotes, List<Map<String, dynamic>> apiExams, int unreadTimetableChanges, int unreadInboxMessages, String? pendingTimetableAction, String? pendingTimetableCurrentLesson, String? pendingTimetableNextLesson, int? pendingChangeHighlightDate, int? pendingChangeHighlightStartTime, bool pendingAssistantOpen, String? pendingAssistantPrompt, int? defaultClassId, String? defaultClassName, Set<int> favoriteClassIds
});




}
/// @nodoc
class _$AppStateCopyWithImpl<$Res>
    implements $AppStateCopyWith<$Res> {
  _$AppStateCopyWithImpl(this._self, this._then);

  final AppState _self;
  final $Res Function(AppState) _then;

/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appVersion = null,Object? appBuildNumber = null,Object? showChangelogOnStartup = null,Object? sessionID = null,Object? schoolUrl = null,Object? schoolName = null,Object? personId = null,Object? personType = null,Object? untisAccounts = null,Object? activeUntisAccountId = freezed,Object? demoMode = null,Object? appLocale = null,Object? themeMode = freezed,Object? visualTheme = freezed,Object? themeBlurPreferences = null,Object? showCancelled = null,Object? timetableSwitchAnimation = null,Object? cancelledLessonColor = null,Object? monochromeLessons = null,Object? monochromeLessonColor = null,Object? backgroundAnimations = null,Object? backgroundAnimationStyle = null,Object? backgroundGyroscope = null,Object? progressivePush = null,Object? dailyBriefingPush = null,Object? importantChangesPush = null,Object? notifyChangeCancellations = null,Object? notifyChangeRoom = null,Object? notifyChangeTeacher = null,Object? notifyChangeOther = null,Object? blurEnabled = null,Object? blurStrength = null,Object? surfaceBlurEnabled = null,Object? surfaceCornerMode = null,Object? surfaceCornerRadius = null,Object? appBgBlurEnabled = null,Object? appBgBlurAmount = null,Object? pageTransition = null,Object? mainTabFadeUpEnabled = null,Object? useMaterialYou = null,Object? isAmoled = null,Object? customColorSeed = null,Object? appIcon = null,Object? lessonCardStyle = null,Object? glowEffectsEnabled = null,Object? lessonBlurEnabled = null,Object? lessonBlurAmount = null,Object? lessonCardOpacity = null,Object? lessonBorderRadius = null,Object? lessonAccentStyle = null,Object? lessonShowTeacher = null,Object? lessonShowSubjectIcons = null,Object? lessonShowRoom = null,Object? lessonCompactMode = null,Object? lessonDimPast = null,Object? lessonCancelledPattern = null,Object? showFullTeacherNames = null,Object? timetableDaySpan = null,Object? swipeBackGesture = null,Object? aiProvider = null,Object? aiModel = null,Object? aiSystemPromptTemplate = null,Object? aiCustomBaseUrl = null,Object? aiCustomCompatibility = null,Object? aiLocalModelPath = null,Object? aiTemperature = null,Object? aiMaxTokens = null,Object? aiTopP = null,Object? aiPersona = null,Object? geminiApiKey = null,Object? openAiApiKey = null,Object? mistralApiKey = null,Object? customAiApiKey = null,Object? hiddenSubjects = null,Object? subjectColors = null,Object? knownSubjects = null,Object? customHomework = null,Object? customExams = null,Object? customGrades = null,Object? currentWeekData = null,Object? homeworks = null,Object? lessonNotes = null,Object? apiExams = null,Object? unreadTimetableChanges = null,Object? unreadInboxMessages = null,Object? pendingTimetableAction = freezed,Object? pendingTimetableCurrentLesson = freezed,Object? pendingTimetableNextLesson = freezed,Object? pendingChangeHighlightDate = freezed,Object? pendingChangeHighlightStartTime = freezed,Object? pendingAssistantOpen = null,Object? pendingAssistantPrompt = freezed,Object? defaultClassId = freezed,Object? defaultClassName = freezed,Object? favoriteClassIds = null,}) {
  return _then(_self.copyWith(
appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,appBuildNumber: null == appBuildNumber ? _self.appBuildNumber : appBuildNumber // ignore: cast_nullable_to_non_nullable
as String,showChangelogOnStartup: null == showChangelogOnStartup ? _self.showChangelogOnStartup : showChangelogOnStartup // ignore: cast_nullable_to_non_nullable
as bool,sessionID: null == sessionID ? _self.sessionID : sessionID // ignore: cast_nullable_to_non_nullable
as String,schoolUrl: null == schoolUrl ? _self.schoolUrl : schoolUrl // ignore: cast_nullable_to_non_nullable
as String,schoolName: null == schoolName ? _self.schoolName : schoolName // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as int,personType: null == personType ? _self.personType : personType // ignore: cast_nullable_to_non_nullable
as int,untisAccounts: null == untisAccounts ? _self.untisAccounts : untisAccounts // ignore: cast_nullable_to_non_nullable
as List<UntisAccount>,activeUntisAccountId: freezed == activeUntisAccountId ? _self.activeUntisAccountId : activeUntisAccountId // ignore: cast_nullable_to_non_nullable
as String?,demoMode: null == demoMode ? _self.demoMode : demoMode // ignore: cast_nullable_to_non_nullable
as bool,appLocale: null == appLocale ? _self.appLocale : appLocale // ignore: cast_nullable_to_non_nullable
as String,themeMode: freezed == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,visualTheme: freezed == visualTheme ? _self.visualTheme : visualTheme // ignore: cast_nullable_to_non_nullable
as AppThemeId,themeBlurPreferences: null == themeBlurPreferences ? _self.themeBlurPreferences : themeBlurPreferences // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,showCancelled: null == showCancelled ? _self.showCancelled : showCancelled // ignore: cast_nullable_to_non_nullable
as bool,timetableSwitchAnimation: null == timetableSwitchAnimation ? _self.timetableSwitchAnimation : timetableSwitchAnimation // ignore: cast_nullable_to_non_nullable
as int,cancelledLessonColor: null == cancelledLessonColor ? _self.cancelledLessonColor : cancelledLessonColor // ignore: cast_nullable_to_non_nullable
as int,monochromeLessons: null == monochromeLessons ? _self.monochromeLessons : monochromeLessons // ignore: cast_nullable_to_non_nullable
as bool,monochromeLessonColor: null == monochromeLessonColor ? _self.monochromeLessonColor : monochromeLessonColor // ignore: cast_nullable_to_non_nullable
as int,backgroundAnimations: null == backgroundAnimations ? _self.backgroundAnimations : backgroundAnimations // ignore: cast_nullable_to_non_nullable
as bool,backgroundAnimationStyle: null == backgroundAnimationStyle ? _self.backgroundAnimationStyle : backgroundAnimationStyle // ignore: cast_nullable_to_non_nullable
as int,backgroundGyroscope: null == backgroundGyroscope ? _self.backgroundGyroscope : backgroundGyroscope // ignore: cast_nullable_to_non_nullable
as bool,progressivePush: null == progressivePush ? _self.progressivePush : progressivePush // ignore: cast_nullable_to_non_nullable
as bool,dailyBriefingPush: null == dailyBriefingPush ? _self.dailyBriefingPush : dailyBriefingPush // ignore: cast_nullable_to_non_nullable
as bool,importantChangesPush: null == importantChangesPush ? _self.importantChangesPush : importantChangesPush // ignore: cast_nullable_to_non_nullable
as bool,notifyChangeCancellations: null == notifyChangeCancellations ? _self.notifyChangeCancellations : notifyChangeCancellations // ignore: cast_nullable_to_non_nullable
as bool,notifyChangeRoom: null == notifyChangeRoom ? _self.notifyChangeRoom : notifyChangeRoom // ignore: cast_nullable_to_non_nullable
as bool,notifyChangeTeacher: null == notifyChangeTeacher ? _self.notifyChangeTeacher : notifyChangeTeacher // ignore: cast_nullable_to_non_nullable
as bool,notifyChangeOther: null == notifyChangeOther ? _self.notifyChangeOther : notifyChangeOther // ignore: cast_nullable_to_non_nullable
as bool,blurEnabled: null == blurEnabled ? _self.blurEnabled : blurEnabled // ignore: cast_nullable_to_non_nullable
as bool,blurStrength: null == blurStrength ? _self.blurStrength : blurStrength // ignore: cast_nullable_to_non_nullable
as double,surfaceBlurEnabled: null == surfaceBlurEnabled ? _self.surfaceBlurEnabled : surfaceBlurEnabled // ignore: cast_nullable_to_non_nullable
as bool,surfaceCornerMode: null == surfaceCornerMode ? _self.surfaceCornerMode : surfaceCornerMode // ignore: cast_nullable_to_non_nullable
as int,surfaceCornerRadius: null == surfaceCornerRadius ? _self.surfaceCornerRadius : surfaceCornerRadius // ignore: cast_nullable_to_non_nullable
as int,appBgBlurEnabled: null == appBgBlurEnabled ? _self.appBgBlurEnabled : appBgBlurEnabled // ignore: cast_nullable_to_non_nullable
as bool,appBgBlurAmount: null == appBgBlurAmount ? _self.appBgBlurAmount : appBgBlurAmount // ignore: cast_nullable_to_non_nullable
as double,pageTransition: null == pageTransition ? _self.pageTransition : pageTransition // ignore: cast_nullable_to_non_nullable
as int,mainTabFadeUpEnabled: null == mainTabFadeUpEnabled ? _self.mainTabFadeUpEnabled : mainTabFadeUpEnabled // ignore: cast_nullable_to_non_nullable
as bool,useMaterialYou: null == useMaterialYou ? _self.useMaterialYou : useMaterialYou // ignore: cast_nullable_to_non_nullable
as bool,isAmoled: null == isAmoled ? _self.isAmoled : isAmoled // ignore: cast_nullable_to_non_nullable
as bool,customColorSeed: null == customColorSeed ? _self.customColorSeed : customColorSeed // ignore: cast_nullable_to_non_nullable
as int,appIcon: null == appIcon ? _self.appIcon : appIcon // ignore: cast_nullable_to_non_nullable
as String,lessonCardStyle: null == lessonCardStyle ? _self.lessonCardStyle : lessonCardStyle // ignore: cast_nullable_to_non_nullable
as int,glowEffectsEnabled: null == glowEffectsEnabled ? _self.glowEffectsEnabled : glowEffectsEnabled // ignore: cast_nullable_to_non_nullable
as bool,lessonBlurEnabled: null == lessonBlurEnabled ? _self.lessonBlurEnabled : lessonBlurEnabled // ignore: cast_nullable_to_non_nullable
as bool,lessonBlurAmount: null == lessonBlurAmount ? _self.lessonBlurAmount : lessonBlurAmount // ignore: cast_nullable_to_non_nullable
as double,lessonCardOpacity: null == lessonCardOpacity ? _self.lessonCardOpacity : lessonCardOpacity // ignore: cast_nullable_to_non_nullable
as double,lessonBorderRadius: null == lessonBorderRadius ? _self.lessonBorderRadius : lessonBorderRadius // ignore: cast_nullable_to_non_nullable
as double,lessonAccentStyle: null == lessonAccentStyle ? _self.lessonAccentStyle : lessonAccentStyle // ignore: cast_nullable_to_non_nullable
as int,lessonShowTeacher: null == lessonShowTeacher ? _self.lessonShowTeacher : lessonShowTeacher // ignore: cast_nullable_to_non_nullable
as bool,lessonShowSubjectIcons: null == lessonShowSubjectIcons ? _self.lessonShowSubjectIcons : lessonShowSubjectIcons // ignore: cast_nullable_to_non_nullable
as bool,lessonShowRoom: null == lessonShowRoom ? _self.lessonShowRoom : lessonShowRoom // ignore: cast_nullable_to_non_nullable
as bool,lessonCompactMode: null == lessonCompactMode ? _self.lessonCompactMode : lessonCompactMode // ignore: cast_nullable_to_non_nullable
as bool,lessonDimPast: null == lessonDimPast ? _self.lessonDimPast : lessonDimPast // ignore: cast_nullable_to_non_nullable
as bool,lessonCancelledPattern: null == lessonCancelledPattern ? _self.lessonCancelledPattern : lessonCancelledPattern // ignore: cast_nullable_to_non_nullable
as bool,showFullTeacherNames: null == showFullTeacherNames ? _self.showFullTeacherNames : showFullTeacherNames // ignore: cast_nullable_to_non_nullable
as bool,timetableDaySpan: null == timetableDaySpan ? _self.timetableDaySpan : timetableDaySpan // ignore: cast_nullable_to_non_nullable
as int,swipeBackGesture: null == swipeBackGesture ? _self.swipeBackGesture : swipeBackGesture // ignore: cast_nullable_to_non_nullable
as bool,aiProvider: null == aiProvider ? _self.aiProvider : aiProvider // ignore: cast_nullable_to_non_nullable
as String,aiModel: null == aiModel ? _self.aiModel : aiModel // ignore: cast_nullable_to_non_nullable
as String,aiSystemPromptTemplate: null == aiSystemPromptTemplate ? _self.aiSystemPromptTemplate : aiSystemPromptTemplate // ignore: cast_nullable_to_non_nullable
as String,aiCustomBaseUrl: null == aiCustomBaseUrl ? _self.aiCustomBaseUrl : aiCustomBaseUrl // ignore: cast_nullable_to_non_nullable
as String,aiCustomCompatibility: null == aiCustomCompatibility ? _self.aiCustomCompatibility : aiCustomCompatibility // ignore: cast_nullable_to_non_nullable
as String,aiLocalModelPath: null == aiLocalModelPath ? _self.aiLocalModelPath : aiLocalModelPath // ignore: cast_nullable_to_non_nullable
as String,aiTemperature: null == aiTemperature ? _self.aiTemperature : aiTemperature // ignore: cast_nullable_to_non_nullable
as double,aiMaxTokens: null == aiMaxTokens ? _self.aiMaxTokens : aiMaxTokens // ignore: cast_nullable_to_non_nullable
as int,aiTopP: null == aiTopP ? _self.aiTopP : aiTopP // ignore: cast_nullable_to_non_nullable
as double,aiPersona: null == aiPersona ? _self.aiPersona : aiPersona // ignore: cast_nullable_to_non_nullable
as String,geminiApiKey: null == geminiApiKey ? _self.geminiApiKey : geminiApiKey // ignore: cast_nullable_to_non_nullable
as String,openAiApiKey: null == openAiApiKey ? _self.openAiApiKey : openAiApiKey // ignore: cast_nullable_to_non_nullable
as String,mistralApiKey: null == mistralApiKey ? _self.mistralApiKey : mistralApiKey // ignore: cast_nullable_to_non_nullable
as String,customAiApiKey: null == customAiApiKey ? _self.customAiApiKey : customAiApiKey // ignore: cast_nullable_to_non_nullable
as String,hiddenSubjects: null == hiddenSubjects ? _self.hiddenSubjects : hiddenSubjects // ignore: cast_nullable_to_non_nullable
as Set<String>,subjectColors: null == subjectColors ? _self.subjectColors : subjectColors // ignore: cast_nullable_to_non_nullable
as Map<String, int>,knownSubjects: null == knownSubjects ? _self.knownSubjects : knownSubjects // ignore: cast_nullable_to_non_nullable
as Set<String>,customHomework: null == customHomework ? _self.customHomework : customHomework // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,customExams: null == customExams ? _self.customExams : customExams // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,customGrades: null == customGrades ? _self.customGrades : customGrades // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,currentWeekData: null == currentWeekData ? _self.currentWeekData : currentWeekData // ignore: cast_nullable_to_non_nullable
as Map<int, List<dynamic>>,homeworks: null == homeworks ? _self.homeworks : homeworks // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,lessonNotes: null == lessonNotes ? _self.lessonNotes : lessonNotes // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,apiExams: null == apiExams ? _self.apiExams : apiExams // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,unreadTimetableChanges: null == unreadTimetableChanges ? _self.unreadTimetableChanges : unreadTimetableChanges // ignore: cast_nullable_to_non_nullable
as int,unreadInboxMessages: null == unreadInboxMessages ? _self.unreadInboxMessages : unreadInboxMessages // ignore: cast_nullable_to_non_nullable
as int,pendingTimetableAction: freezed == pendingTimetableAction ? _self.pendingTimetableAction : pendingTimetableAction // ignore: cast_nullable_to_non_nullable
as String?,pendingTimetableCurrentLesson: freezed == pendingTimetableCurrentLesson ? _self.pendingTimetableCurrentLesson : pendingTimetableCurrentLesson // ignore: cast_nullable_to_non_nullable
as String?,pendingTimetableNextLesson: freezed == pendingTimetableNextLesson ? _self.pendingTimetableNextLesson : pendingTimetableNextLesson // ignore: cast_nullable_to_non_nullable
as String?,pendingChangeHighlightDate: freezed == pendingChangeHighlightDate ? _self.pendingChangeHighlightDate : pendingChangeHighlightDate // ignore: cast_nullable_to_non_nullable
as int?,pendingChangeHighlightStartTime: freezed == pendingChangeHighlightStartTime ? _self.pendingChangeHighlightStartTime : pendingChangeHighlightStartTime // ignore: cast_nullable_to_non_nullable
as int?,pendingAssistantOpen: null == pendingAssistantOpen ? _self.pendingAssistantOpen : pendingAssistantOpen // ignore: cast_nullable_to_non_nullable
as bool,pendingAssistantPrompt: freezed == pendingAssistantPrompt ? _self.pendingAssistantPrompt : pendingAssistantPrompt // ignore: cast_nullable_to_non_nullable
as String?,defaultClassId: freezed == defaultClassId ? _self.defaultClassId : defaultClassId // ignore: cast_nullable_to_non_nullable
as int?,defaultClassName: freezed == defaultClassName ? _self.defaultClassName : defaultClassName // ignore: cast_nullable_to_non_nullable
as String?,favoriteClassIds: null == favoriteClassIds ? _self.favoriteClassIds : favoriteClassIds // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppState].
extension AppStatePatterns on AppState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppState value)  $default,){
final _that = this;
switch (_that) {
case _AppState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppState value)?  $default,){
final _that = this;
switch (_that) {
case _AppState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appVersion,  String appBuildNumber,  bool showChangelogOnStartup,  String sessionID,  String schoolUrl,  String schoolName,  int personId,  int personType,  List<UntisAccount> untisAccounts,  String? activeUntisAccountId,  bool demoMode,  String appLocale,  ThemeMode themeMode,  AppThemeId visualTheme,  Map<String, bool> themeBlurPreferences,  bool showCancelled,  int timetableSwitchAnimation,  int cancelledLessonColor,  bool monochromeLessons,  int monochromeLessonColor,  bool backgroundAnimations,  int backgroundAnimationStyle,  bool backgroundGyroscope,  bool progressivePush,  bool dailyBriefingPush,  bool importantChangesPush,  bool notifyChangeCancellations,  bool notifyChangeRoom,  bool notifyChangeTeacher,  bool notifyChangeOther,  bool blurEnabled,  double blurStrength,  bool surfaceBlurEnabled,  int surfaceCornerMode,  int surfaceCornerRadius,  bool appBgBlurEnabled,  double appBgBlurAmount,  int pageTransition,  bool mainTabFadeUpEnabled,  bool useMaterialYou,  bool isAmoled,  int customColorSeed,  String appIcon,  int lessonCardStyle,  bool glowEffectsEnabled,  bool lessonBlurEnabled,  double lessonBlurAmount,  double lessonCardOpacity,  double lessonBorderRadius,  int lessonAccentStyle,  bool lessonShowTeacher,  bool lessonShowSubjectIcons,  bool lessonShowRoom,  bool lessonCompactMode,  bool lessonDimPast,  bool lessonCancelledPattern,  bool showFullTeacherNames,  int timetableDaySpan,  bool swipeBackGesture,  String aiProvider,  String aiModel,  String aiSystemPromptTemplate,  String aiCustomBaseUrl,  String aiCustomCompatibility,  String aiLocalModelPath,  double aiTemperature,  int aiMaxTokens,  double aiTopP,  String aiPersona,  String geminiApiKey,  String openAiApiKey,  String mistralApiKey,  String customAiApiKey,  Set<String> hiddenSubjects,  Map<String, int> subjectColors,  Set<String> knownSubjects,  List<Map<String, dynamic>> customHomework,  List<Map<String, dynamic>> customExams,  List<Map<String, dynamic>> customGrades,  Map<int, List<dynamic>> currentWeekData,  List<Map<String, dynamic>> homeworks,  List<Map<String, dynamic>> lessonNotes,  List<Map<String, dynamic>> apiExams,  int unreadTimetableChanges,  int unreadInboxMessages,  String? pendingTimetableAction,  String? pendingTimetableCurrentLesson,  String? pendingTimetableNextLesson,  int? pendingChangeHighlightDate,  int? pendingChangeHighlightStartTime,  bool pendingAssistantOpen,  String? pendingAssistantPrompt,  int? defaultClassId,  String? defaultClassName,  Set<int> favoriteClassIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppState() when $default != null:
return $default(_that.appVersion,_that.appBuildNumber,_that.showChangelogOnStartup,_that.sessionID,_that.schoolUrl,_that.schoolName,_that.personId,_that.personType,_that.untisAccounts,_that.activeUntisAccountId,_that.demoMode,_that.appLocale,_that.themeMode,_that.visualTheme,_that.themeBlurPreferences,_that.showCancelled,_that.timetableSwitchAnimation,_that.cancelledLessonColor,_that.monochromeLessons,_that.monochromeLessonColor,_that.backgroundAnimations,_that.backgroundAnimationStyle,_that.backgroundGyroscope,_that.progressivePush,_that.dailyBriefingPush,_that.importantChangesPush,_that.notifyChangeCancellations,_that.notifyChangeRoom,_that.notifyChangeTeacher,_that.notifyChangeOther,_that.blurEnabled,_that.blurStrength,_that.surfaceBlurEnabled,_that.surfaceCornerMode,_that.surfaceCornerRadius,_that.appBgBlurEnabled,_that.appBgBlurAmount,_that.pageTransition,_that.mainTabFadeUpEnabled,_that.useMaterialYou,_that.isAmoled,_that.customColorSeed,_that.appIcon,_that.lessonCardStyle,_that.glowEffectsEnabled,_that.lessonBlurEnabled,_that.lessonBlurAmount,_that.lessonCardOpacity,_that.lessonBorderRadius,_that.lessonAccentStyle,_that.lessonShowTeacher,_that.lessonShowSubjectIcons,_that.lessonShowRoom,_that.lessonCompactMode,_that.lessonDimPast,_that.lessonCancelledPattern,_that.showFullTeacherNames,_that.timetableDaySpan,_that.swipeBackGesture,_that.aiProvider,_that.aiModel,_that.aiSystemPromptTemplate,_that.aiCustomBaseUrl,_that.aiCustomCompatibility,_that.aiLocalModelPath,_that.aiTemperature,_that.aiMaxTokens,_that.aiTopP,_that.aiPersona,_that.geminiApiKey,_that.openAiApiKey,_that.mistralApiKey,_that.customAiApiKey,_that.hiddenSubjects,_that.subjectColors,_that.knownSubjects,_that.customHomework,_that.customExams,_that.customGrades,_that.currentWeekData,_that.homeworks,_that.lessonNotes,_that.apiExams,_that.unreadTimetableChanges,_that.unreadInboxMessages,_that.pendingTimetableAction,_that.pendingTimetableCurrentLesson,_that.pendingTimetableNextLesson,_that.pendingChangeHighlightDate,_that.pendingChangeHighlightStartTime,_that.pendingAssistantOpen,_that.pendingAssistantPrompt,_that.defaultClassId,_that.defaultClassName,_that.favoriteClassIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appVersion,  String appBuildNumber,  bool showChangelogOnStartup,  String sessionID,  String schoolUrl,  String schoolName,  int personId,  int personType,  List<UntisAccount> untisAccounts,  String? activeUntisAccountId,  bool demoMode,  String appLocale,  ThemeMode themeMode,  AppThemeId visualTheme,  Map<String, bool> themeBlurPreferences,  bool showCancelled,  int timetableSwitchAnimation,  int cancelledLessonColor,  bool monochromeLessons,  int monochromeLessonColor,  bool backgroundAnimations,  int backgroundAnimationStyle,  bool backgroundGyroscope,  bool progressivePush,  bool dailyBriefingPush,  bool importantChangesPush,  bool notifyChangeCancellations,  bool notifyChangeRoom,  bool notifyChangeTeacher,  bool notifyChangeOther,  bool blurEnabled,  double blurStrength,  bool surfaceBlurEnabled,  int surfaceCornerMode,  int surfaceCornerRadius,  bool appBgBlurEnabled,  double appBgBlurAmount,  int pageTransition,  bool mainTabFadeUpEnabled,  bool useMaterialYou,  bool isAmoled,  int customColorSeed,  String appIcon,  int lessonCardStyle,  bool glowEffectsEnabled,  bool lessonBlurEnabled,  double lessonBlurAmount,  double lessonCardOpacity,  double lessonBorderRadius,  int lessonAccentStyle,  bool lessonShowTeacher,  bool lessonShowSubjectIcons,  bool lessonShowRoom,  bool lessonCompactMode,  bool lessonDimPast,  bool lessonCancelledPattern,  bool showFullTeacherNames,  int timetableDaySpan,  bool swipeBackGesture,  String aiProvider,  String aiModel,  String aiSystemPromptTemplate,  String aiCustomBaseUrl,  String aiCustomCompatibility,  String aiLocalModelPath,  double aiTemperature,  int aiMaxTokens,  double aiTopP,  String aiPersona,  String geminiApiKey,  String openAiApiKey,  String mistralApiKey,  String customAiApiKey,  Set<String> hiddenSubjects,  Map<String, int> subjectColors,  Set<String> knownSubjects,  List<Map<String, dynamic>> customHomework,  List<Map<String, dynamic>> customExams,  List<Map<String, dynamic>> customGrades,  Map<int, List<dynamic>> currentWeekData,  List<Map<String, dynamic>> homeworks,  List<Map<String, dynamic>> lessonNotes,  List<Map<String, dynamic>> apiExams,  int unreadTimetableChanges,  int unreadInboxMessages,  String? pendingTimetableAction,  String? pendingTimetableCurrentLesson,  String? pendingTimetableNextLesson,  int? pendingChangeHighlightDate,  int? pendingChangeHighlightStartTime,  bool pendingAssistantOpen,  String? pendingAssistantPrompt,  int? defaultClassId,  String? defaultClassName,  Set<int> favoriteClassIds)  $default,) {final _that = this;
switch (_that) {
case _AppState():
return $default(_that.appVersion,_that.appBuildNumber,_that.showChangelogOnStartup,_that.sessionID,_that.schoolUrl,_that.schoolName,_that.personId,_that.personType,_that.untisAccounts,_that.activeUntisAccountId,_that.demoMode,_that.appLocale,_that.themeMode,_that.visualTheme,_that.themeBlurPreferences,_that.showCancelled,_that.timetableSwitchAnimation,_that.cancelledLessonColor,_that.monochromeLessons,_that.monochromeLessonColor,_that.backgroundAnimations,_that.backgroundAnimationStyle,_that.backgroundGyroscope,_that.progressivePush,_that.dailyBriefingPush,_that.importantChangesPush,_that.notifyChangeCancellations,_that.notifyChangeRoom,_that.notifyChangeTeacher,_that.notifyChangeOther,_that.blurEnabled,_that.blurStrength,_that.surfaceBlurEnabled,_that.surfaceCornerMode,_that.surfaceCornerRadius,_that.appBgBlurEnabled,_that.appBgBlurAmount,_that.pageTransition,_that.mainTabFadeUpEnabled,_that.useMaterialYou,_that.isAmoled,_that.customColorSeed,_that.appIcon,_that.lessonCardStyle,_that.glowEffectsEnabled,_that.lessonBlurEnabled,_that.lessonBlurAmount,_that.lessonCardOpacity,_that.lessonBorderRadius,_that.lessonAccentStyle,_that.lessonShowTeacher,_that.lessonShowSubjectIcons,_that.lessonShowRoom,_that.lessonCompactMode,_that.lessonDimPast,_that.lessonCancelledPattern,_that.showFullTeacherNames,_that.timetableDaySpan,_that.swipeBackGesture,_that.aiProvider,_that.aiModel,_that.aiSystemPromptTemplate,_that.aiCustomBaseUrl,_that.aiCustomCompatibility,_that.aiLocalModelPath,_that.aiTemperature,_that.aiMaxTokens,_that.aiTopP,_that.aiPersona,_that.geminiApiKey,_that.openAiApiKey,_that.mistralApiKey,_that.customAiApiKey,_that.hiddenSubjects,_that.subjectColors,_that.knownSubjects,_that.customHomework,_that.customExams,_that.customGrades,_that.currentWeekData,_that.homeworks,_that.lessonNotes,_that.apiExams,_that.unreadTimetableChanges,_that.unreadInboxMessages,_that.pendingTimetableAction,_that.pendingTimetableCurrentLesson,_that.pendingTimetableNextLesson,_that.pendingChangeHighlightDate,_that.pendingChangeHighlightStartTime,_that.pendingAssistantOpen,_that.pendingAssistantPrompt,_that.defaultClassId,_that.defaultClassName,_that.favoriteClassIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appVersion,  String appBuildNumber,  bool showChangelogOnStartup,  String sessionID,  String schoolUrl,  String schoolName,  int personId,  int personType,  List<UntisAccount> untisAccounts,  String? activeUntisAccountId,  bool demoMode,  String appLocale,  ThemeMode themeMode,  AppThemeId visualTheme,  Map<String, bool> themeBlurPreferences,  bool showCancelled,  int timetableSwitchAnimation,  int cancelledLessonColor,  bool monochromeLessons,  int monochromeLessonColor,  bool backgroundAnimations,  int backgroundAnimationStyle,  bool backgroundGyroscope,  bool progressivePush,  bool dailyBriefingPush,  bool importantChangesPush,  bool notifyChangeCancellations,  bool notifyChangeRoom,  bool notifyChangeTeacher,  bool notifyChangeOther,  bool blurEnabled,  double blurStrength,  bool surfaceBlurEnabled,  int surfaceCornerMode,  int surfaceCornerRadius,  bool appBgBlurEnabled,  double appBgBlurAmount,  int pageTransition,  bool mainTabFadeUpEnabled,  bool useMaterialYou,  bool isAmoled,  int customColorSeed,  String appIcon,  int lessonCardStyle,  bool glowEffectsEnabled,  bool lessonBlurEnabled,  double lessonBlurAmount,  double lessonCardOpacity,  double lessonBorderRadius,  int lessonAccentStyle,  bool lessonShowTeacher,  bool lessonShowSubjectIcons,  bool lessonShowRoom,  bool lessonCompactMode,  bool lessonDimPast,  bool lessonCancelledPattern,  bool showFullTeacherNames,  int timetableDaySpan,  bool swipeBackGesture,  String aiProvider,  String aiModel,  String aiSystemPromptTemplate,  String aiCustomBaseUrl,  String aiCustomCompatibility,  String aiLocalModelPath,  double aiTemperature,  int aiMaxTokens,  double aiTopP,  String aiPersona,  String geminiApiKey,  String openAiApiKey,  String mistralApiKey,  String customAiApiKey,  Set<String> hiddenSubjects,  Map<String, int> subjectColors,  Set<String> knownSubjects,  List<Map<String, dynamic>> customHomework,  List<Map<String, dynamic>> customExams,  List<Map<String, dynamic>> customGrades,  Map<int, List<dynamic>> currentWeekData,  List<Map<String, dynamic>> homeworks,  List<Map<String, dynamic>> lessonNotes,  List<Map<String, dynamic>> apiExams,  int unreadTimetableChanges,  int unreadInboxMessages,  String? pendingTimetableAction,  String? pendingTimetableCurrentLesson,  String? pendingTimetableNextLesson,  int? pendingChangeHighlightDate,  int? pendingChangeHighlightStartTime,  bool pendingAssistantOpen,  String? pendingAssistantPrompt,  int? defaultClassId,  String? defaultClassName,  Set<int> favoriteClassIds)?  $default,) {final _that = this;
switch (_that) {
case _AppState() when $default != null:
return $default(_that.appVersion,_that.appBuildNumber,_that.showChangelogOnStartup,_that.sessionID,_that.schoolUrl,_that.schoolName,_that.personId,_that.personType,_that.untisAccounts,_that.activeUntisAccountId,_that.demoMode,_that.appLocale,_that.themeMode,_that.visualTheme,_that.themeBlurPreferences,_that.showCancelled,_that.timetableSwitchAnimation,_that.cancelledLessonColor,_that.monochromeLessons,_that.monochromeLessonColor,_that.backgroundAnimations,_that.backgroundAnimationStyle,_that.backgroundGyroscope,_that.progressivePush,_that.dailyBriefingPush,_that.importantChangesPush,_that.notifyChangeCancellations,_that.notifyChangeRoom,_that.notifyChangeTeacher,_that.notifyChangeOther,_that.blurEnabled,_that.blurStrength,_that.surfaceBlurEnabled,_that.surfaceCornerMode,_that.surfaceCornerRadius,_that.appBgBlurEnabled,_that.appBgBlurAmount,_that.pageTransition,_that.mainTabFadeUpEnabled,_that.useMaterialYou,_that.isAmoled,_that.customColorSeed,_that.appIcon,_that.lessonCardStyle,_that.glowEffectsEnabled,_that.lessonBlurEnabled,_that.lessonBlurAmount,_that.lessonCardOpacity,_that.lessonBorderRadius,_that.lessonAccentStyle,_that.lessonShowTeacher,_that.lessonShowSubjectIcons,_that.lessonShowRoom,_that.lessonCompactMode,_that.lessonDimPast,_that.lessonCancelledPattern,_that.showFullTeacherNames,_that.timetableDaySpan,_that.swipeBackGesture,_that.aiProvider,_that.aiModel,_that.aiSystemPromptTemplate,_that.aiCustomBaseUrl,_that.aiCustomCompatibility,_that.aiLocalModelPath,_that.aiTemperature,_that.aiMaxTokens,_that.aiTopP,_that.aiPersona,_that.geminiApiKey,_that.openAiApiKey,_that.mistralApiKey,_that.customAiApiKey,_that.hiddenSubjects,_that.subjectColors,_that.knownSubjects,_that.customHomework,_that.customExams,_that.customGrades,_that.currentWeekData,_that.homeworks,_that.lessonNotes,_that.apiExams,_that.unreadTimetableChanges,_that.unreadInboxMessages,_that.pendingTimetableAction,_that.pendingTimetableCurrentLesson,_that.pendingTimetableNextLesson,_that.pendingChangeHighlightDate,_that.pendingChangeHighlightStartTime,_that.pendingAssistantOpen,_that.pendingAssistantPrompt,_that.defaultClassId,_that.defaultClassName,_that.favoriteClassIds);case _:
  return null;

}
}

}

/// @nodoc


class _AppState with DiagnosticableTreeMixin implements AppState {
  const _AppState({this.appVersion = '0.0.0', this.appBuildNumber = '0', this.showChangelogOnStartup = false, this.sessionID = '', this.schoolUrl = '', this.schoolName = '', this.personId = 0, this.personType = 0, final  List<UntisAccount> untisAccounts = const [], this.activeUntisAccountId, this.demoMode = false, this.appLocale = 'de', this.themeMode = ThemeMode.system, this.visualTheme = AppThemeId.defaultTheme, final  Map<String, bool> themeBlurPreferences = const {}, this.showCancelled = true, this.timetableSwitchAnimation = 0, this.cancelledLessonColor = 0xFFFF1744, this.monochromeLessons = false, this.monochromeLessonColor = 0xFF757575, this.backgroundAnimations = true, this.backgroundAnimationStyle = 0, this.backgroundGyroscope = false, this.progressivePush = true, this.dailyBriefingPush = true, this.importantChangesPush = true, this.notifyChangeCancellations = true, this.notifyChangeRoom = true, this.notifyChangeTeacher = true, this.notifyChangeOther = true, this.blurEnabled = true, this.blurStrength = 1.0, this.surfaceBlurEnabled = true, this.surfaceCornerMode = 0, this.surfaceCornerRadius = 24, this.appBgBlurEnabled = false, this.appBgBlurAmount = 10.0, this.pageTransition = 0, this.mainTabFadeUpEnabled = false, this.useMaterialYou = true, this.isAmoled = false, this.customColorSeed = 0xFF0F766E, this.appIcon = 'default', this.lessonCardStyle = 0, this.glowEffectsEnabled = false, this.lessonBlurEnabled = false, this.lessonBlurAmount = 12.0, this.lessonCardOpacity = 0.9, this.lessonBorderRadius = 12.0, this.lessonAccentStyle = 0, this.lessonShowTeacher = true, this.lessonShowSubjectIcons = false, this.lessonShowRoom = true, this.lessonCompactMode = false, this.lessonDimPast = true, this.lessonCancelledPattern = true, this.showFullTeacherNames = true, this.timetableDaySpan = 1, this.swipeBackGesture = false, this.aiProvider = 'gemini', this.aiModel = 'gemini-3.6-flash', this.aiSystemPromptTemplate = '', this.aiCustomBaseUrl = '', this.aiCustomCompatibility = 'openai', this.aiLocalModelPath = '', this.aiTemperature = 0.2, this.aiMaxTokens = 2600, this.aiTopP = 0.95, this.aiPersona = 'helpful', this.geminiApiKey = '', this.openAiApiKey = '', this.mistralApiKey = '', this.customAiApiKey = '', final  Set<String> hiddenSubjects = const {}, final  Map<String, int> subjectColors = const {}, final  Set<String> knownSubjects = const {}, final  List<Map<String, dynamic>> customHomework = const [], final  List<Map<String, dynamic>> customExams = const [], final  List<Map<String, dynamic>> customGrades = const [], final  Map<int, List<dynamic>> currentWeekData = const {}, final  List<Map<String, dynamic>> homeworks = const [], final  List<Map<String, dynamic>> lessonNotes = const [], final  List<Map<String, dynamic>> apiExams = const [], this.unreadTimetableChanges = 0, this.unreadInboxMessages = 0, this.pendingTimetableAction, this.pendingTimetableCurrentLesson, this.pendingTimetableNextLesson, this.pendingChangeHighlightDate, this.pendingChangeHighlightStartTime, this.pendingAssistantOpen = false, this.pendingAssistantPrompt, this.defaultClassId, this.defaultClassName, final  Set<int> favoriteClassIds = const {}}): _untisAccounts = untisAccounts,_themeBlurPreferences = themeBlurPreferences,_hiddenSubjects = hiddenSubjects,_subjectColors = subjectColors,_knownSubjects = knownSubjects,_customHomework = customHomework,_customExams = customExams,_customGrades = customGrades,_currentWeekData = currentWeekData,_homeworks = homeworks,_lessonNotes = lessonNotes,_apiExams = apiExams,_favoriteClassIds = favoriteClassIds;
  

// App version
@override@JsonKey() final  String appVersion;
@override@JsonKey() final  String appBuildNumber;
@override@JsonKey() final  bool showChangelogOnStartup;
// Auth / Account
@override@JsonKey() final  String sessionID;
@override@JsonKey() final  String schoolUrl;
@override@JsonKey() final  String schoolName;
@override@JsonKey() final  int personId;
@override@JsonKey() final  int personType;
 final  List<UntisAccount> _untisAccounts;
@override@JsonKey() List<UntisAccount> get untisAccounts {
  if (_untisAccounts is EqualUnmodifiableListView) return _untisAccounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_untisAccounts);
}

@override final  String? activeUntisAccountId;
// Demo mode
@override@JsonKey() final  bool demoMode;
// UI Preferences (device-wide)
@override@JsonKey() final  String appLocale;
@override@JsonKey() final  ThemeMode themeMode;
@override@JsonKey() final  AppThemeId visualTheme;
 final  Map<String, bool> _themeBlurPreferences;
@override@JsonKey() Map<String, bool> get themeBlurPreferences {
  if (_themeBlurPreferences is EqualUnmodifiableMapView) return _themeBlurPreferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_themeBlurPreferences);
}

@override@JsonKey() final  bool showCancelled;
@override@JsonKey() final  int timetableSwitchAnimation;
@override@JsonKey() final  int cancelledLessonColor;
@override@JsonKey() final  bool monochromeLessons;
@override@JsonKey() final  int monochromeLessonColor;
@override@JsonKey() final  bool backgroundAnimations;
@override@JsonKey() final  int backgroundAnimationStyle;
@override@JsonKey() final  bool backgroundGyroscope;
@override@JsonKey() final  bool progressivePush;
@override@JsonKey() final  bool dailyBriefingPush;
@override@JsonKey() final  bool importantChangesPush;
@override@JsonKey() final  bool notifyChangeCancellations;
@override@JsonKey() final  bool notifyChangeRoom;
@override@JsonKey() final  bool notifyChangeTeacher;
@override@JsonKey() final  bool notifyChangeOther;
@override@JsonKey() final  bool blurEnabled;
@override@JsonKey() final  double blurStrength;
@override@JsonKey() final  bool surfaceBlurEnabled;
@override@JsonKey() final  int surfaceCornerMode;
@override@JsonKey() final  int surfaceCornerRadius;
@override@JsonKey() final  bool appBgBlurEnabled;
@override@JsonKey() final  double appBgBlurAmount;
@override@JsonKey() final  int pageTransition;
@override@JsonKey() final  bool mainTabFadeUpEnabled;
@override@JsonKey() final  bool useMaterialYou;
@override@JsonKey() final  bool isAmoled;
@override@JsonKey() final  int customColorSeed;
@override@JsonKey() final  String appIcon;
// Lesson Design
@override@JsonKey() final  int lessonCardStyle;
@override@JsonKey() final  bool glowEffectsEnabled;
@override@JsonKey() final  bool lessonBlurEnabled;
@override@JsonKey() final  double lessonBlurAmount;
@override@JsonKey() final  double lessonCardOpacity;
@override@JsonKey() final  double lessonBorderRadius;
@override@JsonKey() final  int lessonAccentStyle;
@override@JsonKey() final  bool lessonShowTeacher;
@override@JsonKey() final  bool lessonShowSubjectIcons;
@override@JsonKey() final  bool lessonShowRoom;
@override@JsonKey() final  bool lessonCompactMode;
@override@JsonKey() final  bool lessonDimPast;
@override@JsonKey() final  bool lessonCancelledPattern;
@override@JsonKey() final  bool showFullTeacherNames;
@override@JsonKey() final  int timetableDaySpan;
@override@JsonKey() final  bool swipeBackGesture;
// AI Settings
@override@JsonKey() final  String aiProvider;
@override@JsonKey() final  String aiModel;
@override@JsonKey() final  String aiSystemPromptTemplate;
@override@JsonKey() final  String aiCustomBaseUrl;
@override@JsonKey() final  String aiCustomCompatibility;
@override@JsonKey() final  String aiLocalModelPath;
@override@JsonKey() final  double aiTemperature;
@override@JsonKey() final  int aiMaxTokens;
@override@JsonKey() final  double aiTopP;
@override@JsonKey() final  String aiPersona;
@override@JsonKey() final  String geminiApiKey;
@override@JsonKey() final  String openAiApiKey;
@override@JsonKey() final  String mistralApiKey;
@override@JsonKey() final  String customAiApiKey;
// Account-scoped data (updated when account changes)
 final  Set<String> _hiddenSubjects;
// Account-scoped data (updated when account changes)
@override@JsonKey() Set<String> get hiddenSubjects {
  if (_hiddenSubjects is EqualUnmodifiableSetView) return _hiddenSubjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_hiddenSubjects);
}

 final  Map<String, int> _subjectColors;
@override@JsonKey() Map<String, int> get subjectColors {
  if (_subjectColors is EqualUnmodifiableMapView) return _subjectColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_subjectColors);
}

 final  Set<String> _knownSubjects;
@override@JsonKey() Set<String> get knownSubjects {
  if (_knownSubjects is EqualUnmodifiableSetView) return _knownSubjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_knownSubjects);
}

 final  List<Map<String, dynamic>> _customHomework;
@override@JsonKey() List<Map<String, dynamic>> get customHomework {
  if (_customHomework is EqualUnmodifiableListView) return _customHomework;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customHomework);
}

 final  List<Map<String, dynamic>> _customExams;
@override@JsonKey() List<Map<String, dynamic>> get customExams {
  if (_customExams is EqualUnmodifiableListView) return _customExams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customExams);
}

 final  List<Map<String, dynamic>> _customGrades;
@override@JsonKey() List<Map<String, dynamic>> get customGrades {
  if (_customGrades is EqualUnmodifiableListView) return _customGrades;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customGrades);
}

 final  Map<int, List<dynamic>> _currentWeekData;
@override@JsonKey() Map<int, List<dynamic>> get currentWeekData {
  if (_currentWeekData is EqualUnmodifiableMapView) return _currentWeekData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_currentWeekData);
}

 final  List<Map<String, dynamic>> _homeworks;
@override@JsonKey() List<Map<String, dynamic>> get homeworks {
  if (_homeworks is EqualUnmodifiableListView) return _homeworks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_homeworks);
}

 final  List<Map<String, dynamic>> _lessonNotes;
@override@JsonKey() List<Map<String, dynamic>> get lessonNotes {
  if (_lessonNotes is EqualUnmodifiableListView) return _lessonNotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lessonNotes);
}

 final  List<Map<String, dynamic>> _apiExams;
@override@JsonKey() List<Map<String, dynamic>> get apiExams {
  if (_apiExams is EqualUnmodifiableListView) return _apiExams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_apiExams);
}

@override@JsonKey() final  int unreadTimetableChanges;
@override@JsonKey() final  int unreadInboxMessages;
// Pending actions from notifications
@override final  String? pendingTimetableAction;
@override final  String? pendingTimetableCurrentLesson;
@override final  String? pendingTimetableNextLesson;
@override final  int? pendingChangeHighlightDate;
@override final  int? pendingChangeHighlightStartTime;
// Native assistant integration
@override@JsonKey() final  bool pendingAssistantOpen;
@override final  String? pendingAssistantPrompt;
// Class favorites
@override final  int? defaultClassId;
@override final  String? defaultClassName;
 final  Set<int> _favoriteClassIds;
@override@JsonKey() Set<int> get favoriteClassIds {
  if (_favoriteClassIds is EqualUnmodifiableSetView) return _favoriteClassIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_favoriteClassIds);
}


/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppStateCopyWith<_AppState> get copyWith => __$AppStateCopyWithImpl<_AppState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AppState'))
    ..add(DiagnosticsProperty('appVersion', appVersion))..add(DiagnosticsProperty('appBuildNumber', appBuildNumber))..add(DiagnosticsProperty('showChangelogOnStartup', showChangelogOnStartup))..add(DiagnosticsProperty('sessionID', sessionID))..add(DiagnosticsProperty('schoolUrl', schoolUrl))..add(DiagnosticsProperty('schoolName', schoolName))..add(DiagnosticsProperty('personId', personId))..add(DiagnosticsProperty('personType', personType))..add(DiagnosticsProperty('untisAccounts', untisAccounts))..add(DiagnosticsProperty('activeUntisAccountId', activeUntisAccountId))..add(DiagnosticsProperty('demoMode', demoMode))..add(DiagnosticsProperty('appLocale', appLocale))..add(DiagnosticsProperty('themeMode', themeMode))..add(DiagnosticsProperty('visualTheme', visualTheme))..add(DiagnosticsProperty('themeBlurPreferences', themeBlurPreferences))..add(DiagnosticsProperty('showCancelled', showCancelled))..add(DiagnosticsProperty('timetableSwitchAnimation', timetableSwitchAnimation))..add(DiagnosticsProperty('cancelledLessonColor', cancelledLessonColor))..add(DiagnosticsProperty('monochromeLessons', monochromeLessons))..add(DiagnosticsProperty('monochromeLessonColor', monochromeLessonColor))..add(DiagnosticsProperty('backgroundAnimations', backgroundAnimations))..add(DiagnosticsProperty('backgroundAnimationStyle', backgroundAnimationStyle))..add(DiagnosticsProperty('backgroundGyroscope', backgroundGyroscope))..add(DiagnosticsProperty('progressivePush', progressivePush))..add(DiagnosticsProperty('dailyBriefingPush', dailyBriefingPush))..add(DiagnosticsProperty('importantChangesPush', importantChangesPush))..add(DiagnosticsProperty('notifyChangeCancellations', notifyChangeCancellations))..add(DiagnosticsProperty('notifyChangeRoom', notifyChangeRoom))..add(DiagnosticsProperty('notifyChangeTeacher', notifyChangeTeacher))..add(DiagnosticsProperty('notifyChangeOther', notifyChangeOther))..add(DiagnosticsProperty('blurEnabled', blurEnabled))..add(DiagnosticsProperty('blurStrength', blurStrength))..add(DiagnosticsProperty('surfaceBlurEnabled', surfaceBlurEnabled))..add(DiagnosticsProperty('surfaceCornerMode', surfaceCornerMode))..add(DiagnosticsProperty('surfaceCornerRadius', surfaceCornerRadius))..add(DiagnosticsProperty('appBgBlurEnabled', appBgBlurEnabled))..add(DiagnosticsProperty('appBgBlurAmount', appBgBlurAmount))..add(DiagnosticsProperty('pageTransition', pageTransition))..add(DiagnosticsProperty('mainTabFadeUpEnabled', mainTabFadeUpEnabled))..add(DiagnosticsProperty('useMaterialYou', useMaterialYou))..add(DiagnosticsProperty('isAmoled', isAmoled))..add(DiagnosticsProperty('customColorSeed', customColorSeed))..add(DiagnosticsProperty('appIcon', appIcon))..add(DiagnosticsProperty('lessonCardStyle', lessonCardStyle))..add(DiagnosticsProperty('glowEffectsEnabled', glowEffectsEnabled))..add(DiagnosticsProperty('lessonBlurEnabled', lessonBlurEnabled))..add(DiagnosticsProperty('lessonBlurAmount', lessonBlurAmount))..add(DiagnosticsProperty('lessonCardOpacity', lessonCardOpacity))..add(DiagnosticsProperty('lessonBorderRadius', lessonBorderRadius))..add(DiagnosticsProperty('lessonAccentStyle', lessonAccentStyle))..add(DiagnosticsProperty('lessonShowTeacher', lessonShowTeacher))..add(DiagnosticsProperty('lessonShowSubjectIcons', lessonShowSubjectIcons))..add(DiagnosticsProperty('lessonShowRoom', lessonShowRoom))..add(DiagnosticsProperty('lessonCompactMode', lessonCompactMode))..add(DiagnosticsProperty('lessonDimPast', lessonDimPast))..add(DiagnosticsProperty('lessonCancelledPattern', lessonCancelledPattern))..add(DiagnosticsProperty('showFullTeacherNames', showFullTeacherNames))..add(DiagnosticsProperty('timetableDaySpan', timetableDaySpan))..add(DiagnosticsProperty('swipeBackGesture', swipeBackGesture))..add(DiagnosticsProperty('aiProvider', aiProvider))..add(DiagnosticsProperty('aiModel', aiModel))..add(DiagnosticsProperty('aiSystemPromptTemplate', aiSystemPromptTemplate))..add(DiagnosticsProperty('aiCustomBaseUrl', aiCustomBaseUrl))..add(DiagnosticsProperty('aiCustomCompatibility', aiCustomCompatibility))..add(DiagnosticsProperty('aiLocalModelPath', aiLocalModelPath))..add(DiagnosticsProperty('aiTemperature', aiTemperature))..add(DiagnosticsProperty('aiMaxTokens', aiMaxTokens))..add(DiagnosticsProperty('aiTopP', aiTopP))..add(DiagnosticsProperty('aiPersona', aiPersona))..add(DiagnosticsProperty('geminiApiKey', geminiApiKey))..add(DiagnosticsProperty('openAiApiKey', openAiApiKey))..add(DiagnosticsProperty('mistralApiKey', mistralApiKey))..add(DiagnosticsProperty('customAiApiKey', customAiApiKey))..add(DiagnosticsProperty('hiddenSubjects', hiddenSubjects))..add(DiagnosticsProperty('subjectColors', subjectColors))..add(DiagnosticsProperty('knownSubjects', knownSubjects))..add(DiagnosticsProperty('customHomework', customHomework))..add(DiagnosticsProperty('customExams', customExams))..add(DiagnosticsProperty('customGrades', customGrades))..add(DiagnosticsProperty('currentWeekData', currentWeekData))..add(DiagnosticsProperty('homeworks', homeworks))..add(DiagnosticsProperty('lessonNotes', lessonNotes))..add(DiagnosticsProperty('apiExams', apiExams))..add(DiagnosticsProperty('unreadTimetableChanges', unreadTimetableChanges))..add(DiagnosticsProperty('unreadInboxMessages', unreadInboxMessages))..add(DiagnosticsProperty('pendingTimetableAction', pendingTimetableAction))..add(DiagnosticsProperty('pendingTimetableCurrentLesson', pendingTimetableCurrentLesson))..add(DiagnosticsProperty('pendingTimetableNextLesson', pendingTimetableNextLesson))..add(DiagnosticsProperty('pendingChangeHighlightDate', pendingChangeHighlightDate))..add(DiagnosticsProperty('pendingChangeHighlightStartTime', pendingChangeHighlightStartTime))..add(DiagnosticsProperty('pendingAssistantOpen', pendingAssistantOpen))..add(DiagnosticsProperty('pendingAssistantPrompt', pendingAssistantPrompt))..add(DiagnosticsProperty('defaultClassId', defaultClassId))..add(DiagnosticsProperty('defaultClassName', defaultClassName))..add(DiagnosticsProperty('favoriteClassIds', favoriteClassIds));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppState&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.appBuildNumber, appBuildNumber) || other.appBuildNumber == appBuildNumber)&&(identical(other.showChangelogOnStartup, showChangelogOnStartup) || other.showChangelogOnStartup == showChangelogOnStartup)&&(identical(other.sessionID, sessionID) || other.sessionID == sessionID)&&(identical(other.schoolUrl, schoolUrl) || other.schoolUrl == schoolUrl)&&(identical(other.schoolName, schoolName) || other.schoolName == schoolName)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.personType, personType) || other.personType == personType)&&const DeepCollectionEquality().equals(other._untisAccounts, _untisAccounts)&&(identical(other.activeUntisAccountId, activeUntisAccountId) || other.activeUntisAccountId == activeUntisAccountId)&&(identical(other.demoMode, demoMode) || other.demoMode == demoMode)&&(identical(other.appLocale, appLocale) || other.appLocale == appLocale)&&const DeepCollectionEquality().equals(other.themeMode, themeMode)&&const DeepCollectionEquality().equals(other.visualTheme, visualTheme)&&const DeepCollectionEquality().equals(other._themeBlurPreferences, _themeBlurPreferences)&&(identical(other.showCancelled, showCancelled) || other.showCancelled == showCancelled)&&(identical(other.timetableSwitchAnimation, timetableSwitchAnimation) || other.timetableSwitchAnimation == timetableSwitchAnimation)&&(identical(other.cancelledLessonColor, cancelledLessonColor) || other.cancelledLessonColor == cancelledLessonColor)&&(identical(other.monochromeLessons, monochromeLessons) || other.monochromeLessons == monochromeLessons)&&(identical(other.monochromeLessonColor, monochromeLessonColor) || other.monochromeLessonColor == monochromeLessonColor)&&(identical(other.backgroundAnimations, backgroundAnimations) || other.backgroundAnimations == backgroundAnimations)&&(identical(other.backgroundAnimationStyle, backgroundAnimationStyle) || other.backgroundAnimationStyle == backgroundAnimationStyle)&&(identical(other.backgroundGyroscope, backgroundGyroscope) || other.backgroundGyroscope == backgroundGyroscope)&&(identical(other.progressivePush, progressivePush) || other.progressivePush == progressivePush)&&(identical(other.dailyBriefingPush, dailyBriefingPush) || other.dailyBriefingPush == dailyBriefingPush)&&(identical(other.importantChangesPush, importantChangesPush) || other.importantChangesPush == importantChangesPush)&&(identical(other.notifyChangeCancellations, notifyChangeCancellations) || other.notifyChangeCancellations == notifyChangeCancellations)&&(identical(other.notifyChangeRoom, notifyChangeRoom) || other.notifyChangeRoom == notifyChangeRoom)&&(identical(other.notifyChangeTeacher, notifyChangeTeacher) || other.notifyChangeTeacher == notifyChangeTeacher)&&(identical(other.notifyChangeOther, notifyChangeOther) || other.notifyChangeOther == notifyChangeOther)&&(identical(other.blurEnabled, blurEnabled) || other.blurEnabled == blurEnabled)&&(identical(other.blurStrength, blurStrength) || other.blurStrength == blurStrength)&&(identical(other.surfaceBlurEnabled, surfaceBlurEnabled) || other.surfaceBlurEnabled == surfaceBlurEnabled)&&(identical(other.surfaceCornerMode, surfaceCornerMode) || other.surfaceCornerMode == surfaceCornerMode)&&(identical(other.surfaceCornerRadius, surfaceCornerRadius) || other.surfaceCornerRadius == surfaceCornerRadius)&&(identical(other.appBgBlurEnabled, appBgBlurEnabled) || other.appBgBlurEnabled == appBgBlurEnabled)&&(identical(other.appBgBlurAmount, appBgBlurAmount) || other.appBgBlurAmount == appBgBlurAmount)&&(identical(other.pageTransition, pageTransition) || other.pageTransition == pageTransition)&&(identical(other.mainTabFadeUpEnabled, mainTabFadeUpEnabled) || other.mainTabFadeUpEnabled == mainTabFadeUpEnabled)&&(identical(other.useMaterialYou, useMaterialYou) || other.useMaterialYou == useMaterialYou)&&(identical(other.isAmoled, isAmoled) || other.isAmoled == isAmoled)&&(identical(other.customColorSeed, customColorSeed) || other.customColorSeed == customColorSeed)&&(identical(other.appIcon, appIcon) || other.appIcon == appIcon)&&(identical(other.lessonCardStyle, lessonCardStyle) || other.lessonCardStyle == lessonCardStyle)&&(identical(other.glowEffectsEnabled, glowEffectsEnabled) || other.glowEffectsEnabled == glowEffectsEnabled)&&(identical(other.lessonBlurEnabled, lessonBlurEnabled) || other.lessonBlurEnabled == lessonBlurEnabled)&&(identical(other.lessonBlurAmount, lessonBlurAmount) || other.lessonBlurAmount == lessonBlurAmount)&&(identical(other.lessonCardOpacity, lessonCardOpacity) || other.lessonCardOpacity == lessonCardOpacity)&&(identical(other.lessonBorderRadius, lessonBorderRadius) || other.lessonBorderRadius == lessonBorderRadius)&&(identical(other.lessonAccentStyle, lessonAccentStyle) || other.lessonAccentStyle == lessonAccentStyle)&&(identical(other.lessonShowTeacher, lessonShowTeacher) || other.lessonShowTeacher == lessonShowTeacher)&&(identical(other.lessonShowSubjectIcons, lessonShowSubjectIcons) || other.lessonShowSubjectIcons == lessonShowSubjectIcons)&&(identical(other.lessonShowRoom, lessonShowRoom) || other.lessonShowRoom == lessonShowRoom)&&(identical(other.lessonCompactMode, lessonCompactMode) || other.lessonCompactMode == lessonCompactMode)&&(identical(other.lessonDimPast, lessonDimPast) || other.lessonDimPast == lessonDimPast)&&(identical(other.lessonCancelledPattern, lessonCancelledPattern) || other.lessonCancelledPattern == lessonCancelledPattern)&&(identical(other.showFullTeacherNames, showFullTeacherNames) || other.showFullTeacherNames == showFullTeacherNames)&&(identical(other.timetableDaySpan, timetableDaySpan) || other.timetableDaySpan == timetableDaySpan)&&(identical(other.swipeBackGesture, swipeBackGesture) || other.swipeBackGesture == swipeBackGesture)&&(identical(other.aiProvider, aiProvider) || other.aiProvider == aiProvider)&&(identical(other.aiModel, aiModel) || other.aiModel == aiModel)&&(identical(other.aiSystemPromptTemplate, aiSystemPromptTemplate) || other.aiSystemPromptTemplate == aiSystemPromptTemplate)&&(identical(other.aiCustomBaseUrl, aiCustomBaseUrl) || other.aiCustomBaseUrl == aiCustomBaseUrl)&&(identical(other.aiCustomCompatibility, aiCustomCompatibility) || other.aiCustomCompatibility == aiCustomCompatibility)&&(identical(other.aiLocalModelPath, aiLocalModelPath) || other.aiLocalModelPath == aiLocalModelPath)&&(identical(other.aiTemperature, aiTemperature) || other.aiTemperature == aiTemperature)&&(identical(other.aiMaxTokens, aiMaxTokens) || other.aiMaxTokens == aiMaxTokens)&&(identical(other.aiTopP, aiTopP) || other.aiTopP == aiTopP)&&(identical(other.aiPersona, aiPersona) || other.aiPersona == aiPersona)&&(identical(other.geminiApiKey, geminiApiKey) || other.geminiApiKey == geminiApiKey)&&(identical(other.openAiApiKey, openAiApiKey) || other.openAiApiKey == openAiApiKey)&&(identical(other.mistralApiKey, mistralApiKey) || other.mistralApiKey == mistralApiKey)&&(identical(other.customAiApiKey, customAiApiKey) || other.customAiApiKey == customAiApiKey)&&const DeepCollectionEquality().equals(other._hiddenSubjects, _hiddenSubjects)&&const DeepCollectionEquality().equals(other._subjectColors, _subjectColors)&&const DeepCollectionEquality().equals(other._knownSubjects, _knownSubjects)&&const DeepCollectionEquality().equals(other._customHomework, _customHomework)&&const DeepCollectionEquality().equals(other._customExams, _customExams)&&const DeepCollectionEquality().equals(other._customGrades, _customGrades)&&const DeepCollectionEquality().equals(other._currentWeekData, _currentWeekData)&&const DeepCollectionEquality().equals(other._homeworks, _homeworks)&&const DeepCollectionEquality().equals(other._lessonNotes, _lessonNotes)&&const DeepCollectionEquality().equals(other._apiExams, _apiExams)&&(identical(other.unreadTimetableChanges, unreadTimetableChanges) || other.unreadTimetableChanges == unreadTimetableChanges)&&(identical(other.unreadInboxMessages, unreadInboxMessages) || other.unreadInboxMessages == unreadInboxMessages)&&(identical(other.pendingTimetableAction, pendingTimetableAction) || other.pendingTimetableAction == pendingTimetableAction)&&(identical(other.pendingTimetableCurrentLesson, pendingTimetableCurrentLesson) || other.pendingTimetableCurrentLesson == pendingTimetableCurrentLesson)&&(identical(other.pendingTimetableNextLesson, pendingTimetableNextLesson) || other.pendingTimetableNextLesson == pendingTimetableNextLesson)&&(identical(other.pendingChangeHighlightDate, pendingChangeHighlightDate) || other.pendingChangeHighlightDate == pendingChangeHighlightDate)&&(identical(other.pendingChangeHighlightStartTime, pendingChangeHighlightStartTime) || other.pendingChangeHighlightStartTime == pendingChangeHighlightStartTime)&&(identical(other.pendingAssistantOpen, pendingAssistantOpen) || other.pendingAssistantOpen == pendingAssistantOpen)&&(identical(other.pendingAssistantPrompt, pendingAssistantPrompt) || other.pendingAssistantPrompt == pendingAssistantPrompt)&&(identical(other.defaultClassId, defaultClassId) || other.defaultClassId == defaultClassId)&&(identical(other.defaultClassName, defaultClassName) || other.defaultClassName == defaultClassName)&&const DeepCollectionEquality().equals(other._favoriteClassIds, _favoriteClassIds));
}


@override
int get hashCode => Object.hashAll([runtimeType,appVersion,appBuildNumber,showChangelogOnStartup,sessionID,schoolUrl,schoolName,personId,personType,const DeepCollectionEquality().hash(_untisAccounts),activeUntisAccountId,demoMode,appLocale,const DeepCollectionEquality().hash(themeMode),const DeepCollectionEquality().hash(visualTheme),const DeepCollectionEquality().hash(_themeBlurPreferences),showCancelled,timetableSwitchAnimation,cancelledLessonColor,monochromeLessons,monochromeLessonColor,backgroundAnimations,backgroundAnimationStyle,backgroundGyroscope,progressivePush,dailyBriefingPush,importantChangesPush,notifyChangeCancellations,notifyChangeRoom,notifyChangeTeacher,notifyChangeOther,blurEnabled,blurStrength,surfaceBlurEnabled,surfaceCornerMode,surfaceCornerRadius,appBgBlurEnabled,appBgBlurAmount,pageTransition,mainTabFadeUpEnabled,useMaterialYou,isAmoled,customColorSeed,appIcon,lessonCardStyle,glowEffectsEnabled,lessonBlurEnabled,lessonBlurAmount,lessonCardOpacity,lessonBorderRadius,lessonAccentStyle,lessonShowTeacher,lessonShowSubjectIcons,lessonShowRoom,lessonCompactMode,lessonDimPast,lessonCancelledPattern,showFullTeacherNames,timetableDaySpan,swipeBackGesture,aiProvider,aiModel,aiSystemPromptTemplate,aiCustomBaseUrl,aiCustomCompatibility,aiLocalModelPath,aiTemperature,aiMaxTokens,aiTopP,aiPersona,geminiApiKey,openAiApiKey,mistralApiKey,customAiApiKey,const DeepCollectionEquality().hash(_hiddenSubjects),const DeepCollectionEquality().hash(_subjectColors),const DeepCollectionEquality().hash(_knownSubjects),const DeepCollectionEquality().hash(_customHomework),const DeepCollectionEquality().hash(_customExams),const DeepCollectionEquality().hash(_customGrades),const DeepCollectionEquality().hash(_currentWeekData),const DeepCollectionEquality().hash(_homeworks),const DeepCollectionEquality().hash(_lessonNotes),const DeepCollectionEquality().hash(_apiExams),unreadTimetableChanges,unreadInboxMessages,pendingTimetableAction,pendingTimetableCurrentLesson,pendingTimetableNextLesson,pendingChangeHighlightDate,pendingChangeHighlightStartTime,pendingAssistantOpen,pendingAssistantPrompt,defaultClassId,defaultClassName,const DeepCollectionEquality().hash(_favoriteClassIds)]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AppState(appVersion: $appVersion, appBuildNumber: $appBuildNumber, showChangelogOnStartup: $showChangelogOnStartup, sessionID: $sessionID, schoolUrl: $schoolUrl, schoolName: $schoolName, personId: $personId, personType: $personType, untisAccounts: $untisAccounts, activeUntisAccountId: $activeUntisAccountId, demoMode: $demoMode, appLocale: $appLocale, themeMode: $themeMode, visualTheme: $visualTheme, themeBlurPreferences: $themeBlurPreferences, showCancelled: $showCancelled, timetableSwitchAnimation: $timetableSwitchAnimation, cancelledLessonColor: $cancelledLessonColor, monochromeLessons: $monochromeLessons, monochromeLessonColor: $monochromeLessonColor, backgroundAnimations: $backgroundAnimations, backgroundAnimationStyle: $backgroundAnimationStyle, backgroundGyroscope: $backgroundGyroscope, progressivePush: $progressivePush, dailyBriefingPush: $dailyBriefingPush, importantChangesPush: $importantChangesPush, notifyChangeCancellations: $notifyChangeCancellations, notifyChangeRoom: $notifyChangeRoom, notifyChangeTeacher: $notifyChangeTeacher, notifyChangeOther: $notifyChangeOther, blurEnabled: $blurEnabled, blurStrength: $blurStrength, surfaceBlurEnabled: $surfaceBlurEnabled, surfaceCornerMode: $surfaceCornerMode, surfaceCornerRadius: $surfaceCornerRadius, appBgBlurEnabled: $appBgBlurEnabled, appBgBlurAmount: $appBgBlurAmount, pageTransition: $pageTransition, mainTabFadeUpEnabled: $mainTabFadeUpEnabled, useMaterialYou: $useMaterialYou, isAmoled: $isAmoled, customColorSeed: $customColorSeed, appIcon: $appIcon, lessonCardStyle: $lessonCardStyle, glowEffectsEnabled: $glowEffectsEnabled, lessonBlurEnabled: $lessonBlurEnabled, lessonBlurAmount: $lessonBlurAmount, lessonCardOpacity: $lessonCardOpacity, lessonBorderRadius: $lessonBorderRadius, lessonAccentStyle: $lessonAccentStyle, lessonShowTeacher: $lessonShowTeacher, lessonShowSubjectIcons: $lessonShowSubjectIcons, lessonShowRoom: $lessonShowRoom, lessonCompactMode: $lessonCompactMode, lessonDimPast: $lessonDimPast, lessonCancelledPattern: $lessonCancelledPattern, showFullTeacherNames: $showFullTeacherNames, timetableDaySpan: $timetableDaySpan, swipeBackGesture: $swipeBackGesture, aiProvider: $aiProvider, aiModel: $aiModel, aiSystemPromptTemplate: $aiSystemPromptTemplate, aiCustomBaseUrl: $aiCustomBaseUrl, aiCustomCompatibility: $aiCustomCompatibility, aiLocalModelPath: $aiLocalModelPath, aiTemperature: $aiTemperature, aiMaxTokens: $aiMaxTokens, aiTopP: $aiTopP, aiPersona: $aiPersona, geminiApiKey: $geminiApiKey, openAiApiKey: $openAiApiKey, mistralApiKey: $mistralApiKey, customAiApiKey: $customAiApiKey, hiddenSubjects: $hiddenSubjects, subjectColors: $subjectColors, knownSubjects: $knownSubjects, customHomework: $customHomework, customExams: $customExams, customGrades: $customGrades, currentWeekData: $currentWeekData, homeworks: $homeworks, lessonNotes: $lessonNotes, apiExams: $apiExams, unreadTimetableChanges: $unreadTimetableChanges, unreadInboxMessages: $unreadInboxMessages, pendingTimetableAction: $pendingTimetableAction, pendingTimetableCurrentLesson: $pendingTimetableCurrentLesson, pendingTimetableNextLesson: $pendingTimetableNextLesson, pendingChangeHighlightDate: $pendingChangeHighlightDate, pendingChangeHighlightStartTime: $pendingChangeHighlightStartTime, pendingAssistantOpen: $pendingAssistantOpen, pendingAssistantPrompt: $pendingAssistantPrompt, defaultClassId: $defaultClassId, defaultClassName: $defaultClassName, favoriteClassIds: $favoriteClassIds)';
}


}

/// @nodoc
abstract mixin class _$AppStateCopyWith<$Res> implements $AppStateCopyWith<$Res> {
  factory _$AppStateCopyWith(_AppState value, $Res Function(_AppState) _then) = __$AppStateCopyWithImpl;
@override @useResult
$Res call({
 String appVersion, String appBuildNumber, bool showChangelogOnStartup, String sessionID, String schoolUrl, String schoolName, int personId, int personType, List<UntisAccount> untisAccounts, String? activeUntisAccountId, bool demoMode, String appLocale, ThemeMode themeMode, AppThemeId visualTheme, Map<String, bool> themeBlurPreferences, bool showCancelled, int timetableSwitchAnimation, int cancelledLessonColor, bool monochromeLessons, int monochromeLessonColor, bool backgroundAnimations, int backgroundAnimationStyle, bool backgroundGyroscope, bool progressivePush, bool dailyBriefingPush, bool importantChangesPush, bool notifyChangeCancellations, bool notifyChangeRoom, bool notifyChangeTeacher, bool notifyChangeOther, bool blurEnabled, double blurStrength, bool surfaceBlurEnabled, int surfaceCornerMode, int surfaceCornerRadius, bool appBgBlurEnabled, double appBgBlurAmount, int pageTransition, bool mainTabFadeUpEnabled, bool useMaterialYou, bool isAmoled, int customColorSeed, String appIcon, int lessonCardStyle, bool glowEffectsEnabled, bool lessonBlurEnabled, double lessonBlurAmount, double lessonCardOpacity, double lessonBorderRadius, int lessonAccentStyle, bool lessonShowTeacher, bool lessonShowSubjectIcons, bool lessonShowRoom, bool lessonCompactMode, bool lessonDimPast, bool lessonCancelledPattern, bool showFullTeacherNames, int timetableDaySpan, bool swipeBackGesture, String aiProvider, String aiModel, String aiSystemPromptTemplate, String aiCustomBaseUrl, String aiCustomCompatibility, String aiLocalModelPath, double aiTemperature, int aiMaxTokens, double aiTopP, String aiPersona, String geminiApiKey, String openAiApiKey, String mistralApiKey, String customAiApiKey, Set<String> hiddenSubjects, Map<String, int> subjectColors, Set<String> knownSubjects, List<Map<String, dynamic>> customHomework, List<Map<String, dynamic>> customExams, List<Map<String, dynamic>> customGrades, Map<int, List<dynamic>> currentWeekData, List<Map<String, dynamic>> homeworks, List<Map<String, dynamic>> lessonNotes, List<Map<String, dynamic>> apiExams, int unreadTimetableChanges, int unreadInboxMessages, String? pendingTimetableAction, String? pendingTimetableCurrentLesson, String? pendingTimetableNextLesson, int? pendingChangeHighlightDate, int? pendingChangeHighlightStartTime, bool pendingAssistantOpen, String? pendingAssistantPrompt, int? defaultClassId, String? defaultClassName, Set<int> favoriteClassIds
});




}
/// @nodoc
class __$AppStateCopyWithImpl<$Res>
    implements _$AppStateCopyWith<$Res> {
  __$AppStateCopyWithImpl(this._self, this._then);

  final _AppState _self;
  final $Res Function(_AppState) _then;

/// Create a copy of AppState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appVersion = null,Object? appBuildNumber = null,Object? showChangelogOnStartup = null,Object? sessionID = null,Object? schoolUrl = null,Object? schoolName = null,Object? personId = null,Object? personType = null,Object? untisAccounts = null,Object? activeUntisAccountId = freezed,Object? demoMode = null,Object? appLocale = null,Object? themeMode = freezed,Object? visualTheme = freezed,Object? themeBlurPreferences = null,Object? showCancelled = null,Object? timetableSwitchAnimation = null,Object? cancelledLessonColor = null,Object? monochromeLessons = null,Object? monochromeLessonColor = null,Object? backgroundAnimations = null,Object? backgroundAnimationStyle = null,Object? backgroundGyroscope = null,Object? progressivePush = null,Object? dailyBriefingPush = null,Object? importantChangesPush = null,Object? notifyChangeCancellations = null,Object? notifyChangeRoom = null,Object? notifyChangeTeacher = null,Object? notifyChangeOther = null,Object? blurEnabled = null,Object? blurStrength = null,Object? surfaceBlurEnabled = null,Object? surfaceCornerMode = null,Object? surfaceCornerRadius = null,Object? appBgBlurEnabled = null,Object? appBgBlurAmount = null,Object? pageTransition = null,Object? mainTabFadeUpEnabled = null,Object? useMaterialYou = null,Object? isAmoled = null,Object? customColorSeed = null,Object? appIcon = null,Object? lessonCardStyle = null,Object? glowEffectsEnabled = null,Object? lessonBlurEnabled = null,Object? lessonBlurAmount = null,Object? lessonCardOpacity = null,Object? lessonBorderRadius = null,Object? lessonAccentStyle = null,Object? lessonShowTeacher = null,Object? lessonShowSubjectIcons = null,Object? lessonShowRoom = null,Object? lessonCompactMode = null,Object? lessonDimPast = null,Object? lessonCancelledPattern = null,Object? showFullTeacherNames = null,Object? timetableDaySpan = null,Object? swipeBackGesture = null,Object? aiProvider = null,Object? aiModel = null,Object? aiSystemPromptTemplate = null,Object? aiCustomBaseUrl = null,Object? aiCustomCompatibility = null,Object? aiLocalModelPath = null,Object? aiTemperature = null,Object? aiMaxTokens = null,Object? aiTopP = null,Object? aiPersona = null,Object? geminiApiKey = null,Object? openAiApiKey = null,Object? mistralApiKey = null,Object? customAiApiKey = null,Object? hiddenSubjects = null,Object? subjectColors = null,Object? knownSubjects = null,Object? customHomework = null,Object? customExams = null,Object? customGrades = null,Object? currentWeekData = null,Object? homeworks = null,Object? lessonNotes = null,Object? apiExams = null,Object? unreadTimetableChanges = null,Object? unreadInboxMessages = null,Object? pendingTimetableAction = freezed,Object? pendingTimetableCurrentLesson = freezed,Object? pendingTimetableNextLesson = freezed,Object? pendingChangeHighlightDate = freezed,Object? pendingChangeHighlightStartTime = freezed,Object? pendingAssistantOpen = null,Object? pendingAssistantPrompt = freezed,Object? defaultClassId = freezed,Object? defaultClassName = freezed,Object? favoriteClassIds = null,}) {
  return _then(_AppState(
appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,appBuildNumber: null == appBuildNumber ? _self.appBuildNumber : appBuildNumber // ignore: cast_nullable_to_non_nullable
as String,showChangelogOnStartup: null == showChangelogOnStartup ? _self.showChangelogOnStartup : showChangelogOnStartup // ignore: cast_nullable_to_non_nullable
as bool,sessionID: null == sessionID ? _self.sessionID : sessionID // ignore: cast_nullable_to_non_nullable
as String,schoolUrl: null == schoolUrl ? _self.schoolUrl : schoolUrl // ignore: cast_nullable_to_non_nullable
as String,schoolName: null == schoolName ? _self.schoolName : schoolName // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as int,personType: null == personType ? _self.personType : personType // ignore: cast_nullable_to_non_nullable
as int,untisAccounts: null == untisAccounts ? _self._untisAccounts : untisAccounts // ignore: cast_nullable_to_non_nullable
as List<UntisAccount>,activeUntisAccountId: freezed == activeUntisAccountId ? _self.activeUntisAccountId : activeUntisAccountId // ignore: cast_nullable_to_non_nullable
as String?,demoMode: null == demoMode ? _self.demoMode : demoMode // ignore: cast_nullable_to_non_nullable
as bool,appLocale: null == appLocale ? _self.appLocale : appLocale // ignore: cast_nullable_to_non_nullable
as String,themeMode: freezed == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,visualTheme: freezed == visualTheme ? _self.visualTheme : visualTheme // ignore: cast_nullable_to_non_nullable
as AppThemeId,themeBlurPreferences: null == themeBlurPreferences ? _self._themeBlurPreferences : themeBlurPreferences // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,showCancelled: null == showCancelled ? _self.showCancelled : showCancelled // ignore: cast_nullable_to_non_nullable
as bool,timetableSwitchAnimation: null == timetableSwitchAnimation ? _self.timetableSwitchAnimation : timetableSwitchAnimation // ignore: cast_nullable_to_non_nullable
as int,cancelledLessonColor: null == cancelledLessonColor ? _self.cancelledLessonColor : cancelledLessonColor // ignore: cast_nullable_to_non_nullable
as int,monochromeLessons: null == monochromeLessons ? _self.monochromeLessons : monochromeLessons // ignore: cast_nullable_to_non_nullable
as bool,monochromeLessonColor: null == monochromeLessonColor ? _self.monochromeLessonColor : monochromeLessonColor // ignore: cast_nullable_to_non_nullable
as int,backgroundAnimations: null == backgroundAnimations ? _self.backgroundAnimations : backgroundAnimations // ignore: cast_nullable_to_non_nullable
as bool,backgroundAnimationStyle: null == backgroundAnimationStyle ? _self.backgroundAnimationStyle : backgroundAnimationStyle // ignore: cast_nullable_to_non_nullable
as int,backgroundGyroscope: null == backgroundGyroscope ? _self.backgroundGyroscope : backgroundGyroscope // ignore: cast_nullable_to_non_nullable
as bool,progressivePush: null == progressivePush ? _self.progressivePush : progressivePush // ignore: cast_nullable_to_non_nullable
as bool,dailyBriefingPush: null == dailyBriefingPush ? _self.dailyBriefingPush : dailyBriefingPush // ignore: cast_nullable_to_non_nullable
as bool,importantChangesPush: null == importantChangesPush ? _self.importantChangesPush : importantChangesPush // ignore: cast_nullable_to_non_nullable
as bool,notifyChangeCancellations: null == notifyChangeCancellations ? _self.notifyChangeCancellations : notifyChangeCancellations // ignore: cast_nullable_to_non_nullable
as bool,notifyChangeRoom: null == notifyChangeRoom ? _self.notifyChangeRoom : notifyChangeRoom // ignore: cast_nullable_to_non_nullable
as bool,notifyChangeTeacher: null == notifyChangeTeacher ? _self.notifyChangeTeacher : notifyChangeTeacher // ignore: cast_nullable_to_non_nullable
as bool,notifyChangeOther: null == notifyChangeOther ? _self.notifyChangeOther : notifyChangeOther // ignore: cast_nullable_to_non_nullable
as bool,blurEnabled: null == blurEnabled ? _self.blurEnabled : blurEnabled // ignore: cast_nullable_to_non_nullable
as bool,blurStrength: null == blurStrength ? _self.blurStrength : blurStrength // ignore: cast_nullable_to_non_nullable
as double,surfaceBlurEnabled: null == surfaceBlurEnabled ? _self.surfaceBlurEnabled : surfaceBlurEnabled // ignore: cast_nullable_to_non_nullable
as bool,surfaceCornerMode: null == surfaceCornerMode ? _self.surfaceCornerMode : surfaceCornerMode // ignore: cast_nullable_to_non_nullable
as int,surfaceCornerRadius: null == surfaceCornerRadius ? _self.surfaceCornerRadius : surfaceCornerRadius // ignore: cast_nullable_to_non_nullable
as int,appBgBlurEnabled: null == appBgBlurEnabled ? _self.appBgBlurEnabled : appBgBlurEnabled // ignore: cast_nullable_to_non_nullable
as bool,appBgBlurAmount: null == appBgBlurAmount ? _self.appBgBlurAmount : appBgBlurAmount // ignore: cast_nullable_to_non_nullable
as double,pageTransition: null == pageTransition ? _self.pageTransition : pageTransition // ignore: cast_nullable_to_non_nullable
as int,mainTabFadeUpEnabled: null == mainTabFadeUpEnabled ? _self.mainTabFadeUpEnabled : mainTabFadeUpEnabled // ignore: cast_nullable_to_non_nullable
as bool,useMaterialYou: null == useMaterialYou ? _self.useMaterialYou : useMaterialYou // ignore: cast_nullable_to_non_nullable
as bool,isAmoled: null == isAmoled ? _self.isAmoled : isAmoled // ignore: cast_nullable_to_non_nullable
as bool,customColorSeed: null == customColorSeed ? _self.customColorSeed : customColorSeed // ignore: cast_nullable_to_non_nullable
as int,appIcon: null == appIcon ? _self.appIcon : appIcon // ignore: cast_nullable_to_non_nullable
as String,lessonCardStyle: null == lessonCardStyle ? _self.lessonCardStyle : lessonCardStyle // ignore: cast_nullable_to_non_nullable
as int,glowEffectsEnabled: null == glowEffectsEnabled ? _self.glowEffectsEnabled : glowEffectsEnabled // ignore: cast_nullable_to_non_nullable
as bool,lessonBlurEnabled: null == lessonBlurEnabled ? _self.lessonBlurEnabled : lessonBlurEnabled // ignore: cast_nullable_to_non_nullable
as bool,lessonBlurAmount: null == lessonBlurAmount ? _self.lessonBlurAmount : lessonBlurAmount // ignore: cast_nullable_to_non_nullable
as double,lessonCardOpacity: null == lessonCardOpacity ? _self.lessonCardOpacity : lessonCardOpacity // ignore: cast_nullable_to_non_nullable
as double,lessonBorderRadius: null == lessonBorderRadius ? _self.lessonBorderRadius : lessonBorderRadius // ignore: cast_nullable_to_non_nullable
as double,lessonAccentStyle: null == lessonAccentStyle ? _self.lessonAccentStyle : lessonAccentStyle // ignore: cast_nullable_to_non_nullable
as int,lessonShowTeacher: null == lessonShowTeacher ? _self.lessonShowTeacher : lessonShowTeacher // ignore: cast_nullable_to_non_nullable
as bool,lessonShowSubjectIcons: null == lessonShowSubjectIcons ? _self.lessonShowSubjectIcons : lessonShowSubjectIcons // ignore: cast_nullable_to_non_nullable
as bool,lessonShowRoom: null == lessonShowRoom ? _self.lessonShowRoom : lessonShowRoom // ignore: cast_nullable_to_non_nullable
as bool,lessonCompactMode: null == lessonCompactMode ? _self.lessonCompactMode : lessonCompactMode // ignore: cast_nullable_to_non_nullable
as bool,lessonDimPast: null == lessonDimPast ? _self.lessonDimPast : lessonDimPast // ignore: cast_nullable_to_non_nullable
as bool,lessonCancelledPattern: null == lessonCancelledPattern ? _self.lessonCancelledPattern : lessonCancelledPattern // ignore: cast_nullable_to_non_nullable
as bool,showFullTeacherNames: null == showFullTeacherNames ? _self.showFullTeacherNames : showFullTeacherNames // ignore: cast_nullable_to_non_nullable
as bool,timetableDaySpan: null == timetableDaySpan ? _self.timetableDaySpan : timetableDaySpan // ignore: cast_nullable_to_non_nullable
as int,swipeBackGesture: null == swipeBackGesture ? _self.swipeBackGesture : swipeBackGesture // ignore: cast_nullable_to_non_nullable
as bool,aiProvider: null == aiProvider ? _self.aiProvider : aiProvider // ignore: cast_nullable_to_non_nullable
as String,aiModel: null == aiModel ? _self.aiModel : aiModel // ignore: cast_nullable_to_non_nullable
as String,aiSystemPromptTemplate: null == aiSystemPromptTemplate ? _self.aiSystemPromptTemplate : aiSystemPromptTemplate // ignore: cast_nullable_to_non_nullable
as String,aiCustomBaseUrl: null == aiCustomBaseUrl ? _self.aiCustomBaseUrl : aiCustomBaseUrl // ignore: cast_nullable_to_non_nullable
as String,aiCustomCompatibility: null == aiCustomCompatibility ? _self.aiCustomCompatibility : aiCustomCompatibility // ignore: cast_nullable_to_non_nullable
as String,aiLocalModelPath: null == aiLocalModelPath ? _self.aiLocalModelPath : aiLocalModelPath // ignore: cast_nullable_to_non_nullable
as String,aiTemperature: null == aiTemperature ? _self.aiTemperature : aiTemperature // ignore: cast_nullable_to_non_nullable
as double,aiMaxTokens: null == aiMaxTokens ? _self.aiMaxTokens : aiMaxTokens // ignore: cast_nullable_to_non_nullable
as int,aiTopP: null == aiTopP ? _self.aiTopP : aiTopP // ignore: cast_nullable_to_non_nullable
as double,aiPersona: null == aiPersona ? _self.aiPersona : aiPersona // ignore: cast_nullable_to_non_nullable
as String,geminiApiKey: null == geminiApiKey ? _self.geminiApiKey : geminiApiKey // ignore: cast_nullable_to_non_nullable
as String,openAiApiKey: null == openAiApiKey ? _self.openAiApiKey : openAiApiKey // ignore: cast_nullable_to_non_nullable
as String,mistralApiKey: null == mistralApiKey ? _self.mistralApiKey : mistralApiKey // ignore: cast_nullable_to_non_nullable
as String,customAiApiKey: null == customAiApiKey ? _self.customAiApiKey : customAiApiKey // ignore: cast_nullable_to_non_nullable
as String,hiddenSubjects: null == hiddenSubjects ? _self._hiddenSubjects : hiddenSubjects // ignore: cast_nullable_to_non_nullable
as Set<String>,subjectColors: null == subjectColors ? _self._subjectColors : subjectColors // ignore: cast_nullable_to_non_nullable
as Map<String, int>,knownSubjects: null == knownSubjects ? _self._knownSubjects : knownSubjects // ignore: cast_nullable_to_non_nullable
as Set<String>,customHomework: null == customHomework ? _self._customHomework : customHomework // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,customExams: null == customExams ? _self._customExams : customExams // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,customGrades: null == customGrades ? _self._customGrades : customGrades // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,currentWeekData: null == currentWeekData ? _self._currentWeekData : currentWeekData // ignore: cast_nullable_to_non_nullable
as Map<int, List<dynamic>>,homeworks: null == homeworks ? _self._homeworks : homeworks // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,lessonNotes: null == lessonNotes ? _self._lessonNotes : lessonNotes // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,apiExams: null == apiExams ? _self._apiExams : apiExams // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,unreadTimetableChanges: null == unreadTimetableChanges ? _self.unreadTimetableChanges : unreadTimetableChanges // ignore: cast_nullable_to_non_nullable
as int,unreadInboxMessages: null == unreadInboxMessages ? _self.unreadInboxMessages : unreadInboxMessages // ignore: cast_nullable_to_non_nullable
as int,pendingTimetableAction: freezed == pendingTimetableAction ? _self.pendingTimetableAction : pendingTimetableAction // ignore: cast_nullable_to_non_nullable
as String?,pendingTimetableCurrentLesson: freezed == pendingTimetableCurrentLesson ? _self.pendingTimetableCurrentLesson : pendingTimetableCurrentLesson // ignore: cast_nullable_to_non_nullable
as String?,pendingTimetableNextLesson: freezed == pendingTimetableNextLesson ? _self.pendingTimetableNextLesson : pendingTimetableNextLesson // ignore: cast_nullable_to_non_nullable
as String?,pendingChangeHighlightDate: freezed == pendingChangeHighlightDate ? _self.pendingChangeHighlightDate : pendingChangeHighlightDate // ignore: cast_nullable_to_non_nullable
as int?,pendingChangeHighlightStartTime: freezed == pendingChangeHighlightStartTime ? _self.pendingChangeHighlightStartTime : pendingChangeHighlightStartTime // ignore: cast_nullable_to_non_nullable
as int?,pendingAssistantOpen: null == pendingAssistantOpen ? _self.pendingAssistantOpen : pendingAssistantOpen // ignore: cast_nullable_to_non_nullable
as bool,pendingAssistantPrompt: freezed == pendingAssistantPrompt ? _self.pendingAssistantPrompt : pendingAssistantPrompt // ignore: cast_nullable_to_non_nullable
as String?,defaultClassId: freezed == defaultClassId ? _self.defaultClassId : defaultClassId // ignore: cast_nullable_to_non_nullable
as int?,defaultClassName: freezed == defaultClassName ? _self.defaultClassName : defaultClassName // ignore: cast_nullable_to_non_nullable
as String?,favoriteClassIds: null == favoriteClassIds ? _self._favoriteClassIds : favoriteClassIds // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}


}

// dart format on
