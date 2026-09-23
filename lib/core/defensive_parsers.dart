import 'dart:convert';

Map<String, dynamic> decodeJsonMap(Object? source) {
  Object? decoded = source;
  if (source is String) {
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      return <String, dynamic>{};
    }
  }
  if (decoded is! Map) return <String, dynamic>{};
  return decoded.map((key, value) => MapEntry(key.toString(), value));
}

List<Map<String, dynamic>> decodeJsonObjectList(Object? source) {
  Object? decoded = source;
  if (source is String) {
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
  if (decoded is! List) return <Map<String, dynamic>>[];
  return decoded
      .whereType<Map>()
      .map(
        (value) => value.map(
          (key, item) => MapEntry(key.toString(), item),
        ),
      )
      .toList(growable: false);
}

List<String> decodeStringList(Object? source) {
  Object? decoded = source;
  if (source is String) {
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      return const <String>[];
    }
  }
  if (decoded is! List) return const <String>[];
  return decoded.map((value) => value.toString()).toList(growable: false);
}

List<Map<String, dynamic>> parseJsonObjectArrayFromModelText(
  String source, {
  String invalidMessage = 'Invalid JSON array',
}) {
  final start = source.indexOf('[');
  final end = source.lastIndexOf(']');
  if (start < 0 || end <= start) {
    throw FormatException(invalidMessage);
  }
  try {
    final decoded = jsonDecode(source.substring(start, end + 1));
    if (decoded is! List) throw const FormatException();
    return decoded
        .whereType<Map>()
        .map(
          (value) => value.map(
            (key, item) => MapEntry(key.toString(), item),
          ),
        )
        .toList(growable: false);
  } catch (_) {
    throw FormatException(invalidMessage);
  }
}
