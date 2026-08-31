// ─────────────────────────────────────────────────────────────────────────────
// Untis+ App Localization
// Supported locales: de (German), en (English), fr (French), es (Spanish)
// ─────────────────────────────────────────────────────────────────────────────

class AppL10n {
  final String locale;
  const AppL10n._(this.locale);

  static const supportedLocales = ['de', 'en', 'fr', 'es'];

  static AppL10n of(String locale) =>
      AppL10n._(supportedLocales.contains(locale) ? locale : 'de');

  String _t(String key) => _strings[locale]?[key] ?? _strings['de']![key]!;

  // ── Navigation ──────────────────────────────────────────────────────────────
  String get navWeek => _t('navWeek');
  String get navHomework => _t('navHomework');
  String get navExams => _t('navExams');
  String get navInfo => _t('navInfo');
  String get navMenu => _t('navMenu');

  // ── Login ───────────────────────────────────────────────────────────────────
  String get loginServer => _t('loginServer');
  String get loginSchool => _t('loginSchool');
  String get loginUsername => _t('loginUsername');
  String get loginPassword => _t('loginPassword');
  String get loginLoginKey => _t('loginLoginKey');
  String get loginLoginKeyHint => _t('loginLoginKeyHint');
  String get loginCredentialModePassword => _t('loginCredentialModePassword');
  String get loginCredentialModeLoginKey => _t('loginCredentialModeLoginKey');
  String get loginButton => _t('loginButton');
  String get loginFailed => _t('loginFailed');
  String get loginConnectionError => _t('loginConnectionError');
  String get loginSearchSchool => _t('loginSearchSchool');
  String get loginSelectSchool => _t('loginSelectSchool');
  String get loginSearchHint => _t('loginSearchHint');
  String get loginNoSchoolsFound => _t('loginNoSchoolsFound');
  String get loginChangeLanguage => _t('loginChangeLanguage');
  String get loginManualEntry => _t('loginManualEntry');
  String get loginSwitchToSearch => _t('loginSwitchToSearch');
  String get loginChangeSchool => _t('loginChangeSchool');
  String get loginTwoFactorCode => _t('loginTwoFactorCode');
  String get loginTwoFactorHint => _t('loginTwoFactorHint');
  String get loginTwoFactorRequired => _t('loginTwoFactorRequired');
  String get loginTwoFactorInvalid => _t('loginTwoFactorInvalid');
  String get loginVerifyButton => _t('loginVerifyButton');

  // ── Onboarding ─────────────────────────────────────────────────────────────
  String get onboardingWelcomeTitle => _t('onboardingWelcomeTitle');
  String get onboardingChooseLanguageSubtitle =>
      _t('onboardingChooseLanguageSubtitle');
  String get onboardingAppearanceTitle => _t('onboardingAppearanceTitle');
  String get onboardingAppearanceSubtitle => _t('onboardingAppearanceSubtitle');
  String get onboardingThemeSystem => _t('onboardingThemeSystem');
  String get onboardingThemeLight => _t('onboardingThemeLight');
  String get onboardingThemeDark => _t('onboardingThemeDark');
  String get onboardingAnimationsHint => _t('onboardingAnimationsHint');
  String get onboardingSchoolLoginTitle => _t('onboardingSchoolLoginTitle');
  String get onboardingSchoolLoginSubtitle =>
      _t('onboardingSchoolLoginSubtitle');
  String get onboardingGeminiTitle => _t('onboardingGeminiTitle');
  String get onboardingGeminiSubtitle => _t('onboardingGeminiSubtitle');
  String get onboardingGeminiInfo => _t('onboardingGeminiInfo');
  String get onboardingGeminiGetApiKey => _t('onboardingGeminiGetApiKey');
  String get onboardingSkip => _t('onboardingSkip');
  String get onboardingNext => _t('onboardingNext');
  String get onboardingGeminiEnterKeyOrSkip =>
      _t('onboardingGeminiEnterKeyOrSkip');
  String get onboardingReadyTitle => _t('onboardingReadyTitle');
  String get onboardingReadySubtitle => _t('onboardingReadySubtitle');
  String get onboardingFeatureTimetableTitle =>
      _t('onboardingFeatureTimetableTitle');
  String get onboardingFeatureTimetableDesc =>
      _t('onboardingFeatureTimetableDesc');
  String get onboardingFeatureExamsTitle => _t('onboardingFeatureExamsTitle');
  String get onboardingFeatureExamsDesc => _t('onboardingFeatureExamsDesc');
  String get onboardingFeatureAiTitle => _t('onboardingFeatureAiTitle');
  String get onboardingFeatureAiDesc => _t('onboardingFeatureAiDesc');
  String get onboardingFeatureNotifyTitle => _t('onboardingFeatureNotifyTitle');
  String get onboardingFeatureNotifyDesc => _t('onboardingFeatureNotifyDesc');
  String get onboardingFinishSetup => _t('onboardingFinishSetup');
  String get onboardingUseDemoMode => _t('onboardingUseDemoMode');
  String get onboardingUseDemoModeDesc => _t('onboardingUseDemoModeDesc');
  String get tutorialTitle => _t('tutorialTitle');
  String get tutorialSkip => _t('tutorialSkip');
  String get tutorialDone => _t('tutorialDone');
  String get tutorialStepWeekTitle => _t('tutorialStepWeekTitle');
  String get tutorialStepWeekDesc => _t('tutorialStepWeekDesc');
  String get tutorialStepExamsTitle => _t('tutorialStepExamsTitle');
  String get tutorialStepExamsDesc => _t('tutorialStepExamsDesc');
  String get tutorialStepInfoTitle => _t('tutorialStepInfoTitle');
  String get tutorialStepInfoDesc => _t('tutorialStepInfoDesc');
  String get tutorialStepSettingsTitle => _t('tutorialStepSettingsTitle');
  String get tutorialStepSettingsDesc => _t('tutorialStepSettingsDesc');
  String get tutorialStepFinishTitle => _t('tutorialStepFinishTitle');
  String get tutorialStepFinishDesc => _t('tutorialStepFinishDesc');

  // ── Timetable ───────────────────────────────────────────────────────────────
  String get timetableTitle => _t('timetableTitle');
  String get timetablePrevWeek => _t('timetablePrevWeek');
  String get timetableNextWeek => _t('timetableNextWeek');
  String get timetableWeekView => _t('timetableWeekView');
  String get timetableDayGrid => _t('timetableDayGrid');
  String get timetableNotLoaded => _t('timetableNotLoaded');
  String get timetableReload => _t('timetableReload');
  String get timetableSelectClass => _t('timetableSelectClass');
  String get timetableMyTimetable => _t('timetableMyTimetable');
  String get timetableSelectAnother => _t('timetableSelectAnother');
  String get timetableNoClassesFound => _t('timetableNoClassesFound');
  String get freeRoomsTitle => _t('freeRoomsTitle');
  String get freeRoomsSelectTime => _t('freeRoomsSelectTime');
  String get freeRoomsNoneFound => _t('freeRoomsNoneFound');
  String get freeRoomsNoRangesHint => _t('freeRoomsNoRangesHint');
  String freeRoomsCount(int n) => _t('freeRoomsCount').replaceAll('{n}', '$n');
  List<String> get weekDayShort =>
      List<String>.from(_strings[locale]!['weekDayShort'] as List);
  List<String> get weekDayFull =>
      List<String>.from(_strings[locale]!['weekDayFull'] as List);
  String get noLesson => _t('noLesson');

  // ── Lesson Detail ───────────────────────────────────────────────────────────
  String get detailTime => _t('detailTime');
  String get detailTeacher => _t('detailTeacher');
  String get detailRoom => _t('detailRoom');
  String get detailClass => _t('detailClass');
  String get detailLesson => _t('detailLesson');
  String get detailInfo => _t('detailInfo');
  String get detailNotesForStudents => _t('detailNotesForStudents');
  String get detailLessonNotes => _t('detailLessonNotes');
  String get detailHomework => _t('detailHomework');
  String get detailCancelled => _t('detailCancelled');
  String get detailRegular => _t('detailRegular');
  String get detailHideSubject => _t('detailHideSubject');
  String get detailCancelledBadge => _t('detailCancelledBadge');

  // ── Exams ───────────────────────────────────────────────────────────────────
  String get examsTitle => _t('examsTitle');
  String get examsReload => _t('examsReload');
  String get examsNone => _t('examsNone');
  String get examsNoneHint => _t('examsNoneHint');
  String get examsUpcoming => _t('examsUpcoming');
  String get examsPast => _t('examsPast');
  String get examsAdd => _t('examsAdd');
  String get examsAddTitle => _t('examsAddTitle');
  String get examsEditTitle => _t('examsEditTitle');
  String get examsSubjectLabel => _t('examsSubjectLabel');
  String get examsTypeLabel => _t('examsTypeLabel');
  String get examsNotesLabel => _t('examsNotesLabel');
  String get examsSave => _t('examsSave');
  String get examsCancel => _t('examsCancel');
  String get examsDelete => _t('examsDelete');
  String get examsToday => _t('examsToday');
  String get examsTomorrow => _t('examsTomorrow');

  // ── Homework ────────────────────────────────────────────────────────────────
  String get homeworkTitle => _t('homeworkTitle');
  String get homeworkReload => _t('homeworkReload');
  String get homeworkNone => _t('homeworkNone');
  String get homeworkNoneHint => _t('homeworkNoneHint');
  String get homeworkMarkDone => _t('homeworkMarkDone');
  String get homeworkMarkUndone => _t('homeworkMarkUndone');
  String get homeworkDue => _t('homeworkDue');
  String get navGrades => _t('navGrades');
  String get gradesTitle => _t('gradesTitle');
  String get gradesAddTitle => _t('gradesAddTitle');
  String get gradesEditTitle => _t('gradesEditTitle');
  String get gradesSubjectLabel => _t('gradesSubjectLabel');
  String get gradesGradeLabel => _t('gradesGradeLabel');
  String get gradesWeightLabel => _t('gradesWeightLabel');
  String get gradesTypeLabel => _t('gradesTypeLabel');
  String get gradesAverage => _t('gradesAverage');
  String get gradesTotal => _t('gradesTotal');
  String get gradesBestSubject => _t('gradesBestSubject');
  String get gradesAddDesc => _t('gradesAddDesc');
  String get gradesCountPlural => _t('gradesCountPlural');
  String get gradesWeightLabelShort => _t('gradesWeightLabelShort');
  String get gradesNone => _t('gradesNone');
  String get gradesNoneHint => _t('gradesNoneHint');
  String get examsOwn => _t('examsOwn');
  String get examsUnknown => _t('examsUnknown');
  String get examsNoneEntered => _t('examsNoneEntered');
  String get examsImportTitle => _t('examsImportTitle');
  String get examsImportCamera => _t('examsImportCamera');
  String get examsImportGallery => _t('examsImportGallery');
  String get examsImportFile => _t('examsImportFile');
  String get examsImportSuccess => _t('examsImportSuccess');
  String get examsImportError => _t('examsImportError');
  String get examsImportInvalidJson => _t('examsImportInvalidJson');
  String get examsExportSuccess => _t('examsExportSuccess');
  String get examsExportEmpty => _t('examsExportEmpty');
  String get examsActionCustom => _t('examsActionCustom');
  String get examsActionImport => _t('examsActionImport');
  String get examsActionExport => _t('examsActionExport');
  String get examsActionScan => _t('examsActionScan');
  String examsInDays(int n) => _t('examsDaysIn').replaceAll('{n}', '$n');

  // ── School Info / Notifications ────────────────────────────────────────────
  String get infoTitle => _t('infoTitle');
  String get infoReload => _t('infoReload');
  String get infoUpdated => _t('infoUpdated');
  String get infoEmpty => _t('infoEmpty');
  String get infoEmptyHint => _t('infoEmptyHint');
  String get infoFetchError => _t('infoFetchError');
  String get infoOpenLink => _t('infoOpenLink');
    String get navAi => _t('navAi');
  String notificationActionCurrentLesson(String lesson) =>
      _t('notificationActionCurrentLesson').replaceAll('{lesson}', lesson);
  String notificationActionNextLesson(String lesson) =>
      _t('notificationActionNextLesson').replaceAll('{lesson}', lesson);
  String get notificationActionNoNextLesson =>
      _t('notificationActionNoNextLesson');

  // ── AI Chat ─────────────────────────────────────────────────────────────────
  String get aiInputHint => _t('aiInputHint');
  String get aiKnowsSchedule => _t('aiKnowsSchedule');
  String get aiAskAnything => _t('aiAskAnything');
  String get aiNoApiKey => _t('aiNoApiKey');
  String get aiNoReply => _t('aiNoReply');
  String get aiApiError => _t('aiApiError');
  String get aiConnectionError => _t('aiConnectionError');
  String get aiCustomBaseUrlMissing => _t('aiCustomBaseUrlMissing');
  List<String> get aiSuggestions =>
      List<String>.from(_strings[locale]!['aiSuggestions'] as List);

  // ── Settings ─────────────────────────────────────────────────────────────────
  String get settingsTitle => _t('settingsTitle');
  String get settingsLoggedInAs => _t('settingsLoggedInAs');
  String get settingsLogout => _t('settingsLogout');
  String get settingsSectionQuick => _t('settingsSectionQuick');
  String get settingsSectionGeneral => _t('settingsSectionGeneral');
  String get settingsAppearance => _t('settingsAppearance');
  String get settingsAppearanceDesc => _t('settingsAppearanceDesc');
  String get settingsHubNotifications => _t('settingsHubNotifications');
  String get settingsHubDataBackup => _t('settingsHubDataBackup');
  String get settingsHubDataBackupDesc => _t('settingsHubDataBackupDesc');
  String get settingsHubAccount => _t('settingsHubAccount');
  String get settingsHubUpdatesAbout => _t('settingsHubUpdatesAbout');
  String get settingsLanguage => _t('settingsLanguage');
  String get settingsSectionAI => _t('settingsSectionAI');
  String get settingsAiProvider => _t('settingsAiProvider');
  String get settingsAiProviderGemini => _t('settingsAiProviderGemini');
  String get settingsAiProviderOpenAi => _t('settingsAiProviderOpenAi');
  String get settingsAiProviderMistral => _t('settingsAiProviderMistral');
  String get settingsAiProviderCustom => _t('settingsAiProviderCustom');
  String get settingsAiModel => _t('settingsAiModel');
  String get settingsAiApiKey => _t('settingsAiApiKey');
  String get settingsAiApiKeyNotSet => _t('settingsAiApiKeyNotSet');
  String get settingsAiApiKeyDialogDesc => _t('settingsAiApiKeyDialogDesc');
  String get settingsAiApiKeyGet => _t('settingsAiApiKeyGet');
  String get settingsAiApiKeyOpenFailed => _t('settingsAiApiKeyOpenFailed');
  String get settingsAiPrompt => _t('settingsAiPrompt');
  String get settingsAiPromptDesc => _t('settingsAiPromptDesc');
  String get settingsAiPromptEditTitle => _t('settingsAiPromptEditTitle');
  String get settingsAiPromptReset => _t('settingsAiPromptReset');
  String get settingsAiPromptVariables => _t('settingsAiPromptVariables');
  String get settingsAiPromptVariablesDesc =>
      _t('settingsAiPromptVariablesDesc');
  Map<String, String> get aiPromptVariableDescriptions => {
    '[today]': _t('aiVar_today'),
    '[today_iso]': _t('aiVar_today_iso'),
    '[locale]': _t('aiVar_locale'),
    '[school_name]': _t('aiVar_school_name'),
    '[school_url]': _t('aiVar_school_url'),
    '[person_type]': _t('aiVar_person_type'),
    '[person_id]': _t('aiVar_person_id'),
    '[demo_mode]': _t('aiVar_demo_mode'),
    '[current_monday]': _t('aiVar_current_monday'),
    '[current_friday]': _t('aiVar_current_friday'),
    '[day_summary_today]': _t('aiVar_day_summary_today'),
    '[day_summary_tomorrow]': _t('aiVar_day_summary_tomorrow'),
    '[timetable]': _t('aiVar_timetable'),
    '[timetable_json]': _t('aiVar_timetable_json'),
    '[exams]': _t('aiVar_exams'),
    '[exams_json]': _t('aiVar_exams_json'),
    '[current_lesson]': 'Informationen zur aktuellen Stunde',
    '[next_lesson]': 'Informationen zur nächsten Stunde',
  };
  String get settingsAiCustomBaseUrl => _t('settingsAiCustomBaseUrl');
  String get settingsAiCustomBaseUrlDesc => _t('settingsAiCustomBaseUrlDesc');
  String get settingsAiCustomBaseUrlHint => _t('settingsAiCustomBaseUrlHint');
  String get settingsAiCompatibility => _t('settingsAiCompatibility');
  String get settingsAiCompatibilityOpenAi =>
      _t('settingsAiCompatibilityOpenAi');
  String get settingsAiCompatibilityGemini =>
      _t('settingsAiCompatibilityGemini');
  String get settingsAiProviderLocal => _t('settingsAiProviderLocal');
  String get settingsAiLocalModel => _t('settingsAiLocalModel');
  String get settingsAiLocalModelDesc => _t('settingsAiLocalModelDesc');
  String get settingsAiLocalModelDownload => _t('settingsAiLocalModelDownload');
  String get settingsAiLocalModelDownloading => _t('settingsAiLocalModelDownloading');
  String get settingsAiLocalModelInstalled => _t('settingsAiLocalModelInstalled');
  String get settingsAiLocalModelDelete => _t('settingsAiLocalModelDelete');
  String get settingsAiLocalModelActive => _t('settingsAiLocalModelActive');
  String get settingsAiLocalModelError => _t('settingsAiLocalModelError');
  String get aiLocalModelExamNotSupported =>
      _t('aiLocalModelExamNotSupported');
  String get aiLocalModelLoadError => _t('aiLocalModelLoadError');
  String settingsAiLocalModelSize(double size) =>
      _t('settingsAiLocalModelSize').replaceAll('{size}', size.toString());
  String get settingsAiLocalModelDeleteConfirm =>
      _t('settingsAiLocalModelDeleteConfirm');
  String get settingsApiKey => _t('settingsApiKey');
  String get settingsApiKeyNotSet => _t('settingsApiKeyNotSet');
  String get settingsApiKeyDialogTitle => _t('settingsApiKeyDialogTitle');
  String get settingsApiKeyDialogDesc => _t('settingsApiKeyDialogDesc');
  String get settingsApiKeySave => _t('settingsApiKeySave');
  String get settingsApiKeyRemove => _t('settingsApiKeyRemove');
  String get settingsApiKeyCancel => _t('settingsApiKeyCancel');
  String get settingsSectionHidden => _t('settingsSectionHidden');
  String get settingsNoHidden => _t('settingsNoHidden');
  String get settingsNoHiddenDesc => _t('settingsNoHiddenDesc');
  String get settingsUnhide => _t('settingsUnhide');
  String settingsHiddenCount(int n) =>
      _t('settingsHiddenCount').replaceAll('{n}', '$n');
  String get settingsSectionColors => _t('settingsSectionColors');
  String get settingsColorsDesc => _t('settingsColorsDesc');
  String get settingsNoSubjectsLoaded => _t('settingsNoSubjectsLoaded');
  String get settingsNoSubjectsLoadedDesc => _t('settingsNoSubjectsLoadedDesc');
  String get settingsCustomColor => _t('settingsCustomColor');
  String get settingsDefaultColor => _t('settingsDefaultColor');
  String settingsColorFor(String s) =>
      _t('settingsColorFor').replaceAll('{s}', s);
  String get settingsColorReset => _t('settingsColorReset');
  String get settingsColorCustomPicker => _t('settingsColorCustomPicker');
  String get settingsColorApply => _t('settingsColorApply');
  String get settingsColorRed => _t('settingsColorRed');
  String get settingsColorGreen => _t('settingsColorGreen');
  String get settingsColorBlue => _t('settingsColorBlue');
  String get settingsThemeMode => _t('settingsThemeMode');
  String get settingsThemeLight => _t('settingsThemeLight');
  String get settingsThemeSystem => _t('settingsThemeSystem');
  String get settingsThemeDark => _t('settingsThemeDark');
  String get settingsSectionTimetable => _t('settingsSectionTimetable');
  String get settingsShowCancelled => _t('settingsShowCancelled');
  String get settingsShowCancelledDesc => _t('settingsShowCancelledDesc');
  String get settingsCancelledColor => _t('settingsCancelledColor');
  String get settingsCancelledColorDesc => _t('settingsCancelledColorDesc');
  String get settingsLessonDesignTitle => _t('settingsLessonDesignTitle');
  String get settingsLessonDesignDesc => _t('settingsLessonDesignDesc');
  String get settingsLessonStyle => _t('settingsLessonStyle');
  String get settingsLessonStyleDesc => _t('settingsLessonStyleDesc');
  String get settingsLessonStyleModern => _t('settingsLessonStyleModern');
  String get settingsLessonStyleGlass => _t('settingsLessonStyleGlass');
  String get settingsLessonStyleGradient => _t('settingsLessonStyleGradient');
  String get settingsLessonStyleOutline => _t('settingsLessonStyleOutline');
  String get settingsLessonStyleSolid => _t('settingsLessonStyleSolid');
  String get settingsLessonGlow => _t('settingsLessonGlow');
  String get settingsLessonGlowDesc => _t('settingsLessonGlowDesc');
  String get settingsLessonGlowMode => _t('settingsLessonGlowMode');
  String get settingsLessonGlowModeActive => _t('settingsLessonGlowModeActive');
  String get settingsLessonGlowModeAll => _t('settingsLessonGlowModeAll');
  String get settingsLessonGlowIntensity => _t('settingsLessonGlowIntensity');
  String get settingsLessonBlur => _t('settingsLessonBlur');
  String get settingsLessonBlurDesc => _t('settingsLessonBlurDesc');
  String get settingsLessonBlurAmount => _t('settingsLessonBlurAmount');
  String get settingsLessonCardOpacity => _t('settingsLessonCardOpacity');
  String get settingsLessonBorderRadius => _t('settingsLessonBorderRadius');
  String get settingsLessonAccentStyle => _t('settingsLessonAccentStyle');
  String get settingsLessonAccentBar => _t('settingsLessonAccentBar');
  String get settingsLessonAccentThin => _t('settingsLessonAccentThin');
  String get settingsLessonAccentDot => _t('settingsLessonAccentDot');
  String get settingsLessonAccentNone => _t('settingsLessonAccentNone');
  String get settingsLessonShowTeacher => _t('settingsLessonShowTeacher');
  String get settingsLessonShowTeacherDesc => _t('settingsLessonShowTeacherDesc');
  String get settingsLessonShowRoom => _t('settingsLessonShowRoom');
  String get settingsLessonShowRoomDesc => _t('settingsLessonShowRoomDesc');
  String get settingsLessonCompactMode => _t('settingsLessonCompactMode');
  String get settingsLessonCompactModeDesc => _t('settingsLessonCompactModeDesc');
  String get settingsLessonDimPast => _t('settingsLessonDimPast');
  String get settingsLessonDimPastDesc => _t('settingsLessonDimPastDesc');
  String get settingsLessonCancelledPattern => _t('settingsLessonCancelledPattern');
  String get settingsLessonCancelledPatternDesc => _t('settingsLessonCancelledPatternDesc');
  String get settingsLessonPreviewRegular => _t('settingsLessonPreviewRegular');
  String get settingsLessonPreviewActive => _t('settingsLessonPreviewActive');
  String get settingsLessonPreviewCancelled => _t('settingsLessonPreviewCancelled');
  String get settingsLessonPreviewHeader => _t('settingsLessonPreviewHeader');
  String get settingsMonochromeLessons => _t('settingsMonochromeLessons');
  String get settingsMonochromeLessonsDesc => _t('settingsMonochromeLessonsDesc');
  String get settingsDemoMode => _t('settingsDemoMode');
  String get settingsDemoModeDesc => _t('settingsDemoModeDesc');
  String get settingsBackgroundAnimations => _t('settingsBackgroundAnimations');
  String get settingsBackgroundAnimationsDesc =>
      _t('settingsBackgroundAnimationsDesc');
  String get settingsBackgroundGyroscope => _t('settingsBackgroundGyroscope');
  String get settingsBackgroundGyroscopeDesc =>
      _t('settingsBackgroundGyroscopeDesc');
  String get settingsBackgroundStyle => _t('settingsBackgroundStyle');
  String get settingsBackgroundStyleOrbs => _t('settingsBackgroundStyleOrbs');
  String get settingsBackgroundStyleSpace => _t('settingsBackgroundStyleSpace');
  String get settingsBackgroundStyleBubbles =>
      _t('settingsBackgroundStyleBubbles');
  String get settingsBackgroundStyleLines => _t('settingsBackgroundStyleLines');
  String get settingsBackgroundStyleThreeD =>
      _t('settingsBackgroundStyleThreeD');
  String get settingsBackgroundStyleNebula =>
      _t('settingsBackgroundStyleNebula');
  String get settingsBackgroundStylePrism => _t('settingsBackgroundStylePrism');
  String get settingsBackgroundStyleWaves => _t('settingsBackgroundStyleWaves');
  String get settingsBackgroundStyleGrid => _t('settingsBackgroundStyleGrid');
  String get settingsBackgroundStyleRings => _t('settingsBackgroundStyleRings');
  String get settingsBackgroundStyleCustom =>
      _t('settingsBackgroundStyleCustom');
  String get settingsCustomBackgrounds => _t('settingsCustomBackgrounds');
  String get settingsCustomBackgroundsDesc =>
      _t('settingsCustomBackgroundsDesc');
  String settingsCustomBackgroundsSelected(String name) =>
      _t('settingsCustomBackgroundsSelected').replaceAll('{name}', name);
  String get settingsGlassEffect => _t('settingsGlassEffect');
  String get settingsGlassEffectDesc => _t('settingsGlassEffectDesc');
  String get settingsAppBgBlur => _strings[locale]?['settingsAppBgBlur'] ?? _strings['de']?['settingsAppBgBlur'] ?? 'App-Hintergrundunschärfe';
  String get settingsAppBgBlurDesc => _strings[locale]?['settingsAppBgBlurDesc'] ?? _strings['de']?['settingsAppBgBlurDesc'] ?? 'Verwischt den App-Hintergrund für einen Frosted-Glass-Effekt.';
  String get settingsAppBgBlurAmount => _strings[locale]?['settingsAppBgBlurAmount'] ?? _strings['de']?['settingsAppBgBlurAmount'] ?? 'Stärke der Hintergrundunschärfe';
  String get settingsPageTransition => _t('settingsPageTransition');
  String get settingsPageTransitionDesc => _t('settingsPageTransitionDesc');
  String get settingsUseMaterialYou => _t('settingsUseMaterialYou');
  String get settingsUseMaterialYouDesc => _t('settingsUseMaterialYouDesc');
  String get settingsCustomColorSeed => _t('settingsCustomColorSeed');
  String get settingsPageTransitionBounce => _t('settingsPageTransitionBounce');
  String get settingsPageTransitionFade => _t('settingsPageTransitionFade');
  String get settingsPageTransitionSlide => _t('settingsPageTransitionSlide');
  String get settingsPageTransitionZoom => _t('settingsPageTransitionZoom');
  String get settingsPageTransitionBlur => _t('settingsPageTransitionBlur');
  String get settingsPageTransitionEaseIn => _t('settingsPageTransitionEaseIn');
  String get settingsPageTransitionEaseOut => _t('settingsPageTransitionEaseOut');
  String get settingsPageTransitionExpo => _t('settingsPageTransitionExpo');
  String get settingsProgressivePush => _t('settingsProgressivePush');
  String get settingsProgressivePushDesc => _t('settingsProgressivePushDesc');
  String get settingsDailyBriefingPush => _t('settingsDailyBriefingPush');
  String get settingsDailyBriefingPushDesc =>
      _t('settingsDailyBriefingPushDesc');
  String get settingsImportantChangesPush => _t('settingsImportantChangesPush');
  String get settingsImportantChangesPushDesc =>
      _t('settingsImportantChangesPushDesc');
  String get settingsRefreshPushWidgetNow => _t('settingsRefreshPushWidgetNow');
  String get settingsRefreshPushWidgetNowDesc =>
      _t('settingsRefreshPushWidgetNowDesc');
  String get settingsBackgroundLoading => _t('settingsBackgroundLoading');
  String get settingsSectionUpdates => _t('settingsSectionUpdates');
  String get settingsSectionAbout => _t('settingsSectionAbout');
  String get appName => _t('appName');
  String get settingsAppVersion => _t('settingsAppVersion');
  String get settingsBuild => _t('settingsBuild');
  String get settingsSectionSubjects => _t('settingsSectionSubjects');
  String get settingsGithubRepoLabel => _t('settingsGithubRepoLabel');
  String get settingsGithubUpdateCheck => _t('settingsGithubUpdateCheck');
  String get settingsGithubUpdateCheckDesc =>
      _t('settingsGithubUpdateCheckDesc');
  String get settingsGithubDirectDownload => _t('settingsGithubDirectDownload');
  String get settingsGithubDirectDownloadDesc =>
      _t('settingsGithubDirectDownloadDesc');
  String get settingsGithubChecking => _t('settingsGithubChecking');
  String settingsGithubUpdateFound(String v) =>
      _t('settingsGithubUpdateFound').replaceAll('{v}', v);
  String get settingsGithubDownloadNow => _t('settingsGithubDownloadNow');
  String get settingsGithubNoDownloadAsset =>
      _t('settingsGithubNoDownloadAsset');
  String get settingsGithubDownloadStarted =>
      _t('settingsGithubDownloadStarted');
  String get settingsGithubOpenFailed => _t('settingsGithubOpenFailed');
  String get settingsGithubCheckFailed => _t('settingsGithubCheckFailed');
  String get settingsGithubNoUpdate => _t('settingsGithubNoUpdate');
  String get settingsGithubCurrentVersion => _t('settingsGithubCurrentVersion');
  String get settingsGithubLatestVersion => _t('settingsGithubLatestVersion');
  String get settingsGithubInstallQuestion =>
      _t('settingsGithubInstallQuestion');
  String get settingsGithubInstallNow => _t('settingsGithubInstallNow');
  String get settingsGithubInstallLater => _t('settingsGithubInstallLater');
  String get settingsGithubInstallPrompted =>
      _t('settingsGithubInstallPrompted');
  String get settingsGithubOpenReleasePage =>
      _t('settingsGithubOpenReleasePage');
  String get settingsBackupIncludeApiKeys => _t('settingsBackupIncludeApiKeys');
  String get settingsBackupIncludeApiKeysDesc =>
      _t('settingsBackupIncludeApiKeysDesc');
  String get settingsBackupExportAllFile => _t('settingsBackupExportAllFile');
  String get settingsBackupExportAllClipboard =>
      _t('settingsBackupExportAllClipboard');
  String get settingsBackupImportAllTitle => _t('settingsBackupImportAllTitle');
  String get settingsBackupImportAllFile => _t('settingsBackupImportAllFile');
  String get settingsBackupImportAllClipboard =>
      _t('settingsBackupImportAllClipboard');
  String get settingsBackupExportDialogTitle =>
      _t('settingsBackupExportDialogTitle');
  String get settingsBackupExportSuccess => _t('settingsBackupExportSuccess');
  String get settingsBackupExportClipboardSuccess =>
      _t('settingsBackupExportClipboardSuccess');
  String get settingsBackupImportSuccess => _t('settingsBackupImportSuccess');
  String get settingsBackupImportFailed => _t('settingsBackupImportFailed');
  String get settingsBackupClipboardEmpty => _t('settingsBackupClipboardEmpty');
  String get settingsBackupConfirmTitle => _t('settingsBackupConfirmTitle');
  String get settingsBackupConfirmDesc => _t('settingsBackupConfirmDesc');
  String get settingsBackupConfirmAction => _t('settingsBackupConfirmAction');

