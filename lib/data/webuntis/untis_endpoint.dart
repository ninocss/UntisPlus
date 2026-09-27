import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Where WebUntis requests are sent.
///
/// This lives next to the HTTP client rather than in `core/app_state.dart`
/// because it is part of the request layer: every repository builds its URLs
/// through [untisBaseUrl], so the development-server override has to be
/// reachable from below the UI.

/// Default address of a locally running UntisPlus development server.
const String kDefaultDevServerUrl = 'localhost:3000';

/// Source of the development server itself, linked from the developer-mode
/// settings so it can be cloned and started. The README there is the
/// authoritative setup guide; the app only points at the repository.
const String kDevServerRepositoryUrl =
    'https://github.com/OseMine/UntisPlus-dev-server';

/// How the dev-mode status is communicated to the user.
enum DevModeNotificationStyle {
  /// Show a popup dialog on app start when dev server is detected.
  popup,

  /// Show a persistent green bar at the top of the app.
  bar,

  /// No visual indicator.
  none,
}

/// Developer mode redirects WebUntis requests to a local development
/// server instead of the active account's school, so backend work can be
/// exercised without a real school backend.
///
/// It is mutually exclusive with demo mode: demo mode answers from local
/// sample data and performs no requests at all.
/// Dev mode CAN run alongside a real school account — the dev server simply
/// takes precedence when reachable.
final ValueNotifier<bool> devModeNotifier = ValueNotifier(false);

/// Host (and optional port) of the development server, without a scheme.
final ValueNotifier<String> devServerUrlNotifier = ValueNotifier(
  kDefaultDevServerUrl,
);

/// Whether development-server requests use `https://` instead of `http://`.
/// School servers are always reached over HTTPS; only developer mode can opt
/// out, because local development servers usually run plain HTTP.
final ValueNotifier<bool> devUseHttpsNotifier = ValueNotifier(false);

/// School name for the development server (used for authentication, like a
/// real school login).
final ValueNotifier<String> devServerSchoolNameNotifier = ValueNotifier('');

/// Username for the development server authentication.
final ValueNotifier<String> devServerUsernameNotifier = ValueNotifier('');

/// Password for the development server authentication.
final ValueNotifier<String> devServerPasswordNotifier = ValueNotifier('');

/// How to notify the user that dev mode is active and using the dev server.
final ValueNotifier<DevModeNotificationStyle> devModeNotificationStyleNotifier =
    ValueNotifier(DevModeNotificationStyle.popup);

/// Whether the dev server was successfully detected and is being used.
/// Updated on app start by [checkDevServerReachable].
final ValueNotifier<bool> devServerReachableNotifier = ValueNotifier(false);

/// Strips any scheme, path, query or fragment that was pasted into the address
/// field, leaving the bare `host[:port]` the WebUntis client expects.
String normalizeDevServerUrl(String value) {
  var host = value.trim();
  if (host.isEmpty) return kDefaultDevServerUrl;
  host = host.replaceFirst(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://'), '');
  host = host.split('/').first.split('?').first.split('#').first;
  return host.isEmpty ? kDefaultDevServerUrl : host;
}

/// Base URL of the configured development server, or `null` when developer
/// mode is off.
String? _devServerBaseUrl() {
  if (!devModeNotifier.value) return null;
  final scheme = devUseHttpsNotifier.value ? 'https' : 'http';
  return '$scheme://${normalizeDevServerUrl(devServerUrlNotifier.value)}';
}

/// Base URL a WebUntis request for [schoolUrl] is sent to.
///
/// A school server is always reached over HTTPS. Developer mode is the single
/// exception: it targets the configured local server and honours the explicit
/// HTTP/HTTPS choice, but only when the dev server is reachable (or no school
/// is configured, in which case we always try the dev server).
String untisBaseUrl({required String schoolUrl}) {
  final useDev = shouldUseDevServer(
    schoolUrl: schoolUrl,
    requireReachable: schoolUrl.trim().isNotEmpty,
  );
  return useDev ? _devServerBaseUrl()! : 'https://${schoolUrl.trim()}';
}

/// Base URL of the public WebUntis school directory.
///
/// The directory is a shared service rather than a per-school backend, but it
/// is still part of the onboarding flow, so developer mode redirects it to the
/// local server and lets backend work be exercised without querying the real
/// Untis infrastructure. Callers keep the same request and response shape.
/// Dev mode only redirects when the dev server is reachable (or no school is
/// configured, in which case we always try the dev server).
String untisDirectoryBaseUrl() =>
    shouldUseDevServer() ? _devServerBaseUrl()! : 'https://mobile.webuntis.com';

/// Checks if the configured dev server is reachable by making a lightweight
/// request. Updates [devServerReachableNotifier] with the result.
///
/// Returns `true` if the server responded successfully, `false` otherwise.
/// This is called on app start when dev mode is enabled.
Future<bool> checkDevServerReachable() async {
  if (!devModeNotifier.value) {
    devServerReachableNotifier.value = false;
    return false;
  }
  final baseUrl = _devServerBaseUrl();
  if (baseUrl == null) {
    devServerReachableNotifier.value = false;
    return false;
  }
  try {
    // Try a lightweight endpoint that the dev server should expose.
    // Using a short timeout so startup isn't blocked.
    final response = await http.Client().get(
      Uri.parse('$baseUrl/api/health'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 3));
    final reachable = response.statusCode == 200;
    devServerReachableNotifier.value = reachable;
    return reachable;
  } catch (_) {
    devServerReachableNotifier.value = false;
    return false;
  }
}

/// Whether the dev server should be used for requests.
///
/// Returns true if:
/// - Dev mode is enabled AND the dev server is reachable, OR
/// - Dev mode is enabled AND [requireReachable] is false (for cases where
///   we always want to try the dev server, like when no school is configured).
bool shouldUseDevServer({String? schoolUrl, bool requireReachable = true}) {
  if (!devModeNotifier.value) return false;

  // If no school is configured and we don't require reachability, always try the dev server
  final hasSchool = schoolUrl != null && schoolUrl.trim().isNotEmpty;
  if (!hasSchool && !requireReachable) return true;

  // Otherwise, only use dev server if it's reachable
  return devServerReachableNotifier.value;
}
