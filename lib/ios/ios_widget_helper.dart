// iOS-specific widget helper
//
// This file contains iOS-specific implementations for home screen widgets,
// Live Activities, and widget configuration using SwiftUI, WidgetKit,
// and ActivityKit.

import 'dart:async';
import 'dart:io' show Platform;

/// Checks if the app is running on iOS.
bool get isIOS => Platform.isIOS;

/// Checks if WidgetKit is available (iOS 14+).
bool get isWidgetKitAvailable => isIOS;

/// Checks if Live Activities are available (iOS 16.1+).
bool get isLiveActivitiesAvailable => isIOS;

/// Checks if Dynamic Island is available (iOS 16.1+ on supported devices).
bool get isDynamicIslandAvailable => isIOS;

/// Widget family types supported by WidgetKit.
enum IosWidgetFamily {
  /// Small square widget (systemSmall).
  systemSmall,

  /// Medium rectangle (systemMedium).
  systemMedium,

  /// Large square (systemLarge).
  systemLarge,

  /// Extra large (systemExtraLarge, iPadOS 15+).
  systemExtraLarge,

  /// Accessory circular (watchOS / Lock Screen).
  accessoryCircular,

  /// Accessory rectangular (Lock Screen).
  accessoryRectangular,

  /// Accessory inline (Lock Screen).
  accessoryInline,
}

/// Widget kind identifiers.
class IosWidgetKind {
  static const String currentLesson = 'current_lesson';
  static const String dailySchedule = 'daily_schedule';
  static const String customWidget = 'custom_widget';
  static const String summary = 'summary';
}

/// iOS Widget configuration model.
class IosWidgetConfig {
  final String kind;
  final String displayName;
  final String description;
  final List<IosWidgetFamily> supportedFamilies;
  final bool supportsLiveActivity;
  final Duration? updateInterval;

  const IosWidgetConfig({
    required this.kind,
    required this.displayName,
    required this.description,
    this.supportedFamilies = const [
      IosWidgetFamily.systemSmall,
      IosWidgetFamily.systemMedium,
      IosWidgetFamily.systemLarge,
    ],
    this.supportsLiveActivity = false,
    this.updateInterval,
  });
}

/// Predefined widget configurations.
class IosWidgetConfigs {
  static final Map<String, IosWidgetConfig> _configs = {
    IosWidgetKind.currentLesson: IosWidgetConfig(
      kind: IosWidgetKind.currentLesson,
      displayName: 'Current Lesson',
      description: 'Shows the currently ongoing or next lesson',
      supportedFamilies: [
        IosWidgetFamily.systemSmall,
        IosWidgetFamily.systemMedium,
      ],
      supportsLiveActivity: true,
      updateInterval: const Duration(minutes: 5),
    ),
    IosWidgetKind.dailySchedule: IosWidgetConfig(
      kind: IosWidgetKind.dailySchedule,
      displayName: 'Daily Schedule',
      description: 'Shows the full day schedule',
      supportedFamilies: [
        IosWidgetFamily.systemMedium,
        IosWidgetFamily.systemLarge,
      ],
      updateInterval: const Duration(minutes: 15),
    ),
    IosWidgetKind.customWidget: IosWidgetConfig(
      kind: IosWidgetKind.customWidget,
      displayName: 'Custom Widget',
      description: 'User-configured custom widget',
      supportedFamilies: IosWidgetFamily.values,
      updateInterval: const Duration(minutes: 30),
    ),
    IosWidgetKind.summary: IosWidgetConfig(
      kind: IosWidgetKind.summary,
      displayName: 'Summary',
      description: 'Daily overview with key info',
      supportedFamilies: [
        IosWidgetFamily.systemSmall,
        IosWidgetFamily.systemMedium,
      ],
      updateInterval: const Duration(hours: 1),
    ),
  };

  static IosWidgetConfig? get(String kind) => _configs[kind];
  static Iterable<IosWidgetConfig> get all => _configs.values;
}

/// iOS Widget service for managing widget lifecycle.
class IosWidgetService {
  static final IosWidgetService _instance = IosWidgetService._internal();
  factory IosWidgetService() => _instance;
  IosWidgetService._internal();

  bool _initialized = false;
  final Map<String, DateTime> _lastUpdateTimes = {};

  /// Initialize the widget service.
  Future<void> initialize() async {
    if (_initialized) return;
    if (!isIOS) {
      throw UnsupportedError('IosWidgetService only works on iOS');
    }
    _initialized = true;
  }

  /// Reload all widget timelines.
  Future<void> reloadAllTimelines() async {
    if (!_initialized) await initialize();
    // Implementation would call WidgetCenter.shared.reloadAllTimelines()
    // via platform channel
  }

