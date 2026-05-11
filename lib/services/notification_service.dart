import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest_all.dart' as tz;

const int kCurrentLessonNotificationId = 1;
const int kUpdateNotificationId = 2;
const int kDailyBriefingNotificationId = 3;
const int kImportantChangesNotificationId = 4;

const String kCurrentLessonChannelId = 'current_lesson_channel';
const String kDailyBriefingChannelId = 'daily_briefing_channel';
const String kImportantChangesChannelId = 'important_changes_channel';
const String kUpdatesChannelId = 'updates_channel';

class NotificationActionEvent {
  const NotificationActionEvent({
    required this.actionId,
    this.currentLesson,
    this.nextLesson,
  });

  final String actionId;
  final String? currentLesson;
  final String? nextLesson;
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const MethodChannel _nativeChannel = MethodChannel(
    'untisplus/notifications',
  );
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationActionEvent> _actionStreamController =
      StreamController<NotificationActionEvent>.broadcast();

  bool _initialized = false;
  NotificationActionEvent? _pendingActionEvent;

  Stream<NotificationActionEvent> get actionEvents =>
      _actionStreamController.stream;

  NotificationActionEvent? consumePendingActionEvent() {
    final event = _pendingActionEvent;
    _pendingActionEvent = null;
    return event;
  }

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _nativeChannel.setMethodCallHandler((call) async {
      if (call.method != 'onNotificationAction') return;
      final args = call.arguments;
      if (args is! Map) return;
      final actionId = (args['actionId'] ?? '').toString().trim();
      if (actionId.isEmpty) return;
      final event = NotificationActionEvent(
        actionId: actionId,
        currentLesson: (args['currentLesson'] ?? '').toString(),
        nextLesson: (args['nextLesson'] ?? '').toString(),
      );
      _pendingActionEvent = event;
      _actionStreamController.add(event);
    });

