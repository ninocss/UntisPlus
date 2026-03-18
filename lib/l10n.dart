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

  // ── Timetable ───────────────────────────────────────────────────────────────
  String get timetableTitle => _t('timetableTitle');
  String get timetablePrevWeek => _t('timetablePrevWeek');
  String get timetableNextWeek => _t('timetableNextWeek');
  String get timetableWeekView => _t('timetableWeekView');
  String get timetableDayGrid => _t('timetableDayGrid');
  String get timetableNotLoaded => _t('timetableNotLoaded');
  String get timetableReload => _t('timetableReload');
  List<String> get weekDayShort => List<String>.from(_strings[locale]!['weekDayShort'] as List);
  List<String> get weekDayFull => List<String>.from(_strings[locale]!['weekDayFull'] as List);
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
  String examsInDays(int n) => _t('examsDaysIn').replaceAll('{n}', '$n');

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
  String get settingsThemeMode => _t('settingsThemeMode');
  String get settingsThemeLight => _t('settingsThemeLight');
  String get settingsThemeSystem => _t('settingsThemeSystem');
  String get settingsThemeDark => _t('settingsThemeDark');
  String get settingsSectionTimetable => _t('settingsSectionTimetable');
  String get settingsShowCancelled => _t('settingsShowCancelled');
  String get settingsShowCancelledDesc => _t('settingsShowCancelledDesc');
  String get settingsBackgroundAnimations => _t('settingsBackgroundAnimations');
  String get settingsBackgroundAnimationsDesc => _t('settingsBackgroundAnimationsDesc');
  String get settingsSectionAbout => _t('settingsSectionAbout');
  String get settingsAppVersion => _t('settingsAppVersion');
  String get settingsSectionSubjects => _t('settingsSectionSubjects');

  // ── AI System Prompt ─────────────────────────────────────────────────────────
  String get aiSystemPersona => _t('aiSystemPersona');
  String get aiSystemRules => _t('aiSystemRules');

  // ─────────────────────────────────────────────────────────────────────────────
  static const Map<String, Map<String, dynamic>> _strings = {
    // ── GERMAN ────────────────────────────────────────────────────────────────
    'de': {
      'navWeek': 'Woche',
      'navExams': 'Prüfungen',
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

      'timetableTitle': 'Stundenplan',
      'timetablePrevWeek': 'Vorherige Woche',
      'timetableNextWeek': 'Nächste Woche',
      'timetableWeekView': 'Wochenansicht',
      'timetableDayGrid': 'Tagesraster',
      'timetableNotLoaded': 'Stundenplan nicht geladen',
      'timetableReload': 'Neu laden',
      'weekDayShort': ['Mo', 'Di', 'Mi', 'Do', 'Fr'],
      'weekDayFull': ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag'],
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
      'settingsThemeMode': 'Farbschema',
      'settingsThemeLight': 'Hell',
      'settingsThemeSystem': 'System',
      'settingsThemeDark': 'Dunkel',
      'settingsSectionTimetable': 'Stundenplan',
      'settingsShowCancelled': 'Ausgefallene Stunden anzeigen',
      'settingsShowCancelledDesc': 'Ausgefallene Stunden werden im Stundenplan angezeigt',
      'settingsBackgroundAnimations': 'Hintergrundanimationen',
      'settingsBackgroundAnimationsDesc': 'Animierte Farbverläufe im Hintergrund anzeigen',
      'settingsSectionAbout': 'Über die App',
      'settingsAppVersion': 'Version',
      'settingsSectionSubjects': 'Fächer & Farben',

      'aiSystemPersona':
          'Du bist "Plan-Assistent", ein freundlicher und motivierender KI-Helfer für Schüler*innen.',
      'aiSystemRules': '''REGELN:
- Antworte AUSSCHLIEßLICH basierend auf den obigen Stundenplandaten.
- Erfinde KEINE Fächer, Zeiten, Lehrer oder sonstige Informationen.
- Wenn etwas aus den Daten nicht ableitbar ist, sage es offen.
- Beachte [FÄLLT AUS]-Markierungen (diese Stunden finden nicht statt).
- "Freistunden" = Lücken zwischen zwei Unterrichtsstunden.
- Antworte auf Deutsch, freundlich, kurz.
- Beginne nicht automatisch mit "Ja," – antworte direkt.
- Du darfst Markdown zur Formatierung verwenden (z.B. Listen, **fett**).''',
    },

    // ── ENGLISH ───────────────────────────────────────────────────────────────
    'en': {
      'navWeek': 'Week',
      'navExams': 'Exams',
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

      'timetableTitle': 'Timetable',
      'timetablePrevWeek': 'Previous week',
      'timetableNextWeek': 'Next week',
      'timetableWeekView': 'Week view',
      'timetableDayGrid': 'Day grid',
      'timetableNotLoaded': 'Timetable not loaded',
      'timetableReload': 'Reload',
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
      'settingsThemeMode': 'Color scheme',
      'settingsThemeLight': 'Light',
      'settingsThemeSystem': 'System',
      'settingsThemeDark': 'Dark',
      'settingsSectionTimetable': 'Timetable',
      'settingsShowCancelled': 'Show cancelled lessons',
      'settingsShowCancelledDesc': 'Cancelled lessons are shown in the timetable',
      'settingsBackgroundAnimations': 'Background Animations',
      'settingsBackgroundAnimationsDesc': 'Show animated gradient effects in the background',
      'settingsSectionAbout': 'About',
      'settingsAppVersion': 'Version',
      'settingsSectionSubjects': 'Subjects & Colors',

      'aiSystemPersona':
          'You are "Schedule Assistant", a friendly and motivating AI helper for students.',
      'aiSystemRules': '''RULES:
- Answer EXCLUSIVELY based on the timetable data above.
- Do NOT invent subjects, times, teachers or other information.
- If something cannot be derived from the data, say so openly.
- Respect [CANCELLED] markers (those lessons do not take place).
- "Free periods" = gaps between two lessons.
- Answer in English, friendly and concise.
- Do not start automatically with "Yes," – answer directly.
- You may use Markdown for formatting (e.g. lists, **bold**).''',
    },

    // ── FRENCH ────────────────────────────────────────────────────────────────
    'fr': {
      'navWeek': 'Semaine',
      'navExams': 'Examens',
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

      'timetableTitle': 'Emploi du temps',
      'timetablePrevWeek': 'Semaine précédente',
      'timetableNextWeek': 'Semaine suivante',
      'timetableWeekView': 'Vue semaine',
      'timetableDayGrid': 'Grille journalière',
      'timetableNotLoaded': "Emploi du temps non chargé",
      'timetableReload': 'Recharger',
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

      'aiTitle': 'Assistant IA',
      'aiInputHint': 'Poser une question…',
      'aiKnowsSchedule': 'Je connais ton emploi du temps !',
      'aiAskAnything': 'Demande-moi tout sur ta semaine.',
      'aiNoApiKey':
          '⚠️ Saisis ta clé API Gemini dans Paramètres → Général.',
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
      'settingsThemeMode': 'Schéma de couleurs',
      'settingsThemeLight': 'Clair',
      'settingsThemeSystem': 'Système',
      'settingsThemeDark': 'Sombre',
      'settingsSectionTimetable': 'Emploi du temps',
      'settingsShowCancelled': 'Afficher les cours annulés',
      'settingsShowCancelledDesc': 'Les cours annulés sont visibles dans l\'emploi du temps',
      'settingsBackgroundAnimations': 'Animations de fond',
      'settingsBackgroundAnimationsDesc': 'Afficher des effets de dégradé animés en arrière-plan',
      'settingsSectionAbout': 'À propos',
      'settingsAppVersion': 'Version',
      'settingsSectionSubjects': 'Matières & Couleurs',

      'aiSystemPersona':
          'Tu es "Assistant Planning", un assistant IA amical et motivant pour les élèves.',
      'aiSystemRules': '''RÈGLES :
- Répondre EXCLUSIVEMENT sur la base des données d'emploi du temps ci-dessus.
- Ne PAS inventer de matières, d'horaires, d'enseignants ou d'autres informations.
- Si quelque chose ne peut pas être déduit des données, dis-le ouvertement.
- Respecter les marqueurs [ANNULÉ] (ces cours n'ont pas lieu).
- "Heures libres" = pauses entre deux cours.
- Répondre en français, de manière amicale et concise.
- Ne pas commencer automatiquement par "Oui," – répondre directement.
- Tu peux utiliser Markdown pour la mise en forme (ex. listes, **gras**).''',
    },

    // ── SPANISH ───────────────────────────────────────────────────────────────
    'es': {
      'navWeek': 'Semana',
      'navExams': 'Exámenes',
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

      'timetableTitle': 'Horario',
      'timetablePrevWeek': 'Semana anterior',
      'timetableNextWeek': 'Semana siguiente',
      'timetableWeekView': 'Vista semanal',
      'timetableDayGrid': 'Cuadrícula diaria',
      'timetableNotLoaded': 'Horario no cargado',
      'timetableReload': 'Recargar',
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

      'aiTitle': 'Asistente IA',
      'aiInputHint': 'Hacer una pregunta…',
      'aiKnowsSchedule': '¡Conozco tu horario!',
      'aiAskAnything': 'Pregúntame lo que quieras sobre tu semana.',
      'aiNoApiKey':
          '⚠️ Introduce tu clave API de Gemini en Ajustes → General.',
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
      'settingsThemeMode': 'Esquema de colores',
      'settingsThemeLight': 'Claro',
      'settingsThemeSystem': 'Sistema',
      'settingsThemeDark': 'Oscuro',
      'settingsSectionTimetable': 'Horario',
      'settingsShowCancelled': 'Mostrar clases canceladas',
      'settingsShowCancelledDesc': 'Las clases canceladas se muestran en el horario',
      'settingsBackgroundAnimations': 'Animaciones de fondo',
      'settingsBackgroundAnimationsDesc': 'Mostrar efectos de degradado animados en el fondo',
      'settingsSectionAbout': 'Acerca de',
      'settingsAppVersion': 'Versión',
      'settingsSectionSubjects': 'Asignaturas & Colores',

      'aiSystemPersona':
          'Eres "Asistente de Horario", un ayudante IA amigable y motivador para estudiantes.',
      'aiSystemRules': '''REGLAS:
- Responde EXCLUSIVAMENTE basándote en los datos del horario anteriores.
- NO inventes asignaturas, horarios, profesores ni otra información.
- Si algo no se puede deducir de los datos, dilo abiertamente.
- Respeta los marcadores [CANCELADO] (esas clases no tienen lugar).
- "Horas libres" = huecos entre dos clases.
- Responde en español, de forma amigable y concisa.
- No empieces automáticamente con "Sí," – responde directamente.
- Puedes usar Markdown para el formato (ej. listas, **negrita**).''',
    },
  };
}
