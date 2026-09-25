import 'package:flutter/widgets.dart';

import 'l10n/generated/app_l10n.dart';

export 'l10n/generated/app_l10n.dart';

const _supportedLanguageCodes = <String>{'de', 'en', 'fr', 'es'};

/// Returns translations outside the widget tree, for example in background
/// workers and native platform payloads. Unknown locales deliberately use the
/// German catalog, matching the app's historical behavior.
AppL10n appL10nFor(String locale) {
  final normalized = locale.replaceAll('_', '-').split('-').first.toLowerCase();
  final languageCode = _supportedLanguageCodes.contains(normalized)
      ? normalized
      : 'de';
  return lookupAppL10n(Locale(languageCode));
}

extension AppL10nCollections on AppL10n {
  String get locale => localeName.split(RegExp('[-_]')).first;

  String wrapped(String key) {
    const copy = <String, List<String>>{
      'title': ['School Wrapped', 'School Wrapped', 'School Wrapped', 'School Wrapped'],
      'settingsDesc': ['Dein Schuljahr als Story', 'Your school year as a story', 'Ton année scolaire en récit', 'Tu año escolar en historias'],
      'intro': ['Dein Schuljahr in Zahlen.', 'Your school year in numbers.', 'Ton année scolaire en chiffres.', 'Tu año escolar en cifras.'],
      'partial': ['Bisher in diesem Schuljahr', 'So far this school year', 'Jusqu’ici cette année', 'Hasta ahora este curso'],
      'complete': ['Dein Jahresrückblick', 'Your year in review', 'Ton bilan de l’année', 'Tu año en resumen'],
      'begin': ['Wrapped starten', 'Start Wrapped', 'Lancer Wrapped', 'Iniciar Wrapped'],
      'configure': ['Schuljahr festlegen', 'Set school year', 'Définir l’année scolaire', 'Definir el curso escolar'],
      'datesInfo': ['WebUntis liefert kein Schuljahresdatum. Wähle Beginn und Ende.', 'WebUntis has no school year dates. Choose the start and end.', 'WebUntis ne fournit pas de dates. Choisis le début et la fin.', 'WebUntis no proporciona fechas. Elige el inicio y el fin.'],
      'startDate': ['Beginn wählen', 'Choose start', 'Choisir le début', 'Elegir inicio'],
      'endDate': ['Ende wählen', 'Choose end', 'Choisir la fin', 'Elegir fin'],
      'noYear': ['Noch kein Schuljahr verfügbar', 'No school year available yet', 'Aucune année scolaire disponible', 'Aún no hay curso escolar'],
      'noData': ['Noch keine Schuldaten für diesen Rückblick verfügbar. Verbinde dich mit WebUntis und versuche es erneut.', 'No school data is available for this review yet. Connect to WebUntis and try again.', 'Aucune donnée scolaire disponible pour ce bilan. Connecte-toi à WebUntis et réessaie.', 'Aún no hay datos escolares para este resumen. Conéctate a WebUntis e inténtalo de nuevo.'],
      'loading': ['Dein Schuljahr wird gesammelt', 'Gathering your school year', 'Collecte de ton année scolaire', 'Recopilando tu curso escolar'],
      'retry': ['Erneut versuchen', 'Try again', 'Réessayer', 'Reintentar'],
      'incomplete': ['Einige Wochen fehlen. Zahlen zeigen nur verfügbare Daten.', 'Some weeks are missing. Numbers cover available data only.', 'Certaines semaines manquent. Les chiffres ne couvrent que les données disponibles.', 'Faltan algunas semanas. Las cifras solo incluyen los datos disponibles.'],
      'sourceMissing': ['Diese Daten stellt deine Schule nicht bereit.', 'Your school does not provide this data.', 'Ton école ne fournit pas ces données.', 'Tu centro no proporciona estos datos.'],
      'lessonsTitle': ['So viel Unterricht', 'All those lessons', 'Tous ces cours', 'Todas esas clases'],
      'lessons': ['Unterrichtsstunden', 'lessons', 'cours', 'clases'],
      'hours': ['Zeit im Unterricht', 'time in class', 'temps en cours', 'tiempo en clase'],
      'changesTitle': ['Pläne ändern sich', 'Plans change', 'Les plans changent', 'Los planes cambian'],
      'cancelled': ['Ausfälle', 'cancelled lessons', 'cours annulés', 'clases canceladas'],
      'substitutions': ['Vertretungen', 'substitutions', 'remplacements', 'sustituciones'],
      'absenceTitle': ['Deine Fehlzeiten', 'Your absences', 'Tes absences', 'Tus ausencias'],
      'absentLessons': ['betroffene Unterrichtsstunden', 'affected lessons', 'cours concernés', 'clases afectadas'],
      'absenceRecords': ['Abwesenheitseinträge', 'absence records', 'absences enregistrées', 'registros de ausencia'],
      'excused': ['entschuldigt', 'excused', 'justifiées', 'justificadas'],
      'unexcused': ['unentschuldigt', 'unexcused', 'non justifiées', 'sin justificar'],
      'freeTitle': ['Zeit zum Durchatmen', 'Room to breathe', 'Le temps de souffler', 'Tiempo para respirar'],
      'freeDays': ['schulfreie Wochentage', 'school-free weekdays', 'jours de semaine sans cours', 'días lectivos libres'],
      'holidays': ['Ferien & freie Zeiten', 'Holidays & breaks', 'Vacances et pauses', 'Vacaciones y descansos'],
      'gradeTitle': ['Deine Noten', 'Your grades', 'Tes notes', 'Tus notas'],
      'grades': ['eingetragene Noten', 'recorded grades', 'notes enregistrées', 'notas registradas'],
      'workTitle': ['Dein Lernalltag', 'Your school work', 'Ton travail scolaire', 'Tu trabajo escolar'],
      'exams': ['Prüfungen', 'exams', 'examens', 'exámenes'],
      'homework': ['Hausaufgaben', 'homework items', 'devoirs', 'tareas'],
      'finalTitle': ['Das war dein Schuljahr.', 'That was your school year.', 'Voilà ton année scolaire.', 'Así fue tu curso escolar.'],
      'finalSub': ['Bis zum nächsten Kapitel.', 'On to the next chapter.', 'Place au prochain chapitre.', 'Vamos al próximo capítulo.'],
      'musicOn': ['Musik ausschalten', 'Mute music', 'Couper la musique', 'Silenciar música'],
      'musicOff': ['Musik einschalten', 'Play music', 'Activer la musique', 'Activar música'],
      'autoOn': ['Automatisch weiter: an', 'Auto advance: on', 'Défilement auto : activé', 'Avance automática: activada'],
      'autoOff': ['Automatisch weiter: aus', 'Auto advance: off', 'Défilement auto : désactivé', 'Avance automática: desactivada'],
      'next': ['Weiter', 'Next', 'Suivant', 'Siguiente'],
      'back': ['Zurück', 'Back', 'Retour', 'Atrás'],
      'close': ['Schließen', 'Close', 'Fermer', 'Cerrar'],
      'announcement': ['Dein School Wrapped ist da!', 'Your School Wrapped is here!', 'Ton School Wrapped est arrivé !', '¡Ya está tu School Wrapped!'],
      'announcementSub': ['Schau dir dein Schuljahr an.', 'Take a look at your school year.', 'Découvre ton année scolaire.', 'Descubre tu curso escolar.'],
      'later': ['Später', 'Later', 'Plus tard', 'Más tarde'],
      'demo': ['Demo-Rückblick mit Beispieldaten', 'Demo review with sample data', 'Bilan démo avec exemples', 'Resumen de prueba con ejemplos'],
      'summer': ['Sommerferien', 'Summer break', 'Vacances d’été', 'Vacaciones de verano'],
      'winter': ['Winterferien', 'Winter break', 'Vacances d’hiver', 'Vacaciones de invierno'],
      'math': ['Mathe', 'Math', 'Maths', 'Matemáticas'],
      'language': ['Deutsch', 'German', 'Allemand', 'Alemán'],
    };
    final values = copy[key];
    if (values == null) return key;
    final index = switch (locale) {'en' => 1, 'fr' => 2, 'es' => 3, _ => 0};
    return values[index];
  }

