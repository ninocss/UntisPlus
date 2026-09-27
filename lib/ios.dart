// iOS-specific Dart code
//
// This library contains iOS-specific implementations for:
// - AI features (Core ML, on-device inference, Apple Intelligence)
// - Widgets (WidgetKit, Live Activities, Dynamic Island)
// - General iOS utilities (haptics, permissions, safe areas, deep links, etc.)
//
// All code in this library is guarded by `Platform.isIOS` checks and will
// no-op on non-iOS platforms.

export 'ios/ios_ai_helper.dart' hide isIOS;
export 'ios/ios_widget_helper.dart' hide isIOS;
export 'ios/ios_helper.dart' hide isMacOS;