  /// Reload timeline for a specific widget kind.
  Future<void> reloadTimeline(String kind) async {
    if (!_initialized) await initialize();
    // Implementation would call WidgetCenter.shared.reloadTimelines(ofKind: kind)
    // via platform channel
  }

  /// Get widget configuration for a kind.
  IosWidgetConfig? getConfig(String kind) => IosWidgetConfigs.get(kind);

  /// Check if a widget kind supports Live Activities.
  bool supportsLiveActivity(String kind) {
    return IosWidgetConfigs.get(kind)?.supportsLiveActivity ?? false;
  }

  /// Get the recommended update interval for a widget.
  Duration? getUpdateInterval(String kind) {
    return IosWidgetConfigs.get(kind)?.updateInterval;
  }

  /// Record last update time.
  void recordUpdate(String kind) {
    _lastUpdateTimes[kind] = DateTime.now();
  }

  /// Get last update time for a widget.
  DateTime? getLastUpdate(String kind) => _lastUpdateTimes[kind];
}

/// iOS Live Activity service.
class IosLiveActivityService {
  static final IosLiveActivityService _instance = IosLiveActivityService._internal();
  factory IosLiveActivityService() => _instance;
  IosLiveActivityService._internal();

  final Map<String, String> _activeActivities = {};

  /// Start a Live Activity.
  ///
  /// Returns the activity ID if successful.
  Future<String?> start({
    required String kind,
    required Map<String, dynamic> attributes,
    required Map<String, dynamic> contentState,
    Duration? staleDate,
  }) async {
    if (!isLiveActivitiesAvailable) return null;
    // Implementation would call Activity.request() via platform channel
    // For now, return a placeholder ID
    final id = 'la_${DateTime.now().millisecondsSinceEpoch}';
    _activeActivities[id] = kind;
    return id;
  }

  /// Update a Live Activity's content state.
  Future<void> update({
    required String activityId,
    required Map<String, dynamic> contentState,
    Duration? staleDate,
  }) async {
    if (!_activeActivities.containsKey(activityId)) return;
    // Implementation would call activity.update() via platform channel
  }

  /// End a Live Activity.
  Future<void> end({
    required String activityId,
    Map<String, dynamic>? finalContentState,
    Duration? dismissalPolicy,
  }) async {
    if (!_activeActivities.containsKey(activityId)) return;
    // Implementation would call activity.end() via platform channel
    _activeActivities.remove(activityId);
  }

  /// Get all active activity IDs for a widget kind.
  List<String> getActiveActivities(String kind) {
    return _activeActivities.entries
        .where((e) => e.value == kind)
        .map((e) => e.key)
        .toList();
  }

  /// End all activities for a widget kind.
  Future<void> endAllForKind(String kind) async {
    final ids = getActiveActivities(kind);
    for (final id in ids) {
      await end(activityId: id);
    }
  }
}

/// iOS widget data models for timeline entries.
class IosWidgetTimelineEntry {
  final DateTime date;
  final Map<String, dynamic> data;
  final Duration? relevanceDuration;

  const IosWidgetTimelineEntry({
    required this.date,
    required this.data,
    this.relevanceDuration,
  });
}

/// iOS widget data provider protocol.
abstract class IosWidgetDataProvider {
  /// Get timeline entries for a widget.
  Future<List<IosWidgetTimelineEntry>> getTimeline({
    required String kind,
    required IosWidgetFamily family,
    required DateTime afterDate,
    int limit = 100,
  });

  /// Get placeholder view data.
  Map<String, dynamic> getPlaceholder(String kind, IosWidgetFamily family);

  /// Get snapshot data for widget gallery.
  Map<String, dynamic> getSnapshot(String kind, IosWidgetFamily family);
}

/// iOS Lock Screen widget support.
class IosLockScreenWidgets {
  /// Get available Lock Screen widget families.
  static List<IosWidgetFamily> getLockScreenFamilies() {
    return [
      IosWidgetFamily.accessoryCircular,
      IosWidgetFamily.accessoryRectangular,
      IosWidgetFamily.accessoryInline,
    ];
  }

  /// Check if a widget supports Lock Screen.
  static bool supportsLockScreen(String kind) {
    final config = IosWidgetConfigs.get(kind);
    if (config == null) return false;
    final families = config.supportedFamilies;
    return families.any((f) =>
        f == IosWidgetFamily.accessoryCircular ||
        f == IosWidgetFamily.accessoryRectangular ||
        f == IosWidgetFamily.accessoryInline);
  }
}