  String get timetableThreeDayView => switch (locale) {
    'en' => '3-day view',
    'es' => 'Vista de 3 días',
    'fr' => 'Vue sur 3 jours',
    _ => '3-Tage-Ansicht',
  };

  String get teacherSearchRefreshAll => switch (locale) {
    'en' => 'Refresh teachers and timetable',
    'es' => 'Actualizar docentes y horario',
    'fr' => 'Actualiser les enseignants et l’emploi du temps',
    _ => 'Lehrkräfte und Stundenplan aktualisieren',
  };

  String teacherSearchClassFallback(int count) => switch (locale) {
    'en' => 'Teachers from $count accessible class timetables',
    'es' => 'Docentes de $count horarios de clase accesibles',
    'fr' =>
      'Enseignants issus de $count emplois du temps de classe accessibles',
    _ => 'Lehrkräfte aus $count erreichbaren Klassen-Stundenplänen',
  };

  String get teacherSearchClassFallbackUnavailable => switch (locale) {
    'en' =>
      'No teachers could be read from accessible class timetables. Check class timetable access and try refreshing again.',
    'es' =>
      'No se pudieron obtener docentes de los horarios accesibles. Comprueba el acceso y vuelve a actualizar.',
    'fr' =>
      'Aucun enseignant n’a pu être récupéré depuis les emplois du temps accessibles. Vérifie les accès puis réessaie.',
    _ =>
      'Aus den erreichbaren Klassen-Stundenplänen konnten keine Lehrkräfte gelesen werden. Prüfe den Zugriff und aktualisiere erneut.',
  };

  String get settingsAiAvailability => switch (locale) {
    'en' => 'AI features',
    'es' => 'Funciones de IA',
    'fr' => 'Fonctionnalités IA',
    _ => 'KI-Funktionen',
  };

  String get settingsAiEnabled => switch (locale) {
    'en' => 'Enable AI',
    'es' => 'Activar IA',
    'fr' => 'Activer l’IA',
    _ => 'KI aktivieren',
  };

