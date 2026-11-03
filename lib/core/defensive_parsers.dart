import 'dart:convert';

int? asIntOrNull(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  final Object other => int.tryParse(other.toString().trim()),
  null => null,
};

Map<String, dynamic> asStringDynamicMap(Map raw) =>
    raw.map((key, value) => MapEntry(key.toString(), value));

Map<String, dynamic>? tryAsStringDynamicMap(Object? raw) =>
    raw is Map ? asStringDynamicMap(raw) : null;

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
  return asStringDynamicMap(decoded);
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
      .map(asStringDynamicMap)
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

String stripMarkdownCodeFences(String input) {
  return input
      .replaceAll(RegExp(r'```(?:json)?', caseSensitive: false), '')
      .replaceAll('```', '')
      .trim();
}

String extractFirstJsonBlock(String input) {
  final s = stripMarkdownCodeFences(input);
  final arrayStart = s.indexOf('[');
  final objStart = s.indexOf('{');

  if (arrayStart != -1 && (objStart == -1 || arrayStart < objStart)) {
    final end = s.lastIndexOf(']');
    if (end != -1 && end > arrayStart) {
      return s.substring(arrayStart, end + 1).trim();
    }
  }

  if (objStart != -1) {
    final end = s.lastIndexOf('}');
    if (end != -1 && end > objStart) {
      return s.substring(objStart, end + 1).trim();
    }
  }

  return s;
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
        .map(asStringDynamicMap)
        .toList(growable: false);
  } catch (_) {
    throw FormatException(invalidMessage);
  }
}
