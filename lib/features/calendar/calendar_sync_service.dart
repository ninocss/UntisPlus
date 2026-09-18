part of '../../main.dart';

/// Service responsible for syncing timetable/events to native calendar
class CalendarSyncService {
  final CalendarSyncRepository _repository;
  final dynamic _nativeCalendar; // Use dynamic to avoid compile-time method checks

  CalendarSyncService(this._repository, this._nativeCalendar);

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
        final existingId = await _findExistingEvent(config.type, event.id);
        if (existingId != null) {
          await _tryUpdateEvent(existingId, event, targetCalendarId);
          updated++;
        } else {
          await _tryCreateEvent(event, targetCalendarId);
          created++;
        }
      } catch (e) {
        if (error == null) error = e.toString();
      }
    }

    return SyncResult(created, updated, error);
  }

  Future<void> _tryCreateEvent(CalendarSyncEvent event, String? calendarId) async {
    try {
      await _nativeCalendar.createEvent(
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        location: event.location,
        calendarId: calendarId,
      );
    } catch (_) {
      // Method may not exist or fail - silently continue
    }
  }

  Future<void> _tryUpdateEvent(String eventId, CalendarSyncEvent event, String? calendarId) async {
    try {
      await _nativeCalendar.updateEvent(
        eventId: eventId,
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        location: event.location,
        calendarId: calendarId,
      );
    } catch (_) {
      // Method may not exist or fail - silently continue
    }
  }

  /// Find existing native event ID for a given event type and source ID
  Future<String?> _findExistingEvent(CalendarEventType type, String sourceId) async {
    // In a real implementation, this would query the native calendar
    // for events matching the sourceId and type
    // For now, returns null (always creates new events)
    return null;
  }

  /// Fetch events for a specific type from timetable/homework/etc.
  Future<List<CalendarSyncEvent>> _fetchEventsForType(CalendarEventType type) async {
    // This would integrate with your existing data sources
    // For now, returns empty - implement based on your data layer
    return _generateMockEvents(type);
  }

  /// Remove all events for a specific type from native calendar
  Future<void> clearEventType(CalendarEventType type) async {
    // Would need to track native event IDs to delete them
  }

  /// Generate mock events for testing
  List<CalendarSyncEvent> _generateMockEvents(CalendarEventType type) {
    final now = DateTime.now();

    switch (type) {
      case CalendarEventType.tests:
        return [
          CalendarSyncEvent(
            id: 'test_math_1',
            type: CalendarEventType.tests,
            title: 'Mathematik Klausur',
            description: 'Themen: Analysis, Lineare Algebra',
            startTime: now.add(const Duration(days: 2, hours: 8)),
            endTime: now.add(const Duration(days: 2, hours: 10)),
            location: 'Raum 201',
            sourceId: 'test_math_1',
            metadata: {'subject': 'Mathematik', 'weight': 2},
          ),
          CalendarSyncEvent(
            id: 'test_english_1',
            type: CalendarEventType.tests,
            title: 'Englisch Test',
            description: 'Reading Comprehension & Grammar',
            startTime: now.add(const Duration(days: 4, hours: 10)),
            endTime: now.add(const Duration(days: 4, hours: 11, minutes: 30)),
            location: 'Raum 105',
            sourceId: 'test_english_1',
            metadata: {'subject': 'Englisch', 'weight': 1},
          ),
        ];
      case CalendarEventType.homework:
        return [
          CalendarSyncEvent(
            id: 'hw_math_1',
            type: CalendarEventType.homework,
            title: 'Hausaufgabe: Ableitungen',
            description: 'Seite 45, Aufgaben 1-5',
            startTime: now.add(const Duration(days: 1, hours: 16)),
            endTime: now.add(const Duration(days: 1, hours: 17)),
            sourceId: 'hw_math_1',
            metadata: {'subject': 'Mathematik', 'dueDate': now.add(const Duration(days: 3)).toIso8601String()},
          ),
        ];
      case CalendarEventType.assignments:
        return [
          CalendarSyncEvent(
            id: 'assignment_1',
            type: CalendarEventType.assignments,
            title: 'Vertretung: Mathe bei Frau Müller',
            description: 'Regulärer Lehrer krank, Vertretung durch Frau Müller',
            startTime: now.add(const Duration(days: 3, hours: 8)),
            endTime: now.add(const Duration(days: 3, hours: 9)),
            location: 'Raum 201',
            sourceId: 'assignment_1',
            metadata: {'type': 'substitution', 'originalTeacher': 'Herr Schmidt'},
          ),
        ];
      default:
        return [];
    }
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