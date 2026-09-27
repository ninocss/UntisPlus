// iOS-specific general helpers
//
// This file contains iOS-specific utilities, extensions, and platform-specific
// implementations for common tasks like haptics, permissions, system services,
// and iOS-specific UI patterns.

export 'ios_ai_helper.dart' hide isIOS;
export 'ios_widget_helper.dart' hide isIOS;

import 'dart:async'
    show Future;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show
        BuildContext,
        FocusScope,
        MediaQuery,
        ThemeMode;

/// Checks if the app is running on iOS.
bool get isIOS => Platform.isIOS;

/// Checks if the app is running on macOS (Mac Catalyst).
bool get isMacOS => Platform.isMacOS;

/// Checks if the app is running on iPadOS.
bool get isIPadOS => Platform.isIOS && Platform.operatingSystemVersion.contains('iPad');

/// Checks if the app is running on iPhone.
bool get isIPhoneOS => Platform.isIOS && !isIPadOS;

/// iOS version information.
class IosVersion {
  final int major;
  final int minor;
  final int patch;

  const IosVersion(this.major, this.minor, this.patch);

  static IosVersion? parse(String? versionString) {
    if (versionString == null) return null;
    final match = RegExp(r'(\d+)\.(\d+)(?:\.(\d+))?').firstMatch(versionString);
    if (match == null) return null;
    return IosVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.tryParse(match.group(3) ?? '0') ?? 0,
    );
  }

  bool get isAtLeast14 => major >= 14;
  bool get isAtLeast15 => major >= 15;
  bool get isAtLeast16 => major >= 16;
  bool get isAtLeast17 => major >= 17;
  bool get isAtLeast18 => major >= 18;

  @override
  String toString() => '$major.$minor.$patch';
}

/// Get iOS version from platform.
Future<IosVersion?> getIosVersion() async {
  if (!Platform.isIOS && !Platform.isMacOS) return null;
  // Implementation would get version via platform channel
  return null;
}

/// iOS-specific haptic feedback.
class IosHaptics {
  /// Light impact feedback (selection change, toggle).
  static Future<void> lightImpact() async {
    if (!Platform.isIOS) return;
    // Implementation would call UIImpactFeedbackGenerator(style: .light)
    // via platform channel
  }

  /// Medium impact feedback (button press, card tap).
  static Future<void> mediumImpact() async {
    if (!Platform.isIOS) return;
    // Implementation would call UIImpactFeedbackGenerator(style: .medium)
  }

  /// Heavy impact feedback (error, destructive action).
  static Future<void> heavyImpact() async {
    if (!Platform.isIOS) return;
    // Implementation would call UIImpactFeedbackGenerator(style: .heavy)
  }

  /// Selection feedback (picker change, segment switch).
  static Future<void> selectionChanged() async {
    if (!Platform.isIOS) return;
    // Implementation would call UISelectionFeedbackGenerator()
  }

  /// Success notification (task completed).
  static Future<void> success() async {
    if (!Platform.isIOS) return;
    // Implementation would call UINotificationFeedbackGenerator(.success)
  }

  /// Warning notification (warning state).
  static Future<void> warning() async {
    if (!Platform.isIOS) return;
    // Implementation would call UINotificationFeedbackGenerator(.warning)
  }

  /// Error notification (error state).
  static Future<void> error() async {
    if (!Platform.isIOS) return;
    // Implementation would call UINotificationFeedbackGenerator(.error)
  }
}

/// iOS-specific permissions helper.
class IosPermissions {
  /// Check if camera permission is granted.
  static Future<bool> isCameraAuthorized() async {
    if (!Platform.isIOS) return false;
    // Implementation would check AVCaptureDevice.authorizationStatus
    return false;
  }

  /// Request camera permission.
  static Future<bool> requestCameraPermission() async {
    if (!Platform.isIOS) return false;
    // Implementation would request AVCaptureDevice.requestAccessForMediaType
    return false;
  }

  /// Check if microphone permission is granted.
  static Future<bool> isMicrophoneAuthorized() async {
    if (!Platform.isIOS) return false;
    // Implementation would check AVAudioSession.sharedInstance().recordPermission
    return false;
  }

  /// Request microphone permission.
  static Future<bool> requestMicrophonePermission() async {
    if (!Platform.isIOS) return false;
    // Implementation would request AVAudioSession.recordPermission
    return false;
  }

  /// Check if photos permission is granted.
  static Future<bool> isPhotosAuthorized() async {
    if (!Platform.isIOS) return false;
    // Implementation would check PHPhotoLibrary.authorizationStatus
    return false;
  }

  /// Request photos permission.
  static Future<bool> requestPhotosPermission({bool addOnly = false}) async {
    if (!Platform.isIOS) return false;
    // Implementation would request PHPhotoLibrary.requestAuthorization
    return false;
  }

  /// Check if location permission is granted.
  static Future<bool> isLocationAuthorized({bool always = false}) async {
    if (!Platform.isIOS) return false;
    // Implementation would check CLLocationManager.authorizationStatus
    return false;
  }