    final launchDetails = await _flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchResponse != null) {
      _onNotificationResponse(launchResponse);
    }

    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final actionId =
        (response.actionId ?? 'open_timetable').toString().trim().isEmpty
        ? 'open_timetable'
        : (response.actionId ?? 'open_timetable').toString();

    String? currentLesson;
    String? nextLesson;
    final payload = response.payload;
    if (payload != null && payload.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          currentLesson = decoded['currentLesson']?.toString();
          nextLesson = decoded['nextLesson']?.toString();
        }
      } catch (_) {
        // Ignore malformed payloads and still propagate the action id.
      }
    }

    final event = NotificationActionEvent(
      actionId: actionId,
      currentLesson: currentLesson,
      nextLesson: nextLesson,
    );
    _pendingActionEvent = event;
    _actionStreamController.add(event);
  }

  String _labelForAction({required String locale, required String actionId}) {
    switch (locale) {
      case 'en':
        if (actionId == 'open_next_lesson') return 'Next lesson';
        if (actionId == 'open_free_rooms') return 'Free rooms';
        if (actionId == 'open_day') return 'Open day';
        return 'Timetable';
      case 'fr':
        if (actionId == 'open_next_lesson') return 'Cours suivant';
        if (actionId == 'open_free_rooms') return 'Salles libres';
        if (actionId == 'open_day') return 'Ouvrir la journée';
        return 'Emploi du temps';
      case 'es':
        if (actionId == 'open_next_lesson') return 'Siguiente clase';
        if (actionId == 'open_free_rooms') return 'Aulas libres';
        if (actionId == 'open_day') return 'Abrir día';
        return 'Horario';
      case 'el':
        if (actionId == 'open_next_lesson') return 'Επόμενο μάθημα';
        if (actionId == 'open_free_rooms') return 'Ελεύθερες αίθουσες';
        if (actionId == 'open_day') return 'Άνοιγμα ημέρας';
        return 'Πρόγραμμα';
      case 'de':
      default:
        if (actionId == 'open_next_lesson') return 'Nächste Stunde';
        if (actionId == 'open_free_rooms') return 'Freie Räume';
        if (actionId == 'open_day') return 'Tag öffnen';
        return 'Stundenplan';
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showProgressiveNotification({
    required int id,
    required String title,
    required String body,
    int? maxProgress,
    int? currentProgress,
    int? endTimeMs,
    String? subText,
    String locale = 'de',
    String? nextLesson,
  }) async {
    if (kIsWeb) return;

    final bool hasProgress = maxProgress != null && currentProgress != null;

    final payload = jsonEncode({
      'currentLesson': title,
      'nextLesson': nextLesson ?? '',
    });

    if (Platform.isAndroid && hasProgress) {
      try {
        final postedNative =
            await _nativeChannel.invokeMethod<bool>(
              'showProgressCentricNotification',
              <String, dynamic>{
                'id': id,
                'channelId': kCurrentLessonChannelId,
                'title': title,
                'body': body,
                'subText': subText,
                'maxProgress': maxProgress,
                'currentProgress': currentProgress,
                'endTimeMs': endTimeMs,
                'locale': locale,
                'currentLesson': title,
                'nextLesson': nextLesson ?? '',
              },
            ) ??
            false;
        if (postedNative) {
          return;
        }
      } catch (_) {
        // Fallback to cross-platform notification below.
      }
    }

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          kCurrentLessonChannelId,
          'Aktuelle Stunde / Pause',
          channelDescription: 'Zeigt die aktuelle Stunde oder Pause an.',
          importance: Importance.defaultImportance,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
          colorized: false,
          subText: subText,
          showProgress: hasProgress,
          maxProgress: maxProgress ?? 0,
          progress: currentProgress ?? 0,
          indeterminate: false,
          usesChronometer: endTimeMs != null,
          when: endTimeMs,
          chronometerCountDown: endTimeMs != null,
          category: AndroidNotificationCategory.progress,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'open_timetable',
              _labelForAction(locale: locale, actionId: 'open_timetable'),
              showsUserInterface: true,
              cancelNotification: false,
            ),
            AndroidNotificationAction(
              'open_next_lesson',
              _labelForAction(locale: locale, actionId: 'open_next_lesson'),
              showsUserInterface: true,
              cancelNotification: false,
            ),
            AndroidNotificationAction(
              'open_free_rooms',
              _labelForAction(locale: locale, actionId: 'open_free_rooms'),
              showsUserInterface: true,
              cancelNotification: false,
            ),
          ],
        );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> showDailyBriefingNotification({
    required String title,
    required String body,
    required String expandedBody,
    String locale = 'de',
    String? currentLesson,
    String? nextLesson,
  }) async {
    final android = AndroidNotificationDetails(
      kDailyBriefingChannelId,
      'Tagesbriefing',
      channelDescription: 'Gibt am Morgen einen kompakten Tagesüberblick.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: false,
      autoCancel: true,
      category: AndroidNotificationCategory.status,
      styleInformation: BigTextStyleInformation(expandedBody),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'open_timetable',
          _labelForAction(locale: locale, actionId: 'open_day'),
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final details = NotificationDetails(android: android);
    await _flutterLocalNotificationsPlugin.show(
      id: kDailyBriefingNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode({
        'currentLesson': currentLesson ?? '',
        'nextLesson': nextLesson ?? '',
      }),
    );
  }

  Future<void> showImportantChangeNotification({
    required String title,
    required String body,
    String locale = 'de',
    String? currentLesson,
    String? nextLesson,
  }) async {
    final android = AndroidNotificationDetails(
      kImportantChangesChannelId,
      'Wichtige Stundenplan-Änderungen',
      channelDescription:
          'Hinweise bei Änderungen wie Ausfall oder Raumwechsel.',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      category: AndroidNotificationCategory.status,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'open_timetable',
          _labelForAction(locale: locale, actionId: 'open_timetable'),
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final details = NotificationDetails(android: android);
    await _flutterLocalNotificationsPlugin.show(
      id: kImportantChangesNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode({
        'currentLesson': currentLesson ?? '',
        'nextLesson': nextLesson ?? '',
      }),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> showUpdateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const android = AndroidNotificationDetails(
      kUpdatesChannelId,
      'App Updates',
      channelDescription: 'Informiert über neue App-Versionen.',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.recommendation,
      autoCancel: true,
      ongoing: false,
    );

    const details = NotificationDetails(android: android);
    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
