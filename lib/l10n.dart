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
  String get navExams => _t('navExams');
  String get navInfo => _t('navInfo');
  String get navMenu => _t('navMenu');

  // ── Login ───────────────────────────────────────────────────────────────────
  String get loginServer => _t('loginServer');
  String get loginSchool => _t('loginSchool');
  String get loginUsername => _t('loginUsername');
  String get loginPassword => _t('loginPassword');
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
  String get detailLesson => _t('detailLesson');
  String get detailInfo => _t('detailInfo');
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
  String get examsOwn => _t('examsOwn');
  String get examsUnknown => _t('examsUnknown');
  String get examsImportTitle => _t('examsImportTitle');
  String get examsImportCamera => _t('examsImportCamera');
  String get examsImportGallery => _t('examsImportGallery');
  String get examsImportFile => _t('examsImportFile');
  String get examsImportSuccess => _t('examsImportSuccess');
  String get examsImportError => _t('examsImportError');
  String examsInDays(int n) => _t('examsDaysIn').replaceAll('{n}', '$n');

  // ── School Info / Notifications ────────────────────────────────────────────
  String get infoTitle => _t('infoTitle');
  String get infoReload => _t('infoReload');
  String get infoUpdated => _t('infoUpdated');
  String get infoEmpty => _t('infoEmpty');
  String get infoEmptyHint => _t('infoEmptyHint');
  String get infoFetchError => _t('infoFetchError');
  String get infoOpenLink => _t('infoOpenLink');

  // ── AI Chat ─────────────────────────────────────────────────────────────────
  String get aiTitle => _t('aiTitle');
  String get aiInputHint => _t('aiInputHint');
  String get aiKnowsSchedule => _t('aiKnowsSchedule');
  String get aiAskAnything => _t('aiAskAnything');
  String get aiNoApiKey => _t('aiNoApiKey');
  String get aiNoReply => _t('aiNoReply');
  String get aiApiError => _t('aiApiError');
  String get aiConnectionError => _t('aiConnectionError');
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
  String get settingsLanguage => _t('settingsLanguage');
  String get settingsSectionAI => _t('settingsSectionAI');
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
  String get settingsBackgroundAnimations => _t('settingsBackgroundAnimations');
  String get settingsBackgroundAnimationsDesc =>
      _t('settingsBackgroundAnimationsDesc');
  String get settingsBackgroundStyle => _t('settingsBackgroundStyle');
  String get settingsBackgroundStyleOrbs => _t('settingsBackgroundStyleOrbs');
  String get settingsBackgroundStyleSpace => _t('settingsBackgroundStyleSpace');
  String get settingsBackgroundStyleBubbles =>
      _t('settingsBackgroundStyleBubbles');
  String get settingsBackgroundStyleLines => _t('settingsBackgroundStyleLines');
  String get settingsBackgroundStyleThreeD =>
      _t('settingsBackgroundStyleThreeD');
  String get settingsBackgroundStyleAurora =>
      _t('settingsBackgroundStyleAurora');
  String get settingsGlassEffect => _t('settingsGlassEffect');
  String get settingsGlassEffectDesc => _t('settingsGlassEffectDesc');
  String get settingsProgressivePush => _t('settingsProgressivePush');
  String get settingsProgressivePushDesc => _t('settingsProgressivePushDesc');
  String get settingsRefreshPushWidgetNow => _t('settingsRefreshPushWidgetNow');
  String get settingsRefreshPushWidgetNowDesc =>
      _t('settingsRefreshPushWidgetNowDesc');
  String get settingsBackgroundLoading => _t('settingsBackgroundLoading');
  String get settingsSectionUpdates => _t('settingsSectionUpdates');
  String get settingsSectionAbout => _t('settingsSectionAbout');
  String get settingsAppVersion => _t('settingsAppVersion');
  String get settingsSectionSubjects => _t('settingsSectionSubjects');
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
  String get settingsGithubOpenReleasePage =>
      _t('settingsGithubOpenReleasePage');

  // ── AI System Prompt ─────────────────────────────────────────────────────────
  String get aiSystemPersona => _t('aiSystemPersona');
  String get aiSystemRules => _t('aiSystemRules');

  // ─────────────────────────────────────────────────────────────────────────────
  static const Map<String, Map<String, dynamic>> _strings = {
    // ── GERMAN ────────────────────────────────────────────────────────────────
    'de': {
      'navWeek': 'Woche',
      'navExams': 'Prüfungen',
      'navInfo': 'Info',
      'navMenu': 'Menü',

      'loginServer': 'Server URL',
      'loginSchool': 'Schule',
      'loginUsername': 'Benutzername',
      'loginPassword': 'Passwort',
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
          'Verfolge deinen Lernstand und kommende Prüfungen.',
      'onboardingFeatureAiTitle': 'KI-Assistent',
      'onboardingFeatureAiDesc':
          'Frag Gemini nach deinem Tag, Hausaufgaben oder Prüfungen.',
      'onboardingFeatureNotifyTitle': 'Benachrichtigungen & Widgets',
      'onboardingFeatureNotifyDesc':
          'Bleib auf dem Laufenden, bevor die Schule startet.',
      'onboardingFinishSetup': 'Einrichtung abschließen',

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
      'detailLesson': 'Stunde',
      'detailInfo': 'Hinweis',
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
      'examsImportTitle': 'Klausurplan hochladen',
      'examsImportCamera': 'Kamera',
      'examsImportGallery': 'Galerie',
      'examsImportFile': 'PDF / Datei',
      'examsImportSuccess': 'Erfolgreich importiert!',
      'examsImportError': 'Fehler beim Import: ',

      'infoTitle': 'Schulinfos',
      'infoReload': 'Neu laden',
      'infoUpdated': 'Aktualisiert',
      'infoEmpty': 'Keine aktuellen Benachrichtigungen',
      'infoEmptyHint':
          'Falls deine Schule derzeit nichts veröffentlicht hat, erscheint hier keine Meldung.',
      'infoFetchError':
          'Benachrichtigungen konnten nicht geladen werden. Bitte später erneut versuchen.',
      'infoOpenLink': 'Link öffnen',

      'aiTitle': 'KI-Assistent',
      'aiInputHint': 'Frage stellen…',
      'aiKnowsSchedule': 'Ich kenne deinen Stundenplan!',
      'aiAskAnything': 'Frag mich alles über deine Woche.',
      'aiNoApiKey':
          '⚠️ Bitte trage deinen Gemini API-Schlüssel unter Einstellungen → Allgemein ein.',
      'aiNoReply': '⚠️ Keine Antwort erhalten.',
      'aiApiError': '⚠️ API-Fehler:',
      'aiConnectionError': '⚠️ Verbindungsfehler:',
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
      'settingsLanguage': 'Sprache',
      'settingsSectionAI': 'KI-Assistent',
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
      'settingsBackgroundAnimations': 'Hintergrundanimationen',
      'settingsBackgroundAnimationsDesc':
          'Animierte Farbverläufe im Hintergrund anzeigen',
      'settingsBackgroundStyle': 'Animationsstil',
      'settingsBackgroundStyleOrbs': 'Orbs',
      'settingsBackgroundStyleSpace': 'Space',
      'settingsBackgroundStyleBubbles': 'Blasen',
      'settingsBackgroundStyleLines': 'Linien',
      'settingsBackgroundStyleThreeD': '3D-Formen',
      'settingsBackgroundStyleAurora': 'Aurora',
      'settingsGlassEffect': 'Glaseffekt (Blur)',
      'settingsGlassEffectDesc':
          'Aktiviert weiche Glas-/Unschärfeeffekte in der Oberfläche',
      'settingsProgressivePush': 'Progressive Push-Benachrichtigung',
      'settingsProgressivePushDesc':
          'Aktuelle Stunde als dauerhafte Benachrichtigung anzeigen',
      'settingsRefreshPushWidgetNow': 'Push & Widget jetzt aktualisieren',
      'settingsRefreshPushWidgetNowDesc':
          'Lädt sofort die neuesten Daten aus dem API-Cache und aktualisiert Widget und Push',
      'settingsBackgroundLoading': 'Daten werden im Hintergrund geladen...',
      'settingsSectionUpdates': 'Updates',
      'settingsSectionAbout': 'Über die App',
      'settingsAppVersion': 'Version',
      'settingsSectionSubjects': 'Fächer & Farben',
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
      'settingsGithubOpenReleasePage': 'GitHub Release-Seite öffnen',

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
    },

    // ── ENGLISH ───────────────────────────────────────────────────────────────
    'en': {
      'navWeek': 'Week',
      'navExams': 'Exams',
      'navInfo': 'Info',
      'navMenu': 'Menu',

      'loginServer': 'Server URL',
      'loginSchool': 'School',
      'loginUsername': 'Username',
      'loginPassword': 'Password',
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
      'onboardingFeatureExamsDesc': 'Track performance and upcoming exams.',
      'onboardingFeatureAiTitle': 'AI Assistant',
      'onboardingFeatureAiDesc':
          'Ask Gemini about your day, homework or exams.',
      'onboardingFeatureNotifyTitle': 'Notifications & Widgets',
      'onboardingFeatureNotifyDesc': 'Stay updated before school starts.',
      'onboardingFinishSetup': 'Finish Setup',

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
      'detailLesson': 'Lesson',
      'detailInfo': 'Note',
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
      'examsImportTitle': 'Upload exam schedule',
      'examsImportCamera': 'Camera',
      'examsImportGallery': 'Gallery',
      'examsImportFile': 'PDF / File',
      'examsImportSuccess': 'Successfully imported!',
      'examsImportError': 'Import error: ',

      'infoTitle': 'School Info',
      'infoReload': 'Reload',
      'infoUpdated': 'Updated',
      'infoEmpty': 'No current notifications',
      'infoEmptyHint':
          'If your school has not published anything at the moment, nothing is shown here.',
      'infoFetchError': 'Could not load notifications. Please try again later.',
      'infoOpenLink': 'Open link',

      'aiTitle': 'AI Assistant',
      'aiInputHint': 'Ask a question…',
      'aiKnowsSchedule': 'I know your timetable!',
      'aiAskAnything': 'Ask me anything about your week.',
      'aiNoApiKey':
          '⚠️ Please enter your Gemini API key under Settings → General.',
      'aiNoReply': '⚠️ No reply received.',
      'aiApiError': '⚠️ API error:',
      'aiConnectionError': '⚠️ Connection error:',
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
      'settingsBackgroundAnimations': 'Background Animations',
      'settingsBackgroundAnimationsDesc':
          'Show animated gradient effects in the background',
      'settingsBackgroundStyle': 'Animation Style',
      'settingsBackgroundStyleOrbs': 'Orbs',
      'settingsBackgroundStyleSpace': 'Space',
      'settingsBackgroundStyleBubbles': 'Bubbles',
      'settingsBackgroundStyleLines': 'Lines',
      'settingsBackgroundStyleThreeD': '3D Forms',
      'settingsBackgroundStyleAurora': 'Aurora',
      'settingsGlassEffect': 'Glass Effect (Blur)',
      'settingsGlassEffectDesc':
          'Enables soft glass/blur effects across the interface',
      'settingsProgressivePush': 'Progressive push notification',
      'settingsProgressivePushDesc':
          'Show the current lesson as a persistent notification',
      'settingsRefreshPushWidgetNow': 'Refresh push & widget now',
      'settingsRefreshPushWidgetNowDesc':
          'Immediately loads the newest data from the API cache and updates widget and push',
      'settingsBackgroundLoading': 'Data is loading in the background...',
      'settingsSectionUpdates': 'Updates',
      'settingsSectionAbout': 'About',
      'settingsAppVersion': 'Version',
      'settingsSectionSubjects': 'Subjects & Colors',
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
      'settingsGithubOpenReleasePage': 'Open GitHub release page',

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
    },

    // ── FRENCH ────────────────────────────────────────────────────────────────
    'fr': {
      'navWeek': 'Semaine',
      'navExams': 'Examens',
      'navInfo': 'Infos',
      'navMenu': 'Menu',

      'loginServer': 'URL du serveur',
      'loginSchool': 'École',
      'loginUsername': "Nom d'utilisateur",
      'loginPassword': 'Mot de passe',
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
          'Suis tes résultats et les examens à venir.',
      'onboardingFeatureAiTitle': 'Assistant IA',
      'onboardingFeatureAiDesc':
          'Demande à Gemini des infos sur ta journée, tes devoirs ou tes examens.',
      'onboardingFeatureNotifyTitle': 'Notifications & Widgets',
      'onboardingFeatureNotifyDesc': 'Reste informé avant le début des cours.',
      'onboardingFinishSetup': 'Terminer la configuration',

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
      'detailLesson': 'Cours',
      'detailInfo': 'Remarque',
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
      'examsImportTitle': 'Uploader le planning',
      'examsImportCamera': 'Caméra',
      'examsImportGallery': 'Galerie',
      'examsImportFile': 'PDF / Fichier',
      'examsImportSuccess': 'Importé avec succès !',
      'examsImportError': 'Erreur lors de l\'import : ',

      'infoTitle': 'Infos école',
      'infoReload': 'Recharger',
      'infoUpdated': 'Mis à jour',
      'infoEmpty': 'Aucune notification actuelle',
      'infoEmptyHint':
          'Si ton école ne publie rien actuellement, aucune information n\'apparaît ici.',
      'infoFetchError':
          'Impossible de charger les notifications. Réessaie plus tard.',
      'infoOpenLink': 'Ouvrir le lien',

      'aiTitle': 'Assistant IA',
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
      'settingsSectionGeneral': 'Application',
      'settingsAppearance': 'Apparence',
      'settingsAppearanceDesc': 'Système (Clair/Sombre)',
      'settingsLanguage': 'Langue',
      'settingsSectionAI': 'Assistant IA',
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
      'settingsBackgroundAnimations': 'Animations de fond',
      'settingsBackgroundAnimationsDesc':
          'Afficher des effets de dégradé animés en arrière-plan',
      'settingsBackgroundStyle': 'Style d\'animation',
      'settingsBackgroundStyleOrbs': 'Orbes',
      'settingsBackgroundStyleSpace': 'Espace',
      'settingsBackgroundStyleBubbles': 'Bulles',
      'settingsBackgroundStyleLines': 'Lignes',
      'settingsBackgroundStyleThreeD': 'Formes 3D',
      'settingsBackgroundStyleAurora': 'Aurore',
      'settingsProgressivePush': 'Notification push progressive',
      'settingsProgressivePushDesc':
          'Afficher le cours actuel comme notification persistante',
      'settingsRefreshPushWidgetNow': 'Actualiser push et widget maintenant',
      'settingsRefreshPushWidgetNowDesc':
          'Charge immédiatement les dernières données du cache API et met à jour widget et push',
      'settingsBackgroundLoading': 'Les données se chargent en arrière-plan...',
      'settingsSectionAbout': 'À propos',
      'settingsAppVersion': 'Version',
      'settingsSectionSubjects': 'Matières & Couleurs',
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
      'settingsGithubOpenReleasePage': 'Ouvrir la page des versions GitHub',

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
    },

    // ── SPANISH ───────────────────────────────────────────────────────────────
    'es': {
      'navWeek': 'Semana',
      'navExams': 'Exámenes',
      'navInfo': 'Info',
      'navMenu': 'Menú',

      'loginServer': 'URL del servidor',
      'loginSchool': 'Escuela',
      'loginUsername': 'Usuario',
      'loginPassword': 'Contraseña',
      'loginButton': 'Empezar',
      'loginFailed': 'Error de inicio de sesión. Verifica tus datos.',
      'loginConnectionError': 'Error de conexión',
      'loginSearchSchool': 'Buscar escuela',
      'loginSelectSchool': 'Seleccionar escuela',
      'loginSearchHint': 'Nombre o ciudad...',
      'loginNoSchoolsFound': 'No se encontraron escuelas.',
      'loginChangeLanguage': 'Idioma',
      'loginManualEntry': 'Entrada manual',
      'loginSwitchToSearch': 'Volver a buscar',
      'loginChangeSchool': 'Cambiar escuela',

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
          'Sigue tu progreso y los próximos exámenes.',
      'onboardingFeatureAiTitle': 'Asistente IA',
      'onboardingFeatureAiDesc':
          'Pregunta a Gemini sobre tu día, deberes o exámenes.',
      'onboardingFeatureNotifyTitle': 'Notificaciones y Widgets',
      'onboardingFeatureNotifyDesc':
          'Mantente al día antes de que empiece la escuela.',
      'onboardingFinishSetup': 'Finalizar configuración',

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
      'detailLesson': 'Clase',
      'detailInfo': 'Nota',
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
      'examsImportTitle': 'Subir calendario',
      'examsImportCamera': 'Cámara',
      'examsImportGallery': 'Galería',
      'examsImportFile': 'PDF / Archivo',
      'examsImportSuccess': '¡Importado con éxito!',
      'examsImportError': 'Error al importar: ',

      'infoTitle': 'Info escolar',
      'infoReload': 'Recargar',
      'infoUpdated': 'Actualizado',
      'infoEmpty': 'No hay notificaciones actuales',
      'infoEmptyHint':
          'Si tu escuela no ha publicado nada por ahora, no se mostrará nada aquí.',
      'infoFetchError':
          'No se pudieron cargar las notificaciones. Inténtalo más tarde.',
      'infoOpenLink': 'Abrir enlace',

      'aiTitle': 'Asistente IA',
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
      'settingsSectionGeneral': 'Aplicación',
      'settingsAppearance': 'Apariencia',
      'settingsAppearanceDesc': 'Sistema (Claro/Oscuro)',
      'settingsLanguage': 'Idioma',
      'settingsSectionAI': 'Asistente IA',
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
      'settingsBackgroundAnimations': 'Animaciones de fondo',
      'settingsBackgroundAnimationsDesc':
          'Mostrar efectos de degradado animados en el fondo',
      'settingsBackgroundStyle': 'Estilo de animación',
      'settingsBackgroundStyleOrbs': 'Orbes',
      'settingsBackgroundStyleSpace': 'Espacio',
      'settingsBackgroundStyleBubbles': 'Burbujas',
      'settingsBackgroundStyleLines': 'Líneas',
      'settingsBackgroundStyleThreeD': 'Formas 3D',
      'settingsBackgroundStyleAurora': 'Aurora',
      'settingsProgressivePush': 'Notificación push progresiva',
      'settingsProgressivePushDesc':
          'Mostrar la clase actual como notificación persistente',
      'settingsRefreshPushWidgetNow': 'Actualizar push y widget ahora',
      'settingsRefreshPushWidgetNowDesc':
          'Carga inmediatamente los datos más recientes de la caché API y actualiza widget y push',
      'settingsBackgroundLoading':
          'Los datos se están cargando en segundo plano...',
      'settingsSectionAbout': 'Acerca de',
      'settingsAppVersion': 'Versión',
      'settingsSectionSubjects': 'Asignaturas & Colores',
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
      'settingsGithubOpenReleasePage': 'Abrir página de versiones de GitHub',

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
    },
  };
}