  String get settingsAiEnabledDesc => switch (locale) {
    'en' => 'Show or hide the AI tab and all AI tools in the app.',
    'es' =>
      'Muestra u oculta la pestaña de IA y todas las herramientas de IA de la aplicación.',
    'fr' =>
      'Affiche ou masque l’onglet IA et tous les outils IA de l’application.',
    _ => 'Blendet den KI-Tab und alle KI-Tools in der App ein oder aus.',
  };

  List<String> get weekDayShort => <String>[
    weekDayShortMonday,
    weekDayShortTuesday,
    weekDayShortWednesday,
    weekDayShortThursday,
    weekDayShortFriday,
  ];

  List<String> get weekDayFull => <String>[
    weekDayFullMonday,
    weekDayFullTuesday,
    weekDayFullWednesday,
    weekDayFullThursday,
    weekDayFullFriday,
  ];

  List<String> get aiSuggestions => <String>[
    aiSuggestionOne,
    aiSuggestionTwo,
    aiSuggestionThree,
    aiSuggestionFour,
  ];

  List<String> get aiChatSuggestions => <String>[
    aiChatSuggestionOne,
    aiChatSuggestionTwo,
    aiChatSuggestionThree,
  ];

  List<String> get aiGreetings => <String>[
    aiGreetingOne,
    aiGreetingTwo,
    aiGreetingThree,
    aiGreetingFour,
    aiGreetingFive,
  ];

  String examsInDays(int days) => examsDaysIn(days);

  String infoAttachmentLabel(int count, String? extension) {
    final normalizedExtension = (extension ?? '').trim().toUpperCase();
    if (normalizedExtension.isNotEmpty) {
      return count == 1
          ? infoAttachedExtOne(normalizedExtension)
          : infoAttachedExtMany(normalizedExtension);
    }
    return count == 1 ? infoAttachedFile : infoAttachedFiles;
  }

  Map<String, String> get aiPromptVariableDescriptions => <String, String>{
    '[today]': aiVar_today,
    '[today_iso]': aiVar_today_iso,
    '[locale]': aiVar_locale,
    '[school_name]': aiVar_school_name,
    '[school_url]': aiVar_school_url,
    '[person_type]': aiVar_person_type,
    '[person_id]': aiVar_person_id,
    '[demo_mode]': aiVar_demo_mode,
    '[current_monday]': aiVar_current_monday,
    '[current_friday]': aiVar_current_friday,
    '[day_summary_today]': aiVar_day_summary_today,
    '[day_summary_tomorrow]': aiVar_day_summary_tomorrow,
    '[timetable]': aiVar_timetable,
    '[timetable_json]': aiVar_timetable_json,
    '[exams]': aiVar_exams,
    '[exams_json]': aiVar_exams_json,
    '[current_lesson]': aiVar_current_lesson,
    '[next_lesson]': aiVar_next_lesson,
  };

  /// Copy transported to native alarm processes that can run while Flutter is
  /// stopped.
  Map<String, String> nativeAlarmCopy() => <String, String>{
    'channelReminder': nativeAlarmReminderChannel,
    'channelReminderDescription': nativeAlarmReminderChannelDesc,
    'channelAlarm': nativeAlarmChannel,
    'channelAlarmDescription': nativeAlarmChannelDesc,
    'channelRefresh': nativeAlarmRefreshChannel,
    'reminderTitle': nativeAlarmReminderTitle('{minutes}'),
    'disableToday': nativeAlarmDisableToday,
    'alarmTitle': nativeAlarmTitle,
    'swipeHint': nativeAlarmSwipeHint,
    'snooze': nativeAlarmSnooze('{minutes}'),
    'dismiss': nativeAlarmDismiss,
    'refreshing': nativeAlarmRefreshing,
    'defaultLabel': alarmSchedule,
    'statusActive': nativeAlarmStatusActive,
    'statusSnoozing': nativeAlarmStatusSnoozing,
    'timeAccessibility': nativeAlarmTimeAccessibility('{time}'),
  };

  Map<String, String> nativeWidgetCopy() => <String, String>{
    'setupTitle': nativeWidgetSetupTitle,
    'setupAccount': nativeWidgetSetupAccount,
    'setupProfile': nativeWidgetSetupProfile,
    'setupProfileHint': nativeWidgetSetupProfileHint,
    'setupNoProfile': nativeWidgetSetupNoProfile,
    'setupNoAccount': nativeWidgetSetupNoAccount,
    'fallbackRefreshing': nativeWidgetRefreshing,
    'fallbackHomework': widgetNoOpenHomework,
    'fallbackExams': widgetNoUpcomingExams,
    'fallbackNotices': widgetNoNotices,
    'fallbackCurrent': widgetNoCurrentLesson,
    'fallbackNext': widgetNoLessonsToday,
    'fallbackSchedule': widgetNoScheduleData,
    'today': widgetToday,
    'titleSchedule': widgetSchedule,
    'titleHomework': widgetHomework.toUpperCase(),
    'titleNotices': widgetNotices.toUpperCase(),
  };
}