  /// Request location permission.
  static Future<bool> requestLocationPermission({bool always = false}) async {
    if (!Platform.isIOS) return false;
    // Implementation would request CLLocationManager.requestWhenInUseAuthorization
    // or requestAlwaysAuthorization
    return false;
  }

  /// Check if notifications are authorized.
  static Future<bool> isNotificationsAuthorized() async {
    if (!Platform.isIOS) return false;
    // Implementation would check UNUserNotificationCenter.current().getNotificationSettings
    return false;
  }

  /// Request notifications permission.
  static Future<bool> requestNotificationsPermission() async {
    if (!Platform.isIOS) return false;
    // Implementation would request UNUserNotificationCenter.requestAuthorization
    return false;
  }

  /// Open app settings.
  static Future<void> openSettings() async {
    if (!Platform.isIOS) return;
    // Implementation would open UIApplication.openSettingsURLString
  }
}

/// iOS-specific safe area utilities.
class IosSafeArea {
  /// Get the top safe area inset (status bar + navigation bar on iPhone X+).
  static Future<double> getTopInset(BuildContext context) async {
    // Implementation would use MediaQuery or platform channel
    return MediaQuery.of(context).padding.top;
  }

  /// Get the bottom safe area inset (home indicator on iPhone X+).
  static Future<double> getBottomInset(BuildContext context) async {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Get left safe area inset.
  static Future<double> getLeftInset(BuildContext context) async {
    return MediaQuery.of(context).padding.left;
  }

  /// Get right safe area inset.
  static Future<double> getRightInset(BuildContext context) async {
    return MediaQuery.of(context).padding.right;
  }

  /// Check if device has a notch / Dynamic Island.
  static Future<bool> hasNotchOrDynamicIsland() async {
    if (!Platform.isIOS) return false;
    // Implementation would check device model or safe area insets
    return false;
  }

  /// Check if device has Dynamic Island (iPhone 14 Pro+).
  static Future<bool> hasDynamicIsland() async {
    if (!Platform.isIOS) return false;
    // Implementation would check device model
    return false;
  }
}

/// iOS-specific appearance and theming.
class IosAppearance {
  /// Check if dark mode is enabled.
  static bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  /// Get system theme mode.
  static ThemeMode getSystemThemeMode() {
    // Implementation would check UITraitCollection.userInterfaceStyle
    return ThemeMode.system;
  }

  /// Check if Reduce Motion is enabled.
  static Future<bool> isReduceMotionEnabled() async {
    if (!Platform.isIOS) return false;
    // Implementation would check UIAccessibility.isReduceMotionEnabled
    return false;
  }

  /// Check if Reduce Transparency is enabled.
  static Future<bool> isReduceTransparencyEnabled() async {
    if (!Platform.isIOS) return false;
    // Implementation would check UIAccessibility.isReduceTransparencyEnabled
    return false;
  }

  /// Check if Bold Text is enabled.
  static Future<bool> isBoldTextEnabled() async {
    if (!Platform.isIOS) return false;
    // Implementation would check UIAccessibility.isBoldTextEnabled
    return false;
  }

