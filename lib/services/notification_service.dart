import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest_all.dart' as tz;

/// Identifiers for different notification types.
abstract class NotificationIds {
  static const int currentLesson = 1;
  static const int update = 2;
  static const int dailyBriefing = 3;
  static const int importantChanges = 4;
}

/// Channel identifiers for Android notification channels.
abstract class NotificationChannels {
  static const String currentLesson = 'current_lesson_channel';
  static const String dailyBriefing = 'daily_briefing_channel';
  static const String importantChanges = 'important_changes_channel';
  static const String updates = 'updates_channel';
}

/// Represents an action triggered from a notification.
class NotificationActionEvent {
  const NotificationActionEvent({
    required this.actionId,
    this.currentLesson,
    this.nextLesson,
    this.payload,
  });

  final String actionId;
  final String? currentLesson;
  final String? nextLesson;
  final Map<String, dynamic>? payload;

  @override
  String toString() => 'NotificationActionEvent(actionId: $actionId, payload: $payload)';
}

/// A redesigned service for managing local and progressive notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const MethodChannel _nativeChannel = MethodChannel(
    'untisplus/notifications',
  );

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final StreamController<NotificationActionEvent> _actionController =
      StreamController<NotificationActionEvent>.broadcast();

  bool _initialized = false;
  NotificationActionEvent? _pendingEvent;

  /// Stream of notification actions (e.g., button clicks).
  Stream<NotificationActionEvent> get actionEvents => _actionController.stream;

  /// Consumes the pending action event if the app was launched from a notification.
  NotificationActionEvent? consumePendingActionEvent() {
    final event = _pendingEvent;
    _pendingEvent = null;
    return event;
  }

  /// Initializes the notification service and sets up channels/handlers.
  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    _nativeChannel.setMethodCallHandler(_handleNativeMethodCall);

    // Check if the app was launched via a notification.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;
      if (response != null) {
        _handleNotificationResponse(response);
      }
    }

    _initialized = true;
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'onNotificationAction') {
      final args = call.arguments;
      if (args is Map) {
        final actionId = args['actionId']?.toString() ?? 'open_timetable';
        final event = NotificationActionEvent(
          actionId: actionId,
          currentLesson: args['currentLesson']?.toString(),
          nextLesson: args['nextLesson']?.toString(),
          payload: Map<String, dynamic>.from(args),
        );
        _pendingEvent = event;
        _actionController.add(event);
      }
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId ?? 'open_timetable';
    Map<String, dynamic>? payloadMap;

    if (response.payload?.isNotEmpty ?? false) {
      try {
        payloadMap = jsonDecode(response.payload!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final event = NotificationActionEvent(
      actionId: actionId,
      currentLesson: payloadMap?['currentLesson']?.toString(),
      nextLesson: payloadMap?['nextLesson']?.toString(),
      payload: payloadMap,
    );
    _pendingEvent = event;
    _actionController.add(event);
  }

  /// Requests notification permissions (Android 13+).
  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Shows a progressive notification for the current lesson or break.
  /// On Android, it attempts to use a native high-fidelity progress style.
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

    final hasProgress = maxProgress != null && currentProgress != null;
    final payloadMap = {
      'currentLesson': title,
      'nextLesson': nextLesson ?? '',
      'type': 'progressive',
    };

    // Try native Android implementation for high-quality progress bars.
    if (Platform.isAndroid && hasProgress) {
      try {
        final success = await _nativeChannel.invokeMethod<bool>(
          'showProgressiveNotification',
          {
            'id': id,
            'channelId': NotificationChannels.currentLesson,
            'title': title,
            'body': body,
            'subText': subText,
            'progress': currentProgress,
            'maxProgress': maxProgress,
            'endTimeMs': endTimeMs,
            'locale': locale,
            'currentLesson': title,
            'nextLesson': nextLesson ?? '',
          },
        );
        if (success ?? false) return;
      } catch (e) {
        debugPrint('Native progressive notification failed: $e');
      }
    }

    // Fallback to standard local notifications.
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.currentLesson,
      _getChannelName(locale, NotificationChannels.currentLesson),
      channelDescription: _getChannelDesc(locale, NotificationChannels.currentLesson),
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: hasProgress,
      maxProgress: maxProgress ?? 0,
      progress: currentProgress ?? 0,
      usesChronometer: endTimeMs != null,
      when: endTimeMs,
      chronometerCountDown: true,
      subText: subText,
      category: AndroidNotificationCategory.progress,
      actions: [
        AndroidNotificationAction(
          'open_timetable',
          _getActionLabel(locale, 'open_timetable'),
          showsUserInterface: true,
        ),
        if (nextLesson != null)
          AndroidNotificationAction(
            'open_next_lesson',
            _getActionLabel(locale, 'open_next_lesson'),
            showsUserInterface: true,
          ),
      ],
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: jsonEncode(payloadMap),
    );
  }

  /// Shows a briefing for the school day.
  Future<void> showDailyBriefingNotification({
    required String title,
    required String body,
    required String expandedBody,
    String locale = 'de',
    String? currentLesson,
    String? nextLesson,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.dailyBriefing,
      _getChannelName(locale, NotificationChannels.dailyBriefing),
      channelDescription: _getChannelDesc(locale, NotificationChannels.dailyBriefing),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(expandedBody),
      category: AndroidNotificationCategory.status,
    );

    await _plugin.show(
      id: NotificationIds.dailyBriefing,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: jsonEncode({
        'type': 'briefing',
        'currentLesson': currentLesson ?? '',
        'nextLesson': nextLesson ?? '',
      }),
    );
  }

  /// Notifies about important changes like room swaps or cancellations.
  Future<void> showImportantChangeNotification({
    required String title,
    required String body,
    String locale = 'de',
    String? currentLesson,
    String? nextLesson,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.importantChanges,
      _getChannelName(locale, NotificationChannels.importantChanges),
      channelDescription: _getChannelDesc(locale, NotificationChannels.importantChanges),
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.status,
      groupKey: 'com.ninocss.untisplus.CHANGES',
    );

    await _plugin.show(
      id: NotificationIds.importantChanges,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: jsonEncode({
        'type': 'change',
        'currentLesson': currentLesson ?? '',
        'nextLesson': nextLesson ?? '',
      }),
    );
  }

  /// Shows a notification about an available app update.
  Future<void> showUpdateNotification({
    required int id,
    required String title,
    required String body,
    String locale = 'de',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.updates,
      _getChannelName(locale, NotificationChannels.updates),
      channelDescription: _getChannelDesc(locale, NotificationChannels.updates),
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.recommendation,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: jsonEncode({'type': 'update'}),
    );
  }

  /// Cancels a specific notification by ID.
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  String _getActionLabel(String locale, String actionId) {
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

  String _getChannelName(String locale, String channelId) {
    switch (locale) {
      case 'en':
        if (channelId == NotificationChannels.currentLesson) return 'Current lesson / Break';
        if (channelId == NotificationChannels.dailyBriefing) return 'Daily briefing';
        if (channelId == NotificationChannels.importantChanges) return 'Timetable changes';
        return 'App updates';
      case 'fr':
        if (channelId == NotificationChannels.currentLesson) return 'Cours actuel / Pause';
        if (channelId == NotificationChannels.dailyBriefing) return 'Briefing quotidien';
        if (channelId == NotificationChannels.importantChanges) return 'Changements d\'horaire';
        return 'Mises à jour';
      case 'es':
        if (channelId == NotificationChannels.currentLesson) return 'Clase actual / Descanso';
        if (channelId == NotificationChannels.dailyBriefing) return 'Resumen diario';
        if (channelId == NotificationChannels.importantChanges) return 'Cambios importantes';
        return 'Actualizaciones';
      case 'el':
        if (channelId == NotificationChannels.currentLesson) return 'Τρέχον μάθημα / Διάλειμμα';
        if (channelId == NotificationChannels.dailyBriefing) return 'Ημερήσια ενημέρωση';
        if (channelId == NotificationChannels.importantChanges) return 'Σημαντικές αλλαγές';
        return 'Ενημερώσεις';
      case 'de':
      default:
        if (channelId == NotificationChannels.currentLesson) return 'Aktuelle Stunde / Pause';
        if (channelId == NotificationChannels.dailyBriefing) return 'Tagesbriefing';
        if (channelId == NotificationChannels.importantChanges) return 'Stundenplan-Änderungen';
        return 'App-Updates';
    }
  }

  String _getChannelDesc(String locale, String channelId) {
    switch (locale) {
      case 'en':
        if (channelId == NotificationChannels.currentLesson) return 'Ongoing status of the current lesson.';
        if (channelId == NotificationChannels.dailyBriefing) return 'Morning overview of your school day.';
        if (channelId == NotificationChannels.importantChanges) return 'Notifies about cancellations and room changes.';
        return 'Notifications about app improvements.';
      case 'fr':
        if (channelId == NotificationChannels.currentLesson) return 'Statut actuel du cours ou de la pause.';
        if (channelId == NotificationChannels.dailyBriefing) return 'Aperçu matinal de votre journée d\'école.';
        if (channelId == NotificationChannels.importantChanges) return 'Signale les annulations et changements de salle.';
        return 'Informations sur les améliorations de l\'application.';
      case 'de':
      default:
        if (channelId == NotificationChannels.currentLesson) return 'Laufender Status der aktuellen Stunde.';
        if (channelId == NotificationChannels.dailyBriefing) return 'Morgendlicher Überblick über den Schultag.';
        if (channelId == NotificationChannels.importantChanges) return 'Hinweise zu Ausfall oder Raumwechsel.';
        return 'Hinweise zu App-Verbesserungen.';
    }
  }
}
