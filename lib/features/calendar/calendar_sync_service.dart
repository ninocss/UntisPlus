part of '../../main.dart';

/// Service responsible for syncing timetable/events to native calendar
class CalendarSyncService {
  final CalendarSyncRepository _repository;

  CalendarSyncService._(this._repository);

  /// Create a CalendarSyncService with a default repository
  static Future<CalendarSyncService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CalendarSyncService._(CalendarSyncRepository(prefs));
  }

  /// Sync all enabled event types
  Future<SyncResult> syncAll() async {
    final configs = _repository.loadConfigs();
    final enabledConfigs = configs.where((c) => c.enabled).toList();

    if (enabledConfigs.isEmpty) {
      return SyncResult(0, 0, 'No event types enabled for sync');
    }

    int totalCreated = 0;
    int totalUpdated = 0;
    final errors = <String>[];

    for (final config in enabledConfigs) {
      if (!config.enabled) continue;

      final result = await _syncEventType(config);
      totalCreated += result.created;
      totalUpdated += result.updated;
      if (result.error != null) {
        errors.add('${config.type.key}: ${result.error}');
      }
    }

    await _repository.setLastSyncTime(DateTime.now());

    return SyncResult(
      totalCreated,
      totalUpdated,
      errors.isEmpty ? null : errors.join('; '),
    );
  }

  /// Sync a specific event type
  Future<SyncResult> syncEventType(CalendarEventType type) async {
    final config = _repository.getConfig(type);
    if (config == null || !config.enabled) {
      return SyncResult(0, 0, 'Event type not enabled');
    }
    return _syncEventType(config);
  }

  Future<SyncResult> _syncEventType(CalendarSyncConfig config) async {
    final events = await _fetchEventsForType(config.type);
    if (events.isEmpty) return SyncResult(0, 0, null);

    final targetCalendarId = config.subCalendarId;
    int created = 0;
    int updated = 0;
    String? error;

    for (final event in events) {
      try {
        final existingId = await _findExistingEvent(config.type, event.sourceId ?? event.id, targetCalendarId);
        if (existingId != null) {
          await _tryUpdateEvent(existingId, event, targetCalendarId);
          updated++;
        } else {
          await _tryCreateEvent(event, targetCalendarId);
          created++;
        }
      } catch (e) {
        error ??= e.toString();
      }
    }

    return SyncResult(created, updated, error);
  }

  Future<void> _tryCreateEvent(CalendarSyncEvent event, String? calendarId) async {
    final androidCalId = calendarId != null ? int.tryParse(calendarId) : null;
    // Include sourceId in description for tracking
    final description = '${event.description}\n\n[UntisPlus:sourceId:${event.sourceId}]';
    
    final nativeEvent = native_cal.CalendarEvent(
      title: event.title,
      description: description,
      startDate: event.startTime,
      endDate: event.endTime,
      location: event.location,
      androidSettings: native_cal.AndroidEventSettings(
        calendarId: androidCalId,
        hasAlarm: true,
        reminderMinutes: const [15, 60],
      ),
      iosSettings: native_cal.IosEventSettings(
        calendarIdentifier: calendarId,
        alarmMinutes: const [15, 60],
        priority: 5,
      ),
    );

    final success = await NativeCalendar.addEventToCalendar(nativeEvent);
    if (!success) {
      throw Exception('Failed to create event: ${event.title}');
    }
  }

  Future<void> _tryUpdateEvent(String eventId, CalendarSyncEvent event, String? calendarId) async {
    final androidCalId = calendarId != null ? int.tryParse(calendarId) : null;
    final description = '${event.description}\n\n[UntisPlus:sourceId:${event.sourceId}]';
    
    final nativeEvent = native_cal.CalendarEvent(
      title: event.title,
      description: description,
      startDate: event.startTime,
      endDate: event.endTime,
      location: event.location,
      androidSettings: native_cal.AndroidEventSettings(
        calendarId: androidCalId,
        hasAlarm: true,
        reminderMinutes: const [15, 60],
      ),
      iosSettings: native_cal.IosEventSettings(
        calendarIdentifier: calendarId,
        alarmMinutes: const [15, 60],
        priority: 5,
      ),
    );

    final success = await NativeCalendar.addEventToCalendar(nativeEvent);
    if (!success) {
      throw Exception('Failed to update event: ${event.title}');
    }
  }

  /// Find existing native event ID for a given event type and source ID
  Future<String?> _findExistingEvent(CalendarEventType type, String sourceId, String? calendarId) async {
    // Query events from the last 30 days to 30 days in the future
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    final endDate = now.add(const Duration(days: 30));

    final events = await CalendarPlatform.getEvents(
      calendarId: calendarId,
      start: startDate,
      end: endDate,
    );

    for (final nativeEvent in events) {
      // Check if this event was created by our app (by checking description for sourceId)
      final description = nativeEvent['description'] as String? ?? '';
      if (description.contains('[UntisPlus:sourceId:$sourceId]')) {
        return nativeEvent['id'] as String?;
      }
    }

    return null;
  }

  /// Fetch events from native calendar (bidirectional sync - read events from calendar)
  Future<List<CalendarSyncEvent>> fetchNativeEvents({
    CalendarEventType? type,
    String? calendarId,
    DateTime? start,
    DateTime? end,
  }) async {
    final events = await CalendarPlatform.getEvents(
      calendarId: calendarId,
      start: start,
      end: end,
    );

    return events.map((e) {
      final description = e['description'] as String? ?? '';
      final sourceIdMatch = RegExp(r'\[UntisPlus:sourceId:([^\]]+)\]').firstMatch(description);
      final sourceId = sourceIdMatch?.group(1);
      
      return CalendarSyncEvent(
        id: e['id'] as String? ?? '',
        type: type ?? CalendarEventType.tests,
        title: e['title'] as String? ?? '',
        description: description.replaceAll(RegExp(r'\n\n\[UntisPlus:sourceId:[^\]]+\]'), ''),
        startTime: DateTime.fromMillisecondsSinceEpoch(e['start'] as int? ?? 0),
        endTime: DateTime.fromMillisecondsSinceEpoch(e['end'] as int? ?? 0),
        location: e['location'] as String?,
        sourceId: sourceId,
        metadata: {'native': true, 'calendarId': e['calendarId']},
      );
    }).toList();
  }

  /// Fetch events for a specific type from timetable/homework/etc.
  Future<List<CalendarSyncEvent>> _fetchEventsForType(CalendarEventType type) async {
    switch (type) {
      case CalendarEventType.tests:
        return _fetchTestsFromTimetable();
      case CalendarEventType.homework:
        return _fetchHomeworkFromNotifier();
      case CalendarEventType.assignments:
        return _fetchAssignmentsFromTimetable();
      case CalendarEventType.conversations:
        return _fetchConversationsFromTimetable();
      case CalendarEventType.learning:
        return _fetchLearningFromTimetable();
    }
  }

  List<CalendarSyncEvent> _fetchTestsFromTimetable() {
    final weekData = currentWeekDataNotifier.value;
    final events = <CalendarSyncEvent>[];

    for (final dayEntry in weekData.entries) {
      for (final lesson in dayEntry.value) {
        // Check if lesson is a test/exam
        final lessonMap = lesson as Map<String, dynamic>;
        final info = (lessonMap['info'] ?? '').toString().toLowerCase();
        final substText = (lessonMap['substText'] ?? '').toString().toLowerCase();
        final isTest = info.contains('klausur') || info.contains('test') || info.contains('exam') ||
            substText.contains('klausur') || substText.contains('test') || substText.contains('exam');

        if (isTest) {
          final subject = lessonMap['_subjectLong']?.toString() ?? lessonMap['su']?.toString() ?? 'Test';
          final room = lessonMap['_roomLong']?.toString() ?? lessonMap['ro']?.toString() ?? '';
          final teacher = lessonMap['_teacherLong']?.toString() ?? lessonMap['te']?.toString() ?? '';
          final startTime = lessonMap['startTime'] as int? ?? 0;
          final endTime = lessonMap['endTime'] as int? ?? 0;
          final dayIndex = dayEntry.key;

          final date = _currentMonday().add(Duration(days: dayIndex));
          final startDateTime = DateTime(date.year, date.month, date.day, startTime ~/ 100, startTime % 100);
          final endDateTime = DateTime(date.year, date.month, date.day, endTime ~/ 100, endTime % 100);

          events.add(CalendarSyncEvent(
            id: 'test_${lessonMap['id'] ?? '${date.day}_$startTime'}',
            type: CalendarEventType.tests,
            title: '$subject - Klausur',
            description: 'Lehrer: $teacher\nThema: $info',
            startTime: startDateTime,
            endTime: endDateTime,
            location: room,
            sourceId: lessonMap['id']?.toString() ?? 'test_${date.day}_$startTime',
            metadata: {'subject': subject, 'teacher': teacher},
          ));
        }
      }
    }

    return events;
  }

  List<CalendarSyncEvent> _fetchHomeworkFromNotifier() {
    final homeworks = homeworksNotifier.value;
    final events = <CalendarSyncEvent>[];

    for (final hw in homeworks) {
      final hwMap = hw;
      final dueDateStr = hwMap['dueDate']?.toString();
      final dueDate = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
      if (dueDate == null) continue;

      final subject = hwMap['_subjectLong']?.toString() ?? hwMap['subject']?.toString() ?? 'Hausaufgabe';
      final text = hwMap['text']?.toString() ?? '';
      final id = hwMap['id']?.toString() ?? hwMap['lessonId']?.toString() ?? 'hw_${dueDate.millisecondsSinceEpoch}';

      // Create event at 4 PM on due date
      final startDateTime = DateTime(dueDate.year, dueDate.month, dueDate.day, 16, 0);
      final endDateTime = startDateTime.add(const Duration(hours: 1));

      events.add(CalendarSyncEvent(
        id: id,
        type: CalendarEventType.homework,
        title: 'Hausaufgabe: $subject',
        description: text,
        startTime: startDateTime,
        endTime: endDateTime,
        sourceId: id,
        metadata: {'subject': subject},
      ));
    }

    return events;
  }

  List<CalendarSyncEvent> _fetchAssignmentsFromTimetable() {
    final weekData = currentWeekDataNotifier.value;
    final events = <CalendarSyncEvent>[];

    for (final dayEntry in weekData.entries) {
      for (final lesson in dayEntry.value) {
        final lessonMap = lesson as Map<String, dynamic>;
        final info = (lessonMap['info'] ?? '').toString().toLowerCase();
        final substText = (lessonMap['substText'] ?? '').toString().toLowerCase();
        final isSubstitution = info.contains('vertretung') || info.contains('subst') ||
            substText.contains('vertretung') || substText.contains('subst');

        if (isSubstitution) {
          final subject = lessonMap['_subjectLong']?.toString() ?? lessonMap['su']?.toString() ?? 'Vertretung';
          final room = lessonMap['_roomLong']?.toString() ?? lessonMap['ro']?.toString() ?? '';
          final teacher = lessonMap['_teacherLong']?.toString() ?? lessonMap['te']?.toString() ?? '';
          final originalTeacher = lessonMap['_originalTeacherLong']?.toString() ?? '';
          final startTime = lessonMap['startTime'] as int? ?? 0;
          final endTime = lessonMap['endTime'] as int? ?? 0;
          final dayIndex = dayEntry.key;

          final date = _currentMonday().add(Duration(days: dayIndex));
          final startDateTime = DateTime(date.year, date.month, date.day, startTime ~/ 100, startTime % 100);
          final endDateTime = DateTime(date.year, date.month, date.day, endTime ~/ 100, endTime % 100);

          events.add(CalendarSyncEvent(
            id: 'subst_${lessonMap['id'] ?? '${date.day}_$startTime'}',
            type: CalendarEventType.assignments,
            title: 'Vertretung: $subject',
            description: 'Lehrer: $teacher\nOriginal: $originalTeacher\nInfo: $info',
            startTime: startDateTime,
            endTime: endDateTime,
            location: room,
            sourceId: lessonMap['id']?.toString() ?? 'subst_${date.day}_$startTime',
            metadata: {'type': 'substitution', 'originalTeacher': originalTeacher, 'teacher': teacher},
          ));
        }
      }
    }

    return events;
  }

  List<CalendarSyncEvent> _fetchConversationsFromTimetable() {
    // Conversations not implemented yet - return empty
    return [];
  }

  List<CalendarSyncEvent> _fetchLearningFromTimetable() {
    // Learning not implemented yet - return empty
    return [];
  }

  DateTime _currentMonday() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  /// Remove all events for a specific type from native calendar
  Future<void> clearEventType(CalendarEventType type) async {
    // Without device_calendar, we can't delete existing events
    // This would require the user to manually remove events from their calendar
  }
}

/// Result of a sync operation
class SyncResult {
  final int created;
  final int updated;
  final String? error;

  const SyncResult(this.created, this.updated, this.error);

  bool get success => error == null;
  int get total => created + updated;

  @override
  String toString() {
    if (error != null) return 'SyncResult(created: $created, updated: $updated, error: $error)';
    return 'SyncResult(created: $created, updated: $updated)';
  }
}