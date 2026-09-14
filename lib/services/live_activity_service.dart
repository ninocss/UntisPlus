import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Drives the iOS Live Activity that mirrors Android's ongoing "current
/// lesson" notification (progress bar + countdown).
///
/// The activity is hosted by the UntisWidget extension (ActivityKit) and fed
/// by the Runner through the `untisplus/live_activities` channel.
class LiveActivityService {
  LiveActivityService._();

  static final LiveActivityService instance = LiveActivityService._();

  static const MethodChannel _channel = MethodChannel(
    'untisplus/live_activities',
  );

  /// Starts or updates the Live Activity with the current lesson state.
  Future<void> upsert({
    required String lessonName,
    required String nextLesson,
    required String timeRemaining,
  }) async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _channel.invokeMethod('upsert', {
        'lessonName': lessonName,
        'nextLesson': nextLesson,
        'timeRemaining': timeRemaining,
      });
    } catch (e) {
      debugPrint('LiveActivity upsert failed: $e');
    }
  }

  /// Ends the Live Activity (no active lesson / disabled setting).
  Future<void> end() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _channel.invokeMethod('end');
    } catch (e) {
      debugPrint('LiveActivity end failed: $e');
    }
  }
}