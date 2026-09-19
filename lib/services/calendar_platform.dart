import 'dart:async';
import 'package:flutter/services.dart';

class CalendarPlatform {
  static const MethodChannel _channel = MethodChannel('untisplus/calendar');

  static Future<List<Map<String, dynamic>>> getCalendars() async {
    try {
      final result = await _channel.invokeMethod('getCalendars');
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      return [];
    }
  }

  static Future<String?> createCalendar({
    required String name,
    required String color,
    String accountName = 'Untis+',
  }) async {
    try {
      return await _channel.invokeMethod('createCalendar', {
        'name': name,
        'color': color,
        'accountName': accountName,
      });
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getEvents({
    String? calendarId,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final startMs = start?.millisecondsSinceEpoch ?? 0;
      final endMs = end?.millisecondsSinceEpoch ?? 0;
      final result = await _channel.invokeMethod('getEvents', {
        'calendarId': calendarId,
        'startMs': startMs,
        'endMs': endMs,
      });
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      return [];
    }
  }

  static Future<bool> deleteEvent({
    required String calendarId,
    required String eventId,
  }) async {
    try {
      return await _channel.invokeMethod('deleteEvent', {
        'calendarId': calendarId,
        'eventId': eventId,
      }) as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}