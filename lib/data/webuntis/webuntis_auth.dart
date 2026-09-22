import 'package:otp_auth/otp_auth.dart';

/// Normalizes raw WebUntis login keys and supported QR-code URIs.
String normalizeWebUntisSecret(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  if (trimmed.startsWith('otpauth://')) {
    return OTPUri.extractSecret(
      trimmed,
    ).trim().replaceAll(' ', '').toUpperCase();
  }

  if (trimmed.startsWith('untis://')) {
    final uri = Uri.tryParse(trimmed);
    final extracted =
        uri?.queryParameters['key'] ?? uri?.queryParameters['secret'] ?? '';
    if (extracted.isNotEmpty) {
      return extracted.trim().replaceAll(' ', '').toUpperCase();
    }
  }

  return trimmed.replaceAll(' ', '').toUpperCase();
}

/// Creates the six-digit WebUntis TOTP for a stored login key.
String generateWebUntisOtp(String credential) {
  final secret = normalizeWebUntisSecret(credential);
  if (secret.isEmpty) {
    throw ArgumentError('WebUntis secret must not be empty.');
  }
  return TOTP(
    secret: secret,
    digits: 6,
    algorithm: OTPAlgorithm.sha1,
    period: 30,
  ).now();
}

/// Returns the JSESSIONID value from a Set-Cookie header, if present.
String webUntisSessionIdFromCookie(String? setCookie) =>
    RegExp(r'JSESSIONID=([^;]+)').firstMatch(setCookie ?? '')?.group(1) ?? '';
