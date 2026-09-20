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

  /// Sync all enabled event types (bidirectional)
  Future<SyncResult> syncAll() async {
    final configs = _repository.loadConfigs();
    final enabledConfigs = configs.where((c) => c.enabled).toList();

    if (enabledConfigs.isEmpty) {
      return SyncResult(0, 0, 'No event types enabled for sync');
    }

    int totalCreated = 0;
    int totalUpdated = 0;
    int totalSyncedFromCalendar = 0;
    final errors = <String>[];

    for (final config in enabledConfigs) {
      if (!config.enabled) continue;

      final result = await _syncEventTypeBidirectional(config);
      totalCreated += result.created;
      totalUpdated += result.updated;
      totalSyncedFromCalendar += result.syncedFromCalendar;
      if (result.error != null) {
        errors.add('${config.type.key}: ${result.error}');
      }
    }

    await _repository.setLastSyncTime(DateTime.now());

    return SyncResult(
      totalCreated,
      totalUpdated,
      errors.isEmpty ? null : errors.join('; '),
      syncedFromCalendar: totalSyncedFromCalendar,
    );
  }

  /// Sync a specific event type (bidirectional)
  Future<SyncResult> syncEventType(CalendarEventType type) async {
    final config = _repository.getConfig(type);
    if (config == null || !config.enabled) {
      return SyncResult(0, 0, 'Event type not enabled');
    }
    return _syncEventTypeBidirectional(config);
  }

  Future<SyncResult> _syncEventTypeBidirectional(CalendarSyncConfig config) async {
    final localEvents = await _fetchEventsForType(config.type);
    final targetCalendarId = config.subCalendarId;
    
    debugPrint('[CalendarSyncService] _syncEventTypeBidirectional: type=${config.type.key}, targetCalendarId=$targetCalendarId, localEvents=${localEvents.length}');

    int created = 0;
    int updated = 0;
    int syncedFromCalendar = 0;
    String? error;

    // Fetch native events for this calendar
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    final endDate = now.add(const Duration(days: 60));
    
    final nativeEvents = await fetchNativeEvents(
      type: config.type,
      calendarId: targetCalendarId,
      start: startDate,
      end: endDate,
    );
    
    debugPrint('[CalendarSyncService] Found ${nativeEvents.length} native events for ${config.type.key}');

    // Create maps for efficient lookup
    final localEventMap = <String, CalendarSyncEvent>{};
    for (final e in localEvents) {
      localEventMap[e.sourceId ?? e.id] = e;
    }
    
    final nativeEventMap = <String, CalendarSyncEvent>{};
    for (final e in nativeEvents) {
      if (e.sourceId != null) {
        nativeEventMap[e.sourceId!] = e;
      }
    }

    // 1. Push local changes to calendar (create/update)
    for (final localEvent in localEvents) {
      try {
        final sourceId = localEvent.sourceId ?? localEvent.id;
        final nativeEvent = nativeEventMap[sourceId];
        
        if (nativeEvent != null) {
          // Check if local event has changed (compare times, title, description)
          if (_hasEventChanged(localEvent, nativeEvent)) {
            await _tryUpdateEvent(nativeEvent.id, localEvent, targetCalendarId);
            updated++;
            debugPrint('[CalendarSyncService] Updated event in calendar: ${localEvent.title}');
          }
        } else {
          // Create new event in calendar
          await _tryCreateEvent(localEvent, targetCalendarId);
          created++;
          debugPrint('[CalendarSyncService] Created event in calendar: ${localEvent.title}');
        }
      } catch (e) {
        error ??= e.toString();
      }
    }

    // 2. Pull changes from calendar to local (bidirectional)
    for (final nativeEvent in nativeEvents) {
      if (nativeEvent.sourceId == null) continue; // Not our event
      
      final localEvent = localEventMap[nativeEvent.sourceId!];
      
      if (localEvent != null) {
        // Event exists in both - check if native was modified by user
        if (_hasEventChanged(nativeEvent, localEvent)) {
          await _applyNativeChangesToLocal(nativeEvent, localEvent);
          syncedFromCalendar++;
          debugPrint('[CalendarSyncService] Synced from calendar to local: ${nativeEvent.title}');
        }
      } else {
        // Event exists in calendar but not in local data - could be deleted locally
        // Optionally: recreate in local data or log
        debugPrint('[CalendarSyncService] Orphan native event (not in local data): ${nativeEvent.title}');
      }
    }

    // 3. Detect deleted events (in local but not in calendar)
    for (final localEvent in localEvents) {
      final sourceId = localEvent.sourceId ?? localEvent.id;
      if (!nativeEventMap.containsKey(sourceId)) {
        // Event was deleted from calendar - optionally recreate or mark
        debugPrint('[CalendarSyncService] Event deleted from calendar: ${localEvent.title}');
      }
    }

    return SyncResult(created, updated, error, syncedFromCalendar: syncedFromCalendar);
  }

  /// Check if two events have different content (ignoring metadata)
  bool _hasEventChanged(CalendarSyncEvent a, CalendarSyncEvent b) {
    return a.title != b.title ||
           a.description != b.description ||
           a.startTime != b.startTime ||
           a.endTime != b.endTime ||
           a.location != b.location;
  }

  /// Apply changes from native calendar event to local data
  Future<void> _applyNativeChangesToLocal(CalendarSyncEvent nativeEvent, CalendarSyncEvent localEvent) async {
    final sourceId = nativeEvent.sourceId!;
    final type = nativeEvent.type;
    
    try {
      switch (type) {
        case CalendarEventType.homework:
          await _updateHomeworkFromCalendar(sourceId, nativeEvent);
          break;
        case CalendarEventType.tests:
          await _updateTestFromCalendar(sourceId, nativeEvent);
          break;
        case CalendarEventType.assignments:
          await _updateAssignmentFromCalendar(sourceId, nativeEvent);
          break;
        case CalendarEventType.conversations:
        case CalendarEventType.learning:
          // Not implemented yet
          break;
      }
    } catch (e) {
      debugPrint('[CalendarSyncService] Failed to apply native changes: $e');
    }
  }

  /// Update homework due date from calendar event
  Future<void> _updateHomeworkFromCalendar(String sourceId, CalendarSyncEvent nativeEvent) async {
    final homeworks = homeworksNotifier.value;
    final index = homeworks.indexWhere((hw) {
      final id = hw['id']?.toString() ?? hw['lessonId']?.toString();
      return id == sourceId;
    });
    
    if (index >= 0) {
      final hw = Map<String, dynamic>.from(homeworks[index]);
      // Update due date to event start date
      final dueDate = DateTime(nativeEvent.startTime.year, nativeEvent.startTime.month, nativeEvent.startTime.day);
      hw['dueDate'] = dueDate.toIso8601String().split('T').first;
      // Update text from description
      hw['text'] = nativeEvent.description;
      homeworks[index] = hw;
      homeworksNotifier.value = List.from(homeworks);
      debugPrint('[CalendarSyncService] Updated homework due date from calendar: $sourceId -> $dueDate');
    }
  }

  /// Update test/lesson from calendar event (limited - timetable comes from server)
  Future<void> _updateTestFromCalendar(String sourceId, CalendarSyncEvent nativeEvent) async {
    // Tests come from server timetable, can't easily modify locally
    // Could store a local override or notification
    debugPrint('[CalendarSyncService] Test event modified in calendar: $sourceId (server-controlled)');
  }

  /// Update assignment/substitution from calendar event
  Future<void> _updateAssignmentFromCalendar(String sourceId, CalendarSyncEvent nativeEvent) async {
    // Assignments come from server timetable
    debugPrint('[CalendarSyncService] Assignment event modified in calendar: $sourceId (server-controlled)');
  }

  Future<void> _tryCreateEvent(CalendarSyncEvent event, String? calendarId) async {
    // Include sourceId in description for tracking
    final description = '${event.description}\n\n[UntisPlus:sourceId:${event.sourceId}]';
    final startMs = event.startTime.millisecondsSinceEpoch;
    final endMs = event.endTime.millisecondsSinceEpoch;

    final success = await CalendarPlatform.addEvent(
      title: event.title,
      description: description,
      startMs: startMs,
      endMs: endMs,
      location: event.location,
      calendarId: calendarId,
      reminderMinutes: const [15, 60],
    );
    if (!success) {
      throw Exception('Failed to create event: ${event.title}');
    }
  }

  Future<void> _tryUpdateEvent(String eventId, CalendarSyncEvent event, String? calendarId) async {
    // For update, we delete the old event and create a new one
    // since the native calendar API doesn't have a direct update method
    await CalendarPlatform.deleteEvent(calendarId: calendarId ?? '', eventId: eventId);
    await _tryCreateEvent(event, calendarId);
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
  final int syncedFromCalendar;
  final String? error;

  const SyncResult(this.created, this.updated, this.error, {this.syncedFromCalendar = 0});

  bool get success => error == null;
  int get total => created + updated + syncedFromCalendar;

  @override
  String toString() {
    var result = 'SyncResult(created: $created, updated: $updated';
    if (syncedFromCalendar > 0) {
      result += ', fromCalendar: $syncedFromCalendar';
    }
    if (error != null) result += ', error: $error';
    return '$result)';
  }
}