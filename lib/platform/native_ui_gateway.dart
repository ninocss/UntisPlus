import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Typed access to the native UI channel shared by Android and iOS.
class NativeUiGateway {
  const NativeUiGateway({
    MethodChannel channel = const MethodChannel('untisplus/ui'),
  }) : _channel = channel;

  final MethodChannel _channel;

  void registerAssistantOpenHandler(void Function(String? prompt) onOpen) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'openAssistant') return;
      final prompt = call.arguments?.toString().trim() ?? '';
      onOpen(prompt.isEmpty ? null : prompt);
    });
  }

  Future<void> setWindowBlur(bool enabled) async {
    // The iOS implementation uses a full-screen effect view, which would blur
    // the Flutter content itself rather than only the launcher backdrop.
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setWindowBlur', enabled ? 80 : 0);
    } on PlatformException {
      // Blur is optional and unavailable on some Android/API combinations.
    } on MissingPluginException {
      // Tests and unsupported platforms intentionally have no native plugin.
    }
  }

  Future<bool> setLauncherIcon(String icon) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return false;
    try {
      return await _channel.invokeMethod<bool>('setLauncherIcon', icon) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<List<String>> supportedAbis() async {
    if (kIsWeb || !Platform.isAndroid) return const [];
    try {
      final values = await _channel.invokeMethod<List<dynamic>>(
        'getSupportedAbis',
      );
      return values
              ?.map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toList(growable: false) ??
          const [];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  Future<String?> installApk(String path) =>
      _channel.invokeMethod<String>('installApk', {'path': path});
}

class AlarmRefreshGateway {
  const AlarmRefreshGateway({
    MethodChannel channel = const MethodChannel('untisplus/alarm_refresh'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<void> completed({required bool refreshed}) async {
    try {
      await _channel.invokeMethod<void>('completed', {'refreshed': refreshed});
    } on PlatformException {
      // The native scheduler retains the last confirmed plan on failure.
    } on MissingPluginException {
      // The dispatcher can be invoked by tests and unsupported platforms.
    }
  }
}

const nativeUiGateway = NativeUiGateway();
const alarmRefreshGateway = AlarmRefreshGateway();