  // ── AI System Prompt ─────────────────────────────────────────────────────────
  String get aiSystemPersona => _t('aiSystemPersona');
  String get aiSystemRules => _t('aiSystemRules');

  // ── Custom Background Editor ───────────────────────────────────────────────
  String get bgEditorTitle => _t('bgEditorTitle');
  String get bgEditorPreviewTab => _t('bgEditorPreviewTab');
  String get bgEditorDesignTab => _t('bgEditorDesignTab');
  String get bgEditorLibraryTab => _t('bgEditorLibraryTab');
  String get bgEditorStartPoints => _t('bgEditorStartPoints');
  String get bgEditorUpdatedAt => _t('bgEditorUpdatedAt');
  String get bgEditorEdit => _t('bgEditorEdit');
  String get bgEditorUndo => _t('bgEditorUndo');
  String get bgEditorRedo => _t('bgEditorRedo');
  String get bgEditorRandomize => _t('bgEditorRandomize');
  String get bgEditorUnsavedTitle => _t('bgEditorUnsavedTitle');
  String get bgEditorUnsavedDesc => _t('bgEditorUnsavedDesc');
  String get bgEditorDiscard => _t('bgEditorDiscard');
  String get bgEditorLivePreview => _t('bgEditorLivePreview');
  String get bgEditorSave => _t('bgEditorSave');
  String get bgEditorSaved => _t('bgEditorSaved');
  String get bgEditorSaveFailed => _t('bgEditorSaveFailed');
  String get bgEditorUseInApp => _t('bgEditorUseInApp');
  String get bgEditorApplied => _t('bgEditorApplied');
  String get bgEditorLibrary => _t('bgEditorLibrary');
  String get bgEditorNew => _t('bgEditorNew');
  String get bgEditorNewName => _t('bgEditorNewName');
  String get bgEditorDuplicate => _t('bgEditorDuplicate');
  String get bgEditorDelete => _t('bgEditorDelete');
  String get bgEditorDeleteTitle => _t('bgEditorDeleteTitle');
  String get bgEditorDeleteDesc => _t('bgEditorDeleteDesc');
  String get bgEditorDeleteConfirm => _t('bgEditorDeleteConfirm');

  String get bgEditorExportTitle => _t('bgEditorExportTitle');
  String get bgEditorExportSelected => _t('bgEditorExportSelected');
  String get bgEditorExportAll => _t('bgEditorExportAll');
  String get bgEditorExported => _t('bgEditorExported');
  String get bgEditorExportedAll => _t('bgEditorExportedAll');

  String get bgEditorImportTitle => _t('bgEditorImportTitle');
  String get bgEditorImportFromClipboard => _t('bgEditorImportFromClipboard');
  String get bgEditorImportFromFile => _t('bgEditorImportFromFile');
  String get bgEditorImportClipboardEmpty => _t('bgEditorImportClipboardEmpty');
  String bgEditorImportedCount(int n) =>
      _t('bgEditorImportedCount').replaceAll('{n}', '$n');
  String get bgEditorImportFailed => _t('bgEditorImportFailed');

  String get bgEditorMeta => _t('bgEditorMeta');
  String get bgEditorName => _t('bgEditorName');

  String get bgEditorBase => _t('bgEditorBase');
  String get bgEditorUseThemeColors => _t('bgEditorUseThemeColors');
  String get bgEditorUseThemeColorsDesc => _t('bgEditorUseThemeColorsDesc');
  String get bgEditorGradientLinear => _t('bgEditorGradientLinear');
  String get bgEditorGradientRadial => _t('bgEditorGradientRadial');
  String get bgEditorBaseOpacity => _t('bgEditorBaseOpacity');
  String get bgEditorGradientAngle => _t('bgEditorGradientAngle');
  String get bgEditorRadialCenterX => _t('bgEditorRadialCenterX');
  String get bgEditorRadialCenterY => _t('bgEditorRadialCenterY');
  String get bgEditorRadialRadius => _t('bgEditorRadialRadius');
  String bgEditorColorN(int n) => _t('bgEditorColorN').replaceAll('{n}', '$n');

  String get bgEditorOrbs => _t('bgEditorOrbs');
  String get bgEditorOrbsEnabled => _t('bgEditorOrbsEnabled');
  String get bgEditorOrbsThemeDesc => _t('bgEditorOrbsThemeDesc');
  String get bgEditorRandomizeSeed => _t('bgEditorRandomizeSeed');
  String get bgEditorOrbsCount => _t('bgEditorOrbsCount');
  String get bgEditorOrbsSize => _t('bgEditorOrbsSize');
  String get bgEditorOrbsVariance => _t('bgEditorOrbsVariance');
  String get bgEditorOrbsOpacity => _t('bgEditorOrbsOpacity');
  String get bgEditorOrbsSoftness => _t('bgEditorOrbsSoftness');
  String bgEditorOrbColorN(int n) =>
      _t('bgEditorOrbColorN').replaceAll('{n}', '$n');

  String get bgEditorEffects => _t('bgEditorEffects');
  String get bgEditorPatternNone => _t('bgEditorPatternNone');
  String get bgEditorPatternLines => _t('bgEditorPatternLines');
  String get bgEditorPatternGrid => _t('bgEditorPatternGrid');
  String get bgEditorPatternOpacity => _t('bgEditorPatternOpacity');
  String get bgEditorPatternScale => _t('bgEditorPatternScale');
  String get bgEditorPatternAngle => _t('bgEditorPatternAngle');
  String get bgEditorNoise => _t('bgEditorNoise');
  String get bgEditorVignette => _t('bgEditorVignette');

  String get bgEditorMotion => _t('bgEditorMotion');
  String get bgEditorAnimate => _t('bgEditorAnimate');
  String get bgEditorSpeed => _t('bgEditorSpeed');
  String get bgEditorParallax => _t('bgEditorParallax');

  String get bgEditorAiTitle => _t('bgEditorAiTitle');
  String get bgEditorAiDesc => _t('bgEditorAiDesc');
  String get bgEditorAiHint => _t('bgEditorAiHint');
  String get bgEditorAiGenerate => _t('bgEditorAiGenerate');
  String get bgEditorAiSystem => _t('bgEditorAiSystem');
  String get bgEditorAiUserPrefix => _t('bgEditorAiUserPrefix');
  String get bgEditorAiUserSchemaHint => _t('bgEditorAiUserSchemaHint');
  String get bgEditorAiGeneratedName => _t('bgEditorAiGeneratedName');
  String get bgEditorAiSuccess => _t('bgEditorAiSuccess');
  String get bgEditorAiError => _t('bgEditorAiError');

  // ── Changelog & Updates ───────────────────────────────────────────────────
  String get settingsChangelogTitle => _t('settingsChangelogTitle');
  String get settingsChangelogSubtitle => _t('settingsChangelogSubtitle');
  String get changelogTitle => _t('changelogTitle');
  String get changelogLoadError => _t('changelogLoadError');
  String get changelogRetry => _t('changelogRetry');

  // ── AI Assistant & Querying ────────────────────────────────────────────────
  String get aiTitle => _t('aiTitle');
  String get aiTabAnalysis => _t('aiTabAnalysis');
  String get aiTabChat => _t('aiTabChat');
  String get aiMore => _t('aiMore');
  String get aiSettingsMenu => _t('aiSettingsMenu');
  String get aiClearResult => _t('aiClearResult');
  String get aiSearchAgain => _t('aiSearchAgain');
  String get aiNewSearch => _t('aiNewSearch');
  String get aiSearchRunning => _t('aiSearchRunning');
  String get aiSearchShapingDesc => _t('aiSearchShapingDesc');
  String get aiStepAnalyzingTimetable => _t('aiStepAnalyzingTimetable');
  String get aiStepSortingResults => _t('aiStepSortingResults');
  String get aiStepAlmostDone => _t('aiStepAlmostDone');
  String get aiSearchHintPlaceholder => _t('aiSearchHintPlaceholder');
  String get aiOverview => _t('aiOverview');
  String get aiEmptyPromptTitle => _t('aiEmptyPromptTitle');
  String get aiEmptyPromptSubtitle => _t('aiEmptyPromptSubtitle');
  String get aiPromptWhenFinishToday => _t('aiPromptWhenFinishToday');
  String get aiPromptWhatCancelledToday => _t('aiPromptWhatCancelledToday');
  String get aiPromptUpcomingExams => _t('aiPromptUpcomingExams');
  String get aiPromptFirstLessonToday => _t('aiPromptFirstLessonToday');
  String get aiPromptNextLesson => _t('aiPromptNextLesson');
  String get aiPromptTomorrowSchedule => _t('aiPromptTomorrowSchedule');
  String get aiClearInput => _t('aiClearInput');
  String get aiLessons => _t('aiLessons');
  String get aiResultsCardDesc => _t('aiResultsCardDesc');
  String get aiDismiss => _t('aiDismiss');
  String get aiLessonsCountSingle => _t('aiLessonsCountSingle');
  String aiLessonsCountPlural(int count) =>
      _t('aiLessonsCountPlural').replaceAll('{count}', '$count');
  String get aiExamsCountWeekSingle => _t('aiExamsCountWeekSingle');
  String aiExamsCountWeekPlural(int count) =>
      _t('aiExamsCountWeekPlural').replaceAll('{count}', '$count');

  // ── Class Picker ───────────────────────────────────────────────────────────
  String get classPickerHeaderDesc => _t('classPickerHeaderDesc');
  String get classPickerDefaultBadge => _t('classPickerDefaultBadge');
  String get classPickerSetDefault => _t('classPickerSetDefault');
  String get classPickerOtherClasses => _t('classPickerOtherClasses');
  String get classPickerRemoveFavorite => _t('classPickerRemoveFavorite');
  String get classPickerAddFavorite => _t('classPickerAddFavorite');

