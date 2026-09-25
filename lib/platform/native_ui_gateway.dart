import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_channel_names.dart';

/// Inventory ids declared in `shortcuts.xml` for the OPEN_APP_FEATURE App
/// Action. A matched feature arrives as its shortcut id, which means "open
/// the feature" rather than "here is a spoken prompt".
const Set<String> _assistantFeatureIds = {'ai_assistant'};

/// Normalizes a raw assistant payload coming from a deep link or an App
/// Actions/Assistant invocation.
///
/// Returns `null` when the payload is empty decoration (matched feature id,
/// just quotes, `feature=` marker) and carries no usable prompt.
String? normalizedAssistantPrompt(String? raw) {
  var text = raw?.trim() ?? '';
  // Legacy Assistant/App Actions injected an explicit `feature=` marker.
  if (text.startsWith('feature=')) {
    text = text.substring('feature='.length).trim();
  }
  // Gemini often wraps the spoken phrase in quotes.
  if (text.length >= 2) {
    final first = text[0];
    final last = text[text.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      text = text.substring(1, text.length - 1).trim();
    }
  }
  if (text.isEmpty) return null;
  final lower = text.toLowerCase();
  if (_assistantFeatureIds.contains(lower)) return null;
  // Free-form phrases still prefixed with the trigger word.
  const triggerPrefixes = ['open ', 'öffne ', 'abre '];
  for (final prefix in triggerPrefixes) {
    if (lower == prefix.trim()) return null;
  }
  return text;
}

/// The most recent prompt already handed to an assistant listener. Guards
/// against double-delivery when a live `openAssistant` call competes with the
/// cold-start replay of the same stored prompt. Module-level so the
/// [NativeUiGateway] const constructor stays const.
String? lastDeliveredAssistantPrompt;

/// Typed access to the native UI channel shared by Android and iOS.
class NativeUiGateway {
  const NativeUiGateway({
    MethodChannel channel = const MethodChannel(NativeChannelNames.ui),
  }) : _channel = channel;

  final MethodChannel _channel;

  void registerAssistantOpenHandler(void Function(String? prompt) onOpen) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'openAssistant') return;
      final prompt = normalizedAssistantPrompt(
        call.arguments?.toString().trim() ?? '',
      );
      _deliverAssistantPrompt(prompt, onOpen);
      _clearPendingNativePrompt();
    });
    // Replay a request that reached the platform before this handler was
    // registered (cold start). The native side clears the stored value, so a
    // request is delivered exactly once.
    _replayPendingNativePrompt(onOpen);
  }

  Future<void> _replayPendingNativePrompt(void Function(String?) onOpen) async {
    String? pending;
    try {
      pending = await _channel.invokeMethod<String>(
        'getPendingAssistantPrompt',
      );
    } on PlatformException {
      return; // Native channel unavailable (e.g. tests / unsupported host).
    } on MissingPluginException {
      return;
    }
    final prompt = normalizedAssistantPrompt(pending);
    if (prompt != null) _deliverAssistantPrompt(prompt, onOpen);
  }

  Future<void> _clearPendingNativePrompt() async {
    try {
      await _channel.invokeMethod<void>('clearPendingAssistantPrompt');
    } on PlatformException {
      // Best effort: the stored prompt is overwritten by the next invocation.
    } on MissingPluginException {
      // Non-Android hosts have no pending-prompt storage.
    }
  }

  void _deliverAssistantPrompt(
    String? prompt,
    void Function(String?) onOpen,
  ) {
    // A matched App Actions feature id normalizes to null: still open the
    // assistant, just without a prefilled query.
    if (prompt != null && prompt == lastDeliveredAssistantPrompt) return;
    if (prompt != null) lastDeliveredAssistantPrompt = prompt;
    onOpen(prompt);
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
    MethodChannel channel = const MethodChannel(
      NativeChannelNames.alarmRefresh,
    ),
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