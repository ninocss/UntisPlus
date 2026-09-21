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

  /// Read-only catalog diagnostics for tests and CI. UI code must use [of]
  /// instead of reaching into the catalog directly.
  static Map<String, Set<String>> get catalogKeys => {
    for (final entry in _strings.entries) entry.key: entry.value.keys.toSet(),
  };

  static Map<String, List<String>> get emptyCatalogValues => {
    for (final entry in _strings.entries)
      entry.key: entry.value.entries
          .where((value) {
            final content = value.value;
            if (content is String) return content.trim().isEmpty;
            if (content is Iterable) return content.isEmpty;
            return content == null;
          })
          .map((value) => value.key)
          .toList(growable: false),
  };

  static final RegExp _placeholderPattern = RegExp(
    r'\{([A-Za-z][A-Za-z0-9_]*)\}',
  );

  /// Placeholder names are part of the localization API. Keeping them equal
  /// means a caller can format any language without grammar in UI code.
  static Map<String, Map<String, Set<String>>> get catalogPlaceholders => {
    for (final locale in _strings.entries)
      locale.key: {
        for (final translation in locale.value.entries)
          translation.key: translation.value is String
              ? _placeholderPattern
                    .allMatches(translation.value as String)
                    .map((match) => match.group(1)!)
                    .toSet()
              : const <String>{},
      },
  };

  String _t(String key) => _strings[locale]?[key] ?? _strings['de']![key]!;

  /// Translation escape hatch for UI surfaces that are assembled dynamically.
  /// Keys are kept in the same per-locale tables as the typed strings above.
  String ui(String key) => _t('ui_$key');

  /// Formats a dynamic UI string without making callers duplicate sentence
  /// order or grammar. Values are deliberately named so every language can
  /// choose its own placement in the catalog entry.
  String uiFormat(String key, Map<String, Object?> values) {
    var value = ui(key);
    for (final entry in values.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value ?? ''}');
    }
    return value;
  }

  /// Copy transported to native alarm and widget processes. Those processes
  /// can run while Flutter is stopped, so they must not fall back to German
  /// when the user selected another app language.
  Map<String, String> nativeAlarmCopy() => {
    'channelReminder': ui('nativeAlarmReminderChannel'),
    'channelReminderDescription': ui('nativeAlarmReminderChannelDesc'),
    'channelAlarm': ui('nativeAlarmChannel'),
    'channelAlarmDescription': ui('nativeAlarmChannelDesc'),
    'channelRefresh': ui('nativeAlarmRefreshChannel'),
    'reminderTitle': ui('nativeAlarmReminderTitle'),
    'disableToday': ui('nativeAlarmDisableToday'),
    'alarmTitle': ui('nativeAlarmTitle'),
    'swipeHint': ui('nativeAlarmSwipeHint'),
    'snooze': ui('nativeAlarmSnooze'),
    'dismiss': ui('nativeAlarmDismiss'),
    'refreshing': ui('nativeAlarmRefreshing'),
    'defaultLabel': ui('alarmSchedule'),
    'statusActive': ui('nativeAlarmStatusActive'),
    'statusSnoozing': ui('nativeAlarmStatusSnoozing'),
    'timeAccessibility': ui('nativeAlarmTimeAccessibility'),
  };

  Map<String, String> nativeWidgetCopy() => {
    'setupTitle': ui('nativeWidgetSetupTitle'),
    'setupAccount': ui('nativeWidgetSetupAccount'),
    'setupProfile': ui('nativeWidgetSetupProfile'),
    'setupProfileHint': ui('nativeWidgetSetupProfileHint'),
    'setupNoProfile': ui('nativeWidgetSetupNoProfile'),
    'setupNoAccount': ui('nativeWidgetSetupNoAccount'),
    'fallbackRefreshing': ui('nativeWidgetRefreshing'),
    'fallbackHomework': ui('widgetNoOpenHomework'),
    'fallbackExams': ui('widgetNoUpcomingExams'),
    'fallbackNotices': ui('widgetNoNotices'),
    'fallbackCurrent': ui('widgetNoCurrentLesson'),
    'fallbackNext': ui('widgetNoLessonsToday'),
    'fallbackSchedule': ui('widgetNoScheduleData'),
    'today': ui('widgetToday'),
    'titleSchedule': ui('widgetSchedule'),
    'titleHomework': ui('widgetHomework').toUpperCase(),
    'titleNotices': ui('widgetNotices').toUpperCase(),
  };

  // ── Navigation ──────────────────────────────────────────────────────────────
  String get navWeek => _t('navWeek');
  String get navHomework => _t('navHomework');
  String get navExams => _t('navExams');
  String get navInfo => _t('navInfo');
  String get navMenu => _t('navMenu');
  String get navAi => _t('navAi');

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
  String get onboardingFeatureUpdatesTitle =>
      _t('onboardingFeatureUpdatesTitle');
  String get onboardingFeatureUpdatesDesc => _t('onboardingFeatureUpdatesDesc');
  String get onboardingFeatureBackupTitle => _t('onboardingFeatureBackupTitle');
  String get onboardingFeatureBackupDesc => _t('onboardingFeatureBackupDesc');
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
  String get tutorialStepAiTitle => _t('tutorialStepAiTitle');
  String get tutorialStepAiDesc => _t('tutorialStepAiDesc');
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
  String get timetableMoreActions => _t('timetableMoreActions');
  String get timetableExportImage => _t('timetableExportImage');
  String get timetableNoClassesFound => _t('timetableNoClassesFound');
  String get freeRoomsTitle => _t('freeRoomsTitle');
  String get freeRoomsSelectTime => _t('freeRoomsSelectTime');
  String get freeRoomsNoneFound => _t('freeRoomsNoneFound');
  String get freeRoomsNoRangesHint => _t('freeRoomsNoRangesHint');
  String get noLesson => _t('noLesson');
  String get timetableOfflineCache => _t('timetableOfflineCache');
  String get timetableNotSignedIn => _t('timetableNotSignedIn');
  String timetableHttpError(int status) =>
      _t('timetableHttpError').replaceAll('{status}', '$status');
  String get timetableUnknownApiError => _t('timetableUnknownApiError');
  String get timetableLoadError => _t('timetableLoadError');
  String freeRoomsCount(int n) => _t('freeRoomsCount').replaceAll('{n}', '$n');

  List<String> get weekDayShort =>
      List<String>.from(_strings[locale]!['weekDayShort'] as List);
  List<String> get weekDayFull =>
      List<String>.from(_strings[locale]!['weekDayFull'] as List);

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

  String get homeworkAddTitle => _t('homeworkAddTitle');
  String get homeworkEditTitle => _t('homeworkEditTitle');
  String get homeworkAddDesc => _t('homeworkAddDesc');
  String get examsAddDesc => _t('examsAddDesc');
  String get homeworkSubjectLabel => _t('homeworkSubjectLabel');
  String get homeworkTaskLabel => _t('homeworkTaskLabel');
  String get homeworkDueDateLabel => _t('homeworkDueDateLabel');
  String get homeworkActionCustom => _t('homeworkActionCustom');
  String get homeworkActionImport => _t('homeworkActionImport');
  String get homeworkSave => _t('homeworkSave');
  String get homeworkDelete => _t('homeworkDelete');
  String get homeworkCancel => _t('homeworkCancel');
  String get homeworkFilterAll => _t('homeworkFilterAll');
  String get homeworkFilterOpen => _t('homeworkFilterOpen');
  String get homeworkFilterDone => _t('homeworkFilterDone');
  String get examsUpcomingCount => _t('examsUpcomingCount');
  String get examsUpcomingNext => _t('examsUpcomingNext');
  String get gradesTypeSingle => _t('gradesTypeSingle');
  String get gradesDateLabel => _t('gradesDateLabel');
  String gradesCountLabel(int count) {
    final raw = _t('gradesCountLabel');
    if (raw == 'gradesCountLabel') {
      return count == 1 ? '1 Note' : '$count Noten';
    }
    return raw.replaceAll('{count}', '$count');
  }

  String get homeworkImportTitle => _t('homeworkImportTitle');
  String get homeworkImportSuccess => _t('homeworkImportSuccess');
  String get homeworkImportError => _t('homeworkImportError');
  String get subjectOverviewTitle => _t('subjectOverviewTitle');
  String get addGradeForSubject => _t('addGradeForSubject');
  String get addExamForSubject => _t('addExamForSubject');
  String get addHomeworkForSubject => _t('addHomeworkForSubject');
  String get noGradesForSubject => _t('noGradesForSubject');
  String get noExamsForSubject => _t('noExamsForSubject');
  String get noHomeworkForSubject => _t('noHomeworkForSubject');

  // ── School Info / Notifications ────────────────────────────────────────────
  String get infoTitle => _t('infoTitle');
  String get infoReload => _t('infoReload');
  String get infoUpdated => _t('infoUpdated');
  String get infoEmpty => _t('infoEmpty');
  String get infoEmptyHint => _t('infoEmptyHint');
  String get infoFetchError => _t('infoFetchError');
  String get infoOpenLink => _t('infoOpenLink');
  String get infoAttachments => _t('infoAttachments');
  String get attachmentSave => _t('attachmentSave');
  String get attachmentSaved => _t('attachmentSaved');
  String get attachmentDownloadFailed => _t('attachmentDownloadFailed');
  String get attachmentDemoUnavailable => _t('attachmentDemoUnavailable');
  String get infoCopyMessage => _t('infoCopyMessage');
  String get infoMessageCopied => _t('infoMessageCopied');
  String get messageComposeTitle => _t('messageComposeTitle');
  String get messageRecipients => _t('messageRecipients');
  String get messageRecipientsLoading => _t('messageRecipientsLoading');
  String get messageRecipientSelect => _t('messageRecipientSelect');
  String get messageRecipientsApply => _t('messageRecipientsApply');
  String get messageNoRecipients => _t('messageNoRecipients');
  String get messageRecipientsFailed => _t('messageRecipientsFailed');
  String get messageSubject => _t('messageSubject');
  String get messageBody => _t('messageBody');
  String get messageAttach => _t('messageAttach');
  String get messageAttachmentLimit => _t('messageAttachmentLimit');
  String get messageAttachmentTooLarge => _t('messageAttachmentTooLarge');
  String get messageDraftAutosave => _t('messageDraftAutosave');
  String get messageDiscardDraft => _t('messageDiscardDraft');
  String get messageRequiredFields => _t('messageRequiredFields');
  String get messageSend => _t('messageSend');
  String get messageSending => _t('messageSending');
  String get messageSent => _t('messageSent');
  String get messageSendFailed => _t('messageSendFailed');
  String get messageDemoUnavailable => _t('messageDemoUnavailable');

  /// Label for an attachment counter, e.g. "2 Attached PDFs" or
  /// "1 Attached File". Pass an [extension] (upper case, e.g. "PDF") when all
  /// attachments share the same file type, otherwise pass null for the
  /// generic file wording.
  String infoAttachmentLabel(int count, String? extension) {
    final ext = (extension ?? '').trim().toUpperCase();
    if (ext.isNotEmpty) {
      final template = count == 1
          ? _t('infoAttachedExtOne')
          : _t('infoAttachedExtMany');
      return template.replaceAll('{ext}', ext);
    }
    return count == 1 ? _t('infoAttachedFile') : _t('infoAttachedFiles');
  }

  String get notificationActionNextLessonLabel =>
      _t('notificationActionNextLesson');
  String get notificationActionFreeRooms => _t('notificationActionFreeRooms');
  String get notificationActionOpenDay => _t('notificationActionOpenDay');
  String get notificationChannelCurrentLessonName =>
      _t('notificationChannelCurrentLessonName');
  String get notificationChannelCurrentLessonDesc =>
      _t('notificationChannelCurrentLessonDesc');
  String get notificationChannelDailyBriefingName =>
      _t('notificationChannelDailyBriefingName');
  String get notificationChannelDailyBriefingDesc =>
      _t('notificationChannelDailyBriefingDesc');
  String get notificationChannelImportantChangesName =>
      _t('notificationChannelImportantChangesName');
  String get notificationChannelImportantChangesDesc =>
      _t('notificationChannelImportantChangesDesc');
  String get notificationChannelUpdatesName =>
      _t('notificationChannelUpdatesName');
  String get notificationChannelUpdatesDesc =>
      _t('notificationChannelUpdatesDesc');
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
  String get aiClearHistoryTitle => _t('aiClearHistoryTitle');
  String get aiClearHistoryDesc => _t('aiClearHistoryDesc');
  String get aiClearHistorySuccess => _t('aiClearHistorySuccess');
  String get aiClearHistoryTileTitle => _t('aiClearHistoryTileTitle');
  String get aiClearHistoryTileDesc => _t('aiClearHistoryTileDesc');
  String get aiLocalModelDescSmall => _t('aiLocalModelDescSmall');
  String get aiLocalModelDescBalanced => _t('aiLocalModelDescBalanced');
  String get aiLocalModelDescMultilingual => _t('aiLocalModelDescMultilingual');
  String get aiLocalModelDescHighQuality => _t('aiLocalModelDescHighQuality');
  String get aiLocalModelDescStrong => _t('aiLocalModelDescStrong');
  String get aiTyping => _t('aiTyping');
  String get aiChatTitle => _t('aiChatTitle');
  String get aiChatSubtitle => _t('aiChatSubtitle');
  String get aiTryIt => _t('aiTryIt');
  List<String> get aiSuggestions =>
      List<String>.from(_strings[locale]!['aiSuggestions'] as List);
  List<String> get aiChatSuggestions =>
      List<String>.from(_strings[locale]!['aiChatSuggestions'] as List);

  String get aiNoSchoolToday => _t('aiNoSchoolToday');
  String aiCurrentLessonSummary(String subject, String room, String end) =>
      _t('aiCurrentLessonSummary')
          .replaceAll('{subject}', subject)
          .replaceAll('{room}', room)
          .replaceAll('{end}', end);
  String get aiNoCurrentLesson => _t('aiNoCurrentLesson');
  String get aiNoNextLessonSchool => _t('aiNoNextLessonSchool');
  String aiNextLessonSummary(String subject, String room, String start) =>
      _t('aiNextLessonSummary')
          .replaceAll('{subject}', subject)
          .replaceAll('{room}', room)
          .replaceAll('{start}', start);
  String get aiNoMoreLessons => _t('aiNoMoreLessons');
  String get aiDefaultExamType => _t('aiDefaultExamType');

  // ── Settings ─────────────────────────────────────────────────────────────────
  String get settingsTitle => _t('settingsTitle');
  String get commonSaveChanges => _t('commonSaveChanges');
  String get settingsLoggedInAs => _t('settingsLoggedInAs');
  String get settingsLogout => _t('settingsLogout');
  String get settingsSectionQuick => _t('settingsSectionQuick');
  String get settingsSectionGeneral => _t('settingsSectionGeneral');
  String get settingsAppearance => _t('settingsAppearance');
  String get settingsAppearanceDesc => _t('settingsAppearanceDesc');
  String get settingsAppearanceSurfaces => _t('settingsAppearanceSurfaces');
  String get settingsAppearanceMotion => _t('settingsAppearanceMotion');
  String get settingsAppearanceTimetable => _t('settingsAppearanceTimetable');
  String get settingsAppearanceApp => _t('settingsAppearanceApp');
  String get settingsVisualTheme => _t('settingsVisualTheme');
  String get settingsVisualThemeDesc => _t('settingsVisualThemeDesc');
  String get themeDefault => _t('themeDefault');
  String get themeDefaultDesc => _t('themeDefaultDesc');
  String get themeManga => _t('themeManga');
  String get themeMangaDesc => _t('themeMangaDesc');
  String get themeGlass => _t('themeGlass');
  String get themeGlassDesc => _t('themeGlassDesc');
  String get themeCyber => _t('themeCyber');
  String get themeCyberDesc => _t('themeCyberDesc');
  String get settingsHubNotifications => _t('settingsHubNotifications');
  String get settingsHubDataBackup => _t('settingsHubDataBackup');
  String get settingsHubDataBackupDesc => _t('settingsHubDataBackupDesc');
  String get settingsHubAccount => _t('settingsHubAccount');
  String get settingsHubUpdatesAbout => _t('settingsHubUpdatesAbout');
  String get settingsSupport => _t('settingsSupport');
  String get settingsSupportDesc => _t('settingsSupportDesc');
  String get settingsReportIssue => _t('settingsReportIssue');
  String get settingsReportIssueDesc => _t('settingsReportIssueDesc');
  String get settingsLanguage => _t('settingsLanguage');
  String get settingsSectionAI => _t('settingsSectionAI');
  String get settingsAiProvider => _t('settingsAiProvider');
  String get settingsAiProviderGemini => _t('settingsAiProviderGemini');
  String get settingsAiProviderOpenAi => _t('settingsAiProviderOpenAi');
  String get settingsAiProviderMistral => _t('settingsAiProviderMistral');
  String get settingsAiProviderCustom => _t('settingsAiProviderCustom');
  String get settingsAiModel => _t('settingsAiModel');
  String get settingsAiParametersTitle => _t('settingsAiParametersTitle');
  String get settingsAiParametersDesc => _t('settingsAiParametersDesc');
  String get settingsAiAdjustmentTitle => _t('settingsAiAdjustmentTitle');
  String get settingsAiPersonaTitle => _t('settingsAiPersonaTitle');
  String get settingsAiPersonaHelpful => _t('settingsAiPersonaHelpful');
  String get settingsAiPersonaStrict => _t('settingsAiPersonaStrict');
  String get settingsAiPersonaBuddy => _t('settingsAiPersonaBuddy');
  String get settingsAiDataTitle => _t('settingsAiDataTitle');
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
    '[current_lesson]': _t('aiVar_current_lesson'),
    '[next_lesson]': _t('aiVar_next_lesson'),
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
  String get settingsAiLocalModelDownloading =>
      _t('settingsAiLocalModelDownloading');
  String get settingsAiLocalModelInstalled =>
      _t('settingsAiLocalModelInstalled');
  String get settingsAiLocalModelDelete => _t('settingsAiLocalModelDelete');
  String get settingsAiLocalModelActive => _t('settingsAiLocalModelActive');
  String get settingsAiLocalModelError => _t('settingsAiLocalModelError');
  String get aiLocalModelExamNotSupported => _t('aiLocalModelExamNotSupported');
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
  String get settingsTimetableSwitchAnimation =>
      _t('settingsTimetableSwitchAnimation');
  String get settingsTimetableSwitchAnimationDesc =>
      _t('settingsTimetableSwitchAnimationDesc');
  String get settingsTimetableSwitchAnimationDefault =>
      _t('settingsTimetableSwitchAnimationDefault');
  String get settingsTimetableSwitchAnimationMaterial =>
      _t('settingsTimetableSwitchAnimationMaterial');
  String get settingsTimetableSwitchAnimationDepth =>
      _t('settingsTimetableSwitchAnimationDepth');
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
  String get settingsLessonBlur => _t('settingsLessonBlur');
  String get settingsLessonBlurDesc => _t('settingsLessonBlurDesc');
  String get settingsLessonBlurAmount => _t('settingsLessonBlurAmount');
  String get settingsLessonCardOpacity => _t('settingsLessonCardOpacity');
  String get settingsLessonBorderRadius => _t('settingsLessonBorderRadius');
  String get settingsLessonBorderRadiusCompact =>
      _t('settingsLessonBorderRadiusCompact');
  String get settingsLessonBorderRadiusStandard =>
      _t('settingsLessonBorderRadiusStandard');
  String get settingsLessonBorderRadiusRound =>
      _t('settingsLessonBorderRadiusRound');
  String get settingsLessonBorderRadiusPill =>
      _t('settingsLessonBorderRadiusPill');
  String get settingsLessonAccentStyle => _t('settingsLessonAccentStyle');
  String get settingsLessonAccentBar => _t('settingsLessonAccentBar');
  String get settingsLessonAccentThin => _t('settingsLessonAccentThin');
  String get settingsLessonAccentDot => _t('settingsLessonAccentDot');
  String get settingsLessonAccentNone => _t('settingsLessonAccentNone');
  String get settingsLessonShowTeacher => _t('settingsLessonShowTeacher');
  String get settingsLessonShowTeacherDesc =>
      _t('settingsLessonShowTeacherDesc');
  String get settingsLessonShowSubjectIcons =>
      _t('settingsLessonShowSubjectIcons');
  String get settingsLessonShowSubjectIconsDesc =>
      _t('settingsLessonShowSubjectIconsDesc');
  String get settingsLessonShowRoom => _t('settingsLessonShowRoom');
  String get settingsLessonShowRoomDesc => _t('settingsLessonShowRoomDesc');
  String get settingsLessonCompactMode => _t('settingsLessonCompactMode');
  String get settingsLessonCompactModeDesc =>
      _t('settingsLessonCompactModeDesc');
  String get settingsLessonDimPast => _t('settingsLessonDimPast');
  String get settingsLessonDimPastDesc => _t('settingsLessonDimPastDesc');
  String get settingsLessonCancelledPattern =>
      _t('settingsLessonCancelledPattern');
  String get settingsLessonCancelledPatternDesc =>
      _t('settingsLessonCancelledPatternDesc');
  String get settingsLessonPreviewRegular => _t('settingsLessonPreviewRegular');
  String get settingsLessonPreviewActive => _t('settingsLessonPreviewActive');
  String get settingsLessonPreviewCancelled =>
      _t('settingsLessonPreviewCancelled');
  String get settingsLessonPreviewHeader => _t('settingsLessonPreviewHeader');
  String get settingsMonochromeLessons => _t('settingsMonochromeLessons');
  String get settingsMonochromeLessonsDesc =>
      _t('settingsMonochromeLessonsDesc');
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
  String get settingsSurfaceBlur => _t('settingsSurfaceBlur');
  String get settingsSurfaceBlurDesc => _t('settingsSurfaceBlurDesc');
  String get settingsSurfaceCorners => _t('settingsSurfaceCorners');
  String get settingsSurfaceCornersDesc => _t('settingsSurfaceCornersDesc');
  String get settingsSurfaceCornersCurrent =>
      _t('settingsSurfaceCornersCurrent');
  String get settingsSurfaceCornersSharper =>
      _t('settingsSurfaceCornersSharper');
  String get settingsSurfaceCornersCustom =>
      _t('settingsSurfaceCornersCustom');
  String get settingsSurfaceCornerRadius =>
      _t('settingsSurfaceCornerRadius');
  String get settingsGlowEffects => _t('settingsGlowEffects');
  String get settingsGlowEffectsDesc => _t('settingsGlowEffectsDesc');
  String get settingsAppBgBlur =>
      _strings[locale]?['settingsAppBgBlur'] ??
      _strings['de']?['settingsAppBgBlur'] ??
      'App-Hintergrundunschärfe';
  String get settingsAppBgBlurDesc =>
      _strings[locale]?['settingsAppBgBlurDesc'] ??
      _strings['de']?['settingsAppBgBlurDesc'] ??
      'Verwischt den App-Hintergrund für einen Frosted-Glass-Effekt.';
  String get settingsAppBgBlurAmount =>
      _strings[locale]?['settingsAppBgBlurAmount'] ??
      _strings['de']?['settingsAppBgBlurAmount'] ??
      'Stärke der Hintergrundunschärfe';
  String get settingsIsAmoled => _t('settingsIsAmoled');
  String get settingsIsAmoledDesc => _t('settingsIsAmoledDesc');
  String get settingsPageTransition => _t('settingsPageTransition');
  String get settingsPageTransitionDesc => _t('settingsPageTransitionDesc');
  String get settingsUseMaterialYou => _t('settingsUseMaterialYou');
  String get settingsUseMaterialYouDesc => _t('settingsUseMaterialYouDesc');
  String get settingsCustomColorSeed => _t('settingsCustomColorSeed');
  String get settingsPageTransitionDefault => _t('settingsPageTransitionDefault');
  String get settingsPageTransitionBounce => _t('settingsPageTransitionBounce');
  String get settingsPageTransitionFade => _t('settingsPageTransitionFade');
  String get settingsPageTransitionSlide => _t('settingsPageTransitionSlide');
  String get settingsPageTransitionZoom => _t('settingsPageTransitionZoom');
  String get settingsPageTransitionBlur => _t('settingsPageTransitionBlur');
  String get settingsPageTransitionEaseIn => _t('settingsPageTransitionEaseIn');
  String get settingsPageTransitionEaseOut =>
      _t('settingsPageTransitionEaseOut');
  String get settingsPageTransitionExpo => _t('settingsPageTransitionExpo');
  String get settingsMainTabFadeUp => _t('settingsMainTabFadeUp');
  String get settingsMainTabFadeUpDesc => _t('settingsMainTabFadeUpDesc');
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
  String get settingsSectionCredits => _t('settingsSectionCredits');
  String get settingsCreditsDevelopers => _t('settingsCreditsDevelopers');
  String get settingsCreditsDeveloper => _t('settingsCreditsDeveloper');
  String get settingsCreditsFounderDeveloper =>
      _t('settingsCreditsFounderDeveloper');
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
  String get settingsGithubDownloading => _t('settingsGithubDownloading');
  String get settingsGithubDownloadCancel => _t('settingsGithubDownloadCancel');
  String get settingsGithubDownloadCancelled =>
      _t('settingsGithubDownloadCancelled');
  String get settingsGithubDownloadFailed => _t('settingsGithubDownloadFailed');
  String get settingsGithubNoCompatibleAndroidApk =>
      _t('settingsGithubNoCompatibleAndroidApk');
  String get settingsGithubInstallPermissionRequired =>
      _t('settingsGithubInstallPermissionRequired');
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
  String get settingsGithubInstallerOpened =>
      _t('settingsGithubInstallerOpened');
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
  String get changelogNoData => _t('changelogNoData');
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
  String get aiNewChat => _t('aiNewChat');
  String get aiParameterTemperature => _t('aiParameterTemperature');
  String get aiParameterMaxTokens => _t('aiParameterMaxTokens');
  String get aiParameterTopP => _t('aiParameterTopP');
  String aiOrbsCount(int count) =>
      _t('aiOrbsCount').replaceAll('{count}', '$count');
  String aiNoiseLevel(double pct) =>
      _t('aiNoiseLevel').replaceAll('{pct}', '${pct.round()}');
  String get aiGradientType => _t('aiGradientType');

  // ─────────────────────────────────────────────────────────────────────────────
  static const Map<String, Map<String, dynamic>> _strings = {
    // ── GERMAN ────────────────────────────────────────────────────────────────
    'de': {
      'navWeek': 'Woche',
      'navHomework': 'Hausaufgaben',
      'navExams': 'Prüfungen',
      'navInfo': 'Info',
      'navMenu': 'Menü',
      'navAi': 'KI',
      'timetableOfflineCache': 'Offline-Cache aktiv',
      'timetableNotSignedIn': 'Nicht angemeldet',
      'timetableHttpError':
          'HTTP {status}: Der Stundenplan konnte nicht geladen werden.',
      'timetableUnknownApiError': 'Unbekannter WebUntis-Fehler',
      'timetableLoadError':
          'Der Stundenplan konnte nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.',

      'aiClearHistoryTitle': 'Verlauf löschen?',
      'aiClearHistoryDesc': 'Alle bisherigen Chats werden dauerhaft gelöscht.',
      'aiClearHistorySuccess': 'Chat-Verlauf gelöscht.',
      'aiLocalModelDescSmall': 'Klein, schnell, ideal für Mobilgeräte',
      'aiLocalModelDescBalanced': 'Ausgewogen, gute Qualität',
      'aiLocalModelDescMultilingual': 'Stark bei Mehrsprachigkeit',
      'aiLocalModelDescHighQuality': 'Höhere Qualität, mehr Speicher',
      'aiLocalModelDescStrong': 'Sehr stark, aber größer',

      'notificationActionNextLesson': 'Nächste Stunde',
      'notificationActionFreeRooms': 'Freie Räume',
      'notificationActionOpenDay': 'Tag öffnen',
      'notificationChannelCurrentLessonName': 'Aktuelle Stunde / Pause',
      'notificationChannelCurrentLessonDesc':
          'Laufender Status der aktuellen Stunde.',
      'notificationChannelDailyBriefingName': 'Tagesbriefing',
      'notificationChannelDailyBriefingDesc':
          'Morgendlicher Überblick über den Schultag.',
      'notificationChannelImportantChangesName': 'Stundenplan-Änderungen',
      'notificationChannelImportantChangesDesc':
          'Hinweise zu Ausfall oder Raumwechsel.',
      'notificationChannelUpdatesName': 'App-Updates',
      'notificationChannelUpdatesDesc': 'Hinweise zu App-Verbesserungen.',

      'settingsLessonBorderRadiusCompact': 'Kompakt (6px)',
      'settingsLessonBorderRadiusStandard': 'Standard (12px)',
      'settingsLessonBorderRadiusRound': 'Rund (18px)',
      'settingsLessonBorderRadiusPill': 'Pill (24px)',

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
      'onboardingFeatureUpdatesTitle': 'Direkte Updates',
      'onboardingFeatureUpdatesDesc':
          'Lade passende Android-Updates direkt aus den Einstellungen.',
      'onboardingFeatureBackupTitle': 'Backup & Wiederherstellung',
      'onboardingFeatureBackupDesc':
          'Sichere deine Einstellungen und bringe sie auf ein neues Gerät.',
      'onboardingFinishSetup': 'Einrichtung abschließen',
      'onboardingUseDemoMode': 'Demo-Modus starten',
      'onboardingUseDemoModeDesc':
          'Teste Untis+ ohne Schul-Login mit realistisch gefullten Beispieldaten.',
      'tutorialTitle': 'Geführte App-Tour',
      'tutorialSkip': 'Tour überspringen',
      'tutorialDone': 'Tour beenden',
      'tutorialStepWeekTitle': 'Stundenplan',
      'tutorialStepWeekDesc':
          'Dein Schultag beginnt hier. Wechsle Wochen und öffne Stunden für alle Details.',
      'tutorialStepExamsTitle': 'Prüfungen & Aufgaben',
      'tutorialStepExamsDesc':
          'Behalte Klausuren und Aufgaben im Blick und verwalte eigene Einträge.',
      'tutorialStepInfoTitle': 'Schul-Info',
      'tutorialStepInfoDesc':
          'Mitteilungen deiner Schule landen gesammelt in diesem Bereich.',
      'tutorialStepAiTitle': 'KI-Assistent',
      'tutorialStepAiDesc':
          'Frage deinen Assistenten zu Stundenplan, Aufgaben und deinem Schulalltag.',
      'tutorialStepSettingsTitle': 'Einstellungen',
      'tutorialStepSettingsDesc':
          'Passe Design, Benachrichtigungen, Konten und Datenschutz jederzeit an.',
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
      'timetableMoreActions': 'Weitere Aktionen',
      'timetableExportImage': 'Stundenplan als Bild exportieren',
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
      'examsAdd': 'Prüfung hinzufügen',
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
      'homeworkFilterAll': 'Alle',
      'homeworkFilterOpen': 'Offen',
      'homeworkFilterDone': 'Erledigt',
      'examsUpcomingCount': '{count} anstehende Prüfung(en)',
      'examsUpcomingNext': 'Nächste: {subject} am {date}',
      'gradesTypeSingle': 'Einzelnote',
      'gradesDateLabel': 'Datum',
      'gradesCountLabel': '{count} Note(n)',
      'homeworkTitle': 'Hausaufgaben',
      'homeworkReload': 'Neu laden',
      'homeworkNone': 'Keine Hausaufgaben gefunden',
      'homeworkNoneHint': 'Du bist fertig! Genieße deine Freizeit.',
      'homeworkMarkDone': 'Als erledigt markieren',
      'homeworkMarkUndone': 'Als nicht erledigt markieren',
      'homeworkDue': 'Fällig am',
      'homeworkAddTitle': 'Hausaufgabe hinzufügen',
      'homeworkEditTitle': 'Hausaufgabe bearbeiten',
      'homeworkSubjectLabel': 'Fach *',
      'homeworkTaskLabel': 'Aufgabe / Beschreibung *',
      'homeworkDueDateLabel': 'Fällig am',
      'homeworkActionCustom': 'Manuell',
      'homeworkActionImport': 'Importieren (Scan/PDF)',
      'homeworkSave': 'Speichern',
      'homeworkDelete': 'Löschen',
      'homeworkCancel': 'Abbrechen',
      'homeworkImportTitle': 'Hausaufgaben scannen / hochladen',
      'homeworkImportSuccess': 'Hausaufgaben erfolgreich importiert!',
      'homeworkImportError': 'Fehler beim Import: ',
      'subjectOverviewTitle': 'Fächer-Übersicht',
      'addGradeForSubject': '+ Note',
      'addExamForSubject': '+ Klausur',
      'addHomeworkForSubject': '+ Hausaufgabe',
      'noGradesForSubject': 'Keine Noten für dieses Fach',
      'noExamsForSubject': 'Keine Prüfungen für dieses Fach',
      'noHomeworkForSubject': 'Keine Hausaufgaben für dieses Fach',

      'infoTitle': 'Schulinfos',
      'infoReload': 'Neu laden',
      'infoUpdated': 'Aktualisiert',
      'infoEmpty': 'Keine aktuellen Benachrichtigungen',
      'infoEmptyHint':
          'Falls deine Schule derzeit nichts veröffentlicht hat, erscheint hier keine Meldung.',
      'infoFetchError':
          'Benachrichtigungen konnten nicht geladen werden. Bitte später erneut versuchen.',
      'infoOpenLink': 'Link öffnen',
      'infoAttachments': 'Anhänge',
      'infoAttachedExtOne': 'Angehängte {ext}',
      'infoAttachedExtMany': 'Angehängte {ext}s',
      'infoAttachedFile': 'Angehängte Datei',
      'infoAttachedFiles': 'Angehängte Dateien',
      'attachmentSave': 'Anhang speichern',
      'attachmentSaved': 'Anhang gespeichert.',
      'attachmentDownloadFailed':
          'Der Anhang konnte nicht heruntergeladen werden.',
      'attachmentDemoUnavailable':
          'Im Demo-Modus sind keine echten Dateien verfügbar.',
      'infoCopyMessage': 'Nachricht kopieren',
      'infoMessageCopied': 'Nachricht in Zwischenablage kopiert.',
      'messageComposeTitle': 'Nachricht verfassen',
      'messageRecipients': 'Empfänger',
      'messageRecipientsLoading': 'Empfänger werden geladen…',
      'messageRecipientSelect': 'Lehrkraft auswählen',
      'messageRecipientsApply': 'Übernehmen',
      'messageNoRecipients': 'Keine verfügbaren Empfänger gefunden.',
      'messageRecipientsFailed': 'Empfänger konnten nicht geladen werden.',
      'messageSubject': 'Betreff',
      'messageBody': 'Nachricht',
      'messageAttach': 'Anhänge',
      'messageAttachmentLimit': 'Maximal {count} Anhänge sind erlaubt.',
      'messageAttachmentTooLarge': '{name} ist zu groß.',
      'messageDraftAutosave': 'Entwurf wird automatisch gespeichert',
      'messageDiscardDraft': 'Entwurf verwerfen',
      'messageRequiredFields': 'Empfänger, Betreff und Nachricht sind erforderlich.',
      'messageSend': 'Senden',
      'messageSending': 'Wird gesendet…',
      'messageSent': 'Nachricht gesendet.',
      'messageSendFailed': 'Die Nachricht konnte nicht gesendet werden.',
      'messageDemoUnavailable': 'Im Demo-Modus können keine echten Nachrichten gesendet werden.',
      'notificationActionCurrentLesson': 'Aktuelle Stunde: {lesson}',
      'notificationActionNextLessonLabel': 'Nächste Stunde',
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
      'aiClearHistoryTileTitle': 'Verlauf löschen',
      'aiClearHistoryTileDesc': 'Alle Chats vom Gerät entfernen',
      'aiTyping': 'KI schreibt …',
      'aiChatTitle': 'Dein KI-Chat',
      'aiChatSubtitle':
          'Stelle Fragen zu deinem Schulalltag oder chatte einfach so mit der KI.',
      'aiTryIt': 'Probiere es aus:',
      'aiSuggestions': [
        'Was hab ich morgen?',
        'Hab ich heute eine Freistunde?',
        'Wann ist morgen Schulschluss?',
        'Fällt heute etwas aus?',
      ],
      'aiChatSuggestions': [
        'Wie kann ich meine Noten verbessern?',
        'Erkläre mir die Relativitätstheorie einfach.',
        'Schreibe eine Entschuldigung für Sport.',
      ],
      'aiNoSchoolToday': 'Keine Schule heute.',
      'aiCurrentLessonSummary':
          'Aktuelle Stunde: {subject} in Raum {room} (bis {end})',
      'aiNoCurrentLesson': 'Gerade findet kein Unterricht statt.',
      'aiNoNextLessonSchool': 'Nächste Stunde: Keine (heute ist keine Schule).',
      'aiNextLessonSummary':
          'Nächste Stunde: {subject} in Raum {room} um {start}',
      'aiNoMoreLessons': 'Keine weiteren Stunden heute.',
      'aiDefaultExamType': 'Klausur',

      'settingsTitle': 'Einstellungen',
      'commonSaveChanges': 'Änderungen speichern',
      'settingsLoggedInAs': 'Angemeldet als',
      'settingsLogout': 'Abmelden',
      'settingsSectionQuick': 'Schnellzugriff',
      'settingsSectionGeneral': 'App',
      'settingsAppearance': 'Erscheinungsbild',
      'settingsAppearanceDesc': 'System (Hell/Dunkel)',
      'settingsAppearanceSurfaces': 'Oberflächen',
      'settingsAppearanceMotion': 'Animationen & Effekte',
      'settingsAppearanceTimetable': 'Stundenplanfarben',
      'settingsAppearanceApp': 'App',
      'settingsVisualTheme': 'App-Theme',
      'settingsVisualThemeDesc':
          'Ändert Farben, Formen, Schrift und Bewegung in der gesamten App.',
      'themeDefault': 'Default',
      'themeDefaultDesc': 'Der vertraute Untis+-Look',
      'themeManga': 'Manga',
      'themeMangaDesc': 'Papier, Raster und starke Ink-Konturen',
      'themeGlass': 'Glass',
      'themeGlassDesc': 'Ruhige Aurora-Glasflächen mit klaren Kontrasten',
      'themeCyber': 'Cyber',
      'themeCyberDesc': 'Präzise Technikflächen mit fokussierten Akzenten',
      'settingsHubNotifications': 'Benachrichtigungen & Widgets',
      'settingsHubDataBackup': 'Daten & Backup',
      'settingsHubDataBackupDesc': 'Alle App-Einstellungen sichern',
      'settingsHubAccount': 'Account & Demo',
      'settingsHubUpdatesAbout': 'Updates & Über',
      'settingsSupport': 'Entwicklung unterstützen',
      'settingsSupportDesc': 'Unterstütz uns auf Ko-fi',
      'settingsReportIssue': 'Problem melden oder Idee teilen',
      'settingsReportIssueDesc': 'Öffnet die Untis+ Issues auf GitHub',
      'settingsLanguage': 'Sprache',
      'settingsSectionAI': 'KI-Assistent',
      'settingsAiProvider': 'Anbieter',
      'settingsAiProviderGemini': 'Google Gemini',
      'settingsAiProviderOpenAi': 'OpenAI',
      'settingsAiProviderMistral': 'Mistral AI',
      'settingsAiProviderCustom': 'Custom Anbieter',
      'settingsAiProviderLocal': 'Lokal (On-Device)',
      'settingsAiModel': 'Modell',
      'settingsAiParametersTitle': 'Parameter',
      'settingsAiParametersDesc': 'Temperatur, Token-Limit & Top P',
      'settingsAiAdjustmentTitle': 'Anpassung',
      'settingsAiPersonaTitle': 'Persönlichkeit',
      'settingsAiPersonaHelpful': 'Hilfreicher Assistent',
      'settingsAiPersonaStrict': 'Strenger Lehrer',
      'settingsAiPersonaBuddy': 'Schul-Buddy',
      'settingsAiDataTitle': 'Daten',
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
      'settingsAiLocalModelDesc':
          'Wähle und lade ein Modell für On-Device-Inferenz herunter.',
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
      'aiVar_current_lesson': 'Informationen zur aktuellen Stunde',
      'aiVar_next_lesson': 'Informationen zur nächsten Stunde',
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
      'settingsTimetableSwitchAnimation': 'Wechselanimation',
      'settingsTimetableSwitchAnimationDesc':
          'Animation beim Wechsel zwischen Tagen und Wochen.',
      'settingsTimetableSwitchAnimationDefault': 'Standard',
      'settingsTimetableSwitchAnimationMaterial': 'Material 3 Carousel',
      'settingsTimetableSwitchAnimationDepth': 'Tiefe & Fade',
      'settingsShowCancelled': 'Ausgefallene Stunden anzeigen',
      'settingsShowCancelledDesc':
          'Ausgefallene Stunden werden im Stundenplan angezeigt',
      'settingsCancelledColor': 'Ausgefallene Farbe',
      'settingsCancelledColorDesc': 'Farbe für ausgefallene Stunden anpassen',
      'settingsLessonDesignTitle': 'Stunden- & Kartendesign',
      'settingsLessonDesignDesc':
          'Passe Stile, Blur und Details der Stundenkarten an.',
      'settingsLessonStyle': 'Karten-Stil',
      'settingsLessonStyleDesc': 'Wähle das visuelle Grunddesign der Stunden.',
      'settingsLessonStyleModern': 'Modern (Getönt)',
      'settingsLessonStyleGlass': 'Milchglas (Frosted)',
      'settingsLessonStyleGradient': 'Farbverlauf',
      'settingsLessonStyleOutline': 'Kontur / Minimal',
      'settingsLessonStyleSolid': 'Kräftig / Vollton',
      'settingsLessonBlur': 'Milchglas-Unschärfe (Blur)',
      'settingsLessonBlurDesc':
          'Hintergrund hinter den Stundenkarten weichzeichnen.',
      'settingsLessonBlurAmount': 'Weichzeichner-Stärke',
      'settingsLessonCardOpacity': 'Karten-Deckkraft',
      'settingsLessonBorderRadius': 'Eckenrundung',
      'settingsLessonAccentStyle': 'Akzentleiste',
      'settingsLessonAccentBar': 'Klassischer Balken',
      'settingsLessonAccentThin': 'Dünne Linie',
      'settingsLessonAccentDot': 'Punkt-Indikator',
      'settingsLessonAccentNone': 'Keine Leiste',
      'settingsLessonShowTeacher': 'Lehrkraft anzeigen',
      'settingsLessonShowTeacherDesc':
          'Kürzel bzw. Name der Lehrkraft auf der Karte einblenden.',
      'settingsLessonShowSubjectIcons': 'Fach-Icons anzeigen',
      'settingsLessonShowSubjectIconsDesc':
          'Zeigt passende Symbole neben den Fächern im Stundenplan.',
      'settingsLessonShowRoom': 'Raum anzeigen',
      'settingsLessonShowRoomDesc':
          'Raumnummer auf der Stundenkarte einblenden.',
      'settingsLessonCompactMode': 'Kompakte Ansicht',
      'settingsLessonCompactModeDesc':
          'Reduzierte Abstände für mehr Übersicht bei vielen Stunden.',
      'settingsLessonDimPast': 'Vergangene Stunden dimmen',
      'settingsLessonDimPastDesc':
          'Bereits vergangene Stunden am Tag dezent ausgrauen.',
      'settingsLessonCancelledPattern': 'Ausfall-Schraffur',
      'settingsLessonCancelledPatternDesc':
          'Zeigt ein diagonales Schraffurmuster bei Entfällen.',
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
      'settingsGlassEffectDesc': 'Aktiviert Blur in der Oberfläche',
      'settingsSurfaceBlur': 'Blur auf Oberflächen',
      'settingsSurfaceBlurDesc':
          'Verwischt normale Karten und Flächen. Bei aktivem Blur-Effekt werden auch Dialoge, Bottom Sheets und Overlays im Hintergrund weichgezeichnet.',
      'settingsSurfaceCorners': 'Oberflächen-Ecken',
      'settingsSurfaceCornersDesc':
          'Legt fest, wie stark normale Karten und Oberflächen abgerundet sind.',
      'settingsSurfaceCornersCurrent': 'Wie aktuell',
      'settingsSurfaceCornersSharper': 'Eckiger',
      'settingsSurfaceCornersCustom': 'Benutzerdefiniert',
      'settingsSurfaceCornerRadius': 'Eckenradius',
      'settingsGlowEffects': 'Glow-Effekte',
      'settingsGlowEffectsDesc':
          'Farbige Leuchthöfe bei Stunden, Aufgaben, Noten und Symbolen',
      'settingsPageTransition': 'Seitenübergang',
      'settingsPageTransitionDesc': 'Wähle den Stil für Seitenwechsel und optionale Main-Tab-Animationen',
      'settingsPageTransitionDefault': 'Default',
      'settingsPageTransitionBounce': 'Spring',
      'settingsPageTransitionFade': 'Soft Fade',
      'settingsPageTransitionSlide': 'Shared Axis',
      'settingsPageTransitionZoom': 'Focus Zoom',
      'settingsPageTransitionBlur': 'Focus Blur',
      'settingsPageTransitionEaseIn': 'Lift',
      'settingsPageTransitionEaseOut': 'Drift',
      'settingsPageTransitionExpo': 'Expo Rise',
      'settingsMainTabFadeUp': 'Main-Tab-Animationen',
      'settingsMainTabFadeUpDesc':
          'Animiert Main-Tab-Wechsel mit dem oben gewählten Übergang. Aus bedeutet sofortiger Wechsel ohne Animation.',
      'settingsUseMaterialYou': 'Material You',
      'settingsUseMaterialYouDesc':
          'Farben automatisch an Systemakzentfarbe anpassen',
      'settingsCustomColorSeed': 'Farbe wählen',
      'settingsIsAmoled': 'Pitch Black (AMOLED)',
      'settingsIsAmoledDesc':
          'Tiefschwarzer Hintergrund im Darkmode für OLED-Displays.',
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
      'settingsSectionCredits': 'Credits',
      'settingsCreditsDevelopers': 'Entwickler',
      'settingsCreditsDeveloper': 'Entwickler',
      'settingsCreditsFounderDeveloper': 'Gründer & Entwickler',
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
      'settingsGithubDownloading': 'Update wird heruntergeladen…',
      'settingsGithubDownloadCancel': 'Download abbrechen',
      'settingsGithubDownloadCancelled': 'Update-Download abgebrochen.',
      'settingsGithubDownloadFailed':
          'Update konnte nicht heruntergeladen werden.',
      'settingsGithubNoCompatibleAndroidApk':
          'Für die Architektur dieses Geräts ist keine Android-APK verfügbar.',
      'settingsGithubInstallPermissionRequired':
          'Erlaube Untis+ das Installieren unbekannter Apps und starte die Installation anschließend erneut.',
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
      'settingsGithubInstallerOpened': 'System-Installationsdialog geöffnet.',
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
      'changelogNoData': '# Keine Daten verfügbar',
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

      'aiNewChat': 'Neuer Chat',
      'aiParameterTemperature': 'Temperatur',
      'aiParameterMaxTokens': 'Max. Tokens',
      'aiParameterTopP': 'Top P',
      'aiOrbsCount': '{count} Orbs',
      'aiNoiseLevel': '{pct}% Rauschen',
      'aiGradientType': 'Farbverlauf',

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
      'homeworkAddDesc': 'Aufgaben und Abgaben verwalten',
      'examsAddDesc': 'Anstehende Prüfungen eintragen',
      'gradesCountPlural': 'Noten',
      'gradesWeightLabelShort': 'Gewicht',
      'gradesNone': 'Keine Noten',
      'gradesNoneHint': 'Tippe auf +, um deine erste Note einzutragen.',

      'ui_tempEditTitle': 'Stunde temporär bearbeiten',
      'ui_absence': 'Ausfall',
      'ui_reset': 'Zurücksetzen',
      'ui_cancel': 'Abbrechen',
      'ui_localSave': 'Nur lokal speichern',
      'ui_timetableImageSaved': 'Stundenplan-Bild gespeichert',
      'ui_imageExportFailed': 'Bild konnte nicht exportiert werden',
      'ui_homeworkManaged': 'Diese Hausaufgabe wird von Untis verwaltet.',
      'ui_start': 'Start',
      'ui_notifications': 'Mitteilungen',
      'ui_accountRemoveQuestion': 'Konto entfernen?',
      'ui_accountRemoveDesc':
          'Das Konto wird nur von diesem Gerät entfernt. Deine übrigen App-Einstellungen bleiben erhalten.',
      'ui_accountRemove': 'Entfernen',
      'ui_accountRemoveThis': 'Dieses Konto entfernen',
      'ui_accountSignOut': 'Von diesem Gerät abmelden',
      'ui_accounts': 'Konten',
      'ui_accountAdd': 'Konto hinzufügen',
      'ui_accountConnect': 'Weiteres WebUntis-Konto verbinden',
      'ui_alarmApply': 'Übernehmen',
      'ui_alarmOwn': 'Eigener Wecker',
      'ui_alarmTime': 'Weckzeit',
      'ui_alarmActive': 'Aktiv',
      'ui_alarmInactive': 'Deaktiviert',
      'ui_alarmDelete': 'Löschen',
      'ui_alarmSave': 'Speichern',
      'ui_alarmTitle': 'Wecker',
      'ui_alarmReady': 'Weckerbereit',
      'ui_alarmReadyYes': 'Für zuverlässige Wecker bereit',
      'ui_alarmReadyNo': 'Android-Freigaben fehlen',
      'ui_alarmReadyDescYes':
          'Exakte Alarme, Vollbild und Nicht stören sind aktiv.',
      'ui_alarmReadyDescNo': 'Öffne die fehlenden Android-Systemeinstellungen.',
      'ui_alarmExact': 'Exakte Alarme erlauben',
      'ui_alarmExactDesc':
          'Erforderlich, damit Android den Weckzeitpunkt nicht verschiebt.',
      'ui_alarmNotifications': 'Benachrichtigungen erlauben',
      'ui_alarmNotificationsDesc':
          'Erforderlich für den sichtbaren Vollbild-Wecker.',
      'ui_alarmFullscreen': 'Vollbild-Wecker erlauben',
      'ui_alarmFullscreenDesc': 'Zeigt den Wecker auf dem Sperrbildschirm.',
      'ui_alarmDnd': 'Nicht stören umgehen',
      'ui_alarmDndDesc':
          'Erlaubt aktivierten Weckern, trotz „Nicht stören“ zu klingeln.',
      'ui_alarmSmart': 'Smart-Wecker',
      'ui_alarmSchedule': 'Stundenplan-Wecker',
      'ui_alarmAt': '{label} um {time}',
      'ui_alarmScheduleDesc':
          'Weckt vor der ersten nicht ausgefallenen Stunde.',
      'ui_alarmLead': 'Vorlauf',
      'ui_alarmLeadValue': '{n} Min. vor der ersten Stunde',
      'ui_alarmLeadByStart': 'Vorlauf je Startzeit',
      'ui_alarmLeadByStartDesc': 'Eigene Vorlaufzeit oder kein Wecker für bestimmte erste Stunden.',
      'ui_alarmLeadByStartAdd': 'Startzeit hinzufügen',
      'ui_alarmLeadByStartOff': 'Kein Wecker',
      'ui_alarmLeadByStartDefault': 'Standard-Vorlauf verwenden',
      'ui_alarmUpdate': 'Kurz vor dem Wecker aktualisieren',
      'ui_alarmUpdateDesc':
          'WebUntis wird 15 Minuten vorher noch einmal geprüft.',
      'ui_alarmRing': 'Klingeln',
      'ui_alarmSnooze': 'Schlummern',
      'ui_alarmSnoozeDesc': 'Min. · nach links wischen',
      'ui_alarmSnoozeValue': '{n} Min. · nach links wischen',
      'ui_alarmSnoozeDuration': 'Schlummerdauer',
      'ui_alarmRingtone': 'Klingelton',
      'ui_alarmSystemTone': 'Android-Systemweckton',
      'ui_alarmSelectedTone': 'Ausgewählter Android-Weckton',
      'ui_alarmOwnAlarms': 'Eigene Wecker',
      'ui_alarmAdd': 'Wecker hinzufügen',
      'ui_alarmAddDesc': 'Wiederholt sich an ausgewählten Wochentagen.',
      'ui_alarmHeadsUp': 'Vor dem Wecker erinnern',
      'ui_alarmHeadsUpValue': '{n} Min. vorher',
      'ui_alarmHeadsUpDesc':
          'Der aktuelle Tag wird davor noch einmal mit WebUntis abgeglichen.',
      'ui_alarmEarlier': 'Nächsten Wecker früher klingeln lassen',
      'ui_alarmEarlierValue': '{n} Min. früher',
      'ui_alarmEarlierDesc': 'Gilt nur für den nächsten Stundenplan-Wecker.',
      'ui_alarmDateActions': 'Wecker für {date}',
      'ui_alarmDateActionsDesc': 'Diese Ausnahme gilt nur für diesen Schultag.',
      'ui_alarmDisableDate': 'Wecker an diesem Tag ausschalten',
      'ui_alarmCustomTime': 'Eigene Weckzeit',
      'ui_alarmClearDate': 'Ausnahme zurücksetzen',
      'ui_alarmDateDisabled': 'An diesem Tag ausgeschaltet',
      'ui_alarmDateCustom': 'Eigene Zeit: {time}',
      'ui_alarmDateEarlier': '{n} Min. früher',
      'ui_widgets': 'Widgets',
      'ui_widgetPreview': 'Vorschau',
      'ui_widgetPreviewTitle': 'Widgets & Vorschau',
      'ui_widgetRefresh': 'Vorschau aktualisieren',
      'ui_widgetChoose': 'Widget auswählen',
      'ui_widgetOwn': 'Eigene Widgets',
      'ui_widgetEditorOpen': 'Widget-Editor öffnen',
      'ui_widgetEditorDesc':
          'Stelle Inhalte, Reihenfolge, Farben, Transparenz und Layout frei zusammen.',
      'ui_widgetAccount': 'Konto für die Vorschau',
      'ui_widgetNoAccount': 'Kein Konto verfügbar',
      'ui_widgetAddAccountFirst': 'Füge zuerst ein WebUntis-Konto hinzu.',
      'ui_widgetHome': 'Zum Homescreen',
      'ui_widgetHomeUnavailable': 'Auf diesem Gerät nicht verfügbar',
      'ui_widgetHomeSupported':
          'Homescreen-Widgets werden auf Android und iOS unterstützt.',
      'ui_widgetHoldHome': 'Homescreen gedrückt halten',
      'ui_widgetHoldHomeDesc':
          'Tippe danach oben auf „Bearbeiten“ und auf „Widget hinzufügen“.',
      'ui_widgetSelectUntis': 'Untis+ auswählen',
      'ui_widgetSelectUntisDesc':
          'Wähle die gewünschte Variante und Größe aus.',
      'ui_widgetSetAccount': 'Konto festlegen',
      'ui_widgetSetAccountDesc':
          'Halte das Widget gedrückt und wähle „Widget bearbeiten“.',
      'ui_widgetAdd': 'Widget hinzufügen',
      'ui_widgetPickerOpening': 'Widget-Picker wird geöffnet …',
      'ui_widgetPickerSent': 'Widget-Anfrage wurde an den Homescreen gesendet.',
      'ui_widgetPickerHint': 'Öffne den Widget-Picker über deinen Homescreen.',
      'ui_widgetPickerFailed':
          'Das Widget konnte nicht hinzugefügt werden. Öffne den Widget-Picker über den Homescreen.',
      'ui_widgetSyncedPreview':
          'Die Vorschau verwendet die zuletzt für dieses Konto synchronisierten Widget-Daten.',
      'ui_widgetOpenTimetable':
          'Öffne einmal den Stundenplan, damit echte Widget-Daten synchronisiert werden.',
      'ui_editor': 'Widget-Editor',
      'ui_editorYourWidgets': 'Deine Widgets',
      'ui_editorNew': 'Neu',
      'ui_editorDuplicate': 'Duplizieren',
      'ui_editorContentLayout': 'Inhalt und Layout',
      'ui_editorName': 'Name',
      'ui_editorCompact': 'Kompakt',
      'ui_editorStacked': 'Gestapelt',
      'ui_editorTimeline': 'Zeitachse',
      'ui_editorDesign': 'Design',
      'ui_editorBackground': 'Hintergrund',
      'ui_editorAccent': 'Akzent',
      'ui_editorText': 'Text',
      'ui_editorShowIcons': 'Icons anzeigen',
      'ui_editorApplyColor': 'Farbe übernehmen',
      'ui_editorTransparency': 'Transparenz',
      'ui_editorRounding': 'Rundung',
      'ui_editorFontSize': 'Schriftgröße',
      'ui_colorRed': 'Rot',
      'ui_colorGreen': 'Grün',
      'ui_colorBlue': 'Blau',
      'ui_blockCurrent': 'Aktuelle Stunde',
      'ui_blockNext': 'Nächste Stunde',
      'ui_blockSchedule': 'Tagesplan',
      'ui_blockHomework': 'Aufgaben',
      'ui_blockExams': 'Prüfungen',
      'ui_blockNotices': 'Mitteilungen',
      'ui_blockAccount': 'Konto',
      'ui_blockStatus': 'Status',
      'ui_previewCurrent': 'Jetzt: Mathematik',
      'ui_previewNext': 'Danach: Englisch · Raum 204',
      'ui_previewSchedule': '08:00 Mathe\n09:45 Englisch\n11:30 Biologie',
      'ui_previewHomework': '2 offene Aufgaben',
      'ui_previewExams': 'Nächste Prüfung: Freitag',
      'ui_previewNotices': 'Neue Mitteilungen',
      'ui_previewStatus': 'Aktualisiert um 12:30',
      'ui_appearanceAppIcon': 'App-Symbol',
      'ui_notificationsWidgets': 'Widgets & Vorschau',
      'ui_notificationsWidgetsDesc': 'Varianten, Vorschau und Kontozuordnung.',
      'ui_notificationsAlarms': 'Wecker & Smart-Wecker',
      'ui_tempEditDesc':
          'Diese Änderung wird nicht an Untis übertragen und beim nächsten Laden verworfen.',
      'ui_subject': 'Fach',
      'ui_teacher': 'Lehrkraft',
      'ui_room': 'Raum',
      'ui_saveTimetableImage': 'Stundenplan-Bild speichern',
      'ui_widgetAndroidDialogDesc':
          'Das ausgewählte Konto wird im Android-Dialog vorausgewählt. Dort kannst du es vor dem Hinzufügen noch ändern.',
      'ui_widgetCurrent': 'Jetzt',
      'ui_widgetCurrentDesc':
          'Aktuelle Stunde, nächste Stunde und verbleibende Zeit',
      'ui_widgetSchedule': 'Tagesplan',
      'ui_widgetScheduleDesc':
          'Die nächsten Einträge deines heutigen Stundenplans',
      'ui_widgetHomework': 'Aufgaben',
      'ui_widgetHomeworkDesc':
          'Eine kompakte Übersicht deiner offenen Aufgaben',
      'ui_widgetNotices': 'Mitteilungen',
      'ui_widgetNoticesDesc': 'Die neuesten Mitteilungen auf deinem Homescreen',
      'ui_widgetSmallMedium': 'Klein oder mittel',
      'ui_widgetMediumLarge': 'Mittel oder groß',
      'ui_widgetToday': 'HEUTE',
      'ui_widgetNoScheduleData': 'Noch keine Tagesdaten',
      'ui_widgetNoOpenHomework': 'Keine offenen Aufgaben synchronisiert',
      'ui_widgetNoNotices': 'Keine Mitteilungen synchronisiert',
      'ui_widgetNoCurrentLesson': 'Keine aktuelle Stunde',
      'ui_widgetNotSynced': 'Noch nicht synchronisiert',
      'ui_widgetLoading': 'LÄDT',
      'ui_widgetCurrentStatus': 'AKTUELL',
      'ui_widgetPreviewStatus': 'VORSCHAU',
      'ui_widgetTimetableDetail': 'Stundenplan öffnen, um Daten zu laden',
      'ui_alarmMinutesSuffix': ' Min.',
      'ui_editorDefaultName': 'Mein Widget',
      'ui_editorNewWidget': 'Neues Widget',
      'ui_editorCopySuffix': 'Kopie',
      'ui_widgetMinutesRemaining': '{n} Min. verbleibend',
      'ui_widgetNoUpcomingExams': 'Keine anstehenden Prüfungen',
      'ui_widgetExam': 'Prüfung',
      'ui_widgetLesson': 'Unterricht',
      'ui_widgetHomeworkItem': 'Aufgabe',
      'ui_widgetNext': 'Als Nächstes: {title}',
      'ui_widgetNoLessonsToday': 'Heute keine Stunden',
      'ui_widgetOpenNotifications': 'Neue Mitteilungen in Untis+ öffnen',
      'ui_notificationsNone': 'Keine neuen Mitteilungen',
      'ui_appearanceIconChoose': 'Symbol für den Startbildschirm auswählen',
      'ui_appearanceIconAndroidOnly': 'Derzeit auf Android verfügbar',
      'ui_nativeAlarmReminderChannel': 'Untis+ Wecker-Erinnerungen',
      'ui_nativeAlarmReminderChannelDesc': 'Hinweise vor einem Untis+ Wecker',
      'ui_nativeAlarmChannel': 'Untis+ Wecker',
      'ui_nativeAlarmChannelDesc': 'Klingelnde Untis+ Wecker',
      'ui_nativeAlarmRefreshChannel': 'Untis+ Wecker-Aktualisierung',
      'ui_nativeAlarmReminderTitle': 'Wecker in {minutes} Minuten',
      'ui_nativeAlarmDisableToday': 'Für diesen Tag ausschalten',
      'ui_nativeAlarmTitle': 'Wecker',
      'ui_nativeAlarmSwipeHint': 'Nach links schlummern, nach rechts ausschalten',
      'ui_nativeAlarmSnooze': 'Schlummern · {minutes} Min.',
      'ui_nativeAlarmDismiss': 'Ausschalten',
      'ui_nativeAlarmRefreshing': 'Wecker wird aktualisiert',
      'ui_nativeAlarmStatusActive': 'Wecker aktiv',
      'ui_nativeAlarmStatusSnoozing': 'Schlummert',
      'ui_nativeAlarmTimeAccessibility': 'Weckzeit {time}',
      'ui_nativeWidgetSetupTitle': 'Widget einrichten',
      'ui_nativeWidgetSetupAccount': 'Konto für dieses Widget',
      'ui_nativeWidgetSetupProfile': 'Widget-Profil',
      'ui_nativeWidgetSetupProfileHint': 'Profil aus dem Widget-Editor',
      'ui_nativeWidgetSetupNoProfile': 'Erstelle zuerst ein Profil im Untis+-Widget-Editor.',
      'ui_nativeWidgetSetupNoAccount': 'Öffne Untis+ und füge zuerst ein Konto hinzu.',
      'ui_nativeWidgetRefreshing': 'Wird aktualisiert …',
      'ui_refreshing': 'Wird aktualisiert',
      'ui_copyMessage': 'Nachricht kopieren',
      'ui_aiAttachmentTooLarge': 'Anhänge dürfen höchstens 8 MB groß sein.',
      'ui_aiAttachFile': 'Datei anhängen',
      'ui_aiAttachmentText': '\\n\\nDatei {name}:\\n{excerpt}',
      'ui_aiAttachmentUnsupported': 'Anhang {name} ({mimeType}) kann von diesem Anbieter nicht gelesen werden.',
      'ui_aiFileKindPdf': ' oder PDF',
      'ui_aiHomeworkVisionPrompt': 'Du bist ein Assistent, der Hausaufgaben von Tafeln, Arbeitsblättern oder Notizen erfasst.\\nExtrahiere alle Aufgaben aus dem angehängten Bild{fileKind}.\\nAntworte AUSSCHLIESSLICH im folgenden JSON-Array-Format (kein Markdown-Block, nur reines JSON):\\n[\\n  {\\n    "subject": "Mathe",\\n    "text": "Seite 42 Nr. 1–5",\\n    "dueDate": "20260905"\\n  }\\n]\\nWICHTIG: Das Datum MUSS als String im Format YYYYMMDD ausgegeben werden. Fehlt Jahr oder Datum, leite es ab. Wenn die Datei keine Hausaufgaben enthält, gib ein leeres Array [] zurück.',
      'ui_aiExamVisionPrompt': 'Du bist ein Assistent, der Klausurpläne von Schulen strukturiert erfasst.\\nExtrahiere alle relevanten Klausuren und Prüfungen aus dem angehängten Bild{fileKind}.\\nAntworte AUSSCHLIESSLICH im folgenden JSON-Array-Format (kein Markdown-Block, nur reines JSON, keine Grußformeln):\\n[\\n  {\\n    "subject": "Mathe",\\n    "examType": "Klausur",\\n    "date": "20240325",\\n    "description": "Ergänzende Infos oder leere Zeichenkette"\\n  }\\n]\\nWICHTIG: Das Datum MUSS als String im Format YYYYMMDD ausgegeben werden. Fehlt das Jahr, leite es aus dem aktuellen Jahr ({year}) ab. Wenn die Datei keine Klausuren enthält, gib ein leeres Array [] zurück.',
      'ui_aiExamJsonSystemPrompt': 'Extrahiere strukturierte Prüfungsdaten und antworte nur mit JSON.',
      'ui_aiExamImageSystemPrompt': 'Extrahiere strukturierte Prüfungsdaten aus dem Bild. Antworte ausschließlich als JSON-Array.',
      'ui_aiResponseFormat': 'ANTWORTFORMAT:\\n- Antworte kurz und visuell.\\n- Nutze bevorzugt ein JSON-Objekt mit den Feldern headline, summary, tags, metrics und lessons.\\n- metrics ist eine Liste von Objekten mit label und value.\\n- lessons ist eine Liste von Objekten mit subject, subjectShort, room, teacher, time und status.\\n- Vermeide lange Fließtexte.\\n- WICHTIG: Gib NUR Felder an, die für die Frage relevant sind. Wenn die Frage nach keiner Metrik oder keinen Stunden verlangt, lasse metrics bzw. lessons weg oder gib leere Arrays zurück.',
      'ui_bgUpdateTitle': 'Untis+-Update verfügbar',
      'ui_bgUpdateBody': 'Version {version} ist in den GitHub Releases verfügbar.',
      'ui_bgDailyBriefingTitle': 'Dein Schultag auf einen Blick',
      'ui_bgDailyBriefingBody': '{start}–{end}, {lessons} Stunden, {breaks} Pausen',
      'ui_bgDailyBriefingExpanded': 'Start: {start}\\nEnde: {end}\\nStunden: {lessons}\\nPausen: {breaks}\\nNächste Stunde: {next}',
      'ui_bgChangesTitle': 'Stundenplan aktualisiert',
      'ui_bgChangesBody': 'Es gibt neue Änderungen heute. Tippe, um den Stundenplan zu öffnen.',
      'ui_bgCurrentLesson': 'Aktuelle Stunde',
      'ui_bgNextLesson': 'Nächste Stunde',
      'ui_bgNoClasses': 'Kein Unterricht mehr',
      'ui_bgLessonStarts': 'Start um {time}',
      'ui_bgUntil': 'Bis {time} Uhr',
      'ui_bgThen': 'Danach: {lesson}',
      'ui_bgFinished': 'Schluss',
      'ui_bgFreePeriod': 'Frei',
      'ui_bgFallbackLesson': 'Stunde {start}–{end}',
      'ui_bgDemoLesson': 'Demo-Stunde {code}',
      'ui_bgChangesCancelled': '{count} Ausfälle',
      'ui_bgChangesRoom': '{count} Raumänderungen',
      'ui_bgChangesSubstitution': '{count} Vertretungen',
      'ui_bgChangesOther': '{count} Änderungen',
      'ui_widgetSystemColors': 'Material You',
      'ui_widgetCustomColors': 'Eigene Farben',
      'ui_aiActionCreateHomework': 'Hausaufgabe erstellen: {subject} · {text}',
      'ui_aiActionUpdateHomework': 'Hausaufgabe bearbeiten: {subject} · {text}',
      'ui_aiActionDeleteHomework': 'Hausaufgabe löschen: {id}',
      'ui_aiActionCompleteHomework': 'Hausaufgabe erledigt markieren: {id}',
      'ui_aiActionCreateExam': 'Prüfung erstellen: {subject} · {text}',
      'ui_aiActionUpdateExam': 'Prüfung bearbeiten: {subject} · {text}',
      'ui_aiActionDeleteExam': 'Prüfung löschen: {id}',
      'ui_aiActionCreateGrade': 'Note erstellen: {subject} · {value}',
      'ui_aiActionUpdateGrade': 'Note bearbeiten: {subject} · {value}',
      'ui_aiActionDeleteGrade': 'Note löschen: {id}',
      'ui_aiActionUnknown': 'Unbekannte Aktion',
      'ui_aiParametersTitle': 'KI-Parameter',
      'ui_aiPersonaStrict': 'Antworte wie ein strenger, aber gerechter Lehrer. Achte auf Disziplin und Ordnung.',
      'ui_aiPersonaBuddy': 'Antworte wie ein cooler Schulkamerad. Nutze Jugendsprache und sei sehr locker.',
      'ui_aiPersonaHelpful': 'Antworte freundlich, professionell und hilfreich.',
      'ui_aiAssistantIntro': 'Du bist ein hilfreicher Assistent für die Stundenplan-App „Untis+“.',
      'ui_aiAssistantRules': 'Antworte natürlich und freundlich im Chat. Du hast Zugriff auf den Stundenplan und die Prüfungen des Nutzers oben. Verwende Markdown für eine gute Formatierung. Antworte in natürlicher Sprache, niemals als JSON, außer du wirst ausdrücklich darum gebeten. Halte Antworten kurz und präzise und beginne nicht mit einer Selbstvorstellung. Bei einer gewünschten lokalen Änderung schreibe nach deiner normalen Antwort einen separaten Block im exakten Format ```untis-action {"kind":"create_homework|update_homework|delete_homework|complete_homework|create_exam|update_exam|delete_exam|create_grade|update_grade|delete_grade","id":"optional id","subject":"subject","text":"text","dueDate":"YYYYMMDD","value":"optional grade","weight":"optional weight","type":"optional type"} ```. Schlage nur sichere, konkrete Änderungen vor; sie werden erst nach ausdrücklicher Bestätigung ausgeführt. Behaupte niemals, eine Änderung sei erfolgt, wenn du keinen solchen Block vorschlägst oder der Nutzer ihn nicht bestätigt hat.',
      'ui_aiDayDataUnavailable': '{date}: Stundenplandaten für diesen Tag sind noch nicht geladen.',
      'ui_aiWeekDataUnavailable': 'Für {date} ist die passende Stundenplanwoche noch nicht geladen. Ich rate hier nicht.',
      'ui_aiNoScheduledLessons': 'Für {date} ist keine nicht abgesagte Stunde eingetragen.',
      'ui_aiScheduleReply': 'Ja. Du hast am {date}: {lessons}.',
      'ui_aiApplyChangesTitle': 'Änderungen bestätigen',
      'ui_aiApplyChangesDesc': 'Der Assistent hat folgende lokale Änderungen vorgeschlagen:',
      'ui_aiChangesApplied': 'Änderungen übernommen.',
      'ui_apply': 'Übernehmen',
      'ui_aiParametersDesc': 'Feineinstellung für die Antworten des Modells.',
      'ui_aiTemperatureDesc':
          'Höhere Werte machen Antworten kreativer, niedrigere präziser.',
      'ui_aiTokenDesc': 'Maximale Länge einer einzelnen Antwort.',
      'ui_aiTopPDesc': 'Kern-Sampling zur Begrenzung der Wortauswahl.',
      'ui_notificationsDenied':
          'Benachrichtigungen sind in den Systemeinstellungen nicht erlaubt.',
      'ui_notificationsAlarmsDesc':
          'Exakte Android-Wecker, die sich an Ausfälle anpassen.',
      'ui_editorAddWidget': 'Dieses Widget hinzufügen',
      'ui_editorIosHint':
          'Füge Untis+ über den iOS-Widget-Picker hinzu und wähle anschließend dieses Profil in „Widget bearbeiten“.',
    },

    // ── ENGLISH ───────────────────────────────────────────────────────────────
    'en': {
      'navWeek': 'Week',
      'navHomework': 'Homework',
      'navExams': 'Exams',
      'navInfo': 'Info',
      'navMenu': 'Menu',
      'navAi': 'AI',
      'timetableOfflineCache': 'Offline cache active',
      'timetableNotSignedIn': 'Not signed in',
      'timetableHttpError': 'HTTP {status}: The timetable could not be loaded.',
      'timetableUnknownApiError': 'Unknown WebUntis error',
      'timetableLoadError':
          'The timetable could not be loaded. Check your connection and try again.',

      'aiClearHistoryTitle': 'Clear history?',
      'aiClearHistoryDesc': 'All previous chats will be permanently deleted.',
      'aiClearHistorySuccess': 'Chat history cleared.',
      'aiLocalModelDescSmall': 'Small, fast, ideal for mobile devices',
      'aiLocalModelDescBalanced': 'Balanced, good quality',
      'aiLocalModelDescMultilingual': 'Strong for multilingual use',
      'aiLocalModelDescHighQuality': 'Higher quality, more memory',
      'aiLocalModelDescStrong': 'Very strong but larger',

      'notificationActionNextLesson': 'Next lesson',
      'notificationActionFreeRooms': 'Free rooms',
      'notificationActionOpenDay': 'Open day',
      'notificationChannelCurrentLessonName': 'Current lesson / Break',
      'notificationChannelCurrentLessonDesc':
          'Ongoing status of the current lesson.',
      'notificationChannelDailyBriefingName': 'Daily briefing',
      'notificationChannelDailyBriefingDesc':
          'Morning overview of your school day.',
      'notificationChannelImportantChangesName': 'Timetable changes',
      'notificationChannelImportantChangesDesc':
          'Notifies about cancellations and room changes.',
      'notificationChannelUpdatesName': 'App updates',
      'notificationChannelUpdatesDesc': 'Notifications about app improvements.',

      'settingsLessonBorderRadiusCompact': 'Compact (6px)',
      'settingsLessonBorderRadiusStandard': 'Standard (12px)',
      'settingsLessonBorderRadiusRound': 'Round (18px)',
      'settingsLessonBorderRadiusPill': 'Pill (24px)',

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
      'onboardingFeatureUpdatesTitle': 'Direct updates',
      'onboardingFeatureUpdatesDesc':
          'Download the right Android update directly from Settings.',
      'onboardingFeatureBackupTitle': 'Backup & restore',
      'onboardingFeatureBackupDesc':
          'Keep your settings safe and move them to a new device.',
      'onboardingFinishSetup': 'Finish Setup',
      'onboardingUseDemoMode': 'Start demo mode',
      'onboardingUseDemoModeDesc':
          'Try Untis+ without school login using realistic sample data.',
      'tutorialTitle': 'Guided app tour',
      'tutorialSkip': 'Skip tour',
      'tutorialDone': 'Finish tour',
      'tutorialStepWeekTitle': 'Timetable',
      'tutorialStepWeekDesc':
          'Your school day starts here. Switch weeks and open lessons for every detail.',
      'tutorialStepExamsTitle': 'Exams & tasks',
      'tutorialStepExamsDesc':
          'Keep exams and tasks in view and manage your own entries.',
      'tutorialStepInfoTitle': 'School info',
      'tutorialStepInfoDesc':
          'Announcements from your school are collected in this area.',
      'tutorialStepAiTitle': 'AI assistant',
      'tutorialStepAiDesc':
          'Ask your assistant about your timetable, tasks and school day.',
      'tutorialStepSettingsTitle': 'Settings',
      'tutorialStepSettingsDesc':
          'Adjust design, notifications, accounts and privacy whenever you like.',
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
      'timetableMoreActions': 'More actions',
      'timetableExportImage': 'Export timetable as image',
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
      'examsAdd': 'Add exam',
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
      'homeworkFilterAll': 'All',
      'homeworkFilterOpen': 'Open',
      'homeworkFilterDone': 'Done',
      'examsUpcomingCount': '{count} upcoming exam(s)',
      'examsUpcomingNext': 'Next: {subject} ({date})',
      'gradesTypeSingle': 'Single grade',
      'gradesDateLabel': 'Date',
      'gradesCountLabel': '{count} grade(s)',

      'homeworkTitle': 'Homework',
      'homeworkReload': 'Reload',
      'homeworkNone': 'No homework found',
      'homeworkNoneHint': "You're all done! Enjoy your free time.",
      'homeworkMarkDone': 'Mark as done',
      'homeworkMarkUndone': 'Mark as undone',
      'homeworkDue': 'Due on',
      'homeworkAddTitle': 'Add Homework',
      'homeworkEditTitle': 'Edit Homework',
      'homeworkSubjectLabel': 'Subject *',
      'homeworkTaskLabel': 'Task / Description *',
      'homeworkDueDateLabel': 'Due date',
      'homeworkActionCustom': 'Manual',
      'homeworkActionImport': 'Import (Scan/PDF)',
      'homeworkSave': 'Save',
      'homeworkDelete': 'Delete',
      'homeworkCancel': 'Cancel',
      'homeworkImportTitle': 'Scan / Upload Homework',
      'homeworkImportSuccess': 'Homework successfully imported!',
      'homeworkImportError': 'Import error: ',
      'subjectOverviewTitle': 'Subject Overview',
      'addGradeForSubject': '+ Grade',
      'addExamForSubject': '+ Exam',
      'addHomeworkForSubject': '+ Homework',
      'noGradesForSubject': 'No grades for this subject',
      'noExamsForSubject': 'No exams for this subject',
      'noHomeworkForSubject': 'No homework for this subject',

      'infoTitle': 'School Info',
      'infoReload': 'Reload',
      'infoUpdated': 'Updated',
      'infoEmpty': 'No current notifications',
      'infoEmptyHint':
          'If your school has not published anything at the moment, nothing is shown here.',
      'infoFetchError': 'Could not load notifications. Please try again later.',
      'infoOpenLink': 'Open link',
      'infoAttachments': 'Attachments',
      'infoAttachedExtOne': 'Attached {ext}',
      'infoAttachedExtMany': 'Attached {ext}s',
      'infoAttachedFile': 'Attached File',
      'infoAttachedFiles': 'Attached Files',
      'attachmentSave': 'Save attachment',
      'attachmentSaved': 'Attachment saved.',
      'attachmentDownloadFailed': 'The attachment could not be downloaded.',
      'attachmentDemoUnavailable': 'Real files are not available in demo mode.',
      'infoCopyMessage': 'Copy message',
      'infoMessageCopied': 'Message copied to clipboard.',
      'messageComposeTitle': 'Compose message',
      'messageRecipients': 'Recipients',
      'messageRecipientsLoading': 'Loading recipients…',
      'messageRecipientSelect': 'Choose a teacher',
      'messageRecipientsApply': 'Apply',
      'messageNoRecipients': 'No available recipients found.',
      'messageRecipientsFailed': 'Recipients could not be loaded.',
      'messageSubject': 'Subject',
      'messageBody': 'Message',
      'messageAttach': 'Attachments',
      'messageAttachmentLimit': 'A maximum of {count} attachments is allowed.',
      'messageAttachmentTooLarge': '{name} is too large.',
      'messageDraftAutosave': 'Draft saves automatically',
      'messageDiscardDraft': 'Discard draft',
      'messageRequiredFields': 'Recipient, subject and message are required.',
      'messageSend': 'Send',
      'messageSending': 'Sending…',
      'messageSent': 'Message sent.',
      'messageSendFailed': 'The message could not be sent.',
      'messageDemoUnavailable': 'Real messages cannot be sent in demo mode.',
      'notificationActionCurrentLesson': 'Current lesson: {lesson}',
      'notificationActionNextLessonLabel': 'Next lesson',
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
      'aiClearHistoryTileTitle': 'Clear history',
      'aiClearHistoryTileDesc': 'Remove all chats from device',
      'aiTyping': 'AI is typing …',
      'aiChatTitle': 'Your AI chat',
      'aiChatSubtitle':
          'Ask questions about school or simply chat with the AI.',
      'aiTryIt': 'Try it:',
      'aiSuggestions': [
        "What do I have tomorrow?",
        "Do I have a free period today?",
        "When does school end tomorrow?",
        "Is anything cancelled today?",
      ],
      'aiChatSuggestions': [
        'How can I improve my grades?',
        'Explain relativity to me in simple terms.',
        'Write an excuse note for PE.',
      ],
      'aiNoSchoolToday': 'No school today.',
      'aiCurrentLessonSummary':
          'Current lesson: {subject} in room {room} (until {end})',
      'aiNoCurrentLesson': 'There is no lesson right now.',
      'aiNoNextLessonSchool': 'Next lesson: None (there is no school today).',
      'aiNextLessonSummary': 'Next lesson: {subject} in room {room} at {start}',
      'aiNoMoreLessons': 'No more lessons today.',
      'aiDefaultExamType': 'Exam',

      'settingsTitle': 'Settings',
      'commonSaveChanges': 'Save changes',
      'settingsLoggedInAs': 'Logged in as',
      'settingsLogout': 'Sign out',
      'settingsSectionQuick': 'Quick Controls',
      'settingsSectionGeneral': 'App',
      'settingsAppearance': 'Appearance',
      'settingsAppearanceDesc': 'System (Light/Dark)',
      'settingsAppearanceSurfaces': 'Surfaces',
      'settingsAppearanceMotion': 'Motion & effects',
      'settingsAppearanceTimetable': 'Timetable colors',
      'settingsAppearanceApp': 'App',
      'settingsVisualTheme': 'App theme',
      'settingsVisualThemeDesc':
          'Changes colors, shapes, type and motion throughout the app.',
      'themeDefault': 'Default',
      'themeDefaultDesc': 'The familiar Untis+ look',
      'themeManga': 'Manga',
      'themeMangaDesc': 'Paper, halftone and bold ink outlines',
      'themeGlass': 'Glass',
      'themeGlassDesc': 'Calm aurora glass with clear contrast',
      'themeCyber': 'Cyber',
      'themeCyberDesc': 'Precise technical surfaces with focused accents',
      'settingsLanguage': 'Language',
      'settingsSectionAI': 'AI Assistant',
      'settingsAiProvider': 'Provider',
      'settingsAiProviderGemini': 'Google Gemini',
      'settingsAiProviderOpenAi': 'OpenAI',
      'settingsAiProviderMistral': 'Mistral AI',
      'settingsAiProviderCustom': 'Custom Provider',
      'settingsAiProviderLocal': 'Local (On-Device)',
      'settingsAiModel': 'Model',
      'settingsAiParametersTitle': 'Parameters',
      'settingsAiParametersDesc': 'Temperature, Token Limit & Top P',
      'settingsAiAdjustmentTitle': 'Adjustment',
      'settingsAiPersonaTitle': 'Persona',
      'settingsAiPersonaHelpful': 'Helpful Assistant',
      'settingsAiPersonaStrict': 'Strict Teacher',
      'settingsAiPersonaBuddy': 'School Buddy',
      'settingsAiDataTitle': 'Data',
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
      'settingsAiLocalModelDesc':
          'Select and download a model for on-device inference.',
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
      'aiVar_current_lesson': 'Information about the current lesson',
      'aiVar_next_lesson': 'Information about the next lesson',
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
      'settingsTimetableSwitchAnimation': 'Switch animation',
      'settingsTimetableSwitchAnimationDesc':
          'Animation used when moving between timetable days and weeks.',
      'settingsTimetableSwitchAnimationDefault': 'Default',
      'settingsTimetableSwitchAnimationMaterial': 'Material 3 Carousel',
      'settingsTimetableSwitchAnimationDepth': 'Depth & Fade',
      'settingsShowCancelled': 'Show cancelled lessons',
      'settingsShowCancelledDesc':
          'Cancelled lessons are shown in the timetable',
      'settingsCancelledColor': 'Cancelled color',
      'settingsCancelledColorDesc': 'Customize the color for cancelled lessons',
      'settingsLessonDesignTitle': 'Lesson & Card Design',
      'settingsLessonDesignDesc':
          'Customize card styles, blur, and layout details.',
      'settingsLessonStyle': 'Card Style',
      'settingsLessonStyleDesc':
          'Choose the visual aesthetic for timetable lessons.',
      'settingsLessonStyleModern': 'Modern (Tinted)',
      'settingsLessonStyleGlass': 'Frosted Glass',
      'settingsLessonStyleGradient': 'Gradient',
      'settingsLessonStyleOutline': 'Outline / Minimal',
      'settingsLessonStyleSolid': 'Solid Fill',
      'settingsLessonBlur': 'Frosted Glass Blur',
      'settingsLessonBlurDesc':
          'Blur the wallpaper background behind lesson cards.',
      'settingsLessonBlurAmount': 'Blur Strength',
      'settingsLessonCardOpacity': 'Card Opacity',
      'settingsLessonBorderRadius': 'Corner Radius',
      'settingsLessonAccentStyle': 'Accent Indicator',
      'settingsLessonAccentBar': 'Classic Bar',
      'settingsLessonAccentThin': 'Thin Line',
      'settingsLessonAccentDot': 'Dot Badge',
      'settingsLessonAccentNone': 'None',
      'settingsLessonShowTeacher': 'Show Teacher',
      'settingsLessonShowTeacherDesc':
          'Display teacher name or initials on the card.',
      'settingsLessonShowSubjectIcons': 'Show subject icons',
      'settingsLessonShowSubjectIconsDesc':
          'Show matching icons next to subjects in the timetable.',
      'settingsLessonShowRoom': 'Show Room',
      'settingsLessonShowRoomDesc': 'Display room number on the card.',
      'settingsLessonCompactMode': 'Compact View',
      'settingsLessonCompactModeDesc':
          'Tighter padding and fonts for dense timetables.',
      'settingsLessonDimPast': 'Dim Past Lessons',
      'settingsLessonDimPastDesc':
          'Grayscale and dim completed lessons during the day.',
      'settingsLessonCancelledPattern': 'Cancellation Stripes',
      'settingsLessonCancelledPatternDesc':
          'Show a diagonal stripe pattern on cancelled lessons.',
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
      'settingsGlassEffectDesc': 'Enables blur effects across the interface',
      'settingsSurfaceBlur': 'Surface blur',
      'settingsSurfaceBlurDesc':
          'Blurs regular cards and surfaces. When Blur Effect is active, dialog, bottom-sheet, and tutorial backgrounds are blurred too.',
      'settingsSurfaceCorners': 'Surface corners',
      'settingsSurfaceCornersDesc':
          'Controls how rounded regular cards and surfaces are.',
      'settingsSurfaceCornersCurrent': 'Current',
      'settingsSurfaceCornersSharper': 'Sharper',
      'settingsSurfaceCornersCustom': 'Custom',
      'settingsSurfaceCornerRadius': 'Corner radius',
      'settingsGlowEffects': 'Glow effects',
      'settingsGlowEffectsDesc':
          'Colored halos around lessons, tasks, grades, and icons',
      'settingsPageTransition': 'Page Transition',
      'settingsPageTransitionDesc':
          'Choose the style for page navigation and optional main-tab animations',
      'settingsUseMaterialYou': 'Material You',
      'settingsUseMaterialYouDesc':
          'Automatically adapt to your system accent color',
      'settingsCustomColorSeed': 'Custom color',
      'settingsIsAmoled': 'Pitch Black (AMOLED)',
      'settingsIsAmoledDesc':
          'Deep black background in dark mode for OLED displays.',
      'settingsPageTransitionDefault': 'Default',
      'settingsPageTransitionBounce': 'Spring',
      'settingsPageTransitionFade': 'Soft Fade',
      'settingsPageTransitionSlide': 'Shared Axis',
      'settingsPageTransitionZoom': 'Focus Zoom',
      'settingsPageTransitionBlur': 'Focus Blur',
      'settingsPageTransitionEaseIn': 'Lift',
      'settingsPageTransitionEaseOut': 'Drift',
      'settingsPageTransitionExpo': 'Expo Rise',
      'settingsMainTabFadeUp': 'Main-tab animations',
      'settingsMainTabFadeUpDesc':
          'Animates main-tab changes with the transition selected above. Off switches tabs instantly.',
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
      'settingsSectionCredits': 'Credits',
      'settingsCreditsDevelopers': 'Developers',
      'settingsCreditsDeveloper': 'Developer',
      'settingsCreditsFounderDeveloper': 'Founder & Developer',
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
      'settingsGithubDownloading': 'Downloading update…',
      'settingsGithubDownloadCancel': 'Cancel download',
      'settingsGithubDownloadCancelled': 'Update download cancelled.',
      'settingsGithubDownloadFailed': 'Could not download the update.',
      'settingsGithubNoCompatibleAndroidApk':
          'No Android APK is available for this device architecture.',
      'settingsGithubInstallPermissionRequired':
          'Allow Untis+ to install unknown apps, then start the installation again.',
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
      'settingsGithubInstallerOpened': 'System installation prompt opened.',
      'settingsGithubOpenReleasePage': 'Open GitHub release page',
      'settingsHubNotifications': 'Notifications & Widgets',
      'settingsHubDataBackup': 'Data & Backup',
      'settingsHubDataBackupDesc': 'Back up all app settings',
      'settingsHubAccount': 'Account & Demo',
      'settingsHubUpdatesAbout': 'Updates & About',
      'settingsSupport': 'Support Development',
      'settingsSupportDesc': 'Support us on Ko-fi',
      'settingsReportIssue': 'Report a problem or share an idea',
      'settingsReportIssueDesc': 'Open the Untis+ issue tracker on GitHub',
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
      'changelogNoData': '# No data available',
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
      'homeworkAddDesc': 'Manage tasks and deadlines',
      'examsAddDesc': 'Schedule upcoming exams',
      'gradesCountPlural': 'Grades',
      'gradesWeightLabelShort': 'Weight',
      'gradesNone': 'No grades',
      'gradesNoneHint': 'Tap + to add your first grade.',

      'ui_tempEditTitle': 'Temporarily edit lesson',
      'ui_absence': 'Cancelled',
      'ui_reset': 'Reset',
      'ui_cancel': 'Cancel',
      'ui_localSave': 'Save locally only',
      'ui_timetableImageSaved': 'Timetable image saved',
      'ui_imageExportFailed': 'Could not export image',
      'ui_homeworkManaged': 'This homework is managed by Untis.',
      'ui_start': 'Start',
      'ui_notifications': 'Notifications',
      'ui_accountRemoveQuestion': 'Remove account?',
      'ui_accountRemoveDesc':
          'The account is removed only from this device. Your other app settings remain unchanged.',
      'ui_accountRemove': 'Remove',
      'ui_accountRemoveThis': 'Remove this account',
      'ui_accountSignOut': 'Sign out on this device',
      'ui_accounts': 'Accounts',
      'ui_accountAdd': 'Add account',
      'ui_accountConnect': 'Connect another WebUntis account',
      'ui_alarmApply': 'Apply',
      'ui_alarmOwn': 'Custom alarm',
      'ui_alarmTime': 'Alarm time',
      'ui_alarmActive': 'Active',
      'ui_alarmInactive': 'Inactive',
      'ui_alarmDelete': 'Delete',
      'ui_alarmSave': 'Save',
      'ui_alarmTitle': 'Alarms',
      'ui_alarmReady': 'Alarm readiness',
      'ui_alarmReadyYes': 'Ready for reliable alarms',
      'ui_alarmReadyNo': 'Android permissions missing',
      'ui_alarmReadyDescYes':
          'Exact alarms, full screen and Do Not Disturb are active.',
      'ui_alarmReadyDescNo': 'Open the missing Android system settings.',
      'ui_alarmExact': 'Allow exact alarms',
      'ui_alarmExactDesc': 'Required so Android does not delay the alarm.',
      'ui_alarmNotifications': 'Allow notifications',
      'ui_alarmNotificationsDesc':
          'Required for the visible full-screen alarm.',
      'ui_alarmFullscreen': 'Allow full-screen alarms',
      'ui_alarmFullscreenDesc': 'Shows the alarm on the lock screen.',
      'ui_alarmDnd': 'Override Do Not Disturb',
      'ui_alarmDndDesc':
          'Allows enabled alarms to ring despite Do Not Disturb.',
      'ui_alarmSmart': 'Smart alarm',
      'ui_alarmSchedule': 'Timetable alarm',
      'ui_alarmAt': '{label} at {time}',
      'ui_alarmScheduleDesc':
          'Wakes you before the first non-cancelled lesson.',
      'ui_alarmLead': 'Lead time',
      'ui_alarmLeadValue': '{n} min before the first lesson',
      'ui_alarmLeadByStart': 'Lead time by start time',
      'ui_alarmLeadByStartDesc': 'Set a different lead time, or no alarm, for selected first lessons.',
      'ui_alarmLeadByStartAdd': 'Add start time',
      'ui_alarmLeadByStartOff': 'No alarm',
      'ui_alarmLeadByStartDefault': 'Use default lead time',
      'ui_alarmUpdate': 'Refresh shortly before the alarm',
      'ui_alarmUpdateDesc': 'WebUntis is checked again 15 minutes beforehand.',
      'ui_alarmRing': 'Ringing',
      'ui_alarmSnooze': 'Snooze',
      'ui_alarmSnoozeDesc': 'min · swipe left',
      'ui_alarmSnoozeValue': '{n} min · swipe left',
      'ui_alarmSnoozeDuration': 'Snooze duration',
      'ui_alarmRingtone': 'Ringtone',
      'ui_alarmSystemTone': 'Android system alarm tone',
      'ui_alarmSelectedTone': 'Selected Android alarm tone',
      'ui_alarmOwnAlarms': 'Custom alarms',
      'ui_alarmAdd': 'Add alarm',
      'ui_alarmAddDesc': 'Repeats on selected weekdays.',
      'ui_alarmHeadsUp': 'Remind before the alarm',
      'ui_alarmHeadsUpValue': '{n} min beforehand',
      'ui_alarmHeadsUpDesc':
          'The current day is checked with WebUntis again first.',
      'ui_alarmEarlier': 'Make the next alarm ring earlier',
      'ui_alarmEarlierValue': '{n} min earlier',
      'ui_alarmEarlierDesc': 'Only applies to the next timetable alarm.',
      'ui_alarmDateActions': 'Alarm for {date}',
      'ui_alarmDateActionsDesc': 'This exception only applies to this school day.',
      'ui_alarmDisableDate': 'Disable alarm on this day',
      'ui_alarmCustomTime': 'Custom alarm time',
      'ui_alarmClearDate': 'Reset exception',
      'ui_alarmDateDisabled': 'Disabled on this day',
      'ui_alarmDateCustom': 'Custom time: {time}',
      'ui_alarmDateEarlier': '{n} min earlier',
      'ui_widgets': 'Widgets',
      'ui_widgetPreview': 'Preview',
      'ui_widgetPreviewTitle': 'Widgets & preview',
      'ui_widgetRefresh': 'Refresh preview',
      'ui_widgetChoose': 'Choose widget',
      'ui_widgetOwn': 'Custom widgets',
      'ui_widgetEditorOpen': 'Open widget editor',
      'ui_widgetEditorDesc':
          'Build content, order, colors, transparency and layout freely.',
      'ui_widgetAccount': 'Account for preview',
      'ui_widgetNoAccount': 'No account available',
      'ui_widgetAddAccountFirst': 'Add a WebUntis account first.',
      'ui_widgetHome': 'To home screen',
      'ui_widgetHomeUnavailable': 'Unavailable on this device',
      'ui_widgetHomeSupported':
          'Home-screen widgets are supported on Android and iOS.',
      'ui_widgetHoldHome': 'Press and hold the home screen',
      'ui_widgetHoldHomeDesc': 'Then tap “Edit” at the top and “Add widget”.',
      'ui_widgetSelectUntis': 'Select Untis+',
      'ui_widgetSelectUntisDesc': 'Choose the desired variant and size.',
      'ui_widgetSetAccount': 'Set account',
      'ui_widgetSetAccountDesc':
          'Press and hold the widget and choose “Edit widget”.',
      'ui_widgetAdd': 'Add widget',
      'ui_widgetPickerOpening': 'Opening widget picker …',
      'ui_widgetPickerSent': 'Widget request sent to the home screen.',
      'ui_widgetPickerHint': 'Open the widget picker from your home screen.',
      'ui_widgetPickerFailed':
          'Could not add the widget. Open the widget picker from the home screen.',
      'ui_widgetSyncedPreview':
          'The preview uses the latest widget data synced for this account.',
      'ui_widgetOpenTimetable':
          'Open the timetable once to sync real widget data.',
      'ui_editor': 'Widget editor',
      'ui_editorYourWidgets': 'Your widgets',
      'ui_editorNew': 'New',
      'ui_editorDuplicate': 'Duplicate',
      'ui_editorContentLayout': 'Content and layout',
      'ui_editorName': 'Name',
      'ui_editorCompact': 'Compact',
      'ui_editorStacked': 'Stacked',
      'ui_editorTimeline': 'Timeline',
      'ui_editorDesign': 'Design',
      'ui_editorBackground': 'Background',
      'ui_editorAccent': 'Accent',
      'ui_editorText': 'Text',
      'ui_editorShowIcons': 'Show icons',
      'ui_editorApplyColor': 'Apply color',
      'ui_editorTransparency': 'Transparency',
      'ui_editorRounding': 'Rounding',
      'ui_editorFontSize': 'Font size',
      'ui_colorRed': 'Red',
      'ui_colorGreen': 'Green',
      'ui_colorBlue': 'Blue',
      'ui_blockCurrent': 'Current lesson',
      'ui_blockNext': 'Next lesson',
      'ui_blockSchedule': 'Daily schedule',
      'ui_blockHomework': 'Tasks',
      'ui_blockExams': 'Exams',
      'ui_blockNotices': 'Notifications',
      'ui_blockAccount': 'Account',
      'ui_blockStatus': 'Status',
      'ui_previewCurrent': 'Now: Mathematics',
      'ui_previewNext': 'Next: English · Room 204',
      'ui_previewSchedule': '08:00 Maths\n09:45 English\n11:30 Biology',
      'ui_previewHomework': '2 open tasks',
      'ui_previewExams': 'Next exam: Friday',
      'ui_previewNotices': 'New notifications',
      'ui_previewStatus': 'Updated at 12:30',
      'ui_appearanceAppIcon': 'App icon',
      'ui_notificationsWidgets': 'Widgets & preview',
      'ui_notificationsWidgetsDesc':
          'Variants, preview and account assignment.',
      'ui_notificationsAlarms': 'Alarms & smart alarms',
      'ui_tempEditDesc':
          'This change is not sent to Untis and will be discarded on the next load.',
      'ui_subject': 'Subject',
      'ui_teacher': 'Teacher',
      'ui_room': 'Room',
      'ui_saveTimetableImage': 'Save timetable image',
      'ui_widgetAndroidDialogDesc':
          'The selected account is preselected in the Android dialog. You can change it before adding the widget.',
      'ui_widgetCurrent': 'Now',
      'ui_widgetCurrentDesc': 'Current lesson, next lesson and remaining time',
      'ui_widgetSchedule': 'Daily schedule',
      'ui_widgetScheduleDesc': 'The next entries in today’s timetable',
      'ui_widgetHomework': 'Tasks',
      'ui_widgetHomeworkDesc': 'A compact overview of your open tasks',
      'ui_widgetNotices': 'Notifications',
      'ui_widgetNoticesDesc': 'The latest notifications on your home screen',
      'ui_widgetSmallMedium': 'Small or medium',
      'ui_widgetMediumLarge': 'Medium or large',
      'ui_widgetToday': 'TODAY',
      'ui_widgetNoScheduleData': 'No daily data yet',
      'ui_widgetNoOpenHomework': 'No open tasks synced',
      'ui_widgetNoNotices': 'No notifications synced',
      'ui_widgetNoCurrentLesson': 'No current lesson',
      'ui_widgetNotSynced': 'Not synced yet',
      'ui_widgetLoading': 'LOADING',
      'ui_widgetCurrentStatus': 'CURRENT',
      'ui_widgetPreviewStatus': 'PREVIEW',
      'ui_widgetTimetableDetail': 'Open the timetable to load data',
      'ui_alarmMinutesSuffix': ' min',
      'ui_editorDefaultName': 'My widget',
      'ui_editorNewWidget': 'New widget',
      'ui_editorCopySuffix': 'copy',
      'ui_widgetMinutesRemaining': '{n} min remaining',
      'ui_widgetNoUpcomingExams': 'No upcoming exams',
      'ui_widgetExam': 'Exam',
      'ui_widgetLesson': 'Lesson',
      'ui_widgetHomeworkItem': 'Homework',
      'ui_widgetNext': 'Next: {title}',
      'ui_widgetNoLessonsToday': 'No lessons today',
      'ui_widgetOpenNotifications': 'Open new notifications in Untis+',
      'ui_notificationsNone': 'No new notifications',
      'ui_appearanceIconChoose': 'Choose home screen icon',
      'ui_appearanceIconAndroidOnly': 'Currently available on Android',
      'ui_nativeAlarmReminderChannel': 'Untis+ alarm reminders',
      'ui_nativeAlarmReminderChannelDesc': 'Alerts before an Untis+ alarm',
      'ui_nativeAlarmChannel': 'Untis+ alarms',
      'ui_nativeAlarmChannelDesc': 'Ringing Untis+ alarms',
      'ui_nativeAlarmRefreshChannel': 'Untis+ alarm refresh',
      'ui_nativeAlarmReminderTitle': 'Alarm in {minutes} minutes',
      'ui_nativeAlarmDisableToday': 'Disable for today',
      'ui_nativeAlarmTitle': 'Alarm',
      'ui_nativeAlarmSwipeHint': 'Swipe left to snooze, right to dismiss',
      'ui_nativeAlarmSnooze': 'Snooze · {minutes} min',
      'ui_nativeAlarmDismiss': 'Dismiss',
      'ui_nativeAlarmRefreshing': 'Updating alarm',
      'ui_nativeAlarmStatusActive': 'Alarm active',
      'ui_nativeAlarmStatusSnoozing': 'Snoozing',
      'ui_nativeAlarmTimeAccessibility': 'Alarm time {time}',
      'ui_nativeWidgetSetupTitle': 'Set up widget',
      'ui_nativeWidgetSetupAccount': 'Account for this widget',
      'ui_nativeWidgetSetupProfile': 'Widget profile',
      'ui_nativeWidgetSetupProfileHint': 'Profile from the widget editor',
      'ui_nativeWidgetSetupNoProfile': 'Create a profile in the Untis+ widget editor first.',
      'ui_nativeWidgetSetupNoAccount': 'Open Untis+ and add an account first.',
      'ui_nativeWidgetRefreshing': 'Updating …',
      'ui_refreshing': 'Refreshing',
      'ui_copyMessage': 'Copy message',
      'ui_aiAttachmentTooLarge': 'Attachments must not exceed 8 MB.',
      'ui_aiAttachFile': 'Attach file',
      'ui_aiAttachmentText': '\\n\\nFile {name}:\\n{excerpt}',
      'ui_aiAttachmentUnsupported': 'Attachment {name} ({mimeType}) cannot be read by this provider.',
      'ui_aiFileKindPdf': ' or PDF',
      'ui_aiHomeworkVisionPrompt': 'You extract homework from boards, worksheets, and notes.\\nExtract every task from the attached image{fileKind}.\\nReply ONLY in this JSON-array format (no Markdown fence, JSON only):\\n[\\n  {\\n    "subject": "Math",\\n    "text": "Page 42, exercises 1–5",\\n    "dueDate": "20260905"\\n  }\\n]\\nIMPORTANT: The date MUST be a YYYYMMDD string. Infer a missing year or date when possible. If the file contains no homework, return an empty array [].',
      'ui_aiExamVisionPrompt': 'You extract school exam schedules in a structured way.\\nExtract every relevant exam from the attached image{fileKind}.\\nReply ONLY in this JSON-array format (no Markdown fence, JSON only, no greeting):\\n[\\n  {\\n    "subject": "Math",\\n    "examType": "Exam",\\n    "date": "20240325",\\n    "description": "Additional details or an empty string"\\n  }\\n]\\nIMPORTANT: The date MUST be a YYYYMMDD string. Infer a missing year from the current year ({year}). If the file contains no exams, return an empty array [].',
      'ui_aiExamJsonSystemPrompt': 'Extract structured exam data and answer with JSON only.',
      'ui_aiExamImageSystemPrompt': 'Extract structured exam data from the image. Answer only as a JSON array.',
      'ui_aiResponseFormat': 'RESPONSE FORMAT:\\n- Answer briefly and visually.\\n- Prefer a JSON object with headline, summary, tags, metrics, and lessons.\\n- metrics is a list of objects with label and value.\\n- lessons is a list of objects with subject, subjectShort, room, teacher, time, and status.\\n- Avoid long prose.\\n- IMPORTANT: Include ONLY fields relevant to the question. Omit metrics or lessons, or use empty arrays, when they are not requested.',
      'ui_bgUpdateTitle': 'Untis+ update available',
      'ui_bgUpdateBody': 'Version {version} is available on GitHub Releases.',
      'ui_bgDailyBriefingTitle': 'Your school day at a glance',
      'ui_bgDailyBriefingBody': '{start}–{end}, {lessons} lessons, {breaks} breaks',
      'ui_bgDailyBriefingExpanded': 'Start: {start}\\nEnd: {end}\\nLessons: {lessons}\\nBreaks: {breaks}\\nNext: {next}',
      'ui_bgChangesTitle': 'Timetable updated',
      'ui_bgChangesBody': 'There are new changes today. Tap to open your timetable.',
      'ui_bgCurrentLesson': 'Current lesson',
      'ui_bgNextLesson': 'Next lesson',
      'ui_bgNoClasses': 'No more classes',
      'ui_bgLessonStarts': 'Starts at {time}',
      'ui_bgUntil': 'Until {time}',
      'ui_bgThen': 'Then: {lesson}',
      'ui_bgFinished': 'Finished',
      'ui_bgFreePeriod': 'Free period',
      'ui_bgFallbackLesson': 'Lesson {start}–{end}',
      'ui_bgDemoLesson': 'Demo lesson {code}',
      'ui_bgChangesCancelled': '{count} cancellations',
      'ui_bgChangesRoom': '{count} room changes',
      'ui_bgChangesSubstitution': '{count} substitutions',
      'ui_bgChangesOther': '{count} changes',
      'ui_widgetSystemColors': 'Material You',
      'ui_widgetCustomColors': 'Custom colors',
      'ui_aiActionCreateHomework': 'Create homework: {subject} · {text}',
      'ui_aiActionUpdateHomework': 'Update homework: {subject} · {text}',
      'ui_aiActionDeleteHomework': 'Delete homework: {id}',
      'ui_aiActionCompleteHomework': 'Mark homework as done: {id}',
      'ui_aiActionCreateExam': 'Create exam: {subject} · {text}',
      'ui_aiActionUpdateExam': 'Update exam: {subject} · {text}',
      'ui_aiActionDeleteExam': 'Delete exam: {id}',
      'ui_aiActionCreateGrade': 'Create grade: {subject} · {value}',
      'ui_aiActionUpdateGrade': 'Update grade: {subject} · {value}',
      'ui_aiActionDeleteGrade': 'Delete grade: {id}',
      'ui_aiActionUnknown': 'Unknown action',
      'ui_aiParametersTitle': 'AI parameters',
      'ui_aiPersonaStrict': 'Respond like a strict but fair teacher. Pay attention to discipline and order.',
      'ui_aiPersonaBuddy': 'Respond like a relaxed school friend. Use youthful, casual language.',
      'ui_aiPersonaHelpful': 'Respond in a friendly, professional, and helpful way.',
      'ui_aiAssistantIntro': 'You are a helpful assistant for the Untis+ timetable app.',
      'ui_aiAssistantRules': 'Respond naturally and kindly in the chat. You can access the user’s timetable and exams above. Use Markdown for clear formatting. Respond in natural language, never as JSON unless explicitly asked. Keep replies concise and precise, and do not introduce yourself. For a requested local change, append a separate block in this exact format: ```untis-action {"kind":"create_homework|update_homework|delete_homework|complete_homework|create_exam|update_exam|delete_exam|create_grade|update_grade|delete_grade","id":"optional id","subject":"subject","text":"text","dueDate":"YYYYMMDD","value":"optional grade","weight":"optional weight","type":"optional type"} ```. Suggest only safe, concrete changes; they are applied only after explicit confirmation. Never claim a change happened without proposing that block and receiving confirmation.',
      'ui_aiDayDataUnavailable': '{date}: timetable data for this day has not been loaded yet.',
      'ui_aiWeekDataUnavailable': 'The matching timetable week for {date} has not been loaded yet, so I will not guess.',
      'ui_aiNoScheduledLessons': 'No non-cancelled lessons are scheduled for {date}.',
      'ui_aiScheduleReply': 'Yes. On {date}, you have: {lessons}.',
      'ui_aiApplyChangesTitle': 'Confirm changes',
      'ui_aiApplyChangesDesc': 'The assistant has suggested these local changes:',
      'ui_aiChangesApplied': 'Changes applied.',
      'ui_apply': 'Apply',
      'ui_aiParametersDesc': 'Fine-tune the model’s responses.',
      'ui_aiTemperatureDesc':
          'Higher values make responses more creative; lower values are more precise.',
      'ui_aiTokenDesc': 'Maximum length of a single response.',
      'ui_aiTopPDesc': 'Nucleus sampling to limit word selection.',
      'ui_notificationsDenied':
          'Notifications are not allowed in system settings.',
      'ui_notificationsAlarmsDesc':
          'Exact Android alarms that adapt to cancellations.',
      'ui_editorAddWidget': 'Add this widget',
      'ui_editorIosHint':
          'Add Untis+ using the iOS widget picker, then select this profile in “Edit widget”.',

      'aiNewChat': 'New chat',
      'aiParameterTemperature': 'Temperature',
      'aiParameterMaxTokens': 'Max tokens',
      'aiParameterTopP': 'Top P',
      'aiOrbsCount': '{count} orbs',
      'aiNoiseLevel': '{pct}% noise',
      'aiGradientType': 'Gradient',
    },

    // ── FRENCH ────────────────────────────────────────────────────────────────
    'fr': {
      'gradesTotal': 'Total',
      'gradesBestSubject': 'Meilleure matière',
      'gradesAddDesc': 'Complétez votre aperçu des notes',
      'gradesCountPlural': 'notes',
      'gradesWeightLabelShort': 'Coef.',
      'navWeek': 'Semaine',
      'navHomework': 'Devoirs',
      'navExams': 'Examens',
      'navInfo': 'Infos',
      'navMenu': 'Menu',
      'navAi': 'IA',
      'timetableOfflineCache': 'Cache hors ligne actif',
      'timetableNotSignedIn': 'Non connecté',
      'timetableHttpError':
          'HTTP {status} : impossible de charger l’emploi du temps.',
      'timetableUnknownApiError': 'Erreur WebUntis inconnue',
      'timetableLoadError':
          'Impossible de charger l’emploi du temps. Vérifie ta connexion et réessaie.',

      'aiClearHistoryTitle': 'Effacer l\'historique ?',
      'aiClearHistoryDesc':
          'Tous les chats précédents seront définitivement effacés.',
      'aiClearHistorySuccess': 'Historique des chats effacé.',
      'aiLocalModelDescSmall': 'Petit, rapide, idéal pour mobile',
      'aiLocalModelDescBalanced': 'Équilibré, bonne qualité',
      'aiLocalModelDescMultilingual': 'Fort pour le multilinguisme',
      'aiLocalModelDescHighQuality': 'Haute qualité, plus de mémoire',
      'aiLocalModelDescStrong': 'Très fort mais plus grand',

      'notificationActionNextLesson': 'Cours suivant',
      'notificationActionFreeRooms': 'Salles libres',
      'notificationActionOpenDay': 'Ouvrir la journée',
      'notificationChannelCurrentLessonName': 'Cours actuel / Pause',
      'notificationChannelCurrentLessonDesc':
          'Statut actuel du cours ou de la pause.',
      'notificationChannelDailyBriefingName': 'Briefing quotidien',
      'notificationChannelDailyBriefingDesc':
          'Aperçu matinal de votre journée d\'école.',
      'notificationChannelImportantChangesName': 'Changements d\'horaire',
      'notificationChannelImportantChangesDesc':
          'Signale les annulations et changements de salle.',
      'notificationChannelUpdatesName': 'Mises à jour',
      'notificationChannelUpdatesDesc':
          'Informations sur les améliorations de l\'application.',

      'settingsLessonBorderRadiusCompact': 'Compact (6px)',
      'settingsLessonBorderRadiusStandard': 'Standard (12px)',
      'settingsLessonBorderRadiusRound': 'Arrondi (18px)',
      'settingsLessonBorderRadiusPill': 'Pilule (24px)',

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
      'onboardingFeatureUpdatesTitle': 'Mises à jour directes',
      'onboardingFeatureUpdatesDesc':
          'Télécharge la bonne mise à jour Android depuis les réglages.',
      'onboardingFeatureBackupTitle': 'Sauvegarde et restauration',
      'onboardingFeatureBackupDesc':
          'Conserve tes réglages et transfère-les sur un nouvel appareil.',
      'onboardingFinishSetup': 'Terminer la configuration',
      'onboardingUseDemoMode': 'Lancer le mode démo',
      'onboardingUseDemoModeDesc':
          'Teste Untis+ sans connexion école avec des données réalistes.',
      'tutorialTitle': 'Visite guidée de l\'app',
      'tutorialSkip': 'Passer la visite',
      'tutorialDone': 'Terminer la visite',
      'tutorialStepWeekTitle': 'Emploi du temps',
      'tutorialStepWeekDesc':
          'Ta journée commence ici. Change de semaine et ouvre un cours pour les détails.',
      'tutorialStepExamsTitle': 'Examens et tâches',
      'tutorialStepExamsDesc':
          'Garde les examens et les tâches en vue et ajoute tes propres entrées.',
      'tutorialStepInfoTitle': 'Infos école',
      'tutorialStepInfoDesc':
          'Les annonces de ton école sont regroupées dans cette zone.',
      'tutorialStepAiTitle': 'Assistant IA',
      'tutorialStepAiDesc':
          'Interroge ton assistant sur ton emploi du temps et tes tâches.',
      'tutorialStepSettingsTitle': 'Paramètres',
      'tutorialStepSettingsDesc':
          'Ajuste le design, les notifications, les comptes et la confidentialité.',
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
      'timetableMoreActions': 'Plus d’actions',
      'timetableExportImage': "Exporter l’emploi du temps en image",
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
      'homeworkFilterAll': 'Tous',
      'homeworkFilterOpen': 'En cours',
      'homeworkFilterDone': 'Terminés',
      'examsUpcomingCount': '{count} examen(s) à venir',
      'examsUpcomingNext': 'Prochain: {subject} le {date}',
      'gradesTypeSingle': 'Note individuelle',
      'gradesDateLabel': 'Date',
      'gradesCountLabel': '{count} note(s)',

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
      'infoAttachments': 'Pièces jointes',
      'infoAttachedExtOne': '{ext} joint',
      'infoAttachedExtMany': '{ext}s joints',
      'infoAttachedFile': 'Pièce jointe',
      'infoAttachedFiles': 'Pièces jointes',
      'attachmentSave': 'Enregistrer la pièce jointe',
      'attachmentSaved': 'Pièce jointe enregistrée.',
      'attachmentDownloadFailed': 'Impossible de télécharger la pièce jointe.',
      'attachmentDemoUnavailable':
          'Les fichiers réels ne sont pas disponibles en mode démo.',
      'infoCopyMessage': 'Copier le message',
      'infoMessageCopied': 'Message copié dans le presse-papiers.',
      'messageComposeTitle': 'Rédiger un message',
      'messageRecipients': 'Destinataires',
      'messageRecipientsLoading': 'Chargement des destinataires…',
      'messageRecipientSelect': 'Choisir un enseignant',
      'messageRecipientsApply': 'Appliquer',
      'messageNoRecipients': 'Aucun destinataire disponible.',
      'messageRecipientsFailed': 'Impossible de charger les destinataires.',
      'messageSubject': 'Objet',
      'messageBody': 'Message',
      'messageAttach': 'Pièces jointes',
      'messageAttachmentLimit': 'Un maximum de {count} pièces jointes est autorisé.',
      'messageAttachmentTooLarge': '{name} est trop volumineux.',
      'messageDraftAutosave': 'Le brouillon est enregistré automatiquement',
      'messageDiscardDraft': 'Supprimer le brouillon',
      'messageRequiredFields': 'Le destinataire, l’objet et le message sont requis.',
      'messageSend': 'Envoyer',
      'messageSending': 'Envoi…',
      'messageSent': 'Message envoyé.',
      'messageSendFailed': 'Le message n’a pas pu être envoyé.',
      'messageDemoUnavailable': 'Aucun vrai message ne peut être envoyé en mode démo.',
      'notificationActionCurrentLesson': 'Cours actuel : {lesson}',
      'notificationActionNextLessonLabel': 'Cours suivant',
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
      'aiClearHistoryTileTitle': 'Effacer l\'historique',
      'aiClearHistoryTileDesc': 'Supprimer tous les chats de l\'appareil',
      'aiTyping': 'L’IA écrit …',
      'aiChatTitle': 'Ton chat IA',
      'aiChatSubtitle':
          'Pose des questions sur ta vie scolaire ou discute simplement avec l’IA.',
      'aiTryIt': 'Essaie :',
      'aiSuggestions': [
        "Qu'est-ce que j'ai demain ?",
        "Ai-je une heure libre aujourd'hui ?",
        "À quelle heure finit l'école demain ?",
        "Y a-t-il des cours annulés aujourd'hui ?",
      ],
      'aiChatSuggestions': [
        'Comment puis-je améliorer mes notes ?',
        'Explique-moi simplement la théorie de la relativité.',
        'Rédige un mot d’excuse pour le sport.',
      ],
      'aiNoSchoolToday': 'Pas d’école aujourd’hui.',
      'aiCurrentLessonSummary':
          'Cours actuel : {subject}, salle {room} (jusqu’à {end})',
      'aiNoCurrentLesson': 'Il n’y a pas de cours en ce moment.',
      'aiNoNextLessonSchool':
          'Cours suivant : aucun (il n’y a pas école aujourd’hui).',
      'aiNextLessonSummary':
          'Cours suivant : {subject}, salle {room}, à {start}',
      'aiNoMoreLessons': 'Plus aucun cours aujourd’hui.',
      'aiDefaultExamType': 'Examen',

      'settingsTitle': 'Paramètres',
      'commonSaveChanges': 'Enregistrer les modifications',
      'settingsLoggedInAs': 'Connecté en tant que',
      'settingsLogout': 'Se déconnecter',
      'settingsSectionQuick': 'Accès rapide',
      'settingsSectionGeneral': 'Application',
      'settingsAppearance': 'Apparence',
      'settingsAppearanceDesc': 'Système (Clair/Sombre)',
      'settingsAppearanceSurfaces': 'Surfaces',
      'settingsAppearanceMotion': 'Animations & effets',
      'settingsAppearanceTimetable': 'Couleurs de l’emploi du temps',
      'settingsAppearanceApp': 'Application',
      'settingsVisualTheme': 'Thème de l’application',
      'settingsVisualThemeDesc':
          'Modifie les couleurs, les formes, la typographie et les mouvements.',
      'themeDefault': 'Par défaut',
      'themeDefaultDesc': 'Le style Untis+ familier',
      'themeManga': 'Manga',
      'themeMangaDesc': 'Papier, trames et contours à l’encre',
      'themeGlass': 'Verre',
      'themeGlassDesc': 'Verre aurora apaisé et contrastes nets',
      'themeCyber': 'Cyber',
      'themeCyberDesc': 'Surfaces techniques précises et accents ciblés',
      'settingsHubNotifications': 'Notifications & Widgets',
      'settingsHubDataBackup': 'Données & Sauvegarde',
      'settingsHubDataBackupDesc': 'Sauvegarder tous les réglages',
      'settingsHubAccount': 'Compte & Démo',
      'settingsHubUpdatesAbout': 'Mises à jour & À propos',
      'settingsSupport': 'Soutenir le développement',
      'settingsSupportDesc': 'Soutenez-nous sur Ko-fi',
      'settingsReportIssue': 'Signaler un problème ou partager une idée',
      'settingsReportIssueDesc': 'Ouvre les tickets Untis+ sur GitHub',
      'settingsLanguage': 'Langue',
      'settingsSectionAI': 'Assistant IA',
      'settingsAiProvider': 'Fournisseur',
      'settingsAiProviderGemini': 'Google Gemini',
      'settingsAiProviderOpenAi': 'OpenAI',
      'settingsAiProviderMistral': 'Mistral AI',
      'settingsAiProviderCustom': 'Fournisseur personnalisé',
      'settingsAiProviderLocal': 'Local (On-Device)',
      'settingsAiModel': 'Modèle',
      'settingsAiParametersTitle': 'Paramètres',
      'settingsAiParametersDesc': 'Température, limite de jetons & Top P',
      'settingsAiAdjustmentTitle': 'Ajustement',
      'settingsAiPersonaTitle': 'Personnalité',
      'settingsAiPersonaHelpful': 'Assistant utile',
      'settingsAiPersonaStrict': 'Professeur strict',
      'settingsAiPersonaBuddy': 'Copain d\'école',
      'settingsAiDataTitle': 'Données',
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
      'settingsAiLocalModelDesc':
          'Sélectionne et télécharge un modèle pour l\'inférence sur l\'appareil.',
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
      'aiVar_current_lesson': 'Informations sur le cours actuel',
      'aiVar_next_lesson': 'Informations sur le cours suivant',
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
          'Choisis le style des transitions de page et des animations optionnelles des onglets principaux',
      'settingsUseMaterialYou': 'Material You',
      'settingsUseMaterialYouDesc':
          "S'adapter automatiquement à la couleur d'accentuation du système",
      'settingsCustomColorSeed': 'Couleur personnalisée',
      'settingsIsAmoled': 'Pitch Black (AMOLED)',
      'settingsIsAmoledDesc':
          'Arrière-plan noir profond en mode sombre pour les écrans OLED.',
      'settingsPageTransitionDefault': 'Par défaut',
      'settingsPageTransitionBounce': 'Ressort',
      'settingsPageTransitionFade': 'Fondu doux',
      'settingsPageTransitionSlide': 'Axe partagé',
      'settingsPageTransitionZoom': 'Zoom focus',
      'settingsPageTransitionBlur': 'Flou focus',
      'settingsPageTransitionEaseIn': 'Élévation',
      'settingsPageTransitionEaseOut': 'Dérive',
      'settingsPageTransitionExpo': 'Montée Expo',
      'settingsMainTabFadeUp': 'Animations des onglets principaux',
      'settingsMainTabFadeUpDesc':
          'Anime les changements d’onglet principal avec la transition choisie ci-dessus. Désactivé = changement immédiat.',
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
      'settingsTimetableSwitchAnimation': 'Animation de transition',
      'settingsTimetableSwitchAnimationDesc':
          'Animation utilisée pour passer entre les jours et les semaines.',
      'settingsTimetableSwitchAnimationDefault': 'Par défaut',
      'settingsTimetableSwitchAnimationMaterial': 'Material 3 Carousel',
      'settingsTimetableSwitchAnimationDepth': 'Profondeur & fondu',
      'settingsShowCancelled': 'Afficher les cours annulés',
      'settingsShowCancelledDesc':
          'Les cours annulés sont visibles dans l\'emploi du temps',
      'settingsCancelledColor': 'Couleur annulée',
      'settingsCancelledColorDesc':
          'Personnaliser la couleur des cours annulés',
      'settingsLessonDesignTitle': 'Design des cours & cartes',
      'settingsLessonDesignDesc':
          'Personnalisez le style, les flous et les détails des cours.',
      'settingsLessonStyle': 'Style de carte',
      'settingsLessonStyleDesc': 'Choisissez l\'esthétique visuelle des cours.',
      'settingsLessonStyleModern': 'Moderne (Teinté)',
      'settingsLessonStyleGlass': 'Verre dépoli (Glass)',
      'settingsLessonStyleGradient': 'Dégradé',
      'settingsLessonStyleOutline': 'Contour / Minimal',
      'settingsLessonStyleSolid': 'Plein / Contrasté',
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
      'settingsLessonShowTeacherDesc':
          'Afficher les initiales ou le nom de l\'enseignant.',
      'settingsLessonShowSubjectIcons': 'Afficher les icônes des matières',
      'settingsLessonShowSubjectIconsDesc':
          'Affiche des icônes adaptées à côté des matières dans l’emploi du temps.',
      'settingsLessonShowRoom': 'Afficher la salle',
      'settingsLessonShowRoomDesc': 'Afficher le numéro de salle sur la carte.',
      'settingsLessonCompactMode': 'Mode compact',
      'settingsLessonCompactModeDesc':
          'Espacement réduit pour les emplois du temps chargés.',
      'settingsLessonDimPast': 'Atténuer les cours passés',
      'settingsLessonDimPastDesc':
          'Griser discrètement les cours terminés de la journée.',
      'settingsLessonCancelledPattern': 'Hachures d\'annulation',
      'settingsLessonCancelledPatternDesc':
          'Affiche des rayures diagonales en cas d\'annulation.',
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
      'settingsSurfaceBlur': 'Flou des surfaces',
      'settingsSurfaceBlurDesc':
          'Floute les cartes et surfaces normales. Quand l’effet de flou est actif, les arrière-plans des dialogues, panneaux et tutoriels sont aussi floutés.',
      'settingsSurfaceCorners': 'Coins des surfaces',
      'settingsSurfaceCornersDesc':
          'Règle l’arrondi des cartes et surfaces normales.',
      'settingsSurfaceCornersCurrent': 'Actuel',
      'settingsSurfaceCornersSharper': 'Plus anguleux',
      'settingsSurfaceCornersCustom': 'Personnalisé',
      'settingsSurfaceCornerRadius': 'Rayon des coins',
      'settingsGlowEffects': 'Effets lumineux',
      'settingsGlowEffectsDesc':
          'Halos colorés autour des cours, tâches, notes et icônes',
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
      'settingsSectionCredits': 'Crédits',
      'settingsCreditsDevelopers': 'Développeurs',
      'settingsCreditsDeveloper': 'Développeur',
      'settingsCreditsFounderDeveloper': 'Fondateur & Développeur',
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
      'settingsGithubDownloading': 'Téléchargement de la mise à jour…',
      'settingsGithubDownloadCancel': 'Annuler le téléchargement',
      'settingsGithubDownloadCancelled':
          'Téléchargement de la mise à jour annulé.',
      'settingsGithubDownloadFailed':
          'Impossible de télécharger la mise à jour.',
      'settingsGithubNoCompatibleAndroidApk':
          'Aucun APK Android n’est disponible pour l’architecture de cet appareil.',
      'settingsGithubInstallPermissionRequired':
          'Autorise Untis+ à installer des applis inconnues, puis relance l’installation.',
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
      'settingsGithubInstallerOpened':
          'La demande d’installation système est ouverte.',
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
      'changelogNoData': '# Aucune donnée disponible',
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

      'aiNewChat': 'Nouveau chat',
      'aiParameterTemperature': 'Température',
      'aiParameterMaxTokens': 'Max. jetons',
      'aiParameterTopP': 'Top P',
      'aiOrbsCount': '{count} orbes',
      'aiNoiseLevel': '{pct}% bruit',
      'aiGradientType': 'Dégradé',

      'navGrades': 'Notes',
      'gradesTitle': 'Suivi des notes',
      'gradesAddTitle': 'Ajouter une note',
      'gradesEditTitle': 'Modifier la note',
      'gradesSubjectLabel': 'Matière',
      'gradesGradeLabel': 'Note',
      'gradesWeightLabel': 'Coefficient',
      'gradesTypeLabel': 'Type',
      'homeworkAddDesc': 'Gérer les devoirs et échéances',
      'examsAddDesc': 'Planifier les examens à venir',
      'gradesAverage': 'Moyenne',
      'gradesNone': 'Aucune note',
      'gradesNoneHint': 'Appuyez sur + pour ajouter votre première note.',

      'ui_tempEditTitle': 'Modifier temporairement le cours',
      'ui_absence': 'Annulé',
      'ui_reset': 'Réinitialiser',
      'ui_cancel': 'Annuler',
      'ui_localSave': 'Enregistrer uniquement localement',
      'ui_timetableImageSaved': 'Image de l’emploi du temps enregistrée',
      'ui_imageExportFailed': 'Impossible d’exporter l’image',
      'ui_homeworkManaged': 'Ce devoir est géré par Untis.',
      'ui_start': 'Accueil',
      'ui_notifications': 'Notifications',
      'ui_accountRemoveQuestion': 'Supprimer le compte ?',
      'ui_accountRemoveDesc':
          'Le compte est supprimé uniquement de cet appareil. Vos autres réglages restent inchangés.',
      'ui_accountRemove': 'Supprimer',
      'ui_accountRemoveThis': 'Supprimer ce compte',
      'ui_accountSignOut': 'Se déconnecter sur cet appareil',
      'ui_accounts': 'Comptes',
      'ui_accountAdd': 'Ajouter un compte',
      'ui_accountConnect': 'Connecter un autre compte WebUntis',
      'ui_alarmApply': 'Appliquer',
      'ui_alarmOwn': 'Alarme personnalisée',
      'ui_alarmTime': 'Heure de l’alarme',
      'ui_alarmActive': 'Active',
      'ui_alarmInactive': 'Inactive',
      'ui_alarmDelete': 'Supprimer',
      'ui_alarmSave': 'Enregistrer',
      'ui_alarmTitle': 'Alarmes',
      'ui_alarmReady': 'État des alarmes',
      'ui_alarmReadyYes': 'Prêt pour des alarmes fiables',
      'ui_alarmReadyNo': 'Autorisations Android manquantes',
      'ui_alarmReadyDescYes':
          'Alarmes exactes, plein écran et Ne pas déranger sont actifs.',
      'ui_alarmReadyDescNo': 'Ouvrez les réglages système Android manquants.',
      'ui_alarmExact': 'Autoriser les alarmes exactes',
      'ui_alarmExactDesc':
          'Nécessaire pour éviter le décalage de l’alarme par Android.',
      'ui_alarmNotifications': 'Autoriser les notifications',
      'ui_alarmNotificationsDesc':
          'Nécessaire pour l’alarme plein écran visible.',
      'ui_alarmFullscreen': 'Autoriser les alarmes plein écran',
      'ui_alarmFullscreenDesc': 'Affiche l’alarme sur l’écran verrouillé.',
      'ui_alarmDnd': 'Ignorer Ne pas déranger',
      'ui_alarmDndDesc':
          'Permet aux alarmes activées de sonner malgré Ne pas déranger.',
      'ui_alarmSmart': 'Alarme intelligente',
      'ui_alarmSchedule': 'Alarme de l’emploi du temps',
      'ui_alarmAt': '{label} à {time}',
      'ui_alarmScheduleDesc': 'Réveille avant le premier cours non annulé.',
      'ui_alarmLead': 'Délai',
      'ui_alarmLeadValue': '{n} min avant le premier cours',
      'ui_alarmLeadByStart': 'Délai par heure de début',
      'ui_alarmLeadByStartDesc': 'Définissez un délai différent ou aucune alarme selon le premier cours.',
      'ui_alarmLeadByStartAdd': 'Ajouter une heure de début',
      'ui_alarmLeadByStartOff': 'Pas d’alarme',
      'ui_alarmLeadByStartDefault': 'Utiliser le délai par défaut',
      'ui_alarmUpdate': 'Actualiser juste avant l’alarme',
      'ui_alarmUpdateDesc': 'WebUntis est vérifié à nouveau 15 minutes avant.',
      'ui_alarmRing': 'Sonnerie',
      'ui_alarmSnooze': 'Répétition',
      'ui_alarmSnoozeDesc': 'min · glisser vers la gauche',
      'ui_alarmSnoozeValue': '{n} min · glisser vers la gauche',
      'ui_alarmSnoozeDuration': 'Durée de répétition',
      'ui_alarmRingtone': 'Sonnerie',
      'ui_alarmSystemTone': 'Sonnerie système Android',
      'ui_alarmSelectedTone': 'Sonnerie Android sélectionnée',
      'ui_alarmOwnAlarms': 'Alarmes personnalisées',
      'ui_alarmAdd': 'Ajouter une alarme',
      'ui_alarmAddDesc': 'Se répète les jours sélectionnés.',
      'ui_alarmHeadsUp': 'Rappeler avant l’alarme',
      'ui_alarmHeadsUpValue': '{n} min avant',
      'ui_alarmHeadsUpDesc':
          'La journée en cours est d’abord vérifiée à nouveau dans WebUntis.',
      'ui_alarmEarlier': 'Faire sonner la prochaine alarme plus tôt',
      'ui_alarmEarlierValue': '{n} min plus tôt',
      'ui_alarmEarlierDesc': 'S’applique seulement à la prochaine alarme d’emploi du temps.',
      'ui_alarmDateActions': 'Alarme pour le {date}',
      'ui_alarmDateActionsDesc': 'Cette exception ne s’applique qu’à ce jour de cours.',
      'ui_alarmDisableDate': 'Désactiver l’alarme ce jour',
      'ui_alarmCustomTime': 'Heure d’alarme personnalisée',
      'ui_alarmClearDate': 'Réinitialiser l’exception',
      'ui_alarmDateDisabled': 'Désactivée ce jour',
      'ui_alarmDateCustom': 'Heure personnalisée : {time}',
      'ui_alarmDateEarlier': '{n} min plus tôt',
      'ui_widgets': 'Widgets',
      'ui_widgetPreview': 'Aperçu',
      'ui_widgetPreviewTitle': 'Widgets et aperçu',
      'ui_widgetRefresh': 'Actualiser l’aperçu',
      'ui_widgetChoose': 'Choisir un widget',
      'ui_widgetOwn': 'Widgets personnalisés',
      'ui_widgetEditorOpen': 'Ouvrir l’éditeur de widgets',
      'ui_widgetEditorDesc':
          'Composez librement contenu, ordre, couleurs, transparence et mise en page.',
      'ui_widgetAccount': 'Compte pour l’aperçu',
      'ui_widgetNoAccount': 'Aucun compte disponible',
      'ui_widgetAddAccountFirst': 'Ajoutez d’abord un compte WebUntis.',
      'ui_widgetHome': 'Vers l’écran d’accueil',
      'ui_widgetHomeUnavailable': 'Indisponible sur cet appareil',
      'ui_widgetHomeSupported':
          'Les widgets d’accueil sont pris en charge sur Android et iOS.',
      'ui_widgetHoldHome': 'Maintenir l’écran d’accueil',
      'ui_widgetHoldHomeDesc':
          'Touchez ensuite « Modifier » en haut, puis « Ajouter un widget ».',
      'ui_widgetSelectUntis': 'Sélectionner Untis+',
      'ui_widgetSelectUntisDesc':
          'Choisissez la variante et la taille souhaitées.',
      'ui_widgetSetAccount': 'Définir le compte',
      'ui_widgetSetAccountDesc':
          'Maintenez le widget et choisissez « Modifier le widget ».',
      'ui_widgetAdd': 'Ajouter un widget',
      'ui_widgetPickerOpening': 'Ouverture du sélecteur de widgets…',
      'ui_widgetPickerSent': 'Demande de widget envoyée à l’écran d’accueil.',
      'ui_widgetPickerHint':
          'Ouvrez le sélecteur de widgets depuis l’écran d’accueil.',
      'ui_widgetPickerFailed':
          'Impossible d’ajouter le widget. Ouvrez le sélecteur depuis l’écran d’accueil.',
      'ui_widgetSyncedPreview':
          'L’aperçu utilise les dernières données synchronisées pour ce compte.',
      'ui_widgetOpenTimetable':
          'Ouvrez une fois l’emploi du temps pour synchroniser les données réelles.',
      'ui_editor': 'Éditeur de widgets',
      'ui_editorYourWidgets': 'Vos widgets',
      'ui_editorNew': 'Nouveau',
      'ui_editorDuplicate': 'Dupliquer',
      'ui_editorContentLayout': 'Contenu et mise en page',
      'ui_editorName': 'Nom',
      'ui_editorCompact': 'Compact',
      'ui_editorStacked': 'Empilé',
      'ui_editorTimeline': 'Chronologie',
      'ui_editorDesign': 'Design',
      'ui_editorBackground': 'Arrière-plan',
      'ui_editorAccent': 'Accent',
      'ui_editorText': 'Texte',
      'ui_editorShowIcons': 'Afficher les icônes',
      'ui_editorApplyColor': 'Appliquer la couleur',
      'ui_editorTransparency': 'Transparence',
      'ui_editorRounding': 'Arrondi',
      'ui_editorFontSize': 'Taille du texte',
      'ui_colorRed': 'Rouge',
      'ui_colorGreen': 'Vert',
      'ui_colorBlue': 'Bleu',
      'ui_blockCurrent': 'Cours actuel',
      'ui_blockNext': 'Prochain cours',
      'ui_blockSchedule': 'Programme du jour',
      'ui_blockHomework': 'Tâches',
      'ui_blockExams': 'Examens',
      'ui_blockNotices': 'Notifications',
      'ui_blockAccount': 'Compte',
      'ui_blockStatus': 'Statut',
      'ui_previewCurrent': 'Maintenant : Mathématiques',
      'ui_previewNext': 'Ensuite : Anglais · Salle 204',
      'ui_previewSchedule': '08:00 Maths\n09:45 Anglais\n11:30 Biologie',
      'ui_previewHomework': '2 tâches ouvertes',
      'ui_previewExams': 'Prochain examen : vendredi',
      'ui_previewNotices': 'Nouvelles notifications',
      'ui_previewStatus': 'Mis à jour à 12:30',
      'ui_appearanceAppIcon': 'Icône de l’application',
      'ui_notificationsWidgets': 'Widgets et aperçu',
      'ui_notificationsWidgetsDesc':
          'Variantes, aperçu et attribution du compte.',
      'ui_notificationsAlarms': 'Alarmes et alarmes intelligentes',
      'ui_tempEditDesc':
          'Cette modification n’est pas envoyée à Untis et sera annulée au prochain chargement.',
      'ui_subject': 'Matière',
      'ui_teacher': 'Enseignant',
      'ui_room': 'Salle',
      'ui_saveTimetableImage': 'Enregistrer l’image de l’emploi du temps',
      'ui_widgetAndroidDialogDesc':
          'Le compte sélectionné est présélectionné dans la fenêtre Android. Vous pouvez le modifier avant l’ajout.',
      'ui_widgetCurrent': 'Maintenant',
      'ui_widgetCurrentDesc': 'Cours actuel, prochain cours et temps restant',
      'ui_widgetSchedule': 'Programme du jour',
      'ui_widgetScheduleDesc':
          'Les prochaines entrées de votre emploi du temps',
      'ui_widgetHomework': 'Tâches',
      'ui_widgetHomeworkDesc': 'Un aperçu compact de vos tâches ouvertes',
      'ui_widgetNotices': 'Notifications',
      'ui_widgetNoticesDesc':
          'Les dernières notifications sur votre écran d’accueil',
      'ui_widgetSmallMedium': 'Petite ou moyenne',
      'ui_widgetMediumLarge': 'Moyenne ou grande',
      'ui_widgetToday': 'AUJOURD’HUI',
      'ui_widgetNoScheduleData': 'Pas encore de données du jour',
      'ui_widgetNoOpenHomework': 'Aucune tâche ouverte synchronisée',
      'ui_widgetNoNotices': 'Aucune notification synchronisée',
      'ui_widgetNoCurrentLesson': 'Aucun cours actuel',
      'ui_widgetNotSynced': 'Pas encore synchronisé',
      'ui_widgetLoading': 'CHARGEMENT',
      'ui_widgetCurrentStatus': 'ACTUEL',
      'ui_widgetPreviewStatus': 'APERÇU',
      'ui_widgetTimetableDetail':
          'Ouvrez l’emploi du temps pour charger les données',
      'ui_alarmMinutesSuffix': ' min',
      'ui_editorDefaultName': 'Mon widget',
      'ui_editorNewWidget': 'Nouveau widget',
      'ui_editorCopySuffix': 'copie',
      'ui_widgetMinutesRemaining': '{n} min restantes',
      'ui_widgetNoUpcomingExams': 'Aucun examen à venir',
      'ui_widgetExam': 'Examen',
      'ui_widgetLesson': 'Cours',
      'ui_widgetHomeworkItem': 'Devoir',
      'ui_widgetNext': 'Ensuite : {title}',
      'ui_widgetNoLessonsToday': 'Aucun cours aujourd’hui',
      'ui_widgetOpenNotifications':
          'Ouvrir les nouvelles notifications dans Untis+',
      'ui_notificationsNone': 'Aucune nouvelle notification',
      'ui_appearanceIconChoose': 'Choisir l’icône de l’écran d’accueil',
      'ui_appearanceIconAndroidOnly': 'Actuellement disponible sur Android',
      'ui_nativeAlarmReminderChannel': 'Rappels d’alarme Untis+',
      'ui_nativeAlarmReminderChannelDesc': 'Alertes avant une alarme Untis+',
      'ui_nativeAlarmChannel': 'Alarmes Untis+',
      'ui_nativeAlarmChannelDesc': 'Alarmes Untis+ qui sonnent',
      'ui_nativeAlarmRefreshChannel': 'Actualisation des alarmes Untis+',
      'ui_nativeAlarmReminderTitle': 'Alarme dans {minutes} minutes',
      'ui_nativeAlarmDisableToday': 'Désactiver pour aujourd’hui',
      'ui_nativeAlarmTitle': 'Alarme',
      'ui_nativeAlarmSwipeHint': 'Glissez à gauche pour répéter, à droite pour arrêter',
      'ui_nativeAlarmSnooze': 'Répéter · {minutes} min',
      'ui_nativeAlarmDismiss': 'Arrêter',
      'ui_nativeAlarmRefreshing': 'Actualisation de l’alarme',
      'ui_nativeAlarmStatusActive': 'Alarme active',
      'ui_nativeAlarmStatusSnoozing': 'Répétition en cours',
      'ui_nativeAlarmTimeAccessibility': 'Heure de l’alarme {time}',
      'ui_nativeWidgetSetupTitle': 'Configurer le widget',
      'ui_nativeWidgetSetupAccount': 'Compte de ce widget',
      'ui_nativeWidgetSetupProfile': 'Profil du widget',
      'ui_nativeWidgetSetupProfileHint': 'Profil de l’éditeur de widgets',
      'ui_nativeWidgetSetupNoProfile': 'Créez d’abord un profil dans l’éditeur de widgets Untis+.',
      'ui_nativeWidgetSetupNoAccount': 'Ouvrez Untis+ et ajoutez d’abord un compte.',
      'ui_nativeWidgetRefreshing': 'Actualisation…',
      'ui_refreshing': 'Actualisation',
      'ui_copyMessage': 'Copier le message',
      'ui_aiAttachmentTooLarge': 'Les pièces jointes ne doivent pas dépasser 8 Mo.',
      'ui_aiAttachFile': 'Joindre un fichier',
      'ui_aiAttachmentText': '\\n\\nFichier {name} :\\n{excerpt}',
      'ui_aiAttachmentUnsupported': 'La pièce jointe {name} ({mimeType}) ne peut pas être lue par ce fournisseur.',
      'ui_aiFileKindPdf': ' ou PDF',
      'ui_aiHomeworkVisionPrompt': 'Tu extrais les devoirs de tableaux, fiches et notes.\\nExtrais toutes les tâches de l’image jointe{fileKind}.\\nRéponds UNIQUEMENT dans ce format de tableau JSON (sans bloc Markdown, JSON brut) :\\n[\\n  {\\n    "subject": "Mathématiques",\\n    "text": "Page 42, exercices 1 à 5",\\n    "dueDate": "20260905"\\n  }\\n]\\nIMPORTANT : la date DOIT être une chaîne au format YYYYMMDD. Déduis une année ou une date manquante si possible. Si le fichier ne contient aucun devoir, renvoie un tableau vide [].',
      'ui_aiExamVisionPrompt': 'Tu extrais de manière structurée les calendriers d’examens scolaires.\\nExtrais tous les examens pertinents de l’image jointe{fileKind}.\\nRéponds UNIQUEMENT dans ce format de tableau JSON (sans bloc Markdown, JSON brut, sans formule de salutation) :\\n[\\n  {\\n    "subject": "Mathématiques",\\n    "examType": "Examen",\\n    "date": "20240325",\\n    "description": "Informations complémentaires ou chaîne vide"\\n  }\\n]\\nIMPORTANT : la date DOIT être une chaîne au format YYYYMMDD. Déduis une année manquante à partir de l’année en cours ({year}). Si le fichier ne contient aucun examen, renvoie un tableau vide [].',
      'ui_aiExamJsonSystemPrompt': 'Extrais les données structurées des examens et réponds uniquement en JSON.',
      'ui_aiExamImageSystemPrompt': 'Extrais les données structurées des examens de l’image. Réponds uniquement sous forme de tableau JSON.',
      'ui_aiResponseFormat': 'FORMAT DE RÉPONSE :\\n- Réponds de façon brève et visuelle.\\n- Privilégie un objet JSON avec headline, summary, tags, metrics et lessons.\\n- metrics est une liste d’objets avec label et value.\\n- lessons est une liste d’objets avec subject, subjectShort, room, teacher, time et status.\\n- Évite les longs textes.\\n- IMPORTANT : ne fournis QUE les champs utiles à la question. Omet metrics ou lessons, ou renvoie des tableaux vides, s’ils ne sont pas demandés.',
      'ui_bgUpdateTitle': 'Mise à jour Untis+ disponible',
      'ui_bgUpdateBody': 'La version {version} est disponible dans les versions GitHub.',
      'ui_bgDailyBriefingTitle': 'Ton aperçu de la journée',
      'ui_bgDailyBriefingBody': '{start}–{end}, {lessons} cours, {breaks} pauses',
      'ui_bgDailyBriefingExpanded': 'Début : {start}\\nFin : {end}\\nCours : {lessons}\\nPauses : {breaks}\\nSuivant : {next}',
      'ui_bgChangesTitle': 'Emploi du temps mis à jour',
      'ui_bgChangesBody': 'Il y a de nouveaux changements aujourd’hui. Ouvre ton emploi du temps.',
      'ui_bgCurrentLesson': 'Cours actuel',
      'ui_bgNextLesson': 'Cours suivant',
      'ui_bgNoClasses': 'Plus de cours',
      'ui_bgLessonStarts': 'Commence à {time}',
      'ui_bgUntil': 'Jusqu’à {time}',
      'ui_bgThen': 'Ensuite : {lesson}',
      'ui_bgFinished': 'Terminé',
      'ui_bgFreePeriod': 'Heure libre',
      'ui_bgFallbackLesson': 'Cours {start}–{end}',
      'ui_bgDemoLesson': 'Cours démo {code}',
      'ui_bgChangesCancelled': '{count} annulations',
      'ui_bgChangesRoom': '{count} changements de salle',
      'ui_bgChangesSubstitution': '{count} remplacements',
      'ui_bgChangesOther': '{count} changements',
      'ui_widgetSystemColors': 'Material You',
      'ui_widgetCustomColors': 'Couleurs personnalisées',
      'ui_aiActionCreateHomework': 'Créer le devoir : {subject} · {text}',
      'ui_aiActionUpdateHomework': 'Modifier le devoir : {subject} · {text}',
      'ui_aiActionDeleteHomework': 'Supprimer le devoir : {id}',
      'ui_aiActionCompleteHomework': 'Marquer le devoir comme fait : {id}',
      'ui_aiActionCreateExam': 'Créer l’examen : {subject} · {text}',
      'ui_aiActionUpdateExam': 'Modifier l’examen : {subject} · {text}',
      'ui_aiActionDeleteExam': 'Supprimer l’examen : {id}',
      'ui_aiActionCreateGrade': 'Créer la note : {subject} · {value}',
      'ui_aiActionUpdateGrade': 'Modifier la note : {subject} · {value}',
      'ui_aiActionDeleteGrade': 'Supprimer la note : {id}',
      'ui_aiActionUnknown': 'Action inconnue',
      'ui_aiParametersTitle': 'Paramètres IA',
      'ui_aiPersonaStrict': 'Réponds comme un professeur strict mais juste. Veille à la discipline et à l’ordre.',
      'ui_aiPersonaBuddy': 'Réponds comme un camarade détendu, avec un langage jeune et naturel.',
      'ui_aiPersonaHelpful': 'Réponds de façon aimable, professionnelle et utile.',
      'ui_aiAssistantIntro': 'Tu es un assistant utile pour l’application d’emploi du temps Untis+.',
      'ui_aiAssistantRules': 'Réponds naturellement et gentiment dans le chat. Tu peux accéder à l’emploi du temps et aux examens de l’utilisateur ci-dessus. Utilise Markdown pour une mise en forme claire. Réponds en langage naturel, jamais en JSON sauf demande explicite. Reste concis et précis, sans te présenter. Pour une modification locale demandée, ajoute un bloc séparé dans ce format exact : ```untis-action {"kind":"create_homework|update_homework|delete_homework|complete_homework|create_exam|update_exam|delete_exam|create_grade|update_grade|delete_grade","id":"optional id","subject":"subject","text":"text","dueDate":"YYYYMMDD","value":"optional grade","weight":"optional weight","type":"optional type"} ```. Ne propose que des modifications sûres et concrètes ; elles ne sont appliquées qu’après confirmation explicite. N’affirme jamais qu’une modification a été faite sans proposer ce bloc et recevoir la confirmation.',
      'ui_aiDayDataUnavailable': '{date} : les données de cet emploi du temps ne sont pas encore chargées.',
      'ui_aiWeekDataUnavailable': 'La semaine correspondante pour {date} n’est pas encore chargée, je ne vais donc pas deviner.',
      'ui_aiNoScheduledLessons': 'Aucun cours non annulé n’est prévu le {date}.',
      'ui_aiScheduleReply': 'Oui. Le {date}, tu as : {lessons}.',
      'ui_aiApplyChangesTitle': 'Confirmer les modifications',
      'ui_aiApplyChangesDesc': 'L’assistant propose les modifications locales suivantes :',
      'ui_aiChangesApplied': 'Modifications appliquées.',
      'ui_apply': 'Appliquer',
      'ui_aiParametersDesc': 'Ajustez finement les réponses du modèle.',
      'ui_aiTemperatureDesc':
          'Des valeurs élevées rendent les réponses plus créatives ; des valeurs basses, plus précises.',
      'ui_aiTokenDesc': 'Longueur maximale d’une réponse.',
      'ui_aiTopPDesc':
          'Échantillonnage nucleus pour limiter le choix des mots.',
      'ui_notificationsDenied':
          'Les notifications ne sont pas autorisées dans les réglages système.',
      'ui_notificationsAlarmsDesc':
          'Alarmes Android exactes qui s’adaptent aux annulations.',
      'ui_editorAddWidget': 'Ajouter ce widget',
      'ui_editorIosHint':
          'Ajoutez Untis+ avec le sélecteur de widgets iOS, puis choisissez ce profil dans « Modifier le widget ».',

      'homeworkAddTitle': 'Ajouter un devoir',
      'homeworkEditTitle': 'Modifier le devoir',
      'homeworkSubjectLabel': 'Matière / Titre *',
      'homeworkTaskLabel': 'Tâche / Description',
      'homeworkDueDateLabel': 'À rendre pour le',
      'homeworkActionCustom': 'Ajouter manuellement',
      'homeworkActionImport': 'Scanner avec l\'IA',
      'homeworkSave': 'Enregistrer',
      'homeworkDelete': 'Supprimer',
      'homeworkCancel': 'Annuler',
      'homeworkImportTitle': 'Scanner un devoir',
      'homeworkImportSuccess': 'Devoirs scannés avec succès !',
      'homeworkImportError': 'Erreur lors du scan des devoirs : ',
      'subjectOverviewTitle': 'Aperçu de la matière',
      'addGradeForSubject': '+ Note',
      'addExamForSubject': '+ Examen',
      'addHomeworkForSubject': '+ Devoir',
      'noGradesForSubject': 'Aucune note enregistrée pour cette matière.',
      'noExamsForSubject': 'Aucun examen prévu pour cette matière.',
      'noHomeworkForSubject': 'Aucun devoir pour cette matière.',
    },

    // ── SPANISH ───────────────────────────────────────────────────────────────
    'es': {
      'gradesTotal': 'Total',
      'gradesBestSubject': 'Mejor asignatura',
      'gradesAddDesc': 'Completa tu resumen de notas',
      'gradesCountPlural': 'notas',
      'gradesWeightLabelShort': 'Peso',
      'navWeek': 'Semana',
      'navHomework': 'Deberes',
      'navExams': 'Exámenes',
      'navInfo': 'Info',
      'navMenu': 'Menú',
      'navAi': 'IA',
      'timetableOfflineCache': 'Caché sin conexión activo',
      'timetableNotSignedIn': 'Sesión no iniciada',
      'timetableHttpError': 'HTTP {status}: no se pudo cargar el horario.',
      'timetableUnknownApiError': 'Error de WebUntis desconocido',
      'timetableLoadError':
          'No se pudo cargar el horario. Comprueba tu conexión e inténtalo de nuevo.',

      'aiClearHistoryTitle': '¿Borrar historial?',
      'aiClearHistoryDesc':
          'Todos los chats anteriores se borrarán permanentemente.',
      'aiClearHistorySuccess': 'Historial de chat borrado.',
      'aiLocalModelDescSmall': 'Pequeño, rápido, ideal para móviles',
      'aiLocalModelDescBalanced': 'Equilibrado, buena calidad',
      'aiLocalModelDescMultilingual': 'Fuerte para uso multilingüe',
      'aiLocalModelDescHighQuality': 'Mayor calidad, más memoria',
      'aiLocalModelDescStrong': 'Muy fuerte pero más grande',

      'notificationActionNextLesson': 'Siguiente clase',
      'notificationActionFreeRooms': 'Aulas libres',
      'notificationActionOpenDay': 'Abrir día',
      'notificationChannelCurrentLessonName': 'Clase actual / Descanso',
      'notificationChannelCurrentLessonDesc':
          'Estado actual de la clase o descanso.',
      'notificationChannelDailyBriefingName': 'Resumen diario',
      'notificationChannelDailyBriefingDesc':
          'Resumen matutino de tu día escolar.',
      'notificationChannelImportantChangesName': 'Cambios de horario',
      'notificationChannelImportantChangesDesc':
          'Notifica sobre cancelaciones y cambios de aula.',
      'notificationChannelUpdatesName': 'Actualizaciones',
      'notificationChannelUpdatesDesc':
          'Notificaciones sobre mejoras de la aplicación.',

      'settingsLessonBorderRadiusCompact': 'Compacto (6px)',
      'settingsLessonBorderRadiusStandard': 'Estándar (12px)',
      'settingsLessonBorderRadiusRound': 'Redondo (18px)',
      'settingsLessonBorderRadiusPill': 'Píldora (24px)',

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
      'onboardingFeatureUpdatesTitle': 'Actualizaciones directas',
      'onboardingFeatureUpdatesDesc':
          'Descarga la actualización de Android adecuada desde Ajustes.',
      'onboardingFeatureBackupTitle': 'Copia y restauración',
      'onboardingFeatureBackupDesc':
          'Guarda tus ajustes y llévalos a un dispositivo nuevo.',
      'onboardingFinishSetup': 'Finalizar configuración',
      'onboardingUseDemoMode': 'Iniciar modo demo',
      'onboardingUseDemoModeDesc':
          'Prueba Untis+ sin inicio escolar con datos de ejemplo realistas.',
      'tutorialTitle': 'Tour guiado de la app',
      'tutorialSkip': 'Saltar el tour',
      'tutorialDone': 'Finalizar el tour',
      'tutorialStepWeekTitle': 'Horario',
      'tutorialStepWeekDesc':
          'Tu día escolar empieza aquí. Cambia de semana y abre clases para ver detalles.',
      'tutorialStepExamsTitle': 'Exámenes y tareas',
      'tutorialStepExamsDesc':
          'Mantén a la vista exámenes y tareas y añade tus propias entradas.',
      'tutorialStepInfoTitle': 'Info escolar',
      'tutorialStepInfoDesc':
          'Los avisos de tu escuela se reúnen en esta sección.',
      'tutorialStepAiTitle': 'Asistente de IA',
      'tutorialStepAiDesc':
          'Pregunta por tu horario, tus tareas y tu día escolar.',
      'tutorialStepSettingsTitle': 'Configuración',
      'tutorialStepSettingsDesc':
          'Ajusta el diseño, las notificaciones, las cuentas y la privacidad.',
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
      'timetableMoreActions': 'Más acciones',
      'timetableExportImage': 'Exportar horario como imagen',
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
      'homeworkFilterAll': 'Todos',
      'homeworkFilterOpen': 'Pendientes',
      'homeworkFilterDone': 'Completados',
      'examsUpcomingCount': '{count} examen(es) próximo(s)',
      'examsUpcomingNext': 'Próximo: {subject} ({date})',
      'gradesTypeSingle': 'Nota individual',
      'gradesDateLabel': 'Fecha',
      'gradesCountLabel': '{count} nota(s)',

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
      'infoAttachments': 'Adjuntos',
      'infoAttachedExtOne': '{ext} adjunto',
      'infoAttachedExtMany': '{ext}s adjuntos',
      'infoAttachedFile': 'Archivo adjunto',
      'infoAttachedFiles': 'Archivos adjuntos',
      'attachmentSave': 'Guardar adjunto',
      'attachmentSaved': 'Adjunto guardado.',
      'attachmentDownloadFailed': 'No se pudo descargar el adjunto.',
      'attachmentDemoUnavailable':
          'Los archivos reales no están disponibles en el modo de demostración.',
      'infoCopyMessage': 'Copiar mensaje',
      'infoMessageCopied': 'Mensaje copiado al portapapeles.',
      'messageComposeTitle': 'Redactar mensaje',
      'messageRecipients': 'Destinatarios',
      'messageRecipientsLoading': 'Cargando destinatarios…',
      'messageRecipientSelect': 'Elegir profesor',
      'messageRecipientsApply': 'Aplicar',
      'messageNoRecipients': 'No se encontraron destinatarios disponibles.',
      'messageRecipientsFailed': 'No se pudieron cargar los destinatarios.',
      'messageSubject': 'Asunto',
      'messageBody': 'Mensaje',
      'messageAttach': 'Adjuntos',
      'messageAttachmentLimit': 'Se permiten como máximo {count} adjuntos.',
      'messageAttachmentTooLarge': '{name} es demasiado grande.',
      'messageDraftAutosave': 'El borrador se guarda automáticamente',
      'messageDiscardDraft': 'Descartar borrador',
      'messageRequiredFields': 'Se requieren destinatario, asunto y mensaje.',
      'messageSend': 'Enviar',
      'messageSending': 'Enviando…',
      'messageSent': 'Mensaje enviado.',
      'messageSendFailed': 'No se pudo enviar el mensaje.',
      'messageDemoUnavailable': 'No se pueden enviar mensajes reales en modo demo.',
      'notificationActionCurrentLesson': 'Clase actual: {lesson}',
      'notificationActionNextLessonLabel': 'Siguiente clase',
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
      'aiClearHistoryTileTitle': 'Borrar historial',
      'aiClearHistoryTileDesc': 'Eliminar todos los chats del dispositivo',
      'aiTyping': 'La IA está escribiendo …',
      'aiChatTitle': 'Tu chat con IA',
      'aiChatSubtitle':
          'Haz preguntas sobre tu vida escolar o simplemente habla con la IA.',
      'aiTryIt': 'Pruébalo:',
      'aiSuggestions': [
        '¿Qué tengo mañana?',
        '¿Tengo una hora libre hoy?',
        '¿A qué hora termina la escuela mañana?',
        '¿Se cancela algo hoy?',
      ],
      'aiChatSuggestions': [
        '¿Cómo puedo mejorar mis notas?',
        'Explícame la teoría de la relatividad de forma sencilla.',
        'Escribe una justificación para educación física.',
      ],
      'aiNoSchoolToday': 'Hoy no hay clase.',
      'aiCurrentLessonSummary':
          'Clase actual: {subject} en el aula {room} (hasta las {end})',
      'aiNoCurrentLesson': 'Ahora mismo no hay ninguna clase.',
      'aiNoNextLessonSchool': 'Siguiente clase: ninguna (hoy no hay clase).',
      'aiNextLessonSummary':
          'Siguiente clase: {subject} en el aula {room} a las {start}',
      'aiNoMoreLessons': 'No hay más clases hoy.',
      'aiDefaultExamType': 'Examen',

      'settingsTitle': 'Configuración',
      'commonSaveChanges': 'Guardar cambios',
      'settingsLoggedInAs': 'Conectado como',
      'settingsLogout': 'Cerrar sesión',
      'settingsSectionQuick': 'Acceso rápido',
      'settingsSectionGeneral': 'Aplicación',
      'settingsAppearance': 'Apariencia',
      'settingsAppearanceDesc': 'Sistema (Claro/Oscuro)',
      'settingsAppearanceSurfaces': 'Superficies',
      'settingsAppearanceMotion': 'Animaciones y efectos',
      'settingsAppearanceTimetable': 'Colores del horario',
      'settingsAppearanceApp': 'Aplicación',
      'settingsVisualTheme': 'Tema de la aplicación',
      'settingsVisualThemeDesc':
          'Cambia colores, formas, tipografía y movimiento en toda la aplicación.',
      'themeDefault': 'Predeterminado',
      'themeDefaultDesc': 'El aspecto conocido de Untis+',
      'themeManga': 'Manga',
      'themeMangaDesc': 'Papel, semitonos y contornos de tinta',
      'themeGlass': 'Cristal',
      'themeGlassDesc': 'Cristal aurora sereno con contraste claro',
      'themeCyber': 'Cyber',
      'themeCyberDesc': 'Superficies técnicas precisas con acentos focalizados',
      'settingsHubNotifications': 'Notificaciones & Widgets',
      'settingsHubDataBackup': 'Datos & Copia de seguridad',
      'settingsHubDataBackupDesc': 'Guardar toda la configuración',
      'settingsHubAccount': 'Cuenta & Demo',
      'settingsHubUpdatesAbout': 'Actualizaciones & Acerca de',
      'settingsSupport': 'Apoyar el desarrollo',
      'settingsSupportDesc': 'Apóyanos en Ko-fi',
      'settingsReportIssue': 'Informar de un problema o compartir una idea',
      'settingsReportIssueDesc': 'Abre los issues de Untis+ en GitHub',
      'settingsLanguage': 'Idioma',
      'settingsSectionAI': 'Asistente IA',
      'settingsAiProvider': 'Proveedor',
      'settingsAiProviderGemini': 'Google Gemini',
      'settingsAiProviderOpenAi': 'OpenAI',
      'settingsAiProviderMistral': 'Mistral AI',
      'settingsAiProviderCustom': 'Proveedor personalizado',
      'settingsAiProviderLocal': 'Local (On-Device)',
      'settingsAiModel': 'Modelo',
      'settingsAiParametersTitle': 'Parámetros',
      'settingsAiParametersDesc': 'Temperatura, límite de tokens y Top P',
      'settingsAiAdjustmentTitle': 'Ajuste',
      'settingsAiPersonaTitle': 'Personalidad',
      'settingsAiPersonaHelpful': 'Asistente útil',
      'settingsAiPersonaStrict': 'Profesor estricto',
      'settingsAiPersonaBuddy': 'Compañero de escuela',
      'settingsAiDataTitle': 'Datos',
      'settingsAiApiKey': 'Clave API',
      'settingsAiApiKeyNotSet': 'No configurado — toca para configurar',
      'settingsAiApiKeyDialogDesc':
          'Necesario para el asistente IA. Usa «Obtener clave API» para abrir la página correcta del proveedor seleccionado.',
      'settingsAiApiKeyGet': 'Obtener clave API',
      'settingsAiApiKeyOpenFailed': 'No se pudo abrir la página de clave API.',
      'settingsAiPrompt': 'Instrucción del sistema',
      'settingsAiPromptDesc':
          'Edita la instrucción predeterminada y usa variables como [timetable].',
      'settingsAiPromptEditTitle': 'Editar instrucción del sistema',
      'settingsAiPromptReset': 'Restablecer',
      'settingsAiPromptVariables': 'Variables de instrucción',
      'settingsAiPromptVariablesDesc':
          'Todos los marcadores de posición reemplazados automáticamente con datos de la app.',
      'settingsAiLocalModel': 'Modelo local',
      'settingsAiLocalModelDesc':
          'Selecciona y descarga un modelo para inferencia en el dispositivo.',
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
      'aiVar_current_lesson': 'Información sobre la clase actual',
      'aiVar_next_lesson': 'Información sobre la siguiente clase',
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
          'Elige el estilo para las transiciones de página y las animaciones opcionales de pestañas principales',
      'settingsUseMaterialYou': 'Material You',
      'settingsUseMaterialYouDesc':
          'Adaptar automáticamente al color de acento del sistema',
      'settingsCustomColorSeed': 'Color personalizado',
      'settingsIsAmoled': 'Pitch Black (AMOLED)',
      'settingsIsAmoledDesc':
          'Fondo negro profundo en modo oscuro para pantallas OLED.',
      'settingsPageTransitionDefault': 'Predeterminado',
      'settingsPageTransitionBounce': 'Resorte',
      'settingsPageTransitionFade': 'Fundido suave',
      'settingsPageTransitionSlide': 'Eje compartido',
      'settingsPageTransitionZoom': 'Zoom focal',
      'settingsPageTransitionBlur': 'Desenfoque focal',
      'settingsPageTransitionEaseIn': 'Elevación',
      'settingsPageTransitionEaseOut': 'Deriva',
      'settingsPageTransitionExpo': 'Subida Expo',
      'settingsMainTabFadeUp': 'Animaciones de pestañas principales',
      'settingsMainTabFadeUpDesc':
          'Anima los cambios de pestaña principal con la transición elegida arriba. Desactivado = cambio inmediato.',
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
      'settingsTimetableSwitchAnimation': 'Animación de cambio',
      'settingsTimetableSwitchAnimationDesc':
          'Animación usada al cambiar entre días y semanas del horario.',
      'settingsTimetableSwitchAnimationDefault': 'Predeterminada',
      'settingsTimetableSwitchAnimationMaterial': 'Material 3 Carousel',
      'settingsTimetableSwitchAnimationDepth': 'Profundidad y fundido',
      'settingsShowCancelled': 'Mostrar clases canceladas',
      'settingsShowCancelledDesc':
          'Las clases canceladas se muestran en el horario',
      'settingsCancelledColor': 'Color cancelado',
      'settingsCancelledColorDesc':
          'Personalizar el color de las clases canceladas',
      'settingsLessonDesignTitle': 'Diseño de clases y tarjetas',
      'settingsLessonDesignDesc':
          'Personaliza el estilo, desenfoque y los detalles.',
      'settingsLessonStyle': 'Estilo de tarjeta',
      'settingsLessonStyleDesc': 'Elige la estética visual de las clases.',
      'settingsLessonStyleModern': 'Moderno (Tintado)',
      'settingsLessonStyleGlass': 'Efecto cristal (Glass)',
      'settingsLessonStyleGradient': 'Degradado',
      'settingsLessonStyleOutline': 'Contorno / Minimal',
      'settingsLessonStyleSolid': 'Sólido',
      'settingsLessonBlur': 'Desenfoque de cristal',
      'settingsLessonBlurDesc':
          'Desenfoca el fondo detrás de las tarjetas de clase.',
      'settingsLessonBlurAmount': 'Intensidad del desenfoque',
      'settingsLessonCardOpacity': 'Opacidad de tarjeta',
      'settingsLessonBorderRadius': 'Radio de esquinas',
      'settingsLessonAccentStyle': 'Barra de acento',
      'settingsLessonAccentBar': 'Barra clásica',
      'settingsLessonAccentThin': 'Línea fina',
      'settingsLessonAccentDot': 'Punto indicador',
      'settingsLessonAccentNone': 'Ninguna',
      'settingsLessonShowTeacher': 'Mostrar profesor',
      'settingsLessonShowTeacherDesc':
          'Mostrar nombre o iniciales del profesor en la tarjeta.',
      'settingsLessonShowSubjectIcons': 'Mostrar iconos de asignaturas',
      'settingsLessonShowSubjectIconsDesc':
          'Muestra iconos adecuados junto a las asignaturas del horario.',
      'settingsLessonShowRoom': 'Mostrar aula',
      'settingsLessonShowRoomDesc': 'Mostrar número de aula en la tarjeta.',
      'settingsLessonCompactMode': 'Modo compacto',
      'settingsLessonCompactModeDesc':
          'Espaciado reducido para mayor densidad.',
      'settingsLessonDimPast': 'Atenuar clases pasadas',
      'settingsLessonDimPastDesc':
          'Atenuar y poner en escala de grises las clases finalizadas.',
      'settingsLessonCancelledPattern': 'Rayado de cancelación',
      'settingsLessonCancelledPatternDesc':
          'Muestra un patrón de rayas diagonales si la clase se cancela.',
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
      'settingsSurfaceBlur': 'Desenfoque de superficies',
      'settingsSurfaceBlurDesc':
          'Desenfoca tarjetas y superficies normales. Cuando el efecto de desenfoque está activo, también se desenfocan los fondos de diálogos, hojas inferiores y tutoriales.',
      'settingsSurfaceCorners': 'Esquinas de superficies',
      'settingsSurfaceCornersDesc':
          'Controla cuánto se redondean las tarjetas y superficies normales.',
      'settingsSurfaceCornersCurrent': 'Actual',
      'settingsSurfaceCornersSharper': 'Más cuadrado',
      'settingsSurfaceCornersCustom': 'Personalizado',
      'settingsSurfaceCornerRadius': 'Radio de esquina',
      'settingsGlowEffects': 'Efectos de brillo',
      'settingsGlowEffectsDesc':
          'Halos de color alrededor de clases, tareas, notas e iconos',
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
      'settingsSectionCredits': 'Créditos',
      'settingsCreditsDevelopers': 'Desarrolladores',
      'settingsCreditsDeveloper': 'Desarrollador',
      'settingsCreditsFounderDeveloper': 'Fundador y desarrollador',
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
      'settingsGithubDownloading': 'Descargando actualización…',
      'settingsGithubDownloadCancel': 'Cancelar descarga',
      'settingsGithubDownloadCancelled': 'Descarga de actualización cancelada.',
      'settingsGithubDownloadFailed': 'No se pudo descargar la actualización.',
      'settingsGithubNoCompatibleAndroidApk':
          'No hay ningún APK Android para la arquitectura de este dispositivo.',
      'settingsGithubInstallPermissionRequired':
          'Permite a Untis+ instalar aplicaciones desconocidas y vuelve a iniciar la instalación.',
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
      'settingsGithubInstallerOpened':
          'Se abrió el aviso de instalación del sistema.',
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
      'changelogNoData': '# No hay datos disponibles',
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

      'aiNewChat': 'Nuevo chat',
      'aiParameterTemperature': 'Temperatura',
      'aiParameterMaxTokens': 'Máx. tokens',
      'aiParameterTopP': 'Top P',
      'aiOrbsCount': '{count} orbes',
      'aiNoiseLevel': '{pct}% ruido',
      'aiGradientType': 'Degradado',

      'navGrades': 'Notas',
      'gradesTitle': 'Seguimiento de notas',
      'gradesAddTitle': 'Añadir nota',
      'gradesEditTitle': 'Editar nota',
      'gradesSubjectLabel': 'Asignatura',
      'gradesGradeLabel': 'Nota',
      'gradesWeightLabel': 'Peso',
      'gradesTypeLabel': 'Tipo',
      'homeworkAddDesc': 'Gestionar tareas y entregas',
      'examsAddDesc': 'Programar próximos exámenes',
      'gradesAverage': 'Promedio',
      'gradesNone': 'Sin notas',
      'gradesNoneHint': 'Toca + para añadir tu primera nota.',

      'ui_tempEditTitle': 'Editar clase temporalmente',
      'ui_absence': 'Cancelada',
      'ui_reset': 'Restablecer',
      'ui_cancel': 'Cancelar',
      'ui_localSave': 'Guardar solo localmente',
      'ui_timetableImageSaved': 'Imagen del horario guardada',
      'ui_imageExportFailed': 'No se pudo exportar la imagen',
      'ui_homeworkManaged': 'Esta tarea está gestionada por Untis.',
      'ui_start': 'Inicio',
      'ui_notifications': 'Notificaciones',
      'ui_accountRemoveQuestion': '¿Eliminar la cuenta?',
      'ui_accountRemoveDesc':
          'La cuenta solo se elimina de este dispositivo. El resto de ajustes se conserva.',
      'ui_accountRemove': 'Eliminar',
      'ui_accountRemoveThis': 'Eliminar esta cuenta',
      'ui_accountSignOut': 'Cerrar sesión en este dispositivo',
      'ui_accounts': 'Cuentas',
      'ui_accountAdd': 'Añadir cuenta',
      'ui_accountConnect': 'Conectar otra cuenta de WebUntis',
      'ui_alarmApply': 'Aplicar',
      'ui_alarmOwn': 'Alarma personalizada',
      'ui_alarmTime': 'Hora de la alarma',
      'ui_alarmActive': 'Activa',
      'ui_alarmInactive': 'Desactivada',
      'ui_alarmDelete': 'Eliminar',
      'ui_alarmSave': 'Guardar',
      'ui_alarmTitle': 'Alarmas',
      'ui_alarmReady': 'Estado de las alarmas',
      'ui_alarmReadyYes': 'Listo para alarmas fiables',
      'ui_alarmReadyNo': 'Faltan permisos de Android',
      'ui_alarmReadyDescYes':
          'Las alarmas exactas, pantalla completa y No molestar están activas.',
      'ui_alarmReadyDescNo': 'Abre los ajustes del sistema Android que faltan.',
      'ui_alarmExact': 'Permitir alarmas exactas',
      'ui_alarmExactDesc': 'Necesario para que Android no retrase la alarma.',
      'ui_alarmNotifications': 'Permitir notificaciones',
      'ui_alarmNotificationsDesc':
          'Necesario para la alarma visible a pantalla completa.',
      'ui_alarmFullscreen': 'Permitir alarmas a pantalla completa',
      'ui_alarmFullscreenDesc': 'Muestra la alarma en la pantalla de bloqueo.',
      'ui_alarmDnd': 'Ignorar No molestar',
      'ui_alarmDndDesc':
          'Permite que las alarmas activas suenen aunque esté activado No molestar.',
      'ui_alarmSmart': 'Alarma inteligente',
      'ui_alarmSchedule': 'Alarma del horario',
      'ui_alarmAt': '{label} a las {time}',
      'ui_alarmScheduleDesc':
          'Te despierta antes de la primera clase no cancelada.',
      'ui_alarmLead': 'Antelación',
      'ui_alarmLeadValue': '{n} min antes de la primera clase',
      'ui_alarmLeadByStart': 'Margen por hora de inicio',
      'ui_alarmLeadByStartDesc': 'Configura otro margen o ninguna alarma para determinadas primeras clases.',
      'ui_alarmLeadByStartAdd': 'Añadir hora de inicio',
      'ui_alarmLeadByStartOff': 'Sin alarma',
      'ui_alarmLeadByStartDefault': 'Usar el margen predeterminado',
      'ui_alarmUpdate': 'Actualizar poco antes de la alarma',
      'ui_alarmUpdateDesc': 'WebUntis se comprueba de nuevo 15 minutos antes.',
      'ui_alarmRing': 'Sonido',
      'ui_alarmSnooze': 'Posponer',
      'ui_alarmSnoozeDesc': 'min · desliza a la izquierda',
      'ui_alarmSnoozeValue': '{n} min · desliza a la izquierda',
      'ui_alarmSnoozeDuration': 'Duración de la repetición',
      'ui_alarmRingtone': 'Tono de alarma',
      'ui_alarmSystemTone': 'Tono de alarma del sistema Android',
      'ui_alarmSelectedTone': 'Tono de alarma de Android seleccionado',
      'ui_alarmOwnAlarms': 'Alarmas personalizadas',
      'ui_alarmAdd': 'Añadir alarma',
      'ui_alarmAddDesc': 'Se repite en los días seleccionados.',
      'ui_alarmHeadsUp': 'Recordar antes de la alarma',
      'ui_alarmHeadsUpValue': '{n} min antes',
      'ui_alarmHeadsUpDesc':
          'Primero se vuelve a comprobar el día actual con WebUntis.',
      'ui_alarmEarlier': 'Hacer sonar antes la próxima alarma',
      'ui_alarmEarlierValue': '{n} min antes',
      'ui_alarmEarlierDesc': 'Solo se aplica a la próxima alarma del horario.',
      'ui_alarmDateActions': 'Alarma para {date}',
      'ui_alarmDateActionsDesc': 'Esta excepción solo se aplica a este día de clase.',
      'ui_alarmDisableDate': 'Desactivar alarma este día',
      'ui_alarmCustomTime': 'Hora de alarma personalizada',
      'ui_alarmClearDate': 'Restablecer excepción',
      'ui_alarmDateDisabled': 'Desactivada este día',
      'ui_alarmDateCustom': 'Hora personalizada: {time}',
      'ui_alarmDateEarlier': '{n} min antes',
      'ui_widgets': 'Widgets',
      'ui_widgetPreview': 'Vista previa',
      'ui_widgetPreviewTitle': 'Widgets y vista previa',
      'ui_widgetRefresh': 'Actualizar vista previa',
      'ui_widgetChoose': 'Elegir widget',
      'ui_widgetOwn': 'Widgets personalizados',
      'ui_widgetEditorOpen': 'Abrir editor de widgets',
      'ui_widgetEditorDesc':
          'Combina libremente contenido, orden, colores, transparencia y diseño.',
      'ui_widgetAccount': 'Cuenta para la vista previa',
      'ui_widgetNoAccount': 'No hay ninguna cuenta disponible',
      'ui_widgetAddAccountFirst': 'Añade primero una cuenta de WebUntis.',
      'ui_widgetHome': 'A la pantalla de inicio',
      'ui_widgetHomeUnavailable': 'No disponible en este dispositivo',
      'ui_widgetHomeSupported':
          'Los widgets de inicio son compatibles con Android e iOS.',
      'ui_widgetHoldHome': 'Mantén pulsada la pantalla de inicio',
      'ui_widgetHoldHomeDesc':
          'Después toca «Editar» arriba y «Añadir widget».',
      'ui_widgetSelectUntis': 'Seleccionar Untis+',
      'ui_widgetSelectUntisDesc': 'Elige la variante y el tamaño deseados.',
      'ui_widgetSetAccount': 'Definir cuenta',
      'ui_widgetSetAccountDesc':
          'Mantén pulsado el widget y elige «Editar widget».',
      'ui_widgetAdd': 'Añadir widget',
      'ui_widgetPickerOpening': 'Abriendo selector de widgets…',
      'ui_widgetPickerSent':
          'Solicitud de widget enviada a la pantalla de inicio.',
      'ui_widgetPickerHint':
          'Abre el selector de widgets desde la pantalla de inicio.',
      'ui_widgetPickerFailed':
          'No se pudo añadir el widget. Abre el selector desde la pantalla de inicio.',
      'ui_widgetSyncedPreview':
          'La vista previa usa los últimos datos sincronizados para esta cuenta.',
      'ui_widgetOpenTimetable':
          'Abre el horario una vez para sincronizar datos reales del widget.',
      'ui_editor': 'Editor de widgets',
      'ui_editorYourWidgets': 'Tus widgets',
      'ui_editorNew': 'Nuevo',
      'ui_editorDuplicate': 'Duplicar',
      'ui_editorContentLayout': 'Contenido y diseño',
      'ui_editorName': 'Nombre',
      'ui_editorCompact': 'Compacto',
      'ui_editorStacked': 'Apilado',
      'ui_editorTimeline': 'Línea de tiempo',
      'ui_editorDesign': 'Diseño',
      'ui_editorBackground': 'Fondo',
      'ui_editorAccent': 'Acento',
      'ui_editorText': 'Texto',
      'ui_editorShowIcons': 'Mostrar iconos',
      'ui_editorApplyColor': 'Aplicar color',
      'ui_editorTransparency': 'Transparencia',
      'ui_editorRounding': 'Redondeado',
      'ui_editorFontSize': 'Tamaño del texto',
      'ui_colorRed': 'Rojo',
      'ui_colorGreen': 'Verde',
      'ui_colorBlue': 'Azul',
      'ui_blockCurrent': 'Clase actual',
      'ui_blockNext': 'Próxima clase',
      'ui_blockSchedule': 'Plan del día',
      'ui_blockHomework': 'Tareas',
      'ui_blockExams': 'Exámenes',
      'ui_blockNotices': 'Notificaciones',
      'ui_blockAccount': 'Cuenta',
      'ui_blockStatus': 'Estado',
      'ui_previewCurrent': 'Ahora: Matemáticas',
      'ui_previewNext': 'Después: Inglés · Aula 204',
      'ui_previewSchedule': '08:00 Matemáticas\n09:45 Inglés\n11:30 Biología',
      'ui_previewHomework': '2 tareas pendientes',
      'ui_previewExams': 'Próximo examen: viernes',
      'ui_previewNotices': 'Nuevas notificaciones',
      'ui_previewStatus': 'Actualizado a las 12:30',
      'ui_appearanceAppIcon': 'Icono de la aplicación',
      'ui_notificationsWidgets': 'Widgets y vista previa',
      'ui_notificationsWidgetsDesc':
          'Variantes, vista previa y asignación de cuenta.',
      'ui_notificationsAlarms': 'Alarmas y alarmas inteligentes',
      'ui_tempEditDesc':
          'Este cambio no se enviará a Untis y se descartará al volver a cargar.',
      'ui_subject': 'Asignatura',
      'ui_teacher': 'Profesor',
      'ui_room': 'Aula',
      'ui_saveTimetableImage': 'Guardar imagen del horario',
      'ui_widgetAndroidDialogDesc':
          'La cuenta seleccionada aparece preseleccionada en el diálogo de Android. Puedes cambiarla antes de añadir el widget.',
      'ui_widgetCurrent': 'Ahora',
      'ui_widgetCurrentDesc': 'Clase actual, próxima clase y tiempo restante',
      'ui_widgetSchedule': 'Plan del día',
      'ui_widgetScheduleDesc': 'Las próximas entradas de tu horario de hoy',
      'ui_widgetHomework': 'Tareas',
      'ui_widgetHomeworkDesc': 'Un resumen compacto de tus tareas pendientes',
      'ui_widgetNotices': 'Notificaciones',
      'ui_widgetNoticesDesc':
          'Las últimas notificaciones en tu pantalla de inicio',
      'ui_widgetSmallMedium': 'Pequeño o mediano',
      'ui_widgetMediumLarge': 'Mediano o grande',
      'ui_widgetToday': 'HOY',
      'ui_widgetNoScheduleData': 'Aún no hay datos del día',
      'ui_widgetNoOpenHomework': 'No hay tareas pendientes sincronizadas',
      'ui_widgetNoNotices': 'No hay notificaciones sincronizadas',
      'ui_widgetNoCurrentLesson': 'No hay clase actual',
      'ui_widgetNotSynced': 'Aún no sincronizado',
      'ui_widgetLoading': 'CARGANDO',
      'ui_widgetCurrentStatus': 'ACTUAL',
      'ui_widgetPreviewStatus': 'VISTA PREVIA',
      'ui_widgetTimetableDetail': 'Abre el horario para cargar datos',
      'ui_alarmMinutesSuffix': ' min',
      'ui_editorDefaultName': 'Mi widget',
      'ui_editorNewWidget': 'Widget nuevo',
      'ui_editorCopySuffix': 'copia',
      'ui_widgetMinutesRemaining': '{n} min restantes',
      'ui_widgetNoUpcomingExams': 'No hay exámenes próximos',
      'ui_widgetExam': 'Examen',
      'ui_widgetLesson': 'Clase',
      'ui_widgetHomeworkItem': 'Tarea',
      'ui_widgetNext': 'Siguiente: {title}',
      'ui_widgetNoLessonsToday': 'No hay clases hoy',
      'ui_widgetOpenNotifications': 'Abrir nuevas notificaciones en Untis+',
      'ui_notificationsNone': 'No hay notificaciones nuevas',
      'ui_appearanceIconChoose': 'Elegir icono de la pantalla de inicio',
      'ui_appearanceIconAndroidOnly': 'Disponible actualmente en Android',
      'ui_nativeAlarmReminderChannel': 'Recordatorios de alarma de Untis+',
      'ui_nativeAlarmReminderChannelDesc': 'Avisos antes de una alarma de Untis+',
      'ui_nativeAlarmChannel': 'Alarmas de Untis+',
      'ui_nativeAlarmChannelDesc': 'Alarmas de Untis+ sonando',
      'ui_nativeAlarmRefreshChannel': 'Actualización de alarma de Untis+',
      'ui_nativeAlarmReminderTitle': 'Alarma en {minutes} minutos',
      'ui_nativeAlarmDisableToday': 'Desactivar hoy',
      'ui_nativeAlarmTitle': 'Alarma',
      'ui_nativeAlarmSwipeHint': 'Desliza a la izquierda para posponer y a la derecha para apagar',
      'ui_nativeAlarmSnooze': 'Posponer · {minutes} min',
      'ui_nativeAlarmDismiss': 'Apagar',
      'ui_nativeAlarmRefreshing': 'Actualizando alarma',
      'ui_nativeAlarmStatusActive': 'Alarma activa',
      'ui_nativeAlarmStatusSnoozing': 'Pospuesta',
      'ui_nativeAlarmTimeAccessibility': 'Hora de la alarma {time}',
      'ui_nativeWidgetSetupTitle': 'Configurar widget',
      'ui_nativeWidgetSetupAccount': 'Cuenta de este widget',
      'ui_nativeWidgetSetupProfile': 'Perfil del widget',
      'ui_nativeWidgetSetupProfileHint': 'Perfil del editor de widgets',
      'ui_nativeWidgetSetupNoProfile': 'Primero crea un perfil en el editor de widgets de Untis+.',
      'ui_nativeWidgetSetupNoAccount': 'Abre Untis+ y añade primero una cuenta.',
      'ui_nativeWidgetRefreshing': 'Actualizando…',
      'ui_refreshing': 'Actualizando',
      'ui_copyMessage': 'Copiar mensaje',
      'ui_aiAttachmentTooLarge': 'Los adjuntos no pueden superar los 8 MB.',
      'ui_aiAttachFile': 'Adjuntar archivo',
      'ui_aiAttachmentText': '\\n\\nArchivo {name}:\\n{excerpt}',
      'ui_aiAttachmentUnsupported': 'Este proveedor no puede leer el archivo adjunto {name} ({mimeType}).',
      'ui_aiFileKindPdf': ' o PDF',
      'ui_aiHomeworkVisionPrompt': 'Extraes deberes de pizarras, hojas de trabajo y notas.\\nExtrae todas las tareas de la imagen adjunta{fileKind}.\\nResponde SOLO con este formato de matriz JSON (sin bloque Markdown, solo JSON):\\n[\\n  {\\n    "subject": "Matemáticas",\\n    "text": "Página 42, ejercicios 1–5",\\n    "dueDate": "20260905"\\n  }\\n]\\nIMPORTANTE: La fecha DEBE ser una cadena YYYYMMDD. Deduce un año o una fecha faltante si es posible. Si el archivo no contiene deberes, devuelve una matriz vacía [].',
      'ui_aiExamVisionPrompt': 'Extraes calendarios de exámenes escolares de forma estructurada.\\nExtrae todos los exámenes relevantes de la imagen adjunta{fileKind}.\\nResponde SOLO con este formato de matriz JSON (sin bloque Markdown, solo JSON y sin saludo):\\n[\\n  {\\n    "subject": "Matemáticas",\\n    "examType": "Examen",\\n    "date": "20240325",\\n    "description": "Información adicional o cadena vacía"\\n  }\\n]\\nIMPORTANTE: La fecha DEBE ser una cadena YYYYMMDD. Deduce el año que falte a partir del año actual ({year}). Si el archivo no contiene exámenes, devuelve una matriz vacía [].',
      'ui_aiExamJsonSystemPrompt': 'Extrae datos estructurados de exámenes y responde solo con JSON.',
      'ui_aiExamImageSystemPrompt': 'Extrae datos estructurados de exámenes de la imagen. Responde solo como una matriz JSON.',
      'ui_aiResponseFormat': 'FORMATO DE RESPUESTA:\\n- Responde de forma breve y visual.\\n- Prefiere un objeto JSON con headline, summary, tags, metrics y lessons.\\n- metrics es una lista de objetos con label y value.\\n- lessons es una lista de objetos con subject, subjectShort, room, teacher, time y status.\\n- Evita textos largos.\\n- IMPORTANTE: Incluye SOLO los campos relevantes para la pregunta. Omite metrics o lessons, o usa matrices vacías, cuando no se soliciten.',
      'ui_bgUpdateTitle': 'Actualización de Untis+ disponible',
      'ui_bgUpdateBody': 'La versión {version} está disponible en las versiones de GitHub.',
      'ui_bgDailyBriefingTitle': 'Resumen de tu día escolar',
      'ui_bgDailyBriefingBody': '{start}–{end}, {lessons} clases, {breaks} descansos',
      'ui_bgDailyBriefingExpanded': 'Inicio: {start}\\nFin: {end}\\nClases: {lessons}\\nDescansos: {breaks}\\nSiguiente: {next}',
      'ui_bgChangesTitle': 'Horario actualizado',
      'ui_bgChangesBody': 'Hay cambios nuevos hoy. Toca para abrir tu horario.',
      'ui_bgCurrentLesson': 'Clase actual',
      'ui_bgNextLesson': 'Siguiente clase',
      'ui_bgNoClasses': 'No hay más clases',
      'ui_bgLessonStarts': 'Empieza a las {time}',
      'ui_bgUntil': 'Hasta las {time}',
      'ui_bgThen': 'Luego: {lesson}',
      'ui_bgFinished': 'Fin',
      'ui_bgFreePeriod': 'Hora libre',
      'ui_bgFallbackLesson': 'Clase {start}–{end}',
      'ui_bgDemoLesson': 'Clase de demostración {code}',
      'ui_bgChangesCancelled': '{count} cancelaciones',
      'ui_bgChangesRoom': '{count} cambios de aula',
      'ui_bgChangesSubstitution': '{count} sustituciones',
      'ui_bgChangesOther': '{count} cambios',
      'ui_widgetSystemColors': 'Material You',
      'ui_widgetCustomColors': 'Colores personalizados',
      'ui_aiActionCreateHomework': 'Crear tarea: {subject} · {text}',
      'ui_aiActionUpdateHomework': 'Editar tarea: {subject} · {text}',
      'ui_aiActionDeleteHomework': 'Eliminar tarea: {id}',
      'ui_aiActionCompleteHomework': 'Marcar tarea como completada: {id}',
      'ui_aiActionCreateExam': 'Crear examen: {subject} · {text}',
      'ui_aiActionUpdateExam': 'Editar examen: {subject} · {text}',
      'ui_aiActionDeleteExam': 'Eliminar examen: {id}',
      'ui_aiActionCreateGrade': 'Crear nota: {subject} · {value}',
      'ui_aiActionUpdateGrade': 'Editar nota: {subject} · {value}',
      'ui_aiActionDeleteGrade': 'Eliminar nota: {id}',
      'ui_aiActionUnknown': 'Acción desconocida',
      'ui_aiParametersTitle': 'Parámetros de IA',
      'ui_aiPersonaStrict': 'Responde como un profesor estricto pero justo. Presta atención a la disciplina y al orden.',
      'ui_aiPersonaBuddy': 'Responde como un compañero relajado, con un lenguaje juvenil y natural.',
      'ui_aiPersonaHelpful': 'Responde de forma amable, profesional y útil.',
      'ui_aiAssistantIntro': 'Eres un asistente útil para la aplicación de horario Untis+.',
      'ui_aiAssistantRules': 'Responde de forma natural y amable en el chat. Puedes acceder al horario y a los exámenes del usuario de arriba. Usa Markdown para un formato claro. Responde en lenguaje natural, nunca en JSON salvo que se solicite expresamente. Sé conciso y preciso, y no te presentes. Para un cambio local solicitado, añade un bloque independiente con este formato exacto: ```untis-action {"kind":"create_homework|update_homework|delete_homework|complete_homework|create_exam|update_exam|delete_exam|create_grade|update_grade|delete_grade","id":"optional id","subject":"subject","text":"text","dueDate":"YYYYMMDD","value":"optional grade","weight":"optional weight","type":"optional type"} ```. Propón solo cambios seguros y concretos; se aplican únicamente tras una confirmación explícita. Nunca afirmes que se hizo un cambio sin proponer ese bloque y recibir la confirmación.',
      'ui_aiDayDataUnavailable': '{date}: los datos del horario de este día aún no se han cargado.',
      'ui_aiWeekDataUnavailable': 'La semana del horario correspondiente a {date} aún no se ha cargado, así que no voy a adivinar.',
      'ui_aiNoScheduledLessons': 'No hay clases no canceladas previstas para {date}.',
      'ui_aiScheduleReply': 'Sí. El {date} tienes: {lessons}.',
      'ui_aiApplyChangesTitle': 'Confirmar cambios',
      'ui_aiApplyChangesDesc': 'El asistente ha propuesto estos cambios locales:',
      'ui_aiChangesApplied': 'Cambios aplicados.',
      'ui_apply': 'Aplicar',
      'ui_aiParametersDesc': 'Ajusta las respuestas del modelo.',
      'ui_aiTemperatureDesc':
          'Los valores altos hacen las respuestas más creativas; los bajos, más precisas.',
      'ui_aiTokenDesc': 'Longitud máxima de una respuesta.',
      'ui_aiTopPDesc':
          'Muestreo de núcleo para limitar la selección de palabras.',
      'ui_notificationsDenied':
          'Las notificaciones no están permitidas en los ajustes del sistema.',
      'ui_notificationsAlarmsDesc':
          'Alarmas exactas de Android que se adaptan a las cancelaciones.',
      'ui_editorAddWidget': 'Añadir este widget',
      'ui_editorIosHint':
          'Añade Untis+ con el selector de widgets de iOS y elige después este perfil en «Editar widget».',

      'homeworkAddTitle': 'Añadir tarea',
      'homeworkEditTitle': 'Editar tarea',
      'homeworkSubjectLabel': 'Asignatura / Título *',
      'homeworkTaskLabel': 'Tarea / Descripción',
      'homeworkDueDateLabel': 'Para el día',
      'homeworkActionCustom': 'Añadir manualmente',
      'homeworkActionImport': 'Escanear con IA',
      'homeworkSave': 'Guardar',
      'homeworkDelete': 'Eliminar',
      'homeworkCancel': 'Cancelar',
      'homeworkImportTitle': 'Escanear tarea',
      'homeworkImportSuccess': '¡Tareas escaneadas con éxito!',
      'homeworkImportError': 'Error al escanear las tareas: ',
      'subjectOverviewTitle': 'Resumen de la asignatura',
      'addGradeForSubject': '+ Nota',
      'addExamForSubject': '+ Examen',
      'addHomeworkForSubject': '+ Tarea',
      'noGradesForSubject': 'No hay notas registradas para esta asignatura.',
      'noExamsForSubject': 'No hay exámenes programados para esta asignatura.',
      'noHomeworkForSubject': 'No hay tareas pendientes para esta asignatura.',
    },
  };
}
