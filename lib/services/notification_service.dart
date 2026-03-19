import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

    _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  Future<void> showProgressiveNotification({
    required int id,
    required String title,
    required String body,
    int? maxProgress,
    int? currentProgress,
    int? endTimeMs,
    String? subText,
  }) async {
    final bool hasProgress = maxProgress != null && currentProgress != null;
    
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'progressive_channel',
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
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'open_app',
          'Details öffnen',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );
    
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }
}