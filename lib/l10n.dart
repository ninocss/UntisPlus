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