  // ─────────────────────────────────────────────────────────────────────────────
  static const Map<String, Map<String, dynamic>> _strings = {
    // ── GERMAN ────────────────────────────────────────────────────────────────
    'de': {
      'navWeek': 'Woche',
      'navHomework': 'Hausaufgaben',
      'navExams': 'Exams',
      'navInfo': 'Info',
      'navMenu': 'Menü',
    'navAi': 'KI',

      'loginServer': 'Server URL',
      'loginSchool': 'Schule',
      'loginUsername': 'Benutzername',
      'loginPassword': 'Passwort',
      'loginLoginKey': 'Login-Schlüssel',
      'loginLoginKeyHint':
          'Nutze den WebUntis-Login-Schlüssel, wenn sich deine Schule über Microsoft 365 oder Office 365 anmeldet.',
      'loginCredentialModePassword': 'Passwort',
      'loginCredentialModeLoginKey': 'Login-Schlüssel',
      'loginButton': 'Loslegen',
      'loginFailed': 'Login fehlgeschlagen. Prüfe deine Daten.',
      'loginConnectionError': 'Verbindungsfehler',
      'loginSearchSchool': 'Schule suchen',
      'loginSelectSchool': 'Schule wählen',
      'loginSearchHint': 'Schulname oder Stadt...',
      'loginNoSchoolsFound': 'Keine Schulen gefunden.',
      'loginChangeLanguage': 'Sprache',
      'loginManualEntry': 'Manuelle Eingabe',
      'loginSwitchToSearch': 'Zurück zur Suche',
      'loginChangeSchool': 'Schule ändern',
      'loginTwoFactorCode': '2FA-Code',
      'loginTwoFactorHint':
          'Gib den 2FA-Code aus deiner Authenticator-App ein.',
      'loginTwoFactorRequired':
          '2FA ist aktiviert. Bitte gib deinen Verifizierungscode ein.',
      'loginTwoFactorInvalid':
          'Der 2FA-Code ist ungültig oder abgelaufen. Bitte versuche es erneut.',
      'loginVerifyButton': 'Verifizieren',

      'onboardingWelcomeTitle': 'Willkommen bei Untis+',
      'onboardingChooseLanguageSubtitle': 'Wähle deine bevorzugte Sprache',
      'onboardingAppearanceTitle': 'Erscheinungsbild',
      'onboardingAppearanceSubtitle':
          'Gestalte Untis+ genau so, wie du es möchtest',
      'onboardingThemeSystem': 'System',
      'onboardingThemeLight': 'Hell',
      'onboardingThemeDark': 'Dunkel',
      'onboardingAnimationsHint': 'Schöne Hintergrundanimationen aktivieren',
      'onboardingSchoolLoginTitle': 'Schul-Login',
      'onboardingSchoolLoginSubtitle': 'Verbinde dein WebUntis-Konto',
      'onboardingGeminiTitle': 'Gemini KI',
      'onboardingGeminiSubtitle':
          'Chatte mit deinem Stundenplan und deinen Hausaufgaben',
      'onboardingGeminiInfo':
          'Hol dir einen kostenlosen Gemini API-Schlüssel in Google AI Studio, um den leistungsstarken KI-Assistenten in Untis+ freizuschalten.',
      'onboardingGeminiGetApiKey': 'API-Schlüssel holen',
      'onboardingSkip': 'Überspringen',
      'onboardingNext': 'Weiter',
      'onboardingGeminiEnterKeyOrSkip':
          'Bitte gib einen Schlüssel ein oder überspringe diesen Schritt',
      'onboardingReadyTitle': 'Bereit zum Start!',
      'onboardingReadySubtitle': 'Das kannst du alles in Untis+ machen',
      'onboardingFeatureTimetableTitle': 'Stundenplan & Kalender',
      'onboardingFeatureTimetableDesc':
          'Behalte deinen Stundenplan perfekt im Blick.',
      'onboardingFeatureExamsTitle': 'Prüfungen & Hausaufgaben',
      'onboardingFeatureExamsDesc':
          'Verfolge deinen Lernstand, importiere Klausuren und exportiere sie als JSON.',
      'onboardingFeatureAiTitle': 'KI-Assistent',
      'onboardingFeatureAiDesc':
          'Frag Gemini nach deinem Tag, Hausaufgaben oder Prüfungen.',
      'onboardingFeatureNotifyTitle': 'Benachrichtigungen & Widgets',
      'onboardingFeatureNotifyDesc':
          'Bleib auf dem Laufenden, bevor die Schule startet.',
      'onboardingFinishSetup': 'Einrichtung abschließen',
      'onboardingUseDemoMode': 'Demo-Modus starten',
      'onboardingUseDemoModeDesc':
          'Teste Untis+ ohne Schul-Login mit realistisch gefullten Beispieldaten.',
      'tutorialTitle': 'Kurzes App-Tutorial',
      'tutorialSkip': 'Tutorial überspringen',
      'tutorialDone': 'Tutorial beenden',
      'tutorialStepWeekTitle': '1. Stundenplan',
      'tutorialStepWeekDesc':
          'Tippe auf den großen Uhren-Button, um zur Wochenansicht zu wechseln.',
      'tutorialStepExamsTitle': '2. Prüfungen',
      'tutorialStepExamsDesc':
          'Tippe auf den Prüfungs-Button, um Klausuren zu sehen sowie zu importieren und zu exportieren.',
      'tutorialStepInfoTitle': '3. Schul-Info',
      'tutorialStepInfoDesc':
          'Tippe auf den Info-Button für aktuelle Mitteilungen deiner Schule.',
      'tutorialStepSettingsTitle': '4. Einstellungen',
      'tutorialStepSettingsDesc':
          'Tippe auf den Einstellungs-Button, um Sprache, Design und Benachrichtigungen anzupassen.',
      'tutorialStepFinishTitle': 'Fertig!',
      'tutorialStepFinishDesc':
          'Du kennst jetzt alle Hauptbereiche der App. Viel Spaß mit Untis+!',

      'timetableTitle': 'Stundenplan',
      'timetablePrevWeek': 'Vorherige Woche',
      'timetableNextWeek': 'Nächste Woche',
      'timetableWeekView': 'Wochenansicht',
      'timetableDayGrid': 'Tagesraster',
      'timetableNotLoaded': 'Stundenplan nicht geladen',
      'timetableReload': 'Neu laden',
      'timetableSelectClass': 'Klasse wählen',
      'timetableMyTimetable': 'Mein Stundenplan',
      'timetableSelectAnother': 'Andere Klasse',
      'timetableNoClassesFound':
          'Keine Klassen gefunden oder Zugriff verweigert.',
      'freeRoomsTitle': 'Freie Räume',
      'freeRoomsSelectTime': 'Zeitraum wählen',
      'freeRoomsNoneFound': 'Keine freien Räume in diesem Zeitraum gefunden.',
      'freeRoomsNoRangesHint':
          'Keine passenden Zeitfenster im aktuellen Tag gefunden.',
      'freeRoomsCount': '{n} freie Räume',
      'weekDayShort': ['Mo', 'Di', 'Mi', 'Do', 'Fr'],
      'weekDayFull': [
        'Montag',
        'Dienstag',
        'Mittwoch',
        'Donnerstag',
        'Freitag',
      ],
      'noLesson': '(kein Unterricht)',

      'detailTime': 'Zeit',
      'detailTeacher': 'Lehrkraft',
      'detailRoom': 'Raum',
      'detailClass': 'Klasse',
      'detailLesson': 'Stunde',
      'detailInfo': 'Hinweis',
      'detailNotesForStudents': 'Schülernotizen',
      'detailLessonNotes': 'Unterrichtsnotizen',
      'detailHomework': 'Hausaufgaben',
      'detailCancelled': 'FÄLLT AUS',
      'detailRegular': 'Reguläre Stunde',
      'detailHideSubject': 'Fach dauerhaft ausblenden',
      'detailCancelledBadge': 'FÄLLT AUS',

      'examsTitle': 'Prüfungen',
      'examsReload': 'Neu laden',
      'examsNone': 'Keine Prüfungen gefunden',
      'examsNoneHint': 'Tippe auf + um eine Prüfung hinzuzufügen.',
      'examsUpcoming': 'Bevorstehend',
      'examsPast': 'Vergangen',
      'examsAdd': '',
      'examsAddTitle': 'Prüfung hinzufügen',
      'examsEditTitle': 'Prüfung bearbeiten',
      'examsSubjectLabel': 'Fach / Titel *',
      'examsTypeLabel': 'Art (z.B. Klausur, Test)',
      'examsNotesLabel': 'Notizen / Themen',
      'examsSave': 'Speichern',
      'examsCancel': 'Abbrechen',
      'examsDelete': 'Löschen',
      'examsToday': 'Heute',
      'examsTomorrow': 'Morgen',
      'examsDaysIn': 'in {n} Tagen',
      'examsOwn': 'Eigene',
      'examsUnknown': '(unbekannt)',
      'examsNoneEntered': 'Keine Prüfungen eingetragen.',
      'examsImportTitle': 'Klausurplan hochladen',
      'examsImportCamera': 'Kamera',
      'examsImportGallery': 'Galerie',
      'examsImportFile': 'PDF / Datei',
      'examsImportSuccess': 'Erfolgreich importiert!',
      'examsImportError': 'Fehler beim Import: ',
      'examsImportInvalidJson': 'Kein gültiges JSON gefunden.',
      'examsExportSuccess': 'Klausuren als JSON in die Zwischenablage kopiert.',
      'examsExportEmpty': 'Keine eigenen Klausuren zum Exportieren.',
      'examsActionCustom': 'Manuell',
      'examsActionImport': 'Importieren (Scan/PDF)',
      'examsActionExport': 'Exportieren (JSON)',
      'examsActionScan': 'Scannen',

      'homeworkTitle': 'Hausaufgaben',
      'homeworkReload': 'Neu laden',
      'homeworkNone': 'Keine Hausaufgaben gefunden',
      'homeworkNoneHint': 'Du bist fertig! Genieße deine Freizeit.',
      'homeworkMarkDone': 'Als erledigt markieren',
      'homeworkMarkUndone': 'Als nicht erledigt markieren',
      'homeworkDue': 'Fällig am',

      'infoTitle': 'Schulinfos',
      'infoReload': 'Neu laden',
      'infoUpdated': 'Aktualisiert',
      'infoEmpty': 'Keine aktuellen Benachrichtigungen',
      'infoEmptyHint':
          'Falls deine Schule derzeit nichts veröffentlicht hat, erscheint hier keine Meldung.',
      'infoFetchError':
          'Benachrichtigungen konnten nicht geladen werden. Bitte später erneut versuchen.',
      'infoOpenLink': 'Link öffnen',
      'notificationActionCurrentLesson': 'Aktuelle Stunde: {lesson}',
      'notificationActionNextLesson': 'Nächste Stunde: {lesson}',
      'notificationActionNoNextLesson':
          'Keine nächste Stunde für heute gefunden',

      'aiTitle': 'KI-Assistent',
      'aiTabAnalysis': 'Analyse',
      'aiTabChat': 'Chat',
      'aiInputHint': 'Frage stellen…',
      'aiKnowsSchedule': 'Ich kenne deinen Stundenplan!',
      'aiAskAnything': 'Frag mich alles über deine Woche.',
      'aiNoApiKey':
          '⚠️ Bitte trage deinen API-Schlüssel unter Einstellungen → KI-Assistent ein.',
      'aiNoReply': '⚠️ Keine Antwort erhalten.',
      'aiApiError': '⚠️ API-Fehler:',
      'aiConnectionError': '⚠️ Verbindungsfehler:',
      'aiCustomBaseUrlMissing':
          '⚠️ Bitte setze zuerst die Custom Base URL in den KI-Einstellungen.',
      'aiSuggestions': [
        'Was hab ich morgen?',
        'Hab ich heute eine Freistunde?',
        'Wann ist morgen Schulschluss?',
        'Fällt heute etwas aus?',
      ],

      'settingsTitle': 'Einstellungen',
      'settingsLoggedInAs': 'Angemeldet als',
      'settingsLogout': 'Abmelden',
      'settingsSectionQuick': 'Schnellzugriff',
      'settingsSectionGeneral': 'App',
      'settingsAppearance': 'Erscheinungsbild',
      'settingsAppearanceDesc': 'System (Hell/Dunkel)',
      'settingsHubNotifications': 'Benachrichtigungen & Widgets',
      'settingsHubDataBackup': 'Daten & Backup',
      'settingsHubDataBackupDesc': 'Alle App-Einstellungen sichern',
      'settingsHubAccount': 'Account & Demo',
      'settingsHubUpdatesAbout': 'Updates & Über',
      'settingsLanguage': 'Sprache',
      'settingsSectionAI': 'KI-Assistent',
      'settingsAiProvider': 'Anbieter',
      'settingsAiProviderGemini': 'Google Gemini',
      'settingsAiProviderOpenAi': 'OpenAI',
      'settingsAiProviderMistral': 'Mistral AI',
      'settingsAiProviderCustom': 'Custom Anbieter',
      'settingsAiProviderLocal': 'Lokal (On-Device)',
      'settingsAiModel': 'Modell',
      'settingsAiApiKey': 'API-Schlüssel',
      'settingsAiApiKeyNotSet': 'Nicht konfiguriert — Tippen zum Einrichten',
      'settingsAiApiKeyDialogDesc':
          'Erforderlich für den KI-Assistenten. Über „API-Key holen“ öffnest du die passende Seite für den ausgewählten Anbieter.',
      'settingsAiApiKeyGet': 'API-Key holen',
      'settingsAiApiKeyOpenFailed': 'Konnte die API-Key-Seite nicht öffnen.',
      'settingsAiPrompt': 'System-Prompt',
      'settingsAiPromptDesc':
          'Bearbeite den vorgefertigten Prompt und nutze Variablen wie [timetable].',
      'settingsAiPromptEditTitle': 'System-Prompt bearbeiten',
      'settingsAiPromptReset': 'Standard wiederherstellen',
      'settingsAiPromptVariables': 'Prompt-Variablen',
      'settingsAiPromptVariablesDesc':
          'Liste aller Platzhalter, die automatisch mit Daten ersetzt werden.',
      'settingsAiLocalModel': 'Lokales Modell',
      'settingsAiLocalModelDesc': 'Wähle und lade ein Modell für On-Device-Inferenz herunter.',
      'settingsAiLocalModelDownload': 'Herunterladen',
      'settingsAiLocalModelDownloading': 'Wird heruntergeladen…',
      'settingsAiLocalModelInstalled': 'Installiert',
      'settingsAiLocalModelDelete': 'Löschen',
      'settingsAiLocalModelActive': 'Aktiv',
      'settingsAiLocalModelError': 'Download fehlgeschlagen.',
      'aiLocalModelExamNotSupported':
          'Lokale Modelle unterstützen das Importieren von Prüfungsbildern nicht. Bitte wähle einen Online-Anbieter.',
      'aiLocalModelLoadError':
          'Lokales Modell konnte nicht geladen werden. Bitte lade es erneut herunter.',
      'settingsAiLocalModelSize': 'Größe: {size} GB',
      'settingsAiLocalModelDeleteConfirm': 'Modell wirklich löschen?',
      'aiVar_today': 'Heutiges Datum in lokaler Schreibweise',
      'aiVar_today_iso': 'Heutiges Datum im Format YYYY-MM-DD',
      'aiVar_locale': 'Aktive App-Sprache (z.B. de, en)',
      'aiVar_school_name': 'Name der Schule',
      'aiVar_school_url': 'Server/Domain der Schule',
      'aiVar_person_type': 'WebUntis Personentyp als Zahl',
      'aiVar_person_id': 'WebUntis Personen-ID',
      'aiVar_demo_mode': 'true, wenn Demo-Modus aktiv ist',
      'aiVar_current_monday': 'Montag der geladenen Woche (DD.MM.YYYY)',
      'aiVar_current_friday': 'Freitag der geladenen Woche (DD.MM.YYYY)',
      'aiVar_day_summary_today': 'Kurzübersicht für heute',
      'aiVar_day_summary_tomorrow': 'Kurzübersicht für morgen',
      'aiVar_timetable': 'Formatierter Stundenplan der aktuellen Woche',
      'aiVar_timetable_json': 'Rohdaten des Stundenplans als JSON',
      'aiVar_exams': 'Formatierte Liste geplanter Prüfungen',
      'aiVar_exams_json': 'Prüfungsdaten als JSON',
      'settingsAiCustomBaseUrl': 'Custom Base URL',
      'settingsAiCustomBaseUrlDesc':
          'Basis-URL deines eigenen Anbieters (OpenAI- oder Gemini-kompatibel).',
      'settingsAiCustomBaseUrlHint': 'https://api.dein-anbieter.tld/v1',
      'settingsAiCompatibility': 'Custom Kompatibilität',
      'settingsAiCompatibilityOpenAi': 'OpenAI-kompatibel',
      'settingsAiCompatibilityGemini': 'Gemini-kompatibel',
      'settingsApiKey': 'Gemini API-Schlüssel',
      'settingsApiKeyNotSet': 'Nicht konfiguriert — Tippen zum Einrichten',
      'settingsApiKeyDialogTitle': 'Gemini API-Schlüssel',
      'settingsApiKeyDialogDesc':
          'Erforderlich für den KI-Assistenten. Den Schlüssel findest du unter aistudio.google.com/app/apikey.',
      'settingsApiKeySave': 'Speichern',
      'settingsApiKeyRemove': 'Entfernen',
      'settingsApiKeyCancel': 'Abbrechen',
      'settingsSectionHidden': 'Ausgeblendete Fächer',
      'settingsNoHidden': 'Keine Fächer ausgeblendet',
      'settingsNoHiddenDesc': 'Tippe eine Stunde an, um sie auszublenden.',
      'settingsUnhide': 'Einblenden',
      'settingsHiddenCount': '{n} Fach/Fächer ausgeblendet',
      'settingsSectionColors': 'Fachfarben',
      'settingsColorsDesc': 'Tippe auf ein Fach um eine Farbe zu wählen.',
      'settingsNoSubjectsLoaded': 'Keine Fächer geladen',
      'settingsNoSubjectsLoadedDesc': 'Öffne zuerst deinen Stundenplan.',
      'settingsCustomColor': 'Benutzerdefiniert',
      'settingsDefaultColor': 'Standardfarbe',
      'settingsColorFor': 'Farbe für „{s}"',
      'settingsColorReset': 'Auf Standard zurücksetzen',
      'settingsColorCustomPicker': 'Eigene Farbe wählen',
      'settingsColorApply': 'Farbe übernehmen',
      'settingsColorRed': 'Rot',
      'settingsColorGreen': 'Grün',
      'settingsColorBlue': 'Blau',
      'settingsThemeMode': 'Farbschema',
      'settingsThemeLight': 'Hell',
      'settingsThemeSystem': 'System',
      'settingsThemeDark': 'Dunkel',
      'settingsSectionTimetable': 'Stundenplan',
      'settingsShowCancelled': 'Ausgefallene Stunden anzeigen',
      'settingsShowCancelledDesc':
          'Ausgefallene Stunden werden im Stundenplan angezeigt',
      'settingsCancelledColor': 'Ausgefallene Farbe',
      'settingsCancelledColorDesc': 'Farbe für ausgefallene Stunden anpassen',
      'settingsLessonDesignTitle': 'Stunden- & Kartendesign',
      'settingsLessonDesignDesc': 'Passe Stile, Glow, Blur und Details der Stundenkarten an.',
      'settingsLessonStyle': 'Karten-Stil',
      'settingsLessonStyleDesc': 'Wähle das visuelle Grunddesign der Stunden.',
      'settingsLessonStyleModern': 'Modern (Getönt)',
      'settingsLessonStyleGlass': 'Milchglas (Frosted)',
      'settingsLessonStyleGradient': 'Farbverlauf',
      'settingsLessonStyleOutline': 'Kontur / Minimal',
      'settingsLessonStyleSolid': 'Kräftig / Vollton',
      'settingsLessonGlow': 'Glow-Leuchteffekt',
      'settingsLessonGlowDesc': 'Fügt einen leuchtenden Neonschein hinter den Stundenkarten hinzu.',
      'settingsLessonGlowMode': 'Glow-Modus',
      'settingsLessonGlowModeActive': 'Nur laufende Stunde',
      'settingsLessonGlowModeAll': 'Alle Stunden',
      'settingsLessonGlowIntensity': 'Glow-Intensität',
      'settingsLessonBlur': 'Milchglas-Unschärfe (Blur)',
      'settingsLessonBlurDesc': 'Hintergrund hinter den Stundenkarten weichzeichnen.',
      'settingsLessonBlurAmount': 'Weichzeichner-Stärke',
      'settingsLessonCardOpacity': 'Karten-Deckkraft',
      'settingsLessonBorderRadius': 'Eckenrundung',
      'settingsLessonAccentStyle': 'Akzentleiste',
      'settingsLessonAccentBar': 'Klassischer Balken',
      'settingsLessonAccentThin': 'Dünne Linie',
      'settingsLessonAccentDot': 'Punkt-Indikator',
      'settingsLessonAccentNone': 'Keine Leiste',
      'settingsLessonShowTeacher': 'Lehrkraft anzeigen',
      'settingsLessonShowTeacherDesc': 'Kürzel bzw. Name der Lehrkraft auf der Karte einblenden.',
      'settingsLessonShowRoom': 'Raum anzeigen',
      'settingsLessonShowRoomDesc': 'Raumnummer auf der Stundenkarte einblenden.',
      'settingsLessonCompactMode': 'Kompakte Ansicht',
      'settingsLessonCompactModeDesc': 'Reduzierte Abstände für mehr Übersicht bei vielen Stunden.',
      'settingsLessonDimPast': 'Vergangene Stunden dimmen',
      'settingsLessonDimPastDesc': 'Bereits vergangene Stunden am Tag dezent ausgrauen.',
      'settingsLessonCancelledPattern': 'Ausfall-Schraffur',
      'settingsLessonCancelledPatternDesc': 'Zeigt ein diagonales Schraffurmuster bei Entfällen.',
      'settingsLessonPreviewRegular': 'Regulär',
      'settingsLessonPreviewActive': 'Aktive Stunde',
      'settingsLessonPreviewCancelled': 'Ausfall',
      'settingsLessonPreviewHeader': 'Live-Vorschau',
      'settingsMonochromeLessons': 'Monochrome Stunden',
      'settingsMonochromeLessonsDesc':
          'Alle Stunden in Material-You-Farben statt Einzelfarben',
      'settingsDemoMode': 'Demo-Modus',
      'settingsDemoModeDesc':
          'Verwendet lokale Demo-Daten statt Schulserver (sofort aktiv).',
      'settingsBackgroundAnimations': 'Hintergrundanimationen',
      'settingsBackgroundAnimationsDesc':
          'Animierte Farbverläufe im Hintergrund anzeigen',
      'settingsBackgroundGyroscope': 'Gyroskop-Reaktion',
      'settingsBackgroundGyroscopeDesc':
          'Lässt den Hintergrund auf die Gerätebewegung reagieren',
      'settingsBackgroundStyle': 'Animationsstil',
      'settingsBackgroundStyleOrbs': 'Orbs',
      'settingsBackgroundStyleSpace': 'Space',
      'settingsBackgroundStyleBubbles': 'Blasen',
      'settingsBackgroundStyleLines': 'Linien',
      'settingsBackgroundStyleThreeD': '3D-Formen',
      'settingsBackgroundStyleNebula': 'Nebel',
      'settingsBackgroundStylePrism': 'Prisma',
      'settingsBackgroundStyleWaves': 'Wellen',
      'settingsBackgroundStyleGrid': 'Gitter',
      'settingsBackgroundStyleRings': 'Ringe',
      'settingsBackgroundStyleCustom': 'Custom',
      'settingsCustomBackgrounds': 'Eigene Hintergründe',
      'settingsCustomBackgroundsDesc':
          'Erstellen, speichern, importieren & exportieren',
      'settingsCustomBackgroundsSelected': 'Ausgewählt: {name}',

      'bgEditorTitle': 'Hintergrund-Editor',
      'bgEditorPreviewTab': 'Vorschau',
      'bgEditorDesignTab': 'Design',
      'bgEditorLibraryTab': 'Bibliothek',
      'bgEditorStartPoints': 'Startpunkte',
      'bgEditorUpdatedAt': 'Aktualisiert',
      'bgEditorEdit': 'Bearbeiten',
      'bgEditorUndo': 'Rückgängig',
      'bgEditorRedo': 'Wiederholen',
      'bgEditorRandomize': 'Zufall',
      'bgEditorUnsavedTitle': 'Ungespeicherte Änderungen',
      'bgEditorUnsavedDesc':
          'Änderungen speichern, verwerfen oder weiter bearbeiten?',
      'bgEditorDiscard': 'Verwerfen',
      'bgEditorLivePreview': 'Live-Vorschau',
      'bgEditorSave': 'Speichern',
      'bgEditorSaved': 'Gespeichert.',
      'bgEditorSaveFailed': 'Speichern fehlgeschlagen.',
      'bgEditorUseInApp': 'In App verwenden',
      'bgEditorApplied': 'Als Hintergrund aktiviert.',
      'bgEditorLibrary': 'Bibliothek',
      'bgEditorNew': 'Neu',
      'bgEditorNewName': 'Neuer Hintergrund',
      'bgEditorDuplicate': 'Duplizieren',
      'bgEditorDelete': 'Löschen',
      'bgEditorDeleteTitle': 'Hintergrund löschen?',
      'bgEditorDeleteDesc': 'Dieser Hintergrund wird dauerhaft entfernt.',
      'bgEditorDeleteConfirm': 'Löschen',

      'bgEditorExportTitle': 'Export',
      'bgEditorExportSelected': 'Ausgewählten exportieren',
      'bgEditorExportAll': 'Alle exportieren',
      'bgEditorExported': 'JSON in Zwischenablage kopiert.',
      'bgEditorExportedAll': 'Alle Hintergründe als JSON kopiert.',

      'bgEditorImportTitle': 'Import',
      'bgEditorImportFromClipboard': 'Aus Zwischenablage',
      'bgEditorImportFromFile': 'Aus Datei',
      'bgEditorImportClipboardEmpty': 'Zwischenablage ist leer.',
      'bgEditorImportedCount': '{n} Hintergrund(e) importiert.',
      'bgEditorImportFailed': 'Import fehlgeschlagen.',

      'bgEditorMeta': 'Metadaten',
      'bgEditorName': 'Name',
      'bgEditorBase': 'Basis-Gradient',
      'bgEditorUseThemeColors': 'Theme-Farben verwenden',
      'bgEditorUseThemeColorsDesc':
          'Nutzt Farben aus dem aktuellen Farbschema.',
      'bgEditorGradientLinear': 'Linear',
      'bgEditorGradientRadial': 'Radial',
      'bgEditorBaseOpacity': 'Basis-Deckkraft',
      'bgEditorGradientAngle': 'Winkel',
      'bgEditorRadialCenterX': 'Zentrum X',
      'bgEditorRadialCenterY': 'Zentrum Y',
      'bgEditorRadialRadius': 'Radius',
      'bgEditorColorN': 'Farbe {n}',

      'bgEditorOrbs': 'Orbs',
      'bgEditorOrbsEnabled': 'Orbs aktiv',
      'bgEditorOrbsThemeDesc': 'Verwendet Theme-Farben für Orbs.',
      'bgEditorRandomizeSeed': 'Seed randomisieren',
      'bgEditorOrbsCount': 'Anzahl',
      'bgEditorOrbsSize': 'Größe',
      'bgEditorOrbsVariance': 'Varianz',
      'bgEditorOrbsOpacity': 'Deckkraft',
      'bgEditorOrbsSoftness': 'Weichheit',
      'bgEditorOrbColorN': 'Orb-Farbe {n}',

      'bgEditorEffects': 'Muster & Effekte',
      'bgEditorPatternNone': 'Keins',
      'bgEditorPatternLines': 'Linien',
      'bgEditorPatternGrid': 'Gitter',
      'bgEditorPatternOpacity': 'Muster-Deckkraft',
      'bgEditorPatternScale': 'Skalierung',
      'bgEditorPatternAngle': 'Muster-Winkel',
      'bgEditorNoise': 'Rauschen',
      'bgEditorVignette': 'Vignette',

      'bgEditorMotion': 'Bewegung',
      'bgEditorAnimate': 'Animieren',
      'bgEditorSpeed': 'Geschwindigkeit',
      'bgEditorParallax': 'Parallax',

      'bgEditorAiTitle': 'KI-Generator',
      'bgEditorAiDesc':
          'Beschreibe einen Look – die KI erstellt einen neuen Hintergrund.',
      'bgEditorAiHint': 'z.B. „Neon-Nebel, weich, dunkel, blau/pink“',
      'bgEditorAiGenerate': 'Mit KI erstellen',
      'bgEditorAiSystem': '''
You generate ONE Flutter background preset.
Output ONLY valid JSON (no markdown, no commentary).

Return a single JSON object with this schema:
{
    "version": 1,
    "name": "...",
    "base": {
        "type": "linear"|"radial",
        "useThemeColors": true|false,
        "colors": ["#RRGGBB", ...],
        "opacity": 0.0-1.0,
        "angleDeg": 0-360,
        "centerX": -1..1,
        "centerY": -1..1,
        "radius": 0.3-2.5
    },
    "orbs": {
        "enabled": true|false,
        "useThemeColors": true|false,
        "colors": ["#RRGGBB", ...],
        "count": 0-18,
        "seed": 0-2147483647,
        "size": 40-480,
        "sizeVariance": 0.0-1.0,
        "opacity": 0.0-1.0,
        "softness": 0.0-1.0
    },
    "pattern": {
        "type": "none"|"lines"|"grid",
        "opacity": 0.0-1.0,
        "scale": 0.4-3.5,
        "angleDeg": 0-360
    },
    "noise": 0.0-0.5,
    "vignette": 0.0-1.0,
    "animate": true|false,
    "animationSpeed": 0.0-3.0,
    "parallaxStrength": 0.0-1.0
}

Keep values reasonable and visually pleasing. Prefer 2-3 base colors.
Use "useThemeColors": true unless the prompt asks for specific colors.
''',
      'bgEditorAiUserPrefix': 'Description:',
      'bgEditorAiUserSchemaHint':
          'Return JSON only. Do not wrap in code fences.',
      'bgEditorAiGeneratedName': 'KI Hintergrund',
      'bgEditorAiSuccess': 'KI-Hintergrund erstellt.',
      'bgEditorAiError': 'KI: ',
      'settingsGlassEffect': 'Blur-Effekt',
      'settingsGlassEffectDesc':
          'Aktiviert Blur in der Oberfläche',
      'settingsPageTransition': 'Seitenübergang',
      'settingsPageTransitionDesc': 'Wähle den Übergangsstil für Seitenwechsel',
      'settingsPageTransitionBounce': 'Bounce',
      'settingsPageTransitionFade': 'Fade',
      'settingsPageTransitionSlide': 'Slide',
      'settingsPageTransitionZoom': 'Zoom',
      'settingsPageTransitionBlur': 'Blur',
      'settingsPageTransitionEaseIn': 'Ease In',
      'settingsPageTransitionEaseOut': 'Ease Out',
      'settingsPageTransitionExpo': 'Expo',
      'settingsUseMaterialYou': 'Material You',
      'settingsUseMaterialYouDesc':
          'Farben automatisch an Systemakzentfarbe anpassen',
      'settingsCustomColorSeed': 'Farbe wählen',
      'settingsProgressivePush': 'Progressive Push-Benachrichtigung',
      'settingsProgressivePushDesc':
          'Aktuelle Stunde als dauerhafte Benachrichtigung anzeigen',
      'settingsDailyBriefingPush': 'Tagesbriefing-Benachrichtigung',
      'settingsDailyBriefingPushDesc':
          'Zeigt morgens eine kompakte Vorschau auf deinen Schultag',
      'settingsImportantChangesPush': 'Wichtige Änderungen',
      'settingsImportantChangesPushDesc':
          'Benachrichtigt bei Ausfällen, Raumwechseln und Vertretungen',
      'settingsRefreshPushWidgetNow': 'Push & Widget jetzt aktualisieren',
      'settingsRefreshPushWidgetNowDesc':
          'Lädt sofort die neuesten Daten aus dem API-Cache und aktualisiert Widget und Push',
      'settingsBackgroundLoading': 'Daten werden im Hintergrund geladen...',
      'settingsSectionUpdates': 'Updates',
      'settingsSectionAbout': 'Über die App',
      'appName': 'Untis+',
      'settingsAppVersion': 'Version',
      'settingsBuild': 'Build',
      'settingsSectionSubjects': 'Fächer & Farben',
      'settingsGithubRepoLabel': 'github.com/ninocss/UntisPlus',
      'settingsGithubUpdateCheck': 'Nach Updates im GitHub-Repo suchen',
      'settingsGithubUpdateCheckDesc':
          'Prüft das neueste Release von ninocss/UntisPlus.',
      'settingsGithubDirectDownload': 'Neueste Version direkt herunterladen',
      'settingsGithubDirectDownloadDesc':
          'Beim Prüfen wird die neueste APK/Release-Datei sofort geöffnet.',
      'settingsGithubChecking': 'Suche nach Updates...',
      'settingsGithubUpdateFound': 'Neues Release gefunden: {v}',
      'settingsGithubDownloadNow': 'Download',
      'settingsGithubNoDownloadAsset':
          'Kein direktes Download-Asset gefunden. Öffne Release-Seite...',
      'settingsGithubDownloadStarted':
          'Download/Release wurde im Browser geöffnet.',
      'settingsGithubOpenFailed': 'Konnte den Download-Link nicht öffnen.',
      'settingsGithubCheckFailed':
          'Update-Prüfung fehlgeschlagen. Bitte später erneut versuchen.',
      'settingsGithubNoUpdate': 'Du hast bereits die neueste Version.',
      'settingsGithubCurrentVersion': 'Installierte Version',
      'settingsGithubLatestVersion': 'Neueste Version',
      'settingsGithubInstallQuestion':
          'Möchtest du das Update jetzt herunterladen und installieren?',
      'settingsGithubInstallNow': 'Jetzt installieren',
      'settingsGithubInstallLater': 'Später',
      'settingsGithubInstallPrompted':
          'Download gestartet. Nach dem Download erscheint der Installationsdialog.',
      'settingsGithubOpenReleasePage': 'GitHub Release-Seite öffnen',
      'settingsBackupIncludeApiKeys': 'API-Keys einschließen',
      'settingsBackupIncludeApiKeysDesc':
          'Nur aktivieren, wenn das Backup sicher gespeichert wird.',
      'settingsBackupExportAllFile': 'Alle Einstellungen als Datei exportieren',
      'settingsBackupExportAllClipboard':
          'Alle Einstellungen in Zwischenablage kopieren',
      'settingsBackupImportAllTitle': 'Alle Einstellungen importieren',
      'settingsBackupImportAllFile': 'Aus Datei importieren',
      'settingsBackupImportAllClipboard': 'Aus Zwischenablage importieren',
      'settingsBackupExportDialogTitle': 'Einstellungen-Backup speichern',
      'settingsBackupExportSuccess': 'Backup-Datei gespeichert.',
      'settingsBackupExportClipboardSuccess':
          'Backup als JSON in Zwischenablage kopiert.',
      'settingsBackupImportSuccess': 'Backup importiert.',
      'settingsBackupImportFailed':
          'Import fehlgeschlagen. Bitte JSON und Schema prüfen.',
      'settingsBackupClipboardEmpty': 'Zwischenablage ist leer.',
      'settingsBackupConfirmTitle': 'Import bestätigen',
      'settingsBackupConfirmDesc':
          'Import überschreibt aktuelle Einstellungen und aktualisiert die App direkt.',
      'settingsBackupConfirmAction': 'Importieren',

      'aiSystemPersona':
          'Du bist "Plan-Assistent", ein freundlicher und motivierender KI-Helfer für Schüler*innen.',
      'aiSystemRules': '''REGELN:
- Antworte basierend auf den obigen Stundenplan- und Klausurendaten.
- Erfinde KEINE Fächer, Zeiten, Lehrer oder sonstige Informationen.
- Berücksichtige Prüfungen/Klausuren in deinen Antworten, wenn es thematisch passt.
- Wenn etwas aus den Daten nicht ableitbar ist, sage es offen.
- Beachte [FÄLLT AUS]-Markierungen (diese Stunden finden nicht statt).
- "Freistunden" = Lücken zwischen zwei Unterrichtsstunden.
- Antworte auf Deutsch, sei hilfreich, motivierend und auf den Punkt.
- Beginne nicht automatisch mit "Ja," – antworte direkt.
- Du darfst Markdown zur Formatierung verwenden (z.B. Listen, **fett**).''',

      'settingsChangelogTitle': 'Neuigkeiten (Changelog)',
      'settingsChangelogSubtitle': 'Was ist neu in Untis+?',
      'changelogTitle': 'Neuigkeiten',
      'changelogLoadError': 'Fehler beim Laden',
      'changelogRetry': 'Erneut versuchen',

      'aiNewSearch': 'Neue Suche',
      'aiSearchRunning': 'Suche läuft…',
      'aiSearchShapingDesc':
          'Die KI formt gerade Karten und Stundenblöcke aus deinem Stundenplan.',
      'aiStepAnalyzingTimetable': 'Analysiert den Stundenplan…',
      'aiStepSortingResults': 'Sortiert Ergebnisse…',
      'aiStepAlmostDone': 'Fast fertig…',
      'aiSearchHintPlaceholder': 'Stunden, Freistunden, Prüfungen …',
      'aiOverview': 'Übersicht',
      'aiEmptyPromptTitle': 'Was möchtest du wissen?',
      'aiEmptyPromptSubtitle':
          'Frag nach Stunden, Prüfungen oder freien Räumen.',
      'aiPromptWhenFinishToday': 'Wann ist heute Schluss?',
      'aiPromptWhatCancelledToday': 'Was fällt heute aus?',
      'aiPromptUpcomingExams': 'Welche Prüfungen hab ich bald?',
      'aiPromptFirstLessonToday': 'Was hab ich heute als erstes?',
      'aiPromptNextLesson': 'Wann ist meine nächste Stunde?',
      'aiPromptTomorrowSchedule': 'Was hab ich morgen?',
      'aiClearResult': 'Ergebnis leeren',
      'aiSearchAgain': 'Neu suchen',
      'aiClearInput': 'Leeren',
      'aiLessons': 'Stunden',
      'aiMore': 'Mehr',
      'aiSettingsMenu': 'KI-Einstellungen',
      'aiResultsCardDesc':
          'Ergebnisse werden als Karten und Stundenblöcke angezeigt.',
      'aiDismiss': 'Ausblenden',
      'aiLessonsCountSingle': '1 Stunde',
      'aiLessonsCountPlural': '{count} Stunden',
      'aiExamsCountWeekSingle': '1 Prüfung diese Woche',
      'aiExamsCountWeekPlural': '{count} Prüfungen diese Woche',

      'classPickerHeaderDesc':
          'Wähle einen Stundenplan aus. Favoriten werden oben angezeigt.',
      'classPickerDefaultBadge': 'Standard',
      'classPickerSetDefault': 'Als Standard festlegen',
      'classPickerOtherClasses': 'Andere Klassen',
      'classPickerRemoveFavorite': 'Favorit entfernen',
      'classPickerAddFavorite': 'Als Favorit speichern',

      'navGrades': 'Noten',
      'gradesTitle': 'Notentracker',
      'gradesAddTitle': 'Note hinzufügen',
      'gradesEditTitle': 'Note bearbeiten',
      'gradesSubjectLabel': 'Fach',
      'gradesGradeLabel': 'Note',
      'gradesWeightLabel': 'Gewichtung',
      'gradesTypeLabel': 'Art',
      'gradesAverage': 'Schnitt',
      'gradesTotal': 'Gesamt',
      'gradesBestSubject': 'Bestes Fach',
      'gradesAddDesc': 'Leistungsübersicht vervollständigen',
      'gradesCountPlural': 'Noten',
      'gradesWeightLabelShort': 'Gewicht',
      'gradesNone': 'Keine Noten',
      'gradesNoneHint': 'Tippe auf +, um deine erste Note einzutragen.',
    },

    // ── ENGLISH ───────────────────────────────────────────────────────────────
    'en': {
      'navWeek': 'Week',
      'navHomework': 'Homework',
      'navExams': 'Exams',
      'navInfo': 'Info',
      'navMenu': 'Menu',
    'navAi': 'AI',

      'loginServer': 'Server URL',
      'loginSchool': 'School',
      'loginUsername': 'Username',
      'loginPassword': 'Password',
      'loginLoginKey': 'Login key',
      'loginLoginKeyHint':
          'Use the WebUntis login key if your school signs in through Microsoft 365 or Office 365.',
      'loginCredentialModePassword': 'Password',
      'loginCredentialModeLoginKey': 'Login key',
      'loginButton': "Let's go",
      'loginFailed': 'Login failed. Check your credentials.',
      'loginConnectionError': 'Connection error',
      'loginSearchSchool': 'Search school',
      'loginSelectSchool': 'Select school',
      'loginSearchHint': 'School name or city...',
      'loginNoSchoolsFound': 'No schools found.',
      'loginChangeLanguage': 'Language',
      'loginManualEntry': 'Manual Entry',
      'loginSwitchToSearch': 'Back to search',
      'loginChangeSchool': 'Change school',
      'loginTwoFactorCode': '2FA code',
      'loginTwoFactorHint': 'Enter the 2FA code from your authenticator app.',
      'loginTwoFactorRequired':
          '2FA is enabled. Please enter your verification code.',
      'loginTwoFactorInvalid':
          'The 2FA code is invalid or expired. Please try again.',
      'loginVerifyButton': 'Verify',

      'onboardingWelcomeTitle': 'Welcome to Untis+',
      'onboardingChooseLanguageSubtitle': 'Choose your preferred language',
      'onboardingAppearanceTitle': 'Appearance',
      'onboardingAppearanceSubtitle': 'Make Untis+ look exactly how you want',
      'onboardingThemeSystem': 'System',
      'onboardingThemeLight': 'Light',
      'onboardingThemeDark': 'Dark',
      'onboardingAnimationsHint': 'Enable beautiful background animations',
      'onboardingSchoolLoginTitle': 'School Login',
      'onboardingSchoolLoginSubtitle': 'Connect your WebUntis account',
      'onboardingGeminiTitle': 'Gemini AI',
      'onboardingGeminiSubtitle': 'Chat with your schedule and homework',
      'onboardingGeminiInfo':
          'Get a free Gemini API key from Google AI Studio to unlock the powerful AI assistant in Untis+.',
      'onboardingGeminiGetApiKey': 'Get API Key',
      'onboardingSkip': 'Skip',
      'onboardingNext': 'Next',
      'onboardingGeminiEnterKeyOrSkip': 'Please enter a key or skip this step',
      'onboardingReadyTitle': 'Ready to go!',
      'onboardingReadySubtitle': 'Here is what you can do in Untis+',
      'onboardingFeatureTimetableTitle': 'Timetable & Calendar',
      'onboardingFeatureTimetableDesc': 'View your schedule flawlessly.',
      'onboardingFeatureExamsTitle': 'Exams & Homework',
      'onboardingFeatureExamsDesc':
          'Track progress, import exams, and export them as JSON.',
      'onboardingFeatureAiTitle': 'AI Assistant',
      'onboardingFeatureAiDesc':
          'Ask Gemini about your day, homework or exams.',
      'onboardingFeatureNotifyTitle': 'Notifications & Widgets',
      'onboardingFeatureNotifyDesc': 'Stay updated before school starts.',
      'onboardingFinishSetup': 'Finish Setup',
      'onboardingUseDemoMode': 'Start demo mode',
      'onboardingUseDemoModeDesc':
          'Try Untis+ without school login using realistic sample data.',
      'tutorialTitle': 'Quick app tutorial',
      'tutorialSkip': 'Skip tutorial',
      'tutorialDone': 'Finish tutorial',
      'tutorialStepWeekTitle': '1. Timetable',
      'tutorialStepWeekDesc':
          'Tap the large clock button to switch to your weekly timetable.',
      'tutorialStepExamsTitle': '2. Exams',
      'tutorialStepExamsDesc':
          'Tap the exams button to view, import, and export exams.',
      'tutorialStepInfoTitle': '3. School info',
      'tutorialStepInfoDesc':
          'Tap the info button to view current announcements from your school.',
      'tutorialStepSettingsTitle': '4. Settings',
      'tutorialStepSettingsDesc':
          'Tap the settings button to customize language, design and notifications.',
      'tutorialStepFinishTitle': 'Done!',
      'tutorialStepFinishDesc':
          'You now know all core sections of the app. Have fun with Untis+!',

      'timetableTitle': 'Timetable',
      'timetablePrevWeek': 'Previous week',
      'timetableNextWeek': 'Next week',
      'timetableWeekView': 'Week view',
      'timetableDayGrid': 'Day grid',
      'timetableNotLoaded': 'Timetable not loaded',
      'timetableReload': 'Reload',
      'timetableSelectClass': 'Select class',
      'timetableMyTimetable': 'My timetable',
      'timetableSelectAnother': 'Another class',
      'timetableNoClassesFound': 'No classes found or access denied.',
      'freeRoomsTitle': 'Free Rooms',
      'freeRoomsSelectTime': 'Select time range',
      'freeRoomsNoneFound': 'No free rooms found for this time range.',
      'freeRoomsNoRangesHint':
          'No suitable time ranges found for the current day.',
      'freeRoomsCount': '{n} free rooms',
      'weekDayShort': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      'weekDayFull': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      'noLesson': '(no lessons)',

      'detailTime': 'Time',
      'detailTeacher': 'Teacher',
      'detailRoom': 'Room',
      'detailClass': 'Class',
      'detailLesson': 'Lesson',
      'detailInfo': 'Note',
      'detailNotesForStudents': 'Notes for students',
      'detailLessonNotes': 'Lesson notes',
      'detailHomework': 'Homework',
      'detailCancelled': 'CANCELLED',
      'detailRegular': 'Regular lesson',
      'detailHideSubject': 'Permanently hide subject',
      'detailCancelledBadge': 'CANCELLED',

      'examsTitle': 'Exams',
      'examsReload': 'Reload',
      'examsNone': 'No exams found',
      'examsNoneHint': 'Tap + to add an exam.',
      'examsUpcoming': 'Upcoming',
      'examsPast': 'Past',
      'examsAdd': '',
      'examsAddTitle': 'Add exam',
      'examsEditTitle': 'Edit exam',
      'examsSubjectLabel': 'Subject / Title *',
      'examsTypeLabel': 'Type (e.g. test, quiz)',
      'examsNotesLabel': 'Notes / Topics',
      'examsSave': 'Save',
      'examsCancel': 'Cancel',
      'examsDelete': 'Delete',
      'examsToday': 'Today',
      'examsTomorrow': 'Tomorrow',
      'examsDaysIn': 'in {n} days',
      'examsOwn': 'Custom',
      'examsUnknown': '(unknown)',
      'examsNoneEntered': 'No exams entered.',
      'examsImportTitle': 'Upload exam schedule',
      'examsImportCamera': 'Camera',
      'examsImportGallery': 'Gallery',
      'examsImportFile': 'PDF / File',
      'examsImportSuccess': 'Successfully imported!',
      'examsImportError': 'Import error: ',
      'examsImportInvalidJson': 'No valid JSON found.',
      'examsExportSuccess': 'Exams copied as JSON to clipboard.',
      'examsExportEmpty': 'No custom exams to export.',
      'examsActionCustom': 'Manual',
      'examsActionImport': 'Import (Scan/PDF)',
      'examsActionExport': 'Export (JSON)',
      'examsActionScan': 'Scan',

      'homeworkTitle': 'Homework',
      'homeworkReload': 'Reload',
      'homeworkNone': 'No homework found',
      'homeworkNoneHint': "You're all done! Enjoy your free time.",
      'homeworkMarkDone': 'Mark as done',
      'homeworkMarkUndone': 'Mark as undone',
      'homeworkDue': 'Due on',

      'infoTitle': 'School Info',
      'infoReload': 'Reload',
      'infoUpdated': 'Updated',
      'infoEmpty': 'No current notifications',
      'infoEmptyHint':
          'If your school has not published anything at the moment, nothing is shown here.',
      'infoFetchError': 'Could not load notifications. Please try again later.',
      'infoOpenLink': 'Open link',
      'notificationActionCurrentLesson': 'Current lesson: {lesson}',
      'notificationActionNextLesson': 'Next lesson: {lesson}',
      'notificationActionNoNextLesson': 'No next lesson found for today',

      'aiTitle': 'AI Assistant',
      'aiTabAnalysis': 'Analysis',
      'aiTabChat': 'Chat',
      'aiInputHint': 'Ask a question…',
      'aiKnowsSchedule': 'I know your timetable!',
      'aiAskAnything': 'Ask me anything about your week.',
      'aiNoApiKey':
          '⚠️ Please enter your API key under Settings → AI Assistant.',
      'aiNoReply': '⚠️ No reply received.',
      'aiApiError': '⚠️ API error:',
      'aiConnectionError': '⚠️ Connection error:',
      'aiCustomBaseUrlMissing':
          '⚠️ Please configure the custom base URL in AI settings first.',
      'aiSuggestions': [
        "What do I have tomorrow?",
        "Do I have a free period today?",
        "When does school end tomorrow?",
        "Is anything cancelled today?",
      ],

      'settingsTitle': 'Settings',
      'settingsLoggedInAs': 'Logged in as',
      'settingsLogout': 'Sign out',
      'settingsSectionQuick': 'Quick Controls',
      'settingsSectionGeneral': 'App',
      'settingsAppearance': 'Appearance',
      'settingsAppearanceDesc': 'System (Light/Dark)',
      'settingsLanguage': 'Language',
      'settingsSectionAI': 'AI Assistant',
      'settingsAiProvider': 'Provider',
      'settingsAiProviderGemini': 'Google Gemini',
      'settingsAiProviderOpenAi': 'OpenAI',
      'settingsAiProviderMistral': 'Mistral AI',
      'settingsAiProviderCustom': 'Custom Provider',
      'settingsAiProviderLocal': 'Local (On-Device)',
      'settingsAiModel': 'Model',
      'settingsAiApiKey': 'API Key',
      'settingsAiApiKeyNotSet': 'Not configured - tap to set up',
      'settingsAiApiKeyDialogDesc':
          'Required for the AI assistant. Use “Get API Key” to open the correct page for the selected provider.',
      'settingsAiApiKeyGet': 'Get API Key',
      'settingsAiApiKeyOpenFailed': 'Could not open the API key page.',
      'settingsAiPrompt': 'System Prompt',
      'settingsAiPromptDesc':
          'Edit the default prompt and use variables like [timetable].',
      'settingsAiPromptEditTitle': 'Edit system prompt',
      'settingsAiPromptReset': 'Reset to default',
      'settingsAiPromptVariables': 'Prompt Variables',
      'settingsAiPromptVariablesDesc':
          'All placeholders that are automatically replaced with app data.',
      'settingsAiLocalModel': 'Local Model',
      'settingsAiLocalModelDesc': 'Select and download a model for on-device inference.',
      'settingsAiLocalModelDownload': 'Download',
      'settingsAiLocalModelDownloading': 'Downloading…',
      'settingsAiLocalModelInstalled': 'Installed',
      'settingsAiLocalModelDelete': 'Delete',
      'settingsAiLocalModelActive': 'Active',
      'settingsAiLocalModelError': 'Download failed.',
      'aiLocalModelExamNotSupported':
          'Local models do not support importing exam images. Please choose an online provider.',
      'aiLocalModelLoadError':
          'Local model could not be loaded. Please download it again.',
      'settingsAiLocalModelSize': 'Size: {size} GB',
      'settingsAiLocalModelDeleteConfirm': 'Delete this model?',
      'aiVar_today': 'Today\'s date in local format',
      'aiVar_today_iso': 'Today\'s date in YYYY-MM-DD format',
      'aiVar_locale': 'Active app language (e.g. de, en)',
      'aiVar_school_name': 'School name',
      'aiVar_school_url': 'School server/domain',
      'aiVar_person_type': 'WebUntis person type as number',
      'aiVar_person_id': 'WebUntis person ID',
      'aiVar_demo_mode': 'true if demo mode is active',
      'aiVar_current_monday': 'Monday of the loaded week (DD.MM.YYYY)',
      'aiVar_current_friday': 'Friday of the loaded week (DD.MM.YYYY)',
      'aiVar_day_summary_today': 'Brief summary for today',
      'aiVar_day_summary_tomorrow': 'Brief summary for tomorrow',
      'aiVar_timetable': 'Formatted timetable for the current week',
      'aiVar_timetable_json': 'Raw timetable data as JSON',
      'aiVar_exams': 'Formatted list of upcoming exams',
      'aiVar_exams_json': 'Exam data as JSON',
      'settingsAiCustomBaseUrl': 'Custom Base URL',
      'settingsAiCustomBaseUrlDesc':
          'Base URL of your own provider (OpenAI-compatible or Gemini-compatible).',
      'settingsAiCustomBaseUrlHint': 'https://api.your-provider.tld/v1',
      'settingsAiCompatibility': 'Custom compatibility',
      'settingsAiCompatibilityOpenAi': 'OpenAI-compatible',
      'settingsAiCompatibilityGemini': 'Gemini-compatible',
      'settingsApiKey': 'Gemini API Key',
      'settingsApiKeyNotSet': 'Not configured — Tap to set up',
      'settingsApiKeyDialogTitle': 'Gemini API Key',
      'settingsApiKeyDialogDesc':
          'Required for the AI assistant. Find your key at aistudio.google.com/app/apikey.',
      'settingsApiKeySave': 'Save',
      'settingsApiKeyRemove': 'Remove',
      'settingsApiKeyCancel': 'Cancel',
      'settingsSectionHidden': 'Hidden Subjects',
      'settingsNoHidden': 'No subjects hidden',
      'settingsNoHiddenDesc': 'Tap a lesson to hide it.',
      'settingsUnhide': 'Show',
      'settingsHiddenCount': '{n} subject(s) hidden',
      'settingsSectionColors': 'Subject Colors',
      'settingsColorsDesc': 'Tap a subject to choose a color.',
      'settingsNoSubjectsLoaded': 'No subjects loaded',
      'settingsNoSubjectsLoadedDesc': 'Open your timetable first.',
      'settingsCustomColor': 'Custom',
      'settingsDefaultColor': 'Default color',
      'settingsColorFor': 'Color for "{s}"',
      'settingsColorReset': 'Reset to default',
      'settingsColorCustomPicker': 'Pick custom color',
      'settingsColorApply': 'Apply color',
      'settingsColorRed': 'Red',
      'settingsColorGreen': 'Green',
      'settingsColorBlue': 'Blue',
      'settingsThemeMode': 'Color scheme',
      'settingsThemeLight': 'Light',
      'settingsThemeSystem': 'System',
      'settingsThemeDark': 'Dark',
      'settingsSectionTimetable': 'Timetable',
      'settingsShowCancelled': 'Show cancelled lessons',
      'settingsShowCancelledDesc':
          'Cancelled lessons are shown in the timetable',
      'settingsCancelledColor': 'Cancelled color',
      'settingsCancelledColorDesc': 'Customize the color for cancelled lessons',
      'settingsLessonDesignTitle': 'Lesson & Card Design',
      'settingsLessonDesignDesc': 'Customize card styles, glow, blur, and layout details.',
      'settingsLessonStyle': 'Card Style',
      'settingsLessonStyleDesc': 'Choose the visual aesthetic for timetable lessons.',
      'settingsLessonStyleModern': 'Modern (Tinted)',
      'settingsLessonStyleGlass': 'Frosted Glass',
      'settingsLessonStyleGradient': 'Gradient',
      'settingsLessonStyleOutline': 'Outline / Minimal',
      'settingsLessonStyleSolid': 'Solid Fill',
      'settingsLessonGlow': 'Glow Aura Effect',
      'settingsLessonGlowDesc': 'Adds an ambient glowing aura behind lesson cards.',
      'settingsLessonGlowMode': 'Glow Mode',
      'settingsLessonGlowModeActive': 'Active lesson only',
      'settingsLessonGlowModeAll': 'All lessons',
      'settingsLessonGlowIntensity': 'Glow Intensity',
      'settingsLessonBlur': 'Frosted Glass Blur',
      'settingsLessonBlurDesc': 'Blur the wallpaper background behind lesson cards.',
      'settingsLessonBlurAmount': 'Blur Strength',
      'settingsLessonCardOpacity': 'Card Opacity',
      'settingsLessonBorderRadius': 'Corner Radius',
      'settingsLessonAccentStyle': 'Accent Indicator',
      'settingsLessonAccentBar': 'Classic Bar',
      'settingsLessonAccentThin': 'Thin Line',
      'settingsLessonAccentDot': 'Dot Badge',
      'settingsLessonAccentNone': 'None',
      'settingsLessonShowTeacher': 'Show Teacher',
      'settingsLessonShowTeacherDesc': 'Display teacher name or initials on the card.',
      'settingsLessonShowRoom': 'Show Room',
      'settingsLessonShowRoomDesc': 'Display room number on the card.',
      'settingsLessonCompactMode': 'Compact View',
      'settingsLessonCompactModeDesc': 'Tighter padding and fonts for dense timetables.',
      'settingsLessonDimPast': 'Dim Past Lessons',
      'settingsLessonDimPastDesc': 'Grayscale and dim completed lessons during the day.',
      'settingsLessonCancelledPattern': 'Cancellation Stripes',
      'settingsLessonCancelledPatternDesc': 'Show a diagonal stripe pattern on cancelled lessons.',
      'settingsLessonPreviewRegular': 'Regular',
      'settingsLessonPreviewActive': 'Active Lesson',
      'settingsLessonPreviewCancelled': 'Cancelled',
      'settingsLessonPreviewHeader': 'Live Preview',
      'settingsMonochromeLessons': 'Monochrome lessons',
      'settingsMonochromeLessonsDesc':
          'Use Material You colors instead of individual subject colors',
      'settingsDemoMode': 'Demo mode',
      'settingsDemoModeDesc':
          'Uses local demo data instead of school servers (active instantly).',
      'settingsBackgroundAnimations': 'Background Animations',
      'settingsBackgroundAnimationsDesc':
          'Show animated gradient effects in the background',
      'settingsBackgroundGyroscope': 'Gyroscope reaction',
      'settingsBackgroundGyroscopeDesc':
          'Lets backgrounds react to device movement',
      'settingsBackgroundStyle': 'Animation Style',
      'settingsBackgroundStyleOrbs': 'Orbs',
      'settingsBackgroundStyleSpace': 'Space',
      'settingsBackgroundStyleBubbles': 'Bubbles',
      'settingsBackgroundStyleLines': 'Lines',
      'settingsBackgroundStyleThreeD': '3D Forms',
      'settingsBackgroundStyleNebula': 'Nebula',
      'settingsBackgroundStylePrism': 'Prism',
      'settingsBackgroundStyleWaves': 'Waves',
      'settingsBackgroundStyleGrid': 'Grid',
      'settingsBackgroundStyleRings': 'Rings',
      'settingsBackgroundStyleCustom': 'Custom',
      'settingsCustomBackgrounds': 'Custom backgrounds',
      'settingsCustomBackgroundsDesc': 'Create, save, import & export',
      'settingsCustomBackgroundsSelected': 'Selected: {name}',

      'bgEditorTitle': 'Background Editor',
      'bgEditorPreviewTab': 'Preview',
      'bgEditorDesignTab': 'Design',
      'bgEditorLibraryTab': 'Library',
      'bgEditorStartPoints': 'Start points',
      'bgEditorUpdatedAt': 'Updated',
      'bgEditorEdit': 'Edit',
      'bgEditorUndo': 'Undo',
      'bgEditorRedo': 'Redo',
      'bgEditorRandomize': 'Random',
      'bgEditorUnsavedTitle': 'Unsaved changes',
      'bgEditorUnsavedDesc': 'Save changes, discard them, or keep editing?',
      'bgEditorDiscard': 'Discard',
      'bgEditorLivePreview': 'Live preview',
      'bgEditorSave': 'Save',
      'bgEditorSaved': 'Saved.',
      'bgEditorSaveFailed': 'Save failed.',
      'bgEditorUseInApp': 'Use in app',
      'bgEditorApplied': 'Applied as background.',
      'bgEditorLibrary': 'Library',
      'bgEditorNew': 'New',
      'bgEditorNewName': 'New background',
      'bgEditorDuplicate': 'Duplicate',
      'bgEditorDelete': 'Delete',
      'bgEditorDeleteTitle': 'Delete background?',
      'bgEditorDeleteDesc': 'This background will be removed permanently.',
      'bgEditorDeleteConfirm': 'Delete',

      'bgEditorExportTitle': 'Export',
      'bgEditorExportSelected': 'Export selected',
      'bgEditorExportAll': 'Export all',
      'bgEditorExported': 'JSON copied to clipboard.',
      'bgEditorExportedAll': 'All backgrounds copied as JSON.',

      'bgEditorImportTitle': 'Import',
      'bgEditorImportFromClipboard': 'From clipboard',
      'bgEditorImportFromFile': 'From file',
      'bgEditorImportClipboardEmpty': 'Clipboard is empty.',
      'bgEditorImportedCount': 'Imported {n} background(s).',
      'bgEditorImportFailed': 'Import failed.',

      'bgEditorMeta': 'Metadata',
      'bgEditorName': 'Name',
      'bgEditorBase': 'Base gradient',
      'bgEditorUseThemeColors': 'Use theme colors',
      'bgEditorUseThemeColorsDesc': 'Uses colors from the current theme.',
      'bgEditorGradientLinear': 'Linear',
      'bgEditorGradientRadial': 'Radial',
      'bgEditorBaseOpacity': 'Base opacity',
      'bgEditorGradientAngle': 'Angle',
      'bgEditorRadialCenterX': 'Center X',
      'bgEditorRadialCenterY': 'Center Y',
      'bgEditorRadialRadius': 'Radius',
      'bgEditorColorN': 'Color {n}',

      'bgEditorOrbs': 'Orbs',
      'bgEditorOrbsEnabled': 'Enable orbs',
      'bgEditorOrbsThemeDesc': 'Uses theme colors for orbs.',
      'bgEditorRandomizeSeed': 'Randomize seed',
      'bgEditorOrbsCount': 'Count',
      'bgEditorOrbsSize': 'Size',
      'bgEditorOrbsVariance': 'Variance',
      'bgEditorOrbsOpacity': 'Opacity',
      'bgEditorOrbsSoftness': 'Softness',
      'bgEditorOrbColorN': 'Orb color {n}',

      'bgEditorEffects': 'Pattern & effects',
      'bgEditorPatternNone': 'None',
      'bgEditorPatternLines': 'Lines',
      'bgEditorPatternGrid': 'Grid',
      'bgEditorPatternOpacity': 'Pattern opacity',
      'bgEditorPatternScale': 'Scale',
      'bgEditorPatternAngle': 'Pattern angle',
      'bgEditorNoise': 'Noise',
      'bgEditorVignette': 'Vignette',

      'bgEditorMotion': 'Motion',
      'bgEditorAnimate': 'Animate',
      'bgEditorSpeed': 'Speed',
      'bgEditorParallax': 'Parallax',

      'bgEditorAiTitle': 'AI Generator',
      'bgEditorAiDesc': 'Describe a look — AI creates a new background.',
      'bgEditorAiHint': 'e.g. “neon nebula, soft, dark, blue/pink”',
      'bgEditorAiGenerate': 'Generate with AI',
      'bgEditorAiSystem': '''
You generate ONE Flutter background preset.
Output ONLY valid JSON (no markdown, no commentary).

Return a single JSON object with this schema:
{
    "version": 1,
    "name": "...",
    "base": {
        "type": "linear"|"radial",
        "useThemeColors": true|false,
        "colors": ["#RRGGBB", ...],
        "opacity": 0.0-1.0,
        "angleDeg": 0-360,
        "centerX": -1..1,
        "centerY": -1..1,
        "radius": 0.3-2.5
    },
    "orbs": {
        "enabled": true|false,
        "useThemeColors": true|false,
        "colors": ["#RRGGBB", ...],
        "count": 0-18,
        "seed": 0-2147483647,
        "size": 40-480,
        "sizeVariance": 0.0-1.0,
        "opacity": 0.0-1.0,
        "softness": 0.0-1.0
    },
    "pattern": {
        "type": "none"|"lines"|"grid",
        "opacity": 0.0-1.0,
        "scale": 0.4-3.5,
        "angleDeg": 0-360
    },
    "noise": 0.0-0.5,
    "vignette": 0.0-1.0,
    "animate": true|false,
    "animationSpeed": 0.0-3.0,
    "parallaxStrength": 0.0-1.0
}

Keep values reasonable and visually pleasing. Prefer 2-3 base colors.
Use "useThemeColors": true unless the prompt asks for specific colors.
''',
      'bgEditorAiUserPrefix': 'Description:',
      'bgEditorAiUserSchemaHint':
          'Return JSON only. Do not wrap in code fences.',
      'bgEditorAiGeneratedName': 'AI Background',
      'bgEditorAiSuccess': 'AI background created.',
      'bgEditorAiError': 'AI: ',
      'settingsGlassEffect': 'Blur Effect',
      'settingsGlassEffectDesc':
          'Enables blur effects across the interface',
      'settingsPageTransition': 'Page Transition',
      'settingsPageTransitionDesc': 'Choose the transition style for page navigation',
      'settingsUseMaterialYou': 'Material You',
      'settingsUseMaterialYouDesc': 'Automatically adapt to your system accent color',
      'settingsCustomColorSeed': 'Custom color',
      'settingsPageTransitionBounce': 'Bounce',
      'settingsPageTransitionFade': 'Fade',
      'settingsPageTransitionSlide': 'Slide',
      'settingsPageTransitionZoom': 'Zoom',
      'settingsPageTransitionBlur': 'Blur',
      'settingsPageTransitionEaseIn': 'Ease In',
      'settingsPageTransitionEaseOut': 'Ease Out',
      'settingsPageTransitionExpo': 'Expo',
      'settingsProgressivePush': 'Progressive push notification',
      'settingsProgressivePushDesc':
          'Show the current lesson as a persistent notification',
      'settingsDailyBriefingPush': 'Daily briefing notification',
      'settingsDailyBriefingPushDesc':
          'Shows a compact preview of your school day in the morning',
      'settingsImportantChangesPush': 'Important changes',
      'settingsImportantChangesPushDesc':
          'Notifies you about cancellations, room changes, and substitutions',
      'settingsRefreshPushWidgetNow': 'Refresh push & widget now',
      'settingsRefreshPushWidgetNowDesc':
          'Immediately loads the newest data from the API cache and updates widget and push',
      'settingsBackgroundLoading': 'Data is loading in the background...',
      'settingsSectionUpdates': 'Updates',
      'settingsSectionAbout': 'About',
      'appName': 'Untis+',
      'settingsAppVersion': 'Version',
      'settingsBuild': 'Build',
      'settingsSectionSubjects': 'Subjects & Colors',
      'settingsGithubRepoLabel': 'github.com/ninocss/UntisPlus',
      'settingsGithubUpdateCheck': 'Check for updates on GitHub',
      'settingsGithubUpdateCheckDesc':
          'Checks the latest release from ninocss/UntisPlus.',
      'settingsGithubDirectDownload': 'Download latest version directly',
      'settingsGithubDirectDownloadDesc':
          'When checking, immediately opens the newest APK/release file.',
      'settingsGithubChecking': 'Checking for updates...',
      'settingsGithubUpdateFound': 'New release found: {v}',
      'settingsGithubDownloadNow': 'Download',
      'settingsGithubNoDownloadAsset':
          'No direct download asset found. Opening release page...',
      'settingsGithubDownloadStarted':
          'Download/release has been opened in your browser.',
      'settingsGithubOpenFailed': 'Could not open the download link.',
      'settingsGithubCheckFailed':
          'Update check failed. Please try again later.',
      'settingsGithubNoUpdate': 'You already have the latest version.',
      'settingsGithubCurrentVersion': 'Installed version',
      'settingsGithubLatestVersion': 'Latest version',
      'settingsGithubInstallQuestion':
          'Do you want to download and install this update now?',
      'settingsGithubInstallNow': 'Install now',
      'settingsGithubInstallLater': 'Later',
      'settingsGithubInstallPrompted':
          'Download started. The installation prompt appears after download.',
      'settingsGithubOpenReleasePage': 'Open GitHub release page',
      'settingsHubNotifications': 'Notifications & Widgets',
      'settingsHubDataBackup': 'Data & Backup',
      'settingsHubDataBackupDesc': 'Back up all app settings',
      'settingsHubAccount': 'Account & Demo',
      'settingsHubUpdatesAbout': 'Updates & About',
      'settingsBackupIncludeApiKeys': 'Include API keys',
      'settingsBackupIncludeApiKeysDesc':
          'Only enable this if you store the backup securely.',
      'settingsBackupExportAllFile': 'Export all settings to file',
      'settingsBackupExportAllClipboard': 'Copy all settings to clipboard',
      'settingsBackupImportAllTitle': 'Import all settings',
      'settingsBackupImportAllFile': 'Import from file',
      'settingsBackupImportAllClipboard': 'Import from clipboard',
      'settingsBackupExportDialogTitle': 'Save settings backup',
      'settingsBackupExportSuccess': 'Backup file saved.',
      'settingsBackupExportClipboardSuccess':
          'Backup JSON copied to clipboard.',
      'settingsBackupImportSuccess': 'Backup imported.',
      'settingsBackupImportFailed':
          'Import failed. Please validate JSON and schema.',
      'settingsBackupClipboardEmpty': 'Clipboard is empty.',
      'settingsBackupConfirmTitle': 'Confirm import',
      'settingsBackupConfirmDesc':
          'Import will overwrite current settings and immediately refresh the app state.',
      'settingsBackupConfirmAction': 'Import',

      'aiSystemPersona':
          'You are "Schedule Assistant", a friendly and motivating AI helper for students.',
      'aiSystemRules': '''RULES:
- Answer based on the timetable and exam data above.
- Do NOT invent subjects, times, teachers or other information.
- Consider exams/tests in your answers if applicable.
- If something cannot be derived from the data, say so openly.
- Respect [CANCELLED] markers (those lessons do not take place).
- "Free periods" = gaps between two lessons.
- Answer in English, be helpful, motivating, and concise.
- Do not start automatically with "Yes," – answer directly.
- You may use Markdown for formatting (e.g. lists, **bold**).''',

      'settingsChangelogTitle': "What's New (Changelog)",
      'settingsChangelogSubtitle': 'What is new in Untis+?',
      'changelogTitle': "What's New",
      'changelogLoadError': 'Failed to load',
      'changelogRetry': 'Try again',

      'aiNewSearch': 'New search',
      'aiSearchRunning': 'Search running…',
      'aiSearchShapingDesc':
          'The AI is shaping cards and lesson blocks from your timetable.',
      'aiStepAnalyzingTimetable': 'Analyzing timetable…',
      'aiStepSortingResults': 'Sorting results…',
      'aiStepAlmostDone': 'Almost done…',
      'aiSearchHintPlaceholder': 'Lessons, free periods, exams …',
      'aiOverview': 'Overview',
      'aiEmptyPromptTitle': 'What do you want to know?',
      'aiEmptyPromptSubtitle': 'Ask about lessons, exams or free rooms.',
      'aiPromptWhenFinishToday': 'When do I finish today?',
      'aiPromptWhatCancelledToday': 'What is cancelled today?',
      'aiPromptUpcomingExams': 'Which exams are coming up?',
      'aiPromptFirstLessonToday': 'What is my first lesson today?',
      'aiPromptNextLesson': 'When is my next lesson?',
      'aiPromptTomorrowSchedule': 'What do I have tomorrow?',
      'aiClearResult': 'Clear result',
      'aiSearchAgain': 'Search again',
      'aiClearInput': 'Clear',
      'aiLessons': 'Lessons',
      'aiMore': 'More',
      'aiSettingsMenu': 'AI settings',
      'aiResultsCardDesc': 'Results appear as cards and lesson blocks.',
      'aiDismiss': 'Dismiss',
      'aiLessonsCountSingle': '1 lesson',
      'aiLessonsCountPlural': '{count} lessons',
      'aiExamsCountWeekSingle': '1 exam this week',
      'aiExamsCountWeekPlural': '{count} exams this week',

      'classPickerHeaderDesc':
          'Select a timetable. Favorites are shown at the top.',
      'classPickerDefaultBadge': 'Default',
      'classPickerSetDefault': 'Set as default',
      'classPickerOtherClasses': 'Other classes',
      'classPickerRemoveFavorite': 'Remove favorite',
      'classPickerAddFavorite': 'Add to favorites',

      'navGrades': 'Grades',
      'gradesTitle': 'Grade Tracker',
      'gradesAddTitle': 'Add grade',
      'gradesEditTitle': 'Edit grade',
      'gradesSubjectLabel': 'Subject',
      'gradesGradeLabel': 'Grade',
      'gradesWeightLabel': 'Weight',
      'gradesTypeLabel': 'Type',
      'gradesAverage': 'Average',
      'gradesTotal': 'Total',
      'gradesBestSubject': 'Best Subject',
      'gradesAddDesc': 'Complete your grade overview',
      'gradesCountPlural': 'Grades',
      'gradesWeightLabelShort': 'Weight',
      'gradesNone': 'No grades',
      'gradesNoneHint': 'Tap + to add your first grade.',
    },

    // ── FRENCH ────────────────────────────────────────────────────────────────
    'fr': {
      'navWeek': 'Semaine',
      'navHomework': 'Devoirs',
      'navExams': 'Examens',
      'navInfo': 'Infos',
      'navMenu': 'Menu',
      'navAi': 'IA',

      'loginServer': 'URL du serveur',
      'loginSchool': 'École',
      'loginUsername': "Nom d'utilisateur",
      'loginPassword': 'Mot de passe',
      'loginLoginKey': 'Clé de connexion',
      'loginLoginKeyHint':
          'Utilise la clé de connexion WebUntis si ton école se connecte via Microsoft 365 ou Office 365.',
      'loginCredentialModePassword': 'Mot de passe',
      'loginCredentialModeLoginKey': 'Clé de connexion',
      'loginButton': 'Commencer',
      'loginFailed': 'Connexion échouée. Vérifie tes données.',
      'loginConnectionError': 'Erreur de connexion',
      'loginSearchSchool': 'Rechercher une école',
      'loginSelectSchool': "Sélectionner l'école",
      'loginSearchHint': "Nom de l'école ou ville...",
      'loginNoSchoolsFound': 'Aucune école trouvée.',
      'loginChangeLanguage': 'Langue',
      'loginManualEntry': 'Saisie manuelle',
      'loginSwitchToSearch': 'Retour à la recherche',
      'loginChangeSchool': 'Changer d\'école',
      'loginTwoFactorCode': 'Code 2FA',
      'loginTwoFactorHint':
          'Saisis le code 2FA depuis ton application d\'authentification.',
      'loginTwoFactorRequired':
          'Le 2FA est activé. Veuillez saisir votre code de vérification.',
      'loginTwoFactorInvalid': 'Le code 2FA est invalide ou expiré. Réessaie.',
      'loginVerifyButton': 'Vérifier',

      'onboardingWelcomeTitle': 'Bienvenue sur Untis+',
      'onboardingChooseLanguageSubtitle': 'Choisis ta langue préférée',
      'onboardingAppearanceTitle': 'Apparence',
      'onboardingAppearanceSubtitle':
          'Personnalise Untis+ exactement comme tu veux',
      'onboardingThemeSystem': 'Système',
      'onboardingThemeLight': 'Clair',
      'onboardingThemeDark': 'Sombre',
      'onboardingAnimationsHint':
          'Activer de belles animations d\'arrière-plan',
      'onboardingSchoolLoginTitle': 'Connexion école',
      'onboardingSchoolLoginSubtitle': 'Connecte ton compte WebUntis',
      'onboardingGeminiTitle': 'Gemini IA',
      'onboardingGeminiSubtitle':
          'Discute avec ton emploi du temps et tes devoirs',
      'onboardingGeminiInfo':
          'Obtiens une clé API Gemini gratuite depuis Google AI Studio pour débloquer le puissant assistant IA dans Untis+.',
      'onboardingGeminiGetApiKey': 'Obtenir une clé API',
      'onboardingSkip': 'Passer',
      'onboardingNext': 'Suivant',
      'onboardingGeminiEnterKeyOrSkip': 'Saisis une clé ou passe cette étape',
      'onboardingReadyTitle': 'Prêt à commencer !',
      'onboardingReadySubtitle': 'Voici ce que tu peux faire dans Untis+',
      'onboardingFeatureTimetableTitle': 'Emploi du temps & Calendrier',
      'onboardingFeatureTimetableDesc': 'Consulte ton planning sans effort.',
      'onboardingFeatureExamsTitle': 'Examens & Devoirs',
      'onboardingFeatureExamsDesc':
          'Suis ta progression, importe des examens et exporte-les en JSON.',
      'onboardingFeatureAiTitle': 'Assistant IA',
      'onboardingFeatureAiDesc':
          'Demande à Gemini des infos sur ta journée, tes devoirs ou tes examens.',
      'onboardingFeatureNotifyTitle': 'Notifications & Widgets',
      'onboardingFeatureNotifyDesc': 'Reste informé avant le début des cours.',
      'onboardingFinishSetup': 'Terminer la configuration',
      'onboardingUseDemoMode': 'Lancer le mode démo',
      'onboardingUseDemoModeDesc':
          'Teste Untis+ sans connexion école avec des données réalistes.',
      'tutorialTitle': 'Tutoriel rapide de l\'app',
      'tutorialSkip': 'Passer le tutoriel',
      'tutorialDone': 'Terminer le tutoriel',
      'tutorialStepWeekTitle': '1. Emploi du temps',
      'tutorialStepWeekDesc':
          'Appuie sur le grand bouton horloge pour ouvrir la vue semaine.',
      'tutorialStepExamsTitle': '2. Examens',
      'tutorialStepExamsDesc':
          'Appuie sur le bouton examens pour voir, importer et exporter des examens.',
      'tutorialStepInfoTitle': '3. Infos école',
      'tutorialStepInfoDesc':
          'Appuie sur le bouton infos pour lire les annonces de ton école.',
      'tutorialStepSettingsTitle': '4. Paramètres',
      'tutorialStepSettingsDesc':
          'Appuie sur le bouton paramètres pour ajuster la langue, le design et les notifications.',
      'tutorialStepFinishTitle': 'Terminé !',
      'tutorialStepFinishDesc':
          'Tu connais maintenant toutes les zones principales de l\'app. Amuse-toi avec Untis+ !',

      'timetableTitle': 'Emploi du temps',
      'timetablePrevWeek': 'Semaine précédente',
      'timetableNextWeek': 'Semaine suivante',
      'timetableWeekView': 'Vue semaine',
      'timetableDayGrid': 'Grille journalière',
      'timetableNotLoaded': "Emploi du temps non chargé",
      'timetableReload': 'Recharger',
      'timetableSelectClass': 'Sélectionner une classe',
      'timetableMyTimetable': 'Mon emploi du temps',
      'timetableSelectAnother': 'Autre classe',
      'timetableNoClassesFound': 'Aucune classe trouvée ou accès refusé.',
      'freeRoomsTitle': 'Salles libres',
      'freeRoomsSelectTime': 'Choisir une plage horaire',
      'freeRoomsNoneFound':
          'Aucune salle libre trouvée pour cette plage horaire.',
      'freeRoomsNoRangesHint':
          'Aucune plage horaire adaptée trouvée pour ce jour.',
      'freeRoomsCount': '{n} salles libres',
      'weekDayShort': ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven'],
      'weekDayFull': ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'],
      'noLesson': '(pas de cours)',

      'detailTime': 'Heure',
      'detailTeacher': 'Enseignant',
      'detailRoom': 'Salle',
      'detailClass': 'Classe',
      'detailLesson': 'Cours',
      'detailInfo': 'Remarque',
      'detailNotesForStudents': 'Notes pour les étudiants',
      'detailLessonNotes': 'Notes de cours',
      'detailHomework': 'Devoirs',
      'detailCancelled': 'ANNULÉ',
      'detailRegular': 'Cours régulier',
      'detailHideSubject': 'Masquer la matière définitivement',
      'detailCancelledBadge': 'ANNULÉ',

      'examsTitle': 'Examens',
      'examsReload': 'Recharger',
      'examsNone': 'Aucun examen trouvé',
      'examsNoneHint': 'Appuie sur + pour ajouter un examen.',
      'examsUpcoming': 'À venir',
      'examsPast': 'Passés',
      'examsAdd': 'Ajouter',
      'examsAddTitle': 'Ajouter un examen',
      'examsEditTitle': 'Modifier un examen',
      'examsSubjectLabel': 'Matière / Titre *',
      'examsTypeLabel': 'Type (ex. contrôle, test)',
      'examsNotesLabel': 'Notes / Thèmes',
      'examsSave': 'Enregistrer',
      'examsCancel': 'Annuler',
      'examsDelete': 'Supprimer',
      'examsToday': "Aujourd'hui",
      'examsTomorrow': 'Demain',
      'examsDaysIn': 'dans {n} jours',
      'examsOwn': 'Personnel',
      'examsUnknown': '(inconnu)',
      'examsNoneEntered': 'Aucun examen saisi.',
      'examsImportTitle': 'Uploader le planning',
      'examsImportCamera': 'Caméra',
      'examsImportGallery': 'Galerie',
      'examsImportFile': 'PDF / Fichier',
      'examsImportSuccess': 'Importé avec succès !',
      'examsImportError': 'Erreur lors de l\'import : ',
      'examsImportInvalidJson': 'Aucun JSON valide trouvé.',
      'examsExportSuccess': 'Examens copiés en JSON dans le presse-papiers.',
      'examsExportEmpty': 'Aucun examen personnel à exporter.',
      'examsActionCustom': 'Manuel',
      'examsActionImport': 'Importer (Scan/PDF)',
      'examsActionExport': 'Exporter (JSON)',
      'examsActionScan': 'Scanner',

      'homeworkTitle': 'Devoirs',
      'homeworkReload': 'Recharger',
      'homeworkNone': 'Aucun devoir trouvé',
      'homeworkNoneHint': 'Tu as fini ! Profite de ton temps libre.',
      'homeworkMarkDone': 'Marquer comme fait',
      'homeworkMarkUndone': 'Marquer comme non fait',
      'homeworkDue': 'Dû le',

      'infoTitle': 'Infos école',
      'infoReload': 'Recharger',
      'infoUpdated': 'Mis à jour',
      'infoEmpty': 'Aucune notification actuelle',
      'infoEmptyHint':
          'Si ton école ne publie rien actuellement, aucune information n\'apparaît ici.',
      'infoFetchError':
          'Impossible de charger les notifications. Réessaie plus tard.',
      'infoOpenLink': 'Ouvrir le lien',
      'notificationActionCurrentLesson': 'Cours actuel : {lesson}',
      'notificationActionNextLesson': 'Cours suivant : {lesson}',
      'notificationActionNoNextLesson':
          'Aucun cours suivant trouvé pour aujourd’hui',

      'aiTitle': 'Assistant IA',
      'aiTabAnalysis': 'Analyse',
      'aiTabChat': 'Chat',
      'aiInputHint': 'Poser une question…',
      'aiKnowsSchedule': 'Je connais ton emploi du temps !',
      'aiAskAnything': 'Demande-moi tout sur ta semaine.',
      'aiNoApiKey': '⚠️ Saisis ta clé API Gemini dans Paramètres → Général.',
      'aiNoReply': '⚠️ Aucune réponse reçue.',
      'aiApiError': '⚠️ Erreur API :',
      'aiConnectionError': '⚠️ Erreur de connexion :',
      'aiSuggestions': [
        "Qu'est-ce que j'ai demain ?",
        "Ai-je une heure libre aujourd'hui ?",
        "À quelle heure finit l'école demain ?",
        "Y a-t-il des cours annulés aujourd'hui ?",
      ],

      'settingsTitle': 'Paramètres',
      'settingsLoggedInAs': 'Connecté en tant que',
      'settingsLogout': 'Se déconnecter',
      'settingsSectionQuick': 'Accès rapide',
      'settingsSectionGeneral': 'Application',
      'settingsAppearance': 'Apparence',
      'settingsAppearanceDesc': 'Système (Clair/Sombre)',
      'settingsHubNotifications': 'Notifications & Widgets',
      'settingsHubDataBackup': 'Données & Sauvegarde',
      'settingsHubDataBackupDesc': 'Sauvegarder tous les réglages',
      'settingsHubAccount': 'Compte & Démo',
      'settingsHubUpdatesAbout': 'Mises à jour & À propos',
      'settingsLanguage': 'Langue',
      'settingsSectionAI': 'Assistant IA',
      'settingsAiProvider': 'Fournisseur',
      'settingsAiProviderGemini': 'Google Gemini',
      'settingsAiProviderOpenAi': 'OpenAI',
      'settingsAiProviderMistral': 'Mistral AI',
      'settingsAiProviderCustom': 'Fournisseur personnalisé',
      'settingsAiProviderLocal': 'Local (On-Device)',
      'settingsAiModel': 'Modèle',
      'settingsAiApiKey': 'Clé API',
      'settingsAiApiKeyNotSet': 'Non configuré — appuyer pour configurer',
      'settingsAiApiKeyDialogDesc':
          'Requis pour l\'assistant IA. Utilise « Obtenir la clé API » pour ouvrir la bonne page du fournisseur sélectionné.',
      'settingsAiApiKeyGet': 'Obtenir la clé API',
      'settingsAiApiKeyOpenFailed': 'Impossible d\'ouvrir la page de clé API.',
      'settingsAiPrompt': 'Invite système',
      'settingsAiPromptDesc':
          'Modifie l\'invite par défaut et utilise des variables comme [timetable].',
      'settingsAiPromptEditTitle': 'Modifier l\'invite système',
      'settingsAiPromptReset': 'Réinitialiser',
      'settingsAiPromptVariables': 'Variables d\'invite',
      'settingsAiPromptVariablesDesc':
          'Tous les espaces réservés remplacés automatiquement par des données de l\'app.',
      'settingsAiLocalModel': 'Modèle local',
      'settingsAiLocalModelDesc': 'Sélectionne et télécharge un modèle pour l\'inférence sur l\'appareil.',
      'settingsAiLocalModelDownload': 'Télécharger',
      'settingsAiLocalModelDownloading': 'Téléchargement…',
      'settingsAiLocalModelInstalled': 'Installé',
      'settingsAiLocalModelDelete': 'Supprimer',
      'settingsAiLocalModelActive': 'Actif',
      'settingsAiLocalModelError': 'Échec du téléchargement.',
      'aiLocalModelExamNotSupported':
          'Les modèles locaux ne prennent pas en charge l\'importation d\'images d\'examens. Choisis un fournisseur en ligne.',
      'aiLocalModelLoadError':
          'Le modèle local n\'a pas pu être chargé. Télécharge-le à nouveau.',
      'settingsAiLocalModelSize': 'Taille : {size} Go',
      'settingsAiLocalModelDeleteConfirm': 'Supprimer ce modèle ?',
      'aiVar_today': 'Date d\'aujourd\'hui en format local',
      'aiVar_today_iso': 'Date d\'aujourd\'hui au format YYYY-MM-DD',
      'aiVar_locale': 'Langue active de l\'app (ex. de, en)',
      'aiVar_school_name': 'Nom de l\'école',
      'aiVar_school_url': 'Serveur/domaine de l\'école',
      'aiVar_person_type': 'Type de personne WebUntis en chiffre',
      'aiVar_person_id': 'ID de personne WebUntis',
      'aiVar_demo_mode': 'true si le mode démo est actif',
      'aiVar_current_monday': 'Lundi de la semaine chargée (DD.MM.YYYY)',
      'aiVar_current_friday': 'Vendredi de la semaine chargée (DD.MM.YYYY)',
      'aiVar_day_summary_today': 'Résumé court pour aujourd\'hui',
      'aiVar_day_summary_tomorrow': 'Résumé court pour demain',
      'aiVar_timetable': 'Emploi du temps formaté pour la semaine en cours',
      'aiVar_timetable_json': 'Données brutes de l\'emploi du temps en JSON',
      'aiVar_exams': 'Liste formatée des examens à venir',
      'aiVar_exams_json': 'Données d\'examens en JSON',
      'settingsAiCustomBaseUrl': 'URL de base personnalisée',
      'settingsAiCustomBaseUrlDesc':
          'URL de base de ton propre fournisseur (compatible OpenAI ou Gemini).',
      'settingsAiCustomBaseUrlHint': 'https://api.ton-fournisseur.tld/v1',
      'settingsAiCompatibility': 'Compatibilité personnalisée',
      'settingsAiCompatibilityOpenAi': 'Compatible OpenAI',
      'settingsAiCompatibilityGemini': 'Compatible Gemini',
      'aiCustomBaseUrlMissing':
          '⚠️ Configure d\'abord l\'URL de base personnalisée dans les paramètres IA.',
      'settingsPageTransition': 'Transition de page',
      'settingsPageTransitionDesc':
          'Choisis le style de transition pour la navigation',
      'settingsUseMaterialYou': 'Material You',
      'settingsUseMaterialYouDesc':
          "S'adapter automatiquement à la couleur d'accentuation du système",
      'settingsCustomColorSeed': 'Couleur personnalisée',
      'settingsPageTransitionBounce': 'Rebond',
      'settingsPageTransitionFade': 'Fondu',
      'settingsPageTransitionSlide': 'Glissement',
      'settingsPageTransitionZoom': 'Zoom',
      'settingsPageTransitionBlur': 'Flou',
      'settingsPageTransitionEaseIn': 'Ease In',
      'settingsPageTransitionEaseOut': 'Ease Out',
      'settingsPageTransitionExpo': 'Expo',
      'bgEditorUndo': 'Annuler',
      'bgEditorRedo': 'Rétablir',
      'bgEditorRandomize': 'Aléatoire',
      'settingsApiKey': 'Clé API Gemini',
      'settingsApiKeyNotSet': 'Non configuré — Appuyer pour configurer',
      'settingsApiKeyDialogTitle': 'Clé API Gemini',
      'settingsApiKeyDialogDesc':
          "Requis pour l'assistant IA. Trouve ta clé sur aistudio.google.com/app/apikey.",
      'settingsApiKeySave': 'Enregistrer',
      'settingsApiKeyRemove': 'Supprimer',
      'settingsApiKeyCancel': 'Annuler',
      'settingsSectionHidden': 'Matières masquées',
      'settingsNoHidden': 'Aucune matière masquée',
      'settingsNoHiddenDesc': 'Appuie sur un cours pour le masquer.',
      'settingsUnhide': 'Afficher',
      'settingsHiddenCount': '{n} matière(s) masquée(s)',
      'settingsSectionColors': 'Couleurs des matières',
      'settingsColorsDesc': 'Appuie sur une matière pour choisir une couleur.',
      'settingsNoSubjectsLoaded': 'Aucune matière chargée',
      'settingsNoSubjectsLoadedDesc': "Ouvre d'abord ton emploi du temps.",
      'settingsCustomColor': 'Personnalisé',
      'settingsDefaultColor': 'Couleur par défaut',
      'settingsColorFor': 'Couleur pour « {s} »',
      'settingsColorReset': 'Réinitialiser par défaut',
      'settingsColorCustomPicker': 'Choisir une couleur personnalisée',
      'settingsColorApply': 'Appliquer la couleur',
      'settingsColorRed': 'Rouge',
      'settingsColorGreen': 'Vert',
      'settingsColorBlue': 'Bleu',
      'settingsThemeMode': 'Schéma de couleurs',
      'settingsThemeLight': 'Clair',
      'settingsThemeSystem': 'Système',
      'settingsThemeDark': 'Sombre',
      'settingsSectionTimetable': 'Emploi du temps',
      'settingsShowCancelled': 'Afficher les cours annulés',
      'settingsShowCancelledDesc':
          'Les cours annulés sont visibles dans l\'emploi du temps',
      'settingsCancelledColor': 'Couleur annulée',
      'settingsCancelledColorDesc': 'Personnaliser la couleur des cours annulés',
      'settingsLessonDesignTitle': 'Design des cours & cartes',
      'settingsLessonDesignDesc': 'Personnalisez le style, lueurs, flous et détails des cours.',
      'settingsLessonStyle': 'Style de carte',
      'settingsLessonStyleDesc': 'Choisissez l\'esthétique visuelle des cours.',
      'settingsLessonStyleModern': 'Moderne (Teinté)',
      'settingsLessonStyleGlass': 'Verre dépoli (Glass)',
      'settingsLessonStyleGradient': 'Dégradé',
      'settingsLessonStyleOutline': 'Contour / Minimal',
      'settingsLessonStyleSolid': 'Plein / Contrasté',
      'settingsLessonGlow': 'Effet de lueur (Glow)',
      'settingsLessonGlowDesc': 'Ajoute un halo lumineux derrière les cartes de cours.',
      'settingsLessonGlowMode': 'Mode de lueur',
      'settingsLessonGlowModeActive': 'Cours actuel uniquement',
      'settingsLessonGlowModeAll': 'Tous les cours',
      'settingsLessonGlowIntensity': 'Intensité de la lueur',
      'settingsLessonBlur': 'Flou de verre (Blur)',
      'settingsLessonBlurDesc': 'Flouter l\'arrière-plan derrière les cartes.',
      'settingsLessonBlurAmount': 'Force du flou',
      'settingsLessonCardOpacity': 'Opacité de la carte',
      'settingsLessonBorderRadius': 'Rayon des coins',
      'settingsLessonAccentStyle': 'Bande d\'accentuation',
      'settingsLessonAccentBar': 'Barre classique',
      'settingsLessonAccentThin': 'Ligne fine',
      'settingsLessonAccentDot': 'Point indicateur',
      'settingsLessonAccentNone': 'Aucune',
      'settingsLessonShowTeacher': 'Afficher le professeur',
      'settingsLessonShowTeacherDesc': 'Afficher les initiales ou le nom de l\'enseignant.',
      'settingsLessonShowRoom': 'Afficher la salle',
      'settingsLessonShowRoomDesc': 'Afficher le numéro de salle sur la carte.',
      'settingsLessonCompactMode': 'Mode compact',
      'settingsLessonCompactModeDesc': 'Espacement réduit pour les emplois du temps chargés.',
      'settingsLessonDimPast': 'Atténuer les cours passés',
      'settingsLessonDimPastDesc': 'Griser discrètement les cours terminés de la journée.',
      'settingsLessonCancelledPattern': 'Hachures d\'annulation',
      'settingsLessonCancelledPatternDesc': 'Affiche des rayures diagonales en cas d\'annulation.',
      'settingsLessonPreviewRegular': 'Normal',
      'settingsLessonPreviewActive': 'Cours actuel',
      'settingsLessonPreviewCancelled': 'Annulé',
      'settingsLessonPreviewHeader': 'Aperçu en direct',
      'settingsMonochromeLessons': 'Cours monochromes',
      'settingsMonochromeLessonsDesc':
          'Utiliser les couleurs Material You au lieu de couleurs individuelles',
      'settingsDemoMode': 'Mode démo',
      'settingsDemoModeDesc':
          'Utilise des données de démonstration locales au lieu du serveur école (immédiat).',
      'settingsBackgroundAnimations': 'Animations de fond',
      'settingsBackgroundAnimationsDesc':
          'Afficher des effets de dégradé animés en arrière-plan',
      'settingsBackgroundGyroscope': 'Réaction gyroscopique',
      'settingsBackgroundGyroscopeDesc':
          'Permet au fond de réagir aux mouvements de l\'appareil',
      'settingsBackgroundStyle': 'Style d\'animation',
      'settingsBackgroundStyleOrbs': 'Orbes',
      'settingsBackgroundStyleSpace': 'Espace',
      'settingsBackgroundStyleBubbles': 'Bulles',
      'settingsBackgroundStyleLines': 'Lignes',
      'settingsBackgroundStyleThreeD': 'Formes 3D',
      'settingsBackgroundStyleNebula': 'Nebuleuse',
      'settingsBackgroundStylePrism': 'Prisme',
      'settingsBackgroundStyleWaves': 'Vagues',
      'settingsBackgroundStyleGrid': 'Grille',
      'settingsBackgroundStyleRings': 'Anneaux',
      'settingsBackgroundStyleCustom': 'Personnalisé',
      'settingsCustomBackgrounds': 'Fonds personnalisés',
      'settingsCustomBackgroundsDesc':
          'Créer, enregistrer, importer et exporter',
      'settingsCustomBackgroundsSelected': 'Sélectionné : {name}',

      'bgEditorTitle': 'Éditeur de fond',
      'bgEditorPreviewTab': 'Aperçu',
      'bgEditorDesignTab': 'Design',
      'bgEditorLibraryTab': 'Bibliothèque',
      'bgEditorStartPoints': 'Points de départ',
      'bgEditorUpdatedAt': 'Mis à jour',
      'bgEditorEdit': 'Modifier',
      'bgEditorLivePreview': 'Aperçu en direct',
      'bgEditorUnsavedTitle': 'Modifications non enregistrées',
      'bgEditorUnsavedDesc':
          'Enregistrer les modifications, les ignorer ou continuer ?',
      'bgEditorDiscard': 'Ignorer',
      'bgEditorSave': 'Enregistrer',
      'bgEditorSaved': 'Enregistré.',
      'bgEditorSaveFailed': 'Échec de l\'enregistrement.',
      'bgEditorUseInApp': 'Utiliser dans l\'app',
      'bgEditorApplied': 'Activé comme fond.',
      'bgEditorLibrary': 'Bibliothèque',
      'bgEditorNew': 'Nouveau',
      'bgEditorNewName': 'Nouveau fond',
      'bgEditorDuplicate': 'Dupliquer',
      'bgEditorDelete': 'Supprimer',
      'bgEditorDeleteTitle': 'Supprimer le fond ?',
      'bgEditorDeleteDesc': 'Ce fond sera supprimé définitivement.',
      'bgEditorDeleteConfirm': 'Supprimer',

      'bgEditorExportTitle': 'Exporter',
      'bgEditorExportSelected': 'Exporter la sélection',
      'bgEditorExportAll': 'Exporter tout',
      'bgEditorExported': 'JSON copié dans le presse-papiers.',
      'bgEditorExportedAll': 'Tous les fonds copiés en JSON.',

      'bgEditorImportTitle': 'Importer',
      'bgEditorImportFromClipboard': 'Depuis le presse-papiers',
      'bgEditorImportFromFile': 'Depuis un fichier',
      'bgEditorImportClipboardEmpty': 'Presse-papiers vide.',
      'bgEditorImportedCount': '{n} fond(s) importé(s).',
      'bgEditorImportFailed': 'Échec de l\'importation.',

      'bgEditorMeta': 'Métadonnées',
      'bgEditorName': 'Nom',
      'bgEditorBase': 'Dégradé de base',
      'bgEditorUseThemeColors': 'Utiliser les couleurs du thème',
      'bgEditorUseThemeColorsDesc': 'Utilise les couleurs du thème actuel.',
      'bgEditorGradientLinear': 'Linéaire',
      'bgEditorGradientRadial': 'Radial',
      'bgEditorBaseOpacity': 'Opacité de base',
      'bgEditorGradientAngle': 'Angle',
      'bgEditorRadialCenterX': 'Centre X',
      'bgEditorRadialCenterY': 'Centre Y',
      'bgEditorRadialRadius': 'Rayon',
      'bgEditorColorN': 'Couleur {n}',

      'bgEditorOrbs': 'Orbes',
      'bgEditorOrbsEnabled': 'Orbes activés',
      'bgEditorOrbsThemeDesc': 'Utilise les couleurs du thème pour les orbes.',
      'bgEditorRandomizeSeed': 'Aléa du seed',
      'bgEditorOrbsCount': 'Nombre',
      'bgEditorOrbsSize': 'Taille',
      'bgEditorOrbsVariance': 'Variance',
      'bgEditorOrbsOpacity': 'Opacité',
      'bgEditorOrbsSoftness': 'Douceur',
      'bgEditorOrbColorN': 'Couleur d\'orbe {n}',

      'bgEditorEffects': 'Motif & effets',
      'bgEditorPatternNone': 'Aucun',
      'bgEditorPatternLines': 'Lignes',
      'bgEditorPatternGrid': 'Grille',
      'bgEditorPatternOpacity': 'Opacité du motif',
      'bgEditorPatternScale': 'Échelle',
      'bgEditorPatternAngle': 'Angle du motif',
      'bgEditorNoise': 'Bruit',
      'bgEditorVignette': 'Vignette',

      'bgEditorMotion': 'Mouvement',
      'bgEditorAnimate': 'Animer',
      'bgEditorSpeed': 'Vitesse',
      'bgEditorParallax': 'Parallaxe',

      'bgEditorAiTitle': 'Générateur IA',
      'bgEditorAiDesc': 'Décris un style — l\'IA crée un nouveau fond.',
      'bgEditorAiHint': 'ex. « nébuleuse néon, doux, sombre, bleu/rose »',
      'bgEditorAiGenerate': 'Générer avec l\'IA',
      'bgEditorAiSystem': '''
You generate ONE Flutter background preset.
Output ONLY valid JSON (no markdown, no commentary).

Return a single JSON object with this schema:
{
    "version": 1,
    "name": "...",
    "base": {
        "type": "linear"|"radial",
        "useThemeColors": true|false,
        "colors": ["#RRGGBB", ...],
        "opacity": 0.0-1.0,
        "angleDeg": 0-360,
        "centerX": -1..1,
        "centerY": -1..1,
        "radius": 0.3-2.5
    },
    "orbs": {
        "enabled": true|false,
        "useThemeColors": true|false,
        "colors": ["#RRGGBB", ...],
        "count": 0-18,
        "seed": 0-2147483647,
        "size": 40-480,
        "sizeVariance": 0.0-1.0,
        "opacity": 0.0-1.0,
        "softness": 0.0-1.0
    },
    "pattern": {
        "type": "none"|"lines"|"grid",
        "opacity": 0.0-1.0,
        "scale": 0.4-3.5,
        "angleDeg": 0-360
    },
    "noise": 0.0-0.5,
    "vignette": 0.0-1.0,
    "animate": true|false,
    "animationSpeed": 0.0-3.0,
    "parallaxStrength": 0.0-1.0
}

Keep values reasonable and visually pleasing. Prefer 2-3 base colors.
Use "useThemeColors": true unless the prompt asks for specific colors.
''',
      'bgEditorAiUserPrefix': 'Description:',
      'bgEditorAiUserSchemaHint':
          'Return JSON only. Do not wrap in code fences.',
      'bgEditorAiGeneratedName': 'Fond IA',
      'bgEditorAiSuccess': 'Fond IA créé.',
      'bgEditorAiError': 'IA: ',
      'settingsGlassEffect': 'Effet de flou',
      'settingsGlassEffectDesc': 'Active le flou dans l\'interface',
      'settingsSectionUpdates': 'Mises à jour',
      'settingsProgressivePush': 'Notification push progressive',
      'settingsProgressivePushDesc':
          'Afficher le cours actuel comme notification persistante',
      'settingsDailyBriefingPush': 'Notification de briefing quotidien',
      'settingsDailyBriefingPushDesc':
          'Affiche le matin un aperçu compact de ta journée scolaire',
      'settingsImportantChangesPush': 'Changements importants',
      'settingsImportantChangesPushDesc':
          'Alerte en cas d’annulations, de changement de salle ou de remplacements',
      'settingsRefreshPushWidgetNow': 'Actualiser push et widget maintenant',
      'settingsRefreshPushWidgetNowDesc':
          'Charge immédiatement les dernières données du cache API et met à jour widget et push',
      'settingsBackgroundLoading': 'Les données se chargent en arrière-plan...',
      'settingsSectionAbout': 'À propos',
      'appName': 'Untis+',
      'settingsAppVersion': 'Version',
      'settingsBuild': 'Build',
      'settingsSectionSubjects': 'Matières & Couleurs',
      'settingsGithubRepoLabel': 'github.com/ninocss/UntisPlus',
      'settingsGithubUpdateCheck': 'Rechercher des mises à jour sur GitHub',
      'settingsGithubUpdateCheckDesc':
          'Vérifie la dernière version de ninocss/UntisPlus.',
      'settingsGithubDirectDownload':
          'Télécharger directement la dernière version',
      'settingsGithubDirectDownloadDesc':
          'Lors de la vérification, ouvre immédiatement le dernier APK/fichier de version.',
      'settingsGithubChecking': 'Recherche des mises à jour...',
      'settingsGithubUpdateFound': 'Nouvelle version trouvée : {v}',
      'settingsGithubDownloadNow': 'Télécharger',
      'settingsGithubNoDownloadAsset':
          'Aucun fichier de téléchargement direct trouvé. Ouverture de la page de version...',
      'settingsGithubDownloadStarted':
          'Le téléchargement/la version a été ouvert(e) dans le navigateur.',
      'settingsGithubOpenFailed':
          'Impossible d\'ouvrir le lien de téléchargement.',
      'settingsGithubCheckFailed':
          'La vérification des mises à jour a échoué. Réessaie plus tard.',
      'settingsGithubNoUpdate': 'Tu as déjà la version la plus récente.',
      'settingsGithubCurrentVersion': 'Version installée',
      'settingsGithubLatestVersion': 'Dernière version',
      'settingsGithubInstallQuestion':
          'Veux-tu télécharger et installer cette mise à jour maintenant ?',
      'settingsGithubInstallNow': 'Installer maintenant',
      'settingsGithubInstallLater': 'Plus tard',
      'settingsGithubInstallPrompted':
          'Téléchargement démarré. La demande d\'installation apparaît après le téléchargement.',
      'settingsGithubOpenReleasePage': 'Ouvrir la page des versions GitHub',
      'settingsBackupIncludeApiKeys': 'Inclure les clés API',
      'settingsBackupIncludeApiKeysDesc':
          'À activer uniquement si la sauvegarde est stockée de manière sûre.',
      'settingsBackupExportAllFile':
          'Exporter tous les réglages dans un fichier',
      'settingsBackupExportAllClipboard':
          'Copier tous les réglages dans le presse-papiers',
      'settingsBackupImportAllTitle': 'Importer tous les réglages',
      'settingsBackupImportAllFile': 'Importer depuis un fichier',
      'settingsBackupImportAllClipboard': 'Importer depuis le presse-papiers',
      'settingsBackupExportDialogTitle': 'Enregistrer la sauvegarde',
      'settingsBackupExportSuccess': 'Fichier de sauvegarde enregistré.',
      'settingsBackupExportClipboardSuccess':
          'Sauvegarde JSON copiée dans le presse-papiers.',
      'settingsBackupImportSuccess': 'Sauvegarde importée.',
      'settingsBackupImportFailed':
          'Échec de l\'import. Vérifie le JSON et le schéma.',
      'settingsBackupClipboardEmpty': 'Le presse-papiers est vide.',
      'settingsBackupConfirmTitle': 'Confirmer l\'import',
      'settingsBackupConfirmDesc':
          'L\'import écrase les réglages actuels et met à jour l\'app immédiatement.',
      'settingsBackupConfirmAction': 'Importer',

      'aiSystemPersona':
          'Tu es "Assistant Planning", un assistant IA amical et motivant pour les élèves.',
      'aiSystemRules': '''RÈGLES :
- Répondre sur la base des données d'emploi du temps et d'examens ci-dessus.
- Ne PAS inventer de matières, d'horaires, d'enseignants ou d'autres informations.
- Tenir compte des examens/contrôles dans les réponses si pertinent.
- Si quelque chose ne peut pas être déduit des données, dis-le ouvertement.
- Respecter les marqueurs [ANNULÉ] (ces cours n'ont pas lieu).
- "Heures libres" = pauses entre deux cours.
- Répondre en français, de manière amicale, utile et concise.
- Ne pas commencer automatiquement par "Oui," – répondre directement.
- Tu peux utiliser Markdown pour la mise en forme (ex. listes, **gras**).''',

      'settingsChangelogTitle': 'Nouveautés (Changelog)',
      'settingsChangelogSubtitle': 'Quoi de neuf dans Untis+ ?',
      'changelogTitle': 'Nouveautés',
      'changelogLoadError': 'Erreur de chargement',
      'changelogRetry': 'Réessayer',

      'aiNewSearch': 'Nouvelle recherche',
      'aiSearchRunning': 'Recherche en cours…',
      'aiSearchShapingDesc':
          "L'IA génère des cartes et des blocs de cours à partir de ton emploi du temps.",
      'aiStepAnalyzingTimetable': "Analyse de l'emploi du temps…",
      'aiStepSortingResults': 'Tri des résultats…',
      'aiStepAlmostDone': 'Presque terminé…',
      'aiSearchHintPlaceholder': 'Cours, heures libres, examens …',
      'aiOverview': 'Aperçu',
      'aiEmptyPromptTitle': 'Que souhaites-tu savoir ?',
      'aiEmptyPromptSubtitle':
          'Pose des questions sur tes cours, examens ou salles libres.',
      'aiPromptWhenFinishToday': "À quelle heure je termine aujourd'hui ?",
      'aiPromptWhatCancelledToday': "Quels cours sont annulés aujourd'hui ?",
      'aiPromptUpcomingExams': 'Quels sont mes prochains examens ?',
      'aiPromptFirstLessonToday': "Quel est mon premier cours aujourd'hui ?",
      'aiPromptNextLesson': 'Quand est mon prochain cours ?',
      'aiPromptTomorrowSchedule': "Qu'est-ce que j'ai demain ?",
      'aiClearResult': 'Effacer le résultat',
      'aiSearchAgain': 'Rechercher à nouveau',
      'aiClearInput': 'Effacer',
      'aiLessons': 'Cours',
      'aiMore': 'Plus',
      'aiSettingsMenu': 'Paramètres IA',
      'aiResultsCardDesc':
          "Les résultats s'affichent sous forme de cartes et de blocs de cours.",
      'aiDismiss': 'Masquer',
      'aiLessonsCountSingle': '1 cours',
      'aiLessonsCountPlural': '{count} cours',
      'aiExamsCountWeekSingle': '1 examen cette semaine',
      'aiExamsCountWeekPlural': '{count} examens cette semaine',

      'classPickerHeaderDesc':
          "Sélectionnez un emploi du temps. Les favoris s'affichent en haut.",
      'classPickerDefaultBadge': 'Par défaut',
      'classPickerSetDefault': 'Définir par défaut',
      'classPickerOtherClasses': 'Autres classes',
      'classPickerRemoveFavorite': 'Retirer des favoris',
      'classPickerAddFavorite': 'Ajouter aux favoris',

      'navGrades': 'Notes',
      'gradesTitle': 'Suivi des notes',
      'gradesAddTitle': 'Ajouter une note',
      'gradesEditTitle': 'Modifier la note',
      'gradesSubjectLabel': 'Matière',
      'gradesGradeLabel': 'Note',
      'gradesWeightLabel': 'Coefficient',
      'gradesTypeLabel': 'Type',
      'gradesAverage': 'Moyenne',
      'gradesNone': 'Aucune note',
      'gradesNoneHint': 'Appuyez sur + pour ajouter votre première note.',
    },

    // ── SPANISH ───────────────────────────────────────────────────────────────
    'es': {
      'navWeek': 'Semana',
      'navHomework': 'Deberes',
      'navExams': 'Exámenes',
      'navInfo': 'Info',
      'navMenu': 'Menú',
      'navAi': 'IA',

      'loginServer': 'URL del servidor',
      'loginSchool': 'Escuela',
      'loginUsername': 'Usuario',
      'loginPassword': 'Contraseña',
      'loginLoginKey': 'Clave de inicio de sesión',
      'loginLoginKeyHint':
          'Usa la clave de inicio de sesión de WebUntis si tu escuela inicia sesión con Microsoft 365 u Office 365.',
      'loginCredentialModePassword': 'Contraseña',
      'loginCredentialModeLoginKey': 'Clave de inicio de sesión',
      'loginButton': 'Empezar',
      'loginFailed': 'Error de inicio de sesión. Verifica tus datos.',
      'loginConnectionError': 'Error de conexión',
      'loginSearchSchool': 'Busca escuela',
      'loginSelectSchool': 'Selecciona escuela',
      'loginSearchHint': 'Nombre o ciudad...',
      'loginNoSchoolsFound': 'No se encontraron escuelas.',
      'loginChangeLanguage': 'Idioma',
      'loginManualEntry': 'Entrada manual',
      'loginSwitchToSearch': 'Volver a buscar',
      'loginChangeSchool': 'Cambiar escuela',
      'loginTwoFactorCode': 'Código 2FA',
      'loginTwoFactorHint':
          'Introduce el código 2FA de tu aplicación de autenticación.',
      'loginTwoFactorRequired':
          '2FA está activado. Introduce tu código de verificación.',
      'loginTwoFactorInvalid':
          'El código 2FA no es válido o ha caducado. Inténtalo de nuevo.',
      'loginVerifyButton': 'Verificar',

      'onboardingWelcomeTitle': 'Bienvenido a Untis+',
      'onboardingChooseLanguageSubtitle': 'Elige tu idioma preferido',
      'onboardingAppearanceTitle': 'Apariencia',
      'onboardingAppearanceSubtitle':
          'Haz que Untis+ se vea exactamente como quieres',
      'onboardingThemeSystem': 'Sistema',
      'onboardingThemeLight': 'Claro',
      'onboardingThemeDark': 'Oscuro',
      'onboardingAnimationsHint': 'Activar bonitas animaciones de fondo',
      'onboardingSchoolLoginTitle': 'Inicio de sesión escolar',
      'onboardingSchoolLoginSubtitle': 'Conecta tu cuenta de WebUntis',
      'onboardingGeminiTitle': 'Gemini IA',
      'onboardingGeminiSubtitle': 'Chatea con tu horario y tus deberes',
      'onboardingGeminiInfo':
          'Obtén una clave API gratuita de Gemini en Google AI Studio para desbloquear el potente asistente IA en Untis+.',
      'onboardingGeminiGetApiKey': 'Obtener clave API',
      'onboardingSkip': 'Saltar',
      'onboardingNext': 'Continuar',
      'onboardingGeminiEnterKeyOrSkip': 'Introduce una clave o salta este paso',
      'onboardingReadyTitle': 'Listo para empezar',
      'onboardingReadySubtitle': 'Esto es lo que puedes hacer en Untis+',
      'onboardingFeatureTimetableTitle': 'Horario y Calendario',
      'onboardingFeatureTimetableDesc':
          'Consulta tu horario sin complicaciones.',
      'onboardingFeatureExamsTitle': 'Exámenes y Deberes',
      'onboardingFeatureExamsDesc':
          'Sigue tu progreso, importa exámenes y expórtalos en JSON.',
      'onboardingFeatureAiTitle': 'Asistente IA',
      'onboardingFeatureAiDesc':
          'Pregunta a Gemini sobre tu día, deberes o exámenes.',
      'onboardingFeatureNotifyTitle': 'Notificaciones y Widgets',
      'onboardingFeatureNotifyDesc':
          'Mantente al día antes de que empieza la escuela.',
      'onboardingFinishSetup': 'Finalizar configuración',
      'onboardingUseDemoMode': 'Iniciar modo demo',
      'onboardingUseDemoModeDesc':
          'Prueba Untis+ sin inicio escolar con datos de ejemplo realistas.',
      'tutorialTitle': 'Tutorial rápido de la app',
      'tutorialSkip': 'Saltar tutorial',
      'tutorialDone': 'Finalizar tutorial',
      'tutorialStepWeekTitle': '1. Horario',
      'tutorialStepWeekDesc':
          'Toca el botón grande del reloj para abrir la vista semanal.',
      'tutorialStepExamsTitle': '2. Exámenes',
      'tutorialStepExamsDesc':
          'Toca el botón de exámenes para ver, importar y exportar exámenes.',
      'tutorialStepInfoTitle': '3. Info escolar',
      'tutorialStepInfoDesc':
          'Toca el botón de info para leer avisos actuales de tu escuela.',
      'tutorialStepSettingsTitle': '4. Configuración',
      'tutorialStepSettingsDesc':
          'Toca el botón de configuración para ajustar idioma, diseño y notificaciones.',
      'tutorialStepFinishTitle': '¡Listo!',
      'tutorialStepFinishDesc':
          'Ya conoces todas las áreas principales de la app. ¡Disfruta Untis+!',

      'timetableTitle': 'Horario',
      'timetablePrevWeek': 'Semana anterior',
      'timetableNextWeek': 'Semana siguiente',
      'timetableWeekView': 'Vista semanal',
      'timetableDayGrid': 'Cuadrícula diaria',
      'timetableNotLoaded': 'Horario no cargado',
      'timetableReload': 'Recargar',
      'timetableSelectClass': 'Seleccionar clase',
      'timetableMyTimetable': 'Mi horario',
      'timetableSelectAnother': 'Otra clase',
      'timetableNoClassesFound': 'No se encontraron clases o acceso denegado.',
      'freeRoomsTitle': 'Aulas libres',
      'freeRoomsSelectTime': 'Elegir franja horaria',
      'freeRoomsNoneFound':
          'No se encontraron aulas libres para esta franja horaria.',
      'freeRoomsNoRangesHint':
          'No se encontraron franjas horarias adecuadas para el día actual.',
      'freeRoomsCount': '{n} aulas libres',
      'weekDayShort': ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'],
      'weekDayFull': ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'],
      'noLesson': '(sin clases)',

      'detailTime': 'Hora',
      'detailTeacher': 'Profesor',
      'detailRoom': 'Aula',
      'detailClass': 'Clase',
      'detailLesson': 'Clase',
      'detailInfo': 'Nota',
      'detailNotesForStudents': 'Notas para estudiantes',
      'detailLessonNotes': 'Notas de clase',
      'detailHomework': 'Deberes',
      'detailCancelled': 'CANCELADO',
      'detailRegular': 'Clase regular',
      'detailHideSubject': 'Ocultar asignatura permanentemente',
      'detailCancelledBadge': 'CANCELADO',

      'examsTitle': 'Exámenes',
      'examsReload': 'Recargar',
      'examsNone': 'No se encontraron exámenes',
      'examsNoneHint': 'Toca + para añadir un examen.',
      'examsUpcoming': 'Próximos',
      'examsPast': 'Pasados',
      'examsAdd': 'Añadir',
      'examsAddTitle': 'Añadir examen',
      'examsEditTitle': 'Editar examen',
      'examsSubjectLabel': 'Asignatura / Título *',
      'examsTypeLabel': 'Tipo (ej. examen, test)',
      'examsNotesLabel': 'Notas / Temas',
      'examsSave': 'Guardar',
      'examsCancel': 'Cancelar',
      'examsDelete': 'Eliminar',
      'examsToday': 'Hoy',
      'examsTomorrow': 'Mañana',
      'examsDaysIn': 'en {n} días',
      'examsOwn': 'Propio',
      'examsUnknown': '(desconocido)',
      'examsNoneEntered': 'No hay exámenes registrados.',
      'examsImportTitle': 'Subir calendario',
      'examsImportCamera': 'Cámara',
      'examsImportGallery': 'Galería',
      'examsImportFile': 'PDF / Archivo',
      'examsImportSuccess': '¡Importado con éxito!',
      'examsImportError': 'Error al importar: ',
      'examsImportInvalidJson': 'No se encontró un JSON válido.',
      'examsExportSuccess': 'Exámenes copiados como JSON al portapapeles.',
      'examsExportEmpty': 'No hay exámenes propios para exportar.',
      'examsActionCustom': 'Manual',
      'examsActionImport': 'Importar (Escaneo/PDF)',
      'examsActionExport': 'Exportar (JSON)',
      'examsActionScan': 'Escanear',

      'homeworkTitle': 'Deberes',
      'homeworkReload': 'Recargar',
      'homeworkNone': 'No se encontraron deberes',
      'homeworkNoneHint': '¡Has terminado! Disfruta de tu tiempo libre.',
      'homeworkMarkDone': 'Marcar como hecho',
      'homeworkMarkUndone': 'Marcar como no hecho',
      'homeworkDue': 'Vence el',

      'infoTitle': 'Info escolar',
      'infoReload': 'Recargar',
      'infoUpdated': 'Actualizado',
      'infoEmpty': 'No hay notificaciones actuales',
      'infoEmptyHint':
          'Si tu escuela no ha publicado nada por ahora, no se mostrará nada aquí.',
      'infoFetchError':
          'No se pudieron cargar las notificaciones. Inténtalo más tarde.',
      'infoOpenLink': 'Abrir enlace',
      'notificationActionCurrentLesson': 'Clase actual: {lesson}',
      'notificationActionNextLesson': 'Siguiente clase: {lesson}',
      'notificationActionNoNextLesson':
          'No se encontró una siguiente clase para hoy',

      'aiTitle': 'Asistente IA',
      'aiTabAnalysis': 'Análisis',
      'aiTabChat': 'Chat',
      'aiInputHint': 'Hacer una pregunta…',
      'aiKnowsSchedule': '¡Conozco tu horario!',
      'aiAskAnything': 'Pregúntame lo que quieras sobre tu semana.',
      'aiNoApiKey': '⚠️ Introduce tu clave API de Gemini en Ajustes → General.',
      'aiNoReply': '⚠️ No se recibió respuesta.',
      'aiApiError': '⚠️ Error de API:',
      'aiConnectionError': '⚠️ Error de conexión:',
      'aiSuggestions': [
        '¿Qué tengo mañana?',
        '¿Tengo una hora libre hoy?',
        '¿A qué hora termina la escuela mañana?',
        '¿Se cancela algo hoy?',
      ],

      'settingsTitle': 'Configuración',
      'settingsLoggedInAs': 'Conectado como',
      'settingsLogout': 'Cerrar sesión',
      'settingsSectionQuick': 'Acceso rápido',
      'settingsSectionGeneral': 'Aplicación',
      'settingsAppearance': 'Apariencia',
      'settingsAppearanceDesc': 'Sistema (Claro/Oscuro)',
      'settingsHubNotifications': 'Notificaciones & Widgets',
      'settingsHubDataBackup': 'Datos & Copia de seguridad',
      'settingsHubDataBackupDesc': 'Guardar toda la configuración',
      'settingsHubAccount': 'Cuenta & Demo',
      'settingsHubUpdatesAbout': 'Actualizaciones & Acerca de',
      'settingsLanguage': 'Idioma',
      'settingsSectionAI': 'Asistente IA',
      'settingsAiProvider': 'Proveedor',
      'settingsAiProviderGemini': 'Google Gemini',
      'settingsAiProviderOpenAi': 'OpenAI',
      'settingsAiProviderMistral': 'Mistral AI',
      'settingsAiProviderCustom': 'Proveedor personalizado',
      'settingsAiProviderLocal': 'Local (On-Device)',
      'settingsAiModel': 'Modelo',
      'settingsAiApiKey': 'Clave API',
      'settingsAiApiKeyNotSet': 'No configurado — toca para configurar',
      'settingsAiApiKeyDialogDesc':
          'Necesario para el asistente IA. Usa «Obtener clave API» para abrir la página correcta del proveedor seleccionado.',
      'settingsAiApiKeyGet': 'Obtener clave API',
      'settingsAiApiKeyOpenFailed':
          'No se pudo abrir la página de clave API.',
      'settingsAiPrompt': 'Instrucción del sistema',
      'settingsAiPromptDesc':
          'Edita la instrucción predeterminada y usa variables como [timetable].',
      'settingsAiPromptEditTitle': 'Editar instrucción del sistema',
      'settingsAiPromptReset': 'Restablecer',
      'settingsAiPromptVariables': 'Variables de instrucción',
      'settingsAiPromptVariablesDesc':
          'Todos los marcadores de posición reemplazados automáticamente con datos de la app.',
      'settingsAiLocalModel': 'Modelo local',
      'settingsAiLocalModelDesc': 'Selecciona y descarga un modelo para inferencia en el dispositivo.',
      'settingsAiLocalModelDownload': 'Descargar',
      'settingsAiLocalModelDownloading': 'Descargando…',
      'settingsAiLocalModelInstalled': 'Instalado',
      'settingsAiLocalModelDelete': 'Eliminar',
      'settingsAiLocalModelActive': 'Activo',
      'settingsAiLocalModelError': 'Error al descargar.',
      'aiLocalModelExamNotSupported':
          'Los modelos locales no admiten la importación de imágenes de exámenes. Elige un proveedor en línea.',
      'aiLocalModelLoadError':
          'No se pudo cargar el modelo local. Descárgalo de nuevo.',
      'settingsAiLocalModelSize': 'Tamaño: {size} GB',
      'settingsAiLocalModelDeleteConfirm': '¿Eliminar este modelo?',
      'aiVar_today': 'Fecha de hoy en formato local',
      'aiVar_today_iso': 'Fecha de hoy en formato YYYY-MM-DD',
      'aiVar_locale': 'Idioma activo de la app (p.ej. de, en)',
      'aiVar_school_name': 'Nombre del centro escolar',
      'aiVar_school_url': 'Servidor/dominio del centro escolar',
      'aiVar_person_type': 'Tipo de persona de WebUntis como número',
      'aiVar_person_id': 'ID de persona de WebUntis',
      'aiVar_demo_mode': 'true si el modo demo está activo',
      'aiVar_current_monday': 'Lunes de la semana cargada (DD.MM.YYYY)',
      'aiVar_current_friday': 'Viernes de la semana cargada (DD.MM.YYYY)',
      'aiVar_day_summary_today': 'Resumen breve de hoy',
      'aiVar_day_summary_tomorrow': 'Resumen breve de mañana',
      'aiVar_timetable': 'Horario formateado de la semana actual',
      'aiVar_timetable_json': 'Datos brutos del horario en JSON',
      'aiVar_exams': 'Lista formateada de exámenes próximos',
      'aiVar_exams_json': 'Datos de exámenes en JSON',
      'settingsAiCustomBaseUrl': 'URL base personalizada',
      'settingsAiCustomBaseUrlDesc':
          'URL base de tu propio proveedor (compatible con OpenAI o Gemini).',
      'settingsAiCustomBaseUrlHint': 'https://api.tu-proveedor.tld/v1',
      'settingsAiCompatibility': 'Compatibilidad personalizada',
      'settingsAiCompatibilityOpenAi': 'Compatible con OpenAI',
      'settingsAiCompatibilityGemini': 'Compatible con Gemini',
      'aiCustomBaseUrlMissing':
          '⚠️ Configura primero la URL base personalizada en los ajustes de IA.',
      'settingsPageTransition': 'Transición de página',
      'settingsPageTransitionDesc':
          'Elige el estilo de transición para la navegación',
      'settingsUseMaterialYou': 'Material You',
      'settingsUseMaterialYouDesc':
          'Adaptar automáticamente al color de acento del sistema',
      'settingsCustomColorSeed': 'Color personalizado',
      'settingsPageTransitionBounce': 'Rebote',
      'settingsPageTransitionFade': 'Fundido',
      'settingsPageTransitionSlide': 'Deslizamiento',
      'settingsPageTransitionZoom': 'Zoom',
      'settingsPageTransitionBlur': 'Desenfoque',
      'settingsPageTransitionEaseIn': 'Ease In',
      'settingsPageTransitionEaseOut': 'Ease Out',
      'settingsPageTransitionExpo': 'Expo',
      'bgEditorUndo': 'Deshacer',
      'bgEditorRedo': 'Rehacer',
      'bgEditorRandomize': 'Aleatorio',
      'settingsApiKey': 'Clave API Gemini',
      'settingsApiKeyNotSet': 'No configurado — Toca para configurar',
      'settingsApiKeyDialogTitle': 'Clave API Gemini',
      'settingsApiKeyDialogDesc':
          'Necesario para el asistente IA. Encuentra tu clave en aistudio.google.com/app/apikey.',
      'settingsApiKeySave': 'Guardar',
      'settingsApiKeyRemove': 'Eliminar',
      'settingsApiKeyCancel': 'Cancelar',
      'settingsSectionHidden': 'Asignaturas ocultas',
      'settingsNoHidden': 'Sin asignaturas ocultas',
      'settingsNoHiddenDesc': 'Toca una clase para ocultarla.',
      'settingsUnhide': 'Mostrar',
      'settingsHiddenCount': '{n} asignatura(s) oculta(s)',
      'settingsSectionColors': 'Colores de asignaturas',
      'settingsColorsDesc': 'Toca una asignatura para elegir un color.',
      'settingsNoSubjectsLoaded': 'Sin asignaturas cargadas',
      'settingsNoSubjectsLoadedDesc': 'Abre tu horario primero.',
      'settingsCustomColor': 'Personalizado',
      'settingsDefaultColor': 'Color predeterminado',
      'settingsColorFor': 'Color para "{s}"',
      'settingsColorReset': 'Restablecer predeterminado',
      'settingsColorCustomPicker': 'Elegir color personalizado',
      'settingsColorApply': 'Aplicar color',
      'settingsColorRed': 'Rojo',
      'settingsColorGreen': 'Verde',
      'settingsColorBlue': 'Azul',
      'settingsThemeMode': 'Esquema de colores',
      'settingsThemeLight': 'Claro',
      'settingsThemeSystem': 'Sistema',
      'settingsThemeDark': 'Oscuro',
      'settingsSectionTimetable': 'Horario',
      'settingsShowCancelled': 'Mostrar clases canceladas',
      'settingsShowCancelledDesc':
          'Las clases canceladas se muestran en el horario',
      'settingsCancelledColor': 'Color cancelado',
      'settingsCancelledColorDesc': 'Personalizar el color de las clases canceladas',
      'settingsLessonDesignTitle': 'Diseño de clases y tarjetas',
      'settingsLessonDesignDesc': 'Personaliza el estilo, brillo, desenfoque y detalles.',
      'settingsLessonStyle': 'Estilo de tarjeta',
      'settingsLessonStyleDesc': 'Elige la estética visual de las clases.',
      'settingsLessonStyleModern': 'Moderno (Tintado)',
      'settingsLessonStyleGlass': 'Efecto cristal (Glass)',
      'settingsLessonStyleGradient': 'Degradado',
      'settingsLessonStyleOutline': 'Contorno / Minimal',
      'settingsLessonStyleSolid': 'Sólido',
      'settingsLessonGlow': 'Efecto de brillo (Glow)',
      'settingsLessonGlowDesc': 'Añade un aura brillante detrás de las tarjetas.',
      'settingsLessonGlowMode': 'Modo de brillo',
      'settingsLessonGlowModeActive': 'Solo clase actual',
      'settingsLessonGlowModeAll': 'Todas las clases',
      'settingsLessonGlowIntensity': 'Intensidad del brillo',
      'settingsLessonBlur': 'Desenfoque de cristal',
      'settingsLessonBlurDesc': 'Desenfoca el fondo detrás de las tarjetas de clase.',
      'settingsLessonBlurAmount': 'Intensidad del desenfoque',
      'settingsLessonCardOpacity': 'Opacidad de tarjeta',
      'settingsLessonBorderRadius': 'Radio de esquinas',
      'settingsLessonAccentStyle': 'Barra de acento',
      'settingsLessonAccentBar': 'Barra clásica',
      'settingsLessonAccentThin': 'Línea fina',
      'settingsLessonAccentDot': 'Punto indicador',
      'settingsLessonAccentNone': 'Ninguna',
      'settingsLessonShowTeacher': 'Mostrar profesor',
      'settingsLessonShowTeacherDesc': 'Mostrar nombre o iniciales del profesor en la tarjeta.',
      'settingsLessonShowRoom': 'Mostrar aula',
      'settingsLessonShowRoomDesc': 'Mostrar número de aula en la tarjeta.',
      'settingsLessonCompactMode': 'Modo compacto',
      'settingsLessonCompactModeDesc': 'Espaciado reducido para mayor densidad.',
      'settingsLessonDimPast': 'Atenuar clases pasadas',
      'settingsLessonDimPastDesc': 'Atenuar y poner en escala de grises las clases finalizadas.',
      'settingsLessonCancelledPattern': 'Rayado de cancelación',
      'settingsLessonCancelledPatternDesc': 'Muestra un patrón de rayas diagonales si la clase se cancela.',
      'settingsLessonPreviewRegular': 'Normal',
      'settingsLessonPreviewActive': 'Clase actual',
      'settingsLessonPreviewCancelled': 'Cancelada',
      'settingsLessonPreviewHeader': 'Vista previa en vivo',
      'settingsMonochromeLessons': 'Clases monocromáticas',
      'settingsMonochromeLessonsDesc':
          'Usar colores Material You en lugar de colores individuales',
      'settingsDemoMode': 'Modo demo',
      'settingsDemoModeDesc':
          'Usa datos de demostración locales en lugar del servidor escolar (inmediato).',
      'settingsBackgroundAnimations': 'Animaciones de fondo',
      'settingsBackgroundAnimationsDesc':
          'Mostrar efectos de degradado animados en el fondo',
      'settingsBackgroundGyroscope': 'Respuesta del giroscopio',
      'settingsBackgroundGyroscopeDesc':
          'Hace que el fondo reaccione al movimiento del dispositivo',
      'settingsBackgroundStyle': 'Estilo de animación',
      'settingsBackgroundStyleOrbs': 'Orbes',
      'settingsBackgroundStyleSpace': 'Espacio',
      'settingsBackgroundStyleBubbles': 'Burbujas',
      'settingsBackgroundStyleLines': 'Líneas',
      'settingsBackgroundStyleThreeD': 'Formas 3D',
      'settingsBackgroundStyleNebula': 'Nebulosa',
      'settingsBackgroundStylePrism': 'Prisma',
      'settingsBackgroundStyleWaves': 'Ondas',
      'settingsBackgroundStyleGrid': 'Cuadrícula',
      'settingsBackgroundStyleRings': 'Anillos',
      'settingsBackgroundStyleCustom': 'Personalizado',
      'settingsCustomBackgrounds': 'Fondos personalizados',
      'settingsCustomBackgroundsDesc': 'Crear, guardar, importar y exportar',
      'settingsCustomBackgroundsSelected': 'Seleccionado: {name}',

      'bgEditorTitle': 'Editor de fondo',
      'bgEditorPreviewTab': 'Vista previa',
      'bgEditorDesignTab': 'Diseño',
      'bgEditorLibraryTab': 'Biblioteca',
      'bgEditorStartPoints': 'Puntos de inicio',
      'bgEditorUpdatedAt': 'Actualizado',
      'bgEditorEdit': 'Editar',
      'bgEditorLivePreview': 'Vista previa en vivo',
      'bgEditorUnsavedTitle': 'Cambios sin guardar',
      'bgEditorUnsavedDesc':
          '¿Guardar cambios, descartarlos o seguir editando?',
      'bgEditorDiscard': 'Descartar',
      'bgEditorSave': 'Guardar',
      'bgEditorSaved': 'Guardado.',
      'bgEditorSaveFailed': 'Error al guardar.',
      'bgEditorUseInApp': 'Usar en la app',
      'bgEditorApplied': 'Aplicado como fondo.',
      'bgEditorLibrary': 'Biblioteca',
      'bgEditorNew': 'Nuevo',
      'bgEditorNewName': 'Nuevo fondo',
      'bgEditorDuplicate': 'Duplicar',
      'bgEditorDelete': 'Eliminar',
      'bgEditorDeleteTitle': '¿Eliminar fondo?',
      'bgEditorDeleteDesc': 'Este fondo se eliminará permanentemente.',
      'bgEditorDeleteConfirm': 'Eliminar',

      'bgEditorExportTitle': 'Exportar',
      'bgEditorExportSelected': 'Exportar seleccionado',
      'bgEditorExportAll': 'Exportar todo',
      'bgEditorExported': 'JSON copiado al portapapeles.',
      'bgEditorExportedAll': 'Todos los fondos copiados como JSON.',

      'bgEditorImportTitle': 'Importar',
      'bgEditorImportFromClipboard': 'Desde el portapapeles',
      'bgEditorImportFromFile': 'Desde un archivo',
      'bgEditorImportClipboardEmpty': 'El portapapeles está vacío.',
      'bgEditorImportedCount': 'Importados {n} fondo(s).',
      'bgEditorImportFailed': 'Error de importación.',

      'bgEditorMeta': 'Metadatos',
      'bgEditorName': 'Nombre',
      'bgEditorBase': 'Degradado base',
      'bgEditorUseThemeColors': 'Usar colores del tema',
      'bgEditorUseThemeColorsDesc': 'Usa colores del tema actual.',
      'bgEditorGradientLinear': 'Lineal',
      'bgEditorGradientRadial': 'Radial',
      'bgEditorBaseOpacity': 'Opacidad base',
      'bgEditorGradientAngle': 'Ángulo',
      'bgEditorRadialCenterX': 'Centro X',
      'bgEditorRadialCenterY': 'Centro Y',
      'bgEditorRadialRadius': 'Radio',
      'bgEditorColorN': 'Color {n}',

      'bgEditorOrbs': 'Orbes',
      'bgEditorOrbsEnabled': 'Orbes activados',
      'bgEditorOrbsThemeDesc': 'Usa colores del tema para los orbes.',
      'bgEditorRandomizeSeed': 'Aleatorizar semilla',
      'bgEditorOrbsCount': 'Cantidad',
      'bgEditorOrbsSize': 'Tamaño',
      'bgEditorOrbsVariance': 'Variación',
      'bgEditorOrbsOpacity': 'Opacidad',
      'bgEditorOrbsSoftness': 'Suavidad',
      'bgEditorOrbColorN': 'Color de orbe {n}',

      'bgEditorEffects': 'Patrón y efectos',
      'bgEditorPatternNone': 'Ninguno',
      'bgEditorPatternLines': 'Líneas',
      'bgEditorPatternGrid': 'Cuadrícula',
      'bgEditorPatternOpacity': 'Opacidad del patrón',
      'bgEditorPatternScale': 'Escala',
      'bgEditorPatternAngle': 'Ángulo del patrón',
      'bgEditorNoise': 'Ruido',
      'bgEditorVignette': 'Viñeta',

      'bgEditorMotion': 'Movimiento',
      'bgEditorAnimate': 'Animar',
      'bgEditorSpeed': 'Velocidad',
      'bgEditorParallax': 'Parallax',

      'bgEditorAiTitle': 'Generador IA',
      'bgEditorAiDesc': 'Describe un estilo — la IA crea un nuevo fondo.',
      'bgEditorAiHint': 'p. ej. “nebulosa neón, suave, oscura, azul/rosa”',
      'bgEditorAiGenerate': 'Generar con IA',
      'bgEditorAiSystem': '''
You generate ONE Flutter background preset.
Output ONLY valid JSON (no markdown, no commentary).

Return a single JSON object with this schema:
{
    "version": 1,
    "name": "...",
    "base": {
        "type": "linear"|"radial",
        "useThemeColors": true|false,
        "colors": ["#RRGGBB", ...],
        "opacity": 0.0-1.0,
        "angleDeg": 0-360,
        "centerX": -1..1,
        "centerY": -1..1,
        "radius": 0.3-2.5
    },
    "orbs": {
        "enabled": true|false,
        "useThemeColors": true|false,
        "colors": ["#RRGGBB", ...],
        "count": 0-18,
        "seed": 0-2147483647,
        "size": 40-480,
        "sizeVariance": 0.0-1.0,
        "opacity": 0.0-1.0,
        "softness": 0.0-1.0
    },
    "pattern": {
        "type": "none"|"lines"|"grid",
        "opacity": 0.0-1.0,
        "scale": 0.4-3.5,
        "angleDeg": 0-360
    },
    "noise": 0.0-0.5,
    "vignette": 0.0-1.0,
    "animate": true|false,
    "animationSpeed": 0.0-3.0,
    "parallaxStrength": 0.0-1.0
}

Keep values reasonable and visually pleasing. Prefer 2-3 base colors.
Use "useThemeColors": true unless the prompt asks for specific colors.
''',
      'bgEditorAiUserPrefix': 'Description:',
      'bgEditorAiUserSchemaHint':
          'Return JSON only. Do not wrap in code fences.',
      'bgEditorAiGeneratedName': 'Fondo IA',
      'bgEditorAiSuccess': 'Fondo IA creado.',
      'bgEditorAiError': 'IA: ',
      'settingsGlassEffect': 'Efecto de desenfoque',
      'settingsGlassEffectDesc': 'Activa el desenfoque en la interfaz',
      'settingsSectionUpdates': 'Actualizaciones',
      'settingsProgressivePush': 'Notificación push progresiva',
      'settingsProgressivePushDesc':
          'Mostrar la clase actual como notificación persistente',
      'settingsDailyBriefingPush': 'Notificación de resumen diario',
      'settingsDailyBriefingPushDesc':
          'Muestra por la mañana una vista compacta de tu día escolar',
      'settingsImportantChangesPush': 'Cambios importantes',
      'settingsImportantChangesPushDesc':
          'Avisa sobre cancelaciones, cambios de aula y sustituciones',
      'settingsRefreshPushWidgetNow': 'Actualizar push y widget ahora',
      'settingsRefreshPushWidgetNowDesc':
          'Carga inmediatamente los datos más recientes de la caché API y actualiza widget y push',
      'settingsBackgroundLoading':
          'Los datos se están cargando en segundo plano...',
      'settingsSectionAbout': 'Acerca de',
      'appName': 'Untis+',
      'settingsAppVersion': 'Versión',
      'settingsBuild': 'Build',
      'settingsSectionSubjects': 'Asignaturas & Colores',
      'settingsGithubRepoLabel': 'github.com/ninocss/UntisPlus',
      'settingsGithubUpdateCheck': 'Buscar actualizaciones en GitHub',
      'settingsGithubUpdateCheckDesc':
          'Comprueba la última versión de ninocss/UntisPlus.',
      'settingsGithubDirectDownload':
          'Descargar directamente la versión más reciente',
      'settingsGithubDirectDownloadDesc':
          'Al comprobar, abre inmediatamente el APK/archivo de versión más reciente.',
      'settingsGithubChecking': 'Buscando actualizaciones...',
      'settingsGithubUpdateFound': 'Nueva versión encontrada: {v}',
      'settingsGithubDownloadNow': 'Descargar',
      'settingsGithubNoDownloadAsset':
          'No se encontró un archivo de descarga directa. Abriendo página de versiones...',
      'settingsGithubDownloadStarted':
          'La descarga/versión se abrió en el navegador.',
      'settingsGithubOpenFailed': 'No se pudo abrir el enlace de descarga.',
      'settingsGithubCheckFailed':
          'La comprobación de actualizaciones falló. Inténtalo de nuevo más tarde.',
      'settingsGithubNoUpdate': 'Ya tienes la versión más reciente.',
      'settingsGithubCurrentVersion': 'Versión instalada',
      'settingsGithubLatestVersion': 'Última versión',
      'settingsGithubInstallQuestion':
          '¿Quieres descargar e instalar esta actualización ahora?',
      'settingsGithubInstallNow': 'Instalar ahora',
      'settingsGithubInstallLater': 'Más tarde',
      'settingsGithubInstallPrompted':
          'Descarga iniciada. El aviso de instalación aparece al terminar la descarga.',
      'settingsGithubOpenReleasePage': 'Abrir página de versiones de GitHub',
      'settingsBackupIncludeApiKeys': 'Incluir claves API',
      'settingsBackupIncludeApiKeysDesc':
          'Actívalo solo si guardas la copia en un lugar seguro.',
      'settingsBackupExportAllFile': 'Exportar toda la configuración a archivo',
      'settingsBackupExportAllClipboard':
          'Copiar toda la configuración al portapapeles',
      'settingsBackupImportAllTitle': 'Importar toda la configuración',
      'settingsBackupImportAllFile': 'Importar desde archivo',
      'settingsBackupImportAllClipboard': 'Importar desde portapapeles',
      'settingsBackupExportDialogTitle': 'Guardar copia de configuración',
      'settingsBackupExportSuccess': 'Archivo de copia guardado.',
      'settingsBackupExportClipboardSuccess':
          'Copia JSON copiada al portapapeles.',
      'settingsBackupImportSuccess': 'Copia importada.',
      'settingsBackupImportFailed':
          'Error de importación. Verifica el JSON y el esquema.',
      'settingsBackupClipboardEmpty': 'El portapapeles está vacío.',
      'settingsBackupConfirmTitle': 'Confirmar importación',
      'settingsBackupConfirmDesc':
          'La importación sobrescribe la configuración actual y actualiza la app al instante.',
      'settingsBackupConfirmAction': 'Importar',

      'aiSystemPersona':
          'Eres "Asistente de Horario", un ayudante IA amigable y motivador para estudiantes.',
      'aiSystemRules': '''REGLAS:
- Responde basándote en los datos del horario y exámenes anteriores.
- NO inventes asignaturas, horarios, profesores ni otra información.
- Considera exámenes/pruebas en tus respuestas si aplica.
- Si algo no se puede deducir de los datos, dilo abiertamente.
- Respeta los marcadores [CANCELADO] (esas clases no tienen lugar).
- "Horas libres" = huecos entre dos clases.
- Responde en español, de forma amigable, útil y concisa.
- No empieces automáticamente con "Sí," – responde directamente.
- Puedes usar Markdown para el formato (ej. listas, **negrita**).''',

      'settingsChangelogTitle': 'Novedades (Changelog)',
      'settingsChangelogSubtitle': '¿Qué hay de nuevo en Untis+?',
      'changelogTitle': 'Novedades',
      'changelogLoadError': 'Error al cargar',
      'changelogRetry': 'Reintentar',

      'aiNewSearch': 'Nueva búsqueda',
      'aiSearchRunning': 'Búsqueda en curso…',
      'aiSearchShapingDesc':
          'La IA está generando tarjetas y bloques de clases a partir de tu horario.',
      'aiStepAnalyzingTimetable': 'Analizando el horario…',
      'aiStepSortingResults': 'Ordenando resultados…',
      'aiStepAlmostDone': 'Casi listo…',
      'aiSearchHintPlaceholder': 'Clases, horas libres, exámenes …',
      'aiOverview': 'Resumen',
      'aiEmptyPromptTitle': '¿Qué deseas saber?',
      'aiEmptyPromptSubtitle':
          'Pregunta sobre clases, exámenes o aulas libres.',
      'aiPromptWhenFinishToday': '¿A qué hora termino hoy?',
      'aiPromptWhatCancelledToday': '¿Qué se cancela hoy?',
      'aiPromptUpcomingExams': '¿Qué exámenes tengo pronto?',
      'aiPromptFirstLessonToday': '¿Cuál es mi primera clase hoy?',
      'aiPromptNextLesson': '¿Cuándo es mi próxima clase?',
      'aiPromptTomorrowSchedule': '¿Qué tengo mañana?',
      'aiClearResult': 'Borrar resultado',
      'aiSearchAgain': 'Buscar de nuevo',
      'aiClearInput': 'Borrar',
      'aiLessons': 'Clases',
      'aiMore': 'Más',
      'aiSettingsMenu': 'Ajustes de IA',
      'aiResultsCardDesc':
          'Los resultados se muestran como tarjetas y bloques de clases.',
      'aiDismiss': 'Ocultar',
      'aiLessonsCountSingle': '1 clase',
      'aiLessonsCountPlural': '{count} clases',
      'aiExamsCountWeekSingle': '1 examen esta semana',
      'aiExamsCountWeekPlural': '{count} exámenes esta semana',

      'classPickerHeaderDesc':
          'Selecciona un horario. Los favoritos se muestran arriba.',
      'classPickerDefaultBadge': 'Predeterminado',
      'classPickerSetDefault': 'Establecer como predeterminado',
      'classPickerOtherClasses': 'Otras clases',
      'classPickerRemoveFavorite': 'Eliminar de favoritos',
      'classPickerAddFavorite': 'Guardar en favoritos',

      'navGrades': 'Notas',
      'gradesTitle': 'Seguimiento de notas',
      'gradesAddTitle': 'Añadir nota',
      'gradesEditTitle': 'Editar nota',
      'gradesSubjectLabel': 'Asignatura',
      'gradesGradeLabel': 'Nota',
      'gradesWeightLabel': 'Peso',
      'gradesTypeLabel': 'Tipo',
      'gradesAverage': 'Promedio',
      'gradesNone': 'Sin notas',
      'gradesNoneHint': 'Toca + para añadir tu primera nota.',
    },
  };
}
