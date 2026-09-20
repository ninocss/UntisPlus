import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CalendarPlatform {
  static const MethodChannel _channel = MethodChannel('untisplus/calendar');

  static Future<List<Map<String, dynamic>>> getCalendars() async {
    final result = await _channel.invokeMethod('getCalendars');
    final calendars = List<Map<String, dynamic>>.from(result as List);
    debugPrint('[CalendarPlatform] getCalendars: ${calendars.length} calendars');
    for (final cal in calendars) {
      debugPrint('[CalendarPlatform]   - ${cal['name']} (id: ${cal['id']}, default: ${cal['isDefault']})');
    }
    return calendars;
  }

  static Future<String?> createCalendar({
    required String name,
    required String color,
    String accountName = 'Untis+',
  }) async {
    final result = await _channel.invokeMethod('createCalendar', {
      'name': name,
      'color': color,
      'accountName': accountName,
    });
    debugPrint('[CalendarPlatform] createCalendar: $name -> $result');
    return result;
  }

  static Future<List<Map<String, dynamic>>> getEvents({
    String? calendarId,
    DateTime? start,
    DateTime? end,
  }) async {
    final startMs = start?.millisecondsSinceEpoch ?? 0;
    final endMs = end?.millisecondsSinceEpoch ?? 0;
    final result = await _channel.invokeMethod('getEvents', {
      'calendarId': calendarId,
      'startMs': startMs,
      'endMs': endMs,
    });
    return List<Map<String, dynamic>>.from(result as List);
  }

  static Future<bool> deleteEvent({
    required String calendarId,
    required String eventId,
  }) async {
    return await _channel.invokeMethod('deleteEvent', {
      'calendarId': calendarId,
      'eventId': eventId,
    }) as bool? ?? false;
  }

  static Future<bool> addEvent({
    required String title,
    required String description,
    required int startMs,
    required int endMs,
    String? location,
    String? calendarId,
    List<int>? reminderMinutes,
    bool allDay = false,
  }) async {
    debugPrint('[CalendarPlatform] addEvent: title=$title, calendarId=$calendarId');
    final result = await _channel.invokeMethod('addEvent', {
      'title': title,
      'description': description,
      'startMs': startMs,
      'endMs': endMs,
      'location': location,
      'calendarId': calendarId,
      'reminderMinutes': reminderMinutes ?? [15, 60],
      'allDay': allDay,
    });
    debugPrint('[CalendarPlatform] addEvent result: $result');
    return result as bool? ?? false;
  }
}