  /// Check if Differentiate Without Color is enabled.
  static Future<bool> isDifferentiateWithoutColorEnabled() async {
    if (!Platform.isIOS) return false;
    // Implementation would check UIAccessibility.isDifferentiateWithoutColorEnabled
    return false;
  }
}

/// iOS-specific keyboard utilities.
class IosKeyboard {
  /// Check if keyboard is currently visible.
  static bool isVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get keyboard height.
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Dismiss keyboard.
  static void dismiss(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

/// iOS-specific URL schemes and deep linking.
class IosDeepLinks {
  /// Open app settings.
  static Future<void> openAppSettings() async {
    if (!Platform.isIOS) return;
    // Implementation would open UIApplication.openSettingsURLString
  }

  /// Open a URL in Safari (external browser).
  static Future<bool> openInSafari(String url) async {
    if (!Platform.isIOS) return false;
    // Implementation would use UIApplication.open with .safariServices
    return false;
  }

  /// Open a URL in SFSafariViewController (in-app browser).
  static Future<bool> openInSafariViewController(String url) async {
    if (!Platform.isIOS) return false;
    // Implementation would present SFSafariViewController
    return false;
  }

  /// Open Mail compose.
  static Future<void> openMail({
    required String to,
    String? subject,
    String? body,
  }) async {
    if (!Platform.isIOS) return;
    // Implementation would use MFMailComposeViewController
  }

  /// Open Maps with directions.
  static Future<void> openMaps({
    required String destination,
    String? source,
  }) async {
    if (!Platform.isIOS) return;
    // Implementation would use MKMapItem.openMapsWithItems
  }
}

/// iOS-specific file system utilities.
class IosFiles {
  /// Get the Documents directory path.
  static Future<String?> getDocumentsDirectory() async {
    if (!Platform.isIOS) return null;
    // Implementation would use NSSearchPathForDirectoriesInDomains
    return null;
  }

  /// Get the Library directory path.
  static Future<String?> getLibraryDirectory() async {
    if (!Platform.isIOS) return null;
    return null;
  }

  /// Get the Caches directory path.
  static Future<String?> getCachesDirectory() async {
    if (!Platform.isIOS) return null;
    return null;
  }

  /// Get the temporary directory path.
  static Future<String?> getTemporaryDirectory() async {
    if (!Platform.isIOS) return null;
    return null;
  }

  /// Check if a file exists in app sandbox.
  static Future<bool> fileExists(String path) async {
    if (!Platform.isIOS) return false;
    // Implementation would use FileManager.default.fileExistsAtPath
    return false;
  }
}

/// iOS-specific background tasks.
class IosBackgroundTasks {
  /// Register a background task.
  static Future<void> registerTask({
    required String identifier,
    required Future<void> Function() task,
  }) async {
    if (!Platform.isIOS) return;
    // Implementation would use BGTaskScheduler
  }

  /// Submit a background app refresh task.
  static Future<void> submitAppRefresh({
    required String identifier,
    Duration earliestBeginDate = const Duration(minutes: 15),
  }) async {
    if (!Platform.isIOS) return;
    // Implementation would use BGAppRefreshTaskRequest
  }

  /// Submit a background processing task.
  static Future<void> submitProcessing({
    required String identifier,
    required Duration earliestBeginDate,
    bool requiresNetworkConnectivity = false,
    bool requiresExternalPower = false,
  }) async {
    if (!Platform.isIOS) return;
    // Implementation would use BGProcessingTaskRequest
  }
}

/// iOS-specific share sheet.
class IosShareSheet {
  /// Present a share sheet with items.
  static Future<void> share({
    required List<dynamic> items,
    String? subject,
    String? message,
  }) async {
    if (!Platform.isIOS) return;
    // Implementation would present UIActivityViewController
  }

  /// Share text.
  static Future<void> shareText(String text, {String? subject}) async {
    await share(items: [text], subject: subject);
  }

  /// Share a file.
  static Future<void> shareFile(String filePath, {String? subject}) async {
    if (!Platform.isIOS) return;
    // Implementation would share file URL
  }

  /// Share multiple files.
  static Future<void> shareFiles(List<String> filePaths, {String? subject}) async {
    if (!Platform.isIOS) return;
    // Implementation would share multiple file URLs
  }
}

/// iOS-specific device information.
class IosDeviceInfo {
  /// Get device model name (e.g., "iPhone 15 Pro").
  static Future<String?> getModelName() async {
    if (!Platform.isIOS) return null;
    // Implementation would use UIDevice.current.model
    return null;
  }

  /// Get device identifier (e.g., "iPhone15,3").
  static Future<String?> getDeviceIdentifier() async {
    if (!Platform.isIOS) return null;
    // Implementation would use sysctlbyname("hw.machine")
    return null;
  }

  /// Get system version (e.g., "17.2").
  static Future<String?> getSystemVersion() async {
    if (!Platform.isIOS) return null;
    // Implementation would use UIDevice.current.systemVersion
    return null;
  }

  /// Get device name (user-assigned name).
  static Future<String?> getDeviceName() async {
    if (!Platform.isIOS) return null;
    // Implementation would use UIDevice.current.name
    return null;
  }

  /// Check if device is simulator.
  static bool get isSimulator {
    // Check if running on simulator
    return false; // Placeholder
  }

  /// Get battery level (0.0 to 1.0, -1 if unknown).
  static Future<double> getBatteryLevel() async {
    if (!Platform.isIOS) return -1;
    // Implementation would use UIDevice.current.batteryLevel
    return -1;
  }

  /// Check if low power mode is enabled.
  static Future<bool> isLowPowerModeEnabled() async {
    if (!Platform.isIOS) return false;
    // Implementation would use ProcessInfo.processInfo.isLowPowerModeEnabled
    return false;
  }

  /// Get available storage space in bytes.
  static Future<int?> getAvailableStorage() async {
    if (!Platform.isIOS) return null;
    // Implementation would use FileManager.default.attributesOfFileSystemForPath
    return null;
  }
}

/// iOS-specific app lifecycle.
class IosAppLifecycle {
  /// Handle app entering background.
  static Future<void> onEnterBackground() async {
    if (!Platform.isIOS) return;
    // Implementation would save state, cancel timers, etc.
  }

  /// Handle app entering foreground.
  static Future<void> onEnterForeground() async {
    if (!Platform.isIOS) return;
    // Implementation would restore state, resume timers, etc.
  }

  /// Handle app termination.
  static Future<void> onTerminate() async {
    if (!Platform.isIOS) return;
    // Implementation would save critical state
  }

  /// Handle memory warning.
  static Future<void> onMemoryWarning() async {
    if (!Platform.isIOS) return;
    // Implementation would clear caches, release resources
  